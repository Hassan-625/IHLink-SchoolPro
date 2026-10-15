\set ON_ERROR_STOP on
\ir schoolpro-payment-submission-fixture.sql
\ir schoolpro-receipt-review-policy-fixture.sql
\ir ../supabase/migrations/20261015150000_allow_school_finance_to_view_submitted_receipts.sql
do $$ declare
  school_a uuid := '21000000-0000-0000-0000-000000000001';
  school_b uuid := '21000000-0000-0000-0000-000000000002';
  guardian uuid := '11000000-0000-0000-0000-000000000001';
begin
  insert into public.schoolpro_payment_submissions(id,school_id,submitted_by,total_amount,payment_date,receipt_path,receipt_mime)
  values
    ('71000000-0000-0000-0000-000000000001',school_a,guardian,100,'2026-10-15',guardian::text||'/school-a.pdf','application/pdf'),
    ('71000000-0000-0000-0000-000000000002',school_b,guardian,100,'2026-10-15',guardian::text||'/school-b.pdf','application/pdf');
  insert into storage.objects(bucket_id,name,metadata)
  values
    ('schoolpro-payment-receipts',guardian::text||'/school-a.pdf',jsonb_build_object('mimetype','application/pdf','size',1000)),
    ('schoolpro-payment-receipts',guardian::text||'/school-b.pdf',jsonb_build_object('mimetype','application/pdf','size',1000)),
    ('schoolpro-payment-receipts',guardian::text||'/orphan.pdf',jsonb_build_object('mimetype','application/pdf','size',1000));
end $$;

set role authenticated;
select set_config('test.finance_school','21000000-0000-0000-0000-000000000001',false);
select set_config('test.access_school','21000000-0000-0000-0000-000000000001',false);
do $$ begin
  if (select count(*) from storage.objects where bucket_id='schoolpro-payment-receipts') <> 1
     or not exists(select 1 from storage.objects where name='11000000-0000-0000-0000-000000000001/school-a.pdf') then
    raise exception 'TEST FAILURE: authorized finance user should see only own school submitted receipt';
  end if;
end $$;

select set_config('test.finance_school','21000000-0000-0000-0000-000000000002',false);
select set_config('test.access_school','21000000-0000-0000-0000-000000000002',false);
do $$ begin
  if (select count(*) from storage.objects where bucket_id='schoolpro-payment-receipts') <> 1
     or not exists(select 1 from storage.objects where name='11000000-0000-0000-0000-000000000001/school-b.pdf') then
    raise exception 'TEST FAILURE: school B finance should see only school B receipt';
  end if;
end $$;

select set_config('test.finance_school','21000000-0000-0000-0000-000000000001',false);
select set_config('test.access_school','21000000-0000-0000-0000-000000000002',false);
do $$ begin
  if exists(select 1 from storage.objects where bucket_id='schoolpro-payment-receipts') then
    raise exception 'TEST FAILURE: mismatched finance/access school should see no receipts';
  end if;
end $$;
reset role;
\echo 'PASS: school finance receipt policy enforces school isolation and hides orphan objects'
