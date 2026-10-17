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
do $$
begin
  if not exists (select 1 from pg_indexes where schemaname='public' and indexname='schoolpro_library_books_school_id_idx')
     or not exists (select 1 from pg_indexes where schemaname='public' and indexname='schoolpro_transport_routes_school_id_idx')
     or not exists (select 1 from pg_indexes where schemaname='public' and indexname='schoolpro_hostel_rooms_school_id_idx')
     or not exists (select 1 from pg_indexes where schemaname='public' and indexname='schoolpro_inventory_assets_school_id_idx')
     or not exists (select 1 from pg_indexes where schemaname='public' and indexname='schoolpro_result_approvals_school_id_idx')
     or not exists (select 1 from pg_indexes where schemaname='public' and indexname='schoolpro_promotions_school_id_idx') then
    raise exception 'FAIL: missing operational school_id index';
  end if;
end
$$;

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
 public.schoolpro_hostel_rooms, public.schoolpro_inventory_assets, public.schoolpro_calendar_events to authenticated;

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
('50000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002');

insert into public.schoolpro_lesson_notes values
('60000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001');
insert into public.schoolpro_result_approvals values
('70000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001');
insert into public.schoolpro_promotions values
('80000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001');
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
  $$insert into public.schoolpro_member_permissions values ('90000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000002')$$,
  'Permission member belongs to another school');
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
