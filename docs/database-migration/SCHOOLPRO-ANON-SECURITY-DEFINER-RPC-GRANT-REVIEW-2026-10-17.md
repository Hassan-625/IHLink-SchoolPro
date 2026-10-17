# SchoolPro anonymous SECURITY DEFINER RPC grant review — 2026-10-17

## Scope and safety

Read-only review of current `pg_proc` definitions/ACLs and the migration-ledger statements that create or grant public SchoolPro RPCs. No function was called, revoked, modified, or deployed. This is a security finding register, not a remediation commit.

## Current public RPCs

The live catalog contains six `public.schoolpro_*` SECURITY DEFINER functions executable by `anon`:

| Function | Anonymous access | Intended public use / concern | Review status |
|---|---|---|---|
| `check_schoolpro_result_pin(text,text,text,text)` | yes | Looks up an active student by admission number, validates a PIN hash for term/session, then returns published subject result data when allowed. The body has no call to the existing login-attempt throttle and no in-body failed-attempt counter; the PIN table has no attempt-count/lockout column and only updates `last_used_at` on success. Direct PostgREST RPC calls can bypass any throttle implemented only in the frontend. | **High-priority abuse-control gap; not closed.** |
| `schoolpro_verify_result_code(text)` | yes | Public result verification returns school/student identifiers, term/session, issue metadata and the stored result snapshot when the code is valid. | Public by design may be appropriate, but snapshot minimization, code entropy, enumeration resistance and rate limiting must be demonstrated. |
| `submit_schoolpro_application(...)` | yes | Public admissions intake; function inserts a new application and returns identifiers/public token. The body has no visible rate-limit check. | Review spam/abuse controls and duplicate/volume constraints; do not rely on frontend controls. |
| `verify_schoolpro_document(text)` | yes | Public issued-document verification by serial; returns serial/title/type/status/date/school and, for issued records, student name. | Verify serial unpredictability, output minimization, enumeration controls and rate limiting. |
| `get_schoolpro_admission_offer(uuid)` | yes | Retrieves an admission offer by public token and returns applicant/offer details. | Validate public token entropy, expiry, replay/retention and enumeration controls. |
| `accept_schoolpro_admission_offer(uuid,text,text,text)` | yes | Accepts an offer by public token, locks offer/application rows and writes acceptance details. | Validate token entropy/expiry, idempotency, rate limiting and abuse controls; public write RPC deserves explicit acceptance tests. |

Current ACL inspection confirms `anon` execution on these six functions. The ledger shows `20260924144655 harden_rpc_and_customer_platform_access` explicitly granted `anon` and `authenticated` execution on `check_schoolpro_result_pin(text,text,text,text)`. The anonymous grant is therefore not an accidental default alone; it is an explicit historical design decision that must be re-reviewed against current abuse-control requirements.

The `private` schema is not USAGE-granted to `anon` (while `authenticated` has schema usage). Some private SECURITY DEFINER helpers/trigger functions still have broad/default function ACLs, but lack of schema usage limits direct anonymous resolution; review and revoke unnecessary function privileges as part of target hardening rather than relying on schema invisibility alone.

## Required remediation direction (not applied)

1. Put unauthenticated PIN lookup behind a trusted Edge Function with server-side throttling and safe generic errors, then revoke direct `anon` execution on the underlying result PIN RPC unless a reviewed alternative requires it.
2. Use a trusted abuse-control key derived server-side from normalized admission identity + academic period and a server-held secret/challenge; do not introduce an unverified client-supplied IP address as a database security identity. Rate limiting must not trust a client-provided `school_id` or user metadata.
3. Test valid PIN, invalid PIN, expired/inactive PIN, cross-school admission/PIN mismatch, held/unpublished result, repeated failure, parallel attempts, and response non-enumeration. Confirm a direct anonymous RPC attempt is denied after remediation.
4. For public result/document verification, minimize returned fields and snapshot content, use high-entropy unguessable codes, rate-limit at a trusted boundary and test repeated-code enumeration. The fact that a code is public does not authorize public access to the full snapshot without an explicit product decision.
5. For public admission offer and application endpoints, add abuse controls and verify token entropy/expiry, duplicate submissions, idempotent acceptance and school binding.
6. Reconcile these current effective grants against every recovered GRANT/REVOKE statement and later ACL changes before migration; a recovered historical grant statement is not the current effective privilege state.

## Migration impact

Do not reproduce broad anonymous RPC grants in Aiven/trusted API routes by default. Preserve public behavior only through explicitly reviewed, abuse-controlled endpoints. This is a **migration and security gate**; no production change has been made in this report.


## Current data-state qualifier

A read-only count query found **zero rows** in `public.schoolpro_result_verifications` (0 valid/current, 0 inactive/revoked) and **zero rows** in `public.schoolpro_result_access_pins` (0 active/unexpired, 0 inactive/expired) at audit time. Therefore no existing result snapshot or PIN record was exposed by this review, and the direct-RPC abuse concern is a latent endpoint-design risk rather than evidence of current successful exploitation. The public grants and missing in-body throttle still need to be resolved before this feature is populated or reproduced in the target.
