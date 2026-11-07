-- Consolidated Stage C0 SQL security and lifecycle regression.
-- Execute against a disposable local Supabase database after ALL migrations.
-- This test is catalog/contract based and intentionally performs no row mutations.

begin;

do $c0$
declare
  n integer;
  def text;
  rel text;
begin
  -- Class/member lifecycle metadata and destructive API access closure.
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_classes' and column_name='archived_at') then
    raise exception 'schoolpro_classes.archived_at is missing';
  end if;
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_members' and column_name='status') then
    raise exception 'schoolpro_members.status is missing';
  end if;
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_members' and column_name='employment_status') then
    raise exception 'schoolpro_members.employment_status is missing';
  end if;

  foreach rel in array array['schoolpro_classes','schoolpro_members'] loop
    if has_table_privilege('anon','public.'||rel,'DELETE')
      or has_table_privilege('authenticated','public.'||rel,'DELETE') then
      raise exception 'Direct DELETE remains on public.%',rel;
    end if;
    if has_table_privilege('anon','public.'||rel,'TRUNCATE')
      or has_table_privilege('authenticated','public.'||rel,'TRUNCATE') then
      raise exception 'Direct TRUNCATE remains on public.%',rel;
    end if;
    select count(*) into n from pg_policy p
    join pg_class c on c.oid=p.polrelid join pg_namespace s on s.oid=c.relnamespace
    where s.nspname='public' and c.relname=rel and p.polcmd in ('d','*');
    if n<>0 then raise exception 'DELETE or ALL RLS policy remains on public.%',rel; end if;
  end loop;

  select count(*) into n from pg_policy p
  join pg_class c on c.oid=p.polrelid join pg_namespace s on s.oid=c.relnamespace
  where s.nspname='public' and c.relname in ('schoolpro_classes','schoolpro_members')
    and p.polname like 'Super admin % schoolpro_%'
    and p.polcmd in ('r','a','w');
  if n<>6 then raise exception 'Expected six explicit Super Admin SELECT/INSERT/UPDATE policies; found %',n; end if;

  -- Active membership is the common authorization source.
  select pg_get_functiondef('private.has_school_access(uuid,public.school_member_role[])'::regprocedure) into def;
  if position('m.status' in def)=0 or position('active' in def)=0 then
    raise exception 'Central school access helper does not enforce active membership';
  end if;
  select pg_get_functiondef('public.schoolpro_can_author_cbt(uuid)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('active' in def)=0 then
    raise exception 'CBT author helper does not enforce active membership';
  end if;
  select pg_get_functiondef('public.schoolpro_can_manage_cbt(uuid)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('active' in def)=0 then
    raise exception 'CBT manager helper does not enforce active membership';
  end if;

  -- Attendance and timetable legacy permissive policies must be removed.
  select count(*) into n from pg_policy p
  join pg_class c on c.oid=p.polrelid join pg_namespace s on s.oid=c.relnamespace
  where s.nspname='public' and c.relname='schoolpro_attendance'
    and p.polname in ('School educators insert attendance','School educators update attendance',
      'Scoped attendance records','schoolpro_module_permission');
  if n<>0 then raise exception 'Legacy broad attendance policies remain'; end if;

  select count(*) into n from pg_policy p
  join pg_class c on c.oid=p.polrelid join pg_namespace s on s.oid=c.relnamespace
  where s.nspname='public' and c.relname='schoolpro_timetable_entries'
    and p.polname in ('manager timetable','member read timetable','schoolpro_module_permission');
  if n<>0 then raise exception 'Legacy direct-membership timetable policies remain'; end if;

  if not exists(select 1 from pg_trigger where tgname='validate_schoolpro_attendance' and not tgisinternal) then
    raise exception 'Attendance relation validator trigger missing';
  end if;
  if not exists(select 1 from pg_trigger where tgname='schoolpro_cbt_eligibility_tenant_guard' and not tgisinternal) then
    raise exception 'CBT eligibility validator trigger missing';
  end if;
  if not exists(select 1 from pg_trigger where tgname='schoolpro_active_leave_member' and not tgisinternal) then
    raise exception 'Active leave membership trigger missing';
  end if;
  if not exists(select 1 from pg_trigger where tgname='schoolpro_active_payroll_member' and not tgisinternal) then
    raise exception 'Active payroll membership trigger missing';
  end if;

  -- Appointment history and suspension integration.
  if to_regclass('public.schoolpro_staff_appointment_history') is null then
    raise exception 'Immutable staff appointment history table missing';
  end if;
  if to_regclass('public.schoolpro_staff_disciplinary_events') is null then
    raise exception 'Staff disciplinary event history table missing';
  end if;
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_subject_assignments' and column_name='ended_at') then
    raise exception 'Subject appointment end metadata missing';
  end if;
  select pg_get_functiondef('private.guard_schoolpro_employment_status()'::regprocedure) into def;
  if position('dismissed' in def)=0 or position('cannot be restored' in def)=0 then
    raise exception 'Dismissal restoration guard missing';
  end if;

  -- Leave/absence workflow: self-report, reason updates, HR review and history.
  if to_regclass('public.schoolpro_leave_events') is null then
    raise exception 'Leave event history table missing';
  end if;
  foreach rel in array array['request_type','absence_reported_at','reason_updated_at','reason_updated_by','review_note'] loop
    if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_leave_requests' and column_name=rel) then
      raise exception 'Leave workflow column % missing',rel;
    end if;
  end loop;
  if not has_function_privilege('authenticated','public.schoolpro_report_own_absence(uuid,date,date,text)','EXECUTE')
    or not has_function_privilege('authenticated','public.schoolpro_update_own_leave_reason(uuid,text)','EXECUTE')
    or not has_function_privilege('authenticated','public.schoolpro_review_leave_request(uuid,text,text)','EXECUTE') then
    raise exception 'Leave self-service/review RPC grants are incomplete';
  end if;

  -- Staff discipline and appeal workflow.
  if to_regclass('public.schoolpro_staff_disciplinary_cases') is null
    or to_regclass('public.schoolpro_staff_disciplinary_events') is null then
    raise exception 'Staff disciplinary case or event table missing';
  end if;
  if not has_function_privilege('authenticated','public.schoolpro_create_staff_disciplinary_case(uuid,uuid,text,text,text,text,timestamptz)','EXECUTE')
    or not has_function_privilege('authenticated','public.schoolpro_submit_staff_disciplinary_response(uuid,text,boolean)','EXECUTE')
    or not has_function_privilege('authenticated','public.schoolpro_review_staff_appeal(uuid,text,text)','EXECUTE')
    or not has_function_privilege('authenticated','public.schoolpro_close_staff_disciplinary_case(uuid,text)','EXECUTE') then
    raise exception 'Staff disciplinary RPC grants are incomplete';
  end if;
  if has_table_privilege('authenticated','public.schoolpro_staff_disciplinary_cases','INSERT')
    or has_table_privilege('authenticated','public.schoolpro_staff_disciplinary_cases','UPDATE')
    or has_table_privilege('authenticated','public.schoolpro_staff_disciplinary_cases','DELETE') then
    raise exception 'Direct staff disciplinary case writes must remain RPC-only';
  end if;

  -- Student discipline detail and immutable case history.
  if to_regclass('public.schoolpro_discipline_events') is null then
    raise exception 'Student discipline event history table missing';
  end if;
  foreach rel in array array['category','severity','incident_at','location','student_response',
    'guardian_contact_status','guardian_contacted_at','guardian_contact_note',
    'follow_up_at','follow_up_outcome','resolved_at','resolved_by'] loop
    if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_discipline_records' and column_name=rel) then
      raise exception 'Student discipline case column % missing',rel;
    end if;
  end loop;
  select count(*) into n from pg_policy p
  join pg_class c on c.oid=p.polrelid join pg_namespace s on s.oid=c.relnamespace
  where s.nspname='public' and c.relname='schoolpro_discipline_records' and p.polcmd='*'
    and p.polname='discipline authorized access';
  if n<>0 then raise exception 'Legacy discipline ALL policy remains'; end if;
end
$c0$;

rollback;
