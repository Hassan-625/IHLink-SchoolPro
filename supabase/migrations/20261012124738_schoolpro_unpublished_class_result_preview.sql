create or replace function public.schoolpro_review_result(p_student uuid,p_term text,p_session text)
returns setof public.schoolpro_results language plpgsql stable security invoker set search_path='' as $$
declare v_school uuid;v_class uuid;
begin
 select s.school_id,e.class_id into v_school,v_class from public.schoolpro_students s join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session) where s.id=p_student;
 if v_school is null or not private.schoolpro_can_review_class(v_school,v_class) then raise exception 'Not authorized for this class result';end if;
 return query select r.* from public.schoolpro_results r where r.school_id=v_school and r.student_id=p_student and r.term=trim(p_term) and r.session=trim(p_session) order by r.created_at,r.id;
end $$;
revoke all on function public.schoolpro_review_result(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_review_result(uuid,text,text) to authenticated;