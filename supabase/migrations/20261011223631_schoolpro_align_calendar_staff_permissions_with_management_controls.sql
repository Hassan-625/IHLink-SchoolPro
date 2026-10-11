CREATE OR REPLACE FUNCTION public.schoolpro_save_academic_calendar(p_school uuid, p_session text, p_term text, p_start date, p_end date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin
 if not private.schoolpro_module_allowed(p_school,'calendar') or not private.has_school_access(p_school,array['proprietor','administrator','registrar','head_teacher','vice_principal']::public.school_member_role[]) then raise exception 'Calendar permission required';end if;
 if p_session!~'^[0-9]{4}/[0-9]{4}$' or split_part(p_session,'/',2)::int<>split_part(p_session,'/',1)::int+1 or p_term not in('First Term','Second Term','Third Term') or p_start is null or p_end is null then raise exception 'Choose a valid academic session, term and dates';end if;
 insert into public.schoolpro_result_term_settings(school_id,session,term,term_start_date,term_end_date,updated_by)values(p_school,p_session,p_term,p_start,p_end,auth.uid()) on conflict(school_id,session,term) do update set term_start_date=excluded.term_start_date,term_end_date=excluded.term_end_date,updated_by=auth.uid(),updated_at=now();
 perform private.schoolpro_tick_calendar(p_school);
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)values(p_school,auth.uid(),'Academic calendar saved','school',p_school,jsonb_build_object('session',p_session,'term',p_term,'start',p_start,'end',p_end));end$function$
