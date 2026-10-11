"""Generate opt-in SQL fixtures for the existing IHLink Academy testing workspace only.
No automatic application startup or new-school hooks. Does not overwrite existing rows.
"""
import json, pathlib
ROOT=pathlib.Path(__file__).parent
SCHOOL='d342eb87-8d6a-477a-a380-7fab83f586b7'; OWNER='7a65cdab-a9c3-412d-b5d8-7d1bcd857c1d'
classes=[]
for level,prefix,count,short in [('nursery','Nursery',3,'N'),('primary','Basic',5,'B'),('junior_secondary','JSS',3,'J'),('senior_secondary','SS',3,'S')]:
 for n in range(1,count+1):
  for arm in ['A','B']:classes.append(dict(g=len(classes)+1,name=f'{prefix} {n}',arm=arm,level=level,code=f'{short}{n}-{arm}'))
staff_names=[('Amina','Yusuf','administrator'),('Chinedu','Okafor','vice_principal'),('Grace','Adebayo','head_teacher'),('Bello','Musa','bursar'),('Fatima','Ibrahim','registrar'),('Emeka','Nwosu','exam_officer'),('Zainab','Abubakar','class_teacher'),('David','Adeyemi','class_teacher'),('Maryam','Suleiman','class_teacher'),('Esther','Udo','class_teacher'),('Samuel','Bassey','teacher'),('Hauwa','Sani','teacher'),('Daniel','Eze','teacher'),('Ruth','Ojo','teacher'),('Usman','Garba','teacher'),('Ngozi','Obi','librarian'),('Sarah','Bala','nurse'),('Ifeoma','Nnamdi','counsellor'),('Kabiru','Adamu','transport_manager'),('Victoria','Lawal','it_admin')]
people=[dict(n=i+1,kind='staff',first=a,last=b,role=r,email=f'ihacademy.staff.{i+1:02d}@example.com') for i,(a,b,r) in enumerate(staff_names)]
first=['Amina','Chinedu','Grace','Bello','Fatima','Emeka','Zainab','David','Maryam','Esther','Samuel','Hauwa','Daniel','Ruth','Usman','Ngozi','Sarah','Ifeoma','Kabiru','Victoria','Mariam','Joshua','Blessing','Sadiq','Halima','Paul','Peace','Ibrahim','Deborah','Abdul']
last=['Yusuf','Okafor','Adebayo','Musa','Ibrahim','Nwosu','Abubakar','Adeyemi','Suleiman','Udo','Bassey','Sani','Eze','Ojo','Garba','Obi','Bala','Nnamdi','Adamu','Lawal','Afolabi','Danjuma','Ibrahim','Okeke','Aliyu','Olayemi','Ekanem','Tijani','Hassan','Bello','Nwachukwu','Abdullahi','Olumide','Yakubu','Ishaku','Adeniyi','Onyeka','Abass','Akpan','Abiola']
for i in range(140):people.append(dict(n=i+1,kind='parent',first=first[i%30],last=last[(i//30+i)%40],role='parent',email=f'ihacademy.parent.{i+1:03d}@example.com'))
subjects={
'nursery':['Literacy','Numeracy','Phonics','Handwriting','Rhymes and Songs','Basic Science','Social Habits','Health Habits','Creative Arts','Physical Development'],
'primary':['English Studies','Mathematics','Basic Science','Social Studies','Civic Education','Computer Studies','Quantitative Reasoning','Verbal Reasoning','Cultural and Creative Arts','Physical and Health Education'],
'junior_secondary':['English Studies','Mathematics','Basic Science','Basic Technology','Social Studies','Civic Education','Computer Studies','Business Studies','Cultural and Creative Arts','Physical and Health Education'],
'senior_secondary':['English Language','Mathematics','Biology','Chemistry','Physics','Economics','Geography','Government','Computer Studies','Agricultural Science']}
def literal(x):return "'"+json.dumps(x).replace("'","''")+"'::jsonb"
# Deterministic IDs and fixed admissions make replay insert-only and collision-safe.
guard=f"""begin;
select set_config('request.jwt.claim.sub','{OWNER}',true);
select set_config('request.jwt.claims','{{\"sub\":\"{OWNER}\",\"role\":\"authenticated\"}}',true);
do $$ begin if not exists(select 1 from public.schoolpro_schools where id='{SCHOOL}' and owner_id='{OWNER}' and name='IHLINK ACADEMY (Testing)') then raise exception 'Expected testing school not found; refusing to seed';end if;end $$;
"""
core=guard+f"""
with people as(select * from jsonb_to_recordset({literal(people)}) as p(n int,kind text,first text,last text,role text,email text))
insert into auth.users(id,instance_id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,banned_until,confirmation_token,recovery_token,email_change_token_new,email_change)
select md5('ihlink-academy-test-v1:'||kind||':'||n)::uuid,'00000000-0000-0000-0000-000000000000','authenticated','authenticated',email,extensions.crypt(gen_random_uuid()::text,extensions.gen_salt('bf')),now(),jsonb_build_object('provider','email','providers',jsonb_build_array('email'),'schoolpro_initial_login',true,'testing_fixture','ihlink-academy-v1'),jsonb_build_object('requested_service','school','first_name',first,'middle_name','Test','last_name',last,'newsletter_opt_in',false,'testing_fixture','ihlink-academy-v1'),now(),now(),now()+interval '100 years','','','','' from people on conflict(id)do nothing;
insert into auth.identities(user_id,provider_id,identity_data,provider,created_at,updated_at)
select u.id,u.id::text,jsonb_build_object('sub',u.id::text,'email',u.email,'email_verified',true,'phone_verified',false),'email',now(),now() from auth.users u where u.raw_app_meta_data->>'testing_fixture'='ihlink-academy-v1' and not exists(select 1 from auth.identities i where i.user_id=u.id and i.provider='email');
insert into public.customer_service_access(user_id,product,status,plan_name,activated_at)
select id,'schoolpro','active','Testing School Access',now() from auth.users where raw_app_meta_data->>'testing_fixture'='ihlink-academy-v1' on conflict(user_id,product)do nothing;
insert into public.schoolpro_initial_credentials(user_id,school_id,surname_hash)
select id,'{SCHOOL}',extensions.crypt(lower(raw_user_meta_data->>'last_name'),extensions.gen_salt('bf')) from auth.users where raw_app_meta_data->>'testing_fixture'='ihlink-academy-v1' on conflict(user_id)do nothing;
with people as(select * from jsonb_to_recordset({literal(people[:20])}) as p(n int,kind text,first text,last text,role text,email text))
insert into public.schoolpro_members(id,school_id,user_id,role)
select md5('ihlink-academy-test-v1:member:'||n)::uuid,'{SCHOOL}',md5('ihlink-academy-test-v1:staff:'||n)::uuid,role::public.school_member_role from people on conflict(school_id,user_id)do nothing;
with groups as(select * from jsonb_to_recordset({literal(classes)}) as c(g int,name text,arm text,level text,code text))
insert into public.schoolpro_classes(id,school_id,name,arm,level,capacity,form_teacher_id)
select md5('ihlink-academy-test-v1:class:'||g)::uuid,'{SCHOOL}',name,arm,level,40,md5('ihlink-academy-test-v1:member:'||(7+(g-1)%9))::uuid from groups on conflict(school_id,name,arm)do nothing;
with groups as(select * from jsonb_to_recordset({literal(classes)}) as c(g int,name text,arm text,level text,code text))
insert into public.schoolpro_students(id,school_id,admission_number,first_name,last_name,class_name,class_id,gender,date_of_birth,guardian_name,guardian_email)
select md5('ihlink-academy-test-v1:student:'||g||':'||n)::uuid,'{SCHOOL}','IH-TST-2026-'||code||'-'||lpad(n::text,3,'0'),
 (array{str(first).replace('[','[').replace(']',']')})[1+(n-1)%30],
 (array{str(last)})[1+((g-1)*7+(n-1)/30)%40],name||' '||arm,md5('ihlink-academy-test-v1:class:'||g)::uuid,case when n%2=0 then 'female' else 'male' end,
 date '2026-09-01'-(case level when 'nursery' then 4 when 'primary' then 8 when 'junior_secondary' then 12 else 15 end*365+(n*13)%365),
 case when n<=30 then 'Sample guardian '||((((g-1)*30+n-1)%140)+1) else null end,
 case when n<=30 then 'ihacademy.parent.'||lpad(((((g-1)*30+n-1)%140)+1)::text,3,'0')||'@example.com' else null end
from groups cross join generate_series(1,40)n on conflict(school_id,admission_number)do nothing;
with groups as(select * from jsonb_to_recordset({literal(classes)}) as c(g int,name text,arm text,level text,code text))
insert into public.schoolpro_guardian_links(school_id,student_id,guardian_user_id,relationship,linked_by)
select '{SCHOOL}',md5('ihlink-academy-test-v1:student:'||g||':'||n)::uuid,md5('ihlink-academy-test-v1:parent:'||((((g-1)*30+n-1)%140)+1))::uuid,case when n%2=0 then 'mother' else 'father' end,'{OWNER}' from groups cross join generate_series(1,30)n on conflict(student_id,guardian_user_id)do nothing;
with groups as(select * from jsonb_to_recordset({literal(classes)}) as c(g int,name text,arm text,level text,code text)), subjects as(select groups.*,s.value subject,s.ordinality k from groups cross join lateral jsonb_array_elements_text({literal(subjects)}->level)with ordinality s(value,ordinality))
insert into public.schoolpro_subjects(id,school_id,name,code,class_name)
select md5('ihlink-academy-test-v1:subject:'||g||':'||k)::uuid,'{SCHOOL}',subject,'TST-'||code||'-'||lpad(k::text,2,'0'),name||' '||arm from subjects on conflict(school_id,code,class_name)do nothing;
with groups as(select * from jsonb_to_recordset({literal(classes)}) as c(g int,name text,arm text,level text,code text))
insert into public.schoolpro_subject_assignments(school_id,class_id,subject_id,teacher_member_id,session)
select '{SCHOOL}',md5('ihlink-academy-test-v1:class:'||g)::uuid,md5('ihlink-academy-test-v1:subject:'||g||':'||k)::uuid,md5('ihlink-academy-test-v1:member:'||(7+(g-1)%9))::uuid,'2025/2026' from groups cross join generate_series(1,10)k on conflict(class_id,subject_id,session)do nothing;
insert into public.schoolpro_audit_logs(school_id,actor_id,action,entity_type,entity_id,metadata)values('{SCHOOL}','{OWNER}','Testing dataset created','school','{SCHOOL}','{{"fixture":"ihlink-academy-v1","staff":20,"parents":140,"students":1120,"groups":28,"session":"2025/2026","synthetic":true}}');
commit;
select 'Testing core dataset ready' as result;
"""
(ROOT/'academy-core.sql').write_text(core)
(ROOT/'academy-manifest.json').write_text(json.dumps(dict(school_id=SCHOOL,owner_id=OWNER,session='2025/2026',fixture='ihlink-academy-v1',classes=classes,staff=people[:20],parents=people[20:],subjects=subjects),indent=2))
# Completed previous academic session prevents future attendance/results masquerading as real current records.
terms=[('First Term','2025-09-15','2025-12-05','2026-01-12'),('Second Term','2026-01-12','2026-04-03','2026-04-20'),('Third Term','2026-04-20','2026-07-10','2026-09-14')]
for ti,(term,start,end,nextstart) in enumerate(terms,1):
 sql=guard+f"""
insert into public.schoolpro_result_term_settings(school_id,session,term,term_start_date,term_end_date,next_term_begins,class_days,principal_name,form_master_remark_template,principal_remark_template,updated_by)
values('{SCHOOL}','2025/2026','{term}','{start}','{end}','{nextstart}',60,'Grace Adebayo','Keep practising and participate confidently.','Continue working steadily towards your learning goals.','{OWNER}')on conflict(school_id,session,term)do nothing;
with groups as(select * from jsonb_to_recordset({literal(classes)}) as c(g int,name text,arm text,level text,code text)),marks as(
 select g,n,k,level,mod(n*11+k*7+g*3+{ti}*5,66)+30 total from groups cross join generate_series(1,40)n cross join generate_series(1,10)k),components as(
 select *,greatest(3,least(10,floor(total*.1)::int))a1,greatest(3,least(10,floor(total*.1)::int))a2,greatest(3,least(10,floor(total*.1)::int))t1,greatest(3,least(10,floor(total*.1)::int))t2 from marks)
insert into public.schoolpro_results(id,school_id,student_id,subject_id,term,session,assessment_scheme_id,assessment_scores,teacher_comment,head_teacher_comment)
select md5('ihlink-academy-test-v1:result:'||g||':'||n||':'||k||':{ti}')::uuid,'{SCHOOL}',md5('ihlink-academy-test-v1:student:'||g||':'||n)::uuid,md5('ihlink-academy-test-v1:subject:'||g||':'||k)::uuid,'{term}','2025/2026',
 (select id from public.schoolpro_assessment_schemes where school_id='{SCHOOL}' and school_level=level order by is_default desc,created_at limit 1),
 jsonb_build_object('assignment_1',a1,'assignment_2',a2,'test_1',t1,'test_2',t2,'exam',total-a1-a2-t1-t2),
 case when total>=80 then 'Excellent understanding; keep challenging yourself.' when total>=65 then 'Good progress. Practise the areas discussed in class.' when total>=50 then 'Steady effort; more revision will improve confidence.' else 'Needs guided practice and regular revision.' end,
 case when total>=70 then 'A promising performance. Keep up the effort.' else 'Continue learning steadily with support and practice.' end
 from components on conflict(student_id,subject_id,term,session)do nothing;
-- Run the same review and publication functions used by SchoolPro, with owner authorization.
do $$ declare r record;begin for r in select id from public.schoolpro_results where school_id='{SCHOOL}' and session='2025/2026' and term='{term}' and status='draft' and student_id in(select id from public.schoolpro_students where school_id='{SCHOOL}' and admission_number like 'IH-TST-2026-%') loop perform public.review_schoolpro_result(r.id,'approved','Synthetic Academy testing dataset; not a real pupil assessment');end loop;end $$;
select public.publish_schoolpro_selected_results('{SCHOOL}','{term}','2025/2026',array(select id from public.schoolpro_students where school_id='{SCHOOL}' and admission_number like 'IH-TST-2026-%'),false);
insert into public.schoolpro_result_domain_ratings(school_id,student_id,term,session,definition_id,rating,rating_label,rated_by)
select '{SCHOOL}',s.id,'{term}','2025/2026',d.id,2+mod((right(s.admission_number,3)::int)+d.position+{ti},4),substr('ABCD',1+mod((right(s.admission_number,3)::int)+d.position+{ti},4),1),'{OWNER}' from public.schoolpro_students s cross join public.schoolpro_result_domain_definitions d where s.school_id='{SCHOOL}' and s.admission_number like 'IH-TST-2026-%' and d.school_id=s.school_id and d.is_active on conflict(student_id,term,session,definition_id)do nothing;
commit;
select '{term} sample results published' as result;
"""
 (ROOT/f'academy-term-{ti}.sql').write_text(sql)
 attendance=guard+f"""
with days as(select d::date attendance_date,row_number()over(order by d)day_no from generate_series(date '{start}',date '{end}',interval '1 day') d where extract(isodow from d)<6)
insert into public.schoolpro_attendance(school_id,class_id,student_id,attendance_date,status,notes,marked_by)
select '{SCHOOL}',s.class_id,s.id,d.attendance_date,
 (case when mod(right(s.admission_number,3)::int*7+d.day_no+{ti},20)=0 then 'excused' when mod(right(s.admission_number,3)::int*7+d.day_no+{ti},20)in(1,2) then 'absent' when mod(right(s.admission_number,3)::int*7+d.day_no+{ti},20)=3 then 'late' else 'present' end)::public.schoolpro_attendance_status,
 'Synthetic attendance for Academy testing only','{OWNER}' from public.schoolpro_students s cross join days d where s.school_id='{SCHOOL}' and s.admission_number like 'IH-TST-2026-%' on conflict(student_id,attendance_date)do nothing;
commit;
select '{term} attendance saved' as result;
"""
 (ROOT/f'academy-attendance-{ti}.sql').write_text(attendance)
print('Prepared core, three term and three attendance batches; 28 groups, 1120 students, 33600 subject scores.')
