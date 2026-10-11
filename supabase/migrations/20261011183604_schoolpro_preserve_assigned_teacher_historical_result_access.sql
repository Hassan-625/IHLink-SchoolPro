CREATE OR REPLACE FUNCTION private.schoolpro_can_read_student(p_student uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select auth.uid() is not null and private.is_active_account() and exists(
 select 1 from public.schoolpro_students s where s.id=p_student and private.schoolpro_operationally_active(s.school_id) and (
 private.is_admin(array['super_admin'::public.user_role]) or s.user_id=auth.uid()
 or exists(select 1 from public.schoolpro_guardian_links g where g.school_id=s.school_id and g.student_id=s.id and g.guardian_user_id=auth.uid() and g.status='active')
 or exists(select 1 from public.schoolpro_schools sc where sc.id=s.school_id and sc.owner_id=auth.uid())
 or exists(select 1 from public.schoolpro_members m where m.school_id=s.school_id and m.user_id=auth.uid() and (
 m.role::text not in('teacher','class_teacher','parent','student')
 or (m.role in('teacher','class_teacher') and (exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=s.school_id and a.class_id=s.class_id and a.teacher_member_id=m.id) or exists(select 1 from public.schoolpro_classes c where c.id=s.class_id and c.form_teacher_id=m.id) or exists(select 1 from public.schoolpro_enrollment_history e join public.schoolpro_subject_assignments a on a.school_id=e.school_id and a.class_id=e.class_id and a.session=e.session where e.school_id=s.school_id and e.student_id=s.id and a.teacher_member_id=m.id) or exists(select 1 from public.schoolpro_enrollment_history e join public.schoolpro_classes c on c.id=e.class_id and c.school_id=e.school_id where e.school_id=s.school_id and e.student_id=s.id and c.form_teacher_id=m.id)))
 ))));
$function$;
CREATE OR REPLACE FUNCTION private.schoolpro_result_reader_matches(p_school uuid, p_student uuid, p_subject uuid, p_session text, p_status schoolpro_result_status, p_locked boolean)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$select ((EXISTS ( SELECT 1
   FROM (((public.schoolpro_students s
 LEFT JOIN public.schoolpro_enrollment_history e ON (e.student_id=s.id AND e.school_id=s.school_id AND e.session=schoolpro_results.session))
     JOIN public.schoolpro_classes c ON (((c.id = coalesce(e.class_id,s.class_id)) AND (c.school_id = s.school_id))))
     JOIN public.schoolpro_members m ON (((m.id = c.form_teacher_id) AND (m.school_id = c.school_id))))
  WHERE ((s.id = schoolpro_results.student_id) AND (s.school_id = schoolpro_results.school_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['teacher'::public.school_member_role, 'class_teacher'::public.school_member_role])))))) OR (((status = 'published'::public.schoolpro_result_status) AND locked AND (EXISTS ( SELECT 1
   FROM public.schoolpro_guardian_links g
  WHERE ((g.student_id = schoolpro_results.student_id) AND (g.school_id = schoolpro_results.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))) OR ((private.is_admin(ARRAY['super_admin'::public.user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::public.school_member_role, 'administrator'::public.school_member_role, 'exam_officer'::public.school_member_role, 'head_teacher'::public.school_member_role, 'vice_principal'::public.school_member_role]))) OR (private.is_admin(ARRAY['super_admin'::public.user_role])) OR ((EXISTS ( SELECT 1
   FROM (((public.schoolpro_students st
 LEFT JOIN public.schoolpro_enrollment_history e ON (e.student_id=st.id AND e.school_id=st.school_id AND e.session=schoolpro_results.session))
     JOIN public.schoolpro_subject_assignments sa ON (((sa.school_id = schoolpro_results.school_id) AND (sa.class_id = coalesce(e.class_id,st.class_id)) AND (sa.subject_id = schoolpro_results.subject_id) AND (sa.session = schoolpro_results.session))))
     JOIN public.schoolpro_members m ON (((m.id = sa.teacher_member_id) AND (m.school_id = schoolpro_results.school_id))))
  WHERE ((st.id = schoolpro_results.student_id) AND (st.school_id = schoolpro_results.school_id) AND (st.status in ('active'::text,'graduated'::text)) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND (m.role = ANY (ARRAY['teacher'::public.school_member_role, 'class_teacher'::public.school_member_role])))))) OR (((status = 'published'::public.schoolpro_result_status) AND locked AND (EXISTS ( SELECT 1
   FROM public.schoolpro_students s
  WHERE ((s.id = schoolpro_results.student_id) AND (s.user_id = auth.uid())))))) from (select p_school school_id,p_student student_id,p_subject subject_id,p_session session,p_status status,p_locked locked) schoolpro_results $function$
;
