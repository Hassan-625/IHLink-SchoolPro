-- Route post-publication correction requests through Section Head review
-- before the Exam Officer can authorize reopening.
alter table public.schoolpro_result_correction_batches
  drop constraint if exists schoolpro_result_correction_batches_status_check;

alter table public.schoolpro_result_correction_batches
  add column if not exists section_reviewed_by uuid references auth.users(id),
  add column if not exists section_reviewed_at timestamptz,
  add column if not exists section_review_notes text;

-- Existing pending requests (if any) are routed to Section Head review.
update public.schoolpro_result_correction_batches
set status='pending_section_review'
where status='pending';

alter table public.schoolpro_result_correction_batches
  add constraint schoolpro_result_correction_batches_status_check
  check(status in ('pending_section_review','pending_exam_officer','approved','rejected'));

-- Section leaders may see only requests awaiting their own section review.
drop policy if exists schoolpro_result_correction_batches_section_head_read
  on public.schoolpro_result_correction_batches;
create policy schoolpro_result_correction_batches_section_head_read
on public.schoolpro_result_correction_batches for select to authenticated
using (
  status='pending_section_review'
  and private.schoolpro_module_allowed(school_id,'results')
  and (
    (scope='class' and private.schoolpro_member_leads_class(school_id,class_id))
    or (scope='section' and exists(
      select 1 from public.schoolpro_classes c
      where c.school_id=schoolpro_result_correction_batches.school_id
        and c.level=schoolpro_result_correction_batches.section
        and private.schoolpro_member_leads_class(c.school_id,c.id)
    ))
  )
);

drop policy if exists schoolpro_result_correction_batch_items_section_head_read
  on public.schoolpro_result_correction_batch_items;
create policy schoolpro_result_correction_batch_items_section_head_read
on public.schoolpro_result_correction_batch_items for select to authenticated
using (exists(
  select 1 from public.schoolpro_result_correction_batches b
  where b.id=schoolpro_result_correction_batch_items.batch_id
    and b.status='pending_section_review'
    and private.schoolpro_module_allowed(b.school_id,'results')
    and (
      (b.scope='class' and private.schoolpro_member_leads_class(b.school_id,b.class_id))
      or (b.scope='section' and exists(
        select 1 from public.schoolpro_classes c
        where c.school_id=b.school_id and c.level=b.section
          and private.schoolpro_member_leads_class(c.school_id,c.id)
      ))
    )
));

create or replace function public.schoolpro_request_result_reopening(
  p_school uuid,p_scope text,p_class uuid,p_section text,
  p_term text,p_session text,p_reason text
) returns uuid language plpgsql security definer set search_path=''
as $$
declare
  v_request uuid;
  v_member uuid;
  v_count integer;
  v_is_section_head boolean := false;
  v_initial_status text;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'Authentication required';
  end if;
  if not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) then
    raise exception 'Module permission denied: results';
  end if;
  if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null
     or nullif(trim(p_reason),'') is null or length(trim(p_reason))<10 then
    raise exception 'Provide the result period and a correction reason of at least 10 characters';
  end if;
  if p_scope not in ('class','section')
     or (p_scope='class' and (p_class is null or p_section is not null))
     or (p_scope='section' and (p_class is not null or p_section not in ('nursery','primary','junior_secondary','senior_secondary','other'))) then
    raise exception 'Choose exactly one class or section correction scope';
  end if;
  select id into v_member from public.schoolpro_members
    where school_id=p_school and user_id=auth.uid() and status='active';
  if v_member is null then raise exception 'Active school membership required'; end if;

  if p_scope='class' and not (
    private.schoolpro_member_has_responsibility(p_school,'school_admin')
    or exists(select 1 from public.schoolpro_classes c
      where c.school_id=p_school and c.id=p_class and c.form_teacher_id=v_member)
    or exists(select 1 from public.schoolpro_subject_assignments a
      where a.school_id=p_school and a.teacher_member_id=v_member
        and a.class_id=p_class and a.session=trim(p_session) and a.ended_at is null
        and exists(select 1 from public.schoolpro_members m
          where m.id=v_member and m.school_id=p_school and m.role::text in ('teacher','class_teacher')))
    or private.schoolpro_member_leads_class(p_school,p_class)
  ) then
    raise exception 'Only an assigned class teacher, subject teacher, section head or school administrator can request this class reopening';
  end if;
  if p_scope='section' and not (
    private.schoolpro_member_has_responsibility(p_school,'school_admin')
    or exists(select 1 from public.schoolpro_section_leaders sl
      where sl.school_id=p_school and sl.member_id=v_member
        and sl.section=p_section and sl.ended_at is null)
  ) then
    raise exception 'Only the appointed section head or school administrator can request a section reopening';
  end if;

  v_is_section_head := case
    when p_scope='class' then private.schoolpro_member_leads_class(p_school,p_class)
    else exists(select 1 from public.schoolpro_classes c
      where c.school_id=p_school and c.level=p_section
        and private.schoolpro_member_leads_class(p_school,c.id))
  end;
  v_initial_status := case when v_is_section_head
    then 'pending_exam_officer' else 'pending_section_review' end;

  insert into public.schoolpro_result_correction_batches(
    school_id,scope,class_id,section,term,session,reason,requested_by,status
  )
  values(p_school,p_scope,p_class,p_section,trim(p_term),trim(p_session),
    trim(p_reason),auth.uid(),v_initial_status)
  returning id into v_request;

  insert into public.schoolpro_result_correction_batch_items(batch_id,result_id)
  select v_request,r.id
  from public.schoolpro_results r
  join public.schoolpro_students s
    on s.school_id=r.school_id and s.id=r.student_id
  join lateral (
    select coalesce((
      select eh.class_id from public.schoolpro_enrollment_history eh
      where eh.school_id=p_school and eh.student_id=s.id
        and eh.session=trim(p_session)
      order by eh.created_at desc limit 1
    ),s.class_id) class_id
  ) roster on true
  join public.schoolpro_classes c
    on c.school_id=p_school and c.id=roster.class_id
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status in ('approved','published')
    and ((p_scope='class' and c.id=p_class) or (p_scope='section' and c.level=p_section));
  get diagnostics v_count=row_count;
  if v_count=0 then
    raise exception 'No approved or published results exist in the requested correction scope';
  end if;

  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Result reopening requested',p_scope,coalesce(p_class,v_request),
    jsonb_build_object('request_id',v_request,'term',trim(p_term),'session',trim(p_session),
      'section',p_section,'reason',trim(p_reason),'result_count',v_count,
      'initial_review_stage',v_initial_status));
  return v_request;
end
$$;
revoke all on function public.schoolpro_request_result_reopening(uuid,text,uuid,text,text,text,text) from public,anon;
grant execute on function public.schoolpro_request_result_reopening(uuid,text,uuid,text,text,text,text) to authenticated;

create or replace function public.schoolpro_review_result_reopening(
  p_request uuid,p_forward boolean,p_notes text default null
) returns integer language plpgsql security definer set search_path=''
as $$
declare
  request_row public.schoolpro_result_correction_batches;
  v_count integer;
  v_authorized boolean := false;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'Authentication required';
  end if;
  if p_forward is null then raise exception 'Choose forward or reject'; end if;
  select * into request_row
  from public.schoolpro_result_correction_batches
  where id=p_request for update;
  if request_row.id is null or request_row.status<>'pending_section_review' then
    raise exception 'Correction request awaiting Section Head review was not found';
  end if;
  if request_row.requested_by=auth.uid() then
    raise exception 'The requester cannot review their own correction request';
  end if;
  if not coalesce(private.schoolpro_module_allowed(request_row.school_id,'results'),false) then
    raise exception 'Module permission denied: results';
  end if;
  if request_row.scope='class' then
    v_authorized:=private.schoolpro_member_leads_class(request_row.school_id,request_row.class_id);
  else
    select exists(select 1 from public.schoolpro_classes c
      where c.school_id=request_row.school_id and c.level=request_row.section
        and private.schoolpro_member_leads_class(c.school_id,c.id))
    into v_authorized;
  end if;
  if not v_authorized then
    raise exception 'Only the appointed Section Head for this class or section can review this correction request';
  end if;
  if not p_forward and length(trim(coalesce(p_notes,'')))<10 then
    raise exception 'Provide a rejection reason of at least 10 characters';
  end if;

  select count(*) into v_count
  from public.schoolpro_result_correction_batch_items
  where batch_id=p_request;

  update public.schoolpro_result_correction_batches set
    status=case when p_forward then 'pending_exam_officer' else 'rejected' end,
    section_reviewed_by=auth.uid(),
    section_reviewed_at=now(),
    section_review_notes=nullif(trim(p_notes),'')
  where id=p_request and status='pending_section_review';
  if not found then raise exception 'Correction request was already reviewed'; end if;

  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(request_row.school_id,auth.uid(),
    case when p_forward then 'Section Head forwarded result reopening request to Exam Officer'
      else 'Section Head rejected result reopening request' end,
    request_row.scope,coalesce(request_row.class_id,p_request),
    jsonb_build_object('request_id',p_request,'scope',request_row.scope,
      'section',request_row.section,'term',request_row.term,'session',request_row.session,
      'result_count',v_count,'notes',p_notes));
  return v_count;
end
$$;
revoke all on function public.schoolpro_review_result_reopening(uuid,boolean,text) from public,anon;
grant execute on function public.schoolpro_review_result_reopening(uuid,boolean,text) to authenticated;

create or replace function public.schoolpro_decide_result_reopening(
  p_request uuid,p_approve boolean,p_notes text default null
) returns integer language plpgsql security definer set search_path=''
as $$
declare
  request_row public.schoolpro_result_correction_batches;
  v_count integer;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'Authentication required';
  end if;
  if p_approve is null then raise exception 'Choose approve or reject'; end if;
  select * into request_row from public.schoolpro_result_correction_batches
    where id=p_request for update;
  if request_row.id is null or request_row.status<>'pending_exam_officer' then
    raise exception 'Correction request awaiting Exam Officer authorization was not found';
  end if;
  if request_row.requested_by=auth.uid()
     or request_row.section_reviewed_by=auth.uid() then
    raise exception 'The requester and Section Head reviewer cannot authorize the same correction request';
  end if;
  if not coalesce(private.schoolpro_module_allowed(request_row.school_id,'results'),false) then
    raise exception 'Module permission denied: results';
  end if;
  if not private.schoolpro_is_exam_officer(request_row.school_id) then
    raise exception 'Only the Exam Officer can authorize a class or section result reopening';
  end if;
  if p_approve then
    perform set_config('app.schoolpro_correction_reopen',p_request::text,true);
    update public.schoolpro_results r set status='draft',locked=false,updated_at=now()
    where r.id in(
      select i.result_id from public.schoolpro_result_correction_batch_items i
      where i.batch_id=p_request
    ) and r.status in ('approved','published');
    get diagnostics v_count=row_count;
    if v_count=0 then raise exception 'No results remain eligible for reopening in this request'; end if;
  else
    select count(*) into v_count
    from public.schoolpro_result_correction_batch_items
    where batch_id=p_request;
  end if;
  update public.schoolpro_result_correction_batches set
    status=case when p_approve then 'approved' else 'rejected' end,
    reviewed_by=auth.uid(),reviewed_at=now(),
    review_notes=nullif(trim(p_notes),'')
  where id=p_request and status='pending_exam_officer';
  if not found then raise exception 'Correction request was already reviewed'; end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(request_row.school_id,auth.uid(),
    case when p_approve then 'Class or section results reopened for correction'
      else 'Result reopening request rejected by Exam Officer' end,
    request_row.scope,coalesce(request_row.class_id,p_request),
    jsonb_build_object('request_id',p_request,'scope',request_row.scope,
      'section',request_row.section,'term',request_row.term,'session',request_row.session,
      'result_count',v_count,'notes',p_notes,
      'section_reviewed_by',request_row.section_reviewed_by));
  return v_count;
end
$$;
revoke all on function public.schoolpro_decide_result_reopening(uuid,boolean,text) from public,anon;
grant execute on function public.schoolpro_decide_result_reopening(uuid,boolean,text) to authenticated;

comment on function public.schoolpro_review_result_reopening(uuid,boolean,text) is
  'Section Head review of a class/section correction request. A forward decision queues it for independent Exam Officer authorization; a rejection requires an audit note.';
