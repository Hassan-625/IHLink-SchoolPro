-- Keep payment review state changes behind the locked SECURITY DEFINER review RPCs.
-- The generic finance-module ALL policies otherwise allow direct updates/deletes that bypass
-- pending-only review transitions and invoice/allocation reconciliation.
-- Read and guardian-submit policies remain in place; review RPCs perform privileged writes.
drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_submissions;
drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_allocations;
drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_proofs;

-- Fee payment ledger entries remain readable by authorized school/guardian roles.
-- Finance can INSERT through the explicit "School finance records payments" policy;
-- the explicit Super Admin policy is preserved, while the generic finance ALL policy is removed.
drop policy if exists "schoolpro_module_permission" on public.schoolpro_fee_payments;
