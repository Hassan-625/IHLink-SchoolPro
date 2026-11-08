\set ON_ERROR_STOP on
create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;
create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;
create type public.schoolpro_result_status as enum ('draft','approved','published');
create table public.schoolpro_assessment_schemes(
 id uuid primary key,school_id uuid not null,components jsonb not null
);
create table public.schoolpro_results(
 id uuid primary key,school_id uuid not null,student_id uuid not null,subject_id uuid not null,
 term text not null,session text not null,assessment_scheme_id uuid,assessment_scores jsonb,
 total_score numeric not null default 0,status public.schoolpro_result_status not null default 'draft',
 locked boolean not null default false,approved_by uuid,approved_at timestamptz,published_at timestamptz
);
create table public.schoolpro_result_approvals(
 id bigint generated always as identity primary key,school_id uuid not null,result_id uuid unique not null,
 status text not null,reviewed_by uuid,reviewed_at timestamptz,notes text
);
create table public.schoolpro_classes(id uuid primary key,school_id uuid not null);
create table public.schoolpro_students(id uuid primary key,school_id uuid not null,status text not null,class_id uuid);
create table public.schoolpro_enrollment_history(student_id uuid not null,school_id uuid not null,class_id uuid not null,session text not null);
create table public.schoolpro_members(school_id uuid,user_id uuid,role text);
create table public.audit_logs(actor_id uuid,action text,product text,target_type text,target_id text,metadata jsonb);
create function private.schoolpro_module_allowed(uuid,text) returns boolean language sql stable as $$select true$$;
create function public.schoolpro_member_can_manage(uuid) returns boolean language sql stable as $$select true$$;

\ir ../supabase/migrations/20261108110000_schoolpro_require_complete_assessments_for_approval_and_publication.sql
\ir ../supabase/migrations/20261108113000_schoolpro_atomic_bulk_result_approval.sql
\ir ../supabase/migrations/20261108114000_schoolpro_class_publication_current_roster_scope.sql
\ir ../supabase/migrations/20261108115000_schoolpro_class_scoped_atomic_approval.sql

insert into public.schoolpro_assessment_schemes(id,school_id,components) values
 ('10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',
  '[{"key":"ca","label":"Continuous Assessment","maxScore":30},{"key":"exam","label":"Examination","maxScore":70}]'::jsonb);
insert into public.schoolpro_classes(id,school_id) values
 ('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001');
insert into public.schoolpro_students(id,school_id,status) values
 ('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','active'),
 ('40000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','active'),
 ('40000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','active');
insert into public.schoolpro_enrollment_history(student_id,school_id,class_id,session) values
 ('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','2026/2027'),
 ('40000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','2026/2027'),
 ('40000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','2026/2027');
select set_config('request.jwt.claim.sub','50000000-0000-0000-0000-000000000001',false);

-- A malformed scheme with a missing maximum must also fail closed (SQL NULL must not pass a PL/pgSQL IF).
insert into public.schoolpro_assessment_schemes(id,school_id,components) values
 ('10000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001',
  '[{"key":"ca","label":"Continuous Assessment"}]'::jsonb);
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,total_score)
values('60000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',
 '70000000-0000-0000-0000-000000000002','First Term','2026/2027','10000000-0000-0000-0000-000000000002','{"ca":20}'::jsonb,20);
do $test$
begin
 begin
  perform public.review_schoolpro_result('60000000-0000-0000-0000-000000000004','approved',null);
  raise exception 'Expected malformed scheme approval to fail';
 exception when others then
  if sqlerrm not like 'Incomplete assessment:%' then raise;end if;
 end;
 if (select status from public.schoolpro_results where id='60000000-0000-0000-0000-000000000004')<>'draft' then
  raise exception 'Malformed assessment unexpectedly crossed the approval boundary';
 end if;
end
$test$;

-- Approval must reject a Draft with a missing component.
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,total_score)
values('60000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',
 '70000000-0000-0000-0000-000000000001','First Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":20}'::jsonb,20);
do $test$
begin
 begin
  perform public.review_schoolpro_result('60000000-0000-0000-0000-000000000001','approved',null);
  raise exception 'Expected incomplete approval to fail';
 exception when others then
  if sqlerrm not like 'Incomplete assessment:%' then raise;end if;
 end;
end
$test$;
-- Bulk approval must be all-or-nothing when one selected Draft is incomplete.
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,total_score)
values
 ('60000000-0000-0000-0000-000000000005','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',
  '70000000-0000-0000-0000-000000000005','First Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10,"exam":50}'::jsonb,60),
 ('60000000-0000-0000-0000-000000000006','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',
  '70000000-0000-0000-0000-000000000006','First Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10}'::jsonb,10);
do $test$
begin
 begin
  perform public.review_schoolpro_results(array[
   '60000000-0000-0000-0000-000000000005'::uuid,'60000000-0000-0000-0000-000000000006'::uuid
  ],'batch test');
  raise exception 'Expected atomic bulk approval to reject incomplete batch';
 exception when others then
  if sqlerrm not like 'At least one selected assessment is incomplete%' then raise;end if;
 end;
 if exists(select 1 from public.schoolpro_results where id in(
  '60000000-0000-0000-0000-000000000005','60000000-0000-0000-0000-000000000006') and status<>'draft') then
  raise exception 'Bulk approval partially changed a rejected batch';
 end if;
end
$test$;
update public.schoolpro_results set assessment_scores='{"ca":10,"exam":50}'::jsonb,total_score=60
where id='60000000-0000-0000-0000-000000000006';
select public.review_schoolpro_results(array[
 '60000000-0000-0000-0000-000000000005'::uuid,'60000000-0000-0000-0000-000000000006'::uuid
],'batch test');
do $assert$
begin
 if (select count(*) from public.schoolpro_results where id in(
  '60000000-0000-0000-0000-000000000005','60000000-0000-0000-0000-000000000006') and status='approved')<>2 then
  raise exception 'Complete bulk approval did not approve the entire batch';
 end if;
end
$assert$;

update public.schoolpro_results set assessment_scores='{"ca":20,"exam":60}'::jsonb,total_score=80
where id='60000000-0000-0000-0000-000000000001';
select public.review_schoolpro_result('60000000-0000-0000-0000-000000000001','approved','checked');
select public.publish_schoolpro_class_results('20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','First Term','2026/2027');

-- Students without historical rows are included only in their actual current class.
insert into public.schoolpro_classes(id,school_id) values
 ('30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001');
insert into public.schoolpro_students(id,school_id,status,class_id) values
 ('40000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000001','active','30000000-0000-0000-0000-000000000001'),
 ('40000000-0000-0000-0000-000000000005','20000000-0000-0000-0000-000000000001','active','30000000-0000-0000-0000-000000000002');
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,total_score,status)
values
 ('60000000-0000-0000-0000-000000000007','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000004','70000000-0000-0000-0000-000000000007','First Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10,"exam":50}'::jsonb,60,'approved'),
 ('60000000-0000-0000-0000-000000000008','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000005','70000000-0000-0000-0000-000000000008','First Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10,"exam":50}'::jsonb,60,'approved');
select public.publish_schoolpro_class_results('20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','First Term','2026/2027');
do $assert$
begin
 if not exists(select 1 from public.schoolpro_results where id='60000000-0000-0000-0000-000000000007' and status='published' and locked) then
  raise exception 'Active student with no history was not published for their current class';
 end if;
 if not exists(select 1 from public.schoolpro_results where id='60000000-0000-0000-0000-000000000008' and status='approved' and not locked) then
  raise exception 'Class publication incorrectly included an active student from another current class';
 end if;
end
$assert$;

-- Class approval must not include another class's results for the same school/period.
insert into public.schoolpro_classes(id,school_id) values
 ('30000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001');
insert into public.schoolpro_students(id,school_id,status,class_id) values
 ('40000000-0000-0000-0000-000000000006','20000000-0000-0000-0000-000000000001','active','30000000-0000-0000-0000-000000000001'),
 ('40000000-0000-0000-0000-000000000007','20000000-0000-0000-0000-000000000001','active','30000000-0000-0000-0000-000000000003');
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,total_score,status)
values
 ('60000000-0000-0000-0000-000000000009','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000006','70000000-0000-0000-0000-000000000009','Second Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10,"exam":50}'::jsonb,60,'draft'),
 ('60000000-0000-0000-0000-000000000010','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000007','70000000-0000-0000-0000-000000000010','Second Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10,"exam":50}'::jsonb,60,'draft');
select public.review_schoolpro_class_results('20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','Second Term','2026/2027',null);
do $assert$
begin
 if not exists(select 1 from public.schoolpro_results where id='60000000-0000-0000-0000-000000000009' and status='approved') then
  raise exception 'Class-scoped approval did not approve its own current-roster student';
 end if;
 if not exists(select 1 from public.schoolpro_results where id='60000000-0000-0000-0000-000000000010' and status='draft') then
  raise exception 'Class-scoped approval incorrectly approved another class student';
 end if;
end
$assert$;
-- Selected-student approval must be constrained to the chosen class roster.
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,total_score,status)
values
 ('6000000000-0000-0000-0000-000000000011','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000006','70000000-0000-0000-0000-000000000011','Third Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10,"exam":50}'::jsonb,60,'draft'),
 ('6000000000-0000-0000-0000-000000000012','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000007','70000000-0000-0000-0000-000000000012','Third Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10,"exam":50}'::jsonb,60,'draft');
select public.review_schoolpro_class_results('20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','Third Term','2026/2027',null,array['40000000-0000-0000-0000-000000000006'::uuid]);
do $assert$
begin
 if not exists(select 1 from public.schoolpro_results where id='6000000000-0000-0000-0000-000000000011' and status='approved') then
  raise exception 'Selected class-roster student was not approved';
 end if;
 if not exists(select 1 from public.schoolpro_results where id='6000000000-0000-0000-0000-000000000012' and status='draft') then
  raise exception 'Selected-student approval approved another class roster';
 end if;
end
$assert$;
do $test$
begin
 begin
  perform public.review_schoolpro_class_results('20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','Third Term','2026/2027',null,array['40000000-0000-0000-0000-000000000007'::uuid]);
  raise exception 'Expected selected student outside class to fail';
 exception when others then
  if sqlerrm not like 'Every selected student must belong to this class roster%' then raise;end if;
 end;
end
$test$;

-- A directly-created incomplete Approved row must block class publication.
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,total_score,status)
values('60000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002',
 '70000000-0000-0000-0000-000000000001','First Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":10}'::jsonb,10,'approved');
do $test$
begin
 begin
  perform public.publish_schoolpro_class_results('20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','First Term','2026/2027');
  raise exception 'Expected class publication to fail';
 exception when others then
  if sqlerrm not like 'Class contains incomplete approved assessments%' then raise;end if;
 end;
end
$test$;
do $test$
begin
 begin
  perform public.publish_schoolpro_selected_results('20000000-0000-0000-0000-000000000001','First Term','2026/2027',
   array['40000000-0000-0000-0000-000000000002'::uuid],false);
  raise exception 'Expected selected publication to fail';
 exception when others then
  if sqlerrm not like 'Selected students contain incomplete approved assessments%' then raise;end if;
 end;
end
$test$;
do $test$
begin
 begin
  perform public.publish_schoolpro_results('20000000-0000-0000-0000-000000000001','First Term','2026/2027');
  raise exception 'Expected period publication to fail';
 exception when others then
  if sqlerrm not like 'Academic period contains incomplete approved assessments%' then raise;end if;
 end;
end
$test$;

-- Once the missing component is supplied, selected publication succeeds and locks the result.
update public.schoolpro_results set assessment_scores='{"ca":10,"exam":50}'::jsonb,total_score=60
where id='60000000-0000-0000-0000-000000000002';
select public.publish_schoolpro_selected_results('20000000-0000-0000-0000-000000000001','First Term','2026/2027',
 array['40000000-0000-0000-0000-000000000002'::uuid],false);
do $assert$
begin
 if not exists(select 1 from public.schoolpro_results where id='60000000-0000-0000-0000-000000000002' and status='published' and locked) then
  raise exception 'Complete selected result was not published and locked';
 end if;
end
$assert$;
-- The whole-period publisher is exercised on a third complete Approved row.
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,total_score,status)
values('60000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000003',
 '70000000-0000-0000-0000-000000000001','First Term','2026/2027','10000000-0000-0000-0000-000000000001','{"ca":15,"exam":55}'::jsonb,70,'approved');
select public.publish_schoolpro_results('20000000-0000-0000-0000-000000000001','First Term','2026/2027');
do $assert$
begin
 if not exists(select 1 from public.schoolpro_results where id='60000000-0000-0000-0000-000000000003' and status='published' and locked) then
  raise exception 'Complete period result was not published and locked';
 end if;
end
$assert$;
select 'PASS: incomplete results are blocked at approval and every publication boundary; complete results publish and lock.' as result;

-- Exercise the grade-scale trigger on the same disposable PostgreSQL instance.
create table public.schoolpro_grade_scale(
 id uuid primary key,school_id uuid not null,label text not null,min_score numeric not null,max_score numeric not null,
 is_active boolean not null default true,
 constraint schoolpro_grade_range check(min_score>=0 and max_score<=100 and min_score<=max_score)
);
create function public.schoolpro_printable_result(uuid,text,text) returns setof public.schoolpro_results language sql as $$select * from public.schoolpro_results where false$$;
create function public.schoolpro_can_view_result_output(uuid,text,text) returns boolean language sql as $$select true$$;
\ir ../supabase/migrations/20261108111000_schoolpro_consistent_subject_statistics_and_grade_bands.sql

insert into public.schoolpro_grade_scale(id,school_id,label,min_score,max_score,is_active) values
 ('81000000-0000-0000-0000-000000000001','82000000-0000-0000-0000-000000000001','F',0,39.99,true),
 ('81000000-0000-0000-0000-000000000002','82000000-0000-0000-0000-000000000001','E',40,49.99,true),
 ('81000000-0000-0000-0000-000000000003','82000000-0000-0000-0000-000000000001','A',50,100,true);
do $test$
begin
 begin
  insert into public.schoolpro_grade_scale(id,school_id,label,min_score,max_score,is_active)
  values('81000000-0000-0000-0000-000000000004','82000000-0000-0000-0000-000000000001','Overlap',49,60,true);
  raise exception 'Expected overlapping active grade range to fail';
 exception when exclusion_violation then null;
 end;
 begin
  update public.schoolpro_grade_scale set min_score=39 where id='81000000-0000-0000-0000-000000000002';
  raise exception 'Expected overlapping grade update to fail';
 exception when exclusion_violation then null;
 end;
end
$test$;
-- Inactive historical bands may overlap without participating in grade resolution.
insert into public.schoolpro_grade_scale(id,school_id,label,min_score,max_score,is_active)
values('81000000-0000-0000-0000-000000000005','82000000-0000-0000-0000-000000000001','Legacy',30,60,false);
select 'PASS: active grade ranges reject overlap on insert and update; inactive historical bands remain allowed.' as result;
