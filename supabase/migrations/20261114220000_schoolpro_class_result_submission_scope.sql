-- Class-result submission metadata follows the same class/section review boundary
-- as the authoritative result workflow. The former policy granted school-wide
-- reads to active teacher, class-teacher and section-leader memberships.
--
-- Use a dedicated helper rather than schoolpro_can_review_class: that helper
-- intentionally has broader Administrator semantics for other workflow actions,
-- while Principal / Head Teacher / Vice Principal titles must remain section-bound.

create or replace function private.schoolpro_can_read_class_result_submission(
  p_school uuid,
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
    and private.schoolpro_module_allowed(p_school, 'results')
    and exists (
      select 1
      from public.schoolpro_classes c
      where c.id = p_class
        and c.school_id = p_school
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
          and m.role = 'proprietor'
      )
      or private.schoolpro_member_has_responsibility(p_school, 'school_admin')
      or private.schoolpro_is_exam_officer(p_school)
      or exists (
        select 1
        from public.schoolpro_members m
        where m.school_id = p_school
          and m.user_id = auth.uid()
          and m.status = 'active'
          and m.role = 'administrator'
          and not (
            regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g')
              ~ '(^| )(principal|vice principal|head teacher|headteacher|headmaster|head master|headmistress|head mistress)( |$)'
          )
      )
      or private.schoolpro_member_leads_class(p_school, p_class)
      or exists (
        select 1
        from public.schoolpro_classes c
        join public.schoolpro_members m
          on m.id = c.form_teacher_id
         and m.school_id = c.school_id
        where c.id = p_class
          and c.school_id = p_school
          and m.user_id = auth.uid()
          and m.status = 'active'
      )
    );
$function$;

revoke all on function private.schoolpro_can_read_class_result_submission(uuid, uuid)
  from public, anon;
grant execute on function private.schoolpro_can_read_class_result_submission(uuid, uuid)
  to authenticated;

comment on function private.schoolpro_can_read_class_result_submission(uuid, uuid) is
  'Authorizes class-result submission metadata by explicit school authority, Exam Officer, active section appointment, or assigned Form Master; leadership titles do not receive school-wide access by virtue of Administrator membership.';

drop policy if exists "School result leaders read class submissions"
  on public.schoolpro_class_result_submissions;

create policy "School result leaders read class submissions"
  on public.schoolpro_class_result_submissions
  for select
  to authenticated
  using (
    private.schoolpro_can_read_class_result_submission(school_id, class_id)
  );

comment on policy "School result leaders read class submissions"
  on public.schoolpro_class_result_submissions is
  'Class result submission metadata is visible only to explicit school authorities, the Exam Officer, the assigned section leader, or the assigned Form Master.';
