# SchoolPro audit batch 9 — parity recheck, transition inventory and adversarial-test gate — 2026-10-17

## Scope and safety

Read-only production catalog queries and deployed Edge source retrieval only. No production SQL/Storage changes, Edge deploy, bucket mutation, merge, migration replay, export/import or cutover. This report deliberately distinguishes checks actually executed from required tests that remain blocked.

## Edge source restoration and exact parity recheck

Read deployed function sources and compared entrypoint text with branch files. The source checks below were executed during this batch.

| Function | Live version | Branch comparison | Disposition |
|---|---:|---|---|
| `schoolpro-owner-access` | 3 | Exact entrypoint match | Restored path and verified exact text |
| `auth-handoff` | 12 | Exact entrypoint match | Restored path and verified exact text |
| `schoolpro-transfer-ownership` | 1 | Exact entrypoint match | Missing `supabase/functions/schoolpro-transfer-ownership/index.ts` restored in commit `269e6719b944b81b2e37f802e45cabe2ad218772`; exact text verified |
| `schoolpro-student-login` | 3 | Exact entrypoint match | Verified |
| `schoolpro-account-login` | 2 | Exact entrypoint match | Verified |
| `schoolpro-email-worker` | 10 | Exact entrypoint match | Verified using returned nested entrypoint path |
| `schoolpro-render-document` | 14 | Exact after trimming trailing newline only | No semantic drift found by this text check; do not rewrite only for newline |
| `schoolpro-render-result` | 6 | Exact after applying only the two intended output-bucket substitutions | Candidate source differs from deployed source exactly at the intended upload/signing bucket references |
| `schoolpro-result-access` | 1 | Exact after applying only the intended signing-bucket substitution | Candidate source differs from deployed source exactly at the intended output bucket reference |
| `invite-school-staff` | 16 | Not equal; deployed source 10,305 chars vs branch source 9,416 chars | Drift remains unresolved. Deployed snapshot preserved at `docs/database-migration/recovered-deployed-edge-functions-2026-10-17/invite-school-staff/index.ts` in commit `583a49605ae4ebde4c633acb1ed7a1feba19ce62`; do not overwrite candidate source without semantic review |

The deployed source hash values are documented in prior batch reports; the source comparison above is textual entrypoint comparison, not a rebuilt bundle comparison. Restoring `schoolpro-transfer-ownership` repairs the missing expected source path on the audit branch; no deployment was performed.

The result bucket candidate patch was rechecked after restoration. Both result functions match deployed text once only the intended bucket substitutions are reversed. This is a useful bounded-diff check, but not a build or Storage integration test. Existing CI status contexts returned for the two candidate commits are Vercel checks; they are not proof of the Render deployment state, Supabase Edge deployment, or adversarial Storage correctness.

## Historical trigger/cron reconciliation status

The current trigger catalog remains 160 non-internal triggers associated with SchoolPro tables or SchoolPro-named functions. This is a current-state inventory, not a historical transition matrix. Every historical trigger action still needs source-version evidence: table, trigger name, timing/event/WHEN, function signature, later replacement/drop, and final attachment.

The live cron inventory remains seven active jobs:
- `billstack-pending-funding-5m` — `*/5 * * * *`
- `datasub-api-callbacks-1m` — `* * * * *`
- `datasub-provider-health-5m` — `*/5 * * * *`
- `datasub-reconcile-2m` — `*/2 * * * *`
- `ihlink-email-delivery-2m` — `*/2 * * * *`
- `schoolpro-academic-calendar` — `7 * * * *`
- `schoolpro-expiry-grace-daily` — `15 0 * * *`

Current command targets and job names were queried from `cron.job`. The exact historical schedule/unschedule transition diff is still incomplete, and `datasub-provider-health-5m` provenance remains unresolved. Do not infer the historical source solely from the live job name.

## Effective ACL/default ACL position

The current live catalog has broad default ACL entries for postgres-owned public/storage sequences, functions and relations, and platform-owned defaults in cron/extensions/graphql/graphql_public. These are catalog defaults, not SchoolPro-specific migration intent. They must be normalized by owner/schema/object type/privilege and must not be cloned blindly into the MySQL target or another PostgreSQL target.

The full 397-version object/action ACL timeline remains blocked until each recovered payload is paired with its later superseding action and current effective privileges. Current `has_function_privilege` checks and schema USAGE checks are current-state evidence only; role inheritance, ownership, BYPASSRLS and PUBLIC grants remain explicit dimensions.

## Adversarial test gate — not executed

No production abuse payloads were sent. No healthy, isolated, disposable Supabase environment with two-tenant fixtures and separate credentials was available in this pass. The only listed development branch is `main`, marked `MIGRATIONS_FAILED`; it is not safe to use for adversarial tests. Creating a new Supabase branch may incur hourly compute charges and requires explicit cost approval, so I did not create one. Therefore these tests remain **NOT RUN**:

- Public result PIN/code direct-RPC brute force, invalid/revoked code, response minimization and replay.
- Admission offer/application foreign-school IDs, token replay, guardian mismatch, enumeration and throttling.
- CBT invalid/expired/foreign candidate tokens, foreign question IDs, concurrent answer saves, submission replay and deadline races.
- Payment receipt wrong bucket/path traversal/nonexistent object/forged MIME/other-tenant path/replacement and upload-delete race.
- Result-output signed URL authorization for student/guardian/staff across tenants, unpublished/held output, forged path, revoke/expiry and object replacement.
- Class-result submit/publish cross-school and role-boundary cases.

A safe next test environment must be isolated from production, contain synthetic tenant A/B records only, and collect status/body plus row/object/audit deltas without logging bearer tokens or signed URLs. No tests may use real student/payment data.

## Remaining dispositions

1. Signature-aware historical routine body/overload reconciliation: open (236 heuristic candidates; not 236 proven defects).
2. Historical 397-version per-object/action policy and ACL matrix: open.
3. Historical trigger and cron transition matrix: open.
4. Disposable adversarial security tests: blocked on a healthy isolated environment and dedicated synthetic fixtures.
5. Edge parity: six exact source matches, one trailing-newline-only difference, two bounded candidate bucket patches, and `invite-school-staff` source drift unresolved. Candidate bucket fix remains undeployed and unapproved.

No production object was changed and no migration/cutover gate is lifted.
