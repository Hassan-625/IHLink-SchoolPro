-- Read-only preflight for the exact tenant IDs in an existing-student import batch.
-- Mirrors the school-access predicate used by the schoolpro_students INSERT policy.
create or replace function public.schoolpro_existing_student_import_payload_check(
  p_school_id uuid,
  p_rows jsonb
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_active boolean := coalesce(private.is_active_account(), false);
  v_all_authorized boolean := true;
  v_failed integer[] := array[]::integer[];
  v_count integer := 0;
  v_row jsonb;
  v_row_school uuid;
  v_index integer := 0;
begin
  if v_uid is null then
    return jsonb_build_object(
      'authenticated', false, 'active_account', false,
      'requested_school_matches', false, 'row_count', 0,
      'all_rows_authorized', false, 'failed_rows', '[]'::jsonb,
      'reason', 'The database request has no authenticated user.'
    );
  end if;

  if jsonb_typeof(p_rows) <> 'array' then
    return jsonb_build_object(
      'authenticated', true, 'active_account', v_active,
      'requested_school_matches', false, 'row_count', 0,
      'all_rows_authorized', false, 'failed_rows', '[]'::jsonb,
      'reason', 'The submitted batch is not a JSON array.'
    );
  end if;

  for v_row in select value from jsonb_array_elements(p_rows)
  loop
    v_index := v_index + 1;
    v_count := v_count + 1;
    begin
      v_row_school := nullif(v_row->>'school_id', '')::uuid;
    exception when others then
      v_row_school := null;
    end;

    if p_school_id is null
       or v_row_school is null
       or v_row_school <> p_school_id
       or not coalesce(private.has_school_access(v_row_school, array[
         'proprietor'::public.school_member_role,
         'administrator'::public.school_member_role
       ]), false) then
      v_all_authorized := false;
      v_failed := array_append(v_failed, v_index);
    end if;
  end loop;

  if not v_active then
    v_all_authorized := false;
    if cardinality(v_failed) = 0 then
      v_failed := array(select generate_series(1, greatest(v_count, 1)));
    end if;
  end if;

  return jsonb_build_object(
    'authenticated', true,
    'active_account', v_active,
    'requested_school_matches', p_school_id is not null,
    'row_count', v_count,
    'all_rows_authorized', v_all_authorized and v_count > 0,
    'failed_rows', to_jsonb(v_failed),
    'reason', case
      when not v_active then 'The authenticated account is not active.'
      when p_school_id is null then 'No selected school ID was supplied.'
      when v_count = 0 then 'The import batch is empty.'
      when cardinality(v_failed) > 0 then 'One or more submitted school IDs do not match the selected school or fail the INSERT policy access helper.'
      else null
    end
  );
end;
$function$;

revoke all on function public.schoolpro_existing_student_import_payload_check(uuid, jsonb) from public, anon;
grant execute on function public.schoolpro_existing_student_import_payload_check(uuid, jsonb) to authenticated;
