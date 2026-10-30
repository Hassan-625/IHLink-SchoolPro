import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const edge = readFileSync('supabase/functions/schoolpro-public-admission/index.ts', 'utf8');
const verifier = readFileSync('supabase/functions/schoolpro-public-admission/turnstile.mjs', 'utf8');
const migration = readFileSync('supabase/migrations/20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql', 'utf8');
const page = readFileSync('src/pages/schoolpro/SchoolProPublicAdmission.tsx', 'utf8');
const config = readFileSync('supabase/config.toml', 'utf8');

assert.match(edge, /TURNSTILE_SECRET_KEY/, 'Edge gateway must require a server-side Turnstile secret');
assert.match(edge, /TURNSTILE_ALLOWED_HOSTNAMES/, 'Edge gateway must validate expected Turnstile hostnames');
assert.match(edge, /SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS/, 'Edge gateway must enforce configured origin allowlist');
assert.match(edge, /verifyTurnstile\(/, 'Edge gateway must call the shared verifier');
assert.match(edge, /verification\.unavailable/, 'Edge gateway must distinguish upstream failure and fail closed');
assert.match(edge, /!verification\.ok/, 'Edge gateway must reject invalid verification');
assert.match(verifier, /challenges\.cloudflare\.com\/turnstile\/v0\/siteverify/, 'Server-side verifier must call Siteverify');
assert.match(verifier, /verification\?\.success === true/, 'Verifier must fail closed on invalid tokens');
assert.match(verifier, /verification\?\.action === action/, 'Verifier must validate the expected action');
assert.match(verifier, /hostnames\.has\(verification\.hostname\.toLowerCase\(\)\)/, 'Verifier must validate challenge hostname');
assert.match(verifier, /AbortSignal\.timeout\(8_000\)/, 'Siteverify must have a bounded timeout');
assert.match(edge, /raw\.length > 16_384/, 'Edge gateway must bound request body size');
assert.doesNotMatch(edge, /cf-connecting-ip|x-forwarded-for|x-real-ip/i, 'Gateway must not introduce unverified IP identity');
assert.doesNotMatch(verifier, /remoteip\s*:/i, 'Do not send an unverified client IP to Siteverify');
assert.match(migration, /revoke all on function public\.submit_schoolpro_application[\s\S]*?from public, anon, authenticated/i, 'Direct public RPC execution must be revoked');
assert.match(migration, /grant execute on function public\.submit_schoolpro_application[\s\S]*?to service_role/i, 'Only the server-side gateway role may execute the RPC');
assert.match(page, /supabase\.functions\.invoke\('schoolpro-public-admission'/, 'Public form must use the gateway');
assert.doesNotMatch(page, /supabase\.rpc\(['"]submit_schoolpro_application/i, 'Public form must not call the RPC directly');
assert.match(page, /VITE_TURNSTILE_SITE_KEY/, 'Frontend must use the configured public site key');
assert.match(page, /turnstileToken/, 'Frontend must submit a challenge token');
assert.match(config, /\[functions\.schoolpro-public-admission\][\s\S]*?verify_jwt = false/, 'Anonymous gateway must be explicitly configured; its own controls validate the request');

console.log('PASS: public admissions gateway calls the behavior-tested server-side Turnstile verifier and keeps service-role-only RPC execution.');
