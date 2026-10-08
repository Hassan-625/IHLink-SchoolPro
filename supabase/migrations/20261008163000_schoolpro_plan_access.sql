-- Plan access is additional to school membership and module permissions.
create or replace function private.schoolpro_plan_feature_allowed(p_school uuid,p_feature text)
returns boolean language sql stable security definer set search_path='' as $$
 select coalesce((select coalesce(o.enabled,coalesce((p.features->>p_feature)::boolean,false))
 from public.schoolpro_schools school
 join public.schoolpro_subscriptions s on s.school_id=school.id
 join public.schoolpro_plan_catalog p on p.tier=s.tier
 left join public.schoolpro_feature_overrides o on o.school_id=school.id and o.feature=p_feature
 where school.id=p_school and school.status::text='active' and s.status='active'
 and (s.renews_at is null or s.renews_at>now())
 and p_feature in ('website','cbt','advanced_reports','custom_branding')
 order by s.updated_at desc limit 1),false)
$$;
revoke all on function private.schoolpro_plan_feature_allowed(uuid,text) from public;
grant execute on function private.schoolpro_plan_feature_allowed(uuid,text) to authenticated;
create or replace function private.schoolpro_module_allowed(target_school uuid,required_permission text)
returns boolean language sql stable set search_path='' as $$
 select auth.uid() is not null and coalesce(private.is_active_account(),false)
 and private.schoolpro_operationally_active(target_school)
 and required_permission=any(public.schoolpro_user_permissions(target_school))
 and (private.is_admin(array['super_admin']::public.user_role[])
 or case required_permission
 when 'cbt' then private.schoolpro_plan_feature_allowed(target_school,'cbt')
 when 'reports' then private.schoolpro_plan_feature_allowed(target_school,'advanced_reports')
 when 'branding' then private.schoolpro_plan_feature_allowed(target_school,'custom_branding')
 else true end)
$$;
-- Restrictive policies close permissive-policy alternatives without changing membership rules.
do $$
declare t text;
begin
 foreach t in array array['schoolpro_cbt_tests','schoolpro_cbt_test_questions','schoolpro_cbt_answers','schoolpro_cbt_attempts','schoolpro_cbt_eligibility','schoolpro_question_bank'] loop
  if t in ('schoolpro_cbt_tests','schoolpro_cbt_eligibility','schoolpro_question_bank') then
   execute format('create policy schoolpro_plan_access on public.%I as restrictive for all to authenticated using (private.schoolpro_module_allowed(school_id,''cbt'') or (coalesce(private.is_active_account(),false) and private.schoolpro_plan_feature_allowed(school_id,''cbt''))) with check (private.schoolpro_module_allowed(school_id,''cbt'') or (coalesce(private.is_active_account(),false) and private.schoolpro_plan_feature_allowed(school_id,''cbt'')))',t);
  end if;
 end loop;
end $$;
create policy schoolpro_plan_branding_insert on public.schoolpro_branding as restrictive for insert to authenticated with check (private.schoolpro_module_allowed(school_id,'branding'));
create policy schoolpro_plan_branding_update on public.schoolpro_branding as restrictive for update to authenticated using (private.schoolpro_module_allowed(school_id,'branding')) with check (private.schoolpro_module_allowed(school_id,'branding'));
create policy schoolpro_plan_branding_delete on public.schoolpro_branding as restrictive for delete to authenticated using (private.schoolpro_module_allowed(school_id,'branding'));
-- These functions bypass RLS, so they need their own plan guards, including token-based exams.
do $$
declare name text; signature text; definition text; anchor text; replacement text;
begin
 foreach name in array array['start_schoolpro_cbt','save_schoolpro_cbt_answer','submit_schoolpro_cbt','assign_schoolpro_entrance_cbt','get_candidate_cbt','save_candidate_cbt_answer','submit_candidate_cbt'] loop
  select p.oid::regprocedure::text,pg_get_functiondef(p.oid) into strict signature,definition from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname=name;
  anchor:=case when name='assign_schoolpro_entrance_cbt' then 'if a.id is null or t.id is null then' else 'if t.id is null' end;
  replacement:='if not private.schoolpro_plan_feature_allowed(t.school_id,''cbt'') then raise exception ''Online examinations are not available on this school subscription''; end if; '||anchor;
  if position(anchor in definition)=0 then raise exception 'Missing plan guard anchor in %',signature; end if;
  execute replace(definition,anchor,replacement);
 end loop;
 select pg_get_functiondef(p.oid) into strict definition from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='list_available_schoolpro_cbts';
 execute replace(definition,'where t.status=''published''','where private.schoolpro_plan_feature_allowed(t.school_id,''cbt'') and coalesce(private.is_active_account(),false) and t.status=''published''');
 select pg_get_functiondef(p.oid) into strict definition from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='schoolpro_cbt_is_eligible';
 execute replace(definition,'where t.id=p_test','where private.schoolpro_plan_feature_allowed(t.school_id,''cbt'') and coalesce(private.is_active_account(),false) and t.id=p_test');
end $$;

create policy schoolpro_plan_attempts on public.schoolpro_cbt_attempts as restrictive for all to authenticated
using (coalesce(private.is_active_account(),false) and exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id and (private.schoolpro_plan_feature_allowed(t.school_id,'cbt') or private.schoolpro_module_allowed(t.school_id,'cbt'))))
with check (coalesce(private.is_active_account(),false) and exists(select 1 from public.schoolpro_cbt_tests t where t.id=test_id and (private.schoolpro_plan_feature_allowed(t.school_id,'cbt') or private.schoolpro_module_allowed(t.school_id,'cbt'))));
create policy schoolpro_plan_answers on public.schoolpro_cbt_answers as restrictive for all to authenticated
using (coalesce(private.is_active_account(),false) and exists(select 1 from public.schoolpro_cbt_attempts a join public.schoolpro_cbt_tests t on t.id=a.test_id where a.id=attempt_id and (private.schoolpro_plan_feature_allowed(t.school_id,'cbt') or private.schoolpro_module_allowed(t.school_id,'cbt'))))
with check (coalesce(private.is_active_account(),false) and exists(select 1 from public.schoolpro_cbt_attempts a join public.schoolpro_cbt_tests t on t.id=a.test_id where a.id=attempt_id and (private.schoolpro_plan_feature_allowed(t.school_id,'cbt') or private.schoolpro_module_allowed(t.school_id,'cbt'))));
