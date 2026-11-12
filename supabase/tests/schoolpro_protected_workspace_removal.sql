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
