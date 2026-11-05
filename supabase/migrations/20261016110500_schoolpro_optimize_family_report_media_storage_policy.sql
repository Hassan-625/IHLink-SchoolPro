-- Keep result-template workbook listing from evaluating the expensive family-report-media authorization
-- function for every object in the shared bucket. Resolve media paths through indexed exact-path lookups.
create index if not exists schoolpro_students_photo_storage_path_idx
  on public.schoolpro_students (photo_storage_path)
  where photo_storage_path is not null;

create index if not exists schoolpro_result_term_settings_principal_signature_path_idx
  on public.schoolpro_result_term_settings (principal_signature_path)
  where principal_signature_path is not null;

create index if not exists schoolpro_result_term_settings_form_teacher_signature_path_idx
  on public.schoolpro_result_term_settings (form_teacher_signature_path)
  where form_teacher_signature_path is not null;

create index if not exists schoolpro_result_templates_logo_storage_path_idx
  on public.schoolpro_result_templates (logo_storage_path)
  where logo_storage_path is not null;

create or replace function private.schoolpro_family_report_media(p_name text)
returns boolean
language sql
stable
security definer
set search_path to ''
as $function$
  select auth.uid() is not null and (
    exists (
      select 1
      from public.schoolpro_students s
      where s.photo_storage_path = p_name
        and exists (
          select 1
          from public.schoolpro_results r
          where r.student_id = s.id
            and r.school_id = s.school_id
            and r.status = 'published'
            and r.locked
            and public.schoolpro_can_view_result_output(s.id, r.term, r.session)
        )
    )
    or exists (
      select 1
      from public.schoolpro_result_term_settings ts
      where ts.principal_signature_path = p_name
        and exists (
          select 1
          from public.schoolpro_results r
          join public.schoolpro_students s
            on s.id = r.student_id and s.school_id = r.school_id
          where r.school_id = ts.school_id
            and r.term = ts.term
            and r.session = ts.session
            and r.status = 'published'
            and r.locked
            and public.schoolpro_can_view_result_output(s.id, r.term, r.session)
        )
    )
    or exists (
      select 1
      from public.schoolpro_result_term_settings ts
      where ts.form_teacher_signature_path = p_name
        and exists (
          select 1
          from public.schoolpro_results r
          join public.schoolpro_students s
            on s.id = r.student_id and s.school_id = r.school_id
          where r.school_id = ts.school_id
            and r.term = ts.term
            and r.session = ts.session
            and r.status = 'published'
            and r.locked
            and public.schoolpro_can_view_result_output(s.id, r.term, r.session)
        )
    )
    or exists (
      select 1
      from public.schoolpro_result_templates t
      where t.logo_storage_path = p_name
        and exists (
          select 1
          from public.schoolpro_results r
          join public.schoolpro_students s
            on s.id = r.student_id and s.school_id = r.school_id
          where r.school_id = t.school_id
            and r.status = 'published'
            and r.locked
            and public.schoolpro_can_view_result_output(s.id, r.term, r.session)
        )
    )
  );
$function$;

revoke all on function private.schoolpro_family_report_media(text) from public, anon;
grant execute on function private.schoolpro_family_report_media(text) to authenticated;

-- The same private bucket stores workbooks and report images. The CASE expression
-- guarantees non-media paths (including .xlsx templates) do not invoke the costly
-- report authorization function. Preserve access only for the app's known media paths.
drop policy if exists "Families read their report images" on storage.objects;
create policy "Families read their report images"
on storage.objects for select to authenticated
using (
  bucket_id = 'school-result-templates'
  and case
    when name ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/student-photos/[^/]+$'
      then private.schoolpro_family_report_media(name)
    when name ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/result-signatures/[^/]+/[^/]+/[^/]+$'
      then private.schoolpro_family_report_media(name)
    when name ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/school-logo\.[^/]+$'
      then private.schoolpro_family_report_media(name)
    else false
  end
);
