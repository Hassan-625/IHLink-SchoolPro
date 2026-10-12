CREATE OR REPLACE FUNCTION public.schoolpro_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS TABLE(student_id uuid, admission_number text, student_name text, total numeric, average numeric, subjects bigint, class_position bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not private.schoolpro_module_allowed(p_school,'reports') or not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied';end if;
 if not(private.schoolpro_can_review_class(p_school,p_class)) then raise exception 'Not authorized for this class and session';end if;
 return query
 with x as(
  select s.id,s.admission_number,(s.first_name||' '||s.last_name)::text student_name,
   coalesce(sum(r.total_score),0)::numeric total,coalesce(avg(r.total_score),0)::numeric average,count(r.id)::bigint subjects
  from public.schoolpro_students s left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session)
  left join public.schoolpro_results r on r.student_id=s.id and r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published'::public.schoolpro_result_status
  where s.school_id=p_school and coalesce(e.class_id,s.class_id)=p_class and (e.student_id is not null or (s.status='active' and not exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=s.school_id and h.student_id=s.id)))
  group by s.id,s.admission_number,s.first_name,s.last_name
 ),y as(select x.*,rank() over(order by x.total desc)::bigint pos from x)
 select y.id,y.admission_number,y.student_name,y.total,y.average,y.subjects,y.pos from y order by y.pos,y.student_name;
end $function$
