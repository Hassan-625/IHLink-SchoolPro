-- Enforce the SchoolPro result hand-off:
-- Form Master submits the class register; the appointed section head approves;
-- only an approved result can then be published.
create table public.schoolpro_result_workflow (
  result_id uuid primary key references public.schoolpro_results(id) on delete cascade,
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  term text not null,
  session text not null,
  status text not null default 'draft'
    check(status in ('draft','submitted','approved','published')),
  submitted_by uuid references auth.users(id),
  submitted_at timestamptz,
  approved_by uuid references auth.users(id),
  approved_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index schoolpro_result_workflow_class_period_idx
  on public.schoolpro_result_workflow(school_id,class_id,session,term,status);
alter table public.schoolpro_result_workflow enable row level security;
revoke all on public.schoolpro_result_workflow from public,anon,authenticated;

create or replace function public.schoolpro_submit_class_results(
  p_school uuid,p_class uuid,p_term text,p_session text
) returns integer
language plpgsql security definer set search_path=''
as $$
declare v_member uuid;v_count integer;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'Authentication required';
  end if;
  if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then
    raise exception 'Select an academic term and session';
  end if;
  if not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) then
    raise exception 'Module permission denied: results';
  end if;
  select m.id into v_member
  from public.schoolpro_members m
  join public.schoolpro_classes c
    on c.school_id=m.school_id and c.id=p_class and c.form_teacher_id=m.id
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
    and m.role in ('teacher','class_teacher');
  if v_member is null then
    raise exception 'Only the assigned Form Master can submit this class result register';
  end if;
  perform s.id from public.schoolpro_students s
  where s.school_id=p_school and (
    exists(select 1 from public.schoolpro_enrollment_history h
      where h.school_id=p_school and h.student_id=s.id
        and h.session=trim(p_session) and h.class_id=p_class)
    or (s.status='active' and s.class_id=p_class and not exists(
      select 1 from public.schoolpro_enrollment_history h
      where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session)))
  ) order by s.id for update;
  perform r.id from public.schoolpro_results r
  join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status='draft' and not r.locked
    and (
      exists(select 1 from public.schoolpro_enrollment_history h
        where h.school_id=p_school and h.student_id=s.id
          and h.session=trim(p_session) and h.class_id=p_class)
      or (s.status='active' and s.class_id=p_class and not exists(
        select 1 from public.schoolpro_enrollment_history h
        where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session)))
    )
  order by r.id for update of r;
  if not exists(
    select 1 from public.schoolpro_results r
    join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
    where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
      and r.status='draft' and not r.locked
      and (
        exists(select 1 from public.schoolpro_enrollment_history h
          where h.school_id=p_school and h.student_id=s.id
            and h.session=trim(p_session) and h.class_id=p_class)
        or (s.status='active' and s.class_id=p_class and not exists(
          select 1 from public.schoolpro_enrollment_history h
          where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session)))
      )
  ) then raise exception 'There are no unlocked Draft results to submit'; end if;
  if exists(
    select 1 from public.schoolpro_results r
    join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
    where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
      and r.status='draft' and not r.locked
      and (
        exists(select 1 from public.schoolpro_enrollment_history h
          where h.school_id=p_school and h.student_id=s.id
            and h.session=trim(p_session) and h.class_id=p_class)
        or (s.status='active' and s.class_id=p_class and not exists(
          select 1 from public.schoolpro_enrollment_history h
          where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session)))
      )
      and not private.schoolpro_result_assessment_complete(r.id)
  ) then raise exception 'Complete every assessment before submitting results to the section head'; end if;
  insert into public.schoolpro_result_workflow(
    result_id,school_id,class_id,term,session,status,submitted_by,submitted_at,
    approved_by,approved_at,published_at,updated_at
  )
  select r.id,p_school,p_class,trim(p_term),trim(p_session),'submitted',auth.uid(),now(),
    null,null,null,now()
  from public.schoolpro_results r
  join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status='draft' and not r.locked
    and (
      exists(select 1 from public.schoolpro_enrollment_history h
        where h.school_id=p_school and h.student_id=s.id
          and h.session=trim(p_session) and h.class_id=p_class)
      or (s.status='active' and s.class_id=p_class and not exists(
        select 1 from public.schoolpro_enrollment_history h
        where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session)))
    )
  on conflict(result_id) do update set
    school_id=excluded.school_id,class_id=excluded.class_id,term=excluded.term,session=excluded.session,
    status='submitted',submitted_by=excluded.submitted_by,submitted_at=now(),
    approved_by=null,approved_at=null,published_at=null,updated_at=now();
  get diagnostics v_count=row_count;
  return v_count;
end
$$;
revoke all on function public.schoolpro_submit_class_results(uuid,uuid,text,text) from public,anon;
grant execute on function public.schoolpro_submit_class_results(uuid,uuid,text,text) to authenticated;

create or replace function private.enforce_result_workflow()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_level text;v_workflow_status text;
begin
  if old.status in ('approved','published') and (
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

  if new.status=old.status and old.status='draft'
     and (new.school_id is distinct from old.school_id
    or new.student_id is distinct from old.student_id
    or new.subject_id is distinct from old.subject_id
    or new.term is distinct from old.term
    or new.session is distinct from old.session
    or new.ca_score is distinct from old.ca_score
    or new.exam_score is distinct from old.exam_score
    or new.total_score is distinct from old.total_score
    or new.assessment_scores is distinct from old.assessment_scores
    or new.assessment_scheme_id is distinct from old.assessment_scheme_id) then
    update public.schoolpro_result_workflow set status='draft',submitted_by=null,
      submitted_at=null,approved_by=null,approved_at=null,published_at=null,updated_at=now()
    where result_id=old.id and status='submitted';
  end if;

  if new.status is distinct from old.status and new.status in ('approved','published') then
    select c.level into v_level
    from public.schoolpro_students s
    left join lateral (
      select eh.class_id from public.schoolpro_enrollment_history eh
      where eh.school_id=new.school_id and eh.student_id=new.student_id
        and eh.session=trim(coalesce(new.session,''))
      order by eh.created_at desc limit 1
    ) h on true
    join public.schoolpro_classes c on c.school_id=s.school_id
      and c.id=coalesce(h.class_id,s.class_id)
    where s.school_id=new.school_id and s.id=new.student_id;

    select w.status into v_workflow_status
    from public.schoolpro_result_workflow w where w.result_id=new.id for update;
    if new.status='approved' and v_workflow_status is distinct from 'submitted' then
      raise exception 'The Form Master must submit this result to the section head before approval';
    end if;
    if new.status='published' and (old.status<>'approved' or v_workflow_status is distinct from 'approved') then
      raise exception 'The section head must approve this result before publication';
    end if;
    if not private.is_admin(array['super_admin']::public.user_role[])
       and not exists(
        select 1 from public.schoolpro_members m
        join public.schoolpro_section_leaders sl
          on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
        where m.school_id=new.school_id and m.user_id=auth.uid() and m.status='active'
          and sl.section=v_level
          and (
            (v_level in ('nursery','primary') and m.role='head_teacher')
            or (v_level in ('junior_secondary','senior_secondary') and (
              m.role='vice_principal'
              or (m.role='administrator' and lower(coalesce(m.position_title,''))='principal')
            ))
          )
       ) then
      raise exception 'Only the appointed section Head Teacher, Vice Principal or Principal can approve or publish this section result';
    end if;
  end if;
  if new.status='approved' and old.status<>'approved' then
    new.approved_by:=auth.uid();new.approved_at:=now();
  end if;
  if new.status='published' and old.status<>'published' then
    new.published_at:=now();
  end if;
  return new;
end
$$;

create or replace function private.sync_schoolpro_result_workflow()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  if new.status='approved' and old.status is distinct from 'approved' then
    update public.schoolpro_result_workflow set status='approved',
      approved_by=auth.uid(),approved_at=now(),updated_at=now()
    where result_id=new.id and status='submitted';
  elsif new.status='published' and old.status is distinct from 'published' then
    update public.schoolpro_result_workflow set status='published',
      published_at=coalesce(new.published_at,now()),updated_at=now()
    where result_id=new.id and status='approved';
  elsif new.status='draft' and old.status in ('approved','published') then
    update public.schoolpro_result_workflow set status='draft',submitted_by=null,
      submitted_at=null,approved_by=null,approved_at=null,published_at=null,updated_at=now()
    where result_id=new.id;
  end if;
  return new;
end
$$;
revoke all on function private.sync_schoolpro_result_workflow() from public,anon,authenticated;
drop trigger if exists schoolpro_sync_result_workflow on public.schoolpro_results;
create trigger schoolpro_sync_result_workflow
after update of status on public.schoolpro_results
for each row execute function private.sync_schoolpro_result_workflow();

drop trigger if exists schoolpro_enforce_result_workflow on public.schoolpro_results;
create trigger schoolpro_enforce_result_workflow
before update on public.schoolpro_results
for each row execute function private.enforce_result_workflow();
