-- Disposable PostgreSQL regression for INSERT ... RETURNING under student SELECT RLS.
\set ON_ERROR_STOP on

create schema auth;
create schema private;
create type public.user_role as enum ('super_admin');
create type public.school_member_role as enum ('proprietor', 'administrator', 'teacher', 'class_teacher', 'parent', 'student', 'head_teacher', 'vice_principal');

create function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create function private.is_active_account()
returns boolean language sql stable
as $$ select coalesce(nullif(current_setting('test.active_account', true), '')::boolean, false) $$;

create function private.schoolpro_operationally_active(uuid)
returns boolean language sql stable
as $$ select true $$;

create function private.is_admin(public.user_role[] default array['super_admin'::public.user_role])
returns boolean language sql stable
as $$ select false $$;

create function private.schoolpro_is_school_admin(uuid)
returns boolean language sql stable
as $$ select false $$;

create function private.schoolpro_is_exam_officer(uuid)
returns boolean language sql stable
as $$ select false $$;

create function private.schoolpro_member_leads_class(uuid, uuid)
returns boolean language sql stable
as $$ select false $$;

create table public.schoolpro_schools(id uuid primary key, owner_id uuid);
create table public.schoolpro_guardian_links(
  school_id uuid, student_id uuid, guardian_user_id uuid, status text
);
create table public.schoolpro_members(
  id uuid primary key, school_id uuid, user_id uuid, role public.school_member_role, status text
);
create table public.schoolpro_subject_assignments(
  school_id uuid, class_id uuid, teacher_member_id uuid
);
create table public.schoolpro_classes(
  id uuid primary key, school_id uuid, form_teacher_id uuid
);
create table public.schoolpro_students(
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  user_id uuid,
  class_id uuid,
  admission_number text not null
);

grant usage on schema auth, private, public to authenticated;
grant usage on type public.user_role, public.school_member_role to authenticated;
grant execute on function auth.uid() to authenticated;
grant execute on function private.is_active_account() to authenticated;
grant execute on function private.schoolpro_operationally_active(uuid) to authenticated;
grant execute on function private.is_admin(public.user_role[]) to authenticated;
grant execute on function private.schoolpro_is_school_admin(uuid) to authenticated;
grant execute on function private.schoolpro_is_exam_officer(uuid) to authenticated;
grant execute on function private.schoolpro_member_leads_class(uuid, uuid) to authenticated;
grant insert, select on public.schoolpro_students to authenticated;
grant select on public.schoolpro_schools, public.schoolpro_guardian_links,
  public.schoolpro_members, public.schoolpro_subject_assignments, public.schoolpro_classes
  to authenticated;

insert into public.schoolpro_schools values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '11111111-1111-1111-1111-111111111111'
);

alter table public.schoolpro_students enable row level security;

create policy "School leaders insert students"
on public.schoolpro_students for insert to authenticated
with check (school_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid);

-- Apply the exact production migration after the minimal schema and helper stubs exist.
\ir ../supabase/migrations/20261111150000_schoolpro_student_insert_returning_rls.sql

select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select set_config('test.active_account', 'true', false);
set role authenticated;

do $assert$
declare
  inserted_id uuid;
  inserted_admission text;
begin
  insert into public.schoolpro_students(school_id, admission_number)
  values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'HA-RETURNING-001')
  returning id, admission_number into inserted_id, inserted_admission;

  if inserted_id is null or inserted_admission <> 'HA-RETURNING-001' then
    raise exception 'Owner INSERT ... RETURNING did not return the inserted student';
  end if;
end;
$assert$;

reset role;

do $assert$
begin
  if (select count(*) from public.schoolpro_students) <> 1 then
    raise exception 'Expected exactly one committed student row in disposable test';
  end if;
end;
$assert$;

select set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', false);
set role authenticated;

do $assert$
declare visible_rows integer;
begin
  select count(*) into visible_rows from public.schoolpro_students;
  if visible_rows <> 0 then
    raise exception 'A non-owner unexpectedly read another school owner''s student row';
  end if;
end;
$assert$;

reset role;

do $assert$
begin
  raise notice 'PASS: authorised school owner can INSERT ... RETURNING student fields; unrelated account cannot read the row.';
end;
$assert$;
