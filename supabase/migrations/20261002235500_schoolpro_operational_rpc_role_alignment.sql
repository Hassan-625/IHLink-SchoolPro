-- Align SchoolPro operational RPC authorization with dedicated school roles.
-- Each RPC derives the tenant from the target row and then verifies membership in that same school.

create or replace function public.adjust_schoolpro_inventory(p_asset uuid,p_delta integer,p_condition text default null,p_location text default null)
returns integer language plpgsql security definer set search_path='' as $$
declare a public.schoolpro_inventory_assets%rowtype; q int;
begin
 select * into a from public.schoolpro_inventory_assets where id=p_asset for update;
 if a.id is null then raise exception 'Asset not found'; end if;
 if not (
   public.schoolpro_member_can_manage(a.school_id)
   or exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text='inventory_officer')
 ) then raise exception 'Not authorized'; end if;
 q:=a.quantity+p_delta;
 if q<0 then raise exception 'Inventory cannot become negative'; end if;
 update public.schoolpro_inventory_assets set quantity=q,condition=coalesce(p_condition,condition),location=coalesce(p_location,location) where id=p_asset and school_id=a.school_id;
 return q;
end $$;

create or replace function public.allocate_schoolpro_hostel(p_room uuid,p_student uuid,p_session text)
returns uuid language plpgsql security definer set search_path='' as $$
declare r public.schoolpro_hostel_rooms%rowtype; aid uuid;
begin
 select * into r from public.schoolpro_hostel_rooms where id=p_room for update;
 if r.id is null then raise exception 'Room not found'; end if;
 if not (
   public.schoolpro_member_can_manage(r.school_id)
   or exists(select 1 from public.schoolpro_members m where m.school_id=r.school_id and m.user_id=auth.uid() and m.role::text='hostel_manager')
 ) then raise exception 'Not authorized'; end if;
 if r.occupied>=r.capacity then raise exception 'Room is full'; end if;
 if not exists(select 1 from public.schoolpro_students where id=p_student and school_id=r.school_id) then raise exception 'Student is outside this school'; end if;
 update public.schoolpro_hostel_allocations set active=false where school_id=r.school_id and student_id=p_student and active=true;
 insert into public.schoolpro_hostel_allocations(school_id,student_id,room_id,session,active) values(r.school_id,p_student,p_room,p_session,true) returning id into aid;
 update public.schoolpro_hostel_rooms set occupied=(select count(*) from public.schoolpro_hostel_allocations where room_id=p_room and school_id=r.school_id and active=true) where id=p_room and school_id=r.school_id;
 return aid;
end $$;

create or replace function public.assign_schoolpro_transport(p_route uuid,p_student uuid,p_pickup text)
returns uuid language plpgsql security definer set search_path='' as $$
declare r public.schoolpro_transport_routes%rowtype; aid uuid;
begin
 select * into r from public.schoolpro_transport_routes where id=p_route;
 if r.id is null then raise exception 'Route not found'; end if;
 if not (
   public.schoolpro_member_can_manage(r.school_id)
   or exists(select 1 from public.schoolpro_members m where m.school_id=r.school_id and m.user_id=auth.uid() and m.role::text='transport_manager')
 ) then raise exception 'Not authorized'; end if;
 if not exists(select 1 from public.schoolpro_students where id=p_student and school_id=r.school_id) then raise exception 'Student is outside this school'; end if;
 update public.schoolpro_student_transport set active=false where school_id=r.school_id and student_id=p_student and active=true;
 insert into public.schoolpro_student_transport(school_id,student_id,route_id,pickup_point,active) values(r.school_id,p_student,p_route,p_pickup,true) returning id into aid;
 return aid;
end $$;

revoke all on function public.adjust_schoolpro_inventory(uuid,integer,text,text) from public,anon;
revoke all on function public.allocate_schoolpro_hostel(uuid,uuid,text) from public,anon;
revoke all on function public.assign_schoolpro_transport(uuid,uuid,text) from public,anon;
grant execute on function public.adjust_schoolpro_inventory(uuid,integer,text,text) to authenticated;
grant execute on function public.allocate_schoolpro_hostel(uuid,uuid,text) to authenticated;
grant execute on function public.assign_schoolpro_transport(uuid,uuid,text) to authenticated;
