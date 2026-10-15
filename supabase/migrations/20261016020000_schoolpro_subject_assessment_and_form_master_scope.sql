-- Enforce the agreed class/subject boundaries for assignments, CBT authoring and attendance.
-- Existing records are preserved. Legacy CBT rows with no session remain readable only through
-- the scoped read rules; new staff-authored tests must specify class, subject and session.

alter table public.schoolpro_cbt_tests add column if not exists session text;

create or replace function private.schoolpro_can_manage_assignment_scope(p_school uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account()
 and (private.has_school_access(p_school,array['proprietor','administrator','head_teacher','vice_principal']::public.school_member_role[])
      or private.is_admin(array['super_admin']::public.user_role[]))
$$;
revoke all on function private.schoolpro_can_manage_assignment_scope(uuid) from public,anon;
grant execute on function private.schoolpro_can_manage_assignment_scope(uuid) to authenticated;

create or replace function private.schoolpro_can_write_assignment_scope(p_school uuid,p_class uuid,p_subject uuid,p_session text)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account()
 and private.schoolpro_operationally_active(p_school)
 and private.schoolpro_module_allowed(p_school,'assignments')
 and (
   private.schoolpro_can_manage_assignment_scope(p_school)
   or exists(
     select 1 from public.schoolpro_members m
     join public.schoolpro_subject_assignments a on a.school_id=m.school_id and a.teacher_member_id=m.id
     where m.school_id=p_school and m.user_id=auth.uid()
       and m.role::text in('teacher','class_teacher')
       and a.class_id=p_class and a.subject_id=p_subject and trim(a.session)=trim(p_session)
   )
 )
$$;
revoke all on function private.schoolpro_can_write_assignment_scope(uuid,uuid,uuid,text) from public,anon;
grant execute on function private.schoolpro_can_write_assignment_scope(uuid,uuid,uuid,text) to authenticated;

create or replace function private.schoolpro_can_mark_attendance(p_school uuid,p_class uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account()
 and private.schoolpro_operationally_active(p_school)
 and private.schoolpro_module_allowed(p_school,'attendance')
 and (
   private.has_school_access(p_school,array['proprietor','administrator','head_teacher','vice_principal']::public.school_member_role[])
   or private.is_admin(array['super_admin']::public.user_role[])
   or exists(
     select 1 from public.schoolpro_classes c
     join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
     where c.id=p_class and c.school_id=p_school and m.user_id=auth.uid()
       and m.role::text in('teacher','class_teacher')
   )
 )
$$;
revoke all on function private.schoolpro_can_mark_attendance(uuid,uuid) from public,anon;
grant execute on function private.schoolpro_can_mark_attendance(uuid,uuid) to authenticated;

-- Subject teachers and Form Masters may write only their own assigned class/subject/session.
-- Form Masters can still read the class-wide assignment list through the existing targeted-read policy.
drop policy if exists "assignment authorized manage" on public.schoolpro_assignments;
create policy "assignment scoped insert" on public.schoolpro_assignments for insert to authenticated
with check (private.schoolpro_can_manage_assignment_scope(school_id) or (private.schoolpro_can_write_assignment_scope(school_id,class_id,subject_id,session) and created_by=(select auth.uid())));
create policy "assignment scoped update" on public.schoolpro_assignments for update to authenticated
using (private.schoolpro_can_manage_assignment_scope(school_id) or (private.schoolpro_can_write_assignment_scope(school_id,class_id,subject_id,session) and created_by=(select auth.uid())))
with check (private.schoolpro_can_manage_assignment_scope(school_id) or (private.schoolpro_can_write_assignment_scope(school_id,class_id,subject_id,session) and created_by=(select auth.uid())));
create policy "assignment scoped delete" on public.schoolpro_assignments for delete to authenticated
using (private.schoolpro_can_manage_assignment_scope(school_id) or (private.schoolpro_can_write_assignment_scope(school_id,class_id,subject_id,session) and created_by=(select auth.uid())));

-- Attendance is writable by school management or the Form Master assigned to that exact class.
-- Subject-teacher membership alone is deliberately insufficient.
drop policy if exists "School educators insert attendance" on public.schoolpro_attendance;
drop policy if exists "School educators update attendance" on public.schoolpro_attendance;
-- These legacy FOR ALL policies would OR with the new scoped write policies and bypass them.
-- Keep the separate school/student/guardian SELECT policies, but remove legacy all-command access.
drop policy if exists "Scoped attendance records" on public.schoolpro_attendance;
drop policy if exists "schoolpro_module_permission" on public.schoolpro_attendance;
create policy "Form Masters read assigned class attendance" on public.schoolpro_attendance for select to authenticated
using (exists(select 1 from public.schoolpro_classes c
 join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
 where c.id=schoolpro_attendance.class_id and c.school_id=schoolpro_attendance.school_id
 and m.user_id=auth.uid() and m.role::text in('teacher','class_teacher')));

create policy "Form Master or management inserts attendance" on public.schoolpro_attendance for insert to authenticated
with check (private.schoolpro_can_mark_attendance(school_id,class_id) and marked_by=(select auth.uid()));
create policy "Form Master or management updates attendance" on public.schoolpro_attendance for update to authenticated
using (private.schoolpro_can_mark_attendance(school_id,class_id))
with check (private.schoolpro_can_mark_attendance(school_id,class_id) and marked_by=(select auth.uid()));

create or replace function private.schoolpro_can_author_cbt_scope(p_school uuid,p_class uuid,p_subject uuid,p_session text)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account()
 and private.schoolpro_operationally_active(p_school)
 and private.schoolpro_module_allowed(p_school,'cbt')
 and (
   public.schoolpro_can_manage_cbt(p_school)
   or (p_class is not null and p_subject is not null and exists(
     select 1 from public.schoolpro_members m
     join public.schoolpro_subject_assignments a on a.school_id=m.school_id and a.teacher_member_id=m.id
     where m.school_id=p_school and m.user_id=auth.uid()
       and m.role::text in('teacher','class_teacher')
       and a.class_id=p_class and a.subject_id=p_subject
       and (p_session is null or trim(a.session)=trim(p_session))
   ))
 )
$$;
revoke all on function private.schoolpro_can_author_cbt_scope(uuid,uuid,uuid,text) from public,anon;
grant execute on function private.schoolpro_can_author_cbt_scope(uuid,uuid,uuid,text) to authenticated;

create or replace function private.schoolpro_can_read_cbt_test_scope(p_school uuid,p_class uuid,p_subject uuid,p_session text)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account()
 and private.schoolpro_operationally_active(p_school)
 and private.schoolpro_module_allowed(p_school,'cbt')
 and (
   public.schoolpro_can_manage_cbt(p_school)
   or (p_class is not null and p_subject is not null and exists(
     select 1 from public.schoolpro_members m
     join public.schoolpro_subject_assignments a on a.school_id=m.school_id and a.teacher_member_id=m.id
     where m.school_id=p_school and m.user_id=auth.uid()
       and m.role::text in('teacher','class_teacher')
       and a.class_id=p_class and a.subject_id=p_subject
       and (p_session is null or trim(a.session)=trim(p_session))
   ))
   or (p_class is not null and exists(
     select 1 from public.schoolpro_classes c
     join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
     where c.id=p_class and c.school_id=p_school and m.user_id=auth.uid()
       and m.role::text in('teacher','class_teacher')
   ))
 )
$$;
revoke all on function private.schoolpro_can_read_cbt_test_scope(uuid,uuid,uuid,text) from public,anon;
grant execute on function private.schoolpro_can_read_cbt_test_scope(uuid,uuid,uuid,text) to authenticated;

create or replace function private.schoolpro_can_manage_question_scope(p_school uuid,p_class uuid,p_subject uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account()
 and private.schoolpro_operationally_active(p_school)
 and private.schoolpro_module_allowed(p_school,'cbt')
 and (
   public.schoolpro_can_manage_cbt(p_school)
   or (p_subject is not null and exists(
     select 1 from public.schoolpro_members m
     join public.schoolpro_subject_assignments a on a.school_id=m.school_id and a.teacher_member_id=m.id
     where m.school_id=p_school and m.user_id=auth.uid()
       and m.role::text in('teacher','class_teacher')
       and a.subject_id=p_subject and (p_class is null or a.class_id=p_class)
   ))
 )
$$;
revoke all on function private.schoolpro_can_manage_question_scope(uuid,uuid,uuid) from public,anon;
grant execute on function private.schoolpro_can_manage_question_scope(uuid,uuid,uuid) to authenticated;

-- Replace broad school-wide teacher author policies with row-scoped policies.
drop policy if exists "cbt authors create drafts" on public.schoolpro_cbt_tests;
drop policy if exists "cbt authors delete drafts" on public.schoolpro_cbt_tests;
drop policy if exists "cbt authors edit drafts" on public.schoolpro_cbt_tests;
drop policy if exists "cbt authors read tests" on public.schoolpro_cbt_tests;
drop policy if exists "cbt managers manage tests" on public.schoolpro_cbt_tests;
-- The generic plan policy is FOR ALL and would otherwise bypass class/subject/session scoping.
drop policy if exists "schoolpro_plan_access" on public.schoolpro_cbt_tests;
create policy "CBT tests scoped read" on public.schoolpro_cbt_tests for select to authenticated
using (private.schoolpro_can_read_cbt_test_scope(school_id,class_id,subject_id,session));
create policy "CBT tests scoped insert" on public.schoolpro_cbt_tests for insert to authenticated
with check (status='draft' and session is not null and class_id is not null and subject_id is not null
 and private.schoolpro_can_author_cbt_scope(school_id,class_id,subject_id,session)
 and created_by=(select auth.uid()));
create policy "CBT tests scoped update" on public.schoolpro_cbt_tests for update to authenticated
using (public.schoolpro_can_manage_cbt(school_id) or (status='draft' and created_by=(select auth.uid())
 and private.schoolpro_can_author_cbt_scope(school_id,class_id,subject_id,session)))
with check (private.schoolpro_can_author_cbt_scope(school_id,class_id,subject_id,session)
 and (public.schoolpro_can_manage_cbt(school_id) or created_by=(select auth.uid())));
create policy "CBT tests scoped delete" on public.schoolpro_cbt_tests for delete to authenticated
using (public.schoolpro_can_manage_cbt(school_id) or (status='draft' and created_by=(select auth.uid())
 and private.schoolpro_can_author_cbt_scope(school_id,class_id,subject_id,session)));

drop policy if exists "school question manage" on public.schoolpro_question_bank;
drop policy if exists "question bank authorized read" on public.schoolpro_question_bank;
-- Question-bank writes must be governed by the subject/class-specific policies below.
drop policy if exists "schoolpro_plan_access" on public.schoolpro_question_bank;
create policy "Question bank scoped read" on public.schoolpro_question_bank for select to authenticated
using (private.schoolpro_can_manage_question_scope(school_id,class_id,subject_id));
create policy "Question bank scoped manage" on public.schoolpro_question_bank for all to authenticated
using (private.schoolpro_can_manage_question_scope(school_id,class_id,subject_id))
with check (private.schoolpro_can_manage_question_scope(school_id,class_id,subject_id));

drop policy if exists "test question authors write" on public.schoolpro_cbt_test_questions;
drop policy if exists "test question authorized read" on public.schoolpro_cbt_test_questions;
create policy "CBT test question scoped read" on public.schoolpro_cbt_test_questions for select to authenticated
using (exists(select 1 from public.schoolpro_cbt_tests t
 where t.id=test_id and private.schoolpro_can_read_cbt_test_scope(t.school_id,t.class_id,t.subject_id,t.session)));
create policy "CBT test question scoped insert" on public.schoolpro_cbt_test_questions for insert to authenticated
with check (exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id
 and (public.schoolpro_can_manage_cbt(t.school_id) or (t.status='draft' and t.created_by=(select auth.uid())
 and private.schoolpro_can_author_cbt_scope(t.school_id,t.class_id,t.subject_id,t.session)))));
create policy "CBT test question scoped update" on public.schoolpro_cbt_test_questions for update to authenticated
using (exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id
 and (public.schoolpro_can_manage_cbt(t.school_id) or (t.status='draft' and t.created_by=(select auth.uid())
 and private.schoolpro_can_author_cbt_scope(t.school_id,t.class_id,t.subject_id,t.session)))))
with check (exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id
 and (public.schoolpro_can_manage_cbt(t.school_id) or (t.status='draft' and t.created_by=(select auth.uid())
 and private.schoolpro_can_author_cbt_scope(t.school_id,t.class_id,t.subject_id,t.session)))));
create policy "CBT test question scoped delete" on public.schoolpro_cbt_test_questions for delete to authenticated
using (exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id
 and (public.schoolpro_can_manage_cbt(t.school_id) or (t.status='draft' and t.created_by=(select auth.uid())
 and private.schoolpro_can_author_cbt_scope(t.school_id,t.class_id,t.subject_id,t.session)))));

-- The answer-marking RPC must use the same class/subject scope as test authoring.
create or replace function public.mark_schoolpro_theory_answer(p_answer uuid,p_marks numeric,p_feedback text default null)
returns void language plpgsql security definer set search_path='' as $$
declare a public.schoolpro_cbt_answers; at public.schoolpro_cbt_attempts; t public.schoolpro_cbt_tests; q public.schoolpro_question_bank;
begin
 select * into a from public.schoolpro_cbt_answers where id=p_answer for update;
 if a.id is null then raise exception 'Answer not found'; end if;
 select * into at from public.schoolpro_cbt_attempts where id=a.attempt_id;
 if at.id is null then raise exception 'Attempt not found'; end if;
 select * into t from public.schoolpro_cbt_tests where id=at.test_id;
 if t.id is null then raise exception 'Test not found'; end if;
 if not private.schoolpro_module_allowed(t.school_id,'cbt') then raise exception 'Module permission denied: cbt'; end if;
 select * into q from public.schoolpro_question_bank where id=a.question_id and school_id=t.school_id;
 if q.id is null or not exists(select 1 from public.schoolpro_cbt_test_questions tq where tq.test_id=t.id and tq.question_id=q.id) then
   raise exception 'Question is not assigned to this test or school';
 end if;
 if q.question_type<>'theory' then raise exception 'Only theory answers require manual marking'; end if;
 if not private.schoolpro_can_author_cbt_scope(t.school_id,t.class_id,t.subject_id,t.session) then raise exception 'Not authorized'; end if;
 if p_marks<0 or p_marks>q.marks then raise exception 'Marks must be between 0 and question maximum'; end if;
 update public.schoolpro_cbt_answers set marks_awarded=p_marks,feedback=p_feedback,marked_by=auth.uid(),marked_at=now(),is_correct=null where id=a.id;
 update public.schoolpro_cbt_attempts set score=(
   select coalesce(sum(coalesce(x.marks_awarded,0)),0) from public.schoolpro_cbt_answers x
   where x.attempt_id=at.id and exists(select 1 from public.schoolpro_cbt_test_questions tq where tq.test_id=t.id and tq.question_id=x.question_id)
 ) where id=at.id;
end $$;
revoke all on function public.mark_schoolpro_theory_answer(uuid,numeric,text) from public,anon;
grant execute on function public.mark_schoolpro_theory_answer(uuid,numeric,text) to authenticated;

-- The My Classes directory must admit class_teacher membership, while keeping its returned
-- rows limited to the caller, managers, and staff linked to classes they can read.
create or replace function private.schoolpro_class_staff_directory(p_school uuid)
returns table(id uuid,user_id uuid,role text,name text)
language sql stable security definer set search_path='' as $$
 select m.id,m.user_id,m.role::text,
 coalesce(nullif(trim(concat_ws(' ',p.first_name,p.last_name)),''),'Staff member')
 from public.schoolpro_members m join public.profiles p on p.id=m.user_id
 where m.school_id=p_school and auth.uid() is not null and private.is_active_account()
 and private.schoolpro_operationally_active(p_school)
 and (private.has_school_access(p_school,array['proprietor','administrator','teacher','class_teacher','exam_officer','head_teacher','vice_principal']::public.school_member_role[])
      or exists(select 1 from public.schoolpro_members me where me.school_id=p_school and me.user_id=auth.uid()))
 and (private.has_school_access(p_school,array['proprietor','administrator']::public.school_member_role[])
      or m.user_id=auth.uid()
      or exists(select 1 from public.schoolpro_classes c where c.school_id=p_school and private.schoolpro_can_read_class(c.id)
       and (c.form_teacher_id=m.id or exists(select 1 from public.schoolpro_subject_assignments a
        where a.school_id=p_school and a.class_id=c.id and a.teacher_member_id=m.id))))
$$;
revoke all on function private.schoolpro_class_staff_directory(uuid) from public,anon;
grant execute on function private.schoolpro_class_staff_directory(uuid) to authenticated;
create or replace function public.schoolpro_class_staff_directory(p_school uuid)
returns table(id uuid,user_id uuid,role text,name text)
language sql stable security invoker set search_path='' as $$ select * from private.schoolpro_class_staff_directory(p_school) $$;
revoke all on function public.schoolpro_class_staff_directory(uuid) from public,anon;
grant execute on function public.schoolpro_class_staff_directory(uuid) to authenticated;


-- Scope the subject allocation read path itself, not just the My Classes page filter.
drop policy if exists "School users read subject assignments" on public.schoolpro_subject_assignments;
create policy "Subject allocation scoped read" on public.schoolpro_subject_assignments for select to authenticated
using (
 private.has_school_access(school_id,array['proprietor','administrator','exam_officer','head_teacher','vice_principal']::public.school_member_role[])
 or exists(select 1 from public.schoolpro_members m
   where m.school_id=schoolpro_subject_assignments.school_id and m.user_id=auth.uid()
     and m.id=schoolpro_subject_assignments.teacher_member_id and m.role::text in('teacher','class_teacher'))
 or exists(select 1 from public.schoolpro_classes c
   join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
   where c.id=schoolpro_subject_assignments.class_id and c.school_id=schoolpro_subject_assignments.school_id
     and m.user_id=auth.uid() and m.role::text in('teacher','class_teacher'))
);

-- Form Masters can inspect the question content attached to CBT tests in their assigned class,
-- but cannot edit another subject teacher's question bank or test.
create or replace function private.schoolpro_can_read_question_scope(p_school uuid,p_question uuid,p_class uuid,p_subject uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account()
 and private.schoolpro_operationally_active(p_school)
 and private.schoolpro_module_allowed(p_school,'cbt')
 and (
   public.schoolpro_can_manage_cbt(p_school)
   or private.schoolpro_can_manage_question_scope(p_school,p_class,p_subject)
   or exists(
     select 1 from public.schoolpro_cbt_test_questions tq
     join public.schoolpro_cbt_tests t on t.id=tq.test_id
     join public.schoolpro_classes c on c.id=t.class_id and c.school_id=t.school_id
     join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id
     where tq.question_id=p_question
       and t.school_id=p_school and t.class_id is not null and t.subject_id=p_subject
       and (p_class is null or p_class=t.class_id)
       and m.user_id=auth.uid() and m.role::text in('teacher','class_teacher')
   )
 )
$$;
revoke all on function private.schoolpro_can_read_question_scope(uuid,uuid,uuid,uuid) from public,anon;
grant execute on function private.schoolpro_can_read_question_scope(uuid,uuid,uuid,uuid) to authenticated;
drop policy if exists "Question bank scoped read" on public.schoolpro_question_bank;
drop policy if exists "schoolpro_plan_access" on public.schoolpro_cbt_eligibility;
create policy "Question bank scoped read" on public.schoolpro_question_bank for select to authenticated
using (private.schoolpro_can_read_question_scope(school_id,id,class_id,subject_id));

-- Subject teachers can configure eligibility only for the test they authored and its assigned class.
-- Management retains the existing school-wide eligibility control.
create policy "CBT authors manage own test eligibility" on public.schoolpro_cbt_eligibility for all to authenticated
using (
 exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id and t.school_id=schoolpro_cbt_eligibility.school_id
   and t.created_by=(select auth.uid())
   and private.schoolpro_can_author_cbt_scope(t.school_id,t.class_id,t.subject_id,t.session)
   and ((student_id is null and class_id=t.class_id)
     or (student_id is not null and class_id is null and exists(select 1 from public.schoolpro_students s
       where s.id=student_id and s.school_id=t.school_id and s.class_id=t.class_id))))
)
with check (
 exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id and t.school_id=schoolpro_cbt_eligibility.school_id
   and t.created_by=(select auth.uid())
   and private.schoolpro_can_author_cbt_scope(t.school_id,t.class_id,t.subject_id,t.session)
   and ((student_id is null and class_id=t.class_id)
     or (student_id is not null and class_id is null and exists(select 1 from public.schoolpro_students s
       where s.id=student_id and s.school_id=t.school_id and s.class_id=t.class_id))))
);


-- Keep the live tenant-integrity trigger intact and add an independent guard for subject/class scope.
-- Production currently uses enforce_schoolpro_tenant_relations for tenant integrity, so this
-- dedicated trigger does not assume that a source-only legacy trigger name exists.
create or replace function private.schoolpro_validate_cbt_question_scope()
returns trigger language plpgsql security definer set search_path='' as $$
declare test_row public.schoolpro_cbt_tests; question_row public.schoolpro_question_bank;
begin
 select * into test_row from public.schoolpro_cbt_tests where id=new.test_id;
 select * into question_row from public.schoolpro_question_bank where id=new.question_id;
 if test_row.id is null or question_row.id is null then raise exception 'CBT test or question not found'; end if;
 if test_row.school_id<>question_row.school_id then raise exception 'CBT question belongs to another school'; end if;
 if test_row.subject_id is not null and question_row.subject_id is distinct from test_row.subject_id then
   raise exception 'CBT question must match the test subject';
 end if;
 if question_row.class_id is not null and question_row.class_id is distinct from test_row.class_id then
   raise exception 'Class-specific CBT question must match the test class';
 end if;
 return new;
end $$;
revoke all on function private.schoolpro_validate_cbt_question_scope() from public,anon,authenticated;
drop trigger if exists schoolpro_validate_cbt_question_scope on public.schoolpro_cbt_test_questions;
create trigger schoolpro_validate_cbt_question_scope
before insert or update of test_id,question_id on public.schoolpro_cbt_test_questions
for each row execute function private.schoolpro_validate_cbt_question_scope();
