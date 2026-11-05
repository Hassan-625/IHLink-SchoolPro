-- Disposable PostgreSQL regression test. Uses synthetic data only.
-- It first proves the old permissive policies expose a deliberately mismatched row,
-- then applies the draft migration and proves student, guardian and staff reads are scoped.
\set ON_ERROR_STOP on

CREATE ROLE authenticated NOLOGIN;
CREATE ROLE anon NOLOGIN;
CREATE SCHEMA auth;
CREATE SCHEMA private;
CREATE SCHEMA storage;

CREATE TYPE public.user_role AS ENUM ('super_admin');
CREATE TYPE public.school_member_role AS ENUM (
  'owner','proprietor','administrator','admin','registrar',
  'head_teacher','vice_principal','teacher','class_teacher','exam_officer'
);

CREATE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE
AS $$ SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

CREATE TABLE public.schoolpro_schools (
  id uuid PRIMARY KEY,
  owner_id uuid
);

CREATE TABLE public.schoolpro_students (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  user_id uuid,
  class_id uuid,
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
CREATE TABLE public.schoolpro_classes (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  form_teacher_id uuid
);
CREATE TABLE public.schoolpro_permission_denials (
  school_id uuid NOT NULL,
  user_id uuid NOT NULL,
  module text NOT NULL,
  PRIMARY KEY (school_id, user_id, module)
);
CREATE TABLE public.schoolpro_document_issues (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  student_id uuid,
  status text NOT NULL,
  output_storage_path text
);
CREATE TABLE storage.objects (
  id uuid PRIMARY KEY,
  bucket_id text NOT NULL,
  name text NOT NULL,
  owner_id text
);

CREATE FUNCTION public.schoolpro_member_can_manage(p_school uuid) RETURNS boolean
LANGUAGE sql STABLE
AS $$ SELECT EXISTS (
  SELECT 1 FROM public.schoolpro_members m
  WHERE m.school_id = p_school AND m.user_id = auth.uid()
    AND m.role::text IN ('owner','proprietor','administrator','admin')
) $$;
CREATE FUNCTION private.is_admin(p_roles public.user_role[]) RETURNS boolean
LANGUAGE sql STABLE
AS $body$ SELECT false $body$;
CREATE FUNCTION private.schoolpro_module_allowed(p_school uuid, p_module text) RETURNS boolean
LANGUAGE sql STABLE
AS $body$
  SELECT
    EXISTS (
      SELECT 1
      FROM public.schoolpro_members m
      WHERE m.school_id = p_school
        AND m.user_id = auth.uid()
        AND m.role::text IN ('proprietor', 'administrator')
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.schoolpro_permission_denials d
      WHERE d.school_id = p_school
        AND d.user_id = auth.uid()
        AND d.module = p_module
    )
$body$;
CREATE FUNCTION storage.foldername(p_name text) RETURNS text[]
LANGUAGE sql IMMUTABLE
AS $body$ SELECT CASE WHEN array_length(parts,1)>1 THEN parts[1:array_length(parts,1)-1] ELSE ARRAY[]::text[] END FROM (SELECT string_to_array(p_name,'/') AS parts) s $body$;

ALTER TABLE public.schoolpro_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schoolpro_guardian_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schoolpro_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schoolpro_document_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

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

-- Reproduce both original permissive production policies. These are important:
-- PostgreSQL ORs permissive policies, including SELECT access from FOR ALL.
CREATE POLICY "school members read document issues"
ON public.schoolpro_document_issues FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.schoolpro_schools s
    WHERE s.id = school_id AND s.owner_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.schoolpro_members m
    WHERE m.school_id = school_id AND m.user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.schoolpro_students st
    WHERE st.id = student_id AND st.user_id = auth.uid()
  )
);

CREATE POLICY "school managers manage document issues"
ON public.schoolpro_document_issues FOR ALL TO authenticated
USING (
  public.schoolpro_member_can_manage(school_id)
  OR EXISTS (
    SELECT 1 FROM public.schoolpro_members m
    WHERE m.school_id = school_id
      AND m.user_id = auth.uid()
      AND m.role::text IN ('registrar','head_teacher','vice_principal')
  )
)
WITH CHECK (
  public.schoolpro_member_can_manage(school_id)
  OR EXISTS (
    SELECT 1 FROM public.schoolpro_members m
    WHERE m.school_id = school_id
      AND m.user_id = auth.uid()
      AND m.role::text IN ('registrar','head_teacher','vice_principal')
  )
);

CREATE POLICY "schoolpro document outputs read"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'schoolpro-document-outputs'
  AND EXISTS (
    SELECT 1
    FROM public.schoolpro_document_issues d
    LEFT JOIN public.schoolpro_students st ON st.id = d.student_id AND st.school_id = d.school_id
    WHERE d.output_storage_path = objects.name
      AND (
        public.schoolpro_member_can_manage(d.school_id)
        OR private.is_admin(ARRAY['super_admin'::user_role])
        OR EXISTS (SELECT 1 FROM public.schoolpro_members m
                   WHERE m.school_id=d.school_id AND m.user_id=auth.uid()
                     AND m.role::text IN ('registrar','head_teacher','vice_principal'))
        OR (d.status IN ('issued','revoked') AND st.user_id=auth.uid())
        OR (d.status IN ('issued','revoked') AND EXISTS (
             SELECT 1 FROM public.schoolpro_guardian_links g
             WHERE g.student_id=d.student_id AND g.guardian_user_id=auth.uid() AND g.status='active'))
      )
  )
);
CREATE POLICY "schoolpro document outputs insert"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id='schoolpro-document-outputs'
  AND private.schoolpro_module_allowed((storage.foldername(name))[1]::uuid,'documents')
  AND (public.schoolpro_member_can_manage((storage.foldername(name))[1]::uuid)
       OR EXISTS (SELECT 1 FROM public.schoolpro_members m
                  WHERE m.school_id=(storage.foldername(objects.name))[1]::uuid
                    AND m.user_id=auth.uid()
                    AND m.role::text IN ('registrar','head_teacher','vice_principal')))
);
CREATE POLICY "schoolpro document outputs update"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id='schoolpro-document-outputs' AND public.schoolpro_member_can_manage((storage.foldername(name))[1]::uuid))
WITH CHECK (bucket_id='schoolpro-document-outputs'
            AND private.schoolpro_module_allowed((storage.foldername(name))[1]::uuid,'documents')
            AND public.schoolpro_member_can_manage((storage.foldername(name))[1]::uuid));
CREATE POLICY "schoolpro document outputs delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id='schoolpro-document-outputs' AND public.schoolpro_member_can_manage((storage.foldername(name))[1]::uuid));


GRANT USAGE ON SCHEMA public, auth, private, storage TO authenticated, anon;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.schoolpro_member_can_manage(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION private.is_admin(public.user_role[]) TO authenticated;
GRANT EXECUTE ON FUNCTION private.schoolpro_module_allowed(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION storage.foldername(text) TO authenticated;
GRANT SELECT ON public.schoolpro_students, public.schoolpro_guardian_links,
  public.schoolpro_members, public.schoolpro_classes, public.schoolpro_schools,
  public.schoolpro_permission_denials, public.schoolpro_document_issues
  TO authenticated, anon;
GRANT INSERT, UPDATE, DELETE
  ON public.schoolpro_document_issues TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO authenticated, anon;

INSERT INTO public.schoolpro_schools(id,owner_id) VALUES
('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000503'),
('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000504');
INSERT INTO public.schoolpro_members(id,school_id,user_id,role) VALUES
('00000000-0000-0000-0000-000000000705','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000505','exam_officer'),
('00000000-0000-0000-0000-000000000706','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000506','teacher'),
('00000000-0000-0000-0000-000000000707','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000507','teacher'),
('00000000-0000-0000-0000-000000000708','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000508','administrator'),
('00000000-0000-0000-0000-000000000709','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000509','administrator');

INSERT INTO public.schoolpro_classes(id,school_id,form_teacher_id) VALUES
('00000000-0000-0000-0000-000000000901',
 '00000000-0000-0000-0000-000000000001',
 '00000000-0000-0000-0000-000000000706'),
('00000000-0000-0000-0000-000000000902',
 '00000000-0000-0000-0000-000000000002',
 NULL);

INSERT INTO public.schoolpro_students(id,school_id,user_id,class_id) VALUES
('00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000901'),
('00000000-0000-0000-0000-000000000202','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000302','00000000-0000-0000-0000-000000000902');

INSERT INTO public.schoolpro_permission_denials(school_id,user_id,module) VALUES
('00000000-0000-0000-0000-000000000001',
 '00000000-0000-0000-0000-000000000509','documents');
INSERT INTO public.schoolpro_guardian_links(id,school_id,student_id,guardian_user_id,status) VALUES
('00000000-0000-0000-0000-000000000601','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000401','active'),
('00000000-0000-0000-0000-000000000602','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000202','00000000-0000-0000-0000-000000000402','active');
INSERT INTO public.schoolpro_members(id,school_id,user_id,role) VALUES
('00000000-0000-0000-0000-000000000701','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000501','registrar'),
('00000000-0000-0000-0000-000000000702','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000502','registrar'),
('00000000-0000-0000-0000-000000000703','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000503','proprietor'),
('00000000-0000-0000-0000-000000000704','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000504','proprietor');
INSERT INTO public.schoolpro_document_issues(id,school_id,student_id,status,output_storage_path) VALUES
('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','issued','00000000-0000-0000-0000-000000000001/issued/101.pdf'),
('00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000202','issued','00000000-0000-0000-0000-000000000002/issued/102.pdf'),
('00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000202','issued','00000000-0000-0000-0000-000000000001/issued/103.pdf'),
('00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','draft','00000000-0000-0000-0000-000000000001/draft/104.pdf'),
('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000201','revoked','00000000-0000-0000-0000-000000000001/issued/105.pdf');
INSERT INTO storage.objects(id,bucket_id,name,owner_id) VALUES
('00000000-0000-0000-0000-000000000801','schoolpro-document-outputs','00000000-0000-0000-0000-000000000001/issued/101.pdf','00000000-0000-0000-0000-000000000301'),
('00000000-0000-0000-0000-000000000802','schoolpro-document-outputs','00000000-0000-0000-0000-000000000002/issued/102.pdf','00000000-0000-0000-0000-000000000302'),
('00000000-0000-0000-0000-000000000803','schoolpro-document-outputs','00000000-0000-0000-0000-000000000001/issued/103.pdf','00000000-0000-0000-0000-000000000302'),
('00000000-0000-0000-0000-000000000804','schoolpro-document-outputs','00000000-0000-0000-0000-000000000001/draft/104.pdf','00000000-0000-0000-0000-000000000301'),
('00000000-0000-0000-0000-000000000805','schoolpro-document-outputs','00000000-0000-0000-0000-000000000001/issued/105.pdf','00000000-0000-0000-0000-000000000301');

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

CREATE FUNCTION public.assert_visible_output_names(p_expected text[]) RETURNS void
LANGUAGE plpgsql
AS $body$
DECLARE actual text[];
BEGIN
  SELECT COALESCE(array_agg(name ORDER BY name), ARRAY[]::text[])
  INTO actual FROM storage.objects WHERE bucket_id='schoolpro-document-outputs';
  IF actual IS DISTINCT FROM p_expected THEN
    RAISE EXCEPTION 'visible output names %, expected %', actual, p_expected;
  END IF;
END
$body$;
CREATE FUNCTION public.assert_insert_denied(p_name text, p_owner text) RETURNS void
LANGUAGE plpgsql
AS $body$
BEGIN
  BEGIN
    INSERT INTO storage.objects(id,bucket_id,name,owner_id)
    VALUES(gen_random_uuid(),'schoolpro-document-outputs',p_name,p_owner);
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN;
  END;
  RAISE EXCEPTION 'cross-school storage insert unexpectedly succeeded for %', p_name;
END
$body$;
CREATE FUNCTION public.assert_update_path_denied(p_id uuid, p_name text) RETURNS void
LANGUAGE plpgsql
AS $body$
DECLARE changed integer;
BEGIN
  BEGIN
    UPDATE storage.objects SET name=p_name WHERE id=p_id;
  EXCEPTION WHEN insufficient_privilege THEN
    RETURN;
  END;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 0 THEN
    RAISE EXCEPTION 'cross-school storage path update unexpectedly changed % rows', changed;
  END IF;
END
$body$;
CREATE FUNCTION public.assert_delete_noop(p_id uuid) RETURNS void
LANGUAGE plpgsql
AS $body$
DECLARE changed integer;
BEGIN
  DELETE FROM storage.objects WHERE id=p_id;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 0 THEN
    RAISE EXCEPTION 'cross-school storage delete unexpectedly changed % rows', changed;
  END IF;
END
$body$;
GRANT EXECUTE ON FUNCTION public.assert_visible_output_names(text[]) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.assert_insert_denied(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assert_update_path_denied(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assert_delete_noop(uuid) TO authenticated;


-- Before the fix: Student B and Guardian B can see the deliberately mismatched issue 103.
GRANT SELECT ON public.schoolpro_schools TO authenticated;

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
 '00000000-0000-0000-0000-000000000102'::uuid,
 '00000000-0000-0000-0000-000000000103'::uuid,
 '00000000-0000-0000-0000-000000000104'::uuid,
 '00000000-0000-0000-0000-000000000105'::uuid
]);
ROLLBACK;


BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000402',true);
SELECT public.assert_visible_output_names(ARRAY[
 '00000000-0000-0000-0000-000000000001/issued/103.pdf',
 '00000000-0000-0000-0000-000000000002/issued/102.pdf'
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
SELECT public.assert_visible_output_names(ARRAY[
 '00000000-0000-0000-0000-000000000001/draft/104.pdf',
 '00000000-0000-0000-0000-000000000001/issued/101.pdf',
 '00000000-0000-0000-0000-000000000001/issued/103.pdf',
 '00000000-0000-0000-0000-000000000001/issued/105.pdf'
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
-- Only the assigned Form Master, Exam Officer, and permitted school admin
-- may read School A staff documents. Registrar and unassigned teacher cannot.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
SELECT public.assert_visible_issue_ids(ARRAY[]::uuid[]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000502',true);
SELECT public.assert_visible_issue_ids(ARRAY[]::uuid[]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000505',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000101'::uuid,
 '00000000-0000-0000-0000-000000000104'::uuid,
 '00000000-0000-0000-0000-000000000105'::uuid
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000506',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000101'::uuid,
 '00000000-0000-0000-0000-000000000104'::uuid,
 '00000000-0000-0000-0000-000000000105'::uuid
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000507',true);
SELECT public.assert_visible_issue_ids(ARRAY[]::uuid[]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000508',true);
SELECT public.assert_visible_issue_ids(ARRAY[
 '00000000-0000-0000-0000-000000000101'::uuid,
 '00000000-0000-0000-0000-000000000104'::uuid,
 '00000000-0000-0000-0000-000000000105'::uuid
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000509',true);
SELECT public.assert_visible_issue_ids(ARRAY[]::uuid[]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub','',true);
SELECT public.assert_visible_issue_ids(ARRAY[]::uuid[]);
ROLLBACK;


BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000402',true);
SELECT public.assert_visible_output_names(ARRAY[
 '00000000-0000-0000-0000-000000000002/issued/102.pdf'
]);
ROLLBACK;
-- Storage follows the same staff authorization as the document table.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
SELECT public.assert_visible_output_names(ARRAY[]::text[]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000505',true);
SELECT public.assert_visible_output_names(ARRAY[
 '00000000-0000-0000-0000-000000000001/draft/104.pdf',
 '00000000-0000-0000-0000-000000000001/issued/101.pdf',
 '00000000-0000-0000-0000-000000000001/issued/105.pdf'
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000506',true);
SELECT public.assert_visible_output_names(ARRAY[
 '00000000-0000-0000-0000-000000000001/draft/104.pdf',
 '00000000-0000-0000-0000-000000000001/issued/101.pdf',
 '00000000-0000-0000-0000-000000000001/issued/105.pdf'
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000507',true);
SELECT public.assert_visible_output_names(ARRAY[]::text[]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000508',true);
SELECT public.assert_visible_output_names(ARRAY[
 '00000000-0000-0000-0000-000000000001/draft/104.pdf',
 '00000000-0000-0000-0000-000000000001/issued/101.pdf',
 '00000000-0000-0000-0000-000000000001/issued/105.pdf'
]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000509',true);
SELECT public.assert_visible_output_names(ARRAY[]::text[]);
ROLLBACK;
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000301',true);
SELECT public.assert_visible_output_names(ARRAY[
 '00000000-0000-0000-0000-000000000001/issued/101.pdf',
 '00000000-0000-0000-0000-000000000001/issued/105.pdf'
]);
ROLLBACK;
-- Registrar A cannot upload into school B's object namespace.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
SELECT public.assert_insert_denied('00000000-0000-0000-0000-000000000002/new.pdf','00000000-0000-0000-0000-000000000501');
ROLLBACK;
-- Proprietor A cannot rename its own object into school B's namespace.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000503',true);
SELECT public.assert_update_path_denied('00000000-0000-0000-0000-000000000801','00000000-0000-0000-0000-000000000002/tampered.pdf');
ROLLBACK;
-- Proprietor A cannot delete a school B object.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000503',true);
SELECT public.assert_delete_noop('00000000-0000-0000-0000-000000000802');
ROLLBACK;

-- Authorized registrar A retains document issue INSERT, UPDATE and DELETE.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000501',true);
DO $write_test$
DECLARE changed integer;
BEGIN
  INSERT INTO public.schoolpro_document_issues
    (id, school_id, student_id, status, output_storage_path)
  VALUES
    ('00000000-0000-0000-0000-000000000106',
     '00000000-0000-0000-0000-000000000001',
     '00000000-0000-0000-0000-000000000201',
     'draft', NULL);

  -- Reject a School B student linked to a School A document issue.
  DECLARE
    cross_school_rejected boolean := false;
  BEGIN
    BEGIN
      INSERT INTO public.schoolpro_document_issues
        (id, school_id, student_id, status, output_storage_path)
      VALUES
        ('00000000-0000-0000-0000-000000000107',
         '00000000-0000-0000-0000-000000000001',
         '00000000-0000-0000-0000-000000000202',
         'draft', NULL);
    EXCEPTION
      WHEN insufficient_privilege THEN
        cross_school_rejected := true;
    END;

    IF NOT cross_school_rejected THEN
      RAISE EXCEPTION 'cross-school document issue INSERT was accepted';
    END IF;
  END;

  -- UPDATE/DELETE policies remain defined for authorized writers, but
  -- PostgreSQL also applies SELECT visibility when targeting existing rows.
  -- Registrar SELECT is intentionally denied by the clarified access rule.
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'schoolpro_document_issues'
      AND policyname = 'school managers update document issues'
      AND cmd = 'UPDATE'
  ) THEN
    RAISE EXCEPTION 'registrar UPDATE policy was not retained';
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'schoolpro_document_issues'
      AND policyname = 'school managers delete document issues'
      AND cmd = 'DELETE'
  ) THEN
    RAISE EXCEPTION 'registrar DELETE policy was not retained';
  END IF;
END
$write_test$;
ROLLBACK;

SELECT 'issued-document and storage RLS regression passed' AS result;
