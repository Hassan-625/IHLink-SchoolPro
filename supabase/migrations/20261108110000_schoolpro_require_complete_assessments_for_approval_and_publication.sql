-- Prevent incomplete assessment records from crossing approval or publication boundaries.
-- Draft component-by-component entry remains supported; completeness is required only for release.

create or replace function private.schoolpro_result_assessment_complete(p_result uuid)
returns boolean
language plpgsql
stable
security invoker
set search_path=''
as $function$
declare
 r public.schoolpro_results;
 configured jsonb;
 component jsonb;
 component_key text;
 score_value numeric;
 max_value numeric;
 calculated_total numeric:=0;
 configured_count integer;
 distinct_key_count integer;
begin
 select * into r from public.schoolpro_results where id=p_result;
 if not found or r.assessment_scheme_id is null then return false;end if;
 if r.assessment_scores is null or jsonb_typeof(r.assessment_scores)<>'object' then return false;end if;
 select a.components into configured from public.schoolpro_assessment_schemes a
 where a.id=r.assessment_scheme_id and a.school_id=r.school_id;
 if not found or configured is null or jsonb_typeof(configured)<>'array' or jsonb_array_length(configured)=0 then return false;end if;
 select count(*),count(distinct value->>'key') into configured_count,distinct_key_count
 from jsonb_array_elements(configured);
 if configured_count<>distinct_key_count then return false;end if;
 for component in select value from jsonb_array_elements(configured) loop
  component_key:=component->>'key';
  if nullif(trim(component_key),'') is null or jsonb_typeof(component->'maxScore')<>'number' then return false;end if;
  if not (r.assessment_scores ? component_key) or jsonb_typeof(r.assessment_scores->component_key)<>'number' then return false;end if;
  score_value:=(r.assessment_scores->>component_key)::numeric;
  max_value:=(component->>'maxScore')::numeric;
  if max_value<0 or score_value<0 or score_value>max_value then return false;end if;
  calculated_total:=calculated_total+score_value;
 end loop;
 if exists(select 1 from jsonb_object_keys(r.assessment_scores) supplied(key)
   where not exists(select 1 from jsonb_array_elements(configured) c(value) where c.value->>'key'=supplied.key)) then return false;end if;
 return r.total_score=calculated_total;
exception when others then
 return false;
end
$function$;
revoke all on function private.schoolpro_result_assessment_complete(uuid) from public,anon,authenticated;

create or replace function public.review_schoolpro_result(p_result uuid,p_status text,p_notes text default null)
returns void
language plpgsql
security definer
set search_path=''
as $function$
declare r public.schoolpro_results;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into r from public.schoolpro_results where id=p_result for update;
 if r.id is null then raise exception 'Result not found';end if;
 if not private.schoolpro_module_allowed(r.school_id,'results') then raise exception 'Module permission denied: results';end if;
 if p_status not in('approved','rejected') then raise exception 'Invalid review status';end if;
 if r.status='published' then raise exception 'Published results cannot be reviewed; unlock and use the controlled correction workflow';end if;
 if r.locked then raise exception 'Locked results cannot be reviewed';end if;
 if not(public.schoolpro_member_can_manage(r.school_id) or exists(
   select 1 from public.schoolpro_members m where m.school_id=r.school_id and m.user_id=auth.uid()
    and m.role::text in('exam_officer','head_teacher','vice_principal')
 )) then raise exception 'Not authorized';end if;
 if p_status='approved' and not private.schoolpro_result_assessment_complete(r.id) then
  raise exception 'Incomplete assessment: enter a valid score for every configured component before approval';
 end if;
 insert into public.schoolpro_result_approvals(school_id,result_id,status,reviewed_by,reviewed_at,notes)
 values(r.school_id,r.id,p_status,auth.uid(),now(),p_notes)
 on conflict(result_id) do update set status=excluded.status,reviewed_by=excluded.reviewed_by,reviewed_at=excluded.reviewed_at,notes=excluded.notes;
 update public.schoolpro_results set status=case when p_status='approved' then 'approved'::public.schoolpro_result_status else 'draft'::public.schoolpro_result_status end,
  approved_by=case when p_status='approved' then auth.uid() else null end,
  approved_at=case when p_status='approved' then now() else null end,published_at=null where id=r.id;
end
$function$;
revoke all on function public.review_schoolpro_result(uuid,text,text) from public,anon;
grant execute on function public.review_schoolpro_result(uuid,text,text) to authenticated;

create or replace function public.publish_schoolpro_class_results(p_school uuid,p_class uuid,p_term text,p_session text)
returns integer
language plpgsql
security definer
set search_path=''
as $function$
declare n integer;
begin
 if auth.uid() is null or not coalesce(private.schoolpro_module_allowed(p_school,'results'),false)
  or not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then
  raise exception 'Result publication permission required';
 end if;
 if not exists(select 1 from public.schoolpro_classes where id=p_class and school_id=p_school) then raise exception 'Select a class in this school';end if;
 perform r.id from public.schoolpro_results r where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='approved' and not r.locked
  and exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=r.student_id and h.class_id=p_class and h.session=r.session and h.school_id=p_school)
  for update;
 if exists(select 1 from public.schoolpro_results r where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='approved' and not r.locked
  and exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=r.student_id and h.class_id=p_class and h.session=r.session and h.school_id=p_school)
  and not private.schoolpro_result_assessment_complete(r.id)) then
  raise exception 'Class contains incomplete approved assessments; return them for correction before publication';
 end if;
 update public.schoolpro_results r set status='published',published_at=now(),locked=true
 where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='approved' and not r.locked
  and exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=r.student_id and h.class_id=p_class and h.session=r.session and h.school_id=p_school);
 get diagnostics n=row_count;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
 values(auth.uid(),'Class results published','schoolpro','class',p_class::text,jsonb_build_object('school_id',p_school,'term',p_term,'session',p_session,'published',n));
 return n;
end
$function$;
revoke all on function public.publish_schoolpro_class_results(uuid,uuid,text,text) from public,anon;
grant execute on function public.publish_schoolpro_class_results(uuid,uuid,text,text) to authenticated;

create or replace function public.publish_schoolpro_selected_results(p_school uuid,p_term text,p_session text,p_students uuid[] default null,p_all boolean default false)
returns integer
language plpgsql
security definer
set search_path=''
as $function$
declare n integer;
begin
 if auth.uid() is null or not coalesce(private.schoolpro_module_allowed(p_school,'results'),false)
  or not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then
  raise exception 'Result publication permission required';
 end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Select an academic period';end if;
 if p_all then
  if coalesce(cardinality(p_students),0)>0 then raise exception 'Choose one publication scope';end if;
 else
  if coalesce(cardinality(p_students),0)=0 then raise exception 'Select students to publish';end if;
  if exists(select 1 from unnest(p_students) x(id) where x.id is null or not exists(select 1 from public.schoolpro_students s where s.id=x.id and s.school_id=p_school and (s.status='active' or exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session))))) then
   raise exception 'Select students enrolled in this school during the selected session';
  end if;
 end if;
 perform r.id from public.schoolpro_results r where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='approved' and not r.locked
  and exists(select 1 from public.schoolpro_students s where s.id=r.student_id and s.school_id=p_school
   and (s.status='active' or exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school and h.student_id=s.id and h.session=r.session))
   and (p_all or s.id=any(p_students)))
  for update;
 if exists(select 1 from public.schoolpro_results r where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='approved' and not r.locked
  and exists(select 1 from public.schoolpro_students s where s.id=r.student_id and s.school_id=p_school
   and (s.status='active' or exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school and h.student_id=s.id and h.session=r.session))
   and (p_all or s.id=any(p_students)))
  and not private.schoolpro_result_assessment_complete(r.id)) then
  raise exception 'Selected students contain incomplete approved assessments; return them for correction before publication';
 end if;
 update public.schoolpro_results r set status='published',published_at=now(),locked=true
 where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='approved' and not r.locked
  and exists(select 1 from public.schoolpro_students s where s.id=r.student_id and s.school_id=p_school
   and (s.status='active' or exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school and h.student_id=s.id and h.session=r.session))
   and (p_all or s.id=any(p_students)));
 get diagnostics n=row_count;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
 values(auth.uid(),'Selected results published','schoolpro','school',p_school::text,jsonb_build_object('term',p_term,'session',p_session,'all_students',p_all,'students',p_students,'published',n));
 return n;
end
$function$;
revoke all on function public.publish_schoolpro_selected_results(uuid,text,text,uuid[],boolean) from public,anon;
grant execute on function public.publish_schoolpro_selected_results(uuid,text,text,uuid[],boolean) to authenticated;

create or replace function public.publish_schoolpro_results(p_school uuid,p_term text,p_session text)
returns integer
language plpgsql
security definer
set search_path=''
as $function$
declare n integer;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) then raise exception 'Module permission denied: results';end if;
 if not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Select an academic period';end if;
 perform r.id from public.schoolpro_results r where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='approved' and not r.locked for update;
 if exists(select 1 from public.schoolpro_results r where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='approved' and not r.locked and not private.schoolpro_result_assessment_complete(r.id)) then
  raise exception 'Academic period contains incomplete approved assessments; return them for correction before publication';
 end if;
 update public.schoolpro_results set status='published',published_at=now(),locked=true
 where school_id=p_school and term=trim(p_term) and session=trim(p_session) and status='approved' and locked=false;
 get diagnostics n=row_count;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
 values(auth.uid(),'School results published','schoolpro','school',p_school::text,jsonb_build_object('term',trim(p_term),'session',trim(p_session),'published',n));
 return n;
end
$function$;
revoke all on function public.publish_schoolpro_results(uuid,text,text) from public,anon;
grant execute on function public.publish_schoolpro_results(uuid,text,text) to authenticated;
