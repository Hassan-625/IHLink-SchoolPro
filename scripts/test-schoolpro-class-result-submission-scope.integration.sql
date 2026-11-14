\set ON_ERROR_STOP on

-- Disposable PostgreSQL only. Exercise the production policy migration with
-- the current class-review authorization contract and multiple school roles.

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
returns uuid language sql stable
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
  level text not null,
  form_teacher_id uuid
);

create table public.schoolpro_class_result_submissions (
  id uuid primary key,
  school_id uuid not null,
  class_id uuid not null,
  term text not null,
  session text not null,
  submitted_by uuid not null,
  submitted_at timestamptz not null default now(),
  score_fingerprint text not null
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
  p_school uuid,p_roles public.school_member_role[]
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

create or replace function private.schoolpro_member_leads_class(
  p_school uuid,p_class uuid
)
returns boolean language sql stable security definer
set search_path=''
as $$
  select exists(
    select 1
    from public.schoolpro_members m
    join public.schoolpro_section_leaders sl
      on sl.school_id=m.school_id and sl.member_id=m.id and sl.ended_at is null
    join public.schoolpro_classes c
      on c.school_id=p_school and c.id=p_class and c.level=sl.section
    where m.school_id=p_school and m.user_id=auth.uid()
      and m.status='active'
      and m.role <> 'teacher'
      and (
        (m.role='administrator' and lower(coalesce(m.position_title,''))='principal')
        or not exists(
          select 1
          from public.schoolpro_section_leaders principal_sl
          join public.schoolpro_members principal_m
            on principal_m.id=principal_sl.member_id
           and principal_m.school_id=principal_sl.school_id
          where principal_sl.school_id=p_school
            and principal_sl.section=sl.section
            and principal_sl.ended_at is null
            and principal_m.status='active'
            and principal_m.role='administrator'
            and lower(coalesce(principal_m.position_title,''))='principal'
        )
      )
  )
$$;

-- This mirrors the production helper: review is class-bound for section leaders
-- and Form Masters, while school administrators, owners and Exam Officers retain
-- their explicitly authorized school-wide scope.
create or replace function private.schoolpro_can_read_class_result_submission(
  p_school uuid,p_class uuid
)
returns boolean language sql stable security definer
set search_path=''
as $$
  select auth.uid() is not null
    and private.is_active_account()
    and private.schoolpro_operationally_active(p_school)
    and private.schoolpro_module_allowed(p_school,'results')
    and exists(select 1 from public.schoolpro_classes c
      where c.school_id=p_school and c.id=p_class)
    and (
      private.is_admin(array['super_admin']::public.user_role[])
      or exists(select 1 from public.schoolpro_schools s
        where s.id=p_school and s.owner_id=auth.uid())
      or exists(select 1 from public.schoolpro_members m
        where m.school_id=p_school and m.user_id=auth.uid()
          and m.status='active' and m.role='proprietor')
      or private.schoolpro_member_has_responsibility(p_school,'school_admin')
      or private.schoolpro_is_exam_officer(p_school)
      or exists(select 1 from public.schoolpro_members m
        where m.school_id=p_school and m.user_id=auth.uid()
          and m.status='active' and m.role='administrator'
          and not (
            regexp_replace(lower(trim(coalesce(m.position_title,''))), '[^a-z]+', ' ', 'g')
              ~ '(^| )(principal|vice principal|head teacher|headteacher|headmaster|head master|headmistress|head mistress)( |$)'
          ))
      or private.schoolpro_member_leads_class(p_school,p_class)
      or exists(select 1
        from public.schoolpro_classes c
        join public.schoolpro_members m
          on m.id=c.form_teacher_id and m.school_id=c.school_id
        where c.id=p_class and c.school_id=p_school
          and m.user_id=auth.uid() and m.status='active')
    )
$$;

grant usage on schema private to authenticated;
alter table public.schoolpro_class_result_submissions enable row level security;
grant select on public.schoolpro_class_result_submissions to authenticated;

-- Apply the exact production policy migration.
\ir ../supabase/migrations/20261114220000_schoolpro_class_result_submission_scope.sql

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
 ('10000000-0000-4000-8000-000000000007','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','77777777-7777-4777-8777-777777777777','administrator','Principal'),
 ('10000000-0000-4000-8000-000000000008','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','88888888-8888-4888-8888-888888888888','class_teacher',null),
 ('10000000-0000-4000-8000-000000000009','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','99999999-9999-4999-8999-999999999999','teacher',null);

insert into public.schoolpro_section_leaders(id,school_id,member_id,section) values
 ('20000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000001','primary'),
 ('20000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000003','junior_secondary'),
 ('20000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000006','senior_secondary');

insert into public.schoolpro_member_responsibilities(school_id,member_id,responsibility) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','10000000-0000-4000-8000-000000000005','school_admin');

insert into public.schoolpro_classes(id,school_id,level,form_teacher_id) values
 ('30000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','primary','10000000-0000-4000-8000-000000000008'),
 ('30000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','nursery',null),
 ('30000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','junior_secondary',null),
 ('30000000-0000-4000-8000-000000000004','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','senior_secondary',null),
 ('30000000-0000-4000-8000-000000000005','cccccccc-cccc-4ccc-8ccc-cccccccccccc','primary',null);

insert into public.schoolpro_class_result_submissions(
  id,school_id,class_id,term,session,submitted_by,score_fingerprint
) values
 ('40000000-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000001','First','2025/2026','11111111-1111-4111-8111-111111111111','hash-1'),
 ('40000000-0000-4000-8000-000000000002','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000002','First','2025/2026','22222222-2222-4222-8222-222222222222','hash-2'),
 ('40000000-0000-4000-8000-000000000003','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000003','First','2025/2026','33333333-3333-4333-8333-333333333333','hash-3'),
 ('40000000-0000-4000-8000-000000000004','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','30000000-0000-4000-8000-000000000004','First','2025/2026','66666666-6666-4666-8666-666666666666','hash-4'),
 ('40000000-0000-4000-8000-000000000005','cccccccc-cccc-4ccc-8ccc-cccccccccccc','30000000-0000-4000-8000-000000000005','First','2025/2026','dddddddd-dddd-4ddd-8ddd-dddddddddddd','hash-5');

set role authenticated;

-- Assigned Head Teacher is restricted to the appointed Primary class.
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions) <> 1
     or not exists(select 1 from public.schoolpro_class_result_submissions where class_id='30000000-0000-4000-8000-000000000001') then
    raise exception 'Assigned Head Teacher submission visibility was not class-scoped';
  end if;
end
$test$;

-- Unassigned Head Teacher must not receive school-wide submission visibility.
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions) <> 0 then
    raise exception 'Unassigned Head Teacher received school-wide submission access';
  end if;
end
$test$;

-- Assigned Vice Principal is limited to the Junior Secondary section.
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions) <> 1
     or not exists(select 1 from public.schoolpro_class_result_submissions where class_id='30000000-0000-4000-8000-000000000003') then
    raise exception 'Assigned Vice Principal submission visibility was not section-scoped';
  end if;
end
$test$;

-- Principal with an appointment sees only the assigned Senior Secondary class.
select set_config('request.jwt.claim.sub','66666666-6666-4666-8666-666666666666',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions) <> 1
     or not exists(select 1 from public.schoolpro_class_result_submissions where class_id='30000000-0000-4000-8000-000000000004') then
    raise exception 'Appointed Principal submission visibility was not section-scoped';
  end if;
end
$test$;

-- Principal title without a live appointment is not a school-wide authority.
select set_config('request.jwt.claim.sub','77777777-7777-4777-8777-777777777777',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions) <> 0 then
    raise exception 'Unappointed Principal received school-wide submission access';
  end if;
end
$test$;

-- Form Master can review only the class whose form-teacher appointment is current.
select set_config('request.jwt.claim.sub','88888888-8888-4888-8888-888888888888',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions) <> 1
     or not exists(select 1 from public.schoolpro_class_result_submissions where class_id='30000000-0000-4000-8000-000000000001') then
    raise exception 'Form Master submission visibility was not class-scoped';
  end if;
end
$test$;

-- Subject Teacher membership alone does not grant class-wide submission access.
select set_config('request.jwt.claim.sub','99999999-9999-4999-8999-999999999999',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions) <> 0 then
    raise exception 'Subject Teacher membership received class-wide submission access';
  end if;
end
$test$;

-- Exam Officer, explicit school administrator and school owner retain school scope.
select set_config('request.jwt.claim.sub','44444444-4444-4444-8444-444444444444',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 4
     or exists(select 1 from public.schoolpro_class_result_submissions where school_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc') then
    raise exception 'Exam Officer submission scope or tenant isolation failed';
  end if;
end
$test$;

select set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 4 then
    raise exception 'Explicit school administrator must retain school-wide submission access';
  end if;
end
$test$;

select set_config('request.jwt.claim.sub','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions where school_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 4 then
    raise exception 'School owner must retain school-wide submission access';
  end if;
end
$test$;

-- Platform Super Admin retains platform-wide visibility.
select set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false);
select set_config('request.test.admin_role','super_admin',false);
do $test$
begin
  if (select count(*) from public.schoolpro_class_result_submissions) <> 5 then
    raise exception 'Platform Super Admin must retain cross-school submission access';
  end if;
end
$test$;

reset role;
select 'PASS: class-result submission reads are reviewer-, section-, class- and tenant-scoped' as result;
