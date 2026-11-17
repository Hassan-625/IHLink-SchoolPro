create or replace function private.schoolpro_is_exam_officer(p_school uuid)
returns boolean
language sql
stable
security definer
set search_path to ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and (
      exists (
        select 1
        from public.schoolpro_members m
        where m.school_id = p_school
          and m.user_id = auth.uid()
          and m.status = 'active'
          and m.role = 'exam_officer'
      )
      or private.schoolpro_member_has_responsibility(p_school, 'exam_officer')
    );
$function$;

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

      if v_workflow_status is distinct from 'submitted' then
        raise exception 'The Form Master must submit this result to the section head before approval';
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


create or replace function public.schoolpro_decide_result_reopening(
  p_request uuid,
  p_approve boolean,
  p_notes text default null
) returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  request_row public.schoolpro_result_correction_batches;
  v_count integer;
  v_is_super_admin boolean;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'Authentication required';
  end if;

  v_is_super_admin := private.is_admin(array['super_admin']::public.user_role[]);

  if p_approve is null then
    raise exception 'Choose approve or reject';
  end if;

  if v_is_super_admin and nullif(trim(p_notes), '') is null then
    raise exception 'Super Admin override requires an audit note';
  end if;

  select * into request_row
  from public.schoolpro_result_correction_batches
  where id = p_request
  for update;

  if request_row.id is null or request_row.status <> 'pending_exam_officer' then
    raise exception 'Correction request awaiting Exam Officer authorization was not found';
  end if;

  if request_row.requested_by = auth.uid()
     or request_row.section_reviewed_by = auth.uid() then
    raise exception 'The requester and Section Head reviewer cannot authorize the same correction request';
  end if;

  if not coalesce(private.schoolpro_module_allowed(request_row.school_id, 'results'), false) then
    raise exception 'Module permission denied: results';
  end if;

  if not private.schoolpro_is_exam_officer(request_row.school_id)
     and not v_is_super_admin then
    raise exception 'Only an appointed Exam Officer or Super Admin can authorize a class or section result reopening';
  end if;

  if p_approve then
    perform set_config('app.schoolpro_correction_reopen', p_request::text, true);

    update public.schoolpro_results r
    set status = 'draft', locked = false, updated_at = now()
    where r.id in (
      select i.result_id
      from public.schoolpro_result_correction_batch_items i
      where i.batch_id = p_request
    )
    and r.status in ('approved', 'published');

    get diagnostics v_count = row_count;

    if v_count = 0 then
      raise exception 'No results remain eligible for reopening in this request';
    end if;
  else
    select count(*) into v_count
    from public.schoolpro_result_correction_batch_items
    where batch_id = p_request;
  end if;

  update public.schoolpro_result_correction_batches
  set status = case when p_approve then 'approved' else 'rejected' end,
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_notes = nullif(trim(p_notes), '')
  where id = p_request
    and status = 'pending_exam_officer';

  if not found then
    raise exception 'Correction request was already reviewed';
  end if;

  insert into public.schoolpro_audit_logs(
    school_id, actor_id, action, entity_type, entity_id, metadata
  )
  values (
    request_row.school_id,
    auth.uid(),
    case
      when p_approve and v_is_super_admin then 'Super Admin reopened class or section results for correction'
      when not p_approve and v_is_super_admin then 'Super Admin rejected result reopening request'
      when p_approve then 'Class or section results reopened for correction'
      else 'Result reopening request rejected by Exam Officer'
    end,
    request_row.scope,
    coalesce(request_row.class_id, p_request),
    jsonb_build_object(
      'request_id', p_request,
      'scope', request_row.scope,
      'section', request_row.section,
      'term', request_row.term,
      'session', request_row.session,
      'result_count', v_count,
      'notes', p_notes,
      'section_reviewed_by', request_row.section_reviewed_by,
      'authorization_role', case when v_is_super_admin then 'super_admin_override' else 'exam_officer' end,
      'super_admin_override', v_is_super_admin
    )
  );

  return v_count;
end
$function$;

revoke all on function public.schoolpro_decide_result_reopening(uuid, boolean, text) from public, anon;
grant execute on function public.schoolpro_decide_result_reopening(uuid, boolean, text) to authenticated;




-- Explicit Super Admin final approval and publication overrides.
create or replace function public.schoolpro_exam_officer_approve_results(
  p_school uuid,p_term text,p_session text,p_scope text,
  p_class uuid default null,p_section text default null
) returns integer language plpgsql security definer set search_path=''
as $$
declare n integer;
begin
  if auth.uid() is null or not private.is_active_account() then raise exception 'Authentication required'; end if;
  if not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) then
    raise exception 'Module permission denied: results';
  end if;
  if not (private.schoolpro_is_exam_officer(p_school) or private.is_admin(array['super_admin']::public.user_role[])) then raise exception 'Only the Exam Officer or Super Admin can give final result approval'; end if;
  if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null
     or p_scope not in ('class','section','school') then raise exception 'Choose a valid result period and approval scope'; end if;
  if p_scope='class' and p_class is null then raise exception 'Select a class for final approval'; end if;
  if p_scope='section' and p_section not in ('nursery','primary','junior_secondary','senior_secondary','other') then
    raise exception 'Select a valid section for final approval';
  end if;
  if p_scope='school' and (p_class is not null or p_section is not null) then
    raise exception 'Whole-school approval cannot include a class or section filter';
  end if;
  perform private.schoolpro_lock_result_scope(p_school,p_term,p_session,p_scope,p_class,p_section);
  if not private.schoolpro_result_scope_mixed_state(p_school,p_term,p_session,p_scope,p_class,p_section,'exam') then
    raise exception 'Every allocated class and subject result in the selected scope must be section-approved before final approval';
  end if;
  if exists(select 1 from public.schoolpro_result_workflow w
    join public.schoolpro_classes c on c.school_id=w.school_id and c.id=w.class_id
    left join public.schoolpro_results r on r.id=w.result_id
    where w.school_id=p_school and w.term=trim(p_term) and w.session=trim(p_session)
      and (p_scope='school' or (p_scope='class' and w.class_id=p_class)
        or (p_scope='section' and c.level=p_section))
      and (r.id is null or r.status not in ('approved','published'))) then
    raise exception 'Every result in the selected scope must be section-approved before Exam Officer approval';
  end if;
  update public.schoolpro_result_workflow w set status='exam_approved',
    exam_approved_by=auth.uid(),exam_approved_at=now(),updated_at=now()
  from public.schoolpro_classes c
  where c.school_id=w.school_id and c.id=w.class_id and w.school_id=p_school
    and w.term=trim(p_term) and w.session=trim(p_session) and w.status='section_approved'
    and (p_scope='school' or (p_scope='class' and w.class_id=p_class)
      or (p_scope='section' and c.level=p_section));
  get diagnostics n=row_count;
  if n=0 then raise exception 'No section-approved results are available for final approval'; end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),case when private.is_admin(array['super_admin']::public.user_role[]) then 'Results approved by Super Admin override' else 'Results approved by Exam Officer' end,p_scope,coalesce(p_class,p_school),
    jsonb_build_object('term',trim(p_term),'session',trim(p_session),'section',p_section,'result_count',n) || jsonb_build_object('authorization_role',case when private.is_admin(array['super_admin']::public.user_role[]) then 'super_admin_override' else 'exam_officer' end,'super_admin_override',private.is_admin(array['super_admin']::public.user_role[])));
  return n;
end
$$;
revoke all on function public.schoolpro_exam_officer_approve_results(uuid,text,text,text,uuid,text) from public,anon;
grant execute on function public.schoolpro_exam_officer_approve_results(uuid,text,text,text,uuid,text) to authenticated;

create or replace function public.schoolpro_publish_school_results(
  p_school uuid,p_term text,p_session text
) returns integer language plpgsql security definer set search_path=''
as $$
declare n integer;
begin
  if auth.uid() is null or not private.is_active_account() then raise exception 'Authentication required'; end if;
  if not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) then
    raise exception 'Module permission denied: results';
  end if;
  if not (private.schoolpro_is_exam_officer(p_school) or private.is_admin(array['super_admin']::public.user_role[])) then raise exception 'Only the Exam Officer or Super Admin can publish school results'; end if;
  if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then
    raise exception 'Select an academic term and session';
  end if;
  perform private.schoolpro_lock_result_scope(p_school,p_term,p_session,'school',null,null);
  if not private.schoolpro_result_scope_mixed_state(p_school,p_term,p_session,'school',null,null,'exam') then
    raise exception 'Whole-school publication is blocked until every allocated subject result in every class has final Exam Officer approval';
  end if;
  if not exists(select 1 from public.schoolpro_result_workflow w
    where w.school_id=p_school and w.term=trim(p_term) and w.session=trim(p_session)) then
    raise exception 'No submitted results exist for this school period';
  end if;
  if exists(select 1 from public.schoolpro_result_workflow w
    where w.school_id=p_school and w.term=trim(p_term) and w.session=trim(p_session)
      and w.status not in ('exam_approved','published')) then
    raise exception 'Whole-school publication is blocked until every submitted result has final Exam Officer approval';
  end if;
  if exists(select 1 from public.schoolpro_results r
    join public.schoolpro_students s on s.school_id=r.school_id and s.id=r.student_id
    where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
      and r.status not in ('approved','published')) then
    raise exception 'Whole-school publication is blocked because one or more results are not section-approved';
  end if;
  perform set_config('app.schoolpro_exam_publication','on',true);
  update public.schoolpro_results r set status='published',locked=true,updated_at=now()
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status='approved' and exists(select 1 from public.schoolpro_result_workflow w
      where w.result_id=r.id and w.status='exam_approved');
  select count(*)::integer into n from public.schoolpro_results r
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status='published' and r.locked;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),case when private.is_admin(array['super_admin']::public.user_role[]) then 'Whole-school results published by Super Admin override' else 'Whole-school results published' end,'school',p_school,
    jsonb_build_object('term',trim(p_term),'session',trim(p_session),'result_count',n) || jsonb_build_object('authorization_role',case when private.is_admin(array['super_admin']::public.user_role[]) then 'super_admin_override' else 'exam_officer' end,'super_admin_override',private.is_admin(array['super_admin']::public.user_role[])));
  return n;
end
$$;
revoke all on function public.schoolpro_publish_school_results(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_publish_school_results(uuid,text,text) to authenticated;
