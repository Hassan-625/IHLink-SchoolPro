import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const edge = readFileSync('supabase/functions/schoolpro-result-pin-check/index.ts', 'utf8');
const page = readFileSync('src/pages/schoolpro/SchoolProResultChecker.tsx', 'utf8');
const migration = readFileSync('supabase/migrations/20261016122000_schoolpro_result_pin_attempt_rate_limit.sql', 'utf8');
const config = readFileSync('supabase/config.toml', 'utf8');

assert.match(edge, /TURNSTILE_SECRET_KEY/, 'Result checker gateway must require the server-side Turnstile secret');
assert.match(edge, /TURNSTILE_ALLOWED_HOSTNAMES/, 'Result checker gateway must restrict challenge hostnames');
assert.match(edge, /SCHOOLPRO_RESULT_CHECK_ALLOWED_ORIGINS|SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS/, 'Result checker gateway must enforce an origin allowlist');
assert.match(edge, /const action = 'schoolpro_result_pin_check'/, 'Result PIN checks must use a dedicated Turnstile action');
assert.match(edge, /verifyTurnstile\(/, 'Result checker gateway must call the shared Siteverify helper');
assert.match(edge, /admin\.rpc\('check_schoolpro_result_pin'/, 'Only the server-side service role should invoke the database RPC');
assert.doesNotMatch(edge, /cf-connecting-ip|x-forwarded-for|x-real-ip/i, 'Do not introduce an unverified client-IP identity');
assert.match(edge, /raw\.length > 8_192/, 'Result checker gateway must bound the request body');
assert.match(page, /supabase\.functions\.invoke\('schoolpro-result-pin-check'/, 'The result checker UI must call the protected Edge Function');
assert.doesNotMatch(page, /supabase\.rpc\(['"]check_schoolpro_result_pin/i, 'The browser must not invoke the protected database RPC directly');
assert.match(page, /VITE_TURNSTILE_SITE_KEY/, 'The result checker must use the configured public Turnstile site key');
assert.match(page, /turnstileToken/, 'The result checker must submit a challenge token');
assert.match(migration, /revoke all on function public\.check_schoolpro_result_pin[\s\S]*?from public, anon, authenticated/i, 'Direct public/authenticated RPC execution must be revoked');
assert.match(migration, /grant execute on function public\.check_schoolpro_result_pin[\s\S]*?to service_role/i, 'Only service_role should execute the RPC behind the gateway');
assert.match(config, /\[functions\.schoolpro-result-pin-check\][\s\S]*?verify_jwt = false/i, 'Anonymous Edge Function entry must be explicitly configured for its own challenge/origin controls');

console.log('PASS: result-PIN checks are routed through the Turnstile gateway; direct public RPC execution is revoked and no request IP header is trusted.');
