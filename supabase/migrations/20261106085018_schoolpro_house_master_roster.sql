-- Read-only, least-privilege roster for a staff member's active House Master appointment.
-- Student RLS intentionally remains unchanged; the private definer helper returns only
-- the narrow roster fields after validating the caller, school membership and appointment.

create or replace function private.schoolpro_house_master_roster(p_school uuid)
returns table (
  house_id uuid,
  house_name text,
  house_color text,
  student_id uuid,
  admission_number text,
  first_name text,
  middle_name text,
  last_name text,
  class_name text,
  class_arm text,
  assigned_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    h.id as house_id,
    h.name as house_name,
    h.color as house_color,
    st.id as student_id,
    st.admission_number,
    st.first_name,
    st.middle_name,
    st.last_name,
    coalesce(c.name, st.class_name) as class_name,
    c.arm as class_arm,
    sh.assigned_at
  from public.schoolpro_house_master_assignments a
  join public.schoolpro_members m
    on m.id = a.member_id
   and m.school_id = a.school_id
  join public.schoolpro_houses h
    on h.id = a.house_id
   and h.school_id = a.school_id
   and h.is_active
  left join public.schoolpro_student_house_history sh
    on sh.school_id = a.school_id
   and sh.house_id = a.house_id
   and sh.effective_to is null
  left join public.schoolpro_students st
    on st.id = sh.student_id
   and st.school_id = sh.school_id
   and st.status = 'active'
  left join public.schoolpro_classes c
    on c.id = st.class_id
   and c.school_id = st.school_id
  where p_school is not null
    and auth.uid() is not null
    and private.is_active_account()
    and a.school_id = p_school
    and a.ended_at is null
    and m.user_id = auth.uid()
    and m.role in (
      'teacher'::public.school_member_role,
      'class_teacher'::public.school_member_role
    );
$function$;

revoke all on function private.schoolpro_house_master_roster(uuid)
  from public, anon;
grant execute on function private.schoolpro_house_master_roster(uuid)
  to authenticated;

create or replace function public.schoolpro_house_master_roster(p_school uuid)
returns table (
  house_id uuid,
  house_name text,
  house_color text,
  student_id uuid,
  admission_number text,
  first_name text,
  middle_name text,
  last_name text,
  class_name text,
  class_arm text,
  assigned_at timestamptz
)
language sql
stable
security invoker
set search_path = ''
as $function$
  select *
  from private.schoolpro_house_master_roster(p_school);
$function$;

revoke all on function public.schoolpro_house_master_roster(uuid)
  from public, anon;
grant execute on function public.schoolpro_house_master_roster(uuid)
  to authenticated;
