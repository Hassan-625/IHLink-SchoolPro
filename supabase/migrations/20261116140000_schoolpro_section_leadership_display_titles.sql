-- Store the explicit, human-selected display title for each normal section-head appointment.
-- Titles are metadata only; authorization continues to use member roles and appointments.
alter table public.schoolpro_section_leaders
  add column if not exists display_title text
  check (display_title is null or display_title in ('Headmaster','Headmistress'));

create or replace function public.schoolpro_set_section_leader_title(
  p_school uuid,p_member uuid,p_section text,p_display_title text
) returns void
language plpgsql security definer set search_path=''
as $$
declare
  v_assignment public.schoolpro_section_leaders;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not (
       private.is_admin(array['super_admin']::public.user_role[])
       or private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
       or private.schoolpro_member_has_responsibility(p_school,'school_admin')
     ) then
    raise exception 'Only authorized school administration can set a section leadership title';
  end if;
  if p_section not in ('nursery','primary','junior_secondary','senior_secondary','other')
     or coalesce(p_display_title,'') not in ('Headmaster','Headmistress') then
    raise exception 'Choose a valid section and Headmaster or Headmistress title';
  end if;
  select * into v_assignment
  from public.schoolpro_section_leaders
  where school_id=p_school and member_id=p_member
    and section=p_section and ended_at is null
  for update;
  if v_assignment.id is null then
    raise exception 'Assign this staff member to the section before setting the display title';
  end if;
  update public.schoolpro_section_leaders
  set display_title=p_display_title
  where id=v_assignment.id;
  insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Section leadership display title updated','member',p_member,
    jsonb_build_object('section',p_section,'display_title',p_display_title));
end
$$;
revoke all on function public.schoolpro_set_section_leader_title(uuid,uuid,text,text)
  from public,anon;
grant execute on function public.schoolpro_set_section_leader_title(uuid,uuid,text,text)
  to authenticated;
