\set ON_ERROR_STOP on
create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;
create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;
create function private.schoolpro_module_allowed(uuid,text) returns boolean language sql stable as $$select true$$;
create function private.schoolpro_can_write_result(uuid,uuid,uuid,text) returns boolean language sql stable as $$select true$$;

create type public.schoolpro_result_status as enum ('draft','approved','published');
create table public.schoolpro_classes(id uuid primary key,school_id uuid not null,level text);
create table public.schoolpro_students(
 id uuid primary key,school_id uuid not null,admission_number text not null,status text not null,class_id uuid
);
create table public.schoolpro_enrollment_history(
 school_id uuid not null,student_id uuid not null,class_id uuid not null,session text not null,created_at timestamptz default now()
);
create table public.schoolpro_subjects(id uuid primary key,school_id uuid not null,code text not null);
create table public.schoolpro_subject_assignments(
 school_id uuid not null,class_id uuid not null,subject_id uuid not null,session text not null,ended_at timestamptz
);
create table public.schoolpro_assessment_schemes(
 id uuid primary key,school_id uuid not null,components jsonb not null,school_level text not null
);
create table public.schoolpro_results(
 id uuid primary key default gen_random_uuid(),school_id uuid not null,student_id uuid not null,subject_id uuid not null,
 term text not null,session text not null,assessment_scheme_id uuid,assessment_scores jsonb,
 total_score numeric not null default 0,status public.schoolpro_result_status not null default 'draft',
 locked boolean not null default false,updated_at timestamptz default now(),
 unique(student_id,subject_id,term,session)
);

\ir ../supabase/migrations/20261108101000_schoolpro_harden_result_import_rpc.sql

insert into public.schoolpro_classes(id,school_id,level) values
 ('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','junior_secondary'),
 ('30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','jss'),
 ('30000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','senior_secondary'),
 ('30000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000001','sss');
insert into public.schoolpro_students(id,school_id,admission_number,status,class_id) values
 ('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','JSS-CANON','active','30000000-0000-0000-0000-000000000001'),
 ('40000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','JSS-SHORT','active','30000000-0000-0000-0000-000000000002'),
 ('40000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','SSS-CANON','active','30000000-0000-0000-0000-000000000003'),
 ('40000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000001','SSS-SHORT','active','30000000-0000-0000-0000-000000000004');
insert into public.schoolpro_subjects(id,school_id,code) values
 ('70000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','MATH');
insert into public.schoolpro_assessment_schemes(id,school_id,school_level,components) values
 ('10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','junior_secondary','[{"key":"exam","label":"Examination","maxScore":100}]'),
 ('10000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','senior_secondary','[{"key":"exam","label":"Examination","maxScore":100}]');
select set_config('request.jwt.claim.sub','50000000-0000-0000-0000-000000000001',false);

-- Canonical and short level aliases must both be accepted by the authoritative RPC.
select public.import_schoolpro_results(
 '20000000-0000-0000-0000-000000000001','First Term','2026/2027',
 '[{"admission_number":"JSS-CANON","subject_code":"MATH","assessment_scheme_id":"10000000-0000-0000-0000-000000000001","assessment_scores":{"exam":80}},
   {"admission_number":"JSS-SHORT","subject_code":"MATH","assessment_scheme_id":"10000000-0000-0000-0000-000000000001","assessment_scores":{"exam":75}},
   {"admission_number":"SSS-CANON","subject_code":"MATH","assessment_scheme_id":"10000000-0000-0000-0000-000000000002","assessment_scores":{"exam":90}},
   {"admission_number":"SSS-SHORT","subject_code":"MATH","assessment_scheme_id":"10000000-0000-0000-0000-000000000002","assessment_scores":{"exam":85}}]'::jsonb
);
do $assert$
begin
 if (select count(*) from public.schoolpro_results)<>4 then
  raise exception 'Canonical and short Junior/Senior Secondary aliases did not all import';
 end if;
end
$assert$;

-- A genuinely incompatible scheme must still fail and must not persist a row.
do $reject$
begin
 begin
  perform public.import_schoolpro_results(
   '20000000-0000-0000-0000-000000000001','First Term','2026/2027',
   '[{"admission_number":"SSS-CANON","subject_code":"MATH","assessment_scheme_id":"10000000-0000-0000-0000-000000000001","assessment_scores":{"exam":50}}]'::jsonb
  );
  raise exception 'Expected incompatible assessment scheme level to be rejected';
 exception when others then
  if sqlerrm not like 'Assessment scheme level % does not match the selected class level %' then raise;end if;
 end;
 if (select count(*) from public.schoolpro_results)<>4 then
  raise exception 'Rejected incompatible import left a result row behind';
 end if;
end
$reject$;
select 'PASS: result import RPC accepts both secondary level aliases and rejects incompatible levels atomically.' as result;
