-- C0 operational membership regression; run after the complete ordered lifecycle migrations.
begin;
do $test$
declare n integer; permission_reader text; access_reader text;
begin
  -- The central permission RPC must reference the role on schoolpro_members.
  -- schoolpro_board_members has title/previous_role, not a role column.
  permission_reader := pg_get_functiondef('public.schoolpro_user_permissions(uuid)'::regprocedure);
  if position('bm.role = ''administrator''' in permission_reader)=0
    or position('b.role' in permission_reader)>0 then
    raise exception 'School permission reader has an invalid board-role reference';
  end if;

  -- Principal is a first-class school role, but remains a school-scoped identity.
  if not exists (
    select 1 from pg_enum e join pg_type t on t.oid=e.enumtypid
    where t.typname='school_member_role' and e.enumlabel='principal'
  ) then raise exception 'Principal school role is missing'; end if;
  permission_reader := pg_get_functiondef('public.schoolpro_user_permissions(uuid)'::regprocedure);
  if position('m.role::text = ''principal''' in permission_reader)=0 then
    raise exception 'Principal permission mapping is missing';
  end if;
  access_reader := pg_get_functiondef('private.has_school_access(uuid,public.school_member_role[])'::regprocedure);
  if position('m.role::text = ''principal''' in access_reader)=0 then
    raise exception 'Principal is not recognized by school membership authorization';
  end if;
  if not exists(select 1 from pg_trigger t join pg_class c on c.oid=t.tgrelid
    where c.relname='schoolpro_admissions' and t.tgname='schoolpro_audit_capture' and not t.tgisinternal)
    then raise exception 'School admissions audit capture trigger missing'; end if;
  if not exists(select 1 from pg_trigger t join pg_class c on c.oid=t.tgrelid
    where c.relname='schoolpro_admission_events' and t.tgname='schoolpro_audit_capture' and not t.tgisinternal)
    then raise exception 'Admission event audit capture trigger missing'; end if;

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
