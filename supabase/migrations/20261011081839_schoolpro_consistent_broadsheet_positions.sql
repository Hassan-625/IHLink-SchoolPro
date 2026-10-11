CREATE OR REPLACE FUNCTION public.schoolpro_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS TABLE(student_id uuid, admission_number text, student_name text, total numeric, average numeric, subjects bigint, class_position bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not private.schoolpro_module_allowed(p_school,'reports') or not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied';end if;
 if not(
   public.schoolpro_member_can_manage(p_school)
   or private.is_admin(array['super_admin'::public.user_role])
   or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role in('exam_officer'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role))
   or exists(
     select 1 from public.schoolpro_subject_assignments sa
     join public.schoolpro_members m on m.id=sa.teacher_member_id and m.school_id=sa.school_id
     where sa.school_id=p_school and sa.class_id=p_class and sa.session=trim(p_session)
       and m.user_id=auth.uid() and m.role in('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
   )
 ) then raise exception 'Not authorized for this class and session';end if;
 return query
 with x as(
  select s.id,s.admission_number,(s.first_name||' '||s.last_name)::text student_name,
   coalesce(sum(r.total_score),0)::numeric total,coalesce(avg(r.total_score),0)::numeric average,count(r.id)::bigint subjects
  from public.schoolpro_students s
  left join public.schoolpro_results r on r.student_id=s.id and r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published'::public.schoolpro_result_status
  where s.school_id=p_school and s.class_id=p_class and s.status='active'
  group by s.id,s.admission_number,s.first_name,s.last_name
 ),y as(select x.*,rank() over(order by x.total desc)::bigint pos from x)
 select y.id,y.admission_number,y.student_name,y.total,y.average,y.subjects,y.pos from y order by y.pos,y.student_name;
end $function$

