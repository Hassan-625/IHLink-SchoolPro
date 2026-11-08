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
 select coalesce(fs.block_results_when_owing,false) and coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0)>coalesce(fs.allowed_outstanding,0),
        coalesce(bool_or(i.result_hold),false),coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0)
 into blocked,held,outstanding
 from public.schoolpro_finance_settings fs
 left join public.schoolpro_invoices i on i.school_id=s.school_id and i.student_id=s.id and i.term=p_term and i.session=p_session and i.status<>'waived'
 where fs.school_id=s.school_id group by fs.block_results_when_owing,fs.allowed_outstanding;
 if coalesce(held,false) then return jsonb_build_object('ok',false,'message','Result access is currently on hold.');end if;
 if coalesce(blocked,false) then
  return jsonb_build_object('ok',false,'message','Result access is paused by the school because of an outstanding fee balance.','outstanding',coalesce(outstanding,0));
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
  'term',p_term,'session',p_session,'results',payload);
end
$function$;
revoke all on function public.check_schoolpro_result_pin(text,text,text,text) from public,anon;
grant execute on function public.check_schoolpro_result_pin(text,text,text,text) to service_role;
