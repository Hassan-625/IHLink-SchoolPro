\set ON_ERROR_STOP on
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
create schema auth;
create schema private;
create table auth.users(id uuid primary key);
create or replace function auth.uid() returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
create type public.school_member_role as enum ('proprietor','administrator','teacher','class_teacher','discipline_master','game_master');
create table public.schoolpro_schools(id uuid primary key, owner_id uuid);
create table public.schoolpro_members(id uuid primary key,school_id uuid not null references public.schoolpro_schools(id),user_id uuid not null references auth.users(id),role public.school_member_role not null);
create table public.schoolpro_classes(id uuid primary key,school_id uuid not null references public.schoolpro_schools(id),name text,arm text,level text);
create table public.schoolpro_students(id uuid primary key,school_id uuid not null references public.schoolpro_schools(id),class_id uuid references public.schoolpro_classes(id),status text not null);
create or replace function private.schoolpro_module_allowed(p_school uuid,p_module text) returns boolean language sql stable as $$
 select exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
 or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and (
   (p_module='games' and m.role in ('game_master','administrator','proprietor')) or
   (p_module='students' and m.role in ('administrator','proprietor','teacher','class_teacher','game_master'))
 ))
$$;
\ir ../supabase/migrations/20261103142000_schoolpro_houses_and_student_house_history.sql

do $test$
declare
 school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
 school_b uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
 owner_id uuid := '10000000-0000-4000-8000-000000000001';
 teacher_id uuid := '10000000-0000-4000-8000-000000000002';
 admin_id uuid := '10000000-0000-4000-8000-000000000003';
 teacher_member_id uuid := '20000000-0000-4000-8000-000000000002';
 student_a uuid := '30000000-0000-4000-8000-000000000001';
 student_b uuid := '30000000-0000-4000-8000-000000000002';
 student_c uuid := '30000000-0000-4000-8000-000000000003';
 red uuid; green uuid; blue uuid; yellow uuid;
begin
 insert into auth.users values(owner_id),(teacher_id),(admin_id);
 insert into public.schoolpro_schools values(school,owner_id),(school_b,null);
 if (select count(*) from public.schoolpro_houses where school_id=school) <> 4 then
   raise exception 'ASSERT: four default houses were not seeded';
 end if;
 select id into red from public.schoolpro_houses where school_id=school and code='red';
 select id into green from public.schoolpro_houses where school_id=school and code='green';
 select id into blue from public.schoolpro_houses where school_id=school and code='blue';
 select id into yellow from public.schoolpro_houses where school_id=school and code='yellow';
 insert into public.schoolpro_members values
  (teacher_member_id,school,teacher_id,'teacher'),
  ('20000000-0000-4000-8000-000000000003',school,admin_id,'administrator');
 insert into public.schoolpro_students values
  (student_a,school,null,'active'),(student_b,school,null,'active'),(student_c,school,null,'active');
 if (select count(distinct house_id) from public.schoolpro_student_house_history where school_id=school and effective_to is null) <> 3 then
   raise exception 'ASSERT: automatic allocation did not distribute students across the least-populated houses';
 end if;
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform public.schoolpro_set_house_master(school,red,teacher_member_id);
 if not exists(select 1 from public.schoolpro_house_master_assignments where school_id=school and house_id=red and teacher_member_id=teacher_member_id and ended_at is null) then
   raise exception 'ASSERT: eligible teaching staff was not appointed as House Master';
 end if;
 begin
   perform public.schoolpro_set_house_master(school_b,red,teacher_member_id);
   raise exception 'ASSERT: cross-school house assignment succeeded';
 exception when others then
   if sqlerrm like 'ASSERT:%' then raise; end if;
 end;
 perform public.schoolpro_assign_student_house(student_a,blue,'Legacy student manual placement');
 if not exists(select 1 from public.schoolpro_student_house_history where student_id=student_a and house_id=blue and assignment_type='manual' and effective_to is null) then
   raise exception 'ASSERT: manual house assignment did not become current';
 end if;
 if not exists(select 1 from public.schoolpro_student_house_history where student_id=student_a and house_id<>blue and effective_to is not null) then
   raise exception 'ASSERT: previous house assignment history was overwritten';
 end if;
 update public.schoolpro_members set role='administrator' where id=teacher_member_id;
 if exists(select 1 from public.schoolpro_house_master_assignments where teacher_member_id=teacher_member_id and ended_at is null) then
   raise exception 'ASSERT: House Master appointment survived teaching-role downgrade';
 end if;
end
$test$;
select 'PASS: default houses, balanced automatic allocation, manual reassignment history, House Master eligibility and downgrade cleanup' as result;


\ir ../supabase/migrations/20261103143000_schoolpro_competitions_staff_judges_scoring_and_house_points.sql

do $competition_test$
declare
  school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  school_b uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  owner_id uuid := '10000000-0000-4000-8000-000000000001';
  teacher_id uuid := '10000000-0000-4000-8000-000000000002';
  competition_event_id uuid;
  criterion_id uuid;
  entry_id uuid;
  judge_id uuid;
  competition_house_id uuid;
  score_id uuid;
  award_id uuid;
begin
  select id into competition_house_id from public.schoolpro_houses where school_id=school and code='red';
  insert into public.schoolpro_competition_events(school_id,title,event_type,status,judging_guidelines,rules)
  values(school,'Inter-house Debate','debate','open','Evidence, clarity, rebuttal and respectful conduct','{"format":"team debate"}'::jsonb)
  returning id into competition_event_id;
  insert into public.schoolpro_competition_criteria(school_id,event_id,name,description,max_points,weight)
  values(school,competition_event_id,'Argument quality','Reasoning and evidence',40,1.5)
  returning id into criterion_id;
  insert into public.schoolpro_competition_entries(school_id,event_id,house_id,entry_name)
  values(school,competition_event_id,competition_house_id,'Red House Debate Team') returning id into entry_id;
  perform set_config('request.jwt.claim.sub',owner_id::text,true);
  judge_id := public.schoolpro_assign_competition_judge(school,competition_event_id,
    '20000000-0000-4000-8000-000000000002','chief_judge');
  if judge_id is null or not exists(select 1 from public.schoolpro_competition_judges where id=judge_id and member_id='20000000-0000-4000-8000-000000000002' and panel_role='chief_judge' and ended_at is null) then
    raise exception 'ASSERT: staff judge was not assigned to the event panel';
  end if;
  perform set_config('request.jwt.claim.sub',teacher_id::text,true);
  score_id := public.schoolpro_record_competition_score(school,competition_event_id,entry_id,criterion_id,35,'Strong evidence and rebuttal');
  if not exists(select 1 from public.schoolpro_competition_scores where id=score_id and judge_assignment_id=judge_id and points=35) then
    raise exception 'ASSERT: assigned staff judge score was not recorded';
  end if;
  begin
    perform public.schoolpro_record_competition_score(school,competition_event_id,entry_id,criterion_id,41,'Over maximum');
    raise exception 'ASSERT: score above rubric maximum was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub',owner_id::text,true);
  award_id := public.schoolpro_award_house_points(school,competition_house_id,10,'Debate participation and result',competition_event_id,entry_id);
  if not exists(select 1 from public.schoolpro_house_point_ledger where schoolpro_house_point_ledger.id=award_id and points=10 and schoolpro_house_point_ledger.event_id=competition_event_id) then
    raise exception 'ASSERT: house points were not ledgered against the competition';
  end if;
  if not exists(select 1 from public.schoolpro_house_competition_standings where schoolpro_house_competition_standings.school_id=school and schoolpro_house_competition_standings.house_id=competition_house_id and total_points=10) then
    raise exception 'ASSERT: house competition standings did not include awarded points';
  end if;
  begin
    insert into public.schoolpro_competition_entries(school_id,event_id,house_id,entry_name)
    values(school,competition_event_id,(select id from public.schoolpro_houses where school_id=school_b limit 1),'Foreign house entry');
    raise exception 'ASSERT: cross-school house entry was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
  end;
end
$competition_test$;
select 'PASS: staff judge panels, rubric scoring limits, tenant-safe entries, house point ledger and standings' as result;


\ir ../supabase/migrations/20261103144000_schoolpro_competition_result_approval_and_publication.sql

-- Versioned weighted result calculation, explicit approval and publication.
do $results_test$
declare
  school uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  owner_id uuid := '10000000-0000-4000-8000-000000000001';
  teacher_id uuid := '10000000-0000-4000-8000-000000000002';
  event_id uuid;
  run_id uuid;
begin
  select id into event_id from public.schoolpro_competition_events
    where school_id=school and title='Inter-house Debate';
  update public.schoolpro_competition_events set status='completed' where id=event_id;
  perform set_config('request.jwt.claim.sub',owner_id::text,true);
  run_id := public.schoolpro_calculate_competition_results(school,event_id);
  if not exists(select 1 from public.schoolpro_competition_result_entries
    where result_run_id=run_id and entry_name='Red House Debate Team'
      and is_complete and score_percent=87.50 and result_position=1) then
    raise exception 'ASSERT: weighted rubric score or ranking was calculated incorrectly';
  end if;
  begin
    perform set_config('request.jwt.claim.sub',teacher_id::text,true);
    perform public.schoolpro_approve_competition_results(school,run_id);
    raise exception 'ASSERT: a judge without Games management permission approved results';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
  end;
  perform set_config('request.jwt.claim.sub',owner_id::text,true);
  perform public.schoolpro_approve_competition_results(school,run_id);
  perform public.schoolpro_publish_competition_results(school,run_id);
  if not exists(select 1 from public.schoolpro_competition_result_runs
    where id=run_id and status='published' and approved_by=owner_id and published_by=owner_id) then
    raise exception 'ASSERT: result approval/publication audit trail was not recorded';
  end if;
  if not exists(select 1 from public.schoolpro_competition_result_entries
    where result_run_id=run_id and result_position=1 and score_percent=87.50) then
    raise exception 'ASSERT: published result snapshot was not retained';
  end if;
end
$results_test$;
select 'PASS: weighted competition results, role-gated approval, publication and immutable result snapshot' as result;
