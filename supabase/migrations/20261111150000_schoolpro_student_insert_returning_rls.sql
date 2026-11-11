-- Fix INSERT ... RETURNING for school owners and authorised staff.
-- The previous SELECT policy helper queried schoolpro_students by the new row ID.
-- A row inserted by the current command is not reliably visible to that nested
-- STABLE lookup under the command snapshot, so RETURNING could fail despite a
-- valid INSERT policy. Evaluate the same access rules directly from policy row
-- values instead; do not re-query the student row.

create or replace function private.schoolpro_can_read_student_row(
  p_student uuid,
  p_school uuid,
  p_user uuid,
  p_class uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select auth.uid() is not null
    and private.is_active_account()
    and private.schoolpro_operationally_active(p_school)
    and (
      private.is_admin(array['super_admin'::public.user_role])
      or private.schoolpro_is_school_admin(p_school)
      or private.schoolpro_is_exam_officer(p_school)
      or p_user = auth.uid()
      or exists (
        select 1
        from public.schoolpro_guardian_links g
        where g.school_id = p_school
          and g.student_id = p_student
          and g.guardian_user_id = auth.uid()
          and g.status = 'active'
      )
      or exists (
        select 1
        from public.schoolpro_schools sc
        where sc.id = p_school
          and sc.owner_id = auth.uid()
      )
      or private.schoolpro_member_leads_class(p_school, p_class)
      or exists (
        select 1
        from public.schoolpro_members m
        where m.school_id = p_school
          and m.user_id = auth.uid()
          and (
            m.role::text not in (
              'teacher',
              'class_teacher',
              'parent',
              'student',
              'head_teacher',
              'vice_principal'
            )
            or (
              m.role in (
                'teacher'::public.school_member_role,
                'class_teacher'::public.school_member_role
              )
              and (
                exists (
                  select 1
                  from public.schoolpro_subject_assignments a
                  where a.school_id = p_school
                    and a.class_id = p_class
                    and a.teacher_member_id = m.id
                )
                or exists (
                  select 1
                  from public.schoolpro_classes c
                  where c.id = p_class
                    and c.school_id = p_school
                    and c.form_teacher_id = m.id
                )
              )
            )
          )
      )
    );
$function$;

revoke all on function private.schoolpro_can_read_student_row(uuid, uuid, uuid, uuid) from public, anon;
grant execute on function private.schoolpro_can_read_student_row(uuid, uuid, uuid, uuid) to authenticated;

drop policy if exists "School users read students" on public.schoolpro_students;
create policy "School users read students"
on public.schoolpro_students
for select
to authenticated
using (private.schoolpro_can_read_student_row(id, school_id, user_id, class_id));

drop policy if exists "Scoped student records" on public.schoolpro_students;
create policy "Scoped student records"
on public.schoolpro_students
for select
to authenticated
using (private.schoolpro_can_read_student_row(id, school_id, user_id, class_id));
