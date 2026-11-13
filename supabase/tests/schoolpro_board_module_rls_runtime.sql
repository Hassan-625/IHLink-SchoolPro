-- Runtime RLS regression: Board designation must not grant Finance, Payroll or Medical access.
-- Runs only against the disposable Supabase database restored by schoolpro-c0-regression.yml.
begin;
create temporary table board_rls_fixture (
  owner_id uuid, staff_id uuid, school_id uuid, member_id uuid,
  student_id uuid, fee_id uuid, payroll_id uuid, health_id uuid,
  legacy_member_id uuid, genuine_admin_member_id uuid
) on commit drop;

do $seed$
declare
  v_owner uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_school uuid := gen_random_uuid();
  v_member uuid := gen_random_uuid();
  v_student uuid := gen_random_uuid();
  v_fee uuid := gen_random_uuid();
  v_payroll uuid := gen_random_uuid();
  v_health uuid := gen_random_uuid();
  v_legacy uuid := gen_random_uuid();
  v_legacy_user uuid := gen_random_uuid();
  v_genuine_admin_user uuid := gen_random_uuid();
  v_genuine_admin uuid := gen_random_uuid();
begin
  insert into pg_temp.board_rls_fixture values
    (v_owner,v_staff,v_school,v_member,v_student,v_fee,v_payroll,v_health,v_legacy,v_genuine_admin);
  insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  values
    (v_owner,'authenticated','authenticated','owner-'||v_owner||'@example.invalid','{}','{}',now(),now()),
    (v_staff,'authenticated','authenticated','staff-'||v_staff||'@example.invalid','{}','{}',now(),now()),
    (v_legacy_user,'authenticated','authenticated','legacy-'||v_legacy_user||'@example.invalid','{}','{}',now(),now()),
    (v_genuine_admin_user,'authenticated','authenticated','admin-'||v_genuine_admin_user||'@example.invalid','{}','{}',now(),now());
  insert into public.profiles(id,email,status)
  values (v_owner,'owner-'||v_owner||'@example.invalid','active'),(v_staff,'staff-'||v_staff||'@example.invalid','active'),
    (v_legacy_user,'legacy-'||v_legacy_user||'@example.invalid','active'),
    (v_genuine_admin_user,'admin-'||v_genuine_admin_user||'@example.invalid','active')
  on conflict(id) do update set status='active';
  insert into public.schoolpro_schools(id,owner_id,name,code)
  values(v_school,v_owner,'Board RLS runtime fixture','BR-'||v_school);
  update public.schoolpro_schools set status='active' where id=v_school;
  insert into public.schoolpro_subscriptions(school_id,tier,billing_cycle,amount,status)
  values(v_school,'starter','annual',50000,'active');
  insert into public.schoolpro_members(id,school_id,user_id,role)
  values
    (v_member,v_school,v_staff,'teacher'),
    (v_legacy,v_school,v_legacy_user,'administrator'),
    (v_genuine_admin,v_school,v_genuine_admin_user,'administrator');
  insert into public.schoolpro_board_members(member_id,school_id,title,previous_role,appointed_by)
  values
    (v_member,v_school,'Board Member','teacher',v_owner),
    (v_legacy,v_school,'Board Member','teacher',v_owner),
    (v_genuine_admin,v_school,'Board Member','administrator',v_owner);
  insert into public.schoolpro_students(id,school_id,admission_number,first_name,last_name,class_name)
  values(v_student,v_school,'RLS-'||v_student,'RLS','Student','Primary 1');
  insert into public.schoolpro_fee_structures(id,school_id,name,term,session,amount,created_by)
  values(v_fee,v_school,'RLS fixture','First Term','2026/2027',1000,v_owner);
  insert into public.schoolpro_payroll_records(id,school_id,member_id,period,gross,deductions,status)
  values(v_payroll,v_school,v_member,'2026-11',1000,0,'draft');
  insert into public.schoolpro_health_records(id,school_id,student_id,complaint,recorded_by)
  values(v_health,v_school,v_student,'RLS fixture',v_owner);
end
$seed$;

-- The production baseline already grants authenticated USAGE on private; the disposable
-- schema restore omits that ambient privilege, so reproduce it inside this rollback-only test.
grant usage on schema private to authenticated;
grant select on pg_temp.board_rls_fixture to authenticated;
set local role authenticated;
select set_config('request.jwt.claim.sub',staff_id::text,true),
       set_config('request.jwt.claims',json_build_object('sub',staff_id::text,'role','authenticated')::text,true)
from pg_temp.board_rls_fixture;

do $assert$
declare
  f pg_temp.board_rls_fixture%rowtype;
  v_count integer;
begin
  select * into f from pg_temp.board_rls_fixture;
  if (select role from public.schoolpro_members where id=f.member_id) <> 'teacher'::public.school_member_role then
    raise exception 'Board designation changed the actual membership role';
  end if;
  select count(*) into v_count from public.schoolpro_fee_structures where id=f.fee_id;
  if v_count <> 0 then raise exception 'Board member can read Finance without an explicit grant'; end if;
  select count(*) into v_count from public.schoolpro_payroll_records where id=f.payroll_id;
  if v_count <> 0 then raise exception 'Board member can read Payroll without an explicit grant'; end if;
  select count(*) into v_count from public.schoolpro_health_records where id=f.health_id;
  if v_count <> 0 then raise exception 'Board member can read Medical without an explicit grant'; end if;
end
$assert$;
reset role;

-- The school owner/platform fixture (not the Board member) grants read access.
insert into public.schoolpro_member_permissions(school_id,member_id,permission,allowed,updated_by)
select school_id,member_id,permission,true,owner_id
from pg_temp.board_rls_fixture
cross join (values ('finance'),('payroll'),('medical')) as grants(permission);

set local role authenticated;
do $assert_granted$
declare
  f pg_temp.board_rls_fixture%rowtype;
  v_count integer;
  v_affected integer;
begin
  select * into f from pg_temp.board_rls_fixture;
  select count(*) into v_count from public.schoolpro_fee_structures where id=f.fee_id;
  if v_count <> 1 then raise exception 'Explicit Finance read grant was not honored for Board member'; end if;
  select count(*) into v_count from public.schoolpro_payroll_records where id=f.payroll_id;
  if v_count <> 1 then raise exception 'Explicit Payroll read grant was not honored for Board member'; end if;
  select count(*) into v_count from public.schoolpro_health_records where id=f.health_id;
  if v_count <> 1 then raise exception 'Explicit Medical read grant was not honored for Board member'; end if;
  if (select role from public.schoolpro_members where id=f.member_id) <> 'teacher'::public.school_member_role then
    raise exception 'Explicit module grants changed the Board member underlying role';
  end if;

  update public.schoolpro_fee_structures set amount=amount+1 where id=f.fee_id;
  get diagnostics v_affected = row_count;
  if v_affected <> 0 then raise exception 'Board Finance read grant unexpectedly allowed fee-structure UPDATE'; end if;
  delete from public.schoolpro_fee_structures where id=f.fee_id;
  get diagnostics v_affected = row_count;
  if v_affected <> 0 then raise exception 'Board Finance read grant unexpectedly allowed fee-structure DELETE'; end if;

  update public.schoolpro_payroll_records set gross=gross+1 where id=f.payroll_id;
  get diagnostics v_affected = row_count;
  if v_affected <> 0 then raise exception 'Board Payroll read grant unexpectedly allowed payroll UPDATE'; end if;
  delete from public.schoolpro_payroll_records where id=f.payroll_id;
  get diagnostics v_affected = row_count;
  if v_affected <> 0 then raise exception 'Board Payroll read grant unexpectedly allowed payroll DELETE'; end if;

  update public.schoolpro_health_records set complaint='Board write attempt' where id=f.health_id;
  get diagnostics v_affected = row_count;
  if v_affected <> 0 then raise exception 'Board Medical read grant unexpectedly allowed health-record UPDATE'; end if;
  delete from public.schoolpro_health_records where id=f.health_id;
  get diagnostics v_affected = row_count;
  if v_affected <> 0 then raise exception 'Board Medical read grant unexpectedly allowed health-record DELETE'; end if;

  begin
    insert into public.schoolpro_fee_structures(id,school_id,name,term,session,amount,created_by)
    values(gen_random_uuid(),f.school_id,'Board write attempt','Second Term','2026/2027',1000,f.staff_id);
    raise exception 'Board Finance read grant unexpectedly allowed fee-structure INSERT';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.schoolpro_payroll_records(id,school_id,member_id,period,gross,deductions,status)
    values(gen_random_uuid(),f.school_id,f.member_id,'2026-12',1000,0,'draft');
    raise exception 'Board Payroll read grant unexpectedly allowed payroll INSERT';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.schoolpro_health_records(id,school_id,student_id,complaint,recorded_by)
    values(gen_random_uuid(),f.school_id,f.student_id,'Board write attempt',f.staff_id);
    raise exception 'Board Medical read grant unexpectedly allowed health-record INSERT';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.process_schoolpro_payroll(f.payroll_id);
    raise exception 'Board member unexpectedly executed Payroll approval RPC';
  exception when others then
    if sqlerrm = 'Board member unexpectedly executed Payroll approval RPC' then raise; end if;
  end;
end
$assert_granted$;


-- A direct underlying membership-role change must close the active Board appointment.
select set_config('request.jwt.claim.sub',owner_id::text,true),
       set_config('request.jwt.claims',json_build_object('sub',owner_id::text,'role','authenticated')::text,true)
from pg_temp.board_rls_fixture;
set local role authenticated;
do $role_change$
declare
  f pg_temp.board_rls_fixture%rowtype;
  v_ended timestamptz;
  v_ended_by uuid;
  v_reason text;
begin
  select * into f from pg_temp.board_rls_fixture;
  update public.schoolpro_members set role='class_teacher' where id=f.member_id;
  select ended_at,ended_by,end_reason into v_ended,v_ended_by,v_reason
    from public.schoolpro_board_members where member_id=f.member_id;
  if v_ended is null or v_ended_by <> f.owner_id or v_reason <> 'Membership role changed' then
    raise exception 'Independent membership-role change did not close the active Board appointment';
  end if;
end
$role_change$;
reset role;

-- Exercise the withdrawal path as the school owner. Legacy elevated Board
-- members must return to their recorded role; genuine administrators must stay admins.
select set_config('request.jwt.claim.sub',owner_id::text,true),
       set_config('request.jwt.claims',json_build_object('sub',owner_id::text,'role','authenticated')::text,true)
from pg_temp.board_rls_fixture;
set local role authenticated;
do $withdraw$
declare
  f pg_temp.board_rls_fixture%rowtype;
  v_role public.school_member_role;
  v_ended timestamptz;
  v_ended_by uuid;
  v_reason text;
begin
  select * into f from pg_temp.board_rls_fixture;
  perform private.schoolpro_set_board_role(f.school_id,f.legacy_member_id,null);
  select role into v_role from public.schoolpro_members where id=f.legacy_member_id;
  if v_role <> 'teacher'::public.school_member_role then
    raise exception 'Withdrawing legacy Board appointment did not restore the recorded Teacher role';
  end if;
  select ended_at,ended_by,end_reason into v_ended,v_ended_by,v_reason
    from public.schoolpro_board_members where member_id=f.legacy_member_id;
  if v_ended is null or v_ended_by <> f.owner_id or v_reason <> 'Appointment withdrawn' then
    raise exception 'Legacy Board appointment withdrawal audit fields are incorrect';
  end if;

  perform private.schoolpro_set_board_role(f.school_id,f.genuine_admin_member_id,null);
  select role into v_role from public.schoolpro_members where id=f.genuine_admin_member_id;
  if v_role <> 'administrator'::public.school_member_role then
    raise exception 'Withdrawing a Board appointment demoted a genuine administrator';
  end if;
end
$withdraw$;
reset role;
rollback;
select 'PASS: Board RLS denial, Payroll RPC denial, legacy role restoration and genuine administrator preservation' as result;
