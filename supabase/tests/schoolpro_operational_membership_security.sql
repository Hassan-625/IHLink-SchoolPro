-- C0 operational membership regression; run after the complete ordered lifecycle migrations.
begin;
do $test$
declare n integer; permission_reader text; audit_reader text; audit_table text; invitation_reader text;
begin
  -- The central permission RPC must reference the role on schoolpro_members.
  -- schoolpro_board_members has title/previous_role, not a role column.
  permission_reader := pg_get_functiondef('public.schoolpro_user_permissions(uuid)'::regprocedure);
  if position('bm.role = ''administrator''' in permission_reader)=0
    or position('b.role' in permission_reader)>0 then
    raise exception 'School permission reader has an invalid board-role reference';
  end if;

  -- School workspace audit capture must be installed on representative workflows.
  if to_regprocedure('private.capture_schoolpro_audit_log()') is null then
    raise exception 'SchoolPro audit capture trigger function is missing';
  end if;
  audit_reader := pg_get_functiondef('private.capture_schoolpro_audit_log()'::regprocedure);
  if position('changed_fields' in audit_reader)=0 or position('actor_role' in audit_reader)=0 then
    raise exception 'SchoolPro audit capture must retain actor attribution and changed field names';
  end if;
  foreach audit_table in array array[
    'schoolpro_students','schoolpro_members','schoolpro_admissions',
    'schoolpro_admission_events','schoolpro_competition_events',
    'schoolpro_leave_requests','schoolpro_invoices'
  ] loop
    if not exists(
      select 1 from pg_trigger t
      join pg_class c on c.oid=t.tgrelid
      join pg_namespace s on s.oid=c.relnamespace
      where s.nspname='public' and c.relname=audit_table
        and t.tgname='trg_schoolpro_audit_capture' and not t.tgisinternal
    ) then
      raise exception 'SchoolPro audit capture trigger missing on %', audit_table;
    end if;
  end loop;

  -- Principal invitation designation must survive acceptance without adding a new enum role.
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='schoolpro_access_invitations'
      and column_name='position_title'
  ) then raise exception 'Staff invitation position_title column is missing'; end if;
  invitation_reader := pg_get_functiondef('public.schoolpro_accept_access_invitation(uuid,text)'::regprocedure);
  if position('invitation.position_title' in invitation_reader)=0 then
    raise exception 'Staff invitation acceptance does not preserve Principal designation';
  end if;
  if position('position_title' in pg_get_functiondef('public.schoolpro_accept_access_invitation(uuid,text)'::regprocedure))=0 then
    raise exception 'Principal designation is not written to school membership';
  end if;

  -- Legacy direct membership policies must not survive on timetable or attendance.
  select count(*) into n from pg_policy p join pg_class c on c.oid=p.polrelid
  join pg_namespace s on s.oid=c.relnamespace
  where s.nspname='public' and c.relname='schoolpro_timetable_entries'
    and p.polname in ('manager timetable','member read timetable','schoolpro_module_permission');
  if n<>0 then raise exception 'Legacy timetable membership policies remain'; end if;

  select count(*) into n from pg_policy p join pg_class c on c.oid=p.polrelid
  join pg_namespace s on s.oid=c.relnamespace
  where s.nspname='public' and c.relname='schoolpro_attendance'
    and p.polname in ('School educators insert attendance','School educators update attendance',
      'Scoped attendance records','schoolpro_module_permission');
  if n<>0 then raise exception 'Legacy broad attendance policies remain'; end if;

  if not exists(select 1 from pg_trigger where tgname='schoolpro_active_payroll_member' and not tgisinternal)
    then raise exception 'Active payroll membership trigger missing'; end if;
  if not exists(select 1 from pg_trigger where tgname='schoolpro_active_leave_member' and not tgisinternal)
    then raise exception 'Active leave membership trigger missing'; end if;
  if exists(select 1 from pg_policy p join pg_class c on c.oid=p.polrelid
    where c.relname='schoolpro_cbt_tests' and p.polname='schoolpro_plan_access' and p.polcmd='*')
    then raise exception 'Broad CBT plan ALL policy remains'; end if;
  if not exists(select 1 from pg_policy p join pg_class c on c.oid=p.polrelid
    where c.relname='schoolpro_cbt_tests' and p.polname='C0 CBT plan read' and p.polcmd='r')
    then raise exception 'CBT plan read policy missing'; end if;
  if exists(select 1 from pg_policy where polname='C0 leave own pending update')
    then raise exception 'Direct own leave updates must use the audited reason-update RPC'; end if;
  if not has_function_privilege('authenticated','public.schoolpro_update_own_leave_reason(uuid,text)','EXECUTE')
    then raise exception 'Audited own leave reason-update RPC is missing'; end if;
end
$test$;
rollback;
