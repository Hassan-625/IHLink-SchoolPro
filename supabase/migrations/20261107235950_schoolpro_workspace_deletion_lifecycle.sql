-- Stage C0: owner-requested, platform-reviewed workspace removal.
-- Execution is a safe soft deletion: deactivate access and retain academic,
-- financial, audit, legal and Storage history. No tenant rows or Storage objects
-- are physically deleted by this workflow.
begin;

create table if not exists public.schoolpro_workspace_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete restrict,
  requested_by uuid not null references auth.users(id) on delete restrict,
  request_reason text not null check (length(btrim(request_reason)) between 20 and 2000),
  status text not null default 'pending'
    check (status in ('pending','approved','rejected','executed','cancelled')),
  requested_at timestamptz not null default now(),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  cancellation_note text,
  executed_by uuid references auth.users(id) on delete set null,
  executed_at timestamptz,
  execution_note text,
  preflight_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint schoolpro_workspace_deletion_review_metadata_check check (
    (reviewed_by is null and reviewed_at is null and review_note is null)
    or (reviewed_by is not null and reviewed_at is not null
      and review_note is not null and length(btrim(review_note)) between 10 and 2000)
  ),
  constraint schoolpro_workspace_deletion_execution_metadata_check check (
    (executed_by is null and executed_at is null and execution_note is null)
    or (executed_by is not null and executed_at is not null
      and execution_note is not null and length(btrim(execution_note)) between 10 and 2000)
  )
);

create index if not exists schoolpro_workspace_deletion_school_history_idx
  on public.schoolpro_workspace_deletion_requests(school_id,requested_at desc);
create unique index if not exists schoolpro_workspace_deletion_one_open_request_idx
  on public.schoolpro_workspace_deletion_requests(school_id)
  where status in ('pending','approved');

alter table public.schoolpro_workspace_deletion_requests enable row level security;
revoke all on public.schoolpro_workspace_deletion_requests from public,anon,authenticated;
grant select on public.schoolpro_workspace_deletion_requests to authenticated;

drop policy if exists "SchoolPro workspace deletion request read" on public.schoolpro_workspace_deletion_requests;
create policy "SchoolPro workspace deletion request read"
on public.schoolpro_workspace_deletion_requests
for select to authenticated using (
  requested_by=auth.uid()
  or private.is_admin()
  or private.has_school_access(
    school_id,array['proprietor']::public.school_member_role[]
  )
);

create or replace function public.schoolpro_request_workspace_deletion(
  p_school uuid,
  p_reason text,
  p_confirmation text
) returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  target public.schoolpro_schools;
  request_id uuid;
  clean_reason text := btrim(coalesce(p_reason,''));
  snapshot jsonb;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'An active signed-in account is required';
  end if;
  if length(clean_reason) not between 20 and 2000 then
    raise exception 'Provide a reason between 20 and 2000 characters';
  end if;

  select * into target
  from public.schoolpro_schools s
  where s.id=p_school
    and (
      s.owner_id=auth.uid()
      or exists (
        select 1 from public.schoolpro_members m
        where m.school_id=s.id and m.user_id=auth.uid()
          and m.role='proprietor'::public.school_member_role
          and m.status='active'
      )
    )
  for update;

  if target.id is null then
    raise exception 'Only the workspace owner or an active proprietor can request removal';
  end if;
  if btrim(coalesce(p_confirmation,''))<>target.name then
    raise exception 'The school name confirmation does not match';
  end if;
  if target.status='suspended' then
    raise exception 'This workspace is already suspended';
  end if;

  snapshot:=jsonb_build_object(
    'school_name',target.name,
    'school_status',target.status::text,
    'students',(select count(*) from public.schoolpro_students where school_id=p_school),
    'members',(select count(*) from public.schoolpro_members where school_id=p_school),
    'classes',(select count(*) from public.schoolpro_classes where school_id=p_school),
    'invoices',(select count(*) from public.schoolpro_invoices where school_id=p_school),
    'fee_payments',(select count(*) from public.schoolpro_fee_payments where school_id=p_school),
    'captured_at',now()
  );

  insert into public.schoolpro_workspace_deletion_requests(
    school_id,requested_by,request_reason,status,preflight_snapshot
  ) values(p_school,auth.uid(),clean_reason,'pending',snapshot)
  returning id into request_id;

  insert into public.schoolpro_audit_logs
    (school_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_school,auth.uid(),'Workspace removal requested',
    'workspace_deletion_request',request_id::text,snapshot||jsonb_build_object('reason',clean_reason));

  return request_id;
end;
$function$;

create or replace function public.schoolpro_cancel_workspace_deletion(
  p_request uuid,
  p_note text default null
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare target public.schoolpro_workspace_deletion_requests;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'An active signed-in account is required';
  end if;
  select * into target from public.schoolpro_workspace_deletion_requests
  where id=p_request for update;
  if target.id is null or target.requested_by<>auth.uid() then
    raise exception 'Workspace removal request was not found for this requester';
  end if;
  if target.status<>'pending' then
    raise exception 'Only a pending workspace removal request can be cancelled';
  end if;
  update public.schoolpro_workspace_deletion_requests
    set status='cancelled',updated_at=now(),
        cancellation_note=case when length(btrim(coalesce(p_note,'')))>=10 then btrim(p_note) else 'Cancelled by the original requester before platform review.' end
  where id=p_request;
  insert into public.schoolpro_audit_logs
    (school_id,actor_id,action,entity_type,entity_id,metadata)
  values(target.school_id,auth.uid(),'Workspace removal request cancelled',
    'workspace_deletion_request',p_request::text,jsonb_build_object('note',p_note));
end;
$function$;

create or replace function public.schoolpro_review_workspace_deletion(
  p_request uuid,
  p_decision text,
  p_note text
) returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare target public.schoolpro_workspace_deletion_requests;
  clean_note text:=btrim(coalesce(p_note,''));
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.is_admin(array['super_admin']::public.user_role[]) then
    raise exception 'Only an active platform Super Admin can review workspace removal';
  end if;
  if p_decision not in ('approved','rejected') then
    raise exception 'Choose approved or rejected';
  end if;
  if length(clean_note) not between 10 and 2000 then
    raise exception 'Provide a review note between 10 and 2000 characters';
  end if;

  select * into target from public.schoolpro_workspace_deletion_requests
  where id=p_request for update;
  if target.id is null or target.status<>'pending' then
    raise exception 'Only a pending workspace removal request can be reviewed';
  end if;
  if target.requested_by=auth.uid() then
    raise exception 'A requester cannot review their own workspace removal request';
  end if;

  update public.schoolpro_workspace_deletion_requests
    set status=p_decision,reviewed_by=auth.uid(),reviewed_at=now(),
        review_note=clean_note,updated_at=now()
  where id=p_request;

  insert into public.schoolpro_audit_logs
    (school_id,actor_id,action,entity_type,entity_id,metadata)
  values(target.school_id,auth.uid(),'Workspace removal request reviewed',
    'workspace_deletion_request',p_request::text,
    jsonb_build_object('decision',p_decision,'review_note',clean_note,'requester_id',target.requested_by));
end;
$function$;

create or replace function public.schoolpro_execute_workspace_deletion(
  p_request uuid,
  p_confirmation text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  target public.schoolpro_workspace_deletion_requests;
  school_row public.schoolpro_schools;
  result jsonb;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.is_admin(array['super_admin']::public.user_role[]) then
    raise exception 'Only an active platform Super Admin can execute workspace removal';
  end if;

  select * into target from public.schoolpro_workspace_deletion_requests
  where id=p_request for update;
  if target.id is null or target.status<>'approved' then
    raise exception 'Only an approved workspace removal request can be executed';
  end if;
  if target.requested_by=auth.uid() or target.reviewed_by=auth.uid() then
    raise exception 'The requester and approving reviewer cannot execute this request';
  end if;

  select * into school_row from public.schoolpro_schools
  where id=target.school_id for update;
  if school_row.id is null then
    raise exception 'The requested school workspace no longer exists';
  end if;
  if btrim(coalesce(p_confirmation,''))<>school_row.name then
    raise exception 'The school name confirmation does not match';
  end if;

  -- Safe execution intentionally deactivates the workspace instead of physically
  -- deleting tenant rows. Financial, academic, legal, audit and Storage history
  -- remain retained and recoverable; any permanent purge requires a separate
  -- retention review and explicit Storage-object inventory/cleanup phase.
  update public.schoolpro_schools
    set status='suspended'::public.school_status,updated_at=now()
  where id=target.school_id;

  result:=jsonb_build_object(
    'execution_mode','deactivated_history_retained',
    'school_id',target.school_id,
    'school_name',school_row.name,
    'students_retained',(select count(*) from public.schoolpro_students where school_id=target.school_id),
    'members_retained',(select count(*) from public.schoolpro_members where school_id=target.school_id),
    'classes_retained',(select count(*) from public.schoolpro_classes where school_id=target.school_id),
    'financial_records_retained',true,
    'audit_history_retained',true,
    'storage_objects_retained',true,
    'executed_at',now()
  );

  update public.schoolpro_workspace_deletion_requests
    set status='executed',executed_by=auth.uid(),executed_at=now(),
        execution_note='Workspace access deactivated. Academic, financial, legal, audit and Storage records were retained.',
        preflight_snapshot=preflight_snapshot||jsonb_build_object('execution',result),
        updated_at=now()
  where id=p_request;

  insert into public.schoolpro_audit_logs
    (school_id,actor_id,action,entity_type,entity_id,metadata)
  values(target.school_id,auth.uid(),'Workspace deactivated after approved removal request',
    'workspace_deletion_request',p_request::text,result);

  return result;
end;
$function$;

revoke all on function public.schoolpro_request_workspace_deletion(uuid,text,text) from public,anon;
revoke all on function public.schoolpro_cancel_workspace_deletion(uuid,text) from public,anon;
revoke all on function public.schoolpro_review_workspace_deletion(uuid,text,text) from public,anon;
revoke all on function public.schoolpro_execute_workspace_deletion(uuid,text) from public,anon;
grant execute on function public.schoolpro_request_workspace_deletion(uuid,text,text) to authenticated;
grant execute on function public.schoolpro_cancel_workspace_deletion(uuid,text) to authenticated;
grant execute on function public.schoolpro_review_workspace_deletion(uuid,text,text) to authenticated;
grant execute on function public.schoolpro_execute_workspace_deletion(uuid,text) to authenticated;

comment on table public.schoolpro_workspace_deletion_requests is
  'Owner-requested, platform-reviewed workspace deactivation workflow. Execution retains academic, financial, legal, audit and Storage records; it is not a physical data purge.';

commit;
