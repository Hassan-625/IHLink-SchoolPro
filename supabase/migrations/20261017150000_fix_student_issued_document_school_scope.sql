-- Draft migration: enforce tenant-consistent visibility for issued student documents.
-- Source review branch only. Do not apply to production before approval.
-- The student predicate previously compared st.school_id to itself (a tautology).
-- Guardian and staff SELECT policies also need relationship-school consistency because
-- PostgreSQL permissive policies combine with OR semantics.

-- Remove the original broad policies. Permissive policies combine with OR,
-- so leaving either policy in place would bypass the scoped SELECT policies.
DROP POLICY IF EXISTS "school members read document issues"
  ON public.schoolpro_document_issues;
DROP POLICY IF EXISTS "school managers manage document issues"
  ON public.schoolpro_document_issues;

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
      EXISTS (
        SELECT 1
        FROM public.schoolpro_members AS m
        WHERE m.school_id = public.schoolpro_document_issues.school_id
          AND m.user_id = auth.uid()
          AND m.role::text = 'exam_officer'
      )
      OR EXISTS (
        SELECT 1
        FROM public.schoolpro_students AS st
        JOIN public.schoolpro_classes AS c
          ON c.id = st.class_id
         AND c.school_id = st.school_id
        JOIN public.schoolpro_members AS fm
          ON fm.id = c.form_teacher_id
         AND fm.school_id = c.school_id
        WHERE st.id = public.schoolpro_document_issues.student_id
          AND st.school_id = public.schoolpro_document_issues.school_id
          AND fm.user_id = auth.uid()
          AND fm.role::text IN ('teacher', 'class_teacher')
      )
      OR (
        (
          EXISTS (
            SELECT 1
            FROM public.schoolpro_members AS admin_member
            WHERE admin_member.school_id = public.schoolpro_document_issues.school_id
              AND admin_member.user_id = auth.uid()
              AND admin_member.role::text IN ('proprietor', 'administrator')
          )
          OR EXISTS (
            SELECT 1
            FROM public.schoolpro_schools AS owner_school
            WHERE owner_school.id = public.schoolpro_document_issues.school_id
              AND owner_school.owner_id = auth.uid()
          )
        )
        AND private.schoolpro_module_allowed(
          public.schoolpro_document_issues.school_id, 'documents'
        )
      )
    )
    AND (
      public.schoolpro_document_issues.student_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.schoolpro_students AS st
        WHERE st.id = public.schoolpro_document_issues.student_id
          AND st.school_id = public.schoolpro_document_issues.school_id
      )
    )
  );

-- Preserve legitimate manager and authorized registrar write access without
-- granting those roles an additional unscoped SELECT path.
CREATE POLICY "school managers insert document issues"
  ON public.schoolpro_document_issues
  FOR INSERT TO authenticated
  WITH CHECK (
    (
      schoolpro_member_can_manage(school_id)
      OR EXISTS (
        SELECT 1
        FROM public.schoolpro_members AS m
        WHERE m.school_id = public.schoolpro_document_issues.school_id
          AND m.user_id = auth.uid()
          AND m.role::text IN ('registrar', 'head_teacher', 'vice_principal')
      )
    )
    AND (
      student_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.schoolpro_students AS st
        WHERE st.id = public.schoolpro_document_issues.student_id
          AND st.school_id = public.schoolpro_document_issues.school_id
      )
    )
  );

CREATE POLICY "school managers update document issues"
  ON public.schoolpro_document_issues
  FOR UPDATE TO authenticated
  USING (
    schoolpro_member_can_manage(school_id)
    OR EXISTS (
      SELECT 1
      FROM public.schoolpro_members AS m
      WHERE m.school_id = public.schoolpro_document_issues.school_id
        AND m.user_id = auth.uid()
        AND m.role::text IN ('registrar', 'head_teacher', 'vice_principal')
    )
  )
  WITH CHECK (
    (
      schoolpro_member_can_manage(school_id)
      OR EXISTS (
        SELECT 1
        FROM public.schoolpro_members AS m
        WHERE m.school_id = public.schoolpro_document_issues.school_id
          AND m.user_id = auth.uid()
          AND m.role::text IN ('registrar', 'head_teacher', 'vice_principal')
      )
    )
    AND (
      student_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.schoolpro_students AS st
        WHERE st.id = public.schoolpro_document_issues.student_id
          AND st.school_id = public.schoolpro_document_issues.school_id
      )
    )
  );

CREATE POLICY "school managers delete document issues"
  ON public.schoolpro_document_issues
  FOR DELETE TO authenticated
  USING (
    schoolpro_member_can_manage(school_id)
    OR EXISTS (
      SELECT 1
      FROM public.schoolpro_members AS m
      WHERE m.school_id = public.schoolpro_document_issues.school_id
        AND m.user_id = auth.uid()
        AND m.role::text IN ('registrar', 'head_teacher', 'vice_principal')
    )
  );

-- Storage read policy is another permissive path to the same issued document.
-- Use an inner join so every accessible output has a student in the issue's school,
-- and require guardian-link school to match the issue school.
DROP POLICY IF EXISTS "schoolpro document outputs read" ON storage.objects;
CREATE POLICY "schoolpro document outputs read"
  ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'schoolpro-document-outputs'
    AND EXISTS (
      SELECT 1
      FROM public.schoolpro_document_issues AS d
      JOIN public.schoolpro_students AS st
        ON st.id = d.student_id
       AND st.school_id = d.school_id
      WHERE d.output_storage_path = objects.name
        AND (
          EXISTS (
            SELECT 1
            FROM public.schoolpro_members AS m
            WHERE m.school_id = d.school_id
              AND m.user_id = auth.uid()
              AND m.role::text = 'exam_officer'
          )
          OR EXISTS (
            SELECT 1
            FROM public.schoolpro_classes AS c
            JOIN public.schoolpro_members AS fm
              ON fm.id = c.form_teacher_id
             AND fm.school_id = c.school_id
            WHERE c.id = st.class_id
              AND c.school_id = st.school_id
              AND fm.user_id = auth.uid()
              AND fm.role::text IN ('teacher', 'class_teacher')
          )
          OR (
            (
              EXISTS (
                SELECT 1
                FROM public.schoolpro_members AS admin_member
                WHERE admin_member.school_id = d.school_id
                  AND admin_member.user_id = auth.uid()
                  AND admin_member.role::text IN ('proprietor', 'administrator')
              )
              OR EXISTS (
                SELECT 1
                FROM public.schoolpro_schools AS owner_school
                WHERE owner_school.id = d.school_id
                  AND owner_school.owner_id = auth.uid()
              )
            )
            AND private.schoolpro_module_allowed(d.school_id, 'documents')
          )
          OR (
            d.status IN ('issued', 'revoked')
            AND st.user_id = auth.uid()
          )
          OR (
            d.status IN ('issued', 'revoked')
            AND EXISTS (
              SELECT 1
              FROM public.schoolpro_guardian_links AS g
              WHERE g.student_id = d.student_id
                AND g.school_id = d.school_id
                AND g.guardian_user_id = auth.uid()
                AND g.status = 'active'
            )
          )
        )
    )
  );
