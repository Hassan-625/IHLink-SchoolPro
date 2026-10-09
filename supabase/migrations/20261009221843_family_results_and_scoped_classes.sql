-- Family reports use one authorization and fee gate on every output.
create or replace function private.schoolpro_can_read_student(p_student uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account() and exists(
 select 1 from public.schoolpro_students s where s.id=p_student and private.schoolpro_operationally_active(s.school_id) and (
 private.is_admin(array['super_admin'::public.user_role]) or s.user_id=auth.uid()
 or exists(select 1 from public.schoolpro_guardian_links g where g.school_id=s.school_id and g.student_id=s.id and g.guardian_user_id=auth.uid() and g.status='active')
 or exists(select 1 from public.schoolpro_schools sc where sc.id=s.school_id and sc.owner_id=auth.uid())
 or exists(select 1 from public.schoolpro_members m where m.school_id=s.school_id and m.user_id=auth.uid() and (
 m.role::text not in('teacher','class_teacher','parent','student')
 or (m.role in('teacher','class_teacher') and (exists(select 1 from public.schoolpro_subject_assignments a where a.school_id=s.school_id and a.class_id=s.class_id and a.teacher_member_id=m.id) or exists(select 1 from public.schoolpro_classes c where c.id=s.class_id and c.form_teacher_id=m.id)))
 ))));
$$;
revoke all on function private.schoolpro_can_read_student(uuid) from public,anon;
grant execute on function private.schoolpro_can_read_student(uuid) to authenticated;

create table public.schoolpro_result_access_overrides(
 id uuid primary key default gen_random_uuid(),school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 student_id uuid not null references public.schoolpro_students(id) on delete cascade,term text not null,session text not null,
 allowed boolean not null,reason text not null check(char_length(reason) between 3 and 1000),updated_by uuid not null references public.profiles(id),updated_at timestamptz not null default now(),unique(student_id,term,session));
create table public.schoolpro_result_access_events(
 id uuid primary key default gen_random_uuid(),school_id uuid not null references public.schoolpro_schools(id) on delete cascade,
 student_id uuid not null references public.schoolpro_students(id) on delete cascade,term text not null,session text not null,
 allowed boolean not null,reason text not null,changed_by uuid not null references public.profiles(id),created_at timestamptz not null default now());
alter table public.schoolpro_result_access_overrides enable row level security;
alter table public.schoolpro_result_access_events enable row level security;
grant select on public.schoolpro_result_access_overrides,public.schoolpro_result_access_events to authenticated;
create policy "School leaders read result exceptions" on public.schoolpro_result_access_overrides for select to authenticated using(private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "School leaders read result exception history" on public.schoolpro_result_access_events for select to authenticated using(private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create index on public.schoolpro_result_access_events(school_id,student_id,created_at);

create or replace function public.schoolpro_set_result_access_exception(p_student uuid,p_term text,p_session text,p_allowed boolean,p_reason text)
returns void language plpgsql security definer set search_path='' as $$
declare s public.schoolpro_students;
begin
 select * into s from public.schoolpro_students where id=p_student;
 if auth.uid() is null or not private.schoolpro_module_allowed(s.school_id,'finance') or not private.has_school_access(s.school_id,array['proprietor','administrator']::public.school_member_role[]) then raise exception 'Only school leadership can manage result access';end if;
 if trim(p_term) not in('First Term','Second Term','Third Term') or trim(p_session)!~'^20[0-9]{2}/20[0-9]{2}$' or char_length(trim(p_reason))<3 or char_length(trim(p_reason))>1000 then raise exception 'Provide the academic period and a reason';end if;
 insert into public.schoolpro_result_access_overrides(school_id,student_id,term,session,allowed,reason,updated_by) values(s.school_id,s.id,trim(p_term),trim(p_session),p_allowed,trim(p_reason),auth.uid()) on conflict(student_id,term,session) do update set allowed=excluded.allowed,reason=excluded.reason,updated_by=excluded.updated_by,updated_at=now();
 insert into public.schoolpro_result_access_events(school_id,student_id,term,session,allowed,reason,changed_by) values(s.school_id,s.id,trim(p_term),trim(p_session),p_allowed,trim(p_reason),auth.uid());
end $$;
revoke all on function public.schoolpro_set_result_access_exception(uuid,text,text,boolean,text) from public,anon;
grant execute on function public.schoolpro_set_result_access_exception(uuid,text,text,boolean,text) to authenticated;

create or replace function private.schoolpro_result_access(p_student uuid,p_term text,p_session text)
returns table(allowed boolean,outstanding numeric,reason text) language plpgsql stable security definer set search_path='' as $$
declare s public.schoolpro_students;fs public.schoolpro_finance_settings;debt numeric;hold boolean;exception_allowed boolean;
begin
 if not private.schoolpro_can_read_student(p_student) then return;end if;
 select * into s from public.schoolpro_students where id=p_student;
 select * into fs from public.schoolpro_finance_settings where school_id=s.school_id;
 select coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0),coalesce(bool_or(i.result_hold),false) into debt,hold from public.schoolpro_invoices i where i.student_id=s.id and i.school_id=s.school_id and i.term=trim(p_term) and i.session=trim(p_session) and i.status<>'waived';
 -- Staff review is separate from family release; family users never inherit staff bypass.
 if exists(select 1 from public.schoolpro_schools sc where sc.id=s.school_id and sc.owner_id=auth.uid()) or private.is_admin(array['super_admin'::public.user_role]) or exists(select 1 from public.schoolpro_members m where m.school_id=s.school_id and m.user_id=auth.uid() and m.role::text not in('parent','student')) then return query select true,debt,null::text;return;end if;
 select o.allowed into exception_allowed from public.schoolpro_result_access_overrides o where o.student_id=s.id and o.school_id=s.school_id and o.term=trim(p_term) and o.session=trim(p_session);
 if exception_allowed is true then return query select true,debt,null::text;return;end if;
 if hold or (coalesce(fs.block_results_when_owing,false) and debt>coalesce(fs.allowed_outstanding,0)) then return query select false,debt,'Your school has paused this result. Please contact the school accounts office.'::text;else return query select true,debt,null::text;end if;
end $$;
revoke all on function private.schoolpro_result_access(uuid,text,text) from public,anon;
grant execute on function private.schoolpro_result_access(uuid,text,text) to authenticated;
create or replace function public.schoolpro_result_access(target_student uuid,target_term text,target_session text)
returns table(allowed boolean,outstanding numeric,reason text) language sql stable security invoker set search_path='' as $$ select * from private.schoolpro_result_access(target_student,target_term,target_session) $$;
revoke all on function public.schoolpro_result_access(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_result_access(uuid,text,text) to authenticated;

create or replace function public.schoolpro_can_view_result_output(p_student_id uuid,p_term text,p_session text)
returns boolean language sql stable security definer set search_path='' as $$
 select coalesce((select a.allowed from private.schoolpro_result_access(p_student_id,p_term,p_session) a),false) and exists(select 1 from public.schoolpro_results r where r.student_id=p_student_id and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published' and r.locked);
$$;
revoke all on function public.schoolpro_can_view_result_output(uuid,text,text) from public,anon;
grant execute on function public.schoolpro_can_view_result_output(uuid,text,text) to authenticated;

-- No raw scores or period summaries can bypass family fee restrictions.
create policy "Result access gate" on public.schoolpro_results as restrictive for select to authenticated using(private.schoolpro_can_read_student(student_id) and coalesce((select a.allowed from private.schoolpro_result_access(student_id,term,session) a),false));
drop policy "Guardians read published linked results" on public.schoolpro_results;
create policy "Guardians read published linked results" on public.schoolpro_results for select to authenticated using(status='published' and locked and exists(select 1 from public.schoolpro_guardian_links g where g.student_id=schoolpro_results.student_id and g.school_id=schoolpro_results.school_id and g.guardian_user_id=auth.uid() and g.status='active'));
drop policy "students view own published results" on public.schoolpro_results;
create policy "students view own published results" on public.schoolpro_results for select to authenticated using(status='published' and locked and exists(select 1 from public.schoolpro_students s where s.id=schoolpro_results.student_id and s.user_id=auth.uid()));
create policy "Scoped student records" on public.schoolpro_students as restrictive for select to authenticated using(private.schoolpro_can_read_student(id));
-- Include existing staff roles, with the restrictive policy limiting teachers to assigned classes.
drop policy "School users read students" on public.schoolpro_students;
create policy "School users read students" on public.schoolpro_students for select to authenticated using(private.schoolpro_can_read_student(id));
create policy "Scoped domain records" on public.schoolpro_result_domain_ratings as restrictive for all to authenticated using(private.schoolpro_can_read_student(student_id) and coalesce((select a.allowed from private.schoolpro_result_access(student_id,term,session) a),false)) with check(private.schoolpro_can_read_student(student_id) and exists(select 1 from public.schoolpro_students s join public.schoolpro_result_domain_definitions d on d.school_id=s.school_id where s.id=student_id and s.school_id=schoolpro_result_domain_ratings.school_id and d.id=definition_id));

-- Teachers may read their allocations but cannot create, move or delete allocations.
create policy "Leadership creates allocations" on public.schoolpro_subject_assignments as restrictive for insert to authenticated with check(private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "Leadership changes allocations" on public.schoolpro_subject_assignments as restrictive for update to authenticated using(private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[])) with check(private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "Leadership removes allocations" on public.schoolpro_subject_assignments as restrictive for delete to authenticated using(private.has_school_access(school_id,array['proprietor','administrator']::public.school_member_role[]));
create policy "Teachers read their own allocations" on public.schoolpro_subject_assignments as restrictive for select to authenticated using(not exists(select 1 from public.schoolpro_members m where m.school_id=schoolpro_subject_assignments.school_id and m.user_id=auth.uid() and m.role in('teacher','class_teacher')) or exists(select 1 from public.schoolpro_members m where m.id=teacher_member_id and m.school_id=schoolpro_subject_assignments.school_id and m.user_id=auth.uid()));

alter table public.schoolpro_result_domain_ratings add column rating_label text check(rating_label in('A','B','C','D','E','F'));

-- List released periods, including a clear paused state, without exposing their scores.
create or replace function public.schoolpro_family_result_periods(p_student uuid)
returns table(term text,session text,allowed boolean,reason text) language plpgsql stable security definer set search_path='' as $$
begin
 if not private.schoolpro_can_read_student(p_student) then raise exception 'Student access is not available';end if;
 return query select distinct r.term,r.session,a.allowed,a.reason from public.schoolpro_results r cross join lateral private.schoolpro_result_access(r.student_id,r.term,r.session) a where r.student_id=p_student and r.status='published' and r.locked order by r.session desc,r.term;
end $$;
revoke all on function public.schoolpro_family_result_periods(uuid) from public,anon;
grant execute on function public.schoolpro_family_result_periods(uuid) to authenticated;
create policy "Student reads own school" on public.schoolpro_schools for select to authenticated using(exists(select 1 from public.schoolpro_students s where s.school_id=schoolpro_schools.id and s.user_id=auth.uid()));
create policy "Members read linked school" on public.schoolpro_schools for select to authenticated using(exists(select 1 from public.schoolpro_members m where m.school_id=schoolpro_schools.id and m.user_id=auth.uid()));
create policy "Linked families read released ratings" on public.schoolpro_result_domain_ratings for select to authenticated using(public.schoolpro_can_view_result_output(student_id,term,session) and (exists(select 1 from public.schoolpro_students s where s.id=student_id and s.user_id=auth.uid()) or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=schoolpro_result_domain_ratings.student_id and g.guardian_user_id=auth.uid() and g.status='active')));

create or replace function private.schoolpro_can_read_class(p_class uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.is_active_account() and exists(select 1 from public.schoolpro_classes c where c.id=p_class and (
 private.has_school_access(c.school_id,array['proprietor','administrator']::public.school_member_role[])
 or exists(select 1 from public.schoolpro_members m where m.school_id=c.school_id and m.user_id=auth.uid() and (m.role::text not in('teacher','class_teacher','parent','student') or c.form_teacher_id=m.id or exists(select 1 from public.schoolpro_subject_assignments a where a.class_id=c.id and a.school_id=c.school_id and a.teacher_member_id=m.id)))
 or exists(select 1 from public.schoolpro_students s where s.class_id=c.id and s.school_id=c.school_id and (s.user_id=auth.uid() or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=s.id and g.guardian_user_id=auth.uid() and g.status='active')))
 ));
$$;
revoke all on function private.schoolpro_can_read_class(uuid) from public,anon;
grant execute on function private.schoolpro_can_read_class(uuid) to authenticated;
create policy "Scoped class lists" on public.schoolpro_classes as restrictive for select to authenticated using(private.schoolpro_can_read_class(id));
create policy "Authorized class lists" on public.schoolpro_classes for select to authenticated using(private.schoolpro_can_read_class(id));

create or replace function private.schoolpro_family_report_media(p_name text)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.schoolpro_students s join public.schoolpro_results r on r.student_id=s.id and r.school_id=s.school_id left join public.schoolpro_result_term_settings ts on ts.school_id=s.school_id and ts.term=r.term and ts.session=r.session where r.status='published' and r.locked and public.schoolpro_can_view_result_output(s.id,r.term,r.session) and (
 s.photo_storage_path=p_name or ts.principal_signature_path=p_name or ts.form_teacher_signature_path=p_name or exists(select 1 from public.schoolpro_result_templates t where t.school_id=s.school_id and t.logo_storage_path=p_name)));
$$;
revoke all on function private.schoolpro_family_report_media(text) from public,anon;
grant execute on function private.schoolpro_family_report_media(text) to authenticated;
create policy "Families read their report images" on storage.objects for select to authenticated using(bucket_id='school-result-templates' and private.schoolpro_family_report_media(name));

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
 'subject_names',(select jsonb_object_agg(sub.id,sub.name) from public.schoolpro_subjects sub join public.schoolpro_results rr on rr.subject_id=sub.id where rr.student_id=s.id and rr.term=trim(p_term) and rr.session=trim(p_session) and rr.status='published'),'settings',to_jsonb(ts),'gender',s.gender,'date_of_birth',s.date_of_birth,'photo_storage_path',s.photo_storage_path,
 'domains',coalesce((select jsonb_agg(jsonb_build_object('type',d.domain_type,'name',d.name,'rating',coalesce(r.rating_label,r.rating::text)) order by d.domain_type,d.position) from public.schoolpro_result_domain_definitions d left join public.schoolpro_result_domain_ratings r on r.definition_id=d.id and r.school_id=s.school_id and r.student_id=s.id and r.term=trim(p_term) and r.session=trim(p_session) where d.school_id=s.school_id and d.is_active),'[]'::jsonb),
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
