-- Class / term / session result-template assignment selected by the Form Master.
-- Snapshot the workbook and canonical subject-row mapping for reproducible output.

-- Preserve every existing subject ID. Promote only unambiguous legacy names into
-- the canonical catalogue; ambiguous legacy duplicates remain untouched.
alter table public.schoolpro_subjects
  add column if not exists is_catalogue_entry boolean not null default false;

with normalized as (
  select id,school_id,
    lower(regexp_replace(btrim(name), '\s+', ' ', 'g')) as subject_key,
    count(*) over (partition by school_id,lower(regexp_replace(btrim(name), '\s+', ' ', 'g'))) as copies
  from public.schoolpro_subjects
)
update public.schoolpro_subjects s
set is_catalogue_entry=true
from normalized n
where n.id=s.id and n.copies=1;

create unique index if not exists schoolpro_subjects_canonical_name_uidx
  on public.schoolpro_subjects(school_id,lower(regexp_replace(btrim(name), '\s+', ' ', 'g')))
  where is_catalogue_entry;

create or replace function private.schoolpro_guard_canonical_subject_name()
returns trigger language plpgsql security definer set search_path=''
as $fn$
begin
  if tg_op='INSERT' then
    perform pg_advisory_xact_lock(hashtextextended(new.school_id::text,0));
  elsif tg_op='UPDATE'
    and old.is_catalogue_entry=false and new.is_catalogue_entry=true
    and new.school_id is not distinct from old.school_id
    and new.name is not distinct from old.name then
    -- An administrator may explicitly choose one historical duplicate as the
    -- canonical record. Other legacy rows remain intact and retain their IDs.
    perform pg_advisory_xact_lock(hashtextextended(new.school_id::text,0));
    if exists(
      select 1 from public.schoolpro_subjects existing
      where existing.school_id=new.school_id and existing.id is distinct from new.id
        and existing.is_catalogue_entry
        and lower(regexp_replace(btrim(existing.name), '\s+', ' ', 'g'))
          = lower(regexp_replace(btrim(new.name), '\s+', ' ', 'g'))
    ) then
      raise exception 'A canonical subject with this name already exists. Choose that existing catalogue record';
    end if;
    return new;
  elsif new.school_id is distinct from old.school_id
     or new.name is distinct from old.name then
    perform pg_advisory_xact_lock(hashtextextended(new.school_id::text,0));
  else
    return new;
  end if;
  if exists(
    select 1 from public.schoolpro_subjects existing
    where existing.school_id=new.school_id
      and existing.id is distinct from new.id
      and lower(regexp_replace(btrim(existing.name), '\s+', ' ', 'g'))
        = lower(regexp_replace(btrim(new.name), '\s+', ' ', 'g'))
  ) then
    raise exception 'A subject with this name already exists in the school catalogue. Select the existing subject instead of creating a duplicate';
  end if;
  return new;
end;
$fn$;
revoke all on function private.schoolpro_guard_canonical_subject_name() from public,anon,authenticated;
drop trigger if exists schoolpro_guard_canonical_subject_name on public.schoolpro_subjects;
create trigger schoolpro_guard_canonical_subject_name
before insert or update of school_id,name,is_catalogue_entry
on public.schoolpro_subjects
for each row execute function private.schoolpro_guard_canonical_subject_name();



create table public.schoolpro_class_subject_selection_audit (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  class_id uuid not null,
  subject_id uuid not null,
  assignment_id uuid not null,
  session text not null,
  selected_by uuid not null,
  selected_at timestamptz not null default now()
);
create index schoolpro_class_subject_selection_audit_scope_idx
  on public.schoolpro_class_subject_selection_audit(school_id,class_id,session,selected_at desc);
alter table public.schoolpro_class_subject_selection_audit enable row level security;
create policy schoolpro_class_subject_selection_audit_read
  on public.schoolpro_class_subject_selection_audit for select to authenticated
  using (private.has_school_access(school_id));
revoke all on public.schoolpro_class_subject_selection_audit from public,anon,authenticated;
grant select on public.schoolpro_class_subject_selection_audit to authenticated;

-- A Form Master may add an existing canonical school subject to their own
-- assigned class/session. They cannot create or rename catalogue entries.
create or replace function public.schoolpro_form_master_add_class_subject(
  p_school uuid,p_class uuid,p_subject uuid,p_session text
) returns uuid
language plpgsql security definer set search_path=''
as $fn$
declare
  v_member uuid;
  v_assignment uuid;
begin
  if auth.uid() is null or not private.is_active_account()
     or char_length(trim(coalesce(p_session,''))) not between 4 and 20 then
    raise exception 'An active account and valid academic session are required';
  end if;
  select m.id into v_member
  from public.schoolpro_members m
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
  limit 1;
  if v_member is null or not exists(
    select 1 from public.schoolpro_classes c
    where c.school_id=p_school and c.id=p_class and c.archived_at is null
      and c.form_teacher_id=v_member
  ) then
    raise exception 'Only the Form Master assigned to this class can select its subjects';
  end if;
  if not exists(
    select 1 from public.schoolpro_subjects s
    where s.school_id=p_school and s.id=p_subject and s.is_catalogue_entry
  ) then
    raise exception 'Select an existing canonical subject from this school catalogue';
  end if;
  insert into public.schoolpro_subject_assignments(
    school_id,class_id,subject_id,teacher_member_id,session
  ) values (p_school,p_class,p_subject,null,trim(p_session))
  on conflict(class_id,subject_id,session) do nothing
  returning id into v_assignment;
  if v_assignment is null then
    select a.id into v_assignment from public.schoolpro_subject_assignments a
    where a.school_id=p_school and a.class_id=p_class and a.subject_id=p_subject
      and a.session=trim(p_session);
  else
    insert into public.schoolpro_class_subject_selection_audit(
      school_id,class_id,subject_id,assignment_id,session,selected_by
    ) values (p_school,p_class,p_subject,v_assignment,trim(p_session),auth.uid());
  end if;
  return v_assignment;
end;
$fn$;
revoke all on function public.schoolpro_form_master_add_class_subject(uuid,uuid,uuid,text) from public,anon;
grant execute on function public.schoolpro_form_master_add_class_subject(uuid,uuid,uuid,text) to authenticated;

-- All new class allocations must reference a canonical school-catalogue subject.
-- Existing historical allocations remain untouched and keep their subject IDs.
create or replace function private.schoolpro_guard_class_subject_catalogue()
returns trigger language plpgsql security definer set search_path=''
as $fn$
begin
  if not exists(
    select 1 from public.schoolpro_subjects s
    where s.school_id=new.school_id and s.id=new.subject_id
      and s.is_catalogue_entry
  ) then
    raise exception 'Class subject allocations must use an existing canonical subject from this school catalogue';
  end if;
  return new;
end;
$fn$;
revoke all on function private.schoolpro_guard_class_subject_catalogue() from public,anon,authenticated;
drop trigger if exists schoolpro_guard_class_subject_catalogue on public.schoolpro_subject_assignments;
create trigger schoolpro_guard_class_subject_catalogue
before insert or update of school_id,subject_id
on public.schoolpro_subject_assignments
for each row execute function private.schoolpro_guard_class_subject_catalogue();

create table public.schoolpro_result_template_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  term text not null check (term in ('First Term','Second Term','Third Term')),
  session text not null check (char_length(trim(session)) between 4 and 20),
  template_name text not null check (char_length(trim(template_name)) between 1 and 120),
  template_config jsonb not null check (jsonb_typeof(template_config)='object'),
  subject_row_mappings jsonb not null default '{}'::jsonb check (jsonb_typeof(subject_row_mappings)='object'),
  updated_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,class_id,term,session)
);
create index schoolpro_result_template_assignments_lookup_idx
  on public.schoolpro_result_template_assignments(school_id,class_id,session,term);
alter table public.schoolpro_result_template_assignments enable row level security;
create policy schoolpro_result_template_assignments_school_read
  on public.schoolpro_result_template_assignments for select to authenticated
  using (private.has_school_access(school_id));
grant select on public.schoolpro_result_template_assignments to authenticated;
revoke insert,update,delete on public.schoolpro_result_template_assignments from anon,authenticated;

create table public.schoolpro_result_template_assignment_audit (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null,
  class_id uuid not null,
  term text not null,
  session text not null,
  action text not null check (action in ('assigned','reassigned')),
  previous_template_name text,
  new_template_name text not null,
  changed_by uuid not null,
  changed_at timestamptz not null default now(),
  previous_subject_row_mappings jsonb not null default '{}'::jsonb,
  new_subject_row_mappings jsonb not null default '{}'::jsonb
);
create index schoolpro_result_template_assignment_audit_lookup_idx
  on public.schoolpro_result_template_assignment_audit(school_id,class_id,session,term,changed_at desc);
alter table public.schoolpro_result_template_assignment_audit enable row level security;
create policy schoolpro_result_template_assignment_audit_school_read
  on public.schoolpro_result_template_assignment_audit for select to authenticated
  using (private.has_school_access(school_id));
grant select on public.schoolpro_result_template_assignment_audit to authenticated;
revoke insert,update,delete on public.schoolpro_result_template_assignment_audit from anon,authenticated;

create or replace function public.schoolpro_set_class_result_template(
  p_school uuid,p_class uuid,p_term text,p_session text,p_template_config jsonb,p_subject_row_mappings jsonb
) returns uuid
language plpgsql security definer set search_path=''
as $$
declare
  v_member uuid;
  v_old_name text;
  v_new_name text;
  v_assignment uuid;
  v_is_form_master boolean := false;
  v_old_subject_rows jsonb;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'An active signed-in account is required';
  end if;
  if p_term not in ('First Term','Second Term','Third Term')
     or char_length(trim(coalesce(p_session,''))) not between 4 and 20 then
    raise exception 'Choose a valid term and academic session';
  end if;
  if jsonb_typeof(p_template_config) <> 'object'
     or nullif(trim(p_template_config->>'name'),'') is null
     or nullif(trim(p_template_config->>'storage_path'),'') is null
     or nullif(trim(p_template_config->>'sheet_name'),'') is null
     or (p_template_config->>'storage_path') not like p_school::text||'/%'
     or position('..' in p_template_config->>'storage_path')>0
     or octet_length(p_template_config::text)>100000 then
    raise exception 'Choose a saved result workbook belonging to this school';
  end if;
  if not exists(
    select 1 from storage.objects o
    where o.bucket_id='school-result-templates'
      and o.name=p_template_config->>'storage_path'
  ) then
    raise exception 'The selected result workbook is no longer available in this school';
  end if;
  if nullif(p_template_config->>'logo_storage_path','') is not null and (
    (p_template_config->>'logo_storage_path') not like p_school::text||'/%'
    or position('..' in p_template_config->>'logo_storage_path')>0
    or not exists(select 1 from storage.objects o
      where o.bucket_id='school-result-templates'
        and o.name=p_template_config->>'logo_storage_path')
  ) then
    raise exception 'The selected school logo is not available in this school';
  end if;

  if not exists(
    select 1 from public.schoolpro_classes c
    where c.school_id=p_school and c.id=p_class and c.archived_at is null
  ) then
    raise exception 'Choose an active class in the selected school';
  end if;

  select m.id into v_member
  from public.schoolpro_members m
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
  limit 1;

  select exists(
    select 1 from public.schoolpro_classes c
    where c.school_id=p_school and c.id=p_class
      and c.archived_at is null and c.form_teacher_id=v_member
  ) into v_is_form_master;

  if not (v_is_form_master or private.schoolpro_is_school_admin(p_school)) then
    raise exception 'Only this class Form Master or an authorized school administrator can assign its result design';
  end if;

  select template_name,subject_row_mappings into v_old_name,v_old_subject_rows
  from public.schoolpro_result_template_assignments
  where school_id=p_school and class_id=p_class
    and term=trim(p_term) and session=trim(p_session)
  for update;

  v_new_name:=left(trim(v_template_config->>'name'),120);
  insert into public.schoolpro_result_template_assignments(
    school_id,class_id,term,session,template_name,template_config,subject_row_mappings,updated_by
  ) values (
    p_school,p_class,trim(p_term),trim(p_session),v_new_name,p_template_config,p_subject_row_mappings,auth.uid()
  )
  on conflict(school_id,class_id,term,session) do update
    set template_name=excluded.template_name,
        template_config=excluded.template_config,
        subject_row_mappings=excluded.subject_row_mappings,
        updated_by=excluded.updated_by,
        updated_at=now()
  returning id into v_assignment;

  insert into public.schoolpro_result_template_assignment_audit(
    school_id,class_id,term,session,action,previous_template_name,new_template_name,changed_by,
    previous_subject_row_mappings,new_subject_row_mappings
  ) values (
    p_school,p_class,trim(p_term),trim(p_session),
    case when v_old_name is null then 'assigned' else 'reassigned' end,
    v_old_name,v_new_name,auth.uid(),coalesce(v_old_subject_rows,'{}'::jsonb),p_subject_row_mappings
  );
  return v_assignment;
end;
$$;
revoke all on function public.schoolpro_set_class_result_template(uuid,uuid,text,text,jsonb,jsonb) from public,anon;
grant execute on function public.schoolpro_set_class_result_template(uuid,uuid,text,text,jsonb,jsonb) to authenticated;


-- A school owns a library of independently configured workbooks. The legacy
-- one-row schoolpro_result_templates record remains the inbuilt/sample design;
-- it is not the production source when a school has mapped custom templates.
create table public.schoolpro_result_template_library (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 120),
  storage_path text not null,
  sheet_name text not null,
  template_config jsonb not null check (jsonb_typeof(template_config)='object'),
  is_active boolean not null default true,
  created_by uuid not null references public.profiles(id),
  updated_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (school_id,id),
  unique (school_id,storage_path),
  check (storage_path like school_id::text||'/%'),
  check (position('..' in storage_path)=0),
  check (octet_length(template_config::text)<=100000)
);
create index schoolpro_result_template_library_school_idx
  on public.schoolpro_result_template_library(school_id,is_active,updated_at desc);
alter table public.schoolpro_result_template_library enable row level security;
create policy schoolpro_result_template_library_read
  on public.schoolpro_result_template_library for select to authenticated
  using (private.has_school_access(school_id));
create policy schoolpro_result_template_library_insert
  on public.schoolpro_result_template_library for insert to authenticated
  with check (private.is_active_account() and private.schoolpro_is_school_admin(school_id) and created_by=(select auth.uid()) and updated_by=(select auth.uid()));
create policy schoolpro_result_template_library_update
  on public.schoolpro_result_template_library for update to authenticated
  using (private.is_active_account() and private.schoolpro_is_school_admin(school_id))
  with check (private.is_active_account() and private.schoolpro_is_school_admin(school_id) and updated_by=(select auth.uid()));
create policy schoolpro_result_template_library_delete
  on public.schoolpro_result_template_library for delete to authenticated
  using (private.is_active_account() and private.schoolpro_is_school_admin(school_id));
grant select,insert,update,delete on public.schoolpro_result_template_library to authenticated;

create table public.schoolpro_result_template_section_mappings (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  template_id uuid not null,
  section_key text not null check (section_key in ('nursery','primary','junior_secondary','senior_secondary')),
  mapped_by uuid not null references public.profiles(id),
  mapped_at timestamptz not null default now(),
  unique (school_id,template_id,section_key),
  foreign key (school_id,template_id)
    references public.schoolpro_result_template_library(school_id,id) on delete cascade
);
create index schoolpro_result_template_section_mappings_section_idx
  on public.schoolpro_result_template_section_mappings(school_id,section_key);
alter table public.schoolpro_result_template_section_mappings enable row level security;
create policy schoolpro_result_template_section_mappings_read
  on public.schoolpro_result_template_section_mappings for select to authenticated
  using (private.has_school_access(school_id));
create policy schoolpro_result_template_section_mappings_insert
  on public.schoolpro_result_template_section_mappings for insert to authenticated
  with check (private.is_active_account() and private.schoolpro_is_school_admin(school_id) and mapped_by=(select auth.uid()));
create policy schoolpro_result_template_section_mappings_delete
  on public.schoolpro_result_template_section_mappings for delete to authenticated
  using (private.schoolpro_is_school_admin(school_id));
grant select,insert,delete on public.schoolpro_result_template_section_mappings to authenticated;

alter table public.schoolpro_result_template_assignments
  add column template_id uuid not null;
alter table public.schoolpro_result_template_assignments
  add constraint schoolpro_result_template_assignments_library_fk
  foreign key (school_id,template_id)
  references public.schoolpro_result_template_library(school_id,id);

-- Keep the workbook snapshot for reproducible historical output, but require
-- that it originates from a custom template mapped to this class's section.
create or replace function public.schoolpro_set_class_result_template(
  p_school uuid,p_class uuid,p_term text,p_session text,p_template_config jsonb,p_subject_row_mappings jsonb
) returns uuid
language plpgsql security definer set search_path=''
as $$
declare
  v_member uuid;
  v_old_name text;
  v_new_name text;
  v_assignment uuid;
  v_is_form_master boolean := false;
  v_template_id uuid;
  v_template_config jsonb;
  v_section text;
  v_old_subject_rows jsonb;
  v_subject_key text;
  v_subject_row text;
  v_mapping_count integer;
  v_assignment_count integer;
begin
  if auth.uid() is null or not private.is_active_account() then
    raise exception 'An active signed-in account is required';
  end if;
  if p_term not in ('First Term','Second Term','Third Term')
     or char_length(trim(coalesce(p_session,''))) not between 4 and 20 then
    raise exception 'Choose a valid term and academic session';
  end if;
  if jsonb_typeof(p_template_config) <> 'object'
     or nullif(trim(p_template_config->>'name'),'') is null
     or nullif(trim(p_template_config->>'storage_path'),'') is null
     or nullif(trim(p_template_config->>'sheet_name'),'') is null
     or (p_template_config->>'storage_path') not like p_school::text||'/%'
     or position('..' in p_template_config->>'storage_path')>0
     or octet_length(p_template_config::text)>100000 then
    raise exception 'Choose a saved custom result workbook belonging to this school';
  end if;

  if not exists(select 1 from storage.objects o
    where o.bucket_id='school-result-templates'
      and o.name=p_template_config->>'storage_path') then
    raise exception 'The selected result workbook is no longer available in this school';
  end if;
  if nullif(p_template_config->>'logo_storage_path','') is not null and (
    (p_template_config->>'logo_storage_path') not like p_school::text||'/%'
    or position('..' in p_template_config->>'logo_storage_path')>0
    or not exists(select 1 from storage.objects o where o.bucket_id='school-result-templates'
      and o.name=p_template_config->>'logo_storage_path')
  ) then
    raise exception 'The selected school logo is not available in this school';
  end if;

  select case
    when lower(regexp_replace(c.level,'[^a-z0-9]+','_','g')) ~ '(^|_)(nursery|kindergarten|preprimary|pre_primary|kg)(_|$)' then 'nursery'
    when lower(regexp_replace(c.level,'[^a-z0-9]+','_','g')) ~ '(^|_)(junior_secondary|junior|jss)(_|$)' then 'junior_secondary'
    when lower(regexp_replace(c.level,'[^a-z0-9]+','_','g')) ~ '(^|_)(senior_secondary|senior|sss)(_|$)' then 'senior_secondary'
    when lower(regexp_replace(c.level,'[^a-z0-9]+','_','g')) ~ '(^|_)(primary|basic)(_|$)' then 'primary'
    else null end
  into v_section
  from public.schoolpro_classes c
  where c.school_id=p_school and c.id=p_class and c.archived_at is null;
  if v_section is null then
    raise exception 'Choose an active class in a supported school section';
  end if;

  select l.id into v_template_id
  from public.schoolpro_result_template_library l
  join public.schoolpro_result_template_section_mappings sm
    on sm.school_id=l.school_id and sm.template_id=l.id
  where l.school_id=p_school and l.is_active
    and l.storage_path=p_template_config->>'storage_path'
    and l.template_config->>'storage_path'=l.storage_path
    and sm.section_key=v_section
  limit 1;
  if v_template_id is null then
    raise exception 'This custom template has not been mapped to the selected class section';
  end if;
  select l.template_config into v_template_config
  from public.schoolpro_result_template_library l
  where l.school_id=p_school and l.id=v_template_id and l.is_active;
  if v_template_config is null
     or coalesce(v_template_config->>'start_row','') !~ '^[1-9][0-9]{0,4}     or v_template_config->>'storage_path' not like p_school::text||'/%'
     or position('..' in v_template_config->>'storage_path')>0 then
    raise exception 'The selected custom result template is no longer available';
  end if;
  if nullif(v_template_config->>'logo_storage_path','') is not null and (
    v_template_config->>'logo_storage_path' not like p_school::text||'/%'
    or position('..' in v_template_config->>'logo_storage_path')>0
    or not exists(select 1 from storage.objects o
      where o.bucket_id='school-result-templates'
        and o.name=v_template_config->>'logo_storage_path')
  ) then
    raise exception 'The selected custom result template has an unavailable school logo';
  end if;

  select m.id into v_member
  from public.schoolpro_members m
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
  limit 1;
  select exists(select 1 from public.schoolpro_classes c
    where c.school_id=p_school and c.id=p_class and c.archived_at is null
      and c.form_teacher_id=v_member) into v_is_form_master;
  if not (v_is_form_master or private.schoolpro_is_school_admin(p_school)) then
    raise exception 'Only this class Form Master or an authorized school administrator can assign its result design';
  end if;

  if jsonb_typeof(p_subject_row_mappings)<>'object'
     or octet_length(p_subject_row_mappings::text)>50000 then
    raise exception 'Map each assigned class subject to one workbook row before saving';
  end if;
  for v_subject_key,v_subject_row in select key,value from jsonb_each_text(p_subject_row_mappings)
  loop
    if v_subject_key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       or v_subject_row !~ '^[1-9][0-9]{0,4}$' then
      raise exception 'Subject mappings must use valid catalogue subject IDs and positive worksheet row numbers';
    end if;
    if v_subject_row::integer>10000 then
      raise exception 'Subject worksheet rows must be between 1 and 10000';
    end if;
    if v_subject_row::integer < (v_template_config->>'start_row')::integer then
      raise exception 'Subject rows cannot overwrite the workbook heading or student-detail area; use the configured subject start row or a later row';
    end if;
  end loop;
  select count(*) into v_assignment_count
  from public.schoolpro_subject_assignments a
  where a.school_id=p_school and a.class_id=p_class and a.session=trim(p_session);
  select count(*) into v_mapping_count from jsonb_each(p_subject_row_mappings);
  if v_assignment_count=0 or v_assignment_count<>v_mapping_count then
    raise exception 'Every subject allocated to this class and session must be mapped exactly once';
  end if;
  if exists(
    select 1 from public.schoolpro_subject_assignments a
    join public.schoolpro_subjects s on s.id=a.subject_id and s.school_id=a.school_id
    where a.school_id=p_school and a.class_id=p_class and a.session=trim(p_session)
      and not s.is_catalogue_entry
  ) then
    raise exception 'This class still has a legacy subject allocation outside the canonical school catalogue. Ask the school administrator to resolve it before mapping results';
  end if;
  if exists(
    select 1 from public.schoolpro_subject_assignments a
    where a.school_id=p_school and a.class_id=p_class and a.session=trim(p_session)
      and not (p_subject_row_mappings ? a.subject_id::text)
  ) then
    raise exception 'One or more allocated class subjects have no workbook row mapping';
  end if;
  if exists(
    select 1 from (
      select value::integer as row_number from jsonb_each_text(p_subject_row_mappings)
    ) rows group by row_number having count(*)>1
  ) then
    raise exception 'Two subjects cannot be mapped to the same workbook row';
  end if;

  select template_name,subject_row_mappings into v_old_name,v_old_subject_rows
  from public.schoolpro_result_template_assignments
  where school_id=p_school and class_id=p_class
    and term=trim(p_term) and session=trim(p_session)
  for update;
  v_new_name:=left(trim(v_template_config->>'name'),120);
  insert into public.schoolpro_result_template_assignments(
    school_id,class_id,term,session,template_name,template_config,subject_row_mappings,updated_by,template_id
  ) values (
    p_school,p_class,trim(p_term),trim(p_session),v_new_name,v_template_config,p_subject_row_mappings,auth.uid(),v_template_id
  )
  on conflict(school_id,class_id,term,session) do update
    set template_name=excluded.template_name,
        template_config=excluded.template_config,
        subject_row_mappings=excluded.subject_row_mappings,
        updated_by=excluded.updated_by,
        template_id=excluded.template_id,
        updated_at=now()
  returning id into v_assignment;
  insert into public.schoolpro_result_template_assignment_audit(
    school_id,class_id,term,session,action,previous_template_name,new_template_name,changed_by,
    previous_subject_row_mappings,new_subject_row_mappings
  ) values (p_school,p_class,trim(p_term),trim(p_session),
    case when v_old_name is null then 'assigned' else 'reassigned' end,
    v_old_name,v_new_name,auth.uid(),coalesce(v_old_subject_rows,'{}'::jsonb),p_subject_row_mappings);
  return v_assignment;
end;
$$;


-- Preserve the exact class assignment and workbook configuration used for each
-- generated file. These immutable snapshots remain readable even if the live
-- assignment is later changed or the library template is retired.
alter table public.schoolpro_generated_result_outputs
  add column if not exists template_assignment_id uuid,
  add column if not exists template_id uuid,
  add column if not exists template_assignment_updated_at timestamptz,
  add column if not exists template_config_snapshot jsonb,
  add column if not exists subject_row_mappings_snapshot jsonb;

alter table public.schoolpro_generated_result_outputs
  drop constraint if exists schoolpro_generated_result_outputs_template_config_snapshot_object,
  add constraint schoolpro_generated_result_outputs_template_config_snapshot_object
    check (template_config_snapshot is null or jsonb_typeof(template_config_snapshot)='object'),
  drop constraint if exists schoolpro_generated_result_outputs_subject_row_mappings_snapshot_object,
  add constraint schoolpro_generated_result_outputs_subject_row_mappings_snapshot_object
    check (subject_row_mappings_snapshot is null or jsonb_typeof(subject_row_mappings_snapshot)='object');

create index if not exists schoolpro_generated_result_outputs_template_assignment_idx
  on public.schoolpro_generated_result_outputs(school_id,template_assignment_id)
  where template_assignment_id is not null;

-- Replace all section mappings in one transaction; a failed mapping update
-- cannot leave a template partially unmapped.
create or replace function public.schoolpro_set_result_template_sections(
  p_school uuid,p_template_id uuid,p_section_keys text[]
) returns integer
language plpgsql security definer set search_path=''
as $$
declare
  v_count integer;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_is_school_admin(p_school) then
    raise exception 'Only an active authorized school administrator can map result templates';
  end if;
  if p_section_keys is null then
    raise exception 'Choose the sections for this result template';
  end if;
  if exists(select 1 from unnest(p_section_keys) k
    where k not in ('nursery','primary','junior_secondary','senior_secondary')) then
    raise exception 'One or more selected school sections are invalid';
  end if;
  perform 1 from public.schoolpro_result_template_library l
  where l.school_id=p_school and l.id=p_template_id and l.is_active
  for update;
  if not found then
    raise exception 'The selected custom result template is unavailable';
  end if;
  delete from public.schoolpro_result_template_section_mappings
  where school_id=p_school and template_id=p_template_id;
  insert into public.schoolpro_result_template_section_mappings(
    school_id,template_id,section_key,mapped_by
  )
  select p_school,p_template_id,k,auth.uid()
  from (select distinct unnest(p_section_keys) as k) selected;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function public.schoolpro_set_result_template_sections(uuid,uuid,text[]) from public,anon;
grant execute on function public.schoolpro_set_result_template_sections(uuid,uuid,text[]) to authenticated;

     or v_template_config->>'storage_path' is distinct from p_template_config->>'storage_path'
     or v_template_config->>'storage_path' not like p_school::text||'/%'
     or position('..' in v_template_config->>'storage_path')>0 then
    raise exception 'The selected custom result template is no longer available';
  end if;
  if nullif(v_template_config->>'logo_storage_path','') is not null and (
    v_template_config->>'logo_storage_path' not like p_school::text||'/%'
    or position('..' in v_template_config->>'logo_storage_path')>0
    or not exists(select 1 from storage.objects o
      where o.bucket_id='school-result-templates'
        and o.name=v_template_config->>'logo_storage_path')
  ) then
    raise exception 'The selected custom result template has an unavailable school logo';
  end if;

  select m.id into v_member
  from public.schoolpro_members m
  where m.school_id=p_school and m.user_id=auth.uid() and m.status='active'
  limit 1;
  select exists(select 1 from public.schoolpro_classes c
    where c.school_id=p_school and c.id=p_class and c.archived_at is null
      and c.form_teacher_id=v_member) into v_is_form_master;
  if not (v_is_form_master or private.schoolpro_is_school_admin(p_school)) then
    raise exception 'Only this class Form Master or an authorized school administrator can assign its result design';
  end if;

  if jsonb_typeof(p_subject_row_mappings)<>'object'
     or octet_length(p_subject_row_mappings::text)>50000 then
    raise exception 'Map each assigned class subject to one workbook row before saving';
  end if;
  for v_subject_key,v_subject_row in select key,value from jsonb_each_text(p_subject_row_mappings)
  loop
    if v_subject_key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       or v_subject_row !~ '^[1-9][0-9]{0,4}$' then
      raise exception 'Subject mappings must use valid catalogue subject IDs and positive worksheet row numbers';
    end if;
    if v_subject_row::integer>10000 then
      raise exception 'Subject worksheet rows must be between 1 and 10000';
    end if;
  end loop;
  select count(*) into v_assignment_count
  from public.schoolpro_subject_assignments a
  where a.school_id=p_school and a.class_id=p_class and a.session=trim(p_session);
  select count(*) into v_mapping_count from jsonb_each(p_subject_row_mappings);
  if v_assignment_count=0 or v_assignment_count<>v_mapping_count then
    raise exception 'Every subject allocated to this class and session must be mapped exactly once';
  end if;
  if exists(
    select 1 from public.schoolpro_subject_assignments a
    where a.school_id=p_school and a.class_id=p_class and a.session=trim(p_session)
      and not (p_subject_row_mappings ? a.subject_id::text)
  ) then
    raise exception 'One or more allocated class subjects have no workbook row mapping';
  end if;
  if exists(
    select 1 from (
      select value::integer as row_number from jsonb_each_text(p_subject_row_mappings)
    ) rows group by row_number having count(*)>1
  ) then
    raise exception 'Two subjects cannot be mapped to the same workbook row';
  end if;

  select template_name,subject_row_mappings into v_old_name,v_old_subject_rows
  from public.schoolpro_result_template_assignments
  where school_id=p_school and class_id=p_class
    and term=trim(p_term) and session=trim(p_session)
  for update;
  v_new_name:=left(trim(v_template_config->>'name'),120);
  insert into public.schoolpro_result_template_assignments(
    school_id,class_id,term,session,template_name,template_config,subject_row_mappings,updated_by,template_id
  ) values (
    p_school,p_class,trim(p_term),trim(p_session),v_new_name,v_template_config,p_subject_row_mappings,auth.uid(),v_template_id
  )
  on conflict(school_id,class_id,term,session) do update
    set template_name=excluded.template_name,
        template_config=excluded.template_config,
        subject_row_mappings=excluded.subject_row_mappings,
        updated_by=excluded.updated_by,
        template_id=excluded.template_id,
        updated_at=now()
  returning id into v_assignment;
  insert into public.schoolpro_result_template_assignment_audit(
    school_id,class_id,term,session,action,previous_template_name,new_template_name,changed_by,
    previous_subject_row_mappings,new_subject_row_mappings
  ) values (p_school,p_class,trim(p_term),trim(p_session),
    case when v_old_name is null then 'assigned' else 'reassigned' end,
    v_old_name,v_new_name,auth.uid(),coalesce(v_old_subject_rows,'{}'::jsonb),p_subject_row_mappings);
  return v_assignment;
end;
$$;


-- Replace all section mappings in one transaction; a failed mapping update
-- cannot leave a template partially unmapped.
create or replace function public.schoolpro_set_result_template_sections(
  p_school uuid,p_template_id uuid,p_section_keys text[]
) returns integer
language plpgsql security definer set search_path=''
as $$
declare
  v_count integer;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.schoolpro_is_school_admin(p_school) then
    raise exception 'Only an active authorized school administrator can map result templates';
  end if;
  if p_section_keys is null then
    raise exception 'Choose the sections for this result template';
  end if;
  if exists(select 1 from unnest(p_section_keys) k
    where k not in ('nursery','primary','junior_secondary','senior_secondary')) then
    raise exception 'One or more selected school sections are invalid';
  end if;
  perform 1 from public.schoolpro_result_template_library l
  where l.school_id=p_school and l.id=p_template_id and l.is_active
  for update;
  if not found then
    raise exception 'The selected custom result template is unavailable';
  end if;
  delete from public.schoolpro_result_template_section_mappings
  where school_id=p_school and template_id=p_template_id;
  insert into public.schoolpro_result_template_section_mappings(
    school_id,template_id,section_key,mapped_by
  )
  select p_school,p_template_id,k,auth.uid()
  from (select distinct unnest(p_section_keys) as k) selected;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function public.schoolpro_set_result_template_sections(uuid,uuid,text[]) from public,anon;
grant execute on function public.schoolpro_set_result_template_sections(uuid,uuid,text[]) to authenticated;


-- Atomically validate the exact class-template snapshot and record the output.
-- The workbook is uploaded first; this RPC is the authoritative commit point.
-- Locking the assignment row prevents it being changed between comparison and
-- output-row insertion.
create or replace function public.schoolpro_record_generated_result_output(
  p_school uuid,
  p_student uuid,
  p_class uuid,
  p_term text,
  p_session text,
  p_storage_path text,
  p_template_assignment_id uuid,
  p_template_id uuid,
  p_template_assignment_updated_at timestamptz,
  p_template_config_snapshot jsonb,
  p_subject_row_mappings_snapshot jsonb
) returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  v_assignment public.schoolpro_result_template_assignments%rowtype;
  v_output_id uuid;
begin
  if auth.uid() is null or not private.is_active_account()
     or not private.has_school_access(p_school) then
    raise exception 'An active member of this school is required to save a generated result';
  end if;
  if p_school is null or p_student is null or p_class is null
     or p_template_assignment_id is null or p_template_id is null
     or p_template_assignment_updated_at is null
     or p_term not in ('First Term','Second Term','Third Term')
     or char_length(trim(coalesce(p_session,''))) not between 4 and 20
     or nullif(trim(coalesce(p_storage_path,'')),'') is null
     or p_storage_path not like p_school::text||'/'||p_student::text||'/%'
     or position('..' in coalesce(p_storage_path,''))>0
     or jsonb_typeof(p_template_config_snapshot)<>'object'
     or jsonb_typeof(p_subject_row_mappings_snapshot)<>'object' then
    raise exception 'The generated result metadata is invalid';
  end if;

  perform 1
  from public.schoolpro_students s
  where s.id=p_student and s.school_id=p_school and s.class_id=p_class;
  if not found then
    raise exception 'The selected student is no longer enrolled in this class';
  end if;

  select a.* into v_assignment
  from public.schoolpro_result_template_assignments a
  where a.school_id=p_school and a.class_id=p_class
    and a.term=trim(p_term) and a.session=trim(p_session)
  for update;
  if not found
     or v_assignment.id<>p_template_assignment_id
     or v_assignment.template_id<>p_template_id
     or v_assignment.updated_at is distinct from p_template_assignment_updated_at
     or v_assignment.template_config is distinct from p_template_config_snapshot
     or v_assignment.subject_row_mappings is distinct from p_subject_row_mappings_snapshot then
    raise exception 'The class result design or subject mapping changed after preview. Refresh and generate a new preview.';
  end if;

  if not exists(
    select 1 from storage.objects o
    where o.bucket_id='schoolpro-result-outputs' and o.name=p_storage_path
  ) then
    raise exception 'The generated workbook upload could not be verified';
  end if;

  insert into public.schoolpro_generated_result_outputs(
    school_id,student_id,term,session,format,storage_path,generated_by,
    template_assignment_id,template_id,template_assignment_updated_at,
    template_config_snapshot,subject_row_mappings_snapshot
  ) values (
    p_school,p_student,trim(p_term),trim(p_session),'xlsx',p_storage_path,auth.uid(),
    v_assignment.id,v_assignment.template_id,v_assignment.updated_at,
    v_assignment.template_config,v_assignment.subject_row_mappings
  ) returning id into v_output_id;

  return v_output_id;
end;
$$;
revoke all on function public.schoolpro_record_generated_result_output(
  uuid,uuid,uuid,text,text,text,uuid,uuid,timestamptz,jsonb,jsonb
) from public,anon;
grant execute on function public.schoolpro_record_generated_result_output(
  uuid,uuid,uuid,text,text,text,uuid,uuid,timestamptz,jsonb,jsonb
) to authenticated;
