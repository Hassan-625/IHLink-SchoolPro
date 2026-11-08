-- Stage C final authority model:
-- score entry is restricted to the allocated subject teacher;
-- Form Masters submit only complete class registers;
-- section heads review/return/approve their section;
-- Exam Officers perform final school-wide approval and publication;
-- post-publication correction reopening is a class/section-scoped audited request.

create table if not exists public.schoolpro_member_responsibilities (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  member_id uuid not null references public.schoolpro_members(id) on delete cascade,
  responsibility text not null check (responsibility in ('exam_officer','school_admin')),
  assigned_by uuid not null references auth.users(id),
  assigned_at timestamptz not null default now(),
  ended_at timestamptz,
  unique (school_id,member_id,responsibility)
);
create index if not exists schoolpro_member_responsibilities_active_idx
  on public.schoolpro_member_responsibilities(school_id,member_id,responsibility)
  where ended_at is null;
alter table public.schoolpro_member_responsibilities enable row level security;
revoke all on public.schoolpro_member_responsibilities from public,anon,authenticated;
grant select on public.schoolpro_member_responsibilities to authenticated;

create or replace function private.schoolpro_member_has_responsibility(
  p_school uuid,p_responsibility text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null and private.is_active_account() and exists(
    select 1 from public.schoolpro_members m
    join public.schoolpro_member_responsibilities r
      on r.school_id=m.school_id and r.member_id=m.id and r.ended_at is null
    where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
      and r.responsibility=p_responsibility
  )
$$;
revoke all on function private.schoolpro_member_has_responsibility(uuid,text) from public,anon;
grant execute on function private.schoolpro_member_has_responsibility(uuid,text) to authenticated;

create or replace function private.schoolpro_is_school_admin(p_school uuid)
returns boolean language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null and private.is_active_account() and (
    private.is_admin(array['super_admin']::public.user_role[])
    or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
    or private.schoolpro_member_has_responsibility(p_school,'school_admin')
  )
$$;
revoke all on function private.schoolpro_is_school_admin(uuid) from public,anon;
grant execute on function private.schoolpro_is_school_admin(uuid) to authenticated;

create policy schoolpro_member_responsibilities_self_or_admin_read
on public.schoolpro_member_responsibilities for select to authenticated
using (
  exists(select 1 from public.schoolpro_members m
    where m.school_id=schoolpro_member_responsibilities.school_id
      and m.id=schoolpro_member_responsibilities.member_id
      and m.user_id=auth.uid() and m.status='active')
  or private.schoolpro_is_school_admin(school_id)
  or private.is_admin(array['super_admin']::public.user_role[])
);

create or replace function private.schoolpro_is_exam_officer(p_school uuid)
returns boolean language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null and private.is_active_account() and (
    exists(select 1 from public.schoolpro_members m
      where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
        and m.role='exam_officer')
    or private.schoolpro_member_has_responsibility(p_school,'exam_officer')
    or private.is_admin(array['super_admin']::public.user_role[])
  )
$$;
revoke all on function private.schoolpro_is_exam_officer(uuid) from public,anon;
grant execute on function private.schoolpro_is_exam_officer(uuid) to authenticated;

create or replace function public.schoolpro_set_member_responsibility(
  p_school uuid,p_member uuid,p_responsibility text,p_assigned boolean
) returns void
language plpgsql security definer set search_path=''
as $$
declare target public.schoolpro_members;v_assigner uuid;v_permissions text[];
begin
  if auth.uid() is null or not private.is_active_account()
     or not (private.is_admin(array['super_admin']::public.user_role[])
       or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
       or private.schoolpro_member_has_responsibility(p_school,'school_admin')) then
    raise exception 'Only authorized school administration can assign staff responsibilities';
  end if;
  if p_responsibility not in ('exam_officer','school_admin') then
    raise exception 'Choose a supported additional responsibility';
  end if;
  select * into target from public.schoolpro_members
   where id=p_member and school_id=p_school and status='active' for update;
  if target.id is null then raise exception 'Active school staff member not found'; end if;
  v_permissions:=case when p_responsibility='exam_officer'
    then array['results','reports','students','classes','subjects']
    else array['students','results','reports','finance','classes','subjects','attendance','timetable',
      'assignments','admissions','cbt','library','parents','transport','hostel','inventory','discipline',
      'medical','documents','announcements','operations','roles','branding','payroll','calendar',
      'lesson-notes','leave','promotions','games','notifications'] end;
  if coalesce(p_assigned,false) then
    insert into public.schoolpro_member_responsibilities(school_id,member_id,responsibility,assigned_by,assigned_at,ended_at)
    values(p_school,p_member,p_responsibility,auth.uid(),now(),null)
    on conflict(school_id,member_id,responsibility) do update
      set assigned_by=excluded.assigned_by,assigned_at=now(),ended_at=null;
    insert into public.schoolpro_member_permissions(school_id,member_id,permission,allowed,updated_by,updated_at)
    select p_school,p_member,permission,true,auth.uid(),now()
    from unnest(v_permissions) as permission
    on conflict(member_id,permission) do nothing;
  else
    select assigned_by into v_assigner from public.schoolpro_member_responsibilities
     where school_id=p_school and member_id=p_member and responsibility=p_responsibility
     order by assigned_at desc limit 1;
    update public.schoolpro_member_responsibilities set ended_at=now()
     where school_id=p_school and member_id=p_member
       and responsibility=p_responsibility and ended_at is null;
    delete from public.schoolpro_member_permissions
     where member_id=p_member and permission=any(v_permissions)
       and updated_by=v_assigner;
  end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Additional staff responsibility updated','member',p_member,
    jsonb_build_object('responsibility',p_responsibility,'assigned',coalesce(p_assigned,false)));
end
$$;
revoke all on function public.schoolpro_set_member_responsibility(uuid,uuid,text,boolean) from public,anon;
grant execute on function public.schoolpro_set_member_responsibility(uuid,uuid,text,boolean) to authenticated;

-- An explicit section appointment, rather than the member's single primary role,
-- is the authority to lead a section. This allows one staff member to teach,
-- coordinate a class and hold section leadership concurrently.
create or replace function private.schoolpro_member_leads_student_section(
  p_school uuid,p_student uuid,p_session text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null and private.is_active_account() and exists(
    select 1 from public.schoolpro_members m
    join public.schoolpro_section_leaders sl
      on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
    join public.schoolpro_students st on st.school_id=p_school and st.id=p_student
    join public.schoolpro_classes c on c.school_id=p_school and c.id=coalesce((
      select eh.class_id from public.schoolpro_enrollment_history eh
      where eh.school_id=p_school and eh.student_id=p_student
        and eh.session=trim(coalesce(p_session,''))
      order by eh.created_at desc limit 1
    ),st.class_id) and c.level=sl.section
    where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
  )
$$;
revoke all on function private.schoolpro_member_leads_student_section(uuid,uuid,text) from public,anon;
grant execute on function private.schoolpro_member_leads_student_section(uuid,uuid,text) to authenticated;

create or replace function private.schoolpro_member_leads_class(p_school uuid,p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null and private.is_active_account() and exists(
    select 1 from public.schoolpro_members m
    join public.schoolpro_section_leaders sl
      on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
    join public.schoolpro_classes c on c.school_id=p_school and c.id=p_class and c.level=sl.section
    where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
  )
$$;
revoke all on function private.schoolpro_member_leads_class(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_member_leads_class(uuid,uuid) to authenticated;

create or replace function private.schoolpro_set_section_leader(
  p_school uuid,p_member uuid,p_section text,p_assigned boolean
) returns void language plpgsql security definer set search_path=''
as $$
declare target public.schoolpro_members;
begin
  if auth.uid() is null or not private.is_active_account()
     or not (private.is_admin(array['super_admin']::public.user_role[])
       or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
       or private.schoolpro_member_has_responsibility(p_school,'school_admin')) then
    raise exception 'Only authorized school administration can manage section appointments';
  end if;
  if p_section not in ('nursery','primary','junior_secondary','senior_secondary','other') then
    raise exception 'Choose a valid school section';
  end if;
  select * into target from public.schoolpro_members
   where id=p_member and school_id=p_school and status='active' for update;
  if target.id is null then raise exception 'Active school staff member not found'; end if;
  if coalesce(p_assigned,false) then
    insert into public.schoolpro_section_leaders(school_id,member_id,section,assigned_by,assigned_at,ended_at)
    values(p_school,p_member,p_section,auth.uid(),now(),null)
    on conflict(school_id,member_id,section) do update
      set assigned_by=excluded.assigned_by,assigned_at=now(),ended_at=null;
  else
    update public.schoolpro_section_leaders set ended_at=now()
     where school_id=p_school and member_id=p_member and section=p_section and ended_at is null;
  end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Section leadership assignment updated','member',p_member,
    jsonb_build_object('section',p_section,'assigned',coalesce(p_assigned,false)));
end
$$;
revoke all on function private.schoolpro_set_section_leader(uuid,uuid,text,boolean) from public,anon,authenticated;
grant execute on function private.schoolpro_set_section_leader(uuid,uuid,text,boolean) to authenticated;
-- Section leadership is an explicit appointment, not a mutually exclusive
-- primary account role. Teaching staff may hold a section-head appointment
-- alongside their subject-teacher/Form-Master and Exam Officer responsibilities.
create or replace function private.schoolpro_set_section_leader(
  p_school uuid,p_member uuid,p_section text,p_assigned boolean
) returns void language plpgsql security definer set search_path=''
as $$
declare target public.schoolpro_members;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not (private.is_admin(array['super_admin'::public.user_role])
       or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])) then
    raise exception 'Only school leadership can manage section assignments';
  end if;
  if p_section not in ('nursery','primary','junior_secondary','senior_secondary','other') then
    raise exception 'Choose a valid school section';
  end if;
  select * into target from public.schoolpro_members
   where id=p_member and school_id=p_school for update;
  if target.id is null or target.status<>'active' or not (
    target.role in ('teacher','class_teacher')
    or (target.role='head_teacher' and p_section in ('nursery','primary'))
    or (target.role='vice_principal' and p_section in ('junior_secondary','senior_secondary'))
    or (target.role='administrator' and lower(coalesce(target.position_title,''))='principal'
        and p_section in ('junior_secondary','senior_secondary'))
  ) then
    raise exception 'Appoint an active teacher, class teacher, eligible Head Teacher, Vice Principal or Principal as section head';
  end if;
  if coalesce(p_assigned,false) then
    insert into public.schoolpro_section_leaders(school_id,member_id,section,assigned_by,assigned_at,ended_at)
    values(p_school,p_member,p_section,auth.uid(),now(),null)
    on conflict(school_id,member_id,section) do update
      set assigned_by=excluded.assigned_by,assigned_at=now(),ended_at=null;
  else
    update public.schoolpro_section_leaders set ended_at=now()
     where school_id=p_school and member_id=p_member and section=p_section and ended_at is null;
  end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Section leadership assignment updated','member',p_member,
    jsonb_build_object('section',p_section,'assigned',coalesce(p_assigned,false)));
end
$$;
revoke all on function private.schoolpro_set_section_leader(uuid,uuid,text,boolean) from public,anon,authenticated;
grant execute on function private.schoolpro_set_section_leader(uuid,uuid,text,boolean) to authenticated;

create or replace function public.schoolpro_set_section_leader(
  p_school uuid,p_member uuid,p_section text,p_assigned boolean
) returns void language sql security invoker set search_path=''
as $$ select private.schoolpro_set_section_leader(p_school,p_member,p_section,p_assigned) $$;
revoke all on function public.schoolpro_set_section_leader(uuid,uuid,text,boolean) from public,anon;
grant execute on function public.schoolpro_set_section_leader(uuid,uuid,text,boolean) to authenticated;

-- Keep section appointments when a member's primary role changes; the explicit
-- appointment is independently managed and is retired when membership ends.
create or replace function private.enforce_result_workflow()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_level text;v_class uuid;v_workflow_class uuid;v_workflow_status text;
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
    select c.level,c.id into v_level,v_class
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

    select w.status,w.class_id into v_workflow_status,v_workflow_class
    from public.schoolpro_result_workflow w where w.result_id=new.id for update;
    if v_workflow_class is distinct from v_class then
      raise exception 'The class roster changed after submission; the Form Master must resubmit this result';
    end if;
    if new.status='approved' and v_workflow_status is distinct from 'submitted' then
      raise exception 'The Form Master must submit this result to the section head before approval';
    end if;
    if new.status='published' and (old.status<>'approved' or v_workflow_status is distinct from 'approved') then
      raise exception 'The section head must approve this result before publication';
    end if;
    if not private.is_admin(array['super_admin']::public.user_role[])
       and not private.schoolpro_member_leads_student_section(new.school_id,new.student_id,new.session) then
      raise exception 'Only the appointed Section Head can approve or publish this section result';
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

create or replace function private.schoolpro_prune_section_leadership_role()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  update public.schoolpro_section_leaders sl set ended_at=now()
  where sl.school_id=new.school_id and sl.member_id=new.id and sl.ended_at is null
    and not (
      new.role in ('teacher','class_teacher')
      or (sl.section in ('nursery','primary') and new.role='head_teacher')
      or (sl.section in ('junior_secondary','senior_secondary') and (
        new.role='vice_principal'
        or (new.role='administrator' and lower(coalesce(new.position_title,''))='principal')
      ))
    );
  return new;
end
$$;

-- The historical-session reader follows the same explicit appointment scope.
create or replace function private.schoolpro_enrollment_reader_keys()
returns jsonb language sql stable security definer set search_path=''
as $$
with leaders as materialized (
  select s.id from public.schoolpro_schools s
  where auth.uid() is not null and private.is_active_account()
    and private.schoolpro_operationally_active(s.id)
    and (
      private.is_admin(array['super_admin'::public.user_role])
      or (private.schoolpro_module_allowed(s.id,'students') and public.schoolpro_member_can_manage(s.id))
      or private.schoolpro_can_issue_transcript(s.id)
      or private.schoolpro_is_school_admin(s.id)
      or private.schoolpro_is_exam_officer(s.id)
    )
), readable as (
  select e.school_id::text||'|'||e.student_id::text||'|'||e.session key
  from public.schoolpro_enrollment_history e
  where auth.uid() is not null and private.is_active_account()
    and (
      e.school_id in(select id from leaders)
      or exists(select 1 from public.schoolpro_students s
        where s.id=e.student_id and s.school_id=e.school_id and s.user_id=auth.uid())
      or exists(select 1 from public.schoolpro_guardian_links g
        where g.school_id=e.school_id and g.student_id=e.student_id
          and g.guardian_user_id=auth.uid() and g.status='active')
      or exists(select 1 from public.schoolpro_members m
        where m.school_id=e.school_id and m.user_id=auth.uid()
          and m.role in('teacher','class_teacher')
          and (
            exists(select 1 from public.schoolpro_classes c
              where c.school_id=e.school_id and c.id=e.class_id and c.form_teacher_id=m.id)
            or exists(select 1 from public.schoolpro_subject_assignments a
              where a.school_id=e.school_id and a.class_id=e.class_id
                and a.session=e.session and a.teacher_member_id=m.id)
          ))
      or exists(select 1 from public.schoolpro_members m
        join public.schoolpro_section_leaders sl
          on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
        join public.schoolpro_classes c
          on c.school_id=e.school_id and c.id=e.class_id and c.level=sl.section
        where m.school_id=e.school_id and m.user_id=auth.uid() and m.status='active')
    )
    and private.schoolpro_operationally_active(e.school_id)
)
select coalesce(jsonb_object_agg(key,true),'{}'::jsonb) from readable
$$;
revoke all on function private.schoolpro_enrollment_reader_keys() from public,anon;
grant execute on function private.schoolpro_enrollment_reader_keys() to authenticated;

-- Supplemental School Administrator appointments must participate in the same
-- student/class read gates as the primary proprietor/administrator roles.
create or replace function private.schoolpro_can_read_student(p_student uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null and private.is_active_account() and exists(
   select 1 from public.schoolpro_students s
   where s.id=p_student and private.schoolpro_operationally_active(s.school_id)
   and (
     private.is_admin(array['super_admin'::public.user_role])
     or private.schoolpro_is_school_admin(s.school_id)
     or private.schoolpro_is_exam_officer(s.school_id)
     or s.user_id=auth.uid()
     or exists(select 1 from public.schoolpro_guardian_links g
       where g.school_id=s.school_id and g.student_id=s.id and g.guardian_user_id=auth.uid() and g.status='active')
     or exists(select 1 from public.schoolpro_schools sc where sc.id=s.school_id and sc.owner_id=auth.uid())
     or private.schoolpro_member_leads_class(s.school_id,s.class_id)
     or private.schoolpro_is_school_admin(s.school_id)
     or private.schoolpro_is_exam_officer(s.school_id)
     or exists(select 1 from public.schoolpro_members m where m.school_id=s.school_id and m.user_id=auth.uid() and (
       m.role::text not in('teacher','class_teacher','parent','student','head_teacher','vice_principal')
       or (m.role in('teacher','class_teacher') and (
         exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=s.school_id and a.class_id=s.class_id and a.teacher_member_id=m.id)
         or exists(select 1 from public.schoolpro_classes c where c.id=s.class_id and c.school_id=s.school_id and c.form_teacher_id=m.id)
       ))
     ))
   )
 )
$$;
revoke all on function private.schoolpro_can_read_student(uuid) from public,anon;
grant execute on function private.schoolpro_can_read_student(uuid) to authenticated;

create or replace function private.schoolpro_can_read_class(p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null and private.is_active_account() and exists(
   select 1 from public.schoolpro_classes c where c.id=p_class and (
     private.schoolpro_is_school_admin(c.school_id)
     or private.schoolpro_is_exam_officer(c.school_id)
     or private.has_school_access(c.school_id,array['proprietor','administrator']::public.school_member_role[])
     or private.schoolpro_member_leads_class(c.school_id,c.id)
     or exists(select 1 from public.schoolpro_members m where m.school_id=c.school_id and m.user_id=auth.uid() and (
       m.role::text not in('teacher','class_teacher','parent','student','head_teacher','vice_principal')
       or c.form_teacher_id=m.id
       or exists(select 1 from public.schoolpro_subject_assignments a
         where a.class_id=c.id and a.school_id=c.school_id and a.teacher_member_id=m.id)
     ))
     or exists(select 1 from public.schoolpro_students s where s.class_id=c.id and s.school_id=c.school_id
       and (s.user_id=auth.uid() or exists(select 1 from public.schoolpro_guardian_links g
         where g.student_id=s.id and g.guardian_user_id=auth.uid() and g.status='active')))
   )
 )
$$;
revoke all on function private.schoolpro_can_read_class(uuid) from public,anon;
grant execute on function private.schoolpro_can_read_class(uuid) to authenticated;

-- Full broadsheet review is reserved for Form Masters, appointed Section Heads,
-- Exam Officers, school administrators and Super Admins. Ordinary subject teachers
-- can read/write their own subject through the subject-specific results path only.
create or replace function private.schoolpro_can_review_class(p_school uuid,p_class uuid)
returns boolean language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null and private.is_active_account()
    and private.schoolpro_module_allowed(p_school,'results')
    and exists(select 1 from public.schoolpro_classes c
      where c.school_id=p_school and c.id=p_class)
    and (
      private.schoolpro_is_school_admin(p_school)
      or private.schoolpro_is_exam_officer(p_school)
      or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
      or private.is_admin(array['super_admin']::public.user_role[])
      or private.schoolpro_member_leads_class(p_school,p_class)
      or exists(select 1 from public.schoolpro_classes c
        join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
        where c.school_id=p_school and c.id=p_class and m.user_id=auth.uid() and m.status='active')
    )
$$;
revoke all on function private.schoolpro_can_review_class(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_can_review_class(uuid,uuid) to authenticated;

-- Read the active subject-teacher roster for a class without granting staff
-- direct membership/profile table access. Ordinary subject teachers see only
-- their own allocation; Form Masters, section heads, Exam Officers and admins
-- can see every active allocation in their permitted class scope.
create or replace function public.schoolpro_class_subject_teacher_roster(
  p_school uuid,p_class uuid,p_session text
) returns table(subject_id uuid,subject_name text,teacher_member_id uuid,teacher_name text)
language plpgsql stable security definer set search_path=''
as $$
declare v_member uuid;v_form_master boolean;v_wide_view boolean;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_module_allowed(p_school,'results')
     or not private.schoolpro_can_read_class(p_class) then
    raise exception 'Not authorized to view subject-teacher allocations for this class';
  end if;
  select id into v_member from public.schoolpro_members
   where school_id=p_school and user_id=auth.uid() and status='active';
  if v_member is null then raise exception 'Active school membership required'; end if;
  select exists(select 1 from public.schoolpro_classes c
    where c.school_id=p_school and c.id=p_class and c.form_teacher_id=v_member)
    into v_form_master;
  v_wide_view:=v_form_master
    or private.schoolpro_member_leads_class(p_school,p_class)
    or private.schoolpro_is_exam_officer(p_school)
    or private.schoolpro_is_school_admin(p_school)
    or private.is_admin(array['super_admin']::public.user_role[]);
  return query
    select a.subject_id,s.name,a.teacher_member_id,
      coalesce(nullif(trim(concat_ws(' ',p.first_name,p.last_name)),''),p.email,'Assigned staff')::text
    from public.schoolpro_subject_assignments a
    join public.schoolpro_subjects s on s.id=a.subject_id and s.school_id=a.school_id
    join public.schoolpro_members m on m.id=a.teacher_member_id and m.school_id=a.school_id and m.status='active'
    left join public.profiles p on p.id=m.user_id
    where a.school_id=p_school and a.class_id=p_class
      and a.session=trim(p_session) and a.ended_at is null
      and (v_wide_view or a.teacher_member_id=v_member)
    order by s.name,teacher_name;
end
$$;
revoke all on function public.schoolpro_class_subject_teacher_roster(uuid,uuid,text) from public,anon;
grant execute on function public.schoolpro_class_subject_teacher_roster(uuid,uuid,text) to authenticated;

-- Exact subject assignment is the only normal staff authority to create or
-- change marks. Form Master/Class Teacher and school leaders are read/review
-- roles; they cannot overwrite a subject teacher's mark merely by coordinating.
create or replace function private.schoolpro_enforce_subject_teacher_result_write()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_class uuid;
begin
  if tg_op='UPDATE'
     and new.school_id is not distinct from old.school_id
     and new.student_id is not distinct from old.student_id
     and new.subject_id is not distinct from old.subject_id
     and new.term is not distinct from old.term
     and new.session is not distinct from old.session
     and new.ca_score is not distinct from old.ca_score
     and new.exam_score is not distinct from old.exam_score
     and new.total_score is not distinct from old.total_score
     and new.assessment_scores is not distinct from old.assessment_scores
     and new.assessment_scheme_id is not distinct from old.assessment_scheme_id then
    return new;
  end if;
  -- Administrative and review roles are read/review authorities, not score-entry bypasses.
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'Authentication required to enter or change assessment scores';
  end if;
  select coalesce((
    select eh.class_id from public.schoolpro_enrollment_history eh
    where eh.school_id=new.school_id and eh.student_id=new.student_id
      and eh.session=trim(coalesce(new.session,''))
    order by eh.created_at desc limit 1
  ),s.class_id) into v_class
  from public.schoolpro_students s where s.school_id=new.school_id and s.id=new.student_id;
  if v_class is null or not exists(
    select 1 from public.schoolpro_members m
    join public.schoolpro_subject_assignments a
      on a.school_id=m.school_id and a.teacher_member_id=m.id
    where m.school_id=new.school_id and m.user_id=auth.uid() and m.status='active'
      and m.role::text in ('teacher','class_teacher')
      and a.class_id=v_class and a.subject_id=new.subject_id
      and a.session=trim(coalesce(new.session,'')) and a.ended_at is null
  ) then
    raise exception 'Only the active subject teacher assigned to this class and subject can enter or update these scores';
  end if;
  if tg_op='UPDATE' and (old.status<>'draft' or old.locked or new.status<>'draft' or new.locked) then
    raise exception 'Only unlocked Draft scores can be edited; request an authorized correction reopening';
  end if;
  if tg_op='INSERT' and (new.status<>'draft' or new.locked) then
    raise exception 'Subject teachers can create only unlocked Draft scores';
  end if;
  return new;
end
$$;
revoke all on function private.schoolpro_enforce_subject_teacher_result_write() from public,anon,authenticated;
drop trigger if exists schoolpro_subject_teacher_result_write on public.schoolpro_results;
create trigger schoolpro_subject_teacher_result_write
before insert or update of school_id,student_id,subject_id,term,session,ca_score,exam_score,total_score,assessment_scores,assessment_scheme_id
on public.schoolpro_results for each row
execute function private.schoolpro_enforce_subject_teacher_result_write();

-- Preserve assignment history during role downgrade: only a still-active
-- allocation must point to an eligible teacher/class teacher.
create or replace function private.validate_subject_assignment()
returns trigger language plpgsql security definer set search_path=''
as $$
declare class_school uuid;subject_school uuid;member_school uuid;member_role public.school_member_role;
begin
  select school_id into class_school from public.schoolpro_classes where id=new.class_id;
  select school_id into subject_school from public.schoolpro_subjects where id=new.subject_id;
  if class_school is null or subject_school is null
     or class_school<>new.school_id or subject_school<>new.school_id then
    raise exception 'Class and subject must belong to the selected school';
  end if;
  if new.teacher_member_id is not null then
    select school_id,role into member_school,member_role
    from public.schoolpro_members where id=new.teacher_member_id;
    if member_school is null or member_school<>new.school_id then
      raise exception 'Assigned teacher must belong to the selected school';
    end if;
    if new.ended_at is null and member_role not in ('teacher','class_teacher') then
      raise exception 'An active subject allocation requires an eligible teaching member';
    end if;
  end if;
  return new;
end
$$;
revoke all on function private.validate_subject_assignment() from public,anon,authenticated;

-- End active subject allocations when a member loses their teaching role.
-- This retains allocation history while preventing stale assignments from blocking
-- a Form Master's completeness check or authorizing score entry.
create or replace function private.schoolpro_prune_subject_assignments_role()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  if old.role::text in ('teacher','class_teacher')
     and new.role::text not in ('teacher','class_teacher') then
    update public.schoolpro_subject_assignments
      set ended_at=coalesce(ended_at,now())
    where school_id=old.school_id and teacher_member_id=old.id and ended_at is null;
  end if;
  return new;
end
$$;
revoke all on function private.schoolpro_prune_subject_assignments_role() from public,anon,authenticated;
drop trigger if exists schoolpro_prune_subject_assignments_role on public.schoolpro_members;
create trigger schoolpro_prune_subject_assignments_role
after update of role on public.schoolpro_members
for each row execute function private.schoolpro_prune_subject_assignments_role();

-- A class is ready for Form Master submission only when every active subject
-- allocation has a complete Draft result for every learner in that session.
create or replace function private.schoolpro_class_result_matrix_complete(
  p_school uuid,p_class uuid,p_term text,p_session text
) returns boolean
language sql stable security definer set search_path=''
as $$
with roster as (
  select s.id student_id
  from public.schoolpro_students s
  where s.school_id=p_school and (
    exists(select 1 from public.schoolpro_enrollment_history h
      where h.school_id=p_school and h.student_id=s.id
        and h.session=trim(p_session) and h.class_id=p_class)
    or (s.status='active' and s.class_id=p_class and not exists(
      select 1 from public.schoolpro_enrollment_history h
      where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session)))
  )
), assignments as (
  select a.subject_id from public.schoolpro_subject_assignments a
  where a.school_id=p_school and a.class_id=p_class
    and a.session=trim(p_session) and a.ended_at is null
)
select exists(select 1 from roster)
  and exists(select 1 from assignments)
  and not exists(
    select 1 from roster r cross join assignments a
    left join public.schoolpro_results x on x.school_id=p_school
      and x.student_id=r.student_id and x.subject_id=a.subject_id
      and x.term=trim(p_term) and x.session=trim(p_session)
    where x.id is null or x.status<>'draft' or x.locked
      or not private.schoolpro_result_assessment_complete(x.id)
  )
  and not exists(
    select 1 from public.schoolpro_results x
    join roster r on r.student_id=x.student_id
    where x.school_id=p_school and x.term=trim(p_term) and x.session=trim(p_session)
      and (x.status<>'draft' or x.locked or not private.schoolpro_result_assessment_complete(x.id))
  )
$$;
revoke all on function private.schoolpro_class_result_matrix_complete(uuid,uuid,text,text) from public,anon;
grant execute on function private.schoolpro_class_result_matrix_complete(uuid,uuid,text,text) to authenticated;

create or replace function private.schoolpro_result_scope_matrix_state(
  p_school uuid,p_term text,p_session text,p_scope text,p_class uuid,p_section text,
  p_workflow_status text,p_result_status text
) returns boolean language sql stable security definer set search_path=''
as $$
with target_classes as (
  select c.id from public.schoolpro_classes c
  where c.school_id=p_school
    and (p_scope='school' or (p_scope='class' and c.id=p_class)
      or (p_scope='section' and c.level=p_section))
), roster as (
  select c.id class_id,s.id student_id
  from target_classes tc
  join public.schoolpro_classes c on c.id=tc.id and c.school_id=p_school
  join public.schoolpro_students s on s.school_id=p_school and (
    exists(select 1 from public.schoolpro_enrollment_history h
      where h.school_id=p_school and h.student_id=s.id
        and h.session=trim(p_session) and h.class_id=c.id)
    or (s.status='active' and s.class_id=c.id and not exists(
      select 1 from public.schoolpro_enrollment_history h
      where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session)))
  )
), assignments as (
  select a.class_id,a.subject_id from public.schoolpro_subject_assignments a
  join target_classes tc on tc.id=a.class_id
  where a.school_id=p_school and a.session=trim(p_session) and a.ended_at is null
), expected as (
  select r.class_id,r.student_id,a.subject_id from roster r
  join assignments a on a.class_id=r.class_id
)
select exists(select 1 from expected)
  and not exists(
    select 1 from expected e
    left join public.schoolpro_results r on r.school_id=p_school
      and r.student_id=e.student_id and r.subject_id=e.subject_id
      and r.term=trim(p_term) and r.session=trim(p_session)
    left join public.schoolpro_result_workflow w on w.result_id=r.id
    where r.id is null or r.status<>p_result_status or w.status is distinct from p_workflow_status
  )
  and not exists(
    select 1 from public.schoolpro_result_workflow w
    join public.schoolpro_classes c on c.school_id=w.school_id and c.id=w.class_id
    where w.school_id=p_school and w.term=trim(p_term) and w.session=trim(p_session)
      and (p_scope='school' or (p_scope='class' and w.class_id=p_class)
        or (p_scope='section' and c.level=p_section))
      and w.status is distinct from p_workflow_status
  )
$$;
revoke all on function private.schoolpro_result_scope_matrix_state(uuid,text,text,text,uuid,text,text,text) from public,anon;
grant execute on function private.schoolpro_result_scope_matrix_state(uuid,text,text,text,uuid,text,text,text) to authenticated;

create or replace function public.schoolpro_submit_class_results(
  p_school uuid,p_class uuid,p_term text,p_session text
) returns integer
language plpgsql security definer set search_path=''
as $$
declare v_member uuid;v_count integer;
begin
  if auth.uid() is null or not private.is_active_account() then raise exception 'Authentication required'; end if;
  if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then
    raise exception 'Select an academic term and session';
  end if;
  if not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) then
    raise exception 'Module permission denied: results';
  end if;
  select m.id into v_member from public.schoolpro_members m
  join public.schoolpro_classes c on c.school_id=m.school_id
    and c.id=p_class and c.form_teacher_id=m.id
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active';
  if v_member is null then raise exception 'Only the assigned Form Master can submit this class result register'; end if;
  if not private.schoolpro_class_result_matrix_complete(p_school,p_class,p_term,p_session) then
    raise exception 'Submission blocked: every student must have a complete Draft result for every subject allocated to this class in the selected session';
  end if;
  perform s.id from public.schoolpro_students s
  where s.school_id=p_school and (
    exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
      and h.student_id=s.id and h.session=trim(p_session) and h.class_id=p_class)
    or (s.status='active' and s.class_id=p_class and not exists(select 1
      from public.schoolpro_enrollment_history h where h.school_id=p_school
        and h.student_id=s.id and h.session=trim(p_session)))
  ) order by s.id for update;
  perform r.id from public.schoolpro_results r
  join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status='draft' and not r.locked
    and (
      exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
        and h.student_id=s.id and h.session=trim(p_session) and h.class_id=p_class)
      or (s.status='active' and s.class_id=p_class and not exists(select 1
        from public.schoolpro_enrollment_history h where h.school_id=p_school
          and h.student_id=s.id and h.session=trim(p_session)))
    ) order by r.id for update of r;
  insert into public.schoolpro_result_workflow(
    result_id,school_id,class_id,term,session,status,submitted_by,submitted_at,
    approved_by,approved_at,published_at,updated_at
  )
  select r.id,p_school,p_class,trim(p_term),trim(p_session),'submitted',
    auth.uid(),now(),null,null,null,now()
  from public.schoolpro_results r
  join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status='draft' and not r.locked
    and (
      exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
        and h.student_id=s.id and h.session=trim(p_session) and h.class_id=p_class)
      or (s.status='active' and s.class_id=p_class and not exists(select 1
        from public.schoolpro_enrollment_history h where h.school_id=p_school
          and h.student_id=s.id and h.session=trim(p_session)))
    )
  on conflict(result_id) do update set
    school_id=excluded.school_id,class_id=excluded.class_id,term=excluded.term,session=excluded.session,
    status='submitted',submitted_by=excluded.submitted_by,submitted_at=now(),
    approved_by=null,approved_at=null,published_at=null,correction_notes=null,updated_at=now()
  where public.schoolpro_result_workflow.status in ('draft','correction_requested','submitted');
  get diagnostics v_count=row_count;
  if v_count=0 then raise exception 'No Draft results were available to submit'; end if;
  return v_count;
end
$$;
revoke all on function public.schoolpro_submit_class_results(uuid,uuid,text,text) from public,anon;
grant execute on function public.schoolpro_submit_class_results(uuid,uuid,text,text) to authenticated;

-- Expand workflow states while retaining the existing one-row-per-result model.
alter table public.schoolpro_result_workflow
  drop constraint if exists schoolpro_result_workflow_status_check;
alter table public.schoolpro_result_workflow
  add constraint schoolpro_result_workflow_status_check
  check(status in ('draft','submitted','correction_requested','section_approved','exam_approved','published'));
alter table public.schoolpro_result_workflow
  add column if not exists section_approved_by uuid references auth.users(id),
  add column if not exists section_approved_at timestamptz,
  add column if not exists exam_approved_by uuid references auth.users(id),
  add column if not exists exam_approved_at timestamptz,
  add column if not exists correction_notes text;

-- Replace the original trigger: Section Head approves, Exam Officer publishes.
create or replace function private.enforce_result_workflow()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_level text;v_class uuid;v_workflow_class uuid;v_workflow_status text;
begin
  if old.status in ('approved','published') and new.status='draft'
     and not exists(
       select 1 from public.schoolpro_result_correction_batches b
       join public.schoolpro_result_correction_batch_items i on i.batch_id=b.id
       where b.id=nullif(current_setting('app.schoolpro_correction_reopen',true),'')::uuid
         and b.status='pending' and i.result_id=old.id
         and private.schoolpro_is_exam_officer(old.school_id)
     ) then
    raise exception 'Only an Exam Officer-approved class or section correction request can reopen an approved or published result';
  end if;
  if old.status='published' and new.status is distinct from old.status
     and new.status<>'draft' then
    raise exception 'Published results are locked until an authorized correction reopening';
  end if;
  if old.status in ('approved','published') and new.locked is distinct from old.locked
     and not (new.status='draft' and exists(
       select 1 from public.schoolpro_result_correction_batches b
       join public.schoolpro_result_correction_batch_items i on i.batch_id=b.id
       where b.id=nullif(current_setting('app.schoolpro_correction_reopen',true),'')::uuid
         and b.status='pending' and i.result_id=old.id
         and private.schoolpro_is_exam_officer(old.school_id)
     )) then
    raise exception 'Approved and published result lock state can only change through an authorized correction reopening';
  end if;
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
  ) then raise exception 'Approved or published results must be reopened through the correction workflow before editing'; end if;

  if new.status=old.status and old.status='draft' and (
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
    update public.schoolpro_result_workflow set status='draft',submitted_by=null,
      submitted_at=null,approved_by=null,approved_at=null,section_approved_by=null,
      section_approved_at=null,exam_approved_by=null,exam_approved_at=null,updated_at=now()
    where result_id=old.id and status in ('submitted','correction_requested');
  end if;

  if new.status is distinct from old.status and new.status='approved' then
    select c.level,c.id into v_level,v_class
    from public.schoolpro_students s
    left join lateral (select eh.class_id from public.schoolpro_enrollment_history eh
      where eh.school_id=new.school_id and eh.student_id=new.student_id
        and eh.session=trim(coalesce(new.session,'')) order by eh.created_at desc limit 1) h on true
    join public.schoolpro_classes c on c.school_id=s.school_id
      and c.id=coalesce(h.class_id,s.class_id)
    where s.school_id=new.school_id and s.id=new.student_id;
    select w.status,w.class_id into v_workflow_status,v_workflow_class
      from public.schoolpro_result_workflow w where w.result_id=new.id for update;
    if v_workflow_class is distinct from v_class or v_workflow_status is distinct from 'submitted' then
      raise exception 'The Form Master must submit a complete class register before section approval';
    end if;
    if not private.schoolpro_member_leads_student_section(new.school_id,new.student_id,new.session)
       and not private.is_admin(array['super_admin']::public.user_role[]) then
      raise exception 'Only the appointed section head can approve this section result';
    end if;
  elsif new.status is distinct from old.status and new.status='published' then
    select w.status into v_workflow_status from public.schoolpro_result_workflow w
      where w.result_id=new.id for update;
    if old.status<>'approved' or v_workflow_status is distinct from 'exam_approved' then
      raise exception 'The Exam Officer must complete final approval before publication';
    end if;
    if not private.schoolpro_is_exam_officer(new.school_id) then
      raise exception 'Only the Exam Officer can publish school results';
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
    update public.schoolpro_result_workflow set status='section_approved',
      approved_by=auth.uid(),approved_at=now(),section_approved_by=auth.uid(),
      section_approved_at=now(),updated_at=now()
    where result_id=new.id and status='submitted';
  elsif new.status='published' and old.status is distinct from 'published' then
    update public.schoolpro_result_workflow set status='published',
      published_at=coalesce(new.published_at,now()),updated_at=now()
    where result_id=new.id and status='exam_approved';
  elsif new.status='draft' and old.status in ('approved','published') then
    update public.schoolpro_result_workflow set status='draft',submitted_by=null,
      submitted_at=null,approved_by=null,approved_at=null,section_approved_by=null,
      section_approved_at=null,exam_approved_by=null,exam_approved_at=null,
      published_at=null,correction_notes=null,updated_at=now()
    where result_id=new.id;
  end if;
  return new;
end
$$;

-- A Section Head may return a submitted class register to its Form Master.
create or replace function public.schoolpro_return_class_results_for_correction(
  p_school uuid,p_class uuid,p_term text,p_session text,p_notes text
) returns integer language plpgsql security definer set search_path=''
as $$
declare n integer;
begin
  if auth.uid() is null or not private.is_active_account() then raise exception 'Authentication required'; end if;
  if nullif(trim(p_notes),'') is null or length(trim(p_notes))<10 then
    raise exception 'Provide a correction note of at least 10 characters';
  end if;
  if not exists(select 1 from public.schoolpro_classes c where c.school_id=p_school
    and c.id=p_class and private.schoolpro_member_leads_class(p_school,c.id)) then
    raise exception 'Only the appointed section head can return this class result';
  end if;
  update public.schoolpro_result_workflow set status='correction_requested',
    correction_notes=trim(p_notes),updated_at=now()
  where school_id=p_school and class_id=p_class and term=trim(p_term)
    and session=trim(p_session) and status='submitted';
  get diagnostics n=row_count;
  if n=0 then raise exception 'No submitted class results are awaiting section review'; end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Class results returned for correction','class',p_class,
    jsonb_build_object('term',trim(p_term),'session',trim(p_session),'notes',trim(p_notes),'result_count',n));
  return n;
end
$$;
revoke all on function public.schoolpro_return_class_results_for_correction(uuid,uuid,text,text,text) from public,anon;
grant execute on function public.schoolpro_return_class_results_for_correction(uuid,uuid,text,text,text) to authenticated;

create or replace function private.schoolpro_result_scope_mixed_state(
  p_school uuid,p_term text,p_session text,p_scope text,p_class uuid,p_section text,p_stage text
) returns boolean language sql stable security definer set search_path=''
as $$
with target_classes as (
  select c.id from public.schoolpro_classes c
  where c.school_id=p_school and (p_scope='school' or (p_scope='class' and c.id=p_class)
    or (p_scope='section' and c.level=p_section))
), roster as (
  select c.id class_id,s.id student_id from target_classes tc
  join public.schoolpro_classes c on c.id=tc.id and c.school_id=p_school
  join public.schoolpro_students s on s.school_id=p_school and (
    exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
      and h.student_id=s.id and h.session=trim(p_session) and h.class_id=c.id)
    or (s.status='active' and s.class_id=c.id and not exists(
      select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
        and h.student_id=s.id and h.session=trim(p_session)))
  )
), assignments as (
  select a.class_id,a.subject_id from public.schoolpro_subject_assignments a
  join target_classes tc on tc.id=a.class_id
  where a.school_id=p_school and a.session=trim(p_session) and a.ended_at is null
), expected as (
  select r.class_id,r.student_id,a.subject_id from roster r join assignments a on a.class_id=r.class_id
)
select exists(select 1 from expected)
  and not exists(
    select 1 from expected e
    left join public.schoolpro_results r on r.school_id=p_school and r.student_id=e.student_id
      and r.subject_id=e.subject_id and r.term=trim(p_term) and r.session=trim(p_session)
    left join public.schoolpro_result_workflow w on w.result_id=r.id
    where r.id is null or not private.schoolpro_result_assessment_complete(r.id)
      or (p_stage='section' and not (
        (r.status='draft' and w.status='submitted')
        or (r.status='approved' and w.status='section_approved')
      ))
      or (p_stage='exam' and (r.status<>'approved' or w.status not in ('section_approved','exam_approved')))
  )
  and not exists(
    select 1 from public.schoolpro_result_workflow w
    join public.schoolpro_classes c on c.school_id=w.school_id and c.id=w.class_id
    where w.school_id=p_school and w.term=trim(p_term) and w.session=trim(p_session)
      and (p_scope='school' or (p_scope='class' and w.class_id=p_class)
        or (p_scope='section' and c.level=p_section))
      and (p_stage='section' and w.status not in ('submitted','section_approved')
        or p_stage='exam' and w.status not in ('section_approved','exam_approved'))
  )
$$;
revoke all on function private.schoolpro_result_scope_mixed_state(uuid,text,text,text,uuid,text,text) from public,anon;
grant execute on function private.schoolpro_result_scope_mixed_state(uuid,text,text,text,uuid,text,text) to authenticated;

create or replace function public.schoolpro_class_result_workflow_summary(
  p_school uuid,p_class uuid,p_term text,p_session text
) returns table(workflow_status text,correction_notes text,result_count bigint)
language plpgsql stable security definer set search_path=''
as $$
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_module_allowed(p_school,'results')
     or not private.schoolpro_can_review_class(p_school,p_class) then
    raise exception 'Not authorized to view this class result workflow';
  end if;
  return query
    select w.status,w.correction_notes,count(*)::bigint
    from public.schoolpro_result_workflow w
    where w.school_id=p_school and w.class_id=p_class
      and w.term=trim(p_term) and w.session=trim(p_session)
    group by w.status,w.correction_notes
    order by w.status;
end
$$;
revoke all on function public.schoolpro_class_result_workflow_summary(uuid,uuid,text,text) from public,anon;
grant execute on function public.schoolpro_class_result_workflow_summary(uuid,uuid,text,text) to authenticated;

-- A Section Head can approve the complete submitted section as one atomic hand-off.
create or replace function public.schoolpro_approve_section_results(
  p_school uuid,p_section text,p_term text,p_session text
) returns integer language plpgsql security definer set search_path=''
as $$
declare n integer;
begin
  if auth.uid() is null or not private.is_active_account() then raise exception 'Authentication required'; end if;
  if p_section not in ('nursery','primary','junior_secondary','senior_secondary','other')
     or nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then
    raise exception 'Choose a valid section, term and session';
  end if;
  if not exists(select 1 from public.schoolpro_members m
    join public.schoolpro_section_leaders sl on sl.school_id=m.school_id
      and sl.member_id=m.id and sl.ended_at is null and sl.section=p_section
    where m.school_id=p_school and m.user_id=auth.uid() and m.status='active') then
    raise exception 'Only the appointed section head can approve this section';
  end if;
  if not private.schoolpro_result_scope_mixed_state(p_school,p_term,p_session,'section',null,p_section,'section') then
    raise exception 'Every allocated subject result for every student in the section must be complete and submitted by its Form Master';
  end if;
  if not exists(select 1 from public.schoolpro_result_workflow w
    join public.schoolpro_classes c on c.school_id=w.school_id and c.id=w.class_id
    where w.school_id=p_school and c.level=p_section
      and w.term=trim(p_term) and w.session=trim(p_session)) then
    raise exception 'No submitted class results exist in this section for the selected period';
  end if;
  update public.schoolpro_results r set status='approved',updated_at=now()
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status='draft' and not r.locked
    and exists(select 1 from public.schoolpro_result_workflow w
      join public.schoolpro_classes c on c.school_id=w.school_id and c.id=w.class_id
      where w.result_id=r.id and w.status='submitted' and c.level=p_section);
  get diagnostics n=row_count;
  if n=0 then raise exception 'No submitted results were available for section approval'; end if;
  update public.schoolpro_result_workflow w set status='section_approved',
    approved_by=auth.uid(),approved_at=now(),updated_at=now()
  from public.schoolpro_classes c
  where c.school_id=w.school_id and c.id=w.class_id and w.school_id=p_school
    and c.level=p_section and w.term=trim(p_term) and w.session=trim(p_session)
    and w.status='submitted';
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Entire section result approved','section',p_school,
    jsonb_build_object('section',p_section,'term',trim(p_term),'session',trim(p_session),'result_count',n));
  return n;
end
$$;
revoke all on function public.schoolpro_approve_section_results(uuid,text,text,text) from public,anon;
grant execute on function public.schoolpro_approve_section_results(uuid,text,text,text) to authenticated;

-- Exam Officer performs final approval for a class, section or whole school.
create or replace function public.schoolpro_exam_officer_approve_results(
  p_school uuid,p_term text,p_session text,p_scope text,
  p_class uuid default null,p_section text default null
) returns integer language plpgsql security definer set search_path=''
as $$
declare n integer;
begin
  if auth.uid() is null or not private.is_active_account() then raise exception 'Authentication required'; end if;
  if not private.schoolpro_is_exam_officer(p_school) then raise exception 'Only the Exam Officer can give final result approval'; end if;
  if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null
     or p_scope not in ('class','section','school') then raise exception 'Choose a valid result period and approval scope'; end if;
  if p_scope='class' and p_class is null then raise exception 'Select a class for final approval'; end if;
  if p_scope='section' and p_section not in ('nursery','primary','junior_secondary','senior_secondary','other') then
    raise exception 'Select a valid section for final approval';
  end if;
  if p_scope='school' and (p_class is not null or p_section is not null) then
    raise exception 'Whole-school approval cannot include a class or section filter';
  end if;
  if not private.schoolpro_result_scope_mixed_state(p_school,p_term,p_session,p_scope,p_class,p_section,'exam') then
    raise exception 'Every allocated class and subject result in the selected scope must be section-approved before final approval';
  end if;
  if exists(select 1 from public.schoolpro_result_workflow w
    join public.schoolpro_classes c on c.school_id=w.school_id and c.id=w.class_id
    left join public.schoolpro_results r on r.id=w.result_id
    where w.school_id=p_school and w.term=trim(p_term) and w.session=trim(p_session)
      and (p_scope='school' or (p_scope='class' and w.class_id=p_class)
        or (p_scope='section' and c.level=p_section))
      and (r.id is null or r.status<>'approved')) then
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
  values(p_school,auth.uid(),'Results approved by Exam Officer',p_scope,coalesce(p_class,p_school),
    jsonb_build_object('term',trim(p_term),'session',trim(p_session),'section',p_section,'result_count',n));
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
  if not private.schoolpro_is_exam_officer(p_school) then raise exception 'Only the Exam Officer can publish school results'; end if;
  if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then
    raise exception 'Select an academic term and session';
  end if;
  if not private.schoolpro_result_scope_matrix_state(p_school,p_term,p_session,'school',null,null,'exam_approved','approved') then
    raise exception 'Whole-school publication is blocked until every allocated subject result in every class has final Exam Officer approval';
  end if;
  if not exists(select 1 from public.schoolpro_result_workflow w
    where w.school_id=p_school and w.term=trim(p_term) and w.session=trim(p_session)) then
    raise exception 'No submitted results exist for this school period';
  end if;
  if exists(select 1 from public.schoolpro_result_workflow w
    where w.school_id=p_school and w.term=trim(p_term) and w.session=trim(p_session)
      and w.status<>'exam_approved') then
    raise exception 'Whole-school publication is blocked until every submitted result has final Exam Officer approval';
  end if;
  if exists(select 1 from public.schoolpro_results r
    join public.schoolpro_students s on s.school_id=r.school_id and s.id=r.student_id
    where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
      and r.status<>'approved') then
    raise exception 'Whole-school publication is blocked because one or more results are not section-approved';
  end if;
  update public.schoolpro_results r set status='published',locked=true,updated_at=now()
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status='approved' and exists(select 1 from public.schoolpro_result_workflow w
      where w.result_id=r.id and w.status='exam_approved');
  get diagnostics n=row_count;
  if n=0 then raise exception 'No final-approved results are available to publish'; end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Whole-school results published','school',p_school,
    jsonb_build_object('term',trim(p_term),'session',trim(p_session),'result_count',n));
  return n;
end
$$;
revoke all on function public.schoolpro_publish_school_results(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_publish_school_results(uuid,text,text) to authenticated;

-- A correction request snapshots all affected result rows. Approval reopens
-- exactly one class or one entire academic section, never an unscoped school set.
create table public.schoolpro_result_correction_batches (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  scope text not null check(scope in ('class','section')),
  class_id uuid references public.schoolpro_classes(id) on delete restrict,
  section text,
  term text not null,
  session text not null,
  reason text not null check(length(trim(reason))>=10),
  requested_by uuid not null references auth.users(id),
  status text not null default 'pending' check(status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  review_notes text,
  created_at timestamptz not null default now(),
  check((scope='class' and class_id is not null and section is null)
     or (scope='section' and class_id is null and section is not null))
);
create index schoolpro_result_correction_batches_pending_idx
  on public.schoolpro_result_correction_batches(school_id,status,created_at desc);
create table public.schoolpro_result_correction_batch_items (
  batch_id uuid not null references public.schoolpro_result_correction_batches(id) on delete cascade,
  result_id uuid not null references public.schoolpro_results(id) on delete cascade,
  primary key(batch_id,result_id)
);
alter table public.schoolpro_result_correction_batches enable row level security;
alter table public.schoolpro_result_correction_batch_items enable row level security;
revoke all on public.schoolpro_result_correction_batches,public.schoolpro_result_correction_batch_items from public,anon,authenticated;
create policy schoolpro_result_correction_batches_exam_officer_read
on public.schoolpro_result_correction_batches for select to authenticated
using (private.schoolpro_is_exam_officer(school_id) or private.schoolpro_is_school_admin(school_id)
  or private.is_admin(array['super_admin']::public.user_role[]));
create policy schoolpro_result_correction_batch_items_exam_officer_read
on public.schoolpro_result_correction_batch_items for select to authenticated
using (exists(select 1 from public.schoolpro_result_correction_batches b
  where b.id=batch_id and (private.schoolpro_is_exam_officer(b.school_id)
    or private.schoolpro_is_school_admin(b.school_id)
    or private.is_admin(array['super_admin']::public.user_role[]))));
grant select on public.schoolpro_result_correction_batches,public.schoolpro_result_correction_batch_items to authenticated;

create or replace function public.schoolpro_request_result_reopening(
  p_school uuid,p_scope text,p_class uuid,p_section text,
  p_term text,p_session text,p_reason text
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_request uuid;v_member uuid;v_count integer;
begin
  if auth.uid() is null or not private.is_active_account() then raise exception 'Authentication required'; end if;
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
    or exists(select 1 from public.schoolpro_classes c where c.school_id=p_school and c.id=p_class and c.form_teacher_id=v_member)
    or exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=p_school
      and a.teacher_member_id=v_member and a.class_id=p_class and a.session=trim(p_session) and a.ended_at is null
      and exists(select 1 from public.schoolpro_members m where m.id=v_member and m.school_id=p_school and m.role::text in ('teacher','class_teacher')))
    or private.schoolpro_member_leads_class(p_school,p_class)
  ) then raise exception 'Only an assigned class teacher, subject teacher, section head or school administrator can request this class reopening'; end if;
  if p_scope='section' and not (
    private.schoolpro_member_has_responsibility(p_school,'school_admin')
    or exists(select 1 from public.schoolpro_section_leaders sl where sl.school_id=p_school
      and sl.member_id=v_member and sl.section=p_section and sl.ended_at is null)
  ) then raise exception 'Only the appointed section head or school administrator can request a section reopening'; end if;
  insert into public.schoolpro_result_correction_batches(school_id,scope,class_id,section,term,session,reason,requested_by)
  values(p_school,p_scope,p_class,p_section,trim(p_term),trim(p_session),trim(p_reason),auth.uid())
  returning id into v_request;
  insert into public.schoolpro_result_correction_batch_items(batch_id,result_id)
  select v_request,r.id from public.schoolpro_results r
  join public.schoolpro_students s on s.school_id=r.school_id and s.id=r.student_id
  join lateral (select coalesce((select eh.class_id from public.schoolpro_enrollment_history eh
    where eh.school_id=p_school and eh.student_id=s.id and eh.session=trim(p_session)
    order by eh.created_at desc limit 1),s.class_id) class_id) roster on true
  join public.schoolpro_classes c on c.school_id=p_school and c.id=roster.class_id
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
    and r.status in ('approved','published')
    and (p_scope='class' and c.id=p_class or p_scope='section' and c.level=p_section);
  get diagnostics v_count=row_count;
  if v_count=0 then raise exception 'No approved or published results exist in the requested correction scope'; end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Result reopening requested',p_scope,coalesce(p_class,v_request),
    jsonb_build_object('request_id',v_request,'term',trim(p_term),'session',trim(p_session),
      'section',p_section,'reason',trim(p_reason),'result_count',v_count));
  return v_request;
end
$$;
revoke all on function public.schoolpro_request_result_reopening(uuid,text,uuid,text,text,text,text) from public,anon;
grant execute on function public.schoolpro_request_result_reopening(uuid,text,uuid,text,text,text,text) to authenticated;

create or replace function public.schoolpro_decide_result_reopening(
  p_request uuid,p_approve boolean,p_notes text default null
) returns integer language plpgsql security definer set search_path=''
as $$
declare request_row public.schoolpro_result_correction_batches;v_count integer;
begin
  if auth.uid() is null or not private.is_active_account() then raise exception 'Authentication required'; end if;
  if p_approve is null then raise exception 'Choose approve or reject'; end if;
  select * into request_row from public.schoolpro_result_correction_batches where id=p_request for update;
  if request_row.id is null or request_row.status<>'pending' then raise exception 'Pending correction request not found'; end if;
  if not private.schoolpro_is_exam_officer(request_row.school_id) then
    raise exception 'Only the Exam Officer can authorize a class or section result reopening';
  end if;
  if p_approve then
    perform set_config('app.schoolpro_correction_reopen',p_request::text,true);
    update public.schoolpro_results r set status='draft',locked=false,updated_at=now()
    where r.id in(select i.result_id from public.schoolpro_result_correction_batch_items i where i.batch_id=p_request)
      and r.status in ('approved','published');
    get diagnostics v_count=row_count;
    if v_count=0 then raise exception 'No results remain eligible for reopening in this request'; end if;
  else
    select count(*) into v_count from public.schoolpro_result_correction_batch_items where batch_id=p_request;
  end if;
  update public.schoolpro_result_correction_batches set
    status=case when p_approve then 'approved' else 'rejected' end,
    reviewed_by=auth.uid(),reviewed_at=now(),review_notes=nullif(trim(p_notes), '')
  where id=p_request and status='pending';
  if not found then raise exception 'Correction request was already reviewed'; end if;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(request_row.school_id,auth.uid(),
    case when p_approve then 'Class or section results reopened for correction' else 'Result reopening request rejected' end,
    request_row.scope,coalesce(request_row.class_id,p_request),
    jsonb_build_object('request_id',p_request,'scope',request_row.scope,'section',request_row.section,
      'term',request_row.term,'session',request_row.session,'result_count',v_count,'notes',p_notes));
  return v_count;
end
$$;
revoke all on function public.schoolpro_decide_result_reopening(uuid,boolean,text) from public,anon;
grant execute on function public.schoolpro_decide_result_reopening(uuid,boolean,text) to authenticated;

-- Retire legacy per-result, partial-class and pre-section approval/publication RPCs.
-- The only live hand-off is Form Master submit -> Section Head approval ->
-- Exam Officer final approval -> whole-school publication.
do $retire_legacy_result_rpcs$
declare signature text;
begin
  foreach signature in array array[
    'public.review_schoolpro_result(uuid,text,text)',
    'public.review_schoolpro_results(uuid[],text)',
    'public.review_schoolpro_class_results(uuid,uuid,text,text,text,uuid[])',
    'public.publish_schoolpro_class_results(uuid,uuid,text,text)',
    'public.publish_schoolpro_selected_results(uuid,text,text,uuid[],boolean,uuid)',
    'public.publish_schoolpro_results(uuid,text,text)'
  ] loop
    if to_regprocedure(signature) is not null then
      execute format('revoke all on function %s from public,anon,authenticated',signature);
    end if;
  end loop;
end
$retire_legacy_result_rpcs$;

-- Retire the legacy per-result reopening path. All post-approval changes must
-- use a class- or section-scoped correction batch approved by the Exam Officer.
create or replace function public.decide_schoolpro_result_correction_request(
 p_request uuid,p_approve boolean,p_notes text default null
) returns uuid language plpgsql security definer set search_path=''
as $$
begin
  raise exception 'Individual result reopening is retired. Submit a class or section correction request for Exam Officer approval.';
end
$$;
revoke all on function public.decide_schoolpro_result_correction_request(uuid,boolean,text) from public,anon,authenticated;
-- Preserve the legacy request table for audit history, but disable direct client writes/reads
-- wherever that legacy table is present in the upgraded schema.
do $revoke_legacy_table$
begin
  if to_regclass('public.schoolpro_result_correction_requests') is not null then
    execute 'revoke all on table public.schoolpro_result_correction_requests from public,anon,authenticated';
  end if;
end
$revoke_legacy_table$;
do $revoke_legacy$
begin
  if to_regprocedure('public.reopen_schoolpro_result_for_correction(uuid,text)') is not null then
    execute 'revoke all on function public.reopen_schoolpro_result_for_correction(uuid,text) from public,anon,authenticated';
  end if;
end
$revoke_legacy$;

