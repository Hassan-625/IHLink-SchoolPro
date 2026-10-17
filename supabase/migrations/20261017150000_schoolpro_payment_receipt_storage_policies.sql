-- Keep receipt Storage access controls in migration history as well as the live database.
-- Receipt objects are private and stored under the authenticated uploader's user ID.
-- School-finance access is granted only for a receipt linked to a payment-proof row
-- for a school where the caller has one of the approved finance/leadership roles.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'schoolpro-payment-receipts',
  'schoolpro-payment-receipts',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']::text[]
)
on conflict (id) do update
set name = excluded.name,
    public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "guardian upload payment receipts" on storage.objects;
create policy "guardian upload payment receipts"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'schoolpro-payment-receipts'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "guardian read own payment receipts" on storage.objects;
create policy "guardian read own payment receipts"
on storage.objects for select to authenticated
using (
  bucket_id = 'schoolpro-payment-receipts'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "school finance read payment receipts" on storage.objects;
create policy "school finance read payment receipts"
on storage.objects for select to authenticated
using (
  bucket_id = 'schoolpro-payment-receipts'
  and (
    exists (
    select 1
    from public.schoolpro_payment_proofs p
    where p.receipt_path = objects.name
      and private.has_school_access(
        p.school_id,
        array[
          'proprietor'::public.school_member_role,
          'administrator'::public.school_member_role,
          'accountant'::public.school_member_role,
          'bursar'::public.school_member_role
        ]
      )
    )
    or exists (
    select 1
    from public.schoolpro_payment_submissions s
    where s.receipt_path = objects.name
      and private.has_school_access(
        s.school_id,
        array[
          'proprietor'::public.school_member_role,
          'administrator'::public.school_member_role,
          'accountant'::public.school_member_role,
          'bursar'::public.school_member_role
        ]
      )
    )
  )
);
