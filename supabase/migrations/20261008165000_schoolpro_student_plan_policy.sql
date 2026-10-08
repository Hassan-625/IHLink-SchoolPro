-- Resolve plan checks inside private helpers, so student policies do not depend on staff-only test SELECT policies.
create or replace function private.schoolpro_cbt_test_plan_allowed(p_test uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select coalesce(private.is_active_account(),false) and exists(select 1 from public.schoolpro_cbt_tests t where t.id=p_test and (private.schoolpro_plan_feature_allowed(t.school_id,'cbt') or private.schoolpro_module_allowed(t.school_id,'cbt')))
$$;
create or replace function private.schoolpro_cbt_answer_plan_allowed(p_attempt uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.schoolpro_cbt_attempts a where a.id=p_attempt and private.schoolpro_cbt_test_plan_allowed(a.test_id))
$$;
revoke all on function private.schoolpro_cbt_test_plan_allowed(uuid),private.schoolpro_cbt_answer_plan_allowed(uuid) from public;
grant execute on function private.schoolpro_cbt_test_plan_allowed(uuid),private.schoolpro_cbt_answer_plan_allowed(uuid) to authenticated;
alter policy schoolpro_plan_attempts on public.schoolpro_cbt_attempts using (private.schoolpro_cbt_test_plan_allowed(test_id)) with check (private.schoolpro_cbt_test_plan_allowed(test_id));
alter policy schoolpro_plan_answers on public.schoolpro_cbt_answers using (private.schoolpro_cbt_answer_plan_allowed(attempt_id)) with check (private.schoolpro_cbt_answer_plan_allowed(attempt_id));
