\set ON_ERROR_STOP on

create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;
create schema storage;
create type public.school_member_role as enum ('proprietor','administrator','subject_teacher','class_teacher','exam_officer');

create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create or replace function private.has_school_access(p_school uuid)
returns boolean language sql stable as $$ select true $$;
create or replace function private.has_school_access(p_school uuid,p_roles public.school_member_role[])
returns boolean language sql stable as $$ select current_setting('test.school_admin',true)='true' $$;
create or replace function private.is_active_account()
returns boolean language sql stable as $$ select current_setting('test.active',true)='true' $$;
create or replace function private.schoolpro_is_exam_officer(p_school uuid)
returns boolean language sql stable as $$ select current_setting('test.exam_officer',true)='true' $$;

create table public.profiles(id uuid primary key);
create table public.schoolpro_schools(id uuid primary key);
create table public.schoolpro_classes(
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  level text not null,
  archived_at timestamptz,
  form_teacher_id uuid
);
create table public.schoolpro_members(
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  user_id uuid not null,
  status text not null
);
create table public.schoolpro_subjects(
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  name text not null,
  code text not null,
  class_name text not null
);
create table public.schoolpro_subject_assignments(
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id),
  class_id uuid not null references public.schoolpro_classes(id),
  subject_id uuid not null references public.schoolpro_subjects(id),
  teacher_member_id uuid,
  session text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(class_id,subject_id,session)
);
create table storage.objects(bucket_id text not null,name text not null,primary key(bucket_id,name));

insert into public.schoolpro_schools(id) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
-- Seed legacy subject rows before the migration. Unambiguous rows may be
-- promoted; ambiguous duplicates must retain their original IDs unchanged.
insert into public.schoolpro_subjects(id,school_id,name,code,class_name) values
 ('10000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Mathematics','MTH','Primary'),
 ('10000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Physical Development','PHY-N','Nursery'),
 ('10000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','  physical   development ','PHY-P','Primary');

create table public.schoolpro_generated_result_outputs(
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  student_id uuid not null,
  term text not null,
  session text not null,
  format text not null,
  storage_path text not null,
  generated_by uuid,
  generated_at timestamptz not null default now()
);

\ir ../supabase/migrations/20261118100000_schoolpro_class_term_result_template_assignments.sql
\ir ../supabase/migrations/20261118143000_schoolpro_audited_legacy_subject_catalogue_promotion.sql

do $privileges$
begin
  if has_table_privilege('authenticated','public.schoolpro_result_template_assignments','INSERT')
     or has_table_privilege('authenticated','public.schoolpro_result_template_assignments','UPDATE')
     or has_table_privilege('authenticated','public.schoolpro_result_template_assignments','DELETE') then
    raise exception 'ASSERT: authenticated users can directly mutate class result-template assignments';
  end if;
  if has_table_privilege('authenticated','public.schoolpro_result_template_assignment_audit','INSERT')
     or has_table_privilege('authenticated','public.schoolpro_class_subject_selection_audit','INSERT') then
    raise exception 'ASSERT: authenticated users can directly forge subject or template audit rows';
  end if;
  if not has_table_privilege('authenticated','public.schoolpro_class_subject_selection_audit','SELECT') then
    raise exception 'ASSERT: authorized school members cannot read subject-selection audit history';
  end if;
end;
$privileges$;


do $catalogue$
begin
  if not (select is_catalogue_entry from public.schoolpro_subjects where id='10000000-0000-4000-8000-000000000001') then
    raise exception 'ASSERT: unique legacy subject was not promoted to the canonical catalogue';
  end if;
  if (select count(*) from public.schoolpro_subjects where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and lower(regexp_replace(btrim(name),'\s+',' ','g'))='physical development' and is_catalogue_entry)<>0 then
    raise exception 'ASSERT: ambiguous historical duplicate subjects were incorrectly promoted';
  end if;
  begin
    insert into public.schoolpro_subjects(id,school_id,name,code,class_name,is_catalogue_entry)
    values('10000000-0000-4000-8000-000000000004','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','  MATHEMATICS  ','MATH2','Primary',true);
    raise exception 'ASSERT: duplicate canonical subject name was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('already exists in the school catalogue' in sqlerrm)=0 then raise; end if;
  end;
  begin
    insert into public.schoolpro_subjects(id,school_id,name,code,class_name,is_catalogue_entry)
    values('10000000-0000-4000-8000-000000000005','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Mathematics','MATH3','Primary',false);
    raise exception 'ASSERT: unflagged duplicate subject insert bypassed the database guard';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('already exists in the school catalogue' in sqlerrm)=0 then raise; end if;
  end;

  if (select count(*) from public.schoolpro_subjects where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and lower(regexp_replace(btrim(name),'\s+',' ','g'))='physical development')<>2 then
    raise exception 'ASSERT: legacy duplicate subject rows were deleted or rewritten';
  end if;
end;
$catalogue$;

-- Same normalized subject name remains legal in a different school.
insert into public.schoolpro_subjects(id,school_id,name,code,class_name,is_catalogue_entry)
values('20000000-0000-4000-8000-000000000001','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','Mathematics','MTH','Primary',true);

insert into public.profiles(id) values
 ('30000000-0000-4000-8000-000000000001'),
 ('30000000-0000-4000-8000-000000000002');
insert into public.schoolpro_members(id,school_id,user_id,status) values
 ('40000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001','active'),
 ('40000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000002','active');
insert into public.schoolpro_classes(id,school_id,level,form_teacher_id) values
 ('50000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Primary 1','40000000-0000-4000-8000-000000000001'),
 ('50000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Primary 2',null);

-- English is already allocated by the administrator to a teacher. Form Master
-- selection must return that row without replacing its teacher allocation.
insert into public.schoolpro_subjects(id,school_id,name,code,class_name,is_catalogue_entry) values
 ('10000000-0000-4000-8000-000000000006','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','English Language','ENG','Primary',true);
insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,teacher_member_id,session) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000006','40000000-0000-4000-8000-000000000002','2026/2027');

select set_config('request.jwt.claim.sub','30000000-0000-4000-8000-000000000001',false);
select set_config('test.active','true',false);
select set_config('test.school_admin','false',false);
select set_config('test.exam_officer','false',false);
select set_config('test.school_admin','true',false);
do $legacy_promotion_rpc$
begin
  perform public.schoolpro_promote_legacy_subject_to_catalogue(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000003'
  );
  if not (select is_catalogue_entry from public.schoolpro_subjects where id='10000000-0000-4000-8000-000000000003')
     or (select is_catalogue_entry from public.schoolpro_subjects where id='10000000-0000-4000-8000-000000000002') then
    raise exception 'ASSERT: audited RPC promoted the wrong legacy subject record';
  end if;
  if (select count(*) from public.schoolpro_subject_catalogue_promotion_audit where subject_id='10000000-0000-4000-8000-000000000003')<>1 then
    raise exception 'ASSERT: legacy subject promotion was not audited exactly once';
  end if;
  begin
    perform public.schoolpro_promote_legacy_subject_to_catalogue(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000002'
    );
    raise exception 'ASSERT: RPC promoted a second same-name legacy record';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('A canonical subject with this name already exists' in sqlerrm)=0 then raise; end if;
  end;
  if (select count(*) from public.schoolpro_subjects where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and lower(regexp_replace(btrim(name),'\s+',' ','g'))='physical development')<>2 then
    raise exception 'ASSERT: legacy duplicate subject rows were deleted or rewritten';
  end if;
end;
$legacy_promotion_rpc$;
select set_config('test.school_admin','false',false);
do $legacy_promotion_denied$
begin
  begin
    perform public.schoolpro_promote_legacy_subject_to_catalogue(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000002'
    );
    raise exception 'ASSERT: non-admin promoted a legacy subject';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Only an active school administrator' in sqlerrm)=0 then raise; end if;
  end;
end;
$legacy_promotion_denied$;

do $form_master$
declare
  v_math uuid;
  v_english uuid;
  v_assignment uuid;
  v_teacher uuid;
begin
  v_math:=public.schoolpro_form_master_add_class_subject(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000001','2026/2027');
  if v_math is null then raise exception 'ASSERT: Form Master subject selection did not return an assignment'; end if;
  v_english:=public.schoolpro_form_master_add_class_subject(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000006','2026/2027');
  select teacher_member_id into v_teacher from public.schoolpro_subject_assignments where id=v_english;
  if v_teacher is distinct from '40000000-0000-4000-8000-000000000002'::uuid then
    raise exception 'ASSERT: Form Master selection overwrote an existing teacher allocation';
  end if;
  perform public.schoolpro_form_master_add_class_subject(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000001','2026/2027');
  if (select count(*) from public.schoolpro_subject_assignments where class_id='50000000-0000-4000-8000-000000000001' and session='2026/2027')<>2 then
    raise exception 'ASSERT: repeated Form Master selection created duplicate class-subject allocations';
  end if;
  if (select count(*) from public.schoolpro_class_subject_selection_audit where class_id='50000000-0000-4000-8000-000000000001')<>1 then
    raise exception 'ASSERT: Form Master subject selection audit is missing or duplicates an idempotent retry';
  end if;
  begin
    perform public.schoolpro_form_master_add_class_subject(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000002',
      '10000000-0000-4000-8000-000000000001','2026/2027');
    raise exception 'ASSERT: Form Master selected a subject outside their assigned class';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Only the Form Master assigned to this class' in sqlerrm)=0 then raise; end if;
  end;
  begin
    perform public.schoolpro_form_master_add_class_subject(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      '10000000-0000-4000-8000-000000000002','2026/2027');
    raise exception 'ASSERT: Form Master selected ambiguous legacy subject not in canonical catalogue';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('existing canonical subject' in sqlerrm)=0 then raise; end if;
  end;
  begin
    perform public.schoolpro_form_master_add_class_subject(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      '20000000-0000-4000-8000-000000000001','2026/2027');
    raise exception 'ASSERT: cross-school subject entered a class catalogue';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('existing canonical subject' in sqlerrm)=0 then raise; end if;
  end;
end;
$form_master$;

do $legacy_allocation$
begin
  begin
    insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,teacher_member_id,session)
    values('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      '10000000-0000-4000-8000-000000000002',null,'2026/2027');
    raise exception 'ASSERT: non-canonical legacy subject allocation was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('canonical subject' in sqlerrm)=0 then raise; end if;
  end;
end;
$legacy_allocation$;

-- A saved custom workbook and section mapping are required for the class-level
-- assignment. The same canonical subject IDs are used in the row mapping.
insert into storage.objects(bucket_id,name) values
 ('school-result-templates','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx');
insert into public.schoolpro_result_template_library(
  id,school_id,name,storage_path,sheet_name,template_config,created_by,updated_by
) values (
 '60000000-0000-4000-8000-000000000001',
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'Primary custom result',
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx',
 'Result',
 '{"name":"Primary custom result","storage_path":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx","sheet_name":"Result","start_row":10}'::jsonb,
 '30000000-0000-4000-8000-000000000001',
 '30000000-0000-4000-8000-000000000001'
);
insert into public.schoolpro_result_template_section_mappings(school_id,template_id,section_key,mapped_by) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','60000000-0000-4000-8000-000000000001','primary','30000000-0000-4000-8000-000000000001');

do $workbook_mapping$
declare
  v_id uuid;
  v_math text:='10000000-0000-4000-8000-000000000001';
  v_english text:='10000000-0000-4000-8000-000000000006';
  v_map jsonb;
begin
  raise notice 'custom-template auth diagnostic: uid=%, member=%, form_teacher=%, exact_form_master=%, active_account=%, admin_access=%',
    auth.uid(),
    (select m.id from public.schoolpro_members m where m.school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and m.user_id=auth.uid() and m.status='active' limit 1),
    (select c.form_teacher_id from public.schoolpro_classes c where c.id='50000000-0000-4000-8000-000000000001'),
    exists(select 1 from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id
      where c.school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and c.id='50000000-0000-4000-8000-000000000001'
        and c.archived_at is null and m.user_id=auth.uid() and m.status='active'),
    private.is_active_account(),
    private.has_school_access('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', ARRAY['proprietor','administrator']::public.school_member_role[]);
  v_map:=jsonb_build_object(v_math,10,v_english,11);
  v_id:=public.schoolpro_set_class_result_template(
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    '50000000-0000-4000-8000-000000000001',
    'First Term','2026/2027',
    '{"name":"Spoofed caller name","storage_path":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx","sheet_name":"Result"}'::jsonb,
    v_map
  );
  if not exists(select 1 from public.schoolpro_result_template_assignments where id=v_id and subject_row_mappings=v_map and template_name='Primary custom result') then
    raise exception 'ASSERT: assignment did not retain the trusted library name and canonical subject row mappings';
  end if;
  if not exists(select 1 from public.schoolpro_result_template_assignment_audit where class_id='50000000-0000-4000-8000-000000000001' and new_subject_row_mappings=v_map) then
    raise exception 'ASSERT: subject row mapping was not included in the assignment audit';
  end if;

  begin
    perform public.schoolpro_set_class_result_template(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      'First Term','2026/2027',
      '{"name":"Primary custom result","storage_path":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx","sheet_name":"Result","start_row":10}'::jsonb,
      jsonb_build_object(v_math,9,v_english,11)
    );
    raise exception 'ASSERT: subject row mapping overwrote the workbook heading area';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('cannot overwrite the workbook heading' in sqlerrm)=0 then raise; end if;
  end;

  perform set_config('request.jwt.claim.sub','30000000-0000-4000-8000-000000000002',false);
  perform set_config('test.exam_officer','true',false);
  begin
    perform public.schoolpro_set_class_result_template(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      'First Term','2026/2027',
      '{"name":"Primary custom result","storage_path":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx","sheet_name":"Result","start_row":10}'::jsonb,
      v_map
    );
    raise exception 'ASSERT: Exam Officer replaced the saved class result workbook mapping';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Only this class Form Master or an authorized school administrator' in sqlerrm)=0 then raise; end if;
  end;
  -- Subsequent mapping-validation cases must run as the class Form Master;
  -- the preceding negative case deliberately switched to the Exam Officer.
  perform set_config('request.jwt.claim.sub','30000000-0000-4000-8000-000000000001',false);
  perform set_config('test.exam_officer','false',false);

  begin
    perform public.schoolpro_set_class_result_template(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      'First Term','2026/2027',
      '{"name":"Primary custom result","storage_path":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx","sheet_name":"Result"}'::jsonb,
      jsonb_build_object(v_math,10,v_english,10)
    );
    raise exception 'ASSERT: duplicate subject workbook rows were accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Two subjects cannot be mapped to the same workbook row' in sqlerrm)=0 then raise; end if;
  end;

  begin
    perform public.schoolpro_set_class_result_template(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      'First Term','2026/2027',
      '{"name":"Primary custom result","storage_path":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx","sheet_name":"Result"}'::jsonb,
      jsonb_build_object(v_math,10)
    );
    raise exception 'ASSERT: incomplete subject mapping was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Every subject allocated to this class and session must be mapped exactly once' in sqlerrm)=0 then raise; end if;
  end;

  begin
    perform public.schoolpro_set_class_result_template(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      'First Term','2026/2027',
      '{"name":"Primary custom result","storage_path":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx","sheet_name":"Result"}'::jsonb,
      jsonb_build_object(v_math,10001,v_english,11)
    );
    raise exception 'ASSERT: out-of-range workbook row was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('between 1 and 10000' in sqlerrm)=0 then raise; end if;
  end;

  perform set_config('request.jwt.claim.sub','30000000-0000-4000-8000-000000000002',false);
  begin
    perform public.schoolpro_set_class_result_template(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','50000000-0000-4000-8000-000000000001',
      'First Term','2026/2027',
      '{"name":"Primary custom result","storage_path":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa/primary-result.xlsx","sheet_name":"Result"}'::jsonb,
      v_map
    );
    raise exception 'ASSERT: a non-Form-Master member assigned the class result workbook';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Only this class Form Master' in sqlerrm)=0 then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub','30000000-0000-4000-8000-000000000001',false);

  if (select count(*) from public.schoolpro_result_template_assignment_audit where class_id='50000000-0000-4000-8000-000000000001')<>1 then
    raise exception 'ASSERT: rejected subject mappings changed the assignment audit';
  end if;
end;
$workbook_mapping$;


do $output_provenance$
begin
  if not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_generated_result_outputs' and column_name='template_assignment_id')
     or not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_generated_result_outputs' and column_name='template_id')
     or not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_generated_result_outputs' and column_name='template_config_snapshot')
     or not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_generated_result_outputs' and column_name='subject_row_mappings_snapshot')
     or not exists(select 1 from information_schema.columns where table_schema='public' and table_name='schoolpro_generated_result_outputs' and column_name='formula_calculation_snapshot') then
    raise exception 'ASSERT: generated workbooks do not preserve their template assignment and mapping provenance';
  end if;
end;
$output_provenance$;

do $atomic_output$
declare
  v_definition text;
begin
  select pg_get_functiondef('public.schoolpro_record_generated_result_output(uuid,uuid,uuid,text,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb)'::regprocedure)
    into v_definition;
  if v_definition is null
     or position('for update' in lower(v_definition))=0
     or position('subject_row_mappings_snapshot' in lower(v_definition))=0
     or position('formula_calculation_snapshot' in lower(v_definition))=0
     or position('p_formula_calculation_snapshot' in lower(v_definition))=0
     or position('schoolpro_generated_result_outputs' in lower(v_definition))=0
     or not has_function_privilege('authenticated','public.schoolpro_record_generated_result_output(uuid,uuid,uuid,text,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb)','EXECUTE')
     or has_function_privilege('anon','public.schoolpro_record_generated_result_output(uuid,uuid,uuid,text,text,text,uuid,uuid,timestamptz,jsonb,jsonb,jsonb)','EXECUTE') then
    raise exception 'ASSERT: generated result finalization is not protected by the atomic authenticated RPC';
  end if;
end;
$atomic_output$;

select 'PASS: canonical school subject uniqueness, non-destructive legacy duplicate handling, Form Master class-scoped selection, preserved teacher allocations, idempotent audit, and audited subject-ID workbook row mappings.' as result;
