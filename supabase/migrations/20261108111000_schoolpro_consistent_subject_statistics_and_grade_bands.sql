-- Keep published subject statistics honest when a subject has no current-term result.
-- Also make active grade-band non-overlap a database invariant, not only a UI check.

create or replace function private.schoolpro_subject_statistics(p_student uuid,p_term text,p_session text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $function$
declare
 pupil public.schoolpro_students;
 v_class uuid;
 terms text[]:=array['First Term','Second Term','Third Term'];
 idx integer;
 answer jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 idx:=array_position(terms,trim(p_term));
 if idx is null then raise exception 'Choose a valid term';end if;
 select * into pupil from public.schoolpro_students where id=p_student;
 if pupil.id is null then raise exception 'Student not found';end if;
 select coalesce((select e.class_id from public.schoolpro_enrollment_history e
  where e.student_id=pupil.id and e.school_id=pupil.school_id and e.session=trim(p_session)),pupil.class_id)
 into v_class;
 perform 1 from public.schoolpro_printable_result(p_student,trim(p_term),trim(p_session));
 if not found then raise exception 'No authorised published result';end if;

 -- Every aggregate includes only published, locked marks. Missing subject/term marks
 -- are NULL, never synthesized as zero. The unique result key guarantees one row per
 -- student/subject/term/session, so count(*)=idx means all terms through this term exist.
 with own as(
  select r.subject_id,
   max(r.total_score) filter(where r.term='First Term') first_term,
   max(r.total_score) filter(where r.term='Second Term') second_term,
   max(r.total_score) filter(where r.term='Third Term') third_term,
   max(r.total_score) filter(where r.term=trim(p_term)) current_score,
   case when count(*)=idx then avg(r.total_score) else null end cumulative_average
  from public.schoolpro_results r
  where r.school_id=pupil.school_id and r.student_id=pupil.id
   and r.session=trim(p_session) and r.status='published' and r.locked
   and r.term=any(terms[1:idx])
   and public.schoolpro_can_view_result_output(pupil.id,r.term,r.session)
  group by r.subject_id
 ),class_marks as(
  select r.subject_id,r.student_id,count(*) term_count,avg(r.total_score) average,
   max(r.total_score) filter(where r.term=trim(p_term)) current_score
  from public.schoolpro_results r
  join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id
  left join lateral (select h.class_id,true has_history from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id and h.session=trim(p_session) limit 1) e on true
  where s.school_id=pupil.school_id and case when e.has_history is true then e.class_id else s.class_id end=v_class
   and (e.has_history is true or (s.status='active' and not exists(
    select 1 from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id and h.session=trim(p_session))))
   and r.session=trim(p_session) and r.status='published' and r.locked and r.term=any(terms[1:idx])
  group by r.subject_id,r.student_id
 )
 select coalesce(jsonb_object_agg(o.subject_id,jsonb_build_object(
  'first_term',o.first_term,'second_term',o.second_term,'third_term',o.third_term,
  'cumulative_average',round(o.cumulative_average,2),
  'subject_position',case when o.cumulative_average is not null then
   1+(select count(*) from class_marks m where m.subject_id=o.subject_id and m.term_count=idx and m.average>o.cumulative_average)
   else null end,
  'subject_class_average',(select round(avg(m.average),2) from class_marks m where m.subject_id=o.subject_id and m.term_count=idx),
  'current_position',case when o.current_score is not null then
   1+(select count(*) from class_marks m where m.subject_id=o.subject_id and m.current_score>o.current_score)
   else null end,
  'current_class_average',(select round(avg(m.current_score),2) from class_marks m where m.subject_id=o.subject_id)
  )),'{}'::jsonb)
 into answer from own o;
 return answer;
end
$function$;

create or replace function private.schoolpro_guard_grade_scale_overlap()
returns trigger
language plpgsql
set search_path=''
as $function$
begin
 perform pg_advisory_xact_lock(hashtextextended(new.school_id::text,0));
 if new.is_active and exists(
  select 1 from public.schoolpro_grade_scale g
  where g.school_id=new.school_id and g.is_active
   and g.id is distinct from new.id
   and g.min_score<=new.max_score and g.max_score>=new.min_score
 ) then
  raise exception 'Active grade ranges cannot overlap'
   using errcode='23P01';
 end if;
 return new;
end
$function$;

drop trigger if exists schoolpro_grade_scale_no_overlap on public.schoolpro_grade_scale;
create trigger schoolpro_grade_scale_no_overlap
before insert or update of school_id,min_score,max_score,is_active
on public.schoolpro_grade_scale
for each row execute function private.schoolpro_guard_grade_scale_overlap();

revoke all on function private.schoolpro_guard_grade_scale_overlap() from public,anon,authenticated;
