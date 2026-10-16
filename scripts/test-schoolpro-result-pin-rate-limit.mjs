import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const path = 'supabase/migrations/20261016122000_schoolpro_result_pin_attempt_rate_limit.sql';
const sql = readFileSync(path, 'utf8');

assert.match(sql, /create table if not exists private\.schoolpro_result_pin_attempts/i);
assert.match(sql, /attempt_key text primary key/i);
assert.ok(sql.includes('extensions.digest('), 'Admission/PIN hashes must use schema-qualified pgcrypto');
assert.match(sql, /failed_attempts \+ 1 >= 8/i, 'Eight failures must trigger cooldown');
assert.match(sql, /interval '15 minutes'/i, 'Cooldown/window must be bounded to 15 minutes');
assert.match(sql, /blocked_until > now\(\)/i, 'Blocked attempt keys must be rejected before student/PIN lookup');
assert.ok(sql.includes("current_setting('request.headers', true)"), 'Rate-limit key should include request network context to reduce admission-only lockout abuse');
assert.ok(sql.includes('perform private.record_schoolpro_result_pin_failure(v_attempt_key)'), 'Unknown admission and incorrect PIN paths must both count failures');
assert.match(sql, /delete from private\.schoolpro_result_pin_attempts\s+where attempt_key = v_attempt_key/i, 'Successful published-result access must clear the failure counter');
assert.match(sql, /revoke all on table private\.schoolpro_result_pin_attempts from public, anon, authenticated/i, 'Attempt table must not be directly accessible from API roles');
assert.match(sql, /revoke all on function private\.record_schoolpro_result_pin_failure\(text\) from public, anon, authenticated/i, 'Internal counter function must not be callable from API roles');
assert.match(sql, /set search_path to ''/i, 'Security-definer functions must pin an empty search_path');
assert.doesNotMatch(sql, /(?<!extensions\.)digest\(lower\(trim\(coalesce\(p_admission/i, 'pgcrypto digest must be schema-qualified under empty search_path');

console.log('PASS: result-PIN rate-limit migration has hashed network-scoped identifiers, atomic failure counts, cooldown and restricted private storage.');
