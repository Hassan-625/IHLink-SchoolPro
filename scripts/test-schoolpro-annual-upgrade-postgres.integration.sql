\set ON_ERROR_STOP on

-- Disposable PostgreSQL fixture only. Never run against hosted Supabase.

create role anon nologin;
create role authenticated nologin;
create role service_role nologin;

create schema auth;
create schema private;
create schema storage;

create table auth.users (id uuid primary key);

create or replace function auth.uid()
returns uuid
language sql stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create type public.school_member_role as enum (
  'proprietor', 'administrator', 'bursar', 'teacher',
  'class_teacher', 'exam_officer'
);

create type public.user_role as enum (
  'super_admin', 'finance', 'customer'
);

create table public.schoolpro_schools (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id),
  name text not null,
  plan text not null default 'starter',
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.schoolpro_subscription_catalog (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  monthly_price numeric,
  termly_price numeric,
  annual_price numeric,
  active boolean not null default true,
  features jsonb not null default '[]',
  updated_at timestamptz not null default now()
);

create table public.schoolpro_subscriptions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null unique references public.schoolpro_schools(id) on delete cascade,
  tier text not null,
  billing_cycle text not null,
  amount numeric(14,2) not null,
  status text not null,
  starts_at timestamptz,
  renews_at timestamptz,
  managed_by_ihlink boolean not null default false,
  updated_at timestamptz not null default now()
);

create table public.schoolpro_subscription_intents (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  payer_user_id uuid not null references auth.users(id),
  catalog_id uuid not null references public.schoolpro_subscription_catalog(id),
  billing_cycle text not null,
  amount numeric(14,2) not null,
  virtual_account_id uuid,
  reference text not null unique,
  status text not null default 'pending',
  transaction_ref text,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  payment_method text not null default 'bank_transfer',
  replaces_invoice_id uuid,
  invoice_kind text not null default 'subscription',
  demo_request_id uuid
);

create unique index schoolpro_one_pending_invoice_per_school
  on public.schoolpro_subscription_intents(school_id)
  where status = 'pending';

create table public.schoolpro_subscription_payments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  subscription_id uuid references public.schoolpro_subscriptions(id) on delete set null,
  payer_user_id uuid not null references auth.users(id),
  provider text not null default 'billstack',
  reference text not null unique,
  amount numeric(14,2) not null,
  status text not null default 'pending',
  virtual_account_id uuid,
  transaction_ref text unique,
  provider_payload jsonb not null default '{}',
  verified_at timestamptz,
  credited_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.direct_transfer_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  platform_code text not null,
  invoice_id uuid references public.schoolpro_subscription_intents(id),
  source_reference text,
  bank_account_id uuid not null,
  amount numeric(14,2) not null,
  sender_name text not null,
  sender_bank text,
  customer_reference text,
  transferred_at timestamptz,
  proof_storage_path text,
  status text not null default 'awaiting_verification',
  admin_note text,
  verified_by uuid,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.ihlink_bank_accounts (
  id uuid primary key default gen_random_uuid(),
  label text not null default 'IHLink Main Account',
  bank_name text not null,
  account_name text not null,
  account_number text not null,
  is_active boolean not null default true,
  is_default boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid,
  action text not null,
  product text,
  target_type text,
  target_id text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null,
  name text not null,
  unique(bucket_id, name)
);

create or replace function private.is_active_account()
returns boolean language sql stable
as $$ select coalesce(current_setting('request.test.active', true), 'true') = 'true' $$;

create or replace function private.is_admin(p_roles public.user_role[])
returns boolean language sql stable
as $$
  select coalesce(current_setting('request.test.admin_role', true), '') =
    any(select unnest(p_roles)::text)
$$;

create or replace function private.has_school_access(
  p_school uuid,
  p_roles public.school_member_role[]
)
returns boolean language sql stable
as $$
  select current_setting('request.test.school_id', true) = p_school::text
     and current_setting('request.test.school_role', true) =
         any(select unnest(p_roles)::text)
$$;

grant usage on schema private to authenticated;

-- Migration under test.
\ir ../supabase/migrations/20261105100048_schoolpro_annual_upgrade_workflow.sql

-- Minimal wrapper matching the production security-definer call boundary.
create or replace function public.review_direct_bank_transfer(
  p_submission uuid,
  p_decision text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  return private.review_school_subscription_transfer(
    p_submission, p_decision, p_note
  );
end;
$$;

grant execute on function public.review_direct_bank_transfer(uuid,text,text)
  to authenticated;

-- Verify that PostgreSQL registered the expected functions.
do $$
begin
  if to_regprocedure('public.request_schoolpro_upgrade(uuid,uuid)') is null
     or to_regprocedure('public.review_schoolpro_upgrade(uuid,text,text,integer)') is null
     or to_regprocedure('public.cancel_schoolpro_upgrade(uuid,text)') is null
     or to_regprocedure('private.review_school_subscription_transfer(uuid,text,text)') is null then
    raise exception 'Annual upgrade migration did not register every required RPC';
  end if;
end;
$$;

select 'PASS: annual-upgrade migration executed and all four RPC definitions registered' as result;

-- End-to-end synthetic happy path: request -> approval -> Finance settlement.
do $upgrade_lifecycle$
declare
  v_owner uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  v_finance uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  v_school uuid := 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  v_subscription uuid := 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  v_catalog uuid := 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  v_bank uuid := 'ffffffff-ffff-4fff-8fff-ffffffffffff';
  v_request jsonb;
  v_approval jsonb;
  v_settlement jsonb;
  v_repeat jsonb;
  v_request_id uuid;
  v_invoice_id uuid;
  v_submission_id uuid;
  v_invoice_amount numeric;
  v_credit numeric;
  v_expected_credit numeric;
begin
  insert into auth.users(id) values (v_owner), (v_finance);

  insert into public.schoolpro_schools
    (id, owner_id, name, plan, status)
  values
    (v_school, v_owner, 'Synthetic Upgrade School', 'starter', 'active');

  insert into public.schoolpro_subscription_catalog
    (id, code, name, annual_price, active)
  values
    (v_catalog, 'professional', 'Professional', 100000, true);

  insert into public.schoolpro_subscriptions
    (id, school_id, tier, billing_cycle, amount, status, starts_at, renews_at)
  values
    (v_subscription, v_school, 'starter', 'annual', 50000, 'active',
     clock_timestamp() - interval '180 days',
     clock_timestamp() + interval '185 days');

  -- School billing manager requests the upgrade.
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  perform set_config('request.test.active', 'true', true);
  perform set_config('request.test.school_id', v_school::text, true);
  perform set_config('request.test.school_role', 'proprietor', true);

  v_request := public.request_schoolpro_upgrade(v_school, v_catalog);
  v_request_id := (v_request->>'id')::uuid;

  if v_request_id is null then
    raise exception 'Upgrade request did not return an ID: %', v_request;
  end if;

  v_credit := (v_request->>'credit_amount')::numeric;
  v_invoice_amount := (v_request->>'outstanding_amount')::numeric;

  v_expected_credit := round(
    (v_request->>'source_paid_amount')::numeric
    * (v_request->>'quote_unused_seconds')::numeric
    / (v_request->>'quote_total_seconds')::numeric,
    2
  );

  if v_credit <> v_expected_credit then
    raise exception 'Incorrect prorated credit: got %, expected %',
      v_credit, v_expected_credit;
  end if;

  if v_invoice_amount <> 100000 - v_credit or v_invoice_amount <= 0 then
    raise exception 'Incorrect outstanding upgrade amount: %', v_invoice_amount;
  end if;

  -- IHLink Finance approves the immutable quote.
  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  perform set_config('request.test.admin_role', 'finance', true);

  v_approval := public.review_schoolpro_upgrade(
    v_request_id, 'approved', 'Synthetic integration approval', 1
  );

  v_invoice_id := (v_approval->>'invoice_id')::uuid;

  if v_invoice_id is null then
    raise exception 'Approval did not create an invoice: %', v_approval;
  end if;

  if not exists (
    select 1
    from public.schoolpro_subscription_intents i
    where i.id = v_invoice_id
      and i.school_id = v_school
      and i.payer_user_id = v_owner
      and i.amount = v_invoice_amount
      and i.status = 'pending'
      and i.billing_cycle = 'annual'
      and i.payment_method = 'bank_transfer'
      and i.upgrade_request_id = v_request_id
  ) then
    raise exception 'Approved upgrade invoice does not match the approved quote';
  end if;

  -- Simulate an uploaded receipt and a valid receiving bank account.
  insert into public.ihlink_bank_accounts
    (id, bank_name, account_name, account_number, is_active, created_by)
  values
    (v_bank, 'Synthetic Bank', 'IHLink Test Account', '0000000000', true, v_finance);

  insert into storage.objects(bucket_id, name)
  values ('direct-transfer-proofs', v_owner::text || '/upgrade-receipt.png');

  v_submission_id := gen_random_uuid();

  insert into public.direct_transfer_submissions (
    id, user_id, platform_code, invoice_id, source_reference,
    bank_account_id, amount, sender_name, customer_reference,
    proof_storage_path, status
  )
  select
    v_submission_id, v_owner, 'schoolpro_subscription', i.id, i.reference,
    v_bank, i.amount, 'Synthetic Payer', 'SYNTHETIC-UPGRADE-REF-001',
    v_owner::text || '/upgrade-receipt.png', 'awaiting_verification'
  from public.schoolpro_subscription_intents i
  where i.id = v_invoice_id;

  -- Finance verifies the transfer through the private settlement function.
  v_settlement := private.review_school_subscription_transfer(
    v_submission_id, 'approved', 'Synthetic bank transfer verified'
  );

  if not exists (
    select 1 from public.schoolpro_upgrade_requests
    where id = v_request_id and status = 'paid'
  ) then
    raise exception 'Upgrade request was not marked paid';
  end if;

  if not exists (
    select 1 from public.schoolpro_subscriptions
    where id = v_subscription
      and tier = 'professional'
      and billing_cycle = 'annual'
      and amount = 100000
      and status = 'active'
      and managed_by_ihlink = true
  ) then
    raise exception 'Subscription was not atomically upgraded';
  end if;

  if not exists (
    select 1 from public.schoolpro_schools
    where id = v_school and plan = 'professional' and status = 'active'
  ) then
    raise exception 'School plan was not updated while preserving active status';
  end if;

  if not exists (
    select 1 from public.schoolpro_subscription_payments
    where upgrade_request_id = v_request_id
      and school_id = v_school
      and subscription_id = v_subscription
      and payer_user_id = v_owner
      and amount = v_invoice_amount
      and status = 'credited'
  ) then
    raise exception 'Upgrade payment ledger entry is missing or inconsistent';
  end if;

  if not exists (
    select 1 from public.schoolpro_subscription_intents
    where id = v_invoice_id and status = 'paid'
  ) then
    raise exception 'Upgrade invoice was not marked paid';
  end if;

  if not exists (
    select 1 from public.direct_transfer_submissions
    where id = v_submission_id and status = 'approved'
  ) then
    raise exception 'Transfer submission was not approved';
  end if;

  -- Repeating the same approved settlement must be idempotent.
  v_repeat := private.review_school_subscription_transfer(
    v_submission_id, 'approved', 'Repeat settlement check'
  );

  if coalesce((v_repeat->>'already_settled')::boolean, false) is not true then
    raise exception 'Repeat settlement was not recognized as already settled: %',
      v_repeat;
  end if;

  raise notice 'PASS: request, prorated credit, approval, invoice, Finance settlement, ledger and idempotency';
end;
$upgrade_lifecycle$;

select 'PASS: annual upgrade end-to-end lifecycle' as result;

-- Negative-path coverage: rejection, stale quote, cancellation and duplicate reference.
do $upgrade_negative_paths$
declare
  v_owner uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  v_finance uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  v_school uuid := '11111111-1111-4111-8111-111111111111';
  v_subscription uuid := '22222222-2222-4222-8222-222222222222';
  v_catalog uuid := 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  v_bank uuid := 'ffffffff-ffff-4fff-8fff-ffffffffffff';
  v_request_id uuid;
  v_invoice_id uuid;
  v_submission_id uuid;
  v_request jsonb;
  v_result jsonb;
  v_error text;
begin
  insert into public.schoolpro_schools
    (id, owner_id, name, plan, status)
  values
    (v_school, v_owner, 'Synthetic Negative Path School', 'starter', 'active');

  insert into public.schoolpro_subscriptions
    (id, school_id, tier, billing_cycle, amount, status, starts_at, renews_at)
  values
    (v_subscription, v_school, 'starter', 'annual', 50000, 'active',
     clock_timestamp() - interval '180 days',
     clock_timestamp() + interval '185 days');

  -- Owner context.
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  perform set_config('request.test.active', 'true', true);
  perform set_config('request.test.admin_role', '', true);
  perform set_config('request.test.school_id', v_school::text, true);
  perform set_config('request.test.school_role', 'proprietor', true);

  -- 1. Rejection must not create an invoice.
  v_request := public.request_schoolpro_upgrade(v_school, v_catalog);
  v_request_id := (v_request->>'id')::uuid;

  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  perform set_config('request.test.admin_role', 'finance', true);

  v_result := public.review_schoolpro_upgrade(
    v_request_id, 'rejected', 'Synthetic rejection test', 1
  );

  if not exists (
    select 1 from public.schoolpro_upgrade_requests
    where id = v_request_id and status = 'rejected'
  ) or exists (
    select 1 from public.schoolpro_subscription_intents
    where upgrade_request_id = v_request_id
  ) then
    raise exception 'Rejection test failed: request state or invoice is incorrect';
  end if;

  -- 2. A changed source subscription must make the quote stale.
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  perform set_config('request.test.admin_role', '', true);

  v_request := public.request_schoolpro_upgrade(v_school, v_catalog);
  v_request_id := (v_request->>'id')::uuid;

  update public.schoolpro_subscriptions
     set amount = 51000
   where id = v_subscription;

  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  perform set_config('request.test.admin_role', 'finance', true);

  v_result := public.review_schoolpro_upgrade(
    v_request_id, 'approved', 'Synthetic stale quote test', 1
  );

  if not exists (
    select 1 from public.schoolpro_upgrade_requests
    where id = v_request_id and status = 'stale'
  ) or exists (
    select 1 from public.schoolpro_subscription_intents
    where upgrade_request_id = v_request_id
  ) then
    raise exception 'Stale quote test failed: stale request or invoice state is incorrect';
  end if;

  update public.schoolpro_subscriptions
     set amount = 50000
   where id = v_subscription;

  -- 3. The school billing manager can cancel a pending review.
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  perform set_config('request.test.admin_role', '', true);

  v_request := public.request_schoolpro_upgrade(v_school, v_catalog);
  v_request_id := (v_request->>'id')::uuid;

  v_result := public.cancel_schoolpro_upgrade(
    v_request_id, 'Synthetic pending cancellation'
  );

  if not exists (
    select 1 from public.schoolpro_upgrade_requests
    where id = v_request_id and status = 'cancelled'
  ) then
    raise exception 'Pending cancellation test failed';
  end if;

  -- 4. IHLink Finance can cancel an approved request and its pending invoice.
  v_request := public.request_schoolpro_upgrade(v_school, v_catalog);
  v_request_id := (v_request->>'id')::uuid;

  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  perform set_config('request.test.admin_role', 'finance', true);

  perform public.review_schoolpro_upgrade(
    v_request_id, 'approved', 'Synthetic approval before cancellation', 1
  );

  select id into v_invoice_id
    from public.schoolpro_subscription_intents
   where upgrade_request_id = v_request_id;

  if v_invoice_id is null then
    raise exception 'Approved cancellation test did not create an invoice';
  end if;

  perform public.cancel_schoolpro_upgrade(
    v_request_id, 'Synthetic approved cancellation'
  );

  if not exists (
    select 1 from public.schoolpro_upgrade_requests
    where id = v_request_id and status = 'cancelled'
  ) or not exists (
    select 1 from public.schoolpro_subscription_intents
    where id = v_invoice_id and status = 'cancelled'
  ) then
    raise exception 'Approved cancellation did not cancel both request and invoice';
  end if;

  -- 5. A previously reconciled bank reference must be rejected,
  -- including when case and surrounding whitespace differ.
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  perform set_config('request.test.admin_role', '', true);

  v_request := public.request_schoolpro_upgrade(v_school, v_catalog);
  v_request_id := (v_request->>'id')::uuid;

  perform set_config('request.jwt.claim.sub', v_finance::text, true);
  perform set_config('request.test.admin_role', 'finance', true);

  perform public.review_schoolpro_upgrade(
    v_request_id, 'approved', 'Synthetic duplicate reference test', 1
  );

  select id into v_invoice_id
    from public.schoolpro_subscription_intents
   where upgrade_request_id = v_request_id
     and status = 'pending';

  if v_invoice_id is null then
    raise exception 'Duplicate-reference test did not create a pending invoice';
  end if;

  insert into storage.objects(bucket_id, name)
  values ('direct-transfer-proofs', v_owner::text || '/duplicate-upgrade-receipt.png');

  v_submission_id := gen_random_uuid();

  insert into public.direct_transfer_submissions (
    id, user_id, platform_code, invoice_id, source_reference,
    bank_account_id, amount, sender_name, customer_reference,
    proof_storage_path, status
  )
  select
    v_submission_id, v_owner, 'schoolpro_subscription', i.id, i.reference,
    v_bank, i.amount, 'Synthetic Duplicate Payer',
    ' synthetic-upgrade-ref-001 ',
    v_owner::text || '/duplicate-upgrade-receipt.png',
    'awaiting_verification'
  from public.schoolpro_subscription_intents i
  where i.id = v_invoice_id;

  v_error := null;

  begin
    perform private.review_school_subscription_transfer(
      v_submission_id, 'approved', 'Synthetic duplicate reference rejection'
    );
  exception when others then
    v_error := sqlerrm;
  end;

  if v_error is null or v_error not like '%Bank reference already reconciled%' then
    raise exception 'Duplicate-reference test failed; received error: %', v_error;
  end if;

  if not exists (
    select 1 from public.direct_transfer_submissions
    where id = v_submission_id and status = 'awaiting_verification'
  ) or not exists (
    select 1 from public.schoolpro_subscription_intents
    where id = v_invoice_id and status = 'pending'
  ) or not exists (
    select 1 from public.schoolpro_upgrade_requests
    where id = v_request_id and status = 'approved'
  ) or not exists (
    select 1 from public.schoolpro_subscriptions
    where id = v_subscription and tier = 'starter'
  ) then
    raise exception 'Duplicate-reference rejection changed protected billing state';
  end if;

  raise notice 'PASS: rejection, stale quote, pending cancellation, approved cancellation and duplicate-reference rejection';
end;
$upgrade_negative_paths$;

select 'PASS: annual upgrade negative-path integration tests' as result;
