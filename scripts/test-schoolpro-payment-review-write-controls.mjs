import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const path = 'supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql';
const sql = readFileSync(path, 'utf8');

for (const table of [
  'schoolpro_payment_submissions',
  'schoolpro_payment_allocations',
  'schoolpro_payment_proofs',
  'schoolpro_fee_payments',
]) {
  assert.ok(
    sql.includes('drop policy if exists "schoolpro_module_permission" on public.' + table),
    'Missing removal of broad finance ALL policy on ' + table,
  );
}
assert.match(sql, /review RPCs perform privileged writes/i);
assert.match(sql, /explicit "School finance records payments" policy/i);
assert.match(sql, /Super admin read payment submissions/i);
assert.match(sql, /Super admin read payment allocations/i);
assert.match(sql, /Super admin read payment proofs/i);
assert.match(sql, /drop policy if exists "Super admin full access schoolpro_fee_payments"/i);
assert.match(sql, /Super admin read fee payments/i);
assert.match(sql, /private\.is_admin\(ARRAY\['super_admin'\]::public\.user_role\[\]\)/i, 'Super Admin must retain read-only payment inspection');
assert.doesNotMatch(sql, /\b(drop table|truncate|delete from)\b/i, 'Migration must not delete payment or invoice records');
console.log('PASS: broad finance ALL policies are removed from payment lifecycle tables while explicit read/submit/ledger paths remain.');
