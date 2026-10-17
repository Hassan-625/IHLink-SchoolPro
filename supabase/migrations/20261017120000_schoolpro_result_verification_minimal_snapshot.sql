-- Public result-verification codes are bearer credentials. Use 192 bits of randomness
-- and expose only the summary displayed by the public verification page.
-- Do not return subject IDs or per-assessment score breakdowns to anonymous callers.
create or replace function public.issue_schoolpro_result_verification(
  p_student uuid,
  p_term text,
  p_session text
)
returns text
language plpgsql
security definer
set search_path to ''
as $function$
declare
  st record;
  snap jsonb;
  result_count integer;
  code text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select s.id, s.school_id
    into st
  from public.schoolpro_students s
  where s.id = p_student
    and s.status = 'active';

  if st.id is null then
    raise exception 'Student not found';
  end if;

  if not private.schoolpro_module_allowed(st.school_id, 'results') then
    raise exception 'Module permission denied: results';
  end if;

  if not (
    private.is_admin(array['super_admin'::public.user_role])
    or private.has_school_access(
      st.school_id,
      array[
        'proprietor'::public.school_member_role,
        'administrator'::public.school_member_role,
        'exam_officer'::public.school_member_role,
        'head_teacher'::public.school_member_role,
        'vice_principal'::public.school_member_role
      ]
    )
  ) then
    raise exception 'Not authorized';
  end if;

  -- Store only the summary consumed by SchoolProResultChecker. The source
  -- rows must be both published and locked before a verification credential exists.
  select
    count(*)::integer,
    jsonb_build_object(
      'total', coalesce(sum(r.total_score), 0),
      'average', coalesce(round(avg(r.total_score)::numeric, 2), 0)
    )
  into result_count, snap
  from public.schoolpro_results r
  where r.student_id = p_student
    and r.term = trim(p_term)
    and r.session = trim(p_session)
    and r.status = 'published'
    and r.locked = true;

  if result_count = 0 then
    raise exception 'No locked published result is available';
  end if;

  -- 24 random bytes = 192 bits. The previous issuer truncated a UUID to
  -- 16 hex characters (64 bits), despite the column default already using
  -- 24 random bytes. Keep the public verifier's case-insensitive contract.
  code := upper(encode(extensions.gen_random_bytes(24), 'hex'));

  insert into public.schoolpro_result_verifications(
    verification_code,
    school_id,
    student_id,
    term,
    session,
    snapshot,
    status,
    issued_by
  )
  values (
    code,
    st.school_id,
    p_student,
    trim(p_term),
    trim(p_session),
    snap,
    'valid',
    auth.uid()
  );

  return code;
end
$function$;


-- Sanitize the public reader as well as the issuer. Existing valid codes may contain
-- legacy subject/assessment detail snapshots; never return those raw JSON documents.
-- Derive only aggregate totals for legacy snapshots and preserve aggregate snapshots
-- issued by the new issuer. Revoked records never expose a snapshot.
create or replace function public.schoolpro_verify_result_code(p_code text)
returns table(
  status text,
  school_name text,
  student_name text,
  admission_number text,
  class_name text,
  term text,
  session text,
  issued_at timestamptz,
  snapshot jsonb
)
language sql
stable
security definer
set search_path to ''
as $function$
  select
    case when v.revoked_at is null and v.status = 'valid' then 'valid' else 'revoked' end,
    s.name,
    st.first_name || ' ' || st.last_name,
    st.admission_number,
    st.class_name,
    v.term,
    v.session,
    v.issued_at,
    case
      when v.revoked_at is not null or v.status <> 'valid' then null::jsonb
      when v.snapshot ? 'total' and v.snapshot ? 'average' then
        jsonb_build_object('total', v.snapshot->'total', 'average', v.snapshot->'average')
      when jsonb_typeof(v.snapshot->'results') = 'array' then (
        select jsonb_build_object(
          'total', coalesce(sum(nullif(item->>'total_score','')::numeric), 0),
          'average', coalesce(round(avg(nullif(item->>'total_score','')::numeric), 2), 0)
        )
        from jsonb_array_elements(v.snapshot->'results') as item
      )
      else null::jsonb
    end
  from public.schoolpro_result_verifications v
  join public.schoolpro_schools s on s.id = v.school_id
  join public.schoolpro_students st on st.id = v.student_id
  where v.verification_code = upper(trim(p_code))
  limit 1
$function$;
