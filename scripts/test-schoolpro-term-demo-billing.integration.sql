\set ON_ERROR_STOP on

-- Disposable PostgreSQL only. Exercises the active term-Demo billing boundary.

create role anon nologin;
create role authenticated nologin;
create role service_role nologin;

create schema auth;
create schema private;
create schema storage;

create table auth.users (id uuid primary key);
create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create or replace function private.is_active_account()
returns boolean language sql stable
as $$ select coalesce(current_setting('request.test.active', true), 'true') = 'true' $$;

create type public.school_member_role as enum ('proprietor','administrator','bursar','teacher');

create table public.schoolpro_schools (
  id uuid primary key,
  owner_id uuid not null references auth.users(id),
  status text not null default 'active'
);
create table public.schoolpro_members (
  school_id uuid not null references public.schoolpro_schools(id),
  user_id uuid not null references auth.users(id),
  role public.school_member_role not null,
  primary key (school_id,user_id)
);
create table public.schoolpro_subscription_catalog (
  id uuid primary key,
  code text not null,
  annual_price numeric(14,2),
  active boolean not null default true
);
create table public.schoolpro_subscriptions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null unique references public.schoolpro_schools(id),
  tier text not null,
  billing_cycle text not null,
  amount numeric(14,2) not null,
  status text not null,
  renews_at timestamptz
);
create table public.schoolpro_demo_requests (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id),
  status text not null,
  activated_at timestamptz,
  free_access_ends_at timestamptz
);
create table public.schoolpro_subscription_intents (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id),
  payer_user_id uuid not null references auth.users(id),
  catalog_id uuid not null references public.schoolpro_subscription_catalog(id),
  billing_cycle text not null,
  amount numeric(14,2) not null,
  virtual_account_id uuid,
  reference text not null unique,
  status text not null,
  transaction_ref text,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  payment_method text not null,
  invoice_kind text not null default 'subscription',
  demo_request_id uuid
);
create unique index schoolpro_one_pending_invoice_per_school
  on public.schoolpro_subscription_intents(school_id) where status='pending';

create table public.ihlink_bank_accounts (id uuid primary key, is_active boolean not null default true);
create table public.direct_transfer_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  platform_code text not null,
  invoice_id uuid not null references public.schoolpro_subscription_intents(id),
  status text not null default 'awaiting_verification'
);
create table storage.objects (bucket_id text not null, name text not null);

grant usage on schema private to authenticated;

\ir ../supabase/migrations/20261114203000_schoolpro_term_demo_billing_guards.sql

insert into auth.users(id) values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
insert into public.schoolpro_schools(id,owner_id,status)
values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','active');
insert into public.schoolpro_subscription_catalog(id,code,annual_price,active)
values ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','starter',50000,true);
insert into public.ihlink_bank_accounts(id,is_active)
values ('dddddddd-dddd-4ddd-8ddd-dddddddddddd',true);

select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false);
select set_config('request.test.active','true',false);

-- Before Demo activation, a normal annual invoice can be prepared.
do $$
declare v jsonb;
begin
  v := public.prepare_schoolpro_bank_subscription(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
  );
  if v->>'status' <> 'pending' then
    raise exception 'Expected a pending annual invoice before Demo activation: %',v;
  end if;
end;
$$;

-- A pending invoice created before activation cannot be settled during Demo.
insert into public.schoolpro_subscriptions(
  school_id,tier,billing_cycle,amount,status,renews_at
) values (
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','starter','termly',0,'active',now()+interval '30 days'
);
insert into public.schoolpro_demo_requests(
  school_id,status,activated_at,free_access_ends_at
) values (
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','completed',now(),now()+interval '30 days'
);

do $$
declare v_error text;
begin
  begin
    perform public.prepare_schoolpro_bank_subscription(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
    );
  exception when others then v_error := sqlerrm;
  end;
  if v_error is null or v_error not like '%unavailable until the active term Demo ends%' then
    raise exception 'Active Demo did not block invoice preparation: %',v_error;
  end if;
end;
$$;

do $$
declare v_error text;
begin
  begin
    insert into public.schoolpro_subscription_intents(
      school_id,payer_user_id,catalog_id,billing_cycle,amount,reference,status,payment_method
    ) values (
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      'annual',50000,'ACTIVE-DEMO-DIRECT-INSERT','pending','bank_transfer'
    );
  exception when others then v_error := sqlerrm;
  end;
  if v_error is null or v_error not like '%unavailable during an active term Demo%' then
    raise exception 'Active Demo did not block direct invoice creation: %',v_error;
  end if;
end;
$$;

do $$
declare v_invoice uuid; v_error text;
begin
  select id into v_invoice from public.schoolpro_subscription_intents
   where school_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' and status='pending';
  begin
    update public.schoolpro_subscription_intents set status='paid' where id=v_invoice;
  exception when others then v_error := sqlerrm;
  end;
  if v_error is null or v_error not like '%unavailable during an active term Demo%' then
    raise exception 'Active Demo did not block Finance settlement: %',v_error;
  end if;
end;
$$;

do $$
declare v_invoice uuid; v_error text;
begin
  select id into v_invoice from public.schoolpro_subscription_intents
   where school_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' and status='pending';
  begin
    insert into public.direct_transfer_submissions(user_id,platform_code,invoice_id)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','schoolpro_subscription',v_invoice);
  exception when others then v_error := sqlerrm;
  end;
  if v_error is null or v_error not like '%cannot be submitted during an active term Demo%' then
    raise exception 'Active Demo did not block receipt submission: %',v_error;
  end if;
end;
$$;

-- Once the approved Demo period expires, billing and settlement resume.
update public.schoolpro_demo_requests
set free_access_ends_at=now()-interval '1 second';
update public.schoolpro_subscriptions
set status='suspended',renews_at=now()-interval '1 second'
where school_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

do $$
declare v jsonb;
begin
  v := public.prepare_schoolpro_bank_subscription(
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
  );
  if v->>'status' <> 'pending' then
    raise exception 'Billing did not resume after Demo expiry: %',v;
  end if;
end;
$$;

select 'PASS: term Demo suppresses annual invoice creation, receipt submission and Finance settlement until expiry' as result;
