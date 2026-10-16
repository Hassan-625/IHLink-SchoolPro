-- Disposable PostgreSQL integration test for the SchoolPro no-online-gateway migration.
-- Run from repository root against a dedicated throwaway database only.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin; end if;
end $$;

\i supabase/migrations/20261016170000_schoolpro_disable_online_payment_gateway.sql

do $$
declare
  fn regprocedure := 'public.finalize_schoolpro_payment(text,text,numeric,text,jsonb)'::regprocedure;
  role_name text;
  allowed boolean;
begin
  foreach role_name in array array['anon', 'authenticated', 'service_role'] loop
    select has_function_privilege(role_name, fn, 'EXECUTE') into allowed;
    if allowed then
      raise exception 'Unexpected EXECUTE privilege on legacy gateway finalizer for role %', role_name;
    end if;
  end loop;

  begin
    perform public.finalize_schoolpro_payment('test-reference', 'test-transaction', 1, 'success', '{}'::jsonb);
    raise exception 'Legacy online finalizer unexpectedly returned successfully';
  exception
    when sqlstate '0A000' then
      if sqlerrm not like '%SchoolPro online payments are disabled%' then
        raise exception 'Unexpected disabled-finalizer error: %', sqlerrm;
      end if;
  end;
end $$;

select 'PASS: migration applies; anon/authenticated/service_role cannot execute the legacy finalizer; direct invocation fails closed.' as result;
