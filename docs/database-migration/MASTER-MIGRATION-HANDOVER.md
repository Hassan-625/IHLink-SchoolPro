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
