drop policy "Class coordinators read class results" on public.schoolpro_results;
drop policy "Guardians read published linked results" on public.schoolpro_results;
drop policy "Leadership read school results" on public.schoolpro_results;
drop policy "Super admin read schoolpro results" on public.schoolpro_results;
drop policy "Teachers read assigned results" on public.schoolpro_results;
drop policy "students view own published results" on public.schoolpro_results;
create policy "Result reader access" on public.schoolpro_results for select to authenticated using(case when school_id=any((select private.schoolpro_cached_access_schools('results','result-leader'))::uuid[]) then true else (((EXISTS ( SELECT 1
   FROM ((schoolpro_students s
     JOIN schoolpro_classes c ON (((c.id = s.class_id) AND (c.school_id = s.school_id))))
     JOIN schoolpro_members m ON (((m.id = c.form_teacher_id) AND (m.school_id = c.school_id))))
  WHERE ((s.id = schoolpro_results.student_id) AND (s.school_id = schoolpro_results.school_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['teacher'::school_member_role, 'class_teacher'::school_member_role])))))) OR (((status = 'published'::schoolpro_result_status) AND locked AND (EXISTS ( SELECT 1
   FROM schoolpro_guardian_links g
  WHERE ((g.student_id = schoolpro_results.student_id) AND (g.school_id = schoolpro_results.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))) OR ((private.is_admin(ARRAY['super_admin'::user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]))) OR (private.is_admin(ARRAY['super_admin'::user_role])) OR ((EXISTS ( SELECT 1
   FROM ((schoolpro_students st
     JOIN schoolpro_subject_assignments sa ON (((sa.school_id = schoolpro_results.school_id) AND (sa.class_id = st.class_id) AND (sa.subject_id = schoolpro_results.subject_id) AND (sa.session = schoolpro_results.session))))
     JOIN schoolpro_members m ON (((m.id = sa.teacher_member_id) AND (m.school_id = schoolpro_results.school_id))))
  WHERE ((st.id = schoolpro_results.student_id) AND (st.school_id = schoolpro_results.school_id) AND (st.status = 'active'::text) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND (m.role = ANY (ARRAY['teacher'::school_member_role, 'class_teacher'::school_member_role])))))) OR (((status = 'published'::schoolpro_result_status) AND locked AND (EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_results.student_id) AND (s.user_id = auth.uid()))))))) end);
