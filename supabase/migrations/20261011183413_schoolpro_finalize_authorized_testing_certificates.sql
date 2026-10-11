create or replace function public.schoolpro_finalize_testing_certificate(p_issue uuid,p_output_path text) returns void language plpgsql security definer set search_path='' as $$ declare item public.schoolpro_document_issues; actor uuid;begin
select * into item from public.schoolpro_document_issues where id=p_issue for update;
if item.id is null or item.document_type<>'certificate' or coalesce((item.payload->>'synthetic')::boolean,false) is not true then raise exception 'Testing certificate required';end if;
select sc.owner_id into actor from public.schoolpro_schools sc join public.schoolpro_students s on s.school_id=sc.id where sc.id=item.school_id and s.id=item.student_id and s.admission_number like 'IH-TST-%' and s.status='graduated' and upper(sc.name)='IHLINK ACADEMY';
if actor is null or p_output_path not like item.school_id::text||'/generated/%' then raise exception 'Testing record unavailable';end if;
if item.status='issued' then return;end if;if item.status<>'draft' then raise exception 'Draft certificate required';end if;
perform set_config('ihlink.document_lifecycle_rpc','on',true);
update public.schoolpro_document_issues set status='issued',output_storage_path=p_output_path,issued_at=now(),issued_by=actor where id=p_issue;
insert into public.schoolpro_document_issue_events(school_id,issue_id,event_type,actor_id,snapshot) select school_id,id,'issued',actor,to_jsonb(x) from public.schoolpro_document_issues x where id=p_issue;
end $$;
revoke all on function public.schoolpro_finalize_testing_certificate(uuid,text) from public,anon,authenticated;
grant execute on function public.schoolpro_finalize_testing_certificate(uuid,text) to service_role;
