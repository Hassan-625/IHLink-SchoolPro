import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migration = readFileSync(
  'supabase/migrations/20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql',
  'utf8',
);

assert.match(migration, /security definer[\s\S]*?set search_path to ''/i,
  'Public RPC must remain SECURITY DEFINER with an empty search_path');
assert.match(migration, /is_published\s*=\s*true[\s\S]*?admissions_open\s*=\s*true/i,
  'Applications must only be accepted while admissions are published and open');
for (const [field, limit] of [
  ['v_first', 80], ['v_last', 80], ['v_guardian', 120],
  ['v_class', 80], ['v_previous', 160], ['v_phone', 32], ['v_email', 254],
]) {
  assert.match(migration, new RegExp('length\\(' + field + '\\) > ' + limit),
    'Must cap ' + field + ' at ' + limit + ' characters');
}
assert.match(migration, /v_phone_digits\) < 7[\s\S]*?v_phone_digits\) > 15/i,
  'Phone must be constrained to 7–15 digits after normalization');
assert.match(migration, /v_email !~ '[^\n]*@/i, 'Provided email must be format-validated');
assert.match(migration, /p_dob > current_date[\s\S]*?date '1900-01-01'/i,
  'Date of birth must not be in the future or outside the supported range');
assert.match(migration, /pg_advisory_xact_lock[\s\S]*?v_phone_lock[\s\S]*?v_email_lock/i,
  'Per-school normalized phone and email locks must serialize concurrent requests');
assert.match(migration, /interval '1 hour'[\s\S]*?>= 3/i,
  'At most three submissions per normalized contact are allowed per rolling hour');
assert.match(migration, /interval '24 hours'[\s\S]*?>= 5/i,
  'At most five submissions per normalized contact are allowed per rolling day');
assert.doesNotMatch(migration, /x-forwarded-for|x-real-ip|cf-connecting-ip/i,
  'Do not trust caller-controlled network headers for the database rate-limit key');
assert.match(migration, /return jsonb_build_object\([\s\S]*?'application_id'[\s\S]*?'application_number'[\s\S]*?'public_token'/i,
  'Preserve the public application response contract');

console.log('PASS: public admissions RPC has strict field validation and serialized contact-based abuse limits.');
