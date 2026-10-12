CREATE OR REPLACE FUNCTION public.assign_schoolpro_transport(p_route uuid, p_student uuid, p_pickup text, p_session text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.schoolpro_transport_routes; aid uuid;
begin
 if not private.schoolpro_valid_session(p_session) then raise exception 'Choose an academic session';end if;
 if auth.uid() is null then raise exception 'Please sign in';end if;
 select * into r from public.schoolpro_transport_routes where id=p_route;
 if r.id is null or not r.active then raise exception 'Choose an active school route';end if;
 if not private.schoolpro_module_allowed(r.school_id,'transport') or not (public.schoolpro_member_can_manage(r.school_id) or private.has_school_access(r.school_id,array['transport_manager']::public.school_member_role[])) then raise exception 'School transport permission is required';end if;
 perform 1 from public.schoolpro_students where id=p_student and school_id=r.school_id and status='active' for update;
 if not found then raise exception 'Choose an active student from this school';end if;
 perform 1 from public.schoolpro_transport_routes where id=p_route and active for share;
 if not found then raise exception 'This route is no longer active';end if;
 update public.schoolpro_student_transport set active=false where school_id=r.school_id and student_id=p_student and session=p_session and active;
 insert into public.schoolpro_student_transport(school_id,student_id,route_id,pickup_point,active,session)values(r.school_id,p_student,p_route,trim(p_pickup),true,p_session) on conflict(student_id,session) where session is not null do update set route_id=excluded.route_id,pickup_point=excluded.pickup_point,active=true returning id into aid;
 return aid;
end $function$
;
CREATE OR REPLACE FUNCTION public.borrow_schoolpro_library_book(p_book uuid, p_student uuid, p_member uuid, p_due timestamp with time zone, p_session text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare b public.schoolpro_library_books;lid uuid;
begin
 if auth.uid() is null or not private.schoolpro_valid_session(p_session) then raise exception 'Choose an academic session and sign in';end if;
 if not private.schoolpro_module_allowed((select school_id from public.schoolpro_library_books where id=p_book),'library') then raise exception 'Module permission denied: library';end if;
 select * into b from public.schoolpro_library_books where id=p_book for update;
 if b.id is null then raise exception 'Book not found';end if;
 if not(public.schoolpro_member_can_manage(b.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=b.school_id and m.user_id=auth.uid() and m.role::text='librarian')) then raise exception 'Not authorized';end if;
 if b.available_copies<=0 then raise exception 'No available copy';end if;
 if (p_student is null)=(p_member is null) then raise exception 'Choose exactly one borrower';end if;
 if p_student is not null and not exists(select 1 from public.schoolpro_students s where s.id=p_student and s.school_id=b.school_id and s.status='active') then raise exception 'Student borrower does not belong to this school or is inactive';end if;
 if p_member is not null and not exists(select 1 from public.schoolpro_members m where m.id=p_member and m.school_id=b.school_id) then raise exception 'Member borrower does not belong to this school';end if;
 insert into public.schoolpro_library_loans(school_id,book_id,student_id,member_id,due_at,status,session)
 values(b.school_id,b.id,p_student,p_member,coalesce(p_due,now()+interval '14 days'),'borrowed',p_session) returning id into lid;
 update public.schoolpro_library_books set available_copies=available_copies-1 where id=b.id;
 return lid;
end $function$
; 
revoke all on function public.assign_schoolpro_transport(uuid,uuid,text,text) from public,anon;
grant execute on function public.assign_schoolpro_transport(uuid,uuid,text,text) to authenticated;
revoke all on function public.borrow_schoolpro_library_book(uuid,uuid,uuid,timestamptz,text) from public,anon;
grant execute on function public.borrow_schoolpro_library_book(uuid,uuid,uuid,timestamptz,text) to authenticated;
create or replace function public.assign_schoolpro_transport(p_route uuid,p_student uuid,p_pickup text)returns uuid language plpgsql security invoker set search_path='' as $$
declare v_session text;begin
select session into v_session from public.schoolpro_result_term_settings t join public.schoolpro_transport_routes r on r.school_id=t.school_id where r.id=p_route and t.term_start_date<=current_date and t.term_end_date>=current_date limit 1;
return public.assign_schoolpro_transport(p_route,p_student,p_pickup,v_session);
end $$;