
create table public.schoolpro_assessment_schemes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null,
  school_level text not null default 'nursery_primary' check (school_level in ('nursery_primary','secondary','custom')),
  components jsonb not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id, name)
);
create index schoolpro_assessment_schemes_school_idx on public.schoolpro_assessment_schemes (school_id, is_default desc);
alter table public.schoolpro_assessment_schemes enable row level security;
create policy "School users read assessment schemes" on public.schoolpro_assessment_schemes for select to authenticated using (private.has_school_access(school_id));
create policy "School leaders insert assessment schemes" on public.schoolpro_assessment_schemes for insert to authenticated with check (private.has_school_access(school_id, array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders update assessment schemes" on public.schoolpro_assessment_schemes for update to authenticated using (private.has_school_access(school_id, array['proprietor','administrator']::public.school_member_role[])) with check (private.has_school_access(school_id, array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders delete assessment schemes" on public.schoolpro_assessment_schemes for delete to authenticated using (private.has_school_access(school_id, array['proprietor','administrator']::public.school_member_role[]));
grant select, insert, update, delete on public.schoolpro_assessment_schemes to authenticated;

create or replace function private.validate_assessment_scheme()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare component jsonb; score_total numeric := 0; component_keys text[] := '{}';
begin
  if jsonb_typeof(new.components) <> 'array' or jsonb_array_length(new.components) = 0 then raise exception 'Assessment components must be a non-empty list'; end if;
  for component in select value from jsonb_array_elements(new.components) loop
    if coalesce(component->>'key','') = '' or coalesce(component->>'label','') = '' or jsonb_typeof(component->'maxScore') <> 'number' then raise exception 'Every component needs a key, label and numeric maximum score'; end if;
    if (component->>'key') = any(component_keys) then raise exception 'Assessment component keys must be unique'; end if;
    if (component->>'maxScore')::numeric <= 0 then raise exception 'Assessment weights must be greater than zero'; end if;
    component_keys := array_append(component_keys, component->>'key');
    score_total := score_total + (component->>'maxScore')::numeric;
  end loop;
  if score_total <> 100 then raise exception 'Assessment weights must total 100%%'; end if;
  if new.is_default then update public.schoolpro_assessment_schemes set is_default = false where school_id = new.school_id and id <> new.id and is_default; end if;
  new.updated_at := now();
  return new;
end; $$;
revoke all on function private.validate_assessment_scheme() from public, anon, authenticated;
create trigger validate_schoolpro_assessment_scheme before insert or update on public.schoolpro_assessment_schemes for each row execute procedure private.validate_assessment_scheme();

create or replace function private.create_default_school_assessment_scheme()
returns trigger language plpgsql security definer set search_path = ''
as $$ begin
  insert into public.schoolpro_assessment_schemes (school_id,name,school_level,components,is_default) values
  (new.id,'Nursery & Primary Standard','nursery_primary','[{"key":"assignment_1","label":"1st CA Assignment","maxScore":10},{"key":"assignment_2","label":"2nd CA Assignment","maxScore":10},{"key":"test_1","label":"1st CA Test","maxScore":10},{"key":"test_2","label":"2nd CA Test","maxScore":10},{"key":"exam","label":"Examination","maxScore":60}]'::jsonb,true);
  return new;
end; $$;
revoke all on function private.create_default_school_assessment_scheme() from public, anon, authenticated;
create trigger create_default_school_assessment_scheme after insert on public.schoolpro_schools for each row execute procedure private.create_default_school_assessment_scheme();

insert into public.schoolpro_assessment_schemes (school_id,name,school_level,components,is_default)
select id,'Nursery & Primary Standard','nursery_primary','[{"key":"assignment_1","label":"1st CA Assignment","maxScore":10},{"key":"assignment_2","label":"2nd CA Assignment","maxScore":10},{"key":"test_1","label":"1st CA Test","maxScore":10},{"key":"test_2","label":"2nd CA Test","maxScore":10},{"key":"exam","label":"Examination","maxScore":60}]'::jsonb,true
from public.schoolpro_schools on conflict (school_id,name) do nothing;

alter table public.schoolpro_results alter column total_score drop expression;
alter table public.schoolpro_results add column assessment_scheme_id uuid references public.schoolpro_assessment_schemes(id) on delete restrict;
alter table public.schoolpro_results add column assessment_scores jsonb not null default '{}'::jsonb;
update public.schoolpro_results r set
  assessment_scheme_id = s.id,
  assessment_scores = jsonb_build_object('assignment_1',r.ca_score,'assignment_2',0,'test_1',0,'test_2',0,'exam',r.exam_score)
from public.schoolpro_assessment_schemes s where s.school_id = r.school_id and s.is_default;
alter table public.schoolpro_results add constraint schoolpro_results_total_score_check check (total_score between 0 and 100);

create or replace function private.calculate_result_total()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare scheme record; component jsonb; component_key text; max_score numeric; entered_score numeric; calculated numeric := 0;
begin
  if new.assessment_scheme_id is null then return new; end if;
  select school_id,components into scheme from public.schoolpro_assessment_schemes where id = new.assessment_scheme_id;
  if scheme.school_id is null or scheme.school_id <> new.school_id then raise exception 'Assessment scheme does not belong to this school'; end if;
  for component in select value from jsonb_array_elements(scheme.components) loop
    component_key := component->>'key'; max_score := (component->>'maxScore')::numeric;
    entered_score := coalesce((new.assessment_scores->>component_key)::numeric,0);
    if entered_score < 0 or entered_score > max_score then raise exception '% must be between 0 and %', component->>'label', max_score; end if;
    calculated := calculated + entered_score;
  end loop;
  new.total_score := calculated;
  return new;
end; $$;
revoke all on function private.calculate_result_total() from public, anon, authenticated;
create trigger calculate_schoolpro_result_total before insert or update of assessment_scheme_id, assessment_scores on public.schoolpro_results for each row execute procedure private.calculate_result_total();

create or replace function private.enforce_result_workflow()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.status = 'published' and (new.ca_score <> old.ca_score or new.exam_score <> old.exam_score or new.assessment_scores is distinct from old.assessment_scores or new.assessment_scheme_id is distinct from old.assessment_scheme_id) then
    raise exception 'Published results are locked';
  end if;
  if new.status is distinct from old.status and not private.has_school_access(new.school_id, array['proprietor','administrator']::public.school_member_role[]) then
    raise exception 'Only school leaders can approve or publish results';
  end if;
  if new.status = 'approved' and old.status <> 'approved' then new.approved_by := auth.uid(); new.approved_at := now(); end if;
  if new.status = 'published' and old.status <> 'published' then new.published_at := now(); end if;
  return new;
end;
$$;

