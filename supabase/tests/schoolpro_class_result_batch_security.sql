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

  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='schoolpro_class_result_batch_reviews'
      and column_name='student_storage_path' and is_nullable='NO'
  ) then
    raise exception 'Each batch review must have a durable private student workbook path';
  end if;

  v_function:='public.schoolpro_fail_class_result_batch_upload(uuid)';
  if to_regprocedure(v_function) is null
     or has_function_privilege('anon',v_function,'EXECUTE')
     or not has_function_privilege('authenticated',v_function,'EXECUTE') then
    raise exception 'Fail-upload RPC execute grants are incorrect (exists=%, anon_execute=%, authenticated_execute=%, acl=%, anon_member_authenticated=%)',
      to_regprocedure(v_function) is not null,
      has_function_privilege('anon',v_function,'EXECUTE'),
      has_function_privilege('authenticated',v_function,'EXECUTE'),
      (select coalesce(p.proacl::text,'<default>') from pg_proc p where p.oid=to_regprocedure(v_function)),
      pg_has_role('anon','authenticated','MEMBER');
  end if;

  v_function:='public.schoolpro_recover_stale_class_result_batch_uploads(uuid,uuid,text,text)';
  if to_regprocedure(v_function) is null
     or has_function_privilege('anon',v_function,'EXECUTE')
     or not has_function_privilege('authenticated',v_function,'EXECUTE') then
    raise exception 'Stale-upload recovery RPC execute grants are incorrect';
  end if;
  select p.prosrc into v_source from pg_proc p where p.oid=to_regprocedure(v_function);
  if position('45 minutes' in v_source)=0
     or position('status=''uploading''' in v_source)=0
     or position('status=''failed''' in v_source)=0
     or position('student_storage_path' in v_source)=0 then
    raise exception 'Stale-upload recovery must retire old uploading batches and return their student object paths';
  end if;

  v_function:='public.schoolpro_mark_class_result_batch_ready(uuid)';
  if to_regprocedure(v_function) is null
     or has_function_privilege('anon',v_function,'EXECUTE')
     or not has_function_privilege('authenticated',v_function,'EXECUTE') then
    raise exception 'Mark-ready RPC execute grants are incorrect';
  end if;

  select p.prosrc into v_source from pg_proc p
  where p.oid=to_regprocedure('public.schoolpro_mark_class_result_batch_ready(uuid)');
  if position('student_storage_path' in v_source)=0
     or position('schoolpro-class-result-batches' in v_source)=0 then
    raise exception 'Mark-ready RPC must verify every private per-student workbook upload';
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

  v_function:='public.schoolpro_record_generated_result_output(uuid,uuid,uuid,text,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb)';
  if to_regprocedure(v_function) is null
     or has_function_privilege('anon',v_function,'EXECUTE')
     or not has_function_privilege('authenticated',v_function,'EXECUTE') then
    raise exception 'Individual output RPC execute grants are incorrect';
  end if;
  select p.prosrc into v_source from pg_proc p where p.oid=to_regprocedure(v_function);
  if position('schoolpro_enrollment_history' in v_source)=0
     or position('eh.class_id=p_class' in v_source)=0
     or position('eh.session=trim(p_session)' in v_source)=0
     or position('eh.status=''active''' in v_source)=0
     or position('st.class_id' in v_source)>0 then
    raise exception 'Individual output RPC must validate historical enrollment, not current student class';
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

  if position('student_storage_path' in (
    select qual from pg_policies
    where schemaname='storage' and tablename='objects'
      and policyname='schoolpro_class_result_batches_storage_delete_failed'
  ))=0 then
    raise exception 'Failed-upload cleanup policy must permit deleting per-student workbook objects';
  end if;

  if position('approved student review cannot be changed' in (
    select p.prosrc from pg_proc p
    where p.oid=to_regprocedure('public.schoolpro_review_class_result_batch_student(uuid,uuid,text,uuid)')
  ))=0 then
    raise exception 'Approved batch reviews must be immutable';
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
  v_other_class uuid:=gen_random_uuid();
  v_student_record uuid:=gen_random_uuid();
  v_other_student_record uuid:=gen_random_uuid();
  v_template_id uuid:=gen_random_uuid();
  v_assignment_id uuid:=gen_random_uuid();
  v_assignment_updated_at timestamptz;
  v_batch_id uuid;
  v_output_id uuid;
  v_config jsonb:='{"sheet":"Results"}'::jsonb;
  v_mappings jsonb:='{"subjectRows":[]}'::jsonb;
  v_formula jsonb:='{"engine":"hot-formula-parser","engineVersion":"4.0.0","formulaCount":0,"calculationMode":"same-sheet-dependency-graph"}'::jsonb;
  v_roster jsonb;
  v_denied boolean;
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
  update public.schoolpro_schools set status='active' where id=v_school;
  insert into public.schoolpro_subscriptions(school_id,tier,billing_cycle,status,renews_at)
  values(v_school,'standard','termly','active',now()+interval '90 days');
  insert into public.schoolpro_members(id,school_id,user_id,role,status,employment_status)
  values
    (v_form_member,v_school,v_form_teacher,'teacher','active','active'),
    (v_unassigned_member,v_school,v_unassigned_teacher,'teacher','active','active');
  insert into public.schoolpro_classes(id,school_id,name,level,form_teacher_id)
  values
    (v_class,v_school,'Fixture Class','primary',v_form_member),
    (v_other_class,v_school,'Other Fixture Class','primary',null);

  -- Current student.class_id deliberately differs from the selected session's
  -- enrollment-history class. Batch creation must use history, not current placement.
  insert into public.schoolpro_students(
    id,school_id,admission_number,first_name,last_name,class_name,class_id,user_id
  ) values
    (v_student_record,v_school,'BATCH-STUDENT-1','Test','Learner','Other Fixture Class',v_other_class,v_student),
    (v_other_student_record,v_school,'BATCH-STUDENT-2','Other','Learner','Other Fixture Class',v_other_class,null);

  insert into public.schoolpro_enrollment_history(
    school_id,student_id,session,class_id,class_name,section,status
  ) values
    (v_school,v_student_record,'2026/2027',v_class,'Fixture Class','Primary','active'),
    (v_school,v_other_student_record,'2026/2027',v_other_class,'Other Fixture Class','Primary','active');

  insert into public.schoolpro_result_template_library(
    id,school_id,name,storage_path,sheet_name,template_config,created_by,updated_by
  ) values (
    v_template_id,v_school,'Batch fixture template',
    v_school::text||'/templates/batch-fixture.xlsx','Results',
    v_config,v_owner,v_owner
  );

  insert into public.schoolpro_result_template_assignments(
    id,school_id,class_id,term,session,template_name,template_config,
    subject_row_mappings,updated_by,template_id
  ) values (
    v_assignment_id,v_school,v_class,'First Term','2026/2027',
    'Batch fixture template',v_config,v_mappings,v_owner,v_template_id
  ) returning updated_at into v_assignment_updated_at;

  execute 'set local role authenticated';

  v_roster:=jsonb_build_array(jsonb_build_object(
    'student_id',v_student_record,'student_order',1
  ));

  -- Exercise authorization through the public SECURITY DEFINER RPC. The
  -- private schema intentionally has no direct USAGE grant to authenticated.
  perform set_config('request.jwt.claim.sub',v_form_teacher::text,true);
  perform public.schoolpro_create_class_result_batch(
    v_school,v_class,'First Term','2026/2027',v_assignment_id,v_template_id,
    v_assignment_updated_at,v_config,v_mappings,v_formula,v_roster
  );

  foreach v_unassigned_member in array array[v_unassigned_teacher,v_student,v_guardian] loop
    perform set_config('request.jwt.claim.sub',v_unassigned_member::text,true);
    v_denied:=false;
    begin
      perform public.schoolpro_create_class_result_batch(
        v_school,v_class,'First Term','2026/2027',v_assignment_id,v_template_id,
        v_assignment_updated_at,v_config,v_mappings,v_formula,v_roster
      );
    exception when others then v_denied:=true;
    end;
    if not v_denied then
      raise exception 'Unassigned teacher, student, or guardian gained staff-only batch access';
    end if;
  end loop;

  perform set_config('request.jwt.claim.sub',v_super_admin::text,true);
  perform public.schoolpro_create_class_result_batch(
    v_school,v_class,'First Term','2026/2027',v_assignment_id,v_template_id,
    v_assignment_updated_at,v_config,v_mappings,v_formula,v_roster
  );

  -- Owner creates a batch using the historical class placement, even though
  -- the student's current class_id points elsewhere.
  perform set_config('request.jwt.claim.sub',v_owner::text,true);
  v_batch_id:=public.schoolpro_create_class_result_batch(
    v_school,v_class,'First Term','2026/2027',v_assignment_id,v_template_id,
    v_assignment_updated_at,v_config,v_mappings,v_formula,v_roster
  );
  -- Inspect fixture rows as the database owner; authenticated access is
  -- exercised through the RPCs and the dedicated RLS checks above.
  execute 'reset role';
  if not exists (
    select 1 from public.schoolpro_class_result_batches b
    where b.id=v_batch_id and b.status='uploading'
      and b.expected_student_count=1
      and b.storage_path=v_school::text||'/'||v_class::text||'/'||v_batch_id::text||'/workbook.xlsx'
  ) then
    raise exception 'Valid historical-session class batch was not persisted correctly';
  end if;
  if not exists (
    select 1 from public.schoolpro_class_result_batch_reviews r
    where r.batch_id=v_batch_id and r.student_id=v_student_record
      and r.student_order=1 and r.review_status='pending'
  ) then
    raise exception 'Per-student pending review row was not created';
  end if;

  -- Simulate the two Storage objects as transaction-scoped rows, then
  -- exercise upload verification and official per-student approval.
  execute 'reset role';
  insert into storage.objects(bucket_id,name,owner_id,owner,metadata)
  select 'schoolpro-class-result-batches',b.storage_path,v_owner::text,v_owner,
    '{"mimetype":"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","size":1024}'::jsonb
  from public.schoolpro_class_result_batches b where b.id=v_batch_id;
  -- Mark-ready must fail until every per-student private workbook exists.
  execute 'set local role authenticated';
  perform set_config('request.jwt.claim.sub',v_owner::text,true);
  v_denied:=false;
  begin
    perform public.schoolpro_mark_class_result_batch_ready(v_batch_id);
  exception when others then v_denied:=true;
  end;
  if not v_denied then raise exception 'Batch became ready without its private student workbook'; end if;
  execute 'reset role';

  insert into storage.objects(bucket_id,name,owner_id,owner,metadata)
  select 'schoolpro-class-result-batches',r.student_storage_path,v_owner::text,v_owner,
    '{"mimetype":"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","size":2048}'::jsonb
  from public.schoolpro_class_result_batch_reviews r where r.batch_id=v_batch_id;

  execute 'set local role authenticated';
  perform set_config('request.jwt.claim.sub',v_owner::text,true);
  insert into storage.objects(bucket_id,name,owner_id,owner,metadata)
  values (
    'schoolpro-result-outputs',
    v_school::text||'/'||v_student_record::text||'/official-result.xlsx',
    v_owner::text,v_owner,
    '{"mimetype":"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","size":1024}'::jsonb
  );
  v_output_id:=public.schoolpro_record_generated_result_output(
    v_school,v_student_record,v_class,'First Term','2026/2027',
    v_school::text||'/'||v_student_record::text||'/official-result.xlsx',
    v_assignment_id,v_template_id,v_assignment_updated_at,
    v_config,v_mappings,v_formula
  );
  if v_output_id is null then raise exception 'Historical-session official output RPC returned no output ID'; end if;
  if public.schoolpro_mark_class_result_batch_ready(v_batch_id)<>'prepared' then
    raise exception 'Batch did not transition to prepared after verified private upload';
  end if;

  -- Rejection must leave the official output unlinked and the batch
  -- recoverable. A later resumed review may approve the same rejected item.
  if public.schoolpro_review_class_result_batch_student(
    v_batch_id,v_student_record,'rejected',null
  )<>'needs_attention' then
    raise exception 'Rejected student review did not flag the batch for attention';
  end if;

  -- Inspect persisted state as the database owner so RLS policy helpers
  -- remain tested only through the public SECURITY DEFINER RPC boundary.
  execute 'reset role';
  if not exists (
    select 1 from public.schoolpro_class_result_batch_reviews r
    join public.schoolpro_class_result_batches b on b.id=r.batch_id
    where r.batch_id=v_batch_id and r.student_id=v_student_record
      and r.review_status='rejected' and r.generated_result_output_id is null
      and b.status='needs_attention'
  ) then
    raise exception 'Rejected review must not link an official output and must remain resumable';
  end if;

  execute 'set local role authenticated';
  perform set_config('request.jwt.claim.sub',v_owner::text,true);

  if public.schoolpro_review_class_result_batch_student(
    v_batch_id,v_student_record,'approved',v_output_id
  )<>'completed' then
    raise exception 'Approved final student review did not complete the batch';
  end if;

  execute 'reset role';
  if not exists (
    select 1 from public.schoolpro_class_result_batch_reviews r
    join public.schoolpro_generated_result_outputs o on o.id=r.generated_result_output_id
    join public.schoolpro_class_result_batches b on b.id=r.batch_id
    where r.batch_id=v_batch_id and r.review_status='approved'
      and o.student_id=v_student_record and b.status='completed'
  ) then
    raise exception 'Approved batch review was not linked to its official individual output';
  end if;

  -- Duplicate IDs, another class's historical enrollment and stale design
  -- snapshots must each fail closed without creating another batch.
  v_denied:=false;
  begin
    perform public.schoolpro_create_class_result_batch(
      v_school,v_class,'First Term','2026/2027',v_assignment_id,v_template_id,
      v_assignment_updated_at,v_config,v_mappings,v_formula,
      jsonb_build_array(
        jsonb_build_object('student_id',v_student_record,'student_order',1),
        jsonb_build_object('student_id',v_student_record,'student_order',2)
      )
    );
  exception when others then v_denied:=true;
  end;
  if not v_denied then raise exception 'Duplicate student ID was accepted'; end if;

  v_denied:=false;
  begin
    perform public.schoolpro_create_class_result_batch(
      v_school,v_class,'First Term','2026/2027',v_assignment_id,v_template_id,
      v_assignment_updated_at,v_config,v_mappings,v_formula,
      jsonb_build_array(jsonb_build_object('student_id',v_other_student_record,'student_order',1))
    );
  exception when others then v_denied:=true;
  end;
  if not v_denied then raise exception 'Cross-class historical roster row was accepted'; end if;

  v_denied:=false;
  begin
    perform public.schoolpro_create_class_result_batch(
      v_school,v_class,'First Term','2026/2027',v_assignment_id,v_template_id,
      v_assignment_updated_at,v_config||'{"stale":true}'::jsonb,v_mappings,v_formula,v_roster
    );
  exception when others then v_denied:=true;
  end;
  if not v_denied then raise exception 'Stale template configuration snapshot was accepted'; end if;

  execute 'reset role';
end
$runtime$;

rollback;
