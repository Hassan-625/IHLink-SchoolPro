-- Stage C0: richer student discipline case management and immutable case history.
begin;

revoke delete,truncate on public.schoolpro_discipline_records from anon,authenticated;

alter table public.schoolpro_discipline_records
  add column if not exists category text not null default 'general',
  add column if not exists severity text not null default 'moderate',
  add column if not exists incident_at timestamptz not null default now(),
  add column if not exists location text,
  add column if not exists student_response text,
  add column if not exists guardian_contact_status text not null default 'not_required',
  add column if not exists guardian_contacted_at timestamptz,
  add column if not exists guardian_contact_note text,
  add column if not exists assigned_to uuid references public.schoolpro_members(id) on delete set null,
  add column if not exists follow_up_at date,
  add column if not exists follow_up_outcome text,
  add column if not exists resolved_at timestamptz,
  add column if not exists resolved_by uuid references auth.users(id);

alter table public.schoolpro_discipline_records
  drop constraint if exists schoolpro_discipline_records_severity_check;
alter table public.schoolpro_discipline_records
  add constraint schoolpro_discipline_records_severity_check
  check (severity in ('low','moderate','high','critical'));

alter table public.schoolpro_discipline_records
  drop constraint if exists schoolpro_discipline_records_guardian_contact_status_check;
alter table public.schoolpro_discipline_records
  add constraint schoolpro_discipline_records_guardian_contact_status_check
  check (guardian_contact_status in ('not_required','pending','contacted','unable_to_contact'));

create table if not exists public.schoolpro_discipline_events (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete restrict,
  discipline_record_id uuid not null references public.schoolpro_discipline_records(id) on delete restrict,
  event_type text not null,
  actor_id uuid references auth.users(id) on delete set null,
  before_state jsonb,
  after_state jsonb not null,
  created_at timestamptz not null default now()
);
create index if not exists schoolpro_discipline_events_record_idx
  on public.schoolpro_discipline_events(school_id,discipline_record_id,created_at desc);

create or replace function private.validate_schoolpro_discipline_case()
returns trigger language plpgsql security definer set search_path=''
as $function$
begin
  if length(btrim(coalesce(new.incident,''))) not between 5 and 4000 then
    raise exception 'Describe the incident in at least five characters';
  end if;
  if new.category not in ('general','misconduct','bullying','violence','truancy','property_damage','academic_misconduct','substance_concern','safeguarding','other') then
    raise exception 'Choose a valid incident category';
  end if;
  if new.severity not in ('low','moderate','high','critical') then
    raise exception 'Choose a valid incident severity';
  end if;
  if new.assigned_to is not null and not exists (
    select 1 from public.schoolpro_members m
    where m.id=new.assigned_to and m.school_id=new.school_id and m.status='active'
  ) then raise exception 'Choose an active staff member for follow-up'; end if;
  if tg_op='UPDATE' then
    if new.school_id is distinct from old.school_id
      or new.student_id is distinct from old.student_id
      or new.created_by is distinct from old.created_by then
      raise exception 'A discipline case cannot be moved or have its reporter changed';
    end if;
  end if;
  if new.status='resolved' and (tg_op='INSERT' or old.status is distinct from 'resolved') then
    new.resolved_at:=now();new.resolved_by:=auth.uid();
  elsif new.status<>'resolved' then
    new.resolved_at:=null;new.resolved_by:=null;
  end if;
  return new;
end;
$function$;

drop trigger if exists schoolpro_validate_discipline_case on public.schoolpro_discipline_records;
create trigger schoolpro_validate_discipline_case
before insert or update on public.schoolpro_discipline_records
for each row execute function private.validate_schoolpro_discipline_case();

create or replace function private.capture_schoolpro_discipline_event()
returns trigger language plpgsql security definer set search_path=''
as $function$
begin
  insert into public.schoolpro_discipline_events(
    school_id,discipline_record_id,event_type,actor_id,before_state,after_state
  ) values (
    new.school_id,new.id,
    case when tg_op='INSERT' then 'incident_reported'
      when old.status is distinct from new.status then 'case_status_changed'
      when old.action_taken is distinct from new.action_taken then 'action_updated'
      when old.student_response is distinct from new.student_response then 'student_response_recorded'
      when old.guardian_contact_status is distinct from new.guardian_contact_status then 'guardian_contact_updated'
      else 'case_updated' end,
    auth.uid(),
    case when tg_op='INSERT' then null else to_jsonb(old) end,
    to_jsonb(new)
  );
  return new;
end;
$function$;

drop trigger if exists schoolpro_discipline_event_history on public.schoolpro_discipline_records;
create trigger schoolpro_discipline_event_history
after insert or update on public.schoolpro_discipline_records
for each row execute function private.capture_schoolpro_discipline_event();

alter table public.schoolpro_discipline_events enable row level security;
drop policy if exists "C0 student discipline event read" on public.schoolpro_discipline_events;
create policy "C0 student discipline event read"
on public.schoolpro_discipline_events for select to authenticated
using (
  exists (
    select 1 from public.schoolpro_discipline_records d
    where d.id=schoolpro_discipline_events.discipline_record_id
      and d.school_id=schoolpro_discipline_events.school_id
      and (
        d.created_by=auth.uid()
        or private.has_school_access(
          d.school_id,array['proprietor','administrator','vice_principal','head_teacher','counsellor','discipline_master']::public.school_member_role[]
        )
      )
  )
);
revoke all on public.schoolpro_discipline_events from anon,authenticated;
grant select on public.schoolpro_discipline_events to authenticated;
revoke all on function private.validate_schoolpro_discipline_case() from public,anon,authenticated;
revoke all on function private.capture_schoolpro_discipline_event() from public,anon,authenticated;

-- Replace the broad manager ALL policy so a manager cannot hard-delete a case.
drop policy if exists "discipline authorized access" on public.schoolpro_discipline_records;
create policy "C0 discipline managers read"
on public.schoolpro_discipline_records for select to authenticated
using (
  private.schoolpro_module_allowed(school_id,'discipline')
  and private.has_school_access(
    school_id,array['proprietor','administrator','vice_principal','head_teacher','counsellor','discipline_master']::public.school_member_role[]
  )
);
create policy "C0 discipline managers update"
on public.schoolpro_discipline_records for update to authenticated
using (
  private.schoolpro_module_allowed(school_id,'discipline')
  and private.has_school_access(
    school_id,array['proprietor','administrator','vice_principal','head_teacher','counsellor','discipline_master']::public.school_member_role[]
  )
)
with check (
  private.schoolpro_module_allowed(school_id,'discipline')
  and private.has_school_access(
    school_id,array['proprietor','administrator','vice_principal','head_teacher','counsellor','discipline_master']::public.school_member_role[]
  )
);
create policy "C0 discipline managers insert"
on public.schoolpro_discipline_records for insert to authenticated
with check (
  private.schoolpro_module_allowed(school_id,'discipline')
  and private.has_school_access(
    school_id,array['proprietor','administrator','vice_principal','head_teacher','counsellor','discipline_master']::public.school_member_role[]
  )
);

drop policy if exists "Assigned teachers report concerns" on public.schoolpro_discipline_records;
create policy "Assigned active teachers report concerns"
on public.schoolpro_discipline_records for insert to authenticated
with check (
  private.schoolpro_module_allowed(school_id,'discipline')
  and created_by=auth.uid()
  and student_id is not null
  and private.schoolpro_can_read_student(student_id)
  and exists (
    select 1 from public.schoolpro_students s
    where s.id=schoolpro_discipline_records.student_id and s.school_id=schoolpro_discipline_records.school_id
  )
  and status='open'
  and coalesce(action_taken,'')=''
  and exists (
    select 1 from public.schoolpro_members m
    where m.school_id=schoolpro_discipline_records.school_id and m.user_id=auth.uid()
      and m.status='active'
      and m.role::text in ('teacher','class_teacher','discipline_master')
  )
);

commit;
