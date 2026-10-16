-- Enforce receipt upload restrictions at the Storage service, not only in the browser input.
-- Keep the bucket private; receipts contain payer and financial information.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'schoolpro-payment-receipts',
  'schoolpro-payment-receipts',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']::text[]
)
on conflict (id) do update
set name = excluded.name,
    public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

