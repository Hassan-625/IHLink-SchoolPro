-- Class / term / session result-template assignment selected by the Form Master.
-- Snapshot the workbook mapping so Exam Officer generation uses the exact same design.

create table public.schoolpro_result_template_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
  class_id uuid not null references public.schoolpro_classes(id) on delete cascade,
  term text not null check (term in ('First Term','Second Term','Third Term')),
  session text not null check (char_length(trim(session)) between 4 and 20),
  template_name text not null check (char_length(trim(template_name)) between 1 and 120),
  template_config jsonb not null check (jsonb_typeof(template_config)='object'),
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
  changed_at timestamptz not null default now()
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
  p_school uuid,p_class uuid,p_term text,p_session text,p_template_config jsonb
) returns uuid
language plpgsql security definer set search_path=''
as $$
declare
  v_member uuid;
  v_old_name text;
  v_new_name text;
  v_assignment uuid;
  v_is_form_master boolean := false;
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

  if not (v_is_form_master
      or private.schoolpro_is_school_admin(p_school)
      or private.schoolpro_is_exam_officer(p_school)) then
    raise exception 'Only this class Form Master, an authorized school administrator, or the Exam Officer can assign its result design';
  end if;

  select template_name into v_old_name
  from public.schoolpro_result_template_assignments
  where school_id=p_school and class_id=p_class
    and term=trim(p_term) and session=trim(p_session)
  for update;

  v_new_name:=left(trim(p_template_config->>'name'),120);
  insert into public.schoolpro_result_template_assignments(
    school_id,class_id,term,session,template_name,template_config,updated_by
  ) values (
    p_school,p_class,trim(p_term),trim(p_session),v_new_name,p_template_config,auth.uid()
  )
  on conflict(school_id,class_id,term,session) do update
    set template_name=excluded.template_name,
        template_config=excluded.template_config,
        updated_by=excluded.updated_by,
        updated_at=now()
  returning id into v_assignment;

  insert into public.schoolpro_result_template_assignment_audit(
    school_id,class_id,term,session,action,previous_template_name,new_template_name,changed_by
  ) values (
    p_school,p_class,trim(p_term),trim(p_session),
    case when v_old_name is null then 'assigned' else 'reassigned' end,
    v_old_name,v_new_name,auth.uid()
  );
  return v_assignment;
end;
$$;
revoke all on function public.schoolpro_set_class_result_template(uuid,uuid,text,text,jsonb) from public,anon;
grant execute on function public.schoolpro_set_class_result_template(uuid,uuid,text,text,jsonb) to authenticated;
