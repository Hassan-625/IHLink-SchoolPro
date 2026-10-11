create or replace function public.schoolpro_printable_result(p_student uuid,p_term text,p_session text)
returns setof public.schoolpro_results language plpgsql stable security invoker set search_path='' as $function$
declare v_allowed boolean;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Choose a term and session first';end if;
 if not exists(select 1 from public.schoolpro_students s where s.id=p_student) then raise exception 'Student not found';end if;
 select a.allowed into v_allowed from public.schoolpro_result_access(p_student,trim(p_term),trim(p_session))a limit 1;
 if not coalesce(v_allowed,false) then raise exception 'Result output is not available';end if;
 -- The caller's existing row policies enforce school, class/subject and family scope.
 -- Graduation and transfer-out preserve authorised historical results.
 return query select r.* from public.schoolpro_results r where r.student_id=p_student and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published' and r.locked=true order by r.created_at,r.id;
end $function$;
revoke all on function public.schoolpro_printable_result(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_printable_result(uuid,text,text) to authenticated;