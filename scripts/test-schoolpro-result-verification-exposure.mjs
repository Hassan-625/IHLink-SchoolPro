import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migration = readFileSync(
  'supabase/migrations/20261017120000_schoolpro_result_verification_minimal_snapshot.sql',
  'utf8',
);
const publicVerifier = readFileSync(
  'supabase/migrations/20261002213000_harden_document_verification.sql',
  'utf8',
);
const ui = readFileSync('src/pages/schoolpro/SchoolProResultChecker.tsx', 'utf8');

assert.match(migration, /security definer[\s\S]*?set search_path to ''/i,
  'Issuer must remain SECURITY DEFINER with an empty search_path');
assert.match(migration, /if auth\.uid\(\) is null then[\s\S]*?Authentication required/i,
  'Issuing a public verification code must require authentication');
assert.match(migration, /private\.schoolpro_module_allowed\(st\.school_id,\s*'results'\)/i,
  'Issuer must enforce the school results module');
assert.match(migration, /private\.has_school_access\([\s\S]*?'exam_officer'::public\.school_member_role/i,
  'Issuer must enforce a school-scoped allowed role or platform admin');
assert.match(migration, /r\.status = 'published'[\s\S]*?r\.locked = true/i,
  'Only locked published result rows can be snapshotted');
assert.match(migration, /jsonb_build_object\([\s\S]*?'total',[\s\S]*?'average'/i,
  'Snapshot must match the public verification page summary contract');
assert.doesNotMatch(migration, /'subject_id'|'assessment_scores'|'results'\s*,\s*jsonb_agg/i,
  'Public verification snapshot must not expose per-subject IDs or assessment breakdowns');
assert.match(migration, /extensions\.gen_random_bytes\(24\)/i,
  'Verification code must use 24 random bytes (192 bits)');
assert.doesNotMatch(migration, /substr\(replace\(gen_random_uuid\(\)::text,'-',''\),1,16\)/i,
  'Do not truncate a UUID to a 64-bit public verification token');

assert.match(ui, /verified\.snapshot\?\.total/i, 'UI consumes snapshot.total');
assert.match(ui, /verified\.snapshot\?\.average/i, 'UI consumes snapshot.average');
assert.doesNotMatch(publicVerifier, /assessment_scores|subject_id/i,
  'Public document verifier must not expose assessment-level result details');

console.log('PASS: result verification uses a 192-bit code and exposes only the aggregate snapshot consumed by the public UI.');
