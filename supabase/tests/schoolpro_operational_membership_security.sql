-- C0 operational membership regression; run after the complete ordered lifecycle migrations.
begin;
do $test$
declare n integer;
begin
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
