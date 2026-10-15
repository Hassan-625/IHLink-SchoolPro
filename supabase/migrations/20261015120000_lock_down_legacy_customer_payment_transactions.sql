-- Security hardening for the legacy customer payment transaction table.
-- Repository scan (204 JS/TS/JSX/TSX files) found no references to this table,
-- the client-facing payment-outcome RPC remains separately owner-scoped, and
-- inspected active BillStack functions use payment_transactions instead.
-- This migration intentionally does not delete data or alter service_role grants.
begin;

revoke all privileges on table public.customer_payment_transactions
  from public, anon, authenticated;

alter table public.customer_payment_transactions enable row level security;

comment on table public.customer_payment_transactions is
  'Legacy payment table restricted to trusted server-side access; client roles have no direct table privileges. Review dependencies before granting any future access.';

commit;
