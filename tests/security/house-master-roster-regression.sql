-- Security-contract regression for the House Master roster RPC.
-- Run against a disposable database after applying the migration.
\set ON_ERROR_STOP on

DO $test$
DECLARE
  helper_oid oid;
  public_oid oid;
  helper_def text;
  helper_result text;
  public_result text;
BEGIN
  SELECT p.oid, pg_get_functiondef(p.oid), pg_get_function_result(p.oid)
    INTO helper_oid, helper_def, helper_result
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'private'
    AND p.proname = 'schoolpro_house_master_roster'
    AND pg_get_function_identity_arguments(p.oid) = 'p_school uuid';

  IF helper_oid IS NULL THEN
    RAISE EXCEPTION 'private House Master roster helper is missing';
  END IF;

  IF NOT (SELECT prosecdef FROM pg_proc WHERE oid = helper_oid) THEN
    RAISE EXCEPTION 'private roster helper must be SECURITY DEFINER to perform the narrow RLS bypass';
  END IF;

  IF NOT (SELECT coalesce(proconfig::text, '') LIKE '%search_path=""%' FROM pg_proc WHERE oid = helper_oid) THEN
    RAISE EXCEPTION 'private roster helper must pin an empty search_path';
  END IF;

  IF has_function_privilege('anon', helper_oid, 'EXECUTE')
     OR exists (select 1 from aclexplode(coalesce((select proacl from pg_proc where oid = helper_oid), acldefault('f', (select proowner from pg_proc where oid = helper_oid)))) a where a.grantee = 0 and a.privilege_type = 'EXECUTE')
     OR NOT has_function_privilege('authenticated', helper_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'private roster helper execute grants are not least-privilege';
  END IF;

  IF helper_result NOT LIKE 'TABLE(house_id uuid, house_name text, house_color text, student_id uuid, admission_number text, first_name text, middle_name text, last_name text, class_name text, class_arm text, assigned_at timestamp with time zone)' THEN
    RAISE EXCEPTION 'private roster helper returns an unexpected column contract: %', helper_result;
  END IF;

  IF lower(helper_def) NOT LIKE '%auth.uid()%'
     OR lower(helper_def) NOT LIKE '%private.is_active_account()%'
     OR lower(helper_def) NOT LIKE '%a.ended_at is null%'
     OR lower(helper_def) NOT LIKE '%m.user_id = auth.uid()%'
     OR lower(helper_def) NOT LIKE '%effective_to is null%'
     OR lower(helper_def) NOT LIKE '%st.status = ''active''%'
     OR lower(helper_def) NOT LIKE '%teacher%'
     OR lower(helper_def) NOT LIKE '%class_teacher%'
     OR lower(helper_def) NOT LIKE '%a.school_id = p_school%' THEN
    RAISE EXCEPTION 'private roster helper is missing a required caller, membership, appointment, school or current-student restriction';
  END IF;

  SELECT p.oid, pg_get_function_result(p.oid)
    INTO public_oid, public_result
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'schoolpro_house_master_roster'
    AND pg_get_function_identity_arguments(p.oid) = 'p_school uuid';

  IF public_oid IS NULL THEN
    RAISE EXCEPTION 'public House Master roster RPC is missing';
  END IF;

  IF (SELECT prosecdef FROM pg_proc WHERE oid = public_oid) THEN
    RAISE EXCEPTION 'public RPC must remain SECURITY INVOKER';
  END IF;

  IF has_function_privilege('anon', public_oid, 'EXECUTE')
     OR exists (select 1 from aclexplode(coalesce((select proacl from pg_proc where oid = public_oid), acldefault('f', (select proowner from pg_proc where oid = public_oid)))) a where a.grantee = 0 and a.privilege_type = 'EXECUTE')
     OR NOT has_function_privilege('authenticated', public_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'public RPC execute grants are not least-privilege';
  END IF;

  IF public_result <> helper_result THEN
    RAISE EXCEPTION 'public RPC return contract differs from private helper';
  END IF;
END
$test$;

SELECT 'House Master roster security contract: PASS' AS result;
