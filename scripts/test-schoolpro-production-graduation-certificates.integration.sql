-- Disposable PostgreSQL integration test for production graduation certificates.
-- Runs only in isolated CI PostgreSQL; never targets the connected Supabase project.
\set ON_ERROR_STOP on

create role anon nologin;
create role authenticated nologin;
create role service_role nologin;
create schema auth;
create schema private;

create type public.user_role as enum ('super_admin');
create table auth.users(id uuid primary key);
create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create table public.schoolpro_schools (
  id uuid primary key,
  name text not null
);
create table public.schoolpro_members (
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  user_id uuid not null references auth.users(id),
  role text not null
);
create table public.schoolpro_students (
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  status text not null,
  first_name text,
  last_name text
);
create table public.schoolpro_promotions (
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  student_id uuid not null references public.schoolpro_students(id),
  session text not null,
  decision text not null,
  status text not null
);
create table public.schoolpro_document_templates (
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  document_type text not null,
  is_active boolean not null default true
);
create table public.schoolpro_document_issues (
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  template_id uuid references public.schoolpro_document_templates(id),
  student_id uuid references public.schoolpro_students(id),
  document_type text not null,
  title text not null,
  serial_number text not null,
  payload jsonb not null default '{}'::jsonb,
  output_storage_path text,
  status text not null default 'draft' check (status in ('draft','issued','revoked')),
  issued_at timestamptz,
  issued_by uuid references auth.users(id)
);
create table public.schoolpro_document_issue_events (
  id bigint generated always as identity primary key,
  school_id uuid not null,
  issue_id uuid not null references public.schoolpro_document_issues(id),
  event_type text not null,
  actor_id uuid,
  snapshot jsonb not null
);

create or replace function private.is_admin(public.user_role[])
returns boolean language sql stable as $$ select false $$;
create or replace function public.schoolpro_member_can_manage(p_school uuid)
returns boolean language sql stable security definer set search_path=''
as $$
  select exists (
    select 1 from public.schoolpro_members m
    where m.school_id=p_school and m.user_id=auth.uid()
      and m.role in ('proprietor','administrator')
  )
$$;

insert into public.schoolpro_schools(id,name) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Graduation Fixture School'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','Other Fixture School');
insert into auth.users(id) values
 ('11111111-1111-4111-8111-111111111111'),
 ('22222222-2222-4222-8222-222222222222');
insert into public.schoolpro_members(id,school_id,user_id,role) values
 ('33333333-3333-4333-8333-333333333331','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111','registrar'),
 ('33333333-3333-4333-8333-333333333332','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','22222222-2222-4222-8222-222222222222','teacher');
insert into public.schoolpro_students(id,school_id,status,first_name,last_name) values
 ('44444444-4444-4444-8444-444444444441','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','graduated','Ada','Graduate'),
 ('44444444-4444-4444-8444-444444444442','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','active','Ben','Current'),
 ('44444444-4444-4444-8444-444444444443','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','graduated','Cross','School');
insert into public.schoolpro_promotions(id,school_id,student_id,session,decision,status) values
 ('55555555-5555-4555-8555-555555555551','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','44444444-4444-4444-8444-444444444441','2025/2026','graduated','applied'),
 ('55555555-5555-4555-8555-555555555552','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','44444444-4444-4444-8444-444444444441','2024/2025','graduated','pending');
insert into public.schoolpro_document_templates(id,school_id,document_type,is_active) values
 ('66666666-6666-4666-8666-666666666661','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','certificate',true),
 ('66666666-6666-4666-8666-666666666662','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','certificate',false),
 ('66666666-6666-4666-8666-666666666663','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','certificate',true);

\ir ../supabase/migrations/20261103110000_schoolpro_production_graduation_certificates.sql

-- A registrar can issue only for a graduated student with an applied decision,
-- a same-school active certificate template, and an explicit session.
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $test$
begin
  begin
    insert into public.schoolpro_document_issues(id,school_id,template_id,student_id,document_type,title,serial_number,payload)
    values ('77777777-7777-4777-8777-777777777771','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666661','44444444-4444-4444-8444-444444444442','certificate','Invalid active student','CERT-ACTIVE','{"session":"2025/2026"}');
    raise exception 'ASSERT: active student certificate unexpectedly created';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Only graduated students' in sqlerrm)=0 then raise; end if;
  end;
  begin
    insert into public.schoolpro_document_issues(id,school_id,template_id,student_id,document_type,title,serial_number,payload)
    values ('77777777-7777-4777-8777-777777777772','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666661','44444444-4444-4444-8444-444444444441','certificate','No applied graduation','CERT-PENDING','{"session":"2024/2025"}');
    raise exception 'ASSERT: pending graduation certificate unexpectedly created';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('An applied graduation decision' in sqlerrm)=0 then raise; end if;
  end;
  begin
    insert into public.schoolpro_document_issues(id,school_id,template_id,student_id,document_type,title,serial_number,payload)
    values ('77777777-7777-4777-8777-777777777773','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666662','44444444-4444-4444-8444-444444444441','certificate','Inactive template','CERT-INACTIVE','{"session":"2025/2026"}');
    raise exception 'ASSERT: inactive template unexpectedly accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('active certificate template' in sqlerrm)=0 then raise; end if;
  end;
  begin
    insert into public.schoolpro_document_issues(id,school_id,template_id,student_id,document_type,title,serial_number,payload)
    values ('77777777-7777-4777-8777-777777777774','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666663','44444444-4444-4444-8444-444444444441','certificate','Foreign template','CERT-FOREIGN','{"session":"2025/2026"}');
    raise exception 'ASSERT: foreign-school template unexpectedly accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('active certificate template' in sqlerrm)=0 then raise; end if;
  end;
  begin
    insert into public.schoolpro_document_issues(id,school_id,template_id,student_id,document_type,title,serial_number,payload)
    values ('77777777-7777-4777-8777-777777777775','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666661','44444444-4444-4444-8444-444444444441','certificate','Missing session','CERT-NO-SESSION','{}');
    raise exception 'ASSERT: missing graduation session unexpectedly accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('graduation session is required' in sqlerrm)=0 then raise; end if;
  end;
end
$test$;

-- Unauthorized staff cannot even create a certificate draft.
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',false);
do $test$
begin
  begin
    insert into public.schoolpro_document_issues(id,school_id,template_id,student_id,document_type,title,serial_number,payload)
    values ('77777777-7777-4777-8777-777777777776','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666661','44444444-4444-4444-8444-444444444441','certificate','Unauthorized','CERT-UNAUTH','{"session":"2025/2026"}');
    raise exception 'ASSERT: unauthorized staff unexpectedly created a certificate';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Not authorized to issue graduation certificates' in sqlerrm)=0 then raise; end if;
  end;
end
$test$;

-- Valid registrar issuance records actor identity and immutable lifecycle event.
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
insert into public.schoolpro_document_issues(id,school_id,template_id,student_id,document_type,title,serial_number,payload)
values ('77777777-7777-4777-8777-777777777777','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666661','44444444-4444-4444-8444-444444444441','certificate','Graduation Certificate','CERT-VALID','{"session":"2025/2026"}');
do $test$
begin
  begin
    perform public.finalize_schoolpro_document_issue('77777777-7777-4777-8777-777777777777','wrong-school/generated/certificate.pdf');
    raise exception 'ASSERT: invalid storage path unexpectedly accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Invalid output path' in sqlerrm)=0 then raise; end if;
  end;
end
$test$;
select public.finalize_schoolpro_document_issue(
  '77777777-7777-4777-8777-777777777777',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/generated/certificate.pdf'
);
do $test$
begin
  if not exists (
    select 1 from public.schoolpro_document_issues
    where id='77777777-7777-4777-8777-777777777777'
      and status='issued'
      and issued_by='11111111-1111-4111-8111-111111111111'
      and output_storage_path='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/generated/certificate.pdf'
  ) then raise exception 'Certificate finalization did not persist issuer and output path'; end if;
  if not exists (
    select 1 from public.schoolpro_document_issue_events
    where issue_id='77777777-7777-4777-8777-777777777777'
      and event_type='issued'
      and actor_id='11111111-1111-4111-8111-111111111111'
  ) then raise exception 'Certificate issuance event was not recorded'; end if;
end
$test$;

-- Non-certificate document issuance remains compatible with the generic lifecycle.
insert into public.schoolpro_document_issues(id,school_id,template_id,student_id,document_type,title,serial_number,payload)
values ('77777777-7777-4777-8777-777777777778','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',null,null,'admission_letter','Admission Letter','DOC-GENERIC','{}');
select public.finalize_schoolpro_document_issue(
  '77777777-7777-4777-8777-777777777778',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/generated/admission.pdf'
);
do $test$
begin
  if not exists(select 1 from public.schoolpro_document_issues where id='77777777-7777-4777-8777-777777777778' and status='issued') then
    raise exception 'Generic document issuance regressed';
  end if;
  if (select count(*) from public.schoolpro_document_issue_events where event_type='issued') <> 2 then
    raise exception 'Expected exactly two audited issuance events';
  end if;
end
$test$;

\echo 'PASS: graduation-certificate eligibility, authorization, session and template validation, finalization audit, and generic document compatibility.';
