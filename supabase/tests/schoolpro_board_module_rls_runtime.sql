-- Runtime RLS regression: Board designation must not grant Finance, Payroll or Medical access.
-- Runs only against the disposable Supabase database restored by schoolpro-c0-regression.yml.
begin;
create temporary table board_rls_fixture (
  owner_id uuid, staff_id uuid, school_id uuid, member_id uuid,
  student_id uuid, fee_id uuid, payroll_id uuid, health_id uuid
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
begin
  insert into pg_temp.board_rls_fixture values
    (v_owner,v_staff,v_school,v_member,v_student,v_fee,v_payroll,v_health);
  insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  values
    (v_owner,'authenticated','authenticated','owner-'||v_owner||'@example.invalid','{}','{}',now(),now()),
    (v_staff,'authenticated','authenticated','staff-'||v_staff||'@example.invalid','{}','{}',now(),now());
  insert into public.profiles(id,email)
  values (v_owner,'owner-'||v_owner||'@example.invalid'),(v_staff,'staff-'||v_staff||'@example.invalid')
  on conflict(id) do nothing;
  insert into public.schoolpro_schools(id,owner_id,name,code)
  values(v_school,v_owner,'Board RLS runtime fixture','BR-'||v_school);
  insert into public.schoolpro_members(id,school_id,user_id,role)
  values(v_member,v_school,v_staff,'teacher');
  insert into public.schoolpro_board_members(member_id,school_id,title,previous_role,appointed_by)
  values(v_member,v_school,'Board Member','teacher',v_owner);
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
  if v_count <> 0 then raise exception 'Board member can read Finance fee structures'; end if;
  select count(*) into v_count from public.schoolpro_payroll_records where id=f.payroll_id;
  if v_count <> 0 then raise exception 'Board member can read Payroll records'; end if;
  select count(*) into v_count from public.schoolpro_health_records where id=f.health_id;
  if v_count <> 0 then raise exception 'Board member can read Medical records'; end if;
  begin
    perform public.process_schoolpro_payroll(f.payroll_id);
    raise exception 'Board member unexpectedly executed Payroll approval RPC';
  exception when others then
    if sqlerrm = 'Board member unexpectedly executed Payroll approval RPC' then raise; end if;
  end;
end
$assert$;
reset role;
rollback;
select 'PASS: Board designation denied direct Finance, Payroll and Medical RLS access and Payroll approval RPC' as result;
