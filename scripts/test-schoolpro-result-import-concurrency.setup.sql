\set ON_ERROR_STOP on
-- Adds an isolated student and a second compatible-level scheme for the
-- two-session race probe. The RPC's existing test helpers authorize writes.
insert into public.schoolpro_students(id,school_id,admission_number,status,class_id)
values ('40000000-0000-0000-0000-000000000099',
        '20000000-0000-0000-0000-000000000001',
        'JSS-RACE','active',
        '30000000-0000-0000-0000-000000000001');
insert into public.schoolpro_assessment_schemes(id,school_id,school_level,components)
values ('10000000-0000-0000-0000-000000000003',
        '20000000-0000-0000-0000-000000000001',
        'junior_secondary',
        '[{"key":"exam","label":"Examination","maxScore":100}]');
create sequence public.schoolpro_result_import_race_insert_attempts start with 1 increment by 1;
create function public.schoolpro_result_import_race_pause()
returns trigger language plpgsql as $$
begin
 if new.student_id='40000000-0000-0000-0000-000000000099'::uuid then
  perform nextval('public.schoolpro_result_import_race_insert_attempts');
  perform pg_sleep(3);
 end if;
 return new;
end
$$;
create trigger schoolpro_result_import_race_pause
before insert on public.schoolpro_results
for each row execute function public.schoolpro_result_import_race_pause();
