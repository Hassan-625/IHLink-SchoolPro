-- Public verification returns only completed or revoked authoritative issuance records.
create or replace function public.verify_schoolpro_document(p_serial text)
returns table(serial_number text,title text,document_type text,status text,issued_at timestamptz,school_name text,student_name text)
language sql stable security definer set search_path=''
as $$
 select i.serial_number,i.title,i.document_type,i.status,i.issued_at,s.name,
   case when i.status='issued' then trim(coalesce(st.first_name,'')||' '||coalesce(st.last_name,'')) else null end
 from public.schoolpro_document_issues i
 join public.schoolpro_schools s on s.id=i.school_id
 left join public.schoolpro_students st on st.id=i.student_id and st.school_id=i.school_id
 where upper(i.serial_number)=upper(trim(p_serial))
   and i.status in ('issued','revoked')
 limit 1
$$;
revoke all on function public.verify_schoolpro_document(text) from public;
grant execute on function public.verify_schoolpro_document(text) to anon,authenticated,service_role;
