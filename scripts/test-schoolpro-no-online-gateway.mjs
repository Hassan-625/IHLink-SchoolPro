import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const disableSql = readFileSync('supabase/migrations/20261016170000_schoolpro_disable_online_payment_gateway.sql', 'utf8');
const subscriptionUi = readFileSync('src/pages/schoolpro/SchoolProSubscription.tsx', 'utf8');
const schoolFeeUi = readFileSync('src/pages/schoolpro/SchoolProPayments.tsx', 'utf8');
const onlineMigration = readFileSync('supabase/migrations/20260920212500_schoolpro_online_fee_payments.sql', 'utf8');
const receiptStorageMigration = readFileSync('supabase/migrations/20261016180000_schoolpro_payment_receipt_storage_limits.sql', 'utf8');

assert.match(disableSql, /raise exception[\s\S]*SchoolPro online payments are disabled/i,
  'The legacy online finalizer must fail closed');
assert.match(disableSql, /revoke all on function public\.finalize_schoolpro_payment\([\s\S]*from public, anon, authenticated, service_role/i,
  'No API role, including service_role, may execute the legacy online finalizer');
assert.match(disableSql, /comment on function[\s\S]*receipt-based workflows/i,
  'The retained function must explain the product decision and supported alternative');

// Preserve receipt-based subscription and school-fee workflows; they are not online checkout.
assert.match(subscriptionUi, /prepare_schoolpro_bank_subscription/,
  'School subscriptions must prepare bank-transfer instructions');
assert.match(subscriptionUi, /payment_method","bank_transfer"/,
  'School subscription records must be receipt/bank-transfer based');
assert.match(subscriptionUi, /<BankTransferPayments[^>]*platform="schoolpro_subscription"/,
  'School subscription UI must continue to use the receipt submission component');
assert.match(schoolFeeUi, /schoolpro-payment-receipts/,
  'School-fee payments must keep the receipt upload workflow');
assert.match(schoolFeeUi, /submit_schoolpro_payment/,
  'School-fee receipt submissions must continue through the reviewed RPC');

// Keep the historical migration immutable; the forward migration disables its RPC instead.
assert.match(onlineMigration, /gateway text not null default 'flutterwave'/i,
  'The original migration is retained as historical provenance');

assert.match(receiptStorageMigration, /'schoolpro-payment-receipts'[\s\S]*false[\s\S]*5242880/i,
  'Payment receipt storage must remain private and capped at the production-observed 5 MiB');
for (const mime of ['image/jpeg', 'image/png', 'image/webp', 'application/pdf']) {
  assert.ok(receiptStorageMigration.includes(mime), `Receipt storage must allow ${mime}`);
}
assert.match(receiptStorageMigration, /on conflict \(id\) do update[\s\S]*allowed_mime_types = excluded\.allowed_mime_types/i,
  'Existing receipt bucket settings must be brought into compliance by the forward migration');

console.log('PASS: legacy online finalizer is disabled in the forward migration and receipt-based SchoolPro workflows remain present (static source checks only).');
