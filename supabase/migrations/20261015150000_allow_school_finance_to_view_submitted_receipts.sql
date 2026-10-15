begin;

-- School finance must be able to inspect the exact receipt submitted for a
-- school-owned payment. Keep access tied to a real submission and finance role.
drop policy if exists "school finance read submitted payment receipts" on storage.objects;
create policy "school finance read submitted payment receipts"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'schoolpro-payment-receipts'
  and exists (
    select 1
    from public.schoolpro_payment_submissions s
    where s.receipt_path = objects.name
      and private.schoolpro_module_allowed(s.school_id, 'finance')
      and private.has_school_access(
        s.school_id,
        array['proprietor','administrator','accountant','bursar']::public.school_member_role[]
      )
  )
);

commit;
