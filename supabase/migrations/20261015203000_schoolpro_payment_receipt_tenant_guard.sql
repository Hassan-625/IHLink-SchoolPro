-- Harden SchoolPro guardian fee-payment submission against receipt-path IDOR and concurrent over-allocation.
-- Existing payment records are untouched; the submitted receipt must be an object uploaded by this user.
create or replace function public.submit_schoolpro_payment(
  p_school uuid,
  p_bank_account uuid,
  p_total numeric,
  p_payment_date date,
  p_payer_name text,
  p_bank_reference text,
  p_receipt_path text,
  p_receipt_mime text,
  p_allocations jsonb
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  sid uuid;
  a jsonb;
  inv public.schoolpro_invoices%rowtype;
  sum_alloc numeric:=0;
  v_user uuid:=auth.uid();
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;

  if p_receipt_path is null
     or btrim(p_receipt_path)=''
     or split_part(p_receipt_path,'/',1)<>v_user::text
     or not exists (
       select 1 from storage.objects o
       where o.bucket_id='schoolpro-payment-receipts'
         and o.name=p_receipt_path
     ) then
    raise exception 'Receipt upload is missing or does not belong to this account';
  end if;

  if p_total is null or p_total<=0
     or coalesce(jsonb_typeof(p_allocations),'')<>'array'
     or jsonb_array_length(p_allocations)=0 then
    raise exception 'Payment amount and allocations are required';
  end if;

  if not exists (
    select 1 from public.schoolpro_guardian_links g
    where g.school_id=p_school and g.guardian_user_id=v_user and g.status='active'
  ) then
    raise exception 'No active child link for this school';
  end if;

  if p_bank_account is not null and not exists (
    select 1 from public.schoolpro_bank_accounts b
    where b.id=p_bank_account and b.school_id=p_school and b.active
  ) then
    raise exception 'Invalid school bank account';
  end if;

  -- Lock each same-school invoice while validating the allocation so concurrent requests
  -- cannot both spend the same outstanding balance.
  for a in select value from jsonb_array_elements(p_allocations) loop
    select * into inv
    from public.schoolpro_invoices
    where id=(a->>'invoice_id')::uuid and school_id=p_school
    for update;

    if inv.id is null then
      raise exception 'Invalid invoice allocation';
    end if;

    if not exists (
      select 1 from public.schoolpro_guardian_links g
      where g.school_id=p_school and g.student_id=inv.student_id
        and g.guardian_user_id=v_user and g.status='active'
    ) then
      raise exception 'Student is not linked to this parent';
    end if;

    if coalesce((a->>'amount')::numeric,0)<=0
       or (a->>'amount')::numeric>inv.amount_due-inv.amount_paid then
      raise exception 'Invalid allocation amount';
    end if;
    sum_alloc:=sum_alloc+(a->>'amount')::numeric;
  end loop;

  if sum_alloc<>p_total then
    raise exception 'Allocated amount must equal payment total';
  end if;

  insert into public.schoolpro_payment_submissions(
    school_id,submitted_by,bank_account_id,total_amount,payment_date,payer_name,
    bank_reference,receipt_path,receipt_mime
  ) values (
    p_school,v_user,p_bank_account,p_total,p_payment_date,p_payer_name,
    nullif(btrim(p_bank_reference),''),p_receipt_path,p_receipt_mime
  ) returning id into sid;

  for a in select value from jsonb_array_elements(p_allocations) loop
    select * into inv
    from public.schoolpro_invoices
    where id=(a->>'invoice_id')::uuid and school_id=p_school
    for update;
    if inv.id is null then raise exception 'Invalid invoice allocation'; end if;

    insert into public.schoolpro_payment_allocations(
      submission_id,school_id,student_id,invoice_id,amount
    ) values (
      sid,p_school,inv.student_id,inv.id,(a->>'amount')::numeric
    );
  end loop;

  return sid;
end
$function$;

revoke all on function public.submit_schoolpro_payment(uuid,uuid,numeric,date,text,text,text,text,jsonb) from public,anon;
grant execute on function public.submit_schoolpro_payment(uuid,uuid,numeric,date,text,text,text,text,jsonb) to authenticated;
