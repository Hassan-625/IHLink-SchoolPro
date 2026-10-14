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
