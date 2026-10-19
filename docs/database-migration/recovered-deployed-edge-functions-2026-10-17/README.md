# Recovered deployed Edge Function source snapshots — 2026-10-17

These files were retrieved read-only from the live Supabase project `lnqsroyiybutkfngbyge` using the Edge Function source endpoint and committed as **forensic snapshots**, not as approved deployable source. They are intentionally stored under `docs/database-migration/`, not `supabase/functions/`, to avoid accidental deployment or treating recovered production code as a reviewed fix.

| Function | Live version | verify_jwt | Source SHA-256 reported by Supabase | Snapshot |
|---|---:|---:|---|---|
| `schoolpro-owner-access` | 3 | `true` | `7446cdf3322e265ff8ca90536752f24333e728245e7a4504a5af78dc60dfa802` | [index.ts](schoolpro-owner-access/index.ts) |
| `auth-handoff` | 12 | `false` | `8506d14262c74515d7b7d13b307a30bfa92dce86cb38546df115b1e6ddd95582` | [index.ts](auth-handoff/index.ts) |
| `schoolpro-transfer-ownership` | 1 | `true` | `8b075a7706217a7aabd72862c2445fc3e43db26a7089bdad325e56b3cd0d442b` | [index.ts](schoolpro-transfer-ownership/index.ts) |
| `schoolpro-render-result` | 6 | `true` | `f87b6ad094270eabef3d5f2919e5c9acffb7e911059c28b057068be265542461` | [index.ts](schoolpro-render-result/index.ts) |
| `schoolpro-result-access` | 1 | `true` | `4b45e20029d5cd7fa5f334972fee39eebe2bb0c55c4b989175053d326f36ce9a` | [index.ts](schoolpro-result-access/index.ts) |

## Important handling notes
- The bytes are the source returned for the currently deployed version at retrieval time; they do not establish historical source for prior versions.
- No function was deployed, edited in Supabase, or invoked with privileged actions by this recovery.
- Before moving any snapshot into `supabase/functions/`, compare it against app callers, SQL/RPC grants and behavior, secret/env dependencies, and the trusted API target architecture; add tests and explicit review.
- The result renderer and result-access snapshots use bucket `school-result-templates`. The app-side generated-output mapping uses `schoolpro-result-outputs`; this mismatch is still unresolved and must be tested through real Storage API calls and signed URLs before any change.
