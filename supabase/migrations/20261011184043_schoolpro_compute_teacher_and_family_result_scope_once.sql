create or replace function private.schoolpro_cached_readable_students() returns uuid[] language sql stable security definer set search_path='' as $$
select coalesce(array_agg(s.id),array[]::uuid[]) from public.schoolpro_students s
where (select auth.uid()) is not null and (select private.is_active_account())
and s.school_id=any((select coalesce(array_agg(sc.id),array[]::uuid[]) from public.schoolpro_schools sc where private.schoolpro_operationally_active(sc.id))::uuid[])
and ((select private.is_admin(array['super_admin'::public.user_role])) or s.user_id=(select auth.uid())
or exists(select 1 from public.schoolpro_schools sc where sc.id=s.school_id and sc.owner_id=(select auth.uid()))
or exists(select 1 from public.schoolpro_guardian_links g where g.school_id=s.school_id and g.student_id=s.id and g.guardian_user_id=(select auth.uid()) and g.status='active')
or exists(select 1 from public.schoolpro_members m where m.school_id=s.school_id and m.user_id=(select auth.uid()) and (m.role::text not in('teacher','class_teacher','parent','student') or (m.role in('teacher','class_teacher') and (
exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=s.school_id and a.class_id=s.class_id and a.teacher_member_id=m.id)
or exists(select 1 from public.schoolpro_classes c where c.id=s.class_id and c.school_id=s.school_id and c.form_teacher_id=m.id)
or exists(select 1 from public.schoolpro_enrollment_history e join public.schoolpro_subject_assignments a on a.school_id=e.school_id and a.class_id=e.class_id and a.session=e.session where e.student_id=s.id and e.school_id=s.school_id and a.teacher_member_id=m.id)
or exists(select 1 from public.schoolpro_enrollment_history e join public.schoolpro_classes c on c.id=e.class_id and c.school_id=e.school_id where e.student_id=s.id and e.school_id=s.school_id and c.form_teacher_id=m.id)
)))))$$;
create or replace function private.schoolpro_cached_staff_schools() returns uuid[] language sql stable security definer set search_path='' as $$select coalesce(array_agg(sc.id),array[]::uuid[]) from public.schoolpro_schools sc where (select private.is_active_account()) and private.schoolpro_operationally_active(sc.id) and ((select private.is_admin(array['super_admin'::public.user_role])) or sc.owner_id=(select auth.uid()) or exists(select 1 from public.schoolpro_members m where m.school_id=sc.id and m.user_id=(select auth.uid()) and m.role::text not in('parent','student')))$$;
create or replace function private.schoolpro_cached_result_reader_keys() returns jsonb language sql stable security definer set search_path='' as $$
select coalesce(jsonb_object_agg(key,true),'{}'::jsonb) from(
 select s.id::text||'|family' key from public.schoolpro_students s where s.user_id=(select auth.uid()) or exists(select 1 from public.schoolpro_guardian_links g where g.school_id=s.school_id and g.student_id=s.id and g.guardian_user_id=(select auth.uid()) and g.status='active')
 union
 select s.id::text||'|'||a.subject_id::text||'|'||a.session from public.schoolpro_subject_assignments a join public.schoolpro_members m on m.id=a.teacher_member_id and m.school_id=a.school_id join public.schoolpro_students s on s.school_id=a.school_id left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=a.session where coalesce(e.class_id,s.class_id)=a.class_id and s.status in('active','graduated') and m.user_id=(select auth.uid()) and m.role in('teacher','class_teacher')
 union
 select s.id::text||'|*|'||coalesce(e.session,'*') from public.schoolpro_students s left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id join public.schoolpro_classes c on c.id=coalesce(e.class_id,s.class_id) and c.school_id=s.school_id join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id where m.user_id=(select auth.uid()) and m.role in('teacher','class_teacher')
) permitted where (select auth.uid()) is not null and (select private.is_active_account())$$;
revoke all on function private.schoolpro_cached_staff_schools(),private.schoolpro_cached_result_reader_keys() from public,anon;
grant execute on function private.schoolpro_cached_staff_schools(),private.schoolpro_cached_result_reader_keys() to authenticated,service_role;
alter policy "Result reader access" on public.schoolpro_results using(case when school_id=any((select private.schoolpro_cached_access_schools('results','result-leader'))::uuid[]) then true else student_id=any((select private.schoolpro_cached_readable_students())::uuid[]) and (
(select private.schoolpro_cached_result_reader_keys()) ? (student_id::text||'|'||subject_id::text||'|'||session)
or (select private.schoolpro_cached_result_reader_keys()) ? (student_id::text||'|*|'||session)
or (select private.schoolpro_cached_result_reader_keys()) ? (student_id::text||'|*|*')
or (status='published' and locked and (select private.schoolpro_cached_result_reader_keys()) ? (student_id::text||'|family'))
) end);
alter policy "Result access gate" on public.schoolpro_results using((select private.is_active_account()) and case when school_id=any((select private.schoolpro_cached_access_schools('results','result-leader'))::uuid[]) then true else student_id=any((select private.schoolpro_cached_readable_students())::uuid[]) and (school_id=any((select private.schoolpro_cached_staff_schools())::uuid[]) or coalesce((select a.allowed from private.schoolpro_result_access(student_id,term,session) a),false)) end);
