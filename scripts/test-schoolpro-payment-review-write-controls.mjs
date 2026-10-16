import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const path = 'supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql';
const sql = readFileSync(path, 'utf8');

for (const table of [
  'schoolpro_payment_submissions',
  'schoolpro_payment_allocations',
  'schoolpro_payment_proofs',
]) {
  assert.doesNotMatch(
    sql,
    new RegExp('drop policy if exists "schoolpro_module_permission" on public\\.' + table),
    'The existing restrictive finance-module policy must remain on ' + table,
  );
}
assert.match(sql, /drop policy if exists "schoolpro_module_permission" on public\.schoolpro_fee_payments/i);
assert.match(sql, /create policy "schoolpro_module_permission"[\s\S]*?as restrictive for all to authenticated/i, 'Fee ledger policy must remain restrictive');
assert.match(sql, /using \([\s\S]*?private\.is_admin\(ARRAY\['super_admin'\]::public\.user_role\[\]\)[\s\S]*?private\.schoolpro_module_allowed\(school_id, 'finance'\)/i, 'Super Admin inspection and active finance scope must be explicit');
assert.match(sql, /with check \([\s\S]*?private\.schoolpro_module_allowed\(school_id, 'finance'\)[\s\S]*?and not private\.is_admin\(ARRAY\['super_admin'\]::public\.user_role\[\]\)/i, 'Super Admin must not directly write the fee ledger');
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
