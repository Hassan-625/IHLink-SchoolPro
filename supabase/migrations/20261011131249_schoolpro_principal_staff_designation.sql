alter table public.schoolpro_members add column if not exists position_title text;
alter table public.schoolpro_members add constraint schoolpro_position_title_valid check(position_title is null or (position_title='Principal' and role='administrator'));
comment on column public.schoolpro_members.position_title is 'School-specific principal designation using administrator authorization; not company administration.';

