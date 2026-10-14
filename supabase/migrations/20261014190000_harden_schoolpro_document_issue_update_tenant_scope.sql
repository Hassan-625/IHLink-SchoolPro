-- Keep draft document issue updates bound to the same authorized school.
-- This migration is intentionally staged in the review branch; it is not applied to production here.

drop policy if exists "authorized staff update draft document issues"
  on public.schoolpro_document_issues;

create policy "authorized staff update draft document issues"
  on public.schoolpro_document_issues
  for update
  to authenticated
  using (
    status = 'draft'
    and private.schoolpro_module_allowed(school_id, 'documents')
    and (
      schoolpro_member_can_manage(school_id)
      or exists (
        select 1
        from public.schoolpro_members m
        where m.school_id = schoolpro_document_issues.school_id
          and m.user_id = auth.uid()
          and m.role::text = any (array['registrar', 'head_teacher', 'vice_principal'])
      )
    )
  )
  with check (
    status = 'draft'
    and issued_at is null
    and output_storage_path is null
    and private.schoolpro_module_allowed(school_id, 'documents')
    and (
      schoolpro_member_can_manage(school_id)
      or exists (
        select 1
        from public.schoolpro_members m
        where m.school_id = schoolpro_document_issues.school_id
          and m.user_id = auth.uid()
          and m.role::text = any (array['registrar', 'head_teacher', 'vice_principal'])
      )
    )
  );

-- Ensure a document issue's student belongs to the same school as the issue.
drop policy if exists "authorized staff create draft document issues"
  on public.schoolpro_document_issues;

create policy "authorized staff create draft document issues"
  on public.schoolpro_document_issues
  for insert
  to authenticated
  with check (
    status = 'draft'
    and issued_at is null
    and output_storage_path is null
    and private.schoolpro_module_allowed(school_id, 'documents')
    and (
      student_id is null
      or exists (
        select 1
        from public.schoolpro_students st
        where st.id = schoolpro_document_issues.student_id
          and st.school_id = schoolpro_document_issues.school_id
      )
    )
    and (
      schoolpro_member_can_manage(school_id)
      or exists (
        select 1
        from public.schoolpro_members m
        where m.school_id = schoolpro_document_issues.school_id
          and m.user_id = auth.uid()
          and m.role::text = any (array['registrar', 'head_teacher', 'vice_principal'])
      )
    )
  );

drop policy if exists "students read own issued documents"
  on public.schoolpro_document_issues;

create policy "students read own issued documents"
  on public.schoolpro_document_issues
  for select
  to authenticated
  using (
    status = any (array['issued', 'revoked'])
    and exists (
      select 1
      from public.schoolpro_students st
      where st.id = schoolpro_document_issues.student_id
        and st.school_id = schoolpro_document_issues.school_id
        and st.user_id = auth.uid()
    )
  );

drop policy if exists "guardians read ward issued documents"
  on public.schoolpro_document_issues;

create policy "guardians read ward issued documents"
  on public.schoolpro_document_issues
  for select
  to authenticated
  using (
    status = any (array['issued', 'revoked'])
    and exists (
      select 1
      from public.schoolpro_guardian_links g
      join public.schoolpro_students st
        on st.id = g.student_id
       and st.school_id = schoolpro_document_issues.school_id
      where g.student_id = schoolpro_document_issues.student_id
        and g.guardian_user_id = auth.uid()
        and g.status = 'active'
    )
  );
