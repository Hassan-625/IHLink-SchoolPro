-- Session-scoped instructional calendar and authoritative attendance-day enforcement.
-- Generated filename by Supabase CLI 3.1.0; implementation remains migration-only until reviewed.

create table public.schoolpro_instructional_calendar_settings (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  session text not null check (private.schoolpro_valid_session(session)),
  is_configured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid,
  updated_by uuid,
  constraint schoolpro_instructional_calendar_settings_school_session_key unique (school_id, session)
);

create table public.schoolpro_instructional_weekdays (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  session text not null,
  iso_weekday smallint not null check (iso_weekday between 1 and 7),
  is_instructional boolean not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid,
  updated_by uuid,
  constraint schoolpro_instructional_weekdays_school_session_day_key unique (school_id, session, iso_weekday),
  constraint schoolpro_instructional_weekdays_calendar_fk
    foreign key (school_id, session)
    references public.schoolpro_instructional_calendar_settings(school_id, session)
    on delete cascade
);

create table public.schoolpro_instructional_calendar_exceptions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  session text not null,
  calendar_date date not null,
  exception_type text not null check (
    exception_type in ('public_holiday','school_holiday','emergency_closure','make_up_instructional')
  ),
  title text not null check (length(btrim(title)) > 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid,
  updated_by uuid,
  constraint schoolpro_instructional_calendar_exceptions_school_session_date_key
    unique (school_id, session, calendar_date),
  constraint schoolpro_instructional_calendar_exceptions_calendar_fk
    foreign key (school_id, session)
    references public.schoolpro_instructional_calendar_settings(school_id, session)
    on delete cascade
);

create index schoolpro_instructional_exceptions_date_idx
  on public.schoolpro_instructional_calendar_exceptions(school_id, session, calendar_date);
create index schoolpro_instructional_weekdays_lookup_idx
  on public.schoolpro_instructional_weekdays(school_id, session, iso_weekday);

alter table public.schoolpro_instructional_calendar_settings enable row level security;
alter table public.schoolpro_instructional_weekdays enable row level security;
alter table public.schoolpro_instructional_calendar_exceptions enable row level security;

create or replace function private.schoolpro_can_read_instructional_calendar(p_school uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and (
      private.is_admin(array['super_admin']::public.user_role[])
      or exists (
        select 1 from public.schoolpro_schools s
        where s.id = p_school and s.owner_id = auth.uid()
      )
      or exists (
        select 1 from public.schoolpro_members m
        where m.school_id = p_school
          and m.user_id = auth.uid()
          and m.status = 'active'
      )
    );
$function$;

create or replace function private.schoolpro_can_manage_instructional_calendar(p_school uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and (
      exists (
        select 1 from public.schoolpro_schools s
        where s.id = p_school and s.owner_id = auth.uid()
      )
      or exists (
        select 1 from public.schoolpro_members m
        where m.school_id = p_school
          and m.user_id = auth.uid()
          and m.status = 'active'
          and m.role in ('proprietor','administrator')
      )
    );
$function$;

revoke all on function private.schoolpro_can_read_instructional_calendar(uuid) from public, anon;
revoke all on function private.schoolpro_can_manage_instructional_calendar(uuid) from public, anon;
grant execute on function private.schoolpro_can_read_instructional_calendar(uuid) to authenticated;
grant execute on function private.schoolpro_can_manage_instructional_calendar(uuid) to authenticated;

create policy "Instructional calendar same-school read"
  on public.schoolpro_instructional_calendar_settings
  for select to authenticated
  using (private.schoolpro_can_read_instructional_calendar(school_id));
create policy "Instructional calendar proprietor admin insert"
  on public.schoolpro_instructional_calendar_settings
  for insert to authenticated
  with check (private.schoolpro_can_manage_instructional_calendar(school_id));
create policy "Instructional calendar proprietor admin update"
  on public.schoolpro_instructional_calendar_settings
  for update to authenticated
  using (private.schoolpro_can_manage_instructional_calendar(school_id))
  with check (private.schoolpro_can_manage_instructional_calendar(school_id));
create policy "Instructional calendar proprietor admin delete"
  on public.schoolpro_instructional_calendar_settings
  for delete to authenticated
  using (private.schoolpro_can_manage_instructional_calendar(school_id));

create policy "Instructional weekdays same-school read"
  on public.schoolpro_instructional_weekdays
  for select to authenticated
  using (private.schoolpro_can_read_instructional_calendar(school_id));
create policy "Instructional weekdays proprietor admin insert"
  on public.schoolpro_instructional_weekdays
  for insert to authenticated
  with check (private.schoolpro_can_manage_instructional_calendar(school_id));
create policy "Instructional weekdays proprietor admin update"
  on public.schoolpro_instructional_weekdays
  for update to authenticated
  using (private.schoolpro_can_manage_instructional_calendar(school_id))
  with check (private.schoolpro_can_manage_instructional_calendar(school_id));
create policy "Instructional weekdays proprietor admin delete"
  on public.schoolpro_instructional_weekdays
  for delete to authenticated
  using (private.schoolpro_can_manage_instructional_calendar(school_id));

create policy "Instructional exceptions same-school read"
  on public.schoolpro_instructional_calendar_exceptions
  for select to authenticated
  using (private.schoolpro_can_read_instructional_calendar(school_id));
create policy "Instructional exceptions proprietor admin insert"
  on public.schoolpro_instructional_calendar_exceptions
  for insert to authenticated
  with check (private.schoolpro_can_manage_instructional_calendar(school_id));
create policy "Instructional exceptions proprietor admin update"
  on public.schoolpro_instructional_calendar_exceptions
  for update to authenticated
  using (private.schoolpro_can_manage_instructional_calendar(school_id))
  with check (private.schoolpro_can_manage_instructional_calendar(school_id));
create policy "Instructional exceptions proprietor admin delete"
  on public.schoolpro_instructional_calendar_exceptions
  for delete to authenticated
  using (private.schoolpro_can_manage_instructional_calendar(school_id));

revoke all on public.schoolpro_instructional_calendar_settings from public, anon;
revoke all on public.schoolpro_instructional_weekdays from public, anon;
revoke all on public.schoolpro_instructional_calendar_exceptions from public, anon;
grant select, insert, update, delete on public.schoolpro_instructional_calendar_settings to authenticated;
grant select, insert, update, delete on public.schoolpro_instructional_weekdays to authenticated;
grant select, insert, update, delete on public.schoolpro_instructional_calendar_exceptions to authenticated;

create or replace function private.schoolpro_touch_instructional_calendar_row()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  if tg_op = 'UPDATE' then
    if new.school_id is distinct from old.school_id
       or new.session is distinct from old.session then
      raise exception 'Instructional calendar school and session identity cannot be changed';
    end if;
    new.updated_at := now();
    new.updated_by := auth.uid();
  else
    new.created_by := coalesce(new.created_by, auth.uid());
    new.updated_by := auth.uid();
  end if;
  return new;
end;
$function$;

revoke all on function private.schoolpro_touch_instructional_calendar_row() from public, anon, authenticated;

create trigger schoolpro_instructional_settings_touch
  before insert or update on public.schoolpro_instructional_calendar_settings
  for each row execute function private.schoolpro_touch_instructional_calendar_row();
create trigger schoolpro_instructional_weekdays_touch
  before insert or update on public.schoolpro_instructional_weekdays
  for each row execute function private.schoolpro_touch_instructional_calendar_row();
create trigger schoolpro_instructional_exceptions_touch
  before insert or update on public.schoolpro_instructional_calendar_exceptions
  for each row execute function private.schoolpro_touch_instructional_calendar_row();

create or replace function private.schoolpro_sync_instructional_calendar_configuration()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  target_school uuid;
  target_session text;
begin
  if tg_op = 'DELETE' then
    target_school := old.school_id;
    target_session := old.session;
  else
    target_school := new.school_id;
    target_session := new.session;
  end if;

  update public.schoolpro_instructional_calendar_settings s
     set is_configured = (
       select count(*) = 7
       from public.schoolpro_instructional_weekdays w
       where w.school_id = target_school and w.session = target_session
     ),
         updated_at = now(),
         updated_by = auth.uid()
   where s.school_id = target_school and s.session = target_session;

  if tg_op = 'UPDATE'
     and (old.school_id, old.session) is distinct from (new.school_id, new.session) then
    update public.schoolpro_instructional_calendar_settings s
       set is_configured = (
         select count(*) = 7
         from public.schoolpro_instructional_weekdays w
         where w.school_id = old.school_id and w.session = old.session
       ),
           updated_at = now(),
           updated_by = auth.uid()
     where s.school_id = old.school_id and s.session = old.session;
  end if;

  return null;
end;
$function$;

revoke all on function private.schoolpro_sync_instructional_calendar_configuration() from public, anon, authenticated;
create trigger schoolpro_instructional_weekdays_sync_configuration
  after insert or update or delete on public.schoolpro_instructional_weekdays
  for each row execute function private.schoolpro_sync_instructional_calendar_configuration();

create trigger schoolpro_instructional_settings_audit
  after insert or update or delete on public.schoolpro_instructional_calendar_settings
  for each row execute function private.capture_schoolpro_audit_log();
create trigger schoolpro_instructional_weekdays_audit
  after insert or update or delete on public.schoolpro_instructional_weekdays
  for each row execute function private.capture_schoolpro_audit_log();
create trigger schoolpro_instructional_exceptions_audit
  after insert or update or delete on public.schoolpro_instructional_calendar_exceptions
  for each row execute function private.capture_schoolpro_audit_log();

create or replace function private.schoolpro_enforce_instructional_attendance_day()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_is_configured boolean;
  v_is_instructional boolean;
  v_exception_type text;
begin
  -- Preserve corrections to existing records when only status/notes or other
  -- non-identity fields change. Calendar changes do not retroactively invalidate them.
  if tg_op = 'UPDATE'
     and new.attendance_date is not distinct from old.attendance_date
     and new.school_id is not distinct from old.school_id
     and new.session is not distinct from old.session then
    return new;
  end if;

  if new.session is null or btrim(new.session) = '' then
    raise exception 'Choose an academic session before recording attendance';
  end if;

  -- Require the date to fall inside an explicitly configured term for the
  -- selected session; do not infer dates from free-text calendar events.
  if not exists (
    select 1
    from public.schoolpro_result_term_settings t
    where t.school_id = new.school_id
      and t.session = new.session
      and t.term_start_date is not null
      and t.term_end_date is not null
      and new.attendance_date between t.term_start_date and t.term_end_date
  ) then
    raise exception 'Attendance date must fall within a configured term in the selected academic session';
  end if;

  select s.is_configured
    into v_is_configured
  from public.schoolpro_instructional_calendar_settings s
  where s.school_id = new.school_id and s.session = new.session;

  if coalesce(v_is_configured, false) is not true then
    raise exception 'Configure all seven instructional weekdays before recording attendance for this session';
  end if;

  select e.exception_type
    into v_exception_type
  from public.schoolpro_instructional_calendar_exceptions e
  where e.school_id = new.school_id
    and e.session = new.session
    and e.calendar_date = new.attendance_date;

  if found then
    v_is_instructional := v_exception_type = 'make_up_instructional';
  else
    select w.is_instructional
      into v_is_instructional
    from public.schoolpro_instructional_weekdays w
    where w.school_id = new.school_id
      and w.session = new.session
      and w.iso_weekday = extract(isodow from new.attendance_date)::smallint;

    if not found then
      raise exception 'The instructional weekday pattern is incomplete for this session';
    end if;
  end if;

  if not coalesce(v_is_instructional, false) then
    raise exception 'Attendance cannot be recorded on a non-instructional school day';
  end if;

  return new;
end;
$function$;

revoke all on function private.schoolpro_enforce_instructional_attendance_day() from public, anon, authenticated;

-- PostgreSQL orders same-kind triggers alphabetically. This name places the
-- guard after schoolpro_stamp_activity_period, which assigns the session on INSERT.
create trigger schoolpro_validate_instructional_day
  before insert or update on public.schoolpro_attendance
  for each row execute function private.schoolpro_enforce_instructional_attendance_day();
