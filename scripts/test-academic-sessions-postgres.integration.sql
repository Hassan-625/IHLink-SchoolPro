-- Focused disposable PostgreSQL execution test for the proposed Stage B1 calendar migration.
-- Run only against an ephemeral database. This fixture is intentionally isolated from Supabase production.

\set ON_ERROR_STOP on

create role anon nologin;
create role authenticated nologin;
create role service_role nologin;

create schema auth;
create schema private;
create table auth.users (id uuid primary key);
create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create type public.school_member_role as enum (
  'proprietor','administrator','vice_principal','head_teacher','registrar',
  'exam_officer','teacher','class_teacher'
);
create type public.user_role as enum ('super_admin');

create table public.schoolpro_schools (
  id uuid primary key default gen_random_uuid()
);

create table public.schoolpro_students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade
);

create table public.schoolpro_result_term_settings (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  session text not null,
  term text not null,
  term_start_date date,
  term_end_date date,
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id, session, term),
  check (term_end_date is null or term_start_date is null or term_end_date >= term_start_date)
);

create table public.schoolpro_attendance (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  attendance_date date not null,
  session text,
  term text
);

create table public.schoolpro_audit_logs (
  id bigint generated always as identity primary key,
  school_id uuid,
  actor_id uuid,
  action text not null,
  entity_type text,
  entity_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

grant usage on schema private to authenticated;
create or replace function private.has_school_access(p_school uuid, p_roles public.school_member_role[])
returns boolean language sql stable as $
  select p_school::text = current_setting('request.test.school_id', true)
     and exists (
       select 1
       from unnest(p_roles) allowed(role)
       where allowed.role::text = current_setting('request.test.school_role', true)
     )
$;
create or replace function private.is_admin(public.user_role[])
returns boolean language sql stable as $$ select false $$;
create or replace function private.schoolpro_module_allowed(uuid, text)
returns boolean language sql stable as $$ select true $$;
create or replace function private.schoolpro_valid_session(text)
returns boolean language sql immutable as $$
  select $1 ~ '^[0-9]{4}/[0-9]{4}$'
    and split_part($1, '/', 2)::integer = split_part($1, '/', 1)::integer + 1
$$;

\ir ../supabase/migrations/20261030190000_schoolpro_academic_session_lifecycle_and_calendar_history.sql

do $$
declare
  school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  session_id uuid;
  history_count integer;
  remaining integer;
begin
  insert into public.schoolpro_schools(id) values (school);
  perform set_config('request.jwt.claim.sub', '', true);
  insert into public.schoolpro_schools(id) values (foreign_school);

  -- Normal session save and term writes must append immutable history.
  select id into session_id
  from public.schoolpro_save_academic_session(
    school, '2025/2026', date '2025-09-01', date '2026-07-31', 'Initial calendar'
  );

  insert into public.schoolpro_result_term_settings
    (school_id, session, term, term_start_date, term_end_date)
  values
    (school, '2025/2026', 'First Term', date '2025-09-01', date '2025-12-19');

  update public.schoolpro_result_term_settings
  set term_end_date = date '2025-12-20'
  where school_id = school and session = '2025/2026' and term = 'First Term';

  update public.schoolpro_academic_sessions
  set notes = 'Updated calendar'
  where id = session_id;

  select count(*) into history_count
  from public.schoolpro_academic_calendar_history
  where school_id = school;
  if history_count <> 4 then
    raise exception 'Expected 4 history records after session/term create and update; got %', history_count;
  end if;

  -- Verify date-based stamping, explicit-session preservation and legacy fallback.
  insert into public.schoolpro_attendance(school_id, attendance_date)
  values (school, date '2026-03-15') returning * into stamped;
  if stamped.session <> '2025/2026' or stamped.term <> 'First Term' then
    raise exception 'Date-based activity stamping failed: session %, term %', stamped.session, stamped.term;
  end if;

  insert into public.schoolpro_attendance(school_id, attendance_date, session)
  values (school, date '2026-03-15', '2024/2025') returning * into stamped;
  if stamped.session <> '2024/2025' then
    raise exception 'Explicit historical session was not preserved';
  end if;

  -- RLS: teachers may read session rows but not calendar history; exam officers may read both.
  perform set_config('request.test.school_id', school::text, true);
  perform set_config('request.test.school_role', 'teacher', true);
  set local role authenticated;
  select count(*) into visible_count from public.schoolpro_academic_sessions where school_id = school;
  if visible_count <> 1 then raise exception 'Teacher should read the own-school session'; end if;
  select count(*) into visible_count from public.schoolpro_academic_calendar_history where school_id = school;
  if visible_count <> 0 then raise exception 'Teacher must not read privileged calendar history'; end if;
  reset role;

  perform set_config('request.test.school_role', 'exam_officer', true);
  set local role authenticated;
  select count(*) into visible_count from public.schoolpro_academic_calendar_history where school_id = school;
  if visible_count <> 4 then raise exception 'Exam officer should read own-school calendar history; got %', visible_count; end if;
  select count(*) into visible_count from public.schoolpro_academic_sessions where school_id = foreign_school;
  if visible_count <> 0 then raise exception 'Cross-school session read was not isolated'; end if;
  reset role;

  -- Direct session deletion must be rejected.
  begin
    delete from public.schoolpro_academic_sessions where id = session_id;
    raise exception 'ASSERT: direct session delete unexpectedly succeeded';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Academic sessions cannot be deleted' in sqlerrm) = 0 then raise; end if;
  end;

  -- Direct term deletion must be rejected.
  begin
    delete from public.schoolpro_result_term_settings
    where school_id = school and session = '2025/2026' and term = 'First Term';
    raise exception 'ASSERT: direct term delete unexpectedly succeeded';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Academic term records cannot be deleted' in sqlerrm) = 0 then raise; end if;
  end;

  -- Both UPDATE and DELETE against the history ledger must be rejected.
  begin
    update public.schoolpro_academic_calendar_history
    set term = 'Tampered'
    where ctid = (select ctid from public.schoolpro_academic_calendar_history where school_id = school limit 1);
    raise exception 'ASSERT: direct history update unexpectedly succeeded';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Academic calendar history is immutable' in sqlerrm) = 0 then raise; end if;
  end;

  begin
    delete from public.schoolpro_academic_calendar_history
    where ctid = (select ctid from public.schoolpro_academic_calendar_history where school_id = school limit 1);
    raise exception 'ASSERT: direct history delete unexpectedly succeeded';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Academic calendar history is immutable' in sqlerrm) = 0 then raise; end if;
  end;

  -- Deleting the owning school must cascade through terms, sessions and history.
  delete from public.schoolpro_schools where id = school;
  delete from public.schoolpro_schools where id = foreign_school;

  select count(*) into remaining from public.schoolpro_academic_sessions where school_id = school;
  if remaining <> 0 then raise exception 'School cascade left % session rows', remaining; end if;
  select count(*) into remaining from public.schoolpro_result_term_settings where school_id = school;
  if remaining <> 0 then raise exception 'School cascade left % term rows', remaining; end if;
  select count(*) into remaining from public.schoolpro_academic_calendar_history where school_id = school;
  if remaining <> 0 then raise exception 'School cascade left % history rows', remaining; end if;
end;
$$;

select 'PASS: B1 migration applied; session/term history, direct-delete/update guards, and school cleanup cascades executed in disposable PostgreSQL.' as result;
