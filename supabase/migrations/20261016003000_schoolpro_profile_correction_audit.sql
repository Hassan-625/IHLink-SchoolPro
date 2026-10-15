-- Profile correction audit for staff and parent/guardian identity fields.
alter table public.profiles add column if not exists phone text;
create table if not exists public.schoolpro_profile_change_audit (
 id uuid primary key default gen_random_uuid(),
 school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 target_user_id uuid not null references auth.users(id) on delete restrict,
 changed_by uuid not null references auth.users(id) on delete restrict,
 changed_at timestamptz not null default now(),
 changed_fields text[] not null,
 before_values jsonb not null default '{}'::jsonb,
 after_values jsonb not null default '{}'::jsonb
);
create index if not exists schoolpro_profile_change_audit_school_target_idx on public.schoolpro_profile_change_audit(school_id,target_user_id,changed_at desc);
alter table public.schoolpro_profile_change_audit enable row level security;
drop policy if exists schoolpro_profile_change_audit_select on public.schoolpro_profile_change_audit;
create policy schoolpro_profile_change_audit_select on public.schoolpro_profile_change_audit for select to authenticated
using (private.has_school_access(school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role]));

grant select on public.schoolpro_profile_change_audit to authenticated;
