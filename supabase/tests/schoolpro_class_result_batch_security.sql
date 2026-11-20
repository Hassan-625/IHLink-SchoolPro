-- Class-result batch persistence/security contract regression.
-- Run against a disposable database only after applying the candidate migration.
-- This metadata-only suite does not create or mutate school/student records.
begin;

do $test$
declare
  v_table text;
  v_function text;
  v_source text;
  v_bucket record;
  v_policy_count integer;
begin
  foreach v_table in array array[
    'schoolpro_class_result_batches',
    'schoolpro_class_result_batch_reviews'
  ] loop
    if not exists (
      select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public' and c.relname=v_table and c.relrowsecurity
    ) then
      raise exception 'RLS is not enabled on public.%',v_table;
    end if;

    if has_table_privilege('anon','public.'||v_table,'SELECT,INSERT,UPDATE,DELETE')
       or has_table_privilege('authenticated','public.'||v_table,'INSERT,UPDATE,DELETE') then
      raise exception 'Direct anon or authenticated write access remains on public.%',v_table;
    end if;

    if not has_table_privilege('authenticated','public.'||v_table,'SELECT') then
      raise exception 'Authenticated staff cannot read public.% through RLS',v_table;
    end if;

    if exists (
      select 1 from pg_policies
      where schemaname='public' and tablename=v_table
        and (cmd='ALL' or not ('authenticated'=any(roles)))
    ) then
      raise exception 'Unexpected broad or non-authenticated policy on public.%',v_table;
    end if;
  end loop;

  v_function:='public.schoolpro_create_class_result_batch(uuid,uuid,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb,jsonb)';
  if to_regprocedure(v_function) is null
     or has_function_privilege('anon',v_function,'EXECUTE')
     or not has_function_privilege('authenticated',v_function,'EXECUTE') then
    raise exception 'Create-batch RPC execute grants are incorrect';
  end if;
  select p.prosrc into v_source from pg_proc p where p.oid=to_regprocedure(v_function);
  if position('schoolpro_enrollment_history' in v_source)=0
     or position('eh.school_id=p_school' in v_source)=0
     or position('eh.class_id=p_class' in v_source)=0
     or position('eh.session=trim(p_session)' in v_source)=0
     or position('eh.status=''active''' in v_source)=0 then
    raise exception 'Create-batch RPC does not independently validate exact historical enrollment';
  end if;

  v_function:='public.schoolpro_mark_class_result_batch_ready(uuid)';
  if to_regprocedure(v_function) is null
     or has_function_privilege('anon',v_function,'EXECUTE')
     or not has_function_privilege('authenticated',v_function,'EXECUTE') then
    raise exception 'Mark-ready RPC execute grants are incorrect';
  end if;

  v_function:='public.schoolpro_review_class_result_batch_student(uuid,uuid,text,uuid)';
  if to_regprocedure(v_function) is null
     or has_function_privilege('anon',v_function,'EXECUTE')
     or not has_function_privilege('authenticated',v_function,'EXECUTE') then
    raise exception 'Review RPC execute grants are incorrect';
  end if;
  select p.prosrc into v_source from pg_proc p where p.oid=to_regprocedure(v_function);
  if position('schoolpro_generated_result_outputs' in v_source)=0
     or position('o.student_id=p_student_id' in v_source)=0
     or position('o.term=v_batch.term' in v_source)=0
     or position('o.session=v_batch.session' in v_source)=0 then
    raise exception 'Approval does not require the matching individual official output';
  end if;

  select * into v_bucket from storage.buckets
  where id='schoolpro-class-result-batches';
  if not found or v_bucket.public is distinct from false
     or v_bucket.file_size_limit<>52428800 then
    raise exception 'Dedicated class-result bucket must be private and limited to 50 MiB';
  end if;

  select count(*) into v_policy_count from pg_policies
  where schemaname='storage' and tablename='objects'
    and policyname like 'schoolpro_class_result_batches_storage_%';
  if v_policy_count<>3 then
    raise exception 'Expected exactly three dedicated class-result storage policies; found %',v_policy_count;
  end if;

  if exists (
    select 1 from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname like 'schoolpro_class_result_batches_storage_%'
      and not ('authenticated'=any(roles))
  ) then
    raise exception 'Class-result storage policy is not restricted to authenticated users';
  end if;

  if position('private.schoolpro_can_read_class' in (
    select p.prosrc from pg_proc p
    where p.oid=to_regprocedure('private.schoolpro_can_manage_class_result_batch(uuid,uuid,text)')
  ))>0 then
    raise exception 'Staff-only helper must not delegate to class-read helper that admits students/guardians';
  end if;
end
$test$;


-- Runtime authorization regression with transaction-scoped fixtures. The
-- rollback below removes all fixture rows; this never touches live schools.
do $runtime$
declare
  v_owner uuid:=gen_random_uuid();
  v_form_teacher uuid:=gen_random_uuid();
  v_unassigned_teacher uuid:=gen_random_uuid();
  v_student uuid:=gen_random_uuid();
  v_guardian uuid:=gen_random_uuid();
  v_super_admin uuid:=gen_random_uuid();
  v_school uuid:=gen_random_uuid();
  v_class uuid:=gen_random_uuid();
  v_form_member uuid:=gen_random_uuid();
  v_unassigned_member uuid:=gen_random_uuid();
begin
  insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
  select x.id,'authenticated','authenticated','batch-fixture-'||x.id||'@example.invalid','{}','{}',now(),now()
  from (values(v_owner),(v_form_teacher),(v_unassigned_teacher),(v_student),(v_guardian),(v_super_admin)) x(id);

  insert into public.profiles(id,email,status,role)
  select x.id,'batch-fixture-'||x.id||'@example.invalid','active','customer'::public.user_role
  from (values(v_owner),(v_form_teacher),(v_unassigned_teacher),(v_student),(v_guardian),(v_super_admin)) x(id)
  on conflict (id) do update set status='active';
  update public.profiles set role='super_admin' where id=v_super_admin;

  insert into public.schoolpro_schools(id,owner_id,name,code)
  values(v_school,v_owner,'Class batch security fixture','BATCH-'||replace(v_school::text,'-',''));
  insert into public.schoolpro_members(id,school_id,user_id,role,status,employment_status)
  values
    (v_form_member,v_school,v_form_teacher,'teacher','active','active'),
    (v_unassigned_member,v_school,v_unassigned_teacher,'teacher','active','active');
  insert into public.schoolpro_classes(id,school_id,name,level,form_teacher_id)
  values(v_class,v_school,'Fixture Class','primary',v_form_member);

  execute 'set local role authenticated';

  perform set_config('request.jwt.claim.sub',v_owner::text,true);
  if not private.schoolpro_can_manage_class_result_batch(v_school,v_class,'2026/2027') then
    raise exception 'School owner was denied class-result batch access';
  end if;

  perform set_config('request.jwt.claim.sub',v_form_teacher::text,true);
  if not private.schoolpro_can_manage_class_result_batch(v_school,v_class,'2026/2027') then
    raise exception 'Assigned Form Master was denied class-result batch access';
  end if;

  perform set_config('request.jwt.claim.sub',v_unassigned_teacher::text,true);
  if private.schoolpro_can_manage_class_result_batch(v_school,v_class,'2026/2027') then
    raise exception 'Unassigned teacher gained class-result batch access';
  end if;

  perform set_config('request.jwt.claim.sub',v_student::text,true);
  if private.schoolpro_can_manage_class_result_batch(v_school,v_class,'2026/2027') then
    raise exception 'Student gained staff-only class-result batch access';
  end if;

  perform set_config('request.jwt.claim.sub',v_guardian::text,true);
  if private.schoolpro_can_manage_class_result_batch(v_school,v_class,'2026/2027') then
    raise exception 'Guardian gained staff-only class-result batch access';
  end if;

  perform set_config('request.jwt.claim.sub',v_super_admin::text,true);
  if not private.schoolpro_can_manage_class_result_batch(v_school,v_class,'2026/2027') then
    raise exception 'Super Admin was denied class-result batch access';
  end if;

  execute 'reset role';
end
$runtime$;

rollback;
