-- Disposable PostgreSQL integration fixture for public result-verification issuance.
-- This creates only the minimal dependencies needed to execute the actual draft migration.
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create schema if not exists auth;
create schema if not exists private;

create type public.user_role as enum ('super_admin');
create type public.school_member_role as enum (
  'proprietor','administrator','exam_officer','head_teacher','vice_principal'
);

create or replace function auth.uid()
returns uuid language sql stable
as $uid$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $uid$;

create or replace function private.schoolpro_module_allowed(uuid, text)
returns boolean language sql stable as $fn$ select true $fn$;
create or replace function private.is_admin(public.user_role[])
returns boolean language sql stable as $fn$ select false $fn$;
create or replace function private.has_school_access(uuid, public.school_member_role[])
returns boolean language sql stable as $fn$ select true $fn$;

create table public.schoolpro_schools (
  id uuid primary key,
  name text not null
);
create table public.schoolpro_students (
  id uuid primary key,
  school_id uuid not null,
  status text not null,
  first_name text not null default 'Test',
  last_name text not null default 'Student',
  admission_number text not null default 'SP-TEST-001',
  class_name text not null default 'Basic 5 A'
);
create table public.schoolpro_results (
  id uuid primary key,
  student_id uuid not null references public.schoolpro_students(id),
  term text not null,
  session text not null,
  status text not null,
  locked boolean not null,
  total_score numeric not null
);
create table public.schoolpro_result_verifications (
  id uuid primary key default gen_random_uuid(),
  verification_code text not null unique,
  school_id uuid not null,
  student_id uuid not null,
  term text not null,
  session text not null,
  snapshot jsonb not null default '{}'::jsonb,
  status text not null default 'valid',
  issued_by uuid,
  issued_at timestamptz not null default now(),
  revoked_at timestamptz
);

insert into public.schoolpro_schools(id,name)
values ('b1000000-0000-0000-0000-000000000001','Synthetic School');
insert into public.schoolpro_students(id,school_id,status,first_name,last_name,admission_number,class_name)
values ('a1000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000001','active','Test','Student','SP-TEST-001','Basic 5 A');

insert into public.schoolpro_results(id,student_id,term,session,status,locked,total_score)
values
 ('c1000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000001','First Term','2025/2026','published',true,80),
 ('c1000000-0000-0000-0000-000000000002','a1000000-0000-0000-0000-000000000001','First Term','2025/2026','published',true,70),
 ('c1000000-0000-0000-0000-000000000003','a1000000-0000-0000-0000-000000000001','First Term','2025/2026','draft',false,99);

\ir ../supabase/migrations/20261017120000_schoolpro_result_verification_minimal_snapshot.sql

select set_config('request.jwt.claim.sub','d1000000-0000-0000-0000-000000000001',false);

do $verification_test$
declare
  code text;
  saved jsonb;
begin
  code := public.issue_schoolpro_result_verification(
    'a1000000-0000-0000-0000-000000000001','First Term','2025/2026'
  );
  if length(code) <> 48 or code !~ '^[0-9A-F]{48}$' then
    raise exception 'Verification code must be 48 uppercase hex characters (192 bits); got length %', length(code);
  end if;

  select snapshot into saved
  from public.schoolpro_result_verifications
  where verification_code = code;

  if saved <> jsonb_build_object('total',150,'average',75) then
    raise exception 'Unexpected minimal summary snapshot: %', saved;
  end if;
  if saved ? 'results' or saved ? 'subject_id' or saved ? 'assessment_scores' then
    raise exception 'Snapshot contains detailed assessment data: %', saved;
  end if;

  -- The public verifier must also sanitize new aggregate snapshots.
  select result.snapshot into saved
  from public.schoolpro_verify_result_code(code) as result;
  if saved <> jsonb_build_object('total',150,'average',75) then
    raise exception 'Public verifier returned unexpected aggregate snapshot: %', saved;
  end if;
  if saved ? 'results' or saved ? 'subject_id' or saved ? 'assessment_scores' then
    raise exception 'Public verifier leaked detailed result data: %', saved;
  end if;

  -- Legacy valid codes can still hold detailed snapshots; the public reader must reduce them.
  insert into public.schoolpro_result_verifications(
    verification_code, school_id, student_id, term, session, snapshot, status, issued_by
  ) values (
    'LEGACY-DETAIL-CODE',
    'b1000000-0000-0000-0000-000000000001',
    'a1000000-0000-0000-0000-000000000001',
    'First Term', '2024/2025',
    '{"results":[{"subject_id":"subject-a","total_score":80,"assessment_scores":{"ca":20,"exam":60}},{"subject_id":"subject-b","total_score":70,"assessment_scores":{"ca":10,"exam":60}}]}'::jsonb,
    'valid',
    'd1000000-0000-0000-0000-000000000001'
  );
  select result.snapshot into saved
  from public.schoolpro_verify_result_code('LEGACY-DETAIL-CODE') as result;
  if saved <> jsonb_build_object('total',150,'average',75) then
    raise exception 'Legacy public snapshot was not sanitized: %', saved;
  end if;
  if saved ? 'results' or saved ? 'subject_id' or saved ? 'assessment_scores' then
    raise exception 'Legacy public verifier leaked detailed result data: %', saved;
  end if;

  update public.schoolpro_result_verifications
  set revoked_at = now()
  where verification_code = 'LEGACY-DETAIL-CODE';
  select result.snapshot into saved
  from public.schoolpro_verify_result_code('LEGACY-DETAIL-CODE') as result;
  if saved is not null then
    raise exception 'Revoked verification code returned a snapshot: %', saved;
  end if;

  begin
    perform public.issue_schoolpro_result_verification(
      'a1000000-0000-0000-0000-000000000001','Second Term','2025/2026'
    );
    raise exception 'Issuer unexpectedly accepted a period with no locked published results';
  exception when others then
    if sqlerrm = 'Issuer unexpectedly accepted a period with no locked published results' then
      raise;
    end if;
    if sqlerrm <> 'No locked published result is available' then
      raise;
    end if;
  end;
end
$verification_test$;

\echo 'PASS: result verification uses 192-bit codes, stores aggregate snapshots, sanitizes legacy snapshots, and hides revoked snapshots.'
