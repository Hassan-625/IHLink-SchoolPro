-- Permit an explicit "Owner" governance designation for Board appointees.
-- This is title metadata only: it does not change schoolpro_schools.owner_id,
-- membership role, module permissions, or ownership-transfer controls.
begin;

create or replace function private.schoolpro_set_board_role(
  p_school uuid, p_member uuid, p_title text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  m public.schoolpro_members;
  old_role public.school_member_role;
begin
  if auth.uid() is null
     or not private.is_active_account()
     or not private.schoolpro_operationally_active(p_school)
     or not (
       private.is_admin(array['super_admin']::public.user_role[])
       or exists (
         select 1 from public.schoolpro_schools s
         where s.id = p_school and s.owner_id = auth.uid()
       )
     ) then
    raise exception 'Only the school owner can appoint school leadership';
  end if;

  if p_member is null then
    if p_title not in ('Proprietor','Director','School Owner','Owner','Co-owner')
       or p_title is null then
      raise exception 'Choose an owner title';
    end if;

    insert into public.schoolpro_leadership_settings(school_id, owner_title)
    values (p_school, p_title)
    on conflict (school_id) do update
      set owner_title = excluded.owner_title;
  else
    select * into m
      from public.schoolpro_members
     where id = p_member
       and school_id = p_school
       and status = 'active'
     for update;

    if m.id is null
       or m.role = 'proprietor'
       or exists (
         select 1 from public.schoolpro_schools s
         where s.id = p_school and s.owner_id = m.user_id
       ) then
      raise exception 'Choose active staff in this school';
    end if;

    if p_title is null then
      select previous_role
        into old_role
        from public.schoolpro_board_members
       where member_id = m.id
         and school_id = p_school
         and ended_at is null
       for update;

      update public.schoolpro_board_members
         set ended_at = now(),
             ended_by = auth.uid(),
             end_reason = 'Appointment withdrawn'
       where member_id = m.id
         and school_id = p_school
         and ended_at is null;

      if old_role is not null
         and old_role <> 'administrator'::public.school_member_role
         and m.role = 'administrator'::public.school_member_role then
        update public.schoolpro_members
           set role = old_role
         where id = m.id
           and school_id = p_school;
      end if;
    else
      if p_title not in (
        'Chairperson','Owner','Director','Co-owner','Board Secretary',
        'Board Member','Executive Director','Deputy Director'
      ) then
        raise exception 'Choose a valid Board designation';
      end if;

      insert into public.schoolpro_board_members(
        member_id, school_id, title, previous_role, appointed_by
      )
      values (m.id, p_school, p_title, m.role, auth.uid())
      on conflict (member_id) do update
        set title = excluded.title,
            appointed_by = excluded.appointed_by,
            previous_role = excluded.previous_role,
            appointed_at = now(),
            ended_at = null,
            ended_by = null,
            end_reason = null;
    end if;
  end if;

  insert into public.schoolpro_audit_logs(
    school_id, actor_id, action, entity_type, entity_id, metadata
  )
  values (
    p_school, auth.uid(), 'Leadership appointment updated', 'member',
    coalesce(p_member, p_school),
    jsonb_build_object('title', p_title)
  );
end;
$function$;

revoke all on function private.schoolpro_set_board_role(uuid, uuid, text) from public, anon;
grant execute on function private.schoolpro_set_board_role(uuid, uuid, text) to authenticated;

commit;
