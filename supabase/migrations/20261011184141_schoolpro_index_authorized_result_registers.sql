create index if not exists schoolpro_results_student_session_term_idx on public.schoolpro_results(student_id,session,term);
create policy "Result student scope" on public.schoolpro_results as restrictive for select to authenticated using(student_id=any((select private.schoolpro_cached_readable_students())::uuid[]));
alter policy "Result access gate" on public.schoolpro_results using((select private.is_active_account()) and case when school_id=any((select private.schoolpro_cached_access_schools('results','result-leader'))::uuid[]) then true else (school_id=any((select private.schoolpro_cached_staff_schools())::uuid[]) or coalesce((select a.allowed from private.schoolpro_result_access(student_id,term,session) a),false)) end);
alter policy "Result reader access" on public.schoolpro_results using(case when school_id=any((select private.schoolpro_cached_access_schools('results','result-leader'))::uuid[]) then true else (
(select private.schoolpro_cached_result_reader_keys()) ? (student_id::text||'|'||subject_id::text||'|'||session)
or (select private.schoolpro_cached_result_reader_keys()) ? (student_id::text||'|*|'||session)
or (select private.schoolpro_cached_result_reader_keys()) ? (student_id::text||'|*|*')
or (status='published' and locked and (select private.schoolpro_cached_result_reader_keys()) ? (student_id::text||'|family'))
) end);
