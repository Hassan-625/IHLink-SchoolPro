\set ON_ERROR_STOP on

-- Disposable PostgreSQL only: teacher/Form Master -> Section Head ->
-- independent Exam Officer, with request snapshots and audit history.

create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;
create type public.user_role as enum ('super_admin');
create table auth.users(id uuid primary key);

create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
grant usage on schema auth to authenticated;
grant execute on function auth.uid() to authenticated;

create table public.schoolpro_members (
  id uuid primary key,
  school_id uuid not null,
  user_id uuid not null,
  role text not null,
  status text not null default 'active'
);
create table public.schoolpro_member_responsibilities (
  school_id uuid not null,
  member_id uuid not null,
  responsibility text not null,
  ended_at timestamptz
);
create table public.schoolpro_classes (
  id uuid primary key,
  school_id uuid not null,
  level text not null,
  form_teacher_id uuid
);
create table public.schoolpro_section_leaders (
  school_id uuid not null,
  member_id uuid not null,
  section text not null,
  ended_at timestamptz
);
create table public.schoolpro_subject_assignments (
  school_id uuid not null,
  teacher_member_id uuid not null,
  class_id uuid not null,
  session text not null,
  ended_at timestamptz
);
create table public.schoolpro_students (
  id uuid primary key,
  school_id uuid not null,
  class_id uuid not null
);
create table public.schoolpro_enrollment_history (
  school_id uuid not null,
  student_id uuid not null,
  class_id uuid not null,
  session text not null,
  created_at timestamptz not null default now()
);
create table public.schoolpro_results (
  id uuid primary key,
  school_id uuid not null,
  student_id uuid not null,
  term text not null,
  session text not null,
  status text not null,
  locked boolean not null default true,
  updated_at timestamptz not null default now()
);
create table public.schoolpro_result_correction_batches (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  scope text not null check(scope in ('class','section')),
  class_id uuid,
  section text,
  term text not null,
  session text not null,
  reason text not null,
  requested_by uuid not null,
  status text not null default 'pending'
    check(status in ('pending','approved','rejected')),
  reviewed_by uuid,
  reviewed_at timestamptz,
  review_notes text,
  created_at timestamptz not null default now(),
  check((scope='class' and class_id is not null and section is null)
     or (scope='section' and class_id is null and section is not null))
);
create table public.schoolpro_result_correction_batch_items (
  batch_id uuid not null references public.schoolpro_result_correction_batches(id),
  result_id uuid not null references public.schoolpro_results(id),
  primary key(batch_id,result_id)
);
create table public.schoolpro_audit_logs (
  id bigint generated always as identity primary key,
  school_id uuid not null,
  actor_id uuid not null,
  action text not null,
  entity_type text not null,
  entity_id uuid not null,
  metadata jsonb not null default '{}'::jsonb
);

create or replace function private.is_admin(p_roles public.user_role[])
returns boolean language sql stable
as $ select auth.uid()='66666666-6666-4666-8666-666666666666'::uuid $;
create or replace function private.is_active_account()
returns boolean language sql stable
as $$ select auth.uid() is not null $$;
create or replace function private.schoolpro_module_allowed(p_school uuid,p_module text)
returns boolean language sql stable
as $$ select true $$;
create or replace function private.schoolpro_member_has_responsibility(p_school uuid,p_responsibility text)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.schoolpro_members m
  join public.schoolpro_member_responsibilities r
   on r.school_id=m.school_id and r.member_id=m.id and r.ended_at is null
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
    and r.responsibility=p_responsibility)
$$;
create or replace function private.schoolpro_member_leads_class(p_school uuid,p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(
  select 1 from public.schoolpro_members m
  join public.schoolpro_section_leaders sl
   on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
  join public.schoolpro_classes c
   on c.school_id=p_school and c.id=p_class and c.level=sl.section
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
    and ((sl.section in ('nursery','primary') and m.role='head_teacher')
      or (sl.section in ('junior_secondary','senior_secondary')
        and m.role in ('vice_principal','administrator')))
 )
$$;
create or replace function private.schoolpro_is_exam_officer(p_school uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.schoolpro_members m
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
    and m.role='exam_officer')
  or private.schoolpro_member_has_responsibility(p_school,'exam_officer')
$$;
create or replace function private.schoolpro_is_school_admin(p_school uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select private.schoolpro_member_has_responsibility(p_school,'school_admin')
$$;

grant usage on schema private to authenticated;
grant execute on all functions in schema private to authenticated;

alter table public.schoolpro_result_correction_batches enable row level security;
alter table public.schoolpro_result_correction_batch_items enable row level security;
grant select on public.schoolpro_result_correction_batches,
  public.schoolpro_result_correction_batch_items,
  public.schoolpro_classes to authenticated;
grant select on public.schoolpro_results,public.schoolpro_audit_logs to authenticated;

create policy schoolpro_result_correction_batches_exam_officer_read
on public.schoolpro_result_correction_batches for select to authenticated
using(private.schoolpro_is_exam_officer(school_id)
  or private.schoolpro_is_school_admin(school_id));
create policy schoolpro_result_correction_batch_items_exam_officer_read
on public.schoolpro_result_correction_batch_items for select to authenticated
using(exists(select 1 from public.schoolpro_result_correction_batches b
  where b.id=batch_id and (private.schoolpro_is_exam_officer(b.school_id)
    or private.schoolpro_is_school_admin(b.school_id))));
create policy schoolpro_result_correction_batches_requester_read
on public.schoolpro_result_correction_batches for select to authenticated
using(requested_by=auth.uid());

insert into public.schoolpro_members(id,school_id,user_id,role) values
 ('10000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111','teacher'),
 ('10000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','22222222-2222-4222-8222-222222222222','class_teacher'),
 ('10000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','33333333-3333-4333-8333-333333333333','head_teacher'),
 ('10000000-0000-4000-8000-000000000004','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','44444444-4444-4444-8444-444444444444','head_teacher'),
 ('10000000-0000-4000-8000-000000000005','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','55555555-5555-4555-8555-555555555555','exam_officer'),
 ('10000000-0000-4000-8000-000000000006','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666666','administrator');
insert into auth.users(id) values
 ('11111111-1111-4111-8111-111111111111'),
 ('22222222-2222-4222-8222-222222222222'),
 ('33333333-3333-4333-8333-333333333333'),
 ('44444444-4444-4444-8444-444444444444'),
 ('55555555-5555-4555-8555-555555555555'),
 ('66666666-6666-4666-8666-666666666666');

insert into public.schoolpro_classes(id,school_id,level,form_teacher_id) values
 ('20000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','primary','10000000-0000-4000-8000-000000000002'),
 ('20000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','nursery',null);
insert into public.schoolpro_section_leaders(school_id,member_id,section) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000003','primary'),
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000004','nursery');
insert into public.schoolpro_subject_assignments(school_id,teacher_member_id,class_id,session) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','2025/2026');
insert into public.schoolpro_students(id,school_id,class_id) values
 ('30000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001');
insert into public.schoolpro_enrollment_history(school_id,student_id,class_id,session) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','2025/2026');
insert into public.schoolpro_results(id,school_id,student_id,term,session,status,locked) values
 ('40000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001','First Term','2025/2026','published',true),
 ('40000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001','Second Term','2025/2026','published',true);

\ir ../supabase/migrations/20261114222000_schoolpro_result_correction_section_review.sql

set role authenticated;

-- Subject Teacher requests class reopening: queue belongs to the Section Head.
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
select public.schoolpro_request_result_reopening(
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','class',
 '20000000-0000-4000-8000-000000000001',null,
 'First Term','2025/2026','Correct the uploaded subject marks'
) as teacher_request \gset
select set_config('test.teacher_request', :'teacher_request', false);

do $test$
begin
 if (select status from public.schoolpro_result_correction_batches
     where id=current_setting('test.teacher_request')::uuid) <> 'pending_section_review' then
   raise exception 'Teacher request skipped Section Head review';
 end if;
 if (select count(*) from public.schoolpro_result_correction_batches
     where id=current_setting('test.teacher_request')::uuid) <> 1 then
   raise exception 'Requester cannot track their own correction request';
 end if;
end
$test$;

-- Unassigned section leader cannot read or review the Primary request.
select set_config('request.jwt.claim.sub','44444444-4444-4444-8444-444444444444',false);
do $test$
begin
 if exists(select 1 from public.schoolpro_result_correction_batches
   where id=current_setting('test.teacher_request')::uuid) then
   raise exception 'Unassigned Section Head read another section correction request';
 end if;
 begin
   perform public.schoolpro_review_result_reopening(current_setting('test.teacher_request')::uuid,true,null);
   raise exception 'Unassigned Section Head unexpectedly reviewed request';
 exception when others then
   if sqlerrm not like '%Only the appointed Section Head%' then raise; end if;
 end;
end
$test$;

-- Assigned Section Head sees and forwards it to the Exam Officer.
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',false);
do $test$
begin
 if not exists(select 1 from public.schoolpro_result_correction_batches
   where id=current_setting('test.teacher_request')::uuid and status='pending_section_review') then
   raise exception 'Assigned Section Head cannot see its pending correction queue';
 end if;
end
$test$;
select public.schoolpro_review_result_reopening(current_setting('test.teacher_request')::uuid,true,'Checked the section request') as forwarded;
do $test$
begin
 if (select status from public.schoolpro_result_correction_batches
     where id=current_setting('test.teacher_request')::uuid) <> 'pending_exam_officer' then
   raise exception 'Section Head did not forward request to Exam Officer';
 end if;
end
$test$;

-- Neither the original requester nor the Section Head reviewer can authorize reopening.
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $test$
begin
 begin
  perform public.schoolpro_decide_result_reopening(current_setting('test.teacher_request')::uuid,true,null);
  raise exception 'Requester unexpectedly authorized their own reopening';
 exception when others then
  if sqlerrm not like '%requester and Section Head reviewer%' then raise; end if;
 end;
end
$test$;
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',false);
do $test$
begin
 begin
  perform public.schoolpro_decide_result_reopening(current_setting('test.teacher_request')::uuid,true,null);
  raise exception 'Section Head reviewer unexpectedly authorized final reopening';
 exception when others then
  if sqlerrm not like '%requester and Section Head reviewer%' then raise; end if;
 end;
end
$test$;

-- A global Super Admin remains a school administrator but is not an Exam Officer.
select set_config('request.jwt.claim.sub','66666666-6666-4666-8666-666666666666',false);
do $test$
begin
 if private.is_admin(array['super_admin']::public.user_role[]) is not true then
   raise exception 'Super Admin fixture is not recognized as a global administrator';
 end if;
 if private.schoolpro_is_exam_officer('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then
   raise exception 'Super Admin inherited Exam Officer authority without appointment';
 end if;
 begin
  perform public.schoolpro_decide_result_reopening(current_setting('test.teacher_request')::uuid,true,'Unauthorized global override');
  raise exception 'Super Admin unexpectedly authorized result reopening';
 exception when others then
  if sqlerrm not like '%Only the Exam Officer%' then raise; end if;
 end;
end
$test$;

-- Independent Exam Officer authorizes reopening exactly the snapshotted row.
select set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',false);
select public.schoolpro_decide_result_reopening(current_setting('test.teacher_request')::uuid,true,'Verified correction evidence') as reopened;
do $test$
begin
 if (select status from public.schoolpro_result_correction_batches
     where id=current_setting('test.teacher_request')::uuid) <> 'approved' then
   raise exception 'Exam Officer approval was not recorded';
 end if;
 if not exists(select 1 from public.schoolpro_results
   where id='40000000-0000-4000-8000-000000000001' and status='draft' and not locked) then
   raise exception 'Authorized correction did not reopen the result snapshot';
 end if;
 if not exists(select 1 from public.schoolpro_audit_logs
   where action like '%Section Head forwarded%' and actor_id='33333333-3333-4333-8333-333333333333')
   or not exists(select 1 from public.schoolpro_audit_logs
   where action='Class or section results reopened for correction'
     and actor_id='55555555-5555-4555-8555-555555555555') then
   raise exception 'Section Head and Exam Officer decisions were not both audited';
 end if;
end
$test$;

-- Form Master request follows the same route; Section Head rejection requires a reason.
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',false);
select public.schoolpro_request_result_reopening(
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','class',
 '20000000-0000-4000-8000-000000000001',null,
 'Second Term','2025/2026','Request correction to published class marks'
) as form_master_request \gset
select set_config('test.form_master_request', :'form_master_request', false);
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',false);
do $test$
begin
 begin
  perform public.schoolpro_review_result_reopening(current_setting('test.form_master_request')::uuid,false,'short');
  raise exception 'Section Head rejection without a reason unexpectedly succeeded';
 exception when others then
  if sqlerrm not like '%rejection reason of at least 10 characters%' then raise; end if;
 end;
end
$test$;
select public.schoolpro_review_result_reopening(current_setting('test.form_master_request')::uuid,false,'Marks need source evidence') as rejected;
do $test$
begin
 if (select status from public.schoolpro_result_correction_batches
     where id=current_setting('test.form_master_request')::uuid) <> 'rejected' then
   raise exception 'Section Head rejection was not recorded';
 end if;
 if not exists(select 1 from public.schoolpro_results
   where id='40000000-0000-4000-8000-000000000002' and status='published' and locked) then
   raise exception 'Rejected correction request changed a published result';
 end if;
end
$test$;

reset role;
\echo 'PASS: teacher/Form Master correction requests route through assigned Section Head review, then independent Exam Officer authorization; rejection, snapshots, RLS and audit trail hold.'
