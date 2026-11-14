\set ON_ERROR_STOP on

-- Disposable PostgreSQL only. This fixture verifies the real migration and
-- the permissive RLS policy composition used by the production results table.

create role anon nologin;
create role authenticated nologin;

create schema auth;
create schema private;

create type public.user_role as enum ('super_admin');
create type public.school_member_role as enum (
  'proprietor','administrator','exam_officer','head_teacher',
  'vice_principal','teacher','class_teacher'
);

create or replace function auth.uid()
returns uuid
language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;

create table public.schoolpro_schools (
  id uuid primary key,
  owner_id uuid not null
);

create table public.schoolpro_members (
  id uuid primary key,
  school_id uuid not null references public.schoolpro_schools(id),
  user_id uuid not null,
  role public.school_member_role not null,
  position_title text,
  status text not null default 'active'
);

create table public.schoolpro_member_responsibilities (
  school_id uuid not null,
  member_id uuid not null,
  responsibility text not null,
  ended_at timestamptz
);

create table public.schoolpro_section_leaders (
  id uuid primary key,
  school_id uuid not null,
  member_id uuid not null,
  section text not null,
  ended_at timestamptz
);

create table public.schoolpro_classes (
  id uuid primary key,
  school_id uuid not null,
  level text not null
);

create table public.schoolpro_students (
  id uuid primary key,
  school_id uuid not null,
  class_id uuid not null,
  user_id uuid
);

create table public.schoolpro_results (
  id uuid primary key,
  school_id uuid not null,
  student_id uuid not null,
  subject_id uuid not null,
  session text not null,
  term text not null,
  status text not null,
  locked boolean not null default false
);

create or replace function private.is_active_account()
returns boolean language sql stable
as $$ select auth.uid() is not null $$;

create or replace function private.is_admin(p_roles public.user_role[])
returns boolean language sql stable
as $$
  select coalesce(current_setting('request.test.admin_role',true),'') =
    any(select unnest(p_roles)::text)
$$;

create or replace function private.has_school_access(
  p_school uuid,
  p_roles public.school_member_role[]
)
returns boolean language sql stable security definer
set search_path=''
as $$
  select exists(
    select 1 from public.schoolpro_schools s
    where s.id=p_school and s.owner_id=auth.uid()
  ) or exists(
    select 1 from public.schoolpro_members m
    where m.school_id=p_school and m.user_id=auth.uid()
      and m.status='active' and m.role=any(p_roles)
  )
$$;

create or replace function private.schoolpro_member_has_responsibility(
  p_school uuid,p_responsibility text
)
returns boolean language sql stable security definer
set search_path=''
as $$
  select exists(
    select 1 from public.schoolpro_members m
    join public.schoolpro_member_responsibilities r
      on r.school_id=m.school_id and r.member_id=m.id and r.ended_at is null
    where m.school_id=p_school and m.user_id=auth.uid()
      and m.status='active' and r.responsibility=p_responsibility
  )
$$;

create or replace function private.schoolpro_is_school_admin(p_school uuid)
returns boolean language sql stable security definer
set search_path=''
as $$
  select auth.uid() is not null and (
    private.is_admin(array['super_admin']::public.user_role[])
    or private.has_school_access(
      p_school,array['proprietor','administrator']::public.school_member_role[]
    )
    or private.schoolpro_member_has_responsibility(p_school,'school_admin')
  )
$$;

create or replace function private.schoolpro_is_exam_officer(p_school uuid)
returns boolean language sql stable security definer
set search_path=''
as $$
  select auth.uid() is not null and (
    exists(select 1 from public.schoolpro_members m
      where m.school_id=p_school and m.user_id=auth.uid()
        and m.status='active' and m.role='exam_officer')
    or private.schoolpro_member_has_responsibility(p_school,'exam_officer')
    or private.is_admin(array['super_admin']::public.user_role[])
  )
$$;

create or replace function private.schoolpro_operationally_active(p_school uuid)
returns boolean language sql stable
as $$ select exists(select 1 from public.schoolpro_schools where id=p_school) $$;

create or replace function private.schoolpro_module_allowed(p_school uuid,p_permission text)
returns boolean language sql stable
as $$ select true $$;

create or replace function private.schoolpro_lesson_leader(p_school uuid)
returns boolean language sql stable
as $$ select false $$;

grant usage on schema private to authenticated;

create or replace function private.schoolpro_member_leads_student_section(
  p_school uuid,p_student uuid,p_session text
)
returns boolean language sql stable security definer
set search_path=''
as $$
  select exists(
    select 1
    from public.schoolpro_members m
    join public.schoolpro_section_leaders sl
      on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
    join public.schoolpro_students st on st.school_id=p_school and st.id=p_student
    join public.schoolpro_classes c
      on c.school_id=p_school and c.id=st.class_id and c.level=sl.section
    where m.school_id=p_school and m.user_id=auth.uid()
      and m.status='active'
      and (
        m.role in ('head_teacher','vice_principal')
        or (
          m.role='administrator'
          and (
regexp_replace(lower(trim(coalesce(m.position_title,''))), '[^a-z]+', ' ', 'g')
              ~ '(^| )(principal|vice principal|head teacher|headteacher|headmaster|head master|headmistress|head mistress)( |$)'
          )
        )
      )
  )
$$;

-- Apply the exact production forward migration under test.
\ir ../supabase/migrations/20261114213000_schoolpro_section_leader_result_read_scope.sql


create or replace function private.schoolpro_member_leads_class(
  p_school uuid,p_class uuid
)
returns boolean language sql stable security definer
set search_path=''
as $$
  select exists(
    select 1 from public.schoolpro_members m
    join public.schoolpro_section_leaders sl
      on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
    join public.schoolpro_classes c
      on c.school_id=p_school and c.id=p_class and c.level=sl.section
    where m.school_id=p_school and m.user_id=auth.uid()
      and m.status='active'
      and (
        m.role in ('head_teacher','vice_principal')
        or (
          m.role='administrator'
          and (
regexp_replace(lower(trim(coalesce(m.position_title,''))), '[^a-z]+', ' ', 'g')
              ~ '(^| )(principal|vice principal|head teacher|headteacher|headmaster|head master|headmistress|head mistress)( |$)'
          )
        )
      )
  )
$$;

create or replace function private.schoolpro_can_read_student(p_student uuid)
returns boolean language sql stable security definer
set search_path=''
as $$
  select exists(
    select 1 from public.schoolpro_students s
    where s.id=p_student and (
      private.is_admin(array['super_admin']::public.user_role[])
      or private.schoolpro_is_school_admin(s.school_id)
      or private.schoolpro_is_exam_officer(s.school_id)
      or s.user_id=auth.uid()
      or private.schoolpro_member_leads_class(s.school_id,s.class_id)
    )
  )
$$;

create or replace function private.schoolpro_can_review_class(
  p_school uuid,p_class uuid
)
returns boolean language sql stable security definer
set search_path=''
as $$
  select private.schoolpro_is_school_admin(p_school)
    or private.schoolpro_is_exam_officer(p_school)
    or private.schoolpro_member_leads_class(p_school,p_class)
$$;

create or replace function private.schoolpro_can_read_result(
  p_school uuid,p_student uuid,p_subject uuid,p_session text
)
returns boolean language sql stable security definer
set search_path=''
as $$
  select private.schoolpro_can_read_student(p_student)
    and exists(
      select 1 from public.schoolpro_students s
      where s.id=p_student and s.school_id=p_school
        and private.schoolpro_can_review_class(p_school,s.class_id)
    )
$$;

create or replace function private.schoolpro_cached_result_reader_keys()
returns jsonb language sql stable
as $$ select '{}'::jsonb $$;

create or replace function private.schoolpro_result_access(
  p_student uuid,p_term text,p_session text
)
returns table(allowed boolean)
language sql stable
as $$ select true $$;

grant execute on all functions in schema private to authenticated;

alter table public.schoolpro_results enable row level security;
grant select on public.schoolpro_results to authenticated;

create policy "Result reader access"
on public.schoolpro_results for select to authenticated
using (
  case
    when school_id = any(
      (select private.schoolpro_cached_access_schools('results','result-leader'))
    ) then true
    else (
      (select private.schoolpro_cached_result_reader_keys())
        ? (student_id::text || '|*|' || session)
    )
  end
);

create policy "Result access gate"
on public.schoolpro_results for select to authenticated
using (
  (
    private.schoolpro_can_read_student(student_id)
    or private.schoolpro_member_leads_student_section(school_id,student_id,session)
  )
  and coalesce((
    select a.allowed from private.schoolpro_result_access(student_id,term,session) a
  ),false)
);

create policy "schoolpro_result_subject_scope_guard"
on public.schoolpro_results for select to authenticated
using (private.schoolpro_can_read_result(school_id,student_id,subject_id,session));

insert into public.schoolpro_schools(id,owner_id) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'),
 ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','dddddddd-dddd-4ddd-8ddd-dddddddddddd');

insert into public.schoolpro_members(id,school_id,user_id,role,position_title) values
 ('10000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111','head_teacher',null),
 ('10000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','22222222-2222-4222-8222-222222222222','head_teacher',null),
 ('10000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','33333333-3333-4333-8333-333333333333','vice_principal',null),
 ('10000000-0000-4000-8000-000000000004','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','44444444-4444-4444-8444-444444444444','exam_officer',null),
 ('10000000-0000-4000-8000-000000000005','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','55555555-5555-4555-8555-555555555555','administrator',null),
 ('10000000-0000-4000-8000-000000000006','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','66666666-6666-4666-8666-666666666666','administrator','Principal'),
 ('10000000-0000-4000-8000-000000000007','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','77777777-7777-4777-8777-777777777777','administrator','Principal');

insert into public.schoolpro_section_leaders(id,school_id,member_id,section) values
 ('20000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000001','primary'),
 ('20000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000003','junior_secondary'),
 ('20000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000006','senior_secondary');

insert into public.schoolpro_member_responsibilities(school_id,member_id,responsibility) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000005','school_admin');

insert into public.schoolpro_classes(id,school_id,level) values
 ('30000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','primary'),
 ('30000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','nursery'),
 ('30000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','junior_secondary'),
 ('30000000-0000-4000-8000-000000000004','cccccccc-cccc-4ccc-8ccc-cccccccccccc','primary'),
 ('30000000-0000-4000-8000-000000000005','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','senior_secondary');

insert into public.schoolpro_students(id,school_id,class_id) values
 ('40000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001'),
 ('40000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000002'),
 ('40000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000003'),
 ('40000000-0000-4000-8000-000000000004','cccccccc-cccc-4ccc-8ccc-cccccccccccc','30000000-0000-4000-8000-000000000004'),
 ('40000000-0000-4000-8000-000000000005','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000005');

insert into public.schoolpro_results(id,school_id,student_id,subject_id,session,term,status) values
 ('50000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','40000000-0000-4000-8000-000000000001','60000000-0000-4000-8000-000000000001','2025/2026','First','published'),
 ('50000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','40000000-0000-4000-8000-000000000002','60000000-0000-4000-8000-000000000002','2025/2026','First','published'),
 ('50000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','40000000-0000-4000-8000-000000000003','60000000-0000-4000-8000-000000000003','2025/2026','First','published'),
 ('50000000-0000-4000-8000-000000000004','cccccccc-cccc-4ccc-8ccc-cccccccccccc','40000000-0000-4000-8000-000000000004','60000000-0000-4000-8000-000000000004','2025/2026','First','published'),
 ('50000000-0000-4000-8000-000000000005','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','40000000-0000-4000-8000-000000000005','60000000-0000-4000-8000-000000000005','2025/2026','First','published');

set role authenticated;

-- Assigned Head Teacher sees only the assigned Primary result.
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results) <> 1
     or not exists(select 1 from public.schoolpro_results where id='50000000-0000-4000-8000-000000000001') then
    raise exception 'Assigned Head Teacher result visibility was not section-scoped';
  end if;
end
$test$;

-- Unassigned Head Teacher must not receive the school-wide result shortcut.
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results) <> 0 then
    raise exception 'Unassigned Head Teacher received result visibility';
  end if;
end
$test$;

-- Vice Principal sees only the assigned Junior Secondary result.
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results) <> 1
     or not exists(select 1 from public.schoolpro_results where id='50000000-0000-4000-8000-000000000003') then
    raise exception 'Assigned Vice Principal result visibility was not section-scoped';
  end if;
end
$test$;

-- Principal stored as Administrator remains restricted to the assigned section.
select set_config('request.jwt.claim.sub','66666666-6666-4666-8666-666666666666',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results) <> 1
     or not exists(select 1 from public.schoolpro_results where id='50000000-0000-4000-8000-000000000005') then
    raise exception 'Assigned Principal administrator must see only the appointed Senior Secondary result';
  end if;
end
$test$;

-- An Administrator titled Principal without an active appointment receives no result rows.
select set_config('request.jwt.claim.sub','77777777-7777-4777-8777-777777777777',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results) <> 0 then
    raise exception 'Unassigned Principal administrator received school-wide result access';
  end if;
end
$test$;

-- Exam Officer, explicit school administrator, and school owner retain school-wide access.
select set_config('request.jwt.claim.sub','44444444-4444-4444-8444-444444444444',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 4
     or exists(select 1 from public.schoolpro_results where school_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc') then
    raise exception 'Exam Officer school-wide scope or cross-school isolation failed';
  end if;
end
$test$;

select set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 4 then
    raise exception 'Explicit school administrator must retain school-wide result access';
  end if;
end
$test$;

select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 4 then
    raise exception 'School owner must retain school-wide result access';
  end if;
end
$test$;

-- Platform Super Admin retains platform-wide visibility.
select set_config('request.jwt.claim.sub','99999999-9999-4999-8999-999999999999',false);
select set_config('request.test.admin_role','super_admin',false);
do $test$
begin
  if (select count(*) from public.schoolpro_results) <> 5 then
    raise exception 'Platform Super Admin must retain cross-school result access';
  end if;
end
$test$;

reset role;
select 'PASS: section leader result reads are appointment-scoped; schoolwide authorities retain intended access' as result;
