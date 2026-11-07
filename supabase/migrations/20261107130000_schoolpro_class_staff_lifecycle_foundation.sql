-- Stage C0 foundation: additive lifecycle metadata and audited transitions.
-- This migration is intentionally not the complete lifecycle rollout. Follow-up
-- migrations must update every authorization/operational reader and remove direct
-- DELETE privileges before the UI exposes archive/suspension controls.

alter table public.schoolpro_classes
  add column if not exists archived_at timestamptz,
  add column if not exists archived_by uuid references auth.users(id),
  add column if not exists archive_reason text;

alter table public.schoolpro_members
  add column if not exists status text not null default 'active',
  add column if not exists suspended_at timestamptz,
  add column if not exists suspended_by uuid references auth.users(id),
  add column if not exists suspension_reason text;

alter table public.schoolpro_members
  drop constraint if exists schoolpro_members_status_check;
alter table public.schoolpro_members
  add constraint schoolpro_members_status_check
  check (status in ('active','suspended'));

alter table public.schoolpro_classes
  drop constraint if exists schoolpro_classes_archive_metadata_check;
alter table public.schoolpro_classes
  add constraint schoolpro_classes_archive_metadata_check
  check (
    (archived_at is null and archived_by is null and archive_reason is null)
    or
    (archived_at is not null and archived_by is not null
      and archive_reason is not null and length(btrim(archive_reason)) between 10 and 1000)
  );

alter table public.schoolpro_members
  drop constraint if exists schoolpro_members_suspension_metadata_check;
alter table public.schoolpro_members
  add constraint schoolpro_members_suspension_metadata_check
  check (
    (status = 'active' and suspended_at is null and suspended_by is null and suspension_reason is null)
    or
    (status = 'suspended' and suspended_at is not null and suspended_by is not null
      and suspension_reason is not null and length(btrim(suspension_reason)) between 10 and 1000)
  );

create index if not exists schoolpro_classes_active_school_idx
  on public.schoolpro_classes (school_id, level, name)
  where archived_at is null;
create index if not exists schoolpro_members_active_school_idx
  on public.schoolpro_members (school_id, role, user_id)
  where status = 'active';

create or replace function private.guard_schoolpro_lifecycle_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  -- Authenticated clients must use the audited SECURITY DEFINER transition RPCs.
  -- Those RPCs execute with the function owner as current_user.
  if current_user in ('anon','authenticated') then
    if tg_table_name = 'schoolpro_classes' then
      if tg_op = 'INSERT' then
        if new.archived_at is not null or new.archived_by is not null
           or new.archive_reason is not null then
          raise exception 'Class archive state must be changed through the lifecycle workflow';
        end if;
      elsif new.archived_at is distinct from old.archived_at
         or new.archived_by is distinct from old.archived_by
         or new.archive_reason is distinct from old.archive_reason then
        raise exception 'Class archive state must be changed through the lifecycle workflow';
      end if;
    elsif tg_table_name = 'schoolpro_members' then
      if tg_op = 'INSERT' then
        if new.status <> 'active' or new.suspended_at is not null
           or new.suspended_by is not null or new.suspension_reason is not null then
          raise exception 'Staff suspension state must be changed through the lifecycle workflow';
        end if;
      elsif new.status is distinct from old.status
         or new.suspended_at is distinct from old.suspended_at
         or new.suspended_by is distinct from old.suspended_by
         or new.suspension_reason is distinct from old.suspension_reason then
        raise exception 'Staff suspension state must be changed through the lifecycle workflow';
      end if;
    end if;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function private.guard_schoolpro_lifecycle_columns() from public, anon, authenticated;
drop trigger if exists schoolpro_guard_class_lifecycle_columns on public.schoolpro_classes;
create trigger schoolpro_guard_class_lifecycle_columns
before insert or update on public.schoolpro_classes
for each row execute function private.guard_schoolpro_lifecycle_columns();

drop trigger if exists schoolpro_guard_member_lifecycle_columns on public.schoolpro_members;
create trigger schoolpro_guard_member_lifecycle_columns
before insert or update on public.schoolpro_members
for each row execute function private.guard_schoolpro_lifecycle_columns();

create or replace function private.schoolpro_set_class_archive_state(
  p_school uuid, p_class uuid, p_archived boolean, p_reason text
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.schoolpro_classes;
  clean_reason text := btrim(coalesce(p_reason,''));
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.has_school_access(
       p_school, array['proprietor','administrator']::public.school_member_role[]
     ) then
    raise exception 'Only active school leadership can archive or restore classes';
  end if;
  if length(clean_reason) not between 10 and 1000 then
    raise exception 'Provide a reason between 10 and 1000 characters';
  end if;

  select * into target
  from public.schoolpro_classes
  where id = p_class and school_id = p_school
  for update;
  if target.id is null then
    raise exception 'Class was not found in the selected school';
  end if;

  if coalesce(p_archived,false) then
    if target.archived_at is not null then
      raise exception 'Class is already archived';
    end if;
    update public.schoolpro_classes
      set archived_at = now(), archived_by = auth.uid(),
          archive_reason = clean_reason, updated_at = now()
    where id = target.id and school_id = p_school;
  else
    if target.archived_at is null then
      raise exception 'Class is not archived';
    end if;
    update public.schoolpro_classes
      set archived_at = null, archived_by = null, archive_reason = null,
          updated_at = now()
    where id = target.id and school_id = p_school;
  end if;

  insert into public.schoolpro_audit_logs
    (school_id, actor_id, action, entity_type, entity_id, metadata)
  values
    (p_school, auth.uid(),
     case when p_archived then 'Class archived' else 'Class restored' end,
     'class', target.id::text,
     jsonb_build_object('reason',clean_reason,'class_name',target.name,
       'class_level',target.level,'previous_archived_at',target.archived_at));
end;
$$;

create or replace function private.schoolpro_set_member_suspension_state(
  p_school uuid, p_member uuid, p_suspended boolean, p_reason text
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.schoolpro_members;
  clean_reason text := btrim(coalesce(p_reason,''));
  remaining_proprietors integer;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.has_school_access(
       p_school, array['proprietor','administrator']::public.school_member_role[]
     ) then
    raise exception 'Only active school leadership can suspend or restore staff';
  end if;
  if length(clean_reason) not between 10 and 1000 then
    raise exception 'Provide a reason between 10 and 1000 characters';
  end if;

  select * into target
  from public.schoolpro_members
  where id = p_member and school_id = p_school
  for update;
  if target.id is null then
    raise exception 'Staff membership was not found in the selected school';
  end if;

  if coalesce(p_suspended,false) then
    if target.status = 'suspended' then
      raise exception 'Staff membership is already suspended';
    end if;
    if target.role = 'proprietor'::public.school_member_role then
      select count(*) into remaining_proprietors
      from public.schoolpro_members m
      where m.school_id = p_school and m.role = 'proprietor'::public.school_member_role
        and m.status = 'active' and m.id <> target.id;
      if remaining_proprietors = 0 then
        raise exception 'The final active proprietor cannot be suspended';
      end if;
    end if;
    update public.schoolpro_members
      set status = 'suspended', suspended_at = now(),
          suspended_by = auth.uid(), suspension_reason = clean_reason
    where id = target.id and school_id = p_school;
  else
    if target.status <> 'suspended' then
      raise exception 'Staff membership is not suspended';
    end if;
    update public.schoolpro_members
      set status = 'active', suspended_at = null,
          suspended_by = null, suspension_reason = null
    where id = target.id and school_id = p_school;
  end if;

  insert into public.schoolpro_audit_logs
    (school_id, actor_id, action, entity_type, entity_id, metadata)
  values
    (p_school, auth.uid(),
     case when p_suspended then 'Staff membership suspended' else 'Staff membership restored' end,
     'member', target.id::text,
     jsonb_build_object('reason',clean_reason,'role',target.role::text,
       'user_id',target.user_id,'previous_status',target.status));
end;
$$;

revoke all on function private.schoolpro_set_class_archive_state(uuid,uuid,boolean,text) from public, anon;
revoke all on function private.schoolpro_set_member_suspension_state(uuid,uuid,boolean,text) from public, anon;
grant execute on function private.schoolpro_set_class_archive_state(uuid,uuid,boolean,text) to authenticated;
grant execute on function private.schoolpro_set_member_suspension_state(uuid,uuid,boolean,text) to authenticated;

create or replace function public.schoolpro_set_class_archive_state(
  p_school uuid, p_class uuid, p_archived boolean, p_reason text
) returns void
language sql
security invoker
set search_path = ''
as $$ select private.schoolpro_set_class_archive_state(p_school,p_class,p_archived,p_reason) $$;

create or replace function public.schoolpro_set_member_suspension_state(
  p_school uuid, p_member uuid, p_suspended boolean, p_reason text
) returns void
language sql
security invoker
set search_path = ''
as $$ select private.schoolpro_set_member_suspension_state(p_school,p_member,p_suspended,p_reason) $$;

revoke all on function public.schoolpro_set_class_archive_state(uuid,uuid,boolean,text) from public, anon;
revoke all on function public.schoolpro_set_member_suspension_state(uuid,uuid,boolean,text) from public, anon;
grant execute on function public.schoolpro_set_class_archive_state(uuid,uuid,boolean,text) to authenticated;
grant execute on function public.schoolpro_set_member_suspension_state(uuid,uuid,boolean,text) to authenticated;

comment on column public.schoolpro_classes.archived_at is
  'C0 lifecycle marker; archived classes remain retained for academic history.';
comment on column public.schoolpro_members.status is
  'C0 school-scoped membership lifecycle; suspension does not delete the global profile or Auth user.';
