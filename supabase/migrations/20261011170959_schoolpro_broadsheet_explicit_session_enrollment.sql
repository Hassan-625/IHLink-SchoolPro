do $$ declare d text;begin
select pg_get_functiondef('public.schoolpro_broadsheet(uuid,uuid,text,text)'::regprocedure) into d;
if position('(e.student_id is not null or s.status=''active'')' in d)=0 then raise exception 'Unexpected enrollment predicate';end if;
d:=replace(d,'(e.student_id is not null or s.status=''active'')','(e.student_id is not null or (s.status=''active'' and not exists(select 1 from public.schoolpro_enrollment_history h where h.school_id=s.school_id and h.student_id=s.id)))');
execute d;
end $$;
