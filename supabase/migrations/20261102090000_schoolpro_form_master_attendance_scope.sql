-- Form Masters are the default classroom attendance operators.
-- Subject teachers retain assessment, assignment and CBT workflows but do not
-- receive attendance write access unless they are explicitly assigned as a class Form Master.

create or replace function public.schoolpro_user_permissions(p_school uuid)
returns text[] language plpgsql security definer set search_path to '' as $function$
declare m public.schoolpro_members; base text[]; extra text[];
begin
 if auth.uid() is null then return array[]::text[]; end if;
 if exists(select 1 from public.schoolpro_board_members b join public.schoolpro_members bm on bm.id=b.member_id and bm.school_id=b.school_id where b.school_id=p_school and bm.user_id=auth.uid() and bm.role='administrator') then
  return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];
 end if;
 select * into m from public.schoolpro_members where school_id=p_school and user_id=auth.uid() limit 1;
 if exists(select 1 from public.schoolpro_schools where id=p_school and owner_id=auth.uid()) or private.is_admin(array['super_admin']::public.user_role[]) then
  return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];
 end if;
 if m.id is null then return array[]::text[]; end if;
 base:=case m.role
  when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications']
  when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications']
  when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications']
  when 'receptionist' then array['dashboard','admissions','parents','announcements','calendar','notifications']
  when 'administrator' then array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','notifications']
  when 'bursar' then array['dashboard','finance','students','notifications']
  when 'accountant' then array['dashboard','finance','students','reports','notifications']
  when 'teacher' then array['discipline','dashboard','results','assignments','subjects','timetable','lesson-notes','announcements','cbt','notifications']
  when 'class_teacher' then array['discipline','dashboard','students','results','assignments','subjects','timetable','lesson-notes','announcements','notifications']
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
  else array['dashboard','notifications'] end;
 select array_agg(permission) into extra from public.schoolpro_member_permissions where member_id=m.id and allowed=true;
 if exists(select 1 from public.schoolpro_classes c where c.school_id=p_school and c.form_teacher_id=m.id) then
  extra:=coalesce(extra,array[]::text[])||array['attendance']::text[];
 end if;
 return (select array_agg(distinct x) from unnest(base||coalesce(extra,array[]::text[])) x where not exists(select 1 from public.schoolpro_member_permissions p where p.member_id=m.id and p.permission=x and p.allowed=false));
end $function$;

-- Replace the old school-wide teacher write policies with class-scoped Form Master access.
drop policy if exists "School educators insert attendance" on public.schoolpro_attendance;
drop policy if exists "School educators update attendance" on public.schoolpro_attendance;
create policy "School educators insert attendance" on public.schoolpro_attendance
for insert to authenticated with check (
 marked_by=(select auth.uid()) and (
  private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])
  or exists(select 1 from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
   where c.id=schoolpro_attendance.class_id and c.school_id=schoolpro_attendance.school_id and m.user_id=(select auth.uid()) and m.role::text in('teacher','class_teacher')
   and not exists(select 1 from public.schoolpro_member_permissions p where p.member_id=m.id and p.permission='attendance' and p.allowed=false))
 )
);
create policy "School educators update attendance" on public.schoolpro_attendance
for update to authenticated using (
 private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])
 or exists(select 1 from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
  where c.id=schoolpro_attendance.class_id and c.school_id=schoolpro_attendance.school_id and m.user_id=(select auth.uid()) and m.role::text in('teacher','class_teacher')
   and not exists(select 1 from public.schoolpro_member_permissions p where p.member_id=m.id and p.permission='attendance' and p.allowed=false))
) with check (
 marked_by=(select auth.uid()) and (
  private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])
  or exists(select 1 from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
   where c.id=schoolpro_attendance.class_id and c.school_id=schoolpro_attendance.school_id and m.user_id=(select auth.uid()) and m.role::text in('teacher','class_teacher')
   and not exists(select 1 from public.schoolpro_member_permissions p where p.member_id=m.id and p.permission='attendance' and p.allowed=false))
 )
);
