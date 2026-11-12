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
  if not has_function_privilege('authenticated','public.schoolpro_set_class_archive_state(uuid,uuid,boolean,text)','EXECUTE') then
    raise exception 'Audited class archive/restore RPC is not executable by authenticated users';
  end if;
  if not has_function_privilege('authenticated','public.schoolpro_set_member_suspension_state(uuid,uuid,boolean,text)','EXECUTE') then
    raise exception 'Audited staff suspension/restore RPC is not executable by authenticated users';
  end if;
  if to_regclass('public.schoolpro_workspace_deletion_requests') is null then
    raise exception 'Workspace removal request table is missing';
  end if;
  if not (select relrowsecurity from pg_class where oid='public.schoolpro_workspace_deletion_requests'::regclass) then
    raise exception 'Workspace removal request RLS is not enabled';
  end if;
  if not exists(select 1 from pg_policies where schemaname='public'
    and tablename='schoolpro_workspace_deletion_requests'
    and policyname='SchoolPro workspace deletion request read'
    and qual like '%super_admin%') then
    raise exception 'Workspace removal request reads must be limited to the requester, proprietor and platform Super Admins';
  end if;
  if has_table_privilege('anon','public.schoolpro_workspace_deletion_requests','INSERT')
     or has_table_privilege('authenticated','public.schoolpro_workspace_deletion_requests','INSERT')
     or has_table_privilege('authenticated','public.schoolpro_workspace_deletion_requests','UPDATE')
     or has_table_privilege('authenticated','public.schoolpro_workspace_deletion_requests','DELETE') then
    raise exception 'Direct writes remain on workspace removal requests';
  end if;
  if not has_function_privilege('authenticated','public.schoolpro_request_workspace_deletion(uuid,text,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.schoolpro_review_workspace_deletion(uuid,text,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.schoolpro_execute_workspace_deletion(uuid,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.schoolpro_cancel_workspace_deletion(uuid,text)','EXECUTE') then
    raise exception 'Workspace removal lifecycle RPC grants are incomplete';
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
  select pg_get_functiondef('public.schoolpro_set_result_lock(uuid,text,text,boolean)'::regprocedure) into def;
  if position('has_school_access' in def)=0 then
    raise exception 'Result lock RPC does not use active-membership authorization';
  end if;
  select pg_get_functiondef('public.schoolpro_user_permissions(uuid)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('active' in def)=0 then
    raise exception 'Central permission resolver does not suppress suspended memberships';
  end if;
  select pg_get_functiondef('public.schoolpro_member_can_manage(uuid)'::regprocedure) into def;
  if position('has_school_access' in def)=0 then
    raise exception 'Central manage helper does not use active-membership authorization';
  end if;
  select pg_get_functiondef('private.schoolpro_validate_competition_tenant_links()'::regprocedure) into def;
  if position('m.status' in def)=0 or position('active' in def)=0 then
    raise exception 'Competition judge validator does not require active membership';
  end if;
  select pg_get_functiondef('public.mark_schoolpro_theory_answer(uuid,numeric,text)'::regprocedure) into def;
  if position('has_school_access' in def)=0 then raise exception 'CBT theory marking RPC bypasses active membership'; end if;
  select pg_get_functiondef('public.queue_schoolpro_email(uuid,text,text,text,text,jsonb)'::regprocedure) into def;
  if position('has_school_access' in def)=0 then raise exception 'Email queue RPC bypasses active membership'; end if;
  select pg_get_functiondef('public.create_schoolpro_portal_invite(uuid,text,text)'::regprocedure) into def;
  if position('has_school_access' in def)=0 then raise exception 'Portal invite RPC bypasses active membership'; end if;
  select pg_get_functiondef('public.link_schoolpro_student_account(uuid,text)'::regprocedure) into def;
  if position('has_school_access' in def)=0 then raise exception 'Student account linking RPC bypasses active membership'; end if;
  select pg_get_functiondef('public.schedule_schoolpro_admission_event(uuid,text,timestamp with time zone,text,text)'::regprocedure) into def;
  if position('has_school_access' in def)=0 then raise exception 'Admission event RPC bypasses active membership'; end if;
  select pg_get_functiondef('public.verify_schoolpro_admission_document(uuid,boolean,text)'::regprocedure) into def;
  if position('has_school_access' in def)=0 then raise exception 'Admission document RPC bypasses active membership'; end if;
  select pg_get_functiondef('private.schoolpro_coordinator_classes(uuid)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('archived_at' in def)=0 then raise exception 'Coordinator class reader does not enforce active membership and class state'; end if;
  select pg_get_functiondef('private.schoolpro_class_staff_directory(uuid)'::regprocedure) into def;
  if position('m.status' in def)=0 then raise exception 'Class staff directory includes inactive memberships'; end if;
  select pg_get_functiondef('private.schoolpro_teacher_allocation_visible(uuid,uuid,uuid)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('archived_at' in def)=0 then raise exception 'Teacher allocation reader does not enforce active membership/class state'; end if;
  select pg_get_functiondef('private.schoolpro_set_form_master(uuid,uuid)'::regprocedure) into def;
  if position('status' in def)=0 or position('archived_at' in def)=0 then raise exception 'Form Master assignment does not require active staff and class'; end if;
  select pg_get_functiondef('private.validate_subject_assignment()'::regprocedure) into def;
  if position('member_status' in def)=0 or position('archived_at' in def)=0 then raise exception 'Subject assignment validator does not require active staff/class'; end if;
  select pg_get_functiondef('private.schoolpro_is_house_master(uuid,uuid)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('ended_at' in def)=0 then raise exception 'House Master reader includes inactive or ended appointments'; end if;
  select pg_get_functiondef('private.schoolpro_member_leads_class(uuid,uuid)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('sl.ended_at' in def)=0 or position('archived_at' in def)=0 then raise exception 'Section class reader includes inactive staff or archived class'; end if;
  select pg_get_functiondef('private.schoolpro_member_leads_student_section(uuid,uuid,text)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('sl.ended_at' in def)=0 then raise exception 'Section student reader includes inactive or ended appointments'; end if;
  -- Verify the final Stage C authority migration, not only the earlier
  -- role-specific appointment migrations, is present in the complete schema.
  select pg_get_functiondef('private.schoolpro_set_section_leader(uuid,uuid,text,boolean)'::regprocedure) into def;
  if position('target.role = ''teacher''' in def)=0
     or position('target.status<>''active''' in def)=0
     or position('schoolpro_member_has_responsibility(p_school,''school_admin'')' in def)=0 then
    raise exception 'Final section appointment RPC must allow active staff except ordinary Subject Teachers and require authorized administration';
  end if;
  select pg_get_functiondef('private.schoolpro_member_leads_class(uuid,uuid)'::regprocedure) into def;
  if position('m.role <> ''teacher''' in def)=0
     or position('principal_sl.section=sl.section' in def)=0
     or position('principal_m.role=''administrator''' in def)=0
     or position('position_title' in def)=0 then
    raise exception 'Section class authority must exclude Subject Teachers and enforce Principal precedence';
  end if;
  select pg_get_functiondef('private.schoolpro_member_leads_student_section(uuid,uuid,text)'::regprocedure) into def;
  if position('principal_sl.section=sl.section' in def)=0
     or position('principal_m.role=''administrator''' in def)=0
     or position('position_title' in def)=0 then
    raise exception 'Historical section student access must enforce Principal precedence';
  end if;
  select pg_get_functiondef('private.schoolpro_validate_house_master()'::regprocedure) into def;
  if position('m.status' in def)=0 or position('active' in def)=0 then raise exception 'House Master assignment validator allows inactive staff'; end if;
  select pg_get_functiondef('private.schoolpro_set_section_leader(uuid,uuid,text,boolean)'::regprocedure) into def;
  if position('target.status' in def)=0 or position('ended_at' in def)=0 then raise exception 'Section leader appointment writer does not enforce active membership/history'; end if;
  select pg_get_functiondef('private.schoolpro_set_board_role(uuid,uuid,text)'::regprocedure) into def;
  if position('status=' in regexp_replace(def, '[[:space:]]+', '', 'g'))=0 or position('active' in def)=0 or position('ended_at' in def)=0 then raise exception 'Board appointment writer does not enforce active membership/history'; end if;
  select pg_get_functiondef('private.schoolpro_cached_access_schools(text,text)'::regprocedure) into def;
  if position('m.status' in def)=0 or position('active' in def)=0 then raise exception 'Cached access reader includes inactive memberships'; end if;
  select pg_get_functiondef('private.schoolpro_cached_staff_schools()'::regprocedure) into def;
  if position('m.status' in def)=0 or position('active' in def)=0 then raise exception 'Cached staff reader includes inactive memberships'; end if;


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
  if has_table_privilege('anon','public.schoolpro_leave_requests','DELETE')
    or has_table_privilege('authenticated','public.schoolpro_leave_requests','DELETE')
    or has_table_privilege('authenticated','public.schoolpro_leave_requests','TRUNCATE') then
    raise exception 'Direct leave/absence deletion remains possible';
  end if;
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
  if has_table_privilege('anon','public.schoolpro_staff_disciplinary_cases','INSERT')
    or has_table_privilege('anon','public.schoolpro_staff_disciplinary_cases','UPDATE')
    or has_table_privilege('anon','public.schoolpro_staff_disciplinary_cases','DELETE')
    or has_table_privilege('authenticated','public.schoolpro_staff_disciplinary_cases','INSERT')
    or has_table_privilege('authenticated','public.schoolpro_staff_disciplinary_cases','UPDATE')
    or has_table_privilege('authenticated','public.schoolpro_staff_disciplinary_cases','DELETE')
    or has_table_privilege('authenticated','public.schoolpro_staff_disciplinary_cases','TRUNCATE') then
    raise exception 'Direct staff disciplinary case writes must remain RPC-only';
  end if;

  -- Student discipline detail and immutable case history.
  if has_table_privilege('anon','public.schoolpro_discipline_records','DELETE')
    or has_table_privilege('authenticated','public.schoolpro_discipline_records','DELETE')
    or has_table_privilege('authenticated','public.schoolpro_discipline_records','TRUNCATE') then
    raise exception 'Direct student discipline case deletion remains possible';
  end if;
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
  select count(*) into n from pg_policy p join pg_class c on c.oid=p.polrelid
  join pg_namespace s on s.oid=c.relnamespace
  where s.nspname='public' and c.relname='schoolpro_discipline_records' and p.polcmd='d';
  if n<>0 then raise exception 'Student discipline DELETE policy remains'; end if;
  -- Standard reporting is role-controlled; Enterprise analytics have their
  -- own server-side entitlement check in the dedicated Advanced Reports RPC.
  select pg_get_functiondef('private.schoolpro_module_allowed(uuid,text)'::regprocedure) into def;
  if position('when ''reports''' in def)>0 or position('advanced_reports' in def)>0 then
    raise exception 'Standard reports must not inherit the Advanced Reports plan gate';
  end if;
  if position('schoolpro_user_permissions' in def)=0 or position('schoolpro_operationally_active' in def)=0 then
    raise exception 'Standard reports must retain role and active-school checks';
  end if;
  select pg_get_functiondef('public.schoolpro_class_review_sheet(uuid,uuid,text,text)'::regprocedure) into def;
  if position('schoolpro_module_allowed(p_school,''reports'')' in def)=0
     or position('schoolpro_plan_feature_allowed(p_school,''advanced_reports'')' in def)=0
     or position('private.is_admin(array[''super_admin'']::public.user_role[])' in def)=0 then
    raise exception 'Advanced Reports RPC must enforce role permission and Enterprise entitlement with Super Admin bypass';
  end if;

end
$c0$;

rollback;
