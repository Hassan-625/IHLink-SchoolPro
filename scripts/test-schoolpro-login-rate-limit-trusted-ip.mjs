import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const cases = [
  {
    path: 'supabase/functions/schoolpro-account-login/index.ts',
    key: /\['email:'\s*\+\s*email\s*,\s*8\]/,
  },
  {
    path: 'supabase/functions/schoolpro-student-login/index.ts',
    key: /\["account:"\s*\+\s*code\.toLowerCase\(\)\s*\+\s*":"\s*\+\s*admission\.toLowerCase\(\)\s*,\s*8\]/,
  },
];

for (const {path, key} of cases) {
  const source = readFileSync(path, 'utf8');
  assert.match(source, /schoolpro_take_login_attempt/, `${path}: server-side login throttling must remain enabled`);
  assert.match(source, key, `${path}: normalized account identity must remain rate-limited`);
  assert.doesNotMatch(
    source,
    /req\.headers\.get\(\s*["'](?:cf-connecting-ip|x-forwarded-for|x-real-ip|forwarded)["']\s*\)/i,
    `${path}: no forwarding header may define a database rate-limit identity without verified trusted-proxy provenance`,
  );
  assert.doesNotMatch(source, /\bip:\s*\+\s*ip\b/i, `${path}: remove unverified IP buckets`);
}

console.log('PASS: account/student login throttles remain server-side and do not derive database rate-limit identities from unverified forwarding headers.');
