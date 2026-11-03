\set ON_ERROR_STOP on

create role anon nologin;
create role authenticated nologin;
create schema auth;
create schema private;
create table auth.users(id uuid primary key, email text, raw_user_meta_data jsonb default '{}'::jsonb);
create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

create type public.school_member_role as enum
  ('proprietor','administrator','head_teacher','vice_principal','registrar','teacher','class_teacher');
create type public.user_role as enum ('super_admin','customer');

create table public.profiles(
  id uuid primary key, email text, first_name text, last_name text,
  requested_service text, role public.user_role
);
create table public.datasub_wallets(user_id uuid primary key);
create table public.admin_product_access(
  user_id uuid, product text, can_view boolean, can_edit boolean, can_approve boolean,
  primary key(user_id,product)
);
create table public.schoolpro_schools(id uuid primary key);
create table public.schoolpro_classes(
  id uuid primary key, school_id uuid not null references public.schoolpro_schools(id),
  form_teacher_id uuid
);
create table public.schoolpro_subjects(
  id uuid primary key, school_id uuid not null references public.schoolpro_schools(id)
);
create table public.schoolpro_members(
  id uuid primary key, school_id uuid not null references public.schoolpro_schools(id),
  role public.school_member_role not null
);
create table public.schoolpro_students(
  id uuid primary key, school_id uuid not null references public.schoolpro_schools(id),
  class_id uuid references public.schoolpro_classes(id)
);
create or replace function private.has_school_access(
  p_school uuid, p_roles public.school_member_role[] default null
) returns boolean language sql stable as $$ select true $$;

-- Execute the original migration to prove the replacement works against its real
-- table and trigger definitions, then install the proposed corrected function.
\ir ../supabase/migrations/20260916190636_school_academics_attendance_and_superadmin_access.sql
\ir ../supabase/migrations/20261103110000_schoolpro_subject_assignment_teaching_role_guard.sql
\ir ../supabase/migrations/20261103130000_schoolpro_clear_ineligible_form_master.sql

do $test$
declare
  school_a uuid := 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  school_b uuid := 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  class_a uuid := '11111111-1111-4111-8111-111111111111';
  class_b uuid := '22222222-2222-4222-8222-222222222222';
  subject_a uuid := '33333333-3333-4333-8333-333333333333';
  subject_b uuid := '44444444-4444-4444-8444-444444444444';
  teacher_a uuid := '55555555-5555-4555-8555-555555555551';
  class_teacher_a uuid := '55555555-5555-4555-8555-555555555552';
  admin_a uuid := '55555555-5555-4555-8555-555555555553';
  teacher_b uuid := '55555555-5555-4555-8555-555555555554';
  assignment_id uuid;
begin
  insert into public.schoolpro_schools values (school_a),(school_b);
  insert into public.schoolpro_classes values (class_a,school_a),(class_b,school_b);
  insert into public.schoolpro_subjects values (subject_a,school_a),(subject_b,school_b);
  insert into public.schoolpro_members values
    (teacher_a,school_a,'teacher'),
    (class_teacher_a,school_a,'class_teacher'),
    (admin_a,school_a,'administrator'),
    (teacher_b,school_b,'teacher');

  -- Both supported teaching roles are accepted.
  insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,teacher_member_id,session)
  values(school_a,class_a,subject_a,teacher_a,'2026/2027')
  returning id into assignment_id;

  update public.schoolpro_subject_assignments
  set teacher_member_id=class_teacher_a
  where id=assignment_id;

  -- A null teacher is a valid unassigned allocation.
  update public.schoolpro_subject_assignments
  set teacher_member_id=null
  where id=assignment_id;

  -- Form Master is an active teaching responsibility. Demotion clears the
  -- current class assignment, while subject allocation history is retained.
  update public.schoolpro_subject_assignments
  set teacher_member_id=teacher_a
  where id=assignment_id;
  update public.schoolpro_classes set form_teacher_id=teacher_a where id=class_a;
  update public.schoolpro_members set role='administrator' where id=teacher_a;
  if (select form_teacher_id from public.schoolpro_classes where id=class_a) is not null then
    raise exception 'ASSERT: Form Master assignment survived a move out of teaching roles';
  end if;
  if (select teacher_member_id from public.schoolpro_subject_assignments where id=assignment_id) is distinct from teacher_a then
    raise exception 'ASSERT: historical subject allocation was unexpectedly deleted';
  end if;

  -- Leadership roles are not eligible teaching allocations.
  begin
    insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,teacher_member_id,session)
    values(school_a,class_a,subject_a,admin_a,'2027/2028');
    raise exception 'ASSERT: administrator was accepted as an assigned teacher';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('eligible teaching member' in sqlerrm)=0 then raise; end if;
  end;

  -- Foreign-school member is rejected.
  begin
    insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,teacher_member_id,session)
    values(school_a,class_a,subject_a,teacher_b,'2027/2028');
    raise exception 'ASSERT: cross-school teacher was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('eligible teaching member' in sqlerrm)=0 then raise; end if;
  end;

  -- Cross-school class and subject references are rejected independently.
  begin
    insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,session)
    values(school_a,class_b,subject_a,'2027/2028');
    raise exception 'ASSERT: cross-school class was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Class and subject must belong' in sqlerrm)=0 then raise; end if;
  end;

  begin
    insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,session)
    values(school_a,class_a,subject_b,'2027/2028');
    raise exception 'ASSERT: cross-school subject was accepted';
  exception when others then
    if sqlerrm like 'ASSERT:%' then raise; end if;
    if position('Class and subject must belong' in sqlerrm)=0 then raise; end if;
  end;
end;
$test$;

select 'PASS: subject assignment trigger enforces teaching roles and tenant boundaries; Form Master assignment clears on role downgrade while subject allocation history remains.' as result;
