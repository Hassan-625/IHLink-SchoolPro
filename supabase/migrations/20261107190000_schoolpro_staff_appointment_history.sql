-- Stage C0: immutable snapshots for staff appointment end/reappointment events.
-- Captures the pre-change row so tables with legacy uniqueness constraints can
-- reuse their current row without erasing the former appointment evidence.

create table if not exists public.schoolpro_staff_appointment_history (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete restrict,
  member_id uuid,
  appointment_type text not null,
  appointment_record_id text not null,
  event_type text not null check (event_type in ('ended','reappointed','assigned','reassigned')),
  actor_id uuid references auth.users(id) on delete set null,
  event_at timestamptz not null default now(),
  reason text,
  snapshot jsonb not null default '{}'::jsonb
);

create index if not exists schoolpro_staff_appointment_history_member_idx
  on public.schoolpro_staff_appointment_history(school_id,member_id,event_at desc);

alter table public.schoolpro_staff_appointment_history enable row level security;
revoke all on public.schoolpro_staff_appointment_history from public,anon,authenticated;
grant select on public.schoolpro_staff_appointment_history to authenticated;

drop policy if exists "Staff appointment history scoped read" on public.schoolpro_staff_appointment_history;
create policy "Staff appointment history scoped read"
on public.schoolpro_staff_appointment_history for select to authenticated
using (
  private.has_school_access(
    school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[]
  )
  or exists(
    select 1 from public.schoolpro_members m
    where m.school_id=schoolpro_staff_appointment_history.school_id
      and m.id=schoolpro_staff_appointment_history.member_id
      and m.user_id=auth.uid()
  )
);

create or replace function private.capture_schoolpro_staff_appointment_history()
returns trigger language plpgsql security definer set search_path=''
as $function$
declare
  old_json jsonb;
  new_json jsonb := to_jsonb(new);
  snapshot_json jsonb;
  old_ended timestamptz;
  new_ended timestamptz;
  old_member uuid;
  new_member uuid;
  school_key uuid;
  record_key text;
  event_key text;
  reason_text text;
begin
  if tg_op='UPDATE' then old_json:=to_jsonb(old); end if;
  school_key := coalesce(nullif(new_json->>'school_id','')::uuid,
    nullif(old_json->>'school_id','')::uuid);
  old_member := coalesce(
    nullif(old_json->>'member_id','')::uuid,
    nullif(old_json->>'teacher_member_id','')::uuid,
    nullif(old_json->>'form_teacher_id','')::uuid
  );
  new_member := coalesce(
    nullif(new_json->>'member_id','')::uuid,
    nullif(new_json->>'teacher_member_id','')::uuid,
    nullif(new_json->>'form_teacher_id','')::uuid
  );
  record_key := coalesce(new_json->>'id',new_json->>'member_id',
    old_json->>'id',old_json->>'member_id');

  if tg_op='INSERT' then
    if new_member is null then return new; end if;
    event_key:='assigned';
    snapshot_json:=new_json;
  elsif tg_table_name='schoolpro_classes' then
    if old_member is not null and new_member is null then event_key:='ended';
    elsif old_member is null and new_member is not null then event_key:='assigned';
    elsif old_member is distinct from new_member then event_key:='reassigned';
    else return new;
    end if;
    snapshot_json:=old_json;
  else
    old_ended:=nullif(old_json->>'ended_at','')::timestamptz;
    new_ended:=nullif(new_json->>'ended_at','')::timestamptz;
    if old_ended is null and new_ended is not null then event_key:='ended';
    elsif old_ended is not null and new_ended is null then event_key:='reappointed';
    else return new;
    end if;
    snapshot_json:=old_json;
  end if;

  reason_text:=coalesce(new_json->>'end_reason',new_json->>'suspension_reason');
  insert into public.schoolpro_staff_appointment_history(
    school_id,member_id,appointment_type,appointment_record_id,event_type,
    actor_id,event_at,reason,snapshot
  ) values(
    school_key,coalesce(old_member,new_member),tg_table_name,
    coalesce(record_key,'unknown'),event_key,auth.uid(),now(),reason_text,
    coalesce(snapshot_json,'{}'::jsonb)
  );
  return new;
end
$function$;

revoke all on function private.capture_schoolpro_staff_appointment_history() from public,anon,authenticated;

drop trigger if exists schoolpro_appointment_history_board on public.schoolpro_board_members;
create trigger schoolpro_appointment_history_board
before update on public.schoolpro_board_members
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_section on public.schoolpro_section_leaders;
create trigger schoolpro_appointment_history_section
before update on public.schoolpro_section_leaders
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_subject on public.schoolpro_subject_assignments;
create trigger schoolpro_appointment_history_subject
before update on public.schoolpro_subject_assignments
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_house on public.schoolpro_house_master_assignments;
create trigger schoolpro_appointment_history_house
before update on public.schoolpro_house_master_assignments
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_judge on public.schoolpro_competition_judges;
create trigger schoolpro_appointment_history_judge
before update on public.schoolpro_competition_judges
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_form_master on public.schoolpro_classes;
create trigger schoolpro_appointment_history_form_master
before update of form_teacher_id on public.schoolpro_classes
for each row execute function private.capture_schoolpro_staff_appointment_history();


drop trigger if exists schoolpro_appointment_history_insert_board_members on public.schoolpro_board_members;
create trigger schoolpro_appointment_history_insert_board_members
after insert on public.schoolpro_board_members
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_insert_section_leaders on public.schoolpro_section_leaders;
create trigger schoolpro_appointment_history_insert_section_leaders
after insert on public.schoolpro_section_leaders
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_insert_subject_assignments on public.schoolpro_subject_assignments;
create trigger schoolpro_appointment_history_insert_subject_assignments
after insert on public.schoolpro_subject_assignments
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_insert_house_master_assignments on public.schoolpro_house_master_assignments;
create trigger schoolpro_appointment_history_insert_house_master_assignments
after insert on public.schoolpro_house_master_assignments
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_insert_competition_judges on public.schoolpro_competition_judges;
create trigger schoolpro_appointment_history_insert_competition_judges
after insert on public.schoolpro_competition_judges
for each row execute function private.capture_schoolpro_staff_appointment_history();

drop trigger if exists schoolpro_appointment_history_form_master_insert on public.schoolpro_classes;
create trigger schoolpro_appointment_history_form_master_insert
after insert on public.schoolpro_classes
for each row execute function private.capture_schoolpro_staff_appointment_history();
