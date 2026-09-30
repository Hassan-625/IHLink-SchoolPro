CREATE OR REPLACE FUNCTION public.schoolpro_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS TABLE(student_id uuid, admission_number text, student_name text, total numeric, average numeric, subjects bigint, class_position bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$with x as(select s.id student_id,s.admission_number,s.first_name||' '||s.last_name student_name,coalesce(sum(r.total_score),0) total,coalesce(avg(r.total_score),0) average,count(r.id) subjects from public.schoolpro_students s left join public.schoolpro_results r on r.student_id=s.id and r.term=p_term and r.session=p_session where s.school_id=p_school and s.class_id=p_class group by s.id),y as(select x.*,dense_rank() over(order by total desc) class_position from x) select * from y where private.schoolpro_module_allowed(p_school,'reports') and private.schoolpro_module_allowed(p_school,'results') and (public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('teacher','class_teacher','exam_officer','head_teacher','vice_principal')) ) order by class_position,student_name$function$
;

