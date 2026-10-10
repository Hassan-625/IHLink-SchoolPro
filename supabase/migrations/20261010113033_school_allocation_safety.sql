-- Keep allocation changes atomic and school-scoped, including manager roles.
create or replace function public.assign_schoolpro_transport(p_route uuid,p_student uuid,p_pickup text) returns uuid language plpgsql security definer set search_path='' as $$
declare r public.schoolpro_transport_routes; aid uuid;
begin
 if auth.uid() is null then raise exception 'Please sign in';end if;
 select * into r from public.schoolpro_transport_routes where id=p_route;
 if r.id is null or not r.active then raise exception 'Choose an active school route';end if;
 if not private.schoolpro_module_allowed(r.school_id,'transport') or not (public.schoolpro_member_can_manage(r.school_id) or private.has_school_access(r.school_id,array['transport_manager']::public.school_member_role[])) then raise exception 'School transport permission is required';end if;
 perform 1 from public.schoolpro_students where id=p_student and school_id=r.school_id and status='active' for update;
 if not found then raise exception 'Choose an active student from this school';end if;
 perform 1 from public.schoolpro_transport_routes where id=p_route and active for share;
 if not found then raise exception 'This route is no longer active';end if;
 update public.schoolpro_student_transport set active=false where school_id=r.school_id and student_id=p_student and active;
 insert into public.schoolpro_student_transport(school_id,student_id,route_id,pickup_point,active)values(r.school_id,p_student,p_route,trim(p_pickup),true)returning id into aid;
 return aid;
end $$;
create or replace function public.schoolpro_allocate_hostel(p_school uuid,p_student uuid,p_room uuid,p_session text) returns uuid language plpgsql security definer set search_path='' as $$
declare rm public.schoolpro_hostel_rooms; a uuid; old_rooms uuid[];
begin
 if auth.uid() is null then raise exception 'Please sign in';end if;
 if not private.schoolpro_module_allowed(p_school,'hostel') or not (public.schoolpro_member_can_manage(p_school) or private.has_school_access(p_school,array['hostel_manager']::public.school_member_role[])) then raise exception 'School hostel permission is required';end if;
 if coalesce(trim(p_session),'')='' then raise exception 'Choose the academic session';end if;
 perform 1 from public.schoolpro_students where id=p_student and school_id=p_school and status='active' for update;
 if not found then raise exception 'Choose an active student from this school';end if;
 select array_agg(room_id) into old_rooms from public.schoolpro_hostel_allocations where student_id=p_student and school_id=p_school and active;
 perform 1 from public.schoolpro_hostel_rooms where school_id=p_school and (id=p_room or id=any(coalesce(old_rooms,array[]::uuid[]))) order by id for update;
 select * into rm from public.schoolpro_hostel_rooms where id=p_room and school_id=p_school;
 if rm.id is null then raise exception 'Choose a room from this school';end if;
 select id into a from public.schoolpro_hostel_allocations where student_id=p_student and school_id=p_school and room_id=p_room and session=p_session and active limit 1;
 if a is not null then return a;end if;
 if (select count(*) from public.schoolpro_hostel_allocations where room_id=p_room and active)>=rm.capacity then raise exception 'This room is full';end if;
 update public.schoolpro_hostel_allocations set active=false where school_id=p_school and student_id=p_student and active;
 insert into public.schoolpro_hostel_allocations(school_id,student_id,room_id,session,active)values(p_school,p_student,p_room,trim(p_session),true)returning id into a;
 update public.schoolpro_hostel_rooms rooms set occupied=(select count(*) from public.schoolpro_hostel_allocations x where x.room_id=rooms.id and x.active) where rooms.school_id=p_school and (rooms.id=p_room or rooms.id=any(coalesce(old_rooms,array[]::uuid[])));
 return a;
end $$;
create or replace function public.schoolpro_vacate_hostel(p_allocation uuid) returns void language plpgsql security definer set search_path='' as $$
declare a public.schoolpro_hostel_allocations;
begin
 if auth.uid() is null then raise exception 'Please sign in';end if;
 select * into a from public.schoolpro_hostel_allocations where id=p_allocation;
 if a.id is null then raise exception 'Allocation not found';end if;
 if not private.schoolpro_module_allowed(a.school_id,'hostel') or not(public.schoolpro_member_can_manage(a.school_id) or private.has_school_access(a.school_id,array['hostel_manager']::public.school_member_role[])) then raise exception 'School hostel permission is required';end if;
 perform 1 from public.schoolpro_students where id=a.student_id for update;
 perform 1 from public.schoolpro_hostel_rooms where id=a.room_id for update;
 update public.schoolpro_hostel_allocations set active=false where id=a.id and active;
 update public.schoolpro_hostel_rooms rooms set occupied=(select count(*) from public.schoolpro_hostel_allocations x where x.room_id=rooms.id and x.active) where rooms.id=a.room_id;
end $$;
revoke all on function public.assign_schoolpro_transport(uuid,uuid,text),public.schoolpro_allocate_hostel(uuid,uuid,uuid,text),public.schoolpro_vacate_hostel(uuid) from public,anon;
grant execute on function public.assign_schoolpro_transport(uuid,uuid,text),public.schoolpro_allocate_hostel(uuid,uuid,uuid,text),public.schoolpro_vacate_hostel(uuid) to authenticated;
