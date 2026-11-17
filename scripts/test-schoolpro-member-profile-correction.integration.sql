\set ON_ERROR_STOP on
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='service_role') THEN CREATE ROLE service_role NOLOGIN; END IF;
END $$;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS private;
DO $$ BEGIN
  CREATE TYPE public.school_member_role AS ENUM ('proprietor','administrator','teacher');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
$$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
CREATE OR REPLACE FUNCTION auth.role() RETURNS text LANGUAGE sql STABLE AS
$$ SELECT nullif(current_setting('request.jwt.claim.role',true),'') $$;

CREATE TABLE auth.users(id uuid primary key,email text);
CREATE TABLE public.profiles(
  id uuid primary key, email text, first_name text, middle_name text, last_name text,
  phone text, role text, status text
);
CREATE TABLE public.schoolpro_schools(id uuid primary key, owner_id uuid);
CREATE TABLE public.schoolpro_members(
  id uuid primary key, school_id uuid, user_id uuid, role text, status text,
  unique(school_id,user_id)
);
CREATE TABLE public.schoolpro_member_responsibilities(
  id uuid primary key, school_id uuid, member_id uuid, responsibility text, ended_at timestamptz
);
CREATE TABLE public.schoolpro_guardian_links(
  id uuid primary key, school_id uuid, student_id uuid, guardian_user_id uuid, status text default 'active'
);
CREATE OR REPLACE FUNCTION private.has_school_access(p_school uuid,p_roles public.school_member_role[])
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.schoolpro_members m
    WHERE m.school_id=p_school AND m.user_id=auth.uid()
      AND m.status='active' AND m.role=ANY(p_roles::text[])
  )
$$;

INSERT INTO auth.users VALUES
('10000000-0000-0000-0000-000000000001','admin@example.test'),
('10000000-0000-0000-0000-000000000002','staff@example.test'),
('10000000-0000-0000-0000-000000000003','guardian@example.test'),
('10000000-0000-0000-0000-000000000004','outsider@example.test');
INSERT INTO public.schoolpro_schools VALUES
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001');
INSERT INTO public.profiles(id,email,first_name,middle_name,last_name,phone,role,status) VALUES
('10000000-0000-0000-0000-000000000001','admin@example.test','Admin',null,'User',null,'user','active'),
('10000000-0000-0000-0000-000000000002','staff@example.test','Old',null,'Staff','08000000000','user','active'),
('10000000-0000-0000-0000-000000000003','guardian@example.test','Old',null,'Guardian',null,'user','active'),
('10000000-0000-0000-0000-000000000004','outsider@example.test','Out',null,'Sider',null,'user','active');
INSERT INTO public.schoolpro_members VALUES
('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','administrator','active'),
('30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','teacher','active');
INSERT INTO public.schoolpro_guardian_links(id,school_id,student_id,guardian_user_id,status) VALUES
('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003','active');

\i supabase/migrations/20261117230000_schoolpro_atomic_member_profile_corrections.sql

SELECT set_config('request.jwt.claim.role','service_role',false);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);
SELECT public.schoolpro_correct_member_profile_atomic(
 '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000001','Staff','Middle','Corrected','+2348012345678'
);
SELECT public.schoolpro_correct_member_profile_atomic(
 '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000001','Guardian','Middle','Corrected','08012345678'
);
DO $$
BEGIN
  IF (SELECT first_name||'|'||middle_name||'|'||last_name||'|'||phone||'|'||email FROM public.profiles WHERE id='10000000-0000-0000-0000-000000000002')
     <> 'Staff|Middle|Corrected|+2348012345678|staff@example.test' THEN RAISE EXCEPTION 'staff correction/email preservation failed'; END IF;
  IF (SELECT count(*) FROM public.schoolpro_profile_change_audit) <> 2 THEN RAISE EXCEPTION 'expected two atomic audit rows'; END IF;
END $$;

-- School administrators may request a new sign-in email, but the live Auth
-- identity and profile email must not change until the account owner verifies.
SELECT public.schoolpro_request_member_email_change_atomic(
 '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000001','replacement.staff@example.test'
);
DO $$
BEGIN
  IF (SELECT email FROM auth.users WHERE id='10000000-0000-0000-0000-000000000002') <> 'staff@example.test'
    THEN RAISE EXCEPTION 'email changed before verification'; END IF;
  IF (SELECT email FROM public.profiles WHERE id='10000000-0000-0000-0000-000000000002') <> 'staff@example.test'
    THEN RAISE EXCEPTION 'profile email changed before verification'; END IF;
  IF (SELECT status FROM public.schoolpro_member_email_change_requests WHERE target_user_id='10000000-0000-0000-0000-000000000002') <> 'pending'
    THEN RAISE EXCEPTION 'email request was not left pending'; END IF;
END $$;

-- A pending request (no Auth verification sent yet) can be replaced.
SELECT public.schoolpro_request_member_email_change_atomic(
 '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000001','replacement.staff@example.test'
);
DO $
BEGIN
  IF (SELECT count(*) FROM public.schoolpro_member_email_change_requests
      WHERE target_user_id='10000000-0000-0000-0000-000000000002' AND status='cancelled') <> 1
    THEN RAISE EXCEPTION 'superseded pending email request was not cancelled'; END IF;
END $$;
UPDATE public.schoolpro_member_email_change_requests
SET status='verification_sent'
WHERE target_user_id='10000000-0000-0000-0000-000000000002'
  AND requested_email='replacement.staff@example.test';
DO $
BEGIN
  BEGIN
    PERFORM public.schoolpro_request_member_email_change_atomic(
      '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
      '10000000-0000-0000-0000-000000000001','third.staff@example.test');
    RAISE EXCEPTION 'in-flight verification was unexpectedly replaced';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='in-flight verification was unexpectedly replaced' THEN RAISE; END IF;
    IF SQLERRM NOT LIKE '%verification is already in progress%' THEN RAISE; END IF;
  END;
  IF (SELECT status FROM public.schoolpro_member_email_change_requests
      WHERE target_user_id='10000000-0000-0000-0000-000000000002'
        AND requested_email='replacement.staff@example.test') <> 'verification_sent'
    THEN RAISE EXCEPTION 'in-flight verification request was modified'; END IF;
END $$;
UPDATE auth.users SET email='replacement.staff@example.test'
WHERE id='10000000-0000-0000-0000-000000000002';

DO $$
BEGIN
  IF (SELECT email FROM public.profiles WHERE id='10000000-0000-0000-0000-000000000002') <> 'replacement.staff@example.test'
    THEN RAISE EXCEPTION 'verified Auth email was not synced to IHLink profile'; END IF;
  IF (SELECT status FROM public.schoolpro_member_email_change_requests WHERE target_user_id='10000000-0000-0000-0000-000000000002') <> 'confirmed'
    THEN RAISE EXCEPTION 'email change request was not marked confirmed'; END IF;
  IF (SELECT count(*) FROM public.schoolpro_profile_change_audit) <> 3
    THEN RAISE EXCEPTION 'verified email change was not audited'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.schoolpro_profile_change_audit
    WHERE target_user_id='10000000-0000-0000-0000-000000000002'
      AND changed_fields = ARRAY['email']::text[]
      AND before_values->>'email'='staff@example.test'
      AND after_values->>'email'='replacement.staff@example.test'
  ) THEN RAISE EXCEPTION 'email change audit values are incorrect'; END IF;
END $$;

-- Suspended target relationships cannot authorize profile or email changes.
UPDATE public.schoolpro_members SET status='suspended'
WHERE user_id='10000000-0000-0000-0000-000000000002';
DO $$ BEGIN
  BEGIN
    PERFORM public.schoolpro_correct_member_profile_atomic(
      '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
      '10000000-0000-0000-0000-000000000001','Suspended','Staff','Denied',null);
    RAISE EXCEPTION 'suspended staff membership unexpectedly authorized correction';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='suspended staff membership unexpectedly authorized correction' THEN RAISE; END IF;
  END;
END $$;
UPDATE public.schoolpro_members SET status='active'
WHERE user_id='10000000-0000-0000-0000-000000000002';
UPDATE public.schoolpro_guardian_links SET status='suspended'
WHERE guardian_user_id='10000000-0000-0000-0000-000000000003';
DO $$ BEGIN
  BEGIN
    PERFORM public.schoolpro_request_member_email_change_atomic(
      '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003',
      '10000000-0000-0000-0000-000000000001','guardian.new@example.test');
    RAISE EXCEPTION 'suspended guardian link unexpectedly authorized email change';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='suspended guardian link unexpectedly authorized email change' THEN RAISE; END IF;
  END;
END $$;
UPDATE public.schoolpro_guardian_links SET status='active'
WHERE guardian_user_id='10000000-0000-0000-0000-000000000003';

-- An inactive global profile cannot be corrected even if the school link remains active.
UPDATE public.profiles SET status='suspended'
WHERE id='10000000-0000-0000-0000-000000000002';
DO $$ BEGIN
  BEGIN
    PERFORM public.schoolpro_correct_member_profile_atomic(
      '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
      '10000000-0000-0000-0000-000000000001','Inactive','Staff','Denied',null);
    RAISE EXCEPTION 'inactive target account unexpectedly authorized correction';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='inactive target account unexpectedly authorized correction' THEN RAISE; END IF;
  END;
END $$;
UPDATE public.profiles SET status='active'
WHERE id='10000000-0000-0000-0000-000000000002';

-- Unauthorized and inactive actors must not modify either profile or audit.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',false);
DO $$ BEGIN
  BEGIN
    PERFORM public.schoolpro_correct_member_profile_atomic(
      '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
      '10000000-0000-0000-0000-000000000004','No','Access','Allowed',null);
    RAISE EXCEPTION 'unauthorized actor unexpectedly succeeded';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='unauthorized actor unexpectedly succeeded' THEN RAISE; END IF;
  END;
END $$;
UPDATE public.profiles SET status='suspended' WHERE id='10000000-0000-0000-0000-000000000001';
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);
DO $$ BEGIN
  BEGIN
    PERFORM public.schoolpro_correct_member_profile_atomic(
      '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
      '10000000-0000-0000-0000-000000000001','Inactive','Admin','Denied',null);
    RAISE EXCEPTION 'inactive actor unexpectedly succeeded';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='inactive actor unexpectedly succeeded' THEN RAISE; END IF;
  END;
END $$;
UPDATE public.profiles SET status='active' WHERE id='10000000-0000-0000-0000-000000000001';

-- A failed audit insert must roll the preceding profile update back.
CREATE OR REPLACE FUNCTION public.reject_profile_audit_for_test()
RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'simulated audit write failure'; END $$;
CREATE TRIGGER reject_profile_audit_for_test
BEFORE INSERT ON public.schoolpro_profile_change_audit
FOR EACH ROW EXECUTE FUNCTION public.reject_profile_audit_for_test();
DO $$ BEGIN
  BEGIN
    PERFORM public.schoolpro_correct_member_profile_atomic(
      '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
      '10000000-0000-0000-0000-000000000001','Rollback','Must','Persist','08000000000');
    RAISE EXCEPTION 'audit failure did not abort correction';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='audit failure did not abort correction' THEN RAISE; END IF;
  END;
END $$;
DROP TRIGGER reject_profile_audit_for_test ON public.schoolpro_profile_change_audit;
DROP FUNCTION public.reject_profile_audit_for_test();
DO $$
BEGIN
  IF (SELECT first_name FROM public.profiles WHERE id='10000000-0000-0000-0000-000000000002') <> 'Staff'
    THEN RAISE EXCEPTION 'profile update was not rolled back after audit failure'; END IF;
  IF (SELECT count(*) FROM public.schoolpro_profile_change_audit) <> 3
    THEN RAISE EXCEPTION 'audit row count changed after rollback'; END IF;
END $$;

-- Only the authorized school administrator can read this school's audit rows.
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.schoolpro_profile_change_audit TO authenticated;
GRANT SELECT ON public.schoolpro_schools, public.schoolpro_members, public.schoolpro_member_responsibilities TO authenticated;
SET ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);
DO $$ BEGIN
  IF (SELECT count(*) FROM public.schoolpro_profile_change_audit) <> 3
    THEN RAISE EXCEPTION 'school admin cannot read audit history'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',false);
DO $$ BEGIN
  IF (SELECT count(*) FROM public.schoolpro_profile_change_audit) <> 0
    THEN RAISE EXCEPTION 'unrelated user can read audit history'; END IF;
  IF (SELECT count(*) FROM public.schoolpro_member_email_change_requests) <> 0
    THEN RAISE EXCEPTION 'unrelated user can read email change requests'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',false);
DO $$ BEGIN
  IF (SELECT count(*) FROM public.schoolpro_member_email_change_requests WHERE target_user_id='10000000-0000-0000-0000-000000000002') <> 1
    THEN RAISE EXCEPTION 'target account cannot read its own email change request'; END IF;
END $$;
RESET ROLE;
DO $$ BEGIN
  IF has_table_privilege('authenticated','public.schoolpro_profile_change_audit','INSERT')
    THEN RAISE EXCEPTION 'authenticated users can forge audit rows'; END IF;
END $$;

SELECT 'PASS: staff/guardian corrections, verified sign-in email change, authorization, audit visibility and rollback.' AS result;
