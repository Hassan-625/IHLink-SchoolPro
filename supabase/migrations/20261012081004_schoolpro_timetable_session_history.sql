alter table public.schoolpro_timetable_entries add column if not exists session text;
create index schoolpro_timetable_school_session_idx on public.schoolpro_timetable_entries(school_id,session);
create trigger schoolpro_stamp_activity_period before insert on public.schoolpro_timetable_entries for each row execute function private.schoolpro_stamp_activity_period();
create trigger schoolpro_preserve_activity_session before update on public.schoolpro_timetable_entries for each row execute function private.schoolpro_preserve_activity_session();