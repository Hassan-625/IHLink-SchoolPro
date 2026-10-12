
create or replace function private.schoolpro_enrollment_reader_keys() returns jsonb language sql stable security definer set search_path='' as $$
with leaders as materialized (
 select s.id from public.schoolpro_schools s
 where auth.uid() is not null and private.is_active_account() and private.schoolpro_operationally_active(s.id)
 and (private.is_admin(array['super_admin'::public.user_role])
 or (private.schoolpro_module_allowed(s.id,'students') and public.schoolpro_member_can_manage(s.id))
 or private.schoolpro_can_issue_transcript(s.id))
), readable as (
 select e.school_id::text||'|'||e.student_id::text||'|'||e.session key
 from public.schoolpro_enrollment_history e
 where auth.uid() is not null and private.is_active_account() and (
 e.school_id in(select id from leaders)
 or exists(select 1 from public.schoolpro_students s where s.id=e.student_id and s.school_id=e.school_id and s.user_id=auth.uid())
 or exists(select 1 from public.schoolpro_guardian_links g where g.school_id=e.school_id and g.student_id=e.student_id and g.guardian_user_id=auth.uid() and g.status='active')
 or exists(select 1 from public.schoolpro_members m where m.school_id=e.school_id and m.user_id=auth.uid() and m.role in('teacher','class_teacher') and
 (exists(select 1 from public.schoolpro_classes c where c.school_id=e.school_id and c.id=e.class_id and c.form_teacher_id=m.id)
 or exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=e.school_id and a.class_id=e.class_id and a.session=e.session and a.teacher_member_id=m.id)))
 ) and private.schoolpro_operationally_active(e.school_id)
)
select coalesce(jsonb_object_agg(key,true),'{}'::jsonb) from readable
$$;
revoke all on function private.schoolpro_enrollment_reader_keys() from public,anon;
grant execute on function private.schoolpro_enrollment_reader_keys() to authenticated;
alter policy "Authorized school enrollment history" on public.schoolpro_enrollment_history using (
 (select private.schoolpro_enrollment_reader_keys()) ? (school_id::text||'|'||student_id::text||'|'||session)
);
drop policy "Examination leadership enrollment history" on public.schoolpro_enrollment_history;

create or replace function private.schoolpro_class_staff_directory(p_school uuid)
returns table(id uuid,user_id uuid,role text,name text)
language sql stable security definer set search_path='' as $$
 select m.id,m.user_id,m.role::text,
 coalesce(nullif(trim(concat_ws(' ',p.first_name,p.last_name)),''),'Staff member')
 from public.schoolpro_members m join public.profiles p on p.id=m.user_id
 where m.school_id=p_school and auth.uid() is not null and private.is_active_account()
 and private.schoolpro_operationally_active(p_school) and private.has_school_access(p_school)
 and (private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
 or m.user_id=auth.uid()
 or exists(select 1 from public.schoolpro_classes c where c.school_id=p_school and private.schoolpro_can_read_class(c.id) and
 (c.form_teacher_id=m.id or exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=p_school and a.class_id=c.id and a.teacher_member_id=m.id))))
$$;
revoke all on function private.schoolpro_class_staff_directory(uuid) from public,anon;
grant execute on function private.schoolpro_class_staff_directory(uuid) to authenticated;
create or replace function public.schoolpro_class_staff_directory(p_school uuid)
returns table(id uuid,user_id uuid,role text,name text)
language sql stable security invoker set search_path='' as $$ select * from private.schoolpro_class_staff_directory(p_school) $$;
revoke all on function public.schoolpro_class_staff_directory(uuid) from public,anon;
grant execute on function public.schoolpro_class_staff_directory(uuid) to authenticated;

create or replace function private.schoolpro_can_write_result(p_school uuid,p_student uuid,p_subject uuid,p_session text)
returns boolean language sql stable security definer set search_path='' as $$
select auth.uid() is not null and private.is_active_account() and private.schoolpro_module_allowed(p_school,'results')
and exists(select 1 from public.schoolpro_students s where s.id=p_student and s.school_id=p_school)
and exists(select 1 from public.schoolpro_subjects sub where sub.id=p_subject and sub.school_id=p_school)
and (
private.has_school_access(p_school,array['proprietor','administrator','head_teacher','vice_principal','exam_officer']::public.school_member_role[])
or exists(select 1 from public.schoolpro_students st
join public.schoolpro_members m on m.school_id=p_school and m.user_id=auth.uid() and m.role in('teacher','class_teacher')
left join public.schoolpro_enrollment_history e on e.school_id=p_school and e.student_id=st.id and e.session=p_session
where st.id=p_student and st.school_id=p_school and st.status='active' and
(exists(select 1 from public.schoolpro_classes c where c.id=coalesce(e.class_id,st.class_id) and c.school_id=p_school and c.form_teacher_id=m.id)
or exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=p_school and a.class_id=coalesce(e.class_id,st.class_id) and a.teacher_member_id=m.id and a.subject_id=p_subject and trim(a.session)=trim(p_session))))
)
$$;
revoke all on function private.schoolpro_can_write_result(uuid,uuid,uuid,text) from public,anon;
grant execute on function private.schoolpro_can_write_result(uuid,uuid,uuid,text) to authenticated;
