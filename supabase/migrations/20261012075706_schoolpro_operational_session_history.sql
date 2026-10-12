alter table public.schoolpro_payroll_records add column if not exists session text;
alter table public.schoolpro_calendar_events add column if not exists session text;
alter table public.schoolpro_leave_requests add column if not exists session text;
alter table public.schoolpro_announcements add column if not exists session text;
alter table public.schoolpro_student_transport drop constraint schoolpro_student_transport_student_id_key;
create unique index schoolpro_transport_student_session_unique on public.schoolpro_student_transport(student_id,session) where session is not null;
create unique index schoolpro_transport_legacy_student_unique on public.schoolpro_student_transport(student_id) where session is null;
create or replace function private.schoolpro_valid_session(p_session text) returns boolean language sql immutable set search_path='' as $$select coalesce(p_session ~ '^[0-9]{4}/[0-9]{4}$' and split_part(p_session,'/',2)::integer=split_part(p_session,'/',1)::integer+1,false)$$;
revoke all on function private.schoolpro_valid_session(text) from public,anon;
grant execute on function private.schoolpro_valid_session(text) to authenticated;
create or replace function private.schoolpro_stamp_activity_period() returns trigger language plpgsql security definer set search_path='' as $$
declare j jsonb:=to_jsonb(new);sid uuid;d date;t public.schoolpro_result_term_settings;selected text;
begin
 sid:=nullif(j->>'school_id','')::uuid;
 if sid is null and j->>'student_id' is not null then select school_id into sid from public.schoolpro_students where id=(j->>'student_id')::uuid;end if;
 d:=coalesce(nullif(j->>'attendance_date','')::date,nullif(j->>'lesson_date','')::date,nullif(j->>'event_date','')::date,nullif(j->>'start_date','')::date,nullif(j->>'recorded_at','')::timestamptz::date,nullif(j->>'borrowed_at','')::timestamptz::date,current_date);
 selected:=nullif(j->>'session','');
 if selected is null then
  select * into t from public.schoolpro_result_term_settings where school_id=sid and term_start_date<=d and term_end_date>=d order by term_start_date desc limit 1;
  selected:=t.session;
 end if;
 if selected is not null then
  if not private.schoolpro_valid_session(selected) then raise exception 'Select consecutive academic years';end if;
  j:=j||jsonb_build_object('session',selected);
  if j?'term' and nullif(j->>'term','') is null then
   select * into t from public.schoolpro_result_term_settings where school_id=sid and session=selected and term_start_date<=d and term_end_date>=d order by term_start_date desc limit 1;
   if t.id is not null then j:=j||jsonb_build_object('term',t.term);end if;
  end if;
  new:=jsonb_populate_record(new,j);
 end if;
 return new;
end $$;
create or replace function private.schoolpro_preserve_activity_session() returns trigger language plpgsql set search_path='' as $$
begin
 if nullif(old.session,'') is not null and old.session is distinct from new.session then raise exception 'Keep this record in its original academic session';end if;
 if nullif(new.session,'') is not null and not private.schoolpro_valid_session(new.session) then raise exception 'Select consecutive academic years';end if;
 return new;
end $$;
revoke all on function private.schoolpro_preserve_activity_session() from public,anon,authenticated;
do $$declare t text;begin
 foreach t in array array['schoolpro_payroll_records','schoolpro_calendar_events','schoolpro_leave_requests','schoolpro_announcements'] loop
 execute format('create trigger schoolpro_stamp_activity_period before insert on public.%I for each row execute function private.schoolpro_stamp_activity_period()',t);
 end loop;
 foreach t in array array['schoolpro_library_loans','schoolpro_student_transport','schoolpro_hostel_allocations','schoolpro_payroll_records','schoolpro_calendar_events','schoolpro_leave_requests','schoolpro_announcements','schoolpro_health_records','schoolpro_discipline_records','schoolpro_lesson_notes','schoolpro_assignments','schoolpro_academic_documents'] loop
 execute format('create trigger schoolpro_preserve_activity_session before update on public.%I for each row execute function private.schoolpro_preserve_activity_session()',t);
 execute format('create index if not exists %I on public.%I (school_id,session)',t||'_school_session_idx',t);
 end loop;
end $$;