create or replace function private.schoolpro_set_result_access_exception(p_student uuid,p_term text,p_session text,p_allowed boolean,p_reason text)
returns void language plpgsql security definer set search_path='' as $$
declare s public.schoolpro_students;
begin
 select * into s from public.schoolpro_students where id=p_student;
 if auth.uid() is null or not private.schoolpro_module_allowed(s.school_id,'finance') or not private.has_school_access(s.school_id,array['proprietor','administrator']::public.school_member_role[]) then raise exception 'Only school leadership can manage result access';end if;
 if trim(p_term) not in('First Term','Second Term','Third Term') or trim(p_session)!~'^20[0-9]{2}/20[0-9]{2}$' or char_length(trim(p_reason))<3 or char_length(trim(p_reason))>1000 then raise exception 'Provide the academic period and a reason';end if;
 insert into public.schoolpro_result_access_overrides(school_id,student_id,term,session,allowed,reason,updated_by) values(s.school_id,s.id,trim(p_term),trim(p_session),p_allowed,trim(p_reason),auth.uid()) on conflict(student_id,term,session) do update set allowed=excluded.allowed,reason=excluded.reason,updated_by=excluded.updated_by,updated_at=now();
 insert into public.schoolpro_result_access_events(school_id,student_id,term,session,allowed,reason,changed_by) values(s.school_id,s.id,trim(p_term),trim(p_session),p_allowed,trim(p_reason),auth.uid());
end $$;
revoke all on function private.schoolpro_set_result_access_exception(uuid,text,text,boolean,text) from public,anon;
grant execute on function private.schoolpro_set_result_access_exception(uuid,text,text,boolean,text) to authenticated;
create or replace function public.schoolpro_set_result_access_exception(p_student uuid,p_term text,p_session text,p_allowed boolean,p_reason text) returns void language sql security invoker set search_path='' as $$ select private.schoolpro_set_result_access_exception(p_student,p_term,p_session,p_allowed,p_reason) $$;
revoke all on function public.schoolpro_set_result_access_exception(uuid,text,text,boolean,text) from public,anon;
grant execute on function public.schoolpro_set_result_access_exception(uuid,text,text,boolean,text) to authenticated;
create or replace function private.schoolpro_family_result_periods(p_student uuid)
returns table(term text,session text,allowed boolean,reason text) language plpgsql stable security definer set search_path='' as $$
begin
 if not private.schoolpro_can_read_student(p_student) then raise exception 'Student access is not available';end if;
 return query select distinct r.term,r.session,a.allowed,a.reason from public.schoolpro_results r cross join lateral private.schoolpro_result_access(r.student_id,r.term,r.session) a where r.student_id=p_student and r.status='published' and r.locked order by r.session desc,r.term;
end $$;
revoke all on function private.schoolpro_family_result_periods(uuid) from public,anon;
grant execute on function private.schoolpro_family_result_periods(uuid) to authenticated;
create or replace function public.schoolpro_family_result_periods(p_student uuid) returns table(term text,session text,allowed boolean,reason text) language sql security invoker set search_path='' as $$ select * from private.schoolpro_family_result_periods(p_student) $$;
revoke all on function public.schoolpro_family_result_periods(uuid) from public,anon;
grant execute on function public.schoolpro_family_result_periods(uuid) to authenticated;
