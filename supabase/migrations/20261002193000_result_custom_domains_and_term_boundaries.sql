-- Persist live SchoolPro result designer extensions.
alter table public.schoolpro_result_domain_definitions drop constraint if exists schoolpro_result_domain_definitions_domain_type_check;
alter table public.schoolpro_result_domain_definitions add constraint schoolpro_result_domain_definitions_domain_type_check check (domain_type ~ '^[a-z][a-z0-9_]{0,49}$');
alter table public.schoolpro_result_rating_scale drop constraint if exists schoolpro_result_rating_scale_rating_check;
alter table public.schoolpro_result_rating_scale add constraint schoolpro_result_rating_scale_rating_check check (rating between 1 and 10);
alter table public.schoolpro_result_term_settings add column if not exists term_start_date date, add column if not exists term_end_date date;
alter table public.schoolpro_result_term_settings drop constraint if exists schoolpro_result_term_dates_valid;
alter table public.schoolpro_result_term_settings add constraint schoolpro_result_term_dates_valid check (term_start_date is null or term_end_date is null or term_end_date >= term_start_date);
