import { readFileSync } from "node:fs";
import assert from "node:assert/strict";

const read = (path) => readFileSync(path, "utf8");
const fees = read("src/pages/schoolpro/SchoolProFees.tsx");
const parentPayments = read("src/pages/schoolpro/SchoolProPayments.tsx");
const subscription = read("src/pages/schoolpro/SchoolProSubscription.tsx");
const transfer = read("src/components/BankTransferPayments.tsx");
const schoolPaymentFunction = read("supabase/functions/schoolpro-payment/index.ts");
const checks = [];

function check(name, fn) {
  fn();
  checks.push(name);
}

check("SchoolPro parent fee receipt upload uses a private storage path and no overwrite", () => {
  assert.match(parentPayments, /schoolpro-payment-receipts'\)\.upload\(path,file,\{contentType:file\.type,upsert:false\}\)/);
  assert.match(parentPayments, /submit_schoolpro_payment/);
  assert.match(parentPayments, /Receipt submitted for school finance review/);
});

check("School fee receipt approval and rejection use a server-side review RPC", () => {
  assert.match(fees, /review_schoolpro_payment_submission/);
  assert.match(fees, /p_decision:decision/);
  assert.match(fees, /reviewProof\(x\.id,"rejected"\)/);
  assert.match(fees, /reviewProof\(x\.id,"confirmed"\)/);
});

check("School fee correction records a manual payment through the payment RPC", () => {
  assert.match(fees, /record_schoolpro_payment/);
  assert.match(fees, /Manually confirmed by bursar or proprietor/);
});

check("Subscription selection prepares bank-transfer instructions, not online checkout", () => {
  assert.match(subscription, /prepare_schoolpro_bank_subscription/);
  assert.match(subscription, /BankTransferPayments[^;]*platform="schoolpro_subscription"/);
  assert.match(subscription, /Finance verification activates or renews the subscription/);
});

check("Shared receipt submission validates file type and size and does not activate service on upload", () => {
  assert.match(transfer, /file\.size>5\*1024\*1024/);
  assert.match(transfer, /submit_service_bank_transfer/);
  assert.match(transfer, /the service has not been activated by this upload/);
});

check("SchoolPro payment Edge Function does not initialize BillStack or online payment checkout", () => {
  assert.doesNotMatch(schoolPaymentFunction, /billstack|flutterwave|stripe|createCheckout|checkout_url/i);
  assert.match(schoolPaymentFunction, /guardian_links/);
  assert.match(schoolPaymentFunction, /schoolpro_bank_accounts/);
});

console.log("SchoolPro receipt/payment contract checks passed:");
for (const name of checks) console.log("- " + name);
