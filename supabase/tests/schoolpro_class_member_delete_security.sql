-- Stage C0 SQL security regression: class/member direct deletion must be impossible.
-- Run against a disposable database after the lifecycle + DELETE-closure migrations.
begin;

do $test$
declare
  v_table text;
  v_role text;
  v_delete_policy_count integer;
  v_all_policy_count integer;
begin
  foreach v_table in array array['schoolpro_classes','schoolpro_members'] loop
    if has_table_privilege('anon','public.'||v_table,'DELETE')
       or has_table_privilege('authenticated','public.'||v_table,'DELETE') then
      raise exception 'Direct DELETE privilege remains on public.%',v_table;
    end if;
    if has_table_privilege('anon','public.'||v_table,'TRUNCATE')
       or has_table_privilege('authenticated','public.'||v_table,'TRUNCATE') then
      raise exception 'Direct TRUNCATE privilege remains on public.%',v_table;
    end if;

    select count(*) into v_delete_policy_count
    from pg_policy p join pg_class c on c.oid=p.polrelid
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname=v_table and p.polcmd='d';
    if v_delete_policy_count<>0 then
      raise exception 'DELETE RLS policy remains on public.%',v_table;
    end if;

    select count(*) into v_all_policy_count
    from pg_policy p join pg_class c on c.oid=p.polrelid
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname=v_table and p.polcmd='*';
    if v_all_policy_count<>0 then
      raise exception 'Broad ALL RLS policy remains on public.%',v_table;
    end if;

    foreach v_role in array array['anon','authenticated'] loop
      if v_role='anon' and has_table_privilege(v_role,'public.'||v_table,'DELETE') then
        raise exception 'anon can DELETE public.%',v_table;
      elsif v_role='authenticated' and has_table_privilege(v_role,'public.'||v_table,'DELETE') then
        raise exception 'authenticated can DELETE public.%',v_table;
      end if;
    end loop;
  end loop;

  -- Explicit Super Admin operation policies must exist for both tables.
  if (select count(*) from pg_policy p join pg_class c on c.oid=p.polrelid
      join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public' and c.relname in ('schoolpro_classes','schoolpro_members')
        and p.polname like 'Super admin % schoolpro_%') <> 6 then
    raise exception 'Expected six explicit Super Admin SELECT/INSERT/UPDATE policies';
  end if;
end
$test$;

rollback;
