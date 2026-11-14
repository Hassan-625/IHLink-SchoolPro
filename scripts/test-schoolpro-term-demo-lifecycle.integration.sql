\set ON_ERROR_STOP on

-- Disposable PostgreSQL only. Exercises the existing term-Demo lifecycle and
-- the exact paid-annual grace migration; never run against hosted Supabase.

create role anon nologin;
create role authenticated nologin;
create role service_role nologin;

create schema auth;
create schema private;
create schema storage;

create type public.user_role as enum ('super_admin','finance','customer');
create type public.school_member_role as enum ('proprietor','administrator','bursar');
create type public.school_status as enum ('active','trial','suspended');

create table auth.users (id uuid primary key);
create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create or replace function private.is_active_account()
returns boolean language sql stable
as $$ select coalesce(current_setting('request.test.active', true), 'true') = 'true' $$;

create or replace function private.has_product_access(p_product text,p_action text)
returns boolean language sql stable
as $$ select coalesce(current_setting('request.test.approve', true), 'false')='true' and p_product='schoolpro' and p_action='approve' $$;

create or replace function private.is_admin(p_roles public.user_role[])
returns boolean language sql stable
as $$ select coalesce(current_setting('request.test.admin_role', true),'') = any(select unnest(p_roles)::text) $$;

create table public.schoolpro_schools (
  id uuid primary key,
  owner_id uuid not null references auth.users(id),
  name text not null,
  code text not null,
  plan text not null,
  status public.school_status not null default 'trial'
);
create table public.schoolpro_members (
  school_id uuid not null references public.schoolpro_schools(id),
  user_id uuid not null references auth.users(id),
  role public.school_member_role not null,
  primary key(school_id,user_id)
);
create table public.schoolpro_students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id),
  user_id uuid
);
create table public.schoolpro_guardian_links (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id),
  guardian_user_id uuid not null references auth.users(id),
  status text not null
);
create or replace function public.schoolpro_member_can_manage(p_school uuid)
returns boolean language sql stable
as $$ select false $$;

create table public.schoolpro_subscriptions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null unique references public.schoolpro_schools(id),
  tier text not null,
  billing_cycle text not null,
  amount numeric(14,2) not null,
  status text not null,
  starts_at timestamptz not null default now(),
  renews_at timestamptz,
  managed_by_ihlink boolean not null default false,
  customization_level text not null default 'standard',
  updated_at timestamptz not null default now()
);
create table public.schoolpro_demo_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  school_id uuid references public.schoolpro_schools(id),
  school_name text not null,
  contact_name text not null,
  email text not null,
  phone text,
  meeting_format text,
  status text not null,
  notes text,
  activated_at timestamptz,
  free_access_ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.schoolpro_onboarding_requests (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  school_id uuid not null references public.schoolpro_schools(id),
  school_name text not null,
  contact_name text not null,
  email text not null,
  phone text,
  plan_key text,
  status text not null,
  updated_at timestamptz not null default now()
);
create table public.schoolpro_plan_catalog (
  tier text primary key,
  features jsonb not null default '{}'::jsonb
);
create table public.schoolpro_feature_overrides (
  school_id uuid not null references public.schoolpro_schools(id),
  feature text not null,
  enabled boolean not null,
  primary key(school_id,feature)
);
create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid,
  action text not null,
  product text,
  target_type text,
  target_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false,
  file_size_limit bigint,
  allowed_mime_types text[]
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null,
  name text not null,
  unique(bucket_id,name)
);
alter table storage.objects enable row level security;
create or replace function storage.foldername(p_name text)
returns text[] language sql immutable
as $$ select case when position('/' in p_name)>0 then string_to_array(regexp_replace(p_name,'/[^/]*$',''),'/') else '{}'::text[] end $$;

grant usage on schema private,storage to authenticated;
grant select,insert on storage.objects to authenticated;
grant execute on function storage.foldername(text) to authenticated;

create or replace function public.request_schoolpro_workspace_demo(p_request uuid,p_tier text default 'starter')
returns jsonb language plpgsql security definer set search_path=''
as $$
declare r public.schoolpro_onboarding_requests%rowtype; did uuid;
begin
  select * into r from public.schoolpro_onboarding_requests where id=p_request for update;
  if r.id is null or r.user_id is distinct from auth.uid() or r.status not in ('approved','provisioning') then
    raise exception 'Approved school owner request required';
  end if;
  select id into did from public.schoolpro_demo_requests where school_id=r.school_id and user_id=auth.uid() order by created_at limit 1;
  if did is null then
    insert into public.schoolpro_demo_requests(user_id,school_id,school_name,contact_name,email,phone,meeting_format,status,notes)
    values(r.user_id,r.school_id,r.school_name,r.contact_name,r.email,r.phone,'online','new','Calendar-reviewed term Demo')
    returning id into did;
  end if;
  update public.schoolpro_onboarding_requests set status='provisioning',plan_key=p_tier,updated_at=now() where id=r.id;
  return jsonb_build_object('school_id',r.school_id,'demo_request_id',did,'status','awaiting_admin_activation');
end;
$$;

create or replace function public.control_center_activate_schoolpro(p_school uuid,p_tier text default 'starter',p_reason text default null)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_end timestamptz;
begin
  if not coalesce(private.has_product_access('schoolpro','approve'),false) then raise exception 'SchoolPro approval access required'; end if;
  if length(trim(coalesce(p_reason,'')))<3 then raise exception 'Activation reason required'; end if;
  insert into public.schoolpro_subscriptions(school_id,tier,billing_cycle,amount,status,starts_at,renews_at,managed_by_ihlink,updated_at)
  values(p_school,p_tier,'annual',0,'active',now(),now()+interval '1 year',true,now())
  on conflict(school_id) do update set tier=excluded.tier,billing_cycle=excluded.billing_cycle,amount=0,status='active',starts_at=now(),renews_at=excluded.renews_at,managed_by_ihlink=true,updated_at=now()
  returning renews_at into v_end;
  update public.schoolpro_schools set status='active',plan=p_tier where id=p_school;
  return jsonb_build_object('status','active','school_id',p_school,'tier',p_tier,'renews_at',v_end);
end;
$$;

grant execute on function public.request_schoolpro_workspace_demo(uuid,text) to authenticated;
grant execute on function public.control_center_activate_schoolpro(uuid,text,text) to authenticated;

\ir ../supabase/migrations/20261008214000_calendar_reviewed_term_demo.sql
\ir ../supabase/migrations/20261008221500_paid_annual_grace.sql

insert into public.schoolpro_plan_catalog(tier,features)
values('starter','{"cbt":false,"advanced_reports":false,"custom_branding":false}'::jsonb);

insert into auth.users(id) values
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
('cccccccc-cccc-4ccc-8ccc-cccccccccccc');

insert into public.schoolpro_schools(id,owner_id,name,code,plan,status) values
('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Term Demo School','SP-DEMO-001','starter','trial'),
('22222222-2222-4222-8222-222222222222','cccccccc-cccc-4ccc-8ccc-cccccccccccc','Annual Grace School','SP-GRACE-001','starter','active');

insert into public.schoolpro_members(school_id,user_id,role) values
('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','proprietor'),
('22222222-2222-4222-8222-222222222222','cccccccc-cccc-4ccc-8ccc-cccccccccccc','proprietor');

insert into public.schoolpro_onboarding_requests(id,user_id,school_id,school_name,contact_name,email,phone,plan_key,status) values
('33333333-3333-4333-8333-333333333333','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111','Term Demo School','Owner','owner@example.test','08000000000','starter','approved');

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('schoolpro-demo-documents','schoolpro-demo-documents',false,10485760,array['application/pdf','image/jpeg','image/png'])
on conflict(id) do nothing;

select set_config('request.test.active','true',false);
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false);

-- RLS allows the owner to upload only into their own folder.
set role authenticated;
insert into storage.objects(bucket_id,name) values
('schoolpro-demo-documents','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/calendar.pdf'),
('schoolpro-demo-documents','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/letter.pdf');

do $$
declare v_error text;
begin
  begin
    insert into storage.objects(bucket_id,name)
    values('schoolpro-demo-documents','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/foreign.pdf');
  exception when insufficient_privilege then v_error:=sqlerrm;
  end;
  if v_error is null then raise exception 'A user uploaded a Demo document outside their own folder'; end if;
end;
$$;

select set_config('request.jwt.claim.sub','cccccccc-cccc-4ccc-8ccc-cccccccccccc',false);
do $$
declare n integer;
begin
  select count(*) into n from storage.objects where bucket_id='schoolpro-demo-documents';
  if n<>0 then raise exception 'Unrelated authenticated user read another owner’s Demo documents'; end if;
end;
$$;

select set_config('request.test.approve','true',false);
do $$
declare n integer;
begin
  select count(*) into n from storage.objects where bucket_id='schoolpro-demo-documents';
  if n<>2 then raise exception 'Authorized reviewer could not read both Demo documents'; end if;
end;
$$;
reset role;

-- Term-date boundary and document ownership checks.
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false);
do $$
declare v_error text; d date:=current_date;
begin
  begin
    perform public.submit_schoolpro_term_demo(
      '33333333-3333-4333-8333-333333333333','starter',
      d,(d+interval '2 months')::date,(d+interval '1 month')::date,(d+interval '1 month')::date,
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/calendar.pdf',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/letter.pdf'
    );
  exception when others then v_error:=sqlerrm;
  end;
  if v_error is null or v_error not like '%at least three months%' then
    raise exception 'Short term was not rejected: %',v_error;
  end if;

  v_error:=null;
  begin
    perform public.submit_schoolpro_term_demo(
      '33333333-3333-4333-8333-333333333333','starter',
      d,(d+interval '3 months')::date,(d+interval '1 month')::date,(d+interval '4 months')::date,
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/calendar.pdf',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/letter.pdf'
    );
  exception when others then v_error:=sqlerrm;
  end;
  if v_error is null or v_error not like '%exams inside the term%' then
    raise exception 'Out-of-term exam dates were not rejected: %',v_error;
  end if;

  v_error:=null;
  begin
    perform public.submit_schoolpro_term_demo(
      '33333333-3333-4333-8333-333333333333','starter',
      d,(d+interval '3 months')::date,(d+interval '1 month')::date,(d+interval '2 months')::date,
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/foreign.pdf',
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/letter.pdf'
    );
  exception when others then v_error:=sqlerrm;
  end;
  if v_error is null or v_error not like '%Upload your calendar and request letter%' then
    raise exception 'Foreign document path was not rejected: %',v_error;
  end if;
end;
$$;

-- Exactly three months is accepted; access end is the later of term end + 1
-- day and exam end + 15 days in Africa/Lagos local time.
do $$
declare d date:=current_date; v jsonb; v_demo uuid;
begin
  v:=public.submit_schoolpro_term_demo(
    '33333333-3333-4333-8333-333333333333','starter',
    d,(d+interval '3 months')::date,(d+interval '2 months')::date,(d+interval '3 months' - interval '1 day')::date,
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/calendar.pdf',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/33333333-3333-4333-8333-333333333333/letter.pdf'
  );
  v_demo:=(v->>'demo_request_id')::uuid;
  if v_demo is null or v->>'status'<>'awaiting_calendar_review' then
    raise exception 'Valid term Demo was not submitted for review: %',v;
  end if;
  if not exists(select 1 from public.schoolpro_demo_requests where id=v_demo and term_start=d and term_end=(d+interval '3 months')::date and status='new') then
    raise exception 'Validated term dates were not saved to the Demo request';
  end if;
end;
$$;

-- Independent reviewer activates once, with the exact term/exam end calculation.
select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',false);
select set_config('request.test.approve','true',false);
do $$
declare d public.schoolpro_demo_requests%rowtype; v jsonb; expected timestamptz;
begin
  select * into d from public.schoolpro_demo_requests where school_id='11111111-1111-4111-8111-111111111111';
  expected:=greatest((d.term_end+1)::timestamp at time zone 'Africa/Lagos',(d.exam_end+15)::timestamp at time zone 'Africa/Lagos');
  v:=public.activate_schoolpro_demo(d.school_id,'starter',1,'Calendar and request letter verified');
  if v->>'source'<>'calendar_demo' then raise exception 'Calendar-reviewed activation source was not recorded: %',v; end if;
  if not exists(select 1 from public.schoolpro_demo_requests where id=d.id and status='completed' and activated_at is not null and reviewed_by=auth.uid() and free_access_ends_at=expected) then
    raise exception 'Demo activation did not persist reviewer, completion, and calculated expiry';
  end if;
  if not exists(select 1 from public.schoolpro_subscriptions where school_id=d.school_id and status='active' and amount=0 and billing_cycle='termly' and renews_at=expected) then
    raise exception 'Demo activation did not create the zero-value term subscription with correct expiry';
  end if;
  if not exists(select 1 from public.schoolpro_onboarding_requests where school_id=d.school_id and status='active') then
    raise exception 'Demo activation did not activate the approved onboarding request';
  end if;
end;
$$;

do $$
declare v_error text; d public.schoolpro_demo_requests%rowtype;
begin
  select * into d from public.schoolpro_demo_requests where school_id='11111111-1111-4111-8111-111111111111';
  begin
    perform public.activate_schoolpro_demo(d.school_id,'starter',1,'Attempt a second activation');
  exception when others then v_error:=sqlerrm;
  end;
  if v_error is null or v_error not like '%already used its demo%' then
    raise exception 'A second Demo activation was not rejected: %',v_error;
  end if;
end;
$$;

-- The existing expiry worker suspends term Demo exactly at its end timestamp.
update public.schoolpro_subscriptions
set renews_at=now()-interval '1 second'
where school_id='11111111-1111-4111-8111-111111111111';
update public.schoolpro_demo_requests
set free_access_ends_at=now()-interval '1 second'
where school_id='11111111-1111-4111-8111-111111111111';
do $$
declare n integer;
begin
  n:=private.enforce_schoolpro_subscription_expiry();
  if n<>1 then raise exception 'Expiry worker did not suspend the expired term Demo; changed rows=%',n; end if;
  if not exists(select 1 from public.schoolpro_subscriptions where school_id='11111111-1111-4111-8111-111111111111' and status='suspended') then
    raise exception 'Expired term Demo subscription remained active';
  end if;
end;
$$;

-- Paid annual subscriptions retain access through day 14, then suspend.
insert into public.schoolpro_subscriptions(
  school_id,tier,billing_cycle,amount,status,renews_at,managed_by_ihlink
) values (
  '22222222-2222-4222-8222-222222222222','starter','annual',50000,'active',now()-interval '13 days',true
);

select set_config('request.jwt.claim.sub','cccccccc-cccc-4ccc-8ccc-cccccccccccc',false);
do $$
declare e jsonb;
begin
  if not private.schoolpro_operationally_active('22222222-2222-4222-8222-222222222222') then
    raise exception 'Paid annual subscription lost access before the 14-day grace ended';
  end if;
  e:=public.schoolpro_subscription_entitlements('22222222-2222-4222-8222-222222222222');
  if coalesce((e->>'active')::boolean,false) is not true
     or coalesce((e->>'in_grace')::boolean,false) is not true then
    raise exception 'Subscription entitlements did not expose the paid annual grace state: %',e;
  end if;
end;
$$;

update public.schoolpro_subscriptions
set renews_at=now()-interval '15 days'
where school_id='22222222-2222-4222-8222-222222222222';
do $$
declare n integer; e jsonb;
begin
  if private.schoolpro_operationally_active('22222222-2222-4222-8222-222222222222') then
    raise exception 'Paid annual subscription remained operational after the 14-day grace';
  end if;
  e:=public.schoolpro_subscription_entitlements('22222222-2222-4222-8222-222222222222');
  if coalesce((e->>'active')::boolean,true) is not false then
    raise exception 'Subscription entitlements remained active after the 14-day grace: %',e;
  end if;
  n:=private.enforce_schoolpro_subscription_expiry();
  if n<>1 then raise exception 'Expiry worker did not suspend the post-grace paid annual subscription; changed rows=%',n; end if;
end;
$$;

select 'PASS: term-Demo upload ownership, date boundaries, one-time activation, expiry, and paid annual 14-day grace' as result;
