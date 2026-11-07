-- Stage C0: close direct class/member deletion and replace broad Super Admin ALL policies.
-- Apply only after the class/member lifecycle foundation and active-membership helpers.
-- This migration does not delete or modify any school, class, member, or appointment rows.

begin;

drop policy if exists "School leaders delete classes" on public.schoolpro_classes;
drop policy if exists "Super admin full access schoolpro_classes" on public.schoolpro_classes;
drop policy if exists "School leaders delete members" on public.schoolpro_members;
drop policy if exists "Super admin full access schoolpro_members" on public.schoolpro_members;

-- Super Admin access is explicit and operation-scoped; no ALL policy can
-- accidentally reintroduce DELETE. Existing school-leader policies remain.
create policy "Super admin select schoolpro_classes"
  on public.schoolpro_classes for select to authenticated
  using (private.is_admin(array['super_admin'::public.user_role]));

create policy "Super admin insert schoolpro_classes"
  on public.schoolpro_classes for insert to authenticated
  with check (private.is_admin(array['super_admin'::public.user_role]));

create policy "Super admin update schoolpro_classes"
  on public.schoolpro_classes for update to authenticated
  using (private.is_admin(array['super_admin'::public.user_role]))
  with check (private.is_admin(array['super_admin'::public.user_role]));

create policy "Super admin select schoolpro_members"
  on public.schoolpro_members for select to authenticated
  using (private.is_admin(array['super_admin'::public.user_role]));

create policy "Super admin insert schoolpro_members"
  on public.schoolpro_members for insert to authenticated
  with check (private.is_admin(array['super_admin'::public.user_role]));

create policy "Super admin update schoolpro_members"
  on public.schoolpro_members for update to authenticated
  using (private.is_admin(array['super_admin'::public.user_role]))
  with check (private.is_admin(array['super_admin'::public.user_role]));

-- RLS cannot protect against TRUNCATE. Remove both direct destructive
-- privileges from API roles. service_role/owner grants are intentionally
-- untouched; privileged lifecycle RPCs remain the supported path.
revoke delete, truncate on public.schoolpro_classes from anon, authenticated;
revoke delete, truncate on public.schoolpro_members from anon, authenticated;

commit;
