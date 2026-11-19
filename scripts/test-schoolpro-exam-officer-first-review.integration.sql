\set ON_ERROR_STOP on
create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;
create type public.user_role as enum ('super_admin');
create table public.schoolpro_schools(id uuid primary key,owner_id uuid);
create table public.schoolpro_members(id uuid primary key,school_id uuid,user_id uuid,role text,status text default 'active');
create table public.schoolpro_classes(id uuid primary key,school_id uuid,level text);
create table public.schoolpro_students(id uuid primary key,school_id uuid,class_id uuid,status text default 'active');
create table public.schoolpro_subject_assignments(school_id uuid,class_id uuid,subject_id uuid,session text,ended_at timestamptz);
create table public.schoolpro_enrollment_history(school_id uuid,student_id uuid,class_id uuid,session text,created_at timestamptz default now());
create table public.schoolpro_results(
 id uuid primary key,school_id uuid,student_id uuid,subject_id uuid,term text,session text,status text,
 locked boolean default false,ca_score numeric,exam_score numeric,total_score numeric,
 assessment_scores jsonb default '{}'::jsonb,assessment_scheme_id uuid,published_at timestamptz,
 approved_by uuid,approved_at timestamptz
);
create table public.schoolpro_result_workflow(
 result_id uuid primary key,school_id uuid,class_id uuid,term text,session text,status text,
 submitted_by uuid,submitted_at timestamptz,approved_by uuid,approved_at timestamptz,
 published_at timestamptz,updated_at timestamptz default now(),correction_notes text
);
create table public.schoolpro_audit_logs(
 id bigint generated always as identity primary key,school_id uuid,actor_id uuid,
 action text,entity_type text,entity_id uuid,metadata jsonb default '{}'::jsonb
);
create or replace function auth.uid() returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create or replace function private.is_active_account() returns boolean language sql stable
as $$ select auth.uid() is not null $$;
create or replace function private.is_admin(p_roles public.user_role[]) returns boolean language sql stable
as $$ select false $$;
create or replace function private.schoolpro_module_allowed(p_school uuid,p_module text) returns boolean language sql stable
as $$ select true $$;
create or replace function private.schoolpro_is_exam_officer(p_school uuid) returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.status='active' and m.role='exam_officer') $$;
create or replace function private.schoolpro_member_leads_class(p_school uuid,p_class uuid) returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.schoolpro_members m join public.schoolpro_classes c on c.school_id=m.school_id where m.school_id=p_school and c.id=p_class and c.level='primary' and m.user_id=auth.uid() and m.status='active' and m.role='section_head') $$;
create or replace function private.schoolpro_lock_result_scope(p_school uuid,p_term text,p_session text,p_scope text,p_class uuid default null,p_section text default null) returns void language plpgsql security definer set search_path=''
as $$ begin return; end $$;
create or replace function private.schoolpro_class_result_matrix_complete(p_school uuid,p_class uuid,p_term text,p_session text) returns boolean language sql stable security definer set search_path=''
as $$ select coalesce(current_setting('test.matrix_complete',true),'true')='true' $$;
create or replace function private.schoolpro_result_scope_mixed_state(p_school uuid,p_term text,p_session text,p_scope text,p_class uuid,p_section text,p_stage text) returns boolean language sql stable security definer set search_path=''
as $$ select coalesce(current_setting('test.workflow_complete',true),'true')='true' $$;
create or replace function private.schoolpro_can_read_class_result_submission(p_school uuid,p_class uuid) returns boolean language sql stable security definer set search_path=''
as $$ select auth.uid() is not null $$;
grant usage on schema auth,private to authenticated;
grant execute on function auth.uid() to authenticated;

insert into public.schoolpro_schools values
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','99999999-9999-4999-8999-999999999999');
insert into public.schoolpro_members(id,school_id,user_id,role) values
('10000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111','exam_officer'),
('10000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','22222222-2222-4222-8222-222222222222','section_head'),
('10000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','33333333-3333-4333-8333-333333333333','class_teacher');
insert into public.schoolpro_classes values
('20000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','primary');
insert into public.schoolpro_students values
('30000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','active');
insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,session) values
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','2026/2027');
insert into public.schoolpro_enrollment_history(school_id,student_id,class_id,session) values
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','2026/2027');
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,status,locked,assessment_scores,total_score) values
('40000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','First Term','2026/2027','draft',false,'{"test":10}'::jsonb,10);
insert into public.schoolpro_result_workflow(result_id,school_id,class_id,term,session,status,submitted_by,submitted_at) values
('40000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','First Term','2026/2027','submitted','33333333-3333-4333-8333-333333333333',now());

\ir ../supabase/migrations/20261119120000_schoolpro_exam_officer_first_result_review.sql

create trigger schoolpro_enforce_result_workflow_test
before update on public.schoolpro_results
for each row execute function private.enforce_result_workflow();
grant select, update on public.schoolpro_results to authenticated;
grant select, update on public.schoolpro_result_workflow to authenticated;
grant select on public.schoolpro_audit_logs to authenticated;

set role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',false);
select set_config('app.schoolpro_section_approval','on',false);
do $test$
begin
 begin
  update public.schoolpro_results set status='approved'
  where id='40000000-0000-4000-8000-000000000001';
  raise exception 'Section Head approved before Exam Officer first review';
 exception when others then
  if sqlerrm not like '%Exam Officer must complete first review%' then raise; end if;
 end;
end
$test$;

-- Section Head cannot perform the Exam Officer's first-pass validation.
do $test$
begin
 begin
  perform public.schoolpro_exam_officer_review_class_results(
   'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','First Term','2026/2027',null);
  raise exception 'Section Head unexpectedly performed Exam Officer first review';
 exception when others then
  if sqlerrm not like '%Only the appointed Exam Officer%' then raise; end if;
 end;
end
$test$;

-- Exam Officer first review fails closed when the matrix is incomplete.
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
select set_config('test.matrix_complete','false',false);
do $test$
begin
 begin
  perform public.schoolpro_exam_officer_review_class_results(
   'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','First Term','2026/2027',null);
  raise exception 'Incomplete result matrix unexpectedly passed first review';
 exception when others then
  if sqlerrm not like '%every student must have a complete Draft result%' then raise; end if;
 end;
end
$test$;
select set_config('test.matrix_complete','true',false);
select set_config('test.workflow_complete','false',false);
do $test$
begin
 begin
  perform public.schoolpro_exam_officer_review_class_results(
   'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','First Term','2026/2027',null);
  raise exception 'Incomplete workflow matrix unexpectedly passed first review';
 exception when others then
  if sqlerrm not like '%every allocated student/subject result must have a matching submitted workflow record%' then raise; end if;
 end;
end
$test$;
select set_config('test.workflow_complete','true',false);
select public.schoolpro_exam_officer_review_class_results(
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','First Term','2026/2027','Checked all subject sheets') as first_reviewed;

do $test$
begin
 if not exists(select 1 from public.schoolpro_result_first_reviews
   where class_id='20000000-0000-4000-8000-000000000001'
     and reviewed_by='11111111-1111-4111-8111-111111111111'
     and result_count=1 and status='forwarded') then
   raise exception 'Exam Officer first review was not recorded';
 end if;
 if not exists(select 1 from public.schoolpro_audit_logs
   where action='Exam Officer completed first review and forwarded class results to Section Head') then
   raise exception 'First review forwarding was not audited';
 end if;
end
$test$;

-- A Section Head return invalidates the first review without deleting its audit history.
update public.schoolpro_result_workflow set status='correction_requested'
where result_id='40000000-0000-4000-8000-000000000001';
do $test$
begin
 if (select status from public.schoolpro_result_first_reviews
   where class_id='20000000-0000-4000-8000-000000000001'
   order by reviewed_at desc limit 1) <> 'invalidated' then
   raise exception 'Section Head return did not invalidate the prior first-review record';
 end if;
end
$test$;

-- Form Master resubmits; Exam Officer must repeat first review before Section Head approval.
update public.schoolpro_result_workflow set status='submitted',submitted_at=now()
where result_id='40000000-0000-4000-8000-000000000001';
select public.schoolpro_exam_officer_review_class_results(
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','First Term','2026/2027','Rechecked after Section Head return') as reviewed_again;

-- A subsequent score edit also invalidates the second review and the submission.
update public.schoolpro_results set assessment_scores='{"test":11}'::jsonb
where id='40000000-0000-4000-8000-000000000001';
do $test$
begin
 if (select count(*) from public.schoolpro_result_first_reviews
   where class_id='20000000-0000-4000-8000-000000000001' and status='invalidated') <> 2 then
   raise exception 'Score edit did not preserve and invalidate the prior Exam Officer review';
 end if;
 if (select status from public.schoolpro_result_workflow
   where result_id='40000000-0000-4000-8000-000000000001') <> 'draft' then
   raise exception 'Score edit did not return the workflow to Draft';
 end if;
end
$test$;

-- Form Master resubmits; Exam Officer must review once more before Section Head approval.
update public.schoolpro_result_workflow set status='submitted',submitted_at=now()
where result_id='40000000-0000-4000-8000-000000000001';
select public.schoolpro_exam_officer_review_class_results(
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','20000000-0000-4000-8000-000000000001','First Term','2026/2027','Rechecked corrected marks') as reviewed_again;
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',false);
select set_config('app.schoolpro_section_approval','on',false);
update public.schoolpro_results set status='approved'
where id='40000000-0000-4000-8000-000000000001';
do $test$
begin
 if (select status from public.schoolpro_results
   where id='40000000-0000-4000-8000-000000000001') <> 'approved' then
   raise exception 'Section Head could not approve after Exam Officer first review';
 end if;
end
$test$;

reset role;
\echo 'PASS: Form Master submission requires Exam Officer first review, complete-matrix validation, explicit Section Head forwarding, audited review, and invalidation after score edits.'
