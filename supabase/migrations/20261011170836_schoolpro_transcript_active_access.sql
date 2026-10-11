create or replace function private.schoolpro_can_issue_transcript(p_school uuid) returns boolean language sql stable security definer set search_path='' as $$
select auth.uid() is not null and private.is_active_account() and private.schoolpro_operationally_active(p_school) and private.schoolpro_module_allowed(p_school,'results') and (public.schoolpro_member_can_manage(p_school) or private.has_school_access(p_school,array['head_teacher','vice_principal','exam_officer']::public.school_member_role[]))
$$;
create policy "Examination leadership enrollment history" on public.schoolpro_enrollment_history for select to authenticated using(private.schoolpro_can_issue_transcript(school_id));
