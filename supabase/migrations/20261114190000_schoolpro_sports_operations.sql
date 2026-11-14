-- SchoolPro Games: tenant-safe sports operations layered on canonical Houses and Competitions.
-- No duplicate house catalogue; all house links target public.schoolpro_houses.

create table public.schoolpro_sports_teams (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 100),
  sport text not null check (char_length(btrim(sport)) between 1 and 80),
  age_group text,
  section_key text,
  house_id uuid references public.schoolpro_houses(id) on delete restrict,
  exclusive_membership boolean not null default true,
  is_active boolean not null default true,
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id)
);
create index schoolpro_sports_teams_school_active_idx on public.schoolpro_sports_teams(school_id,is_active,sport);

create table public.schoolpro_sports_team_coaches (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  team_id uuid not null,
  member_id uuid not null,
  assigned_at timestamptz not null default now(),
  ended_at timestamptz,
  assigned_by uuid,
  ended_by uuid,
  end_reason text,
  check (ended_at is null or ended_at >= assigned_at),
  unique (school_id,id),
  foreign key (school_id,team_id) references public.schoolpro_sports_teams(school_id,id) on delete cascade
);
create unique index schoolpro_sports_one_active_coach_assignment
  on public.schoolpro_sports_team_coaches(school_id,team_id,member_id) where ended_at is null;
create index schoolpro_sports_coach_member_active_idx
  on public.schoolpro_sports_team_coaches(school_id,member_id) where ended_at is null;

create table public.schoolpro_sports_team_members (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  team_id uuid not null,
  student_id uuid not null,
  joined_at timestamptz not null default now(),
  ended_at timestamptz,
  assigned_by uuid,
  end_reason text,
  check (ended_at is null or ended_at >= joined_at),
  unique (school_id,id),
  foreign key (school_id,team_id) references public.schoolpro_sports_teams(school_id,id) on delete cascade
);
create unique index schoolpro_sports_team_member_active_unique
  on public.schoolpro_sports_team_members(school_id,team_id,student_id) where ended_at is null;
create index schoolpro_sports_team_roster_idx
  on public.schoolpro_sports_team_members(school_id,team_id,ended_at);

create table public.schoolpro_sports_training_sessions (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  team_id uuid not null,
  title text not null check (char_length(btrim(title)) between 1 and 140),
  starts_at timestamptz not null,
  ends_at timestamptz,
  venue text,
  details text,
  status text not null default 'scheduled' check (status in ('scheduled','completed','cancelled')),
  recurrence_group_id uuid,
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id),
  foreign key (school_id,team_id) references public.schoolpro_sports_teams(school_id,id) on delete cascade,
  check (ends_at is null or ends_at > starts_at)
);
create index schoolpro_sports_training_calendar_idx
  on public.schoolpro_sports_training_sessions(school_id,starts_at,status);

create table public.schoolpro_sports_fixtures (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  event_id uuid,
  home_entry_id uuid,
  away_entry_id uuid,
  home_team_id uuid not null,
  away_team_id uuid not null,
  scheduled_at timestamptz not null,
  venue text,
  status text not null default 'scheduled' check (status in ('scheduled','in_progress','completed','postponed','cancelled')),
  home_score integer check (home_score is null or home_score >= 0),
  away_score integer check (away_score is null or away_score >= 0),
  result_notes text,
  result_version integer not null default 0 check (result_version >= 0),
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id),
  foreign key (school_id,event_id) references public.schoolpro_competition_events(school_id,id) on delete restrict,
  foreign key (school_id,home_team_id) references public.schoolpro_sports_teams(school_id,id) on delete restrict,
  foreign key (school_id,away_team_id) references public.schoolpro_sports_teams(school_id,id) on delete restrict,
  foreign key (school_id,home_entry_id) references public.schoolpro_competition_entries(school_id,id) on delete restrict,
  foreign key (school_id,away_entry_id) references public.schoolpro_competition_entries(school_id,id) on delete restrict,
  check (home_team_id <> away_team_id),
  check ((event_id is null and home_entry_id is null and away_entry_id is null) or (event_id is not null and home_entry_id is not null and away_entry_id is not null and home_entry_id<>away_entry_id)),
  check ((home_score is null and away_score is null) or (home_score is not null and away_score is not null))
);
create index schoolpro_sports_fixtures_calendar_idx
  on public.schoolpro_sports_fixtures(school_id,scheduled_at,status);

create table public.schoolpro_sports_fixture_result_history (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  fixture_id uuid not null,
  version integer not null,
  home_score integer not null check (home_score >= 0),
  away_score integer not null check (away_score >= 0),
  status text not null,
  result_notes text,
  action text not null check (action in ('recorded','amended')),
  changed_by uuid,
  changed_at timestamptz not null default now(),
  unique (school_id,fixture_id,version),
  foreign key (school_id,fixture_id) references public.schoolpro_sports_fixtures(school_id,id) on delete cascade
);

create table public.schoolpro_sports_fixture_audit (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  fixture_id uuid not null,
  changed_by uuid,
  changed_at timestamptz not null default now(),
  previous_scheduled_at timestamptz,
  new_scheduled_at timestamptz,
  previous_venue text,
  new_venue text,
  previous_status text,
  new_status text,
  foreign key (school_id,fixture_id) references public.schoolpro_sports_fixtures(school_id,id) on delete cascade
);

create or replace function private.schoolpro_sports_can_manage(p_school uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null
    and coalesce(private.is_active_account(),false)
    and private.schoolpro_operationally_active(p_school)
    and (
      private.is_admin(array['super_admin']::public.user_role[])
      or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
      or exists(select 1 from public.schoolpro_members m
        where m.school_id=p_school and m.user_id=auth.uid()
          and m.status='active' and m.employment_status='active'
          and m.role in ('proprietor'::public.school_member_role,'administrator'::public.school_member_role))
      or private.schoolpro_module_allowed(p_school,'games')
    );
$$;

create or replace function private.schoolpro_sports_is_member(p_school uuid,p_member uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and exists(
    select 1 from public.schoolpro_members m
    where m.id=p_member and m.school_id=p_school and m.user_id=auth.uid()
      and m.status='active' and m.employment_status='active'
  );
$$;
revoke all on function private.schoolpro_sports_is_member(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_sports_is_member(uuid,uuid) to authenticated;

create or replace function private.schoolpro_sports_is_coach(p_school uuid,p_team uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and coalesce(private.is_active_account(),false)
    and private.schoolpro_operationally_active(p_school)
    and exists(
      select 1 from public.schoolpro_sports_team_coaches c
      join public.schoolpro_members m on m.id=c.member_id and m.school_id=c.school_id
      where c.school_id=p_school and c.team_id=p_team and c.ended_at is null
        and m.user_id=auth.uid() and m.status='active' and m.employment_status='active'
        and m.role in ('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
    );
$$;

revoke all on function private.schoolpro_sports_can_manage(uuid) from public,anon;
revoke all on function private.schoolpro_sports_is_coach(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_sports_can_manage(uuid) to authenticated;
grant execute on function private.schoolpro_sports_is_coach(uuid,uuid) to authenticated;

create or replace function private.schoolpro_validate_sports_operation_links()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare linked_school uuid; linked_role public.school_member_role; linked_status text; linked_employment text;
begin
  if tg_table_name='schoolpro_sports_teams' then
    if new.house_id is not null and not exists(
      select 1 from public.schoolpro_houses h where h.id=new.house_id and h.school_id=new.school_id
    ) then raise exception 'House must belong to the selected school'; end if;
  elsif tg_table_name='schoolpro_sports_team_coaches' then
    select m.school_id,m.role,m.status,m.employment_status
      into linked_school,linked_role,linked_status,linked_employment
    from public.schoolpro_members m where m.id=new.member_id;
    if linked_school is distinct from new.school_id or (new.ended_at is null and (
      linked_role not in ('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
      or linked_status<>'active' or linked_employment<>'active')) then
      raise exception 'Coach must be active teaching staff in the selected school';
    end if;
    if not exists(select 1 from public.schoolpro_sports_teams t where t.id=new.team_id and t.school_id=new.school_id and t.is_active) then
      raise exception 'Coach team must be active and belong to the selected school';
    end if;
  elsif tg_table_name='schoolpro_sports_team_members' then
    if not exists(select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id and (new.ended_at is not null or s.status='active')) then
      raise exception 'Participant must be an active student in the selected school';
    end if;
    if not exists(select 1 from public.schoolpro_sports_teams t where t.id=new.team_id and t.school_id=new.school_id and t.is_active) then
      raise exception 'Participant team must be active and belong to the selected school';
    end if;
    if new.ended_at is null then
      perform pg_advisory_xact_lock(hashtextextended(new.school_id::text||':'||new.student_id::text,0));
    end if;
    if new.ended_at is null and exists(
      select 1 from public.schoolpro_sports_team_members other
      join public.schoolpro_sports_teams other_team on other_team.id=other.team_id and other_team.school_id=other.school_id
      join public.schoolpro_sports_teams target_team on target_team.id=new.team_id and target_team.school_id=new.school_id
      where other.school_id=new.school_id and other.student_id=new.student_id and other.ended_at is null
        and other.team_id<>new.team_id and (other_team.exclusive_membership or target_team.exclusive_membership)
    ) then raise exception 'Student already belongs to an incompatible active sports squad'; end if;
  elsif tg_table_name='schoolpro_sports_training_sessions' then
    if not exists(select 1 from public.schoolpro_sports_teams t where t.id=new.team_id and t.school_id=new.school_id) then
      raise exception 'Training team must belong to the selected school';
    end if;
  elsif tg_table_name='schoolpro_sports_fixtures' then
    if not exists(select 1 from public.schoolpro_sports_teams t where t.id=new.home_team_id and t.school_id=new.school_id)
      or not exists(select 1 from public.schoolpro_sports_teams t where t.id=new.away_team_id and t.school_id=new.school_id) then
      raise exception 'Both fixture teams must belong to the selected school';
    end if;
    if new.event_id is not null and not exists(
      select 1 from public.schoolpro_competition_events e
      where e.id=new.event_id and e.school_id=new.school_id and e.event_type in ('sports','athletics')
    ) then raise exception 'Linked competition must be a sports or athletics event in the selected school'; end if;
    if new.event_id is not null and (
      not exists(select 1 from public.schoolpro_competition_entries e where e.id=new.home_entry_id and e.school_id=new.school_id and e.event_id=new.event_id)
      or not exists(select 1 from public.schoolpro_competition_entries e where e.id=new.away_entry_id and e.school_id=new.school_id and e.event_id=new.event_id)
    ) then raise exception 'Linked fixture entries must belong to the selected competition and school'; end if;
  end if;
  return new;
end;
$$;
revoke all on function private.schoolpro_validate_sports_operation_links() from public,anon,authenticated;
create trigger schoolpro_sports_team_house_guard before insert or update on public.schoolpro_sports_teams
for each row execute function private.schoolpro_validate_sports_operation_links();

create or replace function private.schoolpro_close_archived_team_assignments()
returns trigger language plpgsql security definer set search_path = ''
as $
begin
  if old.is_active and not new.is_active then
    update public.schoolpro_sports_team_coaches
      set ended_at=now(),ended_by=auth.uid(),end_reason='Team archived'
      where school_id=new.school_id and team_id=new.id and ended_at is null;
    update public.schoolpro_sports_team_members
      set ended_at=now(),end_reason='Team archived'
      where school_id=new.school_id and team_id=new.id and ended_at is null;
  end if;
  return new;
end;
$;
revoke all on function private.schoolpro_close_archived_team_assignments() from public,anon,authenticated;
create trigger schoolpro_sports_close_archived_team_assignments after update of is_active on public.schoolpro_sports_teams
for each row execute function private.schoolpro_close_archived_team_assignments();

create trigger schoolpro_sports_coach_guard before insert or update on public.schoolpro_sports_team_coaches
for each row execute function private.schoolpro_validate_sports_operation_links();
create trigger schoolpro_sports_team_member_guard before insert or update on public.schoolpro_sports_team_members
for each row execute function private.schoolpro_validate_sports_operation_links();
create trigger schoolpro_sports_training_team_guard before insert or update on public.schoolpro_sports_training_sessions
for each row execute function private.schoolpro_validate_sports_operation_links();
create trigger schoolpro_sports_fixture_links_guard before insert or update on public.schoolpro_sports_fixtures
for each row execute function private.schoolpro_validate_sports_operation_links();

create or replace function private.schoolpro_sports_fixture_write_guard()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if (new.home_score is distinct from old.home_score or new.away_score is distinct from old.away_score
      or new.result_notes is distinct from old.result_notes or new.result_version is distinct from old.result_version)
    and current_user <> 'postgres' then
    raise exception 'Fixture results must be recorded through the audited result workflow';
  end if;
  if new.status='completed' and old.status<>'completed' and current_user<>'postgres' then
    raise exception 'Fixture completion must use the audited result workflow';
  end if;
  if new.status='completed' and (new.home_score is null or new.away_score is null) then
    raise exception 'A completed fixture requires both team scores';
  end if;
  if new.status is distinct from old.status then
    if old.status='completed' or not (
      (old.status='scheduled' and new.status in ('in_progress','postponed','cancelled'))
      or (old.status='in_progress' and new.status in ('completed','postponed','cancelled'))
      or (old.status='postponed' and new.status in ('scheduled','cancelled'))
    ) then raise exception 'Invalid fixture status transition'; end if;
  end if;
  return new;
end;
$$;
revoke all on function private.schoolpro_sports_fixture_write_guard() from public,anon,authenticated;
create trigger schoolpro_sports_fixture_write_guard before update on public.schoolpro_sports_fixtures
for each row execute function private.schoolpro_sports_fixture_write_guard();

create or replace function private.schoolpro_audit_sports_fixture_schedule()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.scheduled_at is distinct from new.scheduled_at or old.venue is distinct from new.venue or old.status is distinct from new.status then
    insert into public.schoolpro_sports_fixture_audit(
      school_id,fixture_id,changed_by,previous_scheduled_at,new_scheduled_at,
      previous_venue,new_venue,previous_status,new_status
    ) values (
      old.school_id,old.id,auth.uid(),old.scheduled_at,new.scheduled_at,
      old.venue,new.venue,old.status,new.status
    );
  end if;
  return new;
end;
$$;
revoke all on function private.schoolpro_audit_sports_fixture_schedule() from public,anon,authenticated;
create trigger schoolpro_sports_fixture_schedule_audit after update on public.schoolpro_sports_fixtures
for each row execute function private.schoolpro_audit_sports_fixture_schedule();

create or replace function public.schoolpro_record_sports_fixture_result(
  p_school uuid,p_fixture uuid,p_home_score integer,p_away_score integer,p_notes text default null,p_complete boolean default true
) returns integer language plpgsql security definer set search_path = ''
as $$
declare f public.schoolpro_sports_fixtures; next_status text; next_version integer;
begin
  if auth.uid() is null or not private.schoolpro_sports_can_manage(p_school) then
    raise exception 'Games management permission required';
  end if;
  if p_home_score is null or p_away_score is null or p_home_score<0 or p_away_score<0 then
    raise exception 'Enter non-negative whole-number scores for both teams';
  end if;
  select * into f from public.schoolpro_sports_fixtures
    where id=p_fixture and school_id=p_school for update;
  if not found then raise exception 'Fixture not found in the selected school'; end if;
  if f.status not in ('in_progress','completed') then raise exception 'Start the fixture before recording a result'; end if;
  next_status:=case when p_complete then 'completed' else 'in_progress' end;
  if f.status='completed' and not p_complete then raise exception 'A completed fixture cannot be reopened'; end if;
  next_version:=f.result_version+1;
  update public.schoolpro_sports_fixtures set
    home_score=p_home_score,away_score=p_away_score,result_notes=nullif(btrim(p_notes),''),
    status=next_status,result_version=next_version,updated_at=now()
    where id=p_fixture and school_id=p_school;
  insert into public.schoolpro_sports_fixture_result_history(
    school_id,fixture_id,version,home_score,away_score,status,result_notes,action,changed_by
  ) values (
    p_school,p_fixture,next_version,p_home_score,p_away_score,next_status,nullif(btrim(p_notes),''),
    case when f.result_version=0 then 'recorded' else 'amended' end,auth.uid()
  );
  return next_version;
end;
$$;
revoke all on function public.schoolpro_record_sports_fixture_result(uuid,uuid,integer,integer,text,boolean) from public,anon;
grant execute on function public.schoolpro_record_sports_fixture_result(uuid,uuid,integer,integer,text,boolean) to authenticated;

alter table public.schoolpro_sports_teams enable row level security;
alter table public.schoolpro_sports_team_coaches enable row level security;
alter table public.schoolpro_sports_team_members enable row level security;
alter table public.schoolpro_sports_training_sessions enable row level security;
alter table public.schoolpro_sports_fixtures enable row level security;
alter table public.schoolpro_sports_fixture_result_history enable row level security;
alter table public.schoolpro_sports_fixture_audit enable row level security;

grant select,insert,update,delete on public.schoolpro_sports_teams,public.schoolpro_sports_team_coaches,
  public.schoolpro_sports_team_members,public.schoolpro_sports_training_sessions to authenticated;
grant select,insert,delete on public.schoolpro_sports_fixtures to authenticated;
grant update(scheduled_at,venue,status,updated_at) on public.schoolpro_sports_fixtures to authenticated;
grant select on public.schoolpro_sports_fixture_result_history,public.schoolpro_sports_fixture_audit to authenticated;

create policy schoolpro_sports_teams_read on public.schoolpro_sports_teams for select to authenticated
using (private.schoolpro_sports_can_manage(school_id) or private.schoolpro_sports_is_coach(school_id,id));
create policy schoolpro_sports_teams_manage on public.schoolpro_sports_teams for all to authenticated
using (private.schoolpro_sports_can_manage(school_id)) with check (private.schoolpro_sports_can_manage(school_id));

create policy schoolpro_sports_coaches_read on public.schoolpro_sports_team_coaches for select to authenticated
using (private.schoolpro_sports_can_manage(school_id)
  or private.schoolpro_sports_is_member(schoolpro_sports_team_coaches.school_id,schoolpro_sports_team_coaches.member_id));
create policy schoolpro_sports_coaches_manage on public.schoolpro_sports_team_coaches for all to authenticated
using (private.schoolpro_sports_can_manage(school_id)) with check (private.schoolpro_sports_can_manage(school_id));

create policy schoolpro_sports_team_members_read on public.schoolpro_sports_team_members for select to authenticated
using (private.schoolpro_sports_can_manage(school_id) or private.schoolpro_sports_is_coach(school_id,team_id));
create policy schoolpro_sports_team_members_manage on public.schoolpro_sports_team_members for all to authenticated
using (private.schoolpro_sports_can_manage(school_id)) with check (private.schoolpro_sports_can_manage(school_id));

create policy schoolpro_sports_training_read on public.schoolpro_sports_training_sessions for select to authenticated
using (private.schoolpro_sports_can_manage(school_id) or private.schoolpro_sports_is_coach(school_id,team_id));
create policy schoolpro_sports_training_manage on public.schoolpro_sports_training_sessions for all to authenticated
using (private.schoolpro_sports_can_manage(school_id)) with check (private.schoolpro_sports_can_manage(school_id));

create policy schoolpro_sports_fixtures_read on public.schoolpro_sports_fixtures for select to authenticated
using (private.schoolpro_sports_can_manage(school_id)
  or private.schoolpro_sports_is_coach(school_id,home_team_id)
  or private.schoolpro_sports_is_coach(school_id,away_team_id));
create policy schoolpro_sports_fixtures_manage on public.schoolpro_sports_fixtures for all to authenticated
using (private.schoolpro_sports_can_manage(school_id)) with check (private.schoolpro_sports_can_manage(school_id));

create policy schoolpro_sports_result_history_read on public.schoolpro_sports_fixture_result_history for select to authenticated
using (private.schoolpro_sports_can_manage(school_id) or exists(
  select 1 from public.schoolpro_sports_fixtures f where f.id=schoolpro_sports_fixture_result_history.fixture_id and f.school_id=schoolpro_sports_fixture_result_history.school_id
    and (private.schoolpro_sports_is_coach(schoolpro_sports_fixture_result_history.school_id,f.home_team_id) or private.schoolpro_sports_is_coach(schoolpro_sports_fixture_result_history.school_id,f.away_team_id))
));
create policy schoolpro_sports_fixture_audit_read on public.schoolpro_sports_fixture_audit for select to authenticated
using (private.schoolpro_sports_can_manage(school_id) or exists(
  select 1 from public.schoolpro_sports_fixtures f where f.id=schoolpro_sports_fixture_audit.fixture_id and f.school_id=schoolpro_sports_fixture_audit.school_id
    and (private.schoolpro_sports_is_coach(schoolpro_sports_fixture_audit.school_id,f.home_team_id) or private.schoolpro_sports_is_coach(schoolpro_sports_fixture_audit.school_id,f.away_team_id))
));


-- A coach receives a narrowly scoped roster projection, not general student-table access.
create or replace function public.schoolpro_sports_coach_roster(p_school uuid,p_team uuid)
returns table (
  team_id uuid,student_id uuid,admission_number text,first_name text,middle_name text,
  last_name text,class_name text,class_arm text,joined_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select tm.team_id,st.id,st.admission_number,st.first_name,st.middle_name,st.last_name,
    coalesce(c.name,st.class_name),c.arm,tm.joined_at
  from public.schoolpro_sports_team_members tm
  join public.schoolpro_students st on st.id=tm.student_id and st.school_id=tm.school_id and st.status='active'
  left join public.schoolpro_classes c on c.id=st.class_id and c.school_id=st.school_id
  where tm.school_id=p_school and tm.team_id=p_team and tm.ended_at is null
    and (private.schoolpro_sports_can_manage(p_school) or private.schoolpro_sports_is_coach(p_school,p_team));
$$;
revoke all on function public.schoolpro_sports_coach_roster(uuid,uuid) from public,anon;
grant execute on function public.schoolpro_sports_coach_roster(uuid,uuid) to authenticated;
