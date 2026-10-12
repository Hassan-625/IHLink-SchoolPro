alter policy schoolpro_module_permission on public.schoolpro_timetable_entries using (private.schoolpro_module_allowed(school_id,'timetable') or (((auth.uid() IS NOT NULL) AND COALESCE(private.is_active_account(), false) AND private.schoolpro_operationally_active(school_id) AND (EXISTS ( SELECT 1
   FROM (schoolpro_students s
     LEFT JOIN schoolpro_enrollment_history e ON (((e.school_id = s.school_id) AND (e.student_id = s.id) AND (e.session = schoolpro_timetable_entries.session))))
  WHERE ((s.school_id = schoolpro_timetable_entries.school_id) AND (COALESCE(e.class_id, s.class_id) = schoolpro_timetable_entries.class_id) AND ((e.student_id IS NOT NULL) OR (NOT (EXISTS ( SELECT 1
           FROM schoolpro_enrollment_history h
          WHERE ((h.school_id = s.school_id) AND (h.student_id = s.id)))))) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM schoolpro_guardian_links g
          WHERE ((g.student_id = s.id) AND (g.school_id = s.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text))))))))))) with check (private.schoolpro_module_allowed(school_id,'timetable'));