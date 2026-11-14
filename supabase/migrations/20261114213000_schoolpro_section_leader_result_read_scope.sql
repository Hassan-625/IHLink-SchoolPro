-- Keep section leaders out of the school-wide result-reader shortcut.
-- Head Teachers and Vice Principals receive result visibility through the
-- section-specific Result access gate and active section appointments.

create or replace function private.schoolpro_cached_access_schools(
  p_permission text,
  p_scope text default 'module'
)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce(array_agg(s.id), array[]::uuid[])
  from public.schoolpro_schools s
  where auth.uid() is not null
    and private.is_active_account()
    and (
      private.is_admin(array['super_admin']::public.user_role[])
      or s.owner_id = auth.uid()
      or exists (
        select 1
        from public.schoolpro_members m
        where m.school_id = s.id
          and m.user_id = auth.uid()
          and m.status = 'active'
      )
    )
    and case p_scope
      when 'lesson-leader' then
        private.schoolpro_module_allowed(s.id, p_permission)
        and private.schoolpro_lesson_leader(s.id)
      when 'result-leader' then
        private.schoolpro_operationally_active(s.id)
        and (
          private.is_admin(array['super_admin']::public.user_role[])
          or s.owner_id = auth.uid()
          or private.schoolpro_member_has_responsibility(s.id, 'school_admin')
          or exists (
            select 1
            from public.schoolpro_members m
            where m.school_id = s.id
              and m.user_id = auth.uid()
              and m.status = 'active'
              and m.role = 'proprietor'
          )
          or exists (
            select 1
            from public.schoolpro_members m
            where m.school_id = s.id
              and m.user_id = auth.uid()
              and m.status = 'active'
              and m.role = 'administrator'
              and not (
                regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'principal%'
                or regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'vice principal%'
                or regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'head teacher%'
                or regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'headmaster%'
                or regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'headmistress%'
              )
          )
          or private.schoolpro_is_exam_officer(s.id)
        )
      else
        private.schoolpro_module_allowed(s.id, p_permission)
    end;
$function$;

revoke all on function private.schoolpro_cached_access_schools(text, text)
  from public, anon;
grant execute on function private.schoolpro_cached_access_schools(text, text)
  to authenticated;

comment on function private.schoolpro_cached_access_schools(text, text) is
  'Returns school-wide module/result-reader scopes. Section leaders are intentionally excluded from the result-leader school-wide shortcut and are authorized by active section-specific result policies.';

-- Apply a restrictive SELECT policy so existing permissive policies cannot
-- turn a section-leader membership/title into school-wide result visibility.
create or replace function private.schoolpro_is_section_leader_for_result(
  p_school uuid
)
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
      from public.schoolpro_members m
      where m.school_id = p_school
        and m.user_id = auth.uid()
        and m.status = 'active'
        and (
          m.role in ('head_teacher', 'vice_principal')
          or (
            m.role = 'administrator'
            and (
              regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'principal%'
              or regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'vice principal%'
              or regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'head teacher%'
              or regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'headmaster%'
              or regexp_replace(lower(trim(coalesce(m.position_title, ''))), '[^a-z]+', ' ', 'g') like 'headmistress%'
            )
          )
        )
    );
$function$;

revoke all on function private.schoolpro_is_section_leader_for_result(uuid)
  from public, anon;
grant execute on function private.schoolpro_is_section_leader_for_result(uuid)
  to authenticated;

drop policy if exists schoolpro_section_leader_result_scope on public.schoolpro_results;
create policy schoolpro_section_leader_result_scope
on public.schoolpro_results
as restrictive
for select
to authenticated
using (
  not private.schoolpro_is_section_leader_for_result(school_id)
  or private.is_admin(array['super_admin']::public.user_role[])
  or exists (
    select 1 from public.schoolpro_schools s
    where s.id = schoolpro_results.school_id
      and s.owner_id = auth.uid()
  )
  or private.schoolpro_member_has_responsibility(school_id, 'school_admin')
  or private.schoolpro_is_exam_officer(school_id)
  or private.schoolpro_member_leads_student_section(
    school_id, student_id, session
  )
);
