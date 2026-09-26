-- SchoolPro document lifecycle completion
create unique index if not exists schoolpro_document_templates_one_default_per_type on public.schoolpro_document_templates(school_id,document_type) where is_default=true and is_active=true;

create or replace function public.set_schoolpro_default_document_template(p_template uuid)
returns void language plpgsql security definer set search_path='' as $$
declare t public.schoolpro_document_templates;
begin
 select * into t from public.schoolpro_document_templates where id=p_template;
 if t.id is null then raise exception 'Template not found'; end if;
 if not public.schoolpro_member_can_manage(t.school_id) then raise exception 'Not authorized'; end if;
 update public.schoolpro_document_templates set is_default=false,updated_at=now() where school_id=t.school_id and document_type=t.document_type and id<>t.id;
 update public.schoolpro_document_templates set is_default=true,is_active=true,updated_at=now() where id=t.id;
end$$;
revoke all on function public.set_schoolpro_default_document_template(uuid) from public,anon;
grant execute on function public.set_schoolpro_default_document_template(uuid) to authenticated,service_role;

create or replace function public.verify_schoolpro_document(p_serial text)
returns table(serial_number text,title text,document_type text,status text,issued_at timestamptz,school_name text,student_name text)
language sql stable security definer set search_path='' as $$
 select i.serial_number,i.title,i.document_type,i.status,i.issued_at,s.name,
        case when i.status='issued' then trim(coalesce(st.first_name,'')||' '||coalesce(st.last_name,'')) else null end
 from public.schoolpro_document_issues i join public.schoolpro_schools s on s.id=i.school_id
 left join public.schoolpro_students st on st.id=i.student_id and st.school_id=i.school_id
 where upper(i.serial_number)=upper(trim(p_serial)) limit 1
$$;
revoke all on function public.verify_schoolpro_document(text) from public;
grant execute on function public.verify_schoolpro_document(text) to anon,authenticated,service_role;

create or replace function public.schoolpro_auto_create_admission_document()
returns trigger language plpgsql security definer set search_path='' as $$
declare t public.schoolpro_document_templates; st public.schoolpro_students;
begin
 if new.enrollment_status='enrolled' and new.admitted_student_id is not null and (old.enrollment_status is distinct from new.enrollment_status or old.admitted_student_id is distinct from new.admitted_student_id) then
   select * into t from public.schoolpro_document_templates where school_id=new.school_id and document_type='admission_letter' and is_default=true and is_active=true order by version desc limit 1;
   if t.id is not null and not exists(select 1 from public.schoolpro_document_issues i where i.school_id=new.school_id and i.document_type='admission_letter' and i.payload->>'application_id'=new.id::text) then
     select * into st from public.schoolpro_students where id=new.admitted_student_id and school_id=new.school_id;
     insert into public.schoolpro_document_issues(school_id,template_id,student_id,document_type,title,payload,status,issued_by)
     values(new.school_id,t.id,new.admitted_student_id,'admission_letter',t.name,jsonb_build_object('application_id',new.id,'student_name',trim(coalesce(st.first_name,'')||' '||coalesce(st.last_name,'')),'first_name',st.first_name,'last_name',st.last_name,'admission_number',st.admission_number,'class_name',st.class_name,'guardian_name',new.guardian_name,'issue_date',current_date::text),'draft',auth.uid());
   end if;
 end if; return new;
end$$;
revoke all on function public.schoolpro_auto_create_admission_document() from public,anon,authenticated;
grant execute on function public.schoolpro_auto_create_admission_document() to service_role;
drop trigger if exists trg_schoolpro_auto_admission_document on public.schoolpro_admissions;
create trigger trg_schoolpro_auto_admission_document after update of enrollment_status,admitted_student_id on public.schoolpro_admissions for each row execute function public.schoolpro_auto_create_admission_document();