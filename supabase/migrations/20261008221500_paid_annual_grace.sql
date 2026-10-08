CREATE OR REPLACE FUNCTION private.schoolpro_plan_feature_allowed(p_school uuid, p_feature text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select coalesce((select coalesce(o.enabled,coalesce((p.features->>p_feature)::boolean,false))
 from public.schoolpro_schools school
 join public.schoolpro_subscriptions s on s.school_id=school.id
 join public.schoolpro_plan_catalog p on p.tier=s.tier
 left join public.schoolpro_feature_overrides o on o.school_id=school.id and o.feature=p_feature
 where school.id=p_school and school.status::text='active' and s.status='active'
 and (s.renews_at is null or s.renews_at+case when s.amount>0 and s.billing_cycle='annual' then interval '14 days' else interval '0 days' end>now())
 and p_feature in ('website','cbt','advanced_reports','custom_branding')
 order by s.updated_at desc limit 1),false)
$function$
;

CREATE OR REPLACE FUNCTION public.schoolpro_subscription_entitlements(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare s public.schoolpro_subscriptions; p public.schoolpro_plan_catalog; base jsonb; ov jsonb; school_state public.school_status;
begin
 if auth.uid() is null or not coalesce(private.is_active_account(),false) then raise exception 'Not authorized'; end if;
 if not(public.schoolpro_member_can_manage(p_school) or exists(select 1 from public.schoolpro_members m where m.school_id=p_school and m.user_id=auth.uid()) or exists(select 1 from public.schoolpro_students st where st.school_id=p_school and st.user_id=auth.uid()) or exists(select 1 from public.schoolpro_guardian_links gl where gl.school_id=p_school and gl.guardian_user_id=auth.uid() and gl.status='active') or private.is_admin(array['super_admin']::public.user_role[])) then raise exception 'Not authorized'; end if;
 select status into school_state from public.schoolpro_schools where id=p_school;
 if school_state is distinct from 'active'::public.school_status then return jsonb_build_object('active',false,'tier','none','website',false,'cbt',false,'advanced_reports',false,'custom_branding',false,'reason','subscription_or_control_center_activation_required'); end if;
 select * into s from public.schoolpro_subscriptions where school_id=p_school order by updated_at desc limit 1;
 if s.id is null or s.status<>'active' or (s.renews_at is not null and s.renews_at+case when s.amount>0 and s.billing_cycle='annual' then interval '14 days' else interval '0 days' end<=now()) then return jsonb_build_object('active',false,'tier','none','website',false,'cbt',false,'advanced_reports',false,'custom_branding',false,'reason','active_subscription_required'); end if;
 select * into p from public.schoolpro_plan_catalog where tier=s.tier;
 base:=jsonb_build_object('active',true,'tier',s.tier,'customization_level',s.customization_level,'in_grace',s.amount>0 and s.billing_cycle='annual' and s.renews_at<=now(),'renews_at',s.renews_at,'access_ends_at',s.renews_at+case when s.amount>0 and s.billing_cycle='annual' then interval '14 days' else interval '0 days' end)||coalesce(p.features,'{}'::jsonb);
 select coalesce(jsonb_object_agg(feature,enabled),'{}'::jsonb) into ov from public.schoolpro_feature_overrides where school_id=p_school;
 return base||ov;
end $function$
;

CREATE OR REPLACE FUNCTION private.enforce_schoolpro_subscription_expiry()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare n integer;
begin
 update public.schoolpro_subscriptions set status='suspended',updated_at=now()
 where (status='trial' and renews_at is not null and renews_at<=now())
    or (status='active' and renews_at is not null and renews_at+case when amount>0 and billing_cycle='annual' then interval '14 days' else interval '0 days' end<=now());
 get diagnostics n=row_count; return n;
end $function$
;

CREATE OR REPLACE FUNCTION private.schoolpro_operationally_active(p_school uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select exists(select 1 from public.schoolpro_schools s join public.schoolpro_subscriptions b on b.school_id=s.id
 where s.id=p_school and s.status::text='active' and b.status='active' and (b.renews_at is null or b.renews_at+case when b.amount>0 and b.billing_cycle='annual' then interval '14 days' else interval '0 days' end>now()))
$function$
;
