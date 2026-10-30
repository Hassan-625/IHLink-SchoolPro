-- SchoolPro does not support online/card payment. Preserve historical intents and
-- migration history, but make the legacy gateway finalizer fail closed for all callers.
create or replace function public.finalize_schoolpro_payment(
  p_reference text,
  p_gateway_transaction_id text,
  p_verified_amount numeric,
  p_status text,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception using
    errcode = '0A000',
    message = 'SchoolPro online payments are disabled; use the receipt-based payment workflow.';
end;
$$;

revoke all on function public.finalize_schoolpro_payment(text,text,numeric,text,jsonb)
  from public, anon, authenticated, service_role;

comment on function public.finalize_schoolpro_payment(text,text,numeric,text,jsonb)
  is 'Disabled by product decision on 2026-10-16: SchoolPro does not accept online/card payments. Retained as a fail-closed compatibility stub; use receipt-based workflows.';
