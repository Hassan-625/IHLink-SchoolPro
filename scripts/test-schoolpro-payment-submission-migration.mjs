import { readFileSync } from "node:fs";
import assert from "node:assert/strict";

const migration = readFileSync(
  "supabase/migrations/20261015143000_harden_schoolpro_payment_receipt_submission.sql",
  "utf8"
);
const checks = [
  ["rejects unauthenticated RPC calls", /if auth\.uid\(\) is null then\s+raise exception 'Authentication required'/i],
  ["limits receipt path to caller-owned folder", /p_receipt_path !~ \('\^' \|\| auth\.uid\(\)::text \|\| '\/\[A-Za-z0-9\._-\]\+\$'\)/i],
  ["requires an object in the private SchoolPro receipt bucket", /bucket_id = 'schoolpro-payment-receipts'[\s\S]*?o\.name = p_receipt_path/i],
  ["checks uploaded MIME metadata matches the declared MIME", /receipt\.metadata->>'mimetype' is distinct from p_receipt_mime/i],
  ["enforces the 5 MiB upload ceiling", /receipt\.metadata->>'size'[\s\S]*?> 5242880/i],
  ["rejects duplicate invoice allocations", /group by \(x->>'invoice_id'\)\s+having count\(\*\) > 1/i],
  ["locks requested invoices in deterministic order", /order by i\.id\s+for update of i/i],
  ["reserves balances already covered by pending submissions", /ps\.status = 'pending'[\s\S]*?inv\.amount_due - inv\.amount_paid - pending_alloc/i],
  ["validates active guardian link for each invoice student", /g\.student_id = inv\.student_id[\s\S]*?g\.guardian_user_id = auth\.uid\(\)[\s\S]*?g\.status = 'active'/i],
  ["requires allocation total to equal receipt total", /if sum_alloc <> p_total then/i],
  ["restricts RPC execution to authenticated callers", /revoke all on function public\.submit_schoolpro_payment[\s\S]*?from public, anon;[\s\S]*?grant execute on function public\.submit_schoolpro_payment[\s\S]*?to authenticated;/i],
];

for (const [name, pattern] of checks) {
  assert.match(migration, pattern, "Missing contract: " + name);
}
assert.match(migration, /begin;[\s\S]*?commit;/i, "Migration must be transactional");
console.log("SchoolPro receipt submission migration contract checks passed:");
for (const [name] of checks) console.log("- " + name);
console.log("- migration is transactional");
