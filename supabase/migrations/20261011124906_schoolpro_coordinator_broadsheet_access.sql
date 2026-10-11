CREATE OR REPLACE FUNCTION public.schoolpro_user_permissions(p_school uuid)
 RETURNS text[]
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare m public.schoolpro_members; base text[]; extra text[];begin if auth.uid() is null then return array[]::text[];end if; if exists(select 1 from public.schoolpro_board_members b join public.schoolpro_members bm on bm.id=b.member_id and bm.school_id=b.school_id where b.school_id=p_school and bm.user_id=auth.uid() and bm.role='administrator') then return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];end if;select * into m from public.schoolpro_members where school_id=p_school and user_id=auth.uid() limit 1;if exists(select 1 from public.schoolpro_schools where id=p_school and owner_id=auth.uid()) or private.is_admin(array['super_admin']::public.user_role[]) then return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];end if;if m.id is null then return array[]::text[];end if;base:=case m.role when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications'] when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications'] when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications'] when 'receptionist' then array['dashboard','admissions','parents','announcements','calendar','notifications'] when 'administrator' then array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','notifications'] when 'bursar' then array['dashboard','finance','students','notifications'] when 'accountant' then array['dashboard','finance','students','reports','notifications'] when 'teacher' then array['reports','discipline','dashboard','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','cbt','notifications'] when 'class_teacher' then array['reports','discipline','dashboard','students','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','notifications'] when 'exam_officer' then array['dashboard','results','reports','cbt','students','classes','subjects','documents','notifications'] when 'registrar' then array['dashboard','students','classes','parents','documents','notifications'] when 'admissions_officer' then array['dashboard','admissions','students','documents','notifications'] when 'librarian' then array['dashboard','library','students','notifications'] when 'nurse' then array['dashboard','medical','students','notifications'] when 'hostel_manager' then array['dashboard','hostel','students','notifications'] when 'transport_manager' then array['dashboard','transport','students','notifications'] when 'inventory_officer' then array['dashboard','inventory','notifications'] when 'hr_officer' then array['dashboard','staff','leave','payroll','notifications'] when 'it_admin' then array['dashboard','roles','branding','operations','notifications'] else array['dashboard','notifications'] end;select array_agg(permission) into extra from public.schoolpro_member_permissions where member_id=m.id and allowed=true;return (select array_agg(distinct x) from unnest(base||coalesce(extra,array[]::text[])) x where not exists(select 1 from public.schoolpro_member_permissions p where p.member_id=m.id and p.permission=x and p.allowed=false));end$function$;

CREATE OR REPLACE FUNCTION public.schoolpro_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS TABLE(student_id uuid, admission_number text, student_name text, total numeric, average numeric, subjects bigint, class_position bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not private.schoolpro_module_allowed(p_school,'reports') or not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied';end if;
 if not(
   public.schoolpro_member_can_manage(p_school)
   or private.is_admin(array['super_admin'::public.user_role])
   or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role in('exam_officer'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role))
   or exists(select 1 from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id where c.id=p_class and c.school_id=p_school and m.user_id=auth.uid() and m.role in('teacher','class_teacher'))
   or exists(
     select 1 from public.schoolpro_subject_assignments sa
     join public.schoolpro_members m on m.id=sa.teacher_member_id and m.school_id=sa.school_id
     where sa.school_id=p_school and sa.class_id=p_class and sa.session=trim(p_session)
       and m.user_id=auth.uid() and m.role in('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
   )
 ) then raise exception 'Not authorized for this class and session';end if;
 return query
 with x as(
  select s.id,s.admission_number,(s.first_name||' '||s.last_name)::text student_name,
   coalesce(sum(r.total_score),0)::numeric total,coalesce(avg(r.total_score),0)::numeric average,count(r.id)::bigint subjects
  from public.schoolpro_students s
  left join public.schoolpro_results r on r.student_id=s.id and r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published'::public.schoolpro_result_status
  where s.school_id=p_school and s.class_id=p_class and s.status='active'
  group by s.id,s.admission_number,s.first_name,s.last_name
 ),y as(select x.*,rank() over(order by x.total desc)::bigint pos from x)
 select y.id,y.admission_number,y.student_name,y.total,y.average,y.subjects,y.pos from y order by y.pos,y.student_name;
end $function$
;
