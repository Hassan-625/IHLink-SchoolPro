\set ON_ERROR_STOP on

create role anon nologin;
create role authenticated nologin;

create schema auth;
create schema private;
create table auth.users(id uuid primary key);
create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create type public.school_member_role as enum
  ('proprietor','administrator','head_teacher','vice_principal','registrar','teacher','class_teacher');
create type public.user_role as enum ('super_admin');

create table public.schoolpro_schools(id uuid primary key);
create table public.schoolpro_classes(
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  name text not null,
  arm text
);
create table public.schoolpro_students(
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  first_name text,
  last_name text,
  status text not null,
  class_id uuid references public.schoolpro_classes(id)
);
create table public.schoolpro_enrollment_history(
  school_id uuid not null,
  student_id uuid not null,
  session text not null,
  class_id uuid not null
);
create table public.schoolpro_subjects(
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  name text not null,
  class_name text not null
);
create table public.schoolpro_results(
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  student_id uuid not null,
  subject_id uuid not null,
  session text not null,
  term text not null,
  status text not null,
  total_score numeric,
  updated_at timestamptz not null default now()
);
create table public.schoolpro_promotions(
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  student_id uuid not null,
  from_class_id uuid,
  to_class_id uuid,
  session text not null,
  status text not null,
  decision text not null check (decision in ('promoted','repeated','graduated')),
  reason text,
  created_at timestamptz not null default now(),
  unique(student_id,session)
);
create table public.schoolpro_transcript_issues(
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  student_id uuid not null,
  revoked_at timestamptz,
  snapshot jsonb not null default '{}'::jsonb,
  issued_at timestamptz not null default now()
);

create or replace function private.schoolpro_module_allowed(uuid,text)
returns boolean language sql stable as $$ select true $$;
create or replace function private.is_admin(public.user_role[])
returns boolean language sql stable as $$ select false $$;
create or replace function private.has_school_access(uuid,public.school_member_role[])
returns boolean language sql stable as $$ select true $$;
create or replace function private.schoolpro_can_issue_transcript(uuid)
returns boolean language sql stable as $$ select true $$;
create or replace function public.schoolpro_result_access(uuid,text,text)
returns table(allowed boolean) language sql stable as $$ select true $$;
create or replace function private.schoolpro_issue_transcript(uuid)
returns void language plpgsql as $$ begin return; end $$;

create or replace function public.create_schoolpro_progression(
  p_student uuid,p_session text,p_decision text,p_to_class uuid default null,p_reason text default null
) returns uuid language plpgsql as $$
declare v_student public.schoolpro_students; v_id uuid;
begin
  select * into v_student from public.schoolpro_students where id=p_student;
  insert into public.schoolpro_promotions(
    school_id,student_id,from_class_id,to_class_id,session,status,decision,reason
  ) values (
    v_student.school_id,v_student.id,v_student.class_id,
    case when p_decision='repeated' then v_student.class_id else p_to_class end,
    p_session,'pending',p_decision,p_reason
  ) returning id into v_id;
  return v_id;
end;
$$;
create or replace function public.apply_schoolpro_promotion(uuid)
returns void language plpgsql as $$ begin update public.schoolpro_promotions set status='applied' where id=$1; end $$;

\ir ../supabase/migrations/20261103100000_schoolpro_progression_subject_requirements.sql

do $fixture$
declare
  school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  foreign_school uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  basic1 uuid := '11111111-1111-4111-8111-111111111111';
  basic2 uuid := '22222222-2222-4222-8222-222222222222';
  math uuid := '33333333-3333-4333-8333-333333333333';
  english uuid := '44444444-4444-4444-8444-444444444444';
  pass_student uuid := '55555555-5555-4555-8555-555555555551';
  fail_student uuid := '55555555-5555-4555-8555-555555555552';
  incomplete_student uuid := '55555555-5555-4555-8555-555555555553';
  result jsonb;
  fail_reason text;
  failed boolean := false;
begin
  insert into public.schoolpro_schools(id) values (school),(foreign_school);
  insert into public.schoolpro_classes(id,school_id,name) values
    (basic1,school,'Basic 1'),(basic2,school,'Basic 2');
  insert into public.schoolpro_subjects(id,school_id,name,class_name) values
    (math,school,'Mathematics','Basic 1'),(english,school,'English','Basic 1');

  insert into public.schoolpro_students(id,school_id,first_name,last_name,status,class_id) values
    (pass_student,school,'Pass','Student','active',basic1),
    (fail_student,school,'Fail','Student','active',basic1),
    (incomplete_student,school,'Incomplete','Student','active',basic1);
  insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id) values
    (school,pass_student,'2025/2026',basic1),
    (school,fail_student,'2025/2026',basic1),
    (school,incomplete_student,'2025/2026',basic1);

  -- All students have annual averages above 45%. The configured Maths rule
  -- distinguishes a pass, a subject failure, and incomplete subject evidence.
  insert into public.schoolpro_results(school_id,student_id,subject_id,session,term,status,total_score)
  select school,student,subject,'2025/2026',term,'published',score
  from (values
    (pass_student,math,'First Term',60::numeric),(pass_student,math,'Second Term',60),(pass_student,math,'Third Term',60),
    (pass_student,english,'First Term',80),(pass_student,english,'Second Term',80),(pass_student,english,'Third Term',80),
    (fail_student,math,'First Term',40),(fail_student,math,'Second Term',40),(fail_student,math,'Third Term',40),
    (fail_student,english,'First Term',80),(fail_student,english,'Second Term',80),(fail_student,english,'Third Term',80),
    (incomplete_student,math,'First Term',40),(incomplete_student,math,'Second Term',40),
    (incomplete_student,english,'First Term',80),(incomplete_student,english,'Second Term',80),(incomplete_student,english,'Third Term',80)
  ) as data(student,subject,term,score);

  perform set_config('request.jwt.claim.sub','99999999-9999-4999-8999-999999999999',true);

  insert into public.schoolpro_progression_subject_requirements(school_id,subject_id,minimum_score)
  values(school,math,50);

  -- Cross-school subject references are rejected even when the caller can write.
  begin
    insert into public.schoolpro_progression_subject_requirements(school_id,subject_id,minimum_score)
    values(foreign_school,math,50);
    raise exception 'ASSERT: cross-school subject rule unexpectedly succeeded';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('must belong to the selected school' in sqlerrm)=0 then raise; end if;
  end;

  -- Out-of-range thresholds are rejected by the table constraint.
  begin
    insert into public.schoolpro_progression_subject_requirements(school_id,subject_id,minimum_score)
    values(school,english,101);
    raise exception 'ASSERT: out-of-range subject minimum unexpectedly succeeded';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if sqlstate <> '23514' then raise; end if;
  end;

  result := private.schoolpro_bulk_academic_action(school,'2025/2026','prepare_progression',array[pass_student,fail_student,incomplete_student]);
  if (result->>'processed')::int <> 2 then
    raise exception 'Expected two prepared decisions and one skipped student; got %',result;
  end if;
  if (select decision from public.schoolpro_promotions where student_id=pass_student) <> 'promoted' then
    raise exception 'Student meeting the subject minimum should be promoted';
  end if;
  if (select decision from public.schoolpro_promotions where student_id=fail_student) <> 'repeated' then
    raise exception 'Student failing a configured subject minimum should repeat';
  end if;
  select reason into fail_reason from public.schoolpro_promotions where student_id=fail_student;
  if fail_reason not like '%Failed subject requirements: Mathematics 40.00% (minimum 50.00%)%' then
    raise exception 'Failed subject detail was not retained in the progression reason: %',fail_reason;
  end if;
  if exists(select 1 from public.schoolpro_promotions where student_id=incomplete_student) then
    raise exception 'Student with incomplete required-subject terms must be skipped for review';
  end if;
  if not exists(
    select 1 from jsonb_array_elements(result->'skipped') item
    where item->>'student_id'=incomplete_student::text
      and item->>'reason' like '%does not have published results for all three terms%'
  ) then
    raise exception 'Missing subject term evidence must be reported in skipped reasons: %',result;
  end if;

  -- Existing review/apply remains explicit; preparation must not change enrolment.
  if (select class_id from public.schoolpro_students where id=pass_student) <> basic1 then
    raise exception 'Preparing a progression decision must not change the student's class';
  end if;
  perform public.apply_schoolpro_promotion((select id from public.schoolpro_promotions where student_id=pass_student));
  if (select status from public.schoolpro_promotions where student_id=pass_student) <> 'applied' then
    raise exception 'Existing apply workflow was not retained';
  end if;
end;
$fixture$;

select 'PASS: configurable subject minimums, tenant guard, score bounds, incomplete-term review, audited repeat decisions and explicit apply workflow' as result;
