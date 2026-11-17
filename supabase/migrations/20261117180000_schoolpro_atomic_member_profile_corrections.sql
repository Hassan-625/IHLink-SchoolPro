begin;

-- School-authorized corrections to a shared IHLink identity.
-- The audit is intentionally not cascade-deleted with a school or account.
alter table public.profiles add column if not exists phone text;

create table if not exists public.schoolpro_profile_change_audit (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  target_user_id uuid not null,
  changed_by uuid not null,
  changed_at timestamptz not null default now(),
  changed_fields text[] not null,
  before_values jsonb not null,
  after_values jsonb not null
);

create index if not exists schoolpro_profile_change_audit_scope_idx
  on public.schoolpro_profile_change_audit(school_id, target_user_id, changed_at desc);

alter table public.schoolpro_profile_change_audit enable row level security;
revoke all on public.schoolpro_profile_change_audit from anon, public;
grant select on public.schoolpro_profile_change_audit to authenticated;
grant usage on schema private to authenticated;

drop policy if exists schoolpro_profile_change_audit_school_admin_read
  on public.schoolpro_profile_change_audit;
create policy schoolpro_profile_change_audit_school_admin_read
  on public.schoolpro_profile_change_audit for select to authenticated
  using (
    private.has_school_access(
      school_id,
      array['proprietor'::public.school_member_role, 'administrator'::public.school_member_role]
    )
  );

create or replace function public.schoolpro_correct_member_profile_atomic(
  p_school_id uuid,
  p_target_user_id uuid,
  p_actor_id uuid,
  p_first_name text,
  p_middle_name text,
  p_last_name text,
  p_phone text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  school_owner uuid;
  actor_role text;
  actor_status text;
  actor_global_role text;
  actor_global_status text;
  actor_member_id uuid;
  target_member_id uuid;
  target_guardian_link_id uuid;
  before_profile jsonb;
  after_profile jsonb;
  fields text[];
begin
  if auth.role() <> 'service_role' then
    raise exception 'Service role required';
  end if;
  if p_actor_id is null or p_target_user_id is null or p_actor_id = p_target_user_id then
    raise exception 'Invalid actor or target';
  end if;
  if coalesce(trim(p_first_name), '') = '' or length(trim(p_first_name)) > 100
     or coalesce(trim(p_last_name), '') = '' or length(trim(p_last_name)) > 100
     or length(trim(coalesce(p_middle_name, ''))) > 100
     or (nullif(trim(coalesce(p_phone, '')), '') is not null
         and trim(p_phone) !~ '^[+0-9() .-]{7,40}$') then
    raise exception 'Invalid profile fields';
  end if;

  select s.owner_id into school_owner
  from public.schoolpro_schools s
  where s.id = p_school_id
  for key share;
  if not found then raise exception 'School not found'; end if;

  select m.id, m.role::text, m.status::text
    into actor_member_id, actor_role, actor_status
  from public.schoolpro_members m
  where m.school_id = p_school_id and m.user_id = p_actor_id
  for key share;

  select p.role::text, p.status::text
    into actor_global_role, actor_global_status
  from public.profiles p
  where p.id = p_actor_id
  for key share;

  if actor_global_status is distinct from 'active' then
    raise exception 'Actor account is inactive';
  end if;

  if actor_member_id is not null and actor_status is distinct from 'active' then
    raise exception 'Actor school membership is inactive';
  end if;

  if not (
    school_owner = p_actor_id
    or (actor_member_id is not null and actor_role in ('proprietor', 'administrator'))
    or (actor_member_id is not null and exists (
      select 1 from public.schoolpro_member_responsibilities r
      where r.school_id = p_school_id and r.member_id = actor_member_id
        and r.responsibility = 'school_admin' and r.ended_at is null
    ))
    or (actor_global_role = 'super_admin' and actor_global_status = 'active')
  ) then
    raise exception 'Not authorized for this school';
  end if;

  -- Lock whichever school relationship proves that the target belongs here.
  -- A concurrent membership/link deletion must wait until this transaction commits.
  select m.id into target_member_id
  from public.schoolpro_members m
  where m.school_id = p_school_id and m.user_id = p_target_user_id
  order by m.id
  limit 1
  for key share;

  select g.id into target_guardian_link_id
  from public.schoolpro_guardian_links g
  where g.school_id = p_school_id and g.guardian_user_id = p_target_user_id
  order by g.id
  limit 1
  for key share;

  if target_member_id is null and target_guardian_link_id is null then
    raise exception 'Target account is not linked to this school';
  end if;

  select jsonb_build_object(
    'first_name', p.first_name,
    'middle_name', p.middle_name,
    'last_name', p.last_name,
    'phone', p.phone
  )
  into before_profile
  from public.profiles p
  where p.id = p_target_user_id
  for update;

  if before_profile is null then raise exception 'Target profile not found'; end if;

  after_profile := jsonb_build_object(
    'first_name', trim(p_first_name),
    'middle_name', nullif(trim(coalesce(p_middle_name, '')), ''),
    'last_name', trim(p_last_name),
    'phone', nullif(trim(coalesce(p_phone, '')), '')
  );

  select coalesce(array_agg(k order by k), array[]::text[])
    into fields
  from jsonb_each(after_profile) as item(k, v)
  where before_profile -> k is distinct from item.v;

  if cardinality(fields) = 0 then
    return jsonb_build_object('changed', false, 'fields', fields);
  end if;

  update public.profiles
  set first_name = after_profile ->> 'first_name',
      middle_name = after_profile ->> 'middle_name',
      last_name = after_profile ->> 'last_name',
      phone = after_profile ->> 'phone'
  where id = p_target_user_id;

  insert into public.schoolpro_profile_change_audit (
    school_id, target_user_id, changed_by, changed_fields, before_values, after_values
  ) values (
    p_school_id, p_target_user_id, p_actor_id, fields, before_profile, after_profile
  );

  return jsonb_build_object('changed', true, 'fields', fields);
end;
$$;

revoke all on function public.schoolpro_correct_member_profile_atomic(uuid, uuid, uuid, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.schoolpro_correct_member_profile_atomic(uuid, uuid, uuid, text, text, text, text)
  to service_role;

commit;
