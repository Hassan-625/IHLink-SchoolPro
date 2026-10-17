import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migrationPath = 'supabase/migrations/20261016160000_schoolpro_repair_operational_tenant_integrity.sql';
const sql = readFileSync(migrationPath, 'utf8');
const rlsMigrationPath = 'supabase/migrations/20261017170000_schoolpro_forward_operational_tenant_isolation.sql';
const rlsSql = readFileSync(rlsMigrationPath, 'utf8');

assert.match(sql, /create or replace function private\.schoolpro_validate_operational_tenant\(\)/i);
assert.match(sql, /security definer\s+set search_path\s*=\s*''/i, 'Trigger functions must use a fixed empty search_path');
assert.match(sql, /revoke all on function private\.schoolpro_validate_operational_tenant\(\)\s+from public, anon, authenticated/i);
assert.match(sql, /revoke all on function private\.validate_schoolpro_member_permission_tenant\(\)\s+from public, anon, authenticated/i);

for (const triggerName of [
  'validate_schoolpro_lesson_notes_tenant',
  'validate_schoolpro_result_approvals_tenant',
  'validate_schoolpro_promotions_tenant',
  'validate_schoolpro_member_permission_tenant',
  'validate_schoolpro_subjects_tenant',
  'validate_schoolpro_classes_tenant',
  'validate_schoolpro_students_tenant',
  'validate_schoolpro_results_tenant',
  'validate_schoolpro_members_tenant',
]) {
  assert.match(sql, new RegExp('create trigger ' + triggerName, 'i'), 'Missing tenant-integrity trigger: ' + triggerName);
}

for (const relatedCheck of [
  /from public\.schoolpro_subjects where id = new\.subject_id for share/i,
  /from public\.schoolpro_classes where id = new\.class_id for share/i,
  /from public\.schoolpro_results where id = new\.result_id for share/i,
  /from public\.schoolpro_students where id = new\.student_id for share/i,
  /from public\.schoolpro_classes where id = new\.from_class_id for share/i,
  /from public\.schoolpro_classes where id = new\.to_class_id for share/i,
  /from public\.schoolpro_members where id = new\.member_id for share/i,
]) {
  assert.match(sql, relatedCheck, 'Missing cross-tenant relationship check');
}

assert.match(sql, /ref_school is distinct from new\.school_id/i, 'Cross-tenant relationships must be rejected, including missing referenced rows');
assert.match(sql, /member_school is null or member_school is distinct from new\.school_id/i, 'Missing or cross-school members must be rejected');
assert.match(
  sql,
  /tg_table_name in \(\s*'schoolpro_subjects',\s*'schoolpro_classes',\s*'schoolpro_students',\s*'schoolpro_results',\s*'schoolpro_members'\s*\)/i,
  'Tenant ownership must be immutable on referenced parent tables'
);
assert.match(sql, /new\.school_id is distinct from old\.school_id/i, 'Parent tenant reassignment must be rejected');
assert.match(sql, /raise exception 'School ownership cannot be reassigned'/i, 'Parent tenant reassignment must fail closed');
assert.doesNotMatch(sql, /insert into|update public\.|delete from/i, 'Migration must not mutate existing application data');

assert.match(rlsSql, /alter table public\.%I enable row level security/i, 'Forward repair must enable RLS on the operational table set');
assert.match(rlsSql, /alter table public\.%I force row level security/i, 'Forward repair must force RLS on the operational table set');
assert.match(rlsSql, /if to_regclass\(format\('public\.%I', t\)\) is null then\s+raise exception/i, 'Forward repair must fail closed when a required operational table is missing');
assert.doesNotMatch(rlsSql, /drop policy|create policy|alter policy/i, 'Forward repair must preserve existing feature-specific policies');
assert.match(rlsSql, /does NOT\s+constrain\s+superusers or roles with BYPASSRLS/i, 'Migration must document the limits of FORCE RLS');
for (const tableName of [
  'schoolpro_library_books',
  'schoolpro_transport_routes',
  'schoolpro_hostel_rooms',
  'schoolpro_inventory_assets',
  'schoolpro_calendar_events',
  'schoolpro_lesson_notes',
  'schoolpro_result_approvals',
  'schoolpro_promotions',
]) {
  assert.match(rlsSql, new RegExp("'" + tableName + "'"), 'Missing RLS posture target: ' + tableName);
}

console.log('PASS: operational relationship integrity and forward-only RLS posture migrations preserve feature policies and fail closed.');
