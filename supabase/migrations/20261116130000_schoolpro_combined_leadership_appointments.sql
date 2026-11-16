-- Explicit, single-holder combined leadership appointments.
-- Combined scopes are independent of individual section-head assignments so
-- removing an overall appointment never removes a person's normal section role.

create table public.schoolpro_combined_leadership_appointments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  member_id uuid not null references public.schoolpro_members(id) on delete cascade,
  appointment_key text not null check (appointment_key in (
    'nursery_primary_headteacher','overall_secondary_principal'
  )),
  assigned_by uuid not null references auth.users(id),
  assigned_at timestamptz not null default now(),
  ended_at timestamptz
);
create unique index schoolpro_combined_leadership_one_active_idx
  on public.schoolpro_combined_leadership_appointments(school_id,appointment_key)
  where ended_at is null;
create index schoolpro_combined_leadership_member_idx
  on public.schoolpro_combined_leadership_appointments(school_id,member_id)
  where ended_at is null;

alter table public.schoolpro_combined_leadership_appointments enable row level security;
alter table public.schoolpro_combined_leadership_appointments force row level security;
revoke all on public.schoolpro_combined_leadership_appointments from anon,authenticated;
grant select on public.schoolpro_combined_leadership_appointments to authenticated;
create policy schoolpro_combined_leadership_admin_or_self_read
on public.schoolpro_combined_leadership_appointments for select to authenticated
using (
  private.is_active_account()
  and private.schoolpro_operationally_active(school_id)
  and (
    private.is_admin(array['super_admin']::public.user_role[])
    or private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])
    or private.schoolpro_member_has_responsibility(school_id,'school_admin')
    or exists(select 1 from public.schoolpro_members m
      where m.id=schoolpro_combined_leadership_appointments.member_id
        and m.school_id=schoolpro_combined_leadership_appointments.school_id
        and m.user_id=auth.uid() and m.status='active')
  )
);

create or replace function public.schoolpro_set_combined_leadership(
  p_school uuid,p_member uuid,p_appointment text,p_assigned boolean
) returns void
language plpgsql security definer set search_path=''
as $$
declare
  target public.schoolpro_members;
  existing public.schoolpro_combined_leadership_appointments;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not (
       private.is_admin(array['super_admin']::public.user_role[])
       or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
       or private.schoolpro_member_has_responsibility(p_school,'school_admin')
     ) then
    raise exception 'Only authorized school administration can manage combined leadership appointments';
  end if;

  select * into target from public.schoolpro_members
  where id=p_member and school_id=p_school and status='active'
  for update;
  if target.id is null then raise exception 'Choose an active staff member in this school'; end if;

  if p_appointment='nursery_primary_headteacher' then
    if target.role <> 'head_teacher' then
      raise exception 'The Nursery–Primary Headteacher must have the Head Teacher authorization role';
    end if;
  elsif p_appointment='overall_secondary_principal' then
    if target.role <> 'administrator'
       or lower(coalesce(target.position_title,'')) <> 'principal' then
      raise exception 'The Overall Secondary Principal must be one of the appointed section Principals';
    end if;
    if coalesce(p_assigned,false) and not exists(
      select 1 from public.schoolpro_section_leaders sl
      where sl.school_id=p_school and sl.member_id=p_member and sl.ended_at is null
        and sl.section in ('junior_secondary','senior_secondary')
    ) then
      raise exception 'Appoint this Principal to their normal JSS or SSS section before assigning overall secondary oversight';
    end if;
  else
    raise exception 'Choose a supported combined leadership appointment';
  end if;

  select * into existing
  from public.schoolpro_combined_leadership_appointments
  where school_id=p_school and appointment_key=p_appointment and ended_at is null
  for update;

  if coalesce(p_assigned,false) then
    if existing.id is not null and existing.member_id <> p_member then
      raise exception 'Another staff member already holds this overall leadership appointment';
    elsif existing.id is null then
      begin
        insert into public.schoolpro_combined_leadership_appointments(
          school_id,member_id,appointment_key,assigned_by,assigned_at,ended_at
        ) values(p_school,p_member,p_appointment,auth.uid(),now(),null);
      exception when unique_violation then
        raise exception 'Another staff member was appointed concurrently; refresh the staff list';
      end;
    else
      update public.schoolpro_combined_leadership_appointments
      set assigned_by=auth.uid(),assigned_at=now()
      where id=existing.id;
    end if;
  else
    update public.schoolpro_combined_leadership_appointments
    set ended_at=now()
    where school_id=p_school and member_id=p_member
      and appointment_key=p_appointment and ended_at is null;
  end if;

  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Combined school leadership appointment updated','member',p_member,
    jsonb_build_object('appointment',p_appointment,'assigned',coalesce(p_assigned,false)));
end
$$;
revoke all on function public.schoolpro_set_combined_leadership(uuid,uuid,text,boolean)
  from public,anon;
grant execute on function public.schoolpro_set_combined_leadership(uuid,uuid,text,boolean)
  to authenticated;

create or replace function private.schoolpro_member_leads_student_section(
  p_school uuid,p_student uuid,p_session text
) returns boolean
language sql stable security definer set search_path=''
as $$
  select auth.uid() is not null and private.is_active_account() and exists(
    select 1
    from public.schoolpro_members m
    join public.schoolpro_students st on st.school_id=p_school and st.id=p_student
    join public.schoolpro_classes c on c.school_id=p_school and c.id=coalesce((
      select eh.class_id from public.schoolpro_enrollment_history eh
      where eh.school_id=p_school and eh.student_id=p_student
        and eh.session=trim(coalesce(p_session,''))
      order by eh.created_at desc limit 1
    ),st.class_id) and c.archived_at is null
    where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
      and (
        exists(
          select 1 from public.schoolpro_section_leaders sl
          where sl.school_id=m.school_id and sl.member_id=m.id
            and sl.ended_at is null and sl.section=c.level
            and m.role <> 'teacher'
            and (
              (m.role='administrator' and lower(coalesce(m.position_title,''))='principal')
              or (not exists(
                select 1 from public.schoolpro_section_leaders psl
                join public.schoolpro_members pm on pm.id=psl.member_id and pm.school_id=psl.school_id
                where psl.school_id=p_school and psl.section=c.level and psl.ended_at is null
                  and pm.status='active' and pm.role='administrator'
                  and lower(coalesce(pm.position_title,''))='principal'
              )
              and not exists(
                select 1 from public.schoolpro_combined_leadership_appointments ca
                join public.schoolpro_members cm on cm.id=ca.member_id and cm.school_id=ca.school_id
                where ca.school_id=p_school and ca.ended_at is null
                  and ca.appointment_key='overall_secondary_principal'
                  and cm.status='active' and cm.role='administrator'
                  and lower(coalesce(cm.position_title,''))='principal'
              )
              )
            )
        )
        or exists(
          select 1 from public.schoolpro_combined_leadership_appointments ca
          where ca.school_id=p_school and ca.member_id=m.id and ca.ended_at is null
            and (
              (ca.appointment_key='nursery_primary_headteacher'
                and m.role='head_teacher' and c.level in ('nursery','primary'))
              or (ca.appointment_key='overall_secondary_principal'
                and m.role='administrator'
                and lower(coalesce(m.position_title,''))='principal'
                and c.level in ('junior_secondary','senior_secondary'))
            )
        )
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
    join public.schoolpro_classes c on c.school_id=p_school and c.id=p_class and c.archived_at is null
    where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
      and (
        exists(
          select 1 from public.schoolpro_section_leaders sl
          where sl.school_id=m.school_id and sl.member_id=m.id
            and sl.ended_at is null and sl.section=c.level and m.role <> 'teacher'
            and (
              (m.role='administrator' and lower(coalesce(m.position_title,''))='principal')
              or (not exists(
                select 1 from public.schoolpro_section_leaders psl
                join public.schoolpro_members pm on pm.id=psl.member_id and pm.school_id=psl.school_id
                where psl.school_id=p_school and psl.section=c.level and psl.ended_at is null
                  and pm.status='active' and pm.role='administrator'
                  and lower(coalesce(pm.position_title,''))='principal'
              )
              and not exists(
                select 1 from public.schoolpro_combined_leadership_appointments ca
                join public.schoolpro_members cm on cm.id=ca.member_id and cm.school_id=ca.school_id
                where ca.school_id=p_school and ca.ended_at is null
                  and ca.appointment_key='overall_secondary_principal'
                  and cm.status='active' and cm.role='administrator'
                  and lower(coalesce(cm.position_title,''))='principal'
              )
              )
            )
        )
        or exists(
          select 1 from public.schoolpro_combined_leadership_appointments ca
          where ca.school_id=p_school and ca.member_id=m.id and ca.ended_at is null
            and (
              (ca.appointment_key='nursery_primary_headteacher'
                and m.role='head_teacher' and c.level in ('nursery','primary'))
              or (ca.appointment_key='overall_secondary_principal'
                and m.role='administrator'
                and lower(coalesce(m.position_title,''))='principal'
                and c.level in ('junior_secondary','senior_secondary'))
            )
        )
      )
  )
$$;
revoke all on function private.schoolpro_member_leads_class(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_member_leads_class(uuid,uuid) to authenticated;

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
        where m.school_id=e.school_id and m.user_id=auth.uid() and m.status='active'
          and m.role in('teacher','class_teacher')
          and (
            exists(select 1 from public.schoolpro_classes c
              where c.school_id=e.school_id and c.id=e.class_id and c.form_teacher_id=m.id)
            or exists(select 1 from public.schoolpro_subject_assignments a
              where a.school_id=e.school_id and a.class_id=e.class_id
                and a.session=e.session and a.teacher_member_id=m.id and a.ended_at is null)
          ))
      or exists(select 1 from public.schoolpro_members m
        join public.schoolpro_section_leaders sl
          on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
        join public.schoolpro_classes c
          on c.school_id=e.school_id and c.id=e.class_id and c.level=sl.section
        where m.school_id=e.school_id and m.user_id=auth.uid() and m.status='active')
      or exists(select 1 from public.schoolpro_members m
        join public.schoolpro_combined_leadership_appointments ca
          on ca.school_id=m.school_id and ca.member_id=m.id and ca.ended_at is null
        join public.schoolpro_classes c
          on c.school_id=e.school_id and c.id=e.class_id
        where m.school_id=e.school_id and m.user_id=auth.uid() and m.status='active'
          and (
            (ca.appointment_key='nursery_primary_headteacher'
              and m.role='head_teacher' and c.level in ('nursery','primary'))
            or (ca.appointment_key='overall_secondary_principal'
              and m.role='administrator'
              and lower(coalesce(m.position_title,''))='principal'
              and c.level in ('junior_secondary','senior_secondary'))
          ))
    )
    and private.schoolpro_operationally_active(e.school_id)
)
select coalesce(jsonb_object_agg(key,true),'{}'::jsonb) from readable
$$;
revoke all on function private.schoolpro_enrollment_reader_keys() from public,anon;
grant execute on function private.schoolpro_enrollment_reader_keys() to authenticated;
alter policy "Authorized school enrollment history"
on public.schoolpro_enrollment_history
using ((select private.schoolpro_enrollment_reader_keys())
  ? (school_id::text||'|'||student_id::text||'|'||session));


-- Keep the underlying section Principal appointment intact while the combined
-- secondary appointment is active. The owner must first retire the combined
-- appointment before removing the member's final normal section appointment.
create or replace function private.schoolpro_set_section_leader(
  p_school uuid,p_member uuid,p_section text,p_assigned boolean
) returns void language plpgsql security definer set search_path=''
as $$
declare target public.schoolpro_members; v_section_count integer;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not (
       private.is_admin(array['super_admin']::public.user_role[])
       or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
       or private.schoolpro_member_has_responsibility(p_school,'school_admin')
     ) then
    raise exception 'Only authorized school administration can manage section appointments';
  end if;
  if p_section not in ('nursery','primary','junior_secondary','senior_secondary','other') then
    raise exception 'Choose a valid school section';
  end if;
  select * into target from public.schoolpro_members
   where id=p_member and school_id=p_school for update;
  if target.id is null or target.status<>'active' then
    raise exception 'Active school staff member not found';
  end if;
  if coalesce(p_assigned,false) and target.role = 'teacher' then
    raise exception 'Head Teacher appointment cannot be assigned to an ordinary Subject Teacher';
  end if;

  if not coalesce(p_assigned,false)
     and p_section in ('junior_secondary','senior_secondary')
     and exists(select 1 from public.schoolpro_combined_leadership_appointments ca
       where ca.school_id=p_school and ca.member_id=p_member
         and ca.appointment_key='overall_secondary_principal' and ca.ended_at is null) then
    select count(*) into v_section_count
    from public.schoolpro_section_leaders sl
    where sl.school_id=p_school and sl.member_id=p_member
      and sl.section in ('junior_secondary','senior_secondary') and sl.ended_at is null;
    if v_section_count <= 1 then
      raise exception 'Retire the Overall Secondary Principal appointment before removing this Principal’s final section appointment';
    end if;
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
revoke all on function private.schoolpro_set_section_leader(uuid,uuid,text,boolean)
  from public,anon,authenticated;
grant execute on function private.schoolpro_set_section_leader(uuid,uuid,text,boolean)
  to authenticated;

create or replace function private.schoolpro_end_invalid_combined_leadership()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  update public.schoolpro_combined_leadership_appointments ca
  set ended_at=now()
  where ca.school_id=new.school_id and ca.member_id=new.id and ca.ended_at is null
    and (
      new.status <> 'active'
      or (ca.appointment_key='nursery_primary_headteacher' and new.role <> 'head_teacher')
      or (ca.appointment_key='overall_secondary_principal'
        and (new.role <> 'administrator'
          or lower(coalesce(new.position_title,'')) <> 'principal'))
    );

  if found then
    insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
    values(new.school_id,coalesce(auth.uid(),new.user_id),'Combined leadership appointment ended after eligibility change',
      'member',new.id,jsonb_build_object('role',new.role,'position_title',new.position_title,'status',new.status));
  end if;
  return new;
end
$$;
revoke all on function private.schoolpro_end_invalid_combined_leadership() from public,anon,authenticated;
drop trigger if exists schoolpro_end_invalid_combined_leadership on public.schoolpro_members;
create trigger schoolpro_end_invalid_combined_leadership
after update of role,position_title,status on public.schoolpro_members
for each row execute function private.schoolpro_end_invalid_combined_leadership();
