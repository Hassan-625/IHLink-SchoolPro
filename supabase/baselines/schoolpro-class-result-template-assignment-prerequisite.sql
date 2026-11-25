-- Test-only schema overlay for the sanitized C0 baseline.
-- The sanitized snapshot omits the private-schema USAGE grant required for
-- authenticated Storage RLS policies to invoke the private authorization helpers.
-- This grant is confined to the disposable CI database baseline.
grant usage on schema private to authenticated;

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

-- Match the current production membership lifecycle columns missing from C0.
alter table public.schoolpro_members
  add column if not exists status text not null default 'active';

-- Match the current production employment lifecycle field missing from C0.
alter table public.schoolpro_members
  add column if not exists employment_status text not null default 'active';

-- Match production's subject-assignment lifecycle fields missing from C0.
alter table public.schoolpro_subject_assignments
  add column if not exists ended_at timestamptz,
  add column if not exists ended_by uuid,
  add column if not exists end_reason text;

-- The C0 snapshot also predates the immutable assignment/formula snapshots
-- added to generated outputs by the class/term assignment migration.
alter table public.schoolpro_generated_result_outputs
  add column if not exists template_assignment_id uuid,
  add column if not exists template_id uuid,
  add column if not exists template_assignment_updated_at timestamptz,
  add column if not exists template_config_snapshot jsonb,
  add column if not exists subject_row_mappings_snapshot jsonb,
  add column if not exists formula_calculation_snapshot jsonb not null default '{}'::jsonb;

alter table public.schoolpro_generated_result_outputs
  drop constraint if exists schoolpro_generated_result_outputs_template_config_snapshot_object,
  add constraint schoolpro_generated_result_outputs_template_config_snapshot_object
    check (template_config_snapshot is null or jsonb_typeof(template_config_snapshot)='object'),
  drop constraint if exists schoolpro_generated_result_outputs_subject_row_mappings_snapshot_object,
  add constraint schoolpro_generated_result_outputs_subject_row_mappings_snapshot_object
    check (subject_row_mappings_snapshot is null or jsonb_typeof(subject_row_mappings_snapshot)='object');

-- The sanitized baseline omits the private result-output bucket that exists
-- in production. Recreate only its bucket metadata for the disposable test.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values (
  'schoolpro-result-outputs',
  'schoolpro-result-outputs',
  false,
  10485760,
  array['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/octet-stream']
)
on conflict (id) do update
set name=excluded.name,
    public=false,
    file_size_limit=excluded.file_size_limit,
    allowed_mime_types=excluded.allowed_mime_types;

-- Match the production canonical-subject marker omitted from the sanitized C0
-- schema snapshot. The routed Results UI queries this field when loading the
-- school's subject catalogue.
alter table public.schoolpro_subjects
  add column if not exists is_catalogue_entry boolean not null default false;

-- The sanitized baseline omits production's private template-storage read
-- policy. Permit an authenticated member with school access (including the
-- disposable fixture owner) to download only objects under that school folder.
drop policy if exists school_result_templates_school_read on storage.objects;
create policy school_result_templates_school_read
  on storage.objects for select to authenticated
  using (
    bucket_id = 'school-result-templates'
    and exists (
      select 1
      from public.schoolpro_schools s
      where s.id = (storage.foldername(name))[1]::uuid
        and (s.owner_id = (select auth.uid()) or private.has_school_access(s.id))
    )
  );
