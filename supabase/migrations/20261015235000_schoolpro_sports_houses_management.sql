-- SchoolPro sports and houses management (school-scoped).
create table if not exists public.schoolpro_sports_houses (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 80),
  colour text,
  created_at timestamptz not null default now(),
  unique (school_id, name)
);
create table if not exists public.schoolpro_sports_teams (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 100),
  sport text not null check (length(trim(sport)) between 1 and 80),
  house_id uuid references public.schoolpro_sports_houses(id) on delete set null,
  age_group text,
  gender_category text,
  coach_member_id uuid references public.schoolpro_members(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.schoolpro_sports_activities (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  title text not null check (length(trim(title)) between 1 and 140),
  sport text not null check (length(trim(sport)) between 1 and 80),
  activity_type text not null default 'training' check (activity_type in ('training','tryout','house_competition','inter-school','fitness','other')),
  activity_date timestamptz not null,
  venue text,
  details text,
  status text not null default 'scheduled' check (status in ('scheduled','in_progress','completed','cancelled')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.schoolpro_sports_participants (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  activity_id uuid not null references public.schoolpro_sports_activities(id) on delete cascade,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  team_id uuid references public.schoolpro_sports_teams(id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  unique (activity_id, student_id)
);
create table if not exists public.schoolpro_sports_fixtures (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  sport text not null check (length(trim(sport)) between 1 and 80),
  competition text not null check (length(trim(competition)) between 1 and 140),
  home_team_id uuid not null references public.schoolpro_sports_teams(id) on delete restrict,
  away_team_id uuid not null references public.schoolpro_sports_teams(id) on delete restrict,
  scheduled_at timestamptz not null,
  venue text,
  home_score integer check (home_score is null or home_score >= 0),
  away_score integer check (away_score is null or away_score >= 0),
  status text not null default 'scheduled' check (status in ('scheduled','in_progress','completed','postponed','cancelled')),
  result_notes text,
  created_at timestamptz not null default now(),
  check (home_team_id <> away_team_id)
);
create index if not exists schoolpro_sports_teams_school_idx on public.schoolpro_sports_teams(school_id);
create index if not exists schoolpro_sports_activities_school_date_idx on public.schoolpro_sports_activities(school_id, activity_date);
create index if not exists schoolpro_sports_participants_school_activity_idx on public.schoolpro_sports_participants(school_id, activity_id);
create index if not exists schoolpro_sports_fixtures_school_date_idx on public.schoolpro_sports_fixtures(school_id, scheduled_at);
alter table public.schoolpro_sports_houses enable row level security;
alter table public.schoolpro_sports_teams enable row level security;
alter table public.schoolpro_sports_activities enable row level security;
alter table public.schoolpro_sports_participants enable row level security;
alter table public.schoolpro_sports_fixtures enable row level security;
drop policy if exists schoolpro_sports_houses_access on public.schoolpro_sports_houses;
create policy schoolpro_sports_houses_access on public.schoolpro_sports_houses for all to authenticated
using (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]))
with check (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]));
drop policy if exists schoolpro_sports_teams_access on public.schoolpro_sports_teams;
create policy schoolpro_sports_teams_access on public.schoolpro_sports_teams for all to authenticated
using (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]))
with check (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]));
drop policy if exists schoolpro_sports_activities_access on public.schoolpro_sports_activities;
create policy schoolpro_sports_activities_access on public.schoolpro_sports_activities for all to authenticated
using (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]))
with check (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]));
drop policy if exists schoolpro_sports_participants_access on public.schoolpro_sports_participants;
create policy schoolpro_sports_participants_access on public.schoolpro_sports_participants for all to authenticated
using (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]))
with check (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]));
drop policy if exists schoolpro_sports_fixtures_access on public.schoolpro_sports_fixtures;
create policy schoolpro_sports_fixtures_access on public.schoolpro_sports_fixtures for all to authenticated
using (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]))
with check (private.schoolpro_module_allowed(school_id, 'calendar') and private.has_school_access(school_id, array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'vice_principal'::public.school_member_role,'head_teacher'::public.school_member_role,'game_master'::public.school_member_role]));
