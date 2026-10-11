create or replace function private.schoolpro_tick_calendar(p_school uuid) returns void language plpgsql security definer set search_path='' as $$declare t public.schoolpro_result_term_settings;previous private.schoolpro_academic_clock;begin
 insert into private.schoolpro_academic_clock(school_id)values(p_school)on conflict(school_id)do nothing;
 select * into previous from private.schoolpro_academic_clock where school_id=p_school for update;
 select * into t from public.schoolpro_result_term_settings where school_id=p_school and term_start_date<=current_date and term_end_date>=current_date order by term_start_date desc limit 1;
 update private.schoolpro_academic_clock set session=t.session,term=t.term,checked_at=now() where school_id=p_school;
 if t.id is not null and (previous.session,previous.term) is distinct from(t.session,t.term) then insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href)select p_school,owner_id,'Academic period started',t.term||' of '||t.session||' is now current. Review enrolments and required approvals.','info','/schoolpro/calendar' from public.schoolpro_schools where id=p_school;end if;end$$;
do $$declare tab text;begin foreach tab in array array['schoolpro_attendance','schoolpro_library_loans','schoolpro_student_transport','schoolpro_health_records','schoolpro_discipline_records'] loop execute format('alter table public.%I add column if not exists session text',tab);execute format('alter table public.%I add column if not exists term text',tab);end loop;end$$;
create or replace function private.schoolpro_stamp_activity_period() returns trigger language plpgsql security definer set search_path='' as $$declare j jsonb:=to_jsonb(new);sid uuid;d date;t public.schoolpro_result_term_settings;begin
 sid:=nullif(j->>'school_id','')::uuid;
 if sid is null and j->>'student_id' is not null then select school_id into sid from public.schoolpro_students where id=(j->>'student_id')::uuid;end if;
 d:=coalesce(nullif(j->>'attendance_date','')::date,nullif(j->>'recorded_at','')::timestamptz::date,nullif(j->>'borrowed_at','')::timestamptz::date,current_date);
 if sid is not null and nullif(j->>'session','') is null then select * into t from public.schoolpro_result_term_settings where school_id=sid and term_start_date<=d and term_end_date>=d order by term_start_date desc limit 1;
  if t.id is not null then j:=j||jsonb_build_object('session',t.session);if j?'term' then j:=j||jsonb_build_object('term',t.term);end if;new:=jsonb_populate_record(new,j);end if;
 end if;return new;end$$;
do $$declare tab text;begin foreach tab in array array['schoolpro_attendance','schoolpro_assignments','schoolpro_library_loans','schoolpro_student_transport','schoolpro_hostel_allocations','schoolpro_health_records','schoolpro_discipline_records'] loop execute format('create trigger schoolpro_stamp_activity_period before insert on public.%I for each row execute function private.schoolpro_stamp_activity_period()',tab);end loop;end$$;

