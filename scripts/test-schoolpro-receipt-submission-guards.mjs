import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const path = 'supabase/migrations/20261015203000_schoolpro_payment_receipt_tenant_guard.sql';
const sql = readFileSync(path, 'utf8');

assert.match(sql, /if v_user is null then[\s\S]*?raise exception 'Authentication required'/i,
  'Receipt submission must require an authenticated user');
assert.match(sql, /split_part\(p_receipt_path,'\/',1\)<>v_user::text[\s\S]*?from storage\.objects o[\s\S]*?o\.bucket_id='schoolpro-payment-receipts'[\s\S]*?o\.name=p_receipt_path[\s\S]*?coalesce\(o\.owner_id,o\.owner::text\)=v_user::text/i,
  'Receipt path must resolve to an object in the receipt bucket owned by the caller');
assert.match(sql, /jsonb_array_length\(p_allocations\)=0[\s\S]*?raise exception 'Payment amount and allocations are required'/i,
  'At least one invoice allocation is required');
assert.match(sql, /group by x->>'invoice_id' having count\(\)>1[\s\S]*?Each invoice may appear only once/i,
  'Duplicate invoice allocations must be rejected');
assert.match(sql, /g\.school_id=p_school and g\.guardian_user_id=v_user and g\.status='active'/i,
  'Caller must have an active guardian link for the selected school');
assert.match(sql, /b\.id=p_bank_account and b\.school_id=p_school and b\.active/i,
  'Selected bank account must belong to the same school and be active');
assert.match(sql, /where id=\(a->>'invoice_id'\)::uuid and school_id=p_school[\s\S]*?for update/i,
  'Invoice must be selected within the requested school and locked');
assert.match(sql, /g\.school_id=p_school and g\.student_id=inv\.student_id[\s\S]*?g\.guardian_user_id=v_user and g\.status='active'/i,
  'Each allocated invoice must belong to a student linked to the submitting guardian');
assert.match(sql, /join public\.schoolpro_payment_submissions ps on ps\.id=pa\.submission_id[\s\S]*?ps\.status='pending'/i,
  'Pending allocations must be counted when calculating available invoice balance');
assert.match(sql, /order by \(value->>'invoice_id'\)::uuid loop/i,
  'Multi-invoice locking must use deterministic invoice order');
assert.match(sql, /if sum_alloc<>p_total then[\s\S]*?Allocated amount must equal payment total/i,
  'Allocation sum must exactly equal declared payment total');
assert.match(sql, /revoke all on function public\.submit_schoolpro_payment[\s\S]*?from public,anon[\s\S]*?grant execute on function public\.submit_schoolpro_payment[\s\S]*?to authenticated/i,
  'Submission RPC must not be executable by anonymous or public roles');

console.log('PASS: receipt submission source guards cover authentication, owned receipt objects, same-school guardian/invoice relationships, deterministic invoice locks, pending reservations, and amount reconciliation.');
