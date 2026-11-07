-- Principal role, complete admissions route wiring support, and school activity audit capture.
-- Existing principal designations remain valid; this adds a first-class stored role.
alter type public.school_member_role add value if not exists 'principal';

alter table public.schoolpro_members
  drop constraint if exists schoolpro_position_title_valid;
alter table public.schoolpro_members
  add constraint schoolpro_position_title_valid
  check (position_title is null or (position_title = 'Principal' and role::text in ('administrator','principal')));

create or replace function private.has_school_access(
  target_school uuid,
  allowed_roles public.school_member_role[] default array[
    'proprietor'::public.school_member_role,
    'administrator'::public.school_member_role,
    'teacher'::public.school_member_role,
    'accountant'::public.school_member_role
  ]
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.status = 'active'
      and (
        private.is_admin()
        or exists (
          select 1 from public.schoolpro_schools s
          where s.id = target_school and s.owner_id = p.id
        )
        or exists (
          select 1 from public.schoolpro_members m
          where m.school_id = target_school
            and m.user_id = p.id
            and m.status = 'active'
            and (
              m.role = any(allowed_roles)
              or (m.role::text = 'principal' and 'administrator'::public.school_member_role = any(allowed_roles))
            )
        )
      )
  );
$function$;

create or replace function public.schoolpro_user_permissions(p_school uuid)
returns text[]
language plpgsql
security definer
set search_path = ''
as $function$
declare
  m public.schoolpro_members;
  base text[];
  extra text[];
begin
  if auth.uid() is null then
    return array[]::text[];
  end if;

  if exists (
    select 1
    from public.schoolpro_board_members b
    join public.schoolpro_members bm
      on bm.id = b.member_id
     and bm.school_id = b.school_id
    where b.school_id = p_school
      and bm.user_id = auth.uid()
      and bm.status = 'active'
      and b.ended_at is null
      and bm.role = 'administrator'
  ) then
    return array[
      'dashboard','students','results','reports','finance','classes','subjects',
      'attendance','timetable','assignments','admissions','cbt','library','staff',
      'parents','transport','hostel','inventory','discipline','medical','documents',
      'announcements','operations','roles','branding','payroll','calendar',
      'lesson-notes','leave','promotions','notifications'
    ]::text[];
  end if;

  select * into m
  from public.schoolpro_members
  where school_id = p_school and user_id = auth.uid()
  limit 1;

  if exists (
    select 1 from public.schoolpro_schools
    where id = p_school and owner_id = auth.uid()
  ) or private.is_admin(array['super_admin']::public.user_role[]) then
    return array[
      'dashboard','students','results','reports','finance','classes','subjects',
      'attendance','timetable','assignments','admissions','cbt','library','staff',
      'parents','transport','hostel','inventory','discipline','medical','documents',
      'announcements','operations','roles','branding','payroll','calendar',
      'lesson-notes','leave','promotions','notifications'
    ]::text[];
  end if;

  if m.id is null or m.status <> 'active' then
    return array[]::text[];
  end if;

  if m.role::text = 'principal'
     or (m.role = 'administrator' and m.position_title = 'Principal') then
    return array[
      'dashboard','students','results','reports','finance','classes','subjects',
      'attendance','timetable','assignments','admissions','cbt','library','staff',
      'parents','transport','hostel','inventory','discipline','medical','documents',
      'announcements','operations','roles','branding','payroll','calendar',
      'lesson-notes','leave','promotions','notifications'
    ]::text[];
  end if;

  base := case m.role::text
    when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications']
    when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications']
    when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications']
    when 'discipline_master' then array['dashboard','students','discipline','notifications']
    when 'game_master' then array['dashboard','students','games','notifications']
    when 'receptionist' then array['dashboard','admissions','parents','announcements','calendar','notifications']
    when 'administrator' then array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','notifications']
    when 'bursar' then array['dashboard','finance','students','notifications']
    when 'accountant' then array['dashboard','finance','students','reports','notifications']
    when 'teacher' then array['reports','discipline','dashboard','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','cbt','notifications']
    when 'class_teacher' then array['reports','discipline','dashboard','students','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','notifications']
    when 'exam_officer' then array['dashboard','results','reports','cbt','students','classes','subjects','documents','notifications']
    when 'registrar' then array['dashboard','students','classes','parents','documents','notifications']
    when 'admissions_officer' then array['dashboard','admissions','students','documents','notifications']
    when 'librarian' then array['dashboard','library','students','notifications']
    when 'nurse' then array['dashboard','medical','students','notifications']
    when 'hostel_manager' then array['dashboard','hostel','students','notifications']
    when 'transport_manager' then array['dashboard','transport','students','notifications']
    when 'inventory_officer' then array['dashboard','inventory','notifications']
    when 'hr_officer' then array['dashboard','staff','leave','payroll','notifications']
    when 'it_admin' then array['dashboard','roles','branding','operations','notifications']
    else array['dashboard','notifications']
  end;

  select array_agg(permission) into extra
  from public.schoolpro_member_permissions
  where member_id = m.id and allowed = true;

  return (
    select array_agg(distinct x)
    from unnest(base || coalesce(extra, array[]::text[])) x
    where not exists (
      select 1 from public.schoolpro_member_permissions p
      where p.member_id = m.id and p.permission = x and p.allowed = false
    )
  );
end;
$function$;

-- Audit capture runs as a private trigger function. No client receives direct
-- INSERT rights on the audit table; each record is tied to auth.uid().
create or replace function private.capture_schoolpro_audit_log()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_row jsonb;
  v_old jsonb;
  v_school uuid;
  v_actor_name text;
  v_profile_role text;
  v_school_role text;
  v_entity_id text;
  v_entity_label text;
  v_changed text[];
begin
  if tg_op = 'DELETE' then
    v_row := to_jsonb(old);
    v_old := v_row;
  else
    v_row := to_jsonb(new);
    if tg_op = 'UPDATE' then v_old := to_jsonb(old); end if;
  end if;

  v_school := nullif(v_row->>'school_id','')::uuid;
  if v_school is null and v_row ? 'application_id' then
    select a.school_id into v_school
    from public.schoolpro_admissions a
    where a.id = nullif(v_row->>'application_id','')::uuid;
  end if;
  if v_school is null or auth.uid() is null then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;

  select nullif(trim(concat_ws(' ',p.first_name,p.middle_name,p.last_name)),''),
         p.role::text
    into v_actor_name,v_profile_role
  from public.profiles p where p.id = auth.uid();

  select m.role::text into v_school_role
  from public.schoolpro_members m
  where m.school_id = v_school and m.user_id = auth.uid() and m.status = 'active'
  order by m.created_at desc limit 1;

  v_entity_id := coalesce(v_row->>'id',v_row->>'application_id');
  v_entity_label := coalesce(
    nullif(v_row->>'application_number',''),
    nullif(v_row->>'title',''),
    nullif(v_row->>'name',''),
    nullif(v_row->>'event_type',''),
    nullif(v_row->>'document_type',''),
    nullif(v_row->>'action','')
  );

  if tg_op = 'UPDATE' then
    select array_agg(k order by k) into v_changed
    from jsonb_object_keys(v_row) as keys(k)
    where v_old->k is distinct from v_row->k;
  else
    v_changed := array['record'];
  end if;

  insert into public.schoolpro_audit_logs(
    school_id,actor_id,action,entity_type,entity_id,metadata
  ) values (
    v_school,
    auth.uid(),
    lower(tg_op),
    tg_table_name,
    v_entity_id,
    jsonb_build_object(
      'actor_name',coalesce(v_actor_name,'User profile unavailable'),
      'actor_role',coalesce(v_school_role,v_profile_role,'unassigned'),
      'record_label',v_entity_label,
      'changed_fields',coalesce(to_jsonb(v_changed),'[]'::jsonb)
    )
  );

  if tg_op = 'DELETE' then return old; else return new; end if;
end;
$function$;

revoke all on function private.capture_schoolpro_audit_log() from public,anon,authenticated;

do $triggers$
declare
  v_table text;
  v_tables text[] := array[
    'schoolpro_admissions',
    'schoolpro_admission_events',
    'schoolpro_admission_documents',
    'schoolpro_admission_offers',
    'schoolpro_members',
    'schoolpro_students',
    'schoolpro_classes',
    'schoolpro_results',
    'schoolpro_leave_requests',
    'schoolpro_discipline_records',
    'schoolpro_payroll_records',
    'schoolpro_calendar_events',
    'schoolpro_promotions',
    'schoolpro_inventory_assets',
    'schoolpro_transport_routes',
    'schoolpro_hostel_rooms',
    'schoolpro_library_books'
  ];
begin
  foreach v_table in array v_tables loop
    if to_regclass('public.' || v_table) is not null then
      execute format('drop trigger if exists schoolpro_audit_capture on public.%I',v_table);
      execute format(
        'create trigger schoolpro_audit_capture after insert or update or delete on public.%I for each row execute function private.capture_schoolpro_audit_log()',
        v_table
      );
    end if;
  end loop;
end;
$triggers$;
