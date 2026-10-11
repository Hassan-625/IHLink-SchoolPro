create or replace function private.schoolpro_cached_access_schools(p_permission text,p_scope text default 'module') returns uuid[] language sql stable security definer set search_path='' as $$
select coalesce(array_agg(s.id),array[]::uuid[]) from public.schoolpro_schools s
where (select auth.uid()) is not null and (select private.is_active_account())
and (private.is_admin(array['super_admin']::public.user_role[]) or s.owner_id=(select auth.uid()) or exists(select 1 from public.schoolpro_members m where m.school_id=s.id and m.user_id=(select auth.uid())))
and case p_scope
when 'lesson-leader' then private.schoolpro_module_allowed(s.id,p_permission) and private.schoolpro_lesson_leader(s.id)
when 'result-leader' then private.schoolpro_operationally_active(s.id) and (private.is_admin(array['super_admin']::public.user_role[]) or s.owner_id=(select auth.uid()) or exists(select 1 from public.schoolpro_members m where m.school_id=s.id and m.user_id=(select auth.uid()) and m.role in('proprietor','administrator','exam_officer','head_teacher','vice_principal')))
else private.schoolpro_module_allowed(s.id,p_permission) end
$$;
revoke all on function private.schoolpro_cached_access_schools(text,text) from public,anon;
grant execute on function private.schoolpro_cached_access_schools(text,text) to authenticated,service_role;
alter policy "lesson notes leadership access" on public.schoolpro_lesson_notes using (school_id=any((select private.schoolpro_cached_access_schools('lesson-notes','lesson-leader'))::uuid[]));
alter policy "lesson notes author access" on public.schoolpro_lesson_notes using (school_id=any((select private.schoolpro_cached_access_schools('lesson-notes','module'))::uuid[]) and created_by=(select auth.uid()) and private.schoolpro_lesson_author_scope(school_id,class_id,subject_id));
alter policy "Result access gate" on public.schoolpro_results using (case when school_id=any((select private.schoolpro_cached_access_schools('results','result-leader'))::uuid[]) then true else (private.schoolpro_can_read_student(student_id) and coalesce((select a.allowed from private.schoolpro_result_access(schoolpro_results.student_id,schoolpro_results.term,schoolpro_results.session) a),false)) end);
create index if not exists schoolpro_lesson_notes_school_order_idx on public.schoolpro_lesson_notes(school_id,lesson_date desc,id);

