-- Keep class publication aligned with the selected class roster.
-- Historical enrolment is authoritative; otherwise only the student's current class is eligible.
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
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Select an academic period';end if;
 perform r.id from public.schoolpro_results r where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='approved' and not r.locked
  and exists(
   select 1 from public.schoolpro_students s
   where s.id=r.student_id and s.school_id=p_school
    and (
     exists(select 1 from public.schoolpro_enrollment_history h
      where h.student_id=s.id and h.class_id=p_class and h.session=r.session and h.school_id=p_school)
     or (s.status='active' and s.class_id=p_class and not exists(select 1 from public.schoolpro_enrollment_history h
      where h.student_id=s.id and h.session=r.session and h.school_id=p_school))
    )
  )
  for update;
 if exists(select 1 from public.schoolpro_results r where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='approved' and not r.locked
  and exists(
   select 1 from public.schoolpro_students s
   where s.id=r.student_id and s.school_id=p_school
    and (
     exists(select 1 from public.schoolpro_enrollment_history h
      where h.student_id=s.id and h.class_id=p_class and h.session=r.session and h.school_id=p_school)
     or (s.status='active' and s.class_id=p_class and not exists(select 1 from public.schoolpro_enrollment_history h
      where h.student_id=s.id and h.session=r.session and h.school_id=p_school))
    )
  )
  and not private.schoolpro_result_assessment_complete(r.id)) then
  raise exception 'Class contains incomplete approved assessments; return them for correction before publication';
 end if;
 update public.schoolpro_results r set status='published',published_at=now(),locked=true
 where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='approved' and not r.locked
  and exists(
   select 1 from public.schoolpro_students s
   where s.id=r.student_id and s.school_id=p_school
    and (
     exists(select 1 from public.schoolpro_enrollment_history h
      where h.student_id=s.id and h.class_id=p_class and h.session=r.session and h.school_id=p_school)
     or (s.status='active' and s.class_id=p_class and not exists(select 1 from public.schoolpro_enrollment_history h
      where h.student_id=s.id and h.session=r.session and h.school_id=p_school))
    )
  );
 get diagnostics n=row_count;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
 values(auth.uid(),'Class results published','schoolpro','class',p_class::text,jsonb_build_object('school_id',p_school,'term',p_term,'session',p_session,'published',n));
 return n;
end
$function$;
revoke all on function public.publish_schoolpro_class_results(uuid,uuid,text,text) from public,anon;
grant execute on function public.publish_schoolpro_class_results(uuid,uuid,text,text) to authenticated;
