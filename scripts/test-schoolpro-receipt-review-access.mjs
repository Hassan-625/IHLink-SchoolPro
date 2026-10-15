import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const migration = readFileSync("supabase/migrations/20261015150000_allow_school_finance_to_view_submitted_receipts.sql", "utf8");
const page = readFileSync("src/pages/schoolpro/SchoolProFees.tsx", "utf8");

assert.match(migration, /on storage\.objects\s+for select\s+to authenticated/i, "receipt-read policy must be authenticated SELECT only");
assert.match(migration, /bucket_id\s*=\s*'schoolpro-payment-receipts'/i, "policy must be limited to private receipt bucket");
assert.match(migration, /s\.receipt_path\s*=\s*objects\.name/i, "receipt access must match an actual submitted receipt path");
assert.match(migration, /schoolpro_module_allowed\(s\.school_id,\s*'finance'\)/i, "finance module permission required");
assert.match(migration, /has_school_access\([\s\S]*'proprietor'[\s\S]*'administrator'[\s\S]*'accountant'[\s\S]*'bursar'/i, "only authorized school finance roles may view submitted receipts");
assert.doesNotMatch(migration, /to\s+public|to\s+anon/i, "receipt-read policy must not grant public or anonymous access");
assert.match(page, /createSignedUrl\(path,\s*60\)/, "receipt preview must use a short-lived signed URL");
assert.match(page, /const preview=window\.open\("about:blank","_blank"\);[\s\S]*?await db\.storage\.from\("schoolpro-payment-receipts"\)\.createSignedUrl/, "receipt tab must be opened synchronously before awaiting signed URL to avoid popup blocking");
assert.match(page, /preview\.opener=null/, "receipt preview tab must not retain an opener reference");
assert.match(page, /View receipt/, "finance review UI must offer receipt preview");
assert.match(page, /review_schoolpro_payment_submission/, "confirmation/rejection must remain on the audited review RPC");

console.log("SchoolPro receipt review access contract passed.");
