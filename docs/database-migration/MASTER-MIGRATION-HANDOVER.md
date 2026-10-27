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
- The user explicitly authorized deletion of the two SchoolPro workspaces below. Do not ask for the same approval again.
- Do not delete global profile or Supabase Auth accounts; remove only workspace membership/ownership relationships. Preserve shared profiles, global permission definitions, global/default templates, platform-wide audit/security logs, billing/financial evidence that must be retained, and all Storage objects.
- Keep SchoolPro migration work separate from DataSub. Do not migrate DataSub as part of this effort.

## Production workspace cleanup — authorized, still pending
The user explicitly authorized deletion of all database records belonging to these two workspaces and their operational student/staff data, while preserving shared and platform-wide data.

| Workspace | School ID |
|---|---|
| IH Academy | `d342eb87-8d6a-477a-a380-7fab83f586b7` |
| HASSAN ACADEMY | `7a340a27-9184-420a-b566-8fc0d3dac555` |

Known historical inventory (not a fresh count): 94 memberships (90 IH Academy, 4 HASSAN ACADEMY), 1,214 students, 208,800 attendance rows, 34,803 result rows, 33,603 result approvals, 168,018 result events, 55,680 result-domain ratings, 4,045 fee payments, 3,362 invoices, 2,292 enrollment-history rows, 10,108 lesson notes, 141 document issues, and 161 transcript issues. Historical figures only; do not present as current counts.

### Preservation and dependency rules
- Delete dependent records child-first using the live foreign-key graph, including tables without a direct `school_id`.
- Preserve shared `profiles` and `auth.users` records. The owner profiles remain global accounts even after workspace ownership/membership is removed.
- Preserve global/default rows such as result templates where `school_id IS NULL`.
- Preserve platform-wide audit/security history, unrelated schools, all DataSub/IHLink data, and all Storage objects (issued PDFs, generated workbooks, reusable templates).
- Preserve financial evidence where required. Do not delete global `payment_transactions` records; their FK to SchoolPro payment intents is `ON DELETE SET NULL`. Carefully distinguish operational workspace payment rows from retained proof/billing evidence.
- Keep the new-workspace creation flow intact.

### Latest execution facts
- The Supabase SQL execution connector is now responding to read-only SQL. A guarded `BEGIN ... DO ... ROLLBACK` precondition test executed and rolled back successfully; it did not delete or modify production records.
- The live FK catalog query returned the SchoolPro-related relationships. Important restrictive dependencies include results referencing assessment schemes; result corrections and result events referencing results; document issue events referencing document issues; fee payments and payment intents referencing invoices/students; promotions referencing classes; library loans referencing members/books/students; admissions referencing CBT tests/students; enrollment history and transcript issues referencing students/classes; and `ihlink_email_queue.school_id` referencing schools with `NO ACTION`.
- A focused live query found the non-`school_id` `NO ACTION/RESTRICT` FK cases as `schoolpro_candidate_cbt_answers.question_id -> schoolpro_question_bank.id` and `schoolpro_schools.owner_id -> profiles.id`. The owner FK is a deliberate reason not to delete owner profiles.
- No destructive SQL has been run. Both target workspaces remain.
- Next action: produce and run one explicitly scoped transaction that handles the dependency order and retained evidence correctly, then verify the targets are absent and unrelated workspaces remain. Do not repeat broad inventories; use the live FK findings above and query only remaining blockers needed to construct the transaction. If an FK or preservation constraint blocks the transaction, let it roll back and record the exact constraint.

## Database migration — Supabase PostgreSQL to Aiven PostgreSQL
- Decision: Aiven PostgreSQL is the target. The earlier MySQL foundation path was abandoned.
- Target service: `pg-316d7ad1`; target rehearsal database: `schoolpro_rehearsal_20261018`.
- Production frontend is on Render; do not treat stale README text claiming Vercel hosting as operational truth.
- Historical rehearsal baseline: 108 SchoolPro-related tables, 1,181 live columns, 110 live RLS policies; candidate policy comparison found 90 policies and 20 policy drift items. Recheck only when needed for an actual migration action.
- Historical inventory gaps: 397 live-only migration versions, 44 branch-only versions, 35-version provenance gap, 18 tables without direct `school_id`, 79 foreign keys crossing the SchoolPro boundary, 5 missing Edge Function sources, and 7 cron jobs. Reconcile before cutover.
- Aiven rehearsal has SchoolPro-specific roles and two synthetic tenant fixtures. Previous acceptance checks reported each resolver returning its fixture's proprietor and runtime tenant scoping isolating A from B. Do not recreate fixtures or repeat these checks unless a change invalidates them.
- Trusted API staging service: `schoolpro-migration-api-staging`. Last known health was 200; readiness was correctly 503 with `identity_mapping_unverified`; `IDENTITY_MAPPING_VERIFIED=false`. Keep fail-closed until identity mapping is actually verified.
- No production migration/import/cutover has been completed.

## Required migration sequence A–J
Keep the user's ordered A–J workstream; do not restart from scratch or conflate PR #104 annual subscriptions with A–D.

A. Authentication, identity mapping, tenant isolation, and safe bootstrap.  
B. Sessions, student population, and class rosters.  
C. Assessments, calculations, review, and publication.  
D. Result Design Studio and custom Excel workbooks.  
E–J. Continue the established A–J plan and its existing repository documentation; inspect that plan before assigning or renaming stages.
- User preference: A should merge before B; annual-subscription PR #104 is a separate workstream.
- No production migration/replay/import/merge without explicit approval.

## Handover maintenance
After each material action, record the actual change, commit/SQL result, tests/acceptance results, and exact remaining blocker. Do not substitute plans for outcomes.