CREATE OR REPLACE FUNCTION private.schoolpro_student_transcripts(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_students;t record;p record; items jsonb:='[]'; allowed boolean; staff boolean;
begin
 select * into s from public.schoolpro_students where id=p_student;
 if auth.uid() is null or not private.is_active_account() or s.id is null or not private.schoolpro_operationally_active(s.school_id) then raise exception 'Student record unavailable';end if;
 staff:=private.schoolpro_can_issue_transcript(s.school_id) or exists(
select 1 from public.schoolpro_enrollment_history e where e.student_id=s.id and e.school_id=s.school_id and e.class_id=any(private.schoolpro_coordinator_classes(s.school_id)));
 if not staff and not (coalesce(s.user_id=auth.uid(),false) or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=s.id and g.school_id=s.school_id and g.guardian_user_id=auth.uid() and g.status='active')) then raise exception 'Student record unavailable';end if;
 for t in select * from public.schoolpro_transcript_issues where student_id=s.id and school_id=s.school_id order by issued_at desc loop
 allowed:=t.revoked_at is null;
 if allowed and not staff then
 for p in select distinct x->>'term' term,x->>'session' session from jsonb_array_elements(t.snapshot->'records') x loop
 if not coalesce((select a.allowed from private.schoolpro_result_access(s.id,p.term,p.session) a),false) then allowed:=false;exit;end if;
 end loop;
 end if;
 items:=items||jsonb_build_array(jsonb_build_object('id',t.id,'serial_number',t.serial_number,'issued_at',t.issued_at,'revoked',t.revoked_at is not null,'allowed',allowed,'snapshot',case when allowed then t.snapshot else null end));
 end loop;return items;
end $function$
