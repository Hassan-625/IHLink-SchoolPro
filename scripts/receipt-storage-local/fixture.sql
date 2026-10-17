-- Isolated test-only dependencies for the real receipt Storage policy migration.
-- This file is copied into a temporary local Supabase project by the CI harness;
-- it is never applied to production and contains no real school or user records.
create schema if not exists private;

do $enum$
begin
  create type public.school_member_role as enum (
    'proprietor', 'administrator', 'accountant', 'bursar'
  );
exception
  when duplicate_object then null;
end
$enum$;

create table public.schoolpro_test_storage_memberships (
  user_id uuid not null,
  school_id uuid not null,
  role public.school_member_role not null,
  primary key (user_id, school_id, role)
);

create table public.schoolpro_payment_proofs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  receipt_path text not null unique
);

create or replace function private.has_school_access(
  p_school uuid,
  p_roles public.school_member_role[] default null
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.schoolpro_test_storage_memberships m
    where m.user_id = (select auth.uid())
      and m.school_id = p_school
      and (p_roles is null or m.role = any(p_roles))
  );
$function$;

grant select on public.schoolpro_test_storage_memberships, public.schoolpro_payment_proofs to authenticated;


create table public.schoolpro_payment_submissions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  submitted_by uuid not null,
  receipt_path text not null unique
);

grant select on public.schoolpro_payment_submissions to authenticated;
