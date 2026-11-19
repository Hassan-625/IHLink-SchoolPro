begin;

-- Stage C five-step lifecycle: Form Master submission is received by the Exam
-- Officer first; the Exam Officer validates the complete class matrix and
-- explicitly forwards it to the appointed Section Head.
create table if not exists public.schoolpro_result_first_reviews (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  class_id uuid not null,
  term text not null,
  session text not null,
  reviewed_by uuid not null,
  reviewed_at timestamptz not null default now(),
  notes text,
  result_count integer not null check (result_count > 0),
  status text not null default 'forwarded' check (status in ('forwarded', 'invalidated'))
);

create unique index if not exists schoolpro_result_first_reviews_one_forwarded_idx
  on public.schoolpro_result_first_reviews(school_id, class_id, term, session)
  where status = 'forwarded';

create index if not exists schoolpro_result_first_reviews_scope_idx
  on public.schoolpro_result_first_reviews(school_id, term, session, class_id, reviewed_at desc);

alter table public.schoolpro_result_first_reviews enable row level security;
revoke all on public.schoolpro_result_first_reviews from public, anon, authenticated;
grant select on public.schoolpro_result_first_reviews to authenticated;
drop policy if exists schoolpro_result_first_reviews_scoped_read
  on public.schoolpro_result_first_reviews;
create policy schoolpro_result_first_reviews_scoped_read
  on public.schoolpro_result_first_reviews
  for select to authenticated
  using (private.schoolpro_can_read_class_result_submission(school_id, class_id));

create or replace function private.schoolpro_invalidate_result_first_review_on_workflow_reset()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.status in ('draft', 'correction_requested')
     and old.status not in ('draft', 'correction_requested') then
    update public.schoolpro_result_first_reviews
    set status = 'invalidated'
    where school_id = new.school_id and class_id = new.class_id
      and term = new.term and session = new.session and status = 'forwarded';
  end if;
  return new;
end
$function$;

revoke all on function private.schoolpro_invalidate_result_first_review_on_workflow_reset()
  from public, anon, authenticated;

drop trigger if exists schoolpro_invalidate_result_first_review_on_workflow_reset
  on public.schoolpro_result_workflow;
create trigger schoolpro_invalidate_result_first_review_on_workflow_reset
after update of status on public.schoolpro_result_workflow
for each row execute function private.schoolpro_invalidate_result_first_review_on_workflow_reset();

create or replace function public.schoolpro_exam_officer_review_class_results(
  p_school uuid,
  p_class uuid,
  p_term text,
  p_session text,
  p_notes text default null
) returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_count integer;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'Authentication required';
  end if;
  if not coalesce(private.schoolpro_module_allowed(p_school, 'results'), false) then
    raise exception 'Module permission denied: results';
  end if;
  -- A Super Admin is not implicitly an appointed Exam Officer for this
  -- operational review stage; the platform role remains distinct.
  if not private.schoolpro_is_exam_officer(p_school) then
    raise exception 'Only the appointed Exam Officer can perform first result review';
  end if;
  if p_class is null or nullif(trim(p_term), '') is null
     or nullif(trim(p_session), '') is null then
    raise exception 'Choose a class, term and academic session';
  end if;
  if length(trim(coalesce(p_notes, ''))) > 2000 then
    raise exception 'First-review notes cannot exceed 2000 characters';
  end if;

  perform private.schoolpro_lock_result_scope(
    p_school, p_term, p_session, 'class', p_class, null
  );

  if not private.schoolpro_class_result_matrix_complete(
    p_school, p_class, p_term, p_session
  ) then
    raise exception 'First review blocked: every student must have a complete Draft result for every subject allocated to this class';
  end if;

  if not private.schoolpro_result_scope_mixed_state(
    p_school, p_term, p_session, 'class', p_class, null, 'section'
  ) then
    raise exception 'First review blocked: every allocated student/subject result must have a matching submitted workflow record';
  end if;

  if exists (
    select 1
    from public.schoolpro_result_workflow w
    join public.schoolpro_classes c
      on c.id = w.class_id and c.school_id = w.school_id
    left join public.schoolpro_results r on r.id = w.result_id
    where w.school_id = p_school and w.class_id = p_class
      and w.term = trim(p_term) and w.session = trim(p_session)
      and (w.status <> 'submitted' or r.id is null or r.status <> 'draft' or r.locked)
  ) then
    raise exception 'First review requires every class result to be submitted and remain an unlocked Draft';
  end if;

  with roster as (
    select s.id as student_id
    from public.schoolpro_students s
    where s.school_id = p_school and (
      exists (
        select 1 from public.schoolpro_enrollment_history h
        where h.school_id = p_school and h.student_id = s.id
          and h.session = trim(p_session) and h.class_id = p_class
      )
      or (s.status = 'active' and s.class_id = p_class and not exists (
        select 1 from public.schoolpro_enrollment_history h
        where h.school_id = p_school and h.student_id = s.id
          and h.session = trim(p_session)
      ))
    )
  ), assignments as (
    select a.subject_id from public.schoolpro_subject_assignments a
    where a.school_id = p_school and a.class_id = p_class
      and a.session = trim(p_session) and a.ended_at is null
  )
  select count(*)::integer into v_count
  from roster s cross join assignments a
  join public.schoolpro_results r
    on r.school_id = p_school and r.student_id = s.student_id
   and r.subject_id = a.subject_id and r.term = trim(p_term)
   and r.session = trim(p_session) and r.status = 'draft' and not r.locked
  join public.schoolpro_result_workflow w
    on w.result_id = r.id and w.school_id = p_school and w.class_id = p_class
   and w.term = trim(p_term) and w.session = trim(p_session) and w.status = 'submitted';

  if v_count = 0 then
    raise exception 'No complete submitted class results are awaiting first review';
  end if;

  if exists (
    select 1 from public.schoolpro_result_first_reviews fr
    where fr.school_id = p_school and fr.class_id = p_class
      and fr.term = trim(p_term) and fr.session = trim(p_session)
      and fr.status = 'forwarded'
  ) then
    raise exception 'This class has already been forwarded; resubmit after any correction before requesting another first review';
  end if;

  insert into public.schoolpro_result_first_reviews(
    school_id, class_id, term, session, reviewed_by, notes, result_count
  ) values (
    p_school, p_class, trim(p_term), trim(p_session), auth.uid(),
    nullif(trim(p_notes), ''), v_count
  );

  insert into public.schoolpro_audit_logs(
    school_id, actor_id, action, entity_type, entity_id, metadata
  ) values (
    p_school, auth.uid(),
    'Exam Officer completed first review and forwarded class results to Section Head',
    'class', p_class,
    jsonb_build_object(
      'term', trim(p_term), 'session', trim(p_session),
      'result_count', v_count, 'notes', nullif(trim(p_notes), '')
    )
  );

  return v_count;
end
$function$;

revoke all on function public.schoolpro_exam_officer_review_class_results(uuid, uuid, text, text, text)
  from public, anon;
grant execute on function public.schoolpro_exam_officer_review_class_results(uuid, uuid, text, text, text)
  to authenticated;

comment on table public.schoolpro_result_first_reviews is
  'Append-only first-pass Exam Officer review audit record for each class/term/session; workflow resets mark the prior forwarding record invalidated without deleting its history.';

create or replace function private.enforce_result_workflow()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_level text;
  v_class uuid;
  v_workflow_class uuid;
  v_workflow_status text;
begin
  if old.status in ('approved', 'published') and (
    new.school_id is distinct from old.school_id
    or new.student_id is distinct from old.student_id
    or new.subject_id is distinct from old.subject_id
    or new.term is distinct from old.term
    or new.session is distinct from old.session
    or new.ca_score is distinct from old.ca_score
    or new.exam_score is distinct from old.exam_score
    or new.total_score is distinct from old.total_score
    or new.assessment_scores is distinct from old.assessment_scores
    or new.assessment_scheme_id is distinct from old.assessment_scheme_id
  ) then
    raise exception 'Approved or published results must be reopened through the correction workflow before editing';
  end if;

  if new.status = old.status
     and old.status = 'draft'
     and (
       new.school_id is distinct from old.school_id
       or new.student_id is distinct from old.student_id
       or new.subject_id is distinct from old.subject_id
       or new.term is distinct from old.term
       or new.session is distinct from old.session
       or new.ca_score is distinct from old.ca_score
       or new.exam_score is distinct from old.exam_score
       or new.total_score is distinct from old.total_score
       or new.assessment_scores is distinct from old.assessment_scores
       or new.assessment_scheme_id is distinct from old.assessment_scheme_id
     ) then
    update public.schoolpro_result_workflow
    set status = 'draft',
        submitted_by = null,
        submitted_at = null,
        approved_by = null,
        approved_at = null,
        published_at = null,
        updated_at = now()
    where result_id = old.id
      and status = 'submitted';

  end if;

  if new.status is distinct from old.status
     and new.status in ('approved', 'published') then
    select c.level, c.id
    into v_level, v_class
    from public.schoolpro_students s
    left join lateral (
      select eh.class_id
      from public.schoolpro_enrollment_history eh
      where eh.school_id = new.school_id
        and eh.student_id = new.student_id
        and eh.session = trim(coalesce(new.session, ''))
      order by eh.created_at desc
      limit 1
    ) h on true
    join public.schoolpro_classes c
      on c.school_id = s.school_id
     and c.id = coalesce(h.class_id, s.class_id)
    where s.school_id = new.school_id
      and s.id = new.student_id;

    select w.status, w.class_id
    into v_workflow_status, v_workflow_class
    from public.schoolpro_result_workflow w
    where w.result_id = new.id
    for update;

    if v_workflow_class is distinct from v_class then
      raise exception 'The class roster changed after submission; the Form Master must resubmit this result';
    end if;

    if new.status = 'approved' then
      if current_setting('app.schoolpro_section_approval', true) is distinct from 'on' then
        raise exception 'Section approval must use the complete-section Section Head approval RPC';
      end if;

      if not exists (
        select 1 from public.schoolpro_result_workflow w
        join public.schoolpro_result_first_reviews fr
          on fr.school_id = w.school_id and fr.class_id = w.class_id
         and fr.term = w.term and fr.session = w.session
        where w.result_id = new.id and fr.status = 'forwarded'
      ) then
        raise exception 'The Exam Officer must complete first review and forward this class to the Section Head before approval';
      end if;

      if v_workflow_status is distinct from 'submitted' then
        raise exception 'The Form Master must submit this result to the Exam Officer before Section Head approval';
      end if;

      if not private.schoolpro_member_leads_class(new.school_id, v_class) then
        raise exception 'Only the eligible appointed section head can approve this class';
      end if;

    elsif new.status = 'published' then
      if current_setting('app.schoolpro_exam_publication', true) is distinct from 'on' then
        raise exception 'Publication must use the Exam Officer final publication RPC';
      end if;

      if old.status <> 'approved'
         or v_workflow_status is distinct from 'exam_approved' then
        raise exception 'The Exam Officer must give final approval before publication';
      end if;

      if not (private.schoolpro_is_exam_officer(new.school_id) or private.is_admin(array['super_admin']::public.user_role[])) then
        raise exception 'Only the Exam Officer can publish final-approved results';
      end if;
    end if;
  end if;

  if new.status = 'approved' and old.status <> 'approved' then
    new.approved_by := auth.uid();
    new.approved_at := now();
  end if;

  if new.status = 'published' and old.status <> 'published' then
    new.published_at := now();
  end if;

  return new;
end;
$function$;



comment on function private.enforce_result_workflow() is
  'Protects published/approved rows and requires an auditable Exam Officer first review before a Section Head can approve submitted class results.';

commit;
