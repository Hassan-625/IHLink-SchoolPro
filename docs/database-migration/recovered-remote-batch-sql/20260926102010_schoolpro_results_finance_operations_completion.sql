alter table public.schoolpro_invoices add column if not exists discount numeric not null default 0 check(discount>=0);
alter table public.schoolpro_invoices add column if not exists scholarship numeric not null default 0 check(scholarship>=0);
alter table public.schoolpro_invoices add column if not exists result_hold boolean not null default false;
alter table public.schoolpro_results add column if not exists locked boolean not null default false;
alter table public.schoolpro_results add column if not exists head_teacher_comment text;

create or replace function public.schoolpro_result_comment(p_score numeric) returns text language sql immutable as $$ select case when p_score>=80 then 'Excellent performance. Keep up the outstanding work.' when p_score>=70 then 'Very good performance. Keep working consistently.' when p_score>=60 then 'Good performance with room for further improvement.' when p_score>=50 then 'Fair performance. More consistent effort is encouraged.' when p_score>=40 then 'Performance is below the desired standard. More effort and support are required.' else 'Significant improvement is required. Please review the subject areas and seek support.' end $$;

create or replace function public.schoolpro_set_result_lock(p_school uuid,p_term text,p_session text,p_locked boolean)
returns integer language plpgsql security definer set search_path=public as $$ declare n int; begin
 if not exists(select 1 from schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid()) and not exists(select 1 from schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in ('proprietor','administrator','exam_officer','head_teacher','vice_principal')) then raise exception 'Not authorized'; end if;
 update schoolpro_results set locked=p_locked where school_id=p_school and term=p_term and session=p_session; get diagnostics n=row_count; return n; end $$;

create or replace function public.schoolpro_can_release_result(p_student uuid,p_term text,p_session text)
returns boolean language sql stable security definer set search_path=public as $$
 select not exists(select 1 from schoolpro_invoices i where i.student_id=p_student and i.term=p_term and i.session=p_session and (i.result_hold=true or greatest(i.amount_due-i.discount-i.scholarship-i.amount_paid,0)>0));
$$;

create or replace function public.allocate_schoolpro_hostel(p_room uuid,p_student uuid,p_session text)
returns uuid language plpgsql security definer set search_path=public as $$ declare r schoolpro_hostel_rooms%rowtype; aid uuid; begin
 select * into r from schoolpro_hostel_rooms where id=p_room for update; if r.id is null then raise exception 'Room not found'; end if;
 if not schoolpro_can_manage_cbt(r.school_id) then raise exception 'Not authorized'; end if;
 if r.occupied>=r.capacity then raise exception 'Room is full'; end if;
 if not exists(select 1 from schoolpro_students where id=p_student and school_id=r.school_id) then raise exception 'Student is outside this school'; end if;
 update schoolpro_hostel_allocations set active=false where school_id=r.school_id and student_id=p_student and active=true;
 insert into schoolpro_hostel_allocations(school_id,student_id,room_id,session,active) values(r.school_id,p_student,p_room,p_session,true) returning id into aid;
 update schoolpro_hostel_rooms set occupied=(select count(*) from schoolpro_hostel_allocations where room_id=p_room and active=true) where id=p_room; return aid; end $$;

create or replace function public.assign_schoolpro_transport(p_route uuid,p_student uuid,p_pickup text)
returns uuid language plpgsql security definer set search_path=public as $$ declare r schoolpro_transport_routes%rowtype; aid uuid; begin
 select * into r from schoolpro_transport_routes where id=p_route; if r.id is null then raise exception 'Route not found'; end if; if not schoolpro_can_manage_cbt(r.school_id) then raise exception 'Not authorized'; end if;
 update schoolpro_student_transport set active=false where school_id=r.school_id and student_id=p_student and active=true;
 insert into schoolpro_student_transport(school_id,student_id,route_id,pickup_point,active) values(r.school_id,p_student,p_route,p_pickup,true) returning id into aid; return aid; end $$;

create or replace function public.adjust_schoolpro_inventory(p_asset uuid,p_delta integer,p_condition text default null,p_location text default null)
returns integer language plpgsql security definer set search_path=public as $$ declare a schoolpro_inventory_assets%rowtype; q int; begin
 select * into a from schoolpro_inventory_assets where id=p_asset for update; if a.id is null then raise exception 'Asset not found'; end if; if not schoolpro_can_manage_cbt(a.school_id) then raise exception 'Not authorized'; end if;
 q:=a.quantity+p_delta; if q<0 then raise exception 'Inventory cannot become negative'; end if; update schoolpro_inventory_assets set quantity=q,condition=coalesce(p_condition,condition),location=coalesce(p_location,location) where id=p_asset; return q; end $$;

create or replace function public.process_schoolpro_payroll(p_record uuid)
returns void language plpgsql security definer set search_path=public as $$ declare r schoolpro_payroll_records%rowtype; begin select * into r from schoolpro_payroll_records where id=p_record; if r.id is null then raise exception 'Payroll record not found'; end if; if not schoolpro_can_manage_cbt(r.school_id) then raise exception 'Not authorized'; end if; update schoolpro_payroll_records set net=greatest(coalesce(gross,0)-coalesce(deductions,0),0),status='processed' where id=p_record; end $$;

revoke all on function public.schoolpro_set_result_lock(uuid,text,text,boolean) from public,anon;
revoke all on function public.schoolpro_can_release_result(uuid,text,text) from public,anon;
revoke all on function public.allocate_schoolpro_hostel(uuid,uuid,text) from public,anon;
revoke all on function public.assign_schoolpro_transport(uuid,uuid,text) from public,anon;
revoke all on function public.adjust_schoolpro_inventory(uuid,integer,text,text) from public,anon;
revoke all on function public.process_schoolpro_payroll(uuid) from public,anon;
grant execute on function public.schoolpro_set_result_lock(uuid,text,text,boolean),public.schoolpro_can_release_result(uuid,text,text),public.allocate_schoolpro_hostel(uuid,uuid,text),public.assign_schoolpro_transport(uuid,uuid,text),public.adjust_schoolpro_inventory(uuid,integer,text,text),public.process_schoolpro_payroll(uuid) to authenticated;