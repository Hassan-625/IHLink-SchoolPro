-- Disposable PostgreSQL integration test for the actual public admissions RPC migration.
create table public.schoolpro_site_settings (
  school_id uuid primary key,
  is_published boolean not null,
  admissions_open boolean not null
);
create table public.schoolpro_admissions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  applicant_name text not null,
  first_name text not null,
  last_name text not null,
  gender text,
  date_of_birth date,
  guardian_name text not null,
  guardian_contact text not null,
  guardian_email text,
  class_applied text not null,
  previous_school text,
  application_number text not null,
  status text not null,
  submitted_at timestamptz not null,
  public_token uuid not null default gen_random_uuid()
);

insert into public.schoolpro_site_settings(school_id,is_published,admissions_open)
values
 ('b1000000-0000-0000-0000-000000000001',true,true),
 ('b1000000-0000-0000-0000-000000000002',true,true);

\ir ../supabase/migrations/20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql

do $admission_abuse_test$
declare
  result jsonb;
  n integer;
begin
  -- Three successful submissions for a contact in one hour.
  result := public.submit_schoolpro_application(
    'b1000000-0000-0000-0000-000000000001','Amina','Bello','female','2017-03-01',
    'Hauwa Bello','0803-123-4567','guardian@example.com','Primary 3',null
  );
  if not (result ? 'application_id' and result ? 'application_number' and result ? 'public_token') then
    raise exception 'Successful application response contract changed: %', result;
  end if;

  perform public.submit_schoolpro_application(
    'b1000000-0000-0000-0000-000000000001','Maryam','Bello','female','2016-02-01',
    'Hauwa Bello','+234 803 123 4567','guardian@example.com','Primary 3',null
  );
  perform public.submit_schoolpro_application(
    'b1000000-0000-0000-0000-000000000001','Fatima','Bello','female','2015-01-01',
    'Hauwa Bello','08031234567','guardian@example.com','Primary 4',null
  );

  begin
    perform public.submit_schoolpro_application(
      'b1000000-0000-0000-0000-000000000001','Zainab','Bello','female','2014-01-01',
      'Hauwa Bello','0803-123-4567','guardian@example.com','Primary 4',null
    );
    raise exception 'Expected hourly contact throttle was not enforced';
  exception when others then
    if sqlerrm = 'Expected hourly contact throttle was not enforced' then raise; end if;
    if sqlerrm not like 'Too many applications for this contact%' then raise; end if;
  end;

  -- The same contact is allowed to apply to a different school.
  perform public.submit_schoolpro_application(
    'b1000000-0000-0000-0000-000000000002','Zainab','Bello','female','2014-01-01',
    'Hauwa Bello','08031234567','guardian@example.com','Primary 4',null
  );

  select count(*) into n from public.schoolpro_admissions
  where school_id='b1000000-0000-0000-0000-000000000001';
  if n <> 3 then raise exception 'Hourly limit expected 3 rows for School A, got %', n; end if;

  begin
    perform public.submit_schoolpro_application(
      'b1000000-0000-0000-0000-000000000001',repeat('A',81),'Bello','female','2017-03-01',
      'Hauwa Bello','0803-555-1212','another@example.com','Primary 3',null
    );
    raise exception 'Expected oversized name to be rejected';
  exception when others then
    if sqlerrm = 'Expected oversized name to be rejected' then raise; end if;
    if sqlerrm not like 'One or more application fields exceed%' then raise; end if;
  end;

  begin
    perform public.submit_schoolpro_application(
      'b1000000-0000-0000-0000-000000000001','Amina','Bello','female','2017-03-01',
      'Hauwa Bello','0803-555-1212','not-an-email','Primary 3',null
    );
    raise exception 'Expected malformed email to be rejected';
  exception when others then
    if sqlerrm = 'Expected malformed email to be rejected' then raise; end if;
    if sqlerrm <> 'Enter a valid guardian email address' then raise; end if;
  end;

  begin
    perform public.submit_schoolpro_application(
      'b1000000-0000-0000-0000-000000000001','Amina','Bello','female','2099-03-01',
      'Hauwa Bello','0803-555-1212','another@example.com','Primary 3',null
    );
    raise exception 'Expected future date of birth to be rejected';
  exception when others then
    if sqlerrm = 'Expected future date of birth to be rejected' then raise; end if;
    if sqlerrm <> 'Enter a valid date of birth' then raise; end if;
  end;
end
$admission_abuse_test$;

\echo 'PASS: admission RPC enforces contact rate limits, school scoping, bounded fields, and email/date validation.'
