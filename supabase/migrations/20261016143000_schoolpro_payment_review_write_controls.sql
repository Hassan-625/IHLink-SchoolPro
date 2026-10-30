-- Preserve the finance-module gate without relying on permissive-policy assumptions.
-- These policies are restrictive: they do not grant access on their own. Rebuild the scope
-- explicitly so guardian-owned submissions remain usable and Super Admin inspection stays
-- read-only, while review mutations continue through the locked SECURITY DEFINER RPC.
-- Submission rows must be created through submit_schoolpro_payment so receipt ownership,
-- allocation totals and invoice locks cannot be bypassed with a direct REST insert.
drop policy if exists "guardian inserts submissions" on public.schoolpro_payment_submissions;
revoke insert on table public.schoolpro_payment_submissions from authenticated;

drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_submissions;
create policy "schoolpro_module_permission"
  on public.schoolpro_payment_submissions as restrictive for all to authenticated
  using (
    private.is_admin(ARRAY['super_admin']::public.user_role[])
    or private.schoolpro_module_allowed(school_id, 'finance')
    or submitted_by = (select auth.uid())
  )
  with check (
    private.schoolpro_module_allowed(school_id, 'finance')
    or (
      submitted_by = (select auth.uid())
      and status = 'pending'
      and exists (
        select 1 from public.schoolpro_guardian_links g
        where g.school_id = public.schoolpro_payment_submissions.school_id
          and g.guardian_user_id = (select auth.uid())
          and g.status = 'active'
      )
    )
  );

drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_allocations;
create policy "schoolpro_module_permission"
  on public.schoolpro_payment_allocations as restrictive for all to authenticated
  using (
    private.is_admin(ARRAY['super_admin']::public.user_role[])
    or private.schoolpro_module_allowed(school_id, 'finance')
    or exists (
      select 1 from public.schoolpro_payment_submissions s
      where s.id = public.schoolpro_payment_allocations.submission_id
        and s.submitted_by = (select auth.uid())
    )
  )
  with check (private.schoolpro_module_allowed(school_id, 'finance'));

-- Legacy proof rows also require an uploaded receipt owned by the submitting guardian.
drop policy if exists "guardian submits proof" on public.schoolpro_payment_proofs;
create policy "guardian submits proof"
  on public.schoolpro_payment_proofs for insert to authenticated
  with check (
    submitted_by = (select auth.uid())
    and receipt_path is not null
    and split_part(receipt_path, '/', 1) = (select auth.uid())::text
    and exists (
      select 1 from storage.objects o
      where o.bucket_id = 'schoolpro-payment-receipts'
        and o.name = public.schoolpro_payment_proofs.receipt_path
        and coalesce(o.owner_id, o.owner::text) = (select auth.uid())::text
    )
    and exists (
      select 1 from public.schoolpro_guardian_links g
      where g.school_id = public.schoolpro_payment_proofs.school_id
        and g.student_id = public.schoolpro_payment_proofs.student_id
        and g.guardian_user_id = (select auth.uid())
        and g.status = 'active'
    )
  );

drop policy if exists "schoolpro_module_permission" on public.schoolpro_payment_proofs;
create policy "schoolpro_module_permission"
  on public.schoolpro_payment_proofs as restrictive for all to authenticated
  using (
    private.is_admin(ARRAY['super_admin']::public.user_role[])
    or private.schoolpro_module_allowed(school_id, 'finance')
    or submitted_by = (select auth.uid())
  )
  with check (
    private.schoolpro_module_allowed(school_id, 'finance')
    or (
      submitted_by = (select auth.uid())
      and exists (
        select 1 from public.schoolpro_guardian_links g
        where g.school_id = public.schoolpro_payment_proofs.school_id
          and g.student_id = public.schoolpro_payment_proofs.student_id
          and g.guardian_user_id = (select auth.uid())
          and g.status = 'active'
      )
    )
  );

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
create policy "schoolpro_module_permission"
  on public.schoolpro_fee_payments as restrictive for all to authenticated
  using (
    private.is_admin(ARRAY['super_admin']::public.user_role[])
    or private.schoolpro_module_allowed(school_id, 'finance')
    or exists (
      select 1 from public.schoolpro_guardian_links g
      where g.school_id = public.schoolpro_fee_payments.school_id
        and g.student_id = public.schoolpro_fee_payments.student_id
        and g.guardian_user_id = (select auth.uid())
        and g.status = 'active'
    )
  )
  with check (
    private.schoolpro_module_allowed(school_id, 'finance')
    and not private.is_admin(ARRAY['super_admin']::public.user_role[])
  );

drop policy if exists "Super admin full access schoolpro_fee_payments" on public.schoolpro_fee_payments;
drop policy if exists "Super admin read fee payments" on public.schoolpro_fee_payments;
create policy "Super admin read fee payments"
  on public.schoolpro_fee_payments for select to authenticated
  using (private.is_admin(ARRAY['super_admin']::public.user_role[]));


-- These financial tables are never a public/anonymous REST surface. RLS remains the
-- row-level boundary for authenticated users; remove the unnecessary anonymous table grants.
revoke all privileges on table
  public.schoolpro_invoices,
  public.schoolpro_payment_allocations,
  public.schoolpro_payment_proofs,
  public.schoolpro_payment_submissions,
  public.schoolpro_fee_payments
from public, anon;
