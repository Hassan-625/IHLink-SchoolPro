# SchoolPro boundary catalog snapshot — policies, FKs, grants, cron and extensions

**Captured:** 2026-10-17, read-only from Supabase project `lnqsroyiybutkfngbyge`, PostgreSQL 17.6. **This is evidence for review, not a target DDL script. Do not execute it on Aiven.** Data and secrets are not included.

## Summary
- RLS policy rows on `public.schoolpro_*`: 293
- Foreign keys involving a `schoolpro_*` table: 274
- Table privilege grants on `public.schoolpro_*`: 2816
- Matching cron jobs (SchoolPro, shared email and DataSub/BillStack): 7
- Installed extensions: 7

## RLS policies — complete live expressions (293)

### `public.schoolpro_academic_documents` — `academic_documents_staff`
- Command: `ALL`; roles: `authenticated`
- USING: `(schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_academic_documents.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['registrar'::text, 'exam_officer'::text, 'head_teacher'::text, 'administrator'::text, 'proprietor'::text]))))))`
- WITH CHECK: `(schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_academic_documents.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['registrar'::text, 'exam_officer'::text, 'head_teacher'::text, 'administrator'::text, 'proprietor'::text]))))))`

### `public.schoolpro_academic_documents` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'documents'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'documents'::text)`

### `public.schoolpro_admission_acceptances` — `acceptances staff read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM (schoolpro_admissions a
     JOIN schoolpro_members m ON ((m.school_id = a.school_id)))
  WHERE ((a.id = schoolpro_admission_acceptances.application_id) AND (m.user_id = auth.uid()))))`
- WITH CHECK: `—`

### `public.schoolpro_admission_documents` — `admission docs staff`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_admissions a
  WHERE ((a.id = schoolpro_admission_documents.application_id) AND private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role]))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_admissions a
  WHERE ((a.id = schoolpro_admission_documents.application_id) AND private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role]))))`

### `public.schoolpro_admission_events` — `admission events staff`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_admissions a
  WHERE ((a.id = schoolpro_admission_events.application_id) AND private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role]))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_admissions a
  WHERE ((a.id = schoolpro_admission_events.application_id) AND private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role]))))`

### `public.schoolpro_admission_offers` — `admission offers staff`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_admissions a
  WHERE ((a.id = schoolpro_admission_offers.application_id) AND private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role]))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_admissions a
  WHERE ((a.id = schoolpro_admission_offers.application_id) AND private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role]))))`

### `public.schoolpro_admissions` — `admissions authorized read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'admissions'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]))`
- WITH CHECK: `—`

### `public.schoolpro_admissions` — `admissions staff manage admissions`
- Command: `ALL`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role])`

### `public.schoolpro_announcements` — `manager announcements`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_announcements.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND ((m.role)::text = ANY (ARRAY['owner'::text, 'proprietor'::text, 'admin'::text, 'school_admin'::text])))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_announcements.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND ((m.role)::text = ANY (ARRAY['owner'::text, 'proprietor'::text, 'admin'::text, 'school_admin'::text])))))`

### `public.schoolpro_announcements` — `member read announcements`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_announcements.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: `—`

### `public.schoolpro_announcements` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'announcements'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'announcements'::text)`

### `public.schoolpro_assessment_schemes` — `Active school staff read assessment catalogue`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM (schoolpro_members m
     JOIN profiles p ON ((p.id = m.user_id)))
  WHERE ((m.school_id = schoolpro_assessment_schemes.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND (p.status = 'active'::account_status) AND ((m.role)::text = ANY (ARRAY['exam_officer'::text, 'head_teacher'::text, 'vice_principal'::text, 'class_teacher'::text, 'registrar'::text, 'it_admin'::text])))))`
- WITH CHECK: `—`

### `public.schoolpro_assessment_schemes` — `Guardians read linked assessment schemes`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_guardian_links gl
  WHERE ((gl.school_id = schoolpro_assessment_schemes.school_id) AND (gl.guardian_user_id = ( SELECT auth.uid() AS uid)) AND (gl.status = 'active'::text))))`
- WITH CHECK: `—`

### `public.schoolpro_assessment_schemes` — `School leaders delete assessment schemes`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_assessment_schemes` — `School leaders insert assessment schemes`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_assessment_schemes` — `School leaders update assessment schemes`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_assessment_schemes` — `School users read assessment schemes`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_assessment_schemes` — `Super admin full access schoolpro_assessment_schemes`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_assignment_submissions` — `assignment submission authorized read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_assignments a
  WHERE ((a.id = schoolpro_assignment_submissions.assignment_id) AND private.schoolpro_module_allowed(a.school_id, 'assignments'::text) AND (private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR ((a.created_by = auth.uid()) AND private.has_school_access(a.school_id, ARRAY['teacher'::school_member_role, 'class_teacher'::school_member_role]))))))`
- WITH CHECK: `—`

### `public.schoolpro_assignment_submissions` — `assignment submission student read own`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_assignment_submissions.student_id) AND (s.user_id = auth.uid()))))`
- WITH CHECK: `—`

### `public.schoolpro_assignments` — `assignment authorized manage`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'assignments'::text) AND (private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR ((created_by = auth.uid()) AND private.has_school_access(school_id, ARRAY['teacher'::school_member_role, 'class_teacher'::school_member_role]))))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'assignments'::text) AND (private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR ((created_by = auth.uid()) AND private.has_school_access(school_id, ARRAY['teacher'::school_member_role, 'class_teacher'::school_member_role]))))`

### `public.schoolpro_assignments` — `assignment targeted read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_family_class_read(school_id, class_id, session) OR (private.schoolpro_module_allowed(school_id, 'assignments'::text) AND (private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR (EXISTS ( SELECT 1
   FROM (schoolpro_subject_assignments a
     JOIN schoolpro_members m ON (((m.id = a.teacher_member_id) AND (m.school_id = a.school_id))))
  WHERE ((a.school_id = schoolpro_assignments.school_id) AND (a.class_id = schoolpro_assignments.class_id) AND (a.subject_id = schoolpro_assignments.subject_id) AND (a.session = schoolpro_assignments.session) AND (m.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM (schoolpro_classes c
     JOIN schoolpro_members m ON (((m.id = c.form_teacher_id) AND (m.school_id = c.school_id))))
  WHERE ((c.id = schoolpro_assignments.class_id) AND (c.school_id = schoolpro_assignments.school_id) AND (m.user_id = auth.uid())))))))`
- WITH CHECK: `—`

### `public.schoolpro_attendance` — `Guardians read linked attendance`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_guardian_links gl
  WHERE ((gl.student_id = schoolpro_attendance.student_id) AND (gl.guardian_user_id = ( SELECT auth.uid() AS uid)) AND (gl.status = 'active'::text))))`
- WITH CHECK: `—`

### `public.schoolpro_attendance` — `School educators insert attendance`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'teacher'::school_member_role]) AND (marked_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_attendance` — `School educators update attendance`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'teacher'::school_member_role])`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'teacher'::school_member_role]) AND (marked_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_attendance` — `School leaders delete attendance`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_attendance` — `School users read attendance`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_attendance` — `Scoped attendance records`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_can_read_student(student_id)`
- WITH CHECK: `(private.schoolpro_can_read_student(student_id) AND (EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_attendance.student_id) AND (s.school_id = schoolpro_attendance.school_id) AND ((EXISTS ( SELECT 1
           FROM schoolpro_enrollment_history h
          WHERE ((h.school_id = s.school_id) AND (h.student_id = s.id) AND (h.session = schoolpro_attendance.session) AND (h.class_id = schoolpro_attendance.class_id)))) OR ((NOT (EXISTS ( SELECT 1
           FROM schoolpro_enrollment_history h
          WHERE (h.student_id = s.id)))) AND (s.class_id = schoolpro_attendance.class_id)))))))`

### `public.schoolpro_attendance` — `Super admin full access schoolpro_attendance`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_attendance` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'attendance'::text) OR ((auth.uid() IS NOT NULL) AND COALESCE(private.is_active_account(), false) AND private.schoolpro_operationally_active(school_id) AND (EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_attendance.student_id) AND (s.school_id = schoolpro_attendance.school_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM schoolpro_guardian_links g
          WHERE ((g.student_id = s.id) AND (g.school_id = s.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text))))))))))`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'attendance'::text)`

### `public.schoolpro_attendance` — `students view own attendance`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_attendance.student_id) AND (s.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: `—`

### `public.schoolpro_audit_logs` — `school leaders read schoolpro audit logs`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.is_admin(ARRAY['super_admin'::user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'it_admin'::school_member_role]))`
- WITH CHECK: `—`

### `public.schoolpro_bank_accounts` — `school finance manage bank accounts`
- Command: `ALL`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`

### `public.schoolpro_bank_accounts` — `school members read bank accounts`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]) OR (EXISTS ( SELECT 1
   FROM (schoolpro_guardian_links g
     JOIN schoolpro_students s ON ((s.id = g.student_id)))
  WHERE ((g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text) AND (s.school_id = schoolpro_bank_accounts.school_id)))))`
- WITH CHECK: `—`

### `public.schoolpro_bank_accounts` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_board_members` — `School leaders and own board appointment`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.is_active_account() AND (private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.id = schoolpro_board_members.member_id) AND (m.user_id = auth.uid()))))))`
- WITH CHECK: `—`

### `public.schoolpro_branding` — `school branding manage`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_branding.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND ((m.role)::text = ANY (ARRAY['owner'::text, 'proprietor'::text, 'admin'::text, 'school_admin'::text])))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_branding.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND ((m.role)::text = ANY (ARRAY['owner'::text, 'proprietor'::text, 'admin'::text, 'school_admin'::text])))))`

### `public.schoolpro_branding` — `school branding read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_branding.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: `—`

### `public.schoolpro_branding` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'branding'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'branding'::text)`

### `public.schoolpro_branding` — `schoolpro_plan_branding_delete`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'branding'::text)`
- WITH CHECK: `—`

### `public.schoolpro_branding` — `schoolpro_plan_branding_insert`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'branding'::text)`

### `public.schoolpro_branding` — `schoolpro_plan_branding_update`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'branding'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'branding'::text)`

### `public.schoolpro_calendar_events` — `calendar management write`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'calendar'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role, 'registrar'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'calendar'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role, 'registrar'::school_member_role]))`

### `public.schoolpro_calendar_events` — `calendar school read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'calendar'::text) AND (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_calendar_events.school_id) AND (m.user_id = auth.uid())))))`
- WITH CHECK: `—`

### `public.schoolpro_candidate_cbt_answers` — `candidate answers authorized staff`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM (schoolpro_candidate_cbt_attempts ca
     JOIN schoolpro_admissions a ON ((a.id = ca.application_id)))
  WHERE ((ca.id = schoolpro_candidate_cbt_answers.attempt_id) AND private.schoolpro_module_allowed(a.school_id, 'admissions'::text) AND private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]))))`
- WITH CHECK: `—`

### `public.schoolpro_candidate_cbt_attempts` — `candidate attempts authorized staff`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_admissions a
  WHERE ((a.id = schoolpro_candidate_cbt_attempts.application_id) AND private.schoolpro_module_allowed(a.school_id, 'admissions'::text) AND private.has_school_access(a.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'registrar'::school_member_role, 'admissions_officer'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]))))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_answers` — `cbt answer staff read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM (schoolpro_cbt_attempts a
     JOIN schoolpro_cbt_tests t ON ((t.id = a.test_id)))
  WHERE ((a.id = schoolpro_cbt_answers.attempt_id) AND private.schoolpro_module_allowed(t.school_id, 'cbt'::text) AND schoolpro_can_manage_cbt(t.school_id))))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_answers` — `cbt answer student read own`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM (schoolpro_cbt_attempts a
     JOIN schoolpro_students s ON ((s.id = a.student_id)))
  WHERE ((a.id = schoolpro_cbt_answers.attempt_id) AND (s.user_id = auth.uid()))))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_answers` — `schoolpro_plan_answers`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_cbt_answer_plan_allowed(attempt_id)`
- WITH CHECK: `private.schoolpro_cbt_answer_plan_allowed(attempt_id)`

### `public.schoolpro_cbt_attempts` — `cbt attempt staff read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_cbt_tests t
  WHERE ((t.id = schoolpro_cbt_attempts.test_id) AND private.schoolpro_module_allowed(t.school_id, 'cbt'::text) AND schoolpro_can_manage_cbt(t.school_id))))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_attempts` — `cbt attempt student read own`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_cbt_attempts.student_id) AND (s.user_id = auth.uid()))))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_attempts` — `schoolpro_plan_attempts`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_cbt_test_plan_allowed(test_id)`
- WITH CHECK: `private.schoolpro_cbt_test_plan_allowed(test_id)`

### `public.schoolpro_cbt_eligibility` — `cbt eligibility managers`
- Command: `ALL`; roles: `authenticated`
- USING: `(schoolpro_can_manage_cbt(school_id) AND private.schoolpro_module_allowed(school_id, 'cbt'::text))`
- WITH CHECK: `(schoolpro_can_manage_cbt(school_id) AND private.schoolpro_module_allowed(school_id, 'cbt'::text))`

### `public.schoolpro_cbt_eligibility` — `cbt eligibility students read own`
- Command: `SELECT`; roles: `authenticated`
- USING: `((student_id IN ( SELECT schoolpro_students.id
   FROM schoolpro_students
  WHERE (schoolpro_students.user_id = auth.uid()))) OR (class_id IN ( SELECT schoolpro_students.class_id
   FROM schoolpro_students
  WHERE (schoolpro_students.user_id = auth.uid()))))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_eligibility` — `schoolpro_plan_access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) OR (COALESCE(private.is_active_account(), false) AND private.schoolpro_plan_feature_allowed(school_id, 'cbt'::text)))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) OR (COALESCE(private.is_active_account(), false) AND private.schoolpro_plan_feature_allowed(school_id, 'cbt'::text)))`

### `public.schoolpro_cbt_test_questions` — `test question authorized read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_cbt_tests t
  WHERE ((t.id = schoolpro_cbt_test_questions.test_id) AND private.schoolpro_module_allowed(t.school_id, 'cbt'::text) AND schoolpro_can_author_cbt(t.school_id))))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_test_questions` — `test question authors write`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_cbt_tests t
  WHERE ((t.id = schoolpro_cbt_test_questions.test_id) AND private.schoolpro_module_allowed(t.school_id, 'cbt'::text) AND schoolpro_can_author_cbt(t.school_id))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_cbt_tests t
  WHERE ((t.id = schoolpro_cbt_test_questions.test_id) AND private.schoolpro_module_allowed(t.school_id, 'cbt'::text) AND schoolpro_can_author_cbt(t.school_id))))`

### `public.schoolpro_cbt_tests` — `cbt authors create drafts`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `((status = 'draft'::text) AND private.schoolpro_module_allowed(school_id, 'cbt'::text) AND schoolpro_can_author_cbt(school_id))`

### `public.schoolpro_cbt_tests` — `cbt authors delete drafts`
- Command: `DELETE`; roles: `authenticated`
- USING: `((status = 'draft'::text) AND private.schoolpro_module_allowed(school_id, 'cbt'::text) AND schoolpro_can_author_cbt(school_id))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_tests` — `cbt authors edit drafts`
- Command: `UPDATE`; roles: `authenticated`
- USING: `((status = 'draft'::text) AND private.schoolpro_module_allowed(school_id, 'cbt'::text) AND schoolpro_can_author_cbt(school_id))`
- WITH CHECK: `((status = 'draft'::text) AND private.schoolpro_module_allowed(school_id, 'cbt'::text) AND schoolpro_can_author_cbt(school_id))`

### `public.schoolpro_cbt_tests` — `cbt authors read tests`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) AND schoolpro_can_author_cbt(school_id))`
- WITH CHECK: `—`

### `public.schoolpro_cbt_tests` — `cbt managers manage tests`
- Command: `ALL`; roles: `authenticated`
- USING: `(schoolpro_can_manage_cbt(school_id) AND private.schoolpro_module_allowed(school_id, 'cbt'::text))`
- WITH CHECK: `(schoolpro_can_manage_cbt(school_id) AND private.schoolpro_module_allowed(school_id, 'cbt'::text))`

### `public.schoolpro_cbt_tests` — `schoolpro_plan_access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) OR (COALESCE(private.is_active_account(), false) AND private.schoolpro_plan_feature_allowed(school_id, 'cbt'::text)))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) OR (COALESCE(private.is_active_account(), false) AND private.schoolpro_plan_feature_allowed(school_id, 'cbt'::text)))`

### `public.schoolpro_charge_categories` — `school community read charge categories`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role, 'teacher'::school_member_role]) OR (EXISTS ( SELECT 1
   FROM schoolpro_guardian_links g
  WHERE ((g.school_id = schoolpro_charge_categories.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))`
- WITH CHECK: `—`

### `public.schoolpro_charge_categories` — `school finance manage charge categories`
- Command: `ALL`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`

### `public.schoolpro_charge_categories` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_class_result_submissions` — `School result leaders read class submissions`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'results'::text) AND (schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_class_result_submissions.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['exam_officer'::text, 'head_teacher'::text, 'vice_principal'::text, 'it_admin'::text, 'teacher'::text, 'class_teacher'::text])))))))`
- WITH CHECK: `—`

### `public.schoolpro_classes` — `Authorized class lists`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_can_read_class(id)`
- WITH CHECK: `—`

### `public.schoolpro_classes` — `School leaders delete classes`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_classes` — `School leaders insert classes`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_classes` — `School leaders update classes`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_classes` — `School users read classes`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_classes` — `Scoped class lists`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_can_read_class(id)`
- WITH CHECK: `—`

### `public.schoolpro_classes` — `Super admin full access schoolpro_classes`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_custom_requests` — `own custom requests`
- Command: `SELECT`; roles: `authenticated`
- USING: `((requester_user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND ((p.role)::text = 'super_admin'::text)))))`
- WITH CHECK: `—`

### `public.schoolpro_custom_requests` — `submit custom request`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(requester_user_id = ( SELECT auth.uid() AS uid))`

### `public.schoolpro_custom_requests` — `superadmin custom request update`
- Command: `UPDATE`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND ((p.role)::text = 'super_admin'::text))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND ((p.role)::text = 'super_admin'::text))))`

### `public.schoolpro_demo_requests` — `Super admin full access schoolpro_demo_requests`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_demo_requests` — `Users read own demo requests`
- Command: `SELECT`; roles: `authenticated`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `—`

### `public.schoolpro_discipline_records` — `Assigned teachers report concerns`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'discipline'::text) AND (created_by = auth.uid()) AND (student_id IS NOT NULL) AND private.schoolpro_can_read_student(student_id) AND (EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_discipline_records.student_id) AND (s.school_id = schoolpro_discipline_records.school_id)))) AND (status = 'open'::text) AND (COALESCE(action_taken, ''::text) = ''::text) AND (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_discipline_records.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['teacher'::text, 'class_teacher'::text]))))))`

### `public.schoolpro_discipline_records` — `Teachers read their reported concerns`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'discipline'::text) AND (created_by = auth.uid()) AND private.schoolpro_can_read_student(student_id))`
- WITH CHECK: `—`

### `public.schoolpro_discipline_records` — `discipline authorized access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'discipline'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'vice_principal'::school_member_role, 'head_teacher'::school_member_role, 'counsellor'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'discipline'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'vice_principal'::school_member_role, 'head_teacher'::school_member_role, 'counsellor'::school_member_role]))`

### `public.schoolpro_document_issue_events` — `authorized staff read document issue events`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.is_admin(ARRAY['super_admin'::user_role]) OR schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_document_issue_events.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['registrar'::text, 'head_teacher'::text, 'vice_principal'::text]))))))`
- WITH CHECK: `—`

### `public.schoolpro_document_issues` — `authorized staff create draft document issues`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `((status = 'draft'::text) AND (issued_at IS NULL) AND (output_storage_path IS NULL) AND private.schoolpro_module_allowed(school_id, 'documents'::text) AND (schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_document_issues.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['registrar'::text, 'head_teacher'::text, 'vice_principal'::text])))))))`

### `public.schoolpro_document_issues` — `authorized staff delete draft document issues`
- Command: `DELETE`; roles: `authenticated`
- USING: `((status = 'draft'::text) AND schoolpro_member_can_manage(school_id))`
- WITH CHECK: `—`

### `public.schoolpro_document_issues` — `authorized staff read document issues`
- Command: `SELECT`; roles: `authenticated`
- USING: `(schoolpro_member_can_manage(school_id) OR private.is_admin(ARRAY['super_admin'::user_role]) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_document_issues.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['registrar'::text, 'head_teacher'::text, 'vice_principal'::text]))))))`
- WITH CHECK: `—`

### `public.schoolpro_document_issues` — `authorized staff update draft document issues`
- Command: `UPDATE`; roles: `authenticated`
- USING: `((status = 'draft'::text) AND private.schoolpro_module_allowed(school_id, 'documents'::text) AND (schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_document_issues.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['registrar'::text, 'head_teacher'::text, 'vice_principal'::text])))))))`
- WITH CHECK: `((status = 'draft'::text) AND (issued_at IS NULL))`

### `public.schoolpro_document_issues` — `guardians read ward issued documents`
- Command: `SELECT`; roles: `authenticated`
- USING: `((status = ANY (ARRAY['issued'::text, 'revoked'::text])) AND (EXISTS ( SELECT 1
   FROM schoolpro_guardian_links g
  WHERE ((g.student_id = schoolpro_document_issues.student_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))`
- WITH CHECK: `—`

### `public.schoolpro_document_issues` — `students read own issued documents`
- Command: `SELECT`; roles: `authenticated`
- USING: `((status = ANY (ARRAY['issued'::text, 'revoked'::text])) AND (EXISTS ( SELECT 1
   FROM schoolpro_students st
  WHERE ((st.id = schoolpro_document_issues.student_id) AND (st.school_id = st.school_id) AND (st.user_id = auth.uid())))))`
- WITH CHECK: `—`

### `public.schoolpro_document_templates` — `school managers manage document templates`
- Command: `ALL`; roles: `authenticated`
- USING: `(schoolpro_member_can_manage(school_id) AND private.schoolpro_module_allowed(school_id, 'documents'::text))`
- WITH CHECK: `(schoolpro_member_can_manage(school_id) AND private.schoolpro_module_allowed(school_id, 'documents'::text))`

### `public.schoolpro_document_templates` — `school members read document templates`
- Command: `SELECT`; roles: `authenticated`
- USING: `((EXISTS ( SELECT 1
   FROM schoolpro_schools s
  WHERE ((s.id = schoolpro_document_templates.school_id) AND (s.owner_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_document_templates.school_id) AND (m.user_id = auth.uid())))))`
- WITH CHECK: `—`

### `public.schoolpro_email_queue` — `school email read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_email_queue.school_id) AND (m.user_id = auth.uid()))))`
- WITH CHECK: `—`

### `public.schoolpro_enrollment_history` — `Authorized school enrollment history`
- Command: `SELECT`; roles: `authenticated`
- USING: `(( SELECT private.schoolpro_enrollment_reader_keys() AS schoolpro_enrollment_reader_keys) ? (((((school_id)::text || '|'::text) || (student_id)::text) || '|'::text) || session))`
- WITH CHECK: `—`

### `public.schoolpro_feature_overrides` — `school reads feature overrides`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_feature_overrides` — `superadmin manages feature overrides`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_fee_bank_accounts` — `schoolpro_fee_bank_manage`
- Command: `ALL`; roles: `public`
- USING: `((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'super_admin'::user_role)))) OR schoolpro_member_can_manage(school_id))`
- WITH CHECK: `((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'super_admin'::user_role)))) OR schoolpro_member_can_manage(school_id))`

### `public.schoolpro_fee_bank_accounts` — `schoolpro_fee_bank_read`
- Command: `SELECT`; roles: `public`
- USING: `((EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'super_admin'::user_role)))) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_fee_bank_accounts.school_id) AND (m.user_id = auth.uid())))))`
- WITH CHECK: `—`

### `public.schoolpro_fee_exceptions` — `finance manage fee exceptions`
- Command: `ALL`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`

### `public.schoolpro_fee_exceptions` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_fee_items` — `schoolpro_fee_item_delete`
- Command: `DELETE`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_fee_structures f
  WHERE ((f.id = schoolpro_fee_items.fee_structure_id) AND private.schoolpro_module_allowed(f.school_id, 'finance'::text) AND private.has_school_access(f.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))))`
- WITH CHECK: `—`

### `public.schoolpro_fee_items` — `schoolpro_fee_item_insert`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_fee_structures f
  WHERE ((f.id = schoolpro_fee_items.fee_structure_id) AND private.schoolpro_module_allowed(f.school_id, 'finance'::text) AND private.has_school_access(f.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))))`

### `public.schoolpro_fee_items` — `schoolpro_fee_item_read`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_can_read_fee_structure(fee_structure_id)`
- WITH CHECK: `—`

### `public.schoolpro_fee_items` — `schoolpro_fee_item_update`
- Command: `UPDATE`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_fee_structures f
  WHERE ((f.id = schoolpro_fee_items.fee_structure_id) AND private.schoolpro_module_allowed(f.school_id, 'finance'::text) AND private.has_school_access(f.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_fee_structures f
  WHERE ((f.id = schoolpro_fee_items.fee_structure_id) AND private.schoolpro_module_allowed(f.school_id, 'finance'::text) AND private.has_school_access(f.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))))`

### `public.schoolpro_fee_payments` — `School finance records payments`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]) AND (recorded_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_fee_payments` — `School members guardians and corporate finance read payments`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]) OR private.schoolpro_owns_invoice_student(school_id, student_id))`
- WITH CHECK: `—`

### `public.schoolpro_fee_payments` — `Super admin full access schoolpro_fee_payments`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_fee_payments` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_fee_records` — `School finance deletes fees`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_fee_records` — `School finance inserts fees`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role])`

### `public.schoolpro_fee_records` — `School finance reads fees`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_fee_records` — `School finance updates fees`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role])`

### `public.schoolpro_fee_records` — `Super admin full access schoolpro_fee_records`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_fee_records` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_fee_structures` — `School finance creates structures`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]) AND (created_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_fee_structures` — `School finance reads structures`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_can_read_fee_structure(id)`
- WITH CHECK: `—`

### `public.schoolpro_fee_structures` — `School finance updates structures`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`

### `public.schoolpro_fee_structures` — `School leaders delete structures`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_fee_structures` — `Super admin full access schoolpro_fee_structures`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_fee_structures` — `schoolpro_fee_structure_delete_scope`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `—`

### `public.schoolpro_fee_structures` — `schoolpro_fee_structure_insert_scope`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_fee_structures` — `schoolpro_fee_structure_read_scope`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_can_read_fee_structure(id)`
- WITH CHECK: `—`

### `public.schoolpro_fee_structures` — `schoolpro_fee_structure_update_scope`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_finance_settings` — `School leaders create finance settings`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) AND (updated_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_finance_settings` — `School leaders update finance settings`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) AND (updated_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_finance_settings` — `School users read finance settings`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_finance_settings` — `Super admin full access schoolpro_finance_settings`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_finance_settings` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_generated_result_outputs` — `authorized staff read generated results`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.is_admin(ARRAY['super_admin'::user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR (EXISTS ( SELECT 1
   FROM ((schoolpro_students st
     JOIN schoolpro_subject_assignments sa ON (((sa.school_id = st.school_id) AND (sa.class_id = st.class_id) AND (sa.session = schoolpro_generated_result_outputs.session))))
     JOIN schoolpro_members m ON ((m.id = sa.teacher_member_id)))
  WHERE ((st.id = schoolpro_generated_result_outputs.student_id) AND (st.school_id = schoolpro_generated_result_outputs.school_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['teacher'::school_member_role, 'class_teacher'::school_member_role]))))))`
- WITH CHECK: `—`

### `public.schoolpro_generated_result_outputs` — `authorized staff register generated results`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `((generated_by = auth.uid()) AND private.schoolpro_module_allowed(school_id, 'results'::text) AND (private.is_admin(ARRAY['super_admin'::user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR (EXISTS ( SELECT 1
   FROM ((schoolpro_students st
     JOIN schoolpro_subject_assignments sa ON (((sa.school_id = st.school_id) AND (sa.class_id = st.class_id) AND (sa.session = schoolpro_generated_result_outputs.session))))
     JOIN schoolpro_members m ON ((m.id = sa.teacher_member_id)))
  WHERE ((st.id = schoolpro_generated_result_outputs.student_id) AND (st.school_id = schoolpro_generated_result_outputs.school_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['teacher'::school_member_role, 'class_teacher'::school_member_role])))))))`

### `public.schoolpro_generated_result_outputs` — `students guardians read generated results`
- Command: `SELECT`; roles: `authenticated`
- USING: `schoolpro_can_view_result_output(student_id, term, session)`
- WITH CHECK: `—`

### `public.schoolpro_grade_scale` — `school leaders manage grade scale`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`

### `public.schoolpro_grade_scale` — `school users read grade scale`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_guardian_links` — `Guardians read own links`
- Command: `SELECT`; roles: `authenticated`
- USING: `((guardian_user_id = ( SELECT auth.uid() AS uid)) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]))`
- WITH CHECK: `—`

### `public.schoolpro_guardian_links` — `School leaders create guardian links`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) AND (linked_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_guardian_links` — `School leaders delete guardian links`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_guardian_links` — `School leaders update guardian links`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_guardian_links` — `Super admin full access schoolpro_guardian_links`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_health_records` — `clinic role boundary`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'medical'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'nurse'::school_member_role, 'counsellor'::school_member_role, 'head_teacher'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'medical'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'nurse'::school_member_role, 'counsellor'::school_member_role, 'head_teacher'::school_member_role]))`

### `public.schoolpro_health_records` — `health_school_staff`
- Command: `ALL`; roles: `authenticated`
- USING: `(schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_health_records.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['nurse'::text, 'counsellor'::text, 'head_teacher'::text, 'administrator'::text, 'proprietor'::text]))))))`
- WITH CHECK: `(schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_health_records.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['nurse'::text, 'counsellor'::text, 'head_teacher'::text, 'administrator'::text, 'proprietor'::text]))))))`

### `public.schoolpro_health_records` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'medical'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'medical'::text)`

### `public.schoolpro_hostel_allocations` — `hostel allocations authorized access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'hostel'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'hostel_manager'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'hostel'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'hostel_manager'::school_member_role]))`

### `public.schoolpro_hostel_rooms` — `hostel rooms authorized access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'hostel'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'hostel_manager'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'hostel'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'hostel_manager'::school_member_role]))`

### `public.schoolpro_inventory_assets` — `inventory authorized access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'inventory'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'inventory_officer'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'inventory'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'inventory_officer'::school_member_role]))`

### `public.schoolpro_invoice_templates` — `school invoice template access`
- Command: `ALL`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `private.has_school_access(school_id)`

### `public.schoolpro_invoice_templates` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_invoices` — `School finance creates invoices`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]) AND (created_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_invoices` — `School finance updates invoices`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])`

### `public.schoolpro_invoices` — `School leaders delete invoices`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_invoices` — `School members guardians and corporate finance read invoices`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]) OR private.schoolpro_owns_invoice_student(school_id, student_id))`
- WITH CHECK: `—`

### `public.schoolpro_invoices` — `Super admin full access schoolpro_invoices`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_invoices` — `schoolpro_invoice_delete_scope`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `—`

### `public.schoolpro_invoices` — `schoolpro_invoice_insert_scope`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_invoices` — `schoolpro_invoice_read_scope`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'finance'::text) OR (private.schoolpro_operationally_active(school_id) AND private.schoolpro_owns_invoice_student(school_id, student_id)))`
- WITH CHECK: `—`

### `public.schoolpro_invoices` — `schoolpro_invoice_update_scope`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_invoices` — `schoolpro_owned_invoice_read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_operationally_active(school_id) AND private.schoolpro_owns_invoice_student(school_id, student_id))`
- WITH CHECK: `—`

### `public.schoolpro_leadership_settings` — `School leadership settings`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_leave_requests` — `leave management access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'leave'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'hr_officer'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'leave'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'hr_officer'::school_member_role]))`

### `public.schoolpro_leave_requests` — `leave own read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'leave'::text) AND (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.id = schoolpro_leave_requests.member_id) AND (m.school_id = schoolpro_leave_requests.school_id) AND (m.user_id = auth.uid())))))`
- WITH CHECK: `—`

### `public.schoolpro_leave_requests` — `leave own request`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'leave'::text) AND (status = 'pending'::text) AND (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.id = schoolpro_leave_requests.member_id) AND (m.school_id = schoolpro_leave_requests.school_id) AND (m.user_id = auth.uid())))))`

### `public.schoolpro_lesson_notes` — `lesson notes author access`
- Command: `ALL`; roles: `authenticated`
- USING: `((school_id = ANY (( SELECT private.schoolpro_cached_access_schools('lesson-notes'::text, 'module'::text) AS schoolpro_cached_access_schools)::uuid[])) AND (created_by = ( SELECT auth.uid() AS uid)) AND private.schoolpro_lesson_author_scope(school_id, class_id, subject_id))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'lesson-notes'::text) AND (created_by = auth.uid()) AND private.schoolpro_lesson_author_scope(school_id, class_id, subject_id))`

### `public.schoolpro_lesson_notes` — `lesson notes leadership access`
- Command: `ALL`; roles: `authenticated`
- USING: `(school_id = ANY (( SELECT private.schoolpro_cached_access_schools('lesson-notes'::text, 'lesson-leader'::text) AS schoolpro_cached_access_schools)::uuid[]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'lesson-notes'::text) AND private.schoolpro_lesson_leader(school_id))`

### `public.schoolpro_library_books` — `Families read borrowed book details`
- Command: `SELECT`; roles: `authenticated`
- USING: `(COALESCE(private.is_active_account(), false) AND private.schoolpro_operationally_active(school_id) AND (EXISTS ( SELECT 1
   FROM schoolpro_library_loans l
  WHERE ((l.book_id = schoolpro_library_books.id) AND (l.school_id = schoolpro_library_books.school_id) AND (l.student_id IS NOT NULL)))))`
- WITH CHECK: `—`

### `public.schoolpro_library_books` — `library books authorized access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'library'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'librarian'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'library'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'librarian'::school_member_role]))`

### `public.schoolpro_library_loans` — `Families read own library loans`
- Command: `SELECT`; roles: `authenticated`
- USING: `(COALESCE(private.is_active_account(), false) AND private.schoolpro_operationally_active(school_id) AND (EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_library_loans.student_id) AND (s.school_id = schoolpro_library_loans.school_id) AND ((s.user_id = auth.uid()) OR (EXISTS ( SELECT 1
           FROM schoolpro_guardian_links g
          WHERE ((g.student_id = s.id) AND (g.school_id = s.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))))))`
- WITH CHECK: `—`

### `public.schoolpro_library_loans` — `library loans authorized access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'library'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'librarian'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'library'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'librarian'::school_member_role]))`

### `public.schoolpro_member_permissions` — `school permission manage`
- Command: `ALL`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'it_admin'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'it_admin'::school_member_role])`

### `public.schoolpro_member_permissions` — `school permission read`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_members` — `School leaders delete members`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_members` — `School leaders insert members`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_members` — `School leaders update members`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_members` — `School staff read own membership`
- Command: `SELECT`; roles: `authenticated`
- USING: `((user_id = ( SELECT auth.uid() AS uid)) AND private.is_active_account())`
- WITH CHECK: `—`

### `public.schoolpro_members` — `School users read members`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_members` — `Super admin full access schoolpro_members`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_module_records` — `school managers write module records`
- Command: `ALL`; roles: `authenticated`
- USING: `((EXISTS ( SELECT 1
   FROM schoolpro_schools s
  WHERE ((s.id = schoolpro_module_records.school_id) AND (s.owner_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_module_records.school_id) AND (m.user_id = auth.uid()) AND (m.role = 'administrator'::school_member_role)))) OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'super_admin'::user_role)))) OR ((module = ANY (ARRAY['assignments'::text, 'cbt'::text, 'timetable'::text, 'announcements'::text])) AND (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_module_records.school_id) AND (m.user_id = auth.uid()) AND (m.role = 'teacher'::school_member_role))))))`
- WITH CHECK: `((EXISTS ( SELECT 1
   FROM schoolpro_schools s
  WHERE ((s.id = schoolpro_module_records.school_id) AND (s.owner_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_module_records.school_id) AND (m.user_id = auth.uid()) AND (m.role = 'administrator'::school_member_role)))) OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'super_admin'::user_role)))) OR ((module = ANY (ARRAY['assignments'::text, 'cbt'::text, 'timetable'::text, 'announcements'::text])) AND (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_module_records.school_id) AND (m.user_id = auth.uid()) AND (m.role = 'teacher'::school_member_role))))))`

### `public.schoolpro_module_records` — `school members read module records`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_notifications` — `own schoolpro notifications`
- Command: `SELECT`; roles: `authenticated`
- USING: `(user_id = auth.uid())`
- WITH CHECK: `—`

### `public.schoolpro_notifications` — `update own schoolpro notifications`
- Command: `UPDATE`; roles: `authenticated`
- USING: `(user_id = auth.uid())`
- WITH CHECK: `(user_id = auth.uid())`

### `public.schoolpro_onboarding_requests` — `Super admin full access schoolpro_onboarding_requests`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_onboarding_requests` — `Users create onboarding requests`
- Command: `INSERT`; roles: `anon, authenticated`
- USING: `—`
- WITH CHECK: `((status = 'submitted'::text) AND (school_id IS NULL) AND (reviewed_by IS NULL) AND (reviewed_at IS NULL) AND (review_notes IS NULL) AND (((auth.uid() IS NULL) AND (user_id IS NULL)) OR ((user_id = auth.uid()) AND private.schoolpro_can_register())))`

### `public.schoolpro_onboarding_requests` — `Users read own onboarding requests`
- Command: `SELECT`; roles: `authenticated`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `—`

### `public.schoolpro_payment_allocations` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_payment_allocations` — `submitter or finance reads allocations`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_payment_submissions s
  WHERE ((s.id = schoolpro_payment_allocations.submission_id) AND ((s.submitted_by = auth.uid()) OR private.has_school_access(s.school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role])))))`
- WITH CHECK: `—`

### `public.schoolpro_payment_intents` — `Payers school and corporate finance read fee intents`
- Command: `SELECT`; roles: `authenticated`
- USING: `((payer_user_id = ( SELECT auth.uid() AS uid)) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]) OR private.has_product_access('corporate'::text, 'view'::text))`
- WITH CHECK: `—`

### `public.schoolpro_payment_intents` — `Super admin full access schoolpro_payment_intents`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_payment_intents` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_payment_proofs` — `guardian reads own proofs`
- Command: `SELECT`; roles: `authenticated`
- USING: `((submitted_by = auth.uid()) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))`
- WITH CHECK: `—`

### `public.schoolpro_payment_proofs` — `guardian submits proof`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `((submitted_by = auth.uid()) AND (EXISTS ( SELECT 1
   FROM schoolpro_guardian_links g
  WHERE ((g.student_id = schoolpro_payment_proofs.student_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))`

### `public.schoolpro_payment_proofs` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_payment_submissions` — `guardian inserts submissions`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `((submitted_by = auth.uid()) AND (EXISTS ( SELECT 1
   FROM schoolpro_guardian_links g
  WHERE ((g.school_id = schoolpro_payment_submissions.school_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text)))))`

### `public.schoolpro_payment_submissions` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'finance'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'finance'::text)`

### `public.schoolpro_payment_submissions` — `submitter or finance reads submissions`
- Command: `SELECT`; roles: `authenticated`
- USING: `((submitted_by = auth.uid()) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))`
- WITH CHECK: `—`

### `public.schoolpro_payroll_records` — `school payroll manage`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'payroll'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'payroll'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))`

### `public.schoolpro_payroll_records` — `school payroll read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'payroll'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]))`
- WITH CHECK: `—`

### `public.schoolpro_plan_catalog` — `public read active schoolpro plans`
- Command: `SELECT`; roles: `anon, authenticated`
- USING: `is_active`
- WITH CHECK: `—`

### `public.schoolpro_plan_catalog` — `superadmin manages schoolpro plans`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_portal_invites` — `school portal invite manage`
- Command: `ALL`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'it_admin'::school_member_role, 'registrar'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'it_admin'::school_member_role, 'registrar'::school_member_role])`

### `public.schoolpro_portal_invites` — `school portal invite read`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'it_admin'::school_member_role, 'registrar'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_promotions` — `promotion managers read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'promotions'::text) AND (private.is_admin(ARRAY['super_admin'::user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role, 'registrar'::school_member_role])))`
- WITH CHECK: `—`

### `public.schoolpro_question_bank` — `question bank authorized read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) AND schoolpro_can_author_cbt(school_id))`
- WITH CHECK: `—`

### `public.schoolpro_question_bank` — `school question manage`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) AND schoolpro_can_author_cbt(school_id))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) AND schoolpro_can_author_cbt(school_id))`

### `public.schoolpro_question_bank` — `schoolpro_plan_access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) OR (COALESCE(private.is_active_account(), false) AND private.schoolpro_plan_feature_allowed(school_id, 'cbt'::text)))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'cbt'::text) OR (COALESCE(private.is_active_account(), false) AND private.schoolpro_plan_feature_allowed(school_id, 'cbt'::text)))`

### `public.schoolpro_result_access_events` — `School leaders read result exception history`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_result_access_overrides` — `School leaders read result exceptions`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_result_access_pins` — `school staff manage result pins`
- Command: `ALL`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `private.has_school_access(school_id)`

### `public.schoolpro_result_access_pins` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'results'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'results'::text)`

### `public.schoolpro_result_approvals` — `result approvals leadership write`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'results'::text) AND (schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_result_approvals.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['exam_officer'::text, 'head_teacher'::text, 'vice_principal'::text])))))))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'results'::text) AND (schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_result_approvals.school_id) AND (m.user_id = auth.uid()) AND ((m.role)::text = ANY (ARRAY['exam_officer'::text, 'head_teacher'::text, 'vice_principal'::text])))))))`

### `public.schoolpro_result_approvals` — `result approvals school read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id) AND private.schoolpro_module_allowed(school_id, 'results'::text))`
- WITH CHECK: `—`

### `public.schoolpro_result_correction_requests` — `schoolpro_correction_request_insert`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `((requested_by = auth.uid()) AND (status = 'pending'::text) AND (EXISTS ( SELECT 1
   FROM schoolpro_results r
  WHERE ((r.id = schoolpro_result_correction_requests.result_id) AND (r.school_id = schoolpro_result_correction_requests.school_id) AND (r.status = 'published'::schoolpro_result_status)))) AND (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_result_correction_requests.school_id) AND (m.user_id = auth.uid()) AND ((m.role = ANY (ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role])) OR (EXISTS ( SELECT 1
           FROM ((schoolpro_results r
             JOIN schoolpro_enrollment_history h ON (((h.student_id = r.student_id) AND (h.session = r.session))))
             JOIN schoolpro_classes c ON ((c.id = h.class_id)))
          WHERE ((r.id = schoolpro_result_correction_requests.result_id) AND (c.form_teacher_id = m.id)))) OR (EXISTS ( SELECT 1
           FROM ((schoolpro_results r
             JOIN schoolpro_enrollment_history h ON (((h.student_id = r.student_id) AND (h.session = r.session))))
             JOIN schoolpro_subject_assignments a ON (((a.class_id = h.class_id) AND (a.subject_id = r.subject_id) AND (a.session = r.session))))
          WHERE ((r.id = schoolpro_result_correction_requests.result_id) AND (a.teacher_member_id = m.id)))))))))`

### `public.schoolpro_result_correction_requests` — `schoolpro_correction_request_read`
- Command: `SELECT`; roles: `authenticated`
- USING: `((requested_by = auth.uid()) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_result_correction_requests.school_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]))))))`
- WITH CHECK: `—`

### `public.schoolpro_result_correction_requests` — `schoolpro_correction_request_review`
- Command: `UPDATE`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_result_correction_requests.school_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role])))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_result_correction_requests.school_id) AND (m.user_id = auth.uid()) AND (m.role = ANY (ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role])))))`

### `public.schoolpro_result_corrections` — `authorized staff read result correction audit`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_result_domain_definitions` — `School leaders manage result domain definitions`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`

### `public.schoolpro_result_domain_definitions` — `School users read result domain definitions`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_result_domain_ratings` — `Linked families read released ratings`
- Command: `SELECT`; roles: `authenticated`
- USING: `(schoolpro_can_view_result_output(student_id, term, session) AND ((EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.id = schoolpro_result_domain_ratings.student_id) AND (s.user_id = auth.uid())))) OR (EXISTS ( SELECT 1
   FROM schoolpro_guardian_links g
  WHERE ((g.student_id = schoolpro_result_domain_ratings.student_id) AND (g.guardian_user_id = auth.uid()) AND (g.status = 'active'::text))))))`
- WITH CHECK: `—`

### `public.schoolpro_result_domain_ratings` — `School staff manage result ratings`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'teacher'::school_member_role, 'class_teacher'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `((private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'teacher'::school_member_role, 'class_teacher'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role])) AND (rated_by = auth.uid()))`

### `public.schoolpro_result_domain_ratings` — `School users read result ratings`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_result_domain_ratings` — `Scoped domain records`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_can_read_student(student_id) AND COALESCE(( SELECT a.allowed
   FROM private.schoolpro_result_access(schoolpro_result_domain_ratings.student_id, schoolpro_result_domain_ratings.term, schoolpro_result_domain_ratings.session) a(allowed, outstanding, reason)), false))`
- WITH CHECK: `(private.schoolpro_can_read_student(student_id) AND (EXISTS ( SELECT 1
   FROM (schoolpro_students s
     JOIN schoolpro_result_domain_definitions d ON ((d.school_id = s.school_id)))
  WHERE ((s.id = schoolpro_result_domain_ratings.student_id) AND (s.school_id = schoolpro_result_domain_ratings.school_id) AND (d.id = schoolpro_result_domain_ratings.definition_id)))))`

### `public.schoolpro_result_events` — `authorized staff read result events`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.is_admin(ARRAY['super_admin'::user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]))`
- WITH CHECK: `—`

### `public.schoolpro_result_rating_scale` — `School leaders manage result rating scale`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`

### `public.schoolpro_result_rating_scale` — `School users read result rating scale`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_result_templates` — `School leaders delete result templates`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_result_templates` — `School leaders insert result templates`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) AND (updated_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_result_templates` — `School leaders update result templates`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role]) AND (updated_by = ( SELECT auth.uid() AS uid)))`

### `public.schoolpro_result_templates` — `School users read result templates`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_result_templates` — `Super admin full access schoolpro_result_templates`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_result_templates` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'results'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'results'::text)`

### `public.schoolpro_result_term_settings` — `School leaders manage result term settings`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `((private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role])) AND (updated_by = auth.uid()))`

### `public.schoolpro_result_term_settings` — `School users read result term settings`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.has_school_access(school_id) OR private.is_admin(ARRAY['super_admin'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_result_verifications` — `authorized staff read result verification registry`
- Command: `SELECT`; roles: `authenticated`
- USING: `(private.is_admin(ARRAY['super_admin'::user_role]) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'exam_officer'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role]))`
- WITH CHECK: `—`

### `public.schoolpro_results` — `Authorized staff insert results`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `(private.schoolpro_can_write_result(school_id, student_id, subject_id, session) AND (locked = false) AND (status = 'draft'::schoolpro_result_status))`

### `public.schoolpro_results` — `Authorized staff update draft results`
- Command: `UPDATE`; roles: `authenticated`
- USING: `(private.schoolpro_can_write_result(school_id, student_id, subject_id, session) AND (locked = false) AND (status = 'draft'::schoolpro_result_status))`
- WITH CHECK: `(private.schoolpro_can_write_result(school_id, student_id, subject_id, session) AND (locked = false) AND (status = 'draft'::schoolpro_result_status))`

### `public.schoolpro_results` — `Result access gate`
- Command: `SELECT`; roles: `authenticated`
- USING: `(( SELECT private.is_active_account() AS is_active_account) AND
CASE
    WHEN (school_id = ANY (( SELECT private.schoolpro_cached_access_schools('results'::text, 'result-leader'::text) AS schoolpro_cached_access_schools)::uuid[])) THEN true
    ELSE ((school_id = ANY (( SELECT private.schoolpro_cached_staff_schools() AS schoolpro_cached_staff_schools)::uuid[])) OR (( SELECT private.schoolpro_cached_family_result_periods() AS schoolpro_cached_family_result_periods) ? (((((student_id)::text || '|'::text) || term) || '|'::text) || session)))
END)`
- WITH CHECK: `—`

### `public.schoolpro_results` — `Result reader access`
- Command: `SELECT`; roles: `authenticated`
- USING: `
CASE
    WHEN (school_id = ANY (( SELECT private.schoolpro_cached_access_schools('results'::text, 'result-leader'::text) AS schoolpro_cached_access_schools)::uuid[])) THEN true
    ELSE ((( SELECT private.schoolpro_cached_result_reader_keys() AS schoolpro_cached_result_reader_keys) ? (((((student_id)::text || '|'::text) || (subject_id)::text) || '|'::text) || session)) OR (( SELECT private.schoolpro_cached_result_reader_keys() AS schoolpro_cached_result_reader_keys) ? (((student_id)::text || '|*|'::text) || session)) OR (( SELECT private.schoolpro_cached_result_reader_keys() AS schoolpro_cached_result_reader_keys) ? ((student_id)::text || '|*|*'::text)) OR ((status = 'published'::schoolpro_result_status) AND locked AND (( SELECT private.schoolpro_cached_result_reader_keys() AS schoolpro_cached_result_reader_keys) ? ((student_id)::text || '|family'::text))))
END`
- WITH CHECK: `—`

### `public.schoolpro_results` — `Result student scope`
- Command: `SELECT`; roles: `authenticated`
- USING: `(student_id = ANY (( SELECT private.schoolpro_cached_readable_students() AS schoolpro_cached_readable_students)::uuid[]))`
- WITH CHECK: `—`

### `public.schoolpro_schools` — `Guardians read linked schools`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_guardian_links gl
  WHERE ((gl.school_id = schoolpro_schools.id) AND (gl.guardian_user_id = ( SELECT auth.uid() AS uid)) AND (gl.status = 'active'::text))))`
- WITH CHECK: `—`

### `public.schoolpro_schools` — `Members read linked school`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_schools.id) AND (m.user_id = auth.uid()))))`
- WITH CHECK: `—`

### `public.schoolpro_schools` — `Owners create schools`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `((owner_id = ( SELECT auth.uid() AS uid)) AND private.schoolpro_can_register())`

### `public.schoolpro_schools` — `School leaders update schools`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `private.has_school_access(id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_schools` — `School users read schools`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(id)`
- WITH CHECK: `—`

### `public.schoolpro_schools` — `Student reads own school`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.school_id = schoolpro_schools.id) AND (s.user_id = auth.uid()))))`
- WITH CHECK: `—`

### `public.schoolpro_schools` — `Super admin full access schoolpro_schools`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_site_content` — `public site content read`
- Command: `SELECT`; roles: `anon, authenticated`
- USING: `(is_published = true)`
- WITH CHECK: `—`

### `public.schoolpro_site_content` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'branding'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'branding'::text)`

### `public.schoolpro_site_gallery` — `public gallery read`
- Command: `SELECT`; roles: `anon, authenticated`
- USING: `(is_published = true)`
- WITH CHECK: `—`

### `public.schoolpro_site_gallery` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'branding'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'branding'::text)`

### `public.schoolpro_site_news` — `public news read`
- Command: `SELECT`; roles: `anon, authenticated`
- USING: `(is_published = true)`
- WITH CHECK: `—`

### `public.schoolpro_site_news` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'branding'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'branding'::text)`

### `public.schoolpro_site_settings` — `published school sites public`
- Command: `SELECT`; roles: `anon, authenticated`
- USING: `((is_published = true) OR (EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_site_settings.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid))))))`
- WITH CHECK: `—`

### `public.schoolpro_site_settings` — `school site managers write`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_site_settings.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND ((m.role)::text = ANY (ARRAY['proprietor'::text, 'administrator'::text, 'it_admin'::text])))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_site_settings.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND ((m.role)::text = ANY (ARRAY['proprietor'::text, 'administrator'::text, 'it_admin'::text])))))`

### `public.schoolpro_site_settings` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `private.schoolpro_module_allowed(school_id, 'branding'::text)`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'branding'::text)`

### `public.schoolpro_student_transport` — `student transport authorized access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'transport'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'transport_manager'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'transport'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'transport_manager'::school_member_role]))`

### `public.schoolpro_students` — `Guardians read linked students`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_guardian_links gl
  WHERE ((gl.student_id = schoolpro_students.id) AND (gl.guardian_user_id = ( SELECT auth.uid() AS uid)) AND (gl.status = 'active'::text))))`
- WITH CHECK: `—`

### `public.schoolpro_students` — `School leaders delete students`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_students` — `School leaders insert students`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_students` — `School leaders update students`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_students` — `School users read students`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_can_read_student(id)`
- WITH CHECK: `—`

### `public.schoolpro_students` — `Scoped student records`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_can_read_student(id)`
- WITH CHECK: `—`

### `public.schoolpro_students` — `Super admin full access schoolpro_students`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_students` — `students view own student row`
- Command: `SELECT`; roles: `authenticated`
- USING: `(user_id = ( SELECT auth.uid() AS uid))`
- WITH CHECK: `—`

### `public.schoolpro_subject_assignments` — `Leadership changes allocations`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_subject_assignments` — `Leadership creates allocations`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`

### `public.schoolpro_subject_assignments` — `Leadership removes allocations`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_subject_assignments` — `School leaders delete subject assignments`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_subject_assignments` — `School leaders insert subject assignments`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role])`

### `public.schoolpro_subject_assignments` — `School leaders update subject assignments`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'head_teacher'::school_member_role, 'vice_principal'::school_member_role])`

### `public.schoolpro_subject_assignments` — `School users read subject assignments`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_subject_assignments` — `Super admin full access schoolpro_subject_assignments`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_subject_assignments` — `Teachers read their own allocations`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_teacher_allocation_visible(school_id, teacher_member_id, class_id)`
- WITH CHECK: `—`

### `public.schoolpro_subjects` — `Active school staff read subject catalogue`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM (schoolpro_members m
     JOIN profiles p ON ((p.id = m.user_id)))
  WHERE ((m.school_id = schoolpro_subjects.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND (p.status = 'active'::account_status) AND ((m.role)::text = ANY (ARRAY['exam_officer'::text, 'head_teacher'::text, 'vice_principal'::text, 'class_teacher'::text, 'registrar'::text, 'it_admin'::text])))))`
- WITH CHECK: `—`

### `public.schoolpro_subjects` — `Guardians read linked subjects`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_guardian_links gl
  WHERE ((gl.school_id = schoolpro_subjects.school_id) AND (gl.guardian_user_id = ( SELECT auth.uid() AS uid)) AND (gl.status = 'active'::text))))`
- WITH CHECK: `—`

### `public.schoolpro_subjects` — `School leaders delete subjects`
- Command: `DELETE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role])`
- WITH CHECK: `—`

### `public.schoolpro_subjects` — `School leaders insert subjects`
- Command: `INSERT`; roles: `authenticated`
- USING: `—`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'teacher'::school_member_role])`

### `public.schoolpro_subjects` — `School leaders update subjects`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'teacher'::school_member_role])`
- WITH CHECK: `private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'teacher'::school_member_role])`

### `public.schoolpro_subjects` — `School users read subjects`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.has_school_access(school_id)`
- WITH CHECK: `—`

### `public.schoolpro_subjects` — `Students read own school subject names`
- Command: `SELECT`; roles: `authenticated`
- USING: `(COALESCE(private.is_active_account(), false) AND private.schoolpro_operationally_active(school_id) AND (EXISTS ( SELECT 1
   FROM schoolpro_students s
  WHERE ((s.school_id = schoolpro_subjects.school_id) AND (s.user_id = auth.uid())))))`
- WITH CHECK: `—`

### `public.schoolpro_subjects` — `Super admin full access schoolpro_subjects`
- Command: `ALL`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_subscription_catalog` — `authenticated read active subscription catalog`
- Command: `SELECT`; roles: `authenticated`
- USING: `(active = true)`
- WITH CHECK: `—`

### `public.schoolpro_subscription_catalog` — `public read active schoolpro subscription catalog`
- Command: `SELECT`; roles: `anon`
- USING: `(active = true)`
- WITH CHECK: `—`

### `public.schoolpro_subscription_catalog` — `schoolpro catalog readable`
- Command: `SELECT`; roles: `authenticated`
- USING: `true`
- WITH CHECK: `—`

### `public.schoolpro_subscription_catalog` — `super admin manages schoolpro subscription pricing`
- Command: `UPDATE`; roles: `authenticated`
- USING: `private.is_admin(ARRAY['super_admin'::user_role])`
- WITH CHECK: `private.is_admin(ARRAY['super_admin'::user_role])`

### `public.schoolpro_subscription_intents` — `school managers read subscription intents`
- Command: `SELECT`; roles: `authenticated`
- USING: `((payer_user_id = auth.uid()) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'bursar'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role, 'finance'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_subscription_payments` — `school managers read subscription payments`
- Command: `SELECT`; roles: `authenticated`
- USING: `((payer_user_id = auth.uid()) OR private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'accountant'::school_member_role, 'bursar'::school_member_role]) OR private.is_admin(ARRAY['super_admin'::user_role, 'finance'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_subscription_plans` — `authenticated read active schoolpro plans`
- Command: `SELECT`; roles: `authenticated`
- USING: `((active = true) OR private.is_admin(ARRAY['super_admin'::user_role, 'finance'::user_role]))`
- WITH CHECK: `—`

### `public.schoolpro_subscriptions` — `schoolpro_subscription_ihlink_write`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'super_admin'::user_role) AND (p.status = 'active'::account_status))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'super_admin'::user_role) AND (p.status = 'active'::account_status))))`

### `public.schoolpro_subscriptions` — `schoolpro_subscription_school_read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(schoolpro_member_can_manage(school_id) OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'super_admin'::user_role) AND (p.status = 'active'::account_status)))))`
- WITH CHECK: `—`

### `public.schoolpro_subscriptions` — `subscription school read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_subscriptions.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: `—`

### `public.schoolpro_timetable_entries` — `family historical timetable read`
- Command: `SELECT`; roles: `authenticated`
- USING: `private.schoolpro_family_class_read(school_id, class_id, session)`
- WITH CHECK: `—`

### `public.schoolpro_timetable_entries` — `manager timetable`
- Command: `ALL`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_timetable_entries.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND ((m.role)::text = ANY (ARRAY['owner'::text, 'proprietor'::text, 'admin'::text, 'school_admin'::text])))))`
- WITH CHECK: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_timetable_entries.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)) AND ((m.role)::text = ANY (ARRAY['owner'::text, 'proprietor'::text, 'admin'::text, 'school_admin'::text])))))`

### `public.schoolpro_timetable_entries` — `member read timetable`
- Command: `SELECT`; roles: `authenticated`
- USING: `(EXISTS ( SELECT 1
   FROM schoolpro_members m
  WHERE ((m.school_id = schoolpro_timetable_entries.school_id) AND (m.user_id = ( SELECT auth.uid() AS uid)))))`
- WITH CHECK: `—`

### `public.schoolpro_timetable_entries` — `schoolpro_module_permission`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_family_class_read(school_id, class_id, session) OR private.schoolpro_module_allowed(school_id, 'timetable'::text))`
- WITH CHECK: `private.schoolpro_module_allowed(school_id, 'timetable'::text)`

### `public.schoolpro_transcript_settings` — `transcript_settings_read`
- Command: `SELECT`; roles: `authenticated`
- USING: `(schoolpro_member_can_manage(school_id) OR private.schoolpro_can_issue_transcript(school_id))`
- WITH CHECK: `—`

### `public.schoolpro_transcript_settings` — `transcript_settings_write`
- Command: `ALL`; roles: `authenticated`
- USING: `(schoolpro_member_can_manage(school_id) OR private.schoolpro_can_issue_transcript(school_id))`
- WITH CHECK: `(schoolpro_member_can_manage(school_id) OR private.schoolpro_can_issue_transcript(school_id))`

### `public.schoolpro_transport_routes` — `transport routes authorized access`
- Command: `ALL`; roles: `authenticated`
- USING: `(private.schoolpro_module_allowed(school_id, 'transport'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'transport_manager'::school_member_role]))`
- WITH CHECK: `(private.schoolpro_module_allowed(school_id, 'transport'::text) AND private.has_school_access(school_id, ARRAY['proprietor'::school_member_role, 'administrator'::school_member_role, 'transport_manager'::school_member_role]))`

## Foreign keys involving SchoolPro-prefixed tables — complete constraint definitions (274)

- `private.schoolpro_academic_clock.schoolpro_academic_clock_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.ihlink_email_queue.ihlink_email_queue_school_id_fkey` → `public.schoolpro_schools`; delete action `a`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id)`
- `public.payment_transactions.payment_transactions_schoolpro_payment_intent_id_fkey` → `public.schoolpro_payment_intents`; delete action `n`, update action `a`; definition: `FOREIGN KEY (schoolpro_payment_intent_id) REFERENCES schoolpro_payment_intents(id) ON DELETE SET NULL`
- `public.schoolpro_academic_documents.schoolpro_academic_documents_issued_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (issued_by) REFERENCES auth.users(id)`
- `public.schoolpro_academic_documents.schoolpro_academic_documents_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_academic_documents.schoolpro_academic_documents_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_access_invitations.schoolpro_access_invitations_created_by_fkey` → `public.profiles`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES profiles(id)`
- `public.schoolpro_access_invitations.schoolpro_access_invitations_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_account_challenges.schoolpro_account_challenges_user_id_fkey` → `public.schoolpro_initial_credentials`; delete action `c`, update action `a`; definition: `FOREIGN KEY (user_id) REFERENCES schoolpro_initial_credentials(user_id) ON DELETE CASCADE`
- `public.schoolpro_admission_acceptances.schoolpro_admission_acceptances_application_id_fkey` → `public.schoolpro_admissions`; delete action `c`, update action `a`; definition: `FOREIGN KEY (application_id) REFERENCES schoolpro_admissions(id) ON DELETE CASCADE`
- `public.schoolpro_admission_acceptances.schoolpro_admission_acceptances_offer_id_fkey` → `public.schoolpro_admission_offers`; delete action `c`, update action `a`; definition: `FOREIGN KEY (offer_id) REFERENCES schoolpro_admission_offers(id) ON DELETE CASCADE`
- `public.schoolpro_admission_documents.schoolpro_admission_documents_application_id_fkey` → `public.schoolpro_admissions`; delete action `c`, update action `a`; definition: `FOREIGN KEY (application_id) REFERENCES schoolpro_admissions(id) ON DELETE CASCADE`
- `public.schoolpro_admission_events.schoolpro_admission_events_application_id_fkey` → `public.schoolpro_admissions`; delete action `c`, update action `a`; definition: `FOREIGN KEY (application_id) REFERENCES schoolpro_admissions(id) ON DELETE CASCADE`
- `public.schoolpro_admission_offers.schoolpro_admission_offers_application_id_fkey` → `public.schoolpro_admissions`; delete action `c`, update action `a`; definition: `FOREIGN KEY (application_id) REFERENCES schoolpro_admissions(id) ON DELETE CASCADE`
- `public.schoolpro_admissions.schoolpro_admissions_admitted_student_id_fkey` → `public.schoolpro_students`; delete action `a`, update action `a`; definition: `FOREIGN KEY (admitted_student_id) REFERENCES schoolpro_students(id)`
- `public.schoolpro_admissions.schoolpro_admissions_entrance_test_id_fkey` → `public.schoolpro_cbt_tests`; delete action `a`, update action `a`; definition: `FOREIGN KEY (entrance_test_id) REFERENCES schoolpro_cbt_tests(id)`
- `public.schoolpro_admissions.schoolpro_admissions_reviewed_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES auth.users(id)`
- `public.schoolpro_admissions.schoolpro_admissions_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_announcements.schoolpro_announcements_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_announcements.schoolpro_announcements_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_assessment_schemes.schoolpro_assessment_schemes_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_assignment_submissions.schoolpro_assignment_submissions_assignment_id_fkey` → `public.schoolpro_assignments`; delete action `c`, update action `a`; definition: `FOREIGN KEY (assignment_id) REFERENCES schoolpro_assignments(id) ON DELETE CASCADE`
- `public.schoolpro_assignment_submissions.schoolpro_assignment_submissions_graded_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (graded_by) REFERENCES auth.users(id)`
- `public.schoolpro_assignment_submissions.schoolpro_assignment_submissions_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_assignments.schoolpro_assignments_class_id_fkey` → `public.schoolpro_classes`; delete action `c`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id) ON DELETE CASCADE`
- `public.schoolpro_assignments.schoolpro_assignments_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_assignments.schoolpro_assignments_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_assignments.schoolpro_assignments_subject_id_fkey` → `public.schoolpro_subjects`; delete action `n`, update action `a`; definition: `FOREIGN KEY (subject_id) REFERENCES schoolpro_subjects(id) ON DELETE SET NULL`
- `public.schoolpro_attendance.schoolpro_attendance_class_id_fkey` → `public.schoolpro_classes`; delete action `c`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id) ON DELETE CASCADE`
- `public.schoolpro_attendance.schoolpro_attendance_marked_by_fkey` → `public.profiles`; delete action `r`, update action `a`; definition: `FOREIGN KEY (marked_by) REFERENCES profiles(id) ON DELETE RESTRICT`
- `public.schoolpro_attendance.schoolpro_attendance_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_attendance.schoolpro_attendance_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_audit_logs.schoolpro_audit_logs_actor_id_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (actor_id) REFERENCES auth.users(id)`
- `public.schoolpro_audit_logs.schoolpro_audit_logs_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_bank_accounts.schoolpro_bank_accounts_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_bank_accounts.schoolpro_bank_accounts_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_board_members.schoolpro_board_members_appointed_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (appointed_by) REFERENCES auth.users(id)`
- `public.schoolpro_board_members.schoolpro_board_members_member_id_fkey` → `public.schoolpro_members`; delete action `c`, update action `a`; definition: `FOREIGN KEY (member_id) REFERENCES schoolpro_members(id) ON DELETE CASCADE`
- `public.schoolpro_board_members.schoolpro_board_members_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_branding.schoolpro_branding_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_calendar_events.schoolpro_calendar_events_class_id_fkey` → `public.schoolpro_classes`; delete action `a`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id)`
- `public.schoolpro_calendar_events.schoolpro_calendar_events_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_candidate_cbt_answers.schoolpro_candidate_cbt_answers_attempt_id_fkey` → `public.schoolpro_candidate_cbt_attempts`; delete action `c`, update action `a`; definition: `FOREIGN KEY (attempt_id) REFERENCES schoolpro_candidate_cbt_attempts(id) ON DELETE CASCADE`
- `public.schoolpro_candidate_cbt_answers.schoolpro_candidate_cbt_answers_marked_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (marked_by) REFERENCES auth.users(id)`
- `public.schoolpro_candidate_cbt_answers.schoolpro_candidate_cbt_answers_question_id_fkey` → `public.schoolpro_question_bank`; delete action `a`, update action `a`; definition: `FOREIGN KEY (question_id) REFERENCES schoolpro_question_bank(id)`
- `public.schoolpro_candidate_cbt_attempts.schoolpro_candidate_cbt_attempts_application_id_fkey` → `public.schoolpro_admissions`; delete action `c`, update action `a`; definition: `FOREIGN KEY (application_id) REFERENCES schoolpro_admissions(id) ON DELETE CASCADE`
- `public.schoolpro_candidate_cbt_attempts.schoolpro_candidate_cbt_attempts_test_id_fkey` → `public.schoolpro_cbt_tests`; delete action `c`, update action `a`; definition: `FOREIGN KEY (test_id) REFERENCES schoolpro_cbt_tests(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_answers.schoolpro_cbt_answers_attempt_id_fkey` → `public.schoolpro_cbt_attempts`; delete action `c`, update action `a`; definition: `FOREIGN KEY (attempt_id) REFERENCES schoolpro_cbt_attempts(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_answers.schoolpro_cbt_answers_marked_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (marked_by) REFERENCES auth.users(id)`
- `public.schoolpro_cbt_answers.schoolpro_cbt_answers_question_id_fkey` → `public.schoolpro_question_bank`; delete action `c`, update action `a`; definition: `FOREIGN KEY (question_id) REFERENCES schoolpro_question_bank(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_attempts.schoolpro_cbt_attempts_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_attempts.schoolpro_cbt_attempts_test_id_fkey` → `public.schoolpro_cbt_tests`; delete action `c`, update action `a`; definition: `FOREIGN KEY (test_id) REFERENCES schoolpro_cbt_tests(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_eligibility.schoolpro_cbt_eligibility_assigned_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (assigned_by) REFERENCES auth.users(id)`
- `public.schoolpro_cbt_eligibility.schoolpro_cbt_eligibility_class_id_fkey` → `public.schoolpro_classes`; delete action `c`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_eligibility.schoolpro_cbt_eligibility_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_eligibility.schoolpro_cbt_eligibility_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_eligibility.schoolpro_cbt_eligibility_test_id_fkey` → `public.schoolpro_cbt_tests`; delete action `c`, update action `a`; definition: `FOREIGN KEY (test_id) REFERENCES schoolpro_cbt_tests(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_test_questions.schoolpro_cbt_test_questions_question_id_fkey` → `public.schoolpro_question_bank`; delete action `c`, update action `a`; definition: `FOREIGN KEY (question_id) REFERENCES schoolpro_question_bank(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_test_questions.schoolpro_cbt_test_questions_test_id_fkey` → `public.schoolpro_cbt_tests`; delete action `c`, update action `a`; definition: `FOREIGN KEY (test_id) REFERENCES schoolpro_cbt_tests(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_tests.schoolpro_cbt_tests_class_id_fkey` → `public.schoolpro_classes`; delete action `n`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id) ON DELETE SET NULL`
- `public.schoolpro_cbt_tests.schoolpro_cbt_tests_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_cbt_tests.schoolpro_cbt_tests_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_cbt_tests.schoolpro_cbt_tests_subject_id_fkey` → `public.schoolpro_subjects`; delete action `n`, update action `a`; definition: `FOREIGN KEY (subject_id) REFERENCES schoolpro_subjects(id) ON DELETE SET NULL`
- `public.schoolpro_charge_categories.schoolpro_charge_categories_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_charge_categories.schoolpro_charge_categories_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_class_result_submissions.schoolpro_class_result_submissions_class_id_fkey` → `public.schoolpro_classes`; delete action `c`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id) ON DELETE CASCADE`
- `public.schoolpro_class_result_submissions.schoolpro_class_result_submissions_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_class_result_submissions.schoolpro_class_result_submissions_submitted_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (submitted_by) REFERENCES auth.users(id)`
- `public.schoolpro_classes.schoolpro_classes_form_teacher_id_fkey` → `public.schoolpro_members`; delete action `n`, update action `a`; definition: `FOREIGN KEY (form_teacher_id) REFERENCES schoolpro_members(id) ON DELETE SET NULL`
- `public.schoolpro_classes.schoolpro_classes_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_custom_requests.schoolpro_custom_requests_requester_user_id_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (requester_user_id) REFERENCES auth.users(id)`
- `public.schoolpro_custom_requests.schoolpro_custom_requests_reviewed_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES auth.users(id)`
- `public.schoolpro_custom_requests.schoolpro_custom_requests_school_id_fkey` → `public.schoolpro_schools`; delete action `a`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id)`
- `public.schoolpro_demo_requests.schoolpro_demo_requests_reviewed_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES auth.users(id)`
- `public.schoolpro_demo_requests.schoolpro_demo_requests_school_id_fkey` → `public.schoolpro_schools`; delete action `n`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE SET NULL`
- `public.schoolpro_demo_requests.schoolpro_demo_requests_user_id_fkey` → `public.profiles`; delete action `n`, update action `a`; definition: `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL`
- `public.schoolpro_discipline_records.schoolpro_discipline_records_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_discipline_records.schoolpro_discipline_records_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_discipline_records.schoolpro_discipline_records_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_document_issue_events.schoolpro_document_issue_events_actor_id_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (actor_id) REFERENCES auth.users(id)`
- `public.schoolpro_document_issue_events.schoolpro_document_issue_events_issue_id_fkey` → `public.schoolpro_document_issues`; delete action `r`, update action `a`; definition: `FOREIGN KEY (issue_id) REFERENCES schoolpro_document_issues(id) ON DELETE RESTRICT`
- `public.schoolpro_document_issue_events.schoolpro_document_issue_events_school_id_fkey` → `public.schoolpro_schools`; delete action `r`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE RESTRICT`
- `public.schoolpro_document_issues.schoolpro_document_issues_issued_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (issued_by) REFERENCES auth.users(id)`
- `public.schoolpro_document_issues.schoolpro_document_issues_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_document_issues.schoolpro_document_issues_student_id_fkey` → `public.schoolpro_students`; delete action `n`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE SET NULL`
- `public.schoolpro_document_issues.schoolpro_document_issues_template_id_fkey` → `public.schoolpro_document_templates`; delete action `n`, update action `a`; definition: `FOREIGN KEY (template_id) REFERENCES schoolpro_document_templates(id) ON DELETE SET NULL`
- `public.schoolpro_document_templates.schoolpro_document_templates_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_document_templates.schoolpro_document_templates_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_email_queue.schoolpro_email_queue_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_enrollment_history.schoolpro_enrollment_history_class_id_fkey` → `public.schoolpro_classes`; delete action `a`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id)`
- `public.schoolpro_enrollment_history.schoolpro_enrollment_history_promotion_id_fkey` → `public.schoolpro_promotions`; delete action `a`, update action `a`; definition: `FOREIGN KEY (promotion_id) REFERENCES schoolpro_promotions(id)`
- `public.schoolpro_enrollment_history.schoolpro_enrollment_history_school_id_fkey` → `public.schoolpro_schools`; delete action `a`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id)`
- `public.schoolpro_enrollment_history.schoolpro_enrollment_history_student_id_fkey` → `public.schoolpro_students`; delete action `a`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id)`
- `public.schoolpro_feature_overrides.schoolpro_feature_overrides_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_feature_overrides.schoolpro_feature_overrides_updated_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (updated_by) REFERENCES auth.users(id)`
- `public.schoolpro_fee_bank_accounts.schoolpro_fee_bank_accounts_receiving_account_id_fkey` → `public.schoolpro_bank_accounts`; delete action `a`, update action `a`; definition: `FOREIGN KEY (receiving_account_id) REFERENCES schoolpro_bank_accounts(id)`
- `public.schoolpro_fee_bank_accounts.schoolpro_fee_bank_accounts_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_fee_bank_accounts.schoolpro_fee_bank_accounts_updated_by_fkey` → `auth.users`; delete action `n`, update action `a`; definition: `FOREIGN KEY (updated_by) REFERENCES auth.users(id) ON DELETE SET NULL`
- `public.schoolpro_fee_exceptions.schoolpro_fee_exceptions_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_fee_exceptions.schoolpro_fee_exceptions_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_fee_exceptions.schoolpro_fee_exceptions_updated_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (updated_by) REFERENCES auth.users(id)`
- `public.schoolpro_fee_items.schoolpro_fee_items_fee_structure_id_fkey` → `public.schoolpro_fee_structures`; delete action `c`, update action `a`; definition: `FOREIGN KEY (fee_structure_id) REFERENCES schoolpro_fee_structures(id) ON DELETE CASCADE`
- `public.schoolpro_fee_payments.schoolpro_fee_payments_invoice_id_fkey` → `public.schoolpro_invoices`; delete action `r`, update action `a`; definition: `FOREIGN KEY (invoice_id) REFERENCES schoolpro_invoices(id) ON DELETE RESTRICT`
- `public.schoolpro_fee_payments.schoolpro_fee_payments_recorded_by_fkey` → `public.profiles`; delete action `r`, update action `a`; definition: `FOREIGN KEY (recorded_by) REFERENCES profiles(id) ON DELETE RESTRICT`
- `public.schoolpro_fee_payments.schoolpro_fee_payments_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_fee_payments.schoolpro_fee_payments_student_id_fkey` → `public.schoolpro_students`; delete action `r`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE RESTRICT`
- `public.schoolpro_fee_records.schoolpro_fee_records_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_fee_records.schoolpro_fee_records_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_fee_structures.schoolpro_fee_structures_created_by_fkey` → `public.profiles`; delete action `r`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE RESTRICT`
- `public.schoolpro_fee_structures.schoolpro_fee_structures_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_finance_settings.schoolpro_finance_settings_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_finance_settings.schoolpro_finance_settings_updated_by_fkey` → `public.profiles`; delete action `r`, update action `a`; definition: `FOREIGN KEY (updated_by) REFERENCES profiles(id) ON DELETE RESTRICT`
- `public.schoolpro_generated_result_outputs.schoolpro_generated_result_outputs_generated_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (generated_by) REFERENCES auth.users(id)`
- `public.schoolpro_generated_result_outputs.schoolpro_generated_result_outputs_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_generated_result_outputs.schoolpro_generated_result_outputs_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_grade_scale.schoolpro_grade_scale_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_guardian_links.schoolpro_guardian_links_guardian_user_id_fkey` → `public.profiles`; delete action `c`, update action `a`; definition: `FOREIGN KEY (guardian_user_id) REFERENCES profiles(id) ON DELETE CASCADE`
- `public.schoolpro_guardian_links.schoolpro_guardian_links_linked_by_fkey` → `public.profiles`; delete action `r`, update action `a`; definition: `FOREIGN KEY (linked_by) REFERENCES profiles(id) ON DELETE RESTRICT`
- `public.schoolpro_guardian_links.schoolpro_guardian_links_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_guardian_links.schoolpro_guardian_links_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_health_records.schoolpro_health_records_recorded_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (recorded_by) REFERENCES auth.users(id)`
- `public.schoolpro_health_records.schoolpro_health_records_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_health_records.schoolpro_health_records_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_hostel_allocations.schoolpro_hostel_allocations_room_id_fkey` → `public.schoolpro_hostel_rooms`; delete action `a`, update action `a`; definition: `FOREIGN KEY (room_id) REFERENCES schoolpro_hostel_rooms(id)`
- `public.schoolpro_hostel_allocations.schoolpro_hostel_allocations_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_hostel_allocations.schoolpro_hostel_allocations_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_hostel_rooms.schoolpro_hostel_rooms_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_initial_credentials.schoolpro_initial_credentials_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_initial_credentials.schoolpro_initial_credentials_user_id_fkey` → `public.profiles`; delete action `c`, update action `a`; definition: `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE`
- `public.schoolpro_inventory_assets.schoolpro_inventory_assets_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_invoice_templates.schoolpro_invoice_templates_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_invoice_templates.schoolpro_invoice_templates_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_invoices.schoolpro_invoices_charge_category_id_fkey` → `public.schoolpro_charge_categories`; delete action `n`, update action `a`; definition: `FOREIGN KEY (charge_category_id) REFERENCES schoolpro_charge_categories(id) ON DELETE SET NULL`
- `public.schoolpro_invoices.schoolpro_invoices_created_by_fkey` → `public.profiles`; delete action `r`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE RESTRICT`
- `public.schoolpro_invoices.schoolpro_invoices_fee_structure_id_fkey` → `public.schoolpro_fee_structures`; delete action `n`, update action `a`; definition: `FOREIGN KEY (fee_structure_id) REFERENCES schoolpro_fee_structures(id) ON DELETE SET NULL`
- `public.schoolpro_invoices.schoolpro_invoices_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_invoices.schoolpro_invoices_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_leadership_settings.schoolpro_leadership_settings_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_leave_requests.schoolpro_leave_requests_member_id_fkey` → `public.schoolpro_members`; delete action `c`, update action `a`; definition: `FOREIGN KEY (member_id) REFERENCES schoolpro_members(id) ON DELETE CASCADE`
- `public.schoolpro_leave_requests.schoolpro_leave_requests_reviewed_by_fkey` → `public.profiles`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES profiles(id)`
- `public.schoolpro_leave_requests.schoolpro_leave_requests_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_lesson_notes.schoolpro_lesson_notes_class_id_fkey` → `public.schoolpro_classes`; delete action `a`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id)`
- `public.schoolpro_lesson_notes.schoolpro_lesson_notes_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_lesson_notes.schoolpro_lesson_notes_reviewed_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES auth.users(id)`
- `public.schoolpro_lesson_notes.schoolpro_lesson_notes_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_lesson_notes.schoolpro_lesson_notes_subject_id_fkey` → `public.schoolpro_subjects`; delete action `a`, update action `a`; definition: `FOREIGN KEY (subject_id) REFERENCES schoolpro_subjects(id)`
- `public.schoolpro_library_books.schoolpro_library_books_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_library_loans.schoolpro_library_loans_book_id_fkey` → `public.schoolpro_library_books`; delete action `a`, update action `a`; definition: `FOREIGN KEY (book_id) REFERENCES schoolpro_library_books(id)`
- `public.schoolpro_library_loans.schoolpro_library_loans_member_id_fkey` → `public.schoolpro_members`; delete action `a`, update action `a`; definition: `FOREIGN KEY (member_id) REFERENCES schoolpro_members(id)`
- `public.schoolpro_library_loans.schoolpro_library_loans_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_library_loans.schoolpro_library_loans_student_id_fkey` → `public.schoolpro_students`; delete action `a`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id)`
- `public.schoolpro_member_permissions.schoolpro_member_permissions_member_id_fkey` → `public.schoolpro_members`; delete action `c`, update action `a`; definition: `FOREIGN KEY (member_id) REFERENCES schoolpro_members(id) ON DELETE CASCADE`
- `public.schoolpro_member_permissions.schoolpro_member_permissions_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_member_permissions.schoolpro_member_permissions_updated_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (updated_by) REFERENCES auth.users(id)`
- `public.schoolpro_members.schoolpro_members_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_members.schoolpro_members_user_id_fkey` → `public.profiles`; delete action `c`, update action `a`; definition: `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE`
- `public.schoolpro_module_records.schoolpro_module_records_created_by_fkey` → `auth.users`; delete action `n`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL`
- `public.schoolpro_module_records.schoolpro_module_records_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_notifications.schoolpro_notifications_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_notifications.schoolpro_notifications_user_id_fkey` → `auth.users`; delete action `c`, update action `a`; definition: `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE`
- `public.schoolpro_onboarding_requests.schoolpro_onboarding_requests_reviewed_by_fkey` → `public.profiles`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES profiles(id)`
- `public.schoolpro_onboarding_requests.schoolpro_onboarding_requests_school_id_fkey` → `public.schoolpro_schools`; delete action `a`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id)`
- `public.schoolpro_onboarding_requests.schoolpro_onboarding_requests_user_id_fkey` → `public.profiles`; delete action `n`, update action `a`; definition: `FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE SET NULL`
- `public.schoolpro_payment_allocations.schoolpro_payment_allocations_invoice_id_fkey` → `public.schoolpro_invoices`; delete action `c`, update action `a`; definition: `FOREIGN KEY (invoice_id) REFERENCES schoolpro_invoices(id) ON DELETE CASCADE`
- `public.schoolpro_payment_allocations.schoolpro_payment_allocations_payment_id_fkey` → `public.schoolpro_fee_payments`; delete action `n`, update action `a`; definition: `FOREIGN KEY (payment_id) REFERENCES schoolpro_fee_payments(id) ON DELETE SET NULL`
- `public.schoolpro_payment_allocations.schoolpro_payment_allocations_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_payment_allocations.schoolpro_payment_allocations_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_payment_allocations.schoolpro_payment_allocations_submission_id_fkey` → `public.schoolpro_payment_submissions`; delete action `c`, update action `a`; definition: `FOREIGN KEY (submission_id) REFERENCES schoolpro_payment_submissions(id) ON DELETE CASCADE`
- `public.schoolpro_payment_intents.schoolpro_payment_intents_invoice_id_fkey` → `public.schoolpro_invoices`; delete action `r`, update action `a`; definition: `FOREIGN KEY (invoice_id) REFERENCES schoolpro_invoices(id) ON DELETE RESTRICT`
- `public.schoolpro_payment_intents.schoolpro_payment_intents_payer_user_id_fkey` → `public.profiles`; delete action `r`, update action `a`; definition: `FOREIGN KEY (payer_user_id) REFERENCES profiles(id) ON DELETE RESTRICT`
- `public.schoolpro_payment_intents.schoolpro_payment_intents_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_payment_intents.schoolpro_payment_intents_student_id_fkey` → `public.schoolpro_students`; delete action `r`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE RESTRICT`
- `public.schoolpro_payment_intents.schoolpro_payment_intents_virtual_account_id_fkey` → `public.virtual_accounts`; delete action `n`, update action `a`; definition: `FOREIGN KEY (virtual_account_id) REFERENCES virtual_accounts(id) ON DELETE SET NULL`
- `public.schoolpro_payment_proofs.schoolpro_payment_proofs_bank_account_id_fkey` → `public.schoolpro_bank_accounts`; delete action `n`, update action `a`; definition: `FOREIGN KEY (bank_account_id) REFERENCES schoolpro_bank_accounts(id) ON DELETE SET NULL`
- `public.schoolpro_payment_proofs.schoolpro_payment_proofs_invoice_id_fkey` → `public.schoolpro_invoices`; delete action `c`, update action `a`; definition: `FOREIGN KEY (invoice_id) REFERENCES schoolpro_invoices(id) ON DELETE CASCADE`
- `public.schoolpro_payment_proofs.schoolpro_payment_proofs_payment_id_fkey` → `public.schoolpro_fee_payments`; delete action `n`, update action `a`; definition: `FOREIGN KEY (payment_id) REFERENCES schoolpro_fee_payments(id) ON DELETE SET NULL`
- `public.schoolpro_payment_proofs.schoolpro_payment_proofs_reviewed_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES auth.users(id)`
- `public.schoolpro_payment_proofs.schoolpro_payment_proofs_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_payment_proofs.schoolpro_payment_proofs_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_payment_proofs.schoolpro_payment_proofs_submitted_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (submitted_by) REFERENCES auth.users(id)`
- `public.schoolpro_payment_submissions.schoolpro_payment_submissions_bank_account_id_fkey` → `public.schoolpro_bank_accounts`; delete action `n`, update action `a`; definition: `FOREIGN KEY (bank_account_id) REFERENCES schoolpro_bank_accounts(id) ON DELETE SET NULL`
- `public.schoolpro_payment_submissions.schoolpro_payment_submissions_reviewed_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES auth.users(id)`
- `public.schoolpro_payment_submissions.schoolpro_payment_submissions_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_payment_submissions.schoolpro_payment_submissions_submitted_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (submitted_by) REFERENCES auth.users(id)`
- `public.schoolpro_payroll_records.schoolpro_payroll_records_approved_by_fkey` → `public.profiles`; delete action `a`, update action `a`; definition: `FOREIGN KEY (approved_by) REFERENCES profiles(id)`
- `public.schoolpro_payroll_records.schoolpro_payroll_records_member_id_fkey` → `public.schoolpro_members`; delete action `c`, update action `a`; definition: `FOREIGN KEY (member_id) REFERENCES schoolpro_members(id) ON DELETE CASCADE`
- `public.schoolpro_payroll_records.schoolpro_payroll_records_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_portal_invites.schoolpro_portal_invites_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_portal_invites.schoolpro_portal_invites_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_promotions.schoolpro_promotions_applied_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (applied_by) REFERENCES auth.users(id)`
- `public.schoolpro_promotions.schoolpro_promotions_decided_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (decided_by) REFERENCES auth.users(id)`
- `public.schoolpro_promotions.schoolpro_promotions_from_class_id_fkey` → `public.schoolpro_classes`; delete action `r`, update action `a`; definition: `FOREIGN KEY (from_class_id) REFERENCES schoolpro_classes(id) ON DELETE RESTRICT`
- `public.schoolpro_promotions.schoolpro_promotions_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_promotions.schoolpro_promotions_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_promotions.schoolpro_promotions_to_class_id_fkey` → `public.schoolpro_classes`; delete action `r`, update action `a`; definition: `FOREIGN KEY (to_class_id) REFERENCES schoolpro_classes(id) ON DELETE RESTRICT`
- `public.schoolpro_question_bank.schoolpro_question_bank_class_id_fkey` → `public.schoolpro_classes`; delete action `a`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id)`
- `public.schoolpro_question_bank.schoolpro_question_bank_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_question_bank.schoolpro_question_bank_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_question_bank.schoolpro_question_bank_subject_id_fkey` → `public.schoolpro_subjects`; delete action `a`, update action `a`; definition: `FOREIGN KEY (subject_id) REFERENCES schoolpro_subjects(id)`
- `public.schoolpro_result_access_events.schoolpro_result_access_events_changed_by_fkey` → `public.profiles`; delete action `a`, update action `a`; definition: `FOREIGN KEY (changed_by) REFERENCES profiles(id)`
- `public.schoolpro_result_access_events.schoolpro_result_access_events_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_access_events.schoolpro_result_access_events_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_result_access_overrides.schoolpro_result_access_overrides_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_access_overrides.schoolpro_result_access_overrides_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_result_access_overrides.schoolpro_result_access_overrides_updated_by_fkey` → `public.profiles`; delete action `a`, update action `a`; definition: `FOREIGN KEY (updated_by) REFERENCES profiles(id)`
- `public.schoolpro_result_access_pins.schoolpro_result_access_pins_created_by_fkey` → `auth.users`; delete action `n`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL`
- `public.schoolpro_result_access_pins.schoolpro_result_access_pins_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_access_pins.schoolpro_result_access_pins_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_result_approvals.schoolpro_result_approvals_result_id_fkey` → `public.schoolpro_results`; delete action `c`, update action `a`; definition: `FOREIGN KEY (result_id) REFERENCES schoolpro_results(id) ON DELETE CASCADE`
- `public.schoolpro_result_approvals.schoolpro_result_approvals_reviewed_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reviewed_by) REFERENCES auth.users(id)`
- `public.schoolpro_result_approvals.schoolpro_result_approvals_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_correction_requests.schoolpro_result_correction_requests_result_id_fkey` → `public.schoolpro_results`; delete action `a`, update action `a`; definition: `FOREIGN KEY (result_id) REFERENCES schoolpro_results(id)`
- `public.schoolpro_result_corrections.schoolpro_result_corrections_reopened_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (reopened_by) REFERENCES auth.users(id)`
- `public.schoolpro_result_corrections.schoolpro_result_corrections_result_id_fkey` → `public.schoolpro_results`; delete action `r`, update action `a`; definition: `FOREIGN KEY (result_id) REFERENCES schoolpro_results(id) ON DELETE RESTRICT`
- `public.schoolpro_result_corrections.schoolpro_result_corrections_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_domain_definitions.schoolpro_result_domain_definitions_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_domain_ratings.schoolpro_result_domain_ratings_definition_id_fkey` → `public.schoolpro_result_domain_definitions`; delete action `c`, update action `a`; definition: `FOREIGN KEY (definition_id) REFERENCES schoolpro_result_domain_definitions(id) ON DELETE CASCADE`
- `public.schoolpro_result_domain_ratings.schoolpro_result_domain_ratings_rated_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (rated_by) REFERENCES auth.users(id)`
- `public.schoolpro_result_domain_ratings.schoolpro_result_domain_ratings_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_domain_ratings.schoolpro_result_domain_ratings_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_result_events.schoolpro_result_events_actor_id_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (actor_id) REFERENCES auth.users(id)`
- `public.schoolpro_result_events.schoolpro_result_events_result_id_fkey` → `public.schoolpro_results`; delete action `r`, update action `a`; definition: `FOREIGN KEY (result_id) REFERENCES schoolpro_results(id) ON DELETE RESTRICT`
- `public.schoolpro_result_events.schoolpro_result_events_school_id_fkey` → `public.schoolpro_schools`; delete action `r`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE RESTRICT`
- `public.schoolpro_result_rating_scale.schoolpro_result_rating_scale_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_templates.schoolpro_result_templates_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_templates.schoolpro_result_templates_updated_by_fkey` → `public.profiles`; delete action `n`, update action `a`; definition: `FOREIGN KEY (updated_by) REFERENCES profiles(id) ON DELETE SET NULL`
- `public.schoolpro_result_term_settings.schoolpro_result_term_settings_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_term_settings.schoolpro_result_term_settings_updated_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (updated_by) REFERENCES auth.users(id)`
- `public.schoolpro_result_verifications.schoolpro_result_verifications_issued_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (issued_by) REFERENCES auth.users(id)`
- `public.schoolpro_result_verifications.schoolpro_result_verifications_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_result_verifications.schoolpro_result_verifications_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_results.schoolpro_results_approved_by_fkey` → `public.profiles`; delete action `n`, update action `a`; definition: `FOREIGN KEY (approved_by) REFERENCES profiles(id) ON DELETE SET NULL`
- `public.schoolpro_results.schoolpro_results_assessment_scheme_id_fkey` → `public.schoolpro_assessment_schemes`; delete action `r`, update action `a`; definition: `FOREIGN KEY (assessment_scheme_id) REFERENCES schoolpro_assessment_schemes(id) ON DELETE RESTRICT`
- `public.schoolpro_results.schoolpro_results_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_results.schoolpro_results_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_results.schoolpro_results_subject_id_fkey` → `public.schoolpro_subjects`; delete action `c`, update action `a`; definition: `FOREIGN KEY (subject_id) REFERENCES schoolpro_subjects(id) ON DELETE CASCADE`
- `public.schoolpro_schools.schoolpro_schools_owner_id_fkey` → `public.profiles`; delete action `r`, update action `a`; definition: `FOREIGN KEY (owner_id) REFERENCES profiles(id) ON DELETE RESTRICT`
- `public.schoolpro_site_content.schoolpro_site_content_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_site_gallery.schoolpro_site_gallery_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_site_news.schoolpro_site_news_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_site_settings.schoolpro_site_settings_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_student_activation_challenges.schoolpro_student_activation_challenges_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_student_transport.schoolpro_student_transport_route_id_fkey` → `public.schoolpro_transport_routes`; delete action `a`, update action `a`; definition: `FOREIGN KEY (route_id) REFERENCES schoolpro_transport_routes(id)`
- `public.schoolpro_student_transport.schoolpro_student_transport_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_student_transport.schoolpro_student_transport_student_id_fkey` → `public.schoolpro_students`; delete action `c`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id) ON DELETE CASCADE`
- `public.schoolpro_students.schoolpro_students_class_id_fkey` → `public.schoolpro_classes`; delete action `n`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id) ON DELETE SET NULL`
- `public.schoolpro_students.schoolpro_students_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_students.schoolpro_students_user_id_fkey` → `auth.users`; delete action `n`, update action `a`; definition: `FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL`
- `public.schoolpro_subject_assignments.schoolpro_subject_assignments_class_id_fkey` → `public.schoolpro_classes`; delete action `c`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id) ON DELETE CASCADE`
- `public.schoolpro_subject_assignments.schoolpro_subject_assignments_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_subject_assignments.schoolpro_subject_assignments_subject_id_fkey` → `public.schoolpro_subjects`; delete action `c`, update action `a`; definition: `FOREIGN KEY (subject_id) REFERENCES schoolpro_subjects(id) ON DELETE CASCADE`
- `public.schoolpro_subject_assignments.schoolpro_subject_assignments_teacher_member_id_fkey` → `public.schoolpro_members`; delete action `n`, update action `a`; definition: `FOREIGN KEY (teacher_member_id) REFERENCES schoolpro_members(id) ON DELETE SET NULL`
- `public.schoolpro_subjects.schoolpro_subjects_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_subscription_intents.schoolpro_subscription_intents_catalog_id_fkey` → `public.schoolpro_subscription_catalog`; delete action `a`, update action `a`; definition: `FOREIGN KEY (catalog_id) REFERENCES schoolpro_subscription_catalog(id)`
- `public.schoolpro_subscription_intents.schoolpro_subscription_intents_demo_request_id_fkey` → `public.schoolpro_demo_requests`; delete action `a`, update action `a`; definition: `FOREIGN KEY (demo_request_id) REFERENCES schoolpro_demo_requests(id)`
- `public.schoolpro_subscription_intents.schoolpro_subscription_intents_payer_user_id_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (payer_user_id) REFERENCES auth.users(id)`
- `public.schoolpro_subscription_intents.schoolpro_subscription_intents_replaces_invoice_id_fkey` → `public.schoolpro_subscription_intents`; delete action `a`, update action `a`; definition: `FOREIGN KEY (replaces_invoice_id) REFERENCES schoolpro_subscription_intents(id)`
- `public.schoolpro_subscription_intents.schoolpro_subscription_intents_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_subscription_intents.schoolpro_subscription_intents_virtual_account_id_fkey` → `public.virtual_accounts`; delete action `a`, update action `a`; definition: `FOREIGN KEY (virtual_account_id) REFERENCES virtual_accounts(id)`
- `public.schoolpro_subscription_payments.schoolpro_subscription_payments_payer_user_id_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (payer_user_id) REFERENCES auth.users(id)`
- `public.schoolpro_subscription_payments.schoolpro_subscription_payments_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_subscription_payments.schoolpro_subscription_payments_subscription_id_fkey` → `public.schoolpro_subscriptions`; delete action `n`, update action `a`; definition: `FOREIGN KEY (subscription_id) REFERENCES schoolpro_subscriptions(id) ON DELETE SET NULL`
- `public.schoolpro_subscription_payments.schoolpro_subscription_payments_virtual_account_id_fkey` → `public.virtual_accounts`; delete action `n`, update action `a`; definition: `FOREIGN KEY (virtual_account_id) REFERENCES virtual_accounts(id) ON DELETE SET NULL`
- `public.schoolpro_subscriptions.schoolpro_subscriptions_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_timetable_entries.schoolpro_timetable_entries_class_id_fkey` → `public.schoolpro_classes`; delete action `c`, update action `a`; definition: `FOREIGN KEY (class_id) REFERENCES schoolpro_classes(id) ON DELETE CASCADE`
- `public.schoolpro_timetable_entries.schoolpro_timetable_entries_created_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (created_by) REFERENCES auth.users(id)`
- `public.schoolpro_timetable_entries.schoolpro_timetable_entries_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`
- `public.schoolpro_timetable_entries.schoolpro_timetable_entries_subject_id_fkey` → `public.schoolpro_subjects`; delete action `n`, update action `a`; definition: `FOREIGN KEY (subject_id) REFERENCES schoolpro_subjects(id) ON DELETE SET NULL`
- `public.schoolpro_transcript_issues.schoolpro_transcript_issues_issued_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (issued_by) REFERENCES auth.users(id)`
- `public.schoolpro_transcript_issues.schoolpro_transcript_issues_revoked_by_fkey` → `auth.users`; delete action `a`, update action `a`; definition: `FOREIGN KEY (revoked_by) REFERENCES auth.users(id)`
- `public.schoolpro_transcript_issues.schoolpro_transcript_issues_school_id_fkey` → `public.schoolpro_schools`; delete action `a`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id)`
- `public.schoolpro_transcript_issues.schoolpro_transcript_issues_student_id_fkey` → `public.schoolpro_students`; delete action `a`, update action `a`; definition: `FOREIGN KEY (student_id) REFERENCES schoolpro_students(id)`
- `public.schoolpro_transcript_settings.schoolpro_transcript_settings_school_id_fkey` → `public.schoolpro_schools`; delete action `a`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id)`
- `public.schoolpro_transport_routes.schoolpro_transport_routes_school_id_fkey` → `public.schoolpro_schools`; delete action `c`, update action `a`; definition: `FOREIGN KEY (school_id) REFERENCES schoolpro_schools(id) ON DELETE CASCADE`

## Current table grants on SchoolPro-prefixed public tables (2816)

- `public.schoolpro_academic_documents`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_academic_documents`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_academic_documents`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_academic_documents`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_academic_documents`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_academic_documents`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_academic_documents`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_academic_documents`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_academic_documents`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_access_invitations`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_access_invitations`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_access_invitations`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_access_invitations`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_access_invitations`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_access_invitations`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_access_invitations`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_access_invitations`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_access_invitations`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_access_invitations`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_access_invitations`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_access_invitations`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_access_invitations`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_access_invitations`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_account_challenges`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_account_challenges`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_account_challenges`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_account_challenges`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_account_challenges`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_account_challenges`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_account_challenges`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_account_challenges`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_account_challenges`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_account_challenges`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_account_challenges`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_account_challenges`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_account_challenges`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_account_challenges`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_admission_acceptances`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_admission_acceptances`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_admission_acceptances`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_admission_acceptances`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_admission_acceptances`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_admission_acceptances`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_admission_acceptances`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_acceptances`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_admission_documents`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_admission_documents`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_admission_documents`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_admission_documents`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_admission_documents`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_admission_documents`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_admission_documents`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_documents`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_admission_events`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_admission_events`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_admission_events`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_admission_events`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_admission_events`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_admission_events`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_admission_events`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_events`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_admission_offers`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_admission_offers`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_admission_offers`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_admission_offers`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_admission_offers`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_admission_offers`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_admission_offers`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admission_offers`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admissions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admissions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admissions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admissions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admissions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admissions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admissions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admissions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_admissions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_admissions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_admissions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_admissions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_admissions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_admissions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_admissions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_admissions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_admissions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_admissions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_admissions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_admissions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_announcements`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_announcements`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_announcements`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_announcements`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_announcements`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_announcements`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_announcements`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_announcements`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_announcements`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_announcements`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_announcements`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_announcements`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_announcements`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_announcements`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_announcements`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_announcements`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_announcements`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_announcements`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_announcements`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_announcements`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_assessment_schemes`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_assessment_schemes`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_assessment_schemes`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_assessment_schemes`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_assessment_schemes`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_assessment_schemes`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_assessment_schemes`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assessment_schemes`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_assignment_submissions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_assignment_submissions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_assignment_submissions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_assignment_submissions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_assignment_submissions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_assignment_submissions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_assignment_submissions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assignment_submissions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assignments`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assignments`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assignments`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assignments`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assignments`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assignments`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assignments`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assignments`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_assignments`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_assignments`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_assignments`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_assignments`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_assignments`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_assignments`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_assignments`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_assignments`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_assignments`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_assignments`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_assignments`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_assignments`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_attendance`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_attendance`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_attendance`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_attendance`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_attendance`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_attendance`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_attendance`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_attendance`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_attendance`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_attendance`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_attendance`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_attendance`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_attendance`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_attendance`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_attendance`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_attendance`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_attendance`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_attendance`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_attendance`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_attendance`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_audit_logs`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_audit_logs`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_audit_logs`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_audit_logs`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_audit_logs`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_audit_logs`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_audit_logs`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_audit_logs`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_bank_accounts`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_bank_accounts`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_bank_accounts`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_bank_accounts`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_bank_accounts`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_bank_accounts`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_bank_accounts`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_bank_accounts`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_board_members`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_board_members`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_board_members`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_board_members`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_board_members`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_board_members`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_board_members`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_board_members`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_board_members`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_board_members`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_board_members`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_board_members`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_board_members`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_board_members`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_board_members`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_branding`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_branding`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_branding`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_branding`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_branding`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_branding`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_branding`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_branding`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_branding`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_branding`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_branding`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_branding`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_branding`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_branding`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_branding`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_branding`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_branding`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_branding`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_branding`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_branding`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_branding`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_branding`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_branding`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_branding`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_branding`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_branding`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_branding`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_branding`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_calendar_events`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_calendar_events`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_calendar_events`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_calendar_events`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_calendar_events`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_calendar_events`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_calendar_events`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_calendar_events`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_candidate_cbt_answers`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_candidate_cbt_answers`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_candidate_cbt_answers`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_candidate_cbt_answers`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_candidate_cbt_answers`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_candidate_cbt_answers`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_candidate_cbt_answers`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_answers`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_candidate_cbt_attempts`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_candidate_cbt_attempts`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_candidate_cbt_attempts`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_candidate_cbt_attempts`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_candidate_cbt_attempts`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_candidate_cbt_attempts`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_candidate_cbt_attempts`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_candidate_cbt_attempts`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_cbt_answers`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_cbt_answers`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_cbt_answers`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_cbt_answers`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_cbt_answers`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_cbt_answers`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_cbt_answers`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_answers`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_cbt_attempts`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_cbt_attempts`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_cbt_attempts`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_cbt_attempts`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_cbt_attempts`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_cbt_attempts`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_cbt_attempts`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_attempts`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_cbt_eligibility`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_cbt_eligibility`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_cbt_eligibility`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_cbt_eligibility`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_cbt_eligibility`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_cbt_eligibility`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_cbt_eligibility`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_eligibility`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_cbt_test_questions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_cbt_test_questions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_cbt_test_questions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_cbt_test_questions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_cbt_test_questions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_cbt_test_questions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_cbt_test_questions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_test_questions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_cbt_tests`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_cbt_tests`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_cbt_tests`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_cbt_tests`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_cbt_tests`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_cbt_tests`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_cbt_tests`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_cbt_tests`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_charge_categories`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_charge_categories`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_charge_categories`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_charge_categories`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_charge_categories`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_charge_categories`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_charge_categories`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_charge_categories`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_class_result_submissions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_class_result_submissions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_class_result_submissions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_class_result_submissions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_class_result_submissions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_class_result_submissions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_class_result_submissions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_class_result_submissions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_classes`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_classes`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_classes`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_classes`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_classes`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_classes`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_classes`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_classes`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_classes`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_classes`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_classes`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_classes`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_classes`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_classes`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_classes`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_classes`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_classes`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_classes`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_classes`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_classes`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_classes`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_classes`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_classes`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_classes`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_classes`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_classes`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_classes`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_classes`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_custom_requests`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_custom_requests`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_custom_requests`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_custom_requests`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_custom_requests`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_custom_requests`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_custom_requests`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_custom_requests`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_demo_requests`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_demo_requests`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_demo_requests`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_demo_requests`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_demo_requests`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_demo_requests`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_demo_requests`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_demo_requests`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_discipline_records`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_discipline_records`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_discipline_records`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_discipline_records`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_discipline_records`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_discipline_records`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_discipline_records`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_discipline_records`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_document_issue_events`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_document_issue_events`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_document_issue_events`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_document_issue_events`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_document_issue_events`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_document_issue_events`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_document_issue_events`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_document_issue_events`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_document_issues`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_document_issues`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_document_issues`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_document_issues`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_document_issues`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_document_issues`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_document_issues`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_document_issues`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_document_templates`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_document_templates`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_document_templates`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_document_templates`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_document_templates`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_document_templates`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_document_templates`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_document_templates`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_email_queue`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_email_queue`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_email_queue`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_email_queue`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_email_queue`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_email_queue`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_email_queue`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_email_queue`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_enrollment_history`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_enrollment_history`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_enrollment_history`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_enrollment_history`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_enrollment_history`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_enrollment_history`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_enrollment_history`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_enrollment_history`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_feature_overrides`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_feature_overrides`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_feature_overrides`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_feature_overrides`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_feature_overrides`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_feature_overrides`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_feature_overrides`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_feature_overrides`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_fee_bank_accounts`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_fee_bank_accounts`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_fee_bank_accounts`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_fee_bank_accounts`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_fee_bank_accounts`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_fee_bank_accounts`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_fee_bank_accounts`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_bank_accounts`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_fee_exceptions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_fee_exceptions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_fee_exceptions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_fee_exceptions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_fee_exceptions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_fee_exceptions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_fee_exceptions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_exceptions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_fee_items`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_fee_items`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_fee_items`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_fee_items`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_fee_items`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_fee_items`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_fee_items`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_items`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_fee_payments`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_fee_payments`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_fee_payments`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_fee_payments`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_fee_payments`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_fee_payments`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_fee_payments`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_payments`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_fee_records`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_fee_records`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_fee_records`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_fee_records`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_fee_records`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_fee_records`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_fee_records`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_records`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_fee_structures`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_fee_structures`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_fee_structures`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_fee_structures`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_fee_structures`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_fee_structures`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_fee_structures`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_fee_structures`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_finance_settings`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_finance_settings`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_finance_settings`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_finance_settings`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_finance_settings`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_finance_settings`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_finance_settings`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_finance_settings`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_generated_result_outputs`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_generated_result_outputs`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_generated_result_outputs`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_generated_result_outputs`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_generated_result_outputs`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_generated_result_outputs`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_generated_result_outputs`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_generated_result_outputs`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_grade_scale`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_grade_scale`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_grade_scale`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_grade_scale`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_grade_scale`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_grade_scale`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_grade_scale`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_grade_scale`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_guardian_links`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_guardian_links`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_guardian_links`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_guardian_links`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_guardian_links`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_guardian_links`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_guardian_links`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_guardian_links`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_health_records`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_health_records`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_health_records`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_health_records`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_health_records`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_health_records`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_health_records`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_health_records`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_health_records`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_health_records`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_health_records`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_health_records`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_health_records`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_health_records`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_health_records`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_health_records`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_health_records`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_health_records`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_health_records`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_health_records`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_hostel_allocations`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_hostel_allocations`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_hostel_allocations`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_hostel_allocations`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_hostel_allocations`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_hostel_allocations`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_hostel_allocations`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_hostel_allocations`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_hostel_rooms`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_hostel_rooms`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_hostel_rooms`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_hostel_rooms`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_hostel_rooms`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_hostel_rooms`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_hostel_rooms`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_hostel_rooms`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_initial_credentials`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_initial_credentials`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_initial_credentials`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_initial_credentials`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_initial_credentials`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_initial_credentials`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_initial_credentials`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_initial_credentials`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_initial_credentials`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_initial_credentials`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_initial_credentials`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_initial_credentials`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_initial_credentials`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_initial_credentials`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_inventory_assets`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_inventory_assets`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_inventory_assets`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_inventory_assets`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_inventory_assets`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_inventory_assets`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_inventory_assets`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_inventory_assets`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_invoice_templates`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_invoice_templates`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_invoice_templates`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_invoice_templates`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_invoice_templates`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_invoice_templates`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_invoice_templates`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_invoice_templates`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_invoices`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_invoices`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_invoices`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_invoices`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_invoices`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_invoices`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_invoices`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_invoices`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_invoices`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_invoices`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_invoices`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_invoices`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_invoices`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_invoices`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_invoices`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_invoices`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_invoices`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_invoices`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_invoices`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_invoices`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_leadership_settings`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_leadership_settings`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_leadership_settings`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_leadership_settings`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_leadership_settings`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_leadership_settings`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_leadership_settings`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_leadership_settings`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_leadership_settings`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_leadership_settings`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_leadership_settings`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_leadership_settings`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_leadership_settings`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_leadership_settings`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_leadership_settings`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_leave_requests`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_leave_requests`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_leave_requests`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_leave_requests`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_leave_requests`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_leave_requests`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_leave_requests`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_leave_requests`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_lesson_notes`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_lesson_notes`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_lesson_notes`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_lesson_notes`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_lesson_notes`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_lesson_notes`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_lesson_notes`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_lesson_notes`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_library_books`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_library_books`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_library_books`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_library_books`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_library_books`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_library_books`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_library_books`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_library_books`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_library_books`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_library_books`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_library_books`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_library_books`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_library_books`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_library_books`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_library_books`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_library_books`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_library_books`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_library_books`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_library_books`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_library_books`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_library_loans`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_library_loans`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_library_loans`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_library_loans`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_library_loans`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_library_loans`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_library_loans`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_library_loans`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_login_attempts`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_login_attempts`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_login_attempts`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_login_attempts`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_login_attempts`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_login_attempts`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_login_attempts`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_login_attempts`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_login_attempts`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_login_attempts`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_login_attempts`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_login_attempts`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_login_attempts`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_login_attempts`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_member_permissions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_member_permissions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_member_permissions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_member_permissions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_member_permissions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_member_permissions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_member_permissions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_member_permissions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_members`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_members`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_members`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_members`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_members`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_members`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_members`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_members`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_members`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_members`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_members`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_members`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_members`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_members`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_members`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_members`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_members`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_members`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_members`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_members`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_members`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_members`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_members`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_members`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_members`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_members`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_members`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_members`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_module_records`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_module_records`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_module_records`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_module_records`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_module_records`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_module_records`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_module_records`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_module_records`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_module_records`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_module_records`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_module_records`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_module_records`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_module_records`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_module_records`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_module_records`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_module_records`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_module_records`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_module_records`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_module_records`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_module_records`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_notifications`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_notifications`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_notifications`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_notifications`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_notifications`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_notifications`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_notifications`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_notifications`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_notifications`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_notifications`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_notifications`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_notifications`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_notifications`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_notifications`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_notifications`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_notifications`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_notifications`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_notifications`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_notifications`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_notifications`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_onboarding_requests`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_onboarding_requests`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_onboarding_requests`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_onboarding_requests`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_onboarding_requests`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_onboarding_requests`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_onboarding_requests`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_onboarding_requests`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_payment_allocations`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_payment_allocations`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_payment_allocations`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_payment_allocations`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_payment_allocations`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_payment_allocations`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_payment_allocations`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_allocations`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_payment_intents`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_payment_intents`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_payment_intents`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_payment_intents`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_payment_intents`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_payment_intents`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_payment_intents`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_intents`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_payment_proofs`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_payment_proofs`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_payment_proofs`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_payment_proofs`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_payment_proofs`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_payment_proofs`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_payment_proofs`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_proofs`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_payment_submissions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_payment_submissions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_payment_submissions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_payment_submissions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_payment_submissions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_payment_submissions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_payment_submissions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payment_submissions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_payroll_records`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_payroll_records`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_payroll_records`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_payroll_records`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_payroll_records`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_payroll_records`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_payroll_records`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_payroll_records`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_plan_catalog`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_plan_catalog`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_plan_catalog`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_plan_catalog`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_plan_catalog`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_plan_catalog`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_plan_catalog`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_plan_catalog`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_portal_invites`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_portal_invites`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_portal_invites`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_portal_invites`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_portal_invites`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_portal_invites`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_portal_invites`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_portal_invites`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_promotions`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_promotions`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_promotions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_promotions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_promotions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_promotions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_promotions`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_promotions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_promotions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_promotions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_promotions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_promotions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_promotions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_promotions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_promotions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_promotions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_promotions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_promotions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_promotions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_promotions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_promotions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_promotions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_promotions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_promotions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_promotions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_question_bank`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_question_bank`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_question_bank`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_question_bank`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_question_bank`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_question_bank`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_question_bank`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_question_bank`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_access_events`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_access_events`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_access_events`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_access_events`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_access_events`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_access_events`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_access_events`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_events`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_access_overrides`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_access_overrides`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_access_overrides`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_access_overrides`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_access_overrides`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_access_overrides`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_access_overrides`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_overrides`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_access_pins`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_access_pins`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_access_pins`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_access_pins`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_access_pins`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_access_pins`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_access_pins`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_access_pins`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_approvals`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_approvals`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_approvals`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_approvals`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_approvals`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_approvals`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_approvals`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_approvals`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_correction_requests`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_correction_requests`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_correction_requests`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_correction_requests`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_correction_requests`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_correction_requests`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_correction_requests`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_correction_requests`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_corrections`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_corrections`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_corrections`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_corrections`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_corrections`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_corrections`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_corrections`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_corrections`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_domain_definitions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_domain_definitions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_domain_definitions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_domain_definitions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_domain_definitions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_domain_definitions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_domain_definitions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_domain_definitions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_domain_ratings`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_domain_ratings`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_domain_ratings`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_domain_ratings`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_domain_ratings`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_domain_ratings`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_domain_ratings`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_domain_ratings`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_events`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_events`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_events`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_events`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_events`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_events`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_events`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_events`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_events`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_events`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_events`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_events`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_events`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_events`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_events`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_events`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_events`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_events`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_events`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_events`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_events`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_rating_scale`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_rating_scale`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_rating_scale`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_rating_scale`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_rating_scale`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_rating_scale`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_rating_scale`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_rating_scale`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_templates`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_templates`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_templates`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_templates`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_templates`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_templates`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_templates`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_templates`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_term_settings`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_term_settings`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_term_settings`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_term_settings`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_term_settings`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_term_settings`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_term_settings`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_term_settings`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_result_verifications`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_result_verifications`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_result_verifications`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_result_verifications`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_result_verifications`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_result_verifications`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_result_verifications`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_result_verifications`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_results`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_results`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_results`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_results`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_results`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_results`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_results`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_results`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_results`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_results`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_results`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_results`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_results`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_results`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_results`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_results`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_results`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_results`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_results`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_results`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_results`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_results`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_results`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_results`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_results`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_results`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_results`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_schools`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_schools`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_schools`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_schools`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_schools`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_schools`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_schools`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_schools`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_schools`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_schools`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_schools`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_schools`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_schools`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_schools`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_schools`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_schools`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_schools`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_schools`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_schools`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_schools`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_schools`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_schools`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_schools`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_schools`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_schools`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_schools`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_schools`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_schools`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_content`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_content`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_content`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_content`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_content`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_content`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_content`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_content`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_site_content`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_site_content`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_site_content`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_site_content`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_site_content`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_site_content`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_site_content`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_content`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_content`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_content`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_content`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_content`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_site_gallery`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_site_gallery`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_site_gallery`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_site_gallery`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_site_gallery`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_site_gallery`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_site_gallery`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_gallery`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_news`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_news`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_news`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_news`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_news`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_news`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_news`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_news`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_site_news`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_site_news`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_site_news`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_site_news`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_site_news`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_site_news`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_site_news`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_news`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_news`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_news`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_news`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_news`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_site_settings`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_site_settings`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_site_settings`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_site_settings`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_site_settings`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_site_settings`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_site_settings`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_site_settings`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_student_activation_challenges`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_student_activation_challenges`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_student_activation_challenges`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_student_activation_challenges`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_student_activation_challenges`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_student_activation_challenges`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_student_activation_challenges`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_student_activation_challenges`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_student_activation_challenges`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_student_activation_challenges`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_student_activation_challenges`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_student_activation_challenges`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_student_activation_challenges`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_student_activation_challenges`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_student_transport`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_student_transport`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_student_transport`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_student_transport`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_student_transport`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_student_transport`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_student_transport`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_student_transport`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_students`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_students`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_students`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_students`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_students`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_students`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_students`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_students`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_students`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_students`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_students`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_students`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_students`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_students`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_students`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_students`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_students`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_students`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_students`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_students`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_students`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_students`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_students`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_students`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_students`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_students`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_students`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_students`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_subject_assignments`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_subject_assignments`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_subject_assignments`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_subject_assignments`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_subject_assignments`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_subject_assignments`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_subject_assignments`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subject_assignments`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subjects`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subjects`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subjects`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subjects`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subjects`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subjects`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subjects`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subjects`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_subjects`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_subjects`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_subjects`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_subjects`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_subjects`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_subjects`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_subjects`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subjects`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subjects`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subjects`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subjects`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subjects`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_subscription_catalog`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_subscription_catalog`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_subscription_catalog`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_subscription_catalog`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_subscription_catalog`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_subscription_catalog`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_subscription_catalog`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_catalog`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_subscription_intents`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_subscription_intents`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_subscription_intents`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_subscription_intents`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_subscription_intents`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_subscription_intents`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_subscription_intents`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_intents`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_subscription_payments`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_subscription_payments`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_subscription_payments`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_subscription_payments`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_subscription_payments`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_subscription_payments`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_subscription_payments`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_payments`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_subscription_plans`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_subscription_plans`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_subscription_plans`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_subscription_plans`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_subscription_plans`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_subscription_plans`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_subscription_plans`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscription_plans`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_subscriptions`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_subscriptions`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_subscriptions`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_subscriptions`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_subscriptions`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_subscriptions`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_subscriptions`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_subscriptions`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_timetable_entries`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_timetable_entries`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_timetable_entries`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_timetable_entries`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_timetable_entries`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_timetable_entries`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_timetable_entries`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_timetable_entries`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_transcript_issues`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_transcript_issues`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_transcript_issues`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_transcript_issues`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_transcript_issues`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_transcript_issues`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_transcript_issues`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_transcript_issues`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_transcript_issues`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_transcript_issues`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_transcript_issues`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_transcript_issues`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_transcript_issues`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_transcript_issues`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_transcript_settings`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_transcript_settings`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_transcript_settings`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_transcript_settings`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_transcript_settings`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_transcript_settings`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_transcript_settings`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_transcript_settings`: grantee `service_role`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `anon`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `anon`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `anon`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `anon`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `anon`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `anon`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `anon`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `authenticated`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `authenticated`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `authenticated`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `authenticated`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `authenticated`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `authenticated`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `authenticated`, privilege `UPDATE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `postgres`, privilege `DELETE`, grantable `YES`
- `public.schoolpro_transport_routes`: grantee `postgres`, privilege `INSERT`, grantable `YES`
- `public.schoolpro_transport_routes`: grantee `postgres`, privilege `REFERENCES`, grantable `YES`
- `public.schoolpro_transport_routes`: grantee `postgres`, privilege `SELECT`, grantable `YES`
- `public.schoolpro_transport_routes`: grantee `postgres`, privilege `TRIGGER`, grantable `YES`
- `public.schoolpro_transport_routes`: grantee `postgres`, privilege `TRUNCATE`, grantable `YES`
- `public.schoolpro_transport_routes`: grantee `postgres`, privilege `UPDATE`, grantable `YES`
- `public.schoolpro_transport_routes`: grantee `service_role`, privilege `DELETE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `service_role`, privilege `INSERT`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `service_role`, privilege `REFERENCES`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `service_role`, privilege `SELECT`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `service_role`, privilege `TRIGGER`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `service_role`, privilege `TRUNCATE`, grantable `NO`
- `public.schoolpro_transport_routes`: grantee `service_role`, privilege `UPDATE`, grantable `NO`

## Scheduled jobs relevant to SchoolPro/shared delivery/DataSub (7)

### `datasub-provider-health-5m` (#1)
- Schedule: `*/5 * * * *`; active: `true`
- Command: `select net.http_post(url:=(select decrypted_secret from vault.decrypted_secrets where name='datasub_project_url')||'/functions/v1/datasub-provider-health',headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||(select decrypted_secret from vault.decrypted_secrets where name='datasub_publishable_key')),body:='{}'::jsonb);`

### `datasub-reconcile-2m` (#3)
- Schedule: `*/2 * * * *`; active: `true`
- Command: `select net.http_post(url:=(select decrypted_secret from vault.decrypted_secrets where name='datasub_project_url')||'/functions/v1/datasub-reconcile',headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||(select decrypted_secret from vault.decrypted_secrets where name='datasub_publishable_key')),body:='{}'::jsonb);`

### `schoolpro-expiry-grace-daily` (#4)
- Schedule: `15 0 * * *`; active: `true`
- Command: `select private.enforce_schoolpro_subscription_expiry();`

### `billstack-pending-funding-5m` (#5)
- Schedule: `*/5 * * * *`; active: `true`
- Command: ` select net.http_post( url:=(select decrypted_secret from vault.decrypted_secrets where name='datasub_project_url')||'/functions/v1/billstack-reconcile', headers:=jsonb_build_object('Content-Type','application/json','x-reconcile-token',(select decrypted_secret from vault.decrypted_secrets where name='billstack_reconcile_token')), body:='{}'::jsonb,timeout_milliseconds:=60000 ) as request_id; `

### `datasub-api-callbacks-1m` (#12)
- Schedule: `* * * * *`; active: `true`
- Command: `select net.http_post(url:='https://lnqsroyiybutkfngbyge.supabase.co/functions/v1/datasub-api-callbacks',headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||(select decrypted_secret from vault.decrypted_secrets where name='ihlink_delivery_worker_token')),body:='{}'::jsonb);`

### `ihlink-email-delivery-2m` (#13)
- Schedule: `*/2 * * * *`; active: `true`
- Command: `select net.http_post(url:='https://lnqsroyiybutkfngbyge.supabase.co/functions/v1/ihlink-email-worker',headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||(select decrypted_secret from vault.decrypted_secrets where name='ihlink_delivery_worker_token')),body:='{}'::jsonb);`

### `schoolpro-academic-calendar` (#14)
- Schedule: `7 * * * *`; active: `true`
- Command: `select private.schoolpro_refresh_academic_clocks()`

## Installed extensions

- `pg_cron` 1.6.4 (schema `pg_catalog`)
- `pg_net` 0.20.4 (schema `extensions`)
- `pg_stat_statements` 1.11 (schema `extensions`)
- `pgcrypto` 1.3 (schema `extensions`)
- `plpgsql` 1.0 (schema `pg_catalog`)
- `supabase_vault` 0.3.1 (schema `vault`)
- `uuid-ossp` 1.1 (schema `extensions`)

## Review interpretation
- The policy expressions frequently reference Supabase-specific `auth.uid()` and `private.*` functions. They must not be copied unchanged to vanilla Aiven as a substitute for a deliberate authorization design.
- Cross-database foreign keys to `auth.users`, `profiles`, `virtual_accounts`, shared `payment_transactions` and `ihlink_email_queue` require explicit API/integration treatment. Aiven cannot enforce these cross-database relationships.
- Grants are catalog evidence only. Also inspect object ownership, schema grants, sequence grants, function EXECUTE ACLs, default privileges, security-definer search paths and RLS semantics before any port.
- Do not port DataSub/BillStack jobs. Retain Supabase Auth/Storage initially and avoid replaying email or expiry jobs during rehearsal until side effects are isolated.
- This snapshot does not contain complete routine bodies or trigger DDL; see the inventory and live routine snapshot documents for targeted definitions and remaining semantic review requirements.
