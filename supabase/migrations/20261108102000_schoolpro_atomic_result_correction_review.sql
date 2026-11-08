-- Make correction-request approval/rejection atomic with the result reopen operation.
-- Clients must not directly mutate request status or review attribution.
drop policy if exists "schoolpro_correction_request_review" on public.schoolpro_result_correction_requests;

create or replace function public.decide_schoolpro_result_correction_request(
 p_request uuid,
 p_approve boolean,
 p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare request_row public.schoolpro_result_correction_requests;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if p_approve is null then raise exception 'Choose whether to approve or reject the request';end if;
 select * into request_row from public.schoolpro_result_correction_requests where id=p_request for update;
 if request_row.id is null then raise exception 'Correction request not found';end if;
 if request_row.status<>'pending' then raise exception 'Only pending correction requests can be reviewed';end if;
 if not private.schoolpro_module_allowed(request_row.school_id,'results') then raise exception 'Module permission denied: results';end if;
 if not(public.schoolpro_member_can_manage(request_row.school_id) or exists(
   select 1 from public.schoolpro_members m
   where m.school_id=request_row.school_id and m.user_id=auth.uid()
     and m.role::text in('exam_officer','head_teacher','vice_principal')
 )) then raise exception 'Not authorized to review result correction requests';end if;
 if p_approve then
  perform public.reopen_schoolpro_result_for_correction(
   request_row.result_id,
   coalesce(nullif(trim(p_notes),''),request_row.reason)
  );
 end if;
 update public.schoolpro_result_correction_requests
 set status=case when p_approve then 'approved' else 'rejected' end,
     reviewed_by=auth.uid(),
     reviewed_at=now(),
     review_notes=nullif(trim(p_notes),'')
 where id=request_row.id and status='pending';
 if not found then raise exception 'Correction request was already reviewed';end if;
 return request_row.id;
end
$function$;
revoke all on function public.decide_schoolpro_result_correction_request(uuid,boolean,text) from public,anon;
grant execute on function public.decide_schoolpro_result_correction_request(uuid,boolean,text) to authenticated;
