-- Disposable PostgreSQL integration test for global document serial uniqueness.
-- Run only in CI; this fixture is not a production migration runner.
create table public.schoolpro_document_issues (
  id uuid primary key,
  school_id uuid not null,
  serial_number text not null,
  status text not null
);
create unique index schoolpro_document_issues_school_id_serial_number_key
  on public.schoolpro_document_issues(school_id, serial_number);

insert into public.schoolpro_document_issues(id,school_id,serial_number,status)
values
 ('a0000000-0000-0000-0000-000000000001','b0000000-0000-0000-0000-000000000001','DOC-ABC123','issued'),
 ('a0000000-0000-0000-0000-000000000002','b0000000-0000-0000-0000-000000000002','DOC-DEF456','issued');

\ir ../supabase/migrations/20261017103000_schoolpro_document_serial_global_uniqueness.sql

do $serial_test$
begin
  begin
    insert into public.schoolpro_document_issues(id,school_id,serial_number,status)
    values ('a0000000-0000-0000-0000-000000000003',
            'b0000000-0000-0000-0000-000000000003','doc-abc123','issued');
    raise exception 'Normalized duplicate serial unexpectedly inserted';
  exception when unique_violation then
    null;
  end;
end
$serial_test$;

\echo 'PASS: normalized document serial is globally unique across schools.'
