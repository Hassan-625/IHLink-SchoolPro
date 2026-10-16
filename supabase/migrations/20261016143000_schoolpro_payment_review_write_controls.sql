-- Keep payment review state changes behind the locked SECURITY DEFINER review RPCs.
-- The generic finance-module ALL policies otherwise allow direct updates/deletes that bypass
-- pending-only review transitions and invoice/allocation reconciliation.
-- Read and guardian-submit policies remain in place; review RPCs perform privileged writes.
drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_submissions;
drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_allocations;
drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_proofs;

-- Preserve platform-wide inspection while keeping submission/allocation/proof writes behind RPCs.
drop policy if exists "Super admin read payment submissions" on public.schoolpro_payment_submissions;
create policy "Super admin read payment submissions"
  on public.schoolpro_payment_submissions for select to authenticated
  using (private.is_admin(ARRAY['super_admin']::public.user_role[]));

drop policy if exists "Super admin read payment allocations" on public.schoolpro_payment_allocations;
create policy "Super admin read payment allocations"
  on public.schoolpro_payment_allocations for select to authenticated
  using (private.is_admin(ARRAY['super_admin']::public.user_role[]));

drop policy if exists "Super admin read payment proofs" on public.schoolpro_payment_proofs;
create policy "Super admin read payment proofs"
  on public.schoolpro_payment_proofs for select to authenticated
  using (private.is_admin(ARRAY['super_admin']::public.user_role[]));

-- Fee payment ledger entries remain readable by authorized school/guardian roles and Super Admin.
-- Finance can INSERT through the explicit "School finance records payments" policy.
-- Replace both broad ALL policies with Super Admin SELECT-only access so payment records
-- cannot be silently edited/deleted outside the reviewed accounting workflows.
drop policy if exists "schoolpro_module_permission" on public.schoolpro_fee_payments;
drop policy if exists "Super admin full access schoolpro_fee_payments" on public.schoolpro_fee_payments;
drop policy if exists "Super admin read fee payments" on public.schoolpro_fee_payments;
create policy "Super admin read fee payments"
  on public.schoolpro_fee_payments for select to authenticated
  using (private.is_admin(ARRAY['super_admin']::public.user_role[]));
