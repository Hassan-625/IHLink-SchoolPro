-- Stage C0: audited staff discipline and leave/absence workflows.
-- Branch-only. Suspension/dismissal calls the existing audited membership lifecycle
-- transition, which ends operational appointments without deleting their history.

begin;

alter table public.schoolpro_members
  add column if not exists employment_status text not null default 'active';
alter table public.schoolpro_members
  drop constraint if exists schoolpro_members_employment_status_check;
alter table public.schoolpro_members
  add constraint schoolpro_members_employment_status_check
  check (employment_status in ('active','suspended','dismissed'));

create or replace function private.guard_schoolpro_employment_status()
returns trigger language plpgsql set search_path=''
as $guard$
begin
  if tg_op='INSERT' then
    if new.employment_status<>'active' then raise exception 'New staff memberships must start active'; end if;
    return new;
  end if;
  if current_user in ('anon','authenticated') and new.employment_status is distinct from old.employment_status then
    raise exception 'Employment status must be changed through the audited HR workflow';
  end if;
  if old.employment_status='dismissed' and new.status='active' then
    raise exception 'A dismissed staff member cannot be restored through the suspension workflow';
  end if;
  if new.status is distinct from old.status then
    if new.status='suspended' and old.employment_status<>'dismissed' then new.employment_status:='suspended';
    elsif new.status='active' and old.employment_status<>'dismissed' then new.employment_status:='active';
    end if;
  end if;
  return new;
end;
$guard$;
drop trigger if exists schoolpro_guard_employment_status on public.schoolpro_members;
create trigger schoolpro_guard_employment_status
before insert or update on public.schoolpro_members
for each row execute function private.guard_schoolpro_employment_status();
revoke all on function private.guard_schoolpro_employment_status() from public,anon,authenticated;

alter table public.schoolpro_leave_requests
  add column if not exists request_type text not null default 'planned_leave',
  add column if not exists absence_reported_at timestamptz,
  add column if not exists reason_updated_at timestamptz,
  add column if not exists reason_updated_by uuid references auth.users(id),
  add column if not exists review_note text;

alter table public.schoolpro_leave_requests
  drop constraint if exists schoolpro_leave_requests_request_type_check;
alter table public.schoolpro_leave_requests
  add constraint schoolpro_leave_requests_request_type_check
  check (request_type in ('planned_leave','absence_report'));

update public.schoolpro_leave_requests
set absence_reported_at=created_at
where request_type='absence_report' and absence_reported_at is null;

create table if not exists public.schoolpro_leave_events (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete restrict,
  leave_request_id uuid not null references public.schoolpro_leave_requests(id) on delete restrict,
  event_type text not null,
  actor_id uuid references auth.users(id) on delete set null,
  before_state jsonb,
  after_state jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.schoolpro_staff_disciplinary_cases (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete restrict,
  member_id uuid not null references public.schoolpro_members(id) on delete restrict,
  action_type text not null check (action_type in (
    'verbal_warning','written_warning','final_warning','investigation',
    'performance_plan','suspension','dismissal'
  )),
  severity text not null default 'moderate' check (severity in ('low','moderate','high','critical')),
  summary text not null check (length(btrim(summary)) between 10 and 500),
  details text,
  status text not null default 'open' check (status in ('open','action_issued','appealed','closed')),
  effective_at timestamptz not null default now(),
  staff_response text,
  response_at timestamptz,
  appeal_status text not null default 'not_submitted'
    check (appeal_status in ('not_submitted','pending','accepted','rejected')),
  appeal_submitted_at timestamptz,
  appeal_review_note text,
  appeal_reviewed_by uuid references auth.users(id),
  appeal_reviewed_at timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz
);

create index if not exists schoolpro_staff_discipline_school_member_idx
  on public.schoolpro_staff_disciplinary_cases(school_id,member_id,created_at desc);
create index if not exists schoolpro_leave_events_request_idx
  on public.schoolpro_leave_events(school_id,leave_request_id,created_at desc);

create table if not exists public.schoolpro_staff_disciplinary_events (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete restrict,
  case_id uuid not null references public.schoolpro_staff_disciplinary_cases(id) on delete restrict,
  event_type text not null,
  actor_id uuid references auth.users(id) on delete set null,
  before_state jsonb,
  after_state jsonb not null,
  created_at timestamptz not null default now()
);

create or replace function private.capture_schoolpro_leave_event()
returns trigger language plpgsql security definer set search_path=''
as $function$
begin
  insert into public.schoolpro_leave_events(
    school_id,leave_request_id,event_type,actor_id,before_state,after_state
  ) values (
    new.school_id,new.id,
    case when tg_op='INSERT' then 'reported'
      when old.reason is distinct from new.reason then 'reason_updated'
      when old.status is distinct from new.status then 'reviewed'
      else 'updated' end,
    auth.uid(),
    case when tg_op='INSERT' then null else to_jsonb(old) end,
    to_jsonb(new)
  );
  return new;
end;
$function$;

drop trigger if exists schoolpro_leave_event_history on public.schoolpro_leave_requests;
create trigger schoolpro_leave_event_history
after insert or update on public.schoolpro_leave_requests
for each row execute function private.capture_schoolpro_leave_event();

create or replace function private.capture_schoolpro_staff_discipline_event()
returns trigger language plpgsql security definer set search_path=''
as $function$
begin
  insert into public.schoolpro_staff_disciplinary_events(
    school_id,case_id,event_type,actor_id,before_state,after_state
  ) values (
    new.school_id,new.id,
    case when tg_op='INSERT' then 'case_opened'
      when old.appeal_status is distinct from new.appeal_status then 'appeal_reviewed'
      when old.staff_response is distinct from new.staff_response then 'staff_response'
      when old.status is distinct from new.status then 'case_status_changed'
      else 'case_updated' end,
    auth.uid(),
    case when tg_op='INSERT' then null else to_jsonb(old) end,
    to_jsonb(new)
  );
  return new;
end;
$function$;

drop trigger if exists schoolpro_staff_discipline_event_history on public.schoolpro_staff_disciplinary_cases;
create trigger schoolpro_staff_discipline_event_history
after insert or update on public.schoolpro_staff_disciplinary_cases
for each row execute function private.capture_schoolpro_staff_discipline_event();

alter table public.schoolpro_leave_events enable row level security;
alter table public.schoolpro_staff_disciplinary_cases enable row level security;
alter table public.schoolpro_staff_disciplinary_events enable row level security;

drop policy if exists "C0 leave event read" on public.schoolpro_leave_events;
create policy "C0 leave event read" on public.schoolpro_leave_events
for select to authenticated using (
  exists (
    select 1 from public.schoolpro_leave_requests lr
    join public.schoolpro_members m on m.id=lr.member_id and m.school_id=lr.school_id
    where lr.id=schoolpro_leave_events.leave_request_id
      and lr.school_id=schoolpro_leave_events.school_id
      and (m.user_id=auth.uid() or private.has_school_access(
        lr.school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[]
      ))
  )
);

create policy "C0 staff discipline case read" on public.schoolpro_staff_disciplinary_cases
for select to authenticated using (
  exists (
    select 1 from public.schoolpro_members m
    where m.id=schoolpro_staff_disciplinary_cases.member_id
      and m.school_id=schoolpro_staff_disciplinary_cases.school_id
      and (
        m.user_id=auth.uid()
        or private.has_school_access(
          schoolpro_staff_disciplinary_cases.school_id,
          array['proprietor','administrator','hr_officer']::public.school_member_role[]
        )
      )
  )
);

create policy "C0 staff discipline event read" on public.schoolpro_staff_disciplinary_events
for select to authenticated using (
  exists (
    select 1 from public.schoolpro_staff_disciplinary_cases c
    join public.schoolpro_members m on m.id=c.member_id and m.school_id=c.school_id
    where c.id=schoolpro_staff_disciplinary_events.case_id
      and c.school_id=schoolpro_staff_disciplinary_events.school_id
      and (
        m.user_id=auth.uid()
        or private.has_school_access(
          c.school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[]
        )
      )
  )
);

revoke all on public.schoolpro_leave_events from anon,authenticated;
grant select on public.schoolpro_leave_events to authenticated;
revoke insert,update,delete on public.schoolpro_staff_disciplinary_cases from anon,authenticated;
grant select on public.schoolpro_staff_disciplinary_cases to authenticated;
revoke all on public.schoolpro_staff_disciplinary_events from anon,authenticated;
grant select on public.schoolpro_staff_disciplinary_events to authenticated;
revoke all on function private.capture_schoolpro_leave_event() from public,anon,authenticated;
revoke all on function private.capture_schoolpro_staff_discipline_event() from public,anon,authenticated;

create or replace function public.schoolpro_report_own_absence(
  p_school uuid,p_start date,p_end date,p_reason text default null
) returns uuid
language plpgsql security definer set search_path=''
as $function$
declare v_member uuid; v_id uuid; v_reason text:=nullif(btrim(coalesce(p_reason,'')),'');
begin
  if auth.uid() is null or not private.is_active_account()
    or not private.schoolpro_module_allowed(p_school,'leave') then
    raise exception 'Active school leave access is required';
  end if;
  select id into v_member from public.schoolpro_members
  where school_id=p_school and user_id=auth.uid() and status='active'
  for update;
  if v_member is null then raise exception 'Active staff membership not found'; end if;
  if p_start is null or p_end is null or p_end<p_start then
    raise exception 'Choose valid absence dates';
  end if;
  if v_reason is not null and length(v_reason)>4000 then
    raise exception 'Absence reason is too long';
  end if;
  insert into public.schoolpro_leave_requests(
    school_id,member_id,leave_type,start_date,end_date,reason,status,
    request_type,absence_reported_at,reason_updated_at,reason_updated_by
  ) values (
    p_school,v_member,'Absence',p_start,p_end,v_reason,'pending',
    'absence_report',now(),case when v_reason is null then null else now() end,
    case when v_reason is null then null else auth.uid() end
  ) returning id into v_id;
  return v_id;
end;
$function$;

create or replace function public.schoolpro_update_own_leave_reason(
  p_request uuid,p_reason text
) returns void
language plpgsql security definer set search_path=''
as $function$
declare target public.schoolpro_leave_requests;
begin
  if auth.uid() is null or not private.is_active_account()
    or length(btrim(coalesce(p_reason,''))) not between 10 and 4000 then
    raise exception 'Provide an explanation between 10 and 4000 characters';
  end if;
  select * into target from public.schoolpro_leave_requests
  where id=p_request for update;
  if target.id is null then raise exception 'Leave or absence record not found'; end if;
  if not exists (
    select 1 from public.schoolpro_members m
    where m.id=target.member_id and m.school_id=target.school_id
      and m.user_id=auth.uid()
  ) then raise exception 'You can update only your own absence reason'; end if;
  if target.status<>'pending' then
    raise exception 'Only a pending leave or absence record can have its reason updated';
  end if;
  update public.schoolpro_leave_requests
  set reason=btrim(p_reason),reason_updated_at=now(),reason_updated_by=auth.uid()
  where id=target.id;
end;
$function$;

create or replace function public.schoolpro_review_leave_request(
  p_request uuid,p_decision text,p_note text default null
) returns void
language plpgsql security definer set search_path=''
as $function$
declare target public.schoolpro_leave_requests;
begin
  select * into target from public.schoolpro_leave_requests
  where id=p_request for update;
  if target.id is null then raise exception 'Leave request not found'; end if;
  if auth.uid() is null or not private.is_active_account()
    or not private.schoolpro_module_allowed(target.school_id,'leave')
    or not private.has_school_access(
      target.school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[]
    ) then raise exception 'HR or school leadership access is required'; end if;
  if p_decision not in ('approved','rejected') or target.status<>'pending' then
    raise exception 'Choose a pending request and a valid decision';
  end if;
  if exists(select 1 from public.schoolpro_members m
    where m.id=target.member_id and m.user_id=auth.uid()) then
    raise exception 'Another authorised person must review your own request';
  end if;
  update public.schoolpro_leave_requests
  set status=p_decision,review_note=nullif(btrim(coalesce(p_note,'')),'')
  where id=target.id;
end;
$function$;

create or replace function public.schoolpro_create_staff_disciplinary_case(
  p_school uuid,p_member uuid,p_action text,p_severity text,
  p_summary text,p_details text default null,p_effective_at timestamptz default now()
) returns uuid
language plpgsql security definer set search_path=''
as $function$
declare v_case uuid; v_reason text;
begin
  if auth.uid() is null or not private.is_active_account()
    or not private.schoolpro_module_allowed(p_school,'staff')
    or not private.has_school_access(
      p_school,array['proprietor','administrator','hr_officer']::public.school_member_role[]
    ) then raise exception 'HR or school leadership access is required'; end if;
  if p_action not in ('verbal_warning','written_warning','final_warning','investigation','performance_plan','suspension','dismissal')
    or p_severity not in ('low','moderate','high','critical')
    or length(btrim(coalesce(p_summary,''))) not between 10 and 500 then
    raise exception 'Choose a valid action, severity and case summary';
  end if;
  if not exists(select 1 from public.schoolpro_members m
    where m.id=p_member and m.school_id=p_school
      and (m.status='active' or (p_action='dismissal' and m.status='suspended' and m.employment_status<>'dismissed'))) then
    raise exception 'Choose an eligible active or suspended staff membership';
  end if;
  if p_effective_at>now() then raise exception 'Future-dated disciplinary actions are not supported; use an approved HR decision when effective'; end if;
  if p_action in ('suspension','dismissal')
    and not private.has_school_access(
      p_school,array['proprietor','administrator']::public.school_member_role[]
    ) then
    raise exception 'Only the proprietor or administrator can execute suspension or dismissal';
  end if;
  insert into public.schoolpro_staff_disciplinary_cases(
    school_id,member_id,action_type,severity,summary,details,status,effective_at,created_by
  ) values (
    p_school,p_member,p_action,p_severity,btrim(p_summary),nullif(btrim(coalesce(p_details,'')),''),
    'open',coalesce(p_effective_at,now()),auth.uid()
  ) returning id into v_case;

  if p_action in ('suspension','dismissal') then
    v_reason:='Disciplinary case '||v_case::text||': '||btrim(p_summary);
    if exists(select 1 from public.schoolpro_members m where m.id=p_member and m.status='active') then
      perform private.schoolpro_set_member_suspension_state(p_school,p_member,true,v_reason);
    end if;
    if p_action='dismissal' then
      update public.schoolpro_members set employment_status='dismissed'
      where id=p_member and school_id=p_school;
    end if;
  end if;

  update public.schoolpro_staff_disciplinary_cases
  set status='action_issued',updated_at=now()
  where id=v_case;
  return v_case;
end;
$function$;

create or replace function public.schoolpro_submit_staff_disciplinary_response(
  p_case uuid,p_response text,p_appeal boolean default false
) returns void
language plpgsql security definer set search_path=''
as $function$
declare target public.schoolpro_staff_disciplinary_cases;
begin
  if auth.uid() is null or not private.is_active_account()
    or length(btrim(coalesce(p_response,''))) not between 10 and 4000 then
    raise exception 'Provide a response between 10 and 4000 characters';
  end if;
  select c.* into target
  from public.schoolpro_staff_disciplinary_cases c
  join public.schoolpro_members m on m.id=c.member_id and m.school_id=c.school_id
  where c.id=p_case and m.user_id=auth.uid()
  for update of c;
  if target.id is null then raise exception 'Your disciplinary case was not found'; end if;
  if target.status='closed' then raise exception 'This case is closed'; end if;
  update public.schoolpro_staff_disciplinary_cases
  set staff_response=btrim(p_response),response_at=now(),
      appeal_status=case when p_appeal then 'pending' else appeal_status end,
      appeal_submitted_at=case when p_appeal then now() else appeal_submitted_at end,
      status=case when p_appeal then 'appealed' else status end,
      updated_at=now()
  where id=target.id;
end;
$function$;

create or replace function public.schoolpro_review_staff_appeal(
  p_case uuid,p_decision text,p_note text
) returns void
language plpgsql security definer set search_path=''
as $function$
declare target public.schoolpro_staff_disciplinary_cases;
begin
  select * into target from public.schoolpro_staff_disciplinary_cases
  where id=p_case for update;
  if target.id is null then raise exception 'Disciplinary case not found'; end if;
  if auth.uid() is null or not private.is_active_account()
    or not private.schoolpro_module_allowed(target.school_id,'staff')
    or not private.has_school_access(
      target.school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[]
    ) then raise exception 'HR or school leadership access is required'; end if;
  if target.appeal_status<>'pending' or p_decision not in ('accepted','rejected')
    or length(btrim(coalesce(p_note,''))) not between 5 and 2000 then
    raise exception 'Choose a pending appeal and provide a review note';
  end if;
  update public.schoolpro_staff_disciplinary_cases
  set appeal_status=p_decision,appeal_review_note=btrim(p_note),
      appeal_reviewed_by=auth.uid(),appeal_reviewed_at=now(),updated_at=now()
  where id=target.id;
end;
$function$;

drop policy if exists "C0 leave own pending update" on public.schoolpro_leave_requests;

revoke all on function public.schoolpro_report_own_absence(uuid,date,date,text) from public,anon;
revoke all on function public.schoolpro_update_own_leave_reason(uuid,text) from public,anon;
revoke all on function public.schoolpro_review_leave_request(uuid,text,text) from public,anon;
revoke all on function public.schoolpro_create_staff_disciplinary_case(uuid,uuid,text,text,text,text,timestamptz) from public,anon;
revoke all on function public.schoolpro_submit_staff_disciplinary_response(uuid,text,boolean) from public,anon;
revoke all on function public.schoolpro_review_staff_appeal(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_report_own_absence(uuid,date,date,text) to authenticated;
grant execute on function public.schoolpro_update_own_leave_reason(uuid,text) to authenticated;
grant execute on function public.schoolpro_review_leave_request(uuid,text,text) to authenticated;
grant execute on function public.schoolpro_create_staff_disciplinary_case(uuid,uuid,text,text,text,text,timestamptz) to authenticated;
grant execute on function public.schoolpro_submit_staff_disciplinary_response(uuid,text,boolean) to authenticated;
grant execute on function public.schoolpro_review_staff_appeal(uuid,text,text) to authenticated;

commit;
