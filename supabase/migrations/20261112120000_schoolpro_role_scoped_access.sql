-- Restore least-privilege module access for Board appointees.
-- A Board appointment is a designation, not an administrator role elevation.
begin;

-- Keep a member's actual school role unchanged when a Board appointment is made.
-- If the role is genuinely changed later, end the Board appointment while
-- preserving its history. During legacy-role restoration, preserve the row when
-- the new role matches the appointment's recorded previous_role.
create or replace function private.schoolpro_clear_changed_board_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.role is distinct from old.role then
    update public.schoolpro_board_members
       set ended_at = coalesce(ended_at, now()),
           ended_by = coalesce(ended_by, auth.uid()),
           end_reason = coalesce(end_reason, 'Membership role changed')
     where member_id = new.id
       and school_id = new.school_id
       and ended_at is null
       and previous_role is distinct from new.role;
  end if;
  return new;
end;
$function$;

revoke all on function private.schoolpro_clear_changed_board_role() from public, anon, authenticated;

-- Remove the administrator elevation applied by the legacy Board appointment
-- workflow. Keep appointments whose original role was already administrator.
update public.schoolpro_members m
   set role = b.previous_role
  from public.schoolpro_board_members b
 where b.member_id = m.id
   and b.school_id = m.school_id
   and b.ended_at is null
   and m.role = 'administrator'::public.school_member_role
   and b.previous_role <> 'administrator'::public.school_member_role;

-- Board appointment changes designation only. Module access continues to come
-- from the member's real school role and explicit per-module grants/denials.
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
    if p_title not in ('Proprietor','Director','School Owner','Co-owner')
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
      -- Legacy appointments elevated the membership role to administrator.
      -- Capture the recorded role before ending the appointment, then restore
      -- it so direct has_school_access() checks cannot retain that elevation.
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
        'Chairperson','Director','Co-owner','Board Secretary',
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

-- The central permission resolver no longer grants a Board-wide administrator
-- permission set. Owners/Proprietors and actual Administrators retain broad
-- school-wide access; every other role retains its own module set.
create or replace function public.schoolpro_user_permissions(p_school uuid)
returns text[]
language plpgsql
security definer
set search_path = ''
as $function$
declare
  m public.schoolpro_members;
  base text[];
  extra text[];
begin
  if auth.uid() is null then
    return array[]::text[];
  end if;

  select * into m
    from public.schoolpro_members
   where school_id = p_school
     and user_id = auth.uid()
   limit 1;

  if exists (
    select 1 from public.schoolpro_schools
    where id = p_school and owner_id = auth.uid()
  ) or private.is_admin(array['super_admin']::public.user_role[]) then
    return array[
      'dashboard','students','results','reports','finance','classes','subjects',
      'attendance','timetable','assignments','admissions','cbt','library','staff',
      'parents','transport','hostel','inventory','discipline','medical','documents',
      'announcements','operations','roles','branding','payroll','calendar',
      'lesson-notes','leave','promotions','games','notifications'
    ]::text[];
  end if;

  if m.id is null or m.status <> 'active' then
    return array[]::text[];
  end if;

  if m.role = 'proprietor' then
    return array[
      'dashboard','students','results','reports','finance','classes','subjects',
      'attendance','timetable','assignments','admissions','cbt','library','staff',
      'parents','transport','hostel','inventory','discipline','medical','documents',
      'announcements','operations','roles','branding','payroll','calendar',
      'lesson-notes','leave','promotions','games','notifications'
    ]::text[];
  end if;

  if m.role = 'administrator' and m.position_title = 'Principal' then
    return array[
      'dashboard','students','results','reports','finance','classes','subjects',
      'attendance','timetable','assignments','admissions','cbt','library','staff',
      'parents','transport','hostel','inventory','discipline','medical','documents',
      'announcements','operations','roles','branding','payroll','calendar',
      'lesson-notes','leave','promotions','games','notifications'
    ]::text[];
  end if;

  base := case m.role
    when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications']
    when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications']
    when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications']
    when 'discipline_master' then array['dashboard','students','discipline','notifications']
    when 'game_master' then array['dashboard','students','games','notifications']
    when 'receptionist' then array['dashboard','admissions','parents','announcements','calendar','notifications']
    when 'administrator' then array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','games','notifications']
    when 'bursar' then array['dashboard','finance','students','notifications']
    when 'accountant' then array['dashboard','finance','students','reports','notifications']
    when 'teacher' then array['reports','discipline','dashboard','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','cbt','notifications']
    when 'class_teacher' then array['reports','discipline','dashboard','students','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','notifications']
    when 'exam_officer' then array['dashboard','results','reports','cbt','students','classes','subjects','documents','notifications']
    when 'registrar' then array['dashboard','students','classes','parents','documents','notifications']
    when 'admissions_officer' then array['dashboard','admissions','students','documents','notifications']
    when 'librarian' then array['dashboard','library','students','notifications']
    when 'nurse' then array['dashboard','medical','students','notifications']
    when 'hostel_manager' then array['dashboard','hostel','students','notifications']
    when 'transport_manager' then array['dashboard','transport','students','notifications']
    when 'inventory_officer' then array['dashboard','inventory','notifications']
    when 'hr_officer' then array['dashboard','staff','leave','payroll','notifications']
    when 'it_admin' then array['dashboard','roles','branding','operations','notifications']
    else array['dashboard','notifications']
  end;

  select array_agg(permission)
    into extra
    from public.schoolpro_member_permissions
   where member_id = m.id
     and allowed = true;

  return (
    select array_agg(distinct x)
      from unnest(base || coalesce(extra, array[]::text[])) x
     where not exists (
       select 1
         from public.schoolpro_member_permissions p
        where p.member_id = m.id
          and p.permission = x
          and p.allowed = false
     )
  );
end;
$function$;

commit;
