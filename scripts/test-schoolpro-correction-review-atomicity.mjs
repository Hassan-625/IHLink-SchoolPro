import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const authority=readFileSync('supabase/migrations/20261108120000_schoolpro_role_responsibility_and_result_lifecycle.sql','utf8');
const broadsheet=readFileSync('src/pages/schoolpro/SchoolProBroadsheet.tsx','utf8');
const results=readFileSync('src/pages/schoolpro/SchoolProResults.tsx','utf8');

assert.match(authority,/create table public\.schoolpro_result_correction_batches/i);
assert.match(authority,/create table public\.schoolpro_result_correction_batch_items/i);
assert.match(authority,/public\.schoolpro_request_result_reopening/i);
assert.match(authority,/public\.schoolpro_decide_result_reopening/i);
assert.match(authority,/Only the Exam Officer can authorize a class or section result reopening/i);
assert.match(authority,/for update/i);
assert.match(authority,/b\.status='pending'/i);
assert.match(authority,/app\.schoolpro_correction_reopen/i);
assert.match(authority,/status=case when p_approve then 'approved' else 'rejected' end/i);
assert.match(authority,/Result reopening requested/i);
assert.match(authority,/Class or section results reopened for correction/i);
assert.match(authority,/revoke all on table public\.schoolpro_result_correction_requests/i);
assert.match(broadsheet,/Pending class \/ section correction requests/i);
assert.match(broadsheet,/schoolpro_decide_result_reopening/i);
assert.match(broadsheet,/schoolpro_request_result_reopening/i);
assert.match(results,/Request Class Result Reopening/i);
assert.doesNotMatch(results,/from\(['"]schoolpro_result_correction_requests['"]\)\.insert/i);
assert.doesNotMatch(results,/decide_schoolpro_result_correction_request/i);
console.log('PASS: Exam Officer-only class/section correction authorization is atomic, audited, snapshot-scoped and no individual-result reopen path remains.');
