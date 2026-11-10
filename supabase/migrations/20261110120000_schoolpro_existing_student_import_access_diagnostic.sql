-- Read-only diagnostic for the authenticated identity used by the existing-student import.
-- This function never writes student, membership, profile, or audit data.
create or replace function public.schoolpro_existing_student_import_access_check(p_school_id uuid)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_authorized boolean := false;
  v_owner boolean := false;
  v_membership boolean := false;
begin
  if v_user_id is null then
    return jsonb_build_object(
      'authenticated', false,
      'authorized', false,
      'requested_school_id', p_school_id,
      'reason', 'No authenticated Supabase user identity reached the database.'
    );
  end if;

  if p_school_id is null then
    return jsonb_build_object(
      'authenticated', true,
      'authorized', false,
      'authenticated_user_id', v_user_id,
      'reason', 'No school workspace ID was supplied.'
    );
  end if;

  v_authorized := private.has_school_access(
    p_school_id,
    array['proprietor'::public.school_member_role, 'administrator'::public.school_member_role]
  );

  if not v_authorized then
    return jsonb_build_object(
      'authenticated', true,
      'authorized', false,
      'authenticated_user_id', v_user_id,
      'requested_school_id', p_school_id,
      'has_school_access', false,
      'reason', 'The authenticated database identity does not have Proprietor or Administrator access to this school.'
    );
  end if;

  select exists (
    select 1 from public.schoolpro_schools s
    where s.id = p_school_id and s.owner_id = v_user_id
  ) into v_owner;

  select exists (
    select 1 from public.schoolpro_members m
    where m.school_id = p_school_id
      and m.user_id = v_user_id
      and m.status = 'active'
      and m.role in ('proprietor', 'administrator')
  ) into v_membership;

  return jsonb_build_object(
    'authenticated', true,
    'authorized', true,
    'authenticated_user_id', v_user_id,
    'requested_school_id', p_school_id,
    'school_owner', v_owner,
    'active_leadership_membership', v_membership,
    'has_school_access', v_authorized,
    'reason', 'The database authenticated identity has school-leadership access.'
  );
end;
$function$;

revoke all on function public.schoolpro_existing_student_import_access_check(uuid) from public;
grant execute on function public.schoolpro_existing_student_import_access_check(uuid) to authenticated;
