# Application dynamic call-site review — SchoolPro Aiven migration

**Date:** 2026-10-17  
**Branch/source reviewed:** `migration/mysql-schoolpro-foundation`  
**Purpose:** Continue the existing migration audit from the completed static call-site manifest; identify dynamic dispatch that needs resolution before any API cutover.  
**Safety:** Read-only source review. No application code, production data, database configuration, or deployment changed.

## Existing evidence reused (not repeated)
- The 107-table candidate inventory is already documented in `SCHOOLPRO-SOURCE-INVENTORY-ALLOWLIST-2026-10-17.md` and the per-table ownership register.
- The static manifest index covers 190 `src/**/*.{ts,tsx,js,jsx}` files across 13 JSONL shards. Parsing the 13 committed shards returned 463 scan records. This is a line-scan candidate manifest, not an AST/runtime call graph.
- The source remains coupled directly to `@supabase/supabase-js` in the browser. Supabase Auth and Storage are planned to remain in place for the first database rehearsal; this does not remove the need to route SchoolPro table/RPC operations safely to Aiven through a server-side boundary.
- The migration-ledger source recovery and 44-version branch-only disposition register are already present. They remain provisional: recovered SQL and catalog object-name matches do not prove complete behavior parity or deployment history.

## Dynamic dispatch findings

### Bounded dispatch sets found in source
| Source | Dynamic expression | Bounded target set / evidence | Disposition |
|---|---|---|---|
| `src/pages/schoolpro/SchoolProModulePage.tsx` | `supabase.from(d.table)` | `d` comes from a local constant `defs` map with exactly 10 literal tables: `schoolpro_admissions`, `schoolpro_timetable_entries`, `schoolpro_assignments`, `schoolpro_cbt_tests`, `schoolpro_library_books`, `schoolpro_transport_routes`, `schoolpro_hostel_rooms`, `schoolpro_inventory_assets`, `schoolpro_discipline_records`, `schoolpro_announcements`. | Bounded client dispatch, but each endpoint must be mapped to an authenticated server-side route and retain the current school/session predicates and write validation. |
| `src/pages/schoolpro/SchoolProWorkflowActions.tsx` | `supabase.from(table)` | Local `kind` switch selects only `schoolpro_library_loans`, `schoolpro_student_transport`, or `schoolpro_hostel_allocations`. | Bounded read set; route through server-side authorization and retain school/session scoping. |
| `src/pages/schoolpro/SchoolProWorkflowActions.tsx` | `supabase.rpc(name,args)` | Nine literal RPC targets found at call sites: `borrow_schoolpro_library_book`, `assign_schoolpro_transport`, `schoolpro_allocate_hostel`, `adjust_schoolpro_inventory`, `create_schoolpro_progression`, `review_schoolpro_leave`, `return_schoolpro_library_book`, `schoolpro_vacate_hostel`, `apply_schoolpro_promotion`. The helper accepts a string, so future callers must not supply arbitrary names. | Finite current set; enumerate signatures, authorization, side effects and idempotency before moving each operation. Add an explicit allowlist at the API boundary. |
| `src/components/SchoolProOnboardingStatus.tsx` | Conditional `supabase.rpc(...)` | Only `request_schoolpro_workspace_demo` or `create_schoolpro_workspace`. | Bounded dispatch; workspace creation and subscription/demo side effects need separate server API contracts and replay-safe behavior. |
| `src/pages/schoolpro/SchoolProResultTemplates.tsx` | Conditional `db.rpc(...)` | Only `schoolpro_review_result` or `schoolpro_printable_result`. | Bounded dispatch; preserve coordinator/reviewer authorization and released-result rules. |
| `src/components/schoolpro/DocumentDesign.tsx` | `supabase.storage.from(bucket)` | `bucket` is passed as a prop and used for signed URLs and uploads; this file alone does not prove the complete caller allowlist. | **Open:** enumerate every caller and resolve literal bucket values and path policy before changing storage behavior. Keep Supabase Storage during the first DB rehearsal. |

### Authentication and fixed Edge Function calls
The scan includes direct Supabase Auth operations for session lifecycle, password sign-in/sign-up/reset, OTP verification, and native session exchange. These are known direct calls, not arbitrary dynamic function dispatch. They remain tied to Supabase Auth for the first rehearsal; do not copy `auth.users`, session, refresh-token or MFA data into Aiven.

The manifest also names fixed Edge Function invocations including `invite-school-staff`, `schoolpro-owner-access`, `auth-handoff`, `schoolpro-transfer-ownership`, `schoolpro-render-document`, `schoolpro-email-worker`, `schoolpro-student-login`, and `schoolpro-account-login`. Each caller/function pair needs a disposition: remain on Supabase, call a new server API, or be deliberately retired. Preserve JWT/signature checks, tenant binding, email/payment idempotency, and object authorization. A source name or `verify_jwt` setting alone is not behavior evidence.

## Migration implications
1. Do **not** try to point browser Supabase clients at Aiven. Aiven is PostgreSQL, not a Supabase REST/Auth/Storage replacement; no privileged Aiven connection string belongs in browser/mobile code.
2. Use the existing candidate table allowlist and ownership register; do not redo the 107-table inventory. Resolve the remaining 18 no-`school_id` tables and shared FKs at row/parent level before any approved data transfer.
3. For each fixed RPC/table call, record request/response shape, role and tenant checks, transaction boundary, trigger/routine side effects, external calls, idempotency, and negative tests. Use explicit route allowlists rather than accepting a client-provided table or RPC name.
4. Reconcile this branch's call-site list against the deployed `main` commit before implementation. The manifest was scanned from `migration/mysql-schoolpro-foundation`; Render's latest recorded live frontend commit is `29856dff17ea8a3bc8bb31b7900967b7df9d316b`. Do not assume branch/live parity.
5. After route mapping, run the first rehearsal on the secured disposable Aiven target `pg-3898d936` only after confirming network restrictions and that it contains no production data. Rehearse schema and synthetic fixtures first; do not import production data or change Render production settings without explicit approval.

## Exact next items
- Resolve all callers of `DesignAssets`/`useDesignImages` and their bucket values.
- Finish an AST/manual pass for indirect, aliased, multiline, and wrapper-mediated Supabase calls; the 463 manifest rows are not an exhaustive call graph.
- Complete row-level ownership and 79 cross-boundary FK dispositions, especially `auth.users`, shared `profiles`, `virtual_accounts`, shared payment ledgers, unscoped catalog/security rows, and transient credential challenges.
- Continue object-by-object schema/semantic comparison for 397 live-only ledger payloads and the 44 branch-only files. The latter already have a per-version provisional disposition register; unresolved rows must not be reclassified as deployed from names or catalog matches alone.
- Keep production export/import, migration replay, Render environment changes, deployments and merges blocked pending reviewed rehearsal evidence and explicit owner approval.

**Current status:** static manifest reviewed for bounded dynamic dispatch; application/API migration is not implemented. No production migration has been run.
