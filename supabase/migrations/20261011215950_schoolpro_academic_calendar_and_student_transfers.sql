alter table public.schoolpro_students add column admission_type text not null default 'new' check(admission_type in('new','transfer_in'));
alter table public.schoolpro_students add column previous_school text;
alter table public.schoolpro_students add column enrollment_session text;
alter table public.schoolpro_students add column transferred_out_at timestamptz;
alter table public.schoolpro_students add column transfer_destination text;
alter table public.schoolpro_students add column transfer_reason text;
create table private.schoolpro_academic_clock(school_id uuid primary key references public.schoolpro_schools(id) on delete cascade,session text,term text,checked_at timestamptz not null default now());
revoke all on private.schoolpro_academic_clock from public,anon,authenticated;
create index schoolpro_term_calendar_dates_idx on public.schoolpro_result_term_settings(school_id,term_start_date,term_end_date);
create or replace function private.schoolpro_validate_calendar() returns trigger language plpgsql set search_path='' as $$begin
 if new.term_start_date is not null and new.term_end_date is not null then
  if new.term_end_date<new.term_start_date then raise exception 'Term ending must follow its beginning';end if;
  perform pg_advisory_xact_lock(hashtextextended(new.school_id::text,0));
  if exists(select 1 from public.schoolpro_result_term_settings t where t.school_id=new.school_id and t.id<>new.id and t.term_start_date<=new.term_end_date and t.term_end_date>=new.term_start_date) then raise exception 'Academic term dates cannot overlap in the same school';end if;
 end if;return new;end$$;
create trigger schoolpro_validate_calendar before insert or update of term_start_date,term_end_date on public.schoolpro_result_term_settings for each row execute function private.schoolpro_validate_calendar();
create or replace function private.schoolpro_tick_calendar(p_school uuid) returns void language plpgsql security definer set search_path='' as $$declare t public.schoolpro_result_term_settings;previous private.schoolpro_academic_clock;begin
 select * into t from public.schoolpro_result_term_settings where school_id=p_school and term_start_date<=current_date and term_end_date>=current_date order by term_start_date desc limit 1;
 select * into previous from private.schoolpro_academic_clock where school_id=p_school for update;
 insert into private.schoolpro_academic_clock(school_id,session,term) values(p_school,t.session,t.term) on conflict(school_id) do update set session=excluded.session,term=excluded.term,checked_at=now();
 if t.id is not null and (previous.session,previous.term) is distinct from(t.session,t.term) then
  insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href) select p_school,owner_id,'Academic period started',t.term||' of '||t.session||' is now current. Review enrolments and required approvals.','info','/schoolpro/calendar' from public.schoolpro_schools where id=p_school;
 end if;end$$;
revoke all on function private.schoolpro_tick_calendar(uuid) from public,anon,authenticated;
create or replace function private.schoolpro_refresh_academic_clocks() returns void language plpgsql security definer set search_path='' as $$declare r record;begin for r in select distinct school_id from public.schoolpro_result_term_settings where term_start_date is not null loop perform private.schoolpro_tick_calendar(r.school_id);end loop;end$$;
revoke all on function private.schoolpro_refresh_academic_clocks() from public,anon,authenticated;
create or replace function public.schoolpro_current_academic_period(p_school uuid) returns jsonb language plpgsql security definer set search_path='' as $$declare t public.schoolpro_result_term_settings;u public.schoolpro_result_term_settings;begin
 if not private.schoolpro_module_allowed(p_school,'dashboard') then raise exception 'School access required';end if;
 perform private.schoolpro_tick_calendar(p_school);
 select * into t from public.schoolpro_result_term_settings where school_id=p_school and term_start_date<=current_date and term_end_date>=current_date order by term_start_date desc limit 1;
 select * into u from public.schoolpro_result_term_settings where school_id=p_school and term_start_date>current_date order by term_start_date limit 1;
 return jsonb_build_object('current',case when t.id is null then null else jsonb_build_object('session',t.session,'term',t.term,'starts',t.term_start_date,'ends',t.term_end_date) end,'upcoming',case when u.id is null then null else jsonb_build_object('session',u.session,'term',u.term,'starts',u.term_start_date,'ends',u.term_end_date) end);end$$;
revoke all on function public.schoolpro_current_academic_period(uuid) from public,anon;grant execute on function public.schoolpro_current_academic_period(uuid) to authenticated;
create or replace function public.schoolpro_save_academic_calendar(p_school uuid,p_session text,p_term text,p_start date,p_end date) returns void language plpgsql security definer set search_path='' as $$begin
 if not private.schoolpro_module_allowed(p_school,'calendar') then raise exception 'Calendar permission required';end if;
 if p_session!~'^[0-9]{4}/[0-9]{4}$' or split_part(p_session,'/',2)::int<>split_part(p_session,'/',1)::int+1 or p_term not in('First Term','Second Term','Third Term') or p_start is null or p_end is null then raise exception 'Choose a valid academic session, term and dates';end if;
 insert into public.schoolpro_result_term_settings(school_id,session,term,term_start_date,term_end_date,updated_by)values(p_school,p_session,p_term,p_start,p_end,auth.uid()) on conflict(school_id,session,term) do update set term_start_date=excluded.term_start_date,term_end_date=excluded.term_end_date,updated_by=auth.uid(),updated_at=now();
 perform private.schoolpro_tick_calendar(p_school);
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)values(p_school,auth.uid(),'Academic calendar saved','school',p_school,jsonb_build_object('session',p_session,'term',p_term,'start',p_start,'end',p_end));end$$;
revoke all on function public.schoolpro_save_academic_calendar(uuid,text,text,date,date) from public,anon;grant execute on function public.schoolpro_save_academic_calendar(uuid,text,text,date,date) to authenticated;
create or replace function private.schoolpro_enrollment_calendar() returns trigger language plpgsql security definer set search_path='' as $$declare period text;c public.schoolpro_classes;begin
 period:=new.enrollment_session;
 if nullif(period,'') is null then select session into period from public.schoolpro_result_term_settings where school_id=new.school_id and term_start_date<=current_date and term_end_date>=current_date order by term_start_date desc limit 1;end if;
 if nullif(period,'') is null then return new;end if;
 if period!~'^[0-9]{4}/[0-9]{4}$' or split_part(period,'/',2)::int<>split_part(period,'/',1)::int+1 then raise exception 'Choose a valid enrolment session';end if;
 select * into c from public.schoolpro_classes where id=new.class_id and school_id=new.school_id;
 insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id,class_name,arm,section,status)values(new.school_id,new.id,period,new.class_id,c.name,coalesce(c.arm,''),coalesce(c.level,'unassigned'),'active') on conflict(school_id,student_id,session)do nothing;
 return new;end$$;
create trigger schoolpro_enrollment_calendar after insert on public.schoolpro_students for each row execute function private.schoolpro_enrollment_calendar();
create or replace function public.schoolpro_transfer_student_out(p_student uuid,p_destination text,p_reason text) returns void language plpgsql security definer set search_path='' as $$declare s public.schoolpro_students;begin
 select * into s from public.schoolpro_students where id=p_student for update;
 if s.id is null or not private.schoolpro_module_allowed(s.school_id,'students') or not private.schoolpro_module_allowed(s.school_id,'promotions') then raise exception 'School management permission required';end if;
 if s.status<>'active' or s.transferred_out_at is not null then raise exception 'Only an active pupil can be transferred out';end if;
 if nullif(trim(p_reason),'') is null then raise exception 'Enter a transfer reason';end if;
 update public.schoolpro_students set status='withdrawn',transferred_out_at=now(),transfer_destination=nullif(trim(p_destination),''),transfer_reason=trim(p_reason) where id=p_student;
 update public.schoolpro_enrollment_history set status='completed' where student_id=p_student and school_id=s.school_id and status='active';
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)values(s.school_id,auth.uid(),'Student transferred out','student',s.id,jsonb_build_object('destination',p_destination,'reason',p_reason));end$$;
revoke all on function public.schoolpro_transfer_student_out(uuid,text,text) from public,anon;grant execute on function public.schoolpro_transfer_student_out(uuid,text,text) to authenticated;
create or replace function private.schoolpro_reject_new_inactive_student_activity() returns trigger language plpgsql security definer set search_path='' as $$declare pupil uuid;begin
 pupil:=nullif(to_jsonb(new)->>'student_id','')::uuid;
 if pupil is not null and (tg_op='INSERT' or (to_jsonb(new)->>'student_id') is distinct from (to_jsonb(old)->>'student_id')) and exists(select 1 from public.schoolpro_students where id=pupil and(status<>'active' or transferred_out_at is not null)) then raise exception 'This pupil is no longer enrolled for new activities';end if;return new;end$$;
do $$declare tab text;begin foreach tab in array array['schoolpro_results','schoolpro_attendance','schoolpro_assignment_submissions','schoolpro_library_loans','schoolpro_student_transport','schoolpro_hostel_allocations','schoolpro_health_records','schoolpro_discipline_records','schoolpro_invoices'] loop if exists(select 1 from information_schema.columns where table_schema='public' and table_name=tab and column_name='student_id') then execute format('create trigger schoolpro_active_pupil_activity before insert or update on public.%I for each row execute function private.schoolpro_reject_new_inactive_student_activity()',tab);end if;end loop;end$$;
do $$begin if exists(select 1 from pg_extension where extname='pg_cron') then perform cron.schedule('schoolpro-academic-calendar','7 * * * *','select private.schoolpro_refresh_academic_clocks()');end if;end$$;

