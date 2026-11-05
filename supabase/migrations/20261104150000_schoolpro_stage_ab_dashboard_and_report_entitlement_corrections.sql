-- Stage A-B correction: make Games & Sports available on every SchoolPro tier,
-- restore standard reports for all plans, and expose Games to school leadership roles.
update public.schoolpro_plan_catalog
set features = coalesce(features, '{}'::jsonb) || jsonb_build_object('games', true),
    updated_at = now()
where tier in ('starter', 'professional', 'enterprise', 'premium');

create or replace function private.schoolpro_plan_feature_allowed(p_school uuid, p_feature text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select coalesce(o.enabled, coalesce((p.features->>p_feature)::boolean, false))
    from public.schoolpro_schools school
    join public.schoolpro_subscriptions s on s.school_id = school.id
    join public.schoolpro_plan_catalog p on p.tier = s.tier
    left join public.schoolpro_feature_overrides o
      on o.school_id = school.id and o.feature = p_feature
    where school.id = p_school
      and school.status::text = 'active'
      and s.status = 'active'
      and (s.renews_at is null or s.renews_at + case
        when s.amount > 0 and s.billing_cycle = 'annual' then interval '14 days'
        else interval '0 days' end > now())
      and p_feature in ('website', 'cbt', 'advanced_reports', 'custom_branding', 'games')
    order by s.updated_at desc
    limit 1
  ), false)
$$;

revoke all on function private.schoolpro_plan_feature_allowed(uuid, text) from public;
grant execute on function private.schoolpro_plan_feature_allowed(uuid, text) to authenticated;

-- 'reports' is the standard academic reporting permission. Enterprise analytics
-- are separately protected by the advanced_reports entitlement at their routes/APIs.
-- This keeps report cards, standard broadsheets and ordinary class exports available
-- to Starter and Professional schools.
create or replace function private.schoolpro_module_allowed(target_school uuid, required_permission text)
returns boolean
language sql
stable
set search_path = ''
as $$
  select auth.uid() is not null
    and coalesce(private.is_active_account(), false)
    and private.schoolpro_operationally_active(target_school)
    and required_permission = any(public.schoolpro_user_permissions(target_school))
    and (
      private.is_admin(array['super_admin']::public.user_role[])
      or case required_permission
        when 'cbt' then private.schoolpro_plan_feature_allowed(target_school, 'cbt')
        when 'branding' then private.schoolpro_plan_feature_allowed(target_school, 'custom_branding')
        when 'games' then private.schoolpro_plan_feature_allowed(target_school, 'games')
        else true
      end
    )
$$;

-- Leadership roles must be able to reach the Games module. Game Master already
-- receives this permission; this adds it to board administrators, principals,
-- school owners and school administrators without widening other specialist roles.
do $$
declare
  definition text;
  needle text := $needle$'discipline','medical'$needle$;
  replacement text := $replacement$'discipline','games','medical'$replacement$;
begin
  select pg_get_functiondef('public.schoolpro_user_permissions(uuid)'::regprocedure)
    into strict definition;
  if strpos(definition, needle) = 0 then
    raise exception 'Expected leadership permission arrays were not found';
  end if;
  definition := replace(definition, needle, replacement);
  execute definition;
end
$$;

comment on function private.schoolpro_module_allowed(uuid, text) is
  'Checks school operational status, role permission and tier entitlements. Standard reports are role-controlled; advanced analytics use the separate advanced_reports entitlement.';
