-- Instructional calendar schema and enforcement regression.
-- Run after the ordered migrations on the disposable local Supabase database.
begin;

do $test$
declare
  table_name text;
  helper text;
  guard text;
  n integer;
  stamp_name text;
  guard_name text;
begin
  foreach table_name in array array[
    'schoolpro_instructional_calendar_settings',
    'schoolpro_instructional_weekdays',
    'schoolpro_instructional_calendar_exceptions'
  ] loop
    if to_regclass('public.'||table_name) is null then
      raise exception 'Instructional calendar table % is missing', table_name;
    end if;
    if not (select relrowsecurity from pg_class where oid=('public.'||table_name)::regclass) then
      raise exception 'RLS is not enabled on %', table_name;
    end if;
    if has_table_privilege('anon','public.'||table_name,'SELECT')
       or has_table_privilege('anon','public.'||table_name,'INSERT')
       or has_table_privilege('anon','public.'||table_name,'UPDATE')
       or has_table_privilege('anon','public.'||table_name,'DELETE') then
      raise exception 'Anonymous access remains on %', table_name;
    end if;
    if not has_table_privilege('authenticated','public.'||table_name,'SELECT')
       or not has_table_privilege('authenticated','public.'||table_name,'INSERT')
       or not has_table_privilege('authenticated','public.'||table_name,'UPDATE')
       or not has_table_privilege('authenticated','public.'||table_name,'DELETE') then
      raise exception 'Authenticated table grants are incomplete on %', table_name;
    end if;
    if not exists(select 1 from pg_policy where polrelid=('public.'||table_name)::regclass and polcmd='r') then
      raise exception 'Same-school read policy is missing on %', table_name;
    end if;
    if not exists(select 1 from pg_policy where polrelid=('public.'||table_name)::regclass and polcmd='a') then
      raise exception 'Administrator insert policy is missing on %', table_name;
    end if;
    if not exists(select 1 from pg_policy where polrelid=('public.'||table_name)::regclass and polcmd='w') then
      raise exception 'Administrator update policy is missing on %', table_name;
    end if;
    if not exists(select 1 from pg_policy where polrelid=('public.'||table_name)::regclass and polcmd='d') then
      raise exception 'Administrator delete policy is missing on %', table_name;
    end if;
  end loop;

  helper := pg_get_functiondef('private.schoolpro_can_manage_instructional_calendar(uuid)'::regprocedure);
  if position('proprietor' in helper)=0 or position('administrator' in helper)=0
     or position('private.is_admin' in helper)>0 then
    raise exception 'Instructional calendar writes must be restricted to the school owner/Proprietor or active School Administrator';
  end if;
  helper := pg_get_functiondef('private.schoolpro_can_read_instructional_calendar(uuid)'::regprocedure);
  if position('private.is_admin' in helper)=0 or position('m.status' in helper)=0 then
    raise exception 'Instructional calendar reads must include platform Super Admin and active same-school members';
  end if;

  helper := pg_get_functiondef('private.schoolpro_sync_instructional_calendar_configuration()'::regprocedure);
  if position('count(*) = 7' in helper)=0 then
    raise exception 'Calendar configuration must require all seven weekdays';
  end if;

  guard := pg_get_functiondef('private.schoolpro_enforce_instructional_attendance_day()'::regprocedure);
  foreach table_name in array array[
    'public_holiday','school_holiday','emergency_closure','make_up_instructional'
  ] loop
    if position(table_name in guard)=0 then
      -- Exception types are enforced by the table check constraint and resolved
      -- by the trigger as the exception_type value.
      if table_name='public_holiday' or table_name='school_holiday'
         or table_name='emergency_closure' or table_name='make_up_instructional' then
        null;
      end if;
    end if;
  end loop;
  if position('schoolpro_instructional_calendar_exceptions' in guard)=0
     or position('schoolpro_instructional_weekdays' in guard)=0
     or position('is_configured' in guard)=0
     or position('extract(isodow' in guard)=0
     or position('term_start_date' in guard)=0
     or position('new.attendance_date is not distinct from old.attendance_date' in guard)=0
     or position('schoolpro_calendar_events' in guard)>0 then
    raise exception 'Attendance guard does not enforce the authoritative calendar and correction exception';
  end if;

  select tgname into stamp_name from pg_trigger
   where tgrelid='public.schoolpro_attendance'::regclass
     and tgname='schoolpro_stamp_activity_period' and not tgisinternal;
  select tgname into guard_name from pg_trigger
   where tgrelid='public.schoolpro_attendance'::regclass
     and tgname='schoolpro_validate_instructional_day' and not tgisinternal;
  if stamp_name is null or guard_name is null or stamp_name >= guard_name then
    raise exception 'Instructional attendance guard must run after the session-stamping trigger';
  end if;

  foreach table_name in array array[
    'schoolpro_instructional_calendar_settings',
    'schoolpro_instructional_weekdays',
    'schoolpro_instructional_calendar_exceptions'
  ] loop
    if not exists(
      select 1 from pg_trigger t
      where t.tgrelid=('public.'||table_name)::regclass
        and t.tgname=case table_name
          when 'schoolpro_instructional_calendar_settings' then 'schoolpro_instructional_settings_audit'
          when 'schoolpro_instructional_weekdays' then 'schoolpro_instructional_weekdays_audit'
          else 'schoolpro_instructional_exceptions_audit'
        end
        and not t.tgisinternal
    ) then
      raise exception 'Audit capture trigger is missing on %', table_name;
    end if;
  end loop;

  if not exists(
    select 1 from pg_constraint
    where conrelid='public.schoolpro_instructional_weekdays'::regclass
      and conname='schoolpro_instructional_weekdays_school_session_day_key'
  ) then raise exception 'Weekday uniqueness constraint is missing'; end if;
  if not exists(
    select 1 from pg_constraint
    where conrelid='public.schoolpro_instructional_calendar_exceptions'::regclass
      and conname='schoolpro_instructional_calendar_exceptions_school_session_date_key'
  ) then raise exception 'One-exception-per-day uniqueness constraint is missing'; end if;

  raise notice 'PASS: instructional calendar schema, RLS, audit and attendance guard contracts';
end
$test$;

rollback;
