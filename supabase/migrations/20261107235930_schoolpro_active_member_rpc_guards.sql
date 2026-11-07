-- Stage C0: remaining public operational RPCs use the central active-membership
-- helper instead of permissive direct membership lookups.
begin;

create or replace function public.create_schoolpro_portal_invite(
  p_student uuid,p_email text,p_type text
) returns uuid
language plpgsql security definer
set search_path = ''
as $function$
declare st public.schoolpro_students; iid uuid;
begin
  select * into st from public.schoolpro_students where id=p_student;
  if st.id is null then raise exception 'Student not found'; end if;
  if not private.schoolpro_module_allowed(st.school_id,'students') then
    raise exception 'Module permission denied: students';
  end if;
  if p_type not in ('student','parent') then raise exception 'Invalid invite type'; end if;
  if not private.has_school_access(
    st.school_id,array['proprietor','administrator','registrar','admissions_officer']::public.school_member_role[]
  ) then raise exception 'Not authorized'; end if;
  insert into public.schoolpro_portal_invites(school_id,student_id,email,invite_type)
  values(st.school_id,st.id,lower(trim(p_email)),p_type)
  returning id into iid;
  perform public.queue_schoolpro_email(
    st.school_id,p_email,st.first_name||' '||st.last_name,
    'portal_invitation','Your SchoolPro portal invitation',
    jsonb_build_object('student_id',st.id,'invite_type',p_type)
  );
  return iid;
end;
$function$;

create or replace function public.create_schoolpro_result_pin(
  target_student uuid,target_term text,target_session text
) returns text
language plpgsql security definer
set search_path = ''
as $function$
declare sid uuid; token text;
begin
  select s.school_id into sid from public.schoolpro_students s where s.id=target_student;
  if sid is null then raise exception 'Student not found'; end if;
  if not private.schoolpro_module_allowed(sid,'results') then
    raise exception 'Module permission denied: results';
  end if;
  if not private.has_school_access(
    sid,array['proprietor','administrator']::public.school_member_role[]
  ) then raise exception 'Not permitted to create result access PINs'; end if;

  token:=upper(substr(encode(gen_random_bytes(8),'hex'),1,12));
  insert into public.schoolpro_result_access_pins(
    school_id,student_id,term,session,pin_hash,created_by,is_active
  ) values(
    sid,target_student,target_term,target_session,
    encode(digest(token,'sha256'),'hex'),auth.uid(),true
  )
  on conflict(student_id,term,session) do update
    set pin_hash=excluded.pin_hash,created_by=excluded.created_by,
      created_at=now(),is_active=true,expires_at=null;
  return token;
end;
$function$;

create or replace function public.link_schoolpro_student_account(
  target_student uuid,target_email text
) returns void
language plpgsql security definer
set search_path = ''
as $function$
declare sid uuid; uid uuid;
begin
  select school_id into sid from public.schoolpro_students where id=target_student;
  if sid is null then raise exception 'Student not found'; end if;
  if not private.schoolpro_module_allowed(sid,'students') then
    raise exception 'Module permission denied: students';
  end if;
  if not private.has_school_access(
    sid,array['administrator']::public.school_member_role[]
  ) then raise exception 'Not permitted'; end if;
  select id into uid from public.profiles
  where lower(email)=lower(trim(target_email)) limit 1;
  if uid is null then raise exception 'No IHLink account exists for this email'; end if;
  update public.schoolpro_students set user_id=uid where id=target_student;
end;
$function$;

create or replace function public.mark_schoolpro_theory_answer(
  p_answer uuid,p_marks numeric,p_feedback text default null
) returns void
language plpgsql security definer
set search_path = ''
as $function$
declare
  a public.schoolpro_cbt_answers;
  at public.schoolpro_cbt_attempts;
  t public.schoolpro_cbt_tests;
  q public.schoolpro_question_bank;
begin
  select * into a from public.schoolpro_cbt_answers where id=p_answer for update;
  if a.id is null then raise exception 'Answer not found'; end if;
  select * into at from public.schoolpro_cbt_attempts where id=a.attempt_id;
  if at.id is null then raise exception 'Attempt not found'; end if;
  select * into t from public.schoolpro_cbt_tests where id=at.test_id;
  if t.id is null then raise exception 'Test not found'; end if;
  if not private.schoolpro_module_allowed(t.school_id,'cbt') then
    raise exception 'Module permission denied: cbt';
  end if;
  select * into q from public.schoolpro_question_bank
  where id=a.question_id and school_id=t.school_id;
  if q.id is null or not exists(
    select 1 from public.schoolpro_cbt_test_questions tq
    where tq.test_id=t.id and tq.question_id=q.id
  ) then raise exception 'Question is not assigned to this test or school'; end if;
  if q.question_type<>'theory' then
    raise exception 'Only theory answers require manual marking';
  end if;
  if not (
    public.schoolpro_member_can_manage(t.school_id)
    or private.has_school_access(
      t.school_id,array['teacher','class_teacher','exam_officer','head_teacher','vice_principal']::public.school_member_role[]
    )
  ) then raise exception 'Not authorized'; end if;
  if p_marks<0 or p_marks>q.marks then
    raise exception 'Marks must be between 0 and question maximum';
  end if;
  update public.schoolpro_cbt_answers
  set marks_awarded=p_marks,feedback=p_feedback,marked_by=auth.uid(),
      marked_at=now(),is_correct=null
  where id=a.id;
  update public.schoolpro_cbt_attempts set score=(
    select coalesce(sum(coalesce(x.marks_awarded,0)),0)
    from public.schoolpro_cbt_answers x
    where x.attempt_id=at.id and exists(
      select 1 from public.schoolpro_cbt_test_questions tq
      where tq.test_id=t.id and tq.question_id=x.question_id
    )
  ) where id=at.id;
end;
$function$;

create or replace function public.queue_schoolpro_email(
  p_school uuid,p_email text,p_name text,p_template text,p_subject text,
  p_payload jsonb default '{}'::jsonb
) returns uuid
language plpgsql security definer
set search_path = ''
as $function$
declare eid uuid;
begin
  if not private.schoolpro_module_allowed(p_school,'notifications') then
    raise exception 'Module permission denied: notifications';
  end if;
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not (
    public.schoolpro_member_can_manage(p_school)
    or private.has_school_access(
      p_school,array['registrar','admissions_officer','teacher','class_teacher','exam_officer','accountant','bursar']::public.school_member_role[]
    )
  ) then raise exception 'Not authorized'; end if;
  if p_email is null or position('@' in p_email)=0 then
    raise exception 'Valid email required';
  end if;
  insert into public.schoolpro_email_queue(
    school_id,recipient_email,recipient_name,template_key,subject,payload
  ) values(
    p_school,lower(trim(p_email)),p_name,p_template,p_subject,
    coalesce(p_payload,'{}'::jsonb)
  ) returning id into eid;
  return eid;
end;
$function$;

create or replace function public.schedule_schoolpro_admission_event(
  p_application uuid,p_type text,p_at timestamptz,p_location text,p_notes text
) returns uuid
language plpgsql security definer
set search_path = ''
as $function$
declare a public.schoolpro_admissions; e uuid;
begin
  select * into a from public.schoolpro_admissions where id=p_application;
  if a.id is null then raise exception 'Application not found'; end if;
  if not private.schoolpro_module_allowed(a.school_id,'admissions') then
    raise exception 'Module permission denied: admissions';
  end if;
  if not private.has_school_access(
    a.school_id,array['proprietor','administrator','admissions_officer','registrar']::public.school_member_role[]
  ) then raise exception 'Not authorized'; end if;
  insert into public.schoolpro_admission_events(
    application_id,event_type,scheduled_at,location,notes
  ) values(a.id,p_type,p_at,p_location,p_notes) returning id into e;
  if a.guardian_email is not null then
    perform public.queue_schoolpro_email(
      a.school_id,a.guardian_email,a.guardian_name,'admission_event',
      'School admission '||p_type||' schedule',
      jsonb_build_object('applicant_name',a.applicant_name,'scheduled_at',p_at,
        'location',p_location,'notes',p_notes)
    );
  end if;
  return e;
end;
$function$;

create or replace function public.verify_schoolpro_admission_document(
  p_document uuid,p_verified boolean,p_notes text default null
) returns void
language plpgsql security definer
set search_path = ''
as $function$
declare d public.schoolpro_admission_documents; a public.schoolpro_admissions;
begin
  select * into d from public.schoolpro_admission_documents where id=p_document;
  if d.id is null then raise exception 'Document not found'; end if;
  select * into a from public.schoolpro_admissions where id=d.application_id;
  if a.id is null then raise exception 'Application not found'; end if;
  if not private.schoolpro_module_allowed(a.school_id,'admissions') then
    raise exception 'Module permission denied: admissions';
  end if;
  if not private.has_school_access(
    a.school_id,array['proprietor','administrator','admissions_officer','registrar']::public.school_member_role[]
  ) then raise exception 'Not authorized'; end if;
  update public.schoolpro_admission_documents
  set verified=p_verified,verified_by=auth.uid(),verified_at=now(),
      verification_notes=p_notes
  where id=p_document;
end;
$function$;

commit;
