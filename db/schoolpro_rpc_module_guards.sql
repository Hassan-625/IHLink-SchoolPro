-- Enforce existing module grants inside privileged RPCs without changing their role or ownership checks.
CREATE OR REPLACE FUNCTION public.adjust_schoolpro_inventory(p_asset uuid, p_delta integer, p_condition text DEFAULT NULL::text, p_location text DEFAULT NULL::text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare a schoolpro_inventory_assets%rowtype; q int; begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_inventory_assets where id=p_asset),'inventory') then raise exception 'Module permission denied: inventory'; end if;  select * into a from schoolpro_inventory_assets where id=p_asset for update; if a.id is null then raise exception 'Asset not found'; end if; if not schoolpro_member_can_manage(a.school_id) then raise exception 'Not authorized'; end if; q:=a.quantity+p_delta; if q<0 then raise exception 'Inventory cannot become negative'; end if; update schoolpro_inventory_assets set quantity=q,condition=coalesce(p_condition,condition),location=coalesce(p_location,location) where id=p_asset; return q; end $function$
;
CREATE OR REPLACE FUNCTION public.admit_schoolpro_applicant(p_application uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare a public.schoolpro_admissions;sid uuid;adm text;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_admissions where id=p_application),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into a from public.schoolpro_admissions where id=p_application;if a.id is null then raise exception 'Application not found';end if;if not(public.schoolpro_member_can_manage(a.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('registrar','admissions_officer'))) then raise exception 'Not authorized';end if;if a.admitted_student_id is not null then return a.admitted_student_id;end if;adm:=coalesce(a.application_number,'ADM-'||upper(substr(replace(a.id::text,'-',''),1,8)));insert into public.schoolpro_students(school_id,admission_number,first_name,last_name,class_name,gender,guardian_name,guardian_phone,status) values(a.school_id,adm,coalesce(nullif(a.first_name,''),split_part(a.applicant_name,' ',1)),coalesce(nullif(a.last_name,''),'Student'),coalesce(a.class_applied,'Unassigned'),a.gender,a.guardian_name,a.guardian_contact,'active') returning id into sid;update public.schoolpro_admissions set status='admitted',reviewed_by=auth.uid(),reviewed_at=now(),admitted_student_id=sid where id=a.id;return sid;end$function$
;
CREATE OR REPLACE FUNCTION public.allocate_schoolpro_hostel(p_room uuid, p_student uuid, p_session text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare r schoolpro_hostel_rooms%rowtype; aid uuid; begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_hostel_rooms where id=p_room),'hostel') then raise exception 'Module permission denied: hostel'; end if;  select * into r from schoolpro_hostel_rooms where id=p_room for update; if r.id is null then raise exception 'Room not found'; end if; if not schoolpro_member_can_manage(r.school_id) then raise exception 'Not authorized'; end if; if r.occupied>=r.capacity then raise exception 'Room is full'; end if; if not exists(select 1 from schoolpro_students where id=p_student and school_id=r.school_id) then raise exception 'Student is outside this school'; end if; update schoolpro_hostel_allocations set active=false where school_id=r.school_id and student_id=p_student and active=true; insert into schoolpro_hostel_allocations(school_id,student_id,room_id,session,active) values(r.school_id,p_student,p_room,p_session,true) returning id into aid; update schoolpro_hostel_rooms set occupied=(select count(*) from schoolpro_hostel_allocations where room_id=p_room and active=true) where id=p_room; return aid; end $function$
;
CREATE OR REPLACE FUNCTION public.apply_schoolpro_promotion(p_promotion uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare p public.schoolpro_promotions;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_promotions where id=p_promotion),'promotions') then raise exception 'Module permission denied: promotions'; end if;  select * into p from public.schoolpro_promotions where id=p_promotion for update;if p.id is null then raise exception 'Promotion not found';end if;if not(public.schoolpro_member_can_manage(p.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=p.school_id and m.user_id=auth.uid() and m.role::text in('registrar','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;if p.status='applied' then return;end if;update public.schoolpro_students set class_name=p.to_class where id=p.student_id and school_id=p.school_id;update public.schoolpro_promotions set status='applied' where id=p.id;end$function$
;
CREATE OR REPLACE FUNCTION public.assign_schoolpro_entrance_cbt(p_application uuid, p_test uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare a public.schoolpro_admissions;t public.schoolpro_cbt_tests;att public.schoolpro_candidate_cbt_attempts;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_admissions where id=p_application),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into a from public.schoolpro_admissions where id=p_application;select * into t from public.schoolpro_cbt_tests where id=p_test and school_id=a.school_id;if a.id is null or t.id is null then raise exception 'Application or test not found';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','admissions_officer','registrar','exam_officer')) then raise exception 'Not authorized';end if;insert into public.schoolpro_candidate_cbt_attempts(application_id,test_id,duration_minutes,expires_at,status) values(a.id,t.id,t.duration_minutes,coalesce(t.closes_at,now()+interval '14 days'),'pending') on conflict(application_id,test_id) do update set expires_at=excluded.expires_at,duration_minutes=excluded.duration_minutes returning * into att;update public.schoolpro_admissions set entrance_test_id=t.id,status='exam_scheduled' where id=a.id;if a.guardian_email is not null then perform public.queue_schoolpro_email(a.school_id,a.guardian_email,a.guardian_name,'entrance_exam_invitation','Entrance examination invitation',jsonb_build_object('applicant_name',a.applicant_name,'test_title',t.title,'cbt_token',att.access_token,'expires_at',att.expires_at));end if;return jsonb_build_object('attempt_id',att.id,'token',att.access_token,'expires_at',att.expires_at);end$function$
;
CREATE OR REPLACE FUNCTION public.assign_schoolpro_transport(p_route uuid, p_student uuid, p_pickup text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare r schoolpro_transport_routes%rowtype; aid uuid; begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_transport_routes where id=p_route),'transport') then raise exception 'Module permission denied: transport'; end if;  select * into r from schoolpro_transport_routes where id=p_route; if r.id is null then raise exception 'Route not found'; end if; if not schoolpro_member_can_manage(r.school_id) then raise exception 'Not authorized'; end if; if not exists(select 1 from schoolpro_students where id=p_student and school_id=r.school_id) then raise exception 'Student is outside this school'; end if; update schoolpro_student_transport set active=false where school_id=r.school_id and student_id=p_student and active=true; insert into schoolpro_student_transport(school_id,student_id,route_id,pickup_point,active) values(r.school_id,p_student,p_route,p_pickup,true) returning id into aid; return aid; end $function$
;
CREATE OR REPLACE FUNCTION public.borrow_schoolpro_library_book(p_book uuid, p_student uuid DEFAULT NULL::uuid, p_member uuid DEFAULT NULL::uuid, p_due timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare b public.schoolpro_library_books;lid uuid;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_library_books where id=p_book),'library') then raise exception 'Module permission denied: library'; end if;  select * into b from public.schoolpro_library_books where id=p_book for update;if b.id is null then raise exception 'Book not found';end if;if not(public.schoolpro_member_can_manage(b.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=b.school_id and m.user_id=auth.uid() and m.role::text='librarian')) then raise exception 'Not authorized';end if;if b.available_copies<=0 then raise exception 'No available copy';end if;if (p_student is null)=(p_member is null) then raise exception 'Choose exactly one borrower';end if;insert into public.schoolpro_library_loans(school_id,book_id,student_id,member_id,due_at,status) values(b.school_id,b.id,p_student,p_member,coalesce(p_due,now()+interval '14 days'),'borrowed') returning id into lid;update public.schoolpro_library_books set available_copies=available_copies-1 where id=b.id;return lid;end$function$
;
CREATE OR REPLACE FUNCTION public.create_schoolpro_portal_invite(p_student uuid, p_email text, p_type text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare st public.schoolpro_students; iid uuid;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_students where id=p_student),'students') then raise exception 'Module permission denied: students'; end if;  select * into st from public.schoolpro_students where id=p_student;if st.id is null then raise exception 'Student not found';end if;if p_type not in('student','parent') then raise exception 'Invalid invite type';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=st.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','registrar','admissions_officer')) and not exists(select 1 from public.schoolpro_schools s where s.id=st.school_id and s.owner_id=auth.uid()) then raise exception 'Not authorized';end if;insert into public.schoolpro_portal_invites(school_id,student_id,email,invite_type) values(st.school_id,st.id,lower(trim(p_email)),p_type) returning id into iid;perform public.queue_schoolpro_email(st.school_id,p_email,st.first_name||' '||st.last_name,'portal_invitation','Your SchoolPro portal invitation',jsonb_build_object('student_id',st.id,'invite_type',p_type));return iid;end$function$
;
CREATE OR REPLACE FUNCTION public.create_schoolpro_result_pin(target_student uuid, target_term text, target_session text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare sid uuid; token text;
begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_students where id=target_student),'results') then raise exception 'Module permission denied: results'; end if; 
 select s.school_id into sid from public.schoolpro_students s where s.id=target_student;
 if sid is null then raise exception 'Student not found'; end if;
 if not (private.has_school_access(sid) and (
   exists(select 1 from public.schoolpro_schools sc where sc.id=sid and sc.owner_id=(select auth.uid()))
   or exists(select 1 from public.schoolpro_members m where m.school_id=sid and m.user_id=(select auth.uid()) and m.role in ('proprietor','administrator'))
   or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='super_admin')
 )) then raise exception 'Not permitted to create result access PINs'; end if;
 token:=upper(substr(encode(gen_random_bytes(8),'hex'),1,12));
 insert into public.schoolpro_result_access_pins(school_id,student_id,term,session,pin_hash,created_by,is_active)
 values(sid,target_student,target_term,target_session,encode(digest(token,'sha256'),'hex'),(select auth.uid()),true)
 on conflict(student_id,term,session) do update set pin_hash=excluded.pin_hash,created_by=excluded.created_by,created_at=now(),is_active=true,expires_at=null;
 return token;
end $function$
;
CREATE OR REPLACE FUNCTION public.ensure_schoolpro_default_assessment_scheme(p_school uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare sid uuid;begin if not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied: results'; end if;  if not public.schoolpro_member_can_manage(p_school) then raise exception 'Not authorized';end if;select id into sid from public.schoolpro_assessment_schemes where school_id=p_school and is_default=true limit 1;if sid is null then insert into public.schoolpro_assessment_schemes(school_id,name,school_level,components,is_default) values(p_school,'Standard 40/60','All',jsonb_build_array(jsonb_build_object('key','ca1_assignment','label','1st CA Assignment','max',10),jsonb_build_object('key','ca2_assignment','label','2nd CA Assignment','max',10),jsonb_build_object('key','ca1_test','label','1st CA Test','max',10),jsonb_build_object('key','ca2_test','label','2nd CA Test','max',10),jsonb_build_object('key','exam','label','Exam','max',60)),true) returning id into sid;end if;return sid;end$function$
;
CREATE OR REPLACE FUNCTION public.ensure_schoolpro_standard_assessment_schemes(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare n uuid;j uuid;s uuid;begin if not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied: results'; end if;  if not public.schoolpro_member_can_manage(p_school) then raise exception 'Not authorized';end if;
insert into public.schoolpro_assessment_schemes(school_id,name,school_level,components,is_default) select p_school,'Nursery & Primary Standard','nursery_primary',jsonb_build_array(jsonb_build_object('key','assignment_1','label','1st CA Assignment','maxScore',10),jsonb_build_object('key','assignment_2','label','2nd CA Assignment','maxScore',10),jsonb_build_object('key','test_1','label','1st CA Test','maxScore',10),jsonb_build_object('key','test_2','label','2nd CA Test','maxScore',10),jsonb_build_object('key','exam','label','Examination','maxScore',60)),not exists(select 1 from public.schoolpro_assessment_schemes where school_id=p_school) where not exists(select 1 from public.schoolpro_assessment_schemes where school_id=p_school and school_level='nursery_primary') returning id into n;
insert into public.schoolpro_assessment_schemes(school_id,name,school_level,components,is_default) select p_school,'Junior Secondary Standard','junior_secondary',jsonb_build_array(jsonb_build_object('key','assignment_1','label','1st CA Assignment','maxScore',10),jsonb_build_object('key','assignment_2','label','2nd CA Assignment','maxScore',10),jsonb_build_object('key','test_1','label','1st CA Test','maxScore',10),jsonb_build_object('key','test_2','label','2nd CA Test','maxScore',10),jsonb_build_object('key','exam','label','Examination','maxScore',60)),false where not exists(select 1 from public.schoolpro_assessment_schemes where school_id=p_school and school_level='junior_secondary') returning id into j;
insert into public.schoolpro_assessment_schemes(school_id,name,school_level,components,is_default) select p_school,'Senior Secondary Standard','senior_secondary',jsonb_build_array(jsonb_build_object('key','assignment_1','label','1st CA Assignment','maxScore',10),jsonb_build_object('key','assignment_2','label','2nd CA Assignment','maxScore',10),jsonb_build_object('key','test_1','label','1st CA Test','maxScore',10),jsonb_build_object('key','test_2','label','2nd CA Test','maxScore',10),jsonb_build_object('key','exam','label','Examination','maxScore',60)),false where not exists(select 1 from public.schoolpro_assessment_schemes where school_id=p_school and school_level='senior_secondary') returning id into s;
return jsonb_build_object('nursery_primary',n,'junior_secondary',j,'senior_secondary',s);end$function$
;
CREATE OR REPLACE FUNCTION public.finalize_schoolpro_enrollment(p_application uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare a public.schoolpro_admissions;sid uuid;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_admissions where id=p_application),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into a from public.schoolpro_admissions where id=p_application for update;if a.id is null then raise exception 'Application not found';end if;if not(public.schoolpro_member_can_manage(a.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('registrar','admissions_officer'))) then raise exception 'Not authorized';end if;if not exists(select 1 from public.schoolpro_admission_offers o join public.schoolpro_admission_acceptances x on x.application_id=o.application_id where o.application_id=a.id and o.status='accepted' and o.accepted_at is not null and x.terms_accepted=true) then raise exception 'A valid admission offer has not been accepted';end if;sid:=public.admit_schoolpro_applicant(a.id);update public.schoolpro_admissions set enrollment_status='enrolled',enrolled_at=now() where id=a.id;return sid;end$function$
;
CREATE OR REPLACE FUNCTION public.generate_schoolpro_class_invoices(p_structure uuid, p_class text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare f public.schoolpro_fee_structures;s public.schoolpro_students;ex public.schoolpro_fee_exceptions;n int:=0;gross numeric;discount_amt numeric;scholarship_amt numeric;waiver_amt numeric;net numeric;
begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_fee_structures where id=p_structure),'finance') then raise exception 'Module permission denied: finance'; end if; 
 select * into f from public.schoolpro_fee_structures where id=p_structure;
 if f.id is null then raise exception 'Fee structure not found';end if;
 if not private.has_school_access(f.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) then raise exception 'Not authorized';end if;
 select coalesce(sum(amount) filter(where not is_optional),0) into gross from public.schoolpro_fee_items where fee_structure_id=f.id;if gross=0 then gross:=f.amount;end if;
 for s in select * from public.schoolpro_students where school_id=f.school_id and status='active' and (coalesce(p_class,f.class_name) is null or class_name=coalesce(p_class,f.class_name)) loop
  ex:=null; select * into ex from public.schoolpro_fee_exceptions where school_id=f.school_id and student_id=s.id and term=f.term and session=f.session;
  discount_amt:=0;scholarship_amt:=0;waiver_amt:=0;
  if ex.id is not null then
   if ex.exception_type='full_waiver' or ex.waived then waiver_amt:=gross;
   elsif ex.exception_type='partial_waiver' then waiver_amt:=case when ex.value_type='percentage' then gross*ex.value/100 else coalesce(nullif(ex.value,0),ex.partial_waiver) end;
   elsif ex.exception_type='scholarship' then scholarship_amt:=case when ex.value_type='percentage' then gross*ex.value/100 else coalesce(nullif(ex.value,0),ex.scholarship) end;
   else discount_amt:=case when ex.value_type='percentage' then gross*ex.value/100 else coalesce(nullif(ex.value,0),ex.discount) end; end if;
  end if;
  discount_amt:=least(gross,greatest(0,discount_amt)); scholarship_amt:=least(gross-discount_amt,greatest(0,scholarship_amt)); waiver_amt:=least(gross-discount_amt-scholarship_amt,greatest(0,waiver_amt));
  net:=greatest(0,gross-discount_amt-scholarship_amt-waiver_amt);
  insert into public.schoolpro_invoices(school_id,student_id,fee_structure_id,title,term,session,gross_amount,amount_due,due_date,discount,scholarship,waiver_amount,status,notes,created_by)
  values(f.school_id,s.id,f.id,f.name,f.term,f.session,gross,net,f.due_date,discount_amt,scholarship_amt,waiver_amt,case when net=0 then 'waived'::public.schoolpro_invoice_status else 'unpaid'::public.schoolpro_invoice_status end,ex.notes,auth.uid()) on conflict do nothing;
  n:=n+1;
 end loop;
 return jsonb_build_object('processed',n,'gross',gross);
end $function$
;
CREATE OR REPLACE FUNCTION public.issue_schoolpro_admission_offer(p_application uuid, p_letter text, p_expiry timestamp with time zone, p_instructions text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare a public.schoolpro_admissions;o public.schoolpro_admission_offers;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_admissions where id=p_application),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into a from public.schoolpro_admissions where id=p_application;if a.id is null then raise exception 'Application not found';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','admissions_officer','registrar')) then raise exception 'Not authorized';end if;insert into public.schoolpro_admission_offers(application_id,offer_number,offered_class,letter_body,expires_at,acceptance_instructions,status) values(a.id,'OFR-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10)),a.class_applied,p_letter,p_expiry,p_instructions,'offered') on conflict(application_id) do update set letter_body=excluded.letter_body,expires_at=excluded.expires_at,acceptance_instructions=excluded.acceptance_instructions,status='offered',issued_at=now() returning * into o;update public.schoolpro_admissions set status='admitted',reviewed_at=now(),reviewed_by=auth.uid() where id=a.id;if a.guardian_email is not null then perform public.queue_schoolpro_email(a.school_id,a.guardian_email,a.guardian_name,'admission_offer','Admission offer for '||a.applicant_name,jsonb_build_object('applicant_name',a.applicant_name,'offer_number',o.offer_number,'offer_token',o.public_token));end if;return jsonb_build_object('offer_id',o.id,'offer_number',o.offer_number,'token',o.public_token);end$function$
;
CREATE OR REPLACE FUNCTION public.link_schoolpro_student_account(target_student uuid, target_email text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare sid uuid; uid uuid;
begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_students where id=target_student),'students') then raise exception 'Module permission denied: students'; end if; 
 select school_id into sid from public.schoolpro_students where id=target_student;
 if sid is null then raise exception 'Student not found'; end if;
 if not (
 exists(select 1 from public.schoolpro_schools s where s.id=sid and s.owner_id=(select auth.uid()))
 or exists(select 1 from public.schoolpro_members m where m.school_id=sid and m.user_id=(select auth.uid()) and m.role='administrator')
 or exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='super_admin')
 ) then raise exception 'Not permitted'; end if;
 select id into uid from public.profiles where lower(email)=lower(trim(target_email)) limit 1;
 if uid is null then raise exception 'No IHLink account exists for this email'; end if;
 update public.schoolpro_students set user_id=uid where id=target_student;
end $function$
;
CREATE OR REPLACE FUNCTION public.mark_schoolpro_theory_answer(p_answer uuid, p_marks numeric, p_feedback text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare a public.schoolpro_cbt_answers;at public.schoolpro_cbt_attempts;t public.schoolpro_cbt_tests;q public.schoolpro_question_bank;begin if not private.schoolpro_module_allowed((select t.school_id from public.schoolpro_cbt_answers a join public.schoolpro_cbt_attempts at on at.id=a.attempt_id join public.schoolpro_cbt_tests t on t.id=at.test_id where a.id=p_answer),'cbt') then raise exception 'Module permission denied: cbt'; end if;  select * into a from public.schoolpro_cbt_answers where id=p_answer for update;if a.id is null then raise exception 'Answer not found';end if;select * into at from public.schoolpro_cbt_attempts where id=a.attempt_id;select * into t from public.schoolpro_cbt_tests where id=at.test_id;select * into q from public.schoolpro_question_bank where id=a.question_id;if q.question_type<>'theory' then raise exception 'Only theory answers require manual marking';end if;if not(public.schoolpro_member_can_manage(t.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=t.school_id and m.user_id=auth.uid() and m.role::text in('teacher','class_teacher','exam_officer','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;if p_marks<0 or p_marks>q.marks then raise exception 'Marks must be between 0 and question maximum';end if;update public.schoolpro_cbt_answers set marks_awarded=p_marks,feedback=p_feedback,marked_by=auth.uid(),marked_at=now(),is_correct=null where id=a.id;update public.schoolpro_cbt_attempts set score=(select coalesce(sum(coalesce(x.marks_awarded,0)),0) from public.schoolpro_cbt_answers x where x.attempt_id=at.id) where id=at.id;end$function$
;
CREATE OR REPLACE FUNCTION public.process_schoolpro_payroll(p_record uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare r schoolpro_payroll_records%rowtype; begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_payroll_records where id=p_record),'payroll') then raise exception 'Module permission denied: payroll'; end if;  select * into r from schoolpro_payroll_records where id=p_record; if r.id is null then raise exception 'Payroll record not found'; end if; if not schoolpro_member_can_manage(r.school_id) and not exists(select 1 from schoolpro_members m where m.school_id=r.school_id and m.user_id=auth.uid() and m.role::text in ('bursar','accountant')) then raise exception 'Not authorized'; end if; update schoolpro_payroll_records set net=greatest(coalesce(gross,0)-coalesce(deductions,0),0),status='processed' where id=p_record; end $function$
;
CREATE OR REPLACE FUNCTION public.publish_schoolpro_results(p_school uuid, p_term text, p_session text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare n int;begin if not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied: results'; end if;  if not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;update public.schoolpro_results set status='published',published_at=now() where school_id=p_school and term=p_term and session=p_session and status='approved';get diagnostics n=row_count;return n;end$function$
;
CREATE OR REPLACE FUNCTION public.queue_schoolpro_email(p_school uuid, p_email text, p_name text, p_template text, p_subject text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare eid uuid;begin if not private.schoolpro_module_allowed(p_school,'notifications') then raise exception 'Module permission denied: notifications'; end if;  if auth.uid() is null then raise exception 'Authentication required';end if;if not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('registrar','admissions_officer','teacher','class_teacher','exam_officer','accountant','bursar'))) then raise exception 'Not authorized';end if;if p_email is null or position('@' in p_email)=0 then raise exception 'Valid email required';end if;insert into public.schoolpro_email_queue(school_id,recipient_email,recipient_name,template_key,subject,payload) values(p_school,lower(trim(p_email)),p_name,p_template,p_subject,coalesce(p_payload,'{}'::jsonb)) returning id into eid;return eid;end$function$
;
CREATE OR REPLACE FUNCTION public.retry_schoolpro_email(p_job uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare j public.schoolpro_email_queue;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_email_queue where id=p_job),'notifications') then raise exception 'Module permission denied: notifications'; end if;  select * into j from public.schoolpro_email_queue where id=p_job for update;if j.id is null then raise exception 'Email job not found';end if;if not(public.schoolpro_member_can_manage(j.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=j.school_id and m.user_id=auth.uid() and m.role::text in('registrar','admissions_officer'))) then raise exception 'Not authorized';end if;update public.schoolpro_email_queue set status='pending',scheduled_at=now(),error=null where id=j.id;end$function$
;
CREATE OR REPLACE FUNCTION public.return_schoolpro_library_book(p_loan uuid, p_fine numeric DEFAULT 0)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare l public.schoolpro_library_loans;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_library_loans where id=p_loan),'library') then raise exception 'Module permission denied: library'; end if;  select * into l from public.schoolpro_library_loans where id=p_loan for update;if l.id is null then raise exception 'Loan not found';end if;if not(public.schoolpro_member_can_manage(l.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=l.school_id and m.user_id=auth.uid() and m.role::text='librarian')) then raise exception 'Not authorized';end if;if l.returned_at is not null then return;end if;update public.schoolpro_library_loans set returned_at=now(),fine=greatest(coalesce(p_fine,0),0),status='returned' where id=l.id;update public.schoolpro_library_books set available_copies=least(copies,available_copies+1) where id=l.book_id;end$function$
;
CREATE OR REPLACE FUNCTION public.review_schoolpro_payment_proof(p_proof uuid, p_decision text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare pr public.schoolpro_payment_proofs%rowtype; inv public.schoolpro_invoices%rowtype; pid uuid; np numeric;
begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_payment_proofs where id=p_proof),'finance') then raise exception 'Module permission denied: finance'; end if; 
 if p_decision not in('confirmed','rejected') then raise exception 'Invalid review decision'; end if;
 select * into pr from public.schoolpro_payment_proofs where id=p_proof for update;if pr.id is null then raise exception 'Payment proof not found';end if;
 if not private.has_school_access(pr.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) then raise exception 'Permission denied';end if;
 if pr.status<>'pending' then raise exception 'Payment proof already reviewed';end if;
 if p_decision='rejected' then update public.schoolpro_payment_proofs set status='rejected',review_note=p_note,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=pr.id;return jsonb_build_object('status','rejected');end if;
 select * into inv from public.schoolpro_invoices where id=pr.invoice_id for update;
 if inv.id is null or inv.school_id<>pr.school_id or inv.student_id<>pr.student_id then raise exception 'Invoice mapping mismatch';end if;
 if inv.status in('paid','waived') or inv.amount_paid+pr.amount>inv.amount_due then raise exception 'Proof amount exceeds outstanding invoice balance';end if;
 insert into public.schoolpro_fee_payments(school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by) values(pr.school_id,pr.invoice_id,pr.student_id,pr.amount,'transfer',coalesce(nullif(btrim(pr.bank_reference),''),'PROOF-'||pr.id::text),'Parent receipt confirmed: '||coalesce(p_note,''),auth.uid()) returning id into pid;
 np:=inv.amount_paid+pr.amount;update public.schoolpro_invoices set amount_paid=np,status=case when np>=amount_due then 'paid'::public.schoolpro_invoice_status else 'part_paid'::public.schoolpro_invoice_status end,updated_at=now() where id=inv.id;
 update public.schoolpro_payment_proofs set status='confirmed',review_note=p_note,reviewed_by=auth.uid(),reviewed_at=now(),payment_id=pid,updated_at=now() where id=pr.id;
 return jsonb_build_object('status','confirmed','payment_id',pid,'invoice_status',case when np>=inv.amount_due then 'paid' else 'part_paid' end,'amount_paid',np);
end $function$
;
CREATE OR REPLACE FUNCTION public.review_schoolpro_payment_submission(p_submission uuid, p_decision text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_payment_submissions%rowtype;a public.schoolpro_payment_allocations%rowtype;inv public.schoolpro_invoices%rowtype;pid uuid;np numeric;
begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_payment_submissions where id=p_submission),'finance') then raise exception 'Module permission denied: finance'; end if; 
 if p_decision not in('confirmed','rejected') then raise exception 'Invalid decision';end if;select * into s from public.schoolpro_payment_submissions where id=p_submission for update;if s.id is null then raise exception 'Submission not found';end if;
 if not private.has_school_access(s.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) then raise exception 'Permission denied';end if;if s.status<>'pending' then raise exception 'Already reviewed';end if;
 if p_decision='rejected' then update public.schoolpro_payment_submissions set status='rejected',review_note=p_note,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=s.id;return jsonb_build_object('status','rejected');end if;
 for a in select * from public.schoolpro_payment_allocations where submission_id=s.id for update loop select * into inv from public.schoolpro_invoices where id=a.invoice_id for update;if inv.id is null or inv.school_id<>s.school_id or inv.student_id<>a.student_id or inv.amount_paid+a.amount>inv.amount_due then raise exception 'Allocation no longer matches invoice balance';end if;insert into public.schoolpro_fee_payments(school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by) values(s.school_id,inv.id,inv.student_id,a.amount,'transfer',coalesce(s.bank_reference,'SUB-'||s.id::text)||'-'||a.id::text,'Confirmed uploaded receipt: '||coalesce(p_note,''),auth.uid()) returning id into pid;np:=inv.amount_paid+a.amount;update public.schoolpro_invoices set amount_paid=np,status=case when np>=amount_due then 'paid'::public.schoolpro_invoice_status else 'part_paid'::public.schoolpro_invoice_status end,updated_at=now() where id=inv.id;update public.schoolpro_payment_allocations set payment_id=pid where id=a.id;end loop;
 update public.schoolpro_payment_submissions set status='confirmed',review_note=p_note,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now() where id=s.id;return jsonb_build_object('status','confirmed');
end $function$
;
CREATE OR REPLACE FUNCTION public.review_schoolpro_result(p_result uuid, p_status text, p_notes text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare r public.schoolpro_results;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_results where id=p_result),'results') then raise exception 'Module permission denied: results'; end if;  select * into r from public.schoolpro_results where id=p_result for update;if r.id is null then raise exception 'Result not found';end if;if p_status not in('approved','rejected') then raise exception 'Invalid review status';end if;if not(public.schoolpro_member_can_manage(r.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=r.school_id and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;insert into public.schoolpro_result_approvals(school_id,result_id,status,reviewed_by,reviewed_at,notes) values(r.school_id,r.id,p_status,auth.uid(),now(),p_notes) on conflict(result_id) do update set status=excluded.status,reviewed_by=excluded.reviewed_by,reviewed_at=excluded.reviewed_at,notes=excluded.notes;update public.schoolpro_results set status=case when p_status='approved' then 'approved'::public.schoolpro_result_status else 'draft'::public.schoolpro_result_status end,approved_by=case when p_status='approved' then auth.uid() else null end,approved_at=case when p_status='approved' then now() else null end,published_at=null where id=r.id;end$function$
;
CREATE OR REPLACE FUNCTION public.schedule_schoolpro_admission_event(p_application uuid, p_type text, p_at timestamp with time zone, p_location text, p_notes text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare a public.schoolpro_admissions;e uuid;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_admissions where id=p_application),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into a from public.schoolpro_admissions where id=p_application;if a.id is null then raise exception 'Application not found';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','admissions_officer','registrar')) then raise exception 'Not authorized';end if;insert into public.schoolpro_admission_events(application_id,event_type,scheduled_at,location,notes) values(a.id,p_type,p_at,p_location,p_notes) returning id into e;if a.guardian_email is not null then perform public.queue_schoolpro_email(a.school_id,a.guardian_email,a.guardian_name,'admission_event','School admission '||p_type||' schedule',jsonb_build_object('applicant_name',a.applicant_name,'scheduled_at',p_at,'location',p_location,'notes',p_notes));end if;return e;end$function$
;
CREATE OR REPLACE FUNCTION public.schoolpro_record_offline_payment(p_invoice uuid, p_amount numeric, p_method text, p_reference text, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare i public.schoolpro_invoices;pid uuid;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_invoices where id=p_invoice),'finance') then raise exception 'Module permission denied: finance'; end if;  select * into i from public.schoolpro_invoices where id=p_invoice for update;if i.id is null then raise exception 'Invoice not found';end if;if not(public.schoolpro_member_can_manage(i.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=i.school_id and m.user_id=auth.uid() and m.role::text in('accountant','bursar'))) then raise exception 'Not authorized';end if;if p_amount is null or p_amount::text in ('NaN','Infinity','-Infinity') or p_amount<>round(p_amount,2) or p_amount<=0 or coalesce(i.amount_paid,0)+p_amount>i.amount_due then raise exception 'Invalid payment amount';end if;insert into public.schoolpro_fee_payments(school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by) values(i.school_id,i.id,i.student_id,p_amount,p_method,p_reference,p_notes,auth.uid()) returning id into pid;update public.schoolpro_invoices set amount_paid=coalesce(amount_paid,0)+p_amount,status=case when coalesce(amount_paid,0)+p_amount>=amount_due then 'paid'::public.schoolpro_invoice_status else 'part_paid'::public.schoolpro_invoice_status end,updated_at=now() where id=i.id;return pid;end$function$
;
CREATE OR REPLACE FUNCTION public.schoolpro_set_result_lock(p_school uuid, p_term text, p_session text, p_locked boolean)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare n int; begin if not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied: results'; end if; 
 if not exists(select 1 from schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid()) and not exists(select 1 from schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in ('proprietor','administrator','exam_officer','head_teacher','vice_principal')) then raise exception 'Not authorized'; end if;
 update schoolpro_results set locked=p_locked where school_id=p_school and term=p_term and session=p_session; get diagnostics n=row_count; return n; end $function$
;
CREATE OR REPLACE FUNCTION public.set_schoolpro_default_document_template(p_template uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare t public.schoolpro_document_templates;
begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_document_templates where id=p_template),'documents') then raise exception 'Module permission denied: documents'; end if; 
 select * into t from public.schoolpro_document_templates where id=p_template;
 if t.id is null then raise exception 'Template not found'; end if;
 if not public.schoolpro_member_can_manage(t.school_id) then raise exception 'Not authorized'; end if;
 update public.schoolpro_document_templates set is_default=false,updated_at=now() where school_id=t.school_id and document_type=t.document_type and id<>t.id;
 update public.schoolpro_document_templates set is_default=true,is_active=true,updated_at=now() where id=t.id;
end$function$
;
CREATE OR REPLACE FUNCTION public.verify_schoolpro_admission_document(p_document uuid, p_verified boolean, p_notes text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare d public.schoolpro_admission_documents;a public.schoolpro_admissions;begin if not private.schoolpro_module_allowed((select a.school_id from public.schoolpro_admission_documents d join public.schoolpro_admissions a on a.id=d.application_id where d.id=p_document),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into d from public.schoolpro_admission_documents where id=p_document;select * into a from public.schoolpro_admissions where id=d.application_id;if a.id is null then raise exception 'Document not found';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','admissions_officer','registrar')) then raise exception 'Not authorized';end if;update public.schoolpro_admission_documents set verified=p_verified,verified_by=auth.uid(),verified_at=now(),verification_notes=p_notes where id=p_document;end$function$
;

