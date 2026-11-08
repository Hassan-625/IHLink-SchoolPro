-- Extend explicit section-head appointments to Principals.
-- Principal remains stored as administrator + position_title='Principal' for
-- compatibility with the existing school role catalogue and permission model.
alter table public.schoolpro_section_leaders
  add column if not exists ended_at timestamptz;

create or replace function private.schoolpro_member_leads_student_section(
  p_school uuid, p_student uuid, p_session text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null
    and private.is_active_account()
    and exists (
      select 1
      from public.schoolpro_members m
      join public.schoolpro_section_leaders sl
        on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
      join public.schoolpro_students st
        on st.school_id=p_school and st.id=p_student
      join public.schoolpro_classes c
        on c.school_id=p_school
       and c.id=coalesce((
         select eh.class_id from public.schoolpro_enrollment_history eh
         where eh.school_id=p_school and eh.student_id=p_student
           and eh.session=trim(coalesce(p_session,''))
         order by eh.created_at desc limit 1
       ), st.class_id)
       and c.level=sl.section
      where m.school_id=p_school and m.user_id=auth.uid()
        and (
          (sl.section in ('nursery','primary') and m.role='head_teacher')
          or (sl.section in ('junior_secondary','senior_secondary') and (
            m.role='vice_principal'
            or (m.role='administrator' and lower(coalesce(m.position_title,''))='principal')
          ))
        )
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
    where m.school_id=p_school and m.user_id=auth.uid()
      and (
          (sl.section in ('nursery','primary') and m.role='head_teacher')
          or (sl.section in ('junior_secondary','senior_secondary') and (
            m.role='vice_principal'
            or (m.role='administrator' and lower(coalesce(m.position_title,''))='principal')
          ))
        )
  )
$$;
revoke all on function private.schoolpro_member_leads_class(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_member_leads_class(uuid,uuid) to authenticated;

create or replace function private.schoolpro_set_section_leader(
  p_school uuid, p_member uuid, p_section text, p_assigned boolean
) returns void
language plpgsql security definer set search_path=''
as $$
declare target public.schoolpro_members;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[]) then
    raise exception 'Only school leadership can manage section assignments';
  end if;
  if p_section not in ('nursery','primary','junior_secondary','senior_secondary','other') then
    raise exception 'Choose a valid school section';
  end if;
  select * into target from public.schoolpro_members
   where id=p_member and school_id=p_school for update;
  if target.id is null or not (
    (target.role='head_teacher' and p_section in ('nursery','primary'))
    or (target.role='vice_principal' and p_section in ('junior_secondary','senior_secondary'))
    or (target.role='administrator' and lower(coalesce(target.position_title,''))='principal'
        and p_section in ('junior_secondary','senior_secondary'))
  ) then
    raise exception 'Nursery and Primary require a Head Teacher; Junior and Senior Secondary require a Vice Principal or Principal';
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

create or replace function private.schoolpro_prune_section_leadership_role()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  if not (
    new.role in ('head_teacher','vice_principal')
    or (new.role='administrator' and lower(coalesce(new.position_title,''))='principal')
  ) then
    update public.schoolpro_section_leaders set ended_at=now()
    where school_id=new.school_id and member_id=new.id and ended_at is null;
  end if;
  return new;
end
$$;
revoke all on function private.schoolpro_prune_section_leadership_role() from public,anon,authenticated;
drop trigger if exists schoolpro_prune_section_leadership_role on public.schoolpro_members;
create trigger schoolpro_prune_section_leadership_role
after update of role,position_title on public.schoolpro_members
for each row execute function private.schoolpro_prune_section_leadership_role();

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
      or exists(select 1
        from public.schoolpro_members m
        join public.schoolpro_section_leaders sl
          on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
        join public.schoolpro_classes c
          on c.school_id=e.school_id and c.id=e.class_id and c.level=sl.section
        where m.school_id=e.school_id and m.user_id=auth.uid()
          and (
          (sl.section in ('nursery','primary') and m.role='head_teacher')
          or (sl.section in ('junior_secondary','senior_secondary') and (
            m.role='vice_principal'
            or (m.role='administrator' and lower(coalesce(m.position_title,''))='principal')
          ))
        ))
    )
    and private.schoolpro_operationally_active(e.school_id)
)
select coalesce(jsonb_object_agg(key,true),'{}'::jsonb) from readable
$$;
revoke all on function private.schoolpro_enrollment_reader_keys() from public,anon;
grant execute on function private.schoolpro_enrollment_reader_keys() to authenticated;

-- The section assignment table is read-only to clients; the RPC above remains
-- the only write path and records every appointment/removal in the audit log.

-- Approval/publication is section-specific: Form Masters submit their class
-- work; only the appointed academic leader for that section can approve or
-- publish it. Platform Super Admin remains an emergency override.
create or replace function private.enforce_result_workflow()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_level text;
begin
  if old.status='published' and (
    new.ca_score is distinct from old.ca_score
    or new.exam_score is distinct from old.exam_score
    or new.assessment_scores is distinct from old.assessment_scores
    or new.assessment_scheme_id is distinct from old.assessment_scheme_id
  ) then
    raise exception 'Published results are locked';
  end if;
  if new.status is distinct from old.status
     and new.status in ('approved','published') then
    select c.level into v_level
    from public.schoolpro_students s
    left join lateral (
      select eh.class_id from public.schoolpro_enrollment_history eh
      where eh.school_id=new.school_id and eh.student_id=new.student_id
        and eh.session=trim(coalesce(new.session,''))
      order by eh.created_at desc limit 1
    ) h on true
    join public.schoolpro_classes c
      on c.school_id=s.school_id and c.id=coalesce(h.class_id,s.class_id)
    where s.school_id=new.school_id and s.id=new.student_id;
    if not private.is_admin(array['super_admin']::public.user_role[])
       and not exists(
        select 1
        from public.schoolpro_members m
        join public.schoolpro_section_leaders sl
          on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
        where m.school_id=new.school_id and m.user_id=auth.uid()
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
    if old.status<>'approved' then raise exception 'Results must be approved by the section head before publication';end if;
    new.published_at:=now();
  end if;
  return new;
end
$$;
