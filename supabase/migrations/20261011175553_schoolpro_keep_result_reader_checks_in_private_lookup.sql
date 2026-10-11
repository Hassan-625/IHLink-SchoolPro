create or replace function private.schoolpro_result_reader_matches(p_row public.schoolpro_results) returns boolean language sql stable security definer set search_path='' as $$ select ((EXISTS ( SELECT 1
   FROM ((public.schoolpro_students s
     JOIN public.schoolpro_classes c ON (((c.id = s.class_id) AND (c.school_id = s.school_id))))
     JOIN public.schoolpro_members m ON (((m.id = c.form_teacher_id) AND (m.school_id = c.school_id))))
  WHERE ((s.id = schoolpro_results.student_id) AND (s.school_id = schoolpro_results.school_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['teacher'::public.school_member_role, 'class_teacher'::public.school_member_role])))))) OR (((status = 'published'::public.schoolpro_result_status) AND locked AND (EXISTS ( SELECT 1
   FROM public.schoolpro_guardian_links g
  WHERE ((g.student_id = schoolpro_results.student_id) AND (g.school_id = schoolpro_results.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))) OR ((private.is_admin(ARRAY['super_admin'::public.user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::public.school_member_role, 'administrator'::public.school_member_role, 'exam_officer'::public.school_member_role, 'head_teacher'::public.school_member_role, 'vice_principal'::public.school_member_role]))) OR (private.is_admin(ARRAY['super_admin'::public.user_role])) OR ((EXISTS ( SELECT 1
   FROM ((public.schoolpro_students st
     JOIN public.schoolpro_subject_assignments sa ON (((sa.school_id = schoolpro_results.school_id) AND (sa.class_id = st.class_id) AND (sa.subject_id = schoolpro_results.subject_id) AND (sa.session = schoolpro_results.session))))
     JOIN public.schoolpro_members m ON (((m.id = sa.teacher_member_id) AND (m.school_id = schoolpro_results.school_id))))
  WHERE ((st.id = schoolpro_results.student_id) AND (st.school_id = schoolpro_results.school_id) AND (st.status = 'active'::text) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND (m.role = ANY (ARRAY['teacher'::public.school_member_role, 'class_teacher'::public.school_member_role])))))) OR (((status = 'published'::public.schoolpro_result_status) AND locked AND (EXISTS ( SELECT 1
   FROM public.schoolpro_students s
  WHERE ((s.id = schoolpro_results.student_id) AND (s.user_id = auth.uid())))))) from (select (p_row).*) schoolpro_results $$;
revoke all on function private.schoolpro_result_reader_matches(public.schoolpro_results) from public,anon;
grant execute on function private.schoolpro_result_reader_matches(public.schoolpro_results) to authenticated,service_role;
alter policy "Result reader access" on public.schoolpro_results using(case when school_id=any((select private.schoolpro_cached_access_schools('results','result-leader'))::uuid[]) then true else private.schoolpro_result_reader_matches(schoolpro_results) end);
