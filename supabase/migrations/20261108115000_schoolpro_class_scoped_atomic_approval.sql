-- Approve only the selected class/session roster; do not widen class approval
-- to every result belonging to the same students in the school.
create or replace function public.review_schoolpro_class_results(
 p_school uuid,p_class uuid,p_term text,p_session text,p_notes text default null
) returns integer
language plpgsql
security definer
set search_path=''
as $function$
declare v_ids uuid[]; v_count integer;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then
  raise exception 'Select an academic period';
 end if;
 if not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) then
  raise exception 'Module permission denied: results';
 end if;
 if not(public.schoolpro_member_can_manage(p_school) or exists(
  select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid()
   and m.role::text in('exam_officer','head_teacher','vice_principal')
 )) then raise exception 'Not authorized';end if;
 if not exists(select 1 from public.schoolpro_classes c where c.id=p_class and c.school_id=p_school) then
  raise exception 'Select a class in this school';
 end if;
 -- Lock the roster while determining the result IDs so class assignment cannot
 -- change between the scope check and the atomic approval RPC.
 perform s.id from public.schoolpro_students s
 where s.school_id=p_school and (
  exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
   and h.student_id=s.id and h.session=trim(p_session) and h.class_id=p_class)
  or (s.status='active' and s.class_id=p_class and not exists(
   select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
    and h.student_id=s.id and h.session=trim(p_session)))
 ) order by s.id for update;
 select coalesce(array_agg(r.id order by r.id),'{}'::uuid[]) into v_ids
 from public.schoolpro_results r
 where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
  and r.status='draft' and not r.locked
  and exists(select 1 from public.schoolpro_students s where s.id=r.student_id and s.school_id=p_school
   and (
    exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
     and h.student_id=s.id and h.session=trim(p_session) and h.class_id=p_class)
    or (s.status='active' and s.class_id=p_class and not exists(
     select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school
      and h.student_id=s.id and h.session=trim(p_session)))
   ));
 if cardinality(v_ids)=0 then return 0;end if;
 v_count:=public.review_schoolpro_results(v_ids,p_notes);
 return v_count;
end
$function$;
revoke all on function public.review_schoolpro_class_results(uuid,uuid,text,text,text) from public,anon;
grant execute on function public.review_schoolpro_class_results(uuid,uuid,text,text,text) to authenticated;
