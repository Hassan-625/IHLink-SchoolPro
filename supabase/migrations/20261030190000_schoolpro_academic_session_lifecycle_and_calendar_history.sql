-- Stage B1: explicit school-session lifecycle and append-only calendar history.
-- Proposed only. This migration is not applied to production by this change.

create table if not exists public.schoolpro_academic_sessions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  session text not null check (
    session ~ '^[0-9]{4}/[0-9]{4}$'
    and split_part(session, '/', 2)::integer = split_part(session, '/', 1)::integer + 1
  ),
  start_date date not null,
  end_date date not null,
  status text not null default 'upcoming'
    check (status in ('upcoming','active','completed','archived')),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id, session),
  check (end_date >= start_date)
);

create index if not exists schoolpro_academic_sessions_school_dates_idx
  on public.schoolpro_academic_sessions(school_id, start_date, end_date);

create table if not exists public.schoolpro_academic_calendar_history (
  id bigint generated always as identity primary key,
  school_id uuid not null,
  session text not null,
  term text,
  change_type text not null check (change_type in ('session_created','session_updated','session_archived','term_created','term_updated')),
  before_state jsonb,
  after_state jsonb not null,
  changed_by uuid references auth.users(id) on delete set null,
  changed_at timestamptz not null default now()
);

create index if not exists schoolpro_academic_calendar_history_lookup_idx
  on public.schoolpro_academic_calendar_history(school_id, session, changed_at desc);

alter table public.schoolpro_academic_sessions enable row level security;
alter table public.schoolpro_academic_calendar_history enable row level security;

drop policy if exists schoolpro_academic_sessions_school_read on public.schoolpro_academic_sessions;
create policy schoolpro_academic_sessions_school_read
  on public.schoolpro_academic_sessions for select to authenticated
  using (private.has_school_access(school_id, array[
    'proprietor'::public.school_member_role, 'administrator'::public.school_member_role,
    'vice_principal'::public.school_member_role, 'head_teacher'::public.school_member_role,
    'registrar'::public.school_member_role, 'exam_officer'::public.school_member_role,
    'teacher'::public.school_member_role, 'class_teacher'::public.school_member_role
  ]) or private.is_admin(array['super_admin'::public.user_role]));

drop policy if exists schoolpro_academic_calendar_history_school_read on public.schoolpro_academic_calendar_history;
create policy schoolpro_academic_calendar_history_school_read
  on public.schoolpro_academic_calendar_history for select to authenticated
  using (private.has_school_access(school_id, array[
    'proprietor'::public.school_member_role, 'administrator'::public.school_member_role,
    'vice_principal'::public.school_member_role, 'head_teacher'::public.school_member_role,
    'registrar'::public.school_member_role, 'exam_officer'::public.school_member_role
  ]) or private.is_admin(array['super_admin'::public.user_role]));

revoke insert, update, delete on public.schoolpro_academic_sessions from anon, authenticated;
revoke insert, update, delete on public.schoolpro_academic_calendar_history from anon, authenticated;
grant select on public.schoolpro_academic_sessions, public.schoolpro_academic_calendar_history to authenticated;
grant usage, select on sequence public.schoolpro_academic_calendar_history_id_seq to authenticated;

create or replace function private.schoolpro_record_calendar_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  old_state jsonb;
  new_state jsonb;
  school uuid;
  session_key text;
  term_key text;
  change text;
begin
  if tg_table_name = 'schoolpro_academic_sessions' then
    if tg_op = 'DELETE' then
      raise exception 'Academic sessions cannot be deleted; archive them instead';
    end if;
    if tg_op = 'UPDATE' then
      old_state := to_jsonb(old);
      new_state := to_jsonb(new);
      if old_state - 'updated_at' - 'updated_by' is not distinct from new_state - 'updated_at' - 'updated_by' then
        return new;
      end if;
      change := case when new.status = 'archived' and old.status <> 'archived'
        then 'session_archived' else 'session_updated' end;
    else
      new_state := to_jsonb(new);
      change := 'session_created';
    end if;
    school := new.school_id;
    session_key := new.session;
  else
    if tg_op = 'DELETE' then
      raise exception 'Academic term records cannot be deleted; amend the calendar instead';
    end if;
    if tg_op = 'UPDATE' then
      old_state := to_jsonb(old);
      new_state := to_jsonb(new);
      if old_state - 'updated_at' - 'updated_by' is not distinct from new_state - 'updated_at' - 'updated_by' then
        return new;
      end if;
      change := 'term_updated';
    else
      new_state := to_jsonb(new);
      change := 'term_created';
    end if;
    school := new.school_id;
    session_key := new.session;
    term_key := new.term;
  end if;

  insert into public.schoolpro_academic_calendar_history
    (school_id, session, term, change_type, before_state, after_state, changed_by)
  values
    (school, session_key, term_key, change, old_state, new_state, auth.uid());
  return new;
end;
$$;

revoke all on function private.schoolpro_record_calendar_history() from public, anon, authenticated;

drop trigger if exists schoolpro_academic_session_history on public.schoolpro_academic_sessions;
create trigger schoolpro_academic_session_history
  after insert or update or delete on public.schoolpro_academic_sessions
  for each row execute function private.schoolpro_record_calendar_history();

drop trigger if exists schoolpro_academic_term_history on public.schoolpro_result_term_settings;
create trigger schoolpro_academic_term_history
  after insert or update or delete on public.schoolpro_result_term_settings
  for each row execute function private.schoolpro_record_calendar_history();

create or replace function public.schoolpro_save_academic_session(
  p_school uuid, p_session text, p_start date, p_end date, p_notes text default null
) returns public.schoolpro_academic_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare result public.schoolpro_academic_sessions;
begin
  if not private.schoolpro_module_allowed(p_school, 'calendar')
     or not private.schoolpro_module_allowed(p_school, 'promotions') then
    raise exception 'Academic calendar management permission required';
  end if;
  if p_session !~ '^[0-9]{4}/[0-9]{4}$'
     or split_part(p_session, '/', 2)::integer <> split_part(p_session, '/', 1)::integer + 1
     or p_start is null or p_end is null or p_end < p_start then
    raise exception 'Enter a valid academic session and date range';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(p_school::text || ':academic-sessions', 0));
  if exists (
    select 1 from public.schoolpro_academic_sessions s
    where s.school_id = p_school and s.session <> p_session
      and s.status <> 'archived'
      and s.start_date <= p_end and s.end_date >= p_start
  ) then
    raise exception 'Academic session dates cannot overlap another non-archived session';
  end if;

  insert into public.schoolpro_academic_sessions
    (school_id, session, start_date, end_date, status, notes, created_by, updated_by)
  values
    (p_school, p_session, p_start, p_end,
     case when current_date < p_start then 'upcoming' when current_date > p_end then 'completed' else 'active' end,
     nullif(trim(p_notes), ''), auth.uid(), auth.uid())
  on conflict (school_id, session) do update
    set start_date = excluded.start_date,
        end_date = excluded.end_date,
        notes = excluded.notes,
        updated_by = auth.uid(),
        updated_at = now(),
        status = case
          when public.schoolpro_academic_sessions.status = 'archived' then 'archived'
          when current_date < excluded.start_date then 'upcoming'
          when current_date > excluded.end_date then 'completed'
          else 'active'
        end
  returning * into result;

  insert into public.schoolpro_audit_logs
    (school_id, actor_id, action, entity_type, entity_id, metadata)
  values
    (p_school, auth.uid(), 'Academic session saved', 'school', p_school,
     jsonb_build_object('session', p_session, 'start', p_start, 'end', p_end));
  return result;
end;
$$;

revoke all on function public.schoolpro_save_academic_session(uuid,text,date,date,text) from public, anon;
grant execute on function public.schoolpro_save_academic_session(uuid,text,date,date,text) to authenticated;

create or replace function public.schoolpro_archive_academic_session(
  p_school uuid, p_session text
) returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.schoolpro_module_allowed(p_school, 'calendar')
     or not private.schoolpro_module_allowed(p_school, 'promotions') then
    raise exception 'Academic calendar management permission required';
  end if;
  update public.schoolpro_academic_sessions
    set status = 'archived', updated_by = auth.uid(), updated_at = now()
  where school_id = p_school and session = p_session and end_date < current_date;
  if not found then
    raise exception 'Only a completed academic session can be archived';
  end if;
end;
$$;

revoke all on function public.schoolpro_archive_academic_session(uuid,text) from public, anon;
grant execute on function public.schoolpro_archive_academic_session(uuid,text) to authenticated;
