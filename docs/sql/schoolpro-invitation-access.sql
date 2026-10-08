-- Invitations are authoritative rows; editable auth metadata never grants school access.
create or replace function private.schoolpro_can_register()
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and not exists(select 1 from public.schoolpro_members where user_id=auth.uid() and role::text<>'proprietor')
 and not exists(select 1 from public.schoolpro_students where user_id=auth.uid())
 and not exists(select 1 from public.schoolpro_guardian_links where guardian_user_id=auth.uid());
$$;
revoke all on function private.schoolpro_can_register() from public,anon;
grant execute on function private.schoolpro_can_register() to authenticated;
drop policy if exists "Owners create schools" on public.schoolpro_schools;
create policy "Owners create schools" on public.schoolpro_schools for insert to authenticated
with check(owner_id=(select auth.uid()) and private.schoolpro_can_register());
drop policy if exists "Users create onboarding requests" on public.schoolpro_onboarding_requests;
create policy "Users create onboarding requests" on public.schoolpro_onboarding_requests for insert to anon,authenticated
with check((auth.uid() is null and user_id is null) or (user_id=auth.uid() and private.schoolpro_can_register()));
create table if not exists public.schoolpro_login_attempts(key text primary key,started_at timestamptz not null default now(),attempts integer not null default 1);
alter table public.schoolpro_login_attempts enable row level security;
revoke all on public.schoolpro_login_attempts from anon,authenticated;
grant all on public.schoolpro_login_attempts to service_role;
create table if not exists public.schoolpro_student_activation_challenges(
 token_hash text primary key,student_id uuid not null references public.schoolpro_students(id) on delete cascade,
 expires_at timestamptz not null default now()+interval '10 minutes');
alter table public.schoolpro_student_activation_challenges enable row level security;
revoke all on public.schoolpro_student_activation_challenges from anon,authenticated;
grant all on public.schoolpro_student_activation_challenges to service_role;
create or replace function public.schoolpro_take_login_attempt(p_key text,p_limit integer)
returns boolean language plpgsql security invoker set search_path='' as $$
declare n integer;begin
 if p_limit<1 or p_limit>60 then return false;end if;
 insert into public.schoolpro_login_attempts as a(key) values(p_key)
 on conflict(key) do update set attempts=case when a.started_at<now()-interval '15 minutes' then 1 else a.attempts+1 end,
 started_at=case when a.started_at<now()-interval '15 minutes' then now() else a.started_at end returning attempts into n;
 delete from public.schoolpro_login_attempts where started_at<now()-interval '1 day';
 delete from public.schoolpro_student_activation_challenges where expires_at<now();
 return n<=p_limit;
end;$$;
create or replace function public.schoolpro_consume_student_challenge(p_hash text)
returns uuid language plpgsql security invoker set search_path='' as $$
declare sid uuid;begin
 select student_id into sid from public.schoolpro_student_activation_challenges where token_hash=p_hash and expires_at>now() for update;
 if sid is null then return null;end if;
 perform 1 from public.schoolpro_students where id=sid and user_id is null and status='active' for update;
 if not found then return null;end if;
 delete from public.schoolpro_student_activation_challenges where student_id=sid;
 return sid;
end;$$;
revoke all on function public.schoolpro_take_login_attempt(text,integer),public.schoolpro_consume_student_challenge(text) from public,anon,authenticated;
grant execute on function public.schoolpro_take_login_attempt(text,integer),public.schoolpro_consume_student_challenge(text) to service_role;
create or replace function private.schoolpro_guardian_school_scope()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id) then
 raise exception 'The student must belong to the selected school';end if;return new;
end;$$;
revoke all on function private.schoolpro_guardian_school_scope() from public,anon,authenticated;
create trigger schoolpro_guardian_school_scope before insert or update of school_id,student_id on public.schoolpro_guardian_links
for each row execute function private.schoolpro_guardian_school_scope();
