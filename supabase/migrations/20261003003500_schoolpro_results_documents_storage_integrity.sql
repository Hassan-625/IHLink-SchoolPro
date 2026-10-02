-- Final SchoolPro tenant-integrity hardening for results, documents and branding storage.

create or replace function private.validate_schoolpro_result_tenant()
returns trigger language plpgsql security definer set search_path='' as $$
declare ref_school uuid;
begin
 select school_id into ref_school from public.schoolpro_students where id=new.student_id;
 if ref_school is null or ref_school<>new.school_id then raise exception 'Result student belongs to another school'; end if;
 select school_id into ref_school from public.schoolpro_subjects where id=new.subject_id;
 if ref_school is null or ref_school<>new.school_id then raise exception 'Result subject belongs to another school'; end if;
 if new.assessment_scheme_id is not null then
   select school_id into ref_school from public.schoolpro_assessment_schemes where id=new.assessment_scheme_id;
   if ref_school is null or ref_school<>new.school_id then raise exception 'Assessment scheme belongs to another school'; end if;
 end if;
 return new;
end $$;
revoke all on function private.validate_schoolpro_result_tenant() from public,anon,authenticated;
drop trigger if exists validate_schoolpro_result_tenant on public.schoolpro_results;
create trigger validate_schoolpro_result_tenant before insert or update of school_id,student_id,subject_id,assessment_scheme_id
on public.schoolpro_results for each row execute function private.validate_schoolpro_result_tenant();

create or replace function private.validate_schoolpro_document_issue_tenant()
returns trigger language plpgsql security definer set search_path='' as $$
declare ref_school uuid;
begin
 if new.template_id is not null then
   select school_id into ref_school from public.schoolpro_document_templates where id=new.template_id;
   if ref_school is null or ref_school<>new.school_id then raise exception 'Document template belongs to another school'; end if;
 end if;
 if new.student_id is not null then
   select school_id into ref_school from public.schoolpro_students where id=new.student_id;
   if ref_school is null or ref_school<>new.school_id then raise exception 'Document student belongs to another school'; end if;
 end if;
 return new;
end $$;
revoke all on function private.validate_schoolpro_document_issue_tenant() from public,anon,authenticated;
drop trigger if exists validate_schoolpro_document_issue_tenant on public.schoolpro_document_issues;
create trigger validate_schoolpro_document_issue_tenant before insert or update of school_id,template_id,student_id
on public.schoolpro_document_issues for each row execute function private.validate_schoolpro_document_issue_tenant();

-- Keep source templates private and require the canonical tenant helper for every object operation.
drop policy if exists "schoolpro template objects read" on storage.objects;
create policy "schoolpro template objects read" on storage.objects for select to authenticated
using (
 bucket_id='schoolpro-document-templates'
 and public.schoolpro_member_can_manage(((storage.foldername(name))[1])::uuid)
);

drop policy if exists "schoolpro template objects insert" on storage.objects;
create policy "schoolpro template objects insert" on storage.objects for insert to authenticated
with check (
 bucket_id='schoolpro-document-templates'
 and public.schoolpro_member_can_manage(((storage.foldername(name))[1])::uuid)
);

drop policy if exists "schoolpro template objects update" on storage.objects;
create policy "schoolpro template objects update" on storage.objects for update to authenticated
using (
 bucket_id='schoolpro-document-templates'
 and public.schoolpro_member_can_manage(((storage.foldername(name))[1])::uuid)
)
with check (
 bucket_id='schoolpro-document-templates'
 and public.schoolpro_member_can_manage(((storage.foldername(name))[1])::uuid)
);

drop policy if exists "schoolpro template objects delete" on storage.objects;
create policy "schoolpro template objects delete" on storage.objects for delete to authenticated
using (
 bucket_id='schoolpro-document-templates'
 and public.schoolpro_member_can_manage(((storage.foldername(name))[1])::uuid)
);

-- Branding is public-readable by design for public school websites, but only tenant managers may mutate it.
drop policy if exists "schoolpro branding authenticated delete" on storage.objects;
create policy "schoolpro branding authenticated delete" on storage.objects for delete to authenticated
using (
 bucket_id='schoolpro-branding'
 and public.schoolpro_member_can_manage(((storage.foldername(name))[1])::uuid)
);
