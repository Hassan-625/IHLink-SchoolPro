-- Runtime RLS regression: Board designation must not grant Finance, Payroll or Medical access.
-- Runs only against the disposable Supabase database restored by schoolpro-c0-regression.yml.
begin;
do $test$
declare
  v_owner uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_school uuid := gen_random_uuid();
  v_member uuid := gen_random_uuid();
  v_student uuid := gen_random_uuid();
  v_fee uuid := gen_random_uuid();
  v_payroll uuid := gen_random_uuid();
  v_health uuid := gen_random_uuid();
  v_count integer;
begin
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
  insert into public.schoolpro_payroll_records(id,school_id,period,gross,deductions,status)
  values(v_payroll,v_school,'2026-11',1000,0,'draft');
  insert into public.schoolpro_health_records(id,school_id,student_id,complaint,recorded_by)
  values(v_health,v_school,v_student,'RLS fixture',v_owner);

  perform set_config('request.jwt.claim.sub',v_staff::text,true);
  perform set_config('request.jwt.claims',json_build_object('sub',v_staff::text,'role','authenticated')::text,true);
  execute 'set local role authenticated';

  if private.has_school_access(v_school,array['proprietor','administrator']::public.school_member_role[]) then
    raise exception 'Board member unexpectedly passes direct proprietor/administrator role check';
  end if;
  if (select role from public.schoolpro_members where id=v_member) <> 'teacher'::public.school_member_role then
    raise exception 'Board designation changed the actual membership role';
  end if;
  select count(*) into v_count from public.schoolpro_fee_structures where id=v_fee;
  if v_count <> 0 then raise exception 'Board member can read Finance fee structures'; end if;
  select count(*) into v_count from public.schoolpro_payroll_records where id=v_payroll;
  if v_count <> 0 then raise exception 'Board member can read Payroll records'; end if;
  select count(*) into v_count from public.schoolpro_health_records where id=v_health;
  if v_count <> 0 then raise exception 'Board member can read Medical records'; end if;
  begin
    perform public.process_schoolpro_payroll(v_payroll);
    raise exception 'Board member unexpectedly executed Payroll approval RPC';
  exception when others then
    if sqlerrm = 'Board member unexpectedly executed Payroll approval RPC' then raise; end if;
  end;
  execute 'reset role';
end
$test$;
rollback;
select 'PASS: Board designation denied direct Finance, Payroll and Medical RLS access and Payroll approval RPC' as result;
