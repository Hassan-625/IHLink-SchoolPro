-- C0 operational membership regression; run after the complete ordered lifecycle migrations.
begin;
do $test$
declare n integer; permission_reader text; audit_reader text; audit_table text; invitation_reader text; board_writer text; board_role_trigger text;
begin
  -- A Board designation must never inject a school-wide administrator grant.
  -- Its member retains the original role and module-specific permissions.
  permission_reader := pg_get_functiondef('public.schoolpro_user_permissions(uuid)'::regprocedure);
  if position('schoolpro_board_members' in permission_reader)>0
    or position('bm.role' in permission_reader)>0 then
    raise exception 'Board appointments must not bypass the member role permission set';
  end if;

  board_writer := pg_get_functiondef('private.schoolpro_set_board_role(uuid,uuid,text)'::regprocedure);
  if position('set role = ''administrator''' in lower(board_writer))>0 then
    raise exception 'Board appointment writer must not elevate membership to administrator';
  end if;
  if position('select previous_role' in lower(board_writer))=0
    or position('set role = old_role' in lower(board_writer))=0
    or position('old_role <> ''administrator''' in lower(board_writer))=0 then
    raise exception 'Withdrawing a legacy Board appointment must restore its recorded non-administrator role';
  end if;

  -- Direct RPC/RLS authorization uses the stored membership role, not the
  -- permission resolver. Confirm that helper remains role-list based and has
  -- no Board appointment shortcut.
  board_writer := pg_get_functiondef('private.has_school_access(uuid,public.school_member_role[])'::regprocedure);
  if position('m.role = any(allowed_roles)' in lower(board_writer))=0
    or position('schoolpro_board_members' in lower(board_writer))>0 then
    raise exception 'Direct school authorization must rely on the restored membership role, not Board designation';
  end if;

  board_role_trigger := pg_get_functiondef('private.schoolpro_clear_changed_board_role()'::regprocedure);
  if position('previous_role' in board_role_trigger)=0
    or position('ended_at' in board_role_trigger)=0 then
    raise exception 'Board role-change trigger must preserve restoration and appointment history';
  end if;

  if exists (
    select 1
    from public.schoolpro_board_members b
    join public.schoolpro_members m
      on m.id=b.member_id and m.school_id=b.school_id
    where b.ended_at is null
      and m.role='administrator'
      and b.previous_role<>'administrator'
  ) then
    raise exception 'An active Board appointment still carries an elevated administrator membership role';
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

  -- Principal invitations preserve their designation through acceptance.
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='schoolpro_access_invitations'
      and column_name='position_title'
  ) then raise exception 'Staff invitation position_title column is missing'; end if;
  invitation_reader := pg_get_functiondef('public.schoolpro_accept_access_invitation(uuid,text)'::regprocedure);
  if position('invitation.position_title' in invitation_reader)=0 then
    raise exception 'Staff invitation acceptance does not preserve Principal designation';
  end if;

  -- Principal and full school administrators retain Games module access.
  permission_reader := pg_get_functiondef('public.schoolpro_user_permissions(uuid)'::regprocedure);
  if position('if m.role = ''administrator'' and m.position_title = ''Principal'' then' in permission_reader)=0
    or (length(permission_reader)-length(replace(permission_reader, '''games''', '')))/length('''games''') < 5 then
    raise exception 'School administrator and Principal permission sets must include Games';
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
