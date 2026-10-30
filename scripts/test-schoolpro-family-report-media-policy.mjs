import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migrationPath = 'supabase/migrations/20261016110500_schoolpro_optimize_family_report_media_storage_policy.sql';
const migration = readFileSync(migrationPath, 'utf8');
const functionStart = migration.indexOf('create or replace function private.schoolpro_family_report_media');
const functionEnd = migration.indexOf('revoke all on function private.schoolpro_family_report_media', functionStart);
assert.ok(functionStart >= 0 && functionEnd > functionStart, 'Migration must replace and then restrict the family-media function');
const fn = migration.slice(functionStart, functionEnd);

for (const indexName of [
  'schoolpro_students_photo_storage_path_idx',
  'schoolpro_result_term_settings_principal_signature_path_idx',
  'schoolpro_result_term_settings_form_teacher_signature_path_idx',
  'schoolpro_result_templates_logo_storage_path_idx',
]) {
  assert.ok(migration.includes(indexName), 'Missing targeted media-path index: ' + indexName);
}

assert.match(fn, /where s\.photo_storage_path = p_name\s+and exists/i, 'Student-photo path must be filtered before published-result authorization');
assert.match(fn, /where ts\.principal_signature_path = p_name\s+and exists/i, 'Principal-signature path must be filtered before published-result authorization');
assert.match(fn, /where ts\.form_teacher_signature_path = p_name\s+and exists/i, 'Form-teacher-signature path must be filtered before published-result authorization');
assert.match(fn, /where t\.logo_storage_path = p_name\s+and exists/i, 'Logo path must be filtered before published-result authorization');
assert.doesNotMatch(fn, /from public\.schoolpro_students s\s+join public\.schoolpro_results r\s+on r\.student_id\s*=\s*s\.id/i, 'Do not restore the broad student/result join that timed out in Storage policy evaluation');

const policyStart = migration.indexOf('create policy "Families read their report images"');
assert.ok(policyStart >= 0, 'Migration must recreate the family media Storage policy');
const policy = migration.slice(policyStart);
assert.match(policy, /and case[\s\S]*student-photos[\s\S]*then private\.schoolpro_family_report_media\(name\)/i, 'Student photos must be checked only on their media path');
assert.match(policy, /result-signatures[\s\S]*then private\.schoolpro_family_report_media\(name\)/i, 'Signatures must be checked only on their media path');
assert.match(policy, /school-logo[\s\S]*then private\.schoolpro_family_report_media\(name\)/i, 'Logos must be checked only on their media path');
assert.match(policy, /else false\s+end/i, 'Non-media objects such as workbooks must short-circuit without invoking the expensive function');

console.log('PASS: family report media policy uses indexed exact-path checks and excludes workbook paths from expensive authorization.');
