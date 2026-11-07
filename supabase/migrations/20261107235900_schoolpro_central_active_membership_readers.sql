-- Stage C0: central permission/cache readers and judge eligibility must
-- consistently honour active membership and active appointment state.
begin;

create or replace function public.schoolpro_user_permissions(p_school uuid)
returns text[]
language plpgsql security definer
set search_path = ''
as $function$
declare m public.schoolpro_members; base text[]; extra text[];
begin
  if auth.uid() is null then return array[]::text[]; end if;

  -- Keep platform-owner semantics, but never let a stale board appointment
  -- grant permissions to an inactive membership.
  if exists(
    select 1 from public.schoolpro_board_members b
    join public.schoolpro_members bm on bm.id=b.member_id and bm.school_id=b.school_id
    where b.school_id=p_school and bm.user_id=auth.uid()
      and bm.status='active' and b.ended_at is null and b.role='administrator'
  ) then
    return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];
  end if;

  select * into m from public.schoolpro_members
  where school_id=p_school and user_id=auth.uid() limit 1;

  if exists(select 1 from public.schoolpro_schools where id=p_school and owner_id=auth.uid())
    or private.is_admin(array['super_admin']::public.user_role[]) then
    return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];
  end if;

  if m.id is null or m.status<>'active' then return array[]::text[]; end if;
  if m.role='administrator' and m.position_title='Principal' then
    return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];
  end if;

  base:=case m.role
    when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications']
    when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications']
    when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications']
    when 'discipline_master' then array['dashboard','students','discipline','notifications']
    when 'game_master' then array['dashboard','students','games','notifications']
    when 'receptionist' then array['dashboard','admissions','parents','announcements','calendar','notifications']
    when 'administrator' then array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','notifications']
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

  select array_agg(permission) into extra
  from public.schoolpro_member_permissions
  where member_id=m.id and allowed=true;
  return (
    select array_agg(distinct x)
    from unnest(base||coalesce(extra,array[]::text[])) x
    where not exists(
      select 1 from public.schoolpro_member_permissions p
      where p.member_id=m.id and p.permission=x and p.allowed=false
    )
  );
end;
$function$;

create or replace function public.schoolpro_member_can_manage(p_school uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $function$
  select private.is_admin(array['super_admin']::public.user_role[])
    or exists(select 1 from public.schoolpro_schools s
      where s.id=p_school and s.owner_id=auth.uid())
    or private.has_school_access(
      p_school,array['proprietor','administrator','it_admin']::public.school_member_role[]
    );
$function$;

create or replace function private.schoolpro_cached_access_schools(
  p_permission text,p_scope text default 'module'
) returns uuid[]
language sql stable security definer
set search_path = ''
as $function$
select coalesce(array_agg(s.id),array[]::uuid[])
from public.schoolpro_schools s
where auth.uid() is not null and private.is_active_account()
  and (
    private.is_admin(array['super_admin']::public.user_role[])
    or s.owner_id=auth.uid()
    or exists(select 1 from public.schoolpro_members m
      where m.school_id=s.id and m.user_id=auth.uid() and m.status='active')
  )
  and case p_scope
    when 'lesson-leader' then private.schoolpro_module_allowed(s.id,p_permission)
      and private.schoolpro_lesson_leader(s.id)
    when 'result-leader' then private.schoolpro_operationally_active(s.id)
      and (
        private.is_admin(array['super_admin']::public.user_role[])
        or s.owner_id=auth.uid()
        or exists(select 1 from public.schoolpro_members m
          where m.school_id=s.id and m.user_id=auth.uid() and m.status='active'
            and m.role in ('proprietor','administrator','exam_officer','head_teacher','vice_principal'))
      )
    else private.schoolpro_module_allowed(s.id,p_permission)
  end
$function$;

create or replace function private.schoolpro_cached_staff_schools()
returns uuid[]
language sql stable security definer
set search_path = ''
as $function$
select coalesce(array_agg(sc.id),array[]::uuid[])
from public.schoolpro_schools sc
where private.is_active_account()
  and private.schoolpro_operationally_active(sc.id)
  and (
    private.is_admin(array['super_admin']::public.user_role[])
    or sc.owner_id=auth.uid()
    or exists(select 1 from public.schoolpro_members m
      where m.school_id=sc.id and m.user_id=auth.uid() and m.status='active'
        and m.role::text not in ('parent','student'))
  )
$function$;

create or replace function private.schoolpro_notify_discipline()
returns trigger
language plpgsql security definer
set search_path = ''
as $function$
begin
  insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href)
  select new.school_id,recipient,'Student concern reported',
    'A staff member reported a student concern. Review the report and decide the next action.',
    'discipline','/schoolpro/discipline'
  from (
    select owner_id recipient from public.schoolpro_schools where id=new.school_id
    union
    select user_id from public.schoolpro_members
    where school_id=new.school_id and status='active'
      and role::text in ('proprietor','administrator')
  ) r
  where recipient is not null;
  return new;
end;
$function$;

create or replace function private.schoolpro_validate_competition_tenant_links()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  if tg_table_name='schoolpro_competition_criteria' then
    if not exists(select 1 from public.schoolpro_competition_events e
      where e.id=new.event_id and e.school_id=new.school_id) then
      raise exception 'Competition event must belong to the same school';
    end if;
  elsif tg_table_name='schoolpro_competition_entries' then
    if not exists(select 1 from public.schoolpro_competition_events e
      where e.id=new.event_id and e.school_id=new.school_id) then
      raise exception 'Competition event must belong to the same school';
    end if;
    if new.house_id is not null and not exists(select 1 from public.schoolpro_houses h
      where h.id=new.house_id and h.school_id=new.school_id) then
      raise exception 'Entry house must belong to the same school';
    end if;
  elsif tg_table_name='schoolpro_competition_judges' then
    if not exists(select 1 from public.schoolpro_competition_events e
      where e.id=new.event_id and e.school_id=new.school_id)
      or not exists(select 1 from public.schoolpro_members m
        where m.id=new.member_id and m.school_id=new.school_id and m.status='active') then
      raise exception 'Judge and event must belong to the same school and judge membership must be active';
    end if;
  elsif tg_table_name='schoolpro_competition_scores' then
    if not exists(select 1 from public.schoolpro_competition_events e
      where e.id=new.event_id and e.school_id=new.school_id)
      or not exists(select 1 from public.schoolpro_competition_entries x
        where x.id=new.entry_id and x.event_id=new.event_id and x.school_id=new.school_id)
      or not exists(select 1 from public.schoolpro_competition_criteria c
        where c.id=new.criterion_id and c.event_id=new.event_id and c.school_id=new.school_id
          and new.points<=c.max_points)
      or not exists(select 1 from public.schoolpro_competition_judges j
        join public.schoolpro_members m on m.id=j.member_id and m.school_id=j.school_id
        where j.id=new.judge_assignment_id and j.event_id=new.event_id
          and j.school_id=new.school_id and j.ended_at is null and m.status='active') then
      raise exception 'Score must reference this event, its entry and rubric, and an active assigned judge; points cannot exceed criterion maximum';
    end if;
  elsif tg_table_name='schoolpro_house_point_ledger' then
    if not exists(select 1 from public.schoolpro_houses h
      where h.id=new.house_id and h.school_id=new.school_id) then
      raise exception 'Award house must belong to the same school';
    end if;
    if new.event_id is not null and not exists(select 1 from public.schoolpro_competition_events e
      where e.id=new.event_id and e.school_id=new.school_id) then
      raise exception 'Award event must belong to the same school';
    end if;
    if new.entry_id is not null and not exists(select 1 from public.schoolpro_competition_entries x
      where x.id=new.entry_id and x.school_id=new.school_id and x.event_id=new.event_id) then
      raise exception 'Award entry must belong to the same event and school';
    end if;
  end if;
  return new;
end;
$function$;

commit;
