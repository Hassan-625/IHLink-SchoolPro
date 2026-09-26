alter table public.schoolpro_result_templates
  add column if not exists custom_fields jsonb not null default '[]'::jsonb,
  add column if not exists logo_storage_path text,
  add column if not exists logo_cell text not null default 'A1',
  add column if not exists logo_width integer not null default 120,
  add column if not exists logo_height integer not null default 80;

comment on column public.schoolpro_result_templates.custom_fields is 'Repeatable custom workbook cell mappings configured by each school.';
comment on column public.schoolpro_result_templates.logo_storage_path is 'Optional school logo stored in the private school-result-templates bucket.';
