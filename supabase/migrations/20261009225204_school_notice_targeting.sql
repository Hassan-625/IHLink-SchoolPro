create or replace function private.schoolpro_send_school_notice(p_school uuid,p_title text,p_message text,p_classes uuid[],p_students uuid[],p_audience text)
returns integer language plpgsql security definer set search_path='' as $$
declare leader boolean;sent integer;
begin
 if auth.uid() is null or not private.schoolpro_module_allowed(p_school,'announcements') then raise exception 'School notice permission required';end if;
 leader:=private.has_school_access(p_school,array['proprietor','administrator','vice_principal','head_teacher']::public.school_member_role[]);
 if not leader and not exists(select 1 from public.schoolpro_members where school_id=p_school and user_id=auth.uid() and role::text in('teacher','class_teacher')) then raise exception 'School notice permission required';end if;
 if length(trim(p_title)) not between 1 and 150 or length(trim(p_message)) not between 1 and 4000 or p_audience not in('families','staff','all') or (not leader and p_audience<>'families') then raise exception 'Choose a permitted audience and enter your notice';end if;
 if exists(select 1 from unnest(coalesce(p_classes,array[]::uuid[])) cid where not exists(select 1 from public.schoolpro_classes c where c.id=cid and c.school_id=p_school and private.schoolpro_can_read_class(c.id))) then raise exception 'Choose classes assigned to your school account';end if;
 if exists(select 1 from unnest(coalesce(p_students,array[]::uuid[])) sid where not exists(select 1 from public.schoolpro_students s where s.id=sid and s.school_id=p_school and private.schoolpro_can_read_student(s.id) and (coalesce(cardinality(p_classes),0)=0 or s.class_id=any(p_classes)))) then raise exception 'Choose students from the selected classes';end if;
 with selected_students as (
 select s.id,s.user_id from public.schoolpro_students s where s.school_id=p_school and s.status='active' and private.schoolpro_can_read_student(s.id) and (coalesce(cardinality(p_classes),0)=0 or s.class_id=any(p_classes)) and (coalesce(cardinality(p_students),0)=0 or s.id=any(p_students))
 ),recipients as(
 select s.user_id from selected_students s where p_audience in('families','all')
 union select g.guardian_user_id from public.schoolpro_guardian_links g join selected_students s on s.id=g.student_id where g.school_id=p_school and g.status='active' and p_audience in('families','all')
 union select m.user_id from public.schoolpro_members m where m.school_id=p_school and leader and p_audience in('staff','all') and (coalesce(cardinality(p_classes),0)=0 or exists(select 1 from public.schoolpro_subject_assignments a where a.teacher_member_id=m.id and a.school_id=p_school and a.class_id=any(p_classes)) or exists(select 1 from public.schoolpro_classes c where c.school_id=p_school and c.id=any(p_classes) and c.form_teacher_id=m.id))
 union select sc.owner_id from public.schoolpro_schools sc where sc.id=p_school and leader and p_audience in('staff','all')
 )insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href)
 select p_school,r.user_id,trim(p_title),trim(p_message),'school_notice','/schoolpro/notifications' from recipients r join public.profiles pr on pr.id=r.user_id where pr.status='active';
 get diagnostics sent=row_count;return sent;
end $$;
revoke all on function private.schoolpro_send_school_notice(uuid,text,text,uuid[],uuid[],text) from public,anon;
grant execute on function private.schoolpro_send_school_notice(uuid,text,text,uuid[],uuid[],text) to authenticated;
create or replace function public.schoolpro_send_school_notice(p_school uuid,p_title text,p_message text,p_classes uuid[] default null,p_students uuid[] default null,p_audience text default 'families')
returns integer language sql security invoker set search_path='' as $$ select private.schoolpro_send_school_notice(p_school,p_title,p_message,p_classes,p_students,p_audience) $$;
revoke all on function public.schoolpro_send_school_notice(uuid,text,text,uuid[],uuid[],text) from public,anon;
grant execute on function public.schoolpro_send_school_notice(uuid,text,text,uuid[],uuid[],text) to authenticated;
