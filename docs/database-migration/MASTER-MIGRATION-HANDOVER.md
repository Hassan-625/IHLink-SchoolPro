# SchoolPro Master Migration and Production Cleanup Handover

**Last updated:** 2026-10-27  
**Repository:** `Hassan-625/IHLink-SchoolPro`  
**Production frontend:** Render — https://ihlink-schoolpro.onrender.com  
**Shared Supabase project:** `lnqsroyiybutkfngbyge` (IHLink Platform, West EU Ireland)  
**Database direction (confirmed 2026-10-28):** Continue on the existing Supabase PostgreSQL project; Render remains the production frontend host. MySQL and Aiven are no longer target platforms for SchoolPro.  
**Status:** No database-platform migration is planned. Continue only with narrowly scoped Supabase security/application work; preserve existing real data and do not seed business/demo records.

## Operating rules
- Preserve the live production architecture and shared IHLink/DataSub data.
- Do not repeat completed checks unless new evidence requires them. Continue from the last known state.
- The user explicitly authorized deletion of the two SchoolPro workspaces below; do not ask for the same approval again.
- Do not delete global `profiles` or Supabase Auth accounts. Preserve global/default templates, platform-wide audit/security history, financial evidence that must be retained, and all Storage objects.
- Keep SchoolPro migration work separate from DataSub.

## Production workspace cleanup — authorized, pending a trigger-policy blocker

| Workspace | School ID |
|---|---|
| IH Academy | `d342eb87-8d6a-477a-a380-7fab83f586b7` |
| HASSAN ACADEMY | `7a340a27-9184-420a-b566-8fc0d3dac555` |

Historical, not freshly verified: 94 memberships (90 IH Academy, 4 HASSAN ACADEMY), 1,214 students, 208,800 attendance rows, 34,803 results, 33,603 result approvals, 168,018 result events, 55,680 result-domain ratings, 4,045 fee payments, 3,362 invoices, 2,292 enrollment-history rows, 10,108 lesson notes, 141 document issues, 161 transcript issues.

### Preservation and dependency rules
- Delete dependent workspace records child-first, including dependent tables without `school_id`.
- Preserve owner/global `profiles` and `auth.users`; preserve global/default templates where `school_id IS NULL`.
- Preserve unrelated schools, all DataSub/IHLink data, platform-wide audit/security history, required billing evidence, and all Storage objects.
- Global `payment_transactions` must remain; their FK to SchoolPro payment intents uses `ON DELETE SET NULL`.
- Ensure the workspace-creation flow remains usable.

### Latest execution facts and exact blocker
- Read-only SQL works through the Supabase SQL connector.
- An earlier full cleanup transaction failed at `schoolpro_lesson_notes`; that transaction rolled back completely. After the user clarified that workspace-specific operational records must be removed while reusable roles/permissions remain, a separate scoped transaction removed all 10,108 lesson-note rows belonging to the two target workspace IDs. The transaction held an access-exclusive lock on `schoolpro_lesson_notes`, temporarily disabled only `schoolpro_lesson_workflow`, deleted rows only for the two approved school UUIDs, and re-enabled the trigger before commit. A post-delete count returned `0` remaining target lesson notes. Other workspace data has not yet been removed by the successful transaction.
- Exact trigger behavior before the scoped removal: `private.schoolpro_validate_lesson_workflow()` requires a non-null `auth.uid()` and blocks deletion of `submitted` or `approved` notes. The trigger is enabled again. The user's explicit instruction now establishes that all workspace-specific lesson-note records are to be removed; reusable role/permission definitions must remain.
- This is an application-level preservation rule, not a foreign-key problem. Do not disable the trigger or alter its function just to force cleanup. Do not attempt to impersonate a user through arbitrary JWT settings.
- The FK catalog found one non-`school_id` restrictive dependency: `schoolpro_candidate_cbt_answers.question_id -> schoolpro_question_bank.id` (`NO ACTION`); the cleanup transaction explicitly accounted for this before the trigger stopped execution.
- User clarified that workspace-specific records are disposable even when they reference reusable role labels or permissions: delete the records, retain role/permission definitions. This explicitly includes submitted and approved lesson notes. The scoped lesson-note deletion is complete; continue child-first cleanup of the remaining workspace records, preserving global profiles/auth accounts, reusable roles/permissions, global templates, all Storage objects, unrelated schools, shared IHLink/DataSub data, and required platform-wide/financial evidence. Do not delete a staff member's global profile or auth account merely because their workspace membership is removed.

## Database platform direction — Supabase retained

- Confirmed by the user on 2026-10-28: continue using the existing Supabase PostgreSQL project `lnqsroyiybutkfngbyge` (IHLink Platform, West EU Ireland); production frontend remains on Render at https://ihlink-schoolpro.onrender.com.
- MySQL and Aiven are not target platforms for SchoolPro. The Aiven rehearsal and MySQL foundation were experiments only; no production cutover should be performed.
- Do not create or seed demo/business records. Do not populate schools, students, sessions, classes, staff, results, subscriptions, or other operational tables with fabricated records.
- Database changes are limited to what is necessary for application execution and security: authentication/identity mapping, role and permission definitions, RLS policies, tenant-isolation controls, constraints, indexes, triggers, and functions. Every change must have a concrete need and scoped validation.
- Preserve existing real data, shared IHLink/DataSub data, global profiles and Auth accounts, reusable role/permission definitions, global/default templates, audit/security history, required financial evidence, and Storage objects unless separately authorized.
- The trusted API staging work for the Aiven experiment is no longer part of the SchoolPro target architecture. Do not use it to route production traffic or migrate data.
- No production migration/import/cutover is planned. Do not run destructive cleanup or broad migrations as part of this direction change.
- Read-only production recheck on 2026-10-28: all eight operational tables listed above still have RLS enabled but `FORCE ROW LEVEL SECURITY=false`; they are owned by `postgres`, whose role bypasses RLS. No schema changes or data writes were made by this check. This confirms the known Stage A posture gap remains; it does not by itself authorize applying a migration.
- Closed as out of scope on 2026-10-28, retaining branches/history: PR #107 (MySQL migration foundation) and PR #109 (Aiven rehearsal API foundation).

## Required migration sequence A–J
A. Authentication, identity mapping, tenant isolation, safe bootstrap.  
B. Sessions, student population, class rosters.  
C. Assessments, calculations, review, publication.  
D. Result Design Studio and custom Excel workbooks.  
E–J. Continue the established A–J plan in existing repository documentation; do not rename stages without inspecting that plan.
- A should merge before B. Annual-subscription PR #104 is a separate workstream.
- No production migration/replay/import/merge without explicit approval.

## Handover maintenance
Record actual changes, commit/SQL outcomes, tests, and exact blockers after material actions. Do not substitute planned work for outcomes.

## 2026-10-28 workspace cleanup status
- Deleted the IH Academy and HASSAN ACADEMY workspace rows and their direct school-scoped records in SchoolPro, including 10,108 lesson notes, payroll records, memberships, students, classes, attendance, results, result events, invoices, payment-related school records, document issues, and other scoped rows. Both target school IDs now return zero rows; the verified core-table counts (schools, memberships, students, classes, payroll, lesson notes, results, attendance) are all zero.
- Removed the matching HASSAN ACADEMY demo request that became unlinked when its school row was deleted. A generated verification across all public `schoolpro_%` tables and `ihlink_email_queue` found no rows still carrying either target `school_id`.
- Global profile/auth accounts and reusable role/permission definitions were intentionally retained. A performance index `idx_schoolpro_result_events_result_id` was added to support safe cleanup of result-linked events. Application triggers disabled for scoped deletions were re-enabled; PostgreSQL foreign-key triggers were not disabled.
- Remaining follow-up: verify and remove any workspace-specific Storage objects, if in scope, and check global-profile references without deleting global accounts. Do not mark Storage cleanup complete until inventory is checked.


## Stage A continuation — Supabase-only (2026-10-28)

- Began focused Stage A continuation on existing draft PR #106; no merge, production migration, data write, or deployment was performed.
- Current PR head inspected: `077d7999f61fd70bdaa4da10a0d90a6c344725d7`. Payment-page validation run #1383 passed; SchoolPro CI run #1656 failed only in the conditional live `tenant-acceptance` job. The other seven jobs passed. The failing authenticated probe retried `schoolpro_result_approvals` and ended with `canceling statement due to statement timeout`.
- Read-only production catalog inspection found `schoolpro_result_approvals` has no index on `school_id`; its existing indexes are on `id` and `result_id`. The draft migration `20261017180000_schoolpro_operational_tenant_indexes.sql` already proposes the required `school_id` index (along with indexes for other operational tables). Existing feature policies include `result approvals school read` (`private.has_school_access` plus `private.schoolpro_module_allowed`) and `result approvals leadership write`; these were inspected, not modified.
- Production `schoolpro_result_approvals` is approximately 9.7 MB total with an estimated live row count of zero; do not infer that it contains no dead tuples from planner statistics alone. The index is the first narrow performance fix to validate. Do not weaken or skip the security acceptance check merely to get green CI.
- Next gate: review the existing forward-only tenant-integrity and operational-index migrations together, then obtain explicit authorization before applying any production schema change. After the approved migration, rerun the existing read-only two-school acceptance job and verify the index/policy catalog. No demo or fabricated records are needed.


## Detailed Stage A operational migration review — 2026-10-28

**Review only. No production DDL/DML, migration application, index creation, deployment, merge, or business/demo data creation occurred.** Reviewed PR #106 head `077d7999f61fd70bdaa4da10a0d90a6c344725d7`.

### Files reviewed
- `supabase/migrations/20261016160000_schoolpro_repair_operational_tenant_integrity.sql`
- `supabase/migrations/20261017180000_schoolpro_operational_tenant_indexes.sql`
- Related RLS posture migration `supabase/migrations/20261017170000_schoolpro_forward_operational_tenant_isolation.sql`
- Disposable PostgreSQL integration SQL and static migration contract tests.

### Findings

1. **Blocker before approval — member-permission tenant reassignment is not made immutable.** The integrity migration's general validator rejects `school_id` reassignment for the eight operational tables and parent tables, and it adds a separate trigger to validate that `schoolpro_member_permissions.member_id` belongs to the row's `school_id`. However, that separate trigger does not compare `OLD.school_id` with `NEW.school_id`. An update that changes both `school_id` and `member_id` to a member in another school can therefore pass this trigger if the caller can perform the update. Current authenticated RLS policy `school permission manage` scopes writes by school, but that is not the same as enforcing the intended invariant for privileged/service-side writes. Decide whether permission rows must be tenant-immutable (recommended for consistency); if yes, add a dedicated reassignment rejection and a disposable PostgreSQL negative test covering a simultaneous school/member change. Do not apply the migration until resolved.

2. **Operational relationship checks are otherwise directionally sound.** The SECURITY DEFINER trigger functions use an empty `search_path`, fully qualify referenced application tables, revoke direct EXECUTE from `PUBLIC`, `anon` and `authenticated`, reject missing or cross-school parent references, and lock referenced subject/class/result/student/member rows with `FOR SHARE` during child validation. Separate immutable-school triggers avoid replacing the existing activation/workflow trigger names. The production catalog confirms the referenced tables and columns/foreign keys exist.

3. **Trigger integration coverage is real but reduced.** The disposable PostgreSQL test executes the SQL triggers and covers cross-school references, parent tenant reassignment, preservation of representative feature-policy names, forced-RLS posture, and presence of six indexes. It is not a complete clone of production. It does not currently assert the member-permission simultaneous reassignment case described in finding 1, nor prove every live workflow against the full production trigger stack. Production has existing BEFORE triggers on calendar events, lesson notes, results, students, and operational activation guards; exact-head full-schema workflow testing remains a release gate.

4. **Index migration is narrowly scoped and non-destructive.** It checks that six required tables exist, then adds B-tree indexes on `school_id` for library books, transport routes, hostel rooms, inventory assets, result approvals, and promotions. It changes no row data or policies. Current production catalog inspection confirms those six named indexes are absent; calendar events already have `(school_id, session)`, and lesson notes already have multiple school-leading indexes. The result-approval table is approximately 9.7 MB total and its live SELECT policies combine `private.has_school_access(school_id)` with `private.schoolpro_module_allowed(school_id, 'results')`. The index addresses the missing tenant-leading access path implicated in the repeated timeout, but it does not guarantee the acceptance probe will pass until retested.

5. **Index operational consideration.** The migration uses ordinary `CREATE INDEX IF NOT EXISTS`, not `CREATE INDEX CONCURRENTLY`; applying it takes a table lock that can briefly block writes. The current reported table sizes are modest, but production stats returned zero estimated live tuples for several tables while prior plan evidence estimated roughly 33,603 result-approval rows. Treat those statistics as inconsistent/stale; do not infer the table is empty. After any separately approved rollout, verify index definitions and rerun the authenticated two-school probe/query plan. Do not weaken or skip the tenant-acceptance test.

6. **Adjacent RLS posture migration.** `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` checks all eight operational tables exist and sets ENABLE/FORCE RLS without dropping or replacing feature-specific policies. This is safer than replaying the historical policy-replacement migration. FORCE RLS does not constrain superusers or roles with `BYPASSRLS`; the migration correctly documents that limitation. Production catalog currently shows RLS enabled and FORCE false on these eight tables. The RLS posture migration remains separate from the integrity and index migrations and is not applied.

### Review disposition
- Operational-index migration: **reviewed, no SQL correctness defect found in the current six index statements; rollout remains unapproved and the live timeout remains unverified.**
- Tenant-integrity migration: **not ready for approval until the member-permission tenant-reassignment gap is explicitly resolved and tested.**
- RLS posture migration: **forward-only approach preserves existing policy definitions; it still requires approved rollout and live post-change verification.**
- PR #106 remains draft/unmerged. No production changes were made during this review.
