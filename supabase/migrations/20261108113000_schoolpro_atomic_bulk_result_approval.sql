-- Approve a selected set of Draft results atomically.
-- The previous client loop could approve part of a class before encountering one invalid row.
create or replace function public.review_schoolpro_results(p_results uuid[],p_notes text default null)
returns integer
language plpgsql
security definer
set search_path=''
as $function$
declare
 v_school uuid;
 v_count integer;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if coalesce(cardinality(p_results),0)=0 or cardinality(p_results)>5000 then
  raise exception 'Select between 1 and 5000 result records';
 end if;
 if (select count(distinct x.id) from unnest(p_results) x(id))<>cardinality(p_results) then
  raise exception 'Duplicate result records were supplied';
 end if;
 select r.school_id into v_school from public.schoolpro_results r
 where r.id=any(p_results) order by r.id limit 1;
 if v_school is null then raise exception 'Result records not found';end if;
 if not coalesce(private.schoolpro_module_allowed(v_school,'results'),false) then
  raise exception 'Module permission denied: results';
 end if;
 if not(public.schoolpro_member_can_manage(v_school) or exists(
  select 1 from public.schoolpro_members m where m.school_id=v_school and m.user_id=auth.uid()
   and m.role::text in('exam_officer','head_teacher','vice_principal')
 )) then raise exception 'Not authorized';end if;
 perform r.id from public.schoolpro_results r where r.id=any(p_results) order by r.id for update;
 select count(*) into v_count from public.schoolpro_results r
 where r.id=any(p_results) and r.school_id=v_school and r.status='draft' and not r.locked;
 if v_count<>cardinality(p_results) then
  raise exception 'Every selected result must belong to this school and remain an unlocked Draft';
 end if;
 if exists(select 1 from public.schoolpro_results r
  where r.id=any(p_results) and not private.schoolpro_result_assessment_complete(r.id)) then
  raise exception 'At least one selected assessment is incomplete; no results were approved';
 end if;
 insert into public.schoolpro_result_approvals(school_id,result_id,status,reviewed_by,reviewed_at,notes)
 select v_school,r.id,'approved',auth.uid(),now(),p_notes
 from public.schoolpro_results r where r.id=any(p_results)
 on conflict(result_id) do update set status=excluded.status,reviewed_by=excluded.reviewed_by,
  reviewed_at=excluded.reviewed_at,notes=excluded.notes;
 update public.schoolpro_results set status='approved',approved_by=auth.uid(),approved_at=now(),published_at=null
 where id=any(p_results) and school_id=v_school and status='draft' and not locked;
 get diagnostics v_count=row_count;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
 values(auth.uid(),'Results approved','schoolpro','school',v_school::text,
  jsonb_build_object('result_ids',p_results,'approved',v_count));
 return v_count;
end
$function$;
revoke all on function public.review_schoolpro_results(uuid[],text) from public,anon;
grant execute on function public.review_schoolpro_results(uuid[],text) to authenticated;
