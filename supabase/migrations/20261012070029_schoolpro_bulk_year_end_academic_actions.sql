create or replace function private.schoolpro_bulk_academic_action(p_school uuid,p_session text,p_action text,p_students uuid[] default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare s record; h record; target uuid; v_id uuid; v_decision text; v_name text; v_year int; v_average numeric; terms int; processed int:=0; omitted jsonb:='[]'; existing record;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if p_action not in ('issue_transcripts','prepare_progression','apply_progression') or p_session !~ '^[0-9]{4}/[0-9]{4}$' then raise exception 'Select a valid action and source session';end if;
 v_year:=split_part(p_session,'/',1)::int;
 if split_part(p_session,'/',2)::int<>v_year+1 then raise exception 'Select consecutive academic years';end if;
 if p_action='issue_transcripts' then
  if not private.schoolpro_can_issue_transcript(p_school) then raise exception 'Transcript permission required';end if;
 else
  if not private.schoolpro_module_allowed(p_school,'promotions') or not(private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(p_school,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role,'registrar'::public.school_member_role])) then raise exception 'Progression permission required';end if;
 end if;
 perform pg_advisory_xact_lock(hashtextextended(p_school::text||p_session||p_action,0));
 for s in select st.* from public.schoolpro_students st join public.schoolpro_enrollment_history eh on eh.student_id=st.id and eh.school_id=st.school_id and eh.session=p_session
  where st.school_id=p_school and (p_students is null or st.id=any(p_students)) order by st.id
 loop
  begin
   if p_action='apply_progression' then
    select * into existing from public.schoolpro_promotions where school_id=p_school and student_id=s.id and session=p_session and status='pending' order by created_at desc limit 1;
    if existing.id is null then continue;end if;
    perform public.apply_schoolpro_promotion(existing.id);processed:=processed+1;continue;
   end if;
   select count(*),avg(a.score) into terms,v_average from(select r.term,avg(r.total_score) score from public.schoolpro_results r where r.school_id=p_school and r.student_id=s.id and r.session=p_session and r.term in('First Term','Second Term','Third Term') and r.status='published' group by r.term)a;
   if terms<>3 or exists(select 1 from public.schoolpro_results r where r.school_id=p_school and r.student_id=s.id and r.session=p_session and r.status<>'published') then raise exception 'All three terms must be published';end if;
   if p_action='issue_transcripts' then
    if exists(select 1 from (values('First Term'),('Second Term'),('Third Term'))t(term) cross join lateral public.schoolpro_result_access(s.id,t.term,p_session) a where not a.allowed) then raise exception 'Result access is held by the school';end if;
    if exists(select 1 from public.schoolpro_transcript_issues i where i.student_id=s.id and i.school_id=p_school and i.revoked_at is null and i.issued_at>=coalesce((select max(updated_at) from public.schoolpro_results r where r.student_id=s.id and r.status='published'),'-infinity'::timestamptz)) then continue;end if;
    perform private.schoolpro_issue_transcript(s.id);processed:=processed+1;continue;
   end if;
   if exists(select 1 from public.schoolpro_promotions p where p.school_id=p_school and p.student_id=s.id and p.session=p_session and p.status in('pending','applied')) then continue;end if;
   select c.* into h from public.schoolpro_enrollment_history e join public.schoolpro_classes c on c.id=e.class_id and c.school_id=e.school_id where e.school_id=p_school and e.student_id=s.id and e.session=p_session;
   if s.status<>'active' or s.class_id is distinct from h.id then raise exception 'Student has already changed class or left';end if;
   v_decision:=case when v_average<30 then 'repeated' when upper(regexp_replace(h.name,'[^a-zA-Z0-9]','','g')) in('SS3','SSS3') then 'graduated' else 'promoted' end;target:=null;
   if v_decision='promoted' then
    v_name:=upper(regexp_replace(h.name,'[^a-zA-Z0-9]','','g'));
    v_name:=case v_name when 'PRENURSERY' then 'NURSERY1' when 'NURSERY1' then 'NURSERY2' when 'NURSERY2' then 'NURSERY3' when 'NURSERY3' then 'BASIC1'
    when 'BASIC1' then 'BASIC2' when 'BASIC2' then 'BASIC3' when 'BASIC3' then 'BASIC4' when 'BASIC4' then 'BASIC5' when 'BASIC5' then 'JSS1'
    when 'PRIMARY1' then 'PRIMARY2' when 'PRIMARY2' then 'PRIMARY3' when 'PRIMARY3' then 'PRIMARY4' when 'PRIMARY4' then 'PRIMARY5' when 'PRIMARY5' then 'JSS1'
    when 'JSS1' then 'JSS2' when 'JSS2' then 'JSS3' when 'JSS3' then 'SS1' when 'SS1' then 'SS2' when 'SS2' then 'SS3' when 'SSS1' then 'SSS2' when 'SSS2' then 'SSS3' else null end;
    select c.id into target from public.schoolpro_classes c where c.school_id=p_school and coalesce(c.arm,'')=coalesce(h.arm,'') and upper(regexp_replace(c.name,'[^a-zA-Z0-9]','','g'))=v_name limit 1;
    if target is null then raise exception 'Set the next class manually for this school naming scheme';end if;
   end if;
   v_id:=public.create_schoolpro_progression(s.id,p_session,v_decision,target,'Year-end review: three published terms; average '||round(v_average,2)||'%.');
   processed:=processed+1;
  exception when others then omitted:=omitted||jsonb_build_array(jsonb_build_object('student_id',s.id,'name',concat_ws(' ',s.first_name,s.last_name),'reason',SQLERRM));
  end;
 end loop;
 return jsonb_build_object('processed',processed,'skipped',omitted);
end $$;
revoke all on function private.schoolpro_bulk_academic_action(uuid,text,text,uuid[]) from public,anon;
grant execute on function private.schoolpro_bulk_academic_action(uuid,text,text,uuid[]) to authenticated;
create or replace function public.schoolpro_bulk_academic_action(p_school uuid,p_session text,p_action text,p_students uuid[] default null)
returns jsonb language sql security invoker set search_path='' as $$select private.schoolpro_bulk_academic_action(p_school,p_session,p_action,p_students)$$;
revoke all on function public.schoolpro_bulk_academic_action(uuid,text,text,uuid[]) from public,anon;
grant execute on function public.schoolpro_bulk_academic_action(uuid,text,text,uuid[]) to authenticated;