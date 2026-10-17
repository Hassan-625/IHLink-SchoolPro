# Live SchoolPro public routine definitions — 2026-10-17

**Source:** Supabase `lnqsroyiybutkfngbyge`, PostgreSQL 17.6. Read-only `pg_proc`/ `pg_get_functiondef` capture. **Do not execute this document on Aiven.** Function bodies are copied for review, not automatically approved for porting. Definitions can change after capture; refresh before any migration.

## Summary
- Catalog metadata identified 127 overloads of public routines whose names contain `schoolpro`.
- Full function definitions captured below: 127 overloads across 124 distinct routine names.
- SECURITY DEFINER routines: 95.
- Languages: plpgsql, sql.

## Review requirements
- Check every SECURITY DEFINER body for fixed `search_path`, fully-qualified object references, privilege checks, tenant binding, EXECUTE grants and caller context.
- Check all side effects, row locks, idempotency, audit records, cross-product writes, Supabase Auth helpers, RLS assumptions, extension dependencies and calls to `private.*` helpers.
- These definitions are not a PostgreSQL 18/Aiven compatibility test and do not prove semantic parity. No routine should be ported until the caller/dependency review and authorization test plan are signed off.

## `public.accept_schoolpro_admission_offer(p_token uuid, p_name text, p_email text, p_notes text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.accept_schoolpro_admission_offer(p_token uuid, p_name text, p_email text, p_notes text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare o public.schoolpro_admission_offers;a public.schoolpro_admissions;
begin
 if p_token is null then raise exception 'Invalid admission offer'; end if;
 select * into o from public.schoolpro_admission_offers where public_token=p_token for update;
 if o.id is null then raise exception 'Invalid admission offer';end if;
 if o.expires_at is not null and now()>o.expires_at then raise exception 'Admission offer expired';end if;
 if o.status='accepted' then return jsonb_build_object('accepted',true,'offer_number',o.offer_number);end if;
 if o.status not in('issued','offered','pending') then raise exception 'Offer cannot be accepted';end if;
 if nullif(trim(p_name),'') is null or position('@' in coalesce(p_email,''))=0 then raise exception 'Name and valid email required';end if;
 select * into a from public.schoolpro_admissions where id=o.application_id for update;
 if a.id is null then raise exception 'Application not found'; end if;

 insert into public.schoolpro_admission_acceptances(application_id,offer_id,accepted_by_name,accepted_by_email,terms_accepted,notes)
 values(o.application_id,o.id,trim(p_name),lower(trim(p_email)),true,p_notes)
 on conflict(application_id) do update set
 offer_id=excluded.offer_id,accepted_by_name=excluded.accepted_by_name,
 accepted_by_email=excluded.accepted_by_email,terms_accepted=true,notes=excluded.notes,
 accepted_at=now();

 update public.schoolpro_admission_offers set status='accepted',accepted_at=now() where id=o.id;
 update public.schoolpro_admissions set accepted_at=now(),status='accepted' where id=o.application_id;
 return jsonb_build_object('accepted',true,'offer_number',o.offer_number);
end $function$

```

## `public.activate_schoolpro_demo(p_request uuid, p_school uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.activate_schoolpro_demo(p_request uuid, p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ begin raise exception 'Use calendar-reviewed term demo approval';end $function$

```

## `public.activate_schoolpro_demo(p_school uuid, p_tier text, p_days integer, p_reason text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.activate_schoolpro_demo(p_school uuid, p_tier text, p_days integer, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare d public.schoolpro_demo_requests%rowtype; finish timestamptz; result jsonb;begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) or not coalesce(private.has_product_access('schoolpro','approve'),false) then raise exception 'Authorized school administrator required';end if;
 if length(trim(coalesce(p_reason,'')))<3 then raise exception 'Calendar review reason required';end if;
 perform 1 from public.schoolpro_schools where id=p_school for update;if not found then raise exception 'School unavailable';end if;
 if exists(select 1 from public.schoolpro_demo_requests where school_id=p_school and activated_at is not null) then raise exception 'This school has already used its demo';end if;
 if exists(select 1 from public.schoolpro_subscriptions where school_id=p_school and status='active' and amount>0 and renews_at>now()) then raise exception 'Paid subscription cannot be replaced by a demo';end if;
 select * into d from public.schoolpro_demo_requests where school_id=p_school and status='new' order by created_at desc limit 1 for update;
 if d.id is null or d.term_start is null or d.term_end is null or d.exam_start is null or d.exam_end is null or d.term_end<(d.term_start+interval '3 months')::date or d.exam_start<d.term_start or d.exam_end<d.exam_start or d.exam_end>d.term_end or d.calendar_path is null or d.letter_path is null then raise exception 'A complete term calendar and request letter are required';end if;
 if not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=d.calendar_path and split_part(name,'/',1)=d.user_id::text) or not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=d.letter_path and split_part(name,'/',1)=d.user_id::text) then raise exception 'Review documents unavailable';end if;
 finish:=greatest((d.term_end+1)::timestamp at time zone 'Africa/Lagos',(d.exam_end+15)::timestamp at time zone 'Africa/Lagos');
 if finish<=now() then raise exception 'Submitted demo term has ended';end if;
 result:=public.control_center_activate_schoolpro(p_school,p_tier,p_reason);
 update public.schoolpro_subscriptions set amount=0,billing_cycle='termly',starts_at=d.term_start::timestamp at time zone 'Africa/Lagos',renews_at=finish,updated_at=now() where school_id=p_school;
 update public.schoolpro_onboarding_requests set status='active',updated_at=now() where school_id=p_school;
 update public.schoolpro_demo_requests set status='completed',activated_at=now(),free_access_ends_at=finish,reviewed_by=auth.uid(),reviewed_at=now(),review_reason=trim(p_reason),updated_at=now() where id=d.id;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata) values(auth.uid(),'schoolpro_calendar_demo_approved','schoolpro','schoolpro_school',p_school::text,jsonb_build_object('demo_request_id',d.id,'term_end',d.term_end,'exam_end',d.exam_end,'access_ends_at',finish,'payment_recorded',false));
 return result||jsonb_build_object('source','calendar_demo','renews_at',finish);end $function$

```

## `public.adjust_schoolpro_inventory(p_asset uuid, p_delta integer, p_condition text, p_location text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.adjust_schoolpro_inventory(p_asset uuid, p_delta integer, p_condition text DEFAULT NULL::text, p_location text DEFAULT NULL::text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare a schoolpro_inventory_assets%rowtype; q int; begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_inventory_assets where id=p_asset),'inventory') then raise exception 'Module permission denied: inventory'; end if;  select * into a from schoolpro_inventory_assets where id=p_asset for update; if a.id is null then raise exception 'Asset not found'; end if; if not schoolpro_member_can_manage(a.school_id) then raise exception 'Not authorized'; end if; q:=a.quantity+p_delta; if q<0 then raise exception 'Inventory cannot become negative'; end if; update schoolpro_inventory_assets set quantity=q,condition=coalesce(p_condition,condition),location=coalesce(p_location,location) where id=p_asset; return q; end $function$

```

## `public.admit_schoolpro_applicant(p_application uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.admit_schoolpro_applicant(p_application uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_admissions;sid uuid;adm text;v_class uuid;v_count int;
begin
 select * into a from public.schoolpro_admissions where id=p_application for update;
 if a.id is null then raise exception 'Application not found';end if;
 if not private.schoolpro_module_allowed(a.school_id,'admissions') then raise exception 'Module permission denied: admissions'; end if;
 if a.admitted_student_id is not null then
   if not exists(select 1 from public.schoolpro_students s where s.id=a.admitted_student_id and s.school_id=a.school_id)
     then raise exception 'Existing admitted student is not valid for this school'; end if;
   return a.admitted_student_id;
 end if;
 adm:=coalesce(nullif(trim(a.application_number),''),'ADM-'||upper(substr(replace(a.id::text,'-',''),1,8)));
 if nullif(trim(a.class_applied),'') is not null then
   select count(*),min(c.id) into v_count,v_class from public.schoolpro_classes c
   where c.school_id=a.school_id and (
    lower(trim(c.name))=lower(trim(a.class_applied)) or
    lower(trim(c.name||case when nullif(trim(c.arm),'') is null then '' else ' '||trim(c.arm) end))=lower(trim(a.class_applied))
   );
   if v_count<>1 then v_class:=null; end if;
 end if;
 insert into public.schoolpro_students(
  school_id,admission_number,first_name,last_name,class_name,class_id,gender,
  date_of_birth,guardian_name,guardian_phone,guardian_email,status
 ) values(
  a.school_id,adm,
  coalesce(nullif(trim(a.first_name),''),nullif(split_part(trim(a.applicant_name),' ',1),''),'Student'),
  coalesce(nullif(trim(a.last_name),''),'Student'),
  coalesce(nullif(trim(a.class_applied),''),'Unassigned'),v_class,a.gender,
  a.date_of_birth,a.guardian_name,a.guardian_contact,
  nullif(lower(trim(coalesce(a.guardian_email,''))),''),
  'active'
 ) returning id into sid;
 update public.schoolpro_admissions
 set status='admitted',reviewed_by=auth.uid(),reviewed_at=now(),admitted_student_id=sid
 where id=a.id;
 return sid;
end $function$

```

## `public.allocate_schoolpro_hostel(p_room uuid, p_student uuid, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.allocate_schoolpro_hostel(p_room uuid, p_student uuid, p_session text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ declare r schoolpro_hostel_rooms%rowtype; aid uuid; begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_hostel_rooms where id=p_room),'hostel') then raise exception 'Module permission denied: hostel'; end if;  select * into r from schoolpro_hostel_rooms where id=p_room for update; if r.id is null then raise exception 'Room not found'; end if; if not schoolpro_member_can_manage(r.school_id) then raise exception 'Not authorized'; end if; if r.occupied>=r.capacity then raise exception 'Room is full'; end if; if not exists(select 1 from schoolpro_students where id=p_student and school_id=r.school_id) then raise exception 'Student is outside this school'; end if; update schoolpro_hostel_allocations set active=false where school_id=r.school_id and student_id=p_student and active=true; insert into schoolpro_hostel_allocations(school_id,student_id,room_id,session,active) values(r.school_id,p_student,p_room,p_session,true) returning id into aid; update schoolpro_hostel_rooms set occupied=(select count(*) from schoolpro_hostel_allocations where room_id=p_room and active=true) where id=p_room; return aid; end $function$

```

## `public.apply_schoolpro_promotion(p_promotion uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.apply_schoolpro_promotion(p_promotion uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare p public.schoolpro_promotions;c public.schoolpro_classes;s public.schoolpro_students;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into p from public.schoolpro_promotions where id=p_promotion for update;
 if p.id is null then raise exception 'Progression not found';end if;
 if not private.schoolpro_module_allowed(p.school_id,'promotions') then raise exception 'Module permission denied';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(p.school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role,'registrar'::public.school_member_role])) then raise exception 'Not authorized';end if;
 if p.status='applied' then return;end if;
 if p.status<>'pending' then raise exception 'Progression is not pending';end if;
 select * into s from public.schoolpro_students where id=p.student_id and school_id=p.school_id for update;
 if s.id is null then raise exception 'Student not found';end if;
 if s.status<>'active' then raise exception 'Only active students can receive progression decisions';end if;
 if s.class_id is distinct from p.from_class_id then raise exception 'Student class changed after progression decision; create a new decision';end if;
 if p.decision in('promoted','repeated') then
  select * into c from public.schoolpro_classes where id=p.to_class_id and school_id=p.school_id;
  if c.id is null then raise exception 'Destination class invalid';end if;
  update public.schoolpro_students set class_id=c.id,class_name=concat_ws(' ',c.name,nullif(c.arm,'')),status='active' where id=s.id;
 elsif p.decision='graduated' then
  update public.schoolpro_students set status='graduated' where id=s.id;
 end if;
 update public.schoolpro_promotions set status='applied',applied_by=auth.uid(),applied_at=now() where id=p.id;
end $function$

```

## `public.assign_schoolpro_entrance_cbt(p_application uuid, p_test uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.assign_schoolpro_entrance_cbt(p_application uuid, p_test uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare a public.schoolpro_admissions;t public.schoolpro_cbt_tests;att public.schoolpro_candidate_cbt_attempts;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_admissions where id=p_application),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into a from public.schoolpro_admissions where id=p_application;select * into t from public.schoolpro_cbt_tests where id=p_test and school_id=a.school_id;if not private.schoolpro_plan_feature_allowed(t.school_id,'cbt') then raise exception 'Online examinations are not available on this school subscription'; end if; if a.id is null or t.id is null then raise exception 'Application or test not found';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','admissions_officer','registrar','exam_officer')) then raise exception 'Not authorized';end if;insert into public.schoolpro_candidate_cbt_attempts(application_id,test_id,duration_minutes,expires_at,status) values(a.id,t.id,t.duration_minutes,coalesce(t.closes_at,now()+interval '14 days'),'pending') on conflict(application_id,test_id) do update set expires_at=excluded.expires_at,duration_minutes=excluded.duration_minutes returning * into att;update public.schoolpro_admissions set entrance_test_id=t.id,status='exam_scheduled' where id=a.id;if a.guardian_email is not null then perform public.queue_schoolpro_email(a.school_id,a.guardian_email,a.guardian_name,'entrance_exam_invitation','Entrance examination invitation',jsonb_build_object('applicant_name',a.applicant_name,'test_title',t.title,'cbt_token',att.access_token,'expires_at',att.expires_at));end if;return jsonb_build_object('attempt_id',att.id,'token',att.access_token,'expires_at',att.expires_at);end$function$

```

## `public.assign_schoolpro_transport(p_route uuid, p_student uuid, p_pickup text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.assign_schoolpro_transport(p_route uuid, p_student uuid, p_pickup text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare v_session text;begin
select session into v_session from public.schoolpro_result_term_settings t join public.schoolpro_transport_routes r on r.school_id=t.school_id where r.id=p_route and t.term_start_date<=current_date and t.term_end_date>=current_date limit 1;
return public.assign_schoolpro_transport(p_route,p_student,p_pickup,v_session);
end $function$

```

## `public.assign_schoolpro_transport(p_route uuid, p_student uuid, p_pickup text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.borrow_schoolpro_library_book(p_book uuid, p_student uuid, p_member uuid, p_due timestamp with time zone)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.borrow_schoolpro_library_book(p_book uuid, p_student uuid DEFAULT NULL::uuid, p_member uuid DEFAULT NULL::uuid, p_due timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare b public.schoolpro_library_books;lid uuid;
begin
 if not private.schoolpro_module_allowed((select school_id from public.schoolpro_library_books where id=p_book),'library') then raise exception 'Module permission denied: library';end if;
 select * into b from public.schoolpro_library_books where id=p_book for update;
 if b.id is null then raise exception 'Book not found';end if;
 if not(public.schoolpro_member_can_manage(b.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=b.school_id and m.user_id=auth.uid() and m.role::text='librarian')) then raise exception 'Not authorized';end if;
 if b.available_copies<=0 then raise exception 'No available copy';end if;
 if (p_student is null)=(p_member is null) then raise exception 'Choose exactly one borrower';end if;
 if p_student is not null and not exists(select 1 from public.schoolpro_students s where s.id=p_student and s.school_id=b.school_id and s.status='active') then raise exception 'Student borrower does not belong to this school or is inactive';end if;
 if p_member is not null and not exists(select 1 from public.schoolpro_members m where m.id=p_member and m.school_id=b.school_id) then raise exception 'Member borrower does not belong to this school';end if;
 insert into public.schoolpro_library_loans(school_id,book_id,student_id,member_id,due_at,status)
 values(b.school_id,b.id,p_student,p_member,coalesce(p_due,now()+interval '14 days'),'borrowed') returning id into lid;
 update public.schoolpro_library_books set available_copies=available_copies-1 where id=b.id;
 return lid;
end $function$

```

## `public.borrow_schoolpro_library_book(p_book uuid, p_student uuid, p_member uuid, p_due timestamp with time zone, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.check_schoolpro_result_pin(p_admission text, p_term text, p_session text, p_pin text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.check_schoolpro_result_pin(p_admission text, p_term text, p_session text, p_pin text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s record;pinrow record;blocked boolean;held boolean;outstanding numeric;payload jsonb;
begin
 select st.id,st.school_id,st.first_name,st.last_name,st.admission_number,st.class_name,sc.name school_name,sc.address into s from public.schoolpro_students st join public.schoolpro_schools sc on sc.id=st.school_id where upper(st.admission_number)=upper(trim(p_admission)) and st.status='active' order by st.created_at desc limit 1;
 if s.id is null then return jsonb_build_object('ok',false,'message','Result details or access PIN are invalid.');end if;
 select * into pinrow from public.schoolpro_result_access_pins p where p.student_id=s.id and p.term=p_term and p.session=p_session and p.is_active and (p.expires_at is null or p.expires_at>now()) and p.pin_hash=encode(digest(upper(trim(p_pin)),'sha256'),'hex') limit 1;
 if pinrow.id is null then return jsonb_build_object('ok',false,'message','Result details or access PIN are invalid.');end if;
 select coalesce(fs.block_results_when_owing,false) and coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0)>coalesce(fs.allowed_outstanding,0),coalesce(bool_or(i.result_hold),false),coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0)
 into blocked,held,outstanding from public.schoolpro_finance_settings fs left join public.schoolpro_invoices i on i.school_id=s.school_id and i.student_id=s.id and i.term=p_term and i.session=p_session and i.status<>'waived' where fs.school_id=s.school_id group by fs.block_results_when_owing,fs.allowed_outstanding;
 if coalesce(held,false) then return jsonb_build_object('ok',false,'message','Result access is currently on hold.');end if;
 if coalesce(blocked,false) then return jsonb_build_object('ok',false,'message','Result access is paused by the school because of an outstanding fee balance.','outstanding',coalesce(outstanding,0));end if;
 select coalesce(jsonb_agg(jsonb_build_object('subject',sub.name,'total_score',r.total_score,'assessment_scores',r.assessment_scores,'status',r.status) order by sub.name),'[]'::jsonb) into payload from public.schoolpro_results r join public.schoolpro_subjects sub on sub.id=r.subject_id where r.student_id=s.id and r.term=p_term and r.session=p_session and r.status='published';
 if jsonb_array_length(payload)=0 then return jsonb_build_object('ok',false,'message','No published result is available for this term and session.');end if;
 update public.schoolpro_result_access_pins set last_used_at=now() where id=pinrow.id;
 return jsonb_build_object('ok',true,'school',jsonb_build_object('name',s.school_name,'address',s.address),'student',jsonb_build_object('name',s.first_name||' '||s.last_name,'admission_number',s.admission_number,'class_name',s.class_name),'term',p_term,'session',p_session,'results',payload);
end $function$

```

## `public.claim_schoolpro_onboarding()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.claim_schoolpro_onboarding()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare verified_email text;n integer;begin
 if auth.uid() is null or not private.schoolpro_can_register() then return 0;end if;
 select lower(email) into verified_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
 if verified_email is null then return 0;end if;
 update public.schoolpro_onboarding_requests set user_id=auth.uid(),updated_at=now()
 where user_id is null and school_id is null and status in('submitted','reviewing','approved') and lower(trim(email))=verified_email;
 get diagnostics n=row_count;return n;
end;$function$

```

## `public.control_center_activate_schoolpro(p_school uuid, p_tier text, p_reason text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.control_center_activate_schoolpro(p_school uuid, p_tier text DEFAULT 'starter'::text, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r timestamptz;
begin
 if auth.uid() is null or not coalesce(private.has_product_access('schoolpro','approve'),false) then raise exception 'SchoolPro approval access required'; end if;
 if length(trim(coalesce(p_reason,'')))<3 then raise exception 'Activation reason is required'; end if;
 perform 1 from public.schoolpro_schools where id=p_school for update;
 if not found then raise exception 'School not found'; end if;
 if not exists(select 1 from public.schoolpro_subscription_catalog where code=p_tier and active=true) then raise exception 'Active SchoolPro plan not found'; end if;
 r:=now()+interval '1 year';
 insert into public.schoolpro_subscriptions(school_id,tier,billing_cycle,amount,status,starts_at,renews_at,managed_by_ihlink,updated_at)
 values(p_school,p_tier,'annual',0,'active',now(),r,true,now())
 on conflict(school_id) do update set tier=excluded.tier,billing_cycle='annual',status='active',starts_at=now(),renews_at=r,managed_by_ihlink=true,updated_at=now();
 update public.schoolpro_schools set status='active',plan=p_tier,updated_at=now() where id=p_school;
 insert into public.audit_logs(actor_id,action,target_type,target_id,metadata)
 values(auth.uid(),'schoolpro_control_center_activation','schoolpro_school',p_school::text,jsonb_build_object('tier',p_tier,'reason',trim(p_reason),'commercial_override',true));
 return jsonb_build_object('status','active','school_id',p_school,'tier',p_tier,'renews_at',r,'source','control_center');
end $function$

```

## `public.create_schoolpro_fee_bundle(p_school uuid, p_name text, p_classes text[], p_term text, p_session text, p_due date, p_items jsonb)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.create_schoolpro_fee_bundle(p_school uuid, p_name text, p_classes text[], p_term text, p_session text, p_due date, p_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare item jsonb; target text; fee_id uuid; amount numeric; total numeric:=0; ids jsonb:='[]'::jsonb;
begin
 if auth.uid() is null or not coalesce(private.schoolpro_module_allowed(p_school,'finance'),false) or not coalesce(private.has_school_access(p_school,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]),false) then raise exception 'School finance permission required';end if;
 if nullif(trim(p_name),'') is null or length(p_name)>200 or nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items) not between 1 and 100 then raise exception 'Enter a fee name, academic period and at least one charge';end if;
 for item in select value from jsonb_array_elements(p_items) loop
  amount:=(item->>'amount')::numeric;
  if nullif(trim(item->>'label'),'') is null or length(item->>'label')>200 or amount is null or amount<0 or amount<>round(amount,2) or amount::text in ('NaN','Infinity','-Infinity') then raise exception 'Every charge needs a name and a valid amount';end if;
  total:=total+amount;
 end loop;
 if p_classes is not null and cardinality(p_classes)=0 then raise exception 'Select a class in this section';end if;
 foreach target in array coalesce(p_classes,array[null::text]) loop
  if target is not null and not exists(select 1 from public.schoolpro_classes where school_id=p_school and concat_ws(' ',name,nullif(arm,''))=target) then raise exception 'Choose a class in this school';end if;
  insert into public.schoolpro_fee_structures(school_id,name,class_name,term,session,amount,due_date,created_by) values(p_school,trim(p_name),target,trim(p_term),trim(p_session),total,p_due,auth.uid()) returning id into fee_id;
  insert into public.schoolpro_fee_items(fee_structure_id,label,amount,category,sort_order)
  select fee_id,trim(value->>'label'),(value->>'amount')::numeric,case when value->>'category' in ('fee','levy','books','transport','hostel','uniform','other') then value->>'category' else 'other' end,ordinality::integer-1 from jsonb_array_elements(p_items) with ordinality;
  ids:=ids||jsonb_build_array(fee_id);
 end loop;
 return jsonb_build_object('structures',ids,'total',total);
end $function$

```

## `public.create_schoolpro_portal_invite(p_student uuid, p_email text, p_type text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.create_schoolpro_portal_invite(p_student uuid, p_email text, p_type text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare st public.schoolpro_students; iid uuid;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_students where id=p_student),'students') then raise exception 'Module permission denied: students'; end if;  select * into st from public.schoolpro_students where id=p_student;if st.id is null then raise exception 'Student not found';end if;if p_type not in('student','parent') then raise exception 'Invalid invite type';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=st.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','registrar','admissions_officer')) and not exists(select 1 from public.schoolpro_schools s where s.id=st.school_id and s.owner_id=auth.uid()) then raise exception 'Not authorized';end if;insert into public.schoolpro_portal_invites(school_id,student_id,email,invite_type) values(st.school_id,st.id,lower(trim(p_email)),p_type) returning id into iid;perform public.queue_schoolpro_email(st.school_id,p_email,st.first_name||' '||st.last_name,'portal_invitation','Your SchoolPro portal invitation',jsonb_build_object('student_id',st.id,'invite_type',p_type));return iid;end$function$

```

## `public.create_schoolpro_progression(p_student uuid, p_session text, p_decision text, p_to_class uuid, p_reason text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.create_schoolpro_progression(p_student uuid, p_session text, p_decision text, p_to_class uuid DEFAULT NULL::uuid, p_reason text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_students;c public.schoolpro_classes;v_id uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into s from public.schoolpro_students where id=p_student for share;
 if s.id is null then raise exception 'Student not found';end if;
 if not private.schoolpro_module_allowed(s.school_id,'promotions') then raise exception 'Module permission denied';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(s.school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role,'registrar'::public.school_member_role])) then raise exception 'Not authorized';end if;
 if trim(coalesce(p_session,''))='' or p_decision not in('promoted','repeated','graduated') then raise exception 'Invalid progression decision';end if;
 if s.class_id is null then raise exception 'Student must be assigned to a class';end if;
 if p_decision='promoted' then
  if p_to_class is null then raise exception 'Destination class required';end if;
  select * into c from public.schoolpro_classes where id=p_to_class and school_id=s.school_id;
  if c.id is null or c.id=s.class_id then raise exception 'Invalid destination class';end if;
 elsif p_decision='repeated' then p_to_class:=s.class_id;
 else p_to_class:=null;
 end if;
 insert into public.schoolpro_promotions(school_id,student_id,from_class_id,to_class_id,from_class,to_class,session,status,decision,decided_by,reason)
 select s.school_id,s.id,s.class_id,p_to_class,concat_ws(' ',fc.name,nullif(fc.arm,'')),case when p_to_class is null then null else (select concat_ws(' ',name,nullif(arm,'')) from public.schoolpro_classes where id=p_to_class) end,trim(p_session),'pending',p_decision,auth.uid(),nullif(trim(coalesce(p_reason,'')),'') from public.schoolpro_classes fc where fc.id=s.class_id
 returning id into v_id;
 return v_id;
end $function$

```

## `public.create_schoolpro_result_pin(target_student uuid, target_term text, target_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.create_schoolpro_workspace(p_request uuid, p_tier text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.create_schoolpro_workspace(p_request uuid, p_tier text DEFAULT 'starter'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.schoolpro_onboarding_requests;c public.schoolpro_subscription_catalog;i public.schoolpro_subscription_intents;sid uuid;owner_email text;begin
 if auth.uid() is null or not private.is_active_account() then raise exception 'Active account required';end if;
 select * into r from public.schoolpro_onboarding_requests where id=p_request for update;
 if r.id is null or r.user_id is null then raise exception 'Verified school owner required';end if;
 if auth.uid()<>r.user_id and not coalesce(private.has_product_access('schoolpro','approve'),false) then raise exception 'School owner or authorized administrator required';end if;
 if r.status not in('approved','provisioning') then raise exception 'School request approval required';end if;
 select email into owner_email from auth.users where id=r.user_id and email_confirmed_at is not null;
 if owner_email is null or not exists(select 1 from public.profiles where id=r.user_id and status='active') then raise exception 'Owner must verify their account first';end if;
 if not exists(select 1 from public.profiles where id=r.user_id and role='super_admin') and (exists(select 1 from public.schoolpro_members where user_id=r.user_id and role<>'proprietor') or exists(select 1 from public.schoolpro_students where user_id=r.user_id) or exists(select 1 from public.schoolpro_guardian_links where guardian_user_id=r.user_id and status='active')) then raise exception 'Invited accounts cannot create an owner workspace';end if;
 select * into c from public.schoolpro_subscription_catalog where code=p_tier and active and annual_price>0;
 if c.id is null then raise exception 'Published school plan required';end if;
 sid:=r.school_id;
 if sid is null then
  insert into public.schoolpro_schools(owner_id,name,code,plan,status) values(r.user_id,trim(r.school_name),'SP-'||upper(left(replace(r.id::text,'-',''),12)),'trial','trial') returning id into sid;
  insert into public.schoolpro_members(school_id,user_id,role) values(sid,r.user_id,'proprietor') on conflict(school_id,user_id) do nothing;
 elsif not exists(select 1 from public.schoolpro_schools where id=sid and owner_id=r.user_id) then raise exception 'Workspace owner mismatch';end if;
 select * into i from public.schoolpro_subscription_intents where school_id=sid and status='pending' order by created_at limit 1 for update;
 if i.id is null then
  insert into public.schoolpro_subscription_intents(school_id,payer_user_id,catalog_id,billing_cycle,amount,reference,status,payment_method) values(sid,r.user_id,c.id,'annual',c.annual_price,'SCHSUB-'||upper(replace(gen_random_uuid()::text,'-','')),'pending','bank_transfer') returning * into i;
  insert into public.schoolpro_email_queue(school_id,recipient_email,recipient_name,template_key,subject,payload) values(sid,owner_email,r.contact_name,'workspace_subscription_invoice','Your SchoolPro workspace and subscription invoice',jsonb_build_object('message','Your school workspace is ready for setup. Invoice '||i.reference||' is for the '||c.name||' annual subscription, NGN '||i.amount||'. Sign in to view the invoice, receiving bank accounts and submit payment proof: https://ihlink-schoolpro.onrender.com/schoolpro/subscription?school_id='||sid::text,'invoice_id',i.id,'action_url','https://ihlink-schoolpro.onrender.com/schoolpro/subscription?school_id='||sid::text));
 elsif i.catalog_id<>c.id then raise exception 'Existing invoice must be reviewed before changing plan';end if;
 update public.schoolpro_onboarding_requests set school_id=sid,status='provisioning',updated_at=now() where id=r.id;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata) values(auth.uid(),'schoolpro_workspace_invoice_created','schoolpro','schoolpro_onboarding_request',r.id::text,jsonb_build_object('school_id',sid,'invoice_id',i.id,'activation',false));
 return jsonb_build_object('school_id',sid,'invoice_id',i.id,'reference',i.reference,'amount',i.amount,'status','pending','owner_email',owner_email);
end $function$

```

## `public.delete_schoolpro_draft_result(p_result uuid, p_reason text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.delete_schoolpro_draft_result(p_result uuid, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.schoolpro_results;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into r from public.schoolpro_results where id=p_result for update;
 if r.id is null then raise exception 'Result not found';end if;
 if r.status<>'draft' or r.locked then raise exception 'Only unlocked draft results can be deleted';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(r.school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'exam_officer'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role]) or private.schoolpro_can_write_result(r.school_id,r.student_id,r.subject_id,r.session)) then raise exception 'Not authorized';end if;
 delete from public.schoolpro_results where id=r.id;
end $function$

```

## `public.edit_schoolpro_fee_bundle(p_structure uuid, p_name text, p_due date, p_items jsonb)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.edit_schoolpro_fee_bundle(p_structure uuid, p_name text, p_due date, p_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare f public.schoolpro_fee_structures; item jsonb; amount numeric; total numeric:=0;
begin
 select * into f from public.schoolpro_fee_structures where id=p_structure for update;
 if f.id is null or auth.uid() is null or not coalesce(private.schoolpro_module_allowed(f.school_id,'finance'),false) or not coalesce(private.has_school_access(f.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]),false) then raise exception 'School finance permission required';end if;
 if nullif(trim(p_name),'') is null or length(p_name)>200 or jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) not between 1 and 100 then raise exception 'Enter a fee name and at least one charge';end if;
 for item in select value from jsonb_array_elements(p_items) loop
  amount:=(item->>'amount')::numeric;
  if nullif(trim(item->>'label'),'') is null or length(item->>'label')>200 or amount is null or amount<0 or amount<>round(amount,2) or amount::text in ('NaN','Infinity','-Infinity') then raise exception 'Every charge needs a name and a valid amount';end if;
  if not coalesce((item->>'is_optional')::boolean,false) then total:=total+amount;end if;
 end loop;
 if exists(select 1 from public.schoolpro_invoices i where i.fee_structure_id=f.id and i.amount_paid=0 and (exists(select 1 from public.schoolpro_payment_intents p where p.invoice_id=i.id and p.status='pending') or exists(select 1 from public.schoolpro_payment_allocations a join public.schoolpro_payment_submissions s on s.id=a.submission_id where a.invoice_id=i.id and s.status='pending'))) then raise exception 'Review pending payments before changing this fee';end if;
 delete from public.schoolpro_fee_items where fee_structure_id=f.id;
 insert into public.schoolpro_fee_items(fee_structure_id,label,amount,category,is_optional,sort_order)
 select f.id,trim(value->>'label'),(value->>'amount')::numeric,case when value->>'category' in ('fee','levy','books','transport','hostel','uniform','other') then value->>'category' else 'other' end,coalesce((value->>'is_optional')::boolean,false),ordinality::integer-1 from jsonb_array_elements(p_items) with ordinality;
 update public.schoolpro_fee_structures set name=trim(p_name),amount=total,due_date=p_due,updated_at=now() where id=f.id;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata) values(auth.uid(),'School fee charges edited','schoolpro','fee_structure',f.id::text,jsonb_build_object('school_id',f.school_id,'previous_total',f.amount,'new_total',total));
 return jsonb_build_object('id',f.id,'total',total);
end $function$

```

## `public.edit_schoolpro_fee_invoice(p_invoice uuid, p_title text, p_amount numeric, p_due date, p_notes text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.edit_schoolpro_fee_invoice(p_invoice uuid, p_title text, p_amount numeric, p_due date, p_notes text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare inv public.schoolpro_invoices;
begin
 select * into inv from public.schoolpro_invoices where id=p_invoice for update;
 if auth.uid() is null or inv.id is null or not coalesce(private.schoolpro_module_allowed(inv.school_id,'finance'),false) or not coalesce(private.has_school_access(inv.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]),false) then raise exception 'School finance permission required';end if;
 if inv.status<>'unpaid' or inv.amount_paid<>0 then raise exception 'Only unpaid invoices without recorded payments can be edited';end if;
 if nullif(trim(p_title),'') is null or length(p_title)>200 or p_amount is null or p_amount<0 or p_amount<>round(p_amount,2) or p_amount::text in ('NaN','Infinity','-Infinity') then raise exception 'Enter an invoice title and a valid amount with up to two decimal places';end if;
 if exists(select 1 from public.schoolpro_payment_intents where invoice_id=inv.id and status='pending') or exists(select 1 from public.schoolpro_payment_allocations a join public.schoolpro_payment_submissions s on s.id=a.submission_id where a.invoice_id=inv.id and s.status='pending') then raise exception 'Review the pending payment before changing this invoice';end if;
 update public.schoolpro_invoices set title=trim(p_title),amount_due=p_amount,gross_amount=p_amount+coalesce(discount,0)+coalesce(scholarship,0)+coalesce(waiver_amount,0),due_date=p_due,notes=left(p_notes,2000),updated_at=now() where id=inv.id;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata) values(auth.uid(),'School fee invoice edited','schoolpro','invoice',inv.id::text,jsonb_build_object('school_id',inv.school_id,'previous_amount',inv.amount_due,'new_amount',p_amount,'previous_title',inv.title,'new_title',trim(p_title)));
 return inv.id;
end $function$

```

## `public.enforce_schoolpro_result_lock()`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.enforce_schoolpro_result_lock()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$ begin if old.locked=true and new.locked=true and (to_jsonb(new)-'locked'-'updated_at') is distinct from (to_jsonb(old)-'locked'-'updated_at') then raise exception 'Result is locked'; end if; return new; end $function$

```

## `public.ensure_schoolpro_default_assessment_scheme(p_school uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.ensure_schoolpro_default_assessment_scheme(p_school uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare sid uuid;begin if not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied: results'; end if;  if not public.schoolpro_member_can_manage(p_school) then raise exception 'Not authorized';end if;select id into sid from public.schoolpro_assessment_schemes where school_id=p_school and is_default=true limit 1;if sid is null then insert into public.schoolpro_assessment_schemes(school_id,name,school_level,components,is_default) values(p_school,'Standard 40/60','All',jsonb_build_array(jsonb_build_object('key','ca1_assignment','label','1st CA Assignment','max',10),jsonb_build_object('key','ca2_assignment','label','2nd CA Assignment','max',10),jsonb_build_object('key','ca1_test','label','1st CA Test','max',10),jsonb_build_object('key','ca2_test','label','2nd CA Test','max',10),jsonb_build_object('key','exam','label','Exam','max',60)),true) returning id into sid;end if;return sid;end$function$

```

## `public.ensure_schoolpro_standard_assessment_schemes(p_school uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.finalize_schoolpro_billstack_transfer(p_intent uuid, p_transaction_ref text, p_verified_amount numeric, p_payload jsonb)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.finalize_schoolpro_billstack_transfer(p_intent uuid, p_transaction_ref text, p_verified_amount numeric, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 i public.schoolpro_payment_intents%rowtype;
 inv public.schoolpro_invoices%rowtype;
 tx public.payment_transactions%rowtype;
 existing uuid; receipt uuid; new_paid numeric;
begin
 if p_verified_amount is null or p_verified_amount<=0 or p_verified_amount<>round(p_verified_amount,2)
    or nullif(btrim(p_transaction_ref),'') is null then
   raise exception 'Verified exact payment required';
 end if;

 select * into i from public.schoolpro_payment_intents where id=p_intent for update;
 if i.id is null then raise exception 'Payment intent not found'; end if;
 if i.gateway<>'billstack' then raise exception 'Payment intent provider mismatch'; end if;
 if i.status='successful' then
   if i.gateway_transaction_id=p_transaction_ref and i.amount=p_verified_amount then
     return jsonb_build_object('status','already_credited','reference',i.reference);
   end if;
   raise exception 'Payment intent already settled by another transaction';
 end if;
 if i.status<>'pending' then raise exception 'Payment intent is not payable'; end if;
 if p_verified_amount<>i.amount then raise exception 'Verified amount does not match invoice payment intent'; end if;

 select * into tx from public.payment_transactions
 where provider='billstack' and transaction_ref=p_transaction_ref for update;
 if tx.id is null
    or tx.status not in('verified','credited')
    or tx.is_settled is distinct from true
    or tx.verified_at is null
    or tx.credited_at is not null
    or tx.amount<>p_verified_amount
    or tx.currency<>'NGN'
    or tx.user_id is distinct from i.payer_user_id
    or tx.platform_code is distinct from 'schoolpro'
    or tx.virtual_account_id is distinct from i.virtual_account_id then
   raise exception 'Verified transaction ownership, platform or replay validation failed';
 end if;

 select id into existing from public.schoolpro_fee_payments where reference=p_transaction_ref limit 1;
 if existing is not null then raise exception 'Transaction already applied'; end if;

 select * into inv from public.schoolpro_invoices where id=i.invoice_id for update;
 if inv.id is null or inv.school_id<>i.school_id or inv.student_id<>i.student_id then
   raise exception 'Invoice mapping mismatch';
 end if;
 if inv.status in ('paid','waived') or inv.amount_paid+i.amount>inv.amount_due then
   raise exception 'Invoice is no longer payable';
 end if;

 insert into public.schoolpro_fee_payments(
   school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by
 ) values(
   i.school_id,i.invoice_id,i.student_id,i.amount,'transfer',p_transaction_ref,
   'Verified BillStack bank transfer',i.payer_user_id
 ) returning id into receipt;

 new_paid:=inv.amount_paid+i.amount;
 update public.schoolpro_invoices
 set amount_paid=new_paid,
     status=case when new_paid>=amount_due then 'paid'::public.schoolpro_invoice_status
                 else 'part_paid'::public.schoolpro_invoice_status end,
     updated_at=now()
 where id=inv.id;

 update public.schoolpro_payment_intents
 set status='successful',gateway_transaction_id=p_transaction_ref,
     gateway_payload=coalesce(p_payload,'{}'::jsonb),credited_at=now(),updated_at=now()
 where id=i.id;

 update public.payment_transactions
 set status='credited',credited_at=now(),updated_at=now()
 where id=tx.id;

 return jsonb_build_object('status','credited','reference',i.reference,'receipt_id',receipt,'amount',i.amount);
end
$function$

```

## `public.finalize_schoolpro_document_issue(p_issue uuid, p_output_path text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.finalize_schoolpro_document_issue(p_issue uuid, p_output_path text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare i public.schoolpro_document_issues;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into i from public.schoolpro_document_issues where id=p_issue for update;
 if i.id is null then raise exception 'Document not found';end if;
 if i.status<>'draft' then raise exception 'Only draft documents can be issued';end if;
 if trim(coalesce(p_output_path,''))='' or p_output_path not like i.school_id::text||'/%' then raise exception 'Invalid output path';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or public.schoolpro_member_can_manage(i.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=i.school_id and m.user_id=auth.uid() and m.role::text in('registrar','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;
 perform set_config('ihlink.document_lifecycle_rpc','on',true);
 update public.schoolpro_document_issues set status='issued',output_storage_path=p_output_path,issued_at=now(),issued_by=auth.uid() where id=i.id;
 insert into public.schoolpro_document_issue_events(school_id,issue_id,event_type,actor_id,snapshot) select school_id,id,'issued',auth.uid(),to_jsonb(x) from public.schoolpro_document_issues x where id=i.id;
end $function$

```

## `public.finalize_schoolpro_enrollment(p_application uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.finalize_schoolpro_enrollment(p_application uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_admissions;sid uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select * into a from public.schoolpro_admissions where id=p_application for update;
 if a.id is null then raise exception 'Application not found';end if;
 if not private.schoolpro_module_allowed(a.school_id,'admissions') then raise exception 'Module permission denied: admissions'; end if;
 if not(public.schoolpro_member_can_manage(a.school_id) or exists(
  select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid()
  and m.role::text in('registrar','admissions_officer'))) then raise exception 'Not authorized';end if;

 if not exists(
  select 1 from public.schoolpro_admission_offers o
  join public.schoolpro_admission_acceptances x on x.offer_id=o.id and x.application_id=o.application_id
  where o.application_id=a.id and o.status='accepted' and o.accepted_at is not null
  and x.terms_accepted=true
 ) then raise exception 'The current admission offer has not been accepted with terms';end if;

 sid:=public.admit_schoolpro_applicant(a.id);
 update public.schoolpro_admissions set enrollment_status='enrolled',enrolled_at=now() where id=a.id;
 return sid;
end $function$

```

## `public.finalize_schoolpro_payment(p_reference text, p_gateway_transaction_id text, p_verified_amount numeric, p_status text, p_payload jsonb)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.finalize_schoolpro_payment(p_reference text, p_gateway_transaction_id text, p_verified_amount numeric, p_status text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin raise exception 'This service accepts bank transfer and Finance-reviewed payment proof only';end $function$

```

## `public.finalize_schoolpro_subscription(p_intent uuid, p_transaction_ref text, p_amount numeric)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.finalize_schoolpro_subscription(p_intent uuid, p_transaction_ref text, p_amount numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin raise exception 'This service accepts bank transfer and Finance-reviewed payment proof only';end $function$

```

## `public.generate_schoolpro_class_invoices(p_structure uuid, p_class text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.generate_schoolpro_class_invoices(p_structure uuid, p_class text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare school uuid;
begin
 select school_id into school from public.schoolpro_fee_structures where id=p_structure;
 if auth.uid() is null or not coalesce(private.schoolpro_module_allowed(school,'finance'),false)
 or not coalesce(private.has_school_access(school,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]),false)
 then raise exception 'School finance permission required'; end if;
 return private.sync_schoolpro_fee_invoices(p_structure,p_class);
end $function$

```

## `public.get_schoolpro_admission_offer(p_token uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.get_schoolpro_admission_offer(p_token uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare o public.schoolpro_admission_offers;a public.schoolpro_admissions;begin select * into o from public.schoolpro_admission_offers where public_token=p_token;if o.id is null then raise exception 'Invalid admission offer';end if;if o.expires_at is not null and now()>o.expires_at and o.status<>'accepted' then raise exception 'Admission offer expired';end if;select * into a from public.schoolpro_admissions where id=o.application_id;return jsonb_build_object('offer_number',o.offer_number,'offered_class',o.offered_class,'letter_body',o.letter_body,'issued_at',o.issued_at,'expires_at',o.expires_at,'status',o.status,'acceptance_instructions',o.acceptance_instructions,'applicant_name',a.applicant_name,'application_number',a.application_number);end$function$

```

## `public.grade_schoolpro_assignment_submission(p_submission uuid, p_score numeric, p_feedback text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.grade_schoolpro_assignment_submission(p_submission uuid, p_score numeric, p_feedback text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare sub public.schoolpro_assignment_submissions;a public.schoolpro_assignments;begin if auth.uid() is null then raise exception 'Authentication required';end if;select * into sub from public.schoolpro_assignment_submissions where id=p_submission for update;if sub.id is null then raise exception 'Submission not found';end if;select * into a from public.schoolpro_assignments where id=sub.assignment_id;if a.id is null then raise exception 'Assignment not found';end if;if not private.schoolpro_module_allowed(a.school_id,'assignments') then raise exception 'Module permission denied: assignments';end if;if not(private.has_school_access(a.school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role]) or (a.created_by=auth.uid() and private.has_school_access(a.school_id,array['teacher'::public.school_member_role,'class_teacher'::public.school_member_role]))) then raise exception 'Not authorized to grade this assignment';end if;if p_score is null or p_score<0 or p_score>a.max_score then raise exception 'Score must be between 0 and %',a.max_score;end if;update public.schoolpro_assignment_submissions set score=p_score,feedback=nullif(trim(p_feedback),''),status='graded',graded_by=auth.uid(),graded_at=now() where id=sub.id;return jsonb_build_object('submission_id',sub.id,'score',p_score,'max_score',a.max_score,'status','graded');end $function$

```

## `public.import_schoolpro_results(p_school uuid, p_term text, p_session text, p_rows jsonb)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.import_schoolpro_results(p_school uuid, p_term text, p_session text, p_rows jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare x jsonb;st uuid;su uuid;sc uuid;scores jsonb;comp jsonb;maxv numeric;v numeric;n int:=0;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied: results';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Term and session are required';end if;
 if jsonb_typeof(p_rows)<>'array' or jsonb_array_length(p_rows)=0 or jsonb_array_length(p_rows)>500 then raise exception 'Import must contain 1 to 500 rows';end if;
 for x in select value from jsonb_array_elements(p_rows) loop
  select id,class_id into st,sc from public.schoolpro_students where school_id=p_school and admission_number=trim(x->>'admission_number') and status='active';
  if st is null then raise exception 'Unknown active student admission number: %',x->>'admission_number';end if;
  select id into su from public.schoolpro_subjects where school_id=p_school and upper(code)=upper(trim(x->>'subject_code'));
  if su is null then raise exception 'Unknown subject code: %',x->>'subject_code';end if;
  if not private.schoolpro_can_write_result(p_school,st,su,trim(p_session)) then raise exception 'Not authorized for student %, subject %, session %',x->>'admission_number',x->>'subject_code',p_session;end if;
  scores:=coalesce(x->'assessment_scores','{}'::jsonb);
  select components into comp from public.schoolpro_assessment_schemes where id=(x->>'assessment_scheme_id')::uuid and school_id=p_school;
  if comp is null then raise exception 'Invalid assessment scheme';end if;
  for comp in select value from jsonb_array_elements(comp) loop
    v:=coalesce((scores->>(comp->>'key'))::numeric,0);maxv:=(comp->>'maxScore')::numeric;
    if v<0 or v>maxv then raise exception 'Score % exceeds allowed range 0-% for %',v,maxv,comp->>'label';end if;
  end loop;
  if exists(select 1 from public.schoolpro_results where student_id=st and subject_id=su and term=trim(p_term) and session=trim(p_session) and (locked or status<>'draft')) then raise exception 'Existing result is locked or no longer draft for % / %',x->>'admission_number',x->>'subject_code';end if;
  insert into public.schoolpro_results(school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,status,locked)
  values(p_school,st,su,trim(p_term),trim(p_session),(x->>'assessment_scheme_id')::uuid,scores,'draft',false)
  on conflict(student_id,subject_id,term,session) do update set assessment_scheme_id=excluded.assessment_scheme_id,assessment_scores=excluded.assessment_scores,updated_at=now();
  n:=n+1;
 end loop;
 return jsonb_build_object('imported',n);
end $function$

```

## `public.issue_schoolpro_admission_offer(p_application uuid, p_letter text, p_expiry timestamp with time zone, p_instructions text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.issue_schoolpro_admission_offer(p_application uuid, p_letter text, p_expiry timestamp with time zone, p_instructions text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_admissions;o public.schoolpro_admission_offers;v_token uuid:=gen_random_uuid();v_number text:='OFR-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select * into a from public.schoolpro_admissions where id=p_application for update;
 if a.id is null then raise exception 'Application not found';end if;
 if not private.schoolpro_module_allowed(a.school_id,'admissions') then raise exception 'Module permission denied: admissions'; end if;
 if not exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid()
 and m.role::text in('proprietor','administrator','admissions_officer','registrar')) then raise exception 'Not authorized';end if;
 if p_expiry is not null and p_expiry<=now() then raise exception 'Offer expiry must be in the future'; end if;

 insert into public.schoolpro_admission_offers(
 application_id,offer_number,offered_class,letter_body,expires_at,acceptance_instructions,status,public_token,issued_at,accepted_at
 ) values(a.id,v_number,a.class_applied,p_letter,p_expiry,p_instructions,'offered',v_token,now(),null)
 on conflict(application_id) do update set
 offer_number=excluded.offer_number,
 offered_class=excluded.offered_class,
 letter_body=excluded.letter_body,
 expires_at=excluded.expires_at,
 acceptance_instructions=excluded.acceptance_instructions,
 status='offered',
 public_token=excluded.public_token,
 issued_at=now(),
 accepted_at=null
 returning * into o;

 update public.schoolpro_admissions
 set status='admitted',reviewed_at=now(),reviewed_by=auth.uid(),accepted_at=null
 where id=a.id;

 if a.guardian_email is not null then
  perform public.queue_schoolpro_email(a.school_id,a.guardian_email,a.guardian_name,'admission_offer',
   'Admission offer for '||a.applicant_name,
   jsonb_build_object('applicant_name',a.applicant_name,'offer_number',o.offer_number,'offer_token',o.public_token));
 end if;
 return jsonb_build_object('offer_id',o.id,'offer_number',o.offer_number,'token',o.public_token);
end $function$

```

## `public.issue_schoolpro_result_verification(p_student uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.issue_schoolpro_result_verification(p_student uuid, p_term text, p_session text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare st record;snap jsonb;code text;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select s.id,s.school_id into st from public.schoolpro_students s where s.id=p_student and s.status='active';
 if st.id is null then raise exception 'Student not found';end if;
 if not private.schoolpro_module_allowed(st.school_id,'results') then raise exception 'Module permission denied: results';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(st.school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'exam_officer'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role])) then raise exception 'Not authorized';end if;
 select jsonb_build_object('results',jsonb_agg(jsonb_build_object('subject_id',r.subject_id,'total_score',r.total_score,'assessment_scores',r.assessment_scores) order by r.subject_id))
 into snap from public.schoolpro_results r where r.student_id=p_student and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published' and r.locked=true;
 if snap->'results' is null then raise exception 'No locked published result is available';end if;
 code:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,16));
 insert into public.schoolpro_result_verifications(verification_code,school_id,student_id,term,session,snapshot,status,issued_by)
 values(code,st.school_id,p_student,trim(p_term),trim(p_session),snap,'valid',auth.uid());
 return code;
end $function$

```

## `public.link_schoolpro_guardian(target_student uuid, guardian_email text, guardian_relationship text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.link_schoolpro_guardian(target_student uuid, guardian_email text, guardian_relationship text DEFAULT 'guardian'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare s public.schoolpro_students%rowtype; guardian uuid; link_id uuid;
begin
  select * into s from public.schoolpro_students where id=target_student;
  if s.id is null then raise exception 'Student not found'; end if;
  if not private.has_school_access(s.school_id,array['proprietor','administrator']::public.school_member_role[]) then raise exception 'Permission denied'; end if;
  select id into guardian from public.profiles where lower(email)=lower(trim(guardian_email)) and status='active';
  if guardian is null then raise exception 'The parent must first create an IHLink account with this email'; end if;
  if guardian_relationship not in ('mother','father','guardian','sponsor') then raise exception 'Invalid relationship'; end if;
  insert into public.schoolpro_guardian_links(school_id,student_id,guardian_user_id,relationship,linked_by)
  values(s.school_id,s.id,guardian,guardian_relationship,(select auth.uid()))
  on conflict(student_id,guardian_user_id) do update set relationship=excluded.relationship,status='active',linked_by=(select auth.uid())
  returning id into link_id;
  return link_id;
end $function$

```

## `public.link_schoolpro_student_account(target_student uuid, target_email text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.list_available_schoolpro_cbts()`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.list_available_schoolpro_cbts()
 RETURNS TABLE(id uuid, title text, instructions text, duration_minutes integer, total_marks numeric, opens_at timestamp with time zone, closes_at timestamp with time zone, attempts_allowed integer, attempts_used bigint, eligible boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
with me as (select s.* from schoolpro_students s where s.user_id=auth.uid() and s.status='active' limit 1)
select t.id,t.title,t.instructions,t.duration_minutes,t.total_marks,t.opens_at,t.closes_at,t.attempts_allowed,
 (select count(*) from schoolpro_cbt_attempts a where a.test_id=t.id and a.student_id=me.id) attempts_used,
 ((not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.eligible=true)
 or exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.eligible=true and (e.student_id=me.id or e.class_id=me.class_id)))
 and not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.student_id=me.id and e.eligible=false)) eligible
from me join schoolpro_cbt_tests t on t.school_id=me.school_id
where private.schoolpro_plan_feature_allowed(t.school_id,'cbt') and coalesce(private.is_active_account(),false) and t.status='published' order by coalesce(t.opens_at,t.created_at) desc;
$function$

```

## `public.manage_schoolpro_subscription_invoice(p_invoice uuid, p_action text, p_version timestamp with time zone, p_reason text)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.manage_schoolpro_subscription_invoice(p_invoice uuid, p_action text, p_version timestamp with time zone, p_reason text)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$select private.manage_schoolpro_subscription_invoice(p_invoice,p_action,p_version,p_reason)$function$

```

## `public.mark_schoolpro_cbt_theory(p_attempt uuid, p_question uuid, p_marks numeric, p_feedback text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.mark_schoolpro_cbt_theory(p_attempt uuid, p_question uuid, p_marks numeric, p_feedback text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_cbt_attempts; t public.schoolpro_cbt_tests; q public.schoolpro_question_bank; v_score numeric;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select * into a from public.schoolpro_cbt_attempts where id=p_attempt for update;
 if a.id is null then raise exception 'Attempt not found'; end if;
 select * into t from public.schoolpro_cbt_tests where id=a.test_id;
 if t.id is null or not private.schoolpro_module_allowed(t.school_id,'cbt') or not public.schoolpro_can_manage_cbt(t.school_id) then raise exception 'Not authorized'; end if;
 if a.status<>'submitted' then raise exception 'Attempt must be submitted before theory marking'; end if;
 select q0.* into q from public.schoolpro_question_bank q0
 join public.schoolpro_cbt_test_questions tq on tq.question_id=q0.id
 where tq.test_id=a.test_id and q0.id=p_question and q0.question_type='theory';
 if q.id is null then raise exception 'Theory question is not assigned to this test'; end if;
 if p_marks is null or p_marks<0 or p_marks>q.marks then raise exception 'Marks must be between 0 and %',q.marks; end if;
 update public.schoolpro_cbt_answers
 set marks_awarded=p_marks,feedback=p_feedback,marked_by=auth.uid(),marked_at=now(),is_correct=null
 where attempt_id=a.id and question_id=q.id;
 if not found then raise exception 'No submitted answer exists for this theory question'; end if;
 select coalesce(sum(ans.marks_awarded),0) into v_score
 from public.schoolpro_cbt_answers ans
 join public.schoolpro_cbt_test_questions tq on tq.question_id=ans.question_id and tq.test_id=a.test_id
 where ans.attempt_id=a.id;
 update public.schoolpro_cbt_attempts set score=v_score where id=a.id;
 return jsonb_build_object('attempt_id',a.id,'question_id',q.id,'marks_awarded',p_marks,'score',v_score,'marked_by',auth.uid());
end $function$

```

## `public.mark_schoolpro_theory_answer(p_answer uuid, p_marks numeric, p_feedback text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.mark_schoolpro_theory_answer(p_answer uuid, p_marks numeric, p_feedback text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_cbt_answers;at public.schoolpro_cbt_attempts;t public.schoolpro_cbt_tests;q public.schoolpro_question_bank;
begin
 select * into a from public.schoolpro_cbt_answers where id=p_answer for update;
 if a.id is null then raise exception 'Answer not found';end if;
 select * into at from public.schoolpro_cbt_attempts where id=a.attempt_id;
 if at.id is null then raise exception 'Attempt not found';end if;
 select * into t from public.schoolpro_cbt_tests where id=at.test_id;
 if t.id is null then raise exception 'Test not found';end if;
 if not private.schoolpro_module_allowed(t.school_id,'cbt') then raise exception 'Module permission denied: cbt';end if;
 select * into q from public.schoolpro_question_bank where id=a.question_id and school_id=t.school_id;
 if q.id is null or not exists(select 1 from public.schoolpro_cbt_test_questions tq where tq.test_id=t.id and tq.question_id=q.id) then
   raise exception 'Question is not assigned to this test or school';
 end if;
 if q.question_type<>'theory' then raise exception 'Only theory answers require manual marking';end if;
 if not(public.schoolpro_member_can_manage(t.school_id) or exists(
   select 1 from public.schoolpro_members m where m.school_id=t.school_id and m.user_id=auth.uid()
   and m.role::text in('teacher','class_teacher','exam_officer','head_teacher','vice_principal')
 )) then raise exception 'Not authorized';end if;
 if p_marks<0 or p_marks>q.marks then raise exception 'Marks must be between 0 and question maximum';end if;
 update public.schoolpro_cbt_answers set marks_awarded=p_marks,feedback=p_feedback,marked_by=auth.uid(),marked_at=now(),is_correct=null where id=a.id;
 update public.schoolpro_cbt_attempts set score=(
   select coalesce(sum(coalesce(x.marks_awarded,0)),0) from public.schoolpro_cbt_answers x
   where x.attempt_id=at.id and exists(select 1 from public.schoolpro_cbt_test_questions tq where tq.test_id=t.id and tq.question_id=x.question_id)
 ) where id=at.id;
end $function$

```

## `public.prepare_schoolpro_bank_subscription(p_school uuid, p_catalog uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.prepare_schoolpro_bank_subscription(p_school uuid, p_catalog uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_schools%rowtype;c public.schoolpro_subscription_catalog%rowtype;i public.schoolpro_subscription_intents%rowtype;
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) then raise exception 'Active account required';end if;
 select * into s from public.schoolpro_schools where id=p_school for update;
 if s.id is null or s.status='suspended' then raise exception 'School unavailable';end if;
 if s.owner_id is distinct from auth.uid() and not exists(select 1 from public.schoolpro_members where school_id=s.id and user_id=auth.uid() and role in('proprietor','administrator','bursar')) then raise exception 'School billing permission required';end if;
 select * into c from public.schoolpro_subscription_catalog where id=p_catalog and active=true;
 if c.id is null or c.annual_price is null or c.annual_price<=0 or c.annual_price<>round(c.annual_price,2) then raise exception 'Published annual plan price required';end if;
 if not exists(select 1 from public.ihlink_bank_accounts where is_active) then raise exception 'Company bank accounts unavailable';end if;
 select * into i from public.schoolpro_subscription_intents where school_id=s.id and status='pending' order by created_at limit 1 for update;
 if i.id is not null then
  if i.payment_method<>'bank_transfer' or i.payer_user_id is distinct from auth.uid() or i.catalog_id is distinct from c.id or i.amount is distinct from c.annual_price then raise exception 'Existing subscription instruction requires Finance review before changing plan or payer';end if;
  return to_jsonb(i);
 end if;
 insert into public.schoolpro_subscription_intents(school_id,payer_user_id,catalog_id,billing_cycle,amount,virtual_account_id,reference,status,payment_method) values(s.id,auth.uid(),c.id,'annual',c.annual_price,null,'SCHSUB-'||upper(replace(gen_random_uuid()::text,'-','')),'pending','bank_transfer') returning * into i;
 return to_jsonb(i);
end $function$

```

## `public.prepare_schoolpro_subscription_payment(p_user uuid, p_school uuid, p_catalog uuid, p_account uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.prepare_schoolpro_subscription_payment(p_user uuid, p_school uuid, p_catalog uuid, p_account uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin raise exception 'This service accepts bank transfer and Finance-reviewed payment proof only';end $function$

```

## `public.process_schoolpro_payroll(p_record uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.process_schoolpro_payroll(p_record uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  update public.schoolpro_payroll_records set status='approved' where id=p_record and status='draft';
  if not found then raise exception 'Only an accessible draft payroll record can be approved'; end if;
end $function$

```

## `public.publish_schoolpro_class_results(p_school uuid, p_class uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.publish_schoolpro_class_results(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare n integer; begin if auth.uid() is null or not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) or not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in ('exam_officer','head_teacher','vice_principal'))) then raise exception 'Result publication permission required'; end if; if not exists(select 1 from public.schoolpro_classes where id=p_class and school_id=p_school) then raise exception 'Select a class in this school'; end if; update public.schoolpro_results r set status='published',published_at=now(),locked=true where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='approved' and not r.locked and exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=r.student_id and h.class_id=p_class and h.session=r.session and h.school_id=p_school); get diagnostics n=row_count; insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)values(auth.uid(),'Class results published','schoolpro','class',p_class::text,jsonb_build_object('school_id',p_school,'term',p_term,'session',p_session,'published',n)); return n; end $function$

```

## `public.publish_schoolpro_results(p_school uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.publish_schoolpro_results(p_school uuid, p_term text, p_session text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare n integer;
begin
 if auth.uid() is null then
  raise exception 'Authentication required';
 end if;
 if not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) then
  raise exception 'Module permission denied: results';
 end if;
 if not (
  public.schoolpro_member_can_manage(p_school)
  or exists (
   select 1 from public.schoolpro_members m
   where m.school_id=p_school
     and m.user_id=auth.uid()
     and m.role::text in ('exam_officer','head_teacher','vice_principal')
  )
 ) then
  raise exception 'Not authorized';
 end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then
  raise exception 'Select an academic period';
 end if;
 update public.schoolpro_results
 set status='published', published_at=now(), locked=true
 where school_id=p_school
   and term=trim(p_term)
   and session=trim(p_session)
   and status='approved'
   and locked=false;
 get diagnostics n=row_count;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata)
 values (
  auth.uid(),
  'School results published',
  'schoolpro',
  'school',
  p_school::text,
  jsonb_build_object('term',trim(p_term),'session',trim(p_session),'published',n)
 );
 return n;
end
$function$

```

## `public.publish_schoolpro_selected_results(p_school uuid, p_term text, p_session text, p_students uuid[], p_all boolean)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.publish_schoolpro_selected_results(p_school uuid, p_term text, p_session text, p_students uuid[] DEFAULT NULL::uuid[], p_all boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare n integer;
begin
 if auth.uid() is null or not coalesce(private.schoolpro_module_allowed(p_school,'results'),false) or not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then raise exception 'Result publication permission required'; end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Select an academic period'; end if;
 if p_all then
  if coalesce(cardinality(p_students),0)>0 then raise exception 'Choose one publication scope'; end if;
 else
  if coalesce(cardinality(p_students),0)=0 then raise exception 'Select students to publish'; end if;
  if exists(select 1 from unnest(p_students) x(id) where x.id is null or not exists(select 1 from public.schoolpro_students s where s.id=x.id and s.school_id=p_school and (s.status='active' or exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school and h.student_id=s.id and h.session=trim(p_session))))) then raise exception 'Select students enrolled in this school during the selected session'; end if;
 end if;
 update public.schoolpro_results r set status='published',published_at=now(),locked=true
 where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='approved' and not r.locked
 and exists(select 1 from public.schoolpro_students s where s.id=r.student_id and s.school_id=p_school and (s.status='active' or exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=p_school and h.student_id=s.id and h.session=r.session)) and (p_all or s.id=any(p_students)));
 get diagnostics n=row_count;
 insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata) values(auth.uid(),'Selected results published','schoolpro','school',p_school::text,jsonb_build_object('term',p_term,'session',p_session,'all_students',p_all,'students',p_students,'published',n));
 return n;
end $function$

```

## `public.queue_schoolpro_email(p_school uuid, p_email text, p_name text, p_template text, p_subject text, p_payload jsonb)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.queue_schoolpro_email(p_school uuid, p_email text, p_name text, p_template text, p_subject text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare eid uuid;begin if not private.schoolpro_module_allowed(p_school,'notifications') then raise exception 'Module permission denied: notifications'; end if;  if auth.uid() is null then raise exception 'Authentication required';end if;if not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('registrar','admissions_officer','teacher','class_teacher','exam_officer','accountant','bursar'))) then raise exception 'Not authorized';end if;if p_email is null or position('@' in p_email)=0 then raise exception 'Valid email required';end if;insert into public.schoolpro_email_queue(school_id,recipient_email,recipient_name,template_key,subject,payload) values(p_school,lower(trim(p_email)),p_name,p_template,p_subject,coalesce(p_payload,'{}'::jsonb)) returning id into eid;return eid;end$function$

```

## `public.queue_schoolpro_transactional_email()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.queue_schoolpro_transactional_email()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare sid uuid; sch uuid; email text; nm text; subj text; msg text; key text;
begin
 if tg_table_name='schoolpro_fee_payments' then sid:=new.student_id; sch:=new.school_id; key:='payment_receipt'; subj:='SchoolPro payment receipt'; msg:='A payment of NGN '||new.amount||' has been recorded. Reference: '||coalesce(new.reference,'N/A')||'.';
 elsif tg_table_name='schoolpro_results' and new.status::text='published' and old.status::text is distinct from 'published' then sid:=new.student_id; sch:=new.school_id; key:='result_published'; subj:='SchoolPro result published'; msg:='A result has been published for '||new.term||', '||new.session||'.';
 else return new; end if;
 select u.email,concat_ws(' ',s.first_name,s.last_name) into email,nm from schoolpro_students s left join auth.users u on u.id=s.user_id where s.id=sid;
 if email is not null then insert into schoolpro_email_queue(school_id,recipient_email,recipient_name,template_key,subject,payload,status) values(sch,email,nm,key,subj,jsonb_build_object('message',msg,'student_id',sid),'pending'); end if;
 return new;
end $function$

```

## `public.record_schoolpro_payment(target_invoice uuid, payment_amount numeric, payment_method text, payment_reference text, payment_notes text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.record_schoolpro_payment(target_invoice uuid, payment_amount numeric, payment_method text, payment_reference text, payment_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  invoice_row public.schoolpro_invoices%rowtype;
  payment_id uuid;
  new_paid numeric;
begin
  select * into invoice_row from public.schoolpro_invoices where id=target_invoice for update;
  if invoice_row.id is null then raise exception 'Invoice not found'; end if;
  if not private.has_school_access(invoice_row.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) then raise exception 'Permission denied'; end if;
  if payment_amount is null or payment_amount<=0 or payment_amount<>round(payment_amount,2) then raise exception 'A positive payment with at most two decimal places is required'; end if;
  if nullif(trim(payment_reference),'') is null then raise exception 'Payment reference is required'; end if;
  if payment_amount <= 0 or invoice_row.amount_paid + payment_amount > invoice_row.amount_due then raise exception 'Payment exceeds the outstanding invoice balance'; end if;
  if payment_method not in ('cash','transfer','card','pos','cheque','other') then raise exception 'Unsupported payment method'; end if;
  insert into public.schoolpro_fee_payments(school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by)
  values(invoice_row.school_id,invoice_row.id,invoice_row.student_id,payment_amount,payment_method,trim(payment_reference),payment_notes,(select auth.uid())) returning id into payment_id;
  new_paid := invoice_row.amount_paid + payment_amount;
  update public.schoolpro_invoices set amount_paid=new_paid,status=case when new_paid>=amount_due then 'paid'::public.schoolpro_invoice_status else 'part_paid'::public.schoolpro_invoice_status end,updated_at=now() where id=invoice_row.id;
  return payment_id;
end;
$function$

```

## `public.reopen_schoolpro_result_for_correction(p_result uuid, p_reason text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.reopen_schoolpro_result_for_correction(p_result uuid, p_reason text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.schoolpro_results;v_audit uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if nullif(trim(p_reason),'') is null then raise exception 'Correction reason is required';end if;
 select * into r from public.schoolpro_results where id=p_result for update;
 if r.id is null then raise exception 'Result not found';end if;
 if r.status<>'published' then raise exception 'Only published results use the correction workflow';end if;
 if not private.schoolpro_module_allowed(r.school_id,'results') then raise exception 'Module permission denied: results';end if;
 if not(public.schoolpro_member_can_manage(r.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=r.school_id and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;
 insert into public.schoolpro_result_corrections(school_id,result_id,reopened_by,reason,previous_snapshot)
 values(r.school_id,r.id,auth.uid(),trim(p_reason),to_jsonb(r)) returning id into v_audit;
 update public.schoolpro_results set status='draft',locked=false,approved_by=null,approved_at=null,published_at=null where id=r.id;
 return v_audit;
end $function$

```

## `public.request_schoolpro_workspace_demo(p_request uuid, p_tier text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.request_schoolpro_workspace_demo(p_request uuid, p_tier text DEFAULT 'starter'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.schoolpro_onboarding_requests; sid uuid; did uuid; owner_email text;begin
 if auth.uid() is null or not private.is_active_account() then raise exception 'Active account required';end if;
 select * into r from public.schoolpro_onboarding_requests where id=p_request for update;
 if r.id is null or r.user_id is distinct from auth.uid() then raise exception 'School owner required';end if;
 if r.status not in('approved','provisioning') then raise exception 'School request approval required';end if;
 select email into owner_email from auth.users where id=r.user_id and email_confirmed_at is not null;
 if owner_email is null then raise exception 'Verified account required';end if;
 if not exists(select 1 from public.profiles where id=r.user_id and role='super_admin') and (exists(select 1 from public.schoolpro_members where user_id=r.user_id and role<>'proprietor') or exists(select 1 from public.schoolpro_students where user_id=r.user_id) or exists(select 1 from public.schoolpro_guardian_links where guardian_user_id=r.user_id and status='active')) then raise exception 'School proprietor account required';end if;
 if not exists(select 1 from public.schoolpro_subscription_catalog where code=p_tier and active) then raise exception 'Published plan required';end if;
 sid:=r.school_id;
 if sid is null then
  insert into public.schoolpro_schools(owner_id,name,code,plan,status) values(r.user_id,trim(r.school_name),'SP-'||upper(left(replace(r.id::text,'-',''),12)),'trial','trial') returning id into sid;
  insert into public.schoolpro_members(school_id,user_id,role) values(sid,r.user_id,'proprietor') on conflict(school_id,user_id) do nothing;
 elsif not exists(select 1 from public.schoolpro_schools where id=sid and owner_id=r.user_id) then raise exception 'Workspace owner mismatch';end if;
 select id into did from public.schoolpro_demo_requests where school_id=sid and user_id=r.user_id order by created_at limit 1;
 if did is null then
  insert into public.schoolpro_demo_requests(user_id,school_id,school_name,contact_name,email,phone,meeting_format,status,notes) values(r.user_id,sid,trim(r.school_name),r.contact_name,owner_email,r.phone,'online','new','Workspace demo requested; plan: '||p_tier) returning id into did;
  insert into public.audit_logs(actor_id,action,product,target_type,target_id,metadata) values(auth.uid(),'schoolpro_demo_requested','schoolpro','schoolpro_school',sid::text,jsonb_build_object('demo_request_id',did,'tier',p_tier));
 end if;
 update public.schoolpro_onboarding_requests set school_id=sid,status='provisioning',plan_key=p_tier,updated_at=now() where id=r.id;
 return jsonb_build_object('school_id',sid,'demo_request_id',did,'status','awaiting_admin_activation');
end $function$

```

## `public.retry_schoolpro_email(p_job uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.retry_schoolpro_email(p_job uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare j public.schoolpro_email_queue;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_email_queue where id=p_job),'notifications') then raise exception 'Module permission denied: notifications'; end if;  select * into j from public.schoolpro_email_queue where id=p_job for update;if j.id is null then raise exception 'Email job not found';end if;if not(public.schoolpro_member_can_manage(j.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=j.school_id and m.user_id=auth.uid() and m.role::text in('registrar','admissions_officer'))) then raise exception 'Not authorized';end if;update public.schoolpro_email_queue set status='pending',scheduled_at=now(),error=null where id=j.id;end$function$

```

## `public.return_schoolpro_library_book(p_loan uuid, p_fine numeric)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.return_schoolpro_library_book(p_loan uuid, p_fine numeric DEFAULT 0)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare l public.schoolpro_library_loans;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_library_loans where id=p_loan),'library') then raise exception 'Module permission denied: library'; end if;  select * into l from public.schoolpro_library_loans where id=p_loan for update;if l.id is null then raise exception 'Loan not found';end if;if not(public.schoolpro_member_can_manage(l.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=l.school_id and m.user_id=auth.uid() and m.role::text='librarian')) then raise exception 'Not authorized';end if;if l.returned_at is not null then return;end if;update public.schoolpro_library_loans set returned_at=now(),fine=greatest(coalesce(p_fine,0),0),status='returned' where id=l.id;update public.schoolpro_library_books set available_copies=least(copies,available_copies+1) where id=l.book_id;end$function$

```

## `public.review_schoolpro_leave(p_request uuid, p_status text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.review_schoolpro_leave(p_request uuid, p_status text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare affected integer;
begin
 if auth.uid() is null then raise exception 'Please sign in';end if;
 if p_status not in ('approved','rejected') then raise exception 'Choose approve or decline';end if;
 update public.schoolpro_leave_requests set status=p_status where id=p_request and status='pending';
 get diagnostics affected=row_count;
 if affected<>1 then raise exception 'This request is unavailable or has already been reviewed';end if;
end $function$

```

## `public.review_schoolpro_onboarding(p_request uuid, p_action text, p_expected_status text, p_note text, p_tier text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.review_schoolpro_onboarding(p_request uuid, p_action text, p_expected_status text, p_note text DEFAULT NULL::text, p_tier text DEFAULT 'starter'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.schoolpro_onboarding_requests;sid uuid;new_status text;begin
 if auth.uid() is null or not private.is_admin(array['super_admin']::public.user_role[]) then raise exception 'Super administrator access required';end if;
 if p_action not in('review','approve','reject','provision','activate') then raise exception 'Choose a valid review action';end if;
 if length(trim(coalesce(p_note,'')))<3 then raise exception 'Enter a review or activation reason';end if;
 select * into r from public.schoolpro_onboarding_requests where id=p_request for update;
 if r.id is null then raise exception 'School request not found';end if;
 if r.status is distinct from p_expected_status then raise exception 'This request changed. Refresh before continuing';end if;
 if r.status='active' then raise exception 'This school is already activated';end if;
 if r.status='rejected' and p_action<>'review' then raise exception 'Review the rejected request before approval';end if;
 if r.school_id is not null and p_action in('reject','review','approve') then raise exception 'This request already has a workspace. Manage the school instead';end if;
 sid:=r.school_id;
 if p_action in('provision','activate') then
  if r.status not in('approved','provisioning') then raise exception 'Approve this school request first';end if;
  if r.user_id is null or not exists(select 1 from public.profiles where id=r.user_id and status='active') then raise exception 'An activated proprietor account must be linked before creating the workspace';end if;
  if not exists(select 1 from public.profiles where id=r.user_id and role='super_admin') and (
   exists(select 1 from public.schoolpro_members where user_id=r.user_id and role<>'proprietor')
   or exists(select 1 from public.schoolpro_students where user_id=r.user_id)
   or exists(select 1 from public.schoolpro_guardian_links where guardian_user_id=r.user_id and status='active')) then raise exception 'Invited school accounts cannot register a separate proprietor workspace';end if;
  if sid is null then
   insert into public.schoolpro_schools(owner_id,name,code,plan,status)
   values(r.user_id,trim(r.school_name),'SP-'||upper(left(replace(r.id::text,'-',''),12)),'trial','trial') returning id into sid;
   insert into public.schoolpro_members(school_id,user_id,role) values(sid,r.user_id,'proprietor') on conflict(school_id,user_id) do nothing;
  else
   if not exists(select 1 from public.schoolpro_schools where id=sid and owner_id=r.user_id) then raise exception 'The linked school owner does not match this request';end if;
  end if;
 end if;
 new_status:=case p_action when 'review' then 'reviewing' when 'approve' then 'approved' when 'reject' then 'rejected' when 'provision' then 'provisioning' else 'active' end;
 if p_action='activate' then perform public.control_center_activate_schoolpro(sid,p_tier,p_note);end if;
 update public.schoolpro_onboarding_requests set status=new_status,school_id=sid,reviewed_by=auth.uid(),reviewed_at=now(),review_notes=trim(p_note),updated_at=now() where id=r.id;
 insert into public.audit_logs(actor_id,action,target_type,target_id,metadata) values(auth.uid(),'schoolpro_onboarding_'||p_action,'schoolpro_onboarding_request',r.id::text,jsonb_build_object('school_id',sid,'before',r.status,'after',new_status,'reason',trim(p_note),'activation_source',case when p_action='activate' then 'authorized_control_center_override' else null end));
 return jsonb_build_object('id',r.id,'school_id',sid,'status',new_status);
end;$function$

```

## `public.review_schoolpro_payment_proof(p_proof uuid, p_decision text, p_note text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.review_schoolpro_payment_submission(p_submission uuid, p_decision text, p_note text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.review_schoolpro_result(p_result uuid, p_status text, p_notes text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.review_schoolpro_result(p_result uuid, p_status text, p_notes text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.schoolpro_results;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into r from public.schoolpro_results where id=p_result for update;
 if r.id is null then raise exception 'Result not found';end if;
 if not private.schoolpro_module_allowed(r.school_id,'results') then raise exception 'Module permission denied: results';end if;
 if p_status not in('approved','rejected') then raise exception 'Invalid review status';end if;
 if r.status='published' then raise exception 'Published results cannot be reviewed; unlock and use the controlled correction workflow';end if;
 if r.locked then raise exception 'Locked results cannot be reviewed';end if;
 if not(public.schoolpro_member_can_manage(r.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=r.school_id and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;
 insert into public.schoolpro_result_approvals(school_id,result_id,status,reviewed_by,reviewed_at,notes)
 values(r.school_id,r.id,p_status,auth.uid(),now(),p_notes)
 on conflict(result_id) do update set status=excluded.status,reviewed_by=excluded.reviewed_by,reviewed_at=excluded.reviewed_at,notes=excluded.notes;
 update public.schoolpro_results set status=case when p_status='approved' then 'approved'::public.schoolpro_result_status else 'draft'::public.schoolpro_result_status end,
 approved_by=case when p_status='approved' then auth.uid() else null end,approved_at=case when p_status='approved' then now() else null end,published_at=null where id=r.id;
end $function$

```

## `public.revoke_schoolpro_document_issue(p_issue uuid, p_reason text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.revoke_schoolpro_document_issue(p_issue uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare i public.schoolpro_document_issues;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if trim(coalesce(p_reason,''))='' then raise exception 'Revocation reason is required';end if;
 select * into i from public.schoolpro_document_issues where id=p_issue for update;
 if i.id is null or i.status<>'issued' then raise exception 'Only issued documents can be revoked';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or public.schoolpro_member_can_manage(i.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=i.school_id and m.user_id=auth.uid() and m.role::text in('registrar','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;
 perform set_config('ihlink.document_lifecycle_rpc','on',true);
 update public.schoolpro_document_issues set status='revoked' where id=i.id;
 insert into public.schoolpro_document_issue_events(school_id,issue_id,event_type,actor_id,reason,snapshot) select school_id,id,'revoked',auth.uid(),trim(p_reason),to_jsonb(x) from public.schoolpro_document_issues x where id=i.id;
end $function$

```

## `public.save_schoolpro_cbt_answer(p_attempt uuid, p_question uuid, p_answer text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.save_schoolpro_cbt_answer(p_attempt uuid, p_question uuid, p_answer text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_cbt_attempts; s public.schoolpro_students; t public.schoolpro_cbt_tests; v_allowed boolean;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select * into s from public.schoolpro_students where user_id=auth.uid() and status='active' limit 1;
 select * into a from public.schoolpro_cbt_attempts where id=p_attempt and student_id=s.id for update;
 if a.id is null or a.status<>'in_progress' then raise exception 'Active attempt not found'; end if;
 select * into t from public.schoolpro_cbt_tests where id=a.test_id and school_id=s.school_id;
 if not private.schoolpro_plan_feature_allowed(t.school_id,'cbt') then raise exception 'Online examinations are not available on this school subscription'; end if; if t.id is null or t.status<>'published' then raise exception 'Test is not available'; end if;
 if a.expires_at is not null and now()>a.expires_at then raise exception 'Time has expired'; end if;
 if t.opens_at is not null and now()<t.opens_at then raise exception 'Test is not open yet'; end if;
 if t.closes_at is not null and now()>t.closes_at then raise exception 'Test has closed'; end if;

 select (
   not exists(select 1 from public.schoolpro_cbt_eligibility e where e.test_id=a.test_id and e.eligible=true)
   or exists(select 1 from public.schoolpro_cbt_eligibility e where e.test_id=a.test_id and e.eligible=true
             and (e.student_id=s.id or e.class_id=s.class_id))
 ) and not exists(
   select 1 from public.schoolpro_cbt_eligibility e where e.test_id=a.test_id and e.student_id=s.id and e.eligible=false
 ) into v_allowed;
 if not v_allowed then raise exception 'CBT eligibility has been revoked'; end if;

 if not exists(select 1 from public.schoolpro_cbt_test_questions tq where tq.test_id=a.test_id and tq.question_id=p_question) then
   raise exception 'Question is not part of this test';
 end if;
 insert into public.schoolpro_cbt_answers(attempt_id,question_id,answer)
 values(a.id,p_question,p_answer)
 on conflict(attempt_id,question_id) do update set answer=excluded.answer;
end $function$

```

## `public.schedule_schoolpro_admission_event(p_application uuid, p_type text, p_at timestamp with time zone, p_location text, p_notes text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schedule_schoolpro_admission_event(p_application uuid, p_type text, p_at timestamp with time zone, p_location text, p_notes text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare a public.schoolpro_admissions;e uuid;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_admissions where id=p_application),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into a from public.schoolpro_admissions where id=p_application;if a.id is null then raise exception 'Application not found';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','admissions_officer','registrar')) then raise exception 'Not authorized';end if;insert into public.schoolpro_admission_events(application_id,event_type,scheduled_at,location,notes) values(a.id,p_type,p_at,p_location,p_notes) returning id into e;if a.guardian_email is not null then perform public.queue_schoolpro_email(a.school_id,a.guardian_email,a.guardian_name,'admission_event','School admission '||p_type||' schedule',jsonb_build_object('applicant_name',a.applicant_name,'scheduled_at',p_at,'location',p_location,'notes',p_notes));end if;return e;end$function$

```

## `public.schoolpro_academic_summary(p_student uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_academic_summary(p_student uuid, p_term text, p_session text)
 RETURNS TABLE(average_score numeric, total_score numeric, subject_count bigint, grade text, remark text, class_position bigint, class_population bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_students;v_avg numeric;v_total numeric;v_count bigint;v_grade text;v_remark text;v_pos bigint;v_pop bigint;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into s from public.schoolpro_students where id=p_student;
 if s.id is null then raise exception 'Student not found';end if;
 perform 1 from public.schoolpro_printable_result(p_student,trim(p_term),trim(p_session)) limit 1;
 if not found then raise exception 'No authorized locked published result is available';end if;
 select round(avg(r.total_score),2),round(sum(r.total_score),2),count(*) into v_avg,v_total,v_count from public.schoolpro_results r where r.student_id=p_student and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published' and r.locked=true;
 select g.label,coalesce(g.overall_remark,g.remark) into v_grade,v_remark from public.schoolpro_grade_scale g where g.school_id=s.school_id and g.is_active and v_avg between g.min_score and g.max_score order by g.position,g.min_score desc limit 1;
 select q.class_position,q.class_population into v_pos,v_pop from public.schoolpro_result_class_rank(p_student,trim(p_term),trim(p_session)) q limit 1;
 return query select v_avg,v_total,v_count,v_grade,v_remark,v_pos,v_pop;
end $function$

```

## `public.schoolpro_accept_access_invitation(p_user uuid, p_hash text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_accept_access_invitation(p_user uuid, p_hash text)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare invitation public.schoolpro_access_invitations; uid_email text; sid uuid;
begin
 select lower(email) into uid_email from public.profiles where id=p_user and status='active';
 select * into invitation from public.schoolpro_access_invitations where token_hash=p_hash and email=uid_email and expires_at>now() and accepted_at is null for update;
 if invitation.id is null then return false;end if;
 if invitation.role='parent' then
  if cardinality(invitation.student_ids)=0 then return false;end if;
  foreach sid in array invitation.student_ids loop
   if not exists(select 1 from public.schoolpro_students where id=sid and school_id=invitation.school_id and status='active')then return false;end if;
  end loop;
  foreach sid in array invitation.student_ids loop
   insert into public.schoolpro_guardian_links(school_id,student_id,guardian_user_id,relationship,status,linked_by)
   values(invitation.school_id,sid,p_user,invitation.relationship,'active',invitation.created_by)
   on conflict(student_id,guardian_user_id) do update set status='active',relationship=excluded.relationship;
  end loop;
 else
  insert into public.schoolpro_members(school_id,user_id,role)values(invitation.school_id,p_user,invitation.role::public.school_member_role)on conflict(school_id,user_id)do nothing;
 end if;
 update public.schoolpro_access_invitations set accepted_at=now() where id=invitation.id;
 return true;
end $function$

```

## `public.schoolpro_allocate_hostel(p_school uuid, p_student uuid, p_room uuid, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_allocate_hostel(p_school uuid, p_student uuid, p_room uuid, p_session text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
 insert into public.schoolpro_hostel_allocations(school_id,student_id,room_id,session,active)values(p_school,p_student,p_room,trim(p_session),true) on conflict(student_id,session) do update set room_id=excluded.room_id,active=true returning id into a;
 update public.schoolpro_hostel_rooms rooms set occupied=(select count(*) from public.schoolpro_hostel_allocations x where x.room_id=rooms.id and x.active) where rooms.school_id=p_school and (rooms.id=p_room or rooms.id=any(coalesce(old_rooms,array[]::uuid[])));
 return a;
end $function$

```

## `public.schoolpro_auto_create_admission_document()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_auto_create_admission_document()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare t public.schoolpro_document_templates; st public.schoolpro_students;
begin
 if new.enrollment_status='enrolled' and new.admitted_student_id is not null and (old.enrollment_status is distinct from new.enrollment_status or old.admitted_student_id is distinct from new.admitted_student_id) then
   select * into t from public.schoolpro_document_templates where school_id=new.school_id and document_type='admission_letter' and is_default=true and is_active=true order by version desc limit 1;
   if t.id is not null and not exists(select 1 from public.schoolpro_document_issues i where i.school_id=new.school_id and i.document_type='admission_letter' and i.payload->>'application_id'=new.id::text) then
     select * into st from public.schoolpro_students where id=new.admitted_student_id and school_id=new.school_id;
     insert into public.schoolpro_document_issues(school_id,template_id,student_id,document_type,title,payload,status,issued_by)
     values(new.school_id,t.id,new.admitted_student_id,'admission_letter',t.name,
       jsonb_build_object('application_id',new.id,'student_name',trim(coalesce(st.first_name,'')||' '||coalesce(st.last_name,'')),'first_name',st.first_name,'last_name',st.last_name,'admission_number',st.admission_number,'class_name',st.class_name,'guardian_name',new.guardian_name,'issue_date',current_date::text),
       'draft',auth.uid());
   end if;
 end if;
 return new;
end$function$

```

## `public.schoolpro_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS TABLE(student_id uuid, admission_number text, student_name text, total numeric, average numeric, subjects bigint, class_position bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not private.schoolpro_module_allowed(p_school,'reports') or not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied';end if;
 if not(private.schoolpro_can_review_class(p_school,p_class)) then raise exception 'Not authorized for this class and session';end if;
 return query
 with x as(
  select s.id,s.admission_number,(s.first_name||' '||s.last_name)::text student_name,
   coalesce(sum(r.total_score),0)::numeric total,coalesce(avg(r.total_score),0)::numeric average,count(r.id)::bigint subjects
  from public.schoolpro_students s left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session)
  left join public.schoolpro_results r on r.student_id=s.id and r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published'::public.schoolpro_result_status
  where s.school_id=p_school and coalesce(e.class_id,s.class_id)=p_class and (e.student_id is not null or (s.status='active' and not exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=s.school_id and h.student_id=s.id)))
  group by s.id,s.admission_number,s.first_name,s.last_name
 ),y as(select x.*,rank() over(order by x.total desc)::bigint pos from x)
 select y.id,y.admission_number,y.student_name,y.total,y.average,y.subjects,y.pos from y order by y.pos,y.student_name;
end $function$

```

## `public.schoolpro_bulk_academic_action(p_school uuid, p_session text, p_action text, p_students uuid[])`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_bulk_academic_action(p_school uuid, p_session text, p_action text, p_students uuid[] DEFAULT NULL::uuid[])
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$select private.schoolpro_bulk_academic_action(p_school,p_session,p_action,p_students)$function$

```

## `public.schoolpro_can_author_cbt(p_school uuid)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_can_author_cbt(p_school uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select private.is_admin(array['super_admin']::public.user_role[])
 or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
 or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid()
   and m.role::text in('proprietor','administrator','teacher','class_teacher','exam_officer','head_teacher','vice_principal'))
$function$

```

## `public.schoolpro_can_manage_cbt(p_school uuid)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_can_manage_cbt(p_school uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select private.is_admin(array['super_admin']::public.user_role[])
 or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
 or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid()
   and m.role::text in('proprietor','administrator','exam_officer','head_teacher','vice_principal'))
$function$

```

## `public.schoolpro_can_release_result(p_student uuid, p_term text, p_session text)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_can_release_result(p_student uuid, p_term text, p_session text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select not exists(
  select 1 from public.schoolpro_invoices i
  where i.student_id=p_student and i.term=p_term and i.session=p_session
  and (i.result_hold=true or greatest(i.amount_due-i.amount_paid,0)>0)
 );
$function$

```

## `public.schoolpro_can_view_result_output(p_student_id uuid, p_term text, p_session text)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_can_view_result_output(p_student_id uuid, p_term text, p_session text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select coalesce((select a.allowed from private.schoolpro_result_access(p_student_id,p_term,p_session) a),false) and exists(select 1 from public.schoolpro_results r where r.student_id=p_student_id and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published' and r.locked);
$function$

```

## `public.schoolpro_cbt_is_eligible(p_test uuid, p_student uuid)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_cbt_is_eligible(p_test uuid, p_student uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select exists(
  select 1 from schoolpro_cbt_tests t join schoolpro_students s on s.id=p_student and s.school_id=t.school_id
  where private.schoolpro_plan_feature_allowed(t.school_id,'cbt') and coalesce(private.is_active_account(),false) and t.id=p_test and s.user_id=auth.uid() and (
   not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.eligible=true)
   or exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.eligible=true and (e.student_id=s.id or e.class_id=s.class_id))
  ) and not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.student_id=s.id and e.eligible=false)
 ); $function$

```

## `public.schoolpro_class_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_class_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare summary jsonb; subjects jsonb;
begin
 select coalesce(jsonb_agg(to_jsonb(b)||jsonb_build_object('scores',coalesce((select jsonb_object_agg(r.subject_id::text,r.total_score) from public.schoolpro_results r where r.school_id=p_school and r.student_id=b.student_id and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published'),'{}'::jsonb)) order by b.class_position,b.student_name),'[]'::jsonb)
 into summary from public.schoolpro_broadsheet(p_school,p_class,p_term,p_session) b;
 select coalesce(jsonb_agg(to_jsonb(q) order by q.name),'[]'::jsonb) into subjects from (
 select distinct su.id,su.name,su.code from public.schoolpro_subjects su join public.schoolpro_results r on r.subject_id=su.id and r.school_id=su.school_id join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session)
 where s.school_id=p_school and coalesce(e.class_id,s.class_id)=p_class and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published')q;
 return jsonb_build_object('rows',summary,'subjects',subjects);
end $function$

```

## `public.schoolpro_class_review_sheet(p_school uuid, p_class uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_class_review_sheet(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare output jsonb;
begin
 if not private.schoolpro_can_review_class(p_school,p_class) then raise exception 'Not authorized for this class';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Select a term and session';end if;
 with roster as (
 select s.id,s.admission_number,concat_ws(' ',s.first_name,s.last_name) name
 from public.schoolpro_students s join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id
 where e.school_id=p_school and e.class_id=p_class and e.session=trim(p_session)
 ), marks as (
 select r.* from public.schoolpro_results r join roster s on s.id=r.student_id
 where r.school_id=p_school and r.term=trim(p_term) and r.session=trim(p_session)
 ), totals as (
 select s.id student_id,s.admission_number,s.name student_name,coalesce(sum(m.total_score),0) total,coalesce(avg(m.total_score),0) average,count(m.id) subjects,
 coalesce(jsonb_object_agg(m.subject_id,m.total_score) filter(where m.id is not null),'{}') scores,
 count(m.id) filter(where m.status='draft') draft_scores,count(m.id) filter(where m.status='approved') approved_scores,count(m.id) filter(where m.status='published') published_scores
 from roster s left join marks m on m.student_id=s.id group by s.id,s.admission_number,s.name
 ), ranked as(select t.*,rank() over(order by average desc) class_position from totals t),
 subject_summary as(select su.id,su.name,su.code,avg(m.total_score) average,count(m.id) recorded from marks m join public.schoolpro_subjects su on su.id=m.subject_id and su.school_id=p_school group by su.id,su.name,su.code)
 select jsonb_build_object('rows',coalesce((select jsonb_agg(to_jsonb(r) order by r.class_position,r.student_name) from ranked r),'[]'),
 'subjects',coalesce((select jsonb_agg(to_jsonb(s) order by s.name) from subject_summary s),'[]'),'review',true) into output;
 return output;
end $function$

```

## `public.schoolpro_class_staff_directory(p_school uuid)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_class_staff_directory(p_school uuid)
 RETURNS TABLE(id uuid, user_id uuid, role text, name text)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$ select * from private.schoolpro_class_staff_directory(p_school) $function$

```

## `public.schoolpro_consume_account_challenge(p_user uuid, p_hash text, p_password text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_consume_account_challenge(p_user uuid, p_hash text, p_password text)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare credential public.schoolpro_initial_credentials;
begin
 select * into credential from public.schoolpro_initial_credentials where user_id=p_user and expires_at>now() and consumed_at is null for update;
 if credential.user_id is null or length(p_password)<10 or extensions.crypt(lower(trim(p_password)),credential.surname_hash)=credential.surname_hash then return false;end if;
 if not exists(select 1 from public.schoolpro_account_challenges where user_id=p_user and token_hash=p_hash and expires_at>now())then return false;end if;
 delete from public.schoolpro_account_challenges where user_id=p_user;
 update public.schoolpro_initial_credentials set consumed_at=now() where user_id=p_user;
 return true;
end $function$

```

## `public.schoolpro_consume_student_challenge(p_hash text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_consume_student_challenge(p_hash text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$declare sid uuid;begin select student_id into sid from public.schoolpro_student_activation_challenges where token_hash=p_hash and expires_at>now() for update;if sid is null then return null;end if;perform 1 from public.schoolpro_students where id=sid and user_id is null and status in('active','graduated') for update;if not found then return null;end if;delete from public.schoolpro_student_activation_challenges where student_id=sid;return sid;end;$function$

```

## `public.schoolpro_coordinator_classes(p_school uuid)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_coordinator_classes(p_school uuid)
 RETURNS uuid[]
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$ select private.schoolpro_coordinator_classes(p_school) $function$

```

## `public.schoolpro_current_academic_period(p_school uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_current_academic_period(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare t public.schoolpro_result_term_settings;u public.schoolpro_result_term_settings;begin
 if not private.schoolpro_module_allowed(p_school,'dashboard') then raise exception 'School access required';end if;
 perform private.schoolpro_tick_calendar(p_school);
 select * into t from public.schoolpro_result_term_settings where school_id=p_school and term_start_date<=current_date and term_end_date>=current_date order by term_start_date desc limit 1;
 select * into u from public.schoolpro_result_term_settings where school_id=p_school and term_start_date>current_date order by term_start_date limit 1;
 return jsonb_build_object('current',case when t.id is null then null else jsonb_build_object('session',t.session,'term',t.term,'starts',t.term_start_date,'ends',t.term_end_date) end,'upcoming',case when u.id is null then null else jsonb_build_object('session',u.session,'term',u.term,'starts',u.term_start_date,'ends',u.term_end_date) end);end$function$

```

## `public.schoolpro_family_result_periods(p_student uuid)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_family_result_periods(p_student uuid)
 RETURNS TABLE(term text, session text, allowed boolean, reason text)
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select * from private.schoolpro_family_result_periods(p_student) $function$

```

## `public.schoolpro_finalize_testing_certificate(p_issue uuid, p_output_path text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_finalize_testing_certificate(p_issue uuid, p_output_path text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare item public.schoolpro_document_issues; actor uuid;begin
select * into item from public.schoolpro_document_issues where id=p_issue for update;
if item.id is null or item.document_type<>'certificate' or coalesce((item.payload->>'synthetic')::boolean,false) is not true then raise exception 'Testing certificate required';end if;
select sc.owner_id into actor from public.schoolpro_schools sc join public.schoolpro_students s on s.school_id=sc.id where sc.id=item.school_id and s.id=item.student_id and s.admission_number like 'IH-TST-%' and s.status='graduated' and upper(sc.name) in('IHLINK ACADEMY','IHLINK ACADEMY (TESTING)');
if actor is null or p_output_path not like item.school_id::text||'/generated/%' then raise exception 'Testing record unavailable';end if;
if item.status='issued' then return;end if;if item.status<>'draft' then raise exception 'Draft certificate required';end if;
perform set_config('ihlink.document_lifecycle_rpc','on',true);
update public.schoolpro_document_issues set status='issued',output_storage_path=p_output_path,issued_at=now(),issued_by=actor where id=p_issue;
insert into public.schoolpro_document_issue_events(school_id,issue_id,event_type,actor_id,snapshot) select school_id,id,'issued',actor,to_jsonb(x) from public.schoolpro_document_issues x where id=p_issue;
end $function$

```

## `public.schoolpro_grade_for_score(p_school uuid, p_score numeric)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_grade_for_score(p_school uuid, p_score numeric)
 RETURNS TABLE(grade text, remark text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(p_school)) then raise exception 'Not authorized';end if;
 return query select g.label,g.remark from public.schoolpro_grade_scale g where g.school_id=p_school and g.is_active and p_score between g.min_score and g.max_score order by g.position,g.min_score desc limit 1;
end $function$

```

## `public.schoolpro_initial_challenge(p_user uuid, p_surname text, p_hash text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_initial_challenge(p_user uuid, p_surname text, p_hash text)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare credential public.schoolpro_initial_credentials;
begin
 select * into credential from public.schoolpro_initial_credentials where user_id=p_user and expires_at>now() and consumed_at is null for update;
 if credential.user_id is null or extensions.crypt(lower(trim(coalesce(p_surname,''))),credential.surname_hash)<>credential.surname_hash then return false;end if;
 delete from public.schoolpro_account_challenges where user_id=p_user;
 insert into public.schoolpro_account_challenges(token_hash,user_id) values(p_hash,p_user);
 return true;
end $function$

```

## `public.schoolpro_issue_library_loan(p_school uuid, p_book uuid, p_student uuid, p_member uuid, p_due timestamp with time zone)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_issue_library_loan(p_school uuid, p_book uuid, p_student uuid DEFAULT NULL::uuid, p_member uuid DEFAULT NULL::uuid, p_due timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare b public.schoolpro_library_books;l uuid;
begin
 if not private.schoolpro_module_allowed(p_school,'library') then raise exception 'Module permission denied: library';end if;
 if not private.is_admin(array['super_admin']::public.user_role[]) and not public.schoolpro_member_can_manage(p_school) then raise exception 'Not authorized';end if;
 if (p_student is null)=(p_member is null) then raise exception 'Choose exactly one borrower';end if;
 select * into b from public.schoolpro_library_books where id=p_book and school_id=p_school for update;
 if b.id is null or b.available_copies<1 then raise exception 'Book unavailable';end if;
 if p_student is not null and not exists(
   select 1 from public.schoolpro_students s where s.id=p_student and s.school_id=p_school and s.status='active'
 ) then raise exception 'Student borrower does not belong to this school or is inactive';end if;
 if p_member is not null and not exists(
   select 1 from public.schoolpro_members m where m.id=p_member and m.school_id=p_school
 ) then raise exception 'Member borrower does not belong to this school';end if;
 insert into public.schoolpro_library_loans(school_id,book_id,student_id,member_id,due_at,fine,status)
 values(p_school,p_book,p_student,p_member,coalesce(p_due,now()+interval '14 days'),0,'borrowed') returning id into l;
 update public.schoolpro_library_books set available_copies=available_copies-1 where id=p_book;
 return l;
end $function$

```

## `public.schoolpro_issue_transcript(p_student uuid)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_issue_transcript(p_student uuid)
 RETURNS uuid
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.schoolpro_issue_transcript(p_student) $function$

```

## `public.schoolpro_join_school_code(p_user uuid, p_school_code text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_join_school_code(p_user uuid, p_school_code text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare sid uuid;invite_hash text;account_email text;
begin
 select id into sid from public.schoolpro_schools where upper(code)=upper(trim(p_school_code));
 if sid is null then return null;end if;
 select lower(email) into account_email from public.profiles where id=p_user and status='active';
 if account_email is null then return null;end if;
 if exists(select 1 from public.schoolpro_schools where id=sid and owner_id=p_user) or exists(select 1 from public.schoolpro_members where school_id=sid and user_id=p_user) or exists(select 1 from public.schoolpro_students where school_id=sid and user_id=p_user and status='active') or exists(select 1 from public.schoolpro_guardian_links where school_id=sid and guardian_user_id=p_user and status='active') then return sid;end if;
 select token_hash into invite_hash from public.schoolpro_access_invitations where school_id=sid and lower(email)=account_email and accepted_at is null and expires_at>now() order by expires_at desc limit 1;
 if invite_hash is not null and public.schoolpro_accept_access_invitation(p_user,invite_hash) then return sid;end if;
 return null;
end $function$

```

## `public.schoolpro_member_can_manage(p_school uuid)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_member_can_manage(p_school uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select private.is_admin(array['super_admin']::public.user_role[])
 or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','it_admin'))
 or exists(select 1 from public.schoolpro_schools s where s.id=p_school and s.owner_id=auth.uid())
$function$

```

## `public.schoolpro_overall_grade(p_student_id uuid, p_term text, p_session text)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_overall_grade(p_student_id uuid, p_term text, p_session text)
 RETURNS TABLE(average_score numeric, grade text, remark text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select a.average_score,a.grade,a.remark from public.schoolpro_academic_summary(p_student_id,p_term,p_session) a
$function$

```

## `public.schoolpro_printable_result(p_student uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_printable_result(p_student uuid, p_term text, p_session text)
 RETURNS SETOF schoolpro_results
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare v_allowed boolean;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if nullif(trim(p_term),'') is null or nullif(trim(p_session),'') is null then raise exception 'Choose a term and session first';end if;
 if not exists(select 1 from public.schoolpro_students s where s.id=p_student) then raise exception 'Student not found';end if;
 select a.allowed into v_allowed from public.schoolpro_result_access(p_student,trim(p_term),trim(p_session))a limit 1;
 if not coalesce(v_allowed,false) then raise exception 'Result output is not available';end if;
 -- The caller's existing row policies enforce school, class/subject and family scope.
 -- Graduation and transfer-out preserve authorised historical results.
 return query select r.* from public.schoolpro_results r where r.student_id=p_student and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published' and r.locked=true order by r.created_at,r.id;
end $function$

```

## `public.schoolpro_progression_summary(p_student uuid, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_progression_summary(p_student uuid, p_session text)
 RETURNS TABLE(progression_status text, from_class text, to_class text, progression_session text, applied_at timestamp with time zone, graduated boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_students;p public.schoolpro_promotions;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into s from public.schoolpro_students where id=p_student;
 if s.id is null then raise exception 'Student not found';end if;
 if not(private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(s.school_id) or s.user_id=auth.uid() or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=s.id and g.guardian_user_id=auth.uid() and g.status='active')) then raise exception 'Not authorized';end if;
 select * into p from public.schoolpro_promotions where student_id=s.id and session=trim(p_session) and status='applied' limit 1;
 if p.id is null then return query select null::text,null::text,null::text,trim(p_session),null::timestamptz,(s.status='graduated');return;end if;
 return query select p.decision,p.from_class,p.to_class,p.session,p.applied_at,(p.decision='graduated' or s.status='graduated');
end $function$

```

## `public.schoolpro_record_offline_payment(p_invoice uuid, p_amount numeric, p_method text, p_reference text, p_notes text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_record_offline_payment(p_invoice uuid, p_amount numeric, p_method text, p_reference text, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare i public.schoolpro_invoices;pid uuid;begin if not private.schoolpro_module_allowed((select school_id from public.schoolpro_invoices where id=p_invoice),'finance') then raise exception 'Module permission denied: finance'; end if;  select * into i from public.schoolpro_invoices where id=p_invoice for update;if i.id is null then raise exception 'Invoice not found';end if;if not(public.schoolpro_member_can_manage(i.school_id) or exists(select 1 from public.schoolpro_members m where m.school_id=i.school_id and m.user_id=auth.uid() and m.role::text in('accountant','bursar'))) then raise exception 'Not authorized';end if;if p_amount is null or p_amount::text in ('NaN','Infinity','-Infinity') or p_amount<>round(p_amount,2) or p_amount<=0 or coalesce(i.amount_paid,0)+p_amount>i.amount_due then raise exception 'Invalid payment amount';end if;insert into public.schoolpro_fee_payments(school_id,invoice_id,student_id,amount,method,reference,notes,recorded_by) values(i.school_id,i.id,i.student_id,p_amount,p_method,p_reference,p_notes,auth.uid()) returning id into pid;update public.schoolpro_invoices set amount_paid=coalesce(amount_paid,0)+p_amount,status=case when coalesce(amount_paid,0)+p_amount>=amount_due then 'paid'::public.schoolpro_invoice_status else 'part_paid'::public.schoolpro_invoice_status end,updated_at=now() where id=i.id;return pid;end$function$

```

## `public.schoolpro_report_details(p_student uuid, p_term text, p_session text)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_report_details(p_student uuid, p_term text, p_session text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$ select private.schoolpro_report_details(p_student,p_term,p_session) $function$

```

## `public.schoolpro_result_access(target_student uuid, target_term text, target_session text)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_result_access(target_student uuid, target_term text, target_session text)
 RETURNS TABLE(allowed boolean, outstanding numeric, reason text)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$ select * from private.schoolpro_result_access(target_student,target_term,target_session) $function$

```

## `public.schoolpro_result_class_rank(p_student_id uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_result_class_rank(p_student_id uuid, p_term text, p_session text)
 RETURNS TABLE(class_population bigint, class_position bigint, total_score numeric, average_score numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_school uuid;v_class uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select s.school_id,coalesce(e.class_id,s.class_id) into v_school,v_class from public.schoolpro_students s left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session) where s.id=p_student_id;
 if v_school is null or v_class is null then raise exception 'Student or class not found';end if;
 if not(
  private.is_admin(array['super_admin'::public.user_role])
  or private.has_school_access(v_school,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'exam_officer'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role])
  or exists(select 1 from public.schoolpro_subject_assignments sa join public.schoolpro_members m on m.id=sa.teacher_member_id and m.school_id=sa.school_id where sa.school_id=v_school and sa.class_id=v_class and sa.session=trim(p_session) and m.user_id=auth.uid() and m.role in('teacher'::public.school_member_role,'class_teacher'::public.school_member_role))
  or exists(select 1 from public.schoolpro_classes c join public.schoolpro_members m on m.id=c.form_teacher_id and m.school_id=c.school_id where c.id=v_class and c.school_id=v_school and m.user_id=auth.uid() and m.role in('teacher','class_teacher'))
  or exists(select 1 from public.schoolpro_students s where s.id=p_student_id and s.user_id=auth.uid())
  or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=p_student_id and g.guardian_user_id=auth.uid() and g.status='active')
 ) then raise exception 'Not authorized for this result ranking';end if;
 if (exists(select 1 from public.schoolpro_students s where s.id=p_student_id and s.user_id=auth.uid()) or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=p_student_id and g.guardian_user_id=auth.uid() and g.status='active'))
 and not public.schoolpro_can_view_result_output(p_student_id,trim(p_term),trim(p_session)) then raise exception 'Published result output is not available';end if;
 return query with totals as(
  select s.id,coalesce(sum(r.total_score),0)::numeric total,case when count(r.id)>0 then avg(r.total_score)::numeric else 0::numeric end avg_score
  from public.schoolpro_students s left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session) left join public.schoolpro_results r on r.student_id=s.id and r.school_id=v_school and r.term=trim(p_term) and r.session=trim(p_session) and r.status='published'::public.schoolpro_result_status
  where s.school_id=v_school and coalesce(e.class_id,s.class_id)=v_class and (e.student_id is not null or (s.status='active' and not exists(select 1 from public.schoolpro_enrollment_history h where h.student_id=s.id and h.school_id=s.school_id))) group by s.id
 ),ranked as(select id,total,avg_score,rank() over(order by total desc)::bigint pos,count(*) over()::bigint pop from totals)
 select pop,pos,total,avg_score from ranked where id=p_student_id;
end $function$

```

## `public.schoolpro_result_comment(p_score numeric)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_result_comment(p_score numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$ select case when p_score>=80 then 'Excellent performance. Keep up the outstanding work.' when p_score>=70 then 'Very good performance. Keep working consistently.' when p_score>=60 then 'Good performance with room for further improvement.' when p_score>=50 then 'Fair performance. More consistent effort is encouraged.' when p_score>=40 then 'Performance is below the desired standard. More effort and support are required.' else 'Significant improvement is required. Please review the subject areas and seek support.' end $function$

```

## `public.schoolpro_return_library_loan(p_loan uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_return_library_loan(p_loan uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$declare l schoolpro_library_loans;begin select * into l from schoolpro_library_loans where id=p_loan for update;if l.id is null then raise exception 'Loan not found';end if;if not private.is_admin(array['super_admin']::public.user_role[]) and not schoolpro_member_can_manage(l.school_id) then raise exception 'Not authorized';end if;if l.status='returned' then return;end if;update schoolpro_library_loans set status='returned',returned_at=now() where id=l.id;update schoolpro_library_books set available_copies=least(copies,available_copies+1) where id=l.book_id;end$function$

```

## `public.schoolpro_review_result(p_student uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_review_result(p_student uuid, p_term text, p_session text)
 RETURNS SETOF schoolpro_results
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
declare v_school uuid;v_class uuid;
begin
 select s.school_id,e.class_id into v_school,v_class from public.schoolpro_students s join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session) where s.id=p_student;
 if v_school is null or not private.schoolpro_can_review_class(v_school,v_class) then raise exception 'Not authorized for this class result';end if;
 return query select r.* from public.schoolpro_results r where r.school_id=v_school and r.student_id=p_student and r.term=trim(p_term) and r.session=trim(p_session) order by r.created_at,r.id;
end $function$

```

## `public.schoolpro_revoke_transcript(p_issue uuid)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_revoke_transcript(p_issue uuid)
 RETURNS void
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.schoolpro_revoke_transcript(p_issue) $function$

```

## `public.schoolpro_save_academic_calendar(p_school uuid, p_session text, p_term text, p_start date, p_end date)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.schoolpro_send_school_notice(p_school uuid, p_title text, p_message text, p_classes uuid[], p_students uuid[], p_audience text)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_send_school_notice(p_school uuid, p_title text, p_message text, p_classes uuid[] DEFAULT NULL::uuid[], p_students uuid[] DEFAULT NULL::uuid[], p_audience text DEFAULT 'families'::text)
 RETURNS integer
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.schoolpro_send_school_notice(p_school,p_title,p_message,p_classes,p_students,p_audience) $function$

```

## `public.schoolpro_set_board_role(p_school uuid, p_member uuid, p_title text)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_set_board_role(p_school uuid, p_member uuid, p_title text)
 RETURNS void
 LANGUAGE sql
 SET search_path TO ''
AS $function$select private.schoolpro_set_board_role(p_school,p_member,p_title)$function$

```

## `public.schoolpro_set_form_master(p_class uuid, p_member uuid)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_set_form_master(p_class uuid, p_member uuid)
 RETURNS void
 LANGUAGE sql
 SET search_path TO ''
AS $function$select private.schoolpro_set_form_master(p_class,p_member)$function$

```

## `public.schoolpro_set_initial_credential(p_user uuid, p_school uuid, p_surname text)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_set_initial_credential(p_user uuid, p_school uuid, p_surname text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if p_surname is null or length(trim(p_surname))<1 or length(p_surname)>100 then raise exception 'Invalid surname';end if;
 insert into public.schoolpro_initial_credentials(user_id,school_id,surname_hash)
 values(p_user,p_school,extensions.crypt(lower(trim(p_surname)),extensions.gen_salt('bf')));
end $function$

```

## `public.schoolpro_set_result_access_exception(p_student uuid, p_term text, p_session text, p_allowed boolean, p_reason text)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_set_result_access_exception(p_student uuid, p_term text, p_session text, p_allowed boolean, p_reason text)
 RETURNS void
 LANGUAGE sql
 SET search_path TO ''
AS $function$ select private.schoolpro_set_result_access_exception(p_student,p_term,p_session,p_allowed,p_reason) $function$

```

## `public.schoolpro_set_result_lock(p_school uuid, p_term text, p_session text, p_locked boolean)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_set_result_lock(p_school uuid, p_term text, p_session text, p_locked boolean)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare n int;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 if not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Module permission denied: results';end if;
 if not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid() and m.role::text in('exam_officer','head_teacher','vice_principal'))) then raise exception 'Not authorized';end if;
 if p_locked=false and exists(select 1 from public.schoolpro_results where school_id=p_school and term=trim(p_term) and session=trim(p_session) and status='published')
 then raise exception 'Published results must be reopened individually through the audited correction workflow';end if;
 update public.schoolpro_results set locked=p_locked where school_id=p_school and term=trim(p_term) and session=trim(p_session);
 get diagnostics n=row_count;return n;
end $function$

```

## `public.schoolpro_student_transcripts(p_student uuid)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_student_transcripts(p_student uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$ select private.schoolpro_student_transcripts(p_student) $function$

```

## `public.schoolpro_subject_statistics(p_student uuid, p_term text, p_session text)`
- Language: `sql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_subject_statistics(p_student uuid, p_term text, p_session text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$ select private.schoolpro_subject_statistics(p_student,p_term,p_session) $function$

```

## `public.schoolpro_submit_class_results(p_school uuid, p_class uuid, p_term text, p_session text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_submit_class_results(p_school uuid, p_class uuid, p_term text, p_session text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_id uuid;v_hash text;
begin
 if auth.uid() is null or not private.schoolpro_module_allowed(p_school,'results') then raise exception 'Result permission required';end if;
 if not exists(select 1 from public.schoolpro_classes c where c.id=p_class and c.school_id=p_school) then raise exception 'Invalid class';end if;
 if not (public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m join public.schoolpro_classes c on c.school_id=m.school_id and c.id=p_class where m.user_id=auth.uid() and m.school_id=p_school and m.role::text in('teacher','class_teacher') and c.form_teacher_id=m.id)) then raise exception 'Class coordinator or school leadership permission required';end if;
 if not exists(select 1 from public.schoolpro_results r join public.schoolpro_enrollment_history h on h.student_id=r.student_id and h.school_id=r.school_id and h.session=r.session where r.school_id=p_school and h.class_id=p_class and r.term=trim(p_term) and r.session=trim(p_session) and r.status='draft' and not r.locked) then raise exception 'No eligible draft marks to submit';end if;
 v_hash:=private.schoolpro_class_result_fingerprint(p_school,p_class,trim(p_term),trim(p_session));
 insert into public.schoolpro_class_result_submissions(school_id,class_id,term,session,submitted_by,submitted_at,score_fingerprint)
 values(p_school,p_class,trim(p_term),trim(p_session),auth.uid(),now(),v_hash)
 on conflict(school_id,class_id,term,session) do update set submitted_by=excluded.submitted_by,submitted_at=now(),score_fingerprint=excluded.score_fingerprint returning id into v_id;
 return v_id;
end $function$

```

## `public.schoolpro_subscription_entitlements(p_school uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_subscription_entitlements(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_subscriptions; p public.schoolpro_plan_catalog; base jsonb; ov jsonb; school_state public.school_status;
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) then raise exception 'Not authorized'; end if;
 if not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid()) or exists(select 1 from public.schoolpro_students st where st.school_id=p_school and st.user_id=auth.uid()) or exists(select 1 from public.schoolpro_guardian_links gl where gl.school_id=p_school and gl.guardian_user_id=auth.uid() and gl.status='active') or private.is_admin(array['super_admin']::public.user_role[])) then raise exception 'Not authorized'; end if;
 select status into school_state from public.schoolpro_schools where id=p_school;
 if school_state is distinct from 'active'::public.school_status then return jsonb_build_object('active',false,'tier','none','website',false,'cbt',false,'advanced_reports',false,'custom_branding',false,'reason','subscription_or_control_center_activation_required'); end if;
 select * into s from public.schoolpro_subscriptions where school_id=p_school order by updated_at desc limit 1;
 if s.id is null or s.status<>'active' or (s.renews_at is not null and s.renews_at+case when s.amount>0 and s.billing_cycle='annual' then interval '14 days' else interval '0 days' end<=now()) then return jsonb_build_object('active',false,'tier','none','website',false,'cbt',false,'advanced_reports',false,'custom_branding',false,'reason','active_subscription_required'); end if;
 select * into p from public.schoolpro_plan_catalog where tier=s.tier;
 base:=jsonb_build_object('active',true,'tier',s.tier,'customization_level',s.customization_level,'in_grace',s.amount>0 and s.billing_cycle='annual' and s.renews_at<=now(),'renews_at',s.renews_at,'access_ends_at',s.renews_at+case when s.amount>0 and s.billing_cycle='annual' then interval '14 days' else interval '0 days' end)||coalesce(p.features,'{}'::jsonb);
 select coalesce(jsonb_object_agg(feature,enabled),'{}'::jsonb) into ov from public.schoolpro_feature_overrides where school_id=p_school;
 return base||ov;
end $function$

```

## `public.schoolpro_take_login_attempt(p_key text, p_limit integer)`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_take_login_attempt(p_key text, p_limit integer)
 RETURNS boolean
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare n integer;begin
 if p_limit<1 or p_limit>60 then return false;end if;
 insert into public.schoolpro_login_attempts as a(key) values(p_key)
 on conflict(key) do update set attempts=case when a.started_at<now()-interval '15 minutes' then 1 else a.attempts+1 end,
 started_at=case when a.started_at<now()-interval '15 minutes' then now() else a.started_at end returning attempts into n;
 delete from public.schoolpro_login_attempts where started_at<now()-interval '1 day';
 delete from public.schoolpro_student_activation_challenges where expires_at<now();
 return n<=p_limit;
end;$function$

```

## `public.schoolpro_transfer_ownership(p_school_id uuid, p_new_owner_id uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_transfer_ownership(p_school_id uuid, p_new_owner_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_actor uuid := auth.uid();
  v_old_owner uuid;
  v_target_status public.account_status;
  v_actor_role public.user_role;
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  select p.role, p.status into v_actor_role, v_target_status
  from public.profiles p where p.id = v_actor;

  if v_actor_role is distinct from 'super_admin'::public.user_role
     or v_target_status is distinct from 'active'::public.account_status then
    raise exception 'Active Super Administrator access required' using errcode = '42501';
  end if;

  if p_school_id is null or p_new_owner_id is null then
    raise exception 'School and new owner are required' using errcode = '22004';
  end if;

  perform 1 from public.schoolpro_schools s where s.id = p_school_id for update;
  if not found then
    raise exception 'School not found' using errcode = 'P0002';
  end if;

  select p.status into v_target_status
  from public.profiles p where p.id = p_new_owner_id;
  if not found or v_target_status is distinct from 'active'::public.account_status then
    raise exception 'New owner must have an active profile' using errcode = '22023';
  end if;

  select s.owner_id into v_old_owner
  from public.schoolpro_schools s where s.id = p_school_id;

  if v_old_owner = p_new_owner_id then
    raise exception 'The selected user already owns this school' using errcode = '22023';
  end if;

  update public.schoolpro_members
     set role = 'proprietor'::public.school_member_role,
         position_title = 'Proprietor'
   where school_id = p_school_id and user_id = p_new_owner_id;

  if not found then
    insert into public.schoolpro_members (school_id, user_id, role, position_title)
    values (p_school_id, p_new_owner_id, 'proprietor'::public.school_member_role, 'Proprietor');
  end if;

  update public.schoolpro_schools
     set owner_id = p_new_owner_id
   where id = p_school_id;

  insert into public.schoolpro_leadership_settings (school_id, owner_title)
  values (p_school_id, 'Proprietor')
  on conflict (school_id) do update set owner_title = excluded.owner_title;

  delete from public.schoolpro_members
   where school_id = p_school_id and user_id = v_old_owner;

  return jsonb_build_object(
    'ok', true,
    'school_id', p_school_id,
    'new_owner_id', p_new_owner_id,
    'previous_owner_membership_removed', true,
    'platform_super_admin_role_unchanged', true
  );
end;
$function$

```

## `public.schoolpro_transfer_student_out(p_student uuid, p_destination text, p_reason text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.schoolpro_user_permissions(p_school uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_user_permissions(p_school uuid)
 RETURNS text[]
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare m public.schoolpro_members; base text[]; extra text[];begin if auth.uid() is null then return array[]::text[];end if; if exists(select 1 from public.schoolpro_board_members b join public.schoolpro_members bm on bm.id=b.member_id and bm.school_id=b.school_id where b.school_id=p_school and bm.user_id=auth.uid() and bm.role='administrator') then return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];end if;select * into m from public.schoolpro_members where school_id=p_school and user_id=auth.uid() limit 1;if m.role='administrator' and m.position_title='Principal' then return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];end if;if exists(select 1 from public.schoolpro_schools where id=p_school and owner_id=auth.uid()) or private.is_admin(array['super_admin']::public.user_role[]) then return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];end if;if m.id is null then return array[]::text[];end if;base:=case m.role when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications'] when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications'] when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications'] when 'receptionist' then array['dashboard','admissions','parents','announcements','calendar','notifications'] when 'administrator' then array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','notifications'] when 'bursar' then array['dashboard','finance','students','notifications'] when 'accountant' then array['dashboard','finance','students','reports','notifications'] when 'teacher' then array['reports','discipline','dashboard','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','cbt','notifications'] when 'class_teacher' then array['reports','discipline','dashboard','students','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','notifications'] when 'exam_officer' then array['dashboard','results','reports','cbt','students','classes','subjects','documents','notifications'] when 'registrar' then array['dashboard','students','classes','parents','documents','notifications'] when 'admissions_officer' then array['dashboard','admissions','students','documents','notifications'] when 'librarian' then array['dashboard','library','students','notifications'] when 'nurse' then array['dashboard','medical','students','notifications'] when 'hostel_manager' then array['dashboard','hostel','students','notifications'] when 'transport_manager' then array['dashboard','transport','students','notifications'] when 'inventory_officer' then array['dashboard','inventory','notifications'] when 'hr_officer' then array['dashboard','staff','leave','payroll','notifications'] when 'it_admin' then array['dashboard','roles','branding','operations','notifications'] else array['dashboard','notifications'] end;select array_agg(permission) into extra from public.schoolpro_member_permissions where member_id=m.id and allowed=true;return (select array_agg(distinct x) from unnest(base||coalesce(extra,array[]::text[])) x where not exists(select 1 from public.schoolpro_member_permissions p where p.member_id=m.id and p.permission=x and p.allowed=false));end$function$

```

## `public.schoolpro_vacate_hostel(p_allocation uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_vacate_hostel(p_allocation uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_hostel_allocations;
begin
 if auth.uid() is null then raise exception 'Please sign in';end if;
 select * into a from public.schoolpro_hostel_allocations where id=p_allocation;
 if a.id is null then raise exception 'Allocation not found';end if;
 if not private.schoolpro_module_allowed(a.school_id,'hostel') or not(public.schoolpro_member_can_manage(a.school_id) or private.has_school_access(a.school_id,array['hostel_manager']::public.school_member_role[])) then raise exception 'School hostel permission is required';end if;
 perform 1 from public.schoolpro_students where id=a.student_id for update;
 select * into a from public.schoolpro_hostel_allocations where id=p_allocation for update;
 perform 1 from public.schoolpro_hostel_rooms where id=a.room_id for update;
 update public.schoolpro_hostel_allocations set active=false where id=a.id and active;
 update public.schoolpro_hostel_rooms rooms set occupied=(select count(*) from public.schoolpro_hostel_allocations x where x.room_id=rooms.id and x.active) where rooms.id=a.room_id;
end $function$

```

## `public.schoolpro_verify_result_code(p_code text)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_verify_result_code(p_code text)
 RETURNS TABLE(status text, school_name text, student_name text, admission_number text, class_name text, term text, session text, issued_at timestamp with time zone, snapshot jsonb)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select case when v.revoked_at is null and v.status='valid' then 'valid' else 'revoked' end,s.name,(st.first_name||' '||st.last_name),st.admission_number,st.class_name,v.term,v.session,v.issued_at,
 case when v.revoked_at is null and v.status='valid' then v.snapshot else null::jsonb end
 from public.schoolpro_result_verifications v join public.schoolpro_schools s on s.id=v.school_id join public.schoolpro_students st on st.id=v.student_id
 where v.verification_code=upper(trim(p_code)) limit 1
$function$

```

## `public.set_schoolpro_default_document_template(p_template uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
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

```

## `public.start_schoolpro_cbt(p_test uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.start_schoolpro_cbt(p_test uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_students; t public.schoolpro_cbt_tests; a public.schoolpro_cbt_attempts; v_count int; v_allowed boolean; v_questions jsonb;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select * into s from public.schoolpro_students where user_id=auth.uid() and status='active' limit 1;
 if s.id is null then raise exception 'Student account is not linked to an active student record'; end if;

 -- Serialize starts for this student/test pair before counting or inserting attempts.
 perform pg_advisory_xact_lock(hashtextextended(p_test::text||':'||s.id::text,0));

 select * into t from public.schoolpro_cbt_tests where id=p_test and school_id=s.school_id;
 if not private.schoolpro_plan_feature_allowed(t.school_id,'cbt') then raise exception 'Online examinations are not available on this school subscription'; end if; if t.id is null then raise exception 'Test not found'; end if;
 if t.status<>'published' then raise exception 'This test is not published'; end if;
 if t.opens_at is not null and now()<t.opens_at then raise exception 'This test is not open yet'; end if;
 if t.closes_at is not null and now()>t.closes_at then raise exception 'This test has closed'; end if;

 select (
   not exists(select 1 from public.schoolpro_cbt_eligibility e where e.test_id=p_test and e.eligible=true)
   or exists(select 1 from public.schoolpro_cbt_eligibility e where e.test_id=p_test and e.eligible=true and (e.student_id=s.id or e.class_id=s.class_id))
 ) and not exists(
   select 1 from public.schoolpro_cbt_eligibility e where e.test_id=p_test and e.student_id=s.id and e.eligible=false
 ) into v_allowed;
 if not v_allowed then raise exception 'You are not eligible to take this test'; end if;

 select * into a from public.schoolpro_cbt_attempts
 where test_id=p_test and student_id=s.id and status='in_progress'
 order by attempt_no desc limit 1 for update;

 if a.id is not null and a.expires_at is not null and now()>a.expires_at then
   update public.schoolpro_cbt_attempts
   set status='submitted',submitted_at=coalesce(submitted_at,a.expires_at)
   where id=a.id;
   a.id:=null;
 end if;

 if a.id is null then
   select count(*) into v_count from public.schoolpro_cbt_attempts where test_id=p_test and student_id=s.id;
   if v_count>=greatest(t.attempts_allowed,1) then raise exception 'Maximum attempts reached'; end if;
   insert into public.schoolpro_cbt_attempts(test_id,student_id,attempt_no,expires_at,status)
   values(p_test,s.id,v_count+1,least(now()+make_interval(mins=>greatest(t.duration_minutes,1)),coalesce(t.closes_at,'infinity'::timestamptz)),'in_progress')
   returning * into a;
 end if;

 select coalesce(jsonb_agg(jsonb_build_object(
   'id',q.id,'question_text',q.question_text,'question_type',q.question_type,
   'options',q.options,'marks',q.marks,'position',tq.position
 ) order by case when t.randomize_questions then random() else tq.position end),'[]'::jsonb)
 into v_questions
 from public.schoolpro_cbt_test_questions tq
 join public.schoolpro_question_bank q on q.id=tq.question_id
 where tq.test_id=p_test;

 return jsonb_build_object(
  'attempt_id',a.id,'attempt_no',a.attempt_no,'expires_at',a.expires_at,
  'test',jsonb_build_object('id',t.id,'title',t.title,'instructions',t.instructions,
    'duration_minutes',t.duration_minutes,'total_marks',t.total_marks,'randomize_options',t.randomize_options),
  'questions',v_questions,
  'answers',(select coalesce(jsonb_object_agg(ans.question_id::text,ans.answer),'{}'::jsonb)
             from public.schoolpro_cbt_answers ans where ans.attempt_id=a.id)
 );
end $function$

```

## `public.submit_schoolpro_application(p_school uuid, p_first text, p_last text, p_gender text, p_dob date, p_guardian text, p_phone text, p_email text, p_class text, p_previous text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.submit_schoolpro_application(p_school uuid, p_first text, p_last text, p_gender text, p_dob date, p_guardian text, p_phone text, p_email text, p_class text, p_previous text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare aid uuid;anum text;tok uuid;begin if not exists(select 1 from public.schoolpro_site_settings s where s.school_id=p_school and s.is_published=true and s.admissions_open=true) then raise exception 'Admissions are not currently open';end if;if nullif(trim(p_first),'') is null or nullif(trim(p_last),'') is null or nullif(trim(p_guardian),'') is null or nullif(trim(p_phone),'') is null or nullif(trim(p_class),'') is null then raise exception 'Required application details are missing';end if;anum:='APP-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));insert into public.schoolpro_admissions(school_id,applicant_name,first_name,last_name,gender,date_of_birth,guardian_name,guardian_contact,guardian_email,class_applied,previous_school,application_number,status,submitted_at) values(p_school,trim(p_first)||' '||trim(p_last),trim(p_first),trim(p_last),p_gender,p_dob,trim(p_guardian),trim(p_phone),lower(trim(p_email)),trim(p_class),p_previous,anum,'pending',now()) returning id,public_token into aid,tok;return jsonb_build_object('application_id',aid,'application_number',anum,'public_token',tok);end$function$

```

## `public.submit_schoolpro_assignment(p_assignment uuid, p_submission_text text, p_file_url text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.submit_schoolpro_assignment(p_assignment uuid, p_submission_text text DEFAULT NULL::text, p_file_url text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_assignments;s public.schoolpro_students;v_id uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required';end if;
 select * into a from public.schoolpro_assignments where id=p_assignment for share;
 if a.id is null then raise exception 'Assignment not found';end if;
 if not private.schoolpro_module_allowed(a.school_id,'assignments') then raise exception 'Module permission denied: assignments';end if;
 select * into s from public.schoolpro_students
 where user_id=auth.uid() and school_id=a.school_id and status='active';
 if s.id is null then raise exception 'Active linked student profile required';end if;
 if a.class_id is not null and s.class_id is distinct from a.class_id then raise exception 'Assignment is not for this student class';end if;
 if a.due_at is not null and now()>a.due_at then raise exception 'Assignment deadline has passed';end if;
 if nullif(trim(coalesce(p_submission_text,'')),'') is null
 and nullif(trim(coalesce(p_file_url,'')),'') is null then raise exception 'Submission text or file is required';end if;

 insert into public.schoolpro_assignment_submissions(
 assignment_id,student_id,submission_text,file_url,submitted_at,status,score,feedback
 ) values(a.id,s.id,nullif(trim(p_submission_text),''),nullif(trim(p_file_url),''),now(),'submitted',null,null)
 on conflict(assignment_id,student_id) do update set
 submission_text=excluded.submission_text,file_url=excluded.file_url,
 submitted_at=now(),status='submitted'
 where public.schoolpro_assignment_submissions.score is null
 returning id into v_id;
 if v_id is null then raise exception 'A graded submission cannot be replaced';end if;
 return v_id;
end $function$

```

## `public.submit_schoolpro_cbt(p_attempt uuid)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.submit_schoolpro_cbt(p_attempt uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare a public.schoolpro_cbt_attempts; s uuid; t public.schoolpro_cbt_tests; v_auto numeric:=0; v_theory int:=0; v_total numeric:=0;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 select id into s from public.schoolpro_students where user_id=auth.uid() and status='active' limit 1;
 select * into a from public.schoolpro_cbt_attempts where id=p_attempt and student_id=s for update;
 if a.id is null then raise exception 'Attempt not found'; end if;
 if a.status='submitted' then return jsonb_build_object('submitted',true,'score',a.score,'already_submitted',true); end if;
 if a.status<>'in_progress' then raise exception 'Attempt is not active'; end if;
 select * into t from public.schoolpro_cbt_tests where id=a.test_id;
 if not private.schoolpro_plan_feature_allowed(t.school_id,'cbt') then raise exception 'Online examinations are not available on this school subscription'; end if; if t.id is null then raise exception 'Test not found'; end if;
 if a.expires_at is not null and now()>a.expires_at then raise exception 'Time has expired'; end if;
 if t.closes_at is not null and now()>t.closes_at then raise exception 'Test has closed'; end if;
 update public.schoolpro_cbt_answers ans
 set is_correct=(lower(trim(coalesce(ans.answer,'')))=lower(trim(coalesce(q.correct_answer,'')))),
     marks_awarded=case when lower(trim(coalesce(ans.answer,'')))=lower(trim(coalesce(q.correct_answer,''))) then q.marks else 0 end,
     marked_at=now()
 from public.schoolpro_question_bank q
 where ans.attempt_id=a.id and ans.question_id=q.id
   and q.question_type in('objective','true_false')
   and exists(select 1 from public.schoolpro_cbt_test_questions tq where tq.test_id=a.test_id and tq.question_id=q.id);
 select coalesce(sum(ans.marks_awarded),0) into v_auto
 from public.schoolpro_cbt_answers ans join public.schoolpro_question_bank q on q.id=ans.question_id
 where ans.attempt_id=a.id and q.question_type in('objective','true_false')
 and exists(select 1 from public.schoolpro_cbt_test_questions tq where tq.test_id=a.test_id and tq.question_id=q.id);
 select count(*) into v_theory
 from public.schoolpro_cbt_answers ans join public.schoolpro_question_bank q on q.id=ans.question_id
 where ans.attempt_id=a.id and q.question_type='theory'
 and exists(select 1 from public.schoolpro_cbt_test_questions tq where tq.test_id=a.test_id and tq.question_id=q.id);
 select coalesce(sum(q.marks),0) into v_total
 from public.schoolpro_cbt_test_questions tq join public.schoolpro_question_bank q on q.id=tq.question_id
 where tq.test_id=a.test_id;
 update public.schoolpro_cbt_attempts set status='submitted',submitted_at=now(),score=v_auto where id=a.id;
 return jsonb_build_object('submitted',true,'objective_score',v_auto,'total_marks',v_total,'theory_answers',v_theory,'theory_pending',v_theory>0);
end $function$

```

## `public.submit_schoolpro_payment(p_school uuid, p_bank_account uuid, p_total numeric, p_payment_date date, p_payer_name text, p_bank_reference text, p_receipt_path text, p_receipt_mime text, p_allocations jsonb)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.submit_schoolpro_payment(p_school uuid, p_bank_account uuid, p_total numeric, p_payment_date date, p_payer_name text, p_bank_reference text, p_receipt_path text, p_receipt_mime text, p_allocations jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare sid uuid; a jsonb; inv public.schoolpro_invoices%rowtype; sum_alloc numeric:=0;
begin
 if p_total<=0 or jsonb_array_length(p_allocations)=0 then raise exception 'Payment amount and allocations are required';end if;
 if not exists(select 1 from public.schoolpro_guardian_links g where g.school_id=p_school and g.guardian_user_id=auth.uid() and g.status='active') then raise exception 'No active child link for this school';end if;
 if p_bank_account is not null and not exists(select 1 from public.schoolpro_bank_accounts b where b.id=p_bank_account and b.school_id=p_school and b.active) then raise exception 'Invalid school bank account';end if;
 for a in select * from jsonb_array_elements(p_allocations) loop
  select * into inv from public.schoolpro_invoices where id=(a->>'invoice_id')::uuid and school_id=p_school;
  if inv.id is null then raise exception 'Invalid invoice allocation';end if;
  if not exists(select 1 from public.schoolpro_guardian_links g where g.student_id=inv.student_id and g.guardian_user_id=auth.uid() and g.status='active') then raise exception 'Student is not linked to this parent';end if;
  if (a->>'amount')::numeric<=0 or (a->>'amount')::numeric>inv.amount_due-inv.amount_paid then raise exception 'Invalid allocation amount';end if;
  sum_alloc:=sum_alloc+(a->>'amount')::numeric;
 end loop;
 if sum_alloc<>p_total then raise exception 'Allocated amount must equal payment total';end if;
 insert into public.schoolpro_payment_submissions(school_id,submitted_by,bank_account_id,total_amount,payment_date,payer_name,bank_reference,receipt_path,receipt_mime) values(p_school,auth.uid(),p_bank_account,p_total,p_payment_date,p_payer_name,nullif(btrim(p_bank_reference),''),p_receipt_path,p_receipt_mime) returning id into sid;
 for a in select * from jsonb_array_elements(p_allocations) loop select * into inv from public.schoolpro_invoices where id=(a->>'invoice_id')::uuid;insert into public.schoolpro_payment_allocations(submission_id,school_id,student_id,invoice_id,amount) values(sid,p_school,inv.student_id,inv.id,(a->>'amount')::numeric);end loop;
 return sid;
end $function$

```

## `public.submit_schoolpro_term_demo(p_request uuid, p_tier text, p_term_start date, p_term_end date, p_exam_start date, p_exam_end date, p_calendar text, p_letter text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.submit_schoolpro_term_demo(p_request uuid, p_tier text, p_term_start date, p_term_end date, p_exam_start date, p_exam_end date, p_calendar text, p_letter text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare result jsonb; did uuid;begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) then raise exception 'Active account required';end if;
 if p_term_start is null or p_term_end is null or p_exam_start is null or p_exam_end is null or p_term_end<(p_term_start+interval '3 months')::date or p_exam_start<p_term_start or p_exam_end<p_exam_start or p_exam_end>p_term_end or p_term_end<current_date then raise exception 'Submit a current term of at least three months with exams inside the term';end if;
 if p_calendar is null or p_letter is null or p_calendar=p_letter or split_part(p_calendar,'/',1)<>auth.uid()::text or split_part(p_letter,'/',1)<>auth.uid()::text or not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=p_calendar) or not exists(select 1 from storage.objects where bucket_id='schoolpro-demo-documents' and name=p_letter) then raise exception 'Upload your calendar and request letter';end if;
 result:=public.request_schoolpro_workspace_demo(p_request,p_tier);did:=(result->>'demo_request_id')::uuid;
 update public.schoolpro_demo_requests set term_start=p_term_start,term_end=p_term_end,exam_start=p_exam_start,exam_end=p_exam_end,calendar_path=p_calendar,letter_path=p_letter,updated_at=now() where id=did and user_id=auth.uid() and activated_at is null and status='new' and calendar_path is null;
 if not found then raise exception 'A submitted or activated demo cannot be changed';end if;
 return result||jsonb_build_object('status','awaiting_calendar_review');end $function$

```

## `public.verify_schoolpro_admission_document(p_document uuid, p_verified boolean, p_notes text)`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.verify_schoolpro_admission_document(p_document uuid, p_verified boolean, p_notes text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare d public.schoolpro_admission_documents;a public.schoolpro_admissions;begin if not private.schoolpro_module_allowed((select a.school_id from public.schoolpro_admission_documents d join public.schoolpro_admissions a on a.id=d.application_id where d.id=p_document),'admissions') then raise exception 'Module permission denied: admissions'; end if;  select * into d from public.schoolpro_admission_documents where id=p_document;select * into a from public.schoolpro_admissions where id=d.application_id;if a.id is null then raise exception 'Document not found';end if;if not exists(select 1 from public.schoolpro_members m where m.school_id=a.school_id and m.user_id=auth.uid() and m.role::text in('proprietor','administrator','admissions_officer','registrar')) then raise exception 'Not authorized';end if;update public.schoolpro_admission_documents set verified=p_verified,verified_by=auth.uid(),verified_at=now(),verification_notes=p_notes where id=p_document;end$function$

```

## `public.verify_schoolpro_document(p_serial text)`
- Language: `sql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.verify_schoolpro_document(p_serial text)
 RETURNS TABLE(serial_number text, title text, document_type text, status text, issued_at timestamp with time zone, school_name text, student_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select i.serial_number,i.title,i.document_type,i.status,i.issued_at,s.name,
   case when i.status='issued' then trim(coalesce(st.first_name,'')||' '||coalesce(st.last_name,'')) else null end
 from public.schoolpro_document_issues i
 join public.schoolpro_schools s on s.id=i.school_id
 left join public.schoolpro_students st on st.id=i.student_id and st.school_id=i.school_id
 where upper(i.serial_number)=upper(trim(p_serial))
   and i.status in ('issued','revoked')
 limit 1
$function$

```
