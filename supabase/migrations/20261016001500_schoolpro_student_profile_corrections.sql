-- Student middle names and auditable school-authorized profile corrections.
alter table public.schoolpro_students add column if not exists middle_name text;
create table if not exists public.schoolpro_student_profile_audit (
 id uuid primary key default gen_random_uuid(),
 school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 student_id uuid not null references public.schoolpro_students(id) on delete cascade,
 changed_by uuid not null references auth.users(id) on delete restrict,
 changed_at timestamptz not null default now(),
 changed_fields text[] not null,
 before_values jsonb not null default '{}'::jsonb,
 after_values jsonb not null default '{}'::jsonb
);
create index if not exists schoolpro_student_profile_audit_student_idx on public.schoolpro_student_profile_audit(school_id,student_id,changed_at desc);
alter table public.schoolpro_student_profile_audit enable row level security;
drop policy if exists schoolpro_student_profile_audit_select on public.schoolpro_student_profile_audit;
create policy schoolpro_student_profile_audit_select on public.schoolpro_student_profile_audit for select to authenticated
using (private.has_school_access(school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'registrar'::public.school_member_role]));
drop policy if exists schoolpro_student_profile_audit_insert on public.schoolpro_student_profile_audit;
create policy schoolpro_student_profile_audit_insert on public.schoolpro_student_profile_audit for insert to authenticated
with check (changed_by=auth.uid() and private.has_school_access(school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'registrar'::public.school_member_role]));
