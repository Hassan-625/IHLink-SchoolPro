import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migrationPath = 'supabase/migrations/20261016160000_schoolpro_repair_operational_tenant_integrity.sql';
const sql = readFileSync(migrationPath, 'utf8');

assert.match(sql, /create or replace function private\.schoolpro_validate_operational_tenant\(\)/i);
assert.match(sql, /security definer\s+set search_path\s*=\s*''/i, 'Trigger functions must use a fixed empty search_path');
assert.match(sql, /revoke all on function private\.schoolpro_validate_operational_tenant\(\)\s+from public, anon, authenticated/i);
assert.match(sql, /revoke all on function private\.validate_schoolpro_member_permission_tenant\(\)\s+from public, anon, authenticated/i);

for (const triggerName of [
  'validate_schoolpro_lesson_notes_tenant',
  'validate_schoolpro_result_approvals_tenant',
  'validate_schoolpro_promotions_tenant',
  'validate_schoolpro_member_permission_tenant',
]) {
  assert.match(sql, new RegExp('create trigger ' + triggerName, 'i'), 'Missing tenant-integrity trigger: ' + triggerName);
}

for (const relatedCheck of [
  /from public\.schoolpro_subjects where id = new\.subject_id/i,
  /from public\.schoolpro_classes where id = new\.class_id/i,
  /from public\.schoolpro_results where id = new\.result_id/i,
  /from public\.schoolpro_students where id = new\.student_id/i,
  /from public\.schoolpro_classes where id = new\.from_class_id/i,
  /from public\.schoolpro_classes where id = new\.to_class_id/i,
  /from public\.schoolpro_members where id = new\.member_id/i,
]) {
  assert.match(sql, relatedCheck, 'Missing cross-tenant relationship check');
}

assert.match(sql, /ref_school is distinct from new\.school_id/i, 'Cross-tenant relationships must be rejected, including missing referenced rows');
assert.match(sql, /member_school is null or member_school is distinct from new\.school_id/i, 'Missing or cross-school members must be rejected');
assert.doesNotMatch(sql, /insert into|update public\.|delete from/i, 'Migration must not mutate existing application data');
console.log('PASS: operational and staff-permission tenant-integrity migration contains fixed-search-path, restricted trigger functions and cross-school relationship checks.');
