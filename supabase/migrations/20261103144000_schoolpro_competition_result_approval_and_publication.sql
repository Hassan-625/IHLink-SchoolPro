-- Stage B6: versioned competition result calculation, approval and publication.
create table public.schoolpro_competition_result_runs (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  event_id uuid not null references public.schoolpro_competition_events(id) on delete cascade,
  version integer not null check (version > 0),
  status text not null default 'calculated' check (status in ('calculated','approved','published','superseded')),
  calculation_method text not null default 'weighted_criterion_average',
  calculated_by uuid not null,
  calculated_at timestamptz not null default now(),
  approved_by uuid,
  approved_at timestamptz,
  published_by uuid,
  published_at timestamptz,
  unique (school_id,id),
  unique (school_id,event_id,version),
  check ((approved_by is null) = (approved_at is null)),
  check ((published_by is null) = (published_at is null))
);
create unique index schoolpro_competition_one_published_run_idx
  on public.schoolpro_competition_result_runs(school_id,event_id)
  where status='published';

create table public.schoolpro_competition_result_entries (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  result_run_id uuid not null references public.schoolpro_competition_result_runs(id) on delete restrict,
  event_id uuid not null references public.schoolpro_competition_events(id) on delete cascade,
  entry_id uuid not null references public.schoolpro_competition_entries(id) on delete restrict,
  house_id uuid references public.schoolpro_houses(id) on delete restrict,
  entry_name text not null,
  is_complete boolean not null,
  score_percent numeric(7,2),
  result_position integer,
  criterion_breakdown jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (result_run_id,entry_id),
  check ((is_complete and score_percent is not null) or (not is_complete and score_percent is null)),
  check (result_position is null or (is_complete and result_position > 0))
);
create index schoolpro_competition_result_entries_event_idx
  on public.schoolpro_competition_result_entries(school_id,event_id,result_run_id,result_position);

alter table public.schoolpro_competition_result_runs enable row level security;
alter table public.schoolpro_competition_result_entries enable row level security;
grant select on public.schoolpro_competition_result_runs,public.schoolpro_competition_result_entries to authenticated;
grant all on public.schoolpro_competition_result_runs,public.schoolpro_competition_result_entries to service_role;
create policy "Games staff read competition result runs"
  on public.schoolpro_competition_result_runs for select to authenticated
  using (private.schoolpro_module_allowed(school_id,'games'));
create policy "Games staff read competition result entries"
  on public.schoolpro_competition_result_entries for select to authenticated
  using (private.schoolpro_module_allowed(school_id,'games'));
create policy "Assigned judges read published event results"
  on public.schoolpro_competition_result_runs for select to authenticated
  using (status='published' and exists(
    select 1 from public.schoolpro_competition_judges j
    join public.schoolpro_members m on m.id=j.member_id and m.school_id=j.school_id
    where j.school_id=schoolpro_competition_result_runs.school_id
      and j.event_id=schoolpro_competition_result_runs.event_id
      and j.ended_at is null and m.user_id=auth.uid()
  ));
create policy "Assigned judges read published result entries"
  on public.schoolpro_competition_result_entries for select to authenticated
  using (exists(
    select 1 from public.schoolpro_competition_result_runs r
    join public.schoolpro_competition_judges j on j.school_id=r.school_id and j.event_id=r.event_id
    join public.schoolpro_members m on m.id=j.member_id and m.school_id=j.school_id
    where r.id=result_run_id and r.status='published'
      and j.ended_at is null and m.user_id=auth.uid()
  ));

create or replace function public.schoolpro_calculate_competition_results(p_school uuid,p_event uuid)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  v_run uuid;
  v_version integer;
  v_criteria integer;
  v_entries integer;
begin
  if auth.uid() is null or not private.schoolpro_module_allowed(p_school,'games') then
    raise exception 'Games module permission required';
  end if;
  perform 1 from public.schoolpro_competition_events
    where id=p_event and school_id=p_school and status in ('scoring','completed') for update;
  if not found then raise exception 'Complete event scoring before calculating results'; end if;
  select count(*) into v_criteria from public.schoolpro_competition_criteria
    where school_id=p_school and event_id=p_event;
  select count(*) into v_entries from public.schoolpro_competition_entries
    where school_id=p_school and event_id=p_event;
  if v_criteria=0 or v_entries=0 then raise exception 'An event needs at least one rubric criterion and one entry'; end if;
  select coalesce(max(version),0)+1 into v_version
    from public.schoolpro_competition_result_runs where school_id=p_school and event_id=p_event;
  insert into public.schoolpro_competition_result_runs(school_id,event_id,version,calculated_by)
    values(p_school,p_event,v_version,auth.uid()) returning id into v_run;

  with criterion_scores as (
    select s.entry_id,s.criterion_id,avg(s.points)::numeric as average_points,
      c.max_points,c.weight,count(*) as judge_count
    from public.schoolpro_competition_scores s
    join public.schoolpro_competition_criteria c
      on c.id=s.criterion_id and c.school_id=s.school_id and c.event_id=s.event_id
    where s.school_id=p_school and s.event_id=p_event
    group by s.entry_id,s.criterion_id,c.max_points,c.weight
  ), per_entry as (
    select e.id as entry_id,e.house_id,e.entry_name,
      count(cs.criterion_id)=v_criteria as is_complete,
      case when count(cs.criterion_id)=v_criteria
        then round((sum((cs.average_points/cs.max_points)*cs.weight)/sum(cs.weight))*100,2)
        else null end as score_percent,
      coalesce(jsonb_object_agg(c.id::text,jsonb_build_object(
        'criterion_name',c.name,'average_points',round(cs.average_points,2),
        'max_points',c.max_points,'weight',c.weight,'judge_count',cs.judge_count
      )) filter(where cs.criterion_id is not null),'{}'::jsonb) as breakdown
    from public.schoolpro_competition_entries e
    cross join public.schoolpro_competition_criteria c
    left join criterion_scores cs on cs.entry_id=e.id and cs.criterion_id=c.id
    where e.school_id=p_school and e.event_id=p_event and c.school_id=p_school and c.event_id=p_event
    group by e.id,e.house_id,e.entry_name
  ), ranked as (
    select pe.*,case when pe.is_complete then rank() over(order by pe.score_percent desc)::integer else null end as position
    from per_entry pe
  )
  insert into public.schoolpro_competition_result_entries(
    school_id,result_run_id,event_id,entry_id,house_id,entry_name,is_complete,score_percent,result_position,criterion_breakdown
  )
  select p_school,v_run,p_event,entry_id,house_id,entry_name,is_complete,score_percent,position,breakdown from ranked;
  return v_run;
end
$$;
revoke all on function public.schoolpro_calculate_competition_results(uuid,uuid) from public,anon;
grant execute on function public.schoolpro_calculate_competition_results(uuid,uuid) to authenticated;

create or replace function public.schoolpro_approve_competition_results(p_school uuid,p_run uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_event uuid;
begin
  if auth.uid() is null or not private.schoolpro_module_allowed(p_school,'games') then
    raise exception 'Games Master or school administrator permission required for result approval';
  end if;
  select event_id into v_event from public.schoolpro_competition_result_runs
    where id=p_run and school_id=p_school and status='calculated' for update;
  if v_event is null then raise exception 'Only a calculated result version can be approved'; end if;
  if exists(select 1 from public.schoolpro_competition_result_entries
    where result_run_id=p_run and school_id=p_school and not is_complete) then
    raise exception 'Every entry must have a score for every rubric criterion before approval';
  end if;
  if not exists(select 1 from public.schoolpro_competition_result_entries
    where result_run_id=p_run and school_id=p_school) then
    raise exception 'Result version has no entries';
  end if;
  update public.schoolpro_competition_result_runs
    set status='approved',approved_by=auth.uid(),approved_at=now()
    where id=p_run and school_id=p_school;
end
$$;
revoke all on function public.schoolpro_approve_competition_results(uuid,uuid) from public,anon;
grant execute on function public.schoolpro_approve_competition_results(uuid,uuid) to authenticated;

create or replace function public.schoolpro_publish_competition_results(p_school uuid,p_run uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_event uuid;
begin
  if auth.uid() is null or not private.schoolpro_module_allowed(p_school,'games') then
    raise exception 'Games Master or school administrator permission required for publication';
  end if;
  select event_id into v_event from public.schoolpro_competition_result_runs
    where id=p_run and school_id=p_school and status='approved' for update;
  if v_event is null then raise exception 'Only an approved result version can be published'; end if;
  perform 1 from public.schoolpro_competition_events
    where id=v_event and school_id=p_school and status='completed' for update;
  if not found then raise exception 'The competition event must be completed before publication'; end if;
  update public.schoolpro_competition_result_runs
    set status='superseded'
    where school_id=p_school and event_id=v_event and status='published';
  update public.schoolpro_competition_result_runs
    set status='published',published_by=auth.uid(),published_at=now()
    where id=p_run and school_id=p_school;
end
$$;
revoke all on function public.schoolpro_publish_competition_results(uuid,uuid) from public,anon;
grant execute on function public.schoolpro_publish_competition_results(uuid,uuid) to authenticated;

-- Competition-linked house points must refer to an entry in the currently published result.
create or replace function public.schoolpro_award_published_competition_points(
  p_school uuid,p_house uuid,p_points numeric,p_reason text,p_event uuid,p_entry uuid
) returns uuid language plpgsql security definer set search_path = ''
as $$
declare v_award uuid;
begin
  if auth.uid() is null or not private.schoolpro_module_allowed(p_school,'games') then
    raise exception 'Games module permission required';
  end if;
  if p_points=0 or nullif(btrim(p_reason),'') is null then
    raise exception 'Enter non-zero points and an award reason';
  end if;
  if not exists(
    select 1 from public.schoolpro_competition_result_runs r
    join public.schoolpro_competition_result_entries re on re.result_run_id=r.id
    where r.school_id=p_school and r.event_id=p_event and r.status='published'
      and re.entry_id=p_entry and re.house_id=p_house and re.is_complete
  ) then raise exception 'House points can only be awarded to an entry in the published competition results'; end if;
  insert into public.schoolpro_house_point_ledger(school_id,house_id,event_id,entry_id,points,reason,awarded_by)
  values(p_school,p_house,p_event,p_entry,p_points,btrim(p_reason),auth.uid()) returning id into v_award;
  return v_award;
end
$$;
revoke all on function public.schoolpro_award_published_competition_points(uuid,uuid,numeric,text,uuid,uuid) from public,anon;
grant execute on function public.schoolpro_award_published_competition_points(uuid,uuid,numeric,text,uuid,uuid) to authenticated;
