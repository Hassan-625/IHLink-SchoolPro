-- Explicit combined leadership appointments for the two school groupings.
-- The underlying section rows remain the source of authorization; this RPC
-- creates/retires both rows atomically and records one auditable appointment event.

create or replace function private.schoolpro_set_combined_leadership(
  p_school uuid,
  p_member uuid,
  p_appointment text,
  p_assigned boolean
) returns void
language plpgsql
security definer
set search_path=''
as $$
declare
  target public.schoolpro_members;
  v_sections text[];
begin
  if auth.uid() is null
     or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not (
       private.is_admin(array['super_admin']::public.user_role[])
       or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
       or private.schoolpro_member_has_responsibility(p_school,'school_admin')
     ) then
    raise exception 'Only authorized school administration can manage combined leadership appointments';
  end if;

  select * into target
  from public.schoolpro_members
  where id=p_member and school_id=p_school and status='active'
  for update;

  if target.id is null then
    raise exception 'Choose an active staff member in this school';
  end if;

  case p_appointment
    when 'nursery_primary_headteacher' then
      if target.role <> 'head_teacher' then
        raise exception 'The Nursery and Primary Headteacher appointment requires the Head Teacher authorization role';
      end if;
      v_sections := array['nursery','primary'];
    when 'overall_secondary_principal' then
      if target.role <> 'administrator'
         or lower(coalesce(target.position_title,'')) <> 'principal' then
        raise exception 'The Overall Secondary Principal must be one of the appointed section Principals';
      end if;
      v_sections := array['junior_secondary','senior_secondary'];
    else
      raise exception 'Choose a supported combined leadership appointment';
  end case;

  if coalesce(p_assigned,false) then
    insert into public.schoolpro_section_leaders(
      school_id,member_id,section,assigned_by,assigned_at,ended_at
    )
    select p_school,p_member,section,auth.uid(),now(),null
    from unnest(v_sections) as section
    on conflict (school_id,member_id,section) do update
      set assigned_by=excluded.assigned_by,
          assigned_at=now(),
          ended_at=null;
  else
    update public.schoolpro_section_leaders
    set ended_at=now()
    where school_id=p_school
      and member_id=p_member
      and section=any(v_sections)
      and ended_at is null;
  end if;

  insert into public.schoolpro_audit_logs(
    school_id,actor_id,action,entity_type,entity_id,metadata
  )
  values(
    p_school,
    auth.uid(),
    'Combined school leadership appointment updated',
    'member',
    p_member,
    jsonb_build_object(
      'appointment',p_appointment,
      'sections',to_jsonb(v_sections),
      'assigned',coalesce(p_assigned,false)
    )
  );
end
$$;

revoke all on function private.schoolpro_set_combined_leadership(uuid,uuid,text,boolean)
  from public,anon,authenticated;
grant execute on function private.schoolpro_set_combined_leadership(uuid,uuid,text,boolean)
  to authenticated;

create or replace function public.schoolpro_set_combined_leadership(
  p_school uuid,
  p_member uuid,
  p_appointment text,
  p_assigned boolean
) returns void
language sql
security invoker
set search_path=''
as $$
  select private.schoolpro_set_combined_leadership(
    p_school,p_member,p_appointment,p_assigned
  )
$$;

revoke all on function public.schoolpro_set_combined_leadership(uuid,uuid,text,boolean)
  from public,anon;
grant execute on function public.schoolpro_set_combined_leadership(uuid,uuid,text,boolean)
  to authenticated;
