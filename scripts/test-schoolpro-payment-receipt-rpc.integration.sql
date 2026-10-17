-- Behavioral integration tests for the actual receipt-submission RPC migration.
-- Runs only against the disposable PostgreSQL service in CI; never target production.
create schema if not exists auth;
create schema if not exists storage;
do $$ begin create role anon nologin; exception when duplicate_object then null; end $$;
do $$ begin create role authenticated nologin; exception when duplicate_object then null; end $$;

create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null,
  name text not null,
  owner_id text,
  owner text,
  unique(bucket_id, name)
);
create table public.schoolpro_guardian_links (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  student_id uuid not null,
  guardian_user_id uuid not null,
  status text not null
);
create table public.schoolpro_bank_accounts (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  active boolean not null default true
);
create table public.schoolpro_invoices (
  id uuid primary key,
  school_id uuid not null,
  student_id uuid not null,
  amount_due numeric not null,
  amount_paid numeric not null default 0
);
create table public.schoolpro_payment_submissions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  submitted_by uuid not null,
  bank_account_id uuid,
  total_amount numeric not null,
  payment_date date not null,
  payer_name text,
  bank_reference text,
  receipt_path text not null,
  receipt_mime text,
  status text not null default 'pending'
);
create table public.schoolpro_payment_allocations (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null,
  school_id uuid not null,
  student_id uuid not null,
  invoice_id uuid not null,
  amount numeric not null
);

\ir ../supabase/migrations/20261015203000_schoolpro_payment_receipt_tenant_guard.sql

create function pg_temp.assert_rejected(p_name text, p_statement text, p_expected text)
returns void language plpgsql as $$
declare actual_message text;
begin
  begin
    execute p_statement;
  exception when others then
    get stacked diagnostics actual_message = message_text;
    if position(p_expected in actual_message) > 0 then return; end if;
    raise exception 'FAIL: % returned unexpected error: %', p_name, actual_message;
  end;
  raise exception 'FAIL: rejected-case was accepted: %', p_name;
end;
$$;

\set school '00000000-0000-0000-0000-000000000001'
\set other_school '00000000-0000-0000-0000-000000000002'
\set guardian '10000000-0000-0000-0000-000000000001'
\set other_guardian '10000000-0000-0000-0000-000000000002'
\set student '20000000-0000-0000-0000-000000000001'
\set other_student '20000000-0000-0000-0000-000000000002'
\set bank '30000000-0000-0000-0000-000000000001'
\set invoice '40000000-0000-0000-0000-000000000001'
\set invoice2 '40000000-0000-0000-0000-000000000002'
\set receipt '10000000-0000-0000-0000-000000000001/receipt.pdf'

insert into public.schoolpro_guardian_links(school_id,student_id,guardian_user_id,status) values
(:'school', :'student', :'guardian', 'active'),
(:'school', :'other_student', :'other_guardian', 'active');
insert into public.schoolpro_bank_accounts(id,school_id,active) values (:'bank', :'school', true);
insert into public.schoolpro_invoices(id,school_id,student_id,amount_due,amount_paid) values
(:'invoice', :'school', :'student', 1000, 0),
(:'invoice2', :'school', :'other_student', 500, 0);
insert into storage.objects(bucket_id,name,owner_id,owner)
values ('schoolpro-payment-receipts', :'receipt', :'guardian', :'guardian');

select set_config('request.jwt.claim.sub', :'guardian', false);

-- Valid submission creates a pending submission and a matching allocation.
select public.submit_schoolpro_payment(
  :'school', :'bank', 400, current_date, 'Test Guardian', 'REF-OK',
  :'receipt', 'application/pdf',
  jsonb_build_array(jsonb_build_object('invoice_id', :'invoice', 'amount', 400))
) as valid_submission_id \gset
select case when exists (
  select 1 from public.schoolpro_payment_submissions ps
  join public.schoolpro_payment_allocations pa on pa.submission_id=ps.id
  where ps.id=:'valid_submission_id'::uuid and ps.status='pending'
    and ps.submitted_by=:'guardian'::uuid and pa.invoice_id=:'invoice'::uuid and pa.amount=400
) then 'PASS: valid guardian receipt submission persisted' else
  (select 1/0)::text end;

select pg_temp.assert_rejected('receipt owned by another user',
  $$select public.submit_schoolpro_payment(
    '00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',50,current_date,'Test','REF-X',
    '10000000-0000-0000-0000-000000000002/foreign.pdf','application/pdf',
    '[{"invoice_id":"40000000-0000-0000-0000-000000000001","amount":50}]'::jsonb)$$,
  'Receipt upload is missing or does not belong to this account');

select pg_temp.assert_rejected('invoice belongs to unlinked student',
  $$select public.submit_schoolpro_payment(
    '00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',50,current_date,'Test','REF-X',
    '10000000-0000-0000-0000-000000000001/receipt.pdf','application/pdf',
    '[{"invoice_id":"40000000-0000-0000-0000-000000000002","amount":50}]'::jsonb)$$,
  'Student is not linked to this parent');

select pg_temp.assert_rejected('duplicate invoice allocation',
  $$select public.submit_schoolpro_payment(
    '00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',100,current_date,'Test','REF-X',
    '10000000-0000-0000-0000-000000000001/receipt.pdf','application/pdf',
    '[{"invoice_id":"40000000-0000-0000-0000-000000000001","amount":50},{"invoice_id":"40000000-0000-0000-0000-000000000001","amount":50}]'::jsonb)$$,
  'Each invoice may appear only once');

select pg_temp.assert_rejected('allocation total mismatch',
  $$select public.submit_schoolpro_payment(
    '00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',100,current_date,'Test','REF-X',
    '10000000-0000-0000-0000-000000000001/receipt.pdf','application/pdf',
    '[{"invoice_id":"40000000-0000-0000-0000-000000000001","amount":50}]'::jsonb)$$,
  'Allocated amount must equal payment total');

select pg_temp.assert_rejected('pending allocation balance reservation',
  $$select public.submit_schoolpro_payment(
    '00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',700,current_date,'Test','REF-X',
    '10000000-0000-0000-0000-000000000001/receipt.pdf','application/pdf',
    '[{"invoice_id":"40000000-0000-0000-0000-000000000001","amount":700}]'::jsonb)$$,
  'Invalid allocation amount');

update public.schoolpro_bank_accounts set active=false where id='30000000-0000-0000-0000-000000000001';
select pg_temp.assert_rejected('inactive bank account',
  $select public.submit_schoolpro_payment(
    '00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',50,current_date,'Test','REF-X',
    '10000000-0000-0000-0000-000000000001/receipt.pdf','application/pdf',
    '[{"invoice_id":"40000000-0000-0000-0000-000000000001","amount":50}]'::jsonb)$,
  'Invalid school bank account');

select 'PASS: receipt submission RPC accepted the valid case and rejected six invalid cases.' as result;
