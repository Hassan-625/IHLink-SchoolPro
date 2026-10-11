CREATE OR REPLACE FUNCTION public.schoolpro_result_class_rank(p_student_id uuid, p_term text, p_session text)
 RETURNS TABLE(class_population bigint, class_position bigint, total_score numeric, average_score numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_school uuid;v_class uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select s.school_id,coalesce(e.class_id,s.class_id) into v_school,v_class from public.schoolpro_students s left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session) where s.id=p_student_id;
 if v_school is null or v_class is null then raise exception 'Student or class not found';end if;
 if not(
  private.is_admin(array['super_admin'::public.user_role])
  or private.has_school_access(v_school,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'exam_officer'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role])
  or exists(select 1 from public.schoolpro_subject_assignments sa join public.schoolpro_members m on m.id=sa.teacher_member_id and m.school_id=sa.school_id where sa.school_id=v_school and sa.class_id=v_class and sa.session=trim(p_session) and m.user_id=auth.uid() and m.role in('teacher'::public.school_member_role,'class_teacher'::public.school_member_role))
  or exists(select 1 from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id where c.id=v_class and c.school_id=v_school and m.user_id=auth.uid() and m.role in('teacher','class_teacher'))
  or exists(select 1 from public.schoolpro_students s where s.id=p_student_id and s.user_id=auth.uid())
  or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=p_student_id and g.guardian_user_id=auth.uid() and g.status='active')
 ) then raise exception 'Not authorized for this result ranking';end if;
 if (exists(select 1 from public.schoolpro_students s where s.id=p_student_id and s.user_id=auth.uid()) or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=p_student_id and g.guardian_user_id=auth.uid() and g.status='active'))
 and not public.schoolpro_can_view_result_output(p_student_id,trim(p_term),trim(p_session)) then raise exception 'Published result output is not available';end if;
 return query with totals as(
  select s.id,coalesce(sum(r.total_score),0)::numeric total,case when count(r.id)>0 then avg(r.total_score)::numeric else 0::numeric end avg_score
  from public.schoolpro_students s left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session) left join public.schoolpro_results r on r.student_id=s.id and r.school_id=v_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published'::public.schoolpro_result_status
  where s.school_id=v_school and coalesce(e.class_id,s.class_id)=v_class and (e.student_id is not null or (s.status='active' and not exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id))) group by s.id
 ),ranked as(select id,total,avg_score,rank() over(order by total desc)::bigint pos,count(*) over()::bigint pop from totals)
 select pop,pos,total,avg_score from ranked where id=p_student_id;
end $function$;
CREATE OR REPLACE FUNCTION private.schoolpro_subject_statistics(p_student uuid, p_term text, p_session text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare pupil public.schoolpro_students;v_class uuid;terms text[]:=array['First Term','Second Term','Third Term'];idx integer;answer jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 idx:=array_position(terms,trim(p_term));if idx is null then raise exception 'Choose a valid term';end if;
 select * into pupil from public.schoolpro_students where id=p_student;
 if pupil.id is null then raise exception 'Student not found';end if;
 select coalesce((select e.class_id from public.schoolpro_enrollment_history e where e.student_id=pupil.id and e.school_id=pupil.school_id and e.session=trim(p_session)),pupil.class_id) into v_class;
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
  from public.schoolpro_results r join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session)
  where s.school_id=pupil.school_id and coalesce(e.class_id,s.class_id)=v_class and (e.student_id is not null or (s.status='active' and not exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id)))
  and r.session=trim(p_session) and r.status='published' and r.locked and r.term=any(terms[1:idx])
  group by r.subject_id,r.student_id
 )select coalesce(jsonb_object_agg(o.subject_id,jsonb_build_object('first_term',o.first_term,'second_term',o.second_term,'third_term',o.third_term,'cumulative_average',round(o.cumulative_average,2),
  'subject_position',case when o.cumulative_average is not null then 1+(select count(*)from class_marks m where m.subject_id=o.subject_id and m.term_count=idx and m.average>o.cumulative_average)else null end,
  'subject_class_average',(select round(avg(m.average),2)from class_marks m where m.subject_id=o.subject_id and m.term_count=idx),
  'current_position',1+(select count(*)from class_marks m where m.subject_id=o.subject_id and m.current_score>(select r.total_score from public.schoolpro_results r where r.student_id=pupil.id and r.subject_id=o.subject_id and r.term=trim(p_term)and r.session=trim(p_session))),
  'current_class_average',(select round(avg(m.current_score),2)from class_marks m where m.subject_id=o.subject_id))), '{}'::jsonb)into answer from own o;
 return answer;
end $function$;
CREATE OR REPLACE FUNCTION private.schoolpro_report_details(p_student uuid, p_term text, p_session text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_students; ts public.schoolpro_result_term_settings; count_results integer; result jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select count(*) into count_results from public.schoolpro_printable_result(p_student,p_term,p_session);
 if count_results=0 then raise exception 'No published results available';end if;
 select * into s from public.schoolpro_students where id=p_student;
 select * into ts from public.schoolpro_result_term_settings where school_id=s.school_id and term=trim(p_term) and session=trim(p_session);
 select jsonb_build_object(
 'class_name',coalesce((select concat_ws(' ',e.class_name,nullif(e.arm,'')) from public.schoolpro_enrollment_history e where e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session)),s.class_name),
 'subject_names',(select jsonb_object_agg(sub.id,sub.name) from public.schoolpro_subjects sub join public.schoolpro_results rr on rr.subject_id=sub.id where rr.student_id=s.id and rr.term=trim(p_term) and rr.session=trim(p_session) and rr.status='published'),'settings',to_jsonb(ts),'gender',s.gender,'date_of_birth',s.date_of_birth,'photo_storage_path',s.photo_storage_path,
 'domains',coalesce((select jsonb_agg(jsonb_build_object('type',d.domain_type,'name',d.name,'rating',coalesce(r.rating_label,r.rating::text)) order by d.domain_type,d.position) from public.schoolpro_result_domain_definitions d left join public.schoolpro_result_domain_ratings r on r.definition_id=d.id and r.school_id=s.school_id and r.student_id=s.id and r.term=trim(p_term) and r.session=trim(p_session) where d.school_id=s.school_id and d.is_active),'[]'::jsonb),
 'rating_scale',coalesce((select jsonb_agg(jsonb_build_object('rating',rating,'description',description) order by position) from public.schoolpro_result_rating_scale where school_id=s.school_id),'[]'::jsonb),
 'grade_scale',coalesce((select jsonb_agg(jsonb_build_object('label',label,'min_score',min_score,'max_score',max_score,'remark',remark,'overall_remark',overall_remark) order by position) from public.schoolpro_grade_scale where school_id=s.school_id and is_active),'[]'::jsonb),
 'attendance',case when ts.term_start_date is not null and ts.term_end_date is not null then (select jsonb_build_object('present',count(*) filter(where status::text='present'),'absent',count(*) filter(where status::text='absent'),'leave',count(*) filter(where status::text in ('leave','excused')),'recorded',count(*)) from public.schoolpro_attendance where student_id=s.id and attendance_date between ts.term_start_date and ts.term_end_date) else null end,
 'rank',(select to_jsonb(r) from public.schoolpro_result_class_rank(s.id,p_term,p_session) r limit 1),
 'logo_storage_path',(select logo_storage_path from public.schoolpro_result_templates where school_id=s.school_id limit 1)
 ) into result;return result;
end $function$
;