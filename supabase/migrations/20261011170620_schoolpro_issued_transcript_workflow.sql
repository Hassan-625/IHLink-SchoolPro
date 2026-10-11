-- Issued transcripts are immutable snapshots. Access is rechecked on every read.
create table public.schoolpro_transcript_issues (
 id uuid primary key default gen_random_uuid(), school_id uuid not null references public.schoolpro_schools(id),
 student_id uuid not null references public.schoolpro_students(id), serial_number text not null unique,
 snapshot jsonb not null, issued_by uuid not null references auth.users(id), issued_at timestamptz not null default now(),
 revoked_at timestamptz, revoked_by uuid references auth.users(id)
);
create index on public.schoolpro_transcript_issues(school_id,student_id,issued_at desc);
alter table public.schoolpro_transcript_issues enable row level security;
revoke all on public.schoolpro_transcript_issues from anon,authenticated;
grant all on public.schoolpro_transcript_issues to service_role;
create function private.schoolpro_can_issue_transcript(p_school uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and private.schoolpro_module_allowed(p_school,'results') and
 (public.schoolpro_member_can_manage(p_school) or private.has_school_access(p_school,array['head_teacher','vice_principal','exam_officer']::public.school_member_role[]))
$$;
revoke all on function private.schoolpro_can_issue_transcript(uuid) from public,anon;
grant execute on function private.schoolpro_can_issue_transcript(uuid) to authenticated;
create function private.schoolpro_issue_transcript(p_student uuid) returns uuid language plpgsql security definer set search_path='' as $$
declare s public.schoolpro_students; payload jsonb; v_id uuid:=gen_random_uuid();
begin
 select * into s from public.schoolpro_students where id=p_student for share;
 if s.id is null or not private.schoolpro_can_issue_transcript(s.school_id) then raise exception 'Only authorized school leadership or the examination officer can issue a transcript';end if;
 select jsonb_build_object('student_name',concat_ws(' ',s.first_name,s.last_name),'admission_number',s.admission_number,
 'school_name',(select name from public.schoolpro_schools where id=s.school_id),
 'records',coalesce(jsonb_agg(jsonb_build_object('session',r.session,'term',r.term,'subject',sub.name,'score',r.total_score,
 'class_name',coalesce(e.class_name,s.class_name),'arm',e.arm) order by r.session,case r.term when 'First Term' then 1 when 'Second Term' then 2 else 3 end,sub.name),'[]'::jsonb)) into payload
 from public.schoolpro_results r join public.schoolpro_subjects sub on sub.id=r.subject_id and sub.school_id=s.school_id
 left join public.schoolpro_enrollment_history e on e.school_id=s.school_id and e.student_id=s.id and e.session=r.session
 where r.school_id=s.school_id and r.student_id=s.id and r.status='published';
 if jsonb_array_length(payload->'records')=0 then raise exception 'Publish the student results before issuing a transcript';end if;
 insert into public.schoolpro_transcript_issues(id,school_id,student_id,serial_number,snapshot,issued_by)
 values(v_id,s.school_id,s.id,'SP-T-'||upper(replace(v_id::text,'-','')),payload,auth.uid());
 return v_id;
end $$;
create function public.schoolpro_issue_transcript(p_student uuid) returns uuid language sql set search_path='' as $$ select private.schoolpro_issue_transcript(p_student) $$;
create function private.schoolpro_student_transcripts(p_student uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s public.schoolpro_students;t record;p record; items jsonb:='[]'; allowed boolean; staff boolean;
begin
 select * into s from public.schoolpro_students where id=p_student;
 if auth.uid() is null or s.id is null then raise exception 'Student record unavailable';end if;
 staff:=private.schoolpro_can_issue_transcript(s.school_id);
 if not staff and not (coalesce(s.user_id=auth.uid(),false) or exists(select 1 from public.schoolpro_guardian_links g where g.student_id=s.id and g.school_id=s.school_id and g.guardian_user_id=auth.uid() and g.status='active')) then raise exception 'Student record unavailable';end if;
 for t in select * from public.schoolpro_transcript_issues where student_id=s.id and school_id=s.school_id order by issued_at desc loop
 allowed:=t.revoked_at is null;
 if allowed and not staff then
 for p in select distinct x->>'term' term,x->>'session' session from jsonb_array_elements(t.snapshot->'records') x loop
 if not coalesce((select a.allowed from private.schoolpro_result_access(s.id,p.term,p.session) a),false) then allowed:=false;exit;end if;
 end loop;
 end if;
 items:=items||jsonb_build_array(jsonb_build_object('id',t.id,'serial_number',t.serial_number,'issued_at',t.issued_at,'revoked',t.revoked_at is not null,'allowed',allowed,'snapshot',case when allowed then t.snapshot else null end));
 end loop;return items;
end $$;
create function public.schoolpro_student_transcripts(p_student uuid) returns jsonb language sql stable set search_path='' as $$ select private.schoolpro_student_transcripts(p_student) $$;
create function private.schoolpro_revoke_transcript(p_issue uuid) returns void language plpgsql security definer set search_path='' as $$
declare t public.schoolpro_transcript_issues;
begin select * into t from public.schoolpro_transcript_issues where id=p_issue for update;
 if t.id is null or not private.schoolpro_can_issue_transcript(t.school_id) then raise exception 'Not authorized';end if;
 update public.schoolpro_transcript_issues set revoked_at=coalesce(revoked_at,now()),revoked_by=coalesce(revoked_by,auth.uid()) where id=t.id;
end $$;
create function public.schoolpro_revoke_transcript(p_issue uuid) returns void language sql set search_path='' as $$ select private.schoolpro_revoke_transcript(p_issue) $$;
revoke all on function private.schoolpro_issue_transcript(uuid),private.schoolpro_student_transcripts(uuid),private.schoolpro_revoke_transcript(uuid),public.schoolpro_issue_transcript(uuid),public.schoolpro_student_transcripts(uuid),public.schoolpro_revoke_transcript(uuid) from public,anon;
grant execute on function private.schoolpro_issue_transcript(uuid),private.schoolpro_student_transcripts(uuid),private.schoolpro_revoke_transcript(uuid),public.schoolpro_issue_transcript(uuid),public.schoolpro_student_transcripts(uuid),public.schoolpro_revoke_transcript(uuid) to authenticated;

