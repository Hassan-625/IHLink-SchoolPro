\set ON_ERROR_STOP on
begin;

create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;

create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;
create function private.is_active_account() returns boolean language sql stable as $$ select auth.uid() is not null $$;
create function private.schoolpro_operationally_active(p_school uuid) returns boolean language sql stable as $$ select p_school is not null $$;
create function private.schoolpro_module_allowed(p_school uuid,p_module text) returns boolean language sql stable as $$ select p_school is not null and p_module='cbt' $$;
create function public.schoolpro_can_manage_cbt(p_school uuid) returns boolean language sql stable as $$
  select auth.uid()='00000000-0000-0000-0000-000000000005'::uuid
$$;
grant usage on schema auth,private to authenticated;
grant execute on all functions in schema auth,private to authenticated;
grant execute on function public.schoolpro_can_manage_cbt(uuid) to authenticated;

create table public.schoolpro_classes(id uuid primary key,school_id uuid not null,archived_at timestamptz);
create table public.schoolpro_subjects(id uuid primary key,school_id uuid not null);
create table public.schoolpro_members(id uuid primary key,school_id uuid not null,user_id uuid not null,status text not null,role text not null);
create table public.schoolpro_subject_assignments(
  id uuid primary key,school_id uuid not null,class_id uuid not null,subject_id uuid not null,
  teacher_member_id uuid not null,session text not null,ended_at timestamptz
);
create table public.schoolpro_cbt_tests(
  id uuid primary key,school_id uuid not null,title text not null,subject_id uuid,class_id uuid,
  duration_minutes integer,total_marks numeric,status text not null,created_by uuid not null,
  instructions text,opens_at timestamptz,closes_at timestamptz,randomize_questions boolean,
  randomize_options boolean,attempts_allowed integer,test_type text,created_at timestamptz default now()
);
create table public.schoolpro_question_bank(
  id uuid primary key,school_id uuid not null,subject_id uuid,class_id uuid,
  question_type text not null,question_text text not null,options jsonb,correct_answer text,
  marks numeric not null,explanation text,created_by uuid not null,created_at timestamptz default now()
);
create table public.schoolpro_cbt_test_questions(id uuid primary key default gen_random_uuid(),test_id uuid not null,question_id uuid not null,position integer);
create table public.schoolpro_students(id uuid primary key,school_id uuid not null,user_id uuid not null,class_id uuid,status text,transferred_out_at timestamptz);
create table public.schoolpro_cbt_eligibility(id uuid primary key default gen_random_uuid(),school_id uuid not null,test_id uuid not null,student_id uuid,class_id uuid,eligible boolean not null,assigned_by uuid);
create table public.schoolpro_cbt_attempts(id uuid primary key,test_id uuid not null,student_id uuid not null,started_at timestamptz default now(),score numeric default 0);
create table public.schoolpro_cbt_answers(
  id uuid primary key,attempt_id uuid not null,question_id uuid not null,answer text,
  marks_awarded numeric,feedback text,marked_by uuid,marked_at timestamptz,is_correct boolean
);

alter table public.schoolpro_cbt_tests enable row level security;
alter table public.schoolpro_question_bank enable row level security;
alter table public.schoolpro_cbt_test_questions enable row level security;
alter table public.schoolpro_cbt_eligibility enable row level security;
alter table public.schoolpro_cbt_attempts enable row level security;
alter table public.schoolpro_cbt_answers enable row level security;

-- Existing policies deliberately include the broad paths the migration must remove.
create policy "C0 CBT plan read" on public.schoolpro_cbt_tests for select to authenticated using (private.schoolpro_module_allowed(school_id,'cbt'));
create policy "cbt authors create drafts" on public.schoolpro_cbt_tests for insert to authenticated with check (public.schoolpro_can_manage_cbt(school_id));
create policy "cbt authors delete drafts" on public.schoolpro_cbt_tests for delete to authenticated using (public.schoolpro_can_manage_cbt(school_id));
create policy "cbt authors edit drafts" on public.schoolpro_cbt_tests for update to authenticated using (public.schoolpro_can_manage_cbt(school_id)) with check (public.schoolpro_can_manage_cbt(school_id));
create policy "cbt authors read tests" on public.schoolpro_cbt_tests for select to authenticated using (public.schoolpro_can_manage_cbt(school_id));
create policy "cbt managers manage tests" on public.schoolpro_cbt_tests for all to authenticated using (public.schoolpro_can_manage_cbt(school_id)) with check (public.schoolpro_can_manage_cbt(school_id));
create policy "question bank authorized read" on public.schoolpro_question_bank for select to authenticated using (public.schoolpro_can_manage_cbt(school_id));
create policy "school question manage" on public.schoolpro_question_bank for all to authenticated using (public.schoolpro_can_manage_cbt(school_id)) with check (public.schoolpro_can_manage_cbt(school_id));
create policy "schoolpro_plan_access" on public.schoolpro_question_bank for all to authenticated using (private.schoolpro_module_allowed(school_id,'cbt')) with check (private.schoolpro_module_allowed(school_id,'cbt'));
create policy "test question authorized read" on public.schoolpro_cbt_test_questions for select to authenticated using (true);
create policy "test question authors write" on public.schoolpro_cbt_test_questions for all to authenticated using (true) with check (true);
create policy "cbt eligibility managers" on public.schoolpro_cbt_eligibility for all to authenticated using (public.schoolpro_can_manage_cbt(school_id)) with check (public.schoolpro_can_manage_cbt(school_id));
create policy "cbt eligibility students read own" on public.schoolpro_cbt_eligibility for select to authenticated using (student_id in (select id from public.schoolpro_students where user_id=auth.uid()));
create policy "cbt attempt staff read" on public.schoolpro_cbt_attempts for select to authenticated using (exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id and public.schoolpro_can_manage_cbt(t.school_id)));
create policy "cbt attempt student read own" on public.schoolpro_cbt_attempts for select to authenticated using (exists(select 1 from public.schoolpro_students s where s.id=student_id and s.user_id=auth.uid()));
create policy "schoolpro_plan_attempts" on public.schoolpro_cbt_attempts for all to authenticated using (true) with check (true);
create policy "cbt answer staff read" on public.schoolpro_cbt_answers for select to authenticated using (exists(select 1 from public.schoolpro_cbt_attempts a join public.schoolpro_cbt_tests t on t.id=a.test_id where a.id=attempt_id and public.schoolpro_can_manage_cbt(t.school_id)));
create policy "cbt answer student read own" on public.schoolpro_cbt_answers for select to authenticated using (exists(select 1 from public.schoolpro_cbt_attempts a join public.schoolpro_students s on s.id=a.student_id where a.id=attempt_id and s.user_id=auth.uid()));
create policy "schoolpro_plan_answers" on public.schoolpro_cbt_answers for all to authenticated using (true) with check (true);

grant select,insert,update,delete on all tables in schema public to authenticated;

insert into public.schoolpro_classes values
 ('10000000-0000-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',null),
 ('10000000-0000-0000-0000-000000000002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',null),
 ('20000000-0000-0000-0000-000000000001','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',null);
insert into public.schoolpro_subjects values
 ('30000000-0000-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
 ('30000000-0000-0000-0000-000000000002','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
insert into public.schoolpro_members values
 ('40000000-0000-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000001','active','teacher'),
 ('40000000-0000-0000-0000-000000000002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000002','active','teacher'),
 ('40000000-0000-0000-0000-000000000003','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000003','active','teacher'),
 ('40000000-0000-0000-0000-000000000004','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000004','active','teacher'),
 ('40000000-0000-0000-0000-000000000005','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb','00000000-0000-0000-0000-000000000007','active','teacher');
insert into public.schoolpro_subject_assignments values
 ('50000000-0000-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','2026/2027',null),
 ('50000000-0000-0000-0000-000000000002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002','2025/2026',null),
 ('50000000-0000-0000-0000-000000000003','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000003','2026/2027',now()),
 ('50000000-0000-0000-0000-000000000004','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','10000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000004','2026/2027',null);

\ir ../supabase/migrations/20261115100000_schoolpro_cbt_session_scoped_authorization.sql

do $$
begin
  if not exists(select 1 from pg_policies where schemaname='public' and tablename='schoolpro_question_bank' and policyname='Question bank assigned session access') then
    raise exception 'Question bank scoped policy missing';
  end if;
  if exists(select 1 from pg_policies where schemaname='public' and tablename='schoolpro_question_bank' and policyname='schoolpro_plan_access') then
    raise exception 'Broad question-bank plan policy was not removed';
  end if;
  if exists(select 1 from pg_policies where schemaname='public' and tablename='schoolpro_cbt_attempts' and policyname='schoolpro_plan_attempts') then
    raise exception 'Broad attempt plan policy was not removed';
  end if;
end $$;

-- Assigned teacher can create only a draft in the exact active allocation.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
insert into public.schoolpro_cbt_tests(id,school_id,title,class_id,subject_id,session,status,created_by)
values('60000000-0000-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Assigned test','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','2026/2027','draft','00000000-0000-0000-0000-000000000001');
do $$
begin
  begin
    insert into public.schoolpro_cbt_tests(id,school_id,title,class_id,subject_id,session,status,created_by)
    values('60000000-0000-0000-0000-000000000002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Wrong session','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','2025/2026','draft',auth.uid());
    raise exception 'FAIL: wrong-session test was accepted';
  exception when insufficient_privilege then null; end;
end $$;
insert into public.schoolpro_question_bank(id,school_id,subject_id,class_id,session,question_type,question_text,marks,created_by)
values('70000000-0000-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','2026/2027','theory','Explain the topic',5,auth.uid());
do $$
begin
  begin
    insert into public.schoolpro_question_bank(id,school_id,subject_id,class_id,session,question_type,question_text,marks,created_by)
    values('70000000-0000-0000-0000-000000000002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','2025/2026','theory','Stale allocation',5,auth.uid());
    raise exception 'FAIL: wrong-session question was accepted';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.schoolpro_question_bank(id,school_id,subject_id,class_id,session,question_type,question_text,marks,created_by)
    values('70000000-0000-0000-0000-000000000003','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','2026/2027','theory','Wrong class',5,auth.uid());
    raise exception 'FAIL: wrong-class question was accepted';
  exception when insufficient_privilege then null; end;
end $$;
insert into public.schoolpro_cbt_test_questions(test_id,question_id,position)
values('60000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001',1);
do $$
begin
  begin
    update public.schoolpro_cbt_tests set status='published' where id='60000000-0000-0000-0000-000000000001';
    raise exception 'FAIL: assigned author published own test';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- Unassigned, stale-session and ended-allocation teachers cannot read or write the scope.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$
begin
  if exists(select 1 from public.schoolpro_cbt_tests where id='60000000-0000-0000-0000-000000000001') then
    raise exception 'FAIL: wrong-session teacher read a CBT test';
  end if;
  begin
    insert into public.schoolpro_cbt_tests(id,school_id,title,class_id,subject_id,session,status,created_by)
    values('60000000-0000-0000-0000-000000000003','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Stale session','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','2026/2027','draft',auth.uid());
    raise exception 'FAIL: stale-session teacher created test';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
do $$
begin
  begin
    insert into public.schoolpro_cbt_tests(id,school_id,title,class_id,subject_id,session,status,created_by)
    values('60000000-0000-0000-0000-000000000004','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','Ended allocation','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','2026/2027','draft',auth.uid());
    raise exception 'FAIL: ended allocation teacher created test';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- Management retains school-wide control, including publishing a draft.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000005',true);
update public.schoolpro_cbt_tests set status='published' where id='60000000-0000-0000-0000-000000000001';
reset role;

-- Student self-read policies remain after removal of the broad plan ALL policies.
insert into public.schoolpro_students values
 ('80000000-0000-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000006','10000000-0000-0000-0000-000000000001','active',null),
 ('80000000-0000-0000-0000-000000000002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','00000000-0000-0000-0000-000000000008','10000000-0000-0000-0000-000000000001','active',null);
insert into public.schoolpro_cbt_attempts(id,test_id,student_id) values
 ('90000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000001'),
 ('90000000-0000-0000-0000-000000000002','60000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000002');
insert into public.schoolpro_cbt_answers(id,attempt_id,question_id,answer) values
 ('a0000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','My answer'),
 ('a0000000-0000-0000-0000-000000000002','90000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000001','Other answer');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000006',true);
do $$
begin
  if (select count(*) from public.schoolpro_cbt_attempts)<>1 then
    raise exception 'FAIL: student attempt self-read boundary changed';
  end if;
  if (select count(*) from public.schoolpro_cbt_answers)<>1 then
    raise exception 'FAIL: student answer self-read boundary changed';
  end if;
end $$;
reset role;

rollback;
