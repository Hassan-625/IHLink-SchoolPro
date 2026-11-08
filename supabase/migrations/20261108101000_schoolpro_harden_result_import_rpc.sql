-- Harden the database import boundary as well as the workbook preview.
-- Imports are full assessment records; incremental component entry remains on the separate upsert flow.
create or replace function public.import_schoolpro_results(p_school uuid,p_term text,p_session text,p_rows jsonb)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
 x jsonb;
 st uuid;
 su uuid;
 sc uuid;
 scores jsonb;
 comp jsonb;
 component jsonb;
 component_key text;
 scheme_level text;
 class_level text;
 maxv numeric;
 v numeric;
 n integer:=0;
 seen_keys text[]:='{}';
 result_row public.schoolpro_results;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied: results';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Term and session are required';end if;
 if p_rows is null or jsonb_typeof(p_rows) is distinct from 'array' or jsonb_array_length(p_rows)=0 or jsonb_array_length(p_rows)>500 then raise exception 'Import must contain 1 to 500 rows';end if;
 for x in select value from jsonb_array_elements(p_rows) loop
  if jsonb_typeof(x)<>'object' then raise exception 'Every import row must be an object';end if;
  if nullif(trim(x->>'admission_number'),'') is null or nullif(trim(x->>'subject_code'),'') is null or nullif(trim(x->>'assessment_scheme_id'),'') is null then
   raise exception 'Admission number, subject code and assessment scheme are required';
  end if;
  select s.id,coalesce(e.class_id,s.class_id) into st,sc
  from public.schoolpro_students s
  left join public.schoolpro_enrollment_history e on e.school_id=s.school_id and e.student_id=s.id and e.session=trim(p_session)
  where s.school_id=p_school and s.admission_number=trim(x->>'admission_number')
    and (e.student_id is not null or (s.status='active' and not exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=s.school_id and h.student_id=s.id)));
  if st is null then raise exception 'Student is not enrolled in the selected session: %',x->>'admission_number';end if;
  select id into su from public.schoolpro_subjects where school_id=p_school and upper(code)=upper(trim(x->>'subject_code'));
  if su is null then raise exception 'Unknown subject code: %',x->>'subject_code';end if;
  if not private.schoolpro_can_write_result(p_school,st,su,trim(p_session)) then raise exception 'Not authorized for student %, subject %, session %',x->>'admission_number',x->>'subject_code',p_session;end if;
  if exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=p_school and a.class_id=sc and a.session=trim(p_session) and a.ended_at is null)
    and not exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=p_school and a.class_id=sc and a.subject_id=su and a.session=trim(p_session) and a.ended_at is null) then
   raise exception 'Subject is not assigned to this class for the selected session';
  end if;
  scores:=x->'assessment_scores';
  if scores is null or jsonb_typeof(scores)<>'object' then raise exception 'Assessment scores must be a JSON object';end if;
  select components,lower(trim(school_level)) into comp,scheme_level from public.schoolpro_assessment_schemes
  where id=(x->>'assessment_scheme_id')::uuid and school_id=p_school;
  if comp is null then raise exception 'Invalid assessment scheme';end if;
  select lower(trim(c.level)) into class_level from public.schoolpro_classes c where c.id=sc and c.school_id=p_school;
  if class_level is not null and scheme_level not in ('all','custom',class_level)
    and not (scheme_level='secondary' and class_level in ('junior_secondary','senior_secondary','jss','sss'))
    and not (scheme_level='nursery_primary' and class_level in ('nursery','primary','nursery_primary'))
    and not (scheme_level='junior_secondary' and class_level='jss')
    and not (scheme_level='senior_secondary' and class_level='sss') then
   raise exception 'Assessment scheme level % does not match the selected class level %',scheme_level,class_level;
  end if;
  for component in select value from jsonb_array_elements(comp) loop
   component_key:=component->>'key';
   if not (scores ? component_key) then raise exception 'Missing assessment component: %',component->>'label';end if;
   if jsonb_typeof(scores->component_key)<>'number' then raise exception 'Assessment component % must be numeric',component->>'label';end if;
   v:=(scores->>component_key)::numeric;
   maxv:=(component->>'maxScore')::numeric;
   if v<0 or v>maxv then raise exception 'Score % exceeds allowed range 0-% for %',v,maxv,component->>'label';end if;
  end loop;
  if exists(select 1 from jsonb_object_keys(scores) as supplied(key)
    where not exists(select 1 from jsonb_array_elements(comp) configured(value) where configured.value->>'key'=supplied.key)) then
   raise exception 'Import contains an unknown assessment component';
  end if;
  if (st::text||':'||su::text)=any(seen_keys) then raise exception 'Duplicate student and subject row in import';end if;
  seen_keys:=array_append(seen_keys,st::text||':'||su::text);
  select * into result_row from public.schoolpro_results
  where student_id=st and subject_id=su and term=trim(p_term) and session=trim(p_session)
  for update;
  if found then
   if result_row.locked or result_row.status<>'draft' then raise exception 'Existing result is locked or no longer draft for % / %',x->>'admission_number',x->>'subject_code';end if;
   if result_row.assessment_scheme_id is not null and result_row.assessment_scheme_id<>(x->>'assessment_scheme_id')::uuid then
    raise exception 'Existing result uses a different assessment scheme for % / %',x->>'admission_number',x->>'subject_code';
   end if;
  end if;
  insert into public.schoolpro_results(school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,status,locked)
  values(p_school,st,su,trim(p_term),trim(p_session),(x->>'assessment_scheme_id')::uuid,scores,'draft',false)
  on conflict(student_id,subject_id,term,session) do update
   set assessment_scheme_id=excluded.assessment_scheme_id,assessment_scores=excluded.assessment_scores,updated_at=now();
  n:=n+1;
 end loop;
 return jsonb_build_object('imported',n);
end
$function$;
revoke all on function public.import_schoolpro_results(uuid,text,text,jsonb) from public,anon;
grant execute on function public.import_schoolpro_results(uuid,text,text,jsonb) to authenticated;
