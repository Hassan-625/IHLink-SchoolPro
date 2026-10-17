-- Public admissions RPC hardening. This is a draft migration; do not apply to production
-- until the Stage A PR and its CI evidence are reviewed.
create or replace function public.submit_schoolpro_application(
  p_school uuid,
  p_first text,
  p_last text,
  p_gender text,
  p_dob date,
  p_guardian text,
  p_phone text,
  p_email text,
  p_class text,
  p_previous text default null
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  aid uuid;
  anum text;
  tok uuid;
  v_first text := nullif(btrim(p_first), '');
  v_last text := nullif(btrim(p_last), '');
  v_gender text := nullif(lower(btrim(p_gender)), '');
  v_guardian text := nullif(btrim(p_guardian), '');
  v_phone text := nullif(btrim(p_phone), '');
  v_phone_digits text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  v_email text := nullif(lower(btrim(p_email)), '');
  v_class text := nullif(btrim(p_class), '');
  v_previous text := nullif(btrim(p_previous), '');
  v_hour_count integer;
  v_day_count integer;
  v_phone_lock bigint;
  v_email_lock bigint;
begin
  if p_school is null or not exists (
    select 1 from public.schoolpro_site_settings s
    where s.school_id = p_school
      and s.is_published = true
      and s.admissions_open = true
  ) then
    raise exception 'Admissions are not currently open';
  end if;

  if v_first is null or v_last is null or v_guardian is null
     or v_phone is null or v_class is null then
    raise exception 'Required application details are missing';
  end if;

  if length(v_first) > 80 or length(v_last) > 80
     or length(v_guardian) > 120 or length(v_class) > 80
     or length(coalesce(v_previous, '')) > 160
     or length(coalesce(v_gender, '')) > 32
     or length(v_phone) > 32
     or length(coalesce(v_email, '')) > 254 then
    raise exception 'One or more application fields exceed the allowed length';
  end if;

  if v_first !~ '[[:alnum:]]' or v_last !~ '[[:alnum:]]'
     or v_guardian !~ '[[:alnum:]]' or v_class !~ '[[:alnum:]]' then
    raise exception 'Application names and class must contain letters or numbers';
  end if;

  if length(v_phone_digits) < 7 or length(v_phone_digits) > 15
     or v_phone !~ '^[0-9+() .-]+$' then
    raise exception 'Enter a valid guardian phone number';
  end if;

  if v_email is not null and (
    v_email !~ '^[A-Za-z0-9.!#$%&''*+/=?^_`{|}~-]+@[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$'
    or length(v_email) > 254
  ) then
    raise exception 'Enter a valid guardian email address';
  end if;

  if v_gender is not null and v_gender not in ('male', 'female', 'other', 'prefer not to say') then
    raise exception 'Select a valid gender option';
  end if;

  if p_dob is not null and (p_dob > current_date or p_dob < date '1900-01-01') then
    raise exception 'Enter a valid date of birth';
  end if;

  -- A transaction-scoped lock serializes requests for the same school/contact.
  -- It uses normalized form values, never a caller-controlled network header.
  v_phone_lock := pg_catalog.hashtextextended(p_school::text || '|phone|' || v_phone_digits, 0);
  v_email_lock := pg_catalog.hashtextextended(p_school::text || '|email|' || coalesce(v_email, ''), 0);
  -- Acquire both normalized contact locks in a stable order to avoid deadlocks.
  if v_phone_lock < v_email_lock then
    perform pg_catalog.pg_advisory_xact_lock(v_phone_lock);
    perform pg_catalog.pg_advisory_xact_lock(v_email_lock);
  else
    perform pg_catalog.pg_advisory_xact_lock(v_email_lock);
    perform pg_catalog.pg_advisory_xact_lock(v_phone_lock);
  end if;

  select
    count(*) filter (where a.submitted_at >= now() - interval '1 hour')::integer,
    count(*) filter (where a.submitted_at >= now() - interval '24 hours')::integer
  into v_hour_count, v_day_count
  from public.schoolpro_admissions a
  where a.school_id = p_school
    and (
      regexp_replace(coalesce(a.guardian_contact, ''), '[^0-9]', '', 'g') = v_phone_digits
      or (v_email is not null and lower(btrim(coalesce(a.guardian_email, ''))) = v_email)
    )
    and a.submitted_at >= now() - interval '24 hours';

  if coalesce(v_hour_count, 0) >= 3 then
    raise exception 'Too many applications for this contact in a short period; try again later';
  end if;
  if coalesce(v_day_count, 0) >= 5 then
    raise exception 'Application limit reached for this contact; try again later';
  end if;

  anum := 'APP-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.schoolpro_admissions(
    school_id, applicant_name, first_name, last_name, gender, date_of_birth,
    guardian_name, guardian_contact, guardian_email, class_applied, previous_school,
    application_number, status, submitted_at
  )
  values (
    p_school, v_first || ' ' || v_last, v_first, v_last, v_gender, p_dob,
    v_guardian, v_phone, v_email, v_class, v_previous,
    anum, 'pending', now()
  )
  returning id, public_token into aid, tok;

  return jsonb_build_object(
    'application_id', aid,
    'application_number', anum,
    'public_token', tok
  );
end
$function$;
