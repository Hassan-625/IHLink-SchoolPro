
create policy "School staff read own membership" on public.schoolpro_members for select to authenticated using(user_id=(select auth.uid()) and private.is_active_account());
alter policy "School members guardians and corporate finance read invoices" on public.schoolpro_invoices using(private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) or private.schoolpro_owns_invoice_student(school_id,student_id));
alter policy "School members guardians and corporate finance read payments" on public.schoolpro_fee_payments using(private.has_school_access(school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) or private.schoolpro_owns_invoice_student(school_id,student_id));

create or replace function private.schoolpro_can_read_fee_structure(p_structure uuid)
returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(
 select 1 from public.schoolpro_fee_structures f where f.id=p_structure and private.schoolpro_operationally_active(f.school_id) and (
 (private.schoolpro_module_allowed(f.school_id,'finance') and private.has_school_access(f.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]))
 or exists(select 1 from public.schoolpro_invoices i where i.fee_structure_id=f.id and i.school_id=f.school_id and private.schoolpro_owns_invoice_student(i.school_id,i.student_id))));
$$;
revoke all on function private.schoolpro_can_read_fee_structure(uuid) from public,anon;
grant execute on function private.schoolpro_can_read_fee_structure(uuid) to authenticated;
alter policy "School finance reads structures" on public.schoolpro_fee_structures using(private.schoolpro_can_read_fee_structure(id));
drop policy schoolpro_module_permission on public.schoolpro_fee_structures;
create policy schoolpro_fee_structure_read_scope on public.schoolpro_fee_structures as restrictive for select to authenticated using(private.schoolpro_can_read_fee_structure(id));
create policy schoolpro_fee_structure_insert_scope on public.schoolpro_fee_structures as restrictive for insert to authenticated with check(private.schoolpro_module_allowed(school_id,'finance'));
create policy schoolpro_fee_structure_update_scope on public.schoolpro_fee_structures as restrictive for update to authenticated using(private.schoolpro_module_allowed(school_id,'finance')) with check(private.schoolpro_module_allowed(school_id,'finance'));
create policy schoolpro_fee_structure_delete_scope on public.schoolpro_fee_structures as restrictive for delete to authenticated using(private.schoolpro_module_allowed(school_id,'finance'));
drop policy "school fee item access" on public.schoolpro_fee_items;
create policy schoolpro_fee_item_read on public.schoolpro_fee_items for select to authenticated using(private.schoolpro_can_read_fee_structure(fee_structure_id));
create policy schoolpro_fee_item_insert on public.schoolpro_fee_items for insert to authenticated with check(exists(select 1 from public.schoolpro_fee_structures f where f.id=fee_structure_id and private.schoolpro_module_allowed(f.school_id,'finance') and private.has_school_access(f.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[])));
create policy schoolpro_fee_item_update on public.schoolpro_fee_items for update to authenticated using(exists(select 1 from public.schoolpro_fee_structures f where f.id=fee_structure_id and private.schoolpro_module_allowed(f.school_id,'finance') and private.has_school_access(f.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]))) with check(exists(select 1 from public.schoolpro_fee_structures f where f.id=fee_structure_id and private.schoolpro_module_allowed(f.school_id,'finance') and private.has_school_access(f.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[])));
create policy schoolpro_fee_item_delete on public.schoolpro_fee_items for delete to authenticated using(exists(select 1 from public.schoolpro_fee_structures f where f.id=fee_structure_id and private.schoolpro_module_allowed(f.school_id,'finance') and private.has_school_access(f.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[])));

