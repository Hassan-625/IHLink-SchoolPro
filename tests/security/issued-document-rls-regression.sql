-- Disposable PostgreSQL regression test. Uses synthetic data only.
-- It first proves the old permissive policies expose a deliberately mismatched row,
-- then applies the draft migration and proves student, guardian and staff reads are scoped.
\set ON_ERROR_STOP on

CREATE ROLE authenticated NOLOGIN;
CREATE ROLE anon NOLOGIN;
CREATE SCHEMA auth;
CREATE SCHEMA private;

CREATE TYPE public.user_role AS ENUM ('super_admin');
CREATE TYPE public.school_member_role AS ENUM ('owner','proprietor','admin','registrar','head_teacher','vice_principal');

CREATE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE
AS $$ SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

CREATE TABLE public.schoolpro_students (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  user_id uuid,
  status text NOT NULL DEFAULT 'active'
);
CREATE TABLE public.schoolpro_guardian_links (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  student_id uuid NOT NULL,
  guardian_user_id uuid NOT NULL,
  status text NOT NULL
);
CREATE TABLE public.schoolpro_members (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role public.school_member_role NOT NULL
);
CREATE TABLE public.schoolpro_document_issues (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  student_id uuid,
  status text NOT NULL
);

CREATE FUNCTION public.schoolpro_member_can_manage(p_school uuid) RETURNS boolean
LANGUAGE sql STABLE
AS $$ SELECT EXISTS (
  SELECT 1 FROM public.schoolpro_members m
  WHERE m.school_id = p_school AND m.user_id = auth.uid()
    AND m.role::text IN ('owner','proprietor','admin')
) $$;
CREATE FUNCTION private.is_admin(p_roles public.user_role[]) RETURNS boolean
LANGUAGE sql STABLE
AS $$ SELECT false $$;

ALTER TABLE public.schoolpro_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schoolpro_guardian_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schoolpro_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schoolpro_document_issues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "test students visible to own identity, guardian, or school member"
ON public.schoolpro_students FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.schoolpro_members m
             WHERE m.school_id = schoolpro_students.school_id AND m.user_id = auth.uid())
  OR EXISTS (SELECT 1 FROM public.schoolpro_guardian_links g
             WHERE g.student_id = schoolpro_students.id
               AND g.school_id = schoolpro_students.school_id
               AND g.guardian_user_id = auth.uid() AND g.status = 'active')
);
CREATE POLICY "test guardian links visible to guardian or school member"
ON public.schoolpro_guardian_links FOR SELECT TO authenticated
USING (
  guardian_user_id = auth.uid()
  OR EXISTS (SELECT 1 FROM public.schoolpro_members m
             WHERE m.school_id = schoolpro_guardian_links.school_id AND m.user_id = auth.uid())
);
CREATE POLICY "test own memberships"
ON public.schoolpro_members FOR SELECT TO authenticated USING (user_id = auth.uid());

-- The original policies, including the faulty student tautology and missing guardian/staff
-- relationship-school checks. These are deliberately installed only in this disposable DB.
CREATE POLICY "students read own issued documents"
ON public.schoolpro_document_issues FOR SELECT TO authenticated
USING (
  status IN ('issued','revoked')
  AND EXISTS (SELECT 1 FROM public.schoolpro_students st
              WHERE st.id = schoolpro_document_issues.student_id
                AND st.school_id = st.school_id
                AND st.user_id = auth.uid())
);
CREATE POLICY "guardians read ward issued documents"
ON public.schoolpro_document_issues FOR SELECT TO authenticated
USING (
  status IN ('issued','revoked')
  AND EXISTS (SELECT 1 FROM public.schoolpro_guardian_links g
              WHERE g.student_id = schoolpro_document_issues.student_id
                AND g.guardian_user_id = auth.uid()
                AND g.status = 'active')
);
CREATE POLICY "authorized staff read document issues"
ON public.schoolpro_document_issues FOR SELECT TO authenticated
USING (
  schoolpro_member_can_manage(school_id)
  OR private.is_admin(ARRAY['super_admin'::user_role])
  OR EXISTS (SELECT 1 FROM public.schoolpro_members m
             WHERE m.school_id = schoolpro_document_issues.school_id
               AND m.user_id = auth.uid()
               AND m.role::text IN ('registrar','head_teacher','vice_principal'))
);

GRANT USAGE ON SCHEMA public, auth, private TO authenticated, anon;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.schoolpro_member_can_manage(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_admin(public.user_role[]) TO authenticated;
GRANT SELECT ON public.schoolpro_students, public.schoolpro_guardian_links,
  public.schoolpro_members, public.schoolpro_document_issues TO authenticated, anon;

INSERT INTO public.schoolpro_students(id,school_id,user_id) VALUES
('00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000301'),
('00000000-0000-0000-0000-000000000202','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000302');
INSERT INTO public.schoolpro_guardian_links(id,school_id,student_id,guardian_user_id,status) VALUES
('00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000401','active'),
('00000000-0000-0000-0000-000000000602','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000202','00000000-0000-0000-0000-000000000402','active');
INSERT INTO public.schoolpro_members(id,school_id,user_id,role) VALUES
('00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000501','registrar'),
('00000000-0000-0000-0000-000000000702','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000502','registrar');
INSERT INTO public.schoolpro_document_issues(id,school_id,student_id,status) VALUES
('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','issued'),
('00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000202','issued'),
('00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000202','issued'),
('00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','draft'),
('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000201','revoked');

CREATE FUNCTION public.assert_visible_issue_ids(p_expected uuid[]) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE actual uuid[];
BEGIN
  SELECT COALESCE(array_agg(id ORDER BY id), ARRAY[]::uuid[])
  INTO actual FROM public.schoolpro_document_issues;
  IF actual IS DISTINCT FROM p_expected THEN
    RAISE EXCEPTION 'visible issue ids %, expected %', actual, p_expected;
  END IF;
END
$$;
GRANT EXECUTE ON FUNCTION public.assert_visible_issue_ids(uuid[]) TO authenticated, anon;

-- Before the fix: Student B and Guardian B can see the deliberately mismatched issue 103.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000302',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000102'::uuid,
 '00000000-0000-0000-0000-000000000103'::uuid
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000402',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000102'::uuid,
 '00000000-0000-0000-0000-000000000103'::uuid
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000101'::uuid,
 '00000000-0000-0000-0000-000000000103'::uuid,
 '00000000-0000-0000-0000-000000000104'::uuid,
 '00000000-0000-0000-0000-000000000105'::uuid
]);
ROLLBACK;

-- Apply the exact draft migration under test, not a copied assertion-only variant.
\i supabase/migrations/20261017150000_fix_student_issued_document_school_scope.sql

-- After the fix: no student, guardian, or staff role sees the mismatched row 103.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000301',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000101'::uuid,
 '00000000-0000-0000-0000-000000000105'::uuid
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000302',true);
SELECT public.assert_visible_issue_ids(ARRAY['00000000-0000-0000-0000-000000000102'::uuid]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000401',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000101'::uuid,
 '00000000-0000-0000-0000-000000000105'::uuid
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000402',true);
SELECT public.assert_visible_issue_ids(ARRAY['00000000-0000-0000-0000-000000000102'::uuid]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000101'::uuid,
 '00000000-0000-0000-0000-000000000104'::uuid,
 '00000000-0000-0000-0000-000000000105'::uuid
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000502',true);
SELECT public.assert_visible_issue_ids(ARRAY['00000000-0000-0000-0000-000000000102'::uuid]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub','',true);
SELECT public.assert_visible_issue_ids(ARRAY[]::uuid[]);
ROLLBACK;

SELECT 'issued-document RLS regression passed' AS result;
