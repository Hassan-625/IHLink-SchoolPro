-- Disposable PostgreSQL integration test. Runs only against the ephemeral CI service.
create schema private;
do $$ begin create role anon nologin; exception when duplicate_object then null; end $$;
do $$ begin create role authenticated nologin; exception when duplicate_object then null; end $$;

create table public.schoolpro_subjects (id uuid primary key, school_id uuid not null);
create table public.schoolpro_classes (id uuid primary key, school_id uuid not null);
create table public.schoolpro_students (id uuid primary key, school_id uuid not null, class_id uuid);
create table public.schoolpro_results (id uuid primary key, school_id uuid not null);
create table public.schoolpro_members (id uuid primary key, school_id uuid not null);
create table public.schoolpro_lesson_notes (id uuid primary key, school_id uuid not null, subject_id uuid, class_id uuid);
create table public.schoolpro_result_approvals (id uuid primary key, school_id uuid not null, result_id uuid not null);
create table public.schoolpro_promotions (id uuid primary key, school_id uuid not null, student_id uuid not null, from_class_id uuid, to_class_id uuid);
create policy "lesson notes authorized access" on public.schoolpro_lesson_notes for all to authenticated
  using (school_id::text = current_setting('test.school_id', true))
  with check (school_id::text = current_setting('test.school_id', true));
create policy "result approvals authorized access" on public.schoolpro_result_approvals for all to authenticated
  using (school_id::text = current_setting('test.school_id', true))
  with check (school_id::text = current_setting('test.school_id', true));
create policy "promotions authorized access" on public.schoolpro_promotions for all to authenticated
  using (school_id::text = current_setting('test.school_id', true))
  with check (school_id::text = current_setting('test.school_id', true));
create table public.schoolpro_member_permissions (id uuid primary key, school_id uuid not null, member_id uuid not null);

-- Minimal fixtures for the forward-only RLS posture repair. Keep feature policy names
-- representative of deployed semantics; the migration must not drop or rewrite policies.
create table public.schoolpro_library_books (id uuid primary key, school_id uuid not null);
create table public.schoolpro_transport_routes (id uuid primary key, school_id uuid not null);
create table public.schoolpro_hostel_rooms (id uuid primary key, school_id uuid not null);
create table public.schoolpro_inventory_assets (id uuid primary key, school_id uuid not null);
create table public.schoolpro_calendar_events (id uuid primary key, school_id uuid not null);
create policy "Families read borrowed book details" on public.schoolpro_library_books for select to authenticated
  using (school_id::text = current_setting('test.school_id', true));
create policy "library books authorized access" on public.schoolpro_library_books for all to authenticated
  using (school_id::text = current_setting('test.school_id', true))
  with check (school_id::text = current_setting('test.school_id', true));
create policy "transport routes authorized access" on public.schoolpro_transport_routes for all to authenticated
  using (school_id::text = current_setting('test.school_id', true))
  with check (school_id::text = current_setting('test.school_id', true));
create policy "hostel rooms authorized access" on public.schoolpro_hostel_rooms for all to authenticated
  using (school_id::text = current_setting('test.school_id', true))
  with check (school_id::text = current_setting('test.school_id', true));
create policy "inventory authorized access" on public.schoolpro_inventory_assets for all to authenticated
  using (school_id::text = current_setting('test.school_id', true))
  with check (school_id::text = current_setting('test.school_id', true));
create policy "calendar school read" on public.schoolpro_calendar_events for select to authenticated
  using (school_id::text = current_setting('test.school_id', true));

\ir ../supabase/migrations/20261016160000_schoolpro_repair_operational_tenant_integrity.sql
\ir ../supabase/migrations/20261017170000_schoolpro_forward_operational_tenant_isolation.sql
\ir ../supabase/migrations/20261017180000_schoolpro_operational_tenant_indexes.sql

-- Ensure every operational tenant probe has a leading school_id index.
select count(*) = 6 as tenant_indexes_present
from pg_indexes
where schemaname='public'
  and indexname = any(array[
    'schoolpro_library_books_school_id_idx',
    'schoolpro_transport_routes_school_id_idx',
    'schoolpro_hostel_rooms_school_id_idx',
    'schoolpro_inventory_assets_school_id_idx',
    'schoolpro_result_approvals_school_id_idx',
    'schoolpro_promotions_school_id_idx'
  ]) \gset
\if :tenant_indexes_present
  \echo 'PASS: all operational school_id indexes exist.'
\else
  \echo 'FAIL: missing operational school_id index.'
  \quit 1
\endif

-- The repair must preserve the live policy names/feature paths, not replace the policies
-- with the historical migration's narrower generic policy set.
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='schoolpro_library_books' and policyname='Families read borrowed book details')
     or not exists (select 1 from pg_policies where schemaname='public' and tablename='schoolpro_calendar_events' and policyname='calendar school read')
     or not exists (select 1 from pg_policies where schemaname='public' and tablename='schoolpro_transport_routes' and policyname='transport routes authorized access')
     or not exists (select 1 from pg_policies where schemaname='public' and tablename='schoolpro_hostel_rooms' and policyname='hostel rooms authorized access')
     or not exists (select 1 from pg_policies where schemaname='public' and tablename='schoolpro_inventory_assets' and policyname='inventory authorized access') then
    raise exception 'FAIL: forward-only repair removed a pre-existing feature policy';
  end if;
  if exists (
    select 1 from unnest(array[
      'schoolpro_library_books','schoolpro_transport_routes','schoolpro_hostel_rooms',
      'schoolpro_inventory_assets','schoolpro_calendar_events','schoolpro_lesson_notes',
      'schoolpro_result_approvals','schoolpro_promotions'
    ]) as x(tablename)
    left join pg_class c on c.relname=x.tablename
    left join pg_namespace n on n.oid=c.relnamespace and n.nspname='public'
    where c.oid is null or not c.relrowsecurity or not c.relforcerowsecurity
  ) then
    raise exception 'FAIL: an operational table is missing ENABLE/FORCE ROW LEVEL SECURITY';
  end if;
end $$;

insert into public.schoolpro_library_books values
 ('a1000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
 ('a1000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
insert into public.schoolpro_transport_routes values
 ('a2000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
 ('a2000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
insert into public.schoolpro_hostel_rooms values
 ('a3000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
 ('a3000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
insert into public.schoolpro_inventory_assets values
 ('a4000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
 ('a4000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
insert into public.schoolpro_calendar_events values
 ('a5000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
 ('a5000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
grant select, insert on public.schoolpro_library_books, public.schoolpro_transport_routes,
 public.schoolpro_hostel_rooms, public.schoolpro_inventory_assets, public.schoolpro_calendar_events,
 public.schoolpro_lesson_notes, public.schoolpro_result_approvals, public.schoolpro_promotions to authenticated;

-- Run the visibility assertion as the ordinary authenticated role, not as the table owner.
set role authenticated;
select set_config('test.school_id','00000000-0000-0000-0000-000000000001',false);
select (
  (select count(*) from public.schoolpro_library_books)=1 and
  (select count(*) from public.schoolpro_transport_routes)=1 and
  (select count(*) from public.schoolpro_hostel_rooms)=1 and
  (select count(*) from public.schoolpro_inventory_assets)=1 and
  (select count(*) from public.schoolpro_calendar_events)=1
) as tenant_rows_scoped \gset
\if :tenant_rows_scoped
  \echo 'PASS: authenticated role sees only its own tenant rows across operational tables.'
\else
  \echo 'FAIL: authenticated role saw missing or cross-tenant operational rows.'
  \quit 1
\endif
reset role;

\ir ../supabase/migrations/20261016160000_schoolpro_repair_operational_tenant_integrity.sql

insert into public.schoolpro_subjects values
('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
insert into public.schoolpro_classes values
('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
insert into public.schoolpro_students values
('30000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001'),
('30000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002');
insert into public.schoolpro_results values
('40000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
('40000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');
insert into public.schoolpro_members values
('50000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001'),
('50000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002'),
('50000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000001');

insert into public.schoolpro_lesson_notes values
('60000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001');
insert into public.schoolpro_result_approvals values
('70000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001');
insert into public.schoolpro_promotions values
('80000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001');

-- Add School B child rows after their referenced parent rows exist.
insert into public.schoolpro_lesson_notes values
('60000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002');
insert into public.schoolpro_result_approvals values
('70000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000002');
insert into public.schoolpro_promotions values
('80000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002');

-- Authenticated School A must see exactly its own row across all eight tables.
set role authenticated;
select set_config('test.school_id','00000000-0000-0000-0000-000000000001',false);
select (
  (select count(*) from public.schoolpro_library_books)=1 and
  (select count(*) from public.schoolpro_transport_routes)=1 and
  (select count(*) from public.schoolpro_hostel_rooms)=1 and
  (select count(*) from public.schoolpro_inventory_assets)=1 and
  (select count(*) from public.schoolpro_calendar_events)=1 and
  (select count(*) from public.schoolpro_lesson_notes)=1 and
  (select count(*) from public.schoolpro_result_approvals)=1 and
  (select count(*) from public.schoolpro_promotions)=1
) as all_eight_tenant_rows_scoped \gset
\if :all_eight_tenant_rows_scoped
  \echo 'PASS: authenticated role sees only its own tenant rows across all eight operational tables.'
\else
  \echo 'FAIL: authenticated role saw missing or cross-tenant rows in the eight operational tables.'
  \quit 1
\endif
reset role;

insert into public.schoolpro_member_permissions values
('90000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001');

create temporary table _initialize_temp_schema (id integer);
drop table _initialize_temp_schema;

create function pg_temp.assert_rejected(p_name text, p_statement text, p_expected text)
returns void language plpgsql as $$
declare actual_message text;
begin
  execute p_statement;
  raise exception 'INTEGRITY_TEST_ACCEPTED:%', p_name;
exception when others then
  get stacked diagnostics actual_message = message_text;
  if actual_message = p_expected then
    return;
  elsif actual_message = 'INTEGRITY_TEST_ACCEPTED:' || p_name then
    raise exception 'FAIL: cross-tenant operation was accepted: %', p_name;
  else
    raise exception 'FAIL: % raised unexpected error: %', p_name, actual_message;
  end if;
end;
$$;

select pg_temp.assert_rejected('cross-school subject',
  $$insert into public.schoolpro_lesson_notes values ('60000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001')$$,
  'Subject belongs to another school');
select pg_temp.assert_rejected('cross-school class',
  $$insert into public.schoolpro_lesson_notes values ('60000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002')$$,
  'Class belongs to another school');
select pg_temp.assert_rejected('missing subject',
  $$insert into public.schoolpro_lesson_notes values ('60000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000099','20000000-0000-0000-0000-000000000001')$$,
  'Subject belongs to another school');
select pg_temp.assert_rejected('cross-school result approval',
  $$insert into public.schoolpro_result_approvals values ('70000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000002')$$,
  'Result belongs to another school');
select pg_temp.assert_rejected('cross-school promotion student',
  $$insert into public.schoolpro_promotions values ('80000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001')$$,
  'Student belongs to another school');
select pg_temp.assert_rejected('cross-school promotion source class',
  $$insert into public.schoolpro_promotions values ('80000000-0000-0000-0000-000000000012','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001')$$,
  'Source class belongs to another school');
select pg_temp.assert_rejected('cross-school promotion destination class',
  $$insert into public.schoolpro_promotions values ('80000000-0000-0000-0000-000000000013','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002')$$,
  'Destination class belongs to another school');
select pg_temp.assert_rejected('cross-school permission member',
  $stmt$insert into public.schoolpro_member_permissions values ('90000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000002')$stmt$,
  'Permission member belongs to another school');

-- A permission may be reassigned to another member within the same school.
update public.schoolpro_member_permissions
set member_id='50000000-0000-0000-0000-000000000003'
where id='90000000-0000-0000-0000-000000000001';
select pg_temp.assert_rejected('permission tenant and member reassignment together',
  $stmt$update public.schoolpro_member_permissions
    set school_id='00000000-0000-0000-0000-000000000002',
        member_id='50000000-0000-0000-0000-000000000002'
    where id='90000000-0000-0000-0000-000000000001'$stmt$,
  'Permission school ownership cannot be reassigned');
select pg_temp.assert_rejected('subject parent reassignment',
  $$update public.schoolpro_subjects set school_id='00000000-0000-0000-0000-000000000002' where id='10000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('class parent reassignment',
  $$update public.schoolpro_classes set school_id='00000000-0000-0000-0000-000000000002' where id='20000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('student parent reassignment',
  $$update public.schoolpro_students set school_id='00000000-0000-0000-0000-000000000002' where id='30000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('result parent reassignment',
  $$update public.schoolpro_results set school_id='00000000-0000-0000-0000-000000000002' where id='40000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('member parent reassignment',
  $$update public.schoolpro_members set school_id='00000000-0000-0000-0000-000000000002' where id='50000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');


select pg_temp.assert_rejected('library row tenant reassignment',
  $$update public.schoolpro_library_books set school_id='00000000-0000-0000-0000-000000000002' where id='a1000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('transport row tenant reassignment',
  $$update public.schoolpro_transport_routes set school_id='00000000-0000-0000-0000-000000000002' where id='a2000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('hostel row tenant reassignment',
  $$update public.schoolpro_hostel_rooms set school_id='00000000-0000-0000-0000-000000000002' where id='a3000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('inventory row tenant reassignment',
  $$update public.schoolpro_inventory_assets set school_id='00000000-0000-0000-0000-000000000002' where id='a4000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('calendar row tenant reassignment',
  $$update public.schoolpro_calendar_events set school_id='00000000-0000-0000-0000-000000000002' where id='a5000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('lesson-note row tenant reassignment',
  $$update public.schoolpro_lesson_notes set school_id='00000000-0000-0000-0000-000000000002' where id='60000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('result-approval row tenant reassignment',
  $$update public.schoolpro_result_approvals set school_id='00000000-0000-0000-0000-000000000002' where id='70000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');
select pg_temp.assert_rejected('promotion row tenant reassignment',
  $$update public.schoolpro_promotions set school_id='00000000-0000-0000-0000-000000000002' where id='80000000-0000-0000-0000-000000000001'$$,
  'School ownership cannot be reassigned');

select 'PASS: PostgreSQL rejected cross-tenant child writes and unsafe parent reassignment.' as result;


-- Simulate a non-BYPASSRLS table-owner role. Ordinary authenticated-role checks alone
-- do not prove FORCE RLS, because PostgreSQL table owners normally bypass RLS.
do $$ begin
  create role schoolpro_test_table_owner nologin nosuperuser nobypassrls;
exception when duplicate_object then null;
end $$;
grant create on schema public to schoolpro_test_table_owner;
alter table public.schoolpro_library_books owner to schoolpro_test_table_owner;
alter table public.schoolpro_transport_routes owner to schoolpro_test_table_owner;
alter table public.schoolpro_hostel_rooms owner to schoolpro_test_table_owner;
alter table public.schoolpro_inventory_assets owner to schoolpro_test_table_owner;
alter table public.schoolpro_calendar_events owner to schoolpro_test_table_owner;
alter table public.schoolpro_lesson_notes owner to schoolpro_test_table_owner;
alter table public.schoolpro_result_approvals owner to schoolpro_test_table_owner;
alter table public.schoolpro_promotions owner to schoolpro_test_table_owner;
revoke create on schema public from schoolpro_test_table_owner;

set role schoolpro_test_table_owner;
select (
  (select count(*) from public.schoolpro_library_books)=0 and
  (select count(*) from public.schoolpro_transport_routes)=0 and
  (select count(*) from public.schoolpro_hostel_rooms)=0 and
  (select count(*) from public.schoolpro_inventory_assets)=0 and
  (select count(*) from public.schoolpro_calendar_events)=0 and
  (select count(*) from public.schoolpro_lesson_notes)=0 and
  (select count(*) from public.schoolpro_result_approvals)=0 and
  (select count(*) from public.schoolpro_promotions)=0
) as forced_rls_blocks_non_bypass_table_owner \gset
\if :forced_rls_blocks_non_bypass_table_owner
  \echo 'PASS: FORCE RLS blocks a non-BYPASSRLS table owner from reading tenant rows without an applicable policy.'
\else
  \echo 'FAIL: a non-BYPASSRLS table owner bypassed forced RLS.'
  \quit 1
\endif
reset role;


-- Combined feature-trigger stack checks. These run after the original positional fixture
-- inserts so the additional workflow columns do not change those earlier fixture shapes.
-- The workflow function below mirrors the production lesson workflow guard; helper scopes
-- are deterministic test doubles, while the tenant-integrity migration remains real.
create schema if not exists auth;
create or replace function auth.uid()
returns uuid language sql stable
as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;

alter table public.schoolpro_lesson_notes
  add column title text,
  add column content text,
  add column status text not null default 'draft',
  add column created_by uuid,
  add column lesson_date date,
  add column term text,
  add column session text,
  add column week integer,
  add column duration_minutes integer,
  add column plan jsonb not null default '{}'::jsonb,
  add column review_comment text,
  add column reviewed_by uuid,
  add column reviewed_at timestamptz,
  add column updated_at timestamptz not null default now();

create or replace function private.schoolpro_lesson_leader(p_school uuid)
returns boolean language sql stable
as $$ select coalesce(nullif(current_setting('test.lesson_leader', true), '')::boolean, false) $$;
create or replace function private.schoolpro_lesson_author_scope(p_school uuid, p_class uuid, p_subject uuid)
returns boolean language sql stable
as $$ select p_class is not null and p_subject is not null $$;

create or replace function private.schoolpro_validate_lesson_workflow()
returns trigger language plpgsql security definer set search_path='' as $$
declare leader boolean;
begin
 if auth.uid() is null then raise exception 'Sign in to manage lesson notes'; end if;
 leader:=private.schoolpro_lesson_leader(case when tg_op='DELETE' then old.school_id else new.school_id end);
 if tg_op='DELETE' then
  if old.status in('submitted','approved') then raise exception 'Reviewed or submitted lessons must be retained'; end if;
  return old;
 end if;
 if new.status not in('draft','submitted','approved','changes_requested') then raise exception 'Choose a valid lesson status'; end if;
 if tg_op='INSERT' then
  new.created_by:=auth.uid();
  if new.status not in('draft','submitted') then raise exception 'Save a draft or submit it for review first'; end if;
  new.review_comment:=null;new.reviewed_by:=null;new.reviewed_at:=null;
 else
  if new.school_id<>old.school_id or new.created_by is distinct from old.created_by then raise exception 'Lesson ownership cannot be changed'; end if;
  if old.status='approved' then raise exception 'Approved lessons must be retained; prepare a new copy'; end if;
  if not leader then
   if old.status='submitted' then raise exception 'Wait for school review before editing this lesson'; end if;
   if new.status not in('draft','submitted') then raise exception 'Only school leadership can review a lesson'; end if;
   if new.review_comment is distinct from old.review_comment or new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at then raise exception 'School review cannot be changed'; end if;
  elsif new.status in('approved','changes_requested') and new.status is distinct from old.status then
   if old.status<>'submitted' then raise exception 'Only a submitted lesson can be reviewed'; end if;
   if new.status='changes_requested' and coalesce(trim(new.review_comment),'')='' then raise exception 'Explain the changes needed'; end if;
   if (to_jsonb(new)-array['status','review_comment','reviewed_by','reviewed_at','updated_at']) is distinct from (to_jsonb(old)-array['status','review_comment','reviewed_by','reviewed_at','updated_at']) then raise exception 'Review the saved lesson without changing its content'; end if;
   new.reviewed_by:=auth.uid();new.reviewed_at:=now();
  elsif old.status='submitted' then raise exception 'Approve the lesson or request changes'; end if;
 end if;
 if not leader and not private.schoolpro_lesson_author_scope(new.school_id,new.class_id,new.subject_id) then raise exception 'Choose your assigned class and subject'; end if;
 if new.week is not null and (new.week<1 or new.week>53) then raise exception 'Week must be between 1 and 53'; end if;
 if new.duration_minutes is not null and (new.duration_minutes<1 or new.duration_minutes>480) then raise exception 'Choose a lesson duration between 1 and 480 minutes'; end if;
 if jsonb_typeof(new.plan)<>'object' then raise exception 'Lesson plan must contain named fields'; end if;
 if new.status='submitted' and (new.class_id is null or new.subject_id is null or new.lesson_date is null or coalesce(trim(new.term),'')='' or coalesce(trim(new.session),'')='' or coalesce(trim(new.title),'')='' or coalesce(trim(new.plan->>'objectives'),'')='' or coalesce(trim(new.content),'')='') then raise exception 'Complete the class, subject, date, period, objectives and lesson content before submission'; end if;
 new.updated_at:=now();return new;
end;
$$;
drop trigger if exists schoolpro_lesson_workflow on public.schoolpro_lesson_notes;
create trigger schoolpro_lesson_workflow before insert or update or delete
on public.schoolpro_lesson_notes for each row execute function private.schoolpro_validate_lesson_workflow();

-- Verify ordinary lesson author save/submit, author self-approval rejection, immutable
-- submitted content, and leadership approval alongside the real tenant guard trigger.
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000101',false);
select set_config('test.lesson_leader','false',false);
insert into public.schoolpro_lesson_notes
 (id,school_id,subject_id,class_id,title,content,lesson_date,term,session,plan,status)
values
 ('60000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',
  'Trigger-stack lesson','Draft content',current_date,'First Term','2026/2027',
  '{"objectives":"Explain the topic"}','draft');
select pg_temp.assert_rejected('lesson author cannot self-approve',
 $$update public.schoolpro_lesson_notes set status='approved' where id='60000000-0000-0000-0000-000000000101'$$,
 'Only school leadership can review a lesson');
update public.schoolpro_lesson_notes set status='submitted'
where id='60000000-0000-0000-0000-000000000101';
select pg_temp.assert_rejected('submitted lesson content is immutable to author',
 $$update public.schoolpro_lesson_notes set content='Changed after submission' where id='60000000-0000-0000-0000-000000000101'$$,
 'Wait for school review before editing this lesson');
select set_config('request.jwt.claim.sub','60000000-0000-0000-0000-000000000102',false);
select set_config('test.lesson_leader','true',false);
update public.schoolpro_lesson_notes set status='approved'
where id='60000000-0000-0000-0000-000000000101';
do $$ begin
 if not exists(select 1 from public.schoolpro_lesson_notes where id='60000000-0000-0000-0000-000000000101' and status='approved' and reviewed_by='60000000-0000-0000-0000-000000000102') then
  raise exception 'FAIL: leadership approval did not retain reviewer identity';
 end if;
end $$;

-- The production calendar workflow function's validation contract is exercised with a
-- compact disposable equivalent, alongside the real immutable-school tenant guard.
alter table public.schoolpro_calendar_events
 add column event_date date,
 add column end_date date,
 add column class_id uuid;
create or replace function private.validate_schoolpro_workflow_record()
returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='UPDATE' and new.school_id is distinct from old.school_id then
  raise exception 'A record cannot be moved to another school';
 end if;
 if new.end_date<new.event_date then raise exception 'The event end date must not be before its start date'; end if;
 if new.class_id is not null and not exists(select 1 from public.schoolpro_classes where id=new.class_id and school_id=new.school_id) then
  raise exception 'Choose a class from this school';
 end if;
 return new;
end;
$$;
drop trigger if exists validate_schoolpro_calendar_workflow on public.schoolpro_calendar_events;
create trigger validate_schoolpro_calendar_workflow before insert or update
on public.schoolpro_calendar_events for each row execute function private.validate_schoolpro_workflow_record();

insert into public.schoolpro_calendar_events(id,school_id,event_date,end_date,class_id)
values ('a5000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000001',current_date,current_date,'20000000-0000-0000-0000-000000000001');
select pg_temp.assert_rejected('calendar rejects reversed date range',
 $$insert into public.schoolpro_calendar_events(id,school_id,event_date,end_date) values ('a5000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000001',current_date,current_date-1)$$,
 'The event end date must not be before its start date');
select pg_temp.assert_rejected('calendar rejects foreign-school class',
 $$insert into public.schoolpro_calendar_events(id,school_id,event_date,end_date,class_id) values ('a5000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000001',current_date,current_date,'20000000-0000-0000-0000-000000000002')$$,
 'Choose a class from this school');
select pg_temp.assert_rejected('calendar tenant reassignment remains blocked with workflow trigger',
 $$update public.schoolpro_calendar_events set school_id='00000000-0000-0000-0000-000000000002' where id='a5000000-0000-0000-0000-000000000101'$$,
 'School ownership cannot be reassigned');
