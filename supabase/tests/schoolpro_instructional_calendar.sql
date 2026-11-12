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

  helper := pg_get_functiondef('private.schoolpro_guard_instructional_calendar_settings()'::regprocedure);
  if position('new.is_configured :=' in helper)=0 or position('count(*) = 7' in helper)=0 then
    raise exception 'Calendar readiness must be derived, not user-set';
  end if;
  if not exists(select 1 from pg_trigger
    where tgrelid='public.schoolpro_instructional_calendar_settings'::regclass
      and tgname='schoolpro_instructional_settings_configuration_guard' and not tgisinternal) then
    raise exception 'Derived calendar readiness guard trigger is missing';
  end if;

  guard := pg_get_functiondef('private.schoolpro_enforce_instructional_attendance_day()'::regprocedure);
  if not exists(
    select 1 from pg_constraint
    where conrelid='public.schoolpro_instructional_calendar_exceptions'::regclass
      and contype='c'
      and pg_get_constraintdef(oid) like '%public_holiday%'
      and pg_get_constraintdef(oid) like '%school_holiday%'
      and pg_get_constraintdef(oid) like '%emergency_closure%'
      and pg_get_constraintdef(oid) like '%make_up_instructional%'
  ) then raise exception 'Instructional exception types are incomplete'; end if;

  if position('schoolpro_instructional_calendar_exceptions' in guard)=0
     or position('schoolpro_instructional_weekdays' in guard)=0
     or position('is_configured' in guard)=0
     or position('extract(isodow' in guard)=0
     or position('term_start_date' in guard)=0
     or position('new.attendance_date is not distinct from old.attendance_date' in guard)=0
     or position('new.class_id is not distinct from old.class_id' in guard)=0
     or position('new.student_id is not distinct from old.student_id' in guard)=0
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


create or replace function pg_temp.assert_schoolpro_attendance_insert_rejected(
  p_school uuid,p_class uuid,p_student uuid,p_marker uuid,p_date date,p_session text,p_expected text
) returns void language plpgsql as $function$
declare v_rejected boolean := false;
begin
  begin
    insert into public.schoolpro_attendance
      (school_id,class_id,student_id,attendance_date,status,marked_by,session)
    values (p_school,p_class,p_student,p_date,'present',p_marker,p_session);
  exception when others then
    if position(p_expected in sqlerrm)=0 then raise; end if;
    v_rejected := true;
  end;
  if not v_rejected then
    raise exception 'Expected attendance insert rejection containing: %',p_expected;
  end if;
end;
$function$;

create or replace function pg_temp.assert_schoolpro_attendance_update_rejected(
  p_school uuid,p_new_student uuid,p_new_class uuid,p_new_date date,p_expected text
) returns void language plpgsql as $function$
declare
  v_id uuid;
  v_rejected boolean := false;
begin
  select id into v_id from public.schoolpro_attendance
   where school_id=p_school and attendance_date=date '2026-11-20'
   order by created_at limit 1;
  if v_id is null then raise exception 'Runtime fixture attendance row is missing'; end if;
  begin
    update public.schoolpro_attendance
       set student_id=coalesce(p_new_student,student_id),
           class_id=coalesce(p_new_class,class_id),
           attendance_date=p_new_date
     where id=v_id;
  exception when others then
    if position(p_expected in sqlerrm)=0 then raise; end if;
    v_rejected := true;
  end;
  if not v_rejected then
    raise exception 'Expected attendance update rejection containing: %',p_expected;
  end if;
end;
$function$;



-- Exercise the real attendance trigger against transaction-scoped fixtures.
-- All fixture rows are synthetic and are rolled back at the end of this test.
do $runtime_setup$
declare
  v_owner uuid := gen_random_uuid();
  v_school uuid := gen_random_uuid();
  v_class_one uuid := gen_random_uuid();
  v_class_two uuid := gen_random_uuid();
  v_student_one uuid := gen_random_uuid();
  v_student_two uuid := gen_random_uuid();
begin
  -- Bypass unrelated onboarding, enrollment and audit triggers only while
  -- creating internally consistent fixtures in this disposable database.
  set local session_replication_role = replica;

  insert into public.profiles (id,email,first_name,last_name)
  values (v_owner,'calendar-regression-owner@example.invalid','Calendar','Regression');

  insert into public.schoolpro_schools (id,owner_id,name,code)
  values (v_school,v_owner,'Calendar Regression Fixture','CAL-'||replace(v_school::text,'-',''));

  insert into public.schoolpro_classes (id,school_id,name,arm,level)
  values
    (v_class_one,v_school,'Primary 4','A','primary'),
    (v_class_two,v_school,'Primary 5','A','primary');

  insert into public.schoolpro_students
    (id,school_id,admission_number,first_name,last_name,class_name,class_id)
  values
    (v_student_one,v_school,'CAL-STU-1','Test','Learner One','Primary 4',v_class_one),
    (v_student_two,v_school,'CAL-STU-2','Test','Learner Two','Primary 4',v_class_one);

  insert into public.schoolpro_result_term_settings
    (school_id,session,term,term_start_date,term_end_date)
  values
    (v_school,'2026/2027','First Term',date '2026-11-16',date '2026-11-22'),
    (v_school,'2027/2028','First Term',date '2027-09-06',date '2027-09-10');

  insert into public.schoolpro_instructional_calendar_settings
    (school_id,session,is_configured)
  values
    (v_school,'2026/2027',true),
    (v_school,'2027/2028',false);

  insert into public.schoolpro_instructional_weekdays
    (school_id,session,iso_weekday,is_instructional)
  select v_school,'2026/2027',day_no,day_no between 1 and 5
  from generate_series(1,7) as day_no;

  insert into public.schoolpro_instructional_calendar_exceptions
    (school_id,session,calendar_date,exception_type,title)
  values
    (v_school,'2026/2027',date '2026-11-17','public_holiday','Fixture public holiday'),
    (v_school,'2026/2027',date '2026-11-18','school_holiday','Fixture school holiday'),
    (v_school,'2026/2027',date '2026-11-19','emergency_closure','Fixture emergency closure'),
    (v_school,'2026/2027',date '2026-11-22','make_up_instructional','Fixture make-up day');

  set local session_replication_role = origin;

  -- Isolate the trigger under test. The attendance session is supplied
  -- explicitly, so the unrelated session-stamping trigger is not needed.
  alter table public.schoolpro_attendance disable trigger all;
  alter table public.schoolpro_attendance enable trigger schoolpro_validate_instructional_day;

  -- Inclusive term start and end dates, and an ordinary instructional weekday.
  insert into public.schoolpro_attendance
    (school_id,class_id,student_id,attendance_date,status,marked_by,session)
  values
    (v_school,v_class_one,v_student_one,date '2026-11-16','present',v_owner,'2026/2027');

  insert into public.schoolpro_attendance
    (school_id,class_id,student_id,attendance_date,status,marked_by,session)
  values
    (v_school,v_class_one,v_student_one,date '2026-11-20','present',v_owner,'2026/2027');

  -- A make-up instructional exception opens a normally closed Sunday.
  insert into public.schoolpro_attendance
    (school_id,class_id,student_id,attendance_date,status,marked_by,session)
  values
    (v_school,v_class_one,v_student_one,date '2026-11-22','present',v_owner,'2026/2027');

  -- The four exception types must override the weekly weekday pattern.
  perform pg_temp.assert_schoolpro_attendance_insert_rejected(
    v_school,v_class_one,v_student_one,v_owner,date '2026-11-17','2026/2027',
    'Attendance cannot be recorded on a non-instructional school day');
  perform pg_temp.assert_schoolpro_attendance_insert_rejected(
    v_school,v_class_one,v_student_one,v_owner,date '2026-11-18','2026/2027',
    'Attendance cannot be recorded on a non-instructional school day');
  perform pg_temp.assert_schoolpro_attendance_insert_rejected(
    v_school,v_class_one,v_student_one,v_owner,date '2026-11-19','2026/2027',
    'Attendance cannot be recorded on a non-instructional school day');

  -- Saturday is closed by the configured weekday pattern.
  perform pg_temp.assert_schoolpro_attendance_insert_rejected(
    v_school,v_class_one,v_student_one,v_owner,date '2026-11-21','2026/2027',
    'Attendance cannot be recorded on a non-instructional school day');

  -- The term bounds are inclusive; dates immediately outside them are rejected.
  perform pg_temp.assert_schoolpro_attendance_insert_rejected(
    v_school,v_class_one,v_student_one,v_owner,date '2026-11-15','2026/2027',
    'Attendance date must fall within a configured term');
  perform pg_temp.assert_schoolpro_attendance_insert_rejected(
    v_school,v_class_one,v_student_one,v_owner,date '2026-11-23','2026/2027',
    'Attendance date must fall within a configured term');

  -- A session without all seven configured weekdays is not attendance-ready.
  perform pg_temp.assert_schoolpro_attendance_insert_rejected(
    v_school,v_class_one,v_student_one,v_owner,date '2027-09-06','2027/2028',
    'Configure all seven instructional weekdays');

  -- Add a closure after an attendance row already exists. Ordinary corrections
  -- remain possible, but changing its date, student or class must revalidate.
  set local session_replication_role = replica;
  insert into public.schoolpro_instructional_calendar_exceptions
    (school_id,session,calendar_date,exception_type,title)
  values (v_school,'2026/2027',date '2026-11-20','emergency_closure','Post-entry closure');
  set local session_replication_role = origin;

  update public.schoolpro_attendance
     set status='late', notes='Correction to an existing record'
   where school_id=v_school and student_id=v_student_one
     and attendance_date=date '2026-11-20';

  perform pg_temp.assert_schoolpro_attendance_update_rejected(
    v_school,v_student_two,null,date '2026-11-20',
    'Attendance cannot be recorded on a non-instructional school day');
  perform pg_temp.assert_schoolpro_attendance_update_rejected(
    v_school,null,v_class_two,date '2026-11-20',
    'Attendance cannot be recorded on a non-instructional school day');
  perform pg_temp.assert_schoolpro_attendance_update_rejected(
    v_school,null,null,date '2026-11-17',
    'Attendance cannot be recorded on a non-instructional school day');

  raise notice 'PASS: instructional attendance runtime behavior (weekdays, exceptions, term bounds, readiness and updates)';
end
$runtime_setup$;


rollback;
