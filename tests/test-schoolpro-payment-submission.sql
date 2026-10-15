\set ON_ERROR_STOP on
\ir /workspace/tests/schoolpro-payment-submission-fixture.sql
\ir /workspace/supabase/migrations/20261015143000_harden_schoolpro_payment_receipt_submission.sql
do $$ declare
  parent_id uuid := '10000000-0000-0000-0000-000000000001';
  school_id uuid := '20000000-0000-0000-0000-000000000001';
  student_id uuid := '30000000-0000-0000-0000-000000000001';
  invoice_id uuid := '40000000-0000-0000-0000-000000000001';
  bank_id uuid := '50000000-0000-0000-0000-000000000001';
  submission_id uuid;
begin
  insert into public.schoolpro_guardian_links values(school_id,student_id,parent_id,'active');
  insert into public.schoolpro_bank_accounts values(bank_id,school_id,true);
  insert into public.schoolpro_invoices(id,school_id,student_id,amount_due,amount_paid) values(invoice_id,school_id,student_id,1000,0);
  insert into storage.objects(bucket_id,name,metadata) values('schoolpro-payment-receipts',parent_id::text||'/receipt.pdf',jsonb_build_object('mimetype','application/pdf','size',1024));
  perform set_config('request.jwt.claim.sub',parent_id::text,false);

  begin
    perform public.submit_schoolpro_payment(school_id,bank_id,100,'2026-10-15','Parent',null,'90000000-0000-0000-0000-000000000001/forged.pdf','application/pdf',jsonb_build_array(jsonb_build_object('invoice_id',invoice_id,'amount',100)));
    raise exception 'TEST FAILURE: forged path was accepted';
  exception when others then
    if sqlerrm='TEST FAILURE: forged path was accepted' then raise; end if;
  end;

  begin
    perform public.submit_schoolpro_payment(school_id,bank_id,100,'2026-10-15','Parent',null,parent_id::text||'/missing.pdf','application/pdf',jsonb_build_array(jsonb_build_object('invoice_id',invoice_id,'amount',100)));
    raise exception 'TEST FAILURE: missing object was accepted';
  exception when others then
    if sqlerrm='TEST FAILURE: missing object was accepted' then raise; end if;
  end;

  begin
    perform public.submit_schoolpro_payment(school_id,bank_id,100,'2026-10-15','Parent',null,parent_id::text||'/receipt.pdf','image/png',jsonb_build_array(jsonb_build_object('invoice_id',invoice_id,'amount',100)));
    raise exception 'TEST FAILURE: MIME mismatch was accepted';
  exception when others then
    if sqlerrm='TEST FAILURE: MIME mismatch was accepted' then raise; end if;
  end;

  submission_id := public.submit_schoolpro_payment(school_id,bank_id,700,'2026-10-15','Parent',null,parent_id::text||'/receipt.pdf','application/pdf',jsonb_build_array(jsonb_build_object('invoice_id',invoice_id,'amount',700)));
  if not exists(select 1 from public.schoolpro_payment_submissions where id=submission_id and status='pending') then raise exception 'TEST FAILURE: valid submission not pending'; end if;

  begin
    perform public.submit_schoolpro_payment(school_id,bank_id,400,'2026-10-15','Parent',null,parent_id::text||'/receipt.pdf','application/pdf',jsonb_build_array(jsonb_build_object('invoice_id',invoice_id,'amount',400)));
    raise exception 'TEST FAILURE: over-allocation against pending submission accepted';
  exception when others then
    if sqlerrm='TEST FAILURE: over-allocation against pending submission accepted' then raise; end if;
  end;

  raise notice 'PASS: forged path, missing object, MIME mismatch, valid submission, and pending-balance reservation';
end $$;
