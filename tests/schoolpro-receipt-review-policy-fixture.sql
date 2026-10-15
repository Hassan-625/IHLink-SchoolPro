do $$ begin
  if not exists(select 1 from pg_type t join pg_namespace n on n.oid=t.typnamespace where n.nspname='public' and t.typname='school_member_role') then
    create type public.school_member_role as enum ('proprietor','administrator','accountant','bursar','teacher');
  end if;
end $$;
create schema if not exists private;
create or replace function private.schoolpro_module_allowed(target_school uuid, required_permission text)
returns boolean language sql stable as $$
  select required_permission = 'finance'
     and current_setting('test.finance_school', true) = target_school::text
$$;
create or replace function private.has_school_access(target_school uuid, allowed_roles public.school_member_role[])
returns boolean language sql stable as $$
  select current_setting('test.access_school', true) = target_school::text
$$;
grant usage on schema private, storage to authenticated;
grant execute on function private.schoolpro_module_allowed(uuid,text) to authenticated;
grant execute on function private.has_school_access(uuid,public.school_member_role[]) to authenticated;
grant select on storage.objects, public.schoolpro_payment_submissions to authenticated;
alter table storage.objects enable row level security;
