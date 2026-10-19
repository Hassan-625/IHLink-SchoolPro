create or replace function public.list_available_schoolpro_cbts()
returns table(id uuid,title text,instructions text,duration_minutes integer,total_marks numeric,opens_at timestamptz,closes_at timestamptz,attempts_allowed integer,attempts_used bigint,eligible boolean)
language sql stable security definer set search_path=public as $$
with me as (select s.* from schoolpro_students s where s.user_id=auth.uid() and s.status='active' limit 1)
select t.id,t.title,t.instructions,t.duration_minutes,t.total_marks,t.opens_at,t.closes_at,t.attempts_allowed,
 (select count(*) from schoolpro_cbt_attempts a where a.test_id=t.id and a.student_id=me.id) attempts_used,
 ((not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.eligible=true)
 or exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.eligible=true and (e.student_id=me.id or e.class_id=me.class_id)))
 and not exists(select 1 from schoolpro_cbt_eligibility e where e.test_id=t.id and e.student_id=me.id and e.eligible=false)) eligible
from me join schoolpro_cbt_tests t on t.school_id=me.school_id
where t.status='published' order by coalesce(t.opens_at,t.created_at) desc;
$$;
revoke all on function public.list_available_schoolpro_cbts() from public,anon;
grant execute on function public.list_available_schoolpro_cbts() to authenticated;