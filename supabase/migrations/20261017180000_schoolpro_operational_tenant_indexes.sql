-- Query-plan support for operational tenant filters.
-- These indexes are deliberately separate from the RLS/policy migration so the
-- catalog repair can be reviewed and rolled back independently if needed.
-- No rows or policy definitions are changed.

do $migration$
declare
  t text;
  required_tables text[] := array[
    'schoolpro_library_books',
    'schoolpro_transport_routes',
    'schoolpro_hostel_rooms',
    'schoolpro_inventory_assets',
    'schoolpro_result_approvals',
    'schoolpro_promotions'
  ];
begin
  foreach t in array required_tables loop
    if to_regclass(format('public.%I', t)) is null then
      raise exception 'Required SchoolPro operational table public.% is missing; aborting tenant index repair', t;
    end if;
  end loop;
end
$migration$;

create index if not exists schoolpro_library_books_school_id_idx
  on public.schoolpro_library_books (school_id);
create index if not exists schoolpro_transport_routes_school_id_idx
  on public.schoolpro_transport_routes (school_id);
create index if not exists schoolpro_hostel_rooms_school_id_idx
  on public.schoolpro_hostel_rooms (school_id);
create index if not exists schoolpro_inventory_assets_school_id_idx
  on public.schoolpro_inventory_assets (school_id);
create index if not exists schoolpro_result_approvals_school_id_idx
  on public.schoolpro_result_approvals (school_id);
create index if not exists schoolpro_promotions_school_id_idx
  on public.schoolpro_promotions (school_id);
