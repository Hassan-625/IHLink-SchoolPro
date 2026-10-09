alter table public.schoolpro_finance_settings add column block_results_for_attendance boolean not null default false, add column minimum_attendance_percent numeric(5,2) not null default 70 check(minimum_attendance_percent between 0 and 100);
create or replace function private.schoolpro_result_access(p_student uuid,p_term text,p_session text)
returns table(allowed boolean,outstanding numeric,reason text) language plpgsql stable security definer set search_path='' as $$
declare s public.schoolpro_students;fs public.schoolpro_finance_settings;debt numeric;hold boolean;exception_allowed boolean;ts public.schoolpro_result_term_settings;recorded_days integer;attended_days integer;expected_days integer;
begin
 if not private.schoolpro_can_read_student(p_student) then return;end if;
 select * into s from public.schoolpro_students where id=p_student;
 select * into fs from public.schoolpro_finance_settings where school_id=s.school_id;
 select coalesce(sum(greatest(i.amount_due-i.amount_paid,0)),0),coalesce(bool_or(i.result_hold),false) into debt,hold from public.schoolpro_invoices i where i.student_id=s.id and i.school_id=s.school_id and i.term=trim(p_term) and i.session=trim(p_session) and i.status<>'waived';
 -- Staff review is separate from family release; family users never inherit staff bypass.
 if exists(select 1 from public.schoolpro_schools sc where sc.id=s.school_id and sc.owner_id=auth.uid()) or private.is_admin(array['super_admin'::public.user_role]) or exists(select 1 from public.schoolpro_members m where m.school_id=s.school_id and m.user_id=auth.uid() and m.role::text not in('parent','student')) then return query select true,debt,null::text;return;end if;
 select o.allowed into exception_allowed from public.schoolpro_result_access_overrides o where o.student_id=s.id and o.school_id=s.school_id and o.term=trim(p_term) and o.session=trim(p_session);
 if exception_allowed is true then return query select true,debt,null::text;return;end if;
 if coalesce(fs.block_results_for_attendance,false) then
  select * into ts from public.schoolpro_result_term_settings where school_id=s.school_id and term=trim(p_term) and session=trim(p_session);
  if ts.term_start_date is null or ts.term_end_date is null then
   return query select false,debt,'Your school is reviewing attendance for this result. Please contact your school.'::text;return;
  end if;
  select count(distinct attendance_date),count(distinct attendance_date) filter(where status::text in('present','late')) into recorded_days,attended_days from public.schoolpro_attendance where student_id=s.id and school_id=s.school_id and attendance_date between ts.term_start_date and ts.term_end_date;
  expected_days:=greatest(coalesce(nullif(ts.class_days,0),recorded_days),recorded_days);
  if expected_days=0 or 100.0*attended_days/expected_days<fs.minimum_attendance_percent then
   return query select false,debt,'Your school has paused this result because attendance is below its requirement. Please contact your school.'::text;return;
  end if;
 end if;
 if hold or (coalesce(fs.block_results_when_owing,false) and debt>coalesce(fs.allowed_outstanding,0)) then return query select false,debt,'Your school has paused this result. Please contact the school accounts office.'::text;else return query select true,debt,null::text;end if;
end $$;

-- A shared school code identifies a workspace; invitation/enrolment is still required.
create or replace function public.schoolpro_join_school_code(p_user uuid,p_school_code text)
returns uuid language plpgsql security invoker set search_path='' as $$
declare sid uuid;invite_hash text;account_email text;
begin
 select id into sid from public.schoolpro_schools where upper(code)=upper(trim(p_school_code));
 if sid is null then return null;end if;
 select lower(email) into account_email from public.profiles where id=p_user and status='active';
 if account_email is null then return null;end if;
 if exists(select 1 from public.schoolpro_schools where id=sid and owner_id=p_user) or exists(select 1 from public.schoolpro_members where school_id=sid and user_id=p_user) or exists(select 1 from public.schoolpro_students where school_id=sid and user_id=p_user and status='active') or exists(select 1 from public.schoolpro_guardian_links where school_id=sid and guardian_user_id=p_user and active) then return sid;end if;
 select token_hash into invite_hash from public.schoolpro_access_invitations where school_id=sid and lower(email)=account_email and accepted_at is null and expires_at>now() order by expires_at desc limit 1;
 if invite_hash is not null and public.schoolpro_accept_access_invitation(p_user,invite_hash) then return sid;end if;
 return null;
end $$;
revoke all on function public.schoolpro_join_school_code(uuid,text) from public,anon,authenticated;
grant execute on function public.schoolpro_join_school_code(uuid,text) to service_role;

create policy "Assigned teachers report concerns" on public.schoolpro_discipline_records for insert to authenticated with check(private.schoolpro_module_allowed(school_id,'discipline') and created_by=auth.uid() and student_id is not null and private.schoolpro_can_read_student(student_id) and exists(select 1 from public.schoolpro_students s where s.id=student_id and s.school_id=schoolpro_discipline_records.school_id) and status='open' and coalesce(action_taken,'')='' and exists(select 1 from public.schoolpro_members m where m.school_id=schoolpro_discipline_records.school_id and m.user_id=auth.uid() and m.role::text in('teacher','class_teacher')));
create policy "Teachers read their reported concerns" on public.schoolpro_discipline_records for select to authenticated using(private.schoolpro_module_allowed(school_id,'discipline') and created_by=auth.uid() and private.schoolpro_can_read_student(student_id));

create or replace function private.schoolpro_notify_discipline()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href)
 select new.school_id,recipient,'Student concern reported','A staff member reported a student concern. Review the report and decide the next action.','discipline','/schoolpro/discipline' from (
 select owner_id recipient from public.schoolpro_schools where id=new.school_id union select user_id from public.schoolpro_members where school_id=new.school_id and role::text in('proprietor','administrator')) r where recipient is not null;
 return new;
end $$;
revoke all on function private.schoolpro_notify_discipline() from public,anon,authenticated;
create trigger schoolpro_notify_discipline after insert on public.schoolpro_discipline_records for each row execute function private.schoolpro_notify_discipline();

CREATE OR REPLACE FUNCTION public.schoolpro_user_permissions(p_school uuid)
 RETURNS text[]
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare m public.schoolpro_members; base text[]; extra text[];begin if auth.uid() is null then return array[]::text[];end if;select * into m from public.schoolpro_members where school_id=p_school and user_id=auth.uid() limit 1;if exists(select 1 from public.schoolpro_schools where id=p_school and owner_id=auth.uid()) or private.is_admin(array['super_admin']::public.user_role[]) then return array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','payroll','calendar','lesson-notes','leave','promotions','notifications']::text[];end if;if m.id is null then return array[]::text[];end if;base:=case m.role when 'vice_principal' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','cbt','discipline','documents','announcements','calendar','notifications'] when 'head_teacher' then array['dashboard','students','results','reports','classes','subjects','attendance','timetable','assignments','lesson-notes','documents','announcements','calendar','notifications'] when 'counsellor' then array['dashboard','students','discipline','parents','announcements','notifications'] when 'receptionist' then array['dashboard','admissions','parents','announcements','calendar','notifications'] when 'administrator' then array['dashboard','students','results','reports','finance','classes','subjects','attendance','timetable','assignments','admissions','cbt','library','staff','parents','transport','hostel','inventory','discipline','medical','documents','announcements','operations','roles','branding','notifications'] when 'bursar' then array['dashboard','finance','students','notifications'] when 'accountant' then array['dashboard','finance','students','reports','notifications'] when 'teacher' then array['discipline','dashboard','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','cbt','notifications'] when 'class_teacher' then array['discipline','dashboard','students','results','attendance','assignments','subjects','timetable','lesson-notes','announcements','notifications'] when 'exam_officer' then array['dashboard','results','reports','cbt','students','classes','subjects','documents','notifications'] when 'registrar' then array['dashboard','students','classes','parents','documents','notifications'] when 'admissions_officer' then array['dashboard','admissions','students','documents','notifications'] when 'librarian' then array['dashboard','library','students','notifications'] when 'nurse' then array['dashboard','medical','students','notifications'] when 'hostel_manager' then array['dashboard','hostel','students','notifications'] when 'transport_manager' then array['dashboard','transport','students','notifications'] when 'inventory_officer' then array['dashboard','inventory','notifications'] when 'hr_officer' then array['dashboard','staff','leave','payroll','notifications'] when 'it_admin' then array['dashboard','roles','branding','operations','notifications'] else array['dashboard','notifications'] end;select array_agg(permission) into extra from public.schoolpro_member_permissions where member_id=m.id and allowed=true;return (select array_agg(distinct x) from unnest(base||coalesce(extra,array[]::text[])) x where not exists(select 1 from public.schoolpro_member_permissions p where p.member_id=m.id and p.permission=x and p.allowed=false));end$function$

