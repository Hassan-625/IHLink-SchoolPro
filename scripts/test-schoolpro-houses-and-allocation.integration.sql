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
 member_id uuid := '20000000-0000-4000-8000-000000000002';
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
  (member_id,school,teacher_id,'teacher'),
  ('20000000-0000-4000-8000-000000000003',school,admin_id,'administrator');
 insert into public.schoolpro_students values
  (student_a,school,null,'active'),(student_b,school,null,'active'),(student_c,school,null,'active');
 if (select count(distinct house_id) from public.schoolpro_student_house_history where school_id=school and effective_to is null) <> 3 then
   raise exception 'ASSERT: automatic allocation did not distribute students across the least-populated houses';
 end if;
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform public.schoolpro_set_house_master(school,red,member_id);
 if not exists(select 1 from public.schoolpro_house_master_assignments where school_id=school and house_id=red and member_id=member_id and ended_at is null) then
   raise exception 'ASSERT: eligible teaching staff was not appointed as House Master';
 end if;
 begin
   perform public.schoolpro_set_house_master(school_b,red,member_id);
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
 update public.schoolpro_members set role='administrator' where id=member_id;
 if exists(select 1 from public.schoolpro_house_master_assignments where member_id=member_id and ended_at is null) then
   raise exception 'ASSERT: House Master appointment survived teaching-role downgrade';
 end if;
end
$test$;
select 'PASS: default houses, balanced automatic allocation, manual reassignment history, House Master eligibility and downgrade cleanup' as result;
