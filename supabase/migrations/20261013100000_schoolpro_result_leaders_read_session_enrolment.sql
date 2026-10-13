-- Keep historical enrollment visibility aligned with the roles already authorized
-- to review school-wide results. Result leaders need session-specific rosters
-- to load the Results portal; this does not grant result-writing permissions.
create or replace function private.schoolpro_enrollment_reader_keys()
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
with leaders as materialized (
 select s.id
 from public.schoolpro_schools s
 where auth.uid() is not null
   and private.is_active_account()
   and private.schoolpro_operationally_active(s.id)
   and (
     private.is_admin(array['super_admin'::public.user_role])
     or (private.schoolpro_module_allowed(s.id,'students') and public.schoolpro_member_can_manage(s.id))
     or private.schoolpro_can_issue_transcript(s.id)
     or s.owner_id=(select auth.uid())
     or exists(
       select 1
       from public.schoolpro_members m
       where m.school_id=s.id
         and m.user_id=(select auth.uid())
         and m.role in (
           'proprietor',
           'administrator',
           'exam_officer',
           'head_teacher',
           'vice_principal'
         )
     )
   )
), readable as (
 select e.school_id::text||'|'||e.student_id::text||'|'||e.session as key
 from public.schoolpro_enrollment_history e
 where auth.uid() is not null
   and private.is_active_account()
   and (
     e.school_id in (select id from leaders)
     or exists(
       select 1
       from public.schoolpro_students s
       where s.id=e.student_id
         and s.school_id=e.school_id
         and s.user_id=(select auth.uid())
     )
     or exists(
       select 1
       from public.schoolpro_guardian_links g
       where g.school_id=e.school_id
         and g.student_id=e.student_id
         and g.guardian_user_id=(select auth.uid())
         and g.status='active'
     )
     or exists(
       select 1
       from public.schoolpro_members m
       where m.school_id=e.school_id
         and m.user_id=(select auth.uid())
         and m.role in ('teacher','class_teacher')
         and (
           exists(
             select 1
             from public.schoolpro_classes c
             where c.school_id=e.school_id
               and c.id=e.class_id
               and c.form_teacher_id=m.id
           )
           or exists(
             select 1
             from public.schoolpro_subject_assignments a
             where a.school_id=e.school_id
               and a.class_id=e.class_id
               and a.session=e.session
               and a.teacher_member_id=m.id
           )
         )
     )
   )
   and private.schoolpro_operationally_active(e.school_id)
)
select coalesce(jsonb_object_agg(key,true),'{}'::jsonb)
from readable
$$;

revoke all on function private.schoolpro_enrollment_reader_keys() from public,anon;
grant execute on function private.schoolpro_enrollment_reader_keys() to authenticated;
