-- Capture school-scoped operational changes in the existing audit ledger.
-- Store actor attribution and changed field names only; never copy row values,
-- credentials, payment proofs, student details or other sensitive payloads.
begin;

create or replace function private.capture_schoolpro_audit_log()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_row jsonb;
  v_old jsonb;
  v_school_id uuid;
  v_actor_id uuid := auth.uid();
  v_actor_name text := 'System';
  v_actor_role text := 'system';
  v_entity_id text;
  v_changed_fields text[] := array[]::text[];
begin
  if tg_op = 'DELETE' then
    v_row := to_jsonb(old);
    v_old := '{}'::jsonb;
  else
    v_row := to_jsonb(new);
    if tg_op = 'UPDATE' then
      v_old := to_jsonb(old);
    else
      v_old := '{}'::jsonb;
    end if;
  end if;

  if v_row ? 'school_id' then
    v_school_id := nullif(v_row ->> 'school_id', '')::uuid;
  elsif v_row ? 'application_id' then
    select a.school_id
      into v_school_id
      from public.schoolpro_admissions a
     where a.id = nullif(v_row ->> 'application_id', '')::uuid;
  end if;

  if v_school_id is null then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;

  v_entity_id := coalesce(v_row ->> 'id', v_row ->> 'application_id', v_row ->> 'member_id');

  if tg_op = 'UPDATE' then
    select coalesce(array_agg(k.key order by k.key), array[]::text[])
      into v_changed_fields
      from jsonb_object_keys(v_row) as k(key)
     where k.key not in ('id', 'created_at', 'updated_at')
       and (v_row -> k.key) is distinct from (v_old -> k.key);
    if cardinality(v_changed_fields) = 0 then
      return new;
    end if;
  else
    select coalesce(array_agg(k.key order by k.key), array[]::text[])
      into v_changed_fields
      from jsonb_object_keys(v_row) as k(key)
     where k.key not in ('id', 'created_at', 'updated_at');
  end if;

  if v_actor_id is not null then
    select coalesce(
      nullif(btrim(concat_ws(' ', p.first_name, p.middle_name, p.last_name)), ''),
      p.email,
      'Unknown user'
    ), coalesce((
      select m.role::text
        from public.schoolpro_members m
       where m.school_id = v_school_id
         and m.user_id = v_actor_id
         and m.status = 'active'
       order by m.created_at desc
       limit 1
    ), p.role::text, 'authenticated')
      into v_actor_name, v_actor_role
      from public.profiles p
     where p.id = v_actor_id;

    v_actor_name := coalesce(v_actor_name, 'Unknown user');
    v_actor_role := coalesce(v_actor_role, 'authenticated');
  end if;

  insert into public.schoolpro_audit_logs
    (school_id, actor_id, action, entity_type, entity_id, metadata)
  values
    (
      v_school_id,
      v_actor_id,
      lower(tg_op),
      tg_table_name,
      v_entity_id,
      jsonb_build_object(
        'operation', tg_op,
        'actor_name', v_actor_name,
        'actor_role', v_actor_role,
        'changed_fields', to_jsonb(v_changed_fields)
      )
    );

  if tg_op = 'DELETE' then return old; else return new; end if;
end;
$function$;

revoke all on function private.capture_schoolpro_audit_log() from public, anon, authenticated;

do $triggers$
declare
  v_table text;
  v_tables text[] := array[
    'schoolpro_members',
    'schoolpro_member_permissions',
    'schoolpro_board_members',
    'schoolpro_students',
    'schoolpro_classes',
    'schoolpro_subjects',
    'schoolpro_subject_assignments',
    'schoolpro_attendance',
    'schoolpro_results',
    'schoolpro_admissions',
    'schoolpro_admission_offers',
    'schoolpro_admission_events',
    'schoolpro_admission_documents',
    'schoolpro_fee_structures',
    'schoolpro_invoices',
    'schoolpro_fee_payments',
    'schoolpro_payment_proofs',
    'schoolpro_staff_disciplinary_cases',
    'schoolpro_staff_disciplinary_events',
    'schoolpro_leave_requests',
    'schoolpro_leave_events',
    'schoolpro_discipline_records',
    'schoolpro_discipline_events',
    'schoolpro_houses',
    'schoolpro_house_master_assignments',
    'schoolpro_house_point_ledger',
    'schoolpro_competition_events',
    'schoolpro_competition_entries',
    'schoolpro_competition_judges',
    'schoolpro_competition_scores',
    'schoolpro_competition_result_runs',
    'schoolpro_competition_result_entries',
    'schoolpro_promotions',
    'schoolpro_library_books',
    'schoolpro_library_loans',
    'schoolpro_transport_routes',
    'schoolpro_student_transport',
    'schoolpro_hostel_rooms',
    'schoolpro_hostel_allocations',
    'schoolpro_inventory_assets',
    'schoolpro_payroll_records',
    'schoolpro_calendar_events',
    'schoolpro_lesson_notes',
    'schoolpro_health_records',
    'schoolpro_document_issues',
    'schoolpro_result_correction_requests'
  ];
begin
  foreach v_table in array v_tables loop
    if to_regclass('public.' || v_table) is not null then
      execute format('drop trigger if exists trg_schoolpro_audit_capture on public.%I', v_table);
      execute format(
        'create trigger trg_schoolpro_audit_capture after insert or update or delete on public.%I for each row execute function private.capture_schoolpro_audit_log()',
        v_table
      );
    end if;
  end loop;
end;
$triggers$;

commit;
