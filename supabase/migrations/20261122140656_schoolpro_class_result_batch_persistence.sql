-- EXECUTABLE CANDIDATE SQL — NOT A PRODUCTION MIGRATION.
-- Generate the eventual migration with `supabase migration new ...` after
-- local CLI validation. This file is deliberately kept under drafts until
-- the RPCs and storage policies have passed disposable-database regression.
--
-- Contract:
--   * Client sends a session-resolved roster; this SQL revalidates every
--     student against schoolpro_enrollment_history (never current_class_id).
--   * Class workbooks live in a separate private bucket, never in the
--     student-keyed schoolpro_generated_result_outputs bucket.
--   * Only Super Admin, school owner/leadership/Exam Officer, the class Form
--     Master, or a teacher assigned to the class/session can access batches.
--   * Official per-student outputs remain separate and are linked on approval.

create table public.schoolpro_class_result_batches (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  term text not null check (term in ('First Term','Second Term','Third Term')),
  session text not null check (session ~ '^[0-9]{4}[/\-][0-9]{4}$'),
  template_assignment_id uuid not null references public.schoolpro_result_template_assignments(id),
  template_id uuid not null,
  template_assignment_updated_at timestamptz not null,
  template_config_snapshot jsonb not null
    check (jsonb_typeof(template_config_snapshot)='object' and octet_length(template_config_snapshot::text)<=100000),
  subject_row_mappings_snapshot jsonb not null
    check (jsonb_typeof(subject_row_mappings_snapshot)='object' and octet_length(subject_row_mappings_snapshot::text)<=100000),
  formula_calculation_snapshot jsonb not null
    check (jsonb_typeof(formula_calculation_snapshot)='object' and octet_length(formula_calculation_snapshot::text)<=100000),
  storage_path text not null unique,
  format text not null default 'xlsx' check (format='xlsx'),
  status text not null default 'uploading'
    check (status in ('uploading','prepared','reviewing','completed','needs_attention','cancelled','failed')),
  expected_student_count integer not null check (expected_student_count between 1 and 500),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id,school_id,class_id,session,term),
  foreign key (school_id,template_id)
    references public.schoolpro_result_template_library(school_id,id)
);

create index schoolpro_class_result_batches_scope_idx
  on public.schoolpro_class_result_batches(school_id,class_id,session,term,created_at desc);

create table public.schoolpro_class_result_batch_reviews (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null,
  school_id uuid not null,
  class_id uuid not null,
  session text not null,
  term text not null,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  student_order integer not null check (student_order between 1 and 500),
  student_storage_path text not null unique,
  subject_row_start integer,
  subject_row_end integer,
  review_status text not null default 'pending'
    check (review_status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  generated_result_output_id uuid references public.schoolpro_generated_result_outputs(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (batch_id,student_id),
  unique (batch_id,student_order),
  unique (generated_result_output_id),
  foreign key (batch_id,school_id,class_id,session,term)
    references public.schoolpro_class_result_batches(id,school_id,class_id,session,term) on delete cascade,
  check (
    (subject_row_start is null and subject_row_end is null)
    or (subject_row_start between 1 and 1048576
        and subject_row_end between subject_row_start and 1048576)
  ),
  check (
    (review_status='pending' and reviewed_by is null and reviewed_at is null and generated_result_output_id is null)
    or (review_status='approved' and reviewed_by is not null and reviewed_at is not null and generated_result_output_id is not null)
    or (review_status='rejected' and reviewed_by is not null and reviewed_at is not null and generated_result_output_id is null)
  )
);

create index schoolpro_class_result_batch_reviews_student_idx
  on public.schoolpro_class_result_batch_reviews(school_id,class_id,session,student_id);

-- This helper intentionally does not call private.has_school_access(): that
-- helper also admits generic platform admins. The batch boundary is explicit.
create or replace function private.schoolpro_can_manage_class_result_batch(
  p_school uuid,p_class uuid,p_session text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null
    and coalesce(private.is_active_account(),false)
    and exists (
      select 1
      from public.schoolpro_classes c
      join public.schoolpro_schools s on s.id=c.school_id
      where c.id=p_class and c.school_id=p_school and c.archived_at is null
        and (
          private.is_admin(array['super_admin']::public.user_role[])
          or s.owner_id=(select auth.uid())
          or exists (
            select 1 from public.schoolpro_members m
            where m.school_id=p_school and m.user_id=(select auth.uid())
              and m.status='active' and m.employment_status='active'
              and m.role in (
                'proprietor'::public.school_member_role,
                'administrator'::public.school_member_role,
                'exam_officer'::public.school_member_role,
                'head_teacher'::public.school_member_role,
                'vice_principal'::public.school_member_role
              )
          )
          or exists (
            select 1
            from public.schoolpro_members m
            where m.school_id=p_school and m.user_id=(select auth.uid())
              and m.status='active' and m.employment_status='active'
              and m.role in (
                'teacher'::public.school_member_role,
                'class_teacher'::public.school_member_role
              )
              and (
                c.form_teacher_id=m.id
                or exists (
                  select 1 from public.schoolpro_subject_assignments a
                  where a.school_id=p_school and a.class_id=p_class
                    and a.session=trim(p_session) and a.teacher_member_id=m.id
                    and a.ended_at is null
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
  using (
    private.schoolpro_can_manage_class_result_batch(school_id,class_id,session)
    and private.schoolpro_module_allowed(school_id,'results')
  );

create policy schoolpro_class_result_batch_reviews_staff_read
  on public.schoolpro_class_result_batch_reviews for select to authenticated
  using (
    private.schoolpro_can_manage_class_result_batch(school_id,class_id,session)
    and private.schoolpro_module_allowed(school_id,'results')
  );

revoke all on public.schoolpro_class_result_batches from public,anon,authenticated;
revoke all on public.schoolpro_class_result_batch_reviews from public,anon,authenticated;
grant select on public.schoolpro_class_result_batches,public.schoolpro_class_result_batch_reviews to authenticated;

-- The API receives the client-built roster, but trusts none of its membership
-- claims. Every student is checked against the exact historical enrollment.
create or replace function public.schoolpro_create_class_result_batch(
  p_school uuid,
  p_class uuid,
  p_term text,
  p_session text,
  p_template_assignment_id uuid,
  p_template_id uuid,
  p_template_assignment_updated_at timestamptz,
  p_template_config_snapshot jsonb,
  p_subject_row_mappings_snapshot jsonb,
  p_formula_calculation_snapshot jsonb,
  p_students jsonb
) returns uuid
language plpgsql security definer set search_path=''
as $$
declare
  v_assignment public.schoolpro_result_template_assignments%rowtype;
  v_batch_id uuid:=gen_random_uuid();
  v_storage_path text;
  v_expected integer;
  v_distinct_ids integer;
  v_distinct_orders integer;
  v_members integer;
begin
  if auth.uid() is null or not coalesce(private.is_active_account(),false)
     or not coalesce(private.schoolpro_module_allowed(p_school,'results'),false)
     or not private.schoolpro_can_manage_class_result_batch(p_school,p_class,p_session) then
    raise exception 'An active, authorized SchoolPro results staff member is required';
  end if;

  if p_school is null or p_class is null
     or trim(coalesce(p_term,'')) not in ('First Term','Second Term','Third Term')
     or trim(coalesce(p_session,'')) !~ '^[0-9]{4}[/\-][0-9]{4}$'
     or p_template_assignment_id is null or p_template_id is null
     or p_template_assignment_updated_at is null
     or jsonb_typeof(p_template_config_snapshot)<>'object'
     or jsonb_typeof(p_subject_row_mappings_snapshot)<>'object'
     or jsonb_typeof(p_formula_calculation_snapshot)<>'object'
     or p_formula_calculation_snapshot->>'engine' is distinct from 'hot-formula-parser'
     or p_formula_calculation_snapshot->>'engineVersion' is distinct from '4.0.0'
     or p_formula_calculation_snapshot->>'calculationMode' is distinct from 'same-sheet-dependency-graph'
     or jsonb_typeof(p_formula_calculation_snapshot->'formulaCount') is distinct from 'number'
     or coalesce(p_formula_calculation_snapshot->>'formulaCount','') !~ '^[0-9]+$'
     or jsonb_typeof(p_students)<>'array' then
    raise exception 'The class-result batch metadata is invalid';
  end if;

  if not exists (
    select 1 from public.schoolpro_classes c
    where c.id=p_class and c.school_id=p_school and c.archived_at is null
  ) then
    raise exception 'The selected class is unavailable in this school';
  end if;

  select count(*) into v_expected from jsonb_array_elements(p_students);
  if v_expected<1 or v_expected>500 then
    raise exception 'A class-result batch must contain between 1 and 500 students';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_students) x
    where jsonb_typeof(x)<>'object'
      or not (coalesce(x->>'student_id','') ~* $re$^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$re$)
      or coalesce(x->>'student_order','') !~ '^[0-9]{1,3}$'
      or (jsonb_exists(x,'subject_row_start') and coalesce(x->>'subject_row_start','') !~ '^[0-9]{1,7}$')
      or (jsonb_exists(x,'subject_row_end') and coalesce(x->>'subject_row_end','') !~ '^[0-9]{1,7}$')
      or ((jsonb_exists(x,'subject_row_start')) <> (jsonb_exists(x,'subject_row_end')))
      or (jsonb_exists(x,'subject_row_start') and ((x->>'subject_row_start')::integer<1
          or (x->>'subject_row_end')::integer<(x->>'subject_row_start')::integer
          or (x->>'subject_row_end')::integer>1048576))
  ) then
    raise exception 'The roster contains an invalid student ID, order, or worksheet row range';
  end if;

  select count(distinct x->>'student_id'),count(distinct x->>'student_order')
    into v_distinct_ids,v_distinct_orders
  from jsonb_array_elements(p_students) x;

  if v_distinct_ids<>v_expected or v_distinct_orders<>v_expected
     or (select min((x->>'student_order')::integer) from jsonb_array_elements(p_students) x)<>1
     or (select max((x->>'student_order')::integer) from jsonb_array_elements(p_students) x)<>v_expected then
    raise exception 'The roster must have unique student IDs and contiguous student order';
  end if;

  -- Resolve every submitted ID against the immutable session history.
  select count(distinct eh.student_id) into v_members
  from jsonb_array_elements(p_students) x
  join public.schoolpro_enrollment_history eh
    on eh.student_id=(x->>'student_id')::uuid
   and eh.school_id=p_school
   and eh.class_id=p_class
   and eh.session=trim(p_session)
   and eh.status='active'
   and not exists (
     select 1 from public.schoolpro_enrollment_history other
     where other.school_id=eh.school_id
       and other.student_id=eh.student_id
       and other.session=eh.session
       and other.status='active'
       and other.class_id is distinct from p_class
   )
  join public.schoolpro_students st
    on st.id=eh.student_id and st.school_id=p_school;

  if v_members<>v_expected then
    raise exception 'The submitted roster does not match this school, class, and academic-session enrollment history';
  end if;

  select a.* into v_assignment
  from public.schoolpro_result_template_assignments a
  where a.id=p_template_assignment_id
    and a.school_id=p_school and a.class_id=p_class
    and a.term=trim(p_term) and a.session=trim(p_session)
  for update;

  if not found
     or v_assignment.template_id<>p_template_id
     or v_assignment.updated_at is distinct from p_template_assignment_updated_at
     or v_assignment.template_config is distinct from p_template_config_snapshot
     or v_assignment.subject_row_mappings is distinct from p_subject_row_mappings_snapshot
     or not exists (
       select 1 from public.schoolpro_result_template_library t
       where t.id=p_template_id and t.school_id=p_school and t.is_active
     ) then
    raise exception 'The assigned result design changed or is no longer active. Refresh the template and generate a new preview.';
  end if;

  v_storage_path:=p_school::text||'/'||p_class::text||'/'||v_batch_id::text||'/workbook.xlsx';

  insert into public.schoolpro_class_result_batches(
    id,school_id,class_id,term,session,template_assignment_id,template_id,
    template_assignment_updated_at,template_config_snapshot,
    subject_row_mappings_snapshot,formula_calculation_snapshot,
    storage_path,expected_student_count,created_by
  ) values (
    v_batch_id,p_school,p_class,trim(p_term),trim(p_session),
    v_assignment.id,v_assignment.template_id,v_assignment.updated_at,
    v_assignment.template_config,v_assignment.subject_row_mappings,
    p_formula_calculation_snapshot,v_storage_path,v_expected,auth.uid()
  );

  insert into public.schoolpro_class_result_batch_reviews(
    batch_id,school_id,class_id,session,term,student_id,student_order,
    student_storage_path,subject_row_start,subject_row_end
  )
  select v_batch_id,p_school,p_class,trim(p_session),trim(p_term),
    (x->>'student_id')::uuid,(x->>'student_order')::integer,
    p_school::text||'/'||p_class::text||'/'||v_batch_id::text||'/students/'||(x->>'student_id')||'.xlsx',
    case when jsonb_exists(x,'subject_row_start') then (x->>'subject_row_start')::integer end,
    case when jsonb_exists(x,'subject_row_end') then (x->>'subject_row_end')::integer end
  from jsonb_array_elements(p_students) x;

  return v_batch_id;
end;
$$;
revoke all on function public.schoolpro_create_class_result_batch(uuid,uuid,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb,jsonb) from public,anon;
grant execute on function public.schoolpro_create_class_result_batch(uuid,uuid,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb,jsonb) to authenticated;

create or replace function public.schoolpro_fail_class_result_batch_upload(p_batch_id uuid)
returns text
language plpgsql security definer set search_path=''
as $fail_upload$
declare
  v_batch public.schoolpro_class_result_batches%rowtype;
begin
  if auth.uid() is null or not coalesce(private.is_active_account(),false) then
    raise exception 'An active account is required';
  end if;

  select b.* into v_batch
  from public.schoolpro_class_result_batches b
  where b.id=p_batch_id
  for update;

  if not found
     or v_batch.created_by<>(select auth.uid())
     or not private.schoolpro_can_manage_class_result_batch(v_batch.school_id,v_batch.class_id,v_batch.session)
     or not private.schoolpro_module_allowed(v_batch.school_id,'results') then
    raise exception 'The class-result batch is unavailable';
  end if;
  if v_batch.status<>'uploading' then
    raise exception 'Only an uploading class-result batch can be failed';
  end if;

  update public.schoolpro_class_result_batches
  set status='failed',updated_at=now()
  where id=p_batch_id;
  return 'failed';
end;
$fail_upload$;
revoke all on function public.schoolpro_fail_class_result_batch_upload(uuid) from public,anon;
grant execute on function public.schoolpro_fail_class_result_batch_upload(uuid) to authenticated;

create or replace function public.schoolpro_mark_class_result_batch_ready(p_batch_id uuid)
returns text
language plpgsql security definer set search_path=''
as $$
declare
  v_batch public.schoolpro_class_result_batches%rowtype;
begin
  if auth.uid() is null or not coalesce(private.is_active_account(),false) then
    raise exception 'An active account is required';
  end if;

  select b.* into v_batch
  from public.schoolpro_class_result_batches b
  where b.id=p_batch_id
  for update;

  if not found
     or not private.schoolpro_can_manage_class_result_batch(v_batch.school_id,v_batch.class_id,v_batch.session)
     or not private.schoolpro_module_allowed(v_batch.school_id,'results') then
    raise exception 'The class-result batch is unavailable';
  end if;
  -- The ready transition is idempotent for a batch already prepared.
  -- This is required when official outputs are registered after preparation
  -- and callers re-check readiness before finalizing individual reviews.
  if v_batch.status='prepared' then
    return 'prepared';
  end if;
  if v_batch.status<>'uploading' then
    raise exception 'Only an uploading class-result batch can be marked ready';
  end if;
  if not exists (
    select 1 from storage.objects o
    where o.bucket_id='schoolpro-class-result-batches'
      and o.name=v_batch.storage_path
      and coalesce(o.owner_id,o.owner::text)=(select auth.uid())::text
  ) or exists (
    select 1 from public.schoolpro_class_result_batch_reviews r
    where r.batch_id=p_batch_id
      and not exists (
        select 1 from storage.objects o
        where o.bucket_id='schoolpro-class-result-batches'
          and o.name=r.student_storage_path
          and coalesce(o.owner_id,o.owner::text)=(select auth.uid())::text
      )
  ) then
    raise exception 'The private class register and every student workbook upload must be verified';
  end if;

  update public.schoolpro_class_result_batches
  set status='prepared',updated_at=now()
  where id=p_batch_id;
  return 'prepared';
end;
$$;
revoke all on function public.schoolpro_mark_class_result_batch_ready(uuid) from public,anon;
grant execute on function public.schoolpro_mark_class_result_batch_ready(uuid) to authenticated;

create or replace function public.schoolpro_review_class_result_batch_student(
  p_batch_id uuid,
  p_student_id uuid,
  p_decision text,
  p_output_id uuid default null
) returns text
language plpgsql security definer set search_path=''
as $$
declare
  v_batch public.schoolpro_class_result_batches%rowtype;
  v_review public.schoolpro_class_result_batch_reviews%rowtype;
  v_rejected integer;
  v_pending integer;
  v_next_status text;
begin
  if auth.uid() is null or not coalesce(private.is_active_account(),false) then
    raise exception 'An active account is required';
  end if;

  select b.* into v_batch
  from public.schoolpro_class_result_batches b
  where b.id=p_batch_id
  for update;

  if not found
     or not private.schoolpro_can_manage_class_result_batch(v_batch.school_id,v_batch.class_id,v_batch.session)
     or not private.schoolpro_module_allowed(v_batch.school_id,'results') then
    raise exception 'The class-result batch is unavailable';
  end if;
  if v_batch.status not in ('prepared','reviewing','needs_attention') then
    raise exception 'This class-result batch is not open for review';
  end if;
  if lower(trim(coalesce(p_decision,''))) not in ('approved','rejected') then
    raise exception 'Review decision must be approved or rejected';
  end if;

  select r.* into v_review
  from public.schoolpro_class_result_batch_reviews r
  where r.batch_id=p_batch_id and r.student_id=p_student_id
  for update;

  if not found then
    raise exception 'The student is not part of this class-result batch';
  end if;
  if v_review.review_status='approved' then
    raise exception 'An approved student review cannot be changed';
  end if;

  if lower(trim(p_decision))='approved' then
    if p_output_id is null or not exists (
      select 1
      from public.schoolpro_generated_result_outputs o
      where o.id=p_output_id
        and o.school_id=v_batch.school_id
        and o.student_id=p_student_id
        and o.term=v_batch.term
        and o.session=v_batch.session
        and o.format='xlsx'
        and o.template_assignment_id=v_batch.template_assignment_id
        and o.template_id=v_batch.template_id
        and o.template_assignment_updated_at=v_batch.template_assignment_updated_at
        and o.template_config_snapshot=v_batch.template_config_snapshot
        and o.subject_row_mappings_snapshot=v_batch.subject_row_mappings_snapshot
        and exists (
          select 1 from storage.objects so
          where so.bucket_id='schoolpro-result-outputs' and so.name=o.storage_path
        )
    ) then
      raise exception 'Approval requires the matching official individual student workbook output';
    end if;
  elsif p_output_id is not null then
    raise exception 'A rejected student review cannot link an official output';
  end if;

  update public.schoolpro_class_result_batch_reviews
  set review_status=lower(trim(p_decision)),
      reviewed_by=auth.uid(),reviewed_at=now(),
      generated_result_output_id=case when lower(trim(p_decision))='approved' then p_output_id else null end
  where id=v_review.id;

  select count(*) filter (where review_status='rejected'),
         count(*) filter (where review_status='pending')
    into v_rejected,v_pending
  from public.schoolpro_class_result_batch_reviews
  where batch_id=p_batch_id;

  v_next_status:=case
    when v_rejected>0 then 'needs_attention'
    when v_pending=0 then 'completed'
    else 'reviewing'
  end;

  update public.schoolpro_class_result_batches
  set status=v_next_status,updated_at=now()
  where id=p_batch_id;

  return v_next_status;
end;
$$;
revoke all on function public.schoolpro_review_class_result_batch_student(uuid,uuid,text,uuid) from public,anon;
grant execute on function public.schoolpro_review_class_result_batch_student(uuid,uuid,text,uuid) to authenticated;


-- Align official per-student output persistence with the same historical
-- school/class/session enrollment contract enforced by class-batch creation.
create or replace function public.schoolpro_record_generated_result_output(
  p_school uuid,
  p_student uuid,
  p_class uuid,
  p_term text,
  p_session text,
  p_storage_path text,
  p_template_assignment_id uuid,
  p_template_id uuid,
  p_template_assignment_updated_at timestamptz,
  p_template_config_snapshot jsonb,
  p_subject_row_mappings_snapshot jsonb,
  p_formula_calculation_snapshot jsonb
) returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  v_assignment public.schoolpro_result_template_assignments%rowtype;
  v_output_id uuid;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.has_school_access(p_school) then
    raise exception 'An active member of this school is required to save a generated result';
  end if;
  if p_school is null or p_student is null or p_class is null
     or p_template_assignment_id is null or p_template_id is null
     or p_template_assignment_updated_at is null
     or p_term not in ('First Term','Second Term','Third Term')
     or char_length(trim(coalesce(p_session,''))) not between 4 and 20
     or nullif(trim(coalesce(p_storage_path,'')),'') is null
     or p_storage_path not like p_school::text||'/'||p_student::text||'/%'
     or position('..' in coalesce(p_storage_path,''))>0
     or jsonb_typeof(p_template_config_snapshot)<>'object'
     or jsonb_typeof(p_subject_row_mappings_snapshot)<>'object'
     or jsonb_typeof(p_formula_calculation_snapshot)<>'object'
     or p_formula_calculation_snapshot->>'engine' is distinct from 'hot-formula-parser'
     or p_formula_calculation_snapshot->>'engineVersion' is distinct from '4.0.0'
     or coalesce((p_formula_calculation_snapshot->>'formulaCount')::integer,-1)<0
     or p_formula_calculation_snapshot->>'calculationMode' is distinct from 'same-sheet-dependency-graph' then
    raise exception 'The generated result metadata is invalid';
  end if;

  if not exists (
    select 1 from public.schoolpro_enrollment_history eh
    join public.schoolpro_students st on st.id=eh.student_id and st.school_id=eh.school_id
    where eh.school_id=p_school and eh.student_id=p_student
      and eh.class_id=p_class and eh.session=trim(p_session)
      and eh.status='active'
      and not exists (
        select 1 from public.schoolpro_enrollment_history other
        where other.school_id=eh.school_id and other.student_id=eh.student_id
          and other.session=eh.session and other.status='active'
          and other.class_id is distinct from p_class
      )
  ) then
    raise exception 'The selected student is not actively enrolled in this school, class and academic session';
  end if;

  select a.* into v_assignment
  from public.schoolpro_result_template_assignments a
  where a.school_id=p_school and a.class_id=p_class
    and a.term=trim(p_term) and a.session=trim(p_session)
  for update;
  if not found
     or v_assignment.id<>p_template_assignment_id
     or v_assignment.template_id<>p_template_id
     or v_assignment.updated_at is distinct from p_template_assignment_updated_at
     or v_assignment.template_config is distinct from p_template_config_snapshot
     or v_assignment.subject_row_mappings is distinct from p_subject_row_mappings_snapshot then
    raise exception 'The class result design or subject mapping changed after preview. Refresh and generate a new preview.';
  end if;

  if not exists(
    select 1 from storage.objects o
    where o.bucket_id='schoolpro-result-outputs' and o.name=p_storage_path
  ) then
    raise exception 'The generated workbook upload could not be verified';
  end if;

  insert into public.schoolpro_generated_result_outputs(
    school_id,student_id,term,session,format,storage_path,generated_by,
    template_assignment_id,template_id,template_assignment_updated_at,
    template_config_snapshot,subject_row_mappings_snapshot,formula_calculation_snapshot
  ) values (
    p_school,p_student,trim(p_term),trim(p_session),'xlsx',p_storage_path,auth.uid(),
    v_assignment.id,v_assignment.template_id,v_assignment.updated_at,
    v_assignment.template_config,v_assignment.subject_row_mappings,p_formula_calculation_snapshot
  ) returning id into v_output_id;

  return v_output_id;
end;
$$;
revoke all on function public.schoolpro_record_generated_result_output(
  uuid,uuid,uuid,text,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb
) from public,anon;
grant execute on function public.schoolpro_record_generated_result_output(
  uuid,uuid,uuid,text,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb
) to authenticated;


-- Dedicated private storage namespace. There is no student/guardian policy.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values (
  'schoolpro-class-result-batches',
  'schoolpro-class-result-batches',
  false,
  52428800,
  array['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
);

create policy schoolpro_class_result_batches_storage_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id='schoolpro-class-result-batches'
    and owner_id=(select auth.uid())::text
    and exists (
      select 1
      from public.schoolpro_class_result_batches b
      where b.status='uploading' and b.created_by=(select auth.uid())
        and private.schoolpro_can_manage_class_result_batch(b.school_id,b.class_id,b.session)
        and private.schoolpro_module_allowed(b.school_id,'results')
        and (
          b.storage_path=name
          or exists (
            select 1 from public.schoolpro_class_result_batch_reviews r
            where r.batch_id=b.id and r.student_storage_path=name
          )
        )
    )
  );

create policy schoolpro_class_result_batches_storage_read
  on storage.objects for select to authenticated
  using (
    bucket_id='schoolpro-class-result-batches'
    and exists (
      select 1 from public.schoolpro_class_result_batches b
      where (b.storage_path=name or exists (
        select 1 from public.schoolpro_class_result_batch_reviews r
        where r.batch_id=b.id and r.student_storage_path=name
      ))
        and private.schoolpro_can_manage_class_result_batch(b.school_id,b.class_id,b.session)
        and private.schoolpro_module_allowed(b.school_id,'results')
    )
  );

-- Failed uploads may be removed by authorized staff for a clean retry. Prepared,
-- reviewing, and completed class workbooks are immutable through Storage API.
create policy schoolpro_class_result_batches_storage_delete_failed
  on storage.objects for delete to authenticated
  using (
    bucket_id='schoolpro-class-result-batches'
    and exists (
      select 1 from public.schoolpro_class_result_batches b
      where b.status in ('failed','cancelled')
        and (b.storage_path=name or exists (
          select 1 from public.schoolpro_class_result_batch_reviews r
          where r.batch_id=b.id and r.student_storage_path=name
        ))
        and private.schoolpro_can_manage_class_result_batch(b.school_id,b.class_id,b.session)
        and private.schoolpro_module_allowed(b.school_id,'results')
    )
  );

-- A batch reviewer must be able to upload the official per-student workbook
-- produced by approving a pending review. Scope this insert to the exact
-- school/student folder of a live pending batch review; ordinary staff cannot
-- upload arbitrary official outputs through this policy.
create or replace function private.schoolpro_can_upload_class_result_output(
  p_storage_path text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null
    and coalesce(private.is_active_account(),false)
    and exists (
      select 1
      from public.schoolpro_class_result_batch_reviews r
      join public.schoolpro_class_result_batches b on b.id=r.batch_id
      where left(
          p_storage_path,
          length(r.school_id::text||'/'||r.student_id::text||'/')
        )=r.school_id::text||'/'||r.student_id::text||'/'
        and r.review_status='pending'
        and r.generated_result_output_id is null
        and b.status in ('prepared','reviewing')
        and b.school_id=r.school_id
        and b.class_id=r.class_id
        and b.session=r.session
        and private.schoolpro_can_manage_class_result_batch(
          b.school_id,b.class_id,b.session
        )
        and private.schoolpro_module_allowed(b.school_id,'results')
    );
$$;

revoke all on function private.schoolpro_can_upload_class_result_output(text) from public,anon;
grant execute on function private.schoolpro_can_upload_class_result_output(text) to authenticated;

create policy schoolpro_class_result_outputs_batch_insert
  on storage.objects for insert to authenticated
  with check (
    bucket_id='schoolpro-result-outputs'
    and owner_id=(select auth.uid())::text
    and private.schoolpro_can_upload_class_result_output(name)
  );

-- Authenticated reviewers must also be able to read the exact official object
-- after it is uploaded and recorded, both while the review is pending and
-- after it is approved. Do not grant general access to the output bucket.
create or replace function private.schoolpro_can_read_class_result_output(
  p_storage_path text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null
    and coalesce(private.is_active_account(),false)
    and exists (
      select 1
      from public.schoolpro_generated_result_outputs o
      join public.schoolpro_class_result_batch_reviews r
        on r.school_id=o.school_id and r.student_id=o.student_id
       and r.term=o.term and r.session=o.session
      join public.schoolpro_class_result_batches b on b.id=r.batch_id
      where o.storage_path=p_storage_path
        and (
          (r.review_status='pending'
            and r.generated_result_output_id is null
            and o.generated_by=auth.uid()
            and b.status in ('prepared','reviewing'))
          or
          (r.review_status='approved'
            and r.generated_result_output_id=o.id
            and b.status='completed')
        )
        and private.schoolpro_can_manage_class_result_batch(
          b.school_id,b.class_id,b.session
        )
        and private.schoolpro_module_allowed(b.school_id,'results')
    );
$$;

revoke all on function private.schoolpro_can_read_class_result_output(text) from public,anon;
grant execute on function private.schoolpro_can_read_class_result_output(text) to authenticated;

create policy schoolpro_class_result_outputs_batch_read
  on storage.objects for select to authenticated
  using (
    bucket_id='schoolpro-result-outputs'
    and private.schoolpro_can_read_class_result_output(name)
  );
