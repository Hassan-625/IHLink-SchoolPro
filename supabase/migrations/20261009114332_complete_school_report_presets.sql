alter table public.schoolpro_assessment_schemes drop constraint schoolpro_assessment_schemes_school_level_check;
alter table public.schoolpro_assessment_schemes add constraint schoolpro_assessment_schemes_school_level_check check (school_level in ('nursery_primary','nursery','primary','secondary','junior_secondary','senior_secondary','custom','all'));
-- Editable starter choices, not a mandated national grading scheme.
create or replace function private.seed_schoolpro_report_defaults(p_school uuid)
returns void language plpgsql security definer set search_path='' as $$
declare preset record; components jsonb:='[{"key":"assignment_1","label":"1st CA Assignment","maxScore":10},{"key":"assignment_2","label":"2nd CA Assignment","maxScore":10},{"key":"test_1","label":"1st CA Test","maxScore":10},{"key":"test_2","label":"2nd CA Test","maxScore":10},{"key":"exam","label":"Examination","maxScore":60}]';
begin
 if not private.schoolpro_operationally_active(p_school) then return;end if;
 for preset in select * from (values ('Nursery Standard','nursery'),('Primary Standard','primary'),('Junior Secondary Standard','junior_secondary'),('Senior Secondary Standard','senior_secondary')) v(name,level) loop
  insert into public.schoolpro_assessment_schemes(school_id,name,school_level,components,is_default)
  values(p_school,preset.name,preset.level,components,preset.level='primary' and not exists(select 1 from public.schoolpro_assessment_schemes where school_id=p_school and is_default)) on conflict(school_id,name) do nothing;
 end loop;
 insert into public.schoolpro_result_domain_definitions(school_id,domain_type,name,position,is_active)
 select p_school,d.kind,d.name,d.position,true from (values
 ('affective','Punctuality',1),('affective','Attendance',2),('affective','Honesty',3),('affective','Cooperation',4),('affective','Neatness',5),('affective','Politeness',6),('affective','Self-control',7),('affective','Responsibility',8),
 ('psychomotor','Handwriting',1),('psychomotor','Reading',2),('psychomotor','Verbal communication',3),('psychomotor','Drawing',4),('psychomotor','Practical work',5),('psychomotor','Sports',6),('psychomotor','Music',7),('psychomotor','Creativity',8)) d(kind,name,position)
 where not exists(select 1 from public.schoolpro_result_domain_definitions old where old.school_id=p_school and old.domain_type=d.kind);
 if not exists(select 1 from public.schoolpro_result_rating_scale where school_id=p_school) then
  insert into public.schoolpro_result_rating_scale(school_id,rating,description,position) values(p_school,5,'Excellent',1),(p_school,4,'Very good',2),(p_school,3,'Good',3),(p_school,2,'Fair',4),(p_school,1,'Needs improvement',5);
 end if;
end $$;
revoke all on function private.seed_schoolpro_report_defaults(uuid) from public,anon,authenticated;
create or replace function private.create_default_school_assessment_scheme()
returns trigger language plpgsql security definer set search_path='' as $$ begin perform private.seed_schoolpro_report_defaults(new.id);return new;end $$;
revoke all on function private.create_default_school_assessment_scheme() from public,anon,authenticated;
do $$ declare s record;begin for s in select id from public.schoolpro_schools loop perform private.seed_schoolpro_report_defaults(s.id);end loop;end $$;

-- Reuse the printable-result authorization and outstanding-fee gate.
create or replace function private.schoolpro_report_details(p_student uuid,p_term text,p_session text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s public.schoolpro_students; ts public.schoolpro_result_term_settings; count_results integer; result jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select count(*) into count_results from public.schoolpro_printable_result(p_student,p_term,p_session);
 if count_results=0 then raise exception 'No published results available';end if;
 select * into s from public.schoolpro_students where id=p_student;
 select * into ts from public.schoolpro_result_term_settings where school_id=s.school_id and term=trim(p_term) and session=trim(p_session);
 select jsonb_build_object(
 'settings',to_jsonb(ts),'gender',s.gender,'date_of_birth',s.date_of_birth,'photo_storage_path',s.photo_storage_path,
 'domains',coalesce((select jsonb_agg(jsonb_build_object('type',d.domain_type,'name',d.name,'rating',r.rating) order by d.domain_type,d.position) from public.schoolpro_result_domain_definitions d left join public.schoolpro_result_domain_ratings r on r.definition_id=d.id and r.school_id=s.school_id and r.student_id=s.id and r.term=trim(p_term) and r.session=trim(p_session) where d.school_id=s.school_id and d.is_active),'[]'::jsonb),
 'rating_scale',coalesce((select jsonb_agg(jsonb_build_object('rating',rating,'description',description) order by position) from public.schoolpro_result_rating_scale where school_id=s.school_id),'[]'::jsonb),
 'grade_scale',coalesce((select jsonb_agg(jsonb_build_object('label',label,'min_score',min_score,'max_score',max_score,'remark',remark,'overall_remark',overall_remark) order by position) from public.schoolpro_grade_scale where school_id=s.school_id and is_active),'[]'::jsonb),
 'attendance',case when ts.term_start_date is not null and ts.term_end_date is not null then (select jsonb_build_object('present',count(*) filter(where status::text='present'),'absent',count(*) filter(where status::text='absent'),'leave',count(*) filter(where status::text in ('leave','excused')),'recorded',count(*)) from public.schoolpro_attendance where student_id=s.id and attendance_date between ts.term_start_date and ts.term_end_date) else null end,
 'rank',(select to_jsonb(r) from public.schoolpro_result_class_rank(s.id,p_term,p_session) r limit 1),
 'logo_storage_path',(select logo_storage_path from public.schoolpro_result_templates where school_id=s.school_id limit 1)
 ) into result;return result;
end $$;
revoke all on function private.schoolpro_report_details(uuid,text,text) from public,anon;
grant execute on function private.schoolpro_report_details(uuid,text,text) to authenticated;
create or replace function public.schoolpro_report_details(p_student uuid,p_term text,p_session text)
returns jsonb language sql stable security invoker set search_path='' as $$ select private.schoolpro_report_details(p_student,p_term,p_session) $$;
revoke all on function public.schoolpro_report_details(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_report_details(uuid,text,text) to authenticated;
