-- Forward-only operational tenant-isolation posture repair.
-- Preserve the live feature-specific policies: the historical 20261002234500 migration
-- drops/replaces them and would remove current family-library and calendar access semantics.
-- This migration changes only RLS flags; relational integrity is enforced by the separately
-- tested 20261016160000_schoolpro_repair_operational_tenant_integrity.sql migration.
--
-- FORCE ROW LEVEL SECURITY is defense in depth for non-BYPASSRLS table owners. It does NOT
-- constrain superusers or roles with BYPASSRLS (including the service role); never expose
-- privileged credentials to browser/mobile clients.

do $migration$
declare
  t text;
  required_tables text[] := array[
    'schoolpro_library_books',
    'schoolpro_transport_routes',
    'schoolpro_hostel_rooms',
    'schoolpro_inventory_assets',
    'schoolpro_calendar_events',
    'schoolpro_lesson_notes',
    'schoolpro_result_approvals',
    'schoolpro_promotions'
  ];
begin
  foreach t in array required_tables loop
    if to_regclass(format('public.%I', t)) is null then
      raise exception 'Required SchoolPro operational table public.% is missing; aborting tenant-isolation repair', t;
    end if;
  end loop;

  foreach t in array required_tables loop
    execute format('alter table public.%I enable row level security', t);
    execute format('alter table public.%I force row level security', t);
  end loop;
end
$migration$;
