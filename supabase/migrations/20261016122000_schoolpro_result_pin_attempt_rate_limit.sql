-- Database-level rate limiting for the public result-PIN checker.
-- Store only a digest of the normalized admission number plus request network identifier.
-- This avoids locking every user out of a student's result based only on the admission number.
create table if not exists private.schoolpro_result_pin_attempts (
  attempt_key text primary key,
  window_started_at timestamptz not null default now(),
  failed_attempts integer not null default 0 check (failed_attempts >= 0),
  blocked_until timestamptz,
  updated_at timestamptz not null default now()
);

revoke all on table private.schoolpro_result_pin_attempts from public, anon, authenticated;

create or replace function private.record_schoolpro_result_pin_failure(p_attempt_key text)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
begin
  insert into private.schoolpro_result_pin_attempts (
    attempt_key, window_started_at, failed_attempts, blocked_until, updated_at
  ) values (p_attempt_key, now(), 1, null, now())
  on conflict (attempt_key) do update
  set
    window_started_at = case
      when private.schoolpro_result_pin_attempts.window_started_at <= now() - interval '15 minutes'
        or (private.schoolpro_result_pin_attempts.blocked_until is not null
            and private.schoolpro_result_pin_attempts.blocked_until <= now())
      then now()
      else private.schoolpro_result_pin_attempts.window_started_at
    end,
    failed_attempts = case
      when private.schoolpro_result_pin_attempts.window_started_at <= now() - interval '15 minutes'
        or (private.schoolpro_result_pin_attempts.blocked_until is not null
            and private.schoolpro_result_pin_attempts.blocked_until <= now())
      then 1
      else private.schoolpro_result_pin_attempts.failed_attempts + 1
    end,
    blocked_until = case
      when private.schoolpro_result_pin_attempts.window_started_at <= now() - interval '15 minutes'
        or (private.schoolpro_result_pin_attempts.blocked_until is not null
            and private.schoolpro_result_pin_attempts.blocked_until <= now())
      then null
      when private.schoolpro_result_pin_attempts.failed_attempts + 1 >= 8
      then now() + interval '15 minutes'
      else private.schoolpro_result_pin_attempts.blocked_until
    end,
    updated_at = now();
end
$function$;

revoke all on function private.record_schoolpro_result_pin_failure(text) from public, anon, authenticated;

create or replace function public.check_schoolpro_result_pin(
  p_admission text,
  p_term text,
  p_session text,
  p_pin text
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  s record;
  pinrow record;
  blocked boolean;
  held boolean;
  outstanding numeric;
  payload jsonb;
  v_attempt_key text;
  v_blocked_until timestamptz;
  v_headers jsonb;
  v_client_ip text;
begin
  v_headers := nullif(current_setting('request.headers', true), '')::jsonb;
  -- On Supabase-hosted requests, prefer the Cloudflare edge's client-IP header.
  -- X-Forwarded-For is caller-influenced and may contain a spoofed leftmost value;
  -- do not use it as the security rate-limit identity.
  v_client_ip := coalesce(
    nullif(trim(v_headers ->> 'cf-connecting-ip'), ''),
    'unknown'
  );
  v_attempt_key := encode(
    extensions.digest(
      lower(trim(coalesce(p_admission, ''))) || '|' || coalesce(nullif(trim(v_client_ip), ''), 'unknown'),
      'sha256'
    ),
    'hex'
  );

  -- Serialize checks sharing the same hashed admission/network key. Without this
  -- lock, concurrent wrong-PIN requests can all pass the pre-check before failures accrue.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_attempt_key, 0));

  select a.blocked_until
    into v_blocked_until
  from private.schoolpro_result_pin_attempts a
  where a.attempt_key = v_attempt_key;

  if v_blocked_until is not null and v_blocked_until > now() then
    return jsonb_build_object('ok', false, 'message', 'Too many attempts. Please try again later.');
  end if;

  select st.id, st.school_id, st.first_name, st.last_name, st.admission_number,
         st.class_name, sc.name school_name, sc.address
    into s
  from public.schoolpro_students st
  join public.schoolpro_schools sc on sc.id = st.school_id
  where upper(st.admission_number) = upper(trim(p_admission))
    and st.status = 'active'
  order by st.created_at desc
  limit 1;

  if s.id is null then
    perform private.record_schoolpro_result_pin_failure(v_attempt_key);
    return jsonb_build_object('ok', false, 'message', 'Result details or access PIN are invalid.');
  end if;

  select *
    into pinrow
  from public.schoolpro_result_access_pins p
  where p.student_id = s.id
    and p.term = p_term
    and p.session = p_session
    and p.is_active
    and (p.expires_at is null or p.expires_at > now())
    and p.pin_hash = encode(extensions.digest(upper(trim(p_pin)), 'sha256'), 'hex')
  limit 1;

  if pinrow.id is null then
    perform private.record_schoolpro_result_pin_failure(v_attempt_key);
    return jsonb_build_object('ok', false, 'message', 'Result details or access PIN are invalid.');
  end if;

  select
    coalesce(fs.block_results_when_owing, false)
      and coalesce(sum(greatest(i.amount_due - i.amount_paid, 0)), 0) > coalesce(fs.allowed_outstanding, 0),
    coalesce(bool_or(i.result_hold), false),
    coalesce(sum(greatest(i.amount_due - i.amount_paid, 0)), 0)
  into blocked, held, outstanding
  from public.schoolpro_finance_settings fs
  left join public.schoolpro_invoices i
    on i.school_id = s.school_id
   and i.student_id = s.id
   and i.term = p_term
   and i.session = p_session
   and i.status <> 'waived'
  where fs.school_id = s.school_id
  group by fs.block_results_when_owing, fs.allowed_outstanding;

  if coalesce(held, false) then
    return jsonb_build_object('ok', false, 'message', 'Result access is currently on hold.');
  end if;

  if coalesce(blocked, false) then
    return jsonb_build_object(
      'ok', false,
      'message', 'Result access is paused by the school because of an outstanding fee balance.',
      'outstanding', coalesce(outstanding, 0)
    );
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'subject', sub.name,
        'total_score', r.total_score,
        'assessment_scores', r.assessment_scores,
        'status', r.status
      ) order by sub.name
    ),
    '[]'::jsonb
  )
  into payload
  from public.schoolpro_results r
  join public.schoolpro_subjects sub on sub.id = r.subject_id
  where r.student_id = s.id
    and r.term = p_term
    and r.session = p_session
    and r.status = 'published';

  if jsonb_array_length(payload) = 0 then
    return jsonb_build_object('ok', false, 'message', 'No published result is available for this term and session.');
  end if;

  delete from private.schoolpro_result_pin_attempts
  where attempt_key = v_attempt_key;

  update public.schoolpro_result_access_pins
  set last_used_at = now()
  where id = pinrow.id;

  return jsonb_build_object(
    'ok', true,
    'school', jsonb_build_object('name', s.school_name, 'address', s.address),
    'student', jsonb_build_object(
      'name', s.first_name || ' ' || s.last_name,
      'admission_number', s.admission_number,
      'class_name', s.class_name
    ),
    'term', p_term,
    'session', p_session,
    'results', payload
  );
end
$function$;

comment on table private.schoolpro_result_pin_attempts is
  'Stores one-way attempt keys and failure windows for rate limiting public result-PIN checks; no raw admission number or PIN is stored.';
