import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const source = await readFile(new URL('../src/hooks/useSchoolProContext.ts', import.meta.url), 'utf8');

assert.match(source, /if\s*\(studentPortal\)/, 'student portal must use its dedicated identity lookup');
assert.match(source, /from\('schoolpro_students'\)[\s\S]*?\.eq\('user_id',\s*uid\)/, 'student lookup must be tied to the authenticated user');
assert.match(source, /if\s*\(selected\)\s*studentPortalQuery\s*=\s*studentPortalQuery\.eq\('school_id',\s*selected\)/, 'student lookup must be constrained to the selected workspace');
assert.match(source, /if\s*\(parentPortal\)/, 'parent portal must use its dedicated active guardian-link lookup');
assert.match(source, /from\('schoolpro_guardian_links'\)[\s\S]*?\.eq\('guardian_user_id',\s*uid\)[\s\S]*?\.eq\('status',\s*'active'\)/, 'parent lookup must require an active link for the authenticated guardian');
assert.match(source, /if\s*\(selected\)\s*parentPortalQuery\s*=\s*parentPortalQuery\.eq\('school_id',\s*selected\)/, 'guardian lookup must be constrained to the selected workspace');
assert.match(source, /profile\?\.role\s*===\s*'super_admin'\s*&&\s*selected/, 'Super Admin workspace access must require explicit selection');
assert.match(source, /profile\?\.role\s*===\s*'super_admin'\s*&&\s*!selected/, 'Super Admin must not silently fall back to an owned school');
console.log('PASS: student and active guardian identities are scoped to the selected workspace; Super Admin still requires explicit selection.');
