-- Align every published class-rank calculation with the report-card release boundary.
-- Draft/approved/unlocked rows remain available to authorised staff review, but never affect
-- published positions or published broadsheet totals.
create or replace function public.schoolpro_result_class_rank(p_student_id uuid,p_term text,p_session text)
returns table(class_population bigint,class_position bigint,total_score numeric,average_score numeric)
language plpgsql security definer set search_path='' as $function$
declare v_school uuid;v_class uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select s.school_id,case when e.has_history is true then e.class_id else s.class_id end into v_school,v_class from public.schoolpro_students s
 left join lateral (select h.class_id,true has_history from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id and h.session=trim(p_session) limit 1) e on true where s.id=p_student_id;
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
  from public.schoolpro_students s
  left join lateral (select h.class_id,true has_history from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id and h.session=trim(p_session) limit 1) e on true
  left join public.schoolpro_results r on r.student_id=s.id and r.school_id=v_school and r.term=trim(p_term) and r.session=trim(p_session)
   and r.status='published'::public.schoolpro_result_status and r.locked=true
  where s.school_id=v_school and case when e.has_history is true then e.class_id else s.class_id end=v_class
   and (e.has_history is true or (s.status='active' and not exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id and h.session=trim(p_session))))
  group by s.id
 ),ranked as(select id,total,avg_score,rank() over(order by total desc)::bigint pos,count(*) over()::bigint pop from totals)
 select pop,pos,total,avg_score from ranked where id=p_student_id;
end $function$;
create or replace function public.schoolpro_broadsheet(p_school uuid,p_class uuid,p_term text,p_session text)
returns table(student_id uuid,admission_number text,student_name text,total numeric,average numeric,subjects bigint,class_position bigint)
language plpgsql stable security definer set search_path='' as $function$
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not private.schoolpro_module_allowed(p_school,'reports') or not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied';end if;
 if not private.schoolpro_can_review_class(p_school,p_class) then raise exception 'Not authorized for this class and session';end if;
 return query with x as(
  select s.id,s.admission_number,(s.first_name||' '||s.last_name)::text student_name,
   coalesce(sum(r.total_score),0)::numeric total,coalesce(avg(r.total_score),0)::numeric average,count(r.id)::bigint subjects
  from public.schoolpro_students s
  left join lateral (select h.class_id,true has_history from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id and h.session=trim(p_session) limit 1) e on true
  left join public.schoolpro_results r on r.student_id=s.id and r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
   and r.status='published'::public.schoolpro_result_status and r.locked=true
  where s.school_id=p_school and case when e.has_history is true then e.class_id else s.class_id end=p_class
   and (e.has_history is true or (s.status='active' and not exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=s.school_id and h.student_id=s.id and h.session=trim(p_session))))
  group by s.id,s.admission_number,s.first_name,s.last_name
 ),y as(select x.*,rank() over(order by x.total desc)::bigint pos from x)
 select y.id,y.admission_number,y.student_name,y.total,y.average,y.subjects,y.pos from y order by y.pos,y.student_name;
end $function$;
