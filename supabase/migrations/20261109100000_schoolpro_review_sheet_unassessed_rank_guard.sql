-- Staff review sheets retain the full roster but only learners with at least one
-- recorded subject result participate in class-position ranking.
create or replace function public.schoolpro_class_review_sheet(p_school uuid,p_class uuid,p_term text,p_session text) returns jsonb
language plpgsql stable security invoker set search_path='' as $$
declare output jsonb;
begin
 if not private.schoolpro_can_review_class(p_school,p_class) then raise exception 'Not authorized for this class';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Select a term and session';end if;
 with roster as (
  select s.id,s.admission_number,concat_ws(' ',s.first_name,s.last_name) name
  from public.schoolpro_students s
  left join lateral (select h.class_id,true has_history from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id and h.session=trim(p_session) limit 1) e on true
  where s.school_id=p_school and case when e.has_history is true then e.class_id else s.class_id end=p_class
    and (e.has_history is true or (s.status='active' and not exists(
      select 1 from public.schoolpro_enrollment_history h where h.school_id=s.school_id and h.student_id=s.id and h.session=trim(p_session)
    )))
 ), marks as (
  select r.* from public.schoolpro_results r join roster s on s.id=r.student_id
  where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
 ), totals as (
  select s.id student_id,s.admission_number,s.name,coalesce(sum(m.total_score),0) total,coalesce(avg(m.total_score),0) average,count(m.id) subjects,
  coalesce(jsonb_object_agg(m.subject_id,m.total_score) filter(where m.id is not null),'{}') scores,
  count(m.id) filter(where m.status='draft') draft_scores,count(m.id) filter(where m.status='approved') approved_scores,count(m.id) filter(where m.status='published') published_scores
  from roster s left join marks m on m.student_id=s.id group by s.id,s.admission_number,s.name
 ), ranked as(
  select t.*,
   case when subjects>0 then rank() over(order by case when subjects>0 then total end desc nulls last)::bigint
        else null::bigint end class_position
  from totals t
 ), subject_summary as(
  select su.id,su.name,su.code,avg(m.total_score) average,count(m.id) recorded
  from marks m join public.schoolpro_subjects su on su.id=m.subject_id and su.school_id=p_school
  group by su.id,su.name,su.code
 )
 select jsonb_build_object(
  'rows',coalesce((select jsonb_agg(to_jsonb(r) order by r.class_position nulls last,r.student_name) from ranked r),'[]'),
  'subjects',coalesce((select jsonb_agg(to_jsonb(s) order by s.name) from subject_summary s),'[]'),
  'review',true
 ) into output;
 return output;
end $$;
revoke all on function public.schoolpro_class_review_sheet(uuid,uuid,text,text) from public,anon;
grant execute on function public.schoolpro_class_review_sheet(uuid,uuid,text,text) to authenticated;
