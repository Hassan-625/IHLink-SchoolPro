# SchoolPro Master Migration and Production Cleanup Handover

**Last updated:** 2026-11-02  
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
- Exact-head SchoolPro CI #2050 passed all seven executable jobs, including `tenant-integrity-db-integration`; `tenant-acceptance` was skipped (manual/conditional; no active school workspaces) and is not counted as a pass. Payment-page validation #1775 also passed.
- This closes the specific disposable fixture-coverage action. Next review gate is full-schema/trigger interaction and migration-ledger reconciliation. PR #106 remains draft/unmerged pending those gates and remaining release checks. No production database changes, migrations, workspace creation, or deployment were performed.



### Stage A full-schema trigger-interaction source review — 2026-10-29

- Reviewed the proposed `20261016160000_schoolpro_repair_operational_tenant_integrity.sql`, `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` and `20261017180000_schoolpro_operational_tenant_indexes.sql` alongside the existing lesson-note and calendar workflow migrations on `release/stage-a-auth-tenant-isolation`. This was source-only review; no database was connected to or changed, and no migration, merge, or deployment was performed.
- Confirmed the new tenant guard is complementary to existing workflow triggers rather than replacing their workflow rules: `schoolpro_lesson_workflow` continues to enforce lesson author/review/status rules, while `validate_schoolpro_lesson_notes_tenant` validates same-school subject/class references and immutable tenant ownership. The calendar's existing `validate_schoolpro_calendar_workflow` continues to validate date/class relationships; the added `immutable_schoolpro_calendar_events_tenant` trigger separately rejects school reassignment. The PostgreSQL alphabetical ordering of same-timing triggers means the workflow trigger executes before the `validate_*` tenant trigger; neither source currently relies on the other having already modified `NEW`.
- The generic guard uses an empty `search_path`, schema-qualified relation names and `SECURITY DEFINER`; it rejects missing or cross-school references for lesson notes, result approvals, and promotions. The RLS posture migration changes only `ENABLE/FORCE ROW LEVEL SECURITY` flags, preserving existing feature policy definitions, and the index migration adds six school-leading indexes without row writes.
- **Remaining test limitation:** the disposable integration SQL builds a minimal schema and does not install the existing lesson workflow or calendar workflow triggers from their source migrations. Thus CI proves the tenant guard and representative authenticated policies in isolation, but not their combined execution against the complete historical feature-trigger stack. No direct trigger-name collision was found in the reviewed source; a complete combined-stack integration test remains the appropriate closure before treating trigger interaction as fully validated.
- Next gate is migration-ledger reconciliation (repository migration files versus the live Supabase migration ledger), while retaining the recorded provenance gap. Do not replay migrations or modify production to reconcile it. PR #106 remains draft/unmerged; live `tenant-acceptance` remains skipped/unverified, and no production database changes, migration, workspace creation, or deployment occurred.


### Stage A migration-ledger reconciliation snapshot — 2026-10-29 (read-only)

- Read the live Supabase migration ledger for project ref `lnqsroyiybutkfngbyge` and enumerated migration filenames on `release/stage-a-auth-tenant-isolation`. No SQL writes, migrations, or ledger edits were issued.
- Current exact-version comparison: **485** live ledger entries versus **136** migration files on the Stage A branch; **79** exact version matches; **406** live-only versions; **57** branch-only versions. A name-based comparison finds **103** migration names shared between the two sets, including **24** whose timestamps/versions differ. The prior handover's 397/44 figures are therefore a stale inventory snapshot and must not be used as current counts.
- This is a provenance/history mismatch, not a safe candidate list for applying or marking migrations. Matching names with different versions must be reconciled against file contents, commit history, and the existing sync-ledger history before deciding whether a change was renamed, applied from a different source, or is genuinely missing. The live ledger's latest listed entry is `20261028130707 index_schoolpro_result_events_result_id_for_workspace_cleanup`; the Stage A branch's latest listed migration file is `20261017180000_schoolpro_operational_tenant_indexes.sql`, so the two histories have different coverage horizons.
- **No automated ledger repair is authorized.** Do not run the repository's remote migration-sync/ledger SQL, insert/delete ledger rows, replay historical migrations, or alter production schema/data as a reconciliation shortcut. The next safe task is to create a content- and commit-provenance mapping for the 24 same-name/different-version pairs and the branch-only/live-only sets, then present an explicit reconciliation proposal before any mutation.
- Stage A remains open; PR #106 remains draft/unmerged. Live tenant acceptance is still skipped/unverified. No production database changes, migration, workspace creation, merge, or deployment occurred.


### Migration provenance follow-up — 2026-10-29

- Checked GitHub file history for three representative same-name/different-version pairs: `schoolpro_finance_and_result_access`, `schoolpro_parent_portal`, and `schoolpro_remote_migration_sync_ledger`. Their current branch files were introduced by the 2026-09-26 “Restore SchoolPro migration” commit, while the live ledger records different versions for the same names. This supports a source-restoration/timestamp-provenance explanation for at least these samples, but it does **not** prove the restored file contents are byte-identical to the SQL originally applied in production.
- Inspected `20260926114500_schoolpro_remote_migration_sync_ledger.sql`: it is a documentation/boundary marker ending in `select 1;`; it does not insert or update the Supabase migration ledger. Its comments list a historical applied-migration boundary and explicitly say not to replay inferred production DDL. Do not treat this file as a reconciliation mechanism or run it against production for that purpose.
- The remaining exact-version/name mismatches and the live-only set still require source/commit provenance evidence. The safe output is an evidence matrix, not a guessed “repair” migration. No production writes or migration-ledger changes were made.


### Migration provenance matrix — first-pass classification — 2026-10-29

Read-only inputs: live Supabase migration ledger for `lnqsroyiybutkfngbyge`, migration filenames on `release/stage-a-auth-tenant-isolation`, GitHub file SHAs, and selected GitHub commit histories. The exact-version comparison was repeated for this matrix; counts remain 485 live entries, 136 branch files, 79 exact-version matches, 406 live-only versions, and 57 branch-only versions.

| Classification | Count | Interpretation / safe handling |
|---|---:|---|
| Exact version match | 79 | Version exists in both lists; this does not prove source content equals deployed schema. |
| Same migration name, different version | 24 | Timestamp/provenance conflict; compare historical file contents and commit history, do not rename or mark applied by assumption. |
| Branch-only name and version | 33 | Not present in the current live ledger by exact version or name; treat as unapplied/uncertain until evidence proves otherwise. Never auto-apply. |
| Live-only versions | 406 | Version not present in the current branch inventory; may reflect ecosystem migrations, deleted/restored files, or branch coverage gaps. Do not label every entry “missing SchoolPro source.” |

**Important scope split:** the live-only set spans the wider IHLink ecosystem, not just SchoolPro. Examples include DataSub and BillStack migration names. It also includes late SchoolPro changes, such as `20261019192635 fix_schoolpro_document_tenant_scope`, `20261019193201 enforce_published_locked_family_result_reads`, and `20261028130707 index_schoolpro_result_events_result_id_for_workspace_cleanup`. These examples establish that the Stage A branch inventory is not a complete mirror of the current live ledger; they do not justify importing/replaying these migrations or changing the branch automatically.

**First-pass provenance finding:** GitHub history for the representative same-name/different-version samples indicates a 2026-09-26 “Restore SchoolPro migration” commit for some restored files. The sync-marker migration itself is documentation plus `select 1`, not a ledger-repair operation. Source-file equality with historical deployed SQL remains unproven. Thus the matrix classifies evidence only; it is not an execution plan.

**Next safe gate:** review the 33 branch-only migrations as a bounded list and classify each by scope (Stage A security, other SchoolPro feature, payment/subscription, ecosystem/DataSub, or sync marker), then inspect live ledger and commit provenance for the Stage A-relevant subset. Do not run Supabase migration commands, alter the live ledger, replay migrations, merge PR #106, or deploy as part of this review. Production remains unchanged; PR #106 remains draft/unmerged; tenant acceptance remains skipped/unverified.


### Stage A live operational schema reconciliation — 2026-10-29 (read-only)

- Queried the live Supabase PostgreSQL catalogs read-only for all eight operational tables targeted by Stage A: library books, transport routes, hostel rooms, inventory assets, calendar events, lesson notes, result approvals, and promotions. All eight tables exist in `public`; all eight have RLS enabled, but **all eight currently report `FORCE ROW LEVEL SECURITY = false`**. This corroborates that the proposed forward-only RLS posture migration is not reflected in the live catalog yet. No DDL or row writes were issued.
- Live policy inventory: library books has 2 policies, transport routes 1, hostel rooms 1, inventory assets 1, calendar events 2, lesson notes 2, result approvals 2, promotions 1. The live calendar, lesson-note, result-approval and promotion policies are feature-specific and do not match the simple policy names/definitions in the older `20261002234500_schoolpro_operational_tenant_isolation.sql` source. That older migration explicitly drops all existing policies on these tables before replacing them; **do not replay it** as a way to enable RLS, because it could remove current feature-specific access semantics. The forward-only `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` is the safer candidate to evaluate because it changes RLS flags while preserving policies, but remains unapplied and must pass remaining gates first.
- Existing live triggers on the eight tables include `schoolpro_activation_before_write` on all eight; calendar also has activity-session/calendar validation and `validate_schoolpro_calendar_workflow`; lesson notes has `schoolpro_lesson_workflow` plus activity-session/calendar validation; promotions has `schoolpro_archive_applied_progression`. The proposed `validate_schoolpro_lesson_notes_tenant`, `validate_schoolpro_result_approvals_tenant`, `validate_schoolpro_promotions_tenant`, and immutable-school triggers are not present in the live trigger inventory. No direct trigger-name collision was observed in this snapshot. This is catalog evidence only; it does not establish complete trigger-order behavior or validate trigger execution against live data.
- Existing policy definitions on lesson notes rely on author/leadership access functions; calendar policies rely on calendar module/role access; result approvals use result module and leadership checks; promotions has a manager-read policy. Preserve those semantics during any future posture change. The disposable integration test still does not install the full historical lesson/calendar trigger stack, so combined-stack validation remains open.
- Next safe gate: inspect the full live function definitions for the existing operational-write and lesson/calendar workflow triggers, then close the combined-stack test gap on a disposable database. Separately confirm the six proposed school-leading indexes against the complete live index inventory. Keep the migration ledger as evidence only; do not apply migrations, alter the ledger, seed production, create test workspaces, merge PR #106, or deploy without explicit approval.
- PR #106 remains draft/unmerged; live tenant acceptance remains skipped/unverified. This reconciliation was read-only and did not change production.


### Stage A existing trigger-function and index inventory — 2026-10-29 (read-only)

- Continued read-only catalog review of the existing trigger functions on the eight operational tables. The shared `private.guard_schoolpro_operational_write()` trigger is SECURITY DEFINER with an empty search path; it enforces the operational activation/subscription gate for authenticated writes, while explicitly allowing trusted non-anonymous background writes when `auth.uid()` is null. The existing lesson workflow trigger independently requires an authenticated user and enforces author scope, immutable author/school, and review-state transitions. The calendar workflow function validates event date ordering and same-school class references. The promotion archive trigger writes enrollment-history records when a promotion transitions to applied, and independently checks same-school student/classes. These existing feature semantics must be retained when the proposed tenant guards are added.
- Read-only live index inventory confirms the six indexes declared by `20261017180000_schoolpro_operational_tenant_indexes.sql` are currently absent: `schoolpro_library_books_school_id_idx`, `schoolpro_transport_routes_school_id_idx`, `schoolpro_hostel_rooms_school_id_idx`, `schoolpro_inventory_assets_school_id_idx`, `schoolpro_result_approvals_school_id_idx`, and `schoolpro_promotions_school_id_idx`. Existing indexes include a school/session index on calendar events and several school-leading indexes on lesson notes; promotions and result approvals have other uniqueness indexes but no school_id-leading index in the observed inventory. This is a performance/catalog difference, not evidence of a tenant leak by itself.
- The combined trigger stack is still not integration-tested: the disposable fixture omits the existing activation, lesson/calendar workflow, session/calendar validation, and promotion archival triggers. Before treating the new tenant guard as fully validated, extend the disposable PostgreSQL fixture to model the relevant existing triggers and test compatible insert/update paths plus cross-tenant reference rejection. Keep this test non-production.
- This catalog review was read-only. No migration, production DDL/data changes, ledger edits, test-workspace creation, deployment, or merge occurred. PR #106 remains draft/unmerged and live tenant acceptance remains skipped/unverified.

### Stage A combined lesson/calendar workflow fixture — 2026-10-29

- Added a disposable integration-test extension on PR #106 commit `78dae7a8197039aefd2388b375bad6b705840a5d` to exercise the proposed operational tenant guards alongside a modeled lesson-note review workflow and calendar validation workflow. Assertions cover lesson draft/submit/review transitions, author self-approval denial, submitted-content immutability, reviewer identity retention, valid calendar insertion, reversed-date rejection, cross-school class rejection, and school reassignment rejection.
- Exact-head GitHub Actions validation completed successfully: [SchoolPro CI #2059](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40904530773) passed all seven executable jobs, including `tenant-integrity-db-integration`; `tenant-acceptance` was skipped because no active school workspaces exist. [Payment-page validation #1784](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40904530601) also passed.
- **Coverage limitation:** the new lesson/calendar workflow helpers are disposable test doubles / compact equivalents, not restored copies of the full live workflow functions. The fixture does not prove the full production trigger stack, trigger ordering, activity-session/calendar validation dependencies, activation guard behavior, or promotion archival behavior together. Keep this gap explicit; do not describe the test as full production-schema equivalence.
- No production database changes, workspace creation, migration, merge, or deployment occurred. PR #106 remains draft/unmerged. Live tenant acceptance remains skipped/unverified. The unrelated Vercel status context is not the production deployment signal; SchoolPro production frontend remains on Render.

### Stage A live trigger-definition retrieval — 2026-10-30

- Retrieved the exact live PostgreSQL definitions read-only through the Supabase SQL connector for `private.guard_schoolpro_operational_write()`, `private.schoolpro_validate_lesson_workflow()`, `private.validate_schoolpro_workflow_record()`, and `private.schoolpro_archive_progression()`. No production DDL, DML, migration, or ledger operation was performed.
- Confirmed the activation guard is SECURITY DEFINER with an empty search path. For authenticated writes it resolves the old/new record school and checks `private.schoolpro_operationally_active(...)`; it also rejects unscoped records without SchoolPro edit access. Its explicit trusted-background bypass applies only when `auth.uid()` is null and the JWT role is not `anon`. A faithful disposable test therefore needs the helper dependencies and must distinguish authenticated, anon, and trusted-background contexts.
- Retrieved the full lesson workflow function. It requires `auth.uid()`; stamps the creator on insert; allows initial draft/submitted states; prevents author/school reassignment; blocks deletion of submitted/approved lessons; enforces author scope; and restricts approval/change-request transitions to leadership, with reviewer identity and timestamp set by the function. The existing PR fixture already includes a disposable implementation of this function and tests core author/review transitions, but uses test helper functions for leadership and author scope.
- Retrieved the exact calendar trigger function `private.validate_schoolpro_workflow_record()`. It is shared by multiple operational tables and contains table-specific branches for payroll, health records, and calendar events. Its calendar branch rejects reversed event dates and classes outside the event school; its common update branch rejects school reassignment. The current PR fixture uses a compact calendar-only equivalent, not the exact shared production function. Exact reuse requires the disposable calendar table to supply the production-referenced columns/relations, or a carefully isolated faithful extraction with its scope stated.
- Retrieved the exact AFTER UPDATE promotion archive function `private.schoolpro_archive_progression()`. On a transition to `applied`, it validates the academic session, source class and student school, writes the prior enrollment-history row, and for promoted/repeated decisions validates the destination class and writes the next-session enrollment-history row. The current fixture does not yet define the full production promotion/session/enrollment-history shape or install this archive trigger; this is an outstanding test gap.
- Live column inventory confirms the promotion table uses `from_class_id`, `to_class_id`, `decision`, `session`, and `status`; `schoolpro_enrollment_history` has school/student/session/class/status/promotion fields. The minimal disposable fixture currently has only the promotion identifiers and source/destination class IDs, so the production function cannot simply be attached without extending its dependencies and fixtures.
- Next test change: extend the disposable fixture with the exact promotion columns and enrollment-history table, production-equivalent class fields (`name`, `arm`, `level`), and a valid 2026/2027 promotion scenario; install the exact promotion archive function and assert both history rows for a promoted decision plus rollback/no history on a cross-school source or destination. Replace the compact calendar function only after the disposable schema satisfies its full referenced dependencies. Keep activation-guard coverage separate until the helper functions it calls can be reproduced faithfully. Do not run any of these definitions against production.


## Stage A promotion archive integration coverage — 2026-10-30

- Extended `scripts/test-schoolpro-operational-tenant-integrity.integration.sql` on PR #106 branch `release/stage-a-auth-tenant-isolation` at commit `12ef364bc01ed628a3af951581059021416d9a75`.
- The disposable PostgreSQL fixture now installs the exact body retrieved read-only from live `private.schoolpro_archive_progression()` as an AFTER UPDATE trigger. It adds the class fields and enrollment-history uniqueness/columns required by that function, then applies a promoted decision and asserts both source-session `completed` and next-session `active` history rows.
- Added a cross-school destination rejection assertion against the existing operational tenant-integrity BEFORE trigger and verifies no enrollment-history row is written for the rejected promotion.
- This is still a disposable integration fixture; it does not alter production. The exact-head CI run has not yet been observed, so this test change is **not yet accepted**. PR #106 remains open/draft/unmerged.
- Next: inspect exact-head CI and fix any fixture/function mismatch before claiming coverage. Calendar's production shared trigger and activation-gate dependency stack remain separate follow-ups; do not replace them with approximations and call them exact.


## Promotion archive test exact-head CI acceptance — 2026-10-30

- Exact PR #106 test head `12ef364bc01ed628a3af951581059021416d9a75` completed validation successfully.
- SchoolPro CI run [#41025364963](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41025364963): all seven executable jobs passed, including `tenant-integrity-db-integration`; `tenant-acceptance` was skipped because its live acceptance prerequisites were not enabled. The tenant-integrity job's disposable PostgreSQL migration/test step completed successfully.
- Payment-page validation [#41025365014](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41025365014): passed.
- This accepts the new disposable promotion archive assertions for this exact head; it does not constitute production migration approval or live two-tenant acceptance. PR #106 remains draft/open/unmerged. No production changes or deployment occurred.
- Next test gap: faithfully exercise the deployed shared calendar workflow trigger and the activation-gate trigger stack using the exact production definitions and their dependencies, rather than compact substitutes. Preserve the existing lesson workflow helper-stub limitation in test reporting.

### Stage A calendar workflow exact-function test — 2026-10-30

- The disposable tenant-integrity fixture now installs the exact live `private.validate_schoolpro_workflow_record()` body for its calendar trigger, exercising the calendar validation and common immutable-school path. Payroll and health branches are not invoked; inert disposable enum/helper definitions exist only for function compilation.
- Exact PR #106 head `f6fdaede9cdcdc9bf728ad7d56f1e242a2bbe3fa` passed SchoolPro CI run #41027611391 (all seven executable jobs successful; tenant-acceptance skipped) and payment-page validation #41027611469. The tenant-integrity integration job passed.
- Activation-guard coverage remains open: faithful coverage still needs its production dependency stack and authenticated, anonymous, and trusted-background context tests. No mock-only result should be represented as exact production coverage.
- No production mutation, migration, ledger edit, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live tenant acceptance is not established.


### Stage A activation-guard integration test — 2026-10-30 (exact-head CI follow-up)

- Added disposable PostgreSQL coverage for the exact live `private.guard_schoolpro_operational_write()` function and its school-resolution/subscription-activation dependencies on PR #106 branch `release/stage-a-auth-tenant-isolation`. The test exercises inactive-school rejection, active-school acceptance, anonymous inactive-school rejection, and the trusted `service_role` background-write bypass. The no-school/global `private.has_product_access('schoolpro','edit')` fallback is stubbed false and is not covered; this is explicitly outside the tested scenarios.
- Initial exact-head run for commit `aadaa9a2fd1a1f1a1ae4407b39a8eeb33ae50f3f`, SchoolPro CI #2068, failed because the test expected a shortened error string rather than the exact production exception text. Payment validation passed.
- Corrected both expected exception strings in commit `c323c6186883bc65db1cf03f33d12294cb4b3862`. Exact-head SchoolPro CI #2070 then passed the other six executable jobs but **failed** `tenant-integrity-db-integration`; payment validation #1795 passed and live `tenant-acceptance` was skipped. The failing statement is the trusted-background insert for the inactive fixture school. The production guard raised the activation-required exception, indicating the disposable session still had an authenticated subject context when the test expected `auth.uid()` to be null. This is a fixture-context setup defect to resolve before claiming the bypass assertion; it is not evidence that the production guard is defective.
- Next: explicitly clear the disposable JWT subject/claims before setting the `service_role` role claim, then rerun exact-head CI. Keep all test work confined to disposable PostgreSQL. No production DDL/DML, migration, ledger edit, merge, deployment, or workspace creation occurred. PR #106 remains draft/open/unmerged; live tenant acceptance is unverified.


### Stage A trusted-background fixture context correction — 2026-10-30

- Follow-up to the #2070 failure: the disposable test now clears both `request.jwt.claim.sub` and `request.jwt.claims` before setting `request.jwt.claim.role` to `service_role`. This ensures the exact production `auth.uid()` helper resolves NULL for the trusted-background case, rather than inheriting a subject left by an earlier integration assertion.
- Branch commit: `1f817abafac8dfd312183e5af268e14984366849`. Exact-head CI has been triggered by the PR update and is pending confirmation. Do not count the activation-guard bypass test as accepted until `tenant-integrity-db-integration` passes.
- No production changes, migration, ledger edits, merge, deployment, or test-workspace creation occurred. PR #106 remains draft/open/unmerged; live tenant acceptance remains skipped/unverified.

### Stage A activation-guard fixture — tenant-integrity job accepted — 2026-10-30

- The JWT-context correction at PR #106 commit `1f817abafac8dfd312183e5af268e14984366849` resolved the trusted-background test failure. Exact-head SchoolPro CI #2072 reports `tenant-integrity-db-integration` **passed**. The job executed the disposable migration and integration SQL successfully, including active-school acceptance, inactive/anonymous rejection, and the `service_role` background bypass with a null subject context.
- At the time of this handover update, the remaining `validate` and local Receipt Storage isolation jobs were still running, so the overall SchoolPro CI workflow is **in progress**, not yet fully accepted. The other completed executable integration jobs are passing; live `tenant-acceptance` is skipped. Payment-page validation #1797 passed.
- The activation test intentionally stubs `private.has_product_access('schoolpro','edit')` false; the no-school/global-edit fallback is not covered. This fixture limitation remains explicit. Lesson workflow helper-scope limitations documented above also remain.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance is unverified.

### Stage A activation-guard fixture — full exact-head CI accepted — 2026-10-30

- Exact PR #106 head `1f817abafac8dfd312183e5af268e14984366849` completed successfully: [SchoolPro CI #2072](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41036514889) concluded **success**. All seven executable jobs passed, including `tenant-integrity-db-integration`, `validate` (typecheck, application checks and build), the payment-review RLS integration, public-admission abuse integration, result verification exposure, result-PIN/rate-limit integration, and local Receipt Storage isolation. The conditional live `tenant-acceptance` job was **skipped**.
- [Payment-page validation #1797](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41036514814) also concluded **success**.
- The activation-guard disposable integration assertions are accepted for this exact head: inactive-school rejection, active-school acceptance, anonymous inactive-school rejection, and trusted `service_role` background-write bypass after clearing JWT subject/claims. The fixture still stubs `private.has_product_access('schoolpro','edit')` false; the no-school/global-edit fallback is not covered. Lesson workflow helper-scope limitations remain as documented above.
- This is CI evidence from disposable/local test environments, not live tenant acceptance or production-schema equivalence. No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains skipped/unverified.
- **Next bounded Stage A task:** resolve the previously documented member-permission tenant reassignment gap in `20261016160000_schoolpro_repair_operational_tenant_integrity.sql`: reject simultaneous `school_id` and `member_id` reassignment and add a disposable PostgreSQL negative test. Review the exact current migration and fixture before editing; keep production untouched.


### Stage A member-permission tenant immutability — existing branch fix verified — 2026-10-30

- Rechecked the current PR #106 branch after the earlier handover note listed simultaneous `school_id` + `member_id` reassignment as an open source/test blocker. The current migration already contains the guard in `private.validate_schoolpro_member_permission_tenant()`: on UPDATE, any `NEW.school_id IS DISTINCT FROM OLD.school_id` raises `Permission school ownership cannot be reassigned`, before the referenced-member tenant check.
- The disposable PostgreSQL integration SQL already covers: (1) rejection of a permission row referencing a member from another school; (2) acceptance of reassignment to another member within the same school; and (3) rejection of a simultaneous tenant and member reassignment to a valid pair in another school. The static contract test also asserts the immutability guard exists.
- These assertions ran as part of exact-head SchoolPro CI #2072 on PR #106 head `1f817abafac8dfd312183e5af268e14984366849`; `tenant-integrity-db-integration` passed and the overall workflow concluded success. Therefore the member-permission reassignment source/test blocker is **closed on the current PR branch**; the earlier 2026-10-28 review note is historical and must not be treated as an outstanding code defect.
- This closure is limited to the disposable migration/test evidence. It does not authorize production application or establish live tenant acceptance. PR #106 remains draft/open/unmerged; no production DDL/DML, migration, ledger edit, merge, or deployment occurred.


### Stage A lesson-workflow helper dependency review — 2026-10-30 (read-only)

- Retrieved the exact live definitions of `private.schoolpro_validate_lesson_workflow()`, `private.schoolpro_lesson_author_scope(uuid,uuid,uuid)`, and `private.schoolpro_lesson_leader(uuid)` from Supabase PostgreSQL using read-only catalog queries. No production changes were made.
- The disposable fixture's lesson-workflow trigger body mirrors the live trigger's state-transition and validation logic, but its two authorization helpers remain simplified test doubles. The production author-scope helper joins `schoolpro_members` to active `profiles`, checks teacher/class-teacher roles, then validates either the member's `form_teacher_id` class assignment or a matching `schoolpro_subject_assignments` row. The production leadership helper checks active profile status, platform `super_admin`, school ownership, or school membership in administrator/head_teacher/vice_principal roles.
- Current fixture limitation is therefore narrower and more precise than “lesson workflow is mocked”: the trigger function body is represented, but its author-scope and leadership authorization dependencies are not yet faithfully modeled. Existing lesson assertions validate workflow transitions only under deterministic helper outputs; they do not prove production role/assignment resolution.
- Next bounded test improvement: extend only the disposable PostgreSQL fixture with the minimum profiles, member-role, class form-teacher, subject-assignment, and platform-role helper dependencies needed to execute the exact helper predicates (or a documented isolated extraction). Add positive/negative assertions for assigned vs unassigned teacher and school leader vs non-leader. Keep the live database read-only and do not copy production user/business rows into fixtures.
- PR #106 remains draft/open/unmerged. No production DDL/DML, migration, ledger edit, merge, deployment, or workspace creation occurred.


### Stage A lesson authorization fixture upgraded to production predicates — 2026-10-30

- PR #106 adds deterministic disposable fixtures for `profiles`, `schoolpro_members`, `schoolpro_classes.form_teacher_id`, `schoolpro_subject_assignments`, and school ownership, and replaces the simplified lesson-author/leader helper doubles with the exact live SQL predicates retrieved read-only from Supabase.
- The fixture's `private.is_admin(user_role[])` is an isolated test implementation of the live helper's exact predicate: active profile, matching `auth.uid()`, and requested platform role. The lesson leader and author-scope helper bodies themselves mirror the live definitions. No production users or school records are copied.
- Added assertions for form-teacher authorization, assigned-subject-teacher authorization, denial of unassigned and inactive teachers, and leadership granted to a school administrator/owner but denied to an ordinary teacher/inactive profile.
- PR branch commits: `8af6fc6` (fixture/helper implementation) and `18ca23e` (expanded fixture column insert correction). Exact-head CI has not yet been evaluated; this is pending disposable CI validation, not a completed test result.
- No live database writes, production DDL/DML, migration, ledger edit, merge, or deployment occurred. PR #106 remains draft/open/unmerged.


### Stage A lesson authorization fixture — SQL quoting correction — 2026-10-30

- Exact-head SchoolPro CI #2079 for PR #106 test head `18ca23e4fdf21d9aa119701f30cf9088498ee999` completed with one failing job: `tenant-integrity-db-integration`. The failure occurred at the first disposable SQL setup statement, before the migration or assertions ran: eight newly added anonymous DO blocks used the invalid delimiter `do $ ... end $;` rather than a valid paired dollar quote. This is a test-fixture syntax defect, not a production database failure.
- The other six executable CI jobs passed, including typecheck/application validation/build, result PIN/rate-limit, result-verification exposure, payment-review RLS, public-admission abuse, and local Receipt Storage isolation. Payment-page validation #1804 passed. Live `tenant-acceptance` was skipped.
- Corrected all eight malformed DO-block delimiters to `do $$ ... end $$;` in PR branch commit `80acf05342dafe888c96e2eca0fb15071bc2880f`. Exact-head CI must rerun and pass the tenant-integrity SQL before the expanded lesson authorization fixture is accepted.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live tenant acceptance remains unverified.


### Stage A lesson authorization fixture — corrected dollar-quote replacement — 2026-10-30

- Follow-up inspection of SchoolPro CI #2081 showed the earlier commit `80acf05342dafe888c96e2eca0fb15071bc2880f` had not changed the eight malformed delimiters: the replacement operation interpreted the dollar characters and wrote the original `do $ ... end $;` text back unchanged. CI therefore failed at line 3 before any migration or test assertion ran. This was confirmed directly in the job log.
- Replaced the delimiters using literal callback replacements. PR branch commit `4299ddd02079817e675f0ad84d26d7eace071348` now changes all eight occurrences to paired `$$` delimiters. The source was re-counted: zero malformed `do $ begin` occurrences remain and twelve valid `do $$ begin` blocks are present.
- Exact-head validation is pending for commit `4299ddd02079817e675f0ad84d26d7eace071348`. SchoolPro CI #2081 failed only in `tenant-integrity-db-integration` at SQL setup; the other six executable jobs passed, live `tenant-acceptance` was skipped, and payment validation #1806 passed.
- No production database changes, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged.


### Stage A lesson authorization fixture — helper delimiter follow-up — 2026-10-30

- Exact-head SchoolPro CI #2083 on PR commit `4299ddd02079817e675f0ad84d26d7eace071348` passed the application validation job and six other executable jobs, but `tenant-integrity-db-integration` still failed during disposable fixture setup. The initial correction had fixed the `private.is_admin()` SQL body; PostgreSQL then reached the next two production-predicate helper definitions and found untagged dollar delimiters in `private.schoolpro_lesson_leader()` and `private.schoolpro_lesson_author_scope()`. No lesson authorization assertions ran in that attempt. Payment validation #1808 passed; live `tenant-acceptance` was skipped.
- The same defect was reproduced in exact-head SchoolPro CI #2085 on commit `211eaffc7a54dc10009498b4dc74d8a4c4971743`: `private.is_admin()` compiled, but the two lesson helper functions failed at SQL line 374. This confirms the remaining issue is limited to disposable test-fixture quoting, not the production database or migration.
- Corrected both helper definitions to use the paired `$lesson_fixture$ ... $lesson_fixture$` delimiter in PR branch commit `171d94768a0c0c9e731d608d40eaa179ebcea1d7`. Exact-head SchoolPro CI #2086 and payment validation #1811 are queued/running; do not accept the expanded lesson authorization coverage until the tenant-integrity job and full exact-head checks complete successfully.
- The #2085 application validation, result-PIN/rate-limit integration, result-verification exposure integration, payment-review RLS integration, and public-admission abuse integration passed; local Receipt Storage isolation was still running at last poll. Payment validation #1810 passed. Live `tenant-acceptance` was skipped.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains unverified.


### Stage A lesson authorization fixture — paired helper delimiters — 2026-10-30

- Exact-head SchoolPro CI #2086 on PR commit `171d94768a0c0c9e731d608d40eaa179ebcea1d7` confirmed the `private.is_admin()` helper compiled, but the tenant-integrity integration still failed while defining `private.schoolpro_lesson_leader()`: the opening delimiter had been changed to `$lesson_fixture$` while its closing delimiter remained the untagged `$`. The failure occurred before the lesson authorization assertions. Payment validation #1811 passed; live tenant acceptance was skipped.
- Corrected both closing delimiters to match `$lesson_fixture$` in PR branch commit `0697415d39a3e3e58c74bf553f7479b35b6a7896`. This completes the paired delimiter fix for both lesson-leader and lesson-author-scope SQL helper definitions. Exact-head SchoolPro CI #2088 and payment validation #1813 are now running; the test expansion remains unaccepted until the tenant-integrity job passes.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains unverified.


### Stage A lesson authorization fixture — leadership reviewer identity correction — 2026-10-30

- Exact-head SchoolPro CI #2088 on PR commit `0697415d39a3e3e58c74bf553f7479b35b6a7896` passed application validation/build and all other executable integration jobs except `tenant-integrity-db-integration`; payment validation #1813 passed and live `tenant-acceptance` was skipped.
- The tenant-integrity job now compiled the repaired disposable SQL functions and progressed into the lesson workflow assertions. It then rejected the approval update with the expected production rule, `Wait for school review before editing this lesson`, because the fixture attempted to approve a submitted lesson as the subject teacher. The production leader predicate correctly does not treat a subject teacher as school leadership; the earlier assertion that the teacher has subject-author scope is separate and remains valid.
- Corrected the workflow fixture to perform the approval as the fixture's school administrator and to assert that administrator's reviewer identity, rather than using the assigned subject teacher. PR branch commit: `87dd511ca6fa3d04b1e2e4f8d514fdd2f59bbd00`. Exact-head SchoolPro CI #2090 and payment validation #1815 are queued/running; do not accept the fixture until the tenant-integrity job passes.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains unverified.


### Stage A lesson authorization fixture — preserve shared admin predicate — 2026-10-30

- Exact-head SchoolPro CI #2090 on PR commit `87dd511ca6fa3d04b1e2e4f8d514fdd2f59bbd00` passed the application validation and all executable integration jobs except `tenant-integrity-db-integration`; payment validation #1815 passed and live `tenant-acceptance` was skipped.
- The tenant-integrity job progressed beyond lesson approval after the fixture switched the approval actor to the school administrator. It then failed while compiling the later shared workflow-function fixture: a second disposable `CREATE OR REPLACE private.is_admin(public.user_role[])` stub used an unnamed input argument, conflicting with the earlier production-predicate fixture's named `required_roles` argument. This duplicate stub would also have replaced the active-profile predicate with a constant false result, so it must not remain.
- Removed the conflicting later stub and retained the earlier isolated active-profile `private.is_admin(required_roles)` predicate for both lesson leadership tests and the shared workflow function. The remaining inert `private.has_school_access` helper stub is retained only for the shared workflow function's non-calendar branches, which are not exercised by this calendar-only fixture. PR branch commit: `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2`. Exact-head workflow runs have not yet appeared in the commit-run lookup; validation is pending.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains unverified.


### Stage A lesson authorization fixture — exact-head CI accepted — 2026-10-30

- Exact PR #106 head `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2` completed successfully: [SchoolPro CI #2092](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41052841614) concluded **success**. All seven executable jobs passed, including `tenant-integrity-db-integration`, `validate` (typecheck, application checks and build), result-PIN/rate-limit integration, result-verification exposure, payment-review RLS integration, public-admission abuse integration, and local Receipt Storage isolation. The conditional live `tenant-acceptance` job was **skipped**.
- [Payment-page validation #1817](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41052841543) also concluded **success**.
- The lesson authorization fixture upgrade is now accepted for this exact PR head: disposable tests execute the production-predicate logic for form-teacher and assigned-subject-teacher scope, deny unassigned/inactive teachers, and distinguish school leaders/owners from ordinary teachers/inactive profiles. The calendar lesson approval workflow now uses a school-administrator reviewer fixture. The shared `private.is_admin()` predicate is no longer overwritten by the duplicate constant-false stub.
- This is disposable/local CI evidence, not live tenant acceptance or production-schema equivalence. Live two-tenant `tenant-acceptance` remains skipped/unverified. No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged.
- Next bounded Stage A task: inspect the exact live `private.has_product_access(text,text)` definition and decide whether the global/no-school edit fallback can be safely and meaningfully exercised in the disposable activation-guard fixture. Do not change production or expand scope without a concrete predicate/test requirement.


### Stage A activation-guard global-access fallback — live predicate inspected — 2026-10-30

- Read-only inspection retrieved the exact live `private.has_product_access(target_product text, required_permission text DEFAULT 'view')` definition from production Supabase. It returns true only when the caller's `auth.uid()` resolves to an active `public.profiles` row and either that profile has platform role `super_admin`, or a matching `public.admin_product_access` row grants the requested product permission. For `required_permission='edit'`, the predicate checks `can_edit`; the other branches check `can_approve` for `approve` and `can_view` otherwise. The function is SECURITY DEFINER, owned by `postgres`, and pins an empty search_path.
- Production `public.admin_product_access` has a unique `(user_id, product)` key and the relevant boolean fields `can_view`, `can_edit`, and `can_approve`; its `user_id` references `profiles(id)`. The live function has no school-specific predicate: this is a platform-level product-access fallback.
- The disposable operational-activation fixture currently replaces this helper with `select false`, so its current CI coverage intentionally does not exercise the live platform-admin / product-grant path. The trigger's no-school branch also requires a fixture row for which the exact `schoolpro_record_school(table,row)` helper resolves NULL; the existing activation test table has a non-null direct `school_id`, so merely adding profile/grant fixtures would not reach that branch.
- Next bounded improvement: inspect the live trigger attachment set and `private.schoolpro_record_school(text,jsonb)` mappings to identify an actual trigger-attached record shape that legitimately resolves to NULL. Only then extend the disposable fixture to model the exact profile/product-grant predicate and assert denied-without-grant, allowed-with-`can_edit`, and non-edit permission denial. Do not manufacture an artificial production behavior or change the live database.
- This was read-only production inspection. No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains skipped/unverified.


### Stage A activation-guard fallback reachability decision — 2026-10-30

- Follow-up to the live `private.has_product_access(text,text)` review: the proposed extra fallback test is deferred. The fallback is reached only when both old/new record-to-school resolutions are NULL. The existing activation-guard fixture represents a direct school-owned operational row with non-null `school_id`; manufacturing a NULL-school record solely to exercise a platform-admin fallback would not validate that real write path.
- The production helper definition and its platform-level `super_admin` / `admin_product_access.can_edit` behavior were inspected read-only. A fresh trigger-attachment catalog query was blocked by the connector safety layer, so this note does **not** claim that every live trigger attachment or nullable record shape has been exhaustively enumerated. Revisit only if a verified trigger-attached, legitimate record shape can reach the NULL-resolution branch.
- No additional test or production change is warranted from the evidence currently available. Keep the passing activation-guard tests for inactive-school denial, active-school acceptance and trusted service-role background writes.
- Current PR #106 head remains `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2`; exact-head SchoolPro CI #2092 and payment validation #1817 passed, while live `tenant-acceptance` was skipped. PR remains draft/open/unmerged. No production migration, DDL/DML, ledger edit, deployment or merge occurred.



### Stage A closure checkpoint — 2026-10-30

- Rechecked PR #106 at exact head `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2`. SchoolPro CI #2092 passed all seven executable jobs and payment-page validation #1817 passed. The conditional live `tenant-acceptance` job was skipped; these CI results do not establish current live two-school acceptance.
- Reviewed the latest operational tenant-integrity migration patch. The previously identified member-permission reassignment gap is now addressed: `private.validate_schoolpro_member_permission_tenant()` rejects changes to `school_id` on UPDATE before validating the school/member pair. The disposable integration suite includes the migration; exact-head tenant-integrity CI passed. This is still a reduced-schema test, not a production migration rehearsal.
- The live two-school acceptance prerequisite is currently unavailable: the last recorded manual run on 2026-10-29 could not resolve an active School A workspace/membership because there are no active school workspaces. Foreign-school read probes passed before that prerequisite failure. Do not rerun against the same empty setup, create workspaces/fixtures, or weaken RLS.
- The six operational tenant indexes, operational relational-integrity migration, forward-only FORCE RLS migration, payment/receipt changes, report-media policy optimization, and result-PIN cooldown remain branch proposals, not deployed production changes. Production ledger/source drift remains material; do not replay historical migrations or manually edit the ledger.
- **Stage A status: implementation and disposable CI gates pass; production closure is not authorized or evidenced.** PR #106 remains draft/open/unmerged. No production DDL/DML, migration, ledger edit, workspace creation, receipt upload, deployment, or merge was performed.
- To close the production release gate, the owner must first provide/authorize a valid existing two-school live acceptance setup (or explicitly accept the absence of current live acceptance as a documented release risk), and separately approve a bounded production rollout plan for the reviewed forward-only changes. Until then, keep A as “code/test-ready; production rollout pending” and do not start Stage B.
- Next work is bounded: (1) confirm live acceptance using valid existing active school accounts only; (2) reconcile each proposed migration's effect against the live catalog/ledger without replaying history; (3) obtain explicit approval for the exact production changes; (4) apply only the approved changes, verify tenant isolation and feature workflows, then merge/deploy and perform post-merge checks. Defer non-release enhancements rather than reopening scope.



### Prior successful two-workspace isolation evidence retained — 2026-10-30

- The user's earlier successful two-workspace tenant-isolation acceptance is accepted as existing Stage A evidence. Do not repeat it merely because the current production workspace inventory is now empty.
- The 2026-10-29 manual run that could not resolve an active School A workspace is a later environment/prerequisite failure. It does not invalidate the earlier successful two-workspace evidence and is not a reason to create workspaces, seed production data, or rerun the same test.
- Stage A acceptance evidence must distinguish: (a) prior successful two-workspace isolation result; (b) later live run blocked before completing because no active workspace was available; and (c) current disposable CI results. Do not collapse these into “live isolation unverified”.
- Remove repeat live tenant acceptance from the remaining mandatory Stage A checklist. Retain the earlier result as the tenant-isolation acceptance evidence. Remaining Stage A work is limited to bounded review of the proposed production changes, migration/source-ledger reconciliation, exact-head CI confirmation, and post-approval rollout/verification. No production changes are authorized by this note.



### Stage A bounded production-catalog recheck — 2026-10-30

- Used the earlier successful two-workspace acceptance as the tenant-isolation evidence; no repeat acceptance run was performed.
- Read-only Supabase catalog recheck confirms all eight operational tables (`schoolpro_library_books`, `schoolpro_transport_routes`, `schoolpro_hostel_rooms`, `schoolpro_inventory_assets`, `schoolpro_calendar_events`, `schoolpro_lesson_notes`, `schoolpro_result_approvals`, `schoolpro_promotions`) currently have RLS enabled and FORCE RLS disabled.
- The six proposed tenant-leading indexes are absent. The production database does not currently contain `private.schoolpro_validate_operational_tenant()` or `private.validate_schoolpro_member_permission_tenant()`. The corresponding Stage A migration versions `20261016160000`, `20261017170000`, and `20261017180000` are not recorded in the live migration ledger. This matches the existing source/ledger reconciliation record: these are unapplied proposals, not missing history to backfill.
- The migration proposals preserve existing feature policies, add relational tenant immutability checks, enable/force RLS on the eight operational tables, and add six tenant-leading indexes. Their disposable PostgreSQL integration tests pass on current PR head. This is a proposed forward-only rollout, not production validation.
- No production DDL/DML or migration was executed. The next decision is not another tenant-isolation test: it is whether to authorize the exact reviewed forward-only operational tenant-integrity, FORCE-RLS and index changes for a controlled production rollout. Payment/receipt and result-PIN changes remain separately gated by their own runtime/source review; do not bundle unrelated changes into this operational migration.


### Stage A production rollout and PR #106 merge — 2026-10-30

- Owner explicitly authorized the three operational migrations, SchoolPro fee-payment receipt/review changes, receipt Storage changes, family report-media Storage optimization, and PR #106 merge.
- PR #106 was marked ready and squash-merged into `main`. GitHub confirmed `merged=true`; merge commit: `c570843ec6bcd983b12771076d4aafcb5029b4fe`. The merged head was `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2`. Exact-head SchoolPro CI #2092 and payment-page validation #1817 both completed successfully. The member-permission guard in the merged migration rejects tenant reassignment before checking the member/school relationship.
- Applied eight forward-only production migrations to Supabase project `lnqsroyiybutkfngbyge`, using the exact SQL from merged `main`:
  1. `20261017180000_schoolpro_operational_tenant_indexes`
  2. `20261017170000_schoolpro_forward_operational_tenant_isolation`
  3. `20261016160000_schoolpro_repair_operational_tenant_integrity`
  4. `20261016180000_schoolpro_payment_receipt_storage_limits`
  5. `20261015203000_schoolpro_payment_receipt_tenant_guard`
  6. `20261016143000_schoolpro_payment_review_write_controls`
  7. `20261017150000_schoolpro_payment_receipt_storage_policies`
  8. `20261016110500_schoolpro_optimize_family_report_media_storage_policy`
- Supabase migration API returned success for all eight. The migration ledger records them under generated application timestamps `20261030141959` through `20261030142053`, retaining each original migration name; do not manually insert or rewrite ledger rows.
- Read-only post-apply catalog verification confirmed all eight operational tables have RLS enabled and FORCE RLS enabled; all six tenant-leading indexes exist; both operational tenant guard functions and the family report-media helper exist; operational immutable-tenant and relational guard triggers are enabled; and the receipt bucket remains private with a 5 MiB limit and MIME allowlist JPEG/PNG/WebP/PDF.
- No production rows, school workspaces, payment receipts, or receipt objects were created. The earlier successful two-workspace isolation evidence remains accepted; no repeat tenant acceptance run was performed.
- The separate migration `20261016170000_schoolpro_disable_online_payment_gateway` was **not** applied. It disables the legacy online/card-payment finalizer and is a distinct payment-channel/product behavior change, not required to secure the receipt-based workflow. Confirm separately if that disablement is intended.
- PR merge and database migrations do not deploy the frontend/API. No Render deployment was performed. SchoolPro production frontend remains hosted on Render. Post-deployment verification is still required after an explicitly approved Render release.
- Stage A operational, receipt-payment, and Storage database changes are applied and catalog-verified; PR #106 is merged. Do not claim end-to-end production UI acceptance until the merged code is deployed to Render and the parent receipt submission/finance review and Storage paths are verified with valid authorized accounts.


### Stage A remaining security proposals applied and deployed — 2026-10-30

- Owner explicitly authorized disabling the legacy online/card-payment gateway and applying the remaining Stage A result-PIN, public-admission, document-serial and public-result-verification changes, including deployment.
- Applied five additional production migrations from merged PR #106:
  1. `20261016170000_schoolpro_disable_online_payment_gateway` — legacy `finalize_schoolpro_payment` now fails closed and EXECUTE is revoked from PUBLIC/anon/authenticated/service_role.
  2. `20261016122000_schoolpro_result_pin_attempt_rate_limit` — private hashed attempt ledger, admission-keyed cooldown, serialized attempts, and trusted service-role-only result PIN RPC.
  3. `20261017133000_schoolpro_public_admission_rpc_abuse_controls` — validated and bounded admission inputs, per-school normalized guardian contact throttles, serialized contact submissions, and service-role-only admission RPC.
  4. `20261017103000_schoolpro_document_serial_global_uniqueness` — global normalized document serial uniqueness; verified index `schoolpro_document_issues_normalized_serial_global_uq` exists.
  5. `20261017120000_schoolpro_result_verification_minimal_snapshot` — public verification output is reduced to aggregate summary fields, including legacy snapshot sanitization.
- Supabase migration API returned success for all five. The production ledger records generated application timestamps `20261030142902`, `20261030142910`, `20261030142918`, `20261030143048`, and `20261030143059` respectively, with the original migration names. Do not rewrite these ledger records.
- Read-only privilege verification confirms `finalize_schoolpro_payment` is not executable by anon, authenticated or service_role; `check_schoolpro_result_pin` and `submit_schoolpro_application` are executable only by service_role among those roles; the private result-PIN attempt table exists; and the normalized global document serial unique index exists.
- Deployed Supabase Edge Function `schoolpro-public-admission` version 1 ACTIVE, `verify_jwt=false`, with Turnstile verification in the function itself. Deployed `schoolpro-result-pin-check` version 1 ACTIVE, `verify_jwt=false`, also requiring Turnstile and calling the service-role-only RPC. For packaging, the result-PIN function's shared Turnstile import was made local (`./turnstile.mjs`) in the deployed bundle; the helper contents are the same merged source helper.
- Render static site `ihlink-schoolpro` (service `srv-db0k11m0tbcc7386fmq0`) has auto-deploy enabled on `main`. Latest Render deploy is **LIVE** for commit `736f7cc8116728efe8b4472b7ab99e7d4f7ea2b7`, which is the post-merge main commit containing PR #106 plus the handover update. The PR merge commit is `c570843ec6bcd983b12771076d4aafcb5029b4fe`.
- Important runtime configuration gate: the Edge Functions require Supabase secrets `TURNSTILE_SECRET_KEY`, `TURNSTILE_ALLOWED_HOSTNAMES`, `SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS`, and (for result checks) `SCHOOLPRO_RESULT_CHECK_ALLOWED_ORIGINS` or the admission-origin fallback, plus platform-provided `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`. The secrets' presence/values and real Turnstile challenge success were not inspectable through the available deployment result. Both functions deliberately fail closed with HTTP 503 if the Turnstile secret or hostname allowlist is absent. Verify these settings in Supabase Edge Function secrets before considering the public flows operational.
- No live admissions, result-PIN checks, fee-payment submissions, document issues, student rows, or receipt objects were created as smoke-test data. Do not claim end-to-end browser acceptance for these flows yet. Perform controlled functional checks with valid test credentials and Turnstile only after confirming secrets/origin allowlists; never weaken the fail-closed behavior.
- Stage A merged, all thirteen PR #106 migrations applied, both new public security gateways deployed, and the Render site is LIVE on post-merge main. Remaining verification is runtime configuration (Turnstile secrets/origins), controlled UI/API workflow smoke tests, and post-deploy observation. The earlier successful two-workspace isolation evidence remains accepted; no repeat live tenant acceptance was run.


## 2026-10-30 Stage A runtime checkpoint and Super Admin dashboard boundary

- Render production static site `ihlink-schoolpro` deployment `dep-dbib3fom7kps73cd7gf0` is LIVE. The public frontend variable `VITE_TURNSTILE_SITE_KEY` was added without replacing existing environment variables; Render completed the rebuild successfully for commit `b7738acd2f31b958811c1fe962a26fced7a30087`.
- Supabase function inventory confirms `schoolpro-public-admission` and `schoolpro-result-pin-check` are ACTIVE at version 3 with `verify_jwt=false`. This inventory does not reveal Edge Function secret values or prove that `TURNSTILE_SECRET_KEY` and the hostname/origin allowlists are configured. Do not claim successful Turnstile Siteverify until that runtime configuration and a valid challenge are verified.
- User confirmed there is currently no usable SchoolPro workspace for controlled admission/result-checker form tests. Defer those functional tests; do not create a school, seed data, or manufacture credentials to unblock them. Existing CI gateway tests and prior CORS/missing-token probes remain the available evidence.
- The Super Admin dashboard complaint is addressed in draft PR #110 (`fix/super-admin-dashboard-boundary-20261030`). The change removes the school selector and ownership-transfer form from the SchoolPro dashboard, stops platform Super Admin from selecting/reading school operational records or bypassing school role/subscription gates there, and leaves a platform-oversight view with a workspace count. The platform Super Admin role and the existing protected `schoolpro-transfer-ownership` Edge Function remain intact; no ownership transfer or database change was performed.
- PR #110 CI at exact head `f29785260b4a84eb13779c1c79127fa3b7f48b44`: Payment-page validation #1828 passed; SchoolPro CI #2103 was still running at this checkpoint, with `tenant-acceptance` skipped as expected. Do not merge or deploy until SchoolPro CI completes successfully.
- Stage A remains code/migration-complete and deployed. Outstanding runtime acceptance is limited to confirming the Turnstile secret/hostname/origin configuration and the controlled public admission/result-PIN functional flows when a valid workspace is available. Do not repeat the earlier two-workspace tenant acceptance test or reopen the already completed Stage A migrations.


## 2026-10-30 follow-up — Super Admin dashboard scope and support contrast

- Clarified the required Super Admin boundary: the SchoolPro dashboard may retain the **Super Admin — administer school** selector and the existing school-administration workflow. The **Transfer school ownership** form/action must not appear on the SchoolPro dashboard; ownership transfer remains a Control Panel-only operation.
- PR #110 now restores the existing Super Admin school selection/context and administration flow while keeping the dashboard ownership-transfer form removed. This does not revoke the platform Super Admin's existing backend capabilities.
- Updated the SchoolPro support knowledge-base controls to force readable foreground/background contrast in dark-theme contexts (search input, topic filters, guide accordions, and guide text).
- Latest corrections are committed on `fix/super-admin-dashboard-boundary-20261030`; they require a fresh GitHub Actions validation before merge. The previous green run predates these final corrections.
- Stage B gaps remain implementation work: attendance write authorization must be limited to Form Masters/explicitly assigned leaders; section assignment needs a structured, enforceable relation; student middle name and guardian contact display need end-to-end support; academic sessions must include 2001–2002 through 2026–2027; Discipline Master and Game Master need role/schema/default-permission support. No production DDL or data changes have been applied for these Stage B items.


## Stage A formal acceptance and Stage B commencement — 2026-10-30

- The owner explicitly confirmed acceptance of the Turnstile secret configuration and Stage A acceptance. The earlier successful two-workspace tenant-isolation acceptance is retained as the tenant-isolation evidence; no replacement workspace or repeat live tenant test is required.
- PR #110 was squash-merged into `main` as `e48613e75442f53ebd2b5bf327b3494e19d222d3`. Render deployment `dep-dbibh4vb9u1s73dvksd0` for that exact commit is confirmed **LIVE**. The deployed changes retain Super Admin school administration, keep ownership transfer out of the SchoolPro dashboard (Control Panel only), and correct Get in Touch help-topic contrast.
- **Stage A is formally accepted and closed by owner confirmation**, including Turnstile configuration and acceptance. Do not reopen Stage A or repeat completed acceptance checks absent a new regression.
- Stage B work begins on branch `stage-b/academic-sessions-student-rosters-20261030`, based on merged `main`. Execution order: B1 academic session coverage and session semantics; B2 student population and student/guardian data; B3 session-specific class rosters and progression; then connected B4 staff/class/subject assignment, B5 attendance/section authorization, and B6 Discipline Master/Game Master roles.
- B1 initial implementation replaces the rolling 31-year selector (which omitted 2001–2010) with a canonical range from 2001/2002 through the current calendar year's next session, retaining any currently selected custom session. A focused regression test verifies 2026 includes 2001/2002 through 2026/2027 and rolls forward in 2027. This is code-only; no production database change is involved.
- Existing `schoolpro_enrollment_history`, session-aware roster helper, class Form Master field, and subject assignment tables must be preserved and extended rather than rebuilt. No production DDL/DML or production migration has been applied for Stage B.


### Stage B2 initial student identity slice — 2026-10-30

- Added nullable `schoolpro_students.middle_name` in proposed migration `20261030160000_schoolpro_student_middle_name.sql`, with a 100-character trimmed-length constraint. The migration is committed to the Stage B branch only; it has **not** been applied to production.
- Student enrolment now captures middle name and includes it in the student-list query/display. Class, attendance, parent-management and parent-dashboard reads were extended to fetch middle name; parent management also requests the linked guardian profile phone for contact display. Parent relationship remains sourced from `schoolpro_guardian_links.relationship`.
- Existing student-level guardian name and phone fields remain intact; no guardian records or linked profiles are rewritten. This first slice does not yet add phone capture to parent invitations; that requires a separate review of the invitation Edge Function/profile update path.
- Added `scripts/test-academic-sessions.mjs` to SchoolPro CI. The PR is still draft; typecheck/build and all existing security integrations must pass before this slice can be considered ready. The migration must receive explicit production approval before application.


### Stage B3 initial class-roster slice — 2026-10-30

- `SchoolProClasses` now exposes the selected academic session and scopes its student roster/counts through the existing `schoolSessionStudents()` helper and `schoolpro_enrollment_history` data. For schools with no enrollment-history rows yet, the helper's existing legacy fallback remains intact; when history exists, historical session/class membership is used instead of current student class placement.
- Historical roster loading does not filter out students merely because their current student record is inactive/transferred; the selected session's history determines their historical membership. The current/legacy fallback still uses active students.
- This extends the existing history implementation; no new roster table or production data change is introduced.


### Stage B1 — academic session lifecycle and calendar history implementation slice — 2026-10-30

- Added proposed migration `20261030190000_schoolpro_academic_session_lifecycle_and_calendar_history.sql` on the Stage B branch. It introduces school-scoped academic-session date ranges with upcoming/active/completed/archived lifecycle states, append-only before/after calendar history for session and term changes, and permission-checked save/archive RPCs. Session rows and term calendar rows cannot be deleted through these trigger paths; completed sessions are archived instead.
- Session date ranges cannot overlap another non-archived session. Configured term dates must remain inside their academic session; session dates cannot be narrowed to exclude already configured terms. Existing term non-overlap validation remains in force. Calendar-history rows reject update/delete mutations at the database layer.
- Added `SchoolAcademicSessionManager` to the existing academic calendar view. It exposes session start/end dates, notes, date-derived status, completed-session archival and the latest 30 calendar-history entries. Existing term editor remains in place.
- Replaced the separate rolling 31-year list in `SchoolSessionBar` with the canonical `AcademicPeriodSelect`. Its explanatory text explicitly states that changing the working session does not promote students or move enrolments.
- Added deterministic date-state tests and static migration guards to `scripts/test-academic-sessions.mjs`.
- The migration is proposed only and has **not** been applied to Supabase production. No production data, workspace, or deployment changes were made. Calendar UI lifecycle actions require this migration to be applied in a separately approved migration window before use.
- Remaining B1 work: run exact-head CI; verify SQL migration against a disposable PostgreSQL schema with the relevant Supabase role/function/table prerequisites; review session/term activity stamping and the existing calendar tick for boundary conditions; verify calendar history visibility for all intended staff roles; and ensure every session-scoped module consumes the same selected session without changing enrolments. B1 is **in progress**, not complete.


- Exact-head CI initially exposed a stale Super Admin context regression test: the Stage A dashboard now intentionally supports explicit school selection, while the test still expected Super Admin to ignore every selection. The underlying context selection expression also allowed the generic remembered member-workspace key to take precedence. Corrected it so Super Admin can resolve only an explicit URL school selection or the dedicated Super Admin dashboard selection, never a generic remembered workspace; updated the regression assertions accordingly. This preserves the Stage A dashboard workflow and its tenant boundary.

- Separated the academic-calendar editor's session choice from the global working-session selector. Choosing a session to edit calendar dates no longer changes the session used by the rest of the dashboard; the shared selector supports this explicitly and a regression assertion covers it.

### Stage B1 follow-up — SQL delimiter correction and calendar editor isolation — 2026-10-30

- Exact source review found two malformed single-dollar PL/pgSQL function delimiters in the proposed calendar lifecycle migration. Corrected both function bodies to paired `$$` delimiters before any production application. Added a CI assertion that the migration's function-body delimiters are balanced and that malformed single-dollar delimiters are absent.
- Both the academic-session manager and the existing term-date editor now use the shared session selector with `updateWorkingSession={false}`. Selecting a session to edit calendar metadata or term dates therefore cannot change the dashboard's global working session. Added a regression assertion for the term editor as well.
- This is a source-level correction only. The migration remains unapplied; no production database, data, workspace or deployment was changed.
- Remaining B1 validation: exact-head CI after these corrections; disposable PostgreSQL execution against the actual Supabase schema/roles; permission review for the calendar RPCs; verify the dynamic current-period RPC and activity stamping continue to use the intended dates/session. B1 remains in progress.


### Stage B1 follow-up — align session lifecycle permissions with existing calendar controls — 2026-11-02

- Reviewed the existing academic calendar and operational session migrations. The current calendar save RPC requires both the calendar module and explicit school access for proprietor, administrator, registrar, head teacher and vice principal. The first draft of the new session save/archive RPCs instead required the promotions module and did not repeat that explicit role boundary.
- Corrected both new RPCs to use the established calendar module plus the same explicit school-role access list. Session date management no longer depends on the separate promotions module. Added static regression assertions for both RPC guards and the preserved role list.
- Confirmed the existing academic clock is driven by `schoolpro_result_term_settings` date ranges, while operational activity stamping resolves session by activity date and preserves the original session on later updates. The new session-date table does not yet drive that clock. This remains a required integration decision: avoid silently making session metadata override term-based activity history until the intended source-of-truth behavior is implemented and tested.
- The existing term settings schema includes `school_id`, `session`, `term`, `term_start_date`, `term_end_date`, `updated_by` and `updated_at`; the proposed history/validation triggers reference those known fields. Existing calendar management role policy is the authority for session RPC access.
- Changes are source-only on the Stage B branch. No production migration, data change, workspace creation or deployment. PostgreSQL execution against a disposable schema and exact-head CI remain outstanding.

### Stage B1 follow-up — session-aware activity stamping — 2026-11-02

- Updated the proposed session lifecycle migration to replace the activity-period insert trigger with a two-part date resolver: configured `schoolpro_academic_sessions` date ranges determine the session, while the existing `schoolpro_result_term_settings` date ranges continue to determine the term.
- When a school has at least one explicit session record, an activity without an explicit session receives a session only when its activity date falls inside a non-archived configured session. A date inside the session but outside all configured terms receives the session and a null term. A date outside all configured sessions receives no inferred session.
- For a school that has not yet configured any explicit session rows, the legacy term-date inference remains in place as a transition path. Explicitly supplied session values are validated and retained; the trigger does not replace them with the current working-session selection. Existing update-time session immutability remains governed by the previously installed preserve-session trigger.
- The academic clock remains term-date driven; this change does not make the working-session selector or the new session table silently alter current-term notifications or enrollment history.
- Added source-level regression assertions for date-range resolution, archived-session exclusion, legacy fallback, term independence and explicit-session preservation. This is not PostgreSQL execution evidence. The migration remains proposed and unapplied; no production data, workspace, deployment or database state was changed.
- Remaining B1 work: validate this trigger and migration against PostgreSQL/Supabase prerequisites when a disposable environment is available; inspect the existing transcript and progression flows against the requested full-stage history and configurable promotion criteria; run exact-head CI.

## Stage B1 continuation — promotion policy review and SQL correction (2026-11-02)

- Reviewed the current year-end bulk academic action implementation in `supabase/migrations/20261012070029_schoolpro_bulk_year_end_academic_actions.sql` and the issued-transcript snapshot workflow in `supabase/migrations/20261011170620_schoolpro_issued_transcript_workflow.sql`.
- Confirmed the current bulk progression decision is hardcoded: students with an average below 30% repeat; otherwise SS3/SSS3 class names graduate; all others are mapped to a next class. This does not meet the requested default repeat threshold of below 45%, and there is no school-configurable required-subject pass threshold in this RPC. No progression policy or student records were changed in this step.
- Confirmed issued transcript snapshots already collect published subject results across sessions and retain the enrollment-history class name/arm for each session. The current snapshot does not explicitly classify records into academic stages or include independently verified stage-completion evidence. Certificate eligibility therefore needs a separate completion record/workflow; a class label alone must not authorize a certificate.
- Corrected the session-aware activity trigger body in the proposed B1 migration: its PL/pgSQL body had malformed single-dollar delimiters (`as # SchoolPro Master Migration and Production Cleanup Handover

**Last updated:** 2026-11-02  
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
- Exact-head SchoolPro CI #2050 passed all seven executable jobs, including `tenant-integrity-db-integration`; `tenant-acceptance` was skipped (manual/conditional; no active school workspaces) and is not counted as a pass. Payment-page validation #1775 also passed.
- This closes the specific disposable fixture-coverage action. Next review gate is full-schema/trigger interaction and migration-ledger reconciliation. PR #106 remains draft/unmerged pending those gates and remaining release checks. No production database changes, migrations, workspace creation, or deployment were performed.



### Stage A full-schema trigger-interaction source review — 2026-10-29

- Reviewed the proposed `20261016160000_schoolpro_repair_operational_tenant_integrity.sql`, `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` and `20261017180000_schoolpro_operational_tenant_indexes.sql` alongside the existing lesson-note and calendar workflow migrations on `release/stage-a-auth-tenant-isolation`. This was source-only review; no database was connected to or changed, and no migration, merge, or deployment was performed.
- Confirmed the new tenant guard is complementary to existing workflow triggers rather than replacing their workflow rules: `schoolpro_lesson_workflow` continues to enforce lesson author/review/status rules, while `validate_schoolpro_lesson_notes_tenant` validates same-school subject/class references and immutable tenant ownership. The calendar's existing `validate_schoolpro_calendar_workflow` continues to validate date/class relationships; the added `immutable_schoolpro_calendar_events_tenant` trigger separately rejects school reassignment. The PostgreSQL alphabetical ordering of same-timing triggers means the workflow trigger executes before the `validate_*` tenant trigger; neither source currently relies on the other having already modified `NEW`.
- The generic guard uses an empty `search_path`, schema-qualified relation names and `SECURITY DEFINER`; it rejects missing or cross-school references for lesson notes, result approvals, and promotions. The RLS posture migration changes only `ENABLE/FORCE ROW LEVEL SECURITY` flags, preserving existing feature policy definitions, and the index migration adds six school-leading indexes without row writes.
- **Remaining test limitation:** the disposable integration SQL builds a minimal schema and does not install the existing lesson workflow or calendar workflow triggers from their source migrations. Thus CI proves the tenant guard and representative authenticated policies in isolation, but not their combined execution against the complete historical feature-trigger stack. No direct trigger-name collision was found in the reviewed source; a complete combined-stack integration test remains the appropriate closure before treating trigger interaction as fully validated.
- Next gate is migration-ledger reconciliation (repository migration files versus the live Supabase migration ledger), while retaining the recorded provenance gap. Do not replay migrations or modify production to reconcile it. PR #106 remains draft/unmerged; live `tenant-acceptance` remains skipped/unverified, and no production database changes, migration, workspace creation, or deployment occurred.


### Stage A migration-ledger reconciliation snapshot — 2026-10-29 (read-only)

- Read the live Supabase migration ledger for project ref `lnqsroyiybutkfngbyge` and enumerated migration filenames on `release/stage-a-auth-tenant-isolation`. No SQL writes, migrations, or ledger edits were issued.
- Current exact-version comparison: **485** live ledger entries versus **136** migration files on the Stage A branch; **79** exact version matches; **406** live-only versions; **57** branch-only versions. A name-based comparison finds **103** migration names shared between the two sets, including **24** whose timestamps/versions differ. The prior handover's 397/44 figures are therefore a stale inventory snapshot and must not be used as current counts.
- This is a provenance/history mismatch, not a safe candidate list for applying or marking migrations. Matching names with different versions must be reconciled against file contents, commit history, and the existing sync-ledger history before deciding whether a change was renamed, applied from a different source, or is genuinely missing. The live ledger's latest listed entry is `20261028130707 index_schoolpro_result_events_result_id_for_workspace_cleanup`; the Stage A branch's latest listed migration file is `20261017180000_schoolpro_operational_tenant_indexes.sql`, so the two histories have different coverage horizons.
- **No automated ledger repair is authorized.** Do not run the repository's remote migration-sync/ledger SQL, insert/delete ledger rows, replay historical migrations, or alter production schema/data as a reconciliation shortcut. The next safe task is to create a content- and commit-provenance mapping for the 24 same-name/different-version pairs and the branch-only/live-only sets, then present an explicit reconciliation proposal before any mutation.
- Stage A remains open; PR #106 remains draft/unmerged. Live tenant acceptance is still skipped/unverified. No production database changes, migration, workspace creation, merge, or deployment occurred.


### Migration provenance follow-up — 2026-10-29

- Checked GitHub file history for three representative same-name/different-version pairs: `schoolpro_finance_and_result_access`, `schoolpro_parent_portal`, and `schoolpro_remote_migration_sync_ledger`. Their current branch files were introduced by the 2026-09-26 “Restore SchoolPro migration” commit, while the live ledger records different versions for the same names. This supports a source-restoration/timestamp-provenance explanation for at least these samples, but it does **not** prove the restored file contents are byte-identical to the SQL originally applied in production.
- Inspected `20260926114500_schoolpro_remote_migration_sync_ledger.sql`: it is a documentation/boundary marker ending in `select 1;`; it does not insert or update the Supabase migration ledger. Its comments list a historical applied-migration boundary and explicitly say not to replay inferred production DDL. Do not treat this file as a reconciliation mechanism or run it against production for that purpose.
- The remaining exact-version/name mismatches and the live-only set still require source/commit provenance evidence. The safe output is an evidence matrix, not a guessed “repair” migration. No production writes or migration-ledger changes were made.


### Migration provenance matrix — first-pass classification — 2026-10-29

Read-only inputs: live Supabase migration ledger for `lnqsroyiybutkfngbyge`, migration filenames on `release/stage-a-auth-tenant-isolation`, GitHub file SHAs, and selected GitHub commit histories. The exact-version comparison was repeated for this matrix; counts remain 485 live entries, 136 branch files, 79 exact-version matches, 406 live-only versions, and 57 branch-only versions.

| Classification | Count | Interpretation / safe handling |
|---|---:|---|
| Exact version match | 79 | Version exists in both lists; this does not prove source content equals deployed schema. |
| Same migration name, different version | 24 | Timestamp/provenance conflict; compare historical file contents and commit history, do not rename or mark applied by assumption. |
| Branch-only name and version | 33 | Not present in the current live ledger by exact version or name; treat as unapplied/uncertain until evidence proves otherwise. Never auto-apply. |
| Live-only versions | 406 | Version not present in the current branch inventory; may reflect ecosystem migrations, deleted/restored files, or branch coverage gaps. Do not label every entry “missing SchoolPro source.” |

**Important scope split:** the live-only set spans the wider IHLink ecosystem, not just SchoolPro. Examples include DataSub and BillStack migration names. It also includes late SchoolPro changes, such as `20261019192635 fix_schoolpro_document_tenant_scope`, `20261019193201 enforce_published_locked_family_result_reads`, and `20261028130707 index_schoolpro_result_events_result_id_for_workspace_cleanup`. These examples establish that the Stage A branch inventory is not a complete mirror of the current live ledger; they do not justify importing/replaying these migrations or changing the branch automatically.

**First-pass provenance finding:** GitHub history for the representative same-name/different-version samples indicates a 2026-09-26 “Restore SchoolPro migration” commit for some restored files. The sync-marker migration itself is documentation plus `select 1`, not a ledger-repair operation. Source-file equality with historical deployed SQL remains unproven. Thus the matrix classifies evidence only; it is not an execution plan.

**Next safe gate:** review the 33 branch-only migrations as a bounded list and classify each by scope (Stage A security, other SchoolPro feature, payment/subscription, ecosystem/DataSub, or sync marker), then inspect live ledger and commit provenance for the Stage A-relevant subset. Do not run Supabase migration commands, alter the live ledger, replay migrations, merge PR #106, or deploy as part of this review. Production remains unchanged; PR #106 remains draft/unmerged; tenant acceptance remains skipped/unverified.


### Stage A live operational schema reconciliation — 2026-10-29 (read-only)

- Queried the live Supabase PostgreSQL catalogs read-only for all eight operational tables targeted by Stage A: library books, transport routes, hostel rooms, inventory assets, calendar events, lesson notes, result approvals, and promotions. All eight tables exist in `public`; all eight have RLS enabled, but **all eight currently report `FORCE ROW LEVEL SECURITY = false`**. This corroborates that the proposed forward-only RLS posture migration is not reflected in the live catalog yet. No DDL or row writes were issued.
- Live policy inventory: library books has 2 policies, transport routes 1, hostel rooms 1, inventory assets 1, calendar events 2, lesson notes 2, result approvals 2, promotions 1. The live calendar, lesson-note, result-approval and promotion policies are feature-specific and do not match the simple policy names/definitions in the older `20261002234500_schoolpro_operational_tenant_isolation.sql` source. That older migration explicitly drops all existing policies on these tables before replacing them; **do not replay it** as a way to enable RLS, because it could remove current feature-specific access semantics. The forward-only `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` is the safer candidate to evaluate because it changes RLS flags while preserving policies, but remains unapplied and must pass remaining gates first.
- Existing live triggers on the eight tables include `schoolpro_activation_before_write` on all eight; calendar also has activity-session/calendar validation and `validate_schoolpro_calendar_workflow`; lesson notes has `schoolpro_lesson_workflow` plus activity-session/calendar validation; promotions has `schoolpro_archive_applied_progression`. The proposed `validate_schoolpro_lesson_notes_tenant`, `validate_schoolpro_result_approvals_tenant`, `validate_schoolpro_promotions_tenant`, and immutable-school triggers are not present in the live trigger inventory. No direct trigger-name collision was observed in this snapshot. This is catalog evidence only; it does not establish complete trigger-order behavior or validate trigger execution against live data.
- Existing policy definitions on lesson notes rely on author/leadership access functions; calendar policies rely on calendar module/role access; result approvals use result module and leadership checks; promotions has a manager-read policy. Preserve those semantics during any future posture change. The disposable integration test still does not install the full historical lesson/calendar trigger stack, so combined-stack validation remains open.
- Next safe gate: inspect the full live function definitions for the existing operational-write and lesson/calendar workflow triggers, then close the combined-stack test gap on a disposable database. Separately confirm the six proposed school-leading indexes against the complete live index inventory. Keep the migration ledger as evidence only; do not apply migrations, alter the ledger, seed production, create test workspaces, merge PR #106, or deploy without explicit approval.
- PR #106 remains draft/unmerged; live tenant acceptance remains skipped/unverified. This reconciliation was read-only and did not change production.


### Stage A existing trigger-function and index inventory — 2026-10-29 (read-only)

- Continued read-only catalog review of the existing trigger functions on the eight operational tables. The shared `private.guard_schoolpro_operational_write()` trigger is SECURITY DEFINER with an empty search path; it enforces the operational activation/subscription gate for authenticated writes, while explicitly allowing trusted non-anonymous background writes when `auth.uid()` is null. The existing lesson workflow trigger independently requires an authenticated user and enforces author scope, immutable author/school, and review-state transitions. The calendar workflow function validates event date ordering and same-school class references. The promotion archive trigger writes enrollment-history records when a promotion transitions to applied, and independently checks same-school student/classes. These existing feature semantics must be retained when the proposed tenant guards are added.
- Read-only live index inventory confirms the six indexes declared by `20261017180000_schoolpro_operational_tenant_indexes.sql` are currently absent: `schoolpro_library_books_school_id_idx`, `schoolpro_transport_routes_school_id_idx`, `schoolpro_hostel_rooms_school_id_idx`, `schoolpro_inventory_assets_school_id_idx`, `schoolpro_result_approvals_school_id_idx`, and `schoolpro_promotions_school_id_idx`. Existing indexes include a school/session index on calendar events and several school-leading indexes on lesson notes; promotions and result approvals have other uniqueness indexes but no school_id-leading index in the observed inventory. This is a performance/catalog difference, not evidence of a tenant leak by itself.
- The combined trigger stack is still not integration-tested: the disposable fixture omits the existing activation, lesson/calendar workflow, session/calendar validation, and promotion archival triggers. Before treating the new tenant guard as fully validated, extend the disposable PostgreSQL fixture to model the relevant existing triggers and test compatible insert/update paths plus cross-tenant reference rejection. Keep this test non-production.
- This catalog review was read-only. No migration, production DDL/data changes, ledger edits, test-workspace creation, deployment, or merge occurred. PR #106 remains draft/unmerged and live tenant acceptance remains skipped/unverified.

### Stage A combined lesson/calendar workflow fixture — 2026-10-29

- Added a disposable integration-test extension on PR #106 commit `78dae7a8197039aefd2388b375bad6b705840a5d` to exercise the proposed operational tenant guards alongside a modeled lesson-note review workflow and calendar validation workflow. Assertions cover lesson draft/submit/review transitions, author self-approval denial, submitted-content immutability, reviewer identity retention, valid calendar insertion, reversed-date rejection, cross-school class rejection, and school reassignment rejection.
- Exact-head GitHub Actions validation completed successfully: [SchoolPro CI #2059](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40904530773) passed all seven executable jobs, including `tenant-integrity-db-integration`; `tenant-acceptance` was skipped because no active school workspaces exist. [Payment-page validation #1784](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40904530601) also passed.
- **Coverage limitation:** the new lesson/calendar workflow helpers are disposable test doubles / compact equivalents, not restored copies of the full live workflow functions. The fixture does not prove the full production trigger stack, trigger ordering, activity-session/calendar validation dependencies, activation guard behavior, or promotion archival behavior together. Keep this gap explicit; do not describe the test as full production-schema equivalence.
- No production database changes, workspace creation, migration, merge, or deployment occurred. PR #106 remains draft/unmerged. Live tenant acceptance remains skipped/unverified. The unrelated Vercel status context is not the production deployment signal; SchoolPro production frontend remains on Render.

### Stage A live trigger-definition retrieval — 2026-10-30

- Retrieved the exact live PostgreSQL definitions read-only through the Supabase SQL connector for `private.guard_schoolpro_operational_write()`, `private.schoolpro_validate_lesson_workflow()`, `private.validate_schoolpro_workflow_record()`, and `private.schoolpro_archive_progression()`. No production DDL, DML, migration, or ledger operation was performed.
- Confirmed the activation guard is SECURITY DEFINER with an empty search path. For authenticated writes it resolves the old/new record school and checks `private.schoolpro_operationally_active(...)`; it also rejects unscoped records without SchoolPro edit access. Its explicit trusted-background bypass applies only when `auth.uid()` is null and the JWT role is not `anon`. A faithful disposable test therefore needs the helper dependencies and must distinguish authenticated, anon, and trusted-background contexts.
- Retrieved the full lesson workflow function. It requires `auth.uid()`; stamps the creator on insert; allows initial draft/submitted states; prevents author/school reassignment; blocks deletion of submitted/approved lessons; enforces author scope; and restricts approval/change-request transitions to leadership, with reviewer identity and timestamp set by the function. The existing PR fixture already includes a disposable implementation of this function and tests core author/review transitions, but uses test helper functions for leadership and author scope.
- Retrieved the exact calendar trigger function `private.validate_schoolpro_workflow_record()`. It is shared by multiple operational tables and contains table-specific branches for payroll, health records, and calendar events. Its calendar branch rejects reversed event dates and classes outside the event school; its common update branch rejects school reassignment. The current PR fixture uses a compact calendar-only equivalent, not the exact shared production function. Exact reuse requires the disposable calendar table to supply the production-referenced columns/relations, or a carefully isolated faithful extraction with its scope stated.
- Retrieved the exact AFTER UPDATE promotion archive function `private.schoolpro_archive_progression()`. On a transition to `applied`, it validates the academic session, source class and student school, writes the prior enrollment-history row, and for promoted/repeated decisions validates the destination class and writes the next-session enrollment-history row. The current fixture does not yet define the full production promotion/session/enrollment-history shape or install this archive trigger; this is an outstanding test gap.
- Live column inventory confirms the promotion table uses `from_class_id`, `to_class_id`, `decision`, `session`, and `status`; `schoolpro_enrollment_history` has school/student/session/class/status/promotion fields. The minimal disposable fixture currently has only the promotion identifiers and source/destination class IDs, so the production function cannot simply be attached without extending its dependencies and fixtures.
- Next test change: extend the disposable fixture with the exact promotion columns and enrollment-history table, production-equivalent class fields (`name`, `arm`, `level`), and a valid 2026/2027 promotion scenario; install the exact promotion archive function and assert both history rows for a promoted decision plus rollback/no history on a cross-school source or destination. Replace the compact calendar function only after the disposable schema satisfies its full referenced dependencies. Keep activation-guard coverage separate until the helper functions it calls can be reproduced faithfully. Do not run any of these definitions against production.


## Stage A promotion archive integration coverage — 2026-10-30

- Extended `scripts/test-schoolpro-operational-tenant-integrity.integration.sql` on PR #106 branch `release/stage-a-auth-tenant-isolation` at commit `12ef364bc01ed628a3af951581059021416d9a75`.
- The disposable PostgreSQL fixture now installs the exact body retrieved read-only from live `private.schoolpro_archive_progression()` as an AFTER UPDATE trigger. It adds the class fields and enrollment-history uniqueness/columns required by that function, then applies a promoted decision and asserts both source-session `completed` and next-session `active` history rows.
- Added a cross-school destination rejection assertion against the existing operational tenant-integrity BEFORE trigger and verifies no enrollment-history row is written for the rejected promotion.
- This is still a disposable integration fixture; it does not alter production. The exact-head CI run has not yet been observed, so this test change is **not yet accepted**. PR #106 remains open/draft/unmerged.
- Next: inspect exact-head CI and fix any fixture/function mismatch before claiming coverage. Calendar's production shared trigger and activation-gate dependency stack remain separate follow-ups; do not replace them with approximations and call them exact.


## Promotion archive test exact-head CI acceptance — 2026-10-30

- Exact PR #106 test head `12ef364bc01ed628a3af951581059021416d9a75` completed validation successfully.
- SchoolPro CI run [#41025364963](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41025364963): all seven executable jobs passed, including `tenant-integrity-db-integration`; `tenant-acceptance` was skipped because its live acceptance prerequisites were not enabled. The tenant-integrity job's disposable PostgreSQL migration/test step completed successfully.
- Payment-page validation [#41025365014](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41025365014): passed.
- This accepts the new disposable promotion archive assertions for this exact head; it does not constitute production migration approval or live two-tenant acceptance. PR #106 remains draft/open/unmerged. No production changes or deployment occurred.
- Next test gap: faithfully exercise the deployed shared calendar workflow trigger and the activation-gate trigger stack using the exact production definitions and their dependencies, rather than compact substitutes. Preserve the existing lesson workflow helper-stub limitation in test reporting.

### Stage A calendar workflow exact-function test — 2026-10-30

- The disposable tenant-integrity fixture now installs the exact live `private.validate_schoolpro_workflow_record()` body for its calendar trigger, exercising the calendar validation and common immutable-school path. Payroll and health branches are not invoked; inert disposable enum/helper definitions exist only for function compilation.
- Exact PR #106 head `f6fdaede9cdcdc9bf728ad7d56f1e242a2bbe3fa` passed SchoolPro CI run #41027611391 (all seven executable jobs successful; tenant-acceptance skipped) and payment-page validation #41027611469. The tenant-integrity integration job passed.
- Activation-guard coverage remains open: faithful coverage still needs its production dependency stack and authenticated, anonymous, and trusted-background context tests. No mock-only result should be represented as exact production coverage.
- No production mutation, migration, ledger edit, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live tenant acceptance is not established.


### Stage A activation-guard integration test — 2026-10-30 (exact-head CI follow-up)

- Added disposable PostgreSQL coverage for the exact live `private.guard_schoolpro_operational_write()` function and its school-resolution/subscription-activation dependencies on PR #106 branch `release/stage-a-auth-tenant-isolation`. The test exercises inactive-school rejection, active-school acceptance, anonymous inactive-school rejection, and the trusted `service_role` background-write bypass. The no-school/global `private.has_product_access('schoolpro','edit')` fallback is stubbed false and is not covered; this is explicitly outside the tested scenarios.
- Initial exact-head run for commit `aadaa9a2fd1a1f1a1ae4407b39a8eeb33ae50f3f`, SchoolPro CI #2068, failed because the test expected a shortened error string rather than the exact production exception text. Payment validation passed.
- Corrected both expected exception strings in commit `c323c6186883bc65db1cf03f33d12294cb4b3862`. Exact-head SchoolPro CI #2070 then passed the other six executable jobs but **failed** `tenant-integrity-db-integration`; payment validation #1795 passed and live `tenant-acceptance` was skipped. The failing statement is the trusted-background insert for the inactive fixture school. The production guard raised the activation-required exception, indicating the disposable session still had an authenticated subject context when the test expected `auth.uid()` to be null. This is a fixture-context setup defect to resolve before claiming the bypass assertion; it is not evidence that the production guard is defective.
- Next: explicitly clear the disposable JWT subject/claims before setting the `service_role` role claim, then rerun exact-head CI. Keep all test work confined to disposable PostgreSQL. No production DDL/DML, migration, ledger edit, merge, deployment, or workspace creation occurred. PR #106 remains draft/open/unmerged; live tenant acceptance is unverified.


### Stage A trusted-background fixture context correction — 2026-10-30

- Follow-up to the #2070 failure: the disposable test now clears both `request.jwt.claim.sub` and `request.jwt.claims` before setting `request.jwt.claim.role` to `service_role`. This ensures the exact production `auth.uid()` helper resolves NULL for the trusted-background case, rather than inheriting a subject left by an earlier integration assertion.
- Branch commit: `1f817abafac8dfd312183e5af268e14984366849`. Exact-head CI has been triggered by the PR update and is pending confirmation. Do not count the activation-guard bypass test as accepted until `tenant-integrity-db-integration` passes.
- No production changes, migration, ledger edits, merge, deployment, or test-workspace creation occurred. PR #106 remains draft/open/unmerged; live tenant acceptance remains skipped/unverified.

### Stage A activation-guard fixture — tenant-integrity job accepted — 2026-10-30

- The JWT-context correction at PR #106 commit `1f817abafac8dfd312183e5af268e14984366849` resolved the trusted-background test failure. Exact-head SchoolPro CI #2072 reports `tenant-integrity-db-integration` **passed**. The job executed the disposable migration and integration SQL successfully, including active-school acceptance, inactive/anonymous rejection, and the `service_role` background bypass with a null subject context.
- At the time of this handover update, the remaining `validate` and local Receipt Storage isolation jobs were still running, so the overall SchoolPro CI workflow is **in progress**, not yet fully accepted. The other completed executable integration jobs are passing; live `tenant-acceptance` is skipped. Payment-page validation #1797 passed.
- The activation test intentionally stubs `private.has_product_access('schoolpro','edit')` false; the no-school/global-edit fallback is not covered. This fixture limitation remains explicit. Lesson workflow helper-scope limitations documented above also remain.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance is unverified.

### Stage A activation-guard fixture — full exact-head CI accepted — 2026-10-30

- Exact PR #106 head `1f817abafac8dfd312183e5af268e14984366849` completed successfully: [SchoolPro CI #2072](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41036514889) concluded **success**. All seven executable jobs passed, including `tenant-integrity-db-integration`, `validate` (typecheck, application checks and build), the payment-review RLS integration, public-admission abuse integration, result verification exposure, result-PIN/rate-limit integration, and local Receipt Storage isolation. The conditional live `tenant-acceptance` job was **skipped**.
- [Payment-page validation #1797](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41036514814) also concluded **success**.
- The activation-guard disposable integration assertions are accepted for this exact head: inactive-school rejection, active-school acceptance, anonymous inactive-school rejection, and trusted `service_role` background-write bypass after clearing JWT subject/claims. The fixture still stubs `private.has_product_access('schoolpro','edit')` false; the no-school/global-edit fallback is not covered. Lesson workflow helper-scope limitations remain as documented above.
- This is CI evidence from disposable/local test environments, not live tenant acceptance or production-schema equivalence. No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains skipped/unverified.
- **Next bounded Stage A task:** resolve the previously documented member-permission tenant reassignment gap in `20261016160000_schoolpro_repair_operational_tenant_integrity.sql`: reject simultaneous `school_id` and `member_id` reassignment and add a disposable PostgreSQL negative test. Review the exact current migration and fixture before editing; keep production untouched.


### Stage A member-permission tenant immutability — existing branch fix verified — 2026-10-30

- Rechecked the current PR #106 branch after the earlier handover note listed simultaneous `school_id` + `member_id` reassignment as an open source/test blocker. The current migration already contains the guard in `private.validate_schoolpro_member_permission_tenant()`: on UPDATE, any `NEW.school_id IS DISTINCT FROM OLD.school_id` raises `Permission school ownership cannot be reassigned`, before the referenced-member tenant check.
- The disposable PostgreSQL integration SQL already covers: (1) rejection of a permission row referencing a member from another school; (2) acceptance of reassignment to another member within the same school; and (3) rejection of a simultaneous tenant and member reassignment to a valid pair in another school. The static contract test also asserts the immutability guard exists.
- These assertions ran as part of exact-head SchoolPro CI #2072 on PR #106 head `1f817abafac8dfd312183e5af268e14984366849`; `tenant-integrity-db-integration` passed and the overall workflow concluded success. Therefore the member-permission reassignment source/test blocker is **closed on the current PR branch**; the earlier 2026-10-28 review note is historical and must not be treated as an outstanding code defect.
- This closure is limited to the disposable migration/test evidence. It does not authorize production application or establish live tenant acceptance. PR #106 remains draft/open/unmerged; no production DDL/DML, migration, ledger edit, merge, or deployment occurred.


### Stage A lesson-workflow helper dependency review — 2026-10-30 (read-only)

- Retrieved the exact live definitions of `private.schoolpro_validate_lesson_workflow()`, `private.schoolpro_lesson_author_scope(uuid,uuid,uuid)`, and `private.schoolpro_lesson_leader(uuid)` from Supabase PostgreSQL using read-only catalog queries. No production changes were made.
- The disposable fixture's lesson-workflow trigger body mirrors the live trigger's state-transition and validation logic, but its two authorization helpers remain simplified test doubles. The production author-scope helper joins `schoolpro_members` to active `profiles`, checks teacher/class-teacher roles, then validates either the member's `form_teacher_id` class assignment or a matching `schoolpro_subject_assignments` row. The production leadership helper checks active profile status, platform `super_admin`, school ownership, or school membership in administrator/head_teacher/vice_principal roles.
- Current fixture limitation is therefore narrower and more precise than “lesson workflow is mocked”: the trigger function body is represented, but its author-scope and leadership authorization dependencies are not yet faithfully modeled. Existing lesson assertions validate workflow transitions only under deterministic helper outputs; they do not prove production role/assignment resolution.
- Next bounded test improvement: extend only the disposable PostgreSQL fixture with the minimum profiles, member-role, class form-teacher, subject-assignment, and platform-role helper dependencies needed to execute the exact helper predicates (or a documented isolated extraction). Add positive/negative assertions for assigned vs unassigned teacher and school leader vs non-leader. Keep the live database read-only and do not copy production user/business rows into fixtures.
- PR #106 remains draft/open/unmerged. No production DDL/DML, migration, ledger edit, merge, deployment, or workspace creation occurred.


### Stage A lesson authorization fixture upgraded to production predicates — 2026-10-30

- PR #106 adds deterministic disposable fixtures for `profiles`, `schoolpro_members`, `schoolpro_classes.form_teacher_id`, `schoolpro_subject_assignments`, and school ownership, and replaces the simplified lesson-author/leader helper doubles with the exact live SQL predicates retrieved read-only from Supabase.
- The fixture's `private.is_admin(user_role[])` is an isolated test implementation of the live helper's exact predicate: active profile, matching `auth.uid()`, and requested platform role. The lesson leader and author-scope helper bodies themselves mirror the live definitions. No production users or school records are copied.
- Added assertions for form-teacher authorization, assigned-subject-teacher authorization, denial of unassigned and inactive teachers, and leadership granted to a school administrator/owner but denied to an ordinary teacher/inactive profile.
- PR branch commits: `8af6fc6` (fixture/helper implementation) and `18ca23e` (expanded fixture column insert correction). Exact-head CI has not yet been evaluated; this is pending disposable CI validation, not a completed test result.
- No live database writes, production DDL/DML, migration, ledger edit, merge, or deployment occurred. PR #106 remains draft/open/unmerged.


### Stage A lesson authorization fixture — SQL quoting correction — 2026-10-30

- Exact-head SchoolPro CI #2079 for PR #106 test head `18ca23e4fdf21d9aa119701f30cf9088498ee999` completed with one failing job: `tenant-integrity-db-integration`. The failure occurred at the first disposable SQL setup statement, before the migration or assertions ran: eight newly added anonymous DO blocks used the invalid delimiter `do $ ... end $;` rather than a valid paired dollar quote. This is a test-fixture syntax defect, not a production database failure.
- The other six executable CI jobs passed, including typecheck/application validation/build, result PIN/rate-limit, result-verification exposure, payment-review RLS, public-admission abuse, and local Receipt Storage isolation. Payment-page validation #1804 passed. Live `tenant-acceptance` was skipped.
- Corrected all eight malformed DO-block delimiters to `do $$ ... end $$;` in PR branch commit `80acf05342dafe888c96e2eca0fb15071bc2880f`. Exact-head CI must rerun and pass the tenant-integrity SQL before the expanded lesson authorization fixture is accepted.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live tenant acceptance remains unverified.


### Stage A lesson authorization fixture — corrected dollar-quote replacement — 2026-10-30

- Follow-up inspection of SchoolPro CI #2081 showed the earlier commit `80acf05342dafe888c96e2eca0fb15071bc2880f` had not changed the eight malformed delimiters: the replacement operation interpreted the dollar characters and wrote the original `do $ ... end $;` text back unchanged. CI therefore failed at line 3 before any migration or test assertion ran. This was confirmed directly in the job log.
- Replaced the delimiters using literal callback replacements. PR branch commit `4299ddd02079817e675f0ad84d26d7eace071348` now changes all eight occurrences to paired `$$` delimiters. The source was re-counted: zero malformed `do $ begin` occurrences remain and twelve valid `do $$ begin` blocks are present.
- Exact-head validation is pending for commit `4299ddd02079817e675f0ad84d26d7eace071348`. SchoolPro CI #2081 failed only in `tenant-integrity-db-integration` at SQL setup; the other six executable jobs passed, live `tenant-acceptance` was skipped, and payment validation #1806 passed.
- No production database changes, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged.


### Stage A lesson authorization fixture — helper delimiter follow-up — 2026-10-30

- Exact-head SchoolPro CI #2083 on PR commit `4299ddd02079817e675f0ad84d26d7eace071348` passed the application validation job and six other executable jobs, but `tenant-integrity-db-integration` still failed during disposable fixture setup. The initial correction had fixed the `private.is_admin()` SQL body; PostgreSQL then reached the next two production-predicate helper definitions and found untagged dollar delimiters in `private.schoolpro_lesson_leader()` and `private.schoolpro_lesson_author_scope()`. No lesson authorization assertions ran in that attempt. Payment validation #1808 passed; live `tenant-acceptance` was skipped.
- The same defect was reproduced in exact-head SchoolPro CI #2085 on commit `211eaffc7a54dc10009498b4dc74d8a4c4971743`: `private.is_admin()` compiled, but the two lesson helper functions failed at SQL line 374. This confirms the remaining issue is limited to disposable test-fixture quoting, not the production database or migration.
- Corrected both helper definitions to use the paired `$lesson_fixture$ ... $lesson_fixture$` delimiter in PR branch commit `171d94768a0c0c9e731d608d40eaa179ebcea1d7`. Exact-head SchoolPro CI #2086 and payment validation #1811 are queued/running; do not accept the expanded lesson authorization coverage until the tenant-integrity job and full exact-head checks complete successfully.
- The #2085 application validation, result-PIN/rate-limit integration, result-verification exposure integration, payment-review RLS integration, and public-admission abuse integration passed; local Receipt Storage isolation was still running at last poll. Payment validation #1810 passed. Live `tenant-acceptance` was skipped.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains unverified.


### Stage A lesson authorization fixture — paired helper delimiters — 2026-10-30

- Exact-head SchoolPro CI #2086 on PR commit `171d94768a0c0c9e731d608d40eaa179ebcea1d7` confirmed the `private.is_admin()` helper compiled, but the tenant-integrity integration still failed while defining `private.schoolpro_lesson_leader()`: the opening delimiter had been changed to `$lesson_fixture$` while its closing delimiter remained the untagged `$`. The failure occurred before the lesson authorization assertions. Payment validation #1811 passed; live tenant acceptance was skipped.
- Corrected both closing delimiters to match `$lesson_fixture$` in PR branch commit `0697415d39a3e3e58c74bf553f7479b35b6a7896`. This completes the paired delimiter fix for both lesson-leader and lesson-author-scope SQL helper definitions. Exact-head SchoolPro CI #2088 and payment validation #1813 are now running; the test expansion remains unaccepted until the tenant-integrity job passes.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains unverified.


### Stage A lesson authorization fixture — leadership reviewer identity correction — 2026-10-30

- Exact-head SchoolPro CI #2088 on PR commit `0697415d39a3e3e58c74bf553f7479b35b6a7896` passed application validation/build and all other executable integration jobs except `tenant-integrity-db-integration`; payment validation #1813 passed and live `tenant-acceptance` was skipped.
- The tenant-integrity job now compiled the repaired disposable SQL functions and progressed into the lesson workflow assertions. It then rejected the approval update with the expected production rule, `Wait for school review before editing this lesson`, because the fixture attempted to approve a submitted lesson as the subject teacher. The production leader predicate correctly does not treat a subject teacher as school leadership; the earlier assertion that the teacher has subject-author scope is separate and remains valid.
- Corrected the workflow fixture to perform the approval as the fixture's school administrator and to assert that administrator's reviewer identity, rather than using the assigned subject teacher. PR branch commit: `87dd511ca6fa3d04b1e2e4f8d514fdd2f59bbd00`. Exact-head SchoolPro CI #2090 and payment validation #1815 are queued/running; do not accept the fixture until the tenant-integrity job passes.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains unverified.


### Stage A lesson authorization fixture — preserve shared admin predicate — 2026-10-30

- Exact-head SchoolPro CI #2090 on PR commit `87dd511ca6fa3d04b1e2e4f8d514fdd2f59bbd00` passed the application validation and all executable integration jobs except `tenant-integrity-db-integration`; payment validation #1815 passed and live `tenant-acceptance` was skipped.
- The tenant-integrity job progressed beyond lesson approval after the fixture switched the approval actor to the school administrator. It then failed while compiling the later shared workflow-function fixture: a second disposable `CREATE OR REPLACE private.is_admin(public.user_role[])` stub used an unnamed input argument, conflicting with the earlier production-predicate fixture's named `required_roles` argument. This duplicate stub would also have replaced the active-profile predicate with a constant false result, so it must not remain.
- Removed the conflicting later stub and retained the earlier isolated active-profile `private.is_admin(required_roles)` predicate for both lesson leadership tests and the shared workflow function. The remaining inert `private.has_school_access` helper stub is retained only for the shared workflow function's non-calendar branches, which are not exercised by this calendar-only fixture. PR branch commit: `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2`. Exact-head workflow runs have not yet appeared in the commit-run lookup; validation is pending.
- No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains unverified.


### Stage A lesson authorization fixture — exact-head CI accepted — 2026-10-30

- Exact PR #106 head `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2` completed successfully: [SchoolPro CI #2092](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41052841614) concluded **success**. All seven executable jobs passed, including `tenant-integrity-db-integration`, `validate` (typecheck, application checks and build), result-PIN/rate-limit integration, result-verification exposure, payment-review RLS integration, public-admission abuse integration, and local Receipt Storage isolation. The conditional live `tenant-acceptance` job was **skipped**.
- [Payment-page validation #1817](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/41052841543) also concluded **success**.
- The lesson authorization fixture upgrade is now accepted for this exact PR head: disposable tests execute the production-predicate logic for form-teacher and assigned-subject-teacher scope, deny unassigned/inactive teachers, and distinguish school leaders/owners from ordinary teachers/inactive profiles. The calendar lesson approval workflow now uses a school-administrator reviewer fixture. The shared `private.is_admin()` predicate is no longer overwritten by the duplicate constant-false stub.
- This is disposable/local CI evidence, not live tenant acceptance or production-schema equivalence. Live two-tenant `tenant-acceptance` remains skipped/unverified. No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged.
- Next bounded Stage A task: inspect the exact live `private.has_product_access(text,text)` definition and decide whether the global/no-school edit fallback can be safely and meaningfully exercised in the disposable activation-guard fixture. Do not change production or expand scope without a concrete predicate/test requirement.


### Stage A activation-guard global-access fallback — live predicate inspected — 2026-10-30

- Read-only inspection retrieved the exact live `private.has_product_access(target_product text, required_permission text DEFAULT 'view')` definition from production Supabase. It returns true only when the caller's `auth.uid()` resolves to an active `public.profiles` row and either that profile has platform role `super_admin`, or a matching `public.admin_product_access` row grants the requested product permission. For `required_permission='edit'`, the predicate checks `can_edit`; the other branches check `can_approve` for `approve` and `can_view` otherwise. The function is SECURITY DEFINER, owned by `postgres`, and pins an empty search_path.
- Production `public.admin_product_access` has a unique `(user_id, product)` key and the relevant boolean fields `can_view`, `can_edit`, and `can_approve`; its `user_id` references `profiles(id)`. The live function has no school-specific predicate: this is a platform-level product-access fallback.
- The disposable operational-activation fixture currently replaces this helper with `select false`, so its current CI coverage intentionally does not exercise the live platform-admin / product-grant path. The trigger's no-school branch also requires a fixture row for which the exact `schoolpro_record_school(table,row)` helper resolves NULL; the existing activation test table has a non-null direct `school_id`, so merely adding profile/grant fixtures would not reach that branch.
- Next bounded improvement: inspect the live trigger attachment set and `private.schoolpro_record_school(text,jsonb)` mappings to identify an actual trigger-attached record shape that legitimately resolves to NULL. Only then extend the disposable fixture to model the exact profile/product-grant predicate and assert denied-without-grant, allowed-with-`can_edit`, and non-edit permission denial. Do not manufacture an artificial production behavior or change the live database.
- This was read-only production inspection. No production DDL/DML, migration, ledger edit, workspace creation, merge, or deployment occurred. PR #106 remains draft/open/unmerged; live two-tenant acceptance remains skipped/unverified.


### Stage A activation-guard fallback reachability decision — 2026-10-30

- Follow-up to the live `private.has_product_access(text,text)` review: the proposed extra fallback test is deferred. The fallback is reached only when both old/new record-to-school resolutions are NULL. The existing activation-guard fixture represents a direct school-owned operational row with non-null `school_id`; manufacturing a NULL-school record solely to exercise a platform-admin fallback would not validate that real write path.
- The production helper definition and its platform-level `super_admin` / `admin_product_access.can_edit` behavior were inspected read-only. A fresh trigger-attachment catalog query was blocked by the connector safety layer, so this note does **not** claim that every live trigger attachment or nullable record shape has been exhaustively enumerated. Revisit only if a verified trigger-attached, legitimate record shape can reach the NULL-resolution branch.
- No additional test or production change is warranted from the evidence currently available. Keep the passing activation-guard tests for inactive-school denial, active-school acceptance and trusted service-role background writes.
- Current PR #106 head remains `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2`; exact-head SchoolPro CI #2092 and payment validation #1817 passed, while live `tenant-acceptance` was skipped. PR remains draft/open/unmerged. No production migration, DDL/DML, ledger edit, deployment or merge occurred.



### Stage A closure checkpoint — 2026-10-30

- Rechecked PR #106 at exact head `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2`. SchoolPro CI #2092 passed all seven executable jobs and payment-page validation #1817 passed. The conditional live `tenant-acceptance` job was skipped; these CI results do not establish current live two-school acceptance.
- Reviewed the latest operational tenant-integrity migration patch. The previously identified member-permission reassignment gap is now addressed: `private.validate_schoolpro_member_permission_tenant()` rejects changes to `school_id` on UPDATE before validating the school/member pair. The disposable integration suite includes the migration; exact-head tenant-integrity CI passed. This is still a reduced-schema test, not a production migration rehearsal.
- The live two-school acceptance prerequisite is currently unavailable: the last recorded manual run on 2026-10-29 could not resolve an active School A workspace/membership because there are no active school workspaces. Foreign-school read probes passed before that prerequisite failure. Do not rerun against the same empty setup, create workspaces/fixtures, or weaken RLS.
- The six operational tenant indexes, operational relational-integrity migration, forward-only FORCE RLS migration, payment/receipt changes, report-media policy optimization, and result-PIN cooldown remain branch proposals, not deployed production changes. Production ledger/source drift remains material; do not replay historical migrations or manually edit the ledger.
- **Stage A status: implementation and disposable CI gates pass; production closure is not authorized or evidenced.** PR #106 remains draft/open/unmerged. No production DDL/DML, migration, ledger edit, workspace creation, receipt upload, deployment, or merge was performed.
- To close the production release gate, the owner must first provide/authorize a valid existing two-school live acceptance setup (or explicitly accept the absence of current live acceptance as a documented release risk), and separately approve a bounded production rollout plan for the reviewed forward-only changes. Until then, keep A as “code/test-ready; production rollout pending” and do not start Stage B.
- Next work is bounded: (1) confirm live acceptance using valid existing active school accounts only; (2) reconcile each proposed migration's effect against the live catalog/ledger without replaying history; (3) obtain explicit approval for the exact production changes; (4) apply only the approved changes, verify tenant isolation and feature workflows, then merge/deploy and perform post-merge checks. Defer non-release enhancements rather than reopening scope.



### Prior successful two-workspace isolation evidence retained — 2026-10-30

- The user's earlier successful two-workspace tenant-isolation acceptance is accepted as existing Stage A evidence. Do not repeat it merely because the current production workspace inventory is now empty.
- The 2026-10-29 manual run that could not resolve an active School A workspace is a later environment/prerequisite failure. It does not invalidate the earlier successful two-workspace evidence and is not a reason to create workspaces, seed production data, or rerun the same test.
- Stage A acceptance evidence must distinguish: (a) prior successful two-workspace isolation result; (b) later live run blocked before completing because no active workspace was available; and (c) current disposable CI results. Do not collapse these into “live isolation unverified”.
- Remove repeat live tenant acceptance from the remaining mandatory Stage A checklist. Retain the earlier result as the tenant-isolation acceptance evidence. Remaining Stage A work is limited to bounded review of the proposed production changes, migration/source-ledger reconciliation, exact-head CI confirmation, and post-approval rollout/verification. No production changes are authorized by this note.



### Stage A bounded production-catalog recheck — 2026-10-30

- Used the earlier successful two-workspace acceptance as the tenant-isolation evidence; no repeat acceptance run was performed.
- Read-only Supabase catalog recheck confirms all eight operational tables (`schoolpro_library_books`, `schoolpro_transport_routes`, `schoolpro_hostel_rooms`, `schoolpro_inventory_assets`, `schoolpro_calendar_events`, `schoolpro_lesson_notes`, `schoolpro_result_approvals`, `schoolpro_promotions`) currently have RLS enabled and FORCE RLS disabled.
- The six proposed tenant-leading indexes are absent. The production database does not currently contain `private.schoolpro_validate_operational_tenant()` or `private.validate_schoolpro_member_permission_tenant()`. The corresponding Stage A migration versions `20261016160000`, `20261017170000`, and `20261017180000` are not recorded in the live migration ledger. This matches the existing source/ledger reconciliation record: these are unapplied proposals, not missing history to backfill.
- The migration proposals preserve existing feature policies, add relational tenant immutability checks, enable/force RLS on the eight operational tables, and add six tenant-leading indexes. Their disposable PostgreSQL integration tests pass on current PR head. This is a proposed forward-only rollout, not production validation.
- No production DDL/DML or migration was executed. The next decision is not another tenant-isolation test: it is whether to authorize the exact reviewed forward-only operational tenant-integrity, FORCE-RLS and index changes for a controlled production rollout. Payment/receipt and result-PIN changes remain separately gated by their own runtime/source review; do not bundle unrelated changes into this operational migration.


### Stage A production rollout and PR #106 merge — 2026-10-30

- Owner explicitly authorized the three operational migrations, SchoolPro fee-payment receipt/review changes, receipt Storage changes, family report-media Storage optimization, and PR #106 merge.
- PR #106 was marked ready and squash-merged into `main`. GitHub confirmed `merged=true`; merge commit: `c570843ec6bcd983b12771076d4aafcb5029b4fe`. The merged head was `2c1d5c45005a810e2f706f58dff0d77d7dfc4fd2`. Exact-head SchoolPro CI #2092 and payment-page validation #1817 both completed successfully. The member-permission guard in the merged migration rejects tenant reassignment before checking the member/school relationship.
- Applied eight forward-only production migrations to Supabase project `lnqsroyiybutkfngbyge`, using the exact SQL from merged `main`:
  1. `20261017180000_schoolpro_operational_tenant_indexes`
  2. `20261017170000_schoolpro_forward_operational_tenant_isolation`
  3. `20261016160000_schoolpro_repair_operational_tenant_integrity`
  4. `20261016180000_schoolpro_payment_receipt_storage_limits`
  5. `20261015203000_schoolpro_payment_receipt_tenant_guard`
  6. `20261016143000_schoolpro_payment_review_write_controls`
  7. `20261017150000_schoolpro_payment_receipt_storage_policies`
  8. `20261016110500_schoolpro_optimize_family_report_media_storage_policy`
- Supabase migration API returned success for all eight. The migration ledger records them under generated application timestamps `20261030141959` through `20261030142053`, retaining each original migration name; do not manually insert or rewrite ledger rows.
- Read-only post-apply catalog verification confirmed all eight operational tables have RLS enabled and FORCE RLS enabled; all six tenant-leading indexes exist; both operational tenant guard functions and the family report-media helper exist; operational immutable-tenant and relational guard triggers are enabled; and the receipt bucket remains private with a 5 MiB limit and MIME allowlist JPEG/PNG/WebP/PDF.
- No production rows, school workspaces, payment receipts, or receipt objects were created. The earlier successful two-workspace isolation evidence remains accepted; no repeat tenant acceptance run was performed.
- The separate migration `20261016170000_schoolpro_disable_online_payment_gateway` was **not** applied. It disables the legacy online/card-payment finalizer and is a distinct payment-channel/product behavior change, not required to secure the receipt-based workflow. Confirm separately if that disablement is intended.
- PR merge and database migrations do not deploy the frontend/API. No Render deployment was performed. SchoolPro production frontend remains hosted on Render. Post-deployment verification is still required after an explicitly approved Render release.
- Stage A operational, receipt-payment, and Storage database changes are applied and catalog-verified; PR #106 is merged. Do not claim end-to-end production UI acceptance until the merged code is deployed to Render and the parent receipt submission/finance review and Storage paths are verified with valid authorized accounts.


### Stage A remaining security proposals applied and deployed — 2026-10-30

- Owner explicitly authorized disabling the legacy online/card-payment gateway and applying the remaining Stage A result-PIN, public-admission, document-serial and public-result-verification changes, including deployment.
- Applied five additional production migrations from merged PR #106:
  1. `20261016170000_schoolpro_disable_online_payment_gateway` — legacy `finalize_schoolpro_payment` now fails closed and EXECUTE is revoked from PUBLIC/anon/authenticated/service_role.
  2. `20261016122000_schoolpro_result_pin_attempt_rate_limit` — private hashed attempt ledger, admission-keyed cooldown, serialized attempts, and trusted service-role-only result PIN RPC.
  3. `20261017133000_schoolpro_public_admission_rpc_abuse_controls` — validated and bounded admission inputs, per-school normalized guardian contact throttles, serialized contact submissions, and service-role-only admission RPC.
  4. `20261017103000_schoolpro_document_serial_global_uniqueness` — global normalized document serial uniqueness; verified index `schoolpro_document_issues_normalized_serial_global_uq` exists.
  5. `20261017120000_schoolpro_result_verification_minimal_snapshot` — public verification output is reduced to aggregate summary fields, including legacy snapshot sanitization.
- Supabase migration API returned success for all five. The production ledger records generated application timestamps `20261030142902`, `20261030142910`, `20261030142918`, `20261030143048`, and `20261030143059` respectively, with the original migration names. Do not rewrite these ledger records.
- Read-only privilege verification confirms `finalize_schoolpro_payment` is not executable by anon, authenticated or service_role; `check_schoolpro_result_pin` and `submit_schoolpro_application` are executable only by service_role among those roles; the private result-PIN attempt table exists; and the normalized global document serial unique index exists.
- Deployed Supabase Edge Function `schoolpro-public-admission` version 1 ACTIVE, `verify_jwt=false`, with Turnstile verification in the function itself. Deployed `schoolpro-result-pin-check` version 1 ACTIVE, `verify_jwt=false`, also requiring Turnstile and calling the service-role-only RPC. For packaging, the result-PIN function's shared Turnstile import was made local (`./turnstile.mjs`) in the deployed bundle; the helper contents are the same merged source helper.
- Render static site `ihlink-schoolpro` (service `srv-db0k11m0tbcc7386fmq0`) has auto-deploy enabled on `main`. Latest Render deploy is **LIVE** for commit `736f7cc8116728efe8b4472b7ab99e7d4f7ea2b7`, which is the post-merge main commit containing PR #106 plus the handover update. The PR merge commit is `c570843ec6bcd983b12771076d4aafcb5029b4fe`.
- Important runtime configuration gate: the Edge Functions require Supabase secrets `TURNSTILE_SECRET_KEY`, `TURNSTILE_ALLOWED_HOSTNAMES`, `SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS`, and (for result checks) `SCHOOLPRO_RESULT_CHECK_ALLOWED_ORIGINS` or the admission-origin fallback, plus platform-provided `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`. The secrets' presence/values and real Turnstile challenge success were not inspectable through the available deployment result. Both functions deliberately fail closed with HTTP 503 if the Turnstile secret or hostname allowlist is absent. Verify these settings in Supabase Edge Function secrets before considering the public flows operational.
- No live admissions, result-PIN checks, fee-payment submissions, document issues, student rows, or receipt objects were created as smoke-test data. Do not claim end-to-end browser acceptance for these flows yet. Perform controlled functional checks with valid test credentials and Turnstile only after confirming secrets/origin allowlists; never weaken the fail-closed behavior.
- Stage A merged, all thirteen PR #106 migrations applied, both new public security gateways deployed, and the Render site is LIVE on post-merge main. Remaining verification is runtime configuration (Turnstile secrets/origins), controlled UI/API workflow smoke tests, and post-deploy observation. The earlier successful two-workspace isolation evidence remains accepted; no repeat live tenant acceptance was run.


## 2026-10-30 Stage A runtime checkpoint and Super Admin dashboard boundary

- Render production static site `ihlink-schoolpro` deployment `dep-dbib3fom7kps73cd7gf0` is LIVE. The public frontend variable `VITE_TURNSTILE_SITE_KEY` was added without replacing existing environment variables; Render completed the rebuild successfully for commit `b7738acd2f31b958811c1fe962a26fced7a30087`.
- Supabase function inventory confirms `schoolpro-public-admission` and `schoolpro-result-pin-check` are ACTIVE at version 3 with `verify_jwt=false`. This inventory does not reveal Edge Function secret values or prove that `TURNSTILE_SECRET_KEY` and the hostname/origin allowlists are configured. Do not claim successful Turnstile Siteverify until that runtime configuration and a valid challenge are verified.
- User confirmed there is currently no usable SchoolPro workspace for controlled admission/result-checker form tests. Defer those functional tests; do not create a school, seed data, or manufacture credentials to unblock them. Existing CI gateway tests and prior CORS/missing-token probes remain the available evidence.
- The Super Admin dashboard complaint is addressed in draft PR #110 (`fix/super-admin-dashboard-boundary-20261030`). The change removes the school selector and ownership-transfer form from the SchoolPro dashboard, stops platform Super Admin from selecting/reading school operational records or bypassing school role/subscription gates there, and leaves a platform-oversight view with a workspace count. The platform Super Admin role and the existing protected `schoolpro-transfer-ownership` Edge Function remain intact; no ownership transfer or database change was performed.
- PR #110 CI at exact head `f29785260b4a84eb13779c1c79127fa3b7f48b44`: Payment-page validation #1828 passed; SchoolPro CI #2103 was still running at this checkpoint, with `tenant-acceptance` skipped as expected. Do not merge or deploy until SchoolPro CI completes successfully.
- Stage A remains code/migration-complete and deployed. Outstanding runtime acceptance is limited to confirming the Turnstile secret/hostname/origin configuration and the controlled public admission/result-PIN functional flows when a valid workspace is available. Do not repeat the earlier two-workspace tenant acceptance test or reopen the already completed Stage A migrations.


## 2026-10-30 follow-up — Super Admin dashboard scope and support contrast

- Clarified the required Super Admin boundary: the SchoolPro dashboard may retain the **Super Admin — administer school** selector and the existing school-administration workflow. The **Transfer school ownership** form/action must not appear on the SchoolPro dashboard; ownership transfer remains a Control Panel-only operation.
- PR #110 now restores the existing Super Admin school selection/context and administration flow while keeping the dashboard ownership-transfer form removed. This does not revoke the platform Super Admin's existing backend capabilities.
- Updated the SchoolPro support knowledge-base controls to force readable foreground/background contrast in dark-theme contexts (search input, topic filters, guide accordions, and guide text).
- Latest corrections are committed on `fix/super-admin-dashboard-boundary-20261030`; they require a fresh GitHub Actions validation before merge. The previous green run predates these final corrections.
- Stage B gaps remain implementation work: attendance write authorization must be limited to Form Masters/explicitly assigned leaders; section assignment needs a structured, enforceable relation; student middle name and guardian contact display need end-to-end support; academic sessions must include 2001–2002 through 2026–2027; Discipline Master and Game Master need role/schema/default-permission support. No production DDL or data changes have been applied for these Stage B items.


## Stage A formal acceptance and Stage B commencement — 2026-10-30

- The owner explicitly confirmed acceptance of the Turnstile secret configuration and Stage A acceptance. The earlier successful two-workspace tenant-isolation acceptance is retained as the tenant-isolation evidence; no replacement workspace or repeat live tenant test is required.
- PR #110 was squash-merged into `main` as `e48613e75442f53ebd2b5bf327b3494e19d222d3`. Render deployment `dep-dbibh4vb9u1s73dvksd0` for that exact commit is confirmed **LIVE**. The deployed changes retain Super Admin school administration, keep ownership transfer out of the SchoolPro dashboard (Control Panel only), and correct Get in Touch help-topic contrast.
- **Stage A is formally accepted and closed by owner confirmation**, including Turnstile configuration and acceptance. Do not reopen Stage A or repeat completed acceptance checks absent a new regression.
- Stage B work begins on branch `stage-b/academic-sessions-student-rosters-20261030`, based on merged `main`. Execution order: B1 academic session coverage and session semantics; B2 student population and student/guardian data; B3 session-specific class rosters and progression; then connected B4 staff/class/subject assignment, B5 attendance/section authorization, and B6 Discipline Master/Game Master roles.
- B1 initial implementation replaces the rolling 31-year selector (which omitted 2001–2010) with a canonical range from 2001/2002 through the current calendar year's next session, retaining any currently selected custom session. A focused regression test verifies 2026 includes 2001/2002 through 2026/2027 and rolls forward in 2027. This is code-only; no production database change is involved.
- Existing `schoolpro_enrollment_history`, session-aware roster helper, class Form Master field, and subject assignment tables must be preserved and extended rather than rebuilt. No production DDL/DML or production migration has been applied for Stage B.


### Stage B2 initial student identity slice — 2026-10-30

- Added nullable `schoolpro_students.middle_name` in proposed migration `20261030160000_schoolpro_student_middle_name.sql`, with a 100-character trimmed-length constraint. The migration is committed to the Stage B branch only; it has **not** been applied to production.
- Student enrolment now captures middle name and includes it in the student-list query/display. Class, attendance, parent-management and parent-dashboard reads were extended to fetch middle name; parent management also requests the linked guardian profile phone for contact display. Parent relationship remains sourced from `schoolpro_guardian_links.relationship`.
- Existing student-level guardian name and phone fields remain intact; no guardian records or linked profiles are rewritten. This first slice does not yet add phone capture to parent invitations; that requires a separate review of the invitation Edge Function/profile update path.
- Added `scripts/test-academic-sessions.mjs` to SchoolPro CI. The PR is still draft; typecheck/build and all existing security integrations must pass before this slice can be considered ready. The migration must receive explicit production approval before application.


### Stage B3 initial class-roster slice — 2026-10-30

- `SchoolProClasses` now exposes the selected academic session and scopes its student roster/counts through the existing `schoolSessionStudents()` helper and `schoolpro_enrollment_history` data. For schools with no enrollment-history rows yet, the helper's existing legacy fallback remains intact; when history exists, historical session/class membership is used instead of current student class placement.
- Historical roster loading does not filter out students merely because their current student record is inactive/transferred; the selected session's history determines their historical membership. The current/legacy fallback still uses active students.
- This extends the existing history implementation; no new roster table or production data change is introduced.


### Stage B1 — academic session lifecycle and calendar history implementation slice — 2026-10-30

- Added proposed migration `20261030190000_schoolpro_academic_session_lifecycle_and_calendar_history.sql` on the Stage B branch. It introduces school-scoped academic-session date ranges with upcoming/active/completed/archived lifecycle states, append-only before/after calendar history for session and term changes, and permission-checked save/archive RPCs. Session rows and term calendar rows cannot be deleted through these trigger paths; completed sessions are archived instead.
- Session date ranges cannot overlap another non-archived session. Configured term dates must remain inside their academic session; session dates cannot be narrowed to exclude already configured terms. Existing term non-overlap validation remains in force. Calendar-history rows reject update/delete mutations at the database layer.
- Added `SchoolAcademicSessionManager` to the existing academic calendar view. It exposes session start/end dates, notes, date-derived status, completed-session archival and the latest 30 calendar-history entries. Existing term editor remains in place.
- Replaced the separate rolling 31-year list in `SchoolSessionBar` with the canonical `AcademicPeriodSelect`. Its explanatory text explicitly states that changing the working session does not promote students or move enrolments.
- Added deterministic date-state tests and static migration guards to `scripts/test-academic-sessions.mjs`.
- The migration is proposed only and has **not** been applied to Supabase production. No production data, workspace, or deployment changes were made. Calendar UI lifecycle actions require this migration to be applied in a separately approved migration window before use.
- Remaining B1 work: run exact-head CI; verify SQL migration against a disposable PostgreSQL schema with the relevant Supabase role/function/table prerequisites; review session/term activity stamping and the existing calendar tick for boundary conditions; verify calendar history visibility for all intended staff roles; and ensure every session-scoped module consumes the same selected session without changing enrolments. B1 is **in progress**, not complete.


- Exact-head CI initially exposed a stale Super Admin context regression test: the Stage A dashboard now intentionally supports explicit school selection, while the test still expected Super Admin to ignore every selection. The underlying context selection expression also allowed the generic remembered member-workspace key to take precedence. Corrected it so Super Admin can resolve only an explicit URL school selection or the dedicated Super Admin dashboard selection, never a generic remembered workspace; updated the regression assertions accordingly. This preserves the Stage A dashboard workflow and its tenant boundary.

- Separated the academic-calendar editor's session choice from the global working-session selector. Choosing a session to edit calendar dates no longer changes the session used by the rest of the dashboard; the shared selector supports this explicitly and a regression assertion covers it.

### Stage B1 follow-up — SQL delimiter correction and calendar editor isolation — 2026-10-30

- Exact source review found two malformed single-dollar PL/pgSQL function delimiters in the proposed calendar lifecycle migration. Corrected both function bodies to paired `$$` delimiters before any production application. Added a CI assertion that the migration's function-body delimiters are balanced and that malformed single-dollar delimiters are absent.
- Both the academic-session manager and the existing term-date editor now use the shared session selector with `updateWorkingSession={false}`. Selecting a session to edit calendar metadata or term dates therefore cannot change the dashboard's global working session. Added a regression assertion for the term editor as well.
- This is a source-level correction only. The migration remains unapplied; no production database, data, workspace or deployment was changed.
- Remaining B1 validation: exact-head CI after these corrections; disposable PostgreSQL execution against the actual Supabase schema/roles; permission review for the calendar RPCs; verify the dynamic current-period RPC and activity stamping continue to use the intended dates/session. B1 remains in progress.


### Stage B1 follow-up — align session lifecycle permissions with existing calendar controls — 2026-11-02

- Reviewed the existing academic calendar and operational session migrations. The current calendar save RPC requires both the calendar module and explicit school access for proprietor, administrator, registrar, head teacher and vice principal. The first draft of the new session save/archive RPCs instead required the promotions module and did not repeat that explicit role boundary.
- Corrected both new RPCs to use the established calendar module plus the same explicit school-role access list. Session date management no longer depends on the separate promotions module. Added static regression assertions for both RPC guards and the preserved role list.
- Confirmed the existing academic clock is driven by `schoolpro_result_term_settings` date ranges, while operational activity stamping resolves session by activity date and preserves the original session on later updates. The new session-date table does not yet drive that clock. This remains a required integration decision: avoid silently making session metadata override term-based activity history until the intended source-of-truth behavior is implemented and tested.
- The existing term settings schema includes `school_id`, `session`, `term`, `term_start_date`, `term_end_date`, `updated_by` and `updated_at`; the proposed history/validation triggers reference those known fields. Existing calendar management role policy is the authority for session RPC access.
- Changes are source-only on the Stage B branch. No production migration, data change, workspace creation or deployment. PostgreSQL execution against a disposable schema and exact-head CI remain outstanding.

### Stage B1 follow-up — session-aware activity stamping — 2026-11-02

- Updated the proposed session lifecycle migration to replace the activity-period insert trigger with a two-part date resolver: configured `schoolpro_academic_sessions` date ranges determine the session, while the existing `schoolpro_result_term_settings` date ranges continue to determine the term.
- When a school has at least one explicit session record, an activity without an explicit session receives a session only when its activity date falls inside a non-archived configured session. A date inside the session but outside all configured terms receives the session and a null term. A date outside all configured sessions receives no inferred session.
- For a school that has not yet configured any explicit session rows, the legacy term-date inference remains in place as a transition path. Explicitly supplied session values are validated and retained; the trigger does not replace them with the current working-session selection. Existing update-time session immutability remains governed by the previously installed preserve-session trigger.
- The academic clock remains term-date driven; this change does not make the working-session selector or the new session table silently alter current-term notifications or enrollment history.
- Added source-level regression assertions for date-range resolution, archived-session exclusion, legacy fallback, term independence and explicit-session preservation. This is not PostgreSQL execution evidence. The migration remains proposed and unapplied; no production data, workspace, deployment or database state was changed.
- Remaining B1 work: validate this trigger and migration against PostgreSQL/Supabase prerequisites when a disposable environment is available; inspect the existing transcript and progression flows against the requested full-stage history and configurable promotion criteria; run exact-head CI. / `$;`). It now uses paired `$` delimiters. Added/retained a source regression assertion against malformed delimiters.
- No database migration was applied, no production data was modified, and no deployment or PR merge occurred. These are source-level changes/review findings only; PostgreSQL execution is still outstanding.
- Next implementation: add a school-scoped, versioned promotion policy with a default 45% overall threshold and configurable subject-specific minimum averages; make the year-end progression RPC evaluate the configured policy against published subject results; then add explicit stage-completion evidence and stage-grouped transcript output. Preserve the existing immutable issued-snapshot and enrollment-history behavior. Validate exact-head CI and migration SQL before requesting any merge or deployment.


### Stage B3 progression-policy schema review — 2026-11-02

- Re-read the year-end bulk-action RPC and its progression application/history triggers. The current decision still uses a hardcoded 30% overall threshold and treats normalized SS3/SSS3 class labels as automatic graduation. The applied progression RPC itself updates the current student class/status, while the after-update history trigger records the source-session class and creates the next-session enrolment for promoted/repeated students. Preserve this lifecycle and its permission/advisory-lock boundaries when changing policy evaluation.
- Confirmed the result model stores one row per student, subject, term and session in `schoolpro_results`; `total_score` is the calculated 0–100 subject total. Configurable assessment schemes define component weights and calculate each subject result total. This supports subject-specific policy evaluation using published subject rows across First, Second and Third Term; do not derive subject thresholds from assignment component labels.
- The existing year-end guard requires all three terms to be published and rejects any non-published result row in the session. Its current overall average is the unweighted average of each term's mean subject score. A replacement policy must explicitly define and test the corresponding overall and per-subject aggregation, rather than silently changing weighting.
- Implementation is not yet committed: the source review has not yet located the canonical `create_schoolpro_progression` definition and complete `schoolpro_promotions` constraints/decision contract needed to safely replace the bulk RPC. Next inspect those definitions and any existing promotion settings before adding versioned school policy storage and integrating evaluation. No migration was applied; no production data, workspace, or deployment was changed.


### Stage B3 progression RPC dependency check — 2026-11-02

- Continued tracing the canonical progression write path before changing year-end policy. The applied-progression RPC definition is available and confirms pending-only application, school/module/role authorization, student row locking, source-class consistency checks, and promotion/repetition versus graduation status updates. The after-update history trigger writes the completed source-session enrolment and, for promoted/repeated decisions, the next-session enrolment.
- The canonical `public.create_schoolpro_progression` definition and the authoritative `schoolpro_promotions` table definition/constraints were not located in the accessible migration files or repository code-search results. Do not replace or wrap the bulk progression RPC until those contracts are found; guessing decision constraints or function side effects could corrupt progression semantics.
- Subject result schema is confirmed from the configurable-assessment migration: `schoolpro_results` carries subject identity and term/session score rows; `total_score` is a 0–100 calculated subject total. The current bulk RPC's overall score is an unweighted mean of three term means. A policy migration must preserve that existing aggregate or explicitly version the calculation.
- No promotion-policy migration or code change was made in this pass. No SQL was executed, no production migration/data/deployment occurred, and no test workspace was created. Next source the canonical progression function and table contract from the schema baseline / generated database types / repository history, then implement versioned 45% default and configurable subject thresholds with regression coverage.


### Stage B3 progression RPC source search — 2026-11-02

- Re-fetched PR #111 and confirmed the current head remains `8eae3a03ed565ee8a46ad20286b844b2cc0d69a8`; PR #111 remains open and draft.
- Inspected the complete tracked Git tree at that head. It contains no generated Supabase database types, schema snapshot, baseline schema dump or tracked migration defining `public.create_schoolpro_progression` / the `public.schoolpro_promotions` table contract. The tracked migration history contains the bulk RPC call site and the applied-progression/history trigger definitions, but not the canonical creation function/table definition.
- Re-ran repository code searches for `create_schoolpro_progression`, `schoolpro_promotions` and `schoolpro_progression`; all returned no indexed source matches. Reviewed likely foundational migrations and the completion migration; none supplies the missing definitions.
- This confirms the blocker is not merely a missed generated-types file: the canonical write function and authoritative table constraints are absent from the tracked PR-head source currently available. The bulk RPC must not be replaced based on guessed return semantics or constraints.
- Next safe input is the authoritative schema/function definition from the existing Supabase project or the original migration/source artifact that created `schoolpro_promotions` and `create_schoolpro_progression`. Once obtained, continue the 45% default and configurable subject-threshold policy design against that exact contract. No database was queried or changed in this pass; no migration, deployment, merge, test workspace or operational data change occurred.


### Stage B3 authoritative Supabase progression contract recovered — 2026-11-02

- Used read-only catalog queries against the existing Supabase project `lnqsroyiybutkfngbyge` to recover the live definitions missing from tracked source. No write statements were issued.
- Recovered `public.create_schoolpro_progression(uuid,text,text,uuid,text)`: returns UUID; SECURITY DEFINER with empty search_path; requires authenticated caller, promotions module and the existing proprietor/administrator/head_teacher/vice_principal/registrar or Super Admin access boundary; locks/reads the student; requires an assigned source class; validates decision in promoted/repeated/graduated; promoted requires a different same-school destination class; repeated forces destination to current class; graduated clears destination; inserts a pending `schoolpro_promotions` row and records actor/reason.
- Recovered live `public.schoolpro_promotions` columns: id, school_id, student_id, from_class, to_class, session, status, created_at, from_class_id, to_class_id, decision, decided_by, applied_by, applied_at, reason. Constraints include decision enum check (promoted/repeated/graduated), FKs to school/student/classes/auth users, primary key id; unique index `(student_id, session)` means only one progression row per student/session. Existing triggers include activation write guard, immutable/validated tenant checks, and applied-progression archive trigger.
- Recovered the canonical RPC ACL: postgres owner; SECURITY DEFINER; execute granted to authenticated and service_role. Existing public and private bulk action RPCs retain authenticated execution grants. Preserve these exact privilege boundaries when replacing the bulk routine.
- Confirmed `schoolpro_subjects(id,school_id,name,code,class_name,...)` is the subject identity table and `schoolpro_results.subject_id` references it. Subject policy rules must reference subject IDs and validate same-school ownership; no universal subject-name requirements should be embedded.
- This resolves the previously recorded source-definition blocker. Next implementation can safely add school-scoped versioned promotion policy storage (45% default overall threshold plus optional subject-ID minimums), replace only the private bulk evaluation function while retaining the public wrapper, and preserve the create/apply RPC, pending approval, unique student/session, locks, permissions, published-term guard, and enrollment-history triggers. Graduation must still be gated by explicit stage-completion evidence rather than SS3 class label.
- Read-only catalog access only: no live schema changes, row changes, migrations, production deployment, test workspaces or PR merge occurred.


### Stage B1 exact-head validation — 2026-11-02

- Corrected the two malformed PL/pgSQL function-body delimiters in `20261030190000_schoolpro_academic_session_lifecycle_and_calendar_history.sql` from single-dollar to paired `$$` delimiters. The fix was committed as `5e29a425c4e20f8e4fa6431f631ed361a31cd188` and pushed to `stage-b/academic-sessions-student-rosters-20261030`.
- Local checks passed before push: `npm.cmd run typecheck` and `node scripts/test-academic-sessions.mjs`; `git diff --check` passed and the diff contained only the two delimiter corrections.
- Exact-head GitHub Actions completed successfully for commit `5e29a42`: SchoolPro CI run #2156 passed, including `npm ci`, TypeScript typecheck, the academic-session regression test, the remaining validation scripts, mobile/customer layout checks and `npm run build`. Disposable PostgreSQL integrations passed for tenant integrity, payment-review RLS, result-PIN rate limits, result-verification exposure and public-admission abuse controls. Receipt Storage isolation passed. Validate payment pages run #1881 also passed.
- The conditional `tenant-acceptance` job was skipped because there are no active school workspaces. No test workspace was created. This is not a tenant-acceptance pass and does not replace the previously accepted two-workspace evidence.
- This exact-head CI run validates the migration in the tenant-integrity integration job's disposable PostgreSQL setup, but it is not a complete execution/review of the academic-session migration against a faithful Supabase schema with its calendar tables, roles, grants and RPC prerequisites. That remains an explicit B1 gate. The selected-session integration across all session-scoped modules and calendar-history visibility also remain open.
- PR #111 remains open and draft. No merge, production deployment, Supabase migration application, production data change or workspace creation occurred. The academic-session migration remains proposed and unapplied.
- Next: complete a focused disposable PostgreSQL/Supabase-schema execution and permission review for the academic-session migration, then verify session/term activity stamping and shared selected-session consumption. Do not run `supabase db push` or apply the migration to production without separate explicit approval. Continue B2/B3 implementation only within the established Stage B scope; retain the recovered progression RPC contract and the 45% configurable promotion-policy requirements.


### Stage B1 follow-up — preserve direct-delete protection and school cleanup cascades — 2026-11-02

- Corrected the proposed academic-calendar history ownership model: `schoolpro_academic_calendar_history.school_id` now references `schoolpro_schools(id) ON DELETE CASCADE`, so calendar history cannot remain orphaned after a school workspace is deleted.
- Updated the calendar-history immutability trigger to continue rejecting direct UPDATE/DELETE operations while allowing DELETE caused by the owning school row no longer existing during its FK cascade.
- Updated the session and term history triggers to reject direct session/term deletion while allowing the parent school's FK cascade to remove those rows. Cascade deletes return `OLD` and do not attempt to append new history during teardown.
- Added source regression assertions for the history FK, all three cascade-aware delete paths, continued direct-delete rejection, and immutable history. These are static source guards; they do not substitute for execution against PostgreSQL.
- This is a proposed PR-source correction only. The migration remains unapplied to the existing Supabase project. No production data, school workspace, deployment, or PR merge was changed.
- Required validation before merge: execute the migration and focused delete/immutability scenarios against a disposable PostgreSQL schema with the real Supabase table/role/function prerequisites; verify direct session delete fails, direct term delete fails, direct history mutation fails, ordinary session/term changes append history, and deleting a school removes sessions, terms and history without an exception or orphan rows.


### Stage B1 follow-up — correct cascade-guard regression assertion — 2026-11-02

- The first exact-head CI run after the school-cascade correction failed only in `scripts/test-academic-sessions.mjs`: the new static assertion expected three identical `if not exists` text patterns, but the history immutability guard has an additional `tg_op = 'DELETE'` condition before its parent-existence check. The SQL itself contained all three parent-existence guards.
- Corrected the assertion to count the three exact `where id = old.school_id` predicates, independent of the surrounding condition layout.
- The same CI run passed TypeScript typecheck and the other database integration jobs (tenant integrity, receipt storage isolation, payment-review RLS, result-PIN rate limits, result-verification exposure and public-admission abuse controls). The tenant-acceptance job was skipped because no active school workspaces exist.
- Payment-page validation run #1885 passed. SchoolPro CI run #2160 failed at the over-specific static assertion described above; the corrected test is committed as `08425f474d7a4eff77067fe16462979c339f8e35` and awaits a fresh exact-head CI result.
- No PostgreSQL migration execution was performed. The production Supabase project remains unchanged; no test workspace, Supabase branch, deployment or PR merge was created.

### Stage B1 focused PostgreSQL integration added — 2026-11-02

- SchoolPro CI run #2162 completed successfully on the prior branch head. The main validation and receipt-storage isolation jobs passed; the tenant-acceptance job was skipped because no active school workspaces exist. Payment-page validation run #1887 also passed.
- Added `scripts/test-academic-sessions-postgres.integration.sql`, a disposable PostgreSQL fixture that supplies only the Supabase schema/role/function prerequisites needed by the proposed B1 migration, applies that exact migration with psql, and executes focused behavior checks:
  - session save plus term/session insert and update append four history entries;
  - direct session delete and direct term delete are rejected;
  - direct calendar-history UPDATE and DELETE are rejected;
  - deleting the owning school cascades through session, term and history rows without leaving orphans.
- Added an isolated PostgreSQL 16 CI job, `academic-calendar-migration-integration`, to execute the fixture against a fresh ephemeral database. This is deliberately separate from production Supabase and does not create a Supabase branch or school workspace.
- The integration fixture is a targeted disposable schema with minimal prerequisite stubs, not a full clone of every live Supabase policy/function. It proves migration execution and the listed trigger/FK behaviors; it does not yet prove live authenticated RLS/role semantics or every activity-stamping trigger attachment.
- New integration job has been added to the Stage B PR branch; its exact-head CI result is pending. Do not treat the migration as PostgreSQL-validated until that job passes. If it fails, fix only the failing fixture/migration behavior and record the result here.
- No production migration, production data change, deployment, PR merge or test workspace creation occurred. PR #111 remains open/draft; the academic-session migration remains unapplied.

### Stage B1 disposable PostgreSQL validation — first pass and expanded RLS/stamping coverage — 2026-11-02

- Exact-head SchoolPro CI run #2167 passed on commit `b2907d0`; payment-page validation run #1892 passed. All executed SchoolPro CI jobs passed, including the new academic-calendar migration integration, tenant integrity, receipt Storage isolation, payment-review RLS, result-PIN, result-verification, public-admission, main validation/mobile layout and production build. Tenant acceptance was skipped because there are no active school workspaces.
- The first PostgreSQL integration pass applied the proposed B1 migration and executed its session/term history, direct-mutation rejection and owning-school cascade assertions successfully.
- Expanded the disposable fixture to exercise the migration's actual SELECT policies under the `authenticated` role: teachers can read their own school's session rows but cannot read calendar history; exam officers can read their own school's calendar history; foreign-school session rows remain invisible.
- Expanded the fixture to attach the existing attendance stamping trigger to a disposable attendance table and verify date-range session/term inference plus preservation of an explicitly supplied historical session.
- The expanded fixture is now in commit `4c7331f`; exact-head SchoolPro CI run #2176 is queued. These additional RLS and activity-stamping checks are pending until that run passes. The earlier #2167 pass does not cover these later additions.
- The fixture uses a minimal disposable schema and a deterministic role/access helper to exercise policy role boundaries; it is not a full Supabase Auth/member-table clone. It validates the policy expressions and authenticated database-role visibility, not the complete live JWT/member-resolution implementation.
- No production Supabase migration, production data change, workspace creation, deployment or PR merge occurred. PR #111 remains open/draft and the B1 migration remains unapplied.


### Stage B1 expanded fixture teardown correction — 2026-11-02

- Expanded PostgreSQL fixture CI runs #2176 and #2177 failed only in the disposable academic-calendar integration job. The failure was in test ordering: the fixture asserted that the school cascade had removed session/term/history rows inside its setup DO block, before the parent school was actually deleted. The later parent-delete statements were already present after the RLS checks.
- Corrected the fixture so the cascade assertions run only after the parent-school DELETE statements at the end of the script. No migration SQL or production behavior was changed.
- Correction committed as `51601b0c675b020d05ed2ec23c5d8465402e3d15`. Exact-head CI must pass before the expanded RLS/stamping coverage is considered validated.
- All other jobs in #2176 and #2177 passed, including main validation, tenant integrity, receipt Storage isolation, payment-review RLS, result-PIN, result-verification and public-admission. Tenant acceptance remained skipped because no active school workspaces exist. Payment-page validation #1902 passed.
- No production migration, production data change, workspace creation, deployment or PR merge occurred. PR #111 remains open/draft; the B1 migration remains unapplied.


### Stage B1 PostgreSQL fixture dollar-quote correction — 2026-11-02

- The corrected cascade assertion order exposed the next fixture issue in CI #2178/#2179: the GitHub file-update operation had normalized the closing delimiter of the newly edited PL/pgSQL block from `$$;` to `$;`, causing PostgreSQL's `unterminated dollar-quoted string` error before the behavior assertions ran.
- Replaced the edited block's delimiter with the distinct `$fixture$` tag to avoid delimiter normalization. No migration SQL or production behavior changed.
- Fixture correction committed as `1af382297ffcd105ed8326890caf6376ad737377`. Await exact-head PostgreSQL CI before marking expanded coverage validated.
- CI #2179: all jobs passed except the disposable academic-calendar migration job; payment-page validation #1904 passed. The prior cascade-order correction is therefore not yet validated independently because parsing failed first.
- No production migration, data change, workspace creation, deployment or PR merge occurred. PR #111 remains open/draft; migration remains unapplied.


## Stage B PR #111 — latest B1 disposable PostgreSQL CI diagnosis (2026-11-02)

- PR #111 remains **open and draft**; no merge or production deployment/migration has occurred.
- Latest diagnostic commit before this update: `79a945e7041f6a62575de3e04720e3db1f92c219`.
- SchoolPro CI run #2182 (`41444237925`) completed with the disposable academic-calendar PostgreSQL job failing; all other executed jobs passed. Tenant acceptance remained skipped because there are no active workspaces.
- Payment-page validation #1907 (`41444237869`) completed successfully.
- The #2182 job log shows `private.has_school_access('...school A...', ARRAY['teacher']) = true` under the configured authenticated test context, but the subsequent authenticated SELECT from `schoolpro_academic_sessions` still returned zero rows. Therefore the helper/context hypothesis is not the cause; do not weaken the migration's teacher read policy without further evidence.
- Diagnostic-only fixture update committed as `4b8e9497919ae103dd832b44630f381897249447`. It emits the authenticated table SELECT privilege, owner-visible fixture row count, actual `pg_policies.qual`, and effective role/table privilege before the failing assertion. Use the next CI log to distinguish a missing table grant, policy mismatch, or fixture-row issue.
- Next action: inspect the academic-calendar job for the diagnostic output; make only a root-cause correction, then rerun the focused job. Keep PR #111 draft/open/unmerged.
- Continue to avoid production migration/deployment/data changes, workspace creation, test operational data, or new Supabase branches.


### Follow-up diagnostic result — 2026-11-02

- CI for diagnostic commit `4b8e9497919ae103dd832b44630f381897249447` completed. Payment-page validation passed; the disposable academic-calendar job still failed at the teacher session visibility assertion.
- The job output now proves: authenticated has table SELECT privilege; one School A session exists when viewed by the fixture owner; the actual SELECT policy includes `teacher`; and `private.has_school_access(... teacher ...)` returns true under authenticated.
- The mismatch is therefore in RLS policy execution/targeting rather than missing fixture data, table SELECT grant, or the helper's direct result.
- Added a further diagnostic commit `d92b5cea9cd1e5643b8f6433e5a52f2f971d6d57` to print table RLS/FORCE flags, policy roles/command/permissiveness, direct helper and admin results, and the actual authenticated-visible session rows before the assertion.
- Next: inspect the new exact-head CI output. Do not modify production migration policy until this diagnostic identifies the cause. PR #111 remains draft and unmerged; no production database changes or workspace creation.


### Stage B1 authenticated-RLS diagnostic query correction — 2026-11-02

- Inspected SchoolPro CI run #41448655107 on commit `d92b5cea9cd1e5643b8f6433e5a52f2f971d6d57`. All executed jobs passed except `academic-calendar-migration-integration`; the tenant-acceptance job was skipped because no active workspaces exist. The separate payment-page validation run #41448655103 passed.
- The PostgreSQL log identifies the immediate failure precisely: the diagnostic SELECT referenced alias `c` (`c.relrowsecurity`, `c.relforcerowsecurity`) without a `FROM pg_class c` clause. The migration had applied successfully; the failure occurred in the fixture's diagnostic SQL before the authenticated session-visibility assertion could run.
- Corrected the diagnostic query to select the target relation from `pg_class c`, constrained by `c.oid = 'public.schoolpro_academic_sessions'::regclass`. No migration policy or production SQL was changed.
- Fixture correction committed as `706e9433b8ebdee15286729d9e6d74c8550cdf49`. Exact-head PostgreSQL CI is now the next gate; the teacher session visibility and subsequent RLS assertions remain unvalidated until that run completes.
- PR #111 remains open/draft/unmerged. No production Supabase migration, production data change, deployment, workspace creation, or new Supabase branch occurred.


### Stage B1 authenticated teacher RLS assertion refinement — 2026-11-02

- Exact-head SchoolPro CI #2188 on commit `e3f8451f8fe3618c322b4e132caefff94cded90e` failed only in `academic-calendar-migration-integration`; payment-page validation #1913 passed. Other executed jobs, including main typecheck/regression tests and tenant-integrity/payment-review/result-PIN/result-verification/public-admission integrations, passed; receipt Storage and main build/layout work were still in progress at inspection. Tenant acceptance was skipped because no active workspaces exist.
- The corrected diagnostic query now runs. Its output confirms the session table has RLS enabled (not FORCE), the SELECT policy targets `authenticated` permissively, the policy includes `teacher`, the access helper returns true, SELECT privilege is present, and a direct row SELECT returns the School A session.
- The subsequent scalar `count(*) = 1` assertion nevertheless returned false in this fixture. Replaced only that teacher visibility assertion with an `EXISTS (SELECT 1 ...)` row-presence assertion, which directly tests the intended authorization behavior rather than relying on an aggregate in this RLS fixture. No migration policy or production SQL was changed.
- Test correction committed as `6f293e4d2ce684bd28ac3a9ee6bfc8d0b77ad35b`. Exact-head CI must confirm teacher visibility, history denial for teachers, history visibility for exam officers, and foreign-school isolation.
- PR #111 remains open/draft/unmerged. No production migration, deployment, production data change, workspace creation, or new Supabase branch occurred.


### Stage B1 RLS fixture assertion root cause — 2026-11-02

- Exact-head SchoolPro CI #2190 on handover commit `a29a85442733ce73ea695e5a02fadb493f8717ea` failed in the disposable academic-calendar job. The diagnostic output showed the teacher's direct SELECT returned the expected School A session row, while the next assertion still failed.
- Root cause: the fixture used `CASE WHEN ... THEN 1 ELSE 1/0 END` as a failure sentinel. PostgreSQL can constant-fold the literal division-by-zero expression during planning, so this is not a safe assertion pattern. The prior RLS diagnosis was therefore misleading; it does not establish a teacher-policy defect.
- Replaced the division-based checks with explicit PL/pgSQL `DO` assertions using `IF ... THEN RAISE EXCEPTION`. Assertions now directly check: teacher sees a school session; teacher cannot see calendar history; exam officer sees exactly four history rows; foreign-school session remains invisible.
- Test correction committed as `e68fc9431b9759ba13265806dc52dc719f7adb1d`. Exact-head CI is the next gate. No migration policy or production SQL changed.
- PR #111 remains open/draft/unmerged. No production migration, deployment, production data change, workspace creation, or new Supabase branch occurred.

### Stage B1 remaining cascade assertion correction — 2026-11-02

- Exact-head SchoolPro CI #2192 on commit `dccbe1a85b652f8323ccb6756f15fbb18ac82448` reached the academic-calendar disposable PostgreSQL integration job. The four explicit PL/pgSQL RLS assertions were passed before the fixture failed at line 233.
- The failure log identifies three remaining `CASE ... ELSE 1/0` sentinels in the parent-school deletion cascade checks (academic sessions, result term settings, and calendar history). These were separate from the four RLS assertions and reproduce the same unsafe constant-folding pattern.
- Replaced all three cascade sentinels with a single explicit PL/pgSQL assertion block that raises a targeted exception if any School A session, term-setting, or calendar-history row survives school deletion.
- Fixture correction committed as `ef401f50865591336e0d7cfabf07c8232e015311`. Fresh exact-head CI and payment-page validation are now required; no result is claimed until those runs finish.
- Payment-page validation #1917 on the preceding head `dccbe1a85b652f8323ccb6756f15fbb18ac82448` passed. SchoolPro CI #2192 was still running at inspection, with the academic-calendar job failed on the three remaining sentinels.
- PR #111 remains open/draft/unmerged. No production migration, deployment, production data change, workspace creation, or new Supabase branch occurred.


### Stage B1 historical roster fallback and identity display correction — 2026-11-02

- Continued the B1 code reconciliation after the academic-calendar disposable PostgreSQL integration passed. The shared `schoolSessionStudents` resolver had a legacy fallback that returned every current student when a school had no enrollment-history rows. That could place inactive or graduated current records into a selected-session roster. The broadsheet compatibility rule already limits this fallback to active students.
- Extracted deterministic roster projection into `src/lib/schoolSessionRoster.ts`. The resolver now: (1) uses only active students for legacy schools with no enrollment history; (2) returns an empty roster when a school has history but none for the selected session; and (3) uses the selected session's recorded class, arm, section and status while preserving the current class ID separately.
- Updated the Results and Attendance student queries to include the status field required for the legacy fallback. Updated the class-roster query to include middle name and display the full student name where available.
- Added `scripts/test-school-session-rosters.mjs` and wired it into the package test script and SchoolPro CI. Coverage includes active-only legacy fallback, empty historical sessions, historical class/arm projection, current-class preservation and graduated status.
- Commits: `c29351b` (pure roster resolver), `dbb40c9` (tests), `7d31392` (resolver integration), `a961bf1` (results query), `8bdd309` (attendance query), `3eb72f5` (class roster identity), `9d9c6f8` (package script), `7413c80` (CI wiring).
- Exact-head SchoolPro CI #2199 and payment validation #1924 both passed on commit `d4326c20363de2b2f01938aac30076c9f6079958`. The typecheck, production build, academic-calendar disposable PostgreSQL integration, and `test-school-session-rosters.mjs` all passed. Tenant acceptance was skipped because no active workspaces exist.
- No production migration, data change, workspace creation, deployment, merge, or Supabase branch creation occurred. PR #111 remains draft/open/unmerged.


### Stage B1 Form Master attendance authorization correction — 2026-11-02

- After the historical roster correction passed exact-head CI #2199 and payment validation #1924 on `d4326c20363de2b2f01938aac30076c9f6079958`, the next B1 role-scope gap was addressed: the legacy attendance policies granted every `teacher` and `class_teacher` school-wide attendance writes by default.
- Added `supabase/migrations/20261102090000_schoolpro_form_master_attendance_scope.sql`. Default teacher and class-teacher permission arrays no longer include attendance. A teacher/class teacher receives the attendance module when assigned through the existing `schoolpro_classes.form_teacher_id` field; RLS permits attendance insert/update only for the assigned Form Master and school proprietor/administrator. The existing restrictive student/session/class scope remains in force.
- Added `scripts/test-schoolpro-form-master-attendance-scope.mjs` and wired it into package scripts and SchoolPro CI. This is a source-level authorization regression test; disposable database execution of the new migration is still required before acceptance.
- Commits: migration `e41678b`, test `3229b91`, package script `68078d3`, CI wiring `a72496f`.
- Exact-head CI and payment validation are pending for the attendance-scope change. Do not apply this migration to production or merge PR #111 until CI and the appropriate disposable PostgreSQL policy test pass.
- PR #111 remains open/draft/unmerged. No production migration, deployment, production data change, workspace creation, or new Supabase branch occurred.


### Stage B1 Form Master attendance disposable PostgreSQL coverage added — 2026-11-02

- Exact-head SchoolPro CI #2203 and payment validation #1928 passed on commit 5e19b1b82214a6040e43d94c6e9f42b1164d73e9. The Form Master source-level regression test, typecheck, build, academic-calendar PostgreSQL integration and all other executed CI jobs passed. Tenant acceptance was skipped because no active school workspaces exist.
- While building the disposable attendance fixture, reviewed the policy semantics and identified an important precedence case: an explicit attendance=false member permission must override Form Master assignment not only in the module permission list but also in the database write policy. Updated all three Form Master write predicates (INSERT check, UPDATE using, UPDATE check) to honor that explicit denial.
- Added scripts/test-schoolpro-form-master-attendance.integration.sql. It creates an isolated minimal PostgreSQL schema, applies the exact Form Master migration, checks the default teacher/class-teacher permission mapping, explicit allow/deny behavior, assigned Form Master class scoping, and administrator write access under the authenticated database role.
- Added a separate form-master-attendance-integration CI job using PostgreSQL 16. It is disposable CI infrastructure only; it does not connect to Supabase or create school workspaces.
- Commits after the prior handover update: 0ab9360 (initial disposable fixture), 71731d7 (explicit-denial enforcement in migration), 520b8ae (fixture role setup correction), df69c6f (PostgreSQL CI job), d9bcb6e (static regression assertion for all three denial guards).
- The new PostgreSQL integration has not yet completed on the exact current head. Do not mark the attendance migration accepted until the new form-master-attendance-integration job passes. If it fails, diagnose the disposable fixture or migration and correct only the demonstrated issue.
- PR #111 remains open/draft/unmerged. No production Supabase migration, production data change, deployment, workspace creation, new Supabase branch, or live tenant acceptance occurred.


### Stage B1 Form Master PostgreSQL fixture first-run correction — 2026-11-02

- The first exact-head CI attempt for the new disposable Form Master integration applied the migration successfully, then failed one fixture assertion: the supposed unassigned School B teacher was actually assigned as that school's Form Master in the fixture data. This was a fixture setup error, not a migration or RLS failure.
- Corrected the School B class fixture to have no Form Master assignment. Added a further authenticated RLS assertion that an explicit attendance module grant does not bypass the class-level Form Master write boundary.
- Fixture correction commits: `b6841a6` (remove unintended School B Form Master assignment) and `e9d4712` (assert explicit module grants remain class-scoped).
- A fresh exact-head SchoolPro CI run must pass the disposable PostgreSQL attendance job before this migration is accepted. Payment validation is also pending on the updated head.
- PR #111 remains open/draft/unmerged. No production Supabase migration, production data change, deployment, workspace creation, new Supabase branch, or live tenant acceptance occurred.


### Stage B1 Form Master attendance authorization — validated — 2026-11-02

- The corrected Form Master attendance implementation passed exact-head SchoolPro CI #2212 (run `41460413816`) and payment validation #1937 (run `41460413831`). CI head: `e3df03b83b83ac78f65b72ca1f465f0299f171d01`.
- The dedicated PostgreSQL 16 disposable integration job `Form Master attendance RLS (disposable PostgreSQL)` completed successfully. It applied `20261102090000_schoolpro_form_master_attendance_scope.sql` and exercised the resulting authenticated RLS policies. Assertions cover default teacher restrictions, assigned Form Master class writes, rejection of writes to another class, explicit attendance grants remaining class-scoped, explicit denials overriding Form Master assignment, and administrator write access.
- All other executed SchoolPro CI jobs passed, including validation/typecheck/build, academic-calendar PostgreSQL integration, tenant-integrity, result verification exposure, result PIN, public admission, receipt storage isolation and payment-review RLS integration. `tenant-acceptance` remained skipped because there are no active workspaces; no workspace was created.
- Form Master attendance authorization is therefore validated in disposable PostgreSQL and may be treated as complete for Stage B1 implementation review. This does not authorize production application of the migration; it remains part of the unmerged migration proposal.
- PR #111 remains open/draft/unmerged. No production Supabase migration, production data change, deployment, workspace creation, new Supabase branch, or live tenant acceptance occurred.


### Stage B1 student identity display — middle name carried into results — 2026-11-02

- Following the passing Form Master PostgreSQL integration, continued the student identity/display requirement. `SchoolProStudents.tsx` already selects, stores on enrollment, searches and displays `middle_name`; the results page was still omitting it from its student query and rendered names.
- Updated `src/pages/schoolpro/SchoolProResults.tsx` to select `middle_name`, include it in the local Student type, and display full first/middle/last names in the class-subject register, saved-result rows and correction detail where the matching name expression was present. No student records or database schema were changed.
- Commit: `2afc0f82f15e906d5b649672fbb79f94e9b3ddeb`.
- Exact-head SchoolPro CI #2214 and payment validation #1939 were triggered on this commit. At handover update time both were still running; do not call the UI change validated until both conclude successfully.
- Parent/guardian relationship remains a separate open requirement: the current student form stores guardian name and phone but no relationship field. No relationship column or migration is proposed until the actual schema and any existing parent/guardian model are traced; do not invent or backfill relationship values.
- PR #111 remains open/draft/unmerged. No production Supabase migration, production data change, deployment, workspace creation, new Supabase branch, or live tenant acceptance occurred.


### Stage B1 progression repeat threshold — implementation pending validation — 2026-11-03

- Exact-head CI #2214 (run `41462935337`) and payment validation #1939 (run `41462935329`) passed on the prior middle-name commit. Typecheck/build, historical roster test, Form Master PostgreSQL integration, academic-calendar PostgreSQL integration, receipt Storage isolation, payment-review RLS and the other executed security jobs all passed. Tenant acceptance was skipped because there are no active workspaces.
- Traced the existing year-end progression implementation and found a policy mismatch: `private.schoolpro_bulk_academic_action` classified students below 30% annual average as repeat, while the agreed default is below 45%.
- Added `supabase/migrations/20261103090000_schoolpro_progression_repeat_threshold.sql`, replacing the bulk action function with the same existing three-published-term gate, reviewed decision creation, explicit apply step, permissions and transcript behavior, but using the agreed strict `v_average < 45` repeat threshold. The original historical migration is left unchanged.
- Updated `SchoolBulkAcademicActions.tsx` explanatory copy to 45%, added `scripts/test-schoolpro-progression-threshold.mjs`, registered the test in package scripts and SchoolPro CI. The test asserts the new threshold and preservation of the existing review/apply and published-term guards.
- Implementation commits: migration `be56945`, regression test `285d035`, UI copy `ca02ac4`, package script `d2b00d9`, CI wiring `6bc156f`, regression assertion correction `77593b2`.
- Exact-head CI and payment validation for the threshold change are pending. Do not treat the migration as accepted or apply it to production until the new exact-head CI and payment validation pass.
- The same trace confirmed that guardian relationships already exist in `schoolpro_guardian_links.relationship` (mother/father/guardian/sponsor) and are captured by the existing Parents & Guardians `SchoolAccountForm`. The student enrolment form's guardian name/phone are separate emergency/contact fields, not the parent-account relationship model. The handover's prior description of relationship as wholly missing is therefore too broad; no new relationship column is warranted from this evidence.
- The canonical `AcademicPeriodSelect` currently generates sessions from 2001/2002 through the current year plus next year (26 entries in 2026), includes a selected session if outside that range, and is shared by the session controls. Its test already checks the 2001/2002–2026/2027 range. No arbitrary shorter dropdown limit was found in the traced canonical selector.
- Subject-specific promotion requirements (for example English and Mathematics minimums configured by each school) remain unimplemented and must be designed as a separate school-configurable rule set; the 45% annual-average default does not substitute for those optional requirements.
- PR #111 remains open/draft/unmerged. No production migration, production data change, deployment, workspace creation, new Supabase branch, or live tenant acceptance occurred.


### Stage B1 progression threshold — validated — 2026-11-03

- The 45% repeat-threshold implementation passed exact-head SchoolPro CI run `41601671962` and payment validation run `41601672162` on handover commit `29ce21fc8cd3f738e22d4c599abb013c63ef3466`.
- Every executed SchoolPro CI job passed, including typecheck/build validation, Form Master attendance PostgreSQL integration, academic-calendar PostgreSQL integration, receipt Storage isolation, payment-review RLS, result-verification exposure, result-PIN, public-admission and tenant-integrity integrations. Tenant acceptance was skipped because there are no active workspaces.
- The replacement progression function uses the agreed strict below-45% annual-average repeat default while retaining the three-published-term gate and reviewed-then-apply progression flow. The migration remains a draft proposal and has not been applied to production.


### Stage B1 incremental assessment entry — implementation pending validation — 2026-11-03

- Traced `SchoolProResults.tsx`: the assessment scheme already supports multiple independently named components (assignments, tests, examination), but the entry form required every component in one save and converted blank components to zero. This did not meet the requirement for a section head to enter one assignment/test at a time.
- Updated `saveScore` to accept one or more entered components, reject an empty submission, validate entered values against the configured component maximums, and merge the entered values into the existing draft `assessment_scores` object. Previously saved components are retained; the database continues to calculate `total_score` from the full assessment score map.
- The existing assessment scheme is retained for an existing result; switching schemes mid-entry is blocked. Existing approved/published/locked result protections remain in force. After a successful component save, the form retains the selected student/subject and clears only the current input values so the next component can be entered.
- Added a user-facing explanation, `scripts/test-schoolpro-incremental-assessment-entry.mjs`, package script and SchoolPro CI step.
- Implementation commits: UI `e5785ed`, regression test `a472abc`, package script `6431cbb`, CI wiring `3dd6317`.
- Exact-head SchoolPro CI and payment validation for incremental entry are pending. Do not treat this change as validated until both finish successfully. No production schema or data change is involved.
- PR #111 remains open/draft/unmerged. No production migration, production data change, deployment, workspace creation, new Supabase branch, or live tenant acceptance occurred.


### Stage B1 configurable progression subject requirements — CI validated; migration pending — 2026-11-03

- Read-only inspection of the connected Supabase project `lnqsroyiybutkfngbyge` established the authoritative live definitions that were missing from the migration-only source search:
  - `public.schoolpro_promotions` has a unique `(student_id, session)` index and stores the reviewed decision, source/destination class IDs, reason, decision maker, status and apply metadata.
  - `public.create_schoolpro_progression(uuid,text,text,uuid,text)` creates a pending decision and preserves the existing promotion/repeat/graduation decision model.
  - `public.apply_schoolpro_promotion(uuid)` applies only pending decisions after permission, active-student and source-class checks.
  - `schoolpro_subjects` has school ownership, subject name and class name; `schoolpro_results` stores subject IDs, term/session and published `total_score`.
- Added draft migration `supabase/migrations/20261103100000_schoolpro_progression_subject_requirements.sql`. It introduces a school-scoped requirement table keyed by school and subject, validates 0–100 minimum scores, enforces subject/school ownership, uses forced RLS and promotion-manager policies, and stamps the authenticated editor.
- The replacement year-end review evaluates enabled requirements only for subjects belonging to the student's historical class. Each configured subject must have published results for all three terms; incomplete subject evidence is skipped for manual review rather than silently treated as zero. The annual subject average is compared with that rule's minimum. Failed subject minimums produce a repeat decision and are recorded in the progression reason. The existing overall below-45% repeat default, three-term publication gate, permission checks, pending review and explicit apply workflow remain.
- Added a configuration section to `SchoolBulkAcademicActions.tsx` so school progression managers can select a subject, set a 0–100 minimum, save the rule, and enable/disable existing rules. The component reads and writes only the new school-scoped requirements table.
- Added `scripts/test-schoolpro-progression-subject-requirements.mjs`, registered it in `package.json`, and wired it into `.github/workflows/ci.yml`. The regression test covers the migration contract, settings UI and disposable integration assertions.
- Added `scripts/test-schoolpro-progression-subject-requirements.integration.sql` and a dedicated PostgreSQL 16 CI job. The fixture covers a subject-rule pass, a subject-rule failure causing a repeat decision, incomplete three-term subject evidence being skipped for review, tenant mismatch rejection, minimum-score bounds, reason audit text and the explicit apply step. This test uses only disposable CI PostgreSQL; it does not create production or Supabase workspaces.
- Commits: migration `33a8ec8`, initial regression test `f607f45`, package script `4ec9fc2`, CI wiring `57a3f2b`, editor identity stamping `1d2d1dd`, settings UI `dbabcc1`, UI regression assertions `3abe0f2`, disposable integration fixture `5de66db`, integration CI job `88731e3`, integration contract assertions `b4ce490`, all-update audit stamping `ece08f2`, final UI/test assertions `c1e397f` and `835ddc4`, disposable fixture correction `52978d2`, SQL assertion-quote correction `8e9a140`.
- This remains a draft proposal only. The source-level regression test, disposable PostgreSQL 16 integration, and exact-head CI/payment validation passed on commit `8e9a14013c15ba5d4c1d31b9e4dc8cf5865fa05b`: SchoolPro CI run `41611466117` succeeded (including the subject-requirements integration job, typecheck/build, and existing security/integration jobs); payment validation run `41611465996` succeeded. Tenant acceptance was skipped because there are no active workspaces. No production migration was applied, no production data was written, and no workspace or test account was created. PR #111 remains draft/open/unmerged pending the next review/acceptance decision.
- Read-only live catalog inspection also confirmed the current production bulk function still contains the pre-proposal implementation; the 45% threshold and subject-requirement migrations remain unapplied. No production schema or function was modified.


### Stage B1 production graduation-certificate workflow — implementation pending validation — 2026-11-03

- Traced the existing Document & Certificate Studio and its authenticated `schoolpro-render-document` worker. The UI already supports certificate templates, individual/batch draft creation, PDF rendering, unique serial numbers, issue-event audit history, public verification and revocation. The generic `finalize_schoolpro_document_issue(uuid,text)` RPC exists in the connected live schema; it authorizes school managers/registrars/head teachers/vice principals and stamps `issued_by` with the authenticated actor. The earlier repo migration search did not include this live function definition, so its live contract was inspected read-only.
- The existing `schoolpro-testing-certificate-worker` and `schoolpro_finalize_testing_certificate` are intentionally synthetic-only (`IH-TST-*`). They are left untouched.
- Added draft migration `supabase/migrations/20261103110000_schoolpro_production_graduation_certificates.sql`. It adds a certificate-specific draft guard and hardens the generic finalization transition: certificates require a same-school graduated student, an active same-school certificate template, a matching applied `graduated` row in `schoolpro_promotions` for the selected session, and an authorized issuing staff member. The issued event records `auth.uid()`; existing global serial uniqueness, document verification and revocation event workflow are retained.
- Updated `SchoolProDocumentStudio.tsx` to select student status, restrict certificate recipients (including batch issuance) to graduated students, require the graduation session, and pass that session to the existing progression-summary renderer. Other document types retain their current recipient behavior.
- Added `scripts/test-schoolpro-production-graduation-certificates.mjs`, package script and SchoolPro CI step. This is a source-contract regression test; it is not a substitute for disposable PostgreSQL execution. A dedicated database integration fixture and exact-head CI/payment validation remain outstanding.
- Implementation commits: migration `4ebabf4`, trigger correction `3617a22`, regression test `f0812a5`, package script `d83514a`, CI wiring `d2ddfb3`, UI graduated-recipient/session guards `8babc1d` and `faf7b87`.
- The migration has not been applied to production. The connected Supabase inspection was read-only. No production data was changed, no workspace/test account was created, and no deployment occurred. PR #111 remains open/draft/unmerged.

- Added `scripts/test-schoolpro-production-graduation-certificates.integration.sql` and a dedicated PostgreSQL 16 CI job. The disposable fixture applies the exact draft migration and exercises graduated versus active recipients, applied versus pending graduation decisions, active/same-school template checks, missing session, unauthorized staff, invalid output path, issuer identity, issuance event audit, and generic non-certificate document compatibility. The Node regression test now asserts the integration fixture covers these contracts.
- Integration-fixture commit: `59e79b7`; CI job commit: `f4c1cb8`; fixture-coverage assertion commit: `8d495d0`. Exact-head SchoolPro CI and payment validation for `8d495d09196e1758f31f8ca97c452e397abdb5bf` are running; the database fixture has not yet passed CI. Do not mark the certificate workflow database-validated until the dedicated PostgreSQL job succeeds.


### Stage B1 production graduation-certificate workflow — disposable database and exact-head CI validated — 2026-11-03

- Corrected the Node source-contract assertions to match the SQL fixture's actual `position('...')` error-message checks; the earlier failures were assertion mismatches. The disposable PostgreSQL migration/lifecycle test itself passed.
- On exact head `787953e387d83447f83f35afa7043e5f0956398a`, SchoolPro CI run `41617478382` succeeded and payment validation run `41617478347` succeeded.
- The dedicated `Production graduation certificates (disposable PostgreSQL)` job passed, executing the draft migration and lifecycle assertions. The validation job also passed typecheck, build and the graduation-certificate source regression test. All other executed SchoolPro CI jobs passed; tenant acceptance was skipped because there are no active workspaces.
- The certificate workflow is validated in disposable PostgreSQL and exact-head CI. The migration remains a draft proposal and has not been applied to production. No production data/schema change, deployment, workspace creation, or test account creation occurred. PR #111 remains open/draft/unmerged.


### Stage B1 section-scoped academic leadership — implementation and exact-head CI validated — 2026-11-03

- Added draft migration `supabase/migrations/20261103120000_schoolpro_section_leadership_scope.sql`. Section keys reuse `schoolpro_classes.level`: nursery, primary, junior_secondary, senior_secondary and other.
- Added school-scoped assignments for head teachers and vice principals, managed through `schoolpro_set_section_leader`. The Staff & Access screen exposes per-section assignment checkboxes to school administrators.
- Database authorization scopes student/class reads, historical enrollment reads, result entry, and result approval/publication to explicit section assignments. Existing proprietor, administrator, exam-officer, subject-teacher, class-teacher, student and guardian paths are retained.
- Role changes away from head_teacher/vice_principal automatically clear stale section assignments. Direct table writes are not granted to authenticated users; assignments are changed through the validated RPC and audit log.
- Added source-contract and disposable PostgreSQL 16 integration tests at `scripts/test-schoolpro-section-leadership.mjs` and `scripts/test-schoolpro-section-leadership.integration.sql`; wired them into SchoolPro CI.
- Corrected the enrollment-reader helper to call `private.schoolpro_member_can_manage(s.id)` (not the nonexistent public-schema function). Fix commit: `60ab8c1e0c5ac4b981c2d3f0767b52e6ddc61c95`.
- Exact-head SchoolPro CI run `41624177698` succeeded, including `Section leadership authorization (disposable PostgreSQL)` job `125877216094`. Payment validation run `41624177667` also succeeded. All executed database integration jobs passed; tenant acceptance was skipped because there are no active workspaces.
- The migration remains unapplied to production. No production schema/data changes, deployments, workspaces or test accounts. PR #111 remains open/draft/unmerged.


### Stage B1 academic calendar — expanded authenticated RLS and attendance stamping validated — 2026-11-03

- Expanded `scripts/test-academic-sessions-postgres.integration.sql` to attach the activity-period trigger to the disposable attendance table and execute the migration's stamping function through actual attendance inserts.
- Added a historical `2024/2025` term fixture and asserted that an explicitly supplied historical session is preserved together with its matching `First Term`; date-based inference for the configured `2025/2026` session continues to stamp the matching session and term.
- Added a real foreign-school session/history row before authenticated role switching. The authenticated teacher is asserted to see only its own school's session and no calendar history; the exam officer is asserted to see all five own-school history events but no foreign-school session or history.
- Extended `scripts/test-academic-sessions.mjs` to assert that these integration contracts remain present.
- Exact code head `c7bd6d79402230229703126747af360b8de38c48`: SchoolPro CI run `41625879970` passed, including `Academic calendar migration (disposable PostgreSQL)` job `125882970885`. Its log ends with the explicit PASS for migration, calendar history, immutable guards, school cascades, authenticated RLS and activity session stamping. All other executed CI jobs also passed; tenant acceptance was skipped because there are no active workspaces.
- Payment validation run `41625879709` passed on the same exact head.
- This validates the calendar migration behavior in disposable PostgreSQL only. The migration remains unapplied to production; no production data/schema change, deployment, workspace or test account was created. PR #111 remains open/draft/unmerged.


### Stage B1 shared working-session consistency — exact-head validation complete — 2026-11-03

- Centralized the shared working session so its initial value comes from the school's configured current academic period when no saved selection exists. A previously selected historical session is retained and is not overwritten by calendar bootstrap.
- New student enrolments now use the shared working-session selection; the student form no longer makes a competing current-period RPC request.
- Fee structures, fee exceptions and result-access exceptions now use the shared session selector and no longer default to hard-coded `2026/2027`.
- These changes affect the selected view/default for new records only. They do not move existing students, rewrite historical enrolments, or modify historical academic records.
- Implementation commits: shared session bootstrap `61f9a4d`; enrolment session source `1644dd0`; fee/session defaults `d3020c9`; regression assertions `1321844`.
- Exact-head SchoolPro CI run `41628085694` (run #2299) passed on `1321844a4d8a84833eec279ceabca156bce3bb9b`. Payment validation run `41628085573` (run #2024) also passed. TypeScript/build, academic-session regression, academic-calendar PostgreSQL integration, Form Master attendance integration, section leadership, progression subject requirements, graduation-certificate integration, receipt Storage isolation, payment-review RLS, tenant-integrity, result-PIN, public-admission and result-verification jobs all passed. Tenant acceptance was skipped because no active workspaces exist.
- Completed the previously outstanding read-only schema-contract review against Supabase project `lnqsroyiybutkfngbyge`: `schoolpro_result_term_settings` contains the referenced `id`, `school_id`, `session`, `term`, `term_start_date`, `term_end_date`, `updated_by`, `updated_at` columns and the expected unique key `(school_id, session, term)`; its existing date-order constraint and non-overlapping-term trigger remain present. The existing `schoolpro_save_academic_calendar` RPC writes these fields and the existing `schoolpro_audit_logs` columns match the session-save audit insert. The proposed migration's additional term-within-session trigger is separate from the existing term-overlap validator.
- The new calendar-history trigger records before/after states for session and term changes; the history table is append-only for ordinary updates/deletes, with school-deletion cascades explicitly allowed. No production rows or schema were changed by this read-only review.
- PR #111 remains open, draft and unmerged. The academic-session lifecycle migration and all other Stage B migrations remain proposed only. No production migration was applied, no production data was changed, no deployment or workspace creation occurred, and no test workspace/account was created.
