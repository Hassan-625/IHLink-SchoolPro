
create or replace function private.schoolpro_family_class_read(p_school uuid,p_class uuid,p_session text) returns boolean language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) or not private.schoolpro_operationally_active(p_school) then return false;end if;
 return exists(select 1 from public.schoolpro_students s where s.school_id=p_school and (s.user_id=auth.uid() or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=s.id and g.school_id=p_school and g.guardian_user_id=auth.uid() and g.status='active')) and (exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=p_school and h.session=p_session and h.class_id=p_class) or (s.class_id=p_class and not exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=p_school))));
end $$;
revoke all on function private.schoolpro_family_class_read(uuid,uuid,text) from public,anon;
grant execute on function private.schoolpro_family_class_read(uuid,uuid,text) to authenticated;
alter policy "family historical timetable read" on public.schoolpro_timetable_entries using (private.schoolpro_family_class_read(school_id,class_id,session));
alter policy schoolpro_module_permission on public.schoolpro_timetable_entries using (private.schoolpro_family_class_read(school_id,class_id,session) or private.schoolpro_module_allowed(school_id,'timetable')) with check (private.schoolpro_module_allowed(school_id,'timetable'));
alter policy "assignment targeted read" on public.schoolpro_assignments using (
 private.schoolpro_family_class_read(school_id,class_id,session) or
 (private.schoolpro_module_allowed(school_id,'assignments') and
 (private.has_school_access(school_id,array['proprietor','administrator','head_teacher','vice_principal']::public.school_member_role[])
 or exists(select 1 from public.schoolpro_subject_assignments a join public.schoolpro_members m on m.id=a.teacher_member_id and m.school_id=a.school_id where a.school_id=schoolpro_assignments.school_id and a.class_id=schoolpro_assignments.class_id and a.subject_id=schoolpro_assignments.subject_id and a.session=schoolpro_assignments.session and m.user_id=auth.uid())
 or exists(select 1 from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id where c.id=schoolpro_assignments.class_id and c.school_id=schoolpro_assignments.school_id and m.user_id=auth.uid()))));
