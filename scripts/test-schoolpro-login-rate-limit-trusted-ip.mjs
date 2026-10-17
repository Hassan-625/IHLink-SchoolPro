import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const paths = [
  'supabase/functions/schoolpro-account-login/index.ts',
  'supabase/functions/schoolpro-student-login/index.ts',
];
for (const path of paths) {
  const source = readFileSync(path, 'utf8');
  assert.match(source, /req\.headers\.get\(["']cf-connecting-ip["']\)/i, `${path}: rate-limit identity must use the edge client-IP header`);
  assert.doesNotMatch(source, /req\.headers\.get\(["']x-forwarded-for["']\)/i, `${path}: do not trust caller-influenced X-Forwarded-For for rate limiting`);
  assert.match(source, /schoolpro_take_login_attempt/, `${path}: keep server-side rate limiting enabled`);
}
console.log('PASS: SchoolPro account and student login rate-limit keys do not use caller-supplied X-Forwarded-For.');
