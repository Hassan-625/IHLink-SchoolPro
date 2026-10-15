begin;

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
set search_path = ''
as $function$
declare
  sid uuid;
  a jsonb;
  inv public.schoolpro_invoices%rowtype;
  sum_alloc numeric := 0;
  pending_alloc numeric := 0;
  receipt storage.objects%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if p_total is null or p_total <= 0 or p_total <> round(p_total, 2)
     or p_payment_date is null
     or p_allocations is null
     or jsonb_typeof(p_allocations) <> 'array'
     or jsonb_array_length(p_allocations) = 0 then
    raise exception 'Valid payment amount, date and allocations are required';
  end if;

  if p_receipt_mime not in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf') then
    raise exception 'Unsupported receipt file type';
  end if;

  if p_receipt_path is null
     or p_receipt_path !~ ('^' || auth.uid()::text || '/[A-Za-z0-9._-]+$')
     or p_receipt_path ~ '(^|/)\.\.?(/|$)' then
    raise exception 'Receipt path must belong to the authenticated payer';
  end if;

  select o.* into receipt
  from storage.objects o
  where o.bucket_id = 'schoolpro-payment-receipts'
    and o.name = p_receipt_path
    and split_part(o.name, '/', 1) = auth.uid()::text;

  if receipt.id is null then
    raise exception 'Receipt object not found in the private SchoolPro receipt bucket';
  end if;

  if receipt.metadata->>'mimetype' is distinct from p_receipt_mime then
    raise exception 'Receipt MIME type does not match uploaded object metadata';
  end if;

  if coalesce((receipt.metadata->>'size')::bigint, 0) <= 0
     or (receipt.metadata->>'size')::bigint > 5242880 then
    raise exception 'Receipt must be between 1 byte and 5 MiB';
  end if;

  if not exists (
    select 1
    from public.schoolpro_guardian_links g
    where g.school_id = p_school
      and g.guardian_user_id = auth.uid()
      and g.status = 'active'
  ) then
    raise exception 'No active child link for this school';
  end if;

  if p_bank_account is not null and not exists (
    select 1 from public.schoolpro_bank_accounts b
    where b.id = p_bank_account and b.school_id = p_school and b.active
  ) then
    raise exception 'Invalid school bank account';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_allocations) x
    group by (x->>'invoice_id')
    having count(*) > 1
  ) then
    raise exception 'Each invoice may appear only once per submission';
  end if;

  -- Lock invoice rows in a stable order so concurrent submissions cannot
  -- both reserve the same outstanding balance.
  for inv in
    select i.*
    from public.schoolpro_invoices i
    join (
      select distinct (x->>'invoice_id')::uuid as invoice_id
      from jsonb_array_elements(p_allocations) x
    ) requested on requested.invoice_id = i.id
    where i.school_id = p_school
    order by i.id
    for update of i
  loop
    null;
  end loop;

  for a in select value from jsonb_array_elements(p_allocations)
  loop
    select i.* into inv
    from public.schoolpro_invoices i
    where i.id = (a->>'invoice_id')::uuid
      and i.school_id = p_school;

    if inv.id is null then
      raise exception 'Invalid invoice allocation';
    end if;

    if not exists (
      select 1
      from public.schoolpro_guardian_links g
      where g.student_id = inv.student_id
        and g.guardian_user_id = auth.uid()
        and g.status = 'active'
    ) then
      raise exception 'Student is not linked to this parent';
    end if;

    if (a->>'amount') is null
       or (a->>'amount')::numeric <= 0
       or (a->>'amount')::numeric <> round((a->>'amount')::numeric, 2) then
      raise exception 'Allocation must be a positive amount with at most two decimal places';
    end if;

    select coalesce(sum(pa.amount), 0) into pending_alloc
    from public.schoolpro_payment_allocations pa
    join public.schoolpro_payment_submissions ps on ps.id = pa.submission_id
    where pa.invoice_id = inv.id
      and ps.status = 'pending';

    if (a->>'amount')::numeric > inv.amount_due - inv.amount_paid - pending_alloc then
      raise exception 'Allocation exceeds the unreserved outstanding invoice balance';
    end if;

    sum_alloc := sum_alloc + (a->>'amount')::numeric;
  end loop;

  if sum_alloc <> p_total then
    raise exception 'Allocated amount must equal payment total';
  end if;

  insert into public.schoolpro_payment_submissions(
    school_id, submitted_by, bank_account_id, total_amount, payment_date,
    payer_name, bank_reference, receipt_path, receipt_mime
  )
  values (
    p_school, auth.uid(), p_bank_account, p_total, p_payment_date,
    nullif(btrim(p_payer_name), ''), nullif(btrim(p_bank_reference), ''),
    p_receipt_path, p_receipt_mime
  )
  returning id into sid;

  for a in select value from jsonb_array_elements(p_allocations)
  loop
    select * into inv
    from public.schoolpro_invoices
    where id = (a->>'invoice_id')::uuid
      and school_id = p_school;

    insert into public.schoolpro_payment_allocations(
      submission_id, school_id, student_id, invoice_id, amount
    )
    values (sid, p_school, inv.student_id, inv.id, (a->>'amount')::numeric);
  end loop;

  return sid;
end
$function$;

revoke all on function public.submit_schoolpro_payment(uuid, uuid, numeric, date, text, text, text, text, jsonb)
  from public, anon;
grant execute on function public.submit_schoolpro_payment(uuid, uuid, numeric, date, text, text, text, text, jsonb)
  to authenticated;

commit;
