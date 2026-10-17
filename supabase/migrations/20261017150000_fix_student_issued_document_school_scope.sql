-- Draft migration: correct the student-issued-document tenant correlation.
-- Scope: RLS predicate only. This file is on the migration rehearsal branch and
-- MUST NOT be applied to production until review and authenticated negative tests pass.
-- Corrects st.school_id = st.school_id (tautology) to compare against the row school_id.

DROP POLICY IF EXISTS "students read own issued documents"
  ON public.schoolpro_document_issues;

CREATE POLICY "students read own issued documents"
  ON public.schoolpro_document_issues
  FOR SELECT
  TO authenticated
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
