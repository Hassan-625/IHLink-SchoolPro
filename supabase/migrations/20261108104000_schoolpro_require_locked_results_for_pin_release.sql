-- Public PIN result checks must use the same immutable release boundary as report cards.
-- A row is family-visible only after publication AND locking.
create or replace function public.check_schoolpro_result_pin(p_admission text,p_term text,p_session text,p_pin text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $function$
declare
 s record;
 pinrow record;
 blocked boolean;
 held boolean;
 outstanding numeric;
 payload jsonb;
 v_attempt_key text;
 v_blocked_until timestamptz;
 v_candidate_count integer;
 exception_allowed boolean;
 attendance_blocked boolean;
 term_start date;
 term_end date;
 minimum_attendance numeric;
 expected_days integer;
 attended_days integer;
begin
 v_attempt_key:=encode(extensions.digest(lower(trim(coalesce(p_admission,''))),'sha256'),'hex');
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_attempt_key,0));
 select a.blocked_until into v_blocked_until from private.schoolpro_result_pin_attempts a where a.attempt_key=v_attempt_key;
 if v_blocked_until is not null and v_blocked_until>now() then
  return jsonb_build_object('ok',false,'message','Too many attempts. Please try again later.');
 end if;
 select count(*)::integer into v_candidate_count
 from public.schoolpro_students st
 where upper(st.admission_number)=upper(trim(p_admission)) and st.status='active'
 and exists(select 1 from public.schoolpro_result_access_pins candidate_pin
  where candidate_pin.student_id=st.id and candidate_pin.term=p_term and candidate_pin.session=p_session
   and candidate_pin.is_active and (candidate_pin.expires_at is null or candidate_pin.expires_at>now())
   and candidate_pin.pin_hash=encode(extensions.digest(upper(trim(p_pin)),'sha256'),'hex'));
 if v_candidate_count>1 then
  perform private.record_schoolpro_result_pin_failure(v_attempt_key);
  return jsonb_build_object('ok',false,'message','Result details or access PIN are invalid.');
 end if;
 select st.id,st.school_id,st.first_name,st.last_name,st.admission_number,st.class_name,sc.name school_name,sc.address
 into s from public.schoolpro_students st join public.schoolpro_schools sc on sc.id=st.school_id
 where upper(st.admission_number)=upper(trim(p_admission)) and st.status='active'
 and exists(select 1 from public.schoolpro_result_access_pins candidate_pin
  where candidate_pin.student_id=st.id and candidate_pin.term=p_term and candidate_pin.session=p_session
   and candidate_pin.is_active and (candidate_pin.expires_at is null or candidate_pin.expires_at>now())
   and candidate_pin.pin_hash=encode(extensions.digest(upper(trim(p_pin)),'sha256'),'hex'));
 if s.id is null then
  perform private.record_schoolpro_result_pin_failure(v_attempt_key);
  return jsonb_build_object('ok',false,'message','Result details or access PIN are invalid.');
 end if;
 select * into pinrow from public.schoolpro_result_access_pins p
 where p.student_id=s.id and p.term=p_term and p.session=p_session and p.is_active
 and (p.expires_at is null or p.expires_at>now())
 and p.pin_hash=encode(extensions.digest(upper(trim(p_pin)),'sha256'),'hex') limit 1;
 if pinrow.id is null then
  perform private.record_schoolpro_result_pin_failure(v_attempt_key);
  return jsonb_build_object('ok',false,'message','Result details or access PIN are invalid.');
 end if;
 select o.allowed into exception_allowed from public.schoolpro_result_access_overrides o
 where o.school_id=s.school_id and o.student_id=s.id and o.term=trim(p_term) and o.session=trim(p_session);
 if not coalesce(exception_allowed,false) then
  select coalesce(fs.block_results_for_attendance,false),fs.minimum_attendance_percent
   into attendance_blocked,minimum_attendance
  from public.schoolpro_finance_settings fs where fs.school_id=s.school_id;
  if coalesce(attendance_blocked,false) then
   select ts.term_start_date,ts.term_end_date into term_start,term_end
   from public.schoolpro_result_term_settings ts
   where ts.school_id=s.school_id and ts.term=trim(p_term) and ts.session=trim(p_session);
   if term_start is null or term_end is null then
    return jsonb_build_object('ok',false,'message','Your school is reviewing attendance for this result. Please contact your school.');
   end if;
   select greatest(coalesce(nullif(ts.class_days,0),count(distinct a.attendance_date)),count(distinct a.attendance_date))::integer,
    count(distinct a.attendance_date) filter(where a.status::text in('present','late'))::integer
   into expected_days,attended_days
   from public.schoolpro_result_term_settings ts
   left join public.schoolpro_attendance a on a.school_id=s.school_id and a.student_id=s.id
    and a.attendance_date between term_start and term_end
   where ts.school_id=s.school_id and ts.term=trim(p_term) and ts.session=trim(p_session)
   group by ts.class_days;
   if coalesce(expected_days,0)=0 or 100.0*coalesce(attended_days,0)/expected_days<coalesce(minimum_attendance,0) then
    return jsonb_build_object('ok',false,'message','Your school has paused this result because attendance is below its requirement. Please contact your school.');
   end if;
  end if;
  select coalesce(fs.block_results_when_owing,false) and coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0)>coalesce(fs.allowed_outstanding,0),
         coalesce(bool_or(i.result_hold),false),coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0)
   into blocked,held,outstanding
  from public.schoolpro_finance_settings fs
  left join public.schoolpro_invoices i on i.school_id=s.school_id and i.student_id=s.id and i.term=trim(p_term) and i.session=trim(p_session) and i.status<>'waived'
  where fs.school_id=s.school_id group by fs.block_results_when_owing,fs.allowed_outstanding;
  if coalesce(held,false) then return jsonb_build_object('ok',false,'message','Result access is currently on hold.');end if;
  if coalesce(blocked,false) then
   return jsonb_build_object('ok',false,'message','Result access is paused by the school because of an outstanding fee balance.','outstanding',coalesce(outstanding,0));
  end if;
 end if;
 select coalesce(jsonb_agg(jsonb_build_object('subject',sub.name,'total_score',r.total_score,'assessment_scores',r.assessment_scores,'status',r.status) order by sub.name),'[]'::jsonb)
 into payload from public.schoolpro_results r join public.schoolpro_subjects sub on sub.id=r.subject_id
 where r.student_id=s.id and r.term=p_term and r.session=p_session and r.status='published' and r.locked=true;
 if jsonb_array_length(payload)=0 then
  return jsonb_build_object('ok',false,'message','No published result is available for this term and session.');
 end if;
 delete from private.schoolpro_result_pin_attempts where attempt_key=v_attempt_key;
 update public.schoolpro_result_access_pins set last_used_at=now() where id=pinrow.id;
 return jsonb_build_object('ok',true,'school',jsonb_build_object('name',s.school_name,'address',s.address),
  'student',jsonb_build_object('name',s.first_name||' '||s.last_name,'admission_number',s.admission_number,'class_name',s.class_name),
  'term',p_term,'session',p_session,'results',payload,
  'grade_scale',coalesce((select jsonb_agg(jsonb_build_object('label',label,'min_score',min_score,'max_score',max_score) order by position) from public.schoolpro_grade_scale where school_id=s.school_id and is_active),'[]'::jsonb));
end
$function$;
revoke all on function public.check_schoolpro_result_pin(text,text,text,text) from public,anon;
grant execute on function public.check_schoolpro_result_pin(text,text,text,text) to service_role;
