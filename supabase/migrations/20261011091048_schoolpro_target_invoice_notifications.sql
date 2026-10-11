CREATE OR REPLACE FUNCTION private.notify_school_staff()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare sid uuid;ttl text;msg text;href text;begin sid:=new.school_id;if tg_table_name='schoolpro_announcements' then ttl:='New announcement: '||new.title;msg:=left(new.body,240);href:='/schoolpro/announcements';elsif tg_table_name='schoolpro_admissions' then ttl:='Admissions update';msg:='Application '||coalesce(new.application_number,new.id::text)||' is now '||new.status;href:='/schoolpro/admissions';elsif tg_table_name='schoolpro_invoices' then
 insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href)
 select sid,recipient,'Fee invoice created',new.title||' · '||new.term||' · '||new.session,tg_table_name,'/schoolpro/invoices/'||new.id
 from (
 select sc.owner_id recipient from public.schoolpro_schools sc where sc.id=sid
 union select m.user_id from public.schoolpro_members m where m.school_id=sid and m.role::text in('proprietor','administrator','accountant','bursar')
 union select st.user_id from public.schoolpro_students st where st.id=new.student_id and st.school_id=sid
 union select g.guardian_user_id from public.schoolpro_guardian_links g where g.student_id=new.student_id and g.school_id=sid and g.status='active'
 ) recipients where recipient is not null;
 return new;else return new;end if;insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href) select sid,m.user_id,ttl,msg,tg_table_name,href from public.schoolpro_members m where m.school_id=sid union select sid,s.owner_id,ttl,msg,tg_table_name,href from public.schoolpro_schools s where s.id=sid and s.owner_id is not null;return new;end$function$

