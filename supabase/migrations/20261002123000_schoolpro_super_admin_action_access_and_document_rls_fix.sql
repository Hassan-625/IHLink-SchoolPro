-- Ensure IHLink Super Admin can execute SchoolPro management actions inside the selected tenant
-- while preserving ordinary school role boundaries. Also fixes document issuance tenant scoping.

create or replace function public.schoolpro_member_can_manage(p_school uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select private.is_admin(array['super_admin']::public.user_role[])
 or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','it_admin'))
 or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
$$;

create or replace function public.schoolpro_can_manage_cbt(p_school uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select private.is_admin(array['super_admin']::public.user_role[])
 or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
 or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in ('proprietor','administrator','teacher','class_teacher','exam_officer','head_teacher','vice_principal','it_admin'))
$$;

drop policy if exists "school managers manage document issues" on public.schoolpro_document_issues;
create policy "school managers manage document issues" on public.schoolpro_document_issues for all to authenticated
using (
 public.schoolpro_member_can_manage(school_id)
 or exists(select 1 from public.schoolpro_members m where m.school_id=schoolpro_document_issues.school_id and m.user_id=auth.uid() and m.role::text in('registrar','head_teacher','vice_principal'))
)
with check (
 public.schoolpro_member_can_manage(school_id)
 or exists(select 1 from public.schoolpro_members m where m.school_id=schoolpro_document_issues.school_id and m.user_id=auth.uid() and m.role::text in('registrar','head_teacher','vice_principal'))
);

create policy "super admin read schoolpro document objects" on storage.objects for select to authenticated
using (bucket_id='schoolpro-document-templates' and private.is_admin(array['super_admin']::public.user_role[]));
create policy "super admin insert schoolpro document objects" on storage.objects for insert to authenticated
with check (bucket_id='schoolpro-document-templates' and private.is_admin(array['super_admin']::public.user_role[]));
create policy "super admin update schoolpro document objects" on storage.objects for update to authenticated
using (bucket_id='schoolpro-document-templates' and private.is_admin(array['super_admin']::public.user_role[]))
with check (bucket_id='schoolpro-document-templates' and private.is_admin(array['super_admin']::public.user_role[]));
create policy "super admin delete schoolpro document objects" on storage.objects for delete to authenticated
using (bucket_id='schoolpro-document-templates' and private.is_admin(array['super_admin']::public.user_role[]));