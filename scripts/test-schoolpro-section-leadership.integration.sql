\set ON_ERROR_STOP on
create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;
create table auth.users(id uuid primary key);
create or replace function auth.uid() returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create type public.school_member_role as enum ('proprietor','administrator','head_teacher','vice_principal','exam_officer','teacher','class_teacher');
create type public.user_role as enum ('super_admin');
create table public.schoolpro_schools(id uuid primary key, owner_id uuid);
create table public.schoolpro_members(
 id uuid primary key, school_id uuid not null references public.schoolpro_schools(id),
 user_id uuid not null references auth.users(id), role public.school_member_role not null,
 position_title text, status text not null default 'active'
);
create table public.schoolpro_classes(
 id uuid primary key, school_id uuid not null references public.schoolpro_schools(id),
 name text not null, level text not null check(level in ('nursery','primary','junior_secondary','senior_secondary','other')),
 form_teacher_id uuid references public.schoolpro_members(id)
);
create table public.schoolpro_students(
 id uuid primary key, school_id uuid not null references public.schoolpro_schools(id),
 class_id uuid references public.schoolpro_classes(id), user_id uuid, status text not null
);
create table public.schoolpro_enrollment_history(
 school_id uuid not null, student_id uuid not null, session text not null,
 class_id uuid not null, created_at timestamptz not null default now()
);
alter table public.schoolpro_enrollment_history enable row level security;
create policy "Authorized school enrollment history" on public.schoolpro_enrollment_history for select to authenticated using(true);
create table public.schoolpro_subjects(id uuid primary key, school_id uuid not null);
create table public.schoolpro_guardian_links(school_id uuid,student_id uuid,guardian_user_id uuid,status text);
create table public.schoolpro_subject_assignments(school_id uuid,class_id uuid,teacher_member_id uuid,subject_id uuid,session text);
create table public.schoolpro_audit_logs(
 school_id uuid, actor_id uuid, action text, entity_type text, entity_id uuid, metadata jsonb
);
create table public.schoolpro_results(
 id uuid primary key, school_id uuid not null, student_id uuid not null, subject_id uuid not null,
 session text not null, term text, ca_score numeric, exam_score numeric, assessment_scores jsonb,
 assessment_scheme_id uuid, total_score numeric not null default 0, status text not null, locked boolean not null default false, approved_by uuid, approved_at timestamptz,
 published_at timestamptz
);
alter table public.schoolpro_results enable row level security;
create policy "Result access gate" on public.schoolpro_results as restrictive for select to authenticated using(true);
create or replace function private.is_active_account() returns boolean language sql stable as $$ select auth.uid() is not null $$;
create or replace function private.schoolpro_operationally_active(uuid) returns boolean language sql stable as $$ select true $$;
create or replace function private.schoolpro_module_allowed(uuid,text) returns boolean language sql stable as $$ select true $$;
create or replace function private.is_admin(public.user_role[]) returns boolean language sql stable as $$ select false $$;
create or replace function private.has_school_access(p_school uuid,p_roles public.school_member_role[])
returns boolean language sql stable as $$
 select exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role=any(p_roles))
$$;
create or replace function public.schoolpro_member_can_manage(uuid) returns boolean language sql stable as $fn$ select false $fn$;
create or replace function private.schoolpro_can_issue_transcript(uuid) returns boolean language sql stable as $$ select false $$;
create or replace function private.schoolpro_result_access(uuid,text,text)
returns table(allowed boolean) language sql stable as $ select true $;
create or replace function private.schoolpro_result_assessment_complete(uuid)
returns boolean language sql stable as $ select true $;
\ir ../supabase/migrations/20261103120000_schoolpro_section_leadership_scope.sql
\ir ../supabase/migrations/20261108118000_schoolpro_principal_section_leadership.sql
\ir ../supabase/migrations/20261108119000_schoolpro_form_master_section_head_result_workflow.sql

do $test$
declare
 school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 nursery_class uuid := '11111111-1111-4111-8111-111111111111';
 primary_class uuid := '22222222-2222-4222-8222-222222222222';
 student_n uuid := '33333333-3333-4333-8333-333333333333';
 student_p uuid := '44444444-4444-4444-8444-444444444444';
 student_jss uuid := '44444444-4444-4444-8444-444444444445';
 student_ss uuid := '44444444-4444-4444-8444-444444444446';
 subject_id uuid := '55555555-5555-4555-8555-555555555555';
 owner_id uuid := '66666666-6666-4666-8666-666666666666';
 head_id uuid := '77777777-7777-4777-8777-777777777777';
 vice_id uuid := '88888888-8888-4888-8888-888888888888';
 principal_id uuid := '88888888-8888-4888-8888-888888888889';
 formmaster_id uuid := '88888888-8888-4888-8888-888888888890';
 head_member uuid := '99999999-9999-4999-8999-999999999991';
 vice_member uuid := '99999999-9999-4999-8999-999999999992';
 principal_member uuid := '99999999-9999-4999-8999-999999999993';
 formmaster_member uuid := '99999999-9999-4999-8999-999999999994';
 formmaster_member uuid := '99999999-9999-4999-8999-999999999994';
begin
 insert into auth.users values(owner_id),(head_id),(vice_id),(principal_id),(formmaster_id);
 insert into public.schoolpro_schools values(school,owner_id);
 insert into public.schoolpro_members(id,school_id,user_id,role,position_title) values
  ('aaaaaaaa-0000-4000-8000-000000000001',school,owner_id,'proprietor',null),
  (head_member,school,head_id,'head_teacher',null),
  (vice_member,school,vice_id,'vice_principal',null),
  (principal_member,school,principal_id,'administrator','Principal'),
  (formmaster_member,school,formmaster_id,'teacher',null);
 insert into public.schoolpro_classes values
  (nursery_class,school,'Nursery 2','nursery',formmaster_member),
  (primary_class,school,'Primary 4','primary',null),
  ('22222222-2222-4222-8222-222222222223',school,'JSS 2','junior_secondary',formmaster_member),
  ('22222222-2222-4222-8222-222222222224',school,'SS 2','senior_secondary',formmaster_member);
 insert into public.schoolpro_students values
  (student_n,school,nursery_class,null,'active'),
  (student_p,school,primary_class,null,'active'),
  (student_jss,school,'22222222-2222-4222-8222-222222222223',null,'active'),
  (student_ss,school,'22222222-2222-4222-8222-222222222224',null,'active');
 insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id) values
  (school,student_n,'2025/2026',nursery_class),
  (school,student_p,'2025/2026',primary_class),
  (school,student_jss,'2025/2026','22222222-2222-4222-8222-222222222223'),
  (school,student_ss,'2025/2026','22222222-2222-4222-8222-222222222224');
 insert into public.schoolpro_subjects values(subject_id,school);
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform public.schoolpro_set_section_leader(school,head_member,'nursery',true);
 perform public.schoolpro_set_section_leader(school,head_member,'primary',true);
 perform public.schoolpro_set_section_leader(school,vice_member,'junior_secondary',true);
 perform public.schoolpro_set_section_leader(school,principal_member,'senior_secondary',true);
 if (select count(*) from public.schoolpro_section_leaders where school_id=school) <> 4 then
   raise exception 'Section leader assignments were not persisted';
 end if;
 perform set_config('request.jwt.claim.sub',formmaster_id::text,true);
 insert into public.schoolpro_results(id,school_id,student_id,subject_id,session,term,ca_score,exam_score,assessment_scores,status)
 values('bbbbbbbb-0000-4000-8000-000000000002',school,student_n,subject_id,'2025/2026','First Term',10,90,'{}','draft');
 if public.schoolpro_submit_class_results(school,nursery_class,'First Term','2025/2026')<>1 then
   raise exception 'Form Master must submit all class Draft results';
 end if;
 perform set_config('request.jwt.claim.sub',head_id::text,true);
 update public.schoolpro_results set status='approved' where id='bbbbbbbb-0000-4000-8000-000000000002';
 update public.schoolpro_results set status='published',locked=true where id='bbbbbbbb-0000-4000-8000-000000000002';
 if (select status from public.schoolpro_result_workflow where result_id='bbbbbbbb-0000-4000-8000-000000000002')<>'published' then
   raise exception 'Appointed Head Teacher approval and publication workflow failed';
 end if;
 if not private.schoolpro_member_leads_student_section(school,student_n,'2025/2026') then
   raise exception 'Head teacher must lead the explicitly assigned Nursery section';
 end if;
 if not private.schoolpro_member_leads_student_section(school,student_p,'2025/2026') then
   raise exception 'Head teacher must lead the explicitly assigned Primary section';
 end if;
 if not private.schoolpro_can_read_student(student_p) then
   raise exception 'Head teacher must read students in assigned Primary section';
 end if;
 if not private.schoolpro_can_read_student(student_n) or not private.schoolpro_can_read_class(nursery_class) then
   raise exception 'Head teacher must read students and classes in assigned section';
 end if;
 if not private.schoolpro_can_read_class(primary_class) then
   raise exception 'Head teacher must read classes in assigned Primary section';
 end if;
 if not private.schoolpro_can_write_result(school,student_n,subject_id,'2025/2026') then
   raise exception 'Head teacher must be able to write results in assigned section';
 end if;
 if not private.schoolpro_can_write_result(school,student_p,subject_id,'2025/2026') then
   raise exception 'Head teacher must write results in assigned Primary section';
 end if;
 update public.schoolpro_results set status='approved'
 where false;
 insert into public.schoolpro_results(id,school_id,student_id,subject_id,session,ca_score,exam_score,assessment_scores,status)
 values('bbbbbbbb-0000-4000-8000-000000000001',school,student_jss,subject_id,'2025/2026',0,0,'{}','draft');
 perform set_config('request.jwt.claim.sub',formmaster_id::text,true);
 if public.schoolpro_submit_class_results(school,'22222222-2222-4222-8222-222222222223','First Term','2025/2026')<>1 then
   raise exception 'Form Master must submit Junior Secondary results';
 end if;
 perform set_config('request.jwt.claim.sub',head_id::text,true);
 insert into public.schoolpro_result_workflow(result_id,school_id,class_id,term,session,status)
 values('bbbbbbbb-0000-4000-8000-000000000001',school,'22222222-2222-4222-8222-222222222223','First Term','2025/2026','submitted');
 begin
   update public.schoolpro_results set status='approved' where id='bbbbbbbb-0000-4000-8000-000000000001';
   raise exception 'ASSERT: section leader approved result outside assigned section';
 exception when others then
   if sqlerrm like 'ASSERT:%' then raise; end if;
   if position('appointed section Head Teacher' in sqlerrm)=0 then raise; end if;
 end;
 perform set_config('request.jwt.claim.sub',vice_id::text,true);
 if not private.schoolpro_member_leads_student_section(school,student_jss,'2025/2026') then
   raise exception 'Vice principal must lead explicitly assigned Junior Secondary section';
 end if;
 if private.schoolpro_member_leads_student_section(school,student_p,'2025/2026') then
   raise exception 'Vice principal must not lead a Primary section';
 end if;
 if private.schoolpro_member_leads_student_section(school,student_n,'2025/2026') then
   raise exception 'Vice principal must not lead an unassigned Nursery section';
 end if;
 if private.schoolpro_enrollment_reader_keys() ? (school::text||'|'||student_p::text||'|2025/2026') then
   raise exception 'Vice principal must not read enrollment history outside assigned section';
 end if;
 if not (private.schoolpro_enrollment_reader_keys() ? (school::text||'|'||student_jss::text||'|2025/2026')) then
   raise exception 'Section leader must read enrollment history inside assigned section';
 end if;
 update public.schoolpro_results set status='approved' where id='bbbbbbbb-0000-4000-8000-000000000001';
 update public.schoolpro_results set status='published',locked=true where id='bbbbbbbb-0000-4000-8000-000000000001';
 if (select status from public.schoolpro_result_workflow where result_id='bbbbbbbb-0000-4000-8000-000000000001')<>'published' then
   raise exception 'Appointed Vice Principal approval and publication workflow failed';
 end if;
 perform set_config('request.jwt.claim.sub',principal_id::text,true);
 if not private.schoolpro_member_leads_class(school,'22222222-2222-4222-8222-222222222224') then
   raise exception 'Principal must read explicitly assigned Senior Secondary section';
 end if;
 if private.schoolpro_member_leads_student_section(school,student_n,'2025/2026') then
   raise exception 'Principal must not lead an unassigned Nursery section';
 end if;
 insert into public.schoolpro_results(id,school_id,student_id,subject_id,session,term,ca_score,exam_score,assessment_scores,status)
 values('bbbbbbbb-0000-4000-8000-000000000003',school,student_ss,subject_id,'2025/2026','First Term',10,90,'{}','draft');
 perform set_config('request.jwt.claim.sub',formmaster_id::text,true);
 if public.schoolpro_submit_class_results(school,'22222222-2222-4222-8222-222222222224','First Term','2025/2026')<>1 then
   raise exception 'Form Master must submit Senior Secondary results';
 end if;
 perform set_config('request.jwt.claim.sub',principal_id::text,true);
 update public.schoolpro_results set status='approved' where id='bbbbbbbb-0000-4000-8000-000000000003';
 update public.schoolpro_results set status='published',locked=true where id='bbbbbbbb-0000-4000-8000-000000000003';
 if (select status from public.schoolpro_result_workflow where result_id='bbbbbbbb-0000-4000-8000-000000000003')<>'published' then
   raise exception 'Appointed Principal approval and publication workflow failed';
 end if;
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 begin
   perform public.schoolpro_set_section_leader(school,head_member,'junior_secondary',true);
   raise exception 'ASSERT: Head Teacher must not be appointed to Junior Secondary';
 exception when others then if sqlerrm like 'ASSERT:%' then raise; end if; end;
 perform public.schoolpro_set_section_leader(school,head_member,'nursery',false);
 if exists(select 1 from public.schoolpro_section_leaders where member_id=head_member and section='nursery' and ended_at is null) then
   raise exception 'Section leader removal failed';
 end if;
 update public.schoolpro_members set role='teacher' where id=vice_member;
 if exists(select 1 from public.schoolpro_section_leaders where member_id=vice_member and ended_at is null) then
   raise exception 'Changing staff role must clear obsolete section assignments';
 end if;
end
$test$;
select 'PASS: section assignments, historical class-level resolution, result-write scope, review scope, and assignment revocation' as result;


-- Stage C authority and final publication lifecycle.
alter table public.schoolpro_members add constraint schoolpro_members_school_id_id_unique unique(school_id,id);
alter table public.schoolpro_subject_assignments add column ended_at timestamptz;
alter table public.schoolpro_results add column updated_at timestamptz not null default now();
\ir ../supabase/migrations/20261108120000_schoolpro_role_responsibility_and_result_lifecycle.sql

do $authority$
declare
 school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 primary_class uuid := '22222222-2222-4222-8222-222222222222';
 student_id uuid := '44444444-4444-4444-8444-444444444444';
 subject_one uuid := '55555555-5555-4555-8555-555555555555';
 subject_two uuid := '55555555-5555-4555-8555-555555555556';
 owner_id uuid := '66666666-6666-4666-8666-666666666666';
 formmaster_id uuid := '88888888-8888-4888-8888-888888888890';
 formmaster_member uuid := '99999999-9999-4999-8999-999999999994';
 section_head_id uuid := '88888888-8888-4888-8888-888888888888';
 section_head_member uuid := '99999999-9999-4999-8999-999999999992';
 subject_teacher_id uuid := '88888888-8888-4888-8888-888888888895';
 subject_teacher_member uuid := '99999999-9999-4999-8999-999999999995';
 exam_officer_id uuid := '88888888-8888-4888-8888-888888888896';
 exam_officer_member uuid := '99999999-9999-4999-8999-999999999996';
 class_request uuid;
 section_request uuid;
begin
 insert into auth.users values(subject_teacher_id),(exam_officer_id);
 insert into public.schoolpro_members(id,school_id,user_id,role,position_title) values
  (subject_teacher_member,school,subject_teacher_id,'teacher',null),
  (exam_officer_member,school,exam_officer_id,'teacher',null);
 update public.schoolpro_classes set form_teacher_id=formmaster_member where id=primary_class;
 insert into public.schoolpro_subjects values(subject_two,school);
 insert into public.schoolpro_subject_assignments(school_id,class_id,teacher_member_id,subject_id,session,ended_at) values
  (school,primary_class,formmaster_member,subject_one,'2026/2027',null),
  (school,primary_class,subject_teacher_member,subject_two,'2026/2027',null);
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform public.schoolpro_set_section_leader(school,subject_teacher_member,'primary',true);
 if not private.schoolpro_member_leads_class(school,primary_class) then
   raise exception 'A teacher with an explicit section appointment must be able to act as Section Head';
 end if;

 -- The Form Master is also a subject teacher, but may edit only their allocated subject.
 perform set_config('request.jwt.claim.sub',formmaster_id::text,true);
 insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scores,status)
 values('bbbbbbbb-0000-4000-8000-000000000011',school,student_id,subject_one,'First Term','2026/2027','{"ca":10,"exam":80}','draft');
 perform set_config('request.jwt.claim.sub',subject_teacher_id::text,true);
 insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scores,status)
 values('bbbbbbbb-0000-4000-8000-000000000012',school,student_id,subject_two,'First Term','2026/2027','{"ca":9,"exam":75}','draft');
 perform set_config('request.jwt.claim.sub',formmaster_id::text,true);
 begin
   update public.schoolpro_results set assessment_scores='{"ca":12,"exam":80}'
   where id='bbbbbbbb-0000-4000-8000-000000000012';
   raise exception 'ASSERT: Form Master changed another subject teacher result';
 exception when others then
   if sqlerrm like 'ASSERT:%' then raise; end if;
   if position('Only the active subject teacher assigned' in sqlerrm)=0 then raise; end if;
 end;
 if public.schoolpro_submit_class_results(school,primary_class,'First Term','2026/2027')<>2 then
   raise exception 'Form Master must submit only after the complete class subject matrix exists';
 end if;

 -- The appointed section head (who is also a subject teacher) approves the whole section.
 perform set_config('request.jwt.claim.sub',subject_teacher_id::text,true);
 if public.schoolpro_approve_section_results(school,'primary','First Term','2026/2027')<>2 then
   raise exception 'Section Head must approve all complete submitted results in the section';
 end if;
 if (select count(*) from public.schoolpro_result_workflow
   where school_id=school and session='2026/2027' and status='section_approved')<>2 then
   raise exception 'Section approval must advance both subject result rows';
 end if;

 -- A staff member can hold Exam Officer authority in addition to a teaching role.
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform public.schoolpro_set_member_responsibility(school,exam_officer_member,'exam_officer',true);
 perform set_config('request.jwt.claim.sub',exam_officer_id::text,true);
 if public.schoolpro_exam_officer_approve_results(school,'First Term','2026/2027','school',null,null)<>2 then
   raise exception 'Exam Officer must give final approval to every school result';
 end if;
 if public.schoolpro_publish_school_results(school,'First Term','2026/2027')<>2 then
   raise exception 'Exam Officer must publish the whole school result set';
 end if;
 if exists(select 1 from public.schoolpro_results where session='2026/2027' and status<>'published' or session='2026/2027' and not locked) then
   raise exception 'Whole-school publication must lock every result';
 end if;

 -- Class-based correction request: no result changes until the Exam Officer authorizes reopening.
 perform set_config('request.jwt.claim.sub',formmaster_id::text,true);
 class_request:=public.schoolpro_request_result_reopening(
   school,'class',primary_class,null,'First Term','2026/2027',
   'Correct the two class assessment records before the next release.'
 );
 perform set_config('request.jwt.claim.sub',exam_officer_id::text,true);
 if public.schoolpro_decide_result_reopening(class_request,true,'Approved class correction')<>2 then
   raise exception 'Exam Officer class correction approval must reopen exactly the affected class';
 end if;
 if exists(select 1 from public.schoolpro_results where session='2026/2027' and (status<>'draft' or locked)) then
   raise exception 'Authorized class correction must return the affected results to unlocked Draft';
 end if;

 -- Re-submit and republish, then exercise section-based reopening independently.
 perform set_config('request.jwt.claim.sub',formmaster_id::text,true);
 if public.schoolpro_submit_class_results(school,primary_class,'First Term','2026/2027')<>2 then
   raise exception 'Corrected class results must be resubmitted by the Form Master';
 end if;
 perform set_config('request.jwt.claim.sub',subject_teacher_id::text,true);
 if public.schoolpro_approve_section_results(school,'primary','First Term','2026/2027')<>2 then
   raise exception 'Corrected results must pass section approval again';
 end if;
 perform set_config('request.jwt.claim.sub',exam_officer_id::text,true);
 if public.schoolpro_exam_officer_approve_results(school,'First Term','2026/2027','school',null,null)<>2 then
   raise exception 'Corrected results must pass final Exam Officer approval again';
 end if;
 if public.schoolpro_publish_school_results(school,'First Term','2026/2027')<>2 then
   raise exception 'Corrected results must be republished by the Exam Officer';
 end if;
 perform set_config('request.jwt.claim.sub',subject_teacher_id::text,true);
 section_request:=public.schoolpro_request_result_reopening(
   school,'section',null,'primary','First Term','2026/2027',
   'Reopen the entire Primary section for a verified section-wide correction.'
 );
 perform set_config('request.jwt.claim.sub',exam_officer_id::text,true);
 if public.schoolpro_decide_result_reopening(section_request,true,'Approved section correction')<>2 then
   raise exception 'Exam Officer section correction approval must reopen the entire affected section';
 end if;
 if exists(select 1 from public.schoolpro_results where session='2026/2027' and (status<>'draft' or locked)) then
   raise exception 'Section reopening must unlock all affected section results';
 end if;
end
$authority$;
select 'PASS: subject-teacher-only marks, complete Form Master submission, concurrent roles, section approval, Exam Officer final approval/publication, and class/section correction reopening' as result;
