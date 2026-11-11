-- Disposable PostgreSQL integration test for the existing-student import payload preflight.
-- This creates only local test roles/functions/data in the CI service database.
\set ON_ERROR_STOP on

create role anon nologin;
create role authenticated nologin;

create schema auth;
create schema private;
create type public.school_member_role as enum ('proprietor', 'administrator', 'teacher');

create function auth.uid()
returns uuid
language sql stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create function private.is_active_account()
returns boolean
language sql stable
as $$
  select coalesce(nullif(current_setting('test.active_account', true), '')::boolean, false)
$$;

create function private.has_school_access(p_school_id uuid, p_roles public.school_member_role[])
returns boolean
language sql stable
as $$
  select coalesce(
    p_school_id::text = nullif(current_setting('test.authorized_school', true), '')
    and 'proprietor'::public.school_member_role = any(p_roles),
    false
  )
$$;

grant usage on schema auth, private, public to authenticated, anon;
grant usage on type public.school_member_role to authenticated;
grant execute on function auth.uid() to authenticated;
grant execute on function private.is_active_account() to authenticated;
grant execute on function private.has_school_access(uuid, public.school_member_role[]) to authenticated;

create table public.test_write_sentinel(id integer primary key);
insert into public.test_write_sentinel values (1);

\ir supabase/migrations/20261110133000_schoolpro_existing_student_import_payload_diagnostic.sql

do $assert$
declare
  v_fn oid := 'public.schoolpro_existing_student_import_payload_check(uuid,jsonb)'::regprocedure;
  v_acl_has_public_execute boolean;
begin
  if (select prosecdef from pg_proc where oid = v_fn) then
    raise exception 'Expected SECURITY INVOKER, found SECURITY DEFINER';
  end if;
  if not has_function_privilege('authenticated', v_fn, 'EXECUTE') then
    raise exception 'authenticated must be able to execute the diagnostic';
  end if;
  if has_function_privilege('anon', v_fn, 'EXECUTE') then
    raise exception 'anon must not be able to execute the diagnostic';
  end if;
  select exists (
    select 1 from aclexplode(coalesce(proacl, acldefault('f', proowner)))
    where grantee = 0 and privilege_type = 'EXECUTE'
  ) into v_acl_has_public_execute
  from pg_proc where oid = v_fn;
  if v_acl_has_public_execute then
    raise exception 'PUBLIC must not have EXECUTE on the diagnostic';
  end if;
end;
$assert$;

select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);
select set_config('test.active_account', 'true', false);
select set_config('test.authorized_school', 'ac7ac8a8-5035-4e39-8868-cad54add84a6', false);
set role authenticated;

do $assert$
declare
  v_result jsonb;
  v_school uuid := 'ac7ac8a8-5035-4e39-8868-cad54add84a6';
  v_other uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
begin
  v_result := public.schoolpro_existing_student_import_payload_check(
    v_school,
    jsonb_build_array(
      jsonb_build_object('school_id', v_school),
      jsonb_build_object('school_id', v_school)
    )
  );
  if v_result->>'all_rows_authorized' <> 'true'
     or (v_result->>'row_count')::integer <> 2
     or jsonb_array_length(v_result->'failed_rows') <> 0 then
    raise exception 'Authorised matching batch should pass; got %', v_result;
  end if;

  v_result := public.schoolpro_existing_student_import_payload_check(
    v_school,
    jsonb_build_array(
      jsonb_build_object('school_id', v_school),
      jsonb_build_object('school_id', v_other)
    )
  );
  if v_result->>'all_rows_authorized' <> 'false'
     or v_result->'failed_rows' <> '[2]'::jsonb then
    raise exception 'Mismatched tenant ID should fail only row 2; got %', v_result;
  end if;

  v_result := public.schoolpro_existing_student_import_payload_check(
    v_school,
    jsonb_build_array(jsonb_build_object('school_id', 'not-a-uuid'))
  );
  if v_result->>'all_rows_authorized' <> 'false'
     or v_result->'failed_rows' <> '[1]'::jsonb then
    raise exception 'Malformed UUID should be reported as a failed row; got %', v_result;
  end if;

  v_result := public.schoolpro_existing_student_import_payload_check(v_school, '[]'::jsonb);
  if v_result->>'all_rows_authorized' <> 'false'
     or v_result->>'reason' <> 'The import batch is empty.' then
    raise exception 'Empty batch must be rejected; got %', v_result;
  end if;

  v_result := public.schoolpro_existing_student_import_payload_check(v_school, '{}'::jsonb);
  if v_result->>'all_rows_authorized' <> 'false'
     or v_result->>'reason' <> 'The submitted batch is not a JSON array.' then
    raise exception 'Non-array payload must be rejected; got %', v_result;
  end if;

  perform set_config('test.active_account', 'false', false);
  v_result := public.schoolpro_existing_student_import_payload_check(
    v_school, jsonb_build_array(jsonb_build_object('school_id', v_school))
  );
  if v_result->>'active_account' <> 'false'
     or v_result->>'all_rows_authorized' <> 'false' then
    raise exception 'Inactive account must be rejected; got %', v_result;
  end if;

  perform set_config('test.active_account', 'true', false);
  perform set_config('request.jwt.claim.sub', '', false);
  v_result := public.schoolpro_existing_student_import_payload_check(
    v_school, jsonb_build_array(jsonb_build_object('school_id', v_school))
  );
  if v_result->>'authenticated' <> 'false'
     or v_result->>'all_rows_authorized' <> 'false' then
    raise exception 'Unauthenticated request must be rejected; got %', v_result;
  end if;
end;
$assert$;

reset role;

do $assert$
begin
  if (select count(*) from public.test_write_sentinel) <> 1 then
    raise exception 'Diagnostic unexpectedly changed the write sentinel';
  end if;
end;
$assert$;

drop table public.test_write_sentinel;
drop function private.has_school_access(uuid, public.school_member_role[]);
drop function private.is_active_account();
drop function auth.uid();
drop type public.school_member_role;
drop schema private;
drop schema auth;
drop role authenticated;
drop role anon;

do $assert$
begin
  raise notice 'PASS: existing-student import payload diagnostic authorization, tenant matching, malformed/empty payload, grants and no-write invariants.';
end;
$assert$;
