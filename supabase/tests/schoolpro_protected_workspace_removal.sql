-- The protected-workspace guard must be installed in the C0 lifecycle schema.
do $$
declare
  trigger_count integer;
  definition text;
begin
  select count(*) into trigger_count
  from pg_trigger t
  join pg_class c on c.oid=t.tgrelid
  join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public'
    and c.relname='schoolpro_workspace_deletion_requests'
    and t.tgname='schoolpro_protect_verification_workspace_removal'
    and not t.tgisinternal;

  if trigger_count <> 1 then
    raise exception 'Expected exactly one protected-workspace removal trigger; found %', trigger_count;
  end if;

  select pg_get_functiondef(p.oid) into definition
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private'
    and p.proname='schoolpro_guard_protected_workspace_removal';

  if definition is null
     or position('eb601205-cffd-420d-97d0-7d5ca081628a' in definition)=0
     or position('ac7ac8a8-5035-4e39-8868-cad54add84a6' in definition)=0
     or position('old.school_id' in lower(definition))=0
     or position('new.school_id' in lower(definition))=0 then
    raise exception 'Protected-workspace trigger does not guard both workspace IDs on insert and update';
  end if;
end;
$$;


-- Exercise the trigger function itself against insert, reassignment, and
-- non-protected rows. A temporary probe table avoids touching tenant data.
begin;
create temporary table protected_workspace_guard_probe (
  school_id uuid not null
);
create trigger protected_workspace_guard_probe_trigger
before insert or update of school_id
on protected_workspace_guard_probe
for each row
execute function private.schoolpro_guard_protected_workspace_removal();

do $$
declare
  blocked boolean;
begin
  -- Non-protected workspaces remain eligible for the lifecycle.
  insert into protected_workspace_guard_probe(school_id)
  values ('11111111-1111-4111-8111-111111111111'::uuid);

  blocked := false;
  begin
    insert into protected_workspace_guard_probe(school_id)
    values ('eb601205-cffd-420d-97d0-7d5ca081628a'::uuid);
  exception when insufficient_privilege then
    blocked := true;
  end;
  if not blocked then
    raise exception 'Protected IHLINK Academy insert was not blocked';
  end if;

  blocked := false;
  begin
    update protected_workspace_guard_probe
       set school_id='ac7ac8a8-5035-4e39-8868-cad54add84a6'::uuid
     where school_id='11111111-1111-4111-8111-111111111111'::uuid;
  exception when insufficient_privilege then
    blocked := true;
  end;
  if not blocked then
    raise exception 'Reassignment to protected HA ACADEMY was not blocked';
  end if;

  -- Simulate a legacy protected request that predates the guard, then prove
  -- that it cannot be reassigned out of the protected set.
  alter table protected_workspace_guard_probe disable trigger protected_workspace_guard_probe_trigger;
  insert into protected_workspace_guard_probe(school_id)
  values ('eb601205-cffd-420d-97d0-7d5ca081628a'::uuid);
  alter table protected_workspace_guard_probe enable trigger protected_workspace_guard_probe_trigger;

  blocked := false;
  begin
    update protected_workspace_guard_probe
       set school_id='11111111-1111-4111-8111-111111111111'::uuid
     where school_id='eb601205-cffd-420d-97d0-7d5ca081628a'::uuid;
  exception when insufficient_privilege then
    blocked := true;
  end;
  if not blocked then
    raise exception 'Reassignment away from a legacy protected request was not blocked';
  end if;
end;
$$;
rollback;
