create table public.schoolpro_classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null,
  arm text not null default '',
  level text not null check (level in ('nursery','primary','junior_secondary','senior_secondary','other')),
  capacity integer not null default 40 check (capacity between 1 and 500),
  form_teacher_id uuid references public.schoolpro_members(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,name,arm)
);
create index schoolpro_classes_school_idx on public.schoolpro_classes (school_id,name);
create index schoolpro_classes_teacher_idx on public.schoolpro_classes (form_teacher_id);
alter table public.schoolpro_classes enable row level security;
create policy "School users read classes" on public.schoolpro_classes for select to authenticated using (private.has_school_access(school_id));
create policy "School leaders insert classes" on public.schoolpro_classes for insert to authenticated with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders update classes" on public.schoolpro_classes for update to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])) with check (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders delete classes" on public.schoolpro_classes for delete to authenticated using (private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
grant select,insert,update,delete on public.schoolpro_classes to authenticated;

