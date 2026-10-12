alter policy "family historical timetable read" on public.schoolpro_timetable_entries using (((auth.uid() is not null and coalesce(private.is_active_account(),false) and private.schoolpro_operationally_active(school_id)) AND (EXISTS ( SELECT 1
   FROM (schoolpro_students s
     LEFT JOIN schoolpro_enrollment_history e ON (((e.school_id = s.school_id) AND (e.student_id = s.id) AND (e.session = schoolpro_timetable_entries.session))))
  WHERE ((s.school_id = schoolpro_timetable_entries.school_id) AND (COALESCE(e.class_id, s.class_id) = schoolpro_timetable_entries.class_id) AND ((e.student_id IS NOT NULL) OR (NOT (EXISTS ( SELECT 1
           FROM schoolpro_enrollment_history h
          WHERE ((h.school_id = s.school_id) AND (h.student_id = s.id)))))) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM schoolpro_guardian_links g
          WHERE ((g.student_id = s.id) AND (g.school_id = s.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text))))))))));
alter policy "assignment targeted read" on public.schoolpro_assignments using (((auth.uid() is not null and coalesce(private.is_active_account(),false) and private.schoolpro_operationally_active(school_id)) AND (private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR (EXISTS ( SELECT 1
   FROM (schoolpro_subject_assignments a
     JOIN schoolpro_members m ON (((m.id = a.teacher_member_id) AND (m.school_id = a.school_id))))
  WHERE ((a.school_id = schoolpro_assignments.school_id) AND (a.class_id = schoolpro_assignments.class_id) AND (a.subject_id = schoolpro_assignments.subject_id) AND (a.session = schoolpro_assignments.session) AND (m.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM (schoolpro_classes c
     JOIN schoolpro_members m ON (((m.id = c.form_teacher_id) AND (m.school_id = c.school_id))))
  WHERE ((c.id = schoolpro_assignments.class_id) AND (c.school_id = schoolpro_assignments.school_id) AND (m.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM (schoolpro_students s
     LEFT JOIN schoolpro_enrollment_history e ON (((e.school_id = s.school_id) AND (e.student_id = s.id) AND (e.session = schoolpro_assignments.session))))
  WHERE ((s.school_id = schoolpro_assignments.school_id) AND (COALESCE(e.class_id, s.class_id) = schoolpro_assignments.class_id) AND ((e.student_id IS NOT NULL) OR (NOT (EXISTS ( SELECT 1
           FROM schoolpro_enrollment_history h
          WHERE ((h.school_id = s.school_id) AND (h.student_id = s.id)))))) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM schoolpro_guardian_links g
          WHERE ((g.student_id = s.id) AND (g.school_id = s.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))))))));