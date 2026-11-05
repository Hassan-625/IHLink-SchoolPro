-- Disposable PostgreSQL regression fixture for the live schoolpro_take_login_attempt contract.
-- This snapshots the read-only production function body; it does not connect to or modify production.
do $roles$
begin
  create role anon nologin;
exception when duplicate_object then null;
end
$roles$;
do $roles$
begin
  create role authenticated nologin;
exception when duplicate_object then null;
end
$roles$;
do $roles$
begin
  create role service_role nologin;
exception when duplicate_object then null;
end
$roles$;

create table public.schoolpro_login_attempts (
  key text primary key,
  started_at timestamptz not null default now(),
  attempts integer not null default 1
);
create table public.schoolpro_student_activation_challenges (
  token_hash text primary key,
  student_id uuid not null,
  expires_at timestamptz not null default (now() + interval '10 minutes')
);

create or replace function public.schoolpro_take_login_attempt(p_key text, p_limit integer)
returns boolean
language plpgsql
set search_path to ''
as $function$
declare n integer;
begin
  if p_limit < 1 or p_limit > 60 then return false; end if;
  insert into public.schoolpro_login_attempts as a(key) values(p_key)
  on conflict(key) do update
    set attempts = case when a.started_at < now() - interval '15 minutes' then 1 else a.attempts + 1 end,
        started_at = case when a.started_at < now() - interval '15 minutes' then now() else a.started_at end
  returning attempts into n;
  delete from public.schoolpro_login_attempts where started_at < now() - interval '1 day';
  delete from public.schoolpro_student_activation_challenges where expires_at < now();
  return n <= p_limit;
end;
$function$;

revoke all on function public.schoolpro_take_login_attempt(text,integer) from public, anon, authenticated;
grant execute on function public.schoolpro_take_login_attempt(text,integer) to service_role;
grant usage on schema public to service_role;
grant select, insert, update, delete on public.schoolpro_login_attempts, public.schoolpro_student_activation_challenges to service_role;

do $test$
declare i integer; allowed boolean; n integer;
begin
  if has_function_privilege('anon','public.schoolpro_take_login_attempt(text,integer)','EXECUTE') then
    raise exception 'anon must not execute the login-attempt RPC';
  end if;
  if has_function_privilege('authenticated','public.schoolpro_take_login_attempt(text,integer)','EXECUTE') then
    raise exception 'authenticated must not execute the login-attempt RPC directly';
  end if;
  if not has_function_privilege('service_role','public.schoolpro_take_login_attempt(text,integer)','EXECUTE') then
    raise exception 'service_role must execute the login-attempt RPC';
  end if;

  if public.schoolpro_take_login_attempt('bad-zero',0) then raise exception 'limit below 1 must fail closed'; end if;
  if public.schoolpro_take_login_attempt('bad-high',61) then raise exception 'limit above 60 must fail closed'; end if;

  for i in 1..8 loop
    allowed := public.schoolpro_take_login_attempt('account-a',8);
    if not allowed then raise exception 'attempt % should be allowed for limit 8',i; end if;
  end loop;
  if public.schoolpro_take_login_attempt('account-a',8) then raise exception 'ninth attempt should be denied'; end if;
  if not public.schoolpro_take_login_attempt('account-b',8) then raise exception 'different account key must have an independent counter'; end if;

  update public.schoolpro_login_attempts set started_at=now()-interval '16 minutes' where key='account-a';
  if not public.schoolpro_take_login_attempt('account-a',8) then raise exception 'attempt counter should reset after 15 minutes'; end if;
  select attempts into n from public.schoolpro_login_attempts where key='account-a';
  if n <> 1 then raise exception 'expected reset counter 1, got %',n; end if;

  update public.schoolpro_login_attempts set started_at=now()-interval '2 days' where key='old-key';
  insert into public.schoolpro_login_attempts(key,started_at,attempts) values('old-key',now()-interval '2 days',20)
  on conflict(key) do update set started_at=excluded.started_at,attempts=excluded.attempts;
  insert into public.schoolpro_student_activation_challenges(token_hash,student_id,expires_at)
  values ('expired-token','00000000-0000-0000-0000-000000000001',now()-interval '1 minute'),
         ('fresh-token','00000000-0000-0000-0000-000000000002',now()+interval '1 minute');
  perform public.schoolpro_take_login_attempt('cleanup-trigger',8);
  if exists(select 1 from public.schoolpro_login_attempts where key='old-key') then raise exception 'rows older than one day must be cleaned'; end if;
  if exists(select 1 from public.schoolpro_student_activation_challenges where token_hash='expired-token') then raise exception 'expired student activation challenge must be cleaned'; end if;
  if not exists(select 1 from public.schoolpro_student_activation_challenges where token_hash='fresh-token') then raise exception 'unexpired student activation challenge must remain'; end if;
end
$test$;

do $grants$
begin
  if has_table_privilege('anon','public.schoolpro_login_attempts','SELECT') or
     has_table_privilege('authenticated','public.schoolpro_login_attempts','SELECT') then
    raise exception 'client roles must not directly read login-attempt rows';
  end if;
end
$grants$;

select 'PASS: login attempt RPC privilege boundary, 15-minute window, configured limits, key separation, stale-row cleanup and expired student-challenge cleanup' as result;
