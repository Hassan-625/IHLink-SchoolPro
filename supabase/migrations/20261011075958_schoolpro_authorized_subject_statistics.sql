create or replace function private.schoolpro_subject_statistics(p_student uuid,p_term text,p_session text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare pupil public.schoolpro_students;terms text[]:=array['First Term','Second Term','Third Term'];idx integer;answer jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 idx:=array_position(terms,trim(p_term));if idx is null then raise exception 'Choose a valid term';end if;
 select * into pupil from public.schoolpro_students where id=p_student;
 if pupil.id is null then raise exception 'Student not found';end if;
 perform 1 from public.schoolpro_printable_result(p_student,trim(p_term),trim(p_session));
 if not found then raise exception 'No authorised published result';end if;
 -- The output contains only this pupil's released marks and aggregate class statistics.
 with own as(
  select r.subject_id,max(r.total_score)filter(where r.term='First Term')first_term,
  max(r.total_score)filter(where r.term='Second Term')second_term,
  max(r.total_score)filter(where r.term='Third Term')third_term,
  case when count(*)=idx then avg(r.total_score)else null end cumulative_average
  from public.schoolpro_results r where r.school_id=pupil.school_id and r.student_id=pupil.id
  and r.session=trim(p_session) and r.status='published' and r.locked and r.term=any(terms[1:idx])
  and public.schoolpro_can_view_result_output(pupil.id,r.term,r.session) group by r.subject_id
 ),class_marks as(
  select r.subject_id,r.student_id,count(*)term_count,avg(r.total_score)average,
  max(r.total_score)filter(where r.term=trim(p_term))current_score
  from public.schoolpro_results r join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
  where s.school_id=pupil.school_id and s.class_id=pupil.class_id and s.status='active'
  and r.session=trim(p_session) and r.status='published' and r.locked and r.term=any(terms[1:idx])
  group by r.subject_id,r.student_id
 )select coalesce(jsonb_object_agg(o.subject_id,jsonb_build_object('first_term',o.first_term,'second_term',o.second_term,'third_term',o.third_term,'cumulative_average',round(o.cumulative_average,2),
  'subject_position',case when o.cumulative_average is not null then 1+(select count(*)from class_marks m where m.subject_id=o.subject_id and m.term_count=idx and m.average>o.cumulative_average)else null end,
  'subject_class_average',(select round(avg(m.average),2)from class_marks m where m.subject_id=o.subject_id and m.term_count=idx),
  'current_position',1+(select count(*)from class_marks m where m.subject_id=o.subject_id and m.current_score>(select r.total_score from public.schoolpro_results r where r.student_id=pupil.id and r.subject_id=o.subject_id and r.term=trim(p_term)and r.session=trim(p_session))),
  'current_class_average',(select round(avg(m.current_score),2)from class_marks m where m.subject_id=o.subject_id))), '{}'::jsonb)into answer from own o;
 return answer;
end $$;
create or replace function public.schoolpro_subject_statistics(p_student uuid,p_term text,p_session text)
returns jsonb language sql stable security invoker set search_path='' as $$ select private.schoolpro_subject_statistics(p_student,p_term,p_session) $$;
revoke all on function private.schoolpro_subject_statistics(uuid,text,text),public.schoolpro_subject_statistics(uuid,text,text) from public,anon;
grant execute on function private.schoolpro_subject_statistics(uuid,text,text),public.schoolpro_subject_statistics(uuid,text,text) to authenticated,service_role;
