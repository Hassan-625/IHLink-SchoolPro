import { readFileSync } from "node:fs";
import assert from "node:assert/strict";

const migration = readFileSync(
  "supabase/migrations/20261015170000_schoolpro_rate_limit_public_result_pin.sql",
  "utf8"
);
const edge = readFileSync(
  "supabase/functions/schoolpro-result-pin-check/index.ts",
  "utf8"
);
const checker = readFileSync(
  "src/pages/schoolpro/SchoolProResultChecker.tsx",
  "utf8"
);

assert.match(migration, /revoke all on function public\.check_schoolpro_result_pin\(text, text, text, text\)[\s\S]*?from public, anon, authenticated/i);
assert.match(migration, /grant execute on function public\.check_schoolpro_result_pin\(text, text, text, text\)[\s\S]*?to service_role/i);
assert.match(edge, /schoolpro_take_login_attempt/);
assert.match(edge, /schoolpro-result-pin:ip:/);
assert.match(edge, /schoolpro-result-pin:pair:/);
assert.match(edge, /limit: 60/);
assert.match(edge, /limit: 8/);
assert.match(edge, /p_key: await sha256\(bucket\.key\)/);
assert.match(edge, /Too many attempts[\s\S]*?15 minutes/);
assert.match(edge, /check_schoolpro_result_pin/);
assert.match(edge, /SUPABASE_SERVICE_ROLE_KEY/);
assert.match(checker, /functions\.invoke\('schoolpro-result-pin-check'/);
assert.doesNotMatch(checker, /rpc\('check_schoolpro_result_pin'/);
assert.match(migration, /begin;[\s\S]*?commit;/i);

console.log("SchoolPro public result PIN rate-limit contract checks passed:");
console.log("- direct public/authenticated execution is revoked");
console.log("- only service_role can call the result PIN RPC");
console.log("- edge endpoint applies hashed per-IP and per-IP/admission buckets");
console.log("- frontend uses the edge endpoint, not the direct RPC");
console.log("- migration is transactional");
