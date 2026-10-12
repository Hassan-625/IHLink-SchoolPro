-- Read-only regression against the explicitly authorized IHLINK ACADEMY testing fixture.
-- Claims are transaction-local and no credentials or records are changed.
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','bf54fce9-3c3d-4f0c-8b8c-a339e4704b02',true);
do $$
declare n integer; denied boolean:=false;
begin
 select count(*) into n from public.schoolpro_enrollment_history where school_id='d342eb87-8d6a-477a-a380-7fab83f586b7' and session='2025/2026';
 if n<>40 then raise exception 'Coordinator historical roster mismatch: %',n;end if;
 select jsonb_array_length(public.schoolpro_class_review_sheet('d342eb87-8d6a-477a-a380-7fab83f586b7','be49ea13-4e43-7c75-7158-bc53bdbb7994','First Term','2025/2026')->'rows') into n;
 if n<>40 then raise exception 'Class review must retain all pupils';end if;
 if private.schoolpro_can_issue_transcript('d342eb87-8d6a-477a-a380-7fab83f586b7') then raise exception 'Coordinator cannot issue transcripts';end if;
 begin perform public.publish_schoolpro_class_results('d342eb87-8d6a-477a-a380-7fab83f586b7','be49ea13-4e43-7c75-7158-bc53bdbb7994','First Term','2025/2026');
 exception when others then denied:=true;end;
 if not denied then raise exception 'Coordinator publication must be denied';end if;
end $$;
select set_config('request.jwt.claim.sub','c19d5fbf-72df-082e-15fb-fc4f8bd19bbc',true);
do $$
declare denied boolean:=false;n integer;
begin
 if cardinality(public.schoolpro_coordinator_classes('d342eb87-8d6a-477a-a380-7fab83f586b7'))<>0 then raise exception 'Subject teacher misidentified as coordinator';end if;
 begin perform public.schoolpro_class_review_sheet('d342eb87-8d6a-477a-a380-7fab83f586b7','333ced51-b2ec-c731-c5d3-0dec3c0e3a40','First Term','2025/2026');
 exception when others then denied:=true;end;
 if not denied then raise exception 'Subject teacher received full class report';end if;
 select count(*) into n from public.schoolpro_results r where not exists(select 1 from public.schoolpro_subject_assignments a join public.schoolpro_members m on m.id=a.teacher_member_id and m.user_id=auth.uid() join public.schoolpro_enrollment_history e on e.school_id=a.school_id and e.class_id=a.class_id and e.session=a.session and e.student_id=r.student_id where a.subject_id=r.subject_id and a.session=r.session);
 if n<>0 then raise exception 'Subject teacher saw unallocated subject scores';end if;
end $$;
select set_config('request.jwt.claim.sub','77c5f330-63cd-4e6c-88e0-4b5858088925',true);
do $$ begin
 if exists(select 1 from public.schoolpro_enrollment_history where student_id<>'128e46b0-de21-ea91-dc86-d770abbff8d8') then raise exception 'Student received another pupil history';end if;
end $$;
rollback;
