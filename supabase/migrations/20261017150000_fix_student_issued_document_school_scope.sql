-- Draft migration: enforce tenant-consistent visibility for issued student documents.
-- Source review branch only. Do not apply to production before approval.
-- The student predicate previously compared st.school_id to itself (a tautology).
-- Guardian and staff SELECT policies also need relationship-school consistency because
-- PostgreSQL permissive policies combine with OR semantics.

DROP POLICY IF EXISTS "students read own issued documents"
  ON public.schoolpro_document_issues;
CREATE POLICY "students read own issued documents"
  ON public.schoolpro_document_issues
  FOR SELECT TO authenticated
  USING (
    status IN ('issued', 'revoked')
    AND EXISTS (
      SELECT 1
      FROM public.schoolpro_students AS st
      WHERE st.id = public.schoolpro_document_issues.student_id
        AND st.school_id = public.schoolpro_document_issues.school_id
        AND st.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "guardians read ward issued documents"
  ON public.schoolpro_document_issues;
CREATE POLICY "guardians read ward issued documents"
  ON public.schoolpro_document_issues
  FOR SELECT TO authenticated
  USING (
    status IN ('issued', 'revoked')
    AND EXISTS (
      SELECT 1
      FROM public.schoolpro_guardian_links AS g
      WHERE g.student_id = public.schoolpro_document_issues.student_id
        AND g.guardian_user_id = auth.uid()
        AND g.status = 'active'
        AND g.school_id = public.schoolpro_document_issues.school_id
    )
  );

DROP POLICY IF EXISTS "authorized staff read document issues"
  ON public.schoolpro_document_issues;
CREATE POLICY "authorized staff read document issues"
  ON public.schoolpro_document_issues
  FOR SELECT TO authenticated
  USING (
    (
      schoolpro_member_can_manage(public.schoolpro_document_issues.school_id)
      OR private.is_admin(ARRAY['super_admin'::user_role])
      OR EXISTS (
        SELECT 1
        FROM public.schoolpro_members AS m
        WHERE m.school_id = public.schoolpro_document_issues.school_id
          AND m.user_id = auth.uid()
          AND m.role::text IN ('registrar', 'head_teacher', 'vice_principal')
      )
    )
    AND EXISTS (
      SELECT 1
      FROM public.schoolpro_students AS st
      WHERE st.id = public.schoolpro_document_issues.student_id
        AND st.school_id = public.schoolpro_document_issues.school_id
    )
  );
