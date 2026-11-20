-- TEST-ONLY MINIMAL SCHEMA BOOTSTRAP.
-- Used only by the class-result batch SQL workflow to validate the candidate
-- against production-shaped prerequisite columns/functions. This is not a
-- SchoolPro migration and must never be deployed to a hosted project.

create schema if not exists private;

create type public.user_role as enum ('super_admin','platform_admin','support','finance','customer');
create type public.school_member_role as enum (
  'proprietor','administrator','teacher','accountant','vice_principal',
  'head_teacher','bursar','registrar','admissions_officer','exam_officer',
  'class_teacher','librarian','counsellor','nurse','hostel_manager',
  'transport_manager','inventory_officer','hr_officer','receptionist',
  'it_admin','discipline_master','game_master','board_member'
);
create type public.account_status as enum ('active','suspended','disabled');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  role public.user_role not null default 'customer',
  status public.account_status not null default 'active'
);

create table public.schoolpro_schools (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id),
  name text not null,
  code text not null unique
);

create table public.schoolpro_members (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.school_member_role not null,
  status text not null default 'active',
  employment_status text not null default 'active'
);

create table public.schoolpro_classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null,
  level text not null,
  form_teacher_id uuid references public.schoolpro_members(id),
  archived_at timestamptz
);

create table public.schoolpro_students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade
);

create table public.schoolpro_enrollment_history (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  session text not null,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  status text not null default 'active'
);

create table public.schoolpro_subject_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  teacher_member_id uuid not null references public.schoolpro_members(id),
  session text not null,
  ended_at timestamptz
);

create table public.schoolpro_result_template_library (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  is_active boolean not null default true,
  unique (school_id,id)
);

create table public.schoolpro_result_template_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  term text not null,
  session text not null,
  template_id uuid not null,
  updated_at timestamptz not null default now(),
  template_config jsonb not null default '{}'::jsonb,
  subject_row_mappings jsonb not null default '{}'::jsonb
);

create table public.schoolpro_generated_result_outputs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  term text not null,
  session text not null,
  format text not null,
  storage_path text not null,
  template_assignment_id uuid,
  template_id uuid,
  template_assignment_updated_at timestamptz,
  template_config_snapshot jsonb,
  subject_row_mappings_snapshot jsonb
);

create or replace function private.is_active_account()
returns boolean language sql stable security definer set search_path=''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id=(select auth.uid()) and p.status='active'
  );
$$;

create or replace function private.is_admin(required_roles public.user_role[] default array['super_admin']::public.user_role[])
returns boolean language sql stable security definer set search_path=''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id=(select auth.uid()) and p.status='active' and p.role=any(required_roles)
  );
$$;

create or replace function private.schoolpro_module_allowed(target_school uuid,required_permission text)
returns boolean language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null
    and private.is_active_account()
    and required_permission='results'
    and exists (select 1 from public.schoolpro_schools s where s.id=target_school);
$$;

revoke all on function private.is_active_account() from public,anon;
revoke all on function private.is_admin(public.user_role[]) from public,anon;
revoke all on function private.schoolpro_module_allowed(uuid,text) from public,anon;
grant execute on function private.is_active_account() to authenticated;
grant execute on function private.is_admin(public.user_role[]) to authenticated;
grant execute on function private.schoolpro_module_allowed(uuid,text) to authenticated;
