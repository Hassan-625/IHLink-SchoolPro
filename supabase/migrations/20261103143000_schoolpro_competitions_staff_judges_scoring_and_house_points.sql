-- Stage B6: configurable competitions, staff judging panels, rubric scoring and house points.
create table public.schoolpro_competition_events (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 120),
  event_type text not null check (event_type in ('sports','athletics','debate','quiz','cultural','academic','custom')),
  description text,
  academic_session text,
  term text,
  rules jsonb not null default '{}'::jsonb,
  eligibility jsonb not null default '{}'::jsonb,
  judging_guidelines text,
  status text not null default 'draft' check (status in ('draft','open','scoring','completed','cancelled')),
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id),
  check (ends_at is null or starts_at is null or ends_at >= starts_at)
);
create index schoolpro_competition_events_school_status_idx
  on public.schoolpro_competition_events(school_id,status,starts_at);

create table public.schoolpro_competition_criteria (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  event_id uuid not null references public.schoolpro_competition_events(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 100),
  description text,
  max_points numeric(9,2) not null check (max_points > 0),
  weight numeric(9,3) not null default 1 check (weight > 0),
  sort_order integer not null default 100,
  created_at timestamptz not null default now(),
  unique (school_id,id)
);
create index schoolpro_competition_criteria_event_idx on public.schoolpro_competition_criteria(school_id,event_id,sort_order);

create table public.schoolpro_competition_entries (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  event_id uuid not null references public.schoolpro_competition_events(id) on delete cascade,
  house_id uuid references public.schoolpro_houses(id) on delete restrict,
  entry_name text not null check (char_length(btrim(entry_name)) between 1 and 140),
  participant_details jsonb not null default '{}'::jsonb,
  result_position integer check (result_position is null or result_position > 0),
  created_at timestamptz not null default now(),
  unique (school_id,id),
  unique (event_id,house_id,entry_name)
);
create index schoolpro_competition_entries_event_idx on public.schoolpro_competition_entries(school_id,event_id);

create table public.schoolpro_competition_judges (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  event_id uuid not null references public.schoolpro_competition_events(id) on delete cascade,
  member_id uuid not null references public.schoolpro_members(id) on delete restrict,
  panel_role text not null default 'judge' check (panel_role in ('chief_judge','judge','timekeeper','referee','moderator')),
  assigned_at timestamptz not null default now(),
  ended_at timestamptz,
  assigned_by uuid,
  check (ended_at is null or ended_at >= assigned_at),
  unique (school_id,id)
);
create unique index schoolpro_competition_one_active_judge_idx
  on public.schoolpro_competition_judges(event_id,member_id) where ended_at is null;
create index schoolpro_competition_judges_panel_idx
  on public.schoolpro_competition_judges(school_id,event_id,ended_at);

create table public.schoolpro_competition_scores (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  event_id uuid not null references public.schoolpro_competition_events(id) on delete cascade,
  entry_id uuid not null references public.schoolpro_competition_entries(id) on delete cascade,
  criterion_id uuid not null references public.schoolpro_competition_criteria(id) on delete cascade,
  judge_assignment_id uuid not null references public.schoolpro_competition_judges(id) on delete restrict,
  points numeric(9,2) not null check (points >= 0),
  comments text,
  scored_at timestamptz not null default now(),
  unique (entry_id,criterion_id,judge_assignment_id)
);
create index schoolpro_competition_scores_entry_idx on public.schoolpro_competition_scores(school_id,event_id,entry_id);

create table public.schoolpro_house_point_ledger (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  house_id uuid not null references public.schoolpro_houses(id) on delete restrict,
  event_id uuid references public.schoolpro_competition_events(id) on delete set null,
  entry_id uuid references public.schoolpro_competition_entries(id) on delete set null,
  points numeric(10,2) not null check (points <> 0),
  reason text not null check (char_length(btrim(reason)) between 1 and 240),
  awarded_by uuid,
  awarded_at timestamptz not null default now()
);
create index schoolpro_house_point_ledger_standings_idx
  on public.schoolpro_house_point_ledger(school_id,house_id,awarded_at);

-- Enforce tenant consistency on every cross-table relationship, regardless of client/RLS.
create or replace function private.schoolpro_validate_competition_tenant_links()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if tg_table_name = 'schoolpro_competition_criteria' then
    if not exists(select 1 from public.schoolpro_competition_events e where e.id=new.event_id and e.school_id=new.school_id) then
      raise exception 'Competition event must belong to the same school';
    end if;
  elsif tg_table_name = 'schoolpro_competition_entries' then
    if not exists(select 1 from public.schoolpro_competition_events e where e.id=new.event_id and e.school_id=new.school_id) then
      raise exception 'Competition event must belong to the same school';
    end if;
    if new.house_id is not null and not exists(select 1 from public.schoolpro_houses h where h.id=new.house_id and h.school_id=new.school_id) then
      raise exception 'Entry house must belong to the same school';
    end if;
  elsif tg_table_name = 'schoolpro_competition_judges' then
    if not exists(select 1 from public.schoolpro_competition_events e where e.id=new.event_id and e.school_id=new.school_id)
       or not exists(select 1 from public.schoolpro_members m where m.id=new.member_id and m.school_id=new.school_id) then
      raise exception 'Judge and event must belong to the same school';
    end if;
  elsif tg_table_name = 'schoolpro_competition_scores' then
    if not exists(select 1 from public.schoolpro_competition_events e where e.id=new.event_id and e.school_id=new.school_id)
       or not exists(select 1 from public.schoolpro_competition_entries x where x.id=new.entry_id and x.event_id=new.event_id and x.school_id=new.school_id)
       or not exists(select 1 from public.schoolpro_competition_criteria c where c.id=new.criterion_id and c.event_id=new.event_id and c.school_id=new.school_id and new.points <= c.max_points)
       or not exists(select 1 from public.schoolpro_competition_judges j where j.id=new.judge_assignment_id and j.event_id=new.event_id and j.school_id=new.school_id and j.ended_at is null) then
      raise exception 'Score must reference this event, its entry and rubric, and an active assigned judge; points cannot exceed criterion maximum';
    end if;
  elsif tg_table_name = 'schoolpro_house_point_ledger' then
    if not exists(select 1 from public.schoolpro_houses h where h.id=new.house_id and h.school_id=new.school_id) then
      raise exception 'Award house must belong to the same school';
    end if;
    if new.event_id is not null and not exists(select 1 from public.schoolpro_competition_events e where e.id=new.event_id and e.school_id=new.school_id) then
      raise exception 'Award event must belong to the same school';
    end if;
    if new.entry_id is not null and not exists(select 1 from public.schoolpro_competition_entries x where x.id=new.entry_id and x.school_id=new.school_id and x.event_id=new.event_id) then
      raise exception 'Award entry must belong to the same event and school';
    end if;
  end if;
  return new;
end
$$;
revoke all on function private.schoolpro_validate_competition_tenant_links() from public, anon, authenticated;
create trigger schoolpro_competition_criteria_tenant_guard before insert or update on public.schoolpro_competition_criteria for each row execute function private.schoolpro_validate_competition_tenant_links();
create trigger schoolpro_competition_entries_tenant_guard before insert or update on public.schoolpro_competition_entries for each row execute function private.schoolpro_validate_competition_tenant_links();
create trigger schoolpro_competition_judges_tenant_guard before insert or update on public.schoolpro_competition_judges for each row execute function private.schoolpro_validate_competition_tenant_links();
create trigger schoolpro_competition_scores_tenant_guard before insert or update on public.schoolpro_competition_scores for each row execute function private.schoolpro_validate_competition_tenant_links();
create trigger schoolpro_house_point_ledger_tenant_guard before insert or update on public.schoolpro_house_point_ledger for each row execute function private.schoolpro_validate_competition_tenant_links();

alter table public.schoolpro_competition_events enable row level security;
alter table public.schoolpro_competition_criteria enable row level security;
alter table public.schoolpro_competition_entries enable row level security;
alter table public.schoolpro_competition_judges enable row level security;
alter table public.schoolpro_competition_scores enable row level security;
alter table public.schoolpro_house_point_ledger enable row level security;
grant select on public.schoolpro_competition_events,public.schoolpro_competition_criteria,public.schoolpro_competition_entries,
  public.schoolpro_competition_judges,public.schoolpro_competition_scores,public.schoolpro_house_point_ledger to authenticated;
grant all on public.schoolpro_competition_events,public.schoolpro_competition_criteria,public.schoolpro_competition_entries,
  public.schoolpro_competition_judges,public.schoolpro_competition_scores,public.schoolpro_house_point_ledger to service_role;
grant insert,update,delete on public.schoolpro_competition_events,public.schoolpro_competition_criteria,public.schoolpro_competition_entries to authenticated;

create policy "Games staff read competitions" on public.schoolpro_competition_events for select to authenticated using (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff manage competitions" on public.schoolpro_competition_events for all to authenticated using (private.schoolpro_module_allowed(school_id,'games')) with check (private.schoolpro_module_allowed(school_id,'games'));
create policy "Assigned judges read their event" on public.schoolpro_competition_events for select to authenticated
using (exists(select 1 from public.schoolpro_competition_judges j join public.schoolpro_members m on m.id=j.member_id
  where j.event_id=public.schoolpro_competition_events.id and j.school_id=public.schoolpro_competition_events.school_id
    and j.ended_at is null and m.user_id=auth.uid()));
create policy "Games staff read competition criteria" on public.schoolpro_competition_criteria for select to authenticated using (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff manage competition criteria" on public.schoolpro_competition_criteria for all to authenticated using (private.schoolpro_module_allowed(school_id,'games')) with check (private.schoolpro_module_allowed(school_id,'games'));
create policy "Assigned judges read event criteria" on public.schoolpro_competition_criteria for select to authenticated
using (exists(select 1 from public.schoolpro_competition_judges j join public.schoolpro_members m on m.id=j.member_id
  where j.event_id=public.schoolpro_competition_criteria.event_id and j.school_id=public.schoolpro_competition_criteria.school_id
    and j.ended_at is null and m.user_id=auth.uid()));
create policy "Games staff read competition entries" on public.schoolpro_competition_entries for select to authenticated using (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff manage competition entries" on public.schoolpro_competition_entries for all to authenticated using (private.schoolpro_module_allowed(school_id,'games')) with check (private.schoolpro_module_allowed(school_id,'games'));
create policy "Assigned judges read event entries" on public.schoolpro_competition_entries for select to authenticated
using (exists(select 1 from public.schoolpro_competition_judges j join public.schoolpro_members m on m.id=j.member_id
  where j.event_id=public.schoolpro_competition_entries.event_id and j.school_id=public.schoolpro_competition_entries.school_id
    and j.ended_at is null and m.user_id=auth.uid()));
create policy "Assigned staff read own judge assignments" on public.schoolpro_competition_judges for select to authenticated
using (exists(select 1 from public.schoolpro_members m where m.id=member_id and m.school_id=school_id and m.user_id=auth.uid()));
create policy "Games staff read competition judges" on public.schoolpro_competition_judges for select to authenticated using (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff manage competition judges" on public.schoolpro_competition_judges for all to authenticated using (private.schoolpro_module_allowed(school_id,'games')) with check (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff read competition scores" on public.schoolpro_competition_scores for select to authenticated using (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff manage competition scores" on public.schoolpro_competition_scores for all to authenticated using (private.schoolpro_module_allowed(school_id,'games')) with check (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff read house points" on public.schoolpro_house_point_ledger for select to authenticated using (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff award house points" on public.schoolpro_house_point_ledger for insert to authenticated with check (private.schoolpro_module_allowed(school_id,'games'));

-- Judges may submit only their own scores for an event to which they are actively assigned.
create policy "Assigned judges read own competition scores" on public.schoolpro_competition_scores for select to authenticated
using (exists(select 1 from public.schoolpro_competition_judges j join public.schoolpro_members m on m.id=j.member_id
  where j.id=judge_assignment_id and j.school_id=public.schoolpro_competition_scores.school_id and j.ended_at is null and m.user_id=auth.uid()));
create policy "Assigned judges submit own competition scores" on public.schoolpro_competition_scores for insert to authenticated
with check (exists(select 1 from public.schoolpro_competition_judges j join public.schoolpro_members m on m.id=j.member_id
  where j.id=judge_assignment_id and j.school_id=public.schoolpro_competition_scores.school_id and j.ended_at is null and m.user_id=auth.uid()));

create or replace function public.schoolpro_assign_competition_judge(
  p_school uuid,p_event uuid,p_member uuid,p_panel_role text default 'judge'
) returns uuid language plpgsql security definer set search_path = ''
as $$
declare assignment_id uuid;
begin
  if auth.uid() is null or not private.schoolpro_module_allowed(p_school,'games') then raise exception 'Games module permission required'; end if;
  if p_panel_role not in ('chief_judge','judge','timekeeper','referee','moderator') then raise exception 'Invalid judging panel role'; end if;
  if not exists(select 1 from public.schoolpro_competition_events where id=p_event and school_id=p_school and status not in ('completed','cancelled'))
     or not exists(select 1 from public.schoolpro_members where id=p_member and school_id=p_school) then
    raise exception 'Select an active event and staff member from this school';
  end if;
  insert into public.schoolpro_competition_judges(school_id,event_id,member_id,panel_role,assigned_by)
  values(p_school,p_event,p_member,p_panel_role,auth.uid())
  on conflict do nothing returning id into assignment_id;
  if assignment_id is null then
    select id into assignment_id from public.schoolpro_competition_judges
    where event_id=p_event and member_id=p_member and ended_at is null;
    if assignment_id is not null then
      update public.schoolpro_competition_judges set panel_role=p_panel_role where id=assignment_id;
    end if;
  end if;
  return assignment_id;
end
$$;
revoke all on function public.schoolpro_assign_competition_judge(uuid,uuid,uuid,text) from public,anon;
grant execute on function public.schoolpro_assign_competition_judge(uuid,uuid,uuid,text) to authenticated;

create or replace function public.schoolpro_record_competition_score(
  p_school uuid,p_event uuid,p_entry uuid,p_criterion uuid,p_points numeric,p_comments text default null
) returns uuid language plpgsql security definer set search_path = ''
as $$
declare judge_id uuid; score_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select j.id into judge_id from public.schoolpro_competition_judges j
  join public.schoolpro_members m on m.id=j.member_id and m.school_id=j.school_id
  where j.school_id=p_school and j.event_id=p_event and j.ended_at is null and m.user_id=auth.uid()
    and j.panel_role in ('chief_judge','judge','referee','moderator')
  order by case j.panel_role when 'chief_judge' then 0 else 1 end limit 1;
  if judge_id is null and not private.schoolpro_module_allowed(p_school,'games') then raise exception 'You are not assigned as a judge for this event'; end if;
  if judge_id is null then raise exception 'Assign a judge record to score through the judging panel'; end if;
  if not exists(select 1 from public.schoolpro_competition_events where id=p_event and school_id=p_school and status in ('open','scoring')) then
    raise exception 'Competition is not accepting scores';
  end if;
  insert into public.schoolpro_competition_scores(school_id,event_id,entry_id,criterion_id,judge_assignment_id,points,comments)
  values(p_school,p_event,p_entry,p_criterion,judge_id,p_points,p_comments)
  on conflict(entry_id,criterion_id,judge_assignment_id) do update set points=excluded.points,comments=excluded.comments,scored_at=now()
  returning id into score_id;
  return score_id;
end
$$;
revoke all on function public.schoolpro_record_competition_score(uuid,uuid,uuid,uuid,numeric,text) from public,anon;
grant execute on function public.schoolpro_record_competition_score(uuid,uuid,uuid,uuid,numeric,text) to authenticated;

create or replace function public.schoolpro_award_house_points(
  p_school uuid,p_house uuid,p_points numeric,p_reason text,p_event uuid default null,p_entry uuid default null
) returns uuid language plpgsql security definer set search_path = ''
as $$
declare award_id uuid;
begin
  if auth.uid() is null or not private.schoolpro_module_allowed(p_school,'games') then raise exception 'Games module permission required'; end if;
  if p_points=0 or nullif(btrim(p_reason),'') is null then raise exception 'Enter non-zero points and an award reason'; end if;
  insert into public.schoolpro_house_point_ledger(school_id,house_id,event_id,entry_id,points,reason,awarded_by)
  values(p_school,p_house,p_event,p_entry,p_points,btrim(p_reason),auth.uid()) returning id into award_id;
  return award_id;
end
$$;
revoke all on function public.schoolpro_award_house_points(uuid,uuid,numeric,text,uuid,uuid) from public,anon;
grant execute on function public.schoolpro_award_house_points(uuid,uuid,numeric,text,uuid,uuid) to authenticated;

create or replace view public.schoolpro_house_competition_standings
with (security_invoker=true) as
select h.school_id,h.id as house_id,h.name as house_name,h.color,
  coalesce(sum(l.points),0)::numeric(12,2) as total_points,
  count(distinct l.event_id) filter (where l.event_id is not null) as events_scored
from public.schoolpro_houses h
left join public.schoolpro_house_point_ledger l on l.school_id=h.school_id and l.house_id=h.id
where h.is_active
group by h.school_id,h.id,h.name,h.color;
grant select on public.schoolpro_house_competition_standings to authenticated;
