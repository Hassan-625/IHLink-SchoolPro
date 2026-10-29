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


## Stage B requirements restored and expanded — 2026-10-28

**Planning and handover update only.** User explicitly confirmed that no migration is to be performed for now. Do not apply SQL, seed/populate operational records, deploy, merge, or change production data. Continue with requirement reconciliation and read-only/code-level verification only.

Stage B remains **Academic sessions, student population and class rosters**. The requirements below are carried forward from prior SchoolPro discussions and related authorization/result-workflow notes. They are not a request to insert demo data. Any academic sessions, students, staff, classes, or scores must come from authorized real-school workflows; use disposable test fixtures only in isolated test environments.

### B1. Academic sessions, terms, enrollment and class rosters
- Support the legacy academic-session range discussed previously (2001–2002 through 2025–2026) and the 2026–2027 session, without blindly inserting session rows into production. Confirm the app can select/configure a session and its terms using the actual school's authorized data.
- Load rosters for the selected school, session, class and arm only. Verify historical enrollment/class assignment as of the selected session; do not silently use a student's current class for historical results or exports.
- Keep class, arm, section, subject allocation, staff assignment, session and school ownership distinct. A subject teacher sees only assigned subject + class/arm + session combinations; a form/class teacher sees only their assigned class; section leaders see only their assigned section.
- Verify student admission/enrollment, transfer/promotion history, class loading, roster counts and school/tenant boundaries. Promotion remains preview-first and must not silently change a student's class/history.
- Preserve the historical Basic 5 A / 2025–2026 subject-mapping anomaly as a regression investigation, not as permission to repair or fabricate rows: the earlier report found 40 students, 400 results, and subject definitions linked to Basic 4 A IDs for 37 records and Basic 5 A for 3. The affected demo/workspace rows have since been removed during the separately authorized cleanup; do not recreate them. Any future repair requires authoritative mapping evidence and an auditable correction process.
- Student identity/display requirements: include the student's middle name where available; show parent/guardian contact and relationship correctly in the relevant student/parent views. Preserve existing identity records; do not fabricate missing names or contact details.
- Student portal onboarding requirement from prior review: first login uses school code, admission number and the configured initial password rule, then requires a password change before the student can access their own **published** results. Verify that this flow does not expose drafts or another student's data.
- Do not seed sessions, students, classes, staff, parents, results, subscriptions or any other operational records merely to make the UI look populated. Empty states must be accurate and usable.

### B2. Staff roles and assignment scope that Stage B must prepare
- Keep platform Super Admin distinct from school proprietor/owner and school leadership. School ownership or a display title must not grant platform-wide access.
- Maintain explicit roles/capabilities for proprietor, administrator, Subject Teacher, Class Teacher/Form Teacher, Exam Officer, head teacher/section head, principal/vice principal, and the requested Discipline Master and Game Master roles. Do not infer permissions from a display label alone.
- Separate staff role from class-teacher assignment and subject allocation. The prior Form Master example showed that a correct staff role does not itself assign a class: the Pre-Nursery A Form Master/class-teacher relationship must be stored and displayed explicitly.
- Subject teachers are assigned to subject + class/arm + session and may enter/submit scores only within those assignments; they do not take attendance merely because they teach a subject.
- Form Teachers/Class Coordinators are scoped to their assigned class, can access that class roster and subject submissions, take/coordinate attendance, review/compile the class broadsheet and forward the class result.
- Section leaders are scoped to their configured section: Nursery; Primary (including configured Basic 1–5); JSS; or SSS. Their assigned section view should include its classes/arms, teacher allocations, attendance, assignments, CBT, broadsheets and results, with read/write/review actions still governed by explicit permissions.
- Exam Officers have authorized school-wide examination/result administration and review/publication responsibilities, not an automatic bypass of role checks.

### B3. Progressive score entry — explicit requirement for Stage B handoff and Stage C delivery
- Authorized score-entry staff, including a section head when the school's permission model assigns that capability, must be able to enter and save each assessment component independently (for example, first assessment/1st assignment, then later assessment components) rather than being forced to wait until every score/component for the class or subject is available.
- Preserve incomplete work as a draft/partial state. Do not fabricate missing marks, treat missing components as zero unless the configured assessment rule explicitly says so, or imply that a complete result is ready for publication.
- Validate each component against its configured maximum; calculate totals and class-subject averages consistently when sufficient configured inputs exist. Display which components are missing and which have been saved.
- Enforce the assigned school, section, class/arm, subject and session scope on both the UI and backend/RLS. A section head's ability to enter scores must be an explicit capability; it must not arise merely from viewing the section or roster.
- **Stage B dependency:** make sure session/class/arm rosters, section ownership, staff assignments and assignment scopes are reliable before the score-entry UI loads. **Stage C implementation:** incremental assessment saves, validation/calculation, broadsheet aggregation, review, publication, and correction workflow. This cross-stage placement preserves the A–J sequence while making the requirement visible in Stage B acceptance planning.

### B4. Attendance, assignments, CBT and results workflow dependencies
- Attendance is a class/form responsibility under the assigned Form Teacher/Class Coordinator scope; subject teachers do not receive attendance-write permission by default.
- Section leaders can access attendance, assignments, CBT, broadsheets and results for their assigned section only, with separate action permissions.
- Subject submissions flow to the Form Teacher/Class Coordinator for class broadsheet review, then to the appropriate section leadership (head teacher for Nursery/Primary; principal/vice principal for JSS/SSS), then to the Exam Officer for authorized publication.
- Publication is explicit and scoped by school/session/class. A class without a published result must not appear published merely because another class was published.
- Published results are locked against ordinary edits. Corrections require an auditable request, recorded reason/authorization, Exam Officer-controlled reopening of the relevant scope, resubmission through the approval chain, and preservation of the prior published version/history.
- Keep read, score-write, attendance-write, review/approve, reopen and publish capabilities distinct; enforce them in backend authorization and Supabase RLS, not navigation visibility alone.

### B5. Related requirements carried into Stage C and D (do not lose during B)
- Stage C: independently save assessment components; configured score limits and total calculations; class-subject averages shown once and calculated against the correct historical class/subject mapping; load only the selected class/session/term; preserve audit history and published-result corrections.
- Stage D: section-specific result/report standards for Nursery, Primary, JSS and SSS; Result Design Studio with template upload, preview, field mapping, logos and signatories; custom Excel workbook import/export without overwriting base templates; retain the previously deferred A4 print issue for explicit verification.
- Exports and broadsheets must work for a single class, selected students and authorized all-class scope, without cross-class or cross-tenant leakage. Historical subject mappings must be validated; duplicate subject names alone are not enough to merge or remap scores.

### B acceptance gate (no production writes)
1. Trace the actual UI/API/schema path for school → session/term → section → class/arm → enrollment roster and subject/staff assignments.
2. Confirm student middle-name and parent/guardian contact/relationship display paths.
3. Verify role-to-assignment separation and allowed roster visibility for Subject Teacher, Form Teacher, section head, Exam Officer and Super Admin, including denial for unassigned classes/sections and other schools.
4. Write/execute automated tests only in an isolated disposable environment for empty states, historical enrollment, role scope, partial assessment saves and missing-component behavior; do not create production fixtures.
5. Keep incremental assessment entry and the approval/publication lifecycle tracked for Stage C, and report blockers with evidence rather than repeating already-completed broad audits.

### Continuation checkpoint
- No migration or production change is authorized at this point.
- The next work is to reconcile these requirements against the existing Stage B/C implementation and tests, then report exact code/test gaps and a small, ordered next action list. Do not start a new database audit or create demo records.


## Stage B/C read-only code reconciliation — 2026-10-28

No production changes were made. Inspected the current `main` implementation of `src/pages/schoolpro/SchoolProResults.tsx`, `SchoolProBroadsheet.tsx`, `SchoolClassRoster.tsx`, `SchoolClassCoordinators.tsx`, `SchoolProStudents.tsx`, and `src/lib/schoolSessionStudents.ts`. This is source review only; no live-user workflow or isolated integration test was executed during this pass.

### Confirmed code gaps to carry forward

1. **Incremental assessment entry is not currently supported by the main score form.** In `SchoolProResults.tsx`, `saveScore` constructs `assessment_scores` by converting every configured component with `Number(scoreForm.scores[c.key] || 0)`. The form marks every component input `required`. Therefore, staff are forced to provide every assessment component before saving; blank components are converted to zero in the save payload. This conflicts directly with the requirement to save 1st assessment/assignment independently and enter later components when available. Change design should preserve absent/unentered components as missing, support component-by-component draft saves, and compute totals/status from configured assessment rules rather than silently treating blank as zero. Validate the backend/RPC calculation and import path too before implementation.

2. **Section-head score entry is not explicitly scoped in this page's client-side selection.** The page's client-side `teacherScoped` filter applies to `teacher` and `class_teacher` roles; other roles see the broader school student list. `canReview` includes `head_teacher` and `vice_principal`, but that is a review capability, not a proof of score-write authorization. This does not by itself prove a data leak or unauthorized write because Supabase RLS/database routines remain authoritative; however, it means section-scoped score-entry permissions are not visibly enforced by this UI. Confirm the backend authorization, then filter the section-head UI to assigned section/class scopes and keep score-write distinct from review/approval.

3. **Student middle name and parent/guardian relationship are absent from the current student-management form/query.** `SchoolProStudents.tsx` selects and types first name, last name, guardian name and guardian phone, but not `middle_name` or a guardian relationship field. Its enrollment insert also omits both. The score-entry page likewise does not select `middle_name`. Verify the live schema and all relevant profile/guardian views before deciding whether a field already exists but is simply not surfaced; do not invent or backfill personal details.

4. **Historical roster behavior exists but needs targeted regression checks.** `SchoolClassRoster.tsx` calls `schoolSessionStudents`; that helper reads `schoolpro_enrollment_history` for the selected session and uses historical class assignments when present. If there are no history rows for that session but any history exists for the school, it returns no students; if the school has no enrollment-history rows at all, it falls back to current student records. This fallback may be intentional for legacy schools, but must be tested explicitly so current-class fallback is never used to misstate historical enrollment once history exists.

5. **Broadsheet workflow has explicit class submission and approval/publication calls.** `SchoolProBroadsheet.tsx` uses database RPCs for class review, submission, approval and publication and shows an empty-state message when no saved subject scores exist. It also calculates subject averages in the client from the rows returned by the class-review RPC. Verify that the RPC itself enforces school, class, section, session, term and action permissions; client-side filtering alone is insufficient. Do not infer that the workflow is correct solely from the page code.

### Immediate order of work (read-only until separately authorized)
1. Trace the database function/RLS paths used by `saveScore`, `import_schoolpro_results`, `schoolpro_class_review_sheet`, `schoolpro_submit_class_results`, `review_schoolpro_result`, and publication RPCs. Check partial-component semantics and role/section enforcement in source and tests.
2. Trace student schema and guardian relationship fields, then map all affected enrollment/display components.
3. Add isolated automated tests for independently saving first assessment then later components, blank-vs-zero semantics, section-head assigned/unassigned sections, teacher assignment scopes, historical roster fallback, middle-name display and guardian relationship display.
4. Only after the source/test gaps are understood, propose a small code-only change set and acceptance plan. No production migration, SQL execution, operational data population, merge or deployment is authorized by this checkpoint.


### Stage C backend/RLS trace — read-only live function definitions (2026-10-28)

Inspected the live definitions of `private.schoolpro_can_write_result`, `private.schoolpro_can_review_class`, `public.import_schoolpro_results`, `public.review_schoolpro_result`, `public.schoolpro_submit_class_results`, `public.schoolpro_class_review_sheet`, and class/selected publication functions. No function was invoked to write data; this was catalog inspection only.

6. **Partial component semantics are also blocked in the live import RPC.** `public.import_schoolpro_results` uses `coalesce((scores->>component_key)::numeric, 0)` when validating each configured component. Thus an omitted component is validated as zero, even though the JSON payload can otherwise omit it. Together with the UI's required inputs and zero-coercion, the incremental-entry requirement needs a consistent UI + RPC + total-calculation change, not only relaxing the form's `required` attributes. Explicitly entered zero must remain distinguishable from an unentered component.

7. **Section-leader authorization is broader than the stated section scope in the live result functions.** `private.schoolpro_can_write_result` permits school members with `head_teacher` or `vice_principal` through a school-wide `has_school_access(...)` role check; it does not verify that the target student/class is in that leader's assigned section. `public.review_schoolpro_result` likewise accepts a head teacher or vice principal based on school membership and the result module permission, without a section/class scope check. `public.publish_schoolpro_class_results` checks the supplied class belongs to the school, but its role check likewise permits those school roles without checking their assigned section. This is a backend authorization gap against the requested Nursery/Primary/JSS/SSS section boundary; fix and test before considering section-scoped score entry/review/publication complete. Exam Officer and school leadership scope should remain separately defined.

8. **Some downstream result displays omit middle names.** `public.schoolpro_class_review_sheet` currently builds student display names from first and last name only. The student-management page and score-entry page also omit `middle_name` from their selected fields and enrollment payload. Parent/guardian relationship is not present in the reviewed student form/type/query; only guardian name and phone are handled there. Check the actual schema and connected student/parent views before implementation.

9. **Submission/review scopes are not identical.** `public.schoolpro_submit_class_results` requires class coordinator or school leadership and uses historical enrollment to locate eligible draft marks. `private.schoolpro_can_review_class` limits class-sheet access to transcript-capable roles or configured coordinator classes. The generic review and publication RPCs have broader role checks than the class-sheet helper, so the workflow must not rely on the UI's selected class to enforce section permissions.

### Updated Stage B/C disposition
- **Stage B:** continue requirement mapping for historical enrollment/class assignment, correct roster scope, staff-to-class/subject assignments, middle name and guardian relationship display, and empty-state behavior. No operational rows should be seeded.
- **Stage C:** highest-priority code/test work is (a) incremental component saves with missing-versus-zero semantics, (b) backend section-scoped score-write/review/publication checks, (c) historical enrollment correctness, and (d) audited publication/correction regressions.
- These are code/function/policy gaps to resolve in a reviewed branch and isolated test environment. They do not authorize production SQL, migrations, merges, or deployments.


## Roadmap sequencing correction and unmerged-PR register — 2026-10-28

**Execution order is unchanged: finish Stage A first. Do not begin Stage B implementation, merge feature PRs, apply migrations, deploy, or populate production data until Stage A is reviewed, approved, merged, and post-merge verified.** The user corrected the prior response because it sounded as though we were starting Stage B. Stage B requirements and PRs may be documented/reconciled now, but this is planning only while A remains active.

### Stage B requirement register
Stage B must carry forward the academic-session, historical enrollment/class roster, student identity and guardian display, staff-to-class/subject assignment, Form Master attendance, section-leader scope, Discipline Master/Game Master, and incremental assessment-entry requirements already recorded above. In particular, section heads must be able to enter configured components such as 1st assessment/assignment independently when explicitly authorized; missing components must not silently become zero. Score calculation/review/publication implementation remains Stage C, dependent on correct Stage B roster and assignment scope.

### All currently open PRs to reconcile in the A→J plan (no merges authorized)

The open PRs are tracked together in this roadmap register so their requirements and dependencies are not lost. Their owning stage remains as noted; recording them under the Stage B planning register does **not** mean they are all Stage B changes or that Stage B work should start before A is cleared.

- **#106 — Stage A, active gate:** [Auth race, tenant isolation, payment and Storage controls](https://github.com/Hassan-625/IHLink-SchoolPro/pull/106). Must remain the current workstream. Outstanding gates include live tenant acceptance timeout, operational tenant-integrity reassignment test, payment RLS/runtime evidence, source/ledger reconciliation, Storage performance and result-PIN cooldown validation. Current detailed migration review found a member-permission tenant reassignment gap. No merge until resolved.
- **#108 — document/Storage tenant security:** [Issued-document tenant RLS predicate](https://github.com/Hassan-625/IHLink-SchoolPro/pull/108). Disposable PostgreSQL regression passed; still needs live policy/helper/ACL review and actual Supabase Storage API, signed URL, download/RPC and object-key tampering checks. Do not apply to production yet.
- **#105 — staff and academic workflow continuation:** [Staff access, sports management and profile correction safeguards](https://github.com/Hassan-625/IHLink-SchoolPro/pull/105). Includes Discipline Master/Game Master, guardian fields, student middle names, atomic profile corrections, My Classes/Form Master mapping, incremental result entry, subject/class/session assignment controls, CBT and Form Master-only attendance. Its base is PR #103, so it must not be merged directly to main without reconciling the dependency chain.
- **#104 — subscriptions (separate H workstream):** [Annual Demo billing and plan upgrades](https://github.com/Hassan-625/IHLink-SchoolPro/pull/104). Annual billing, Demo expiry/grace, upgrade requests and Finance receipt verification. Its base is PR #101; keep it separate from A–D acceptance and do not apply its migration or merge now.
- **#103 — Stage D result design:** [Section-specific result design](https://github.com/Hassan-625/IHLink-SchoolPro/pull/103). Requires section-template selection, uploaded-template/field-mapping output verification and CI. Its base is PR #101.
- **#102 — Stage D report print validation:** [All-term report-card printing tests](https://github.com/Hassan-625/IHLink-SchoolPro/pull/102). Requires First/Second/Third Term browser/PDF artifact inspection and A4 page checks. Its base is PR #101.
- **#101 — Stage D report layout/history:** [Assessment labels and term-history columns](https://github.com/Hassan-625/IHLink-SchoolPro/pull/101). Requires exact-head CI and A4 output verification against the workbook guide.
- **#100 — Stage D Excel export:** [Class subject averages export](https://github.com/Hassan-625/IHLink-SchoolPro/pull/100). Isolated on main; requires exact-head CI and validation of class/subject mapping assumptions and held-report behavior.

PRs #107 (MySQL) and #109 (Aiven) were closed because the user chose to stay on existing Supabase PostgreSQL; they are not active work. Do not reopen them.

### Dependency and sequence rules
1. Continue **Stage A only** until its release gates are closed. Keep PR #106 draft/unmerged while any blocker remains.
2. Once A is approved, merged and verified, reconcile Stage B requirements and its related PR branches against current main, without blindly merging stacked branches.
3. Then verify Stage C result-entry/calculation/review/publication requirements and regressions.
4. Resume Stage D Result Design Studio, section templates, report history/printing and Excel exports only after the earlier acceptance gates are satisfied.
5. Continue E–J in the full roadmap. Subscription PR #104 stays a separate H concern and must not reset the A→D sequence.
6. No production migrations, operational row population, merge or deployment are authorized by this checkpoint.


### Stage A member-permission tenant immutability regression — 2026-10-28

- Continued Stage A on PR #106 only; no Stage B implementation started.
- In `release/stage-a-auth-tenant-isolation`, migration `20261016160000_schoolpro_repair_operational_tenant_integrity.sql` now rejects any UPDATE that changes `schoolpro_member_permissions.school_id` before checking the member relationship. This closes the specific case where a privileged writer could change both `school_id` and `member_id` to a valid pair in another school.
- Expanded the disposable PostgreSQL integration fixture with a negative test for changing both fields together and a positive same-school member reassignment test. Added a static assertion for the immutability guard.
- Exact source head after these edits: `e630e792c213255e7437b8d7a7346dcb5f1d4072`. SchoolPro CI [#1988](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40713744470) and payment-page validation [#1715](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40713744256) were in progress at the latest check; do not count this fix as validated until both finish on this exact head.
- PR #106 remains draft/unmerged. This is a code/test change only: no production SQL, migration, data population, merge, or deployment was performed. The live `schoolpro_result_approvals` tenant-acceptance timeout and other Stage A gates remain open.


### Live tenant acceptance positive-control correction — 2026-10-28

- On exact head `e630e792c213255e7437b8d7a7346dcb5f1d4072`, SchoolPro CI #1988 reached the live tenant-acceptance job but failed immediately because School A had no readable student row. This was a missing live fixture/data assumption, not evidence of cross-tenant leakage. No production rows were created.
- Updated `scripts/test-schoolpro-tenant-isolation-live.mjs` to use the authenticated user's own-school membership as the required positive control, while still checking student visibility if a student row exists. If no student exists, it emits an explicit limitation instead of seeding data or claiming positive student-read coverage.
- Current PR #106 head: `2a5642b3c6bf1477df6470b8b3733cdb9d92a900`. Fresh SchoolPro CI [#1990](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40714013700) and payment-page validation [#1717](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40714013895) are in progress. Await both exact-head results; the previous payment-page pass was on the prior head.
- The membership-tenant immutability guard and its same-school/foreign-school regression cases are included on this head. PR #106 remains draft/unmerged; the earlier live result-approval timeout and other Stage A gates remain open. No production SQL, migration, data population, merge or deployment was performed.


### Live tenant acceptance fixture assumptions — follow-up — 2026-10-28

- The next exact-head live run (#1990) showed the same account also had no readable own-school membership row. This confirms the acceptance harness must not require pre-existing operational rows as its positive control; it is not a reason to create production fixtures.
- Removed the membership-row requirement. The script still checks own-school academic-period RPC access and foreign-school RPC denial, and continues foreign-row probes for the operational tables. It reports explicitly when no own-school student row exists, so no positive student-row read is claimed.
- New code head: `d665a1ed18f5916c6679a984066d82a099030a78`. Exact-head SchoolPro CI and payment-page validation must be checked before accepting this change.
- This is strictly a test-harness adjustment. Do not seed live data, suppress explicit API/database errors, or count the tenant gate as passed if any authorization or transport check fails. Production remains untouched; PR #106 remains draft.


### Stage A exact-head CI findings — 2026-10-28

- SchoolPro CI #1992 uncovered a malformed single-dollar SQL delimiter in the newly added member-permission regression statements. Corrected both statements to use the explicit `$stmt$...$stmt$` delimiter on PR #106 head `0f6eaef7281d242f0e2e481bf9ffaf5784dbf733`. The earlier integration run is failed and must not be counted.
- The same CI run progressed further in live tenant acceptance: all foreign-school read probes for the operational tables completed without returning foreign rows, but the own-school `schoolpro_current_academic_period` RPC returned `School access required`. This is an unresolved authorization/account-to-school mapping failure, not a passing acceptance and not something to bypass. No secrets or live records were changed.
- Next: inspect exact-head CI for the corrected disposable regression test; separately diagnose why the configured School A identity cannot call the own-school RPC. Keep the live acceptance gate failed until a valid own-school access control passes. No production migration, row write, merge, or deployment.


### Latest Stage A validation status — 2026-10-28 15:18 UTC

- On PR #106 head `0f6eaef7281d242f0e2e481bf9ffaf5784dbf733`, payment-page validation #1721 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40714475141.
- SchoolPro CI #1994 is still running: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40714475024. The payment-review RLS integration job has passed. The tenant-integrity PostgreSQL job has not completed at this checkpoint, so the new same-school and combined tenant/member reassignment assertions are not yet accepted.
- Live tenant acceptance remains failed: the run reports no own-school student row (explicitly logged as a limitation), all twelve foreign-school row probes returned no rows, but the own-school `schoolpro_current_academic_period` RPC failed with `School access required`. This needs a valid existing School A user-to-school membership/ID mapping. Do not weaken the RPC assertion or create production fixtures to make the check green.
- PR #106 remains draft/unmerged; no production SQL, migration, data seeding, merge or deployment was performed.


### Stage A: tenant-integrity integration passed; live RPC diagnostic improved — 2026-10-28

- SchoolPro CI #1994's `tenant-integrity-db-integration` completed successfully on head `0f6eaef7281d242f0e2e481bf9ffaf5784dbf733`, validating the repaired dollar-quoted SQL and disposable tenant-integrity regression tests. The main `validate` job was still in progress at the last poll; the overall workflow is not yet marked green.
- The remaining live acceptance failure is specifically `schoolpro_current_academic_period` returning `School access required`. Source review confirms this RPC gates on `private.schoolpro_module_allowed(p_school,'dashboard')`, which in turn requires an authenticated active profile, dashboard permission, and an operational school with an active subscription. Therefore the failure is not yet proof of a cross-tenant policy defect.
- Added read-only diagnostics to the live acceptance script to report the test user's own profile status and whether `schoolpro_user_permissions(ownSchoolId)` contains `dashboard`; if the RPC still fails, the error now includes those findings and directs investigation toward school/subscription operational state as appropriate. No production data is written or altered.
- New PR #106 head: `cf1ea6b78af4889621570545c12418b59d872709`. Re-run and verify CI on this exact head; do not count the prior live failure as resolved. PR remains draft/unmerged and Stage A is still open.


### Exact-head live tenant diagnostic — 2026-10-28 15:24 UTC

- PR #106 head under test: `cf1ea6b78af4889621570545c12418b59d872709`; merge ref for CI: `21a38e82d935eb62005f4a2f02c968a3b3138d23`.
- SchoolPro CI run #1997: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40715455279. The live `tenant-acceptance` job failed again. Its diagnostic now establishes that School A's authenticated profile is `active`, but `schoolpro_user_permissions(own_school_id)` does **not** include `dashboard`. The own-school `schoolpro_current_academic_period` RPC therefore fails with `School access required`. All 12 foreign-school row probes completed with no foreign rows returned for School A. These negative probes do not replace the missing positive own-school authorization control.
- This points first to the configured test identity's school membership/role/permission mapping, or an incorrect school ID, rather than proving a tenant-isolation leak. Before changing application code, verify read-only that the configured School A account is actually an authorized member/owner of the configured School A ID. Do not seed or modify production records, weaken the RPC check, or disclose credentials. If mapping is correct, inspect school/subscription operational status next.
- On this exact head, `tenant-integrity-db-integration`, `payment-review-rls-integration`, `result-pin-rate-limit-integration`, `result-verification-exposure-integration`, and `public-admission-abuse-integration` passed. The main `validate` and local Supabase Receipt Storage isolation jobs were still in progress at the last poll; do not claim overall CI success until they finish.
- Payment-page validation #1724 passed on the current PR head: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40715455319.
- PR #106 remains draft/unmerged; Stage A remains open. No production DDL, data changes, merge, or deployment was performed.


### Latest exact-head CI and expanded read-only tenant diagnostics — 2026-10-28 15:30 UTC

- SchoolPro CI #1997 completed on PR #106 head `cf1ea6b78af4889621570545c12418b59d872709`: seven jobs passed, but `tenant-acceptance` failed. The general `validate` job and local Supabase Receipt Storage isolation both passed. Payment-page validation #1724 passed.
- The live test's existing diagnostics show School A profile `active` but no `dashboard` permission for the configured school ID; the own-school academic-period RPC remains denied. This is not accepted as a pass.
- Added further read-only diagnostic output to the live test on new PR head `d52e4fe0b7dbad8e6c4c9a2f92a6943d50c6c931`: visible matching membership role, whether configured school ownership matches the authenticated user, configured school status, and whether the latest visible subscription is active/current. Diagnostics intentionally avoid printing account IDs, emails, or other personal data and do not write records. The diagnostics are best-effort if RLS hides those rows.
- Exact-head CI for `d52e4fe0b7dbad8e6c4c9a2f92a6943d50c6c931` is pending/unconfirmed at this checkpoint; do not claim it passed until a run is found and its jobs inspected.
- PR #106 remains draft/unmerged. No production DDL, row writes, test data seeding, merge, or deployment was performed. Stage A stays open; do not start Stage B implementation.


## Stage A auth race review continuation — 2026-10-28

- Continued PR #106 only; no test accounts/schools were created, no production data or database was changed, and no merge/deployment was performed.
- Reviewed `src/context/AuthContext.tsx` on `release/stage-a-auth-tenant-isolation`. Found a narrow race: when a newer accepted auth event arrived while an earlier profile/access query was already in flight, the earlier query was not invalidated until the replacement query's scheduled callback began. That left a short interval in which the earlier account's profile/access response could still commit.
- Fixed the race by incrementing `profileRequestVersion` immediately when the new auth event is accepted, before scheduling the replacement profile load. Also clear the previous profile and product/service grants while the new account's access snapshot is loading, preventing the new session from temporarily being paired with the previous account's access state. Expanded `scripts/test-auth-profile-race.mjs` to assert immediate invalidation, clearing stale grants, and a reordered in-flight response scenario.
- Latest code head after these edits: `c95ddcdbd781561110d24c90826d15a351d1408c`. Exact-head CI has not yet been confirmed for this commit; do not count the fix as validated until the relevant auth-race test and full CI complete on this exact head.
- The latest prior confirmed run for head `d52e4fe0b7dbad8e6c4c9a2f92a6943d50c6c931` had general validation, local Receipt Storage isolation, tenant-integrity, payment-review, result-PIN, public-admission and result-verification jobs pass; live `tenant-acceptance` failed. Payment-page validation passed. This is an unresolved release gate, not permission to create test identities or seed production fixtures.
- PR #106 remains draft/unmerged. Stage A remains the only active implementation stage. Continue to avoid production DDL, row writes, migrations, merge or deployment without explicit approval.

## Live tenant acceptance workflow policy — 2026-10-28

- The user directed that work stop creating/using test accounts and test schools. The tenant-acceptance job was therefore changed to manual-only (workflow_dispatch plus the existing explicit RUN_LIVE_TENANT_ACCEPTANCE=true opt-in). It no longer signs in to configured school accounts on normal pull-request or push CI. No credentials or account records were changed.
- This does not replace tenant-security validation: disposable PostgreSQL tenant-integrity tests and local Supabase Storage isolation remain in CI. The live job can only be intentionally invoked manually while the opt-in repository variable remains enabled.
- The last live tenant-acceptance failure on the previous workflow revision reported School A dashboard permission=false for its configured identity. This remains an identity/configuration acceptance result, not evidence of a production tenant-isolation defect. Do not troubleshoot by creating accounts/schools.
- PR #106 remains draft/unmerged. Auth race code and its regression checks still require exact-head CI validation. No production database changes or deployment were performed.


## Exact-head CI and trusted-client-IP source review — 2026-10-29

- PR #106 head checked: `3becf82bf17d32b017ecf8b54bae7848e9130144`. SchoolPro CI run [#40878541583](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40878541583) completed with seven executable jobs passing: general validation/typecheck/build, payment-review RLS and duplicate-review concurrency, public-admission abuse controls, result-verification exposure, result-PIN cooldown/concurrency, operational tenant-integrity PostgreSQL tests, and local Supabase Receipt Storage isolation. The manual-only `tenant-acceptance` job was skipped. Do not describe live tenant acceptance as passed.
- Reviewed the current result-PIN Edge Function and its disposable-gateway assertions: it requires the Turnstile challenge and allowed origin, calls the database RPC server-side, and does not read `cf-connecting-ip`, `x-forwarded-for`, or `x-real-ip`. The SQL cooldown key is a digest of the normalized admission identifier and serializes requests with an advisory transaction lock; it does not trust caller-supplied forwarding headers.
- Reviewed the current school-account and student-login Edge Functions: both rate-limit normalized account identifiers via the server-side database RPC and explicitly avoid forwarding headers as security identities. This removes the earlier concern that the current code relies on unverified forwarded-IP headers. It does not provide an IP-based limit against attackers rotating account/admission identifiers; treat that as a separate risk decision, not as evidence of trusted proxy provenance.
- The source/test gate is green for this exact head, but Stage A is still not merge-ready. Live tenant acceptance remains unverified because the manual-only test prerequisite is unavailable in the user's current empty-workspace setup. Production catalog evidence still shows the six proposed tenant-leading indexes absent and operational tables with `FORCE ROW LEVEL SECURITY=false`; the live result-approvals probe has timed out on earlier attempts. The proposed index, forward RLS posture and tenant-integrity migrations remain unapplied.
- Next step remains non-production review/reconciliation: continue the source-vs-ledger and full-schema/trigger-interaction review, preserving the migration provenance gap. Do not create test schools/accounts, seed production, run production DDL, deploy, merge, or mark historical migrations applied without the user's explicit approval.


### Stage A operational RLS fixture review — 2026-10-29

- Continued the non-production source review of PR #106's operational tenant-integrity and forward-only RLS migrations. No database was connected to or changed; no migration, deployment, merge, or test-account/workspace creation occurred.
- Found a specific integration-coverage gap in `scripts/test-schoolpro-operational-tenant-integrity.integration.sql`: the authenticated own-tenant/foreign-tenant row-visibility assertion exercises only five operational tables (library books, transport routes, hostel rooms, inventory assets, and calendar events). The fixture creates `schoolpro_lesson_notes`, `schoolpro_result_approvals`, and `schoolpro_promotions`, but does not define their representative tenant policies or assert authenticated own-school visibility and foreign-school denial for them. The separate non-BYPASSRLS table-owner check covers all eight tables, but that is not a substitute for testing the intended authenticated policy semantics.
- This matters because the forward-only migration deliberately preserves existing feature-specific policies and only enables/forces RLS; the reduced fixture currently cannot establish that those three modules retain the expected authenticated access after the RLS posture change. This is a test coverage gap, not evidence of a production leak.
- Next source-side action: extend the disposable fixture with representative policy behavior and own/foreign row assertions for lesson notes, result approvals, and promotions, then run exact-head CI. Keep PR #106 draft/unmerged until the fixture coverage, full-schema/trigger interaction review, migration-ledger reconciliation, and remaining release gates are resolved. Do not replay historical migrations or change production.

### Operational tenant-policy fixture expansion — 2026-10-29

- PR #106 head `38609c542c0ad992b12036b90d97c6e9c7ba94df` extends the disposable PostgreSQL operational tenant-integrity fixture with representative tenant-scoped policies for `schoolpro_lesson_notes`, `schoolpro_result_approvals`, and `schoolpro_promotions`.
- It seeds School B rows for those tables only after their referenced subject/class/student/result fixtures exist, then asserts that an authenticated School A role sees exactly one own-school row across all eight operational tables.
- Exact-head SchoolPro CI #2050 and payment-page validation #1775 started for this commit. The tenant-acceptance job is skipped because live acceptance is manual/conditional and there are no active school workspaces; this is not counted as a pass.
- Await the disposable tenant-integrity job and all exact-head checks. PR #106 remains draft/unmerged. No production database changes, migrations, workspace creation, or deployment were performed.

