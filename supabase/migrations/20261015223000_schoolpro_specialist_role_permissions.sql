-- Extend the permission resolver with explicit least-privilege defaults for
-- the two specialist roles. Compare the enum through text so this migration
-- can be applied after the enum-add migration has committed.
create or replace function public.schoolpro_user_permissions(p_school uuid)
returns text[]
language plpgsql
security definer
set search_path to ''
as $function$
declare
  m public.schoolpro_members;
  base text[];
  extra text[];
begin
  if auth.uid() is null then
    return array[]::text[];
  end if;

  if exists (
    select 1 from public.schoolpro_board_members b
    join public.schoolpro_members bm on bm.id = b.member_id and bm.school_id = b.school_id
    where b.school_id = p_school and bm.user_id = auth.uid() and bm.role = 'administrator'
  ) then
    return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];
  end if;

  select * into m
  from public.schoolpro_members
  where school_id = p_school and user_id = auth.uid()
  limit 1;

  if m.role = 'administrator' and m.position_title = 'Principal' then
    return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];
  end if;

  if exists(select 1 from public.schoolpro_schools where id = p_school and owner_id = auth.uid())
     or private.is_admin(array['super_admin']::public.user_role[]) then
    return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];
  end if;

  if m.id is null then
    return array[]::text[];
  end if;

  base := case m.role::text
    when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications']
    when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications']
    when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications']
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
    when 'discipline_master' then array['dashboard','discipline','notifications']
    when 'game_master' then array['dashboard','calendar','notifications']
    else array['dashboard','notifications']
  end;

  select array_agg(permission) into extra
  from public.schoolpro_member_permissions
  where member_id = m.id and allowed = true;

  return (
    select array_agg(distinct x)
    from unnest(base || coalesce(extra, array[]::text[])) x
    where not exists (
      select 1 from public.schoolpro_member_permissions p
      where p.member_id = m.id and p.permission = x and p.allowed = false
    )
  );
end;
$function$;


-- Discipline Masters may review and manage discipline records, but this does
-- not grant access to results, finance, or other school modules.
drop policy if exists "discipline authorized access" on public.schoolpro_discipline_records;
create policy "discipline authorized access"
on public.schoolpro_discipline_records
for all
to authenticated
using (
  private.schoolpro_module_allowed(school_id, 'discipline'::text)
  and private.has_school_access(
    school_id,
    array[
      'proprietor'::public.school_member_role,
      'administrator'::public.school_member_role,
      'vice_principal'::public.school_member_role,
      'head_teacher'::public.school_member_role,
      'counsellor'::public.school_member_role,
      'discipline_master'::public.school_member_role
    ]
  )
)
with check (
  private.schoolpro_module_allowed(school_id, 'discipline'::text)
  and private.has_school_access(
    school_id,
    array[
      'proprietor'::public.school_member_role,
      'administrator'::public.school_member_role,
      'vice_principal'::public.school_member_role,
      'head_teacher'::public.school_member_role,
      'counsellor'::public.school_member_role,
      'discipline_master'::public.school_member_role
    ]
  )
);
