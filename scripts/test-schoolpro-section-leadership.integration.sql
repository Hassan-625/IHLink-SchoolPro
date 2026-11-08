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
 position_title text
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
 assessment_scheme_id uuid, status text not null, approved_by uuid, approved_at timestamptz,
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
returns table(allowed boolean) language sql stable as $$ select true $$;
\ir ../supabase/migrations/20261103120000_schoolpro_section_leadership_scope.sql
\ir ../supabase/migrations/20261108118000_schoolpro_principal_section_leadership.sql
create trigger enforce_result_workflow before update on public.schoolpro_results
for each row execute function private.enforce_result_workflow();

do $test$
declare
 school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 nursery_class uuid := '11111111-1111-4111-8111-111111111111';
 primary_class uuid := '22222222-2222-4222-8222-222222222222';
 student_n uuid := '33333333-3333-4333-8333-333333333333';
 student_p uuid := '44444444-4444-4444-8444-444444444444';
 subject_id uuid := '55555555-5555-4555-8555-555555555555';
 owner_id uuid := '66666666-6666-4666-8666-666666666666';
 head_id uuid := '77777777-7777-4777-8777-777777777777';
 vice_id uuid := '88888888-8888-4888-8888-888888888888';
 principal_id uuid := '88888888-8888-4888-8888-888888888889';
 head_member uuid := '99999999-9999-4999-8999-999999999991';
 vice_member uuid := '99999999-9999-4999-8999-999999999992';
 principal_member uuid := '99999999-9999-4999-8999-999999999993';
begin
 insert into auth.users values(owner_id),(head_id),(vice_id),(principal_id);
 insert into public.schoolpro_schools values(school,owner_id);
 insert into public.schoolpro_members values
  ('aaaaaaaa-0000-4000-8000-000000000001',school,owner_id,'proprietor'),
  (head_member,school,head_id,'head_teacher'),
  (vice_member,school,vice_id,'vice_principal',null),
  (principal_member,school,principal_id,'administrator','Principal');
 insert into public.schoolpro_classes values
  (nursery_class,school,'Nursery 2','nursery',null),
  (primary_class,school,'Primary 4','primary',null),
  ('22222222-2222-4222-8222-222222222223',school,'JSS 2','junior_secondary',null),
  ('22222222-2222-4222-8222-222222222224',school,'SS 2','senior_secondary',null);
 insert into public.schoolpro_students values
  (student_n,school,nursery_class,null,'active'),
  (student_p,school,primary_class,null,'active');
 insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id) values
  (school,student_n,'2025/2026',nursery_class),
  (school,student_p,'2025/2026',primary_class);
 insert into public.schoolpro_subjects values(subject_id,school);
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform public.schoolpro_set_section_leader(school,head_member,'nursery',true);
 perform public.schoolpro_set_section_leader(school,head_member,'primary',true);
 perform public.schoolpro_set_section_leader(school,vice_member,'junior_secondary',true);
 perform public.schoolpro_set_section_leader(school,principal_member,'senior_secondary',true);
 if (select count(*) from public.schoolpro_section_leaders where school_id=school) <> 4 then
   raise exception 'Section leader assignments were not persisted';
 end if;
 perform set_config('request.jwt.claim.sub',head_id::text,true);
 if not private.schoolpro_member_leads_student_section(school,student_n,'2025/2026') then
   raise exception 'Head teacher must lead the explicitly assigned Nursery section';
 end if;
 if not private.schoolpro_member_leads_student_section(school,student_p,'2025/2026') then
   raise exception 'Head teacher must lead the explicitly assigned Primary section';
 end if;
 if private.schoolpro_can_read_student(student_p) then
   raise exception 'Head teacher must not read students outside assigned section';
 end if;
 if not private.schoolpro_can_read_student(student_n) or not private.schoolpro_can_read_class(nursery_class) then
   raise exception 'Head teacher must read students and classes in assigned section';
 end if;
 if private.schoolpro_can_read_class(primary_class) then
   raise exception 'Head teacher must not read classes outside assigned section';
 end if;
 if not private.schoolpro_can_write_result(school,student_n,subject_id,'2025/2026') then
   raise exception 'Head teacher must be able to write results in assigned section';
 end if;
 if private.schoolpro_can_write_result(school,student_p,subject_id,'2025/2026') then
   raise exception 'Head teacher must not write results outside assigned section';
 end if;
 update public.schoolpro_results set status='approved'
 where false;
 insert into public.schoolpro_results(id,school_id,student_id,subject_id,session,ca_score,exam_score,assessment_scores,status)
 values('bbbbbbbb-0000-4000-8000-000000000001',school,student_p,subject_id,'2025/2026',0,0,'{}','draft');
 begin
   update public.schoolpro_results set status='approved' where id='bbbbbbbb-0000-4000-8000-000000000001';
   raise exception 'ASSERT: section leader approved result outside assigned section';
 exception when others then
   if sqlerrm like 'ASSERT:%' then raise; end if;
   if position('Only authorized school or section leaders' in sqlerrm)=0 then raise; end if;
 end;
 perform set_config('request.jwt.claim.sub',vice_id::text,true);
 if private.schoolpro_member_leads_student_section(school,student_p,'2025/2026') then
   raise exception 'Vice principal must not lead a Primary section';
 end if;
 if private.schoolpro_member_leads_student_section(school,student_n,'2025/2026') then
   raise exception 'Vice principal must not lead an unassigned Nursery section';
 end if;
 if private.schoolpro_enrollment_reader_keys() ? (school::text||'|'||student_n::text||'|2025/2026') then
   raise exception 'Vice principal must not read enrollment history outside assigned section';
 end if;
 if not (private.schoolpro_enrollment_reader_keys() ? (school::text||'|'||student_p::text||'|2025/2026')) then
   raise exception 'Section leader must read enrollment history inside assigned section';
 end if;
 perform set_config('request.jwt.claim.sub',principal_id::text,true);
 if not private.schoolpro_member_leads_class(school,'22222222-2222-4222-8222-222222222224') then
   raise exception 'Principal must read explicitly assigned Senior Secondary section';
 end if;
 if private.schoolpro_member_leads_student_section(school,student_n,'2025/2026') then
   raise exception 'Principal must not lead an unassigned Nursery section';
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
