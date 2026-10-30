import assert from 'node:assert/strict';
import { verifyTurnstile } from '../supabase/functions/schoolpro-public-admission/turnstile.mjs';

const hostnames = new Set(['admissions.example.com']);
const valid = { success: true, action: 'schoolpro_public_admission', hostname: 'admissions.example.com' };
let calls = 0;
let lastRequest;

const fakeFetch = async (url, init) => {
  calls += 1;
  lastRequest = { url, init };
  return { ok: true, json: async () => valid };
};

assert.deepEqual(
  await verifyTurnstile({ token: 'valid-token', secret: 'server-secret', action: 'schoolpro_public_admission', hostnames, fetchImpl: fakeFetch }),
  { ok: true, unavailable: false },
  'a valid, action-bound, hostname-bound token is accepted',
);
assert.equal(lastRequest.url, 'https://challenges.cloudflare.com/turnstile/v0/siteverify');
assert.equal(lastRequest.init.method, 'POST');
assert.equal(lastRequest.init.headers['Content-Type'], 'application/x-www-form-urlencoded');
assert.equal(lastRequest.init.body.get('response'), 'valid-token');
assert.equal(lastRequest.init.body.get('secret'), 'server-secret');
assert.ok(lastRequest.init.signal instanceof AbortSignal, 'Siteverify request has a bounded abort signal');
assert.equal(calls, 1);

const noFetch = async () => { throw new Error('must not call Siteverify'); };
for (const input of [
  { token: '', secret: 'secret', action: 'schoolpro_public_admission', hostnames, fetchImpl: noFetch },
  { token: 'x'.repeat(2049), secret: 'secret', action: 'schoolpro_public_admission', hostnames, fetchImpl: noFetch },
  { token: 'token', secret: '', action: 'schoolpro_public_admission', hostnames, fetchImpl: noFetch },
  { token: 'token', secret: 'secret', action: 'schoolpro_public_admission', hostnames: new Set(), fetchImpl: noFetch },
]) {
  assert.deepEqual(await verifyTurnstile(input), { ok: false, unavailable: false }, 'missing/oversized input or config fails closed before network');
}

for (const bad of [
  { ...valid, success: false },
  { ...valid, action: 'different_action' },
  { ...valid, hostname: 'attacker.example.net' },
  { ...valid, hostname: null },
  { ...valid, success: false, 'error-codes': ['timeout-or-duplicate'] },
]) {
  const result = await verifyTurnstile({
    token: 'token',
    secret: 'secret',
    action: 'schoolpro_public_admission',
    hostnames,
    fetchImpl: async () => ({ ok: true, json: async () => bad }),
  });
  assert.deepEqual(result, { ok: false, unavailable: false }, 'invalid, expired/replayed, wrong-action, or wrong-hostname tokens are rejected');
}

assert.deepEqual(
  await verifyTurnstile({
    token: 'token', secret: 'secret', action: 'schoolpro_public_admission', hostnames,
    fetchImpl: async () => ({ ok: false, status: 502, json: async () => ({}) }),
  }),
  { ok: false, unavailable: true },
  'Siteverify HTTP errors fail closed as temporarily unavailable',
);
assert.deepEqual(
  await verifyTurnstile({
    token: 'token', secret: 'secret', action: 'schoolpro_public_admission', hostnames,
    fetchImpl: async () => { throw new Error('network down'); },
  }),
  { ok: false, unavailable: true },
  'Siteverify network errors fail closed as temporarily unavailable',
);

console.log('PASS: Turnstile verifier accepts only successful action/hostname-bound responses and fails closed for invalid, replayed, malformed, or unavailable cases.');
