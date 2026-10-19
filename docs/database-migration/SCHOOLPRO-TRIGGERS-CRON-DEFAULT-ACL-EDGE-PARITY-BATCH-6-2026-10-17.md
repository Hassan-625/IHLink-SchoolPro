# SchoolPro transition audit — triggers, cron, default ACLs and deployed Edge Function parity — batch 6 — 2026-10-17

## Safety boundary

All production database work in this batch was catalog/read-only inspection. No DDL/DML, grant/revoke, migration replay, Storage object mutation, Edge Function deployment, Render change, merge, export/import, or cutover was performed. The adversarial request cases below are test requirements, not tests claimed as passed: no disposable environment and dedicated two-tenant test credentials were supplied by this inspection path, and the production environment was not used to send abuse payloads.

## Trigger-to-function live inventory

The current production catalog query found 160 non-internal triggers associated with SchoolPro tables or SchoolPro-named trigger functions. Of these, 141 invoke SECURITY DEFINER functions; 156 point to functions in `private` and four to functions in `public` (the remaining trigger rows point to functions in other schemas). The inventory is the live state, not a 397-version historical diff.

Each trigger matrix row must preserve table/schema, trigger name, timing/events/column filter, WHEN clause, function schema/name/identity arguments, function owner, SECURITY DEFINER, search_path, and source migration transitions. Repeated common triggers such as `private.guard_schoolpro_operational_write()`, activity-period stamp/preserve triggers and validation/notification triggers must be checked for complete table coverage and unintended overlap. A function-level review alone does not prove that the intended trigger remains attached to every table.

## Current cron transition inventory

The live `cron.job` table currently has seven active jobs:

| Job | Schedule | Current command target | Audit note |
|---|---|---|---|
| `billstack-pending-funding-5m` | `*/5 * * * *` | `billstack-reconcile` Edge Function | Verify token rotation and request authorization in non-production |
| `datasub-api-callbacks-1m` | `* * * * *` | `datasub-api-callbacks` Edge Function | Job command references worker token secret |
| `datasub-provider-health-5m` | `*/5 * * * *` | `datasub-provider-health` Edge Function | Prior migration-ledger name/command provenance remains unresolved |
| `datasub-reconcile-2m` | `*/2 * * * *` | `datasub-reconcile` Edge Function | Verify endpoint and authorization in non-production |
| `ihlink-email-delivery-2m` | `*/2 * * * *` | `ihlink-email-worker` Edge Function | Shared email worker dependency |
| `schoolpro-academic-calendar` | `7 * * * *` | `private.schoolpro_refresh_academic_clocks()` | SchoolPro-specific |
| `schoolpro-expiry-grace-daily` | `15 0 * * *` | `private.enforce_schoolpro_subscription_expiry()` | SchoolPro-specific; body evolved over time |

Secrets are not exposed in this report. Exact live command strings and schedules were inspected, but a full per-version `cron.schedule`/`cron.unschedule` transition diff remains open. Do not infer provenance from job name alone.

## Schema privileges and default ACLs

Effective schema checks confirmed:
- `anon`: USAGE on `public` and `storage`, but not `private`.
- `authenticated`: USAGE on `public`, `private`, and `storage`.
- `service_role`: USAGE on `public` and `storage`, but not `private` in this direct schema check.
- `postgres`: USAGE and CREATE on `public` and `private`.

The catalog's `pg_default_acl` includes explicit default grants for `postgres`-owned objects in `public` and `storage`: object types sequence (`S`), function (`f`), and relation (`r`) list anon, authenticated and service_role in addition to postgres. Separate defaults owned by `supabase_admin` exist for public, GraphQL and extension schemas; these are platform-wide and must not be casually copied into a target database. The literal default ACL strings are in the source catalog evidence and must be normalized by object type/privilege before target decisions. In particular, a default EXECUTE grant is not a substitute for auditing existing function ACLs, schema USAGE, function owner, and RLS predicates.

This is a material migration design constraint: do not import broad Supabase platform defaults into a dedicated SchoolPro/MySQL architecture, and do not blindly reproduce PostgreSQL default ACLs in a new PostgreSQL target. Target privileges should be explicit, least-privilege and reviewed per role/object.

## Deployed Edge Function evidence: result outputs and document renderer

Read-only Supabase Edge Function metadata and source retrieval confirmed the following deployed versions and hashes:

| Function | Deployed version | verify_jwt | Deployed source hash (SHA-256) | Finding |
|---|---:|---|---|---|
| `schoolpro-render-result` | 6 | true | `f87b6ad094270eabef3d5f2919e5c9acffb7e911059c28b057068be265542461` | Authenticates caller with `auth.getUser()`; reads student/result/template data using caller-scoped client; media/download path uses bucket `school-result-templates` |
| `schoolpro-result-access` | 1 | true | `4b45e20029d5cd7fa5f334972fee39eebe2bb0c55c4b989175053d326f36ce9a` | Calls `schoolpro_can_view_result_output`, fetches output row, signs path from `school-result-templates` for 120 seconds |
| `schoolpro-render-document` | 14 | true | `2597a98a1cfa2145c1326f51a386e5c8466512334cb55a4513e4df8a1833d2fd` | Reads/writes document template/output buckets; validates school-prefixed template/image paths; uses academic/progression RPCs and finalizes issued document |
| `schoolpro-owner-access` | 3 | true | `7446cdf3322e265ff8ca90536752f24333e728245e7a4504a5af78dc60dfa802` | Service-role-backed owner/access workflow with active-profile and school owner/platform access checks |
| `auth-handoff` | 12 | false | `8506d14262c74515d7b7d13b307a30bfa92dce86cb38546df115b1e6ddd95582` | Manually validates Bearer token and active profile before generating a magic-link token hash |
| `invite-school-staff` | 16 | false | `56eca9f1c6270269f0895be0351615b15c9fb73dce0867d4e1b8b8dc5ceeb72d` | Manually validates Bearer token; rate limits and checks school leadership/member access |

For the result renderer/access pair, the live implementation uses `school-result-templates` for result PDF media and signed downloads. The previously inventoried frontend/result-output policies and output references use `schoolpro-result-outputs`. This is an unresolved cross-layer bucket-name mismatch until the bucket inventory, storage policies, generated output records, frontend calls and intended access model are reconciled together. No bucket rename or copy is approved by this finding.

The deployed `schoolpro-render-document` source retrieved from the service matches the repository source at `supabase/functions/schoolpro-render-document/index.ts` at the inspected branch for the returned entrypoint. By contrast, the expected repository paths `supabase/functions/schoolpro-render-result/index.ts` and `supabase/functions/schoolpro-result-access/index.ts` returned 404 on the inspected branch. This reinforces the earlier inventory that their active deployed sources are missing at the expected main-source paths. The repository path for deployed `schoolpro-owner-access` and `auth-handoff` must also be verified/restored. A 404 is only evidence of missing at that path/ref, not proof that no alternate source exists.

## Adversarial test status — not executed in production

These cases remain **NOT RUN / BLOCKING** pending a disposable project and dedicated fixtures:

1. Public result PIN/code RPCs: anon/authenticated boundary, valid/invalid/revoked codes, brute-force limits through direct RPC (not just UI/Edge), response field minimization, expiry and replay.
2. Admission offer/application RPCs: foreign-school offer IDs, token guessing/replay, owner/guardian mismatch, state transitions, request throttling and response enumeration.
3. Candidate CBT RPCs: invalid/expired/other-candidate tokens, question IDs from other attempts, replay after submission, deadline races, concurrent answer writes, cross-school attempt IDs.
4. Payment receipt Storage: cross-school receipt path, path traversal/normalization, wrong bucket, nonexistent object, forged MIME type, another user's object, replacement after submission, and upload/delete races.
5. Result outputs: student/guardian/staff from tenant A requests tenant B student; unpublished/held/invalid output; forged output path; output row bucket mismatch; signed URL after revoke/expiry; object deleted/replaced after authorization.
6. Admission/result/document issuance RPCs through direct PostgREST, not only UI. Capture HTTP status, response shape, database audit rows, Storage outcomes and absence of cross-tenant data.
7. All test evidence must use disposable tenant fixtures and must not expose actual student records or reusable bearer/signed URLs in logs.

## Overall disposition

This batch improves live transition evidence but does not close the requested 397-version semantic audit. Function body/overload disposition, complete per-object/action policy and ACL matrix, all trigger/cron historical transitions, Storage API adversarial tests, Edge Function source restoration/parity, and bucket alignment remain open. No production changes or cutover are authorized.
