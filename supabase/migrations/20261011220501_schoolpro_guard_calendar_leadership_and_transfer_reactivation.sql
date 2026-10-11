CREATE OR REPLACE FUNCTION public.schoolpro_save_academic_calendar(p_school uuid, p_session text, p_term text, p_start date, p_end date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin
 if not private.schoolpro_module_allowed(p_school,'calendar') or not private.schoolpro_module_allowed(p_school,'promotions') then raise exception 'Calendar permission required';end if;
 if p_session!~'^[0-9]{4}/[0-9]{4}$' or split_part(p_session,'/',2)::int<>split_part(p_session,'/',1)::int+1 or p_term not in('First Term','Second Term','Third Term') or p_start is null or p_end is null then raise exception 'Choose a valid academic session, term and dates';end if;
 insert into public.schoolpro_result_term_settings(school_id,session,term,term_start_date,term_end_date,updated_by)values(p_school,p_session,p_term,p_start,p_end,auth.uid()) on conflict(school_id,session,term) do update set term_start_date=excluded.term_start_date,term_end_date=excluded.term_end_date,updated_by=auth.uid(),updated_at=now();
 perform private.schoolpro_tick_calendar(p_school);
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)values(p_school,auth.uid(),'Academic calendar saved','school',p_school,jsonb_build_object('session',p_session,'term',p_term,'start',p_start,'end',p_end));end$function$
;
create or replace function private.schoolpro_reject_new_inactive_student_activity() returns trigger language plpgsql security definer set search_path='' as $$declare pupil uuid;j jsonb:=to_jsonb(new);prior jsonb;begin if tg_op='UPDATE' then prior:=to_jsonb(old);end if;pupil:=nullif(j->>'student_id','')::uuid;if pupil is not null and(tg_op='INSERT' or j->>'student_id' is distinct from prior->>'student_id' or (j->>'active'='true' and prior->>'active'='false') or j->>'attendance_date' is distinct from prior->>'attendance_date') and exists(select 1 from public.schoolpro_students where id=pupil and(status<>'active' or transferred_out_at is not null)) then raise exception 'This pupil is no longer enrolled for new activities';end if;return new;end$$;
