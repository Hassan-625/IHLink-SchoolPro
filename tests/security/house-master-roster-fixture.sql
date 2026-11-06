-- Minimal disposable PostgreSQL schema for the House Master roster migration test.
\set ON_ERROR_STOP on

CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE SCHEMA auth;
CREATE SCHEMA private;

-- Supabase Auth subset used by the regression's disposable identities.
CREATE TABLE auth.users (
  id uuid PRIMARY KEY,
  aud text,
  role text,
  email text UNIQUE,
  encrypted_password text,
  confirmed_at timestamptz,
  raw_app_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  raw_user_meta_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  email text,
  status text NOT NULL DEFAULT 'active'
);

CREATE TABLE public.schoolpro_schools (
  id uuid PRIMARY KEY,
  owner_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  code text NOT NULL UNIQUE
);

CREATE TYPE public.school_member_role AS ENUM ('teacher', 'class_teacher', 'administrator');

CREATE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE
AS $$ SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

CREATE FUNCTION private.is_active_account() RETURNS boolean
LANGUAGE sql STABLE
AS $$ SELECT auth.uid() IS NOT NULL $$;

GRANT USAGE ON SCHEMA private TO authenticated;

CREATE TABLE public.schoolpro_members (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role public.school_member_role NOT NULL
);
CREATE TABLE public.schoolpro_houses (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  name text NOT NULL,
  color text NOT NULL,
  code text NOT NULL,
  is_active boolean NOT NULL DEFAULT true
);
CREATE TABLE public.schoolpro_house_master_assignments (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  house_id uuid NOT NULL,
  member_id uuid NOT NULL,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz
);
CREATE TABLE public.schoolpro_student_house_history (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  student_id uuid NOT NULL,
  house_id uuid NOT NULL,
  assignment_type text NOT NULL,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  effective_to timestamptz
);
CREATE TABLE public.schoolpro_students (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  admission_number text,
  first_name text,
  middle_name text,
  last_name text,
  class_name text,
  class_id uuid,
  status text NOT NULL
);
CREATE TABLE public.schoolpro_classes (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,
  name text NOT NULL,
  arm text,
  level text
);
