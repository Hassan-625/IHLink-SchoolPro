do $migration$
declare definition text; updated text;
begin
 select pg_get_functiondef(oid) into definition from pg_proc where oid='public.schoolpro_broadsheet(uuid,uuid,text,text)'::regprocedure;
 updated:=replace(definition,'from public.schoolpro_students s','from public.schoolpro_students s left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session)');
 updated:=replace(updated,'s.class_id=p_class and s.status=''active''','coalesce(e.class_id,s.class_id)=p_class and (e.student_id is not null or s.status=''active'')');
 if updated=definition or position('coalesce(e.class_id,s.class_id)=p_class' in updated)=0 then raise exception 'Unexpected broadsheet definition; migration stopped';end if;
 execute updated;
 select pg_get_functiondef(oid) into definition from pg_proc where oid='public.schoolpro_class_broadsheet(uuid,uuid,text,text)'::regprocedure;
 updated:=replace(definition,'join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id','join public.schoolpro_students s on s.id=r.student_id and s.school_id=r.school_id left join public.schoolpro_enrollment_history e on e.student_id=s.id and e.school_id=s.school_id and e.session=trim(p_session)');
 updated:=replace(updated,'s.class_id=p_class','coalesce(e.class_id,s.class_id)=p_class');
 if updated=definition or position('coalesce(e.class_id,s.class_id)=p_class' in updated)=0 then raise exception 'Unexpected subject broadsheet definition; migration stopped';end if;
 execute updated;
end $migration$;
