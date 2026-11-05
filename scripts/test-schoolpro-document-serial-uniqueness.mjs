import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migration = readFileSync(
  'supabase/migrations/20261017103000_schoolpro_document_serial_global_uniqueness.sql',
  'utf8',
);
const verifier = readFileSync(
  'supabase/migrations/20261002213000_harden_document_verification.sql',
  'utf8',
);

assert.match(migration, /group by upper\(trim\(serial_number\)\)\s+having count\(\*\) > 1/i,
  'Migration must fail closed if normalized duplicate serials already exist');
assert.match(migration, /create unique index if not exists schoolpro_document_issues_normalized_serial_global_uq\s+on public\.schoolpro_document_issues \(upper\(trim\(serial_number\)\)\)/i,
  'Normalized document serials must be globally unique');
assert.match(verifier, /where upper\(i\.serial_number\)=upper\(trim\(p_serial\)\)/i,
  'Public verifier normalizes serial input; database uniqueness must use the same normalization');

console.log('PASS: public document serials are protected by a fail-closed normalized global uniqueness migration.');
