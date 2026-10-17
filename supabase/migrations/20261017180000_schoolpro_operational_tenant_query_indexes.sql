-- Supporting indexes for authenticated tenant-scoped reads of operational modules.
-- Production catalog audit found school_id-leading indexes absent on several tables.
-- In particular schoolpro_result_approvals has ~33k rows and no school_id index; the
-- two-school RLS probe timed out while scanning it. This migration is forward-only.
-- Apply only after review/explicit approval; do not replay the historical policy migration.

CREATE INDEX IF NOT EXISTS schoolpro_library_books_school_id_idx
  ON public.schoolpro_library_books (school_id, id);
CREATE INDEX IF NOT EXISTS schoolpro_transport_routes_school_id_idx
  ON public.schoolpro_transport_routes (school_id, id);
CREATE INDEX IF NOT EXISTS schoolpro_hostel_rooms_school_id_idx
  ON public.schoolpro_hostel_rooms (school_id, id);
CREATE INDEX IF NOT EXISTS schoolpro_inventory_assets_school_id_idx
  ON public.schoolpro_inventory_assets (school_id, id);
CREATE INDEX IF NOT EXISTS schoolpro_result_approvals_school_id_idx
  ON public.schoolpro_result_approvals (school_id, id);
CREATE INDEX IF NOT EXISTS schoolpro_promotions_school_id_idx
  ON public.schoolpro_promotions (school_id, id);

-- calendar_events and lesson_notes already have school_id-leading composite indexes
-- in the live catalog, so avoid adding redundant indexes for those tables.
