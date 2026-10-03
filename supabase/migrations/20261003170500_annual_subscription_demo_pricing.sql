-- Live production controls: annual SchoolPro billing, four-month demo window and Command Center pricing access.
create or replace function private.validate_schoolpro_demo_window() returns trigger language plpgsql set search_path='' as $$ begin if new.preferred_date is not null and (new.preferred_date < current_date or new.preferred_date > (current_date + interval '4 months')::date) then raise exception 'Demo date must be between today and four months from today'; end if; return new; end $$;
drop trigger if exists trg_schoolpro_demo_window on public.schoolpro_demo_requests;
create trigger trg_schoolpro_demo_window before insert or update of preferred_date on public.schoolpro_demo_requests for each row execute function private.validate_schoolpro_demo_window();
grant select on public.schoolpro_subscription_catalog to anon;
grant select,update on public.schoolpro_subscription_catalog to authenticated;
drop policy if exists "public read active schoolpro subscription catalog" on public.schoolpro_subscription_catalog;
create policy "public read active schoolpro subscription catalog" on public.schoolpro_subscription_catalog for select to anon using(active=true);
drop policy if exists "super admin manages schoolpro subscription pricing" on public.schoolpro_subscription_catalog;
create policy "super admin manages schoolpro subscription pricing" on public.schoolpro_subscription_catalog for update to authenticated using(private.is_admin(array['super_admin'::public.user_role])) with check(private.is_admin(array['super_admin'::public.user_role]));
