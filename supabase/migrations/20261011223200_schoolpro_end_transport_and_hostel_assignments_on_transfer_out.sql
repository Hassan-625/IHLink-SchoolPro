CREATE OR REPLACE FUNCTION public.schoolpro_transfer_student_out(p_student uuid, p_destination text, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare s public.schoolpro_students;room record;begin
 select * into s from public.schoolpro_students where id=p_student for update;
 if s.id is null or not private.schoolpro_module_allowed(s.school_id,'students') or not private.schoolpro_module_allowed(s.school_id,'promotions') then raise exception 'School management permission required';end if;
 if s.status<>'active' or s.transferred_out_at is not null then raise exception 'Only an active pupil can be transferred out';end if;
 if nullif(trim(p_reason),'') is null then raise exception 'Enter a transfer reason';end if;
 update public.schoolpro_students set status='withdrawn',transferred_out_at=now(),transfer_destination=nullif(trim(p_destination),''),transfer_reason=trim(p_reason) where id=p_student;
 update public.schoolpro_student_transport set active=false where student_id=p_student and school_id=s.school_id and active;
 for room in select distinct room_id from public.schoolpro_hostel_allocations where student_id=p_student and school_id=s.school_id and active loop
 perform 1 from public.schoolpro_hostel_rooms where id=room.room_id for update;
 update public.schoolpro_hostel_allocations set active=false where student_id=p_student and school_id=s.school_id and room_id=room.room_id and active;
 update public.schoolpro_hostel_rooms r set occupied=(select count(*) from public.schoolpro_hostel_allocations a where a.room_id=r.id and a.active)where r.id=room.room_id and r.school_id=s.school_id;
 end loop;
 update public.schoolpro_enrollment_history set status='completed' where student_id=p_student and school_id=s.school_id and status='active';
 insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)values(s.school_id,auth.uid(),'Student transferred out','student',s.id,jsonb_build_object('destination',p_destination,'reason',p_reason));end$function$
