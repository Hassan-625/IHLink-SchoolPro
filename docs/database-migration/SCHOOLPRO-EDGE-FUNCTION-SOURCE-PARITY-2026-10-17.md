# Deployed SchoolPro Edge Function source parity — 2026-10-17

## Method and limits

Compared source returned by the live Supabase Edge Function source endpoint with the GitHub `main` source at the paths below. This is source-text comparison, not a runtime/config/environment comparison. No Edge Function was deployed or invoked for privileged changes.

## Results

| Function | Live version | Repository path | Result |
|---|---:|---|---|
| `invite-school-staff` | 16 | `supabase/functions/invite-school-staff/index.ts` | **Source drift, limited to diagnostics/error reporting in the inspected diff.** Deployed source adds a request UUID and stage labels around authentication, request parsing, rate limit, profile lookup, invitation insert/link, user creation/profile/credential setup; catch path logs sanitized error details and returns the request ID. Repository catch path returns the generic error without those diagnostics. The compared diff did not show a change to the authorization/data-operation expressions, but this is not a formal semantic proof; review the full function and dependent RPCs before accepting parity. |
| `schoolpro-render-document` | 14 | `supabase/functions/schoolpro-render-document/index.ts` | **Semantically identical after trimming trailing whitespace.** The byte mismatch is one trailing newline only (9,084 vs 9,085 chars); do not treat this as a behavioral drift. |
| `schoolpro-email-worker` | 10 | `supabase/functions/schoolpro-email-worker/index.ts` | **Exact source match.** The deployed response labels the file `schoolpro-email-worker/index.ts`; comparison used that actual returned file entry. |
| `schoolpro-student-login` | 3 | `supabase/functions/schoolpro-student-login/index.ts` | **Exact source match** (5,953 chars). |
| `schoolpro-account-login` | 2 | `supabase/functions/schoolpro-account-login/index.ts` | **Exact source match** (4,693 chars). |

Supabase-reported deployed source hashes:
- `invite-school-staff` v16: `56eca9f1c6270269f0895be0351615b15c9fb73dce0867d4e1b8b8dc5ceeb72d`
- `schoolpro-render-document` v14: `2597a98a1cfa2145c1326f51a386e5c8466512334cb55a4513e4df8a1833d2fd`
- `schoolpro-email-worker` v10: `7002e1f49ba99ff05817cc488e0e203762d953f1a12b291578657129aba53885`
- `schoolpro-student-login` v3: `a4cb4b4a77abddfc0a1ba1d0290ce3838135b3621298082b7daaf3507977267d`
- `schoolpro-account-login` v2: `8772d055fc7bdc1e3f0484ccd260cdb8671a4b7c4de329c381332f90daee4b78`

## Missing-source recovery status

Five other live function sources were recovered into forensic snapshots under [recovered-deployed-edge-functions-2026-10-17](recovered-deployed-edge-functions-2026-10-17/README.md): `schoolpro-owner-access` v3, `auth-handoff` v12, `schoolpro-transfer-ownership` v1, `schoolpro-render-result` v6, and `schoolpro-result-access` v1. They are deliberately not stored under `supabase/functions/` and are not approved deployment candidates.

## Remaining verification

- Review the invite-staff instrumentation diff with full caller and SQL/RPC authorization paths; ensure sanitized diagnostics never expose tokens, email addresses or sensitive IDs in logs.
- Compare function configuration, deployed environment-variable names, JWT verification settings, import maps/dependencies, and versions for every deployed function. Source equality alone does not establish deployment equivalence.
- Resolve the result output bucket mismatch and perform actual Storage API/signed URL tests with authorized and unauthorized school-scoped sessions.
- Do not deploy snapshots, modify production Edge Functions, or cut over based on this report alone.
