-- Test-only schema overlay for the sanitized C0 baseline.
-- The production schema snapshot predates the class/term result-template
-- assignment table. Reproduce its current contract here without replaying
-- the unrelated legacy migration chain.


create table public.schoolpro_result_template_library (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 120),
  storage_path text not null,
  sheet_name text not null,
  template_config jsonb not null check (jsonb_typeof(template_config)='object'),
  is_active boolean not null default true,
  created_by uuid not null references public.profiles(id),
  updated_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id),
  unique (school_id,storage_path),
  check (storage_path like school_id::text||'/%'),
  check (position('..' in storage_path)=0),
  check (octet_length(template_config::text)<=100000)
);

create table public.schoolpro_result_template_section_mappings (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  template_id uuid not null,
  section_key text not null check (section_key in ('nursery','primary','junior_secondary','senior_secondary')),
  mapped_by uuid not null references public.profiles(id),
  mapped_at timestamptz not null default now(),
  unique (school_id,template_id,section_key),
  foreign key (school_id,template_id)
    references public.schoolpro_result_template_library(school_id,id) on delete cascade
);

create table public.schoolpro_result_template_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  term text not null check (term in ('First Term','Second Term','Third Term')),
  session text not null check (char_length(trim(session)) between 4 and 20),
  template_name text not null check (char_length(trim(template_name)) between 1 and 120),
  template_config jsonb not null check (jsonb_typeof(template_config)='object'),
  subject_row_mappings jsonb not null default '{}'::jsonb
    check (jsonb_typeof(subject_row_mappings)='object'),
  updated_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  template_id uuid,
  unique (school_id,class_id,term,session)
);

create index schoolpro_result_template_assignments_lookup_idx
  on public.schoolpro_result_template_assignments(school_id,class_id,session,term);

alter table public.schoolpro_result_template_assignments enable row level security;
create policy schoolpro_result_template_assignments_school_read
  on public.schoolpro_result_template_assignments for select to authenticated
  using (private.has_school_access(school_id));
grant select on public.schoolpro_result_template_assignments to authenticated;
revoke insert,update,delete on public.schoolpro_result_template_assignments from anon,authenticated;

-- The C0 snapshot predates class archival metadata used by current helpers.
alter table public.schoolpro_classes add column if not exists archived_at timestamptz;
