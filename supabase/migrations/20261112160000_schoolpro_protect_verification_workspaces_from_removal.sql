-- Keep the two explicitly retained SchoolPro verification workspaces outside
-- the proprietor-requested workspace-removal lifecycle.
begin;

create or replace function private.schoolpro_guard_protected_workspace_removal()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.school_id in (
    'eb601205-cffd-420d-97d0-7d5ca081628a'::uuid, -- IHLINK Academy
    'ac7ac8a8-5035-4e39-8868-cad54add84a6'::uuid  -- HA ACADEMY
  ) or (
    tg_op = 'UPDATE'
    and old.school_id in (
      'eb601205-cffd-420d-97d0-7d5ca081628a'::uuid,
      'ac7ac8a8-5035-4e39-8868-cad54add84a6'::uuid
    )
  ) then
    raise exception 'This SchoolPro verification workspace is protected from workspace removal'
      using errcode = '42501';
  end if;

  return new;
end;
$function$;

revoke all on function private.schoolpro_guard_protected_workspace_removal()
  from public, anon, authenticated;

drop trigger if exists schoolpro_protect_verification_workspace_removal
  on public.schoolpro_workspace_deletion_requests;

create trigger schoolpro_protect_verification_workspace_removal
before insert or update of school_id, status
on public.schoolpro_workspace_deletion_requests
for each row
execute function private.schoolpro_guard_protected_workspace_removal();

comment on function private.schoolpro_guard_protected_workspace_removal() is
  'Blocks workspace-removal requests and lifecycle transitions for IHLINK Academy and HA ACADEMY, which are retained verification workspaces.';

commit;
