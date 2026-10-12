
create or replace function private.schoolpro_coordinator_classes(p_school uuid) returns uuid[]
language sql stable security definer set search_path='' as $$
select coalesce(array_agg(c.id),array[]::uuid[])
from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
where c.school_id=p_school and m.user_id=auth.uid() and m.role in('teacher','class_teacher')
and auth.uid() is not null and private.is_active_account() and private.schoolpro_operationally_active(p_school)
and private.schoolpro_module_allowed(p_school,'results')
$$;
revoke all on function private.schoolpro_coordinator_classes(uuid) from public,anon;
grant execute on function private.schoolpro_coordinator_classes(uuid) to authenticated;
create or replace function public.schoolpro_coordinator_classes(p_school uuid) returns uuid[]
language sql stable security invoker set search_path='' as $$ select private.schoolpro_coordinator_classes(p_school) $$;
revoke all on function public.schoolpro_coordinator_classes(uuid) from public,anon;
grant execute on function public.schoolpro_coordinator_classes(uuid) to authenticated;

create or replace function private.schoolpro_can_review_class(p_school uuid,p_class uuid) returns boolean
language sql stable security definer set search_path='' as $$
select auth.uid() is not null and private.is_active_account() and private.schoolpro_operationally_active(p_school)
and private.schoolpro_module_allowed(p_school,'results') and private.schoolpro_module_allowed(p_school,'reports')
and exists(select 1 from public.schoolpro_classes where id=p_class and school_id=p_school)
and (private.schoolpro_can_issue_transcript(p_school) or p_class=any(private.schoolpro_coordinator_classes(p_school)))
$$;
revoke all on function private.schoolpro_can_review_class(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_can_review_class(uuid,uuid) to authenticated;

create or replace function public.schoolpro_class_review_sheet(p_school uuid,p_class uuid,p_term text,p_session text) returns jsonb
language plpgsql stable security invoker set search_path='' as $$
declare output jsonb;
begin
 if not private.schoolpro_can_review_class(p_school,p_class) then raise exception 'Not authorized for this class';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Select a term and session';end if;
 with roster as (
 select s.id,s.admission_number,concat_ws(' ',s.first_name,s.last_name) name
 from public.schoolpro_students s join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id
 where e.school_id=p_school and e.class_id=p_class and e.session=trim(p_session)
 ), marks as (
 select r.* from public.schoolpro_results r join roster s on s.id=r.student_id
 where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
 ), totals as (
 select s.id student_id,s.admission_number,s.name student_name,coalesce(sum(m.total_score),0) total,coalesce(avg(m.total_score),0) average,count(m.id) subjects,
 coalesce(jsonb_object_agg(m.subject_id,m.total_score) filter(where m.id is not null),'{}') scores,
 count(m.id) filter(where m.status='draft') draft_scores,count(m.id) filter(where m.status='approved') approved_scores,count(m.id) filter(where m.status='published') published_scores
 from roster s left join marks m on m.student_id=s.id group by s.id,s.admission_number,s.name
 ), ranked as(select t.*,rank() over(order by average desc) class_position from totals t),
 subject_summary as(select su.id,su.name,su.code,avg(m.total_score) average,count(m.id) recorded from marks m join public.schoolpro_subjects su on su.id=m.subject_id and su.school_id=p_school group by su.id,su.name,su.code)
 select jsonb_build_object('rows',coalesce((select jsonb_agg(to_jsonb(r) order by r.class_position,r.student_name) from ranked r),'[]'),
 'subjects',coalesce((select jsonb_agg(to_jsonb(s) order by s.name) from subject_summary s),'[]'),'review',true) into output;
 return output;
end $$;
revoke all on function public.schoolpro_class_review_sheet(uuid,uuid,text,text) from public,anon;
grant execute on function public.schoolpro_class_review_sheet(uuid,uuid,text,text) to authenticated;
