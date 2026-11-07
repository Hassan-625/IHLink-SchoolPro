-- Stage C0 follow-up: make core authorization helpers honor lifecycle state.
-- Apply only after 20261107130000_schoolpro_class_staff_lifecycle_foundation.sql.
-- This is a partial authorization correction, not the complete C0 rollout. The
-- remaining direct membership readers, write validators, DELETE grants/policies,
-- operational appointment cleanup, and regression suite remain required.

create or replace function private.has_school_access(
  target_school uuid,
  allowed_roles public.school_member_role[] default array[
    'proprietor'::public.school_member_role,
    'administrator'::public.school_member_role,
    'teacher'::public.school_member_role,
    'accountant'::public.school_member_role
  ]
) returns boolean
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
            and m.role = any(allowed_roles)
        )
      )
  );
$function$;

create or replace function private.schoolpro_can_read_class(p_class uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and exists (
      select 1
      from public.schoolpro_classes c
      where c.id = p_class
        and (
          private.has_school_access(
            c.school_id,
            array['proprietor','administrator']::public.school_member_role[]
          )
          or private.schoolpro_member_leads_class(c.school_id,c.id)
          or exists (
            select 1
            from public.schoolpro_members m
            where m.school_id = c.school_id
              and m.user_id = auth.uid()
              and m.status = 'active'
              and (
                m.role::text not in (
                  'teacher','class_teacher','parent','student',
                  'head_teacher','vice_principal'
                )
                or c.form_teacher_id = m.id
                or exists (
                  select 1
                  from public.schoolpro_subject_assignments a
                  where a.class_id = c.id
                    and a.school_id = c.school_id
                    and a.teacher_member_id = m.id
                )
              )
          )
          -- Student and guardian access is deliberately retained for historical
          -- academic records, including records linked to archived classes.
          or exists (
            select 1
            from public.schoolpro_students s
            where s.class_id = c.id
              and s.school_id = c.school_id
              and (
                s.user_id = auth.uid()
                or exists (
                  select 1
                  from public.schoolpro_guardian_links g
                  where g.student_id = s.id
                    and g.guardian_user_id = auth.uid()
                    and g.status = 'active'
                )
              )
          )
        )
    );
$function$;

create or replace function private.schoolpro_member_leads_class(
  p_school uuid, p_class uuid
) returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and exists (
      select 1
      from public.schoolpro_members m
      join public.schoolpro_section_leaders sl
        on sl.school_id = m.school_id and sl.member_id = m.id
      join public.schoolpro_classes c
        on c.school_id = p_school and c.id = p_class and c.level = sl.section
      where m.school_id = p_school
        and m.user_id = auth.uid()
        and m.status = 'active'
        and m.role in ('head_teacher','vice_principal')
    );
$function$;

create or replace function private.schoolpro_member_leads_student_section(
  p_school uuid, p_student uuid, p_session text
) returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and exists (
      select 1
      from public.schoolpro_members m
      join public.schoolpro_section_leaders sl
        on sl.school_id = m.school_id and sl.member_id = m.id
      join public.schoolpro_students st
        on st.school_id = p_school and st.id = p_student
      join public.schoolpro_classes c
        on c.school_id = p_school
       and c.id = coalesce((
         select eh.class_id
         from public.schoolpro_enrollment_history eh
         where eh.school_id = p_school
           and eh.student_id = p_student
           and eh.session = trim(coalesce(p_session,''))
         order by eh.created_at desc
         limit 1
       ), st.class_id)
       and c.level = sl.section
      where m.school_id = p_school
        and m.user_id = auth.uid()
        and m.status = 'active'
        and m.role in ('head_teacher','vice_principal')
    );
$function$;

create or replace function private.schoolpro_is_house_master(
  p_school uuid, p_house uuid default null
) returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and exists (
      select 1
      from public.schoolpro_house_master_assignments a
      join public.schoolpro_members m
        on m.id = a.member_id and m.school_id = a.school_id
      where a.school_id = p_school
        and a.ended_at is null
        and m.user_id = auth.uid()
        and m.status = 'active'
        and (p_house is null or a.house_id = p_house)
        and m.role in (
          'teacher'::public.school_member_role,
          'class_teacher'::public.school_member_role
        )
    );
$function$;

create or replace function private.schoolpro_lesson_author_scope(
  p_school uuid, p_class uuid, p_subject uuid
) returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.schoolpro_members m
    join public.profiles p on p.id = m.user_id
    where m.school_id = p_school
      and m.user_id = auth.uid()
      and m.status = 'active'
      and p.status = 'active'
      and m.role in ('teacher','class_teacher')
      and (
        exists (
          select 1 from public.schoolpro_classes c
          where c.id = p_class and c.school_id = p_school
            and c.form_teacher_id = m.id
        )
        or exists (
          select 1 from public.schoolpro_subject_assignments a
          where a.school_id = p_school and a.class_id = p_class
            and a.teacher_member_id = m.id
            and (p_subject is null or a.subject_id = p_subject)
        )
      )
  );
$function$;

create or replace function private.schoolpro_lesson_leader(p_school uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.status = 'active'
  )
  and (
    private.is_admin(array['super_admin']::public.user_role[])
    or exists (
      select 1 from public.schoolpro_schools s
      where s.id = p_school and s.owner_id = auth.uid()
    )
    or exists (
      select 1 from public.schoolpro_members m
      where m.school_id = p_school
        and m.user_id = auth.uid()
        and m.status = 'active'
        and m.role in ('administrator','head_teacher','vice_principal')
    )
  );
$function$;

create or replace function private.schoolpro_validate_house_master()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  if not exists (
    select 1 from public.schoolpro_houses h
    where h.id = new.house_id
      and h.school_id = new.school_id
      and h.is_active
  ) then
    raise exception 'House must be active and belong to the selected school';
  end if;

  if not exists (
    select 1 from public.schoolpro_members m
    where m.id = new.member_id
      and m.school_id = new.school_id
      and m.status = 'active'
      and m.role in (
        'teacher'::public.school_member_role,
        'class_teacher'::public.school_member_role
      )
  ) then
    raise exception 'House Master must be active teaching staff in the same school';
  end if;
  return new;
end;
$function$;

-- Retain the existing private-schema-only execution model. Callers are the
-- existing SECURITY DEFINER functions/triggers; do not grant these helpers
-- directly to browser roles.
revoke all on function private.has_school_access(uuid,public.school_member_role[]) from public, anon, authenticated;
revoke all on function private.schoolpro_can_read_class(uuid) from public, anon, authenticated;
revoke all on function private.schoolpro_member_leads_class(uuid,uuid) from public, anon, authenticated;
revoke all on function private.schoolpro_member_leads_student_section(uuid,uuid,text) from public, anon, authenticated;
revoke all on function private.schoolpro_is_house_master(uuid,uuid) from public, anon, authenticated;
revoke all on function private.schoolpro_lesson_author_scope(uuid,uuid,uuid) from public, anon, authenticated;
revoke all on function private.schoolpro_lesson_leader(uuid) from public, anon, authenticated;
revoke all on function private.schoolpro_validate_house_master() from public, anon, authenticated;
