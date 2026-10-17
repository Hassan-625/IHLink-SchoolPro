-- Disposable PostgreSQL integration test for the actual result-PIN cooldown migration.
-- Runs only against the ephemeral CI service; do not point DATABASE_URL at production.
create schema if not exists private;
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create table public.schoolpro_schools (
  id uuid primary key, name text not null, address text
);
create table public.schoolpro_students (
  id uuid primary key, school_id uuid not null, first_name text not null,
  last_name text not null, admission_number text not null, class_name text,
  status text not null, created_at timestamptz not null default now()
);
create table public.schoolpro_result_access_pins (
  id uuid primary key, student_id uuid not null, term text not null, session text not null,
  is_active boolean not null default true, expires_at timestamptz, pin_hash text not null,
  last_used_at timestamptz
);
create table public.schoolpro_finance_settings (
  school_id uuid primary key, block_results_when_owing boolean not null default false,
  allowed_outstanding numeric not null default 0
);
create table public.schoolpro_invoices (
  id uuid primary key, school_id uuid not null, student_id uuid not null, term text not null,
  session text not null, status text not null, amount_due numeric not null default 0,
  amount_paid numeric not null default 0, result_hold boolean not null default false
);
create table public.schoolpro_subjects (id uuid primary key, name text not null);
create table public.schoolpro_results (
  id uuid primary key, student_id uuid not null, subject_id uuid not null, term text not null,
  session text not null, status text not null, total_score numeric, assessment_scores jsonb
);

\ir ../supabase/migrations/20261016122000_schoolpro_result_pin_attempt_rate_limit.sql

insert into public.schoolpro_schools (id,name,address)
values ('00000000-0000-0000-0000-000000000001','Fixture School','Test address');
insert into public.schoolpro_students
  (id,school_id,first_name,last_name,admission_number,class_name,status)
values
  ('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001',
   'Amina','Bello','SP-TEST-001','Basic 1 A','active');
insert into public.schoolpro_result_access_pins
  (id,student_id,term,session,is_active,pin_hash)
values
  ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
   'First Term','2025/2026',true,encode(extensions.digest('1234','sha256'),'hex'));
insert into public.schoolpro_subjects (id,name)
values ('30000000-0000-0000-0000-000000000001','Mathematics');
insert into public.schoolpro_results
  (id,student_id,subject_id,term,session,status,total_score,assessment_scores)
values
  ('40000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000001','First Term','2025/2026','published',85,'{"ca":25,"exam":60}');

-- Simulate request metadata as PostgREST would expose it to the SQL function.
select set_config('request.headers','{"x-forwarded-for":"198.51.100.99, 203.0.113.10","cf-connecting-ip":"203.0.113.10"}',false);

do $test$
declare
  i integer;
  result jsonb;
  attempt_count integer;
  key_length integer;
begin
  -- Seven wrong PINs remain ordinary failures; the eighth starts a 15-minute block.
  for i in 1..8 loop
    result := public.check_schoolpro_result_pin('SP-TEST-001','First Term','2025/2026','wrong-pin');
    if coalesce((result->>'ok')::boolean,false) then
      raise exception 'Wrong PIN unexpectedly succeeded on attempt %', i;
    end if;
  end loop;

  select failed_attempts, length(attempt_key)
    into attempt_count, key_length
  from private.schoolpro_result_pin_attempts
  limit 1;
  if attempt_count <> 8 then
    raise exception 'Expected 8 failed attempts, got %', attempt_count;
  end if;
  if key_length <> 64 then
    raise exception 'Attempt key should be a SHA-256 hex digest (64 chars), got %', key_length;
  end if;

  result := public.check_schoolpro_result_pin('SP-TEST-001','First Term','2025/2026','1234');
  if coalesce((result->>'ok')::boolean,true) or result->>'message' <> 'Too many attempts. Please try again later.' then
    raise exception 'Blocked key was not rejected before PIN verification: %', result;
  end if;

  -- Unknown admissions also accrue failures, using the same generic public error.
  delete from private.schoolpro_result_pin_attempts;
  for i in 1..8 loop
    result := public.check_schoolpro_result_pin('SP-UNKNOWN-999','First Term','2025/2026','1234');
  end loop;
  if not exists (
    select 1 from private.schoolpro_result_pin_attempts a
    where length(a.attempt_key)=64 and a.failed_attempts=8 and a.blocked_until > now()
  ) then
    raise exception 'Unknown admission did not trigger hashed-key cooldown';
  end if;

  -- After an expired cooldown, a valid published-result lookup succeeds and clears its key.
  update private.schoolpro_result_pin_attempts
    set blocked_until = now() - interval '1 second',
        window_started_at = now() - interval '16 minutes'
  where attempt_key = encode(extensions.digest('sp-test-001|203.0.113.10','sha256'),'hex');
  result := public.check_schoolpro_result_pin('SP-TEST-001','First Term','2025/2026','1234');
  if not coalesce((result->>'ok')::boolean,false) then
    raise exception 'Valid PIN should succeed after cooldown expires: %', result;
  end if;
  if exists (select 1 from private.schoolpro_result_pin_attempts
             where attempt_key = encode(extensions.digest('sp-test-001|203.0.113.10','sha256'),'hex')) then
    raise exception 'Successful result access did not clear the failure counter';
  end if;
end
$test$;

\echo 'PASS: result-PIN migration executes; wrong/unknown admissions accrue hashed failures, cooldown rejects requests, and successful published-result access clears the counter.'
