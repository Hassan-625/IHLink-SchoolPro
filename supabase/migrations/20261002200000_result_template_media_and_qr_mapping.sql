-- Persist result-template media and verification placement used by standalone and Command Center generators.
alter table public.schoolpro_result_templates
  add column if not exists photo_cell text,
  add column if not exists photo_width integer default 90,
  add column if not exists photo_height integer default 110,
  add column if not exists principal_signature_cell text,
  add column if not exists teacher_signature_cell text,
  add column if not exists signature_width integer default 120,
  add column if not exists signature_height integer default 45,
  add column if not exists qr_cell text,
  add column if not exists qr_size integer default 90;
