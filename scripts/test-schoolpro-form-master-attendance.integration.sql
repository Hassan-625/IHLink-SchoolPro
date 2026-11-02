-- Disposable PostgreSQL integration test for the Form Master attendance migration.
-- This fixture defines only the Supabase primitives and SchoolPro tables used by
-- the migration, then applies the exact migration from the repository.

\set ON_ERROR_STOP on

create schema if not exists auth;
create schema if not exists private;
create type public.school_member_role as enum ('proprietor', 'administrator', 'teacher', 'class_teacher');
create type public.user_role as enum ('super_admin');

create table public.schoolpro_schools (
  id uuid primary key,
  owner_id uuid not null
);
create table public.schoolpro_members (
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  user_id uuid not null,
  role text not null
);
create table public.schoolpro_board_members (
  school_id uuid not null,
  member_id uuid not null,
  primary key (school_id, member_id)
);
create table public.schoolpro_member_permissions (
  member_id uuid not null,
  permission text not null,
  allowed boolean not null
);
create table public.schoolpro_classes (
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  form_teacher_id uuid references public.schoolpro_members(id)
);
create table public.schoolpro_attendance (
  id uuid primary key,
  school_id uuid not null,
  class_id uuid not null,
  marked_by uuid not null,
  student_id uuid not null,
  attendance_date date not null
);

create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
create function private.is_admin(public.user_role[]) returns boolean
language sql stable as $$ select false $$;
create function private.has_school_access(p_school uuid, p_roles public.school_member_role[])
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.schoolpro_members m
    where m.school_id = p_school
      and m.user_id = auth.uid()
      and m.role = any (select unnest(p_roles)::text)
  )
$$;

-- Legacy policies intentionally model the broad teacher write access being replaced.
alter table public.schoolpro_attendance enable row level security;
create policy "School educators insert attendance" on public.schoolpro_attendance
for insert to authenticated with check (
  private.has_school_access(school_id, array['proprietor','administrator','teacher','class_teacher']::public.school_member_role[])
);
create policy "School educators update attendance" on public.schoolpro_attendance
for update to authenticated using (
  private.has_school_access(school_id, array['proprietor','administrator','teacher','class_teacher']::public.school_member_role[])
) with check (
  private.has_school_access(school_id, array['proprietor','administrator','teacher','class_teacher']::public.school_member_role[])
);

create role authenticated nologin;
grant usage on schema public, private, auth to authenticated;
grant select, insert, update on public.schoolpro_attendance to authenticated;
grant select on public.schoolpro_members, public.schoolpro_classes, public.schoolpro_member_permissions,
  public.schoolpro_board_members, public.schoolpro_schools to authenticated;
grant execute on all functions in schema auth, private to authenticated;

insert into public.schoolpro_schools(id, owner_id) values
 ('10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001'),
 ('10000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002');

insert into public.schoolpro_members(id, school_id, user_id, role) values
 ('30000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','teacher'),
 ('30000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002','class_teacher'),
 ('30000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000003','teacher'),
 ('30000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000004','administrator'),
 ('30000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000005','teacher');

insert into public.schoolpro_classes(id, school_id, form_teacher_id) values
 ('50000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001'),
 ('50000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002'),
 ('50000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001',null),
 ('50000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000005');

insert into public.schoolpro_member_permissions(member_id, permission, allowed) values
 ('30000000-0000-0000-0000-000000000003','attendance',true),
 ('30000000-0000-0000-0000-000000000001','attendance',false);

\ir ../supabase/migrations/20261102090000_schoolpro_form_master_attendance_scope.sql

-- Verify default permission calculation, explicit grants/denials, and assignment.
do $test$
declare p text[];
begin
  perform set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000001',false);
  p := public.schoolpro_user_permissions('10000000-0000-0000-0000-000000000001');
  if 'attendance' = any(p) then raise exception 'Form Master explicit denial was ignored'; end if;

  perform set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000002',false);
  p := public.schoolpro_user_permissions('10000000-0000-0000-0000-000000000001');
  if not ('attendance' = any(p)) then raise exception 'Assigned class teacher did not receive attendance permission'; end if;

  perform set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000003',false);
  p := public.schoolpro_user_permissions('10000000-0000-0000-0000-000000000001');
  if not ('attendance' = any(p)) then raise exception 'Explicit attendance grant was not preserved'; end if;

  perform set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000005',false);
  p := public.schoolpro_user_permissions('10000000-0000-0000-0000-000000000002');
  if 'attendance' = any(p) then raise exception 'Unassigned teacher received attendance permission'; end if;
end
$test$;

-- Exercise actual RLS as authenticated: assigned Form Masters can write only
-- their own class, ordinary teachers cannot write, and administrators retain access.
set role authenticated;
select set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000001',false);
do $test$
begin
  begin
    insert into public.schoolpro_attendance values
      ('60000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001',current_date);
    raise exception 'Explicitly denied teacher unexpectedly inserted attendance';
  exception when insufficient_privilege then null;
  end;
end
$test$;

select set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000002',false);
insert into public.schoolpro_attendance values
 ('60000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000002',current_date);

do $test$
begin
  begin
    insert into public.schoolpro_attendance values
      ('60000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000003',current_date);
    raise exception 'Form Master unexpectedly inserted attendance for another class';
  exception when insufficient_privilege then null;
  end;
end
$test$;

select set_config('request.jwt.claim.sub','40000000-0000-0000-0000-000000000004',false);
insert into public.schoolpro_attendance values
 ('60000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000003','40000000-0000-0000-0000-000000000004','70000000-0000-0000-0000-000000000004',current_date);

reset role;

do $test$
begin
  if (select count(*) from public.schoolpro_attendance) <> 2 then
    raise exception 'Unexpected attendance rows after RLS checks';
  end if;
end
$test$;

\echo 'PASS: Form Master attendance permission mapping and authenticated RLS writes are correctly scoped.'
