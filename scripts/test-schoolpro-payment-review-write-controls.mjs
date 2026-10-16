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
  assert.match(
    sql,
    new RegExp('drop policy if exists "schoolpro_module_permission" on public\\.' + table),
    'The policy boundary must be explicitly rebuilt on ' + table,
  );
}
assert.equal((sql.match(/create policy "schoolpro_module_permission"/g) || []).length, 4,
  'All four payment-table module policies must be recreated explicitly');
assert.match(sql, /schoolpro_payment_submissions as restrictive for all[\s\S]*?submitted_by = \(select auth\.uid\(\)\)[\s\S]*?guardian_user_id = \(select auth\.uid\(\)\)/i,
  'Guardian-owned payment submissions must remain scoped to active guardian links');
assert.match(sql, /schoolpro_payment_allocations as restrictive for all[\s\S]*?s\.submitted_by = \(select auth\.uid\(\)\)/i,
  'Submitters retain scoped allocation reads without a direct-write grant');
assert.match(sql, /schoolpro_payment_proofs as restrictive for all[\s\S]*?g\.student_id = public\.schoolpro_payment_proofs\.student_id[\s\S]*?g\.guardian_user_id = \(select auth\.uid\(\)\)/i,
  'Guardian proof scope must bind school, student, user and active link');
assert.match(sql, /schoolpro_fee_payments as restrictive for all[\s\S]*?private\.is_admin\(ARRAY\['super_admin'\]::public\.user_role\[\]\)[\s\S]*?private\.schoolpro_module_allowed\(school_id, 'finance'\)/i,
  'Super Admin inspection and active finance scope must be explicit');
assert.match(sql, /with check \([\s\S]*?private\.schoolpro_module_allowed\(school_id, 'finance'\)[\s\S]*?and not private\.is_admin\(ARRAY\['super_admin'\]::public\.user_role\[\]\)/i,
  'Super Admin must not directly write the fee ledger');
assert.match(sql, /Super admin read payment submissions/i);
assert.match(sql, /Super admin read payment allocations/i);
assert.match(sql, /Super admin read payment proofs/i);
assert.match(sql, /drop policy if exists "Super admin full access schoolpro_fee_payments"/i);
assert.match(sql, /Super admin read fee payments/i);
assert.doesNotMatch(sql, /\b(drop table|truncate|delete from)\b/i, 'Migration must not delete payment or invoice records');

console.log('PASS: payment RLS keeps guardian submission/read scopes, preserves the finance-module gate, and restricts Super Admin to inspection.');
