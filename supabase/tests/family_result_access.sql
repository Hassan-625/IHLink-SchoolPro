begin;
-- Every fixture below is rolled back; no live school or learner records are changed.
do $$
<<fixture>>
declare owner_id uuid:=gen_random_uuid(); teacher_id uuid:=gen_random_uuid(); parent_id uuid:=gen_random_uuid(); learner_id uuid:=gen_random_uuid(); other_parent uuid:=gen_random_uuid(); school_id uuid:=gen_random_uuid(); class_id uuid:=gen_random_uuid(); other_class uuid:=gen_random_uuid(); student_id uuid:=gen_random_uuid(); other_student uuid:=gen_random_uuid(); member_id uuid:=gen_random_uuid(); subject_id uuid:=gen_random_uuid(); result_id uuid:=gen_random_uuid(); lesson_id uuid:=gen_random_uuid(); blocked boolean; denied boolean; n integer;
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
 perform set_config('request.jwt.claim.sub',learner_id::text,true);
 execute 'set local role authenticated';
 select not a.allowed into blocked from public.schoolpro_result_access(student_id,'First Term','2026/2027')a;
 if blocked is distinct from true then raise exception 'Student fee gate failed';end if;
 select count(*) into n from public.schoolpro_results where id=result_id;if n<>0 then raise exception 'Blocked raw results exposed';end if;
 if public.schoolpro_can_view_result_output(student_id,'First Term','2026/2027') then raise exception 'Blocked ranking/export leaked';end if;
 perform set_config('request.jwt.claim.sub',parent_id::text,true);
 select not a.allowed into blocked from public.schoolpro_result_access(student_id,'First Term','2026/2027')a;
 if blocked is distinct from true then raise exception 'Parent fee gate failed';end if;
 select count(*) into n from public.schoolpro_family_result_periods(student_id)where allowed=false;
 if n<>1 then raise exception 'Paused result manifest failed';end if;
 perform set_config('request.jwt.claim.sub',other_parent::text,true);
 if private.schoolpro_can_read_student(student_id)then raise exception 'Unlinked parent gained access';end if;
 perform set_config('request.jwt.claim.sub',teacher_id::text,true);
 if not private.schoolpro_can_read_student(student_id)or private.schoolpro_can_read_student(other_student)then raise exception 'Teacher class scoping failed';end if;
 select count(*) into n from public.schoolpro_students where schoolpro_students.school_id=fixture.school_id;if n<>1 then raise exception 'Teacher student RLS leaked unassigned class';end if;
 denied:=false;begin insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,teacher_member_id,session)values(fixture.school_id,fixture.class_id,fixture.subject_id,fixture.member_id,'2027/2028');exception when insufficient_privilege then denied:=true;end;if not denied then raise exception 'Teacher created allocation';end if;
 if not private.schoolpro_can_read_class(class_id)or private.schoolpro_can_read_class(other_class)then raise exception 'Teacher class list scoping failed';end if;
 denied:=false;begin perform public.schoolpro_set_result_access_exception(student_id,'First Term','2026/2027',true,'Teacher should not override');exception when others then denied:=true;end;
 if not denied then raise exception 'Teacher granted fee exception';end if;
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform public.schoolpro_set_result_access_exception(student_id,'First Term','2026/2027',true,'Small outstanding approved');
 perform set_config('request.jwt.claim.sub',parent_id::text,true);
 if not public.schoolpro_can_view_result_output(student_id,'First Term','2026/2027')then raise exception 'Owner exception ignored';end if;
 select count(*) into n from public.schoolpro_printable_result(student_id,'First Term','2026/2027');if n<>1 then raise exception 'Generated family report failed';end if;
 if public.schoolpro_report_details(student_id,'First Term','2026/2027')->'subject_names'->>subject_id::text<>'Mathematics' then raise exception 'Report subject names missing';end if;
 execute 'reset role';
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 perform public.schoolpro_set_result_access_exception(student_id,'First Term','2026/2027',false,'Return to school policy');
 update public.schoolpro_finance_settings set allowed_outstanding=100 where schoolpro_finance_settings.school_id=fixture.school_id;
 perform set_config('request.jwt.claim.sub',learner_id::text,true);
 if not public.schoolpro_can_view_result_output(student_id,'First Term','2026/2027')then raise exception 'Debt threshold equality failed';end if;

 -- Attendance is enforced for both raw scores and generated output.
 insert into public.schoolpro_result_term_settings(school_id,term,session,term_start_date,term_end_date,class_days) values(fixture.school_id,'First Term','2026/2027','2026-09-01','2026-09-10',10);
 insert into public.schoolpro_attendance(school_id,class_id,student_id,attendance_date,status,marked_by) select fixture.school_id,fixture.class_id,fixture.student_id,'2026-09-01'::date+i,'present',fixture.teacher_id from generate_series(0,5)i;
 update public.schoolpro_finance_settings set block_results_for_attendance=true,minimum_attendance_percent=70 where schoolpro_finance_settings.school_id=fixture.school_id;
 execute 'set local role authenticated';
 if public.schoolpro_can_view_result_output(student_id,'First Term','2026/2027')then raise exception 'Attendance gate failed below 70 percent';end if;
 select count(*) into n from public.schoolpro_results where id=result_id;if n<>0 then raise exception 'Attendance-blocked scores exposed';end if;
 execute 'reset role';
 insert into public.schoolpro_attendance(school_id,class_id,student_id,attendance_date,status,marked_by) values(fixture.school_id,fixture.class_id,fixture.student_id,'2026-09-07','late',fixture.teacher_id);
 -- Student access must work without a linked parent.
 delete from public.schoolpro_guardian_links where schoolpro_guardian_links.school_id=fixture.school_id;
 execute 'set local role authenticated';
 if not public.schoolpro_can_view_result_output(student_id,'First Term','2026/2027')then raise exception '70 percent threshold or parent-independent student access failed';end if;
 perform set_config('request.jwt.claim.sub',teacher_id::text,true);
 insert into public.schoolpro_discipline_records(school_id,student_id,incident,status,created_by) values(fixture.school_id,fixture.student_id,'Fixture concern without a linked parent','open',fixture.teacher_id);
 update public.schoolpro_classes set form_teacher_id=member_id where id=class_id;get diagnostics n=row_count;if n<>0 then raise exception 'Teacher assigned form teacher';end if;
 denied:=false;begin insert into public.schoolpro_discipline_records(school_id,student_id,incident,status,created_by) values(fixture.school_id,fixture.other_student,'Unassigned student','open',fixture.teacher_id);exception when insufficient_privilege then denied:=true;end;if not denied then raise exception 'Unassigned student concern allowed';end if;
 execute 'reset role';
 if not exists(select 1 from public.schoolpro_notifications where schoolpro_notifications.school_id=fixture.school_id and user_id=fixture.owner_id and kind='discipline')then raise exception 'Proprietor was not notified';end if;
 -- Notice targeting must follow class permissions, including teachers without a parent link.
 perform set_config('request.jwt.claim.sub',teacher_id::text,true);
 execute 'set local role authenticated';
 n:=public.schoolpro_send_school_notice(school_id,'Fixture notice','Assigned-class notice',array[class_id],null,'families');
 if n<>1 then raise exception 'Assigned teacher notice recipient count failed';end if;
 denied:=false;begin perform public.schoolpro_send_school_notice(school_id,'Unassigned','Not allowed',array[other_class],null,'families');exception when others then denied:=true;end;if not denied then raise exception 'Teacher notified unassigned class';end if;
 denied:=false;begin perform public.schoolpro_send_school_notice(school_id,'Staff','Not allowed',null,null,'staff');exception when others then denied:=true;end;if not denied then raise exception 'Teacher notified all staff';end if;
 execute 'reset role';
 if not exists(select 1 from public.schoolpro_notifications where schoolpro_notifications.school_id=fixture.school_id and user_id=fixture.learner_id and title='Fixture notice')then raise exception 'Student app notice missing';end if;
 -- School code never admits an uninvited account.
 if public.schoolpro_join_school_code(other_parent,'FIX-'||school_id) is not null then raise exception 'School code granted uninvited access';end if;
 insert into public.schoolpro_access_invitations(school_id,email,role,token_hash,created_by) values(fixture.school_id,'fixture-'||fixture.other_parent||'@example.invalid','teacher',md5(fixture.other_parent::text)||md5(fixture.other_parent::text),fixture.owner_id);
 if public.schoolpro_join_school_code(other_parent,'FIX-'||school_id) is distinct from school_id then raise exception 'Invited school-code join failed';end if;
 if public.schoolpro_join_school_code(learner_id,'FIX-'||school_id) is distinct from school_id then raise exception 'Enrolled learner school code failed';end if;
 perform set_config('request.jwt.claim.sub',learner_id::text,true);
 execute 'set local role authenticated';
 denied:=false;begin perform public.schoolpro_join_school_code(other_parent,'FIX-'||school_id);exception when insufficient_privilege then denied:=true;end;if not denied then raise exception 'Client invoked service-only school join';end if;
 execute 'reset role';

 -- Lesson review is a school decision, never a teacher self-approval.
 perform set_config('request.jwt.claim.sub',teacher_id::text,true);
 execute 'set local role authenticated';
 insert into public.schoolpro_lesson_notes(id,school_id,class_id,subject_id,title,content,lesson_date,term,session,plan)
 values(lesson_id,fixture.school_id,fixture.class_id,fixture.subject_id,'Fractions','Guided examples',current_date,'First Term','2026/2027','{"objectives":"Identify halves"}');
 denied:=false;
 begin
 insert into public.schoolpro_lesson_notes(school_id,class_id,subject_id,title)values(fixture.school_id,fixture.other_class,fixture.subject_id,'Unassigned');
 exception when others then denied:=true;end;
 if not denied then raise exception 'Teacher saved an unassigned class lesson';end if;
 denied:=false;
 begin update public.schoolpro_lesson_notes set status='approved' where id=lesson_id;
 exception when others then denied:=true;end;
 if not denied then raise exception 'Teacher approved own lesson';end if;
 update public.schoolpro_lesson_notes set status='submitted' where id=lesson_id;
 denied:=false;
 begin update public.schoolpro_lesson_notes set content='Changed after submission' where id=lesson_id;
 exception when others then denied:=true;end;
 if not denied then raise exception 'Submitted lesson remained editable';end if;
 execute 'reset role';
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 execute 'set local role authenticated';
 update public.schoolpro_lesson_notes set status='changes_requested',review_comment='Add an example' where id=lesson_id;
 execute 'reset role';
 perform set_config('request.jwt.claim.sub',teacher_id::text,true);
 execute 'set local role authenticated';
 update public.schoolpro_lesson_notes set content='Guided examples and practice',status='submitted' where id=lesson_id;
 execute 'reset role';
 perform set_config('request.jwt.claim.sub',owner_id::text,true);
 execute 'set local role authenticated';
 update public.schoolpro_lesson_notes set status='approved' where id=lesson_id;
 if not exists(select 1 from public.schoolpro_lesson_notes where id=lesson_id and status='approved' and reviewed_by=owner_id)then raise exception 'Owner lesson approval missing';end if;
 denied:=false;
 begin delete from public.schoolpro_lesson_notes where id=lesson_id;
 exception when others then denied:=true;end;
 if not denied then raise exception 'Approved lesson could be deleted';end if;
 execute 'reset role';

 perform set_config('request.jwt.claim.sub','',true);
 if private.schoolpro_can_read_student(student_id)then raise exception 'Anonymous student data leaked';end if;
end $$;
rollback;
select 'PASS: parent/student fee gate, published manifest, class scope, owner-only audited exceptions, threshold, attendance, parent-independent access, teacher concerns/owner notifications, shared-code invitation protection and report details' result;
