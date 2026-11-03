-- Stage B6: tenant-scoped houses, house-master appointments and student house history.
-- All allocation changes are append-only history; current membership is effective_to IS NULL.

create table public.schoolpro_houses (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 60),
  code text not null check (code ~ '^[a-z0-9_-]{1,24}$'),
  color text not null default '#64748B' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  sort_order integer not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id, code),
  unique (school_id, name)
);
create index schoolpro_houses_active_order_idx
  on public.schoolpro_houses(school_id, is_active, sort_order, name);

create table public.schoolpro_house_master_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  house_id uuid not null references public.schoolpro_houses(id) on delete cascade,
  member_id uuid not null references public.schoolpro_members(id) on delete restrict,
  assigned_at timestamptz not null default now(),
  ended_at timestamptz,
  assigned_by uuid,
  check (ended_at is null or ended_at >= assigned_at)
);
create unique index schoolpro_one_active_house_master_per_house
  on public.schoolpro_house_master_assignments(school_id, house_id) where ended_at is null;
create unique index schoolpro_one_active_house_per_master
  on public.schoolpro_house_master_assignments(school_id, member_id) where ended_at is null;
create index schoolpro_house_master_member_idx
  on public.schoolpro_house_master_assignments(school_id, member_id, ended_at);

create table public.schoolpro_student_house_history (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  student_id uuid not null references public.schoolpro_students(id) on delete cascade,
  house_id uuid not null references public.schoolpro_houses(id) on delete restrict,
  assignment_type text not null check (assignment_type in ('automatic','manual')),
  assigned_at timestamptz not null default now(),
  effective_to timestamptz,
  assigned_by uuid,
  reason text,
  check (effective_to is null or effective_to >= assigned_at)
);
create unique index schoolpro_one_current_house_per_student
  on public.schoolpro_student_house_history(school_id, student_id) where effective_to is null;
create index schoolpro_house_history_roster_idx
  on public.schoolpro_student_house_history(school_id, house_id, effective_to, student_id);

alter table public.schoolpro_houses enable row level security;
alter table public.schoolpro_house_master_assignments enable row level security;
alter table public.schoolpro_student_house_history enable row level security;
grant select on public.schoolpro_houses, public.schoolpro_house_master_assignments,
  public.schoolpro_student_house_history to authenticated;
grant all on public.schoolpro_houses, public.schoolpro_house_master_assignments,
  public.schoolpro_student_house_history to service_role;

create or replace function private.schoolpro_is_house_master(p_school uuid, p_house uuid default null)
returns boolean language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.schoolpro_house_master_assignments a
    join public.schoolpro_members m on m.id = a.member_id and m.school_id = a.school_id
    where a.school_id = p_school and a.ended_at is null and m.user_id = auth.uid()
      and (p_house is null or a.house_id = p_house)
      and m.role in ('teacher'::public.school_member_role, 'class_teacher'::public.school_member_role)
  )
$$;
revoke all on function private.schoolpro_is_house_master(uuid,uuid) from public, anon;\ngrant execute on function private.schoolpro_is_house_master(uuid,uuid) to authenticated;

create policy "School games staff and assigned house masters read houses"
on public.schoolpro_houses for select to authenticated
using (private.schoolpro_module_allowed(school_id, 'games')
  or private.schoolpro_is_house_master(school_id, id));
create policy "School games staff read house master assignments"
on public.schoolpro_house_master_assignments for select to authenticated
using (private.schoolpro_module_allowed(school_id, 'games')
  or private.schoolpro_is_house_master(school_id, house_id));
create policy "School staff read student house history"
on public.schoolpro_student_house_history for select to authenticated
using (private.schoolpro_module_allowed(school_id, 'students')
  or private.schoolpro_module_allowed(school_id, 'games')
  or private.schoolpro_is_house_master(school_id, house_id));

create or replace function private.schoolpro_seed_default_houses()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.schoolpro_houses(school_id, name, code, color, sort_order)
  values
    (new.id, 'Red House', 'red', '#DC2626', 10),
    (new.id, 'Green House', 'green', '#16A34A', 20),
    (new.id, 'Blue House', 'blue', '#2563EB', 30),
    (new.id, 'Yellow House', 'yellow', '#EAB308', 40)
  on conflict (school_id, code) do nothing;
  return new;
end
$$;
revoke all on function private.schoolpro_seed_default_houses() from public, anon, authenticated;
create trigger schoolpro_seed_default_houses
after insert on public.schoolpro_schools
for each row execute function private.schoolpro_seed_default_houses();

-- Existing schools receive the same defaults without overwriting school customizations.
insert into public.schoolpro_houses(school_id, name, code, color, sort_order)
select s.id, h.name, h.code, h.color, h.sort_order
from public.schoolpro_schools s
cross join (values
  ('Red House','red','#DC2626',10),
  ('Green House','green','#16A34A',20),
  ('Blue House','blue','#2563EB',30),
  ('Yellow House','yellow','#EAB308',40)
) as h(name,code,color,sort_order)
on conflict (school_id, code) do nothing;

create or replace function private.schoolpro_validate_house_master()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.schoolpro_houses h
    where h.id = new.house_id and h.school_id = new.school_id and h.is_active
  ) then raise exception 'House must be active and belong to the selected school'; end if;
  if not exists (
    select 1 from public.schoolpro_members m
    where m.id = new.member_id and m.school_id = new.school_id
      and m.role in ('teacher'::public.school_member_role, 'class_teacher'::public.school_member_role)
  ) then raise exception 'House Master must be a teaching staff member in the same school'; end if;
  return new;
end
$$;
revoke all on function private.schoolpro_validate_house_master() from public, anon, authenticated;
create trigger schoolpro_validate_house_master
before insert or update of school_id, house_id, member_id
on public.schoolpro_house_master_assignments
for each row execute function private.schoolpro_validate_house_master();

create or replace function private.schoolpro_auto_assign_student_house()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare chosen_house uuid;
begin
  -- Serialize per-school allocation so concurrent admissions cannot overfill the same house.
  perform pg_advisory_xact_lock(hashtextextended(new.school_id::text, 0));
  -- Explicit assignment takes precedence; otherwise balance current active membership.
  if exists (select 1 from public.schoolpro_student_house_history
             where school_id = new.school_id and student_id = new.id and effective_to is null) then
    return new;
  end if;
  select h.id into chosen_house
  from public.schoolpro_houses h
  left join public.schoolpro_student_house_history sh
    on sh.school_id = h.school_id and sh.house_id = h.id and sh.effective_to is null
  left join public.schoolpro_students enrolled
    on enrolled.id = sh.student_id and enrolled.school_id = sh.school_id and enrolled.status = 'active'
  where h.school_id = new.school_id and h.is_active
  group by h.id, h.sort_order, h.name
  order by count(sh.id), h.sort_order, h.name, h.id
  limit 1;
  if chosen_house is not null then
    insert into public.schoolpro_student_house_history
      (school_id, student_id, house_id, assignment_type, reason)
    values (new.school_id, new.id, chosen_house, 'automatic', 'Balanced automatic allocation at enrolment');
  end if;
  return new;
end
$$;
revoke all on function private.schoolpro_auto_assign_student_house() from public, anon, authenticated;
create trigger schoolpro_auto_assign_student_house
after insert on public.schoolpro_students
for each row execute function private.schoolpro_auto_assign_student_house();

create or replace function public.schoolpro_save_house(
  p_school uuid, p_name text, p_code text, p_color text default '#64748B',
  p_sort_order integer default 100, p_house uuid default null, p_is_active boolean default true
) returns uuid language plpgsql security definer set search_path = ''
as $$
declare saved_id uuid;
begin
  if auth.uid() is null or not private.schoolpro_module_allowed(p_school, 'games') then
    raise exception 'Games module permission required';
  end if;
  if nullif(btrim(p_name), '') is null or char_length(btrim(p_name)) > 60
     or lower(btrim(p_code)) !~ '^[a-z0-9_-]{1,24}$'
     or p_color !~ '^#[0-9A-Fa-f]{6}$' then
    raise exception 'Enter a valid house name, code and six-digit colour';
  end if;
  if p_house is null then
    insert into public.schoolpro_houses(school_id,name,code,color,sort_order,is_active)
    values(p_school,btrim(p_name),lower(btrim(p_code)),p_color,p_sort_order,p_is_active)
    returning id into saved_id;
  else
    update public.schoolpro_houses set name=btrim(p_name),code=lower(btrim(p_code)),
      color=p_color,sort_order=p_sort_order,is_active=p_is_active,updated_at=now()
    where id=p_house and school_id=p_school returning id into saved_id;
    if saved_id is null then raise exception 'House not found in this school'; end if;
    if not p_is_active then
      update public.schoolpro_house_master_assignments set ended_at=now()
      where school_id=p_school and house_id=saved_id and ended_at is null;
    end if;
  end if;
  return saved_id;
end
$$;
revoke all on function public.schoolpro_save_house(uuid,text,text,text,integer,uuid,boolean) from public, anon;
grant execute on function public.schoolpro_save_house(uuid,text,text,text,integer,uuid) to authenticated;

create or replace function public.schoolpro_set_house_master(
  p_school uuid, p_house uuid, p_member uuid
) returns void language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null or not private.schoolpro_module_allowed(p_school, 'games') then
    raise exception 'Games module permission required';
  end if;
  if not exists(select 1 from public.schoolpro_houses where id=p_house and school_id=p_school and is_active) then
    raise exception 'Active house not found in this school';
  end if;
  update public.schoolpro_house_master_assignments
    set ended_at=now()
    where school_id=p_school and (house_id=p_house or (p_member is not null and member_id=p_member)) and ended_at is null;
  if p_member is not null then
    insert into public.schoolpro_house_master_assignments(school_id,house_id,member_id,assigned_by)
    values(p_school,p_house,p_member,auth.uid());
  end if;
end
$$;
revoke all on function public.schoolpro_set_house_master(uuid,uuid,uuid) from public, anon;
grant execute on function public.schoolpro_set_house_master(uuid,uuid,uuid) to authenticated;

create or replace function public.schoolpro_assign_student_house(
  p_student uuid, p_house uuid, p_reason text default null
) returns void language plpgsql security definer set search_path = ''
as $$
declare pupil public.schoolpro_students;
begin
  select * into pupil from public.schoolpro_students where id=p_student for update;
  if pupil.id is null or auth.uid() is null
     or not private.schoolpro_module_allowed(pupil.school_id, 'games') then
    raise exception 'Games module permission required for this student';
  end if;
  if not exists(select 1 from public.schoolpro_houses
    where id=p_house and school_id=pupil.school_id and is_active) then
    raise exception 'Select an active house belonging to this school';
  end if;
  if exists(select 1 from public.schoolpro_student_house_history
    where school_id=pupil.school_id and student_id=pupil.id and house_id=p_house and effective_to is null) then
    return;
  end if;
  update public.schoolpro_student_house_history set effective_to=now()
    where school_id=pupil.school_id and student_id=pupil.id and effective_to is null;
  insert into public.schoolpro_student_house_history
    (school_id,student_id,house_id,assignment_type,assigned_by,reason)
  values(pupil.school_id,pupil.id,p_house,'manual',auth.uid(),nullif(btrim(p_reason),''));
end
$$;
revoke all on function public.schoolpro_assign_student_house(uuid,uuid,text) from public, anon;
grant execute on function public.schoolpro_assign_student_house(uuid,uuid,text) to authenticated;

-- A house master who is demoted or moved out of the school loses the active appointment.
create or replace function private.schoolpro_clear_ineligible_house_master()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if old.role in ('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
     and (new.role not in ('teacher'::public.school_member_role,'class_teacher'::public.school_member_role)
       or new.school_id is distinct from old.school_id) then
    update public.schoolpro_house_master_assignments set ended_at=now()
    where member_id=old.id and school_id=old.school_id and ended_at is null;
  end if;
  return new;
end
$$;
revoke all on function private.schoolpro_clear_ineligible_house_master() from public, anon, authenticated;
create trigger schoolpro_clear_ineligible_house_master
after update of role, school_id on public.schoolpro_members
for each row execute function private.schoolpro_clear_ineligible_house_master();
