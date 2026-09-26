drop policy "Users and admins read profiles" on public.profiles;
drop policy "School leaders read staff profiles" on public.profiles;
create policy "Authorized users read profiles" on public.profiles for select to authenticated using (
  id = (select auth.uid()) or private.is_admin() or
  exists (select 1 from public.schoolpro_members m where m.user_id = profiles.id and private.has_school_access(m.school_id, array['proprietor','administrator']::public.school_member_role[]))
);
create index schoolpro_results_assessment_scheme_idx on public.schoolpro_results (assessment_scheme_id);
