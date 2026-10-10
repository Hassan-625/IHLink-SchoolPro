begin;
-- Every fixture below is rolled back; no live school or learner records are changed.
do $$
<<fixture>>
declare owner_id uuid:=gen_random_uuid(); teacher_id uuid:=gen_random_uuid(); parent_id uuid:=gen_random_uuid(); learner_id uuid:=gen_random_uuid(); other_parent uuid:=gen_random_uuid(); school_id uuid:=gen_random_uuid(); class_id uuid:=gen_random_uuid(); other_class uuid:=gen_random_uuid(); student_id uuid:=gen_random_uuid(); other_student uuid:=gen_random_uuid(); member_id uuid:=gen_random_uuid(); subject_id uuid:=gen_random_uuid(); result_id uuid:=gen_random_uuid(); lesson_id uuid:=gen_random_uuid(); book_id uuid:=gen_random_uuid(); loan_id uuid; asset_id uuid:=gen_random_uuid(); route_id uuid:=gen_random_uuid(); room_id uuid:=gen_random_uuid(); allocation_id uuid; progression_id uuid; blocked boolean; denied boolean; n integer;
begin
 insert into auth.users(id,aud,role,email,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
 select v.id,'authenticated','authenticated','fixture-'||v.id||'@example.invalid','{}','{"first_name":"Test","middle_name":"Fixture","last_name":"User"}',now(),now() from (values(owner_id),(teacher_id),(parent_id),(learner_id),(other_parent))v(id);
 insert into public.schoolpro_schools(id,owner_id,name,code)values(school_id,owner_id,'Family access fixture','FIX-'||school_id);
 insert into public.schoolpro_subscriptions(school_id,tier,billing_cycle,status,renews_at)values(school_id,'standard','termly','active',now()+interval '90 days');
 update public.schoolpro_schools set status='active' where id=school_id;
 insert into public.schoolpro_members(id,school_id,user_id,role)values(member_id,school_id,teacher_id,'teacher');
 insert into public.schoolpro_classes(id,school_id,name,level)values(class_id,school_id,'Primary 1','primary'),(other_class,school_id,'JSS 1','junior_secondary');
 insert into public.schoolpro_students(id,school_id,admission_number,first_name,last_name,class_id,class_name,user_id)values(student_id,school_id,'FIX-1','One','Fixture',class_id,'Primary 1',learner_id),(other_student,school_id,'FIX-2','Two','Fixture',other_class,'JSS 1',null);
 insert into public.schoolpro_guardian_links(school_id,student_id,guardian_user_id,linked_by)values(school_id,student_id,parent_id,owner_id);
 insert into public.schoolpro_subjects(id,school_id,name,code,class_name)values(subject_id,school_id,'Mathematics','FIX-MTH','Primary 1');
 insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,teacher_member_id,session)values(school_id,class_id,subject_id,member_id,'2026/2027');
 insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,ca_score,exam_score,status,locked)values(result_id,school_id,student_id,subject_id,'First Term','2026/2027',30,50,'published',true);
 insert into public.schoolpro_invoices(school_id,student_id,title,term,session,amount_due,created_by)values(school_id,student_id,'Fixture fees','First Term','2026/2027',100,owner_id);
 insert into public.schoolpro_finance_settings(school_id,block_results_when_owing,allowed_outstanding,updated_by)values(school_id,true,0,owner_id);
 insert into public.schoolpro_member_permissions(school_id,member_id,permission,allowed,updated_by) values(fixture.school_id,fixture.member_id,'leave',true,fixture.owner_id);
 -- Operational leave review and borrower stock are verified without retaining fixtures.
 perform set_config('request.jwt.claim.sub',teacher_id::text,true);
 execute 'set local role authenticated';
 insert into public.schoolpro_leave_requests(school_id,member_id,leave_type,start_date,end_date,reason,status)
 values(fixture.school_id,fixture.member_id,'Personal',current_date,current_date+1,'Fixture','pending');
 execute 'reset role';
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 execute 'set local role authenticated';
 perform public.review_schoolpro_leave((select id from public.schoolpro_leave_requests where schoolpro_leave_requests.school_id=fixture.school_id and schoolpro_leave_requests.member_id=fixture.member_id),'approved');
 if not exists(select 1 from public.schoolpro_leave_requests where schoolpro_leave_requests.school_id=fixture.school_id and reviewed_by=fixture.owner_id and status='approved')then raise exception 'Leave approval missing';end if;
 denied:=false;begin update public.schoolpro_leave_requests set status='pending' where schoolpro_leave_requests.school_id=fixture.school_id;exception when others then denied:=true;end;
 if not denied then raise exception 'Reviewed leave remained editable';end if;
 execute 'reset role';

 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 execute 'set local role authenticated';
 insert into public.schoolpro_library_books(id,school_id,title,copies,available_copies)values(book_id,fixture.school_id,'Fixture book',1,1);
 loan_id:=public.borrow_schoolpro_library_book(book_id,student_id,null,now()+interval '7 days');
 if (select available_copies from public.schoolpro_library_books where id=book_id)<>0 then raise exception 'Borrow failed to decrease availability';end if;
 denied:=false;begin perform public.borrow_schoolpro_library_book(book_id,student_id,null,now()+interval '7 days');exception when others then denied:=true;end;if not denied then raise exception 'Unavailable book issued';end if;
 perform public.return_schoolpro_library_book(loan_id,0);perform public.return_schoolpro_library_book(loan_id,0);
 if (select available_copies from public.schoolpro_library_books where id=book_id)<>1 then raise exception 'Repeated return inflated copies';end if;
 insert into public.schoolpro_inventory_assets(id,school_id,name,quantity)values(asset_id,fixture.school_id,'Fixture stock',2);
 perform public.adjust_schoolpro_inventory(asset_id,-1);
 denied:=false;begin perform public.adjust_schoolpro_inventory(asset_id,-2);exception when others then denied:=true;end;if not denied then raise exception 'Stock became negative';end if;
 insert into public.schoolpro_transport_routes(id,school_id,name)values(route_id,fixture.school_id,'Fixture route');
 perform public.assign_schoolpro_transport(route_id,student_id,'School gate');
 if (select count(*) from public.schoolpro_student_transport t where t.student_id=fixture.student_id and t.active)<>1 then raise exception 'Transport assignment missing';end if;
 insert into public.schoolpro_hostel_rooms(id,school_id,hostel_name,room,capacity)values(room_id,fixture.school_id,'Fixture hostel','One',2);
 allocation_id:=public.schoolpro_allocate_hostel(school_id,student_id,room_id,'2026/2027');
 perform public.schoolpro_vacate_hostel(allocation_id);perform public.schoolpro_vacate_hostel(allocation_id);
 if (select occupied from public.schoolpro_hostel_rooms where id=room_id)<>0 then raise exception 'Vacated room remained occupied';end if;
 progression_id:=public.create_schoolpro_progression(student_id,'2026/2027','promoted',other_class,'Fixture');
 perform public.apply_schoolpro_promotion(progression_id);perform public.apply_schoolpro_promotion(progression_id);
 if not exists(select 1 from public.schoolpro_students st where st.id=student_id and st.class_id=other_class)then raise exception 'Promotion did not update class';end if;
 execute 'reset role';

 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 execute 'set local role authenticated';
 insert into public.schoolpro_payroll_records(school_id,member_id,period,gross,deductions) values(fixture.school_id,fixture.member_id,'2026-10',10000,2500);
 if (select net from public.schoolpro_payroll_records where schoolpro_payroll_records.school_id=fixture.school_id)<>7500 then raise exception 'Payroll calculation failed';end if;
 denied:=false;begin update public.schoolpro_payroll_records set status='paid',payment_reference='TEST' where schoolpro_payroll_records.school_id=fixture.school_id;exception when others then denied:=true;end;
 if not denied then raise exception 'Unapproved payroll became paid';end if;
 perform public.process_schoolpro_payroll((select id from public.schoolpro_payroll_records where schoolpro_payroll_records.school_id=fixture.school_id));
 denied:=false;begin update public.schoolpro_payroll_records set gross=20000 where schoolpro_payroll_records.school_id=fixture.school_id;exception when others then denied:=true;end;
 if not denied then raise exception 'Approved payroll remained editable';end if;
 update public.schoolpro_payroll_records set status='paid',payment_reference='TEST-TRANSFER' where schoolpro_payroll_records.school_id=fixture.school_id;
 if not exists(select 1 from public.schoolpro_payroll_records where schoolpro_payroll_records.school_id=fixture.school_id and paid_at is not null and approved_by=fixture.owner_id) then raise exception 'Payroll history missing';end if;
 insert into public.schoolpro_health_records(school_id,student_id,complaint,status,follow_up_date) values(fixture.school_id,fixture.student_id,'Fixture only','follow-up',current_date+1);
 denied:=false;begin insert into public.schoolpro_health_records(school_id,student_id,complaint,status) values(fixture.school_id,fixture.student_id,'Fixture only','follow-up');exception when others then denied:=true;end;
 if not denied then raise exception 'Follow-up date not enforced';end if;
 insert into public.schoolpro_calendar_events(school_id,title,event_date,end_date,class_id) values(fixture.school_id,'Fixture event',current_date,current_date+1,fixture.class_id);
 denied:=false;begin update public.schoolpro_calendar_events set end_date=current_date-1 where schoolpro_calendar_events.school_id=fixture.school_id;exception when others then denied:=true;end;
 if not denied then raise exception 'Invalid calendar duration accepted';end if;
 execute 'reset role';
 perform set_config('request.jwt.claim.sub',teacher_id::text,true);
 execute 'set local role authenticated';
 if exists(select 1 from public.schoolpro_health_records where schoolpro_health_records.school_id=fixture.school_id) then raise exception 'Teacher accessed private clinic record';end if;
 if exists(select 1 from public.schoolpro_payroll_records where schoolpro_payroll_records.school_id=fixture.school_id) then raise exception 'Teacher accessed payroll';end if;
 execute 'reset role';
end $$;
rollback;
