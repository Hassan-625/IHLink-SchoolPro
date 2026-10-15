create extension if not exists pgcrypto;
create schema if not exists auth;
create schema if not exists storage;
create schema if not exists private;
do $$ begin
  if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
end $$;
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
create type public.schoolpro_invoice_status as enum ('unpaid','part_paid','paid','waived');
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null,
  name text not null,
  metadata jsonb not null default '{}'::jsonb,
  unique(bucket_id,name)
);
create table public.schoolpro_invoices (
  id uuid primary key,
  school_id uuid not null,
  student_id uuid not null,
  amount_due numeric not null,
  amount_paid numeric not null default 0,
  status public.schoolpro_invoice_status not null default 'unpaid',
  updated_at timestamptz not null default now()
);
create table public.schoolpro_guardian_links (
  school_id uuid not null,
  student_id uuid not null,
  guardian_user_id uuid not null,
  status text not null
);
create table public.schoolpro_bank_accounts (
  id uuid primary key,
  school_id uuid not null,
  active boolean not null default true
);
create table public.schoolpro_payment_submissions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  submitted_by uuid not null,
  bank_account_id uuid,
  total_amount numeric not null,
  payment_date date not null,
  payer_name text,
  bank_reference text,
  receipt_path text not null,
  receipt_mime text,
  status text not null default 'pending',
  review_note text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.schoolpro_payment_allocations (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null,
  school_id uuid not null,
  student_id uuid not null,
  invoice_id uuid not null,
  amount numeric not null,
  payment_id uuid,
  created_at timestamptz not null default now()
);
create table public.schoolpro_fee_payments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  invoice_id uuid not null,
  student_id uuid not null,
  amount numeric not null,
  method text not null,
  reference text not null,
  notes text,
  recorded_by uuid
);
