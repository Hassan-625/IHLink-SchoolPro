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

-- Synthetic fixtures are confined to this disposable PostgreSQL service.
INSERT INTO public.schoolpro_members (id, school_id, user_id, role) VALUES
  ('c0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','teacher'),
  ('c0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000002','class_teacher'),
  ('c0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000003','teacher');

INSERT INTO public.schoolpro_houses (id, school_id, name, color) VALUES
  ('d0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','Red House','#DC2626'),
  ('d0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000002','Blue House','#2563EB');

INSERT INTO public.schoolpro_house_master_assignments (id, school_id, house_id, member_id) VALUES
  ('e0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001','c0000000-0000-0000-0000-000000000001'),
  ('e0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000002','c0000000-0000-0000-0000-000000000002');

INSERT INTO public.schoolpro_classes (id, school_id, name, arm) VALUES
  ('g0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','Primary 1','A');

INSERT INTO public.schoolpro_students
  (id, school_id, admission_number, first_name, middle_name, last_name, class_name, class_id, status)
VALUES
  ('f0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','ADM-001','Amina','Zainab','Yusuf','Primary 1','g0000000-0000-0000-0000-000000000001','active'),
  ('f0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001','ADM-002','Inactive','Test','Student','Primary 1','g0000000-0000-0000-0000-000000000001','inactive'),
  ('f0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000002','ADM-003','Foreign','School','Student','Primary 2',null,'active'),
  ('f0000000-0000-0000-0000-000000000004','a0000000-0000-0000-0000-000000000001','ADM-004','Former','House','Student','Primary 1','g0000000-0000-0000-0000-000000000001','active');

INSERT INTO public.schoolpro_student_house_history
  (id, school_id, student_id, house_id, assigned_at, effective_to)
VALUES
  ('h0000000-0000-0000-0000-000000000001','a0000000-0000-0000-0000-000000000001','f0000000-0000-0000-0000-000000000001','d0000000-0000-0000-0000-000000000001',now(),null),
  ('h0000000-0000-0000-0000-000000000002','a0000000-0000-0000-0000-000000000001','f0000000-0000-0000-0000-000000000002','d0000000-0000-0000-0000-000000000001',now(),null),
  ('h0000000-0000-0000-0000-000000000003','a0000000-0000-0000-0000-000000000001','f0000000-0000-0000-0000-000000000003','d0000000-0000-0000-0000-000000000001',now(),null),
  ('h0000000-0000-0000-0000-000000000004','a0000000-0000-0000-0000-000000000001','f0000000-0000-0000-0000-000000000004','d0000000-0000-0000-0000-000000000001',now() - interval '2 days',now() - interval '1 day');

BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', 'b0000000-0000-0000-0000-000000000001', true);

DO $runtime$
DECLARE
  visible_active integer;
  roster_row record;
BEGIN
  SELECT count(*) FILTER (WHERE student_id IS NOT NULL)
    INTO visible_active
  FROM public.schoolpro_house_master_roster('a0000000-0000-0000-0000-000000000001');

  IF visible_active <> 1 THEN
    RAISE EXCEPTION 'House Master should see exactly one current active same-school student; got %', visible_active;
  END IF;

  SELECT * INTO roster_row
  FROM public.schoolpro_house_master_roster('a0000000-0000-0000-0000-000000000001')
  WHERE student_id = 'f0000000-0000-0000-0000-000000000001';

  IF roster_row.house_name <> 'Red House'
     OR roster_row.admission_number <> 'ADM-001'
     OR roster_row.first_name <> 'Amina'
     OR roster_row.middle_name <> 'Zainab'
     OR roster_row.class_name <> 'Primary 1'
     OR roster_row.class_arm <> 'A' THEN
    RAISE EXCEPTION 'House Master roster did not return the expected minimal student/class details';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.schoolpro_house_master_roster('a0000000-0000-0000-0000-000000000001')
    WHERE student_id IN (
      'f0000000-0000-0000-0000-000000000002',
      'f0000000-0000-0000-0000-000000000003',
      'f0000000-0000-0000-0000-000000000004'
    )
  ) THEN
    RAISE EXCEPTION 'Roster leaked an inactive, cross-school or historical student assignment';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', 'b0000000-0000-0000-0000-000000000002', true);
  IF EXISTS (SELECT 1 FROM public.schoolpro_house_master_roster('a0000000-0000-0000-0000-000000000001')) THEN
    RAISE EXCEPTION 'House Master from another school read the requested school roster';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', 'b0000000-0000-0000-0000-000000000003', true);
  IF EXISTS (SELECT 1 FROM public.schoolpro_house_master_roster('a0000000-0000-0000-0000-000000000001')) THEN
    RAISE EXCEPTION 'Teaching staff without an active House Master appointment received a roster';
  END IF;
END
$runtime$;

ROLLBACK;

