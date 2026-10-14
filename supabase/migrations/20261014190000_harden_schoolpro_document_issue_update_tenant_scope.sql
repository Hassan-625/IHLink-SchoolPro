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
    and (
      student_id is null
      or exists (
        select 1
        from public.schoolpro_students st
        where st.id = schoolpro_document_issues.student_id
          and st.school_id = schoolpro_document_issues.school_id
      )
    )
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


-- Keep the lifecycle RPC aligned with the documents module entitlement and
-- only finalize to a real object in the private document-output bucket.
create or replace function public.finalize_schoolpro_document_issue(
  p_issue uuid,
  p_output_path text
)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  i public.schoolpro_document_issues;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select *
    into i
    from public.schoolpro_document_issues
   where id = p_issue
   for update;

  if i.id is null then
    raise exception 'Document not found';
  end if;
  if i.status <> 'draft' then
    raise exception 'Only draft documents can be issued';
  end if;
  if trim(coalesce(p_output_path, '')) = ''
     or p_output_path not like i.school_id::text || '/%' then
    raise exception 'Invalid output path';
  end if;
  if not private.schoolpro_module_allowed(i.school_id, 'documents') then
    raise exception 'Module permission denied: documents';
  end if;
  if not (
    private.is_admin(array['super_admin'::public.user_role])
    or public.schoolpro_member_can_manage(i.school_id)
    or exists (
      select 1
        from public.schoolpro_members m
       where m.school_id = i.school_id
         and m.user_id = auth.uid()
         and m.role::text in ('registrar', 'head_teacher', 'vice_principal')
    )
  ) then
    raise exception 'Not authorized';
  end if;
  if not exists (
    select 1
      from storage.objects o
     where o.bucket_id = 'schoolpro-document-outputs'
       and o.name = p_output_path
  ) then
    raise exception 'Document output file not found in the authorized bucket';
  end if;

  perform set_config('ihlink.document_lifecycle_rpc', 'on', true);
  update public.schoolpro_document_issues
     set status = 'issued',
         output_storage_path = p_output_path,
         issued_at = now(),
         issued_by = auth.uid()
   where id = i.id;

  insert into public.schoolpro_document_issue_events
    (school_id, issue_id, event_type, actor_id, snapshot)
  select school_id, id, 'issued', auth.uid(), to_jsonb(x)
    from public.schoolpro_document_issues x
   where id = i.id;
end
$function$;
