-- Scope SchoolPro CBT authoring and question-bank access to an active
-- class/subject/session allocation. Student test-taking remains RPC-mediated.
-- Existing legacy rows are retained; null-session rows remain management-only.

alter table public.schoolpro_cbt_tests
  add column if not exists session text;

alter table public.schoolpro_question_bank
  add column if not exists session text;

create or replace function private.schoolpro_cbt_staff_scope(
  p_school uuid,
  p_class uuid,
  p_subject uuid,
  p_session text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $function$
  select
    (select auth.uid()) is not null
    and coalesce(private.is_active_account(), false)
    and private.schoolpro_operationally_active(p_school)
    and private.schoolpro_module_allowed(p_school, 'cbt')
    and p_class is not null
    and p_subject is not null
    and nullif(btrim(p_session), '') is not null
    and private.schoolpro_valid_session(btrim(p_session))
    and exists (
      select 1
      from public.schoolpro_classes c
      join public.schoolpro_subjects s
        on s.school_id=c.school_id
      join public.schoolpro_members m
        on m.school_id=c.school_id
       and m.user_id=(select auth.uid())
       and m.status='active'
       and m.role::text in ('teacher','class_teacher')
      join public.schoolpro_subject_assignments a
        on a.school_id=c.school_id
       and a.class_id=c.id
       and a.subject_id=s.id
       and a.teacher_member_id=m.id
       and a.session=btrim(p_session)
       and a.ended_at is null
      where c.id=p_class
        and c.school_id=p_school
        and c.archived_at is null
        and s.id=p_subject
    );
$function$;

revoke all on function private.schoolpro_cbt_staff_scope(uuid,uuid,uuid,text)
  from public, anon;
grant execute on function private.schoolpro_cbt_staff_scope(uuid,uuid,uuid,text)
  to authenticated;

create or replace function private.schoolpro_cbt_management_access(p_school uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $function$
  select
    (select auth.uid()) is not null
    and coalesce(private.is_active_account(),false)
    and private.schoolpro_operationally_active(p_school)
    and private.schoolpro_module_allowed(p_school,'cbt')
    and public.schoolpro_can_manage_cbt(p_school);
$function$;

revoke all on function private.schoolpro_cbt_management_access(uuid)
  from public, anon;
grant execute on function private.schoolpro_cbt_management_access(uuid)
  to authenticated;

create or replace function private.schoolpro_cbt_can_author(
  p_school uuid,
  p_class uuid,
  p_subject uuid,
  p_session text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $function$
  select
    (select auth.uid()) is not null
    and coalesce(private.is_active_account(), false)
    and private.schoolpro_operationally_active(p_school)
    and private.schoolpro_module_allowed(p_school, 'cbt')
    and (
      public.schoolpro_can_manage_cbt(p_school)
      or private.schoolpro_cbt_staff_scope(p_school,p_class,p_subject,p_session)
    );
$function$;

revoke all on function private.schoolpro_cbt_can_author(uuid,uuid,uuid,text)
  from public, anon;
grant execute on function private.schoolpro_cbt_can_author(uuid,uuid,uuid,text)
  to authenticated;

create or replace function private.schoolpro_cbt_can_read_test(
  p_school uuid,
  p_class uuid,
  p_subject uuid,
  p_session text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $function$
  select
    (select auth.uid()) is not null
    and coalesce(private.is_active_account(), false)
    and private.schoolpro_operationally_active(p_school)
    and private.schoolpro_module_allowed(p_school, 'cbt')
    and (
      public.schoolpro_can_manage_cbt(p_school)
      or private.schoolpro_cbt_staff_scope(p_school,p_class,p_subject,p_session)
    );
$function$;

revoke all on function private.schoolpro_cbt_can_read_test(uuid,uuid,uuid,text)
  from public, anon;
grant execute on function private.schoolpro_cbt_can_read_test(uuid,uuid,uuid,text)
  to authenticated;

-- CBT tests: remove the school-wide author/read and broad plan-read paths.
drop policy if exists "C0 CBT plan read" on public.schoolpro_cbt_tests;
drop policy if exists "cbt authors create drafts" on public.schoolpro_cbt_tests;
drop policy if exists "cbt authors delete drafts" on public.schoolpro_cbt_tests;
drop policy if exists "cbt authors edit drafts" on public.schoolpro_cbt_tests;
drop policy if exists "cbt authors read tests" on public.schoolpro_cbt_tests;
drop policy if exists "cbt managers manage tests" on public.schoolpro_cbt_tests;

create policy "CBT staff read assigned session tests"
on public.schoolpro_cbt_tests
for select to authenticated
using (private.schoolpro_cbt_can_read_test(school_id,class_id,subject_id,session));

create policy "CBT staff create assigned session drafts"
on public.schoolpro_cbt_tests
for insert to authenticated
with check (
  status='draft'
  and class_id is not null
  and subject_id is not null
  and nullif(btrim(session),'') is not null
  and private.schoolpro_valid_session(btrim(session))
  and created_by=(select auth.uid())
  and private.schoolpro_cbt_can_author(school_id,class_id,subject_id,session)
);

create policy "CBT staff update own assigned drafts"
on public.schoolpro_cbt_tests
for update to authenticated
using (
  (private.schoolpro_cbt_management_access(school_id)
    and (session is null or private.schoolpro_valid_session(btrim(session))))
  or (
    status='draft'
    and created_by=(select auth.uid())
    and private.schoolpro_cbt_staff_scope(school_id,class_id,subject_id,session)
  )
)
with check (
  (private.schoolpro_cbt_management_access(school_id)
    and (session is null or private.schoolpro_valid_session(btrim(session))))
  or (
    status='draft'
    and created_by=(select auth.uid())
    and private.schoolpro_cbt_staff_scope(school_id,class_id,subject_id,session)
  )
);

create policy "CBT staff delete own assigned drafts"
on public.schoolpro_cbt_tests
for delete to authenticated
using (
  private.schoolpro_cbt_management_access(school_id)
  or (
    status='draft'
    and created_by=(select auth.uid())
    and private.schoolpro_cbt_staff_scope(school_id,class_id,subject_id,session)
  )
);

-- Question bank rows are session-bound. Existing null-session records are retained
-- and remain available to CBT managers, but cannot be edited by subject teachers.
drop policy if exists "question bank authorized read" on public.schoolpro_question_bank;
drop policy if exists "school question manage" on public.schoolpro_question_bank;
drop policy if exists "schoolpro_plan_access" on public.schoolpro_question_bank;

create policy "Question bank assigned session access"
on public.schoolpro_question_bank
for all to authenticated
using (
  private.schoolpro_cbt_management_access(school_id)
  or private.schoolpro_cbt_staff_scope(school_id,class_id,subject_id,session)
)
with check (
  (
    (private.schoolpro_cbt_management_access(school_id)
      and (session is null or private.schoolpro_valid_session(btrim(session))))
    or private.schoolpro_cbt_staff_scope(school_id,class_id,subject_id,session)
  )
  and (created_by=(select auth.uid()) or private.schoolpro_cbt_management_access(school_id))
);

-- Test-question links inherit the exact scope of their parent test. This also
-- removes the older school-wide teacher policy for both reads and writes.
drop policy if exists "test question authorized read" on public.schoolpro_cbt_test_questions;
drop policy if exists "test question authors write" on public.schoolpro_cbt_test_questions;

create policy "CBT test question assigned session read"
on public.schoolpro_cbt_test_questions
for select to authenticated
using (
  exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=test_id
      and private.schoolpro_cbt_can_read_test(t.school_id,t.class_id,t.subject_id,t.session)
  )
);

create policy "CBT test question assigned session insert"
on public.schoolpro_cbt_test_questions
for insert to authenticated
with check (
  exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=test_id
      and (
        private.schoolpro_cbt_management_access(t.school_id)
        or (
          t.status='draft'
          and t.created_by=(select auth.uid())
          and private.schoolpro_cbt_staff_scope(t.school_id,t.class_id,t.subject_id,t.session)
        )
      )
  )
  and exists (
    select 1 from public.schoolpro_question_bank q
    join public.schoolpro_cbt_tests t on t.id=test_id
    where q.id=question_id
      and q.school_id=t.school_id
      and q.subject_id is not distinct from t.subject_id
      and (q.class_id is null or q.class_id=t.class_id)
      and q.session is not distinct from t.session
  )
);

create policy "CBT test question assigned session update"
on public.schoolpro_cbt_test_questions
for update to authenticated
using (
  exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=test_id
      and (
        private.schoolpro_cbt_management_access(t.school_id)
        or (
          t.status='draft'
          and t.created_by=(select auth.uid())
          and private.schoolpro_cbt_staff_scope(t.school_id,t.class_id,t.subject_id,t.session)
        )
      )
  )
)
with check (
  exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=test_id
      and (
        private.schoolpro_cbt_management_access(t.school_id)
        or (
          t.status='draft'
          and t.created_by=(select auth.uid())
          and private.schoolpro_cbt_staff_scope(t.school_id,t.class_id,t.subject_id,t.session)
        )
      )
  )
  and exists (
    select 1 from public.schoolpro_question_bank q
    join public.schoolpro_cbt_tests t on t.id=test_id
    where q.id=question_id
      and q.school_id=t.school_id
      and q.subject_id is not distinct from t.subject_id
      and (q.class_id is null or q.class_id=t.class_id)
      and q.session is not distinct from t.session
  )
);

create policy "CBT test question assigned session delete"
on public.schoolpro_cbt_test_questions
for delete to authenticated
using (
  exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=test_id
      and (
        private.schoolpro_cbt_management_access(t.school_id)
        or (
          t.status='draft'
          and t.created_by=(select auth.uid())
          and private.schoolpro_cbt_staff_scope(t.school_id,t.class_id,t.subject_id,t.session)
        )
      )
  )
);

-- Eligibility management is restricted to management or the author of a test
-- with a still-active allocation. Student own-rule reads remain intact.
drop policy if exists "cbt eligibility managers" on public.schoolpro_cbt_eligibility;
create policy "CBT management or assigned author eligibility"
on public.schoolpro_cbt_eligibility
for all to authenticated
using (
  exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=test_id
      and t.school_id=schoolpro_cbt_eligibility.school_id
      and (
        private.schoolpro_cbt_management_access(t.school_id)
        or (
          t.created_by=(select auth.uid())
          and private.schoolpro_cbt_staff_scope(t.school_id,t.class_id,t.subject_id,t.session)
          and (
            (student_id is null and class_id=t.class_id)
            or (
              student_id is not null
              and class_id is null
              and exists (
                select 1 from public.schoolpro_students s
                where s.id=student_id
                  and s.school_id=t.school_id
                  and s.class_id=t.class_id
              )
            )
          )
        )
      )
  )
)
with check (
  exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=test_id
      and t.school_id=schoolpro_cbt_eligibility.school_id
      and (
        private.schoolpro_cbt_management_access(t.school_id)
        or (
          t.created_by=(select auth.uid())
          and assigned_by=(select auth.uid())
          and private.schoolpro_cbt_staff_scope(t.school_id,t.class_id,t.subject_id,t.session)
          and (
            (student_id is null and class_id=t.class_id)
            or (
              student_id is not null
              and class_id is null
              and exists (
                select 1 from public.schoolpro_students s
                where s.id=student_id
                  and s.school_id=t.school_id
                  and s.class_id=t.class_id
              )
            )
          )
        )
      )
  )
);

-- The old plan-only ALL policies exposed every attempt/answer row to any active
-- account in a subscribed school. Student self-read and management read remain.
drop policy if exists "schoolpro_plan_attempts" on public.schoolpro_cbt_attempts;
drop policy if exists "schoolpro_plan_answers" on public.schoolpro_cbt_answers;

-- Assigned subject teachers may review attempts and answers only for tests in
-- their exact active class/subject/session allocation. Student self-read stays.
drop policy if exists "cbt attempt staff read" on public.schoolpro_cbt_attempts;
create policy "CBT assigned staff read attempts"
on public.schoolpro_cbt_attempts
for select to authenticated
using (
  exists (
    select 1 from public.schoolpro_cbt_tests t
    where t.id=test_id
      and private.schoolpro_cbt_can_read_test(t.school_id,t.class_id,t.subject_id,t.session)
  )
);

drop policy if exists "cbt answer staff read" on public.schoolpro_cbt_answers;
create policy "CBT assigned staff read answers"
on public.schoolpro_cbt_answers
for select to authenticated
using (
  exists (
    select 1
    from public.schoolpro_cbt_attempts a
    join public.schoolpro_cbt_tests t on t.id=a.test_id
    where a.id=attempt_id
      and private.schoolpro_cbt_can_read_test(t.school_id,t.class_id,t.subject_id,t.session)
  )
);

-- Manual theory marking is a privileged write path: use the same exact active
-- allocation check as test authoring rather than a school-wide teacher role.
create or replace function public.mark_schoolpro_theory_answer(
  p_answer uuid,
  p_marks numeric,
  p_feedback text default null
)
returns void
language plpgsql
security definer
set search_path=''
as $function$
declare
  a public.schoolpro_cbt_answers;
  attempt_row public.schoolpro_cbt_attempts;
  test_row public.schoolpro_cbt_tests;
  question_row public.schoolpro_question_bank;
begin
  if (select auth.uid()) is null or not coalesce(private.is_active_account(),false) then
    raise exception 'Authentication required';
  end if;

  select * into a
  from public.schoolpro_cbt_answers
  where id=p_answer
  for update;
  if a.id is null then raise exception 'Answer not found'; end if;

  select * into attempt_row
  from public.schoolpro_cbt_attempts
  where id=a.attempt_id;
  if attempt_row.id is null then raise exception 'Attempt not found'; end if;

  select * into test_row
  from public.schoolpro_cbt_tests
  where id=attempt_row.test_id;
  if test_row.id is null then raise exception 'Test not found'; end if;

  if not private.schoolpro_module_allowed(test_row.school_id,'cbt') then
    raise exception 'Module permission denied: cbt';
  end if;

  select * into question_row
  from public.schoolpro_question_bank
  where id=a.question_id and school_id=test_row.school_id;
  if question_row.id is null or not exists (
    select 1 from public.schoolpro_cbt_test_questions tq
    where tq.test_id=test_row.id and tq.question_id=question_row.id
  ) then
    raise exception 'Question is not assigned to this test or school';
  end if;

  if question_row.question_type<>'theory' then
    raise exception 'Only theory answers require manual marking';
  end if;

  if not private.schoolpro_cbt_can_author(
    test_row.school_id,test_row.class_id,test_row.subject_id,test_row.session
  ) then
    raise exception 'Not authorized to mark this test';
  end if;

  if p_marks<0 or p_marks>question_row.marks then
    raise exception 'Marks must be between 0 and question maximum';
  end if;

  update public.schoolpro_cbt_answers
  set marks_awarded=p_marks,
      feedback=p_feedback,
      marked_by=(select auth.uid()),
      marked_at=now(),
      is_correct=null
  where id=a.id;

  update public.schoolpro_cbt_attempts
  set score=(
    select coalesce(sum(coalesce(x.marks_awarded,0)),0)
    from public.schoolpro_cbt_answers x
    where x.attempt_id=attempt_row.id
      and exists (
        select 1 from public.schoolpro_cbt_test_questions tq
        where tq.test_id=test_row.id and tq.question_id=x.question_id
      )
  )
  where id=attempt_row.id;
end;
$function$;

revoke all on function public.mark_schoolpro_theory_answer(uuid,numeric,text)
  from public, anon;
grant execute on function public.mark_schoolpro_theory_answer(uuid,numeric,text)
  to authenticated;
