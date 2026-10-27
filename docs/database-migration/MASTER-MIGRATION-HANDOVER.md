# SchoolPro Master Migration and Production Cleanup Handover

**Last updated:** 2026-10-27  
**Repository:** `Hassan-625/IHLink-SchoolPro`  
**Production frontend:** Render — https://ihlink-schoolpro.onrender.com  
**Shared Supabase project:** `lnqsroyiybutkfngbyge` (IHLink Platform, West EU Ireland)  
**Aiven PostgreSQL target:** service `pg-316d7ad1`; database `schoolpro_rehearsal_20261018`  
**Status:** Migration and production workspace cleanup are NOT complete.

## Operating rules
- Audit-first; preserve the live production architecture and shared IHLink/DataSub data.
- Do not describe a step as completed unless an action and its result were observed.
- Do not repeat completed checks unless new evidence requires them. Continue from the last known state and record material outcomes here.
- No production data migration, replay, import, merge, destructive SQL, or Storage deletion without the user's explicit authorization. The user has explicitly authorized deletion of the two SchoolPro workspaces listed below.
- Do not delete global profile or Supabase Auth accounts; remove only workspace membership/ownership relationships. Preserve shared profiles, global permission definitions, global/default templates, platform-wide audit/security logs, billing/financial evidence that must be retained, and all Storage objects.
- Keep SchoolPro migration work separate from DataSub. Do not migrate DataSub as part of this effort.

## Production workspace cleanup — authorized, still pending
The user explicitly authorized deletion of all database records belonging to these two workspaces and their operational student/staff data, while preserving shared and platform-wide data.

| Workspace | School ID |
|---|---|
| IH Academy | `d342eb87-8d6a-477a-a380-7fab83f586b7` |
| HASSAN ACADEMY | `7a340a27-9184-420a-b566-8fc0d3dac555` |

Known historical inventory (not a fresh count): 94 memberships (90 IH Academy, 4 HASSAN ACADEMY), 1,214 students, 208,800 attendance rows, 34,803 result rows, 33,603 result approvals, 168,018 result events, 55,680 result-domain ratings, 4,045 fee payments, 3,362 invoices, 2,292 enrollment-history rows, 10,108 lesson notes, 141 document issues, and 161 transcript issues. These are historical figures only; do not treat them as verified current counts.

### Cleanup constraints
- Delete child/dependent records before parent records, respecting all foreign keys and triggers. There are many dependent tables without a direct `school_id`; use the live FK graph, not just a list of tables with `school_id`.
- Preserve shared `profiles` and `auth.users` records. The two owner profiles were previously found to have no other workspace ownership/membership, but they must remain as global accounts.
- Preserve global/default rows such as result templates where `school_id IS NULL`.
- Preserve platform-wide audit/security records and financial/billing evidence. Workspace operational history (e.g. result workflow events) may be removed as workspace data where appropriate; do not confuse it with global audit logs.
- Preserve all Storage objects and files, including issued-document PDFs, generated result workbooks, and reusable template files.
- Keep unrelated schools/workspaces and all DataSub/IHLink data unchanged.
- Ensure new customers can create workspaces after cleanup.

### Execution status and next action
- No production deletion has been executed; both workspaces remain.
- The Supabase SQL execution connector was blocked by its safety checks, including for a read-only query. Do not claim this is a database-side SQL error or bypass the restriction with the migration tool.
- Continue using Supabase SQL Editor or another explicitly supported authorized database execution path. Execute one carefully scoped transaction, using the full FK dependency graph and explicit exclusions above; include a precondition that the two exact target IDs and names match, row counts/logging for affected records, and post-commit checks that both target workspaces are absent and unrelated workspace counts/records are unchanged.
- If the transaction cannot be executed through an available authorized path, report the specific blocker and provide the next executable action; do not repeat generic inventory/verifications or imply progress that did not occur.

## Database migration — Supabase PostgreSQL to Aiven PostgreSQL
- Decision: PostgreSQL on Aiven is the target. The earlier MySQL foundation path was abandoned.
- Target service: `pg-316d7ad1`; target rehearsal database: `schoolpro_rehearsal_20261018`.
- Frontend remains hosted on Render; do not use stale repository README statements claiming production is hosted on Vercel as the current operational truth.
- The rehearsal baseline was previously observed to have 108 SchoolPro-related tables, 1,181 live columns, and 110 live RLS policies; candidate policy comparison found 90 policies and 20 policy drift items. Recheck only when needed to execute the next migration step.
- Inventory gaps previously recorded: 397 live-only migration versions, 44 branch-only versions, 35-version provenance gap, 18 tables without direct `school_id`, 79 foreign keys crossing the SchoolPro boundary, 5 missing Edge Function sources, and 7 cron jobs. These are historical audit findings and require reconciliation before cutover.
- Aiven rehearsal has been configured with SchoolPro-specific roles and two synthetic tenant fixtures for isolation testing. Previous acceptance checks reported the resolver returning each fixture's proprietor and the runtime tenant scope isolating A from B. Do not recreate fixtures or repeat these checks unless a new change invalidates them.
- A separate trusted API staging service exists: `schoolpro-migration-api-staging`. Its last known health was 200, while readiness was correctly 503 with `identity_mapping_unverified`; `IDENTITY_MAPPING_VERIFIED=false`. Keep it fail-closed until the Supabase identity mapping is actually verified.
- No production migration/import/cutover has been completed.

## Required migration sequence A–J
Keep the user's ordered A–J workstream; do not restart from scratch or conflate PR #104 annual subscriptions with A–D.

A. Authentication, identity mapping, tenant isolation, and safe bootstrap.
B. Sessions, student population, and class rosters.
C. Assessments, calculations, review, and publication.
D. Result Design Studio and custom Excel workbooks.
E–J. Continue the established A–J plan and its existing repository documentation; inspect the existing plan before assigning or renaming these stages. Preserve dependencies and acceptance gates.
- User preference recorded: A should merge before B; annual-subscription PR #104 is a separate workstream.
- No production migration/replay/import/merge without explicit approval.

## Handover maintenance
Update this document after each material database, API, migration, or cleanup action, recording:
1. what was actually changed and where;
2. commit/SQL execution reference and result where available;
3. tests/acceptance results;
4. what remains blocked and the exact next action.
Do not replace actual outcomes with planned work.