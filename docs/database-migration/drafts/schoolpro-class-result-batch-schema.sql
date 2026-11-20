-- DESIGN DRAFT ONLY — not a Supabase migration and not safe to apply yet.
-- The production output table is student-keyed and its storage policy permits
-- student/guardian reads. Class workbooks therefore require a separate,
-- staff-only bucket and parent batch/review records.

create table public.schoolpro_class_result_batches (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  term text not null check (term in ('First Term','Second Term','Third Term')),
  session text not null check (char_length(trim(session)) between 4 and 20),
  template_assignment_id uuid not null references public.schoolpro_result_template_assignments(id),
  template_id uuid not null references public.schoolpro_result_template_library(id),
  template_assignment_updated_at timestamptz not null,
  template_config_snapshot jsonb not null check (jsonb_typeof(template_config_snapshot)='object' and octet_length(template_config_snapshot::text)<=100000),
  subject_row_mappings_snapshot jsonb not null check (jsonb_typeof(subject_row_mappings_snapshot)='object' and octet_length(subject_row_mappings_snapshot::text)<=100000),
  storage_path text not null unique,
  format text not null default 'xlsx' check (format='xlsx'),
  status text not null default 'uploading'
    check (status in ('uploading','prepared','reviewing','completed','needs_attention','cancelled','failed')),
  expected_student_count integer not null check (expected_student_count between 1 and 500),
  formula_calculation_snapshot jsonb not null default '{}'::jsonb
    check (jsonb_typeof(formula_calculation_snapshot)='object'),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id,school_id,class_id)
);

create index schoolpro_class_result_batches_scope_idx
  on public.schoolpro_class_result_batches(school_id,class_id,session,term,created_at desc);

create table public.schoolpro_class_result_batch_reviews (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null,
  school_id uuid not null,
  class_id uuid not null,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  student_order integer not null check (student_order between 1 and 500),
  subject_row_start integer not null check (subject_row_start between 1 and 1048576),
  subject_row_end integer not null check (subject_row_end between subject_row_start and 1048576),
  review_status text not null default 'pending'
    check (review_status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  generated_result_output_id uuid references public.schoolpro_generated_result_outputs(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (batch_id,student_id),
  unique (batch_id,student_order),
  unique (generated_result_output_id),
  foreign key (batch_id,school_id,class_id)
    references public.schoolpro_class_result_batches(id,school_id,class_id) on delete cascade,
  check (
    (review_status='pending' and reviewed_by is null and reviewed_at is null and generated_result_output_id is null)
    or (review_status='approved' and reviewed_by is not null and reviewed_at is not null and generated_result_output_id is not null)
    or (review_status='rejected' and reviewed_by is not null and reviewed_at is not null and generated_result_output_id is null)
  )
);

create index schoolpro_class_result_batch_reviews_student_idx
  on public.schoolpro_class_result_batch_reviews(school_id,class_id,student_id);

-- Staff-only authorization. Unlike private.schoolpro_can_read_class(), this
-- deliberately excludes student and guardian access.
create or replace function private.schoolpro_can_manage_class_result_batch(
  p_school uuid,p_class uuid,p_session text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null
    and private.is_active_account()
    and exists (
      select 1
      from public.schoolpro_classes c
      where c.id=p_class and c.school_id=p_school and c.archived_at is null
        and (
          private.is_admin(array['super_admin']::public.user_role[])
          or private.has_school_access(
            p_school,
            array['proprietor','administrator','exam_officer','head_teacher','vice_principal']::public.school_member_role[]
          )
          or exists (
            select 1
            from public.schoolpro_members m
            where m.school_id=p_school and m.user_id=auth.uid()
              and m.status='active'
              and m.role in ('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
              and (
                c.form_teacher_id=m.id
                or exists (
                  select 1 from public.schoolpro_subject_assignments a
                  where a.school_id=p_school and a.class_id=p_class
                    and a.session=p_session and a.teacher_member_id=m.id
                )
              )
          )
        )
    );
$$;
revoke all on function private.schoolpro_can_manage_class_result_batch(uuid,uuid,text) from public,anon;
grant execute on function private.schoolpro_can_manage_class_result_batch(uuid,uuid,text) to authenticated;

alter table public.schoolpro_class_result_batches enable row level security;
alter table public.schoolpro_class_result_batch_reviews enable row level security;
create policy schoolpro_class_result_batches_staff_read
  on public.schoolpro_class_result_batches for select to authenticated
  using (private.schoolpro_can_manage_class_result_batch(school_id,class_id,session));
create policy schoolpro_class_result_batch_reviews_staff_read
  on public.schoolpro_class_result_batch_reviews for select to authenticated
  using (private.schoolpro_can_manage_class_result_batch(school_id,class_id,
    (select b.session from public.schoolpro_class_result_batches b where b.id=batch_id)));
revoke all on public.schoolpro_class_result_batches from public,anon,authenticated;
revoke all on public.schoolpro_class_result_batch_reviews from public,anon,authenticated;
grant select on public.schoolpro_class_result_batches,public.schoolpro_class_result_batch_reviews to authenticated;

-- Proposed private bucket. Create/review bucket policies only after the
-- storage policy helper and RPCs have been validated against production.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values (
  'schoolpro-class-result-batches',
  'schoolpro-class-result-batches',
  false,
  52428800,
  array['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
)
on conflict (id) do update
set public=false,
    file_size_limit=excluded.file_size_limit,
    allowed_mime_types=excluded.allowed_mime_types;

-- RPC design contract (implementation still required):
-- 1. schoolpro_create_class_result_batch(...)
--    - auth + active account + results module + staff helper
--    - exact current assignment ID, updated_at and JSON snapshots
--    - roster IDs unique and all belong to this school/class
--    - insert batch in 'uploading' and one pending review row per roster member
--    - enforce safe school/class-scoped storage_path
-- 2. schoolpro_mark_class_result_batch_ready(batch_id)
--    - verify the private storage object exists, then move uploading -> prepared
-- 3. schoolpro_review_class_result_batch_student(batch_id, student_id, decision, output_id)
--    - only approved/rejected decisions; approved requires an existing
--      individual output matching school/student/term/session/xlsx
--    - record reviewer/time; update parent state to reviewing/completed/
--      needs_attention; never expose the class workbook to students/guardians.
-- 4. Storage INSERT/SELECT/DELETE policies must resolve the batch row and call
--    the staff helper. Do not reuse the student-output bucket's policies.
--
-- This draft intentionally omits executable RPC and storage policies until
-- their contracts and privilege boundaries are implemented and tested.
