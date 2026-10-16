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
  'Subject school change would invalidate lesson-note tenant scope');
select pg_temp.assert_rejected('class parent reassignment',
  $$update public.schoolpro_classes set school_id='00000000-0000-0000-0000-000000000002' where id='20000000-0000-0000-0000-000000000001'$$,
  'Class school change would invalidate operational tenant scope');
select pg_temp.assert_rejected('student parent reassignment',
  $$update public.schoolpro_students set school_id='00000000-0000-0000-0000-000000000002' where id='30000000-0000-0000-0000-000000000001'$$,
  'Student school change would invalidate promotion tenant scope');
select pg_temp.assert_rejected('result parent reassignment',
  $$update public.schoolpro_results set school_id='00000000-0000-0000-0000-000000000002' where id='40000000-0000-0000-0000-000000000001'$$,
  'Result school change would invalidate approval tenant scope');
select pg_temp.assert_rejected('member parent reassignment',
  $$update public.schoolpro_members set school_id='00000000-0000-0000-0000-000000000002' where id='50000000-0000-0000-0000-000000000001'$$,
  'Member school change would invalidate permission tenant scope');

select 'PASS: PostgreSQL rejected cross-tenant child writes and unsafe parent reassignment.' as result;
