-- Optional, self-declared staff profile gender used only to suggest a section-head display title.
-- It is not an authorization attribute and never changes roles or appointments.
alter table public.profiles
  add column if not exists gender text
  check (gender is null or gender in ('male','female','unspecified'));

comment on column public.profiles.gender is
  'Optional self-declared gender. Used only for a suggested Headmaster/Headmistress display title; never for authorization.';
