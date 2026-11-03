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
returns boolean language sql stable as 'select p_school::text = current_setting(''request.test.school_id'', true)
  and exists (select 1 from unnest(p_roles) allowed(role)
              where allowed.role::text = current_setting(''request.test.school_role'', true))';
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

-- Install the activity-period trigger boundary in this disposable fixture so the
-- migration's replacement trigger function is executed by real attendance writes.
drop trigger if exists schoolpro_attendance_stamp_activity_period on public.schoolpro_attendance;
create trigger schoolpro_attendance_stamp_activity_period
  before insert or update on public.schoolpro_attendance
  for each row execute function private.schoolpro_stamp_activity_period();


do $fixture$
declare
  school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  session_id uuid;
  history_count integer;
  stamped public.schoolpro_attendance;
  foreign_school uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
begin
  insert into public.schoolpro_schools(id) values (school);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.test.school_id', school::text, true);
  perform set_config('request.test.school_role', 'proprietor', true);
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

  -- A historical term remains addressable after the current session changes.
  insert into public.schoolpro_result_term_settings
    (school_id, session, term, term_start_date, term_end_date)
  values (school, '2024/2025', 'First Term', date '2024-09-01', date '2024-12-20');

  -- Verify date-based stamping and explicit-session + matching-term preservation.
  insert into public.schoolpro_attendance(school_id, attendance_date)
  values (school, date '2025-10-15') returning * into stamped;
  if stamped.session <> '2025/2026' or stamped.term <> 'First Term' then
    raise exception 'Date-based activity stamping failed: session %, term %', stamped.session, stamped.term;
  end if;

  insert into public.schoolpro_attendance(school_id, attendance_date, session)
  values (school, date '2024-10-15', '2024/2025') returning * into stamped;
  if stamped.session <> '2024/2025' or stamped.term <> 'First Term' then
    raise exception 'Explicit historical session/term was not preserved: session %, term %', stamped.session, stamped.term;
  end if;

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

end;
$fixture$;

-- Create a real foreign-tenant session/history row so negative visibility checks are not vacuous.
select set_config('request.test.school_id', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', true);
select set_config('request.test.school_role', 'proprietor', true);
select public.schoolpro_save_academic_session(
  'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '2025/2026',
  date '2025-09-01', date '2026-07-31', 'Foreign tenant fixture'
);

-- Capture table grants, policy text, and the owner-visible fixture row before switching roles.
select has_table_privilege('authenticated', 'public.schoolpro_academic_sessions', 'SELECT') as authenticated_can_select,
       (select count(*) from public.schoolpro_academic_sessions
        where school_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') as owner_visible_school_sessions,
       (select string_agg(qual, E'\n') from pg_policies
        where schemaname = 'public' and tablename = 'schoolpro_academic_sessions') as session_policy_qual;

-- Exercise the actual policies as the authenticated database role.
set role authenticated;
select set_config('request.test.school_id', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', false);
select set_config('request.test.school_role', 'teacher', false);
select current_setting('request.test.school_id', true) as test_school_id,
       current_setting('request.test.school_role', true) as test_school_role,
       private.has_school_access('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', array['teacher'::public.school_member_role]) as helper_allows_teacher;
select current_user as effective_role,
       has_table_privilege(current_user, 'public.schoolpro_academic_sessions', 'SELECT') as effective_role_can_select;
select c.relrowsecurity as row_security_enabled,
       c.relforcerowsecurity as force_row_security,
       (select string_agg(format('roles=%s;cmd=%s;permissive=%s', roles, cmd, permissive), E'\n')
        from pg_policies
        where schemaname = 'public' and tablename = 'schoolpro_academic_sessions') as policy_targeting,
       private.has_school_access('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
         array['teacher'::public.school_member_role]) as direct_helper_result,
       private.is_admin(array['super_admin'::public.user_role]) as direct_admin_result
from pg_class c
where c.oid = 'public.schoolpro_academic_sessions'::regclass;
select school_id, session from public.schoolpro_academic_sessions;
do $rls_assertions$
begin
  if (select count(*) from public.schoolpro_academic_sessions) <> 1
     or exists (select 1 from public.schoolpro_academic_sessions
                where school_id <> 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then
    raise exception 'Teacher must read own-school session only and must not see foreign-tenant sessions';
  end if;
  if exists (select 1 from public.schoolpro_academic_calendar_history) then
    raise exception 'Teacher must not be able to read calendar history';
  end if;
end;
$rls_assertions$;
select set_config('request.test.school_role', 'exam_officer', false);
do $rls_assertions$
begin
  if (select count(*) from public.schoolpro_academic_calendar_history
      where school_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 5 then
    raise exception 'Exam officer must read all five own-school calendar history rows';
  end if;
  if exists (select 1 from public.schoolpro_academic_calendar_history
             where school_id <> 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') then
    raise exception 'Calendar history must not be visible across tenant boundaries';
  end if;
  if exists (select 1 from public.schoolpro_academic_sessions
             where school_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb') then
    raise exception 'School sessions must not be visible across tenant boundaries';
  end if;
end;
$rls_assertions$;
reset role;

-- Parent deletion must remove all owned calendar rows and history without orphaning.
delete from public.schoolpro_schools where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
delete from public.schoolpro_schools where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
do $cascade_assertions$
begin
  if exists (
    select 1 from public.schoolpro_academic_sessions
    where school_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ) then
    raise exception 'Deleting a school must cascade to its academic sessions';
  end if;
  if exists (
    select 1 from public.schoolpro_result_term_settings
    where school_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ) then
    raise exception 'Deleting a school must cascade to its result term settings';
  end if;
  if exists (
    select 1 from public.schoolpro_academic_calendar_history
    where school_id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
  ) then
    raise exception 'Deleting a school must cascade to its calendar history';
  end if;
end;
$cascade_assertions$;

select 'PASS: B1 migration, calendar history, immutable guards, school cascades, authenticated RLS, and activity session stamping.' as result;
