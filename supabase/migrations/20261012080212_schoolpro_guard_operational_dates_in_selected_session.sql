create or replace function private.schoolpro_validate_activity_calendar() returns trigger language plpgsql security definer set search_path='' as $$
declare j jsonb:=to_jsonb(new);prior jsonb;d date;begin_date date;end_date date;date_key text;
begin
 if nullif(j->>'session','') is null then return new;end if;
 date_key:=case when j?'attendance_date' then 'attendance_date' when j?'lesson_date' then 'lesson_date' when j?'event_date' then 'event_date' when j?'start_date' then 'start_date' when j?'recorded_at' then 'recorded_at' when j?'borrowed_at' then 'borrowed_at' end;
 if date_key is null or nullif(j->>date_key,'') is null then return new;end if;
 if tg_op='UPDATE' then prior:=to_jsonb(old);if j->>date_key is not distinct from prior->>date_key then return new;end if;end if;
 d:=(j->>date_key)::timestamptz::date;
 select min(term_start_date),max(term_end_date) into begin_date,end_date from public.schoolpro_result_term_settings where school_id=new.school_id and session=new.session;
 if begin_date is not null and (d<begin_date or d>end_date) then raise exception 'The activity date is outside the selected academic session';end if;
 return new;
end $$;
revoke all on function private.schoolpro_validate_activity_calendar() from public,anon,authenticated;
do $$declare t text;begin foreach t in array array['schoolpro_attendance','schoolpro_library_loans','schoolpro_health_records','schoolpro_lesson_notes','schoolpro_calendar_events','schoolpro_leave_requests'] loop execute format('create trigger schoolpro_validate_activity_calendar before insert or update on public.%I for each row execute function private.schoolpro_validate_activity_calendar()',t);end loop;end $$;