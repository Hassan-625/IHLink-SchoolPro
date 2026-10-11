CREATE OR REPLACE FUNCTION private.sync_schoolpro_fee_invoices(p_structure uuid, p_class text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare f public.schoolpro_fee_structures; s public.schoolpro_students; ex public.schoolpro_fee_exceptions;
 old public.schoolpro_invoices; gross numeric; discount_amt numeric; scholarship_amt numeric; waiver_amt numeric; net numeric;
 issued integer:=0; refreshed integer:=0; retained integer:=0;
begin
 select * into f from public.schoolpro_fee_structures where id=p_structure for update;
 if f.id is null then raise exception 'Fee structure not found'; end if;
 if not f.is_active then return jsonb_build_object('processed',0,'issued',0,'updated',0,'retained',0); end if;
 select coalesce(sum(amount) filter(where not is_optional),0) into gross from public.schoolpro_fee_items where fee_structure_id=f.id;
 if gross=0 then gross:=f.amount; end if;
 if gross is null or gross<0 or gross<>round(gross,2) then raise exception 'Fee must be nonnegative with at most two decimal places'; end if;
 for s in select candidate.* from public.schoolpro_students candidate where candidate.school_id=f.school_id and candidate.status='active'
 and (case when exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=f.school_id) then exists(select 1 from public.schoolpro_enrollment_history e where e.school_id=candidate.school_id and e.student_id=candidate.id and e.session=f.session and (coalesce(p_class,f.class_name) is null or e.class_name||case when coalesce(e.arm,'')='' then '' else ' '||e.arm end=coalesce(p_class,f.class_name))) else coalesce(p_class,f.class_name) is null or candidate.class_name=coalesce(p_class,f.class_name) end) order by id loop
  ex:=null; select * into ex from public.schoolpro_fee_exceptions where school_id=f.school_id and student_id=s.id and term=f.term and session=f.session;
  discount_amt:=0;scholarship_amt:=0;waiver_amt:=0;
  if ex.id is not null then
   if ex.exception_type='full_waiver' or ex.waived then waiver_amt:=gross;
   elsif ex.exception_type='partial_waiver' then waiver_amt:=case when ex.value_type='percentage' then gross*ex.value/100 else coalesce(nullif(ex.value,0),ex.partial_waiver) end;
   elsif ex.exception_type='scholarship' then scholarship_amt:=case when ex.value_type='percentage' then gross*ex.value/100 else coalesce(nullif(ex.value,0),ex.scholarship) end;
   else discount_amt:=case when ex.value_type='percentage' then gross*ex.value/100 else coalesce(nullif(ex.value,0),ex.discount) end; end if;
  end if;
  discount_amt:=round(least(gross,greatest(0,discount_amt)),2);
  scholarship_amt:=round(least(gross-discount_amt,greatest(0,scholarship_amt)),2);
  waiver_amt:=round(least(gross-discount_amt-scholarship_amt,greatest(0,waiver_amt)),2);
  net:=greatest(0,gross-discount_amt-scholarship_amt-waiver_amt);
  select * into old from public.schoolpro_invoices where student_id=s.id and fee_structure_id=f.id for update;
  if old.id is null then
   insert into public.schoolpro_invoices(school_id,student_id,fee_structure_id,title,term,session,gross_amount,amount_due,due_date,discount,scholarship,waiver_amount,status,notes,created_by)
   values(f.school_id,s.id,f.id,f.name,f.term,f.session,gross,net,f.due_date,discount_amt,scholarship_amt,waiver_amt,
   case when net=0 then 'waived'::public.schoolpro_invoice_status else 'unpaid'::public.schoolpro_invoice_status end,ex.notes,coalesce(auth.uid(),f.created_by));
   issued:=issued+1;
  elsif old.amount_paid>0 or old.status in ('paid','part_paid') then retained:=retained+1;
  elsif (old.amount_due,old.gross_amount,old.discount,old.scholarship,old.waiver_amount,old.title,old.due_date)
   is distinct from (net,gross,discount_amt,scholarship_amt,waiver_amt,f.name,f.due_date) then
   if exists(select 1 from public.schoolpro_payment_intents where invoice_id=old.id and status='pending') then
    raise exception 'A pending payment instruction must be reconciled before changing this fee';
   end if;
   update public.schoolpro_invoices set title=f.name,amount_due=net,gross_amount=gross,discount=discount_amt,
    scholarship=scholarship_amt,waiver_amount=waiver_amt,due_date=f.due_date,notes=ex.notes,
    status=case when net=0 then 'waived'::public.schoolpro_invoice_status else 'unpaid'::public.schoolpro_invoice_status end,updated_at=now() where id=old.id;
   refreshed:=refreshed+1;
  else retained:=retained+1; end if;
 end loop;
 if issued+refreshed>0 then
  insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
  values(auth.uid(),'School fee invoices synchronized','schoolpro','fee_structure',f.id::text,
    jsonb_build_object('school_id',f.school_id,'issued',issued,'updated',refreshed,'retained',retained));
 end if;
 return jsonb_build_object('processed',issued+refreshed+retained,'issued',issued,'updated',refreshed,'retained',retained,'gross',gross);
end $function$
