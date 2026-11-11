## Stage C continuation — existing-student first-time onboarding (2026-11-09)

**Branch:** `feat/schoolpro-existing-student-onboarding`  
**Status:** Implementation in progress; no merge, production migration, production data write, or Render deployment.

Added a distinct `existing` admission type for students who were already attending a school before it first adopts SchoolPro. The Students & Enrolment screen now distinguishes New Student, Existing Student and Transfer In, explains the existing-student path, retains the school's admission number and selected current class, optionally accepts an existing house assignment, and labels existing students in the roster. If no house is selected, the existing balanced automatic house-allocation trigger remains the fallback. Existing students are still enrolled against the selected academic session so session-scoped enrollment history is created by the existing trigger.

A forward migration expands the `schoolpro_students.admission_type` check constraint to allow `existing` while preserving `new` and `transfer_in`. No student rows were created or changed. Bulk spreadsheet onboarding is not included in this increment and remains a follow-up enhancement. Validation and CI are pending.

---

## Stage C continuation — staff review-sheet unassessed ranking boundary (2026-11-09)

**PR:** [#133 — Stage C: harden assessment score import validation](https://github.com/Hassan-625/IHLink-SchoolPro/pull/133)  
**Branch:** `feat/schoolpro-stage-c-assessment-results-workflow`

Corrected a remaining consistency gap in `schoolpro_class_review_sheet`: the staff review sheet previously assigned a class position to every roster row, including learners with no recorded subject scores. The new follow-up migration preserves the complete class roster, ranks only learners with at least one recorded result, leaves `class_position` null for unassessed learners, and sorts those learners after ranked entries. Added a source-contract regression assertion to the existing ranking test, which is already part of SchoolPro CI. No production migration or data write has been applied.


## Stage C continuation — result import RPC PostgreSQL integration coverage (2026-11-09)

**PR:** [#133 — Stage C: harden assessment score import validation](https://github.com/Hassan-625/IHLink-SchoolPro/pull/133)  
**Branch:** `feat/schoolpro-stage-c-assessment-results-workflow`  

Added a disposable PostgreSQL integration fixture for the authoritative `import_schoolpro_results` RPC. It exercises all four combinations of canonical and short Junior/Senior Secondary class-level values, verifies valid imports persist, and verifies a genuinely mismatched scheme is rejected without leaving partial rows. Added a dedicated PostgreSQL 16 CI job; this does not connect to the configured production Supabase project. No production migration, data write, merge, or Render deployment.


## Stage C continuation — database import scheme-level alias enforcement (2026-11-09)

**PR:** [#133 — Stage C: harden assessment score import validation](https://github.com/Hassan-625/IHLink-SchoolPro/pull/133)  
**Branch:** `feat/schoolpro-stage-c-assessment-results-workflow`  

Extended the previous secondary-level alias correction to the authoritative database import RPC. The RPC now accepts both canonical and short Junior Secondary (`junior_secondary` / `jss`) and Senior Secondary (`senior_secondary` / `sss`) class-level values, matching the frontend preview. Added source-contract assertions so backend enforcement cannot regress independently. Proposed migration only; no production database changes, merge, or Render deployment.


## Stage C continuation — assessment scheme level alias correction (2026-11-09)

**PR:** [#133 — Stage C: harden assessment score import validation](https://github.com/Hassan-625/IHLink-SchoolPro/pull/133)  
**Branch:** `feat/schoolpro-stage-c-assessment-results-workflow`  

Corrected the score-import preview's class-level compatibility check so Junior Secondary and Senior Secondary schemes accept both canonical level values (`junior_secondary` / `senior_secondary`) and their short aliases (`jss` / `sss`). This aligns row-level import validation with the scheme selector's existing compatibility rules and prevents valid same-section imports from being incorrectly rejected. Added a source-contract regression assertion. Branch-only change; no production migration, data write, merge, or Render deployment.


# SchoolPro Master Migration and Production Cleanup Handover

## Stage C continuation — assessment workbook schema and class-level validation (2026-11-08)

**PR:** [#133 — Stage C: harden assessment score import validation](https://github.com/Hassan-625/IHLink-SchoolPro/pull/133)  
**Branch:** `feat/schoolpro-stage-c-assessment-results-workflow`  

Hardened the workbook preview before any import RPC call. It now rejects non-empty unsupported columns rather than silently ignoring misspelled or stale assessment headings, while allowing the configured component keys across the school's assessment schemes. It also checks each student's selected-session class level against the chosen assessment scheme and reports an actionable row-level preview error for incompatible Nursery/Primary/Junior Secondary/Senior Secondary schemes. The database import RPC remains the final enforcement boundary. Added source-contract assertions for both checks. This is branch-only work; no production database migration, merge, or Render deployment was performed.


## Stage C continuation — section leadership eligibility correction (2026-11-08)

**PR:** [#133 — Stage C: harden assessment score import validation](https://github.com/Hassan-625/IHLink-SchoolPro/pull/133)  
**Branch:** `feat/schoolpro-stage-c-assessment-results-workflow`  
**Status:** Proposed branch changes only. No production migration, production data write, merge, or Render deployment.

The Stage C section-leadership model follows four independent academic sections: Nursery, Primary, Junior Secondary and Senior Secondary. An active school staff member may be formally appointed to any one or more of these sections. The only excluded staff role is ordinary `teacher` (Subject Teacher); parent and student accounts are also ineligible because they are not staff. Class Teachers/Form Masters, Head Teachers, Vice Principals, Principals, Exam Officers, administrators, proprietors and other active staff roles may be appointed.

Principal remains the highest academic authority. If a Principal has an active appointment to a section, other appointees—including a Vice Principal—cannot exercise section-head approval authority in that section. This precedence is enforced in the database. Appointment authority is restricted to Proprietor/Administrator, IHLink Super Admin and members with the explicit `school_admin` responsibility.

Updated Staff & Access to show section appointment controls for every active eligible staff role, rather than only Head Teacher, Vice Principal and Principal. Ordinary Subject Teachers cannot be appointed. A Class Teacher appointment does not grant additional subject score-entry rights; those remain limited to active class/subject/session allocations. Added regression coverage for Class Teacher eligibility, ordinary Subject Teacher rejection, Principal precedence, school-admin authorization and UI role filtering.

This correction does not change subject-score write scope: a subject teacher remains restricted to their active class/subject/session allocations. Form Master class-wide visibility and submission do not grant permission to edit another teacher's marks.

---

**Last updated:** 2026-11-06  
**Repository:** `Hassan-625/IHLink-SchoolPro`  
**Production frontend:** Render — https://ihlink-schoolpro.onrender.com  
**Shared Supabase project:** `lnqsroyiybutkfngbyge` (IHLink Platform, West EU Ireland)  
**Database direction (confirmed 2026-10-28):** Continue on the existing Supabase PostgreSQL project; Render remains the production frontend host. MySQL and Aiven are no longer target platforms for SchoolPro.  
**Status:** Stage A accepted. Stage B database rollout complete: all 14 Stage B migrations are recorded in the existing Supabase project, covering sessions/calendar, student identity and progression, Form Master attendance scope, section leadership, houses, House Masters, competitions, staff judging, scoring, result approval/publication and house points. PR #111 and corrective PR #113 are merged. The historical cleanup of two earlier workspaces completed on 2026-10-28; a read-only production recheck on 2026-11-07 confirms two different active SchoolPro workspace rows created on 2026-11-04 and 2026-11-05. Their operational purpose and ownership must be confirmed before any lifecycle action. Render frontend deployment is not part of this database rollout and has not been verified here.

## Operating rules
- Preserve the live production architecture and shared IHLink/DataSub data.
- Do not repeat completed checks unless new evidence requires them. Continue from the last known state.
- The previously authorized cleanup of the two historical SchoolPro workspaces below was completed on 2026-10-28. A read-only production recheck on 2026-11-07 found two different active school rows created on 2026-11-04 and 2026-11-05. Do not assume these are test records or historical leftovers, and do not delete, archive, or otherwise mutate them without separate explicit authorization.
- Do not delete global `profiles` or Supabase Auth accounts. Preserve global/default templates, platform-wide audit/security history, financial evidence that must be retained, and all Storage objects.
- Keep SchoolPro migration work separate from DataSub.

## Historical production workspace cleanup — completed 2026-10-28

**Historical disposition:** The cleanup completed on 2026-10-28; both target workspaces and their scoped operational rows were removed. The workspace IDs and counts below are retained as audit history, not as pending work. This statement describes the state immediately after that historical cleanup, not the current production state. A separate read-only recheck on 2026-11-07 found two newer active workspaces, documented below.

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

### Stage B1 session propagation review — complete — 2026-11-03

- Completed the focused source review of the session-scoped workflows touched by Stage B: Results, Attendance, Classes, Students, Fees, Document & Certificate Studio, Parent Dashboard, Staff, class roster, bulk academic actions, the shared session bar, Academic Calendar and Academic Session Manager.
- Session pickers use `AcademicPeriodSelect`, which synchronizes session values with `useSchoolSession`; Results and Staff also consume the shared hook directly. The teacher-only Results session dropdown is intentionally constrained to that teacher's assigned session values, while the shared working session initializes it when the form loads.
- The remaining literal `2026/2027` in Document & Certificate Studio is sample-template content and placeholder guidance, not an operational session default. Fee forms, student enrolment and the other inspected workflows have no hard-coded session default.
- B1's calendar lifecycle migration passed its disposable PostgreSQL integration; exact-head CI/payment validation and the live term-settings/audit-log contract review are complete. B1 academic-session/session-selector scope is complete. B2 student identity/family semantics and B3 historical rosters/progression remain in progress.

### Stage B2 student identity and family records — implementation pending CI validation — 2026-11-03

- Read-only inspection of the connected Supabase schema confirmed the existing family model is sufficient; no new relationship table or duplicate relationship column is needed:
  - schoolpro_guardian_links stores school_id, student_id, guardian_user_id, relationship, status and linked_by.
  - schoolpro_access_invitations stores invited child IDs and relationship. The existing schoolpro_accept_access_invitation RPC validates that each selected child is active and belongs to the invitation school, then creates/activates the guardian links.
  - profiles.phone and schoolpro_students.guardian_email already exist. Parent management reads the linked profile phone and displays the saved relationship.
- Updated the parent account form to capture an optional guardian contact phone. The existing invitation Edge Function validates the length, saves it to a newly created parent profile, and fills an existing profile phone only when that field is blank. A non-empty global profile phone is never overwritten by a school invitation. Existing guardian relationship and invitation-acceptance behavior are unchanged.
- Student enrolment now captures optional guardian email alongside the existing guardian name and phone fields. The student record list displays the email and includes guardian email in search. The parent-child selection list now displays the student's full name including middle name.
- Removed the direct hard-delete handler from the student page. Student exit continues through the existing schoolpro_transfer_student_out RPC, which marks the student withdrawn, records transfer details, closes active enrollment history, releases active transport/hostel allocations and writes an audit event. Academic and financial history is not deleted.
- Added scripts/test-schoolpro-student-family-records.mjs, registered it as test:schoolpro-student-family-records in package.json, and wired it into the SchoolPro CI validation job.
- Implementation commits: parent phone form 50cfc29; initial invitation phone handling 45dd9f5; student guardian email and removal of delete UI 6b85e2f; delete-handler removal a6b3c22; invitation phone validation/preservation 27c2139; invitation-order correction c51f4bb; family-record regression test 09bff93; package script 2c03d9f; CI wiring 612f273; guardian-email search cfcafc0; full-name parent-child selector 63d1a7f.
- The connected Supabase inspection was read-only. No migration, DDL, DML, production data change, deployment, workspace creation or test-account creation occurred. No additional Supabase branch was created.
- Exact-head SchoolPro CI and payment validation for the B2 code are pending. Do not mark B2 complete or merge PR #111 until those checks pass and the resulting head is reviewed. PR #111 remains draft/open/unmerged.

### Stage B3 bulk progression roster consistency — implementation pending exact-head validation — 2026-11-03

- Focused review found that the Classes & Arms view and class roster already used schoolSessionStudents(), but SchoolBulkAcademicActions read schoolpro_enrollment_history directly. That bypass meant legacy schools with no enrollment-history rows could see an empty year-end progression/transcript roster instead of the intended active-student fallback.
- Updated SchoolBulkAcademicActions to load the school's student records and resolve them through the same schoolSessionStudents() helper used by class rosters. This preserves historical class/session assignments when history exists, returns an empty roster for a historical session when the school has history but no rows for that session, and uses active current students only when the school has no enrollment-history records at all.
- Extended scripts/test-school-session-rosters.mjs to assert that bulk academic actions use the canonical resolver and pass its resolved student/class IDs to the progression RPC.
- Implementation commits: bulk action resolver a6eda5f; regression assertion 95d7f53.
- Exact-head SchoolPro CI and payment validation are pending. No production schema/data changes, migration, deployment, workspace creation or test-account creation occurred.

### Stage B3 database-side legacy roster fallback — implementation pending exact-head validation — 2026-11-03

- Follow-up to the application-side roster resolver found that the bulk progression RPC still inner-joined schoolpro_enrollment_history. That would exclude every active student at a legacy school with no history rows, even though the UI correctly displayed its active current roster.
- Updated schoolpro_bulk_academic_action in the proposed progression migration to use the same rule as schoolSessionStudents(): if the school has any enrollment-history rows, only students with a row for the selected session are included and their historical class is authoritative; only when the school has no history rows at all does it fall back to active students and their current class.
- Extended the progression source regression test and disposable-PostgreSQL integration fixture to cover a legacy school with no enrollment-history rows, three published terms, and a repeat decision under the default below-45% threshold.
- Extended the session-roster regression test to assert that class counts use historical class_id rather than the student's current class, and that graduated students remain visible in their historical class roster.
- Implementation commits: database resolver a9e5b07; source assertion b52e71f; legacy integration fixture 2fafe2c; school-owned legacy subject fixture 6fa3038; historical class-count regression 514c4d6.
- This remains a proposed migration and disposable integration test only. No production schema/data change, migration application, deployment, workspace creation or test-account creation occurred. Exact-head SchoolPro CI and payment validation are required before treating B3 as complete.

### Stage B3 roster regression assertion syntax correction — 2026-11-03

- Exact-head SchoolPro CI run `41632059358` exposed a JavaScript parse error in `scripts/test-school-session-rosters.mjs`: an apostrophe in the assertion message terminated its single-quoted string. This was a test-source syntax issue; the roster implementation and database progression integration jobs passed.
- Corrected the assertion wording without changing test behavior. Fix commit: `b7372667b1d23c790ab83d7eb913e3f238f4c791`.
- Payment validation run `41632059491` passed on the preceding head. The corrected commit requires fresh exact-head SchoolPro CI and payment validation; the prior CI's Receipt Storage isolation job was still in progress when inspected.
- PR #111 remains open/draft/unmerged. No production migration, data change, deployment, workspace or test account was created.

### Stage B2/B3 exact-head validation — passed — 2026-11-03

- Corrected the apostrophe syntax error in the session-roster regression assertion (commit `b7372667b1d23c790ab83d7eb913e3f238f4c791`) and recorded the correction above.
- Final handover update commit: `8a9b657168c10ea5056db2b2c89677b6170cee13`.
- Exact-head SchoolPro CI run `41632784502` (run #2322) passed. The `validate` job, session-roster regression, student-family-record regression and all database integration jobs passed, including progression subject requirements, production graduation certificates, Form Master attendance RLS, section leadership authorization, academic calendar, Receipt Storage isolation, tenant-integrity, payment-review RLS, public admission, result-PIN and result-verification exposure. Tenant acceptance was skipped because no active workspaces exist.
- Exact-head payment validation run `41632784513` (run #2047) passed.
- B2 student identity/family-record implementation and B3 session-specific roster/progression implementation now have passing exact-head CI/payment evidence. PR #111 remains open, draft and unmerged.
- Next Stage B work is B4 staff, class and subject assignment integrity. Existing staff and subject allocation screens are present; B4 should focus on validating their data model, tenant/session scoping, role authorization and assignment lifecycle rather than duplicating existing UI. No B4 changes are included in this validation.
- No production migration, production data change, deployment, workspace creation, test-account creation or new Supabase branch occurred. All database migration tests ran against disposable PostgreSQL/local CI infrastructure only.


## Stage B4 — subject allocation teaching-role eligibility guard — 2026-11-03

- Source review found that the Subjects & Teacher Allocation page offered every school member in the teacher selector, including finance, administration and operational roles. The Form Master selector already restricted candidates to the two teaching roles.
- Restricted subject-assignment candidates to `teacher` (Subject Teacher) and `class_teacher` (Class Teacher), matching the existing school role descriptions and Form Master eligibility. This is a UI eligibility guard; the database/RLS remains authoritative and backend assignment constraints still require separate verification before B4 can be accepted.
- Extended the existing session-roster regression test (already wired into SchoolPro CI) with an assertion that the subject allocation selector filters candidates to teaching roles.
- No schema or production change, migration execution, deployment, workspace or test account was created. PR #111 remains draft and unmerged.
- Next B4 action: trace the subject-assignment write policy/trigger and the form-master RPC to confirm that the backend independently validates same-school membership and teaching-role eligibility; then address any demonstrated stale-reference or role-transition defect with isolated regression coverage.


## Stage B4 — backend assignment authorization trace — 2026-11-03

- Rechecked the latest exact-head CI/payment workflows after the subject-teacher selector change: SchoolPro CI #2325 and payment validation #2050 both completed successfully on `7e51eb19f176ae9aa3d6c88b8faaeb24a3b5f043`.
- Read the existing `private.schoolpro_set_form_master` implementation (migration `20261011124255_schoolpro_board_and_class_coordinator_roles.sql`). It resolves the class's owning school, requires the Classes module and proprietor/administrator access, and rejects a selected member unless that member belongs to the same school and has role `teacher` or `class_teacher`. It writes an audit event. This is an existing backend safeguard; no duplicate RPC is needed.
- The same database-level guarantee has not yet been established for `schoolpro_subject_assignments`: the inspected allocation policy migration (`20261012121241_schoolpro_bounded_teacher_allocation_policy.sql`) changes teacher read visibility only. The UI selector restriction is not a substitute for a write-time tenant/role guard. Do not mark B4 complete until the assignment table's write policy/trigger is located and verified or a proposed migration adds an equivalent guard with disposable-PostgreSQL regression coverage.
- No live Supabase writes or schema inspection were performed, and no production migration was applied. PR #111 remains draft and unmerged.

### Stage B4 — subject-assignment database role alignment — 2026-11-03

- Located the original `private.validate_subject_assignment()` trigger in `20260916190636_school_academics_attendance_and_superadmin_access.sql`.
- The original trigger enforced same-school class, subject, and member references, but its role allowlist was `teacher`, `administrator`, and `proprietor`. This contradicted the subject-assignment UI and teaching-role contract: the UI offers `teacher` and `class_teacher`, while the trigger rejected `class_teacher` and admitted non-teaching leadership roles.
- Added proposed migration `20261103110000_schoolpro_subject_assignment_teaching_role_guard.sql` to align the trigger with the supported teaching roles (`teacher`, `class_teacher`) while preserving same-school class, subject, and member checks. A null teacher remains valid for an unassigned subject.
- Extended `scripts/test-school-session-rosters.mjs` with regression assertions tying the UI role filter to the database guard and checking all three tenant-boundary predicates. This is a source-level regression assertion, not a substitute for a live/disposable-PostgreSQL trigger execution test; add database execution coverage before final B4 acceptance.
- No Supabase migration was applied and no production data or workspace was created or changed.

### Stage B4 — disposable PostgreSQL assignment-trigger coverage — 2026-11-03

- Added `scripts/test-schoolpro-subject-assignment-guard.integration.sql`. It creates a disposable schema fixture, applies the original subject-assignment migration followed by the proposed role-alignment migration, and executes the actual trigger through INSERT/UPDATE statements.
- Coverage includes acceptance of `teacher` and `class_teacher`, acceptance of an unassigned (`NULL`) teacher, and rejection of administrator assignment, a foreign-school teacher, a foreign-school class, and a foreign-school subject.
- Added a dedicated `subject-assignment-guard-integration` GitHub Actions job using an isolated PostgreSQL 16 service. It does not connect to Supabase or require school workspaces/accounts.
- The dedicated PostgreSQL 16 job passed on commit `43d03bbd5e52c2a16060e873ddbe01de3c4633a6` in SchoolPro CI run `41637169487`. This validates the trigger behavior on that commit; later Staff-page display changes are separate and still need validation on the newer PR head. B4 remains in progress pending the current-head CI result and review of remaining staff/class/subject assignment paths.

### Stage B4 — staff role-change responsibility display — 2026-11-03

- Staff role changes are currently performed directly on `schoolpro_members.role`; existing subject-allocation and Form Master references are retained for historical continuity.
- The Staff page previously rendered every referenced allocation as a current teaching responsibility, even after a staff member's role changed to a non-teaching role.
- Updated the responsibility projection to label Form Master / subject allocations only for members whose current role is `teacher` or `class_teacher`. This is a display correction; it does not delete or rewrite historical assignment records and does not change authorization.
- Added a regression assertion to `scripts/test-school-session-rosters.mjs`.
- Attendance remains governed separately by the Form Master scoped RLS migration and its disposable-PostgreSQL test; this UI correction does not grant attendance access.

### Stage B4 — class-level Form Master assignment UI — 2026-11-03

- The database RPC `schoolpro_set_form_master(p_class,p_member)` already validates school ownership, Classes-module access, leadership authority, and same-school membership with role `teacher` or `class_teacher`.
- The Classes & Arms page previously had no control to assign or change a class Form Master, leaving the validated backend workflow inaccessible through the normal interface.
- Added a Form Master selector to each class row. It loads only same-school teaching-role members and calls the existing RPC; it does not write `form_teacher_id` directly.
- Added regression assertions for the RPC call and the eligible-role query to `scripts/test-school-session-rosters.mjs`, which runs in SchoolPro CI.
- No database migration or production data change was made. Current-head CI is required to validate this UI and test update.


## Stage B4 — Form Master role-downgrade cleanup — 2026-11-03

- Added proposed migration `20261103130000_schoolpro_clear_ineligible_form_master.sql`. When a member changes from `teacher` or `class_teacher` to a non-teaching role, the database trigger clears that member from current `schoolpro_classes.form_teacher_id` assignments in the same school.
- This prevents a former Form Master assignment from silently becoming active again if the member later returns to a teaching role. A new assignment must be made explicitly.
- Subject assignment rows are deliberately retained because they may be needed to preserve historical result attribution. The existing subject-assignment guard still validates teaching eligibility on new or changed allocations.
- Extended the disposable PostgreSQL subject-assignment integration harness to execute the role-downgrade trigger and assert that the Form Master link is cleared while the subject allocation row remains intact. Extended the existing session-roster regression script with migration assertions.
- Validation is pending on the new exact PR head. The previous exact head `d2c2453ece828e22b50115458ec0aa867eee8808` passed SchoolPro CI #2342 and payment validation #2067.
- No production migration, data change, deployment, workspace creation, or test account was used.


## Stage B6 — Houses, games and competitions foundation — 2026-11-03

- User confirmed a full Houses, Sports, Games and Competitions module: default Red, Green, Blue and Yellow houses; school-configurable houses; House Masters appointed from teaching staff; balanced automatic house allocation for newly enrolled students; manual assignment/reassignment for existing or transferred students; configurable inter-house sports, athletics, debates, quizzes, cultural events and other competitions; Game Master-defined rules, eligibility, scoring rubrics, judging guidance, penalties, awards and house-point standings; and a separate Discipline Master role.
- Added `discipline_master` and `game_master` to the application role catalogue and staff role grouping. Added their dedicated dashboard recognition and management-operation role mapping. The role permission migration gives Discipline Master only dashboard/student/discipline/notification access and Game Master dashboard/student/games/notification access; explicit member permission denies remain authoritative.
- Added forward-only enum and role-permission migrations: `20261103140000_schoolpro_house_competition_roles.sql` and `20261103141000_schoolpro_house_competition_role_permissions.sql`. These are repository migrations only; they have not been applied to Supabase.
- This is the role/access foundation, not completion of the Houses and Competitions feature. Next implementation slice must add tenant-scoped house configuration and student house-membership history, balanced allocation with deterministic tie-breaking, manual assignment workflow, teaching-staff House Master assignments, and the competition/rubric/judging/points schema and UI. Do not overwrite historical student house assignments or competition results.
- No live database change, production data write, deployment, test workspace creation or PR merge was performed for this B6 foundation.


## Stage B6 — House configuration and student allocation foundation — 2026-11-03

- Added migration `20261103142000_schoolpro_houses_and_student_house_history.sql` (repository-only; not applied to Supabase). It creates tenant-scoped houses, house-master appointment history and student house-membership history.
- New and existing schools receive default Red, Green, Blue and Yellow houses. House names, codes, colours and ordering can be configured through a games-permission RPC.
- New student records receive a balanced automatic house assignment by selecting the active house with the lowest current roster count (stable tie-break by configured order/name/id). This covers direct enrolment and admission-to-student conversion because the trigger runs on student insertion. If no active houses exist, the student remains unassigned rather than failing enrolment.
- Existing/transfer students can be manually assigned through a tenant-checked RPC. Reassignment closes the prior history row and creates a new manual row; it never overwrites the historical assignment.
- House Masters are appointments of same-school teaching staff (teacher/class_teacher), not a broad staff role. One active House Master per house and one active house per House Master are enforced. Demotion from teaching roles closes the appointment while preserving history.
- RLS protects house, appointment and student-house-history reads. Mutations are exposed through authenticated RPCs that require the school games permission. No direct table write policies were added.
- Added disposable PostgreSQL integration coverage and a CI job for default-house seeding, balanced allocation, manual reassignment history, tenant boundaries and House Master eligibility/downgrade.
- Competition/event/rubric/judging/points schema and UI remain the next B6 slice. No production migration, live data change, deployment, test workspace creation or PR merge was performed.


## Stage B6 — Competition events, staff judging and house standings — 2026-11-03

- Corrected the literal escaped-newline defect in the house-master helper grant statement in `20261103142000_schoolpro_houses_and_student_house_history.sql`. The prior CI failure stopped at this syntax defect before exercising house allocation behavior.
- Added proposed migration `20261103143000_schoolpro_competitions_staff_judges_scoring_and_house_points.sql`.
- Competition events support sports, athletics, debate, quiz, cultural, academic and custom event types; optional session/term labels; event rules and eligibility JSON; judging guidelines; lifecycle states; and start/end dates.
- Added configurable weighted scoring criteria with maximum points, house/team entries and participant details.
- Staff judges are explicit event assignments selected from the same school's staff records. A judging panel can designate chief judges, judges, timekeepers, referees and moderators; assignments have an end timestamp and retain history. Staff can be assigned to multiple events, but only once per event while active.
- Assigned judges can submit scores only for events to which they are actively assigned. Scores are linked to the event, entry, rubric criterion and judge assignment; a database trigger enforces tenant consistency and rejects scores above the criterion maximum. A judge can revise their own criterion score through the scoring RPC while the event is open/scoring.
- Added an append-only house-point ledger and a security-invoker standings view. Awards retain the awarding staff identity, reason, optional event and entry references; positive and negative adjustments are supported for corrections/penalties.
- Added disposable PostgreSQL assertions for staff judge appointment, rubric score recording and maximum enforcement, cross-school house-entry rejection, point ledger insertion and house standings. These run in the existing house-allocation integration job; no live workspace or account is needed.
- The first exact-head run `41643968457` failed because the house migration contained a literal `\\n` before a GRANT statement. The migration syntax has been corrected; the previous run is not evidence of a passing house or competition test. New exact-head CI/payment validation is required.
- These migrations and tests are repository-only. Do not apply them to Supabase, deploy, create workspaces, or merge PR #111 without explicit authorization and passing exact-head validation.


### B6 implementation refinement — judge access and setup permissions — 2026-11-03

- Competition setup tables (events, rubric criteria and entries) grant authenticated insert/update/delete privileges guarded by the games-module RLS policy. Judge assignments, score writes and house-point ledger writes remain RPC-controlled.
- Assigned judges receive read access only to their own event, its criteria and entries; they do not receive general games administration access. Judge score submission remains limited to active panel assignments.
- The house and competition integration script now runs both migrations in sequence and covers a chief-judge staff assignment, valid score, over-maximum rejection, cross-school house-entry rejection and house standings.
- Exact-head CI has not yet reported a run for the latest commit. Do not treat the migrations as validated until the new PostgreSQL integration job and the full SchoolPro CI/payment checks complete successfully.


## B6 — Houses, Games and Competitions workspace UI — 2026-11-03

- Added `src/pages/schoolpro/SchoolProGames.tsx` and registered `/schoolpro/games` behind the `games` permission. Added a school navigation item and path-to-permission mapping.
- The workspace provides house configuration, House Master appointment and appointment history, manual house assignment for transfer/existing students, competition event creation, event-specific weighted rubric criteria, house/team entries, staff judging-panel assignments, judge score entry, manual house-point adjustments/penalties, and inter-house standings.
- House Masters are selected from teachers/class teachers; event judges are selected from the school's staff records and can be assigned as chief judge, judge, timekeeper, referee or moderator.
- Staff judges can use the score submission flow only when authenticated as an active judge assigned to that event. Games administrators manage event configuration and scoring panels.
- The page uses the current school's scoped Supabase queries and existing RPCs; no client-side demo data or test workspaces were introduced.
- UI is committed to PR #111. Typecheck/build and disposable PostgreSQL integration remain pending for the exact latest head. Do not apply migrations to Supabase or deploy until those checks pass and the user authorizes the next stage.


### B6 UI refinement — event lifecycle and staff judge portal — 2026-11-03

- Added competition lifecycle controls so Game Masters can move events from draft to open, scoring and completed. The score RPC only accepts scores while an event is open or scoring.
- Added a separate `/schoolpro/judge` portal for staff who are assigned to judging panels. This route does not grant the Games module; its data access is constrained by RLS to the signed-in staff member's own active assignments, the assigned event's rubric/entries and score records. The portal submits scores through the judge-attributed RPC.
- Added RLS allowing an authenticated staff member to read only their own judge assignment rows. The predicate is explicitly qualified by the outer judge table's school and member IDs.
- Added navigation for both the Games administration workspace and the personal judging portal.
- The exact-head typecheck/build and disposable PostgreSQL integration have not yet returned results. Treat this as implementation in review, not validated production functionality.


### B6 — Games and judging UI integration — 2026-11-03

- Added the SchoolPro Games management page integration for house configuration, House Master appointments, manual student-house placement, event creation, rubrics, house/team entries, staff judging panels, judge score entry and house standings/point awards.
- Added a dedicated My Judging Panel page. Staff can see only events assigned to their own school membership and submit/revise criterion scores through the judge RPC; active assignment, event status and maximum score are enforced server-side.
- Event creation UI now exposes separate JSON objects for event rules and eligibility, plus judging guidelines. Invalid JSON is rejected before submission.
- Fixed malformed JSX closing syntax on the Staff and Games routes, and corrected house-points form state references.
- Exact CI run #2384 reported a house-test PL/pgSQL ambiguity: the test variable `member_id` shadowed the same-named table column in assertions. Renamed the test variable to `teacher_member_id`. That run's TypeScript failure was from the malformed routes; those are now corrected. A subsequent exact-head run is still required.
- Do not mark B6 validated until the latest TypeScript checks and the combined house/competition PostgreSQL integration job pass. No Supabase migration, deployment, or PR merge has been performed.


### B6 exact-head validation findings and fixes — 2026-11-03

- Exact PR-head validation on `b22da8ffa021882133593281918a8dbdb3c1e109` completed with failures in both SchoolPro CI run #2389 and payment-page validation run #2114. The payment validation failure was the same TypeScript issue as the main CI failure; it was not an independent payment-page defect.
- TypeScript identified the Games page helper signature as too restrictive: Supabase PostgREST query/RPC builders are awaitable (`PromiseLike`) but are not native `Promise` instances. Updated the `run` helper argument type to `PromiseLike<{ error: any; data?: any }>` so it accepts the actual Supabase builder return types while preserving awaited error handling.
- The house/competition PostgreSQL integration failed in the competition assertion because the PL/pgSQL variable `event_id` was ambiguous with the ledger table column `event_id`. Renamed the test-block variable and its references to `competition_event_id`; the ledger column remains explicitly qualified.
- Both source/test fixes are committed to the PR branch. The next required action is exact-head CI and payment validation; neither failure is considered resolved until those workflows pass. No Supabase migration, production data change, deployment, workspace creation or PR merge occurred.


### B6 integration test column-reference correction — 2026-11-03

- SchoolPro CI run #2392 on commit `9eb496084c58ea87edeb1e2beb924e0a46e02fef` passed the full application `validate` job (including TypeScript and production build) and all other listed integration jobs except `houses-and-house-allocation-integration`. Payment validation for this head was not reported in the workflow result inspected.
- The remaining house/competition job failure was caused by the previous test-only rename replacing schema column names as well as the PL/pgSQL variable. The schema correctly uses `event_id` in competition criteria, entries and house-point ledger; only the PL/pgSQL local variable is `competition_event_id`.
- Corrected the integration test to use the renamed local variable for values/RPC arguments while restoring the actual `event_id` column identifiers in INSERT column lists and the qualified ledger assertion.
- This is a test-harness correction only. Exact-head PostgreSQL integration and payment validation remain required. No Supabase migration, production data change, deployment, workspace creation or PR merge occurred.


### B6 exact-head validation — competition test variable ambiguity — 2026-11-03

- Exact-head SchoolPro CI #2394 on PR head `8393267ad8605a68813d1c4e80a33331f3979014` completed with only `houses-and-house-allocation-integration` failing. The application validate job (TypeScript, source assertions and production build), all other listed database integration jobs, and payment-page validation #2119 passed. Tenant acceptance remained skipped because there are no active workspaces.
- The house/competition SQL test itself successfully passed the default-house, balanced automatic allocation, manual reassignment history, House Master eligibility and downgrade-cleanup assertions. The competition block then failed because local PL/pgSQL variable `house_id` shadowed the standings view column in its final assertion.
- Renamed only the competition-block local variable to `competition_house_id`, retaining the real schema column names `house_id` and `event_id`. Also corrected the cross-school competition-entry INSERT column list to use the actual `event_id` column (not the similarly named local variable).
- Test-only fixes committed as `2dd0229` and follow-up schema-column correction as `ee1e4aa`. Exact-head CI and payment validation must be checked again on the new head. Do not proceed to result aggregation/publication until the combined integration job passes.
- No production migration, live data change, workspace creation, deployment or PR merge occurred.


## 2026-11-03 authoritative Stage B6 continuation

This section supersedes older stage-status summaries above where they conflict.

- Stage A remains accepted and complete. Stage B1–B5 are recorded as complete in the current working sequence. Stage B6 is in progress.
- The active work is PR #111 on `stage-b/academic-sessions-student-rosters-20261030`. It remains a draft PR. No merge, production deployment, Supabase migration application, production data change, or database-platform migration has been performed.
- B6 foundations already committed: Discipline Master and Game Master roles; configurable Red/Green/Blue/Yellow houses; balanced automatic allocation of new active students; manual assignment history; House Master appointment history; event types/rules/eligibility; rubric criteria; staff judging panels; judge score entry; house-points ledger and standings.
- CI for head `a504c19df1e820fbbcb77aa825700e0ca61e733f` completed successfully: SchoolPro CI run #2397 and payment-page validation #2122 both passed. The house allocation/competition integration and local Receipt Storage isolation jobs passed. Tenant acceptance was skipped because no active workspaces exist; do not create test workspaces to force this conditional check.
- New repository-only migration `20261103144000_schoolpro_competition_result_approval_and_publication.sql` adds versioned result snapshots, weighted rubric calculation (average judge score per criterion, normalized by criterion maximum and weight), competition ranking with tied positions, explicit Games-permission approval and publication, and a helper that permits event-linked house points only against a published result entry.
- New integration assertions were appended to `scripts/test-schoolpro-houses-and-allocation.integration.sql` for the 87.50 weighted score fixture, ranking, rejection of approval by a judge without Games management permission, approval/publication audit fields, and retained result snapshot.
- These latest result-calculation changes are committed on the PR branch but have not yet completed CI. Do not claim them validated until the new head's full SchoolPro CI and payment-page validation complete.
- Next action: inspect the latest commit and CI run. Fix only concrete failures. Once green, continue B6 UI work to expose result preview/version, approval, publication and published-result-based house awards. Preserve the no-production-write/no-merge/no-deployment boundary.


### B6 result migration CI harness correction (2026-11-03)

- CI run #41653140463 exposed that the house/competition disposable PostgreSQL script invoked the new result RPCs without first applying the result migration. The earlier house allocation and competition/judging tests passed; the failure was specifically that schoolpro_calculate_competition_results(uuid,uuid) did not exist in the test database.
- Corrected scripts/test-schoolpro-houses-and-allocation.integration.sql to include supabase/migrations/20261103144000_schoolpro_competition_result_approval_and_publication.sql before the result calculation assertions.
- Commit: 4cf319b27f6600e6d6beff959f140ffa46726e0f.
- New CI run is expected for this head. Result calculation, approval and publication remain unvalidated until that run completes. No production changes.

## 2026-11-03 — B6 competition result integration CI correction

- Latest validation of the B6 result approval/publication work found a test-harness syntax issue, not a database assertion failure: the psql include for `20261103144000_schoolpro_competition_result_approval_and_publication.sql` had two leading backslashes, so psql reported `invalid command \\\\ ` at line 143.
- The preceding house, judge-panel, rubric-limit, tenant-safe-entry, point-ledger and standings assertions had passed in that run.
- Corrected the include to the single-backslash psql directive `\\ir ../supabase/migrations/20261103144000_schoolpro_competition_result_approval_and_publication.sql`.
- Fix committed on the existing Stage B branch as `076ae3be52f5e769499a4f6f4dd5cb935486366e`. This only changes the disposable PostgreSQL integration test script; no migration was applied to Supabase and no production data, deployment, or PR merge occurred.
- Previous head `f109fc7aa22e2bbe802ad01b256908ad5b26ca16`: payment-page validation passed; SchoolPro CI failed only in `houses-and-house-allocation-integration` because of the malformed include. All other CI jobs passed; tenant acceptance was skipped because there are no active workspaces.
- Await fresh CI and payment-page validation on the corrected head before treating B6 result aggregation/approval/publication as validated.

## 2026-11-03 — B6 result authorization test-fixture correction

- After the psql include syntax fix, SchoolPro CI #2404 reached the competition result authorization assertion and failed because the test expected a teacher to be denied approval, but the shared teacher fixture had been changed to `administrator` earlier in the House Master downgrade-cleanup test.
- The production approval and publication RPCs already check `private.schoolpro_module_allowed(p_school,'games')`; the failure was caused by test-fixture state leaking between assertions, not evidence that a judge bypassed the production permission check.
- Restored the fixture membership role to `teacher` immediately after verifying that downgrading the role closed the House Master appointment. This keeps the downgrade-cleanup assertion while ensuring the later assigned-judge approval denial test exercises a non-Games role.
- Test correction committed as `7bfadeec22fcec4cd94f6f8786e94f5ce63b8303`. Await fresh CI on this head; no production migration, Supabase change, deployment, or PR merge.

## 2026-11-03 — B6 competition result workflow UI

- Latest validated backend head before UI work: `9644efcb09e2949f1ddb85575c7e63ddbdf1dc93`; SchoolPro CI #2406 passed, including disposable PostgreSQL house allocation, competition judging, weighted result calculation, judge authorization denial, result approval/publication and snapshot assertions. Payment-page validation #2131 passed. Tenant acceptance skipped because there are no active workspaces.
- Connected `src/pages/schoolpro/SchoolProGames.tsx` to the versioned result backend: load event result runs, select the newest calculated/approved/published version, load its immutable entry snapshot, calculate a new version, approve calculated versions, and publish approved versions only after the event is marked completed. Buttons are gated by the Games management role in the UI; RPCs remain the authoritative permission enforcement.
- Kept manual house-point adjustments separate from competition-linked awards by making those manual awards unlinked to an event. Competition-linked awards must use the published-result RPC, which validates that the entry and house belong to the published snapshot.
- UI commits: `7248166b4dfbf9f6ff163d6a60e0f3f728731c4c` and `b5a036b567805f5af5e175113e3f0942d1a0edae`. Await fresh CI/build validation on the UI head before treating this interface as complete.
- No Supabase migration applied, no production data changed, no deployment, no PR merge, and no test workspace/account created.
- Follow-up UI addition: published result snapshots now expose a Games-manager award action per house entry. The action calls `schoolpro_award_published_competition_points`, so event-linked house points can only be recorded against a complete entry in the currently published version; free-form house adjustments remain separate and event-unlinked. Commit: `ac720370ffb280fca6e7b36671fbe1bdf8194994`.


## 2026-11-04 — Stage B production database rollout completed

- Corrective PR #113, **Fix section leadership helper schema reference**, merged successfully. Merge commit: `54b94b86c2c1cd60c3c411e652c35c8ad23a5b3e`. Its exact-head SchoolPro CI workflow run `41669205877` completed successfully, and payment-page validation run `41669206043` completed successfully. The section-leadership authorization integration check passed. Tenant acceptance was skipped because there are no active school workspaces; no workspace was created to force the check.
- The separate Stage B feature PR #111 was already merged on 2026-11-03 (merge commit `7557e0ff3b8a1eaeb9b9a70cf77d3fb9aa54bf77`).
- Preserved the first seven Stage B production migrations already applied on 2026-11-03. Resumed at migration eight; did not replay those first seven.
- Applied the remaining seven migrations to Supabase project `lnqsroyiybutkfngbyge`, in order:
  1. `schoolpro_section_leadership_scope`
  2. `schoolpro_clear_ineligible_form_master`
  3. `schoolpro_house_competition_roles`
  4. `schoolpro_house_competition_role_permissions`
  5. `schoolpro_houses_and_student_house_history`
  6. `schoolpro_competitions_staff_judges_scoring_and_house_points`
  7. `schoolpro_competition_result_approval_and_publication`
- Supabase migration ledger records all seven newly applied migrations with versions `20261104101139` through `20261104101217`; together with the seven recorded on 2026-11-03, all 14 Stage B migrations are recorded.
- Read-only catalog verification confirmed the section-leadership, houses, student-house history, competition events/criteria/entries/judges/scores, house-point ledger and competition result run/entry tables exist. It also confirmed the section-leader RPC, competition calculation/publication RPCs and published-result house-points RPC exist. The incorrect private-schema helper `private.schoolpro_member_can_manage(uuid)` does not exist; the migration correctly uses the existing public helper.
- No school workspace, staff account, student, house, event, judge, score, result or other operational test record was created. No school operational data was populated or modified by this rollout.
- A Vercel commit status reported `Account is blocked`; this is not a Render deployment result. The production frontend is hosted on Render. No Render deployment was triggered or verified as part of this database-only rollout.
- **Next:** continue with the post-rollout application/production readiness step for the merged Stage B UI on Render, then move to Stage C only after confirming the live UI is compatible with the now-applied schema. Do not create test workspaces or seed demo records; use existing CI/disposable PostgreSQL coverage and read-only production checks.


## Production registration hotfix — 2026-11-04

- **Issue:** A real SchoolPro school-registration submission returned a generic UI error. Supabase logs showed the POST /rest/v1/schoolpro_onboarding_requests request returning HTTP 401 with PostgreSQL error permission denied for function schoolpro_can_register.
- **Root cause:** The original INSERT policy combined anon and authenticated roles in one expression. Its anonymous branch allowed a null user_id, but PostgreSQL could still evaluate the authenticated-only private.schoolpro_can_register() predicate. The anon role has no USAGE on private and no EXECUTE on that helper.
- **Production correction:** Replaced the combined policy with separate policies: anonymous inserts require user_id IS NULL and all review/workspace fields unset; authenticated inserts require user_id = auth.uid(), all review/workspace fields unset, and private.schoolpro_can_register(). No permissions were broadened on the private schema or helper.
- **Migration:** 20261104113534_schoolpro_split_onboarding_insert_policies was applied to the existing Supabase project and is included in supabase/migrations/20261104113534_schoolpro_split_onboarding_insert_policies.sql.
- **Data impact:** The failed request left no onboarding-request row and created no SchoolPro workspace for the submitting account. No school, staff, student, house, competition or other operational records were created.
- **Source follow-up:** The migration is on branch fix-schoolpro-onboarding-anon-policy-20261104; merge through PR after CI. The production database hotfix is already active.
- **User retry guidance:** If the initial registration created an Auth account but no active session (email verification flow), verify the email, sign in, and submit the school request again. The anonymous submission path is now independently permitted without invoking the authenticated eligibility helper; authenticated requests remain subject to proprietor eligibility.


## 2026-11-04 — School-owner registration routing follow-up

- Reproduced the second part of the registration incident from source: the School Owner Login uses the dedicated `schoolpro-account-login` Edge Function, then resolves a school destination. An authenticated proprietor with no school membership currently falls through to the generic SchoolPro landing route; the access-denied page then incorrectly directs every unresolved account to Student Login.
- Updated `src/lib/schoolSignIn.ts` to call the authenticated `claim_schoolpro_onboarding()` RPC after school membership resolution, then look for the signed-in user's submitted/reviewing/approved/provisioning/active request. If one exists, route to `/schoolpro/register?requests=1` so the existing My school requests component can display its status.
- Updated `src/pages/schoolpro/SchoolProAccessDenied.tsx`: signed-in accounts without a resolved school are now directed to their SchoolPro registration/request-status page; signed-out users are directed to School Owner Login. Student Login remains explicitly identified as student-only.
- These source changes were added to the existing registration-policy PR branch `fix-schoolpro-onboarding-anon-policy-20261104`; fresh CI is required because the branch head changed.
- The current `IHLink-SchoolPro` repository contains the onboarding review SQL/RPC and database authorization policies, but it does not contain the Central Super Admin `/admin/schoolpro` review-page implementation. The control-panel frontend is therefore outside this repository's source tree and must be located in the separate control-panel repository before claiming that the review queue UI has been repaired. The production database still has zero onboarding requests at the time of diagnosis; do not invent or create one.
- No new account, workspace, staff/student record or other operational test data was created. No Render deployment has been triggered for this follow-up.


## 2026-11-04 — Stage A–B correction pass started (do not proceed to Stage C)

- Opened a focused correction pass on branch `fix/stage-a-b-dashboard-entitlement-completion`; no production deployment, production migration application, subscription change, or operational data creation has occurred.
- Added `docs/database-migration/STAGE-A-B-CORRECTION-REGISTER.md` as the consolidated gate for outstanding Stage A–B corrections and the plan/upgrade workflow. Stage C is blocked until this register's release gates are satisfied.
- Confirmed Games & Sports implementation already exists in `src/pages/schoolpro/SchoolProGames.tsx`, route `/schoolpro/games`, and the Stage B houses/competition migrations. It includes house configuration, House Masters, manual student assignment, event setup, judging panels, scoring, result publication and inter-house standings.
- Confirmed the live `schoolpro_user_permissions` function does not grant `games` to board administrators, principals, school owners or ordinary school administrators, despite the UI expecting those roles to manage the Games screen. Game Master already has the `games` permission.
- Confirmed registration's requested-module list omitted Games & Sports. Game Master also landed on the generic admin dashboard, and teacher navigation omitted My Judging Panel.
- Confirmed standard-report entitlement regression: `private.schoolpro_module_allowed` tied generic `reports` permission to the Enterprise `advanced_reports` feature, and `/schoolpro/broadsheet` was explicitly wrapped in the Enterprise gate. This contradicted the agreed plan: ordinary report cards, broadsheets and exports remain available on all tiers.
- Added a proposed forward-only migration `20261104150000_schoolpro_stage_ab_dashboard_and_report_entitlement_corrections.sql` to enable Games on Starter/Professional/Enterprise (and legacy Premium), grant Games to leadership permission arrays, and separate standard report access from the Enterprise Advanced Reports entitlement. Migration is committed on the correction branch only; it has not been applied to Supabase.
- Updated the correction branch to include Games & Sports in registration and the public feature list, add optional preferred-plan selection, route Game Master to the Games screen, expose My Judging Panel in teacher navigation, show annual-only prices and catalogue-driven feature lists on pricing, show Games/standard reports in the subscription view, and remove the Enterprise gate from the standard broadsheet route.
- Added `scripts/test-schoolpro-stage-ab-corrections.mjs` and wired it into the package scripts and SchoolPro CI. PR #116 is open. An early typecheck caught a JSX closing-tag mismatch in the permission-scoped dashboard; that was corrected. Latest exact-head SchoolPro CI #2440 and payment validation #2166 are queued; do not merge until both pass.
- Live catalogue finding: `schoolpro_plan_catalog` stores tier feature flags (Starter currently CBT=false, Advanced Reports=false, custom branding=false; Professional CBT=true; Enterprise CBT/Advanced Reports/custom branding=true). `schoolpro_subscription_catalog` stores monthly, termly and annual prices, but its `features` arrays are empty. Its current annual prices are Starter ₦50,000, Professional ₦100,000 and Enterprise ₦150,000. Monthly/termly values also exist but are not supported by the annual-only paid activation workflow and must not be advertised yet. These are read-only findings; no prices were changed.
- The entitlement catalogue also contains legacy `premium` with a separate `term_price` of ₦55,000; Starter/Professional/Enterprise `term_price` values in that table are ₦15,000/₦35,000/₦75,000. Do not publish Premium as a fourth plan or overwrite either catalogue until the authoritative commercial policy is confirmed.
- Central Admin already has `AdminSchoolProSubscriptions` with manual Control Center plan activation/override and `AdminSchoolProOnboarding` with request review, approval/rejection, workspace creation and unpaid invoice issuance. A dedicated SchoolPro upgrade-request/review/payment-verification lifecycle/table was not found in the live SchoolPro subscription tables; the current manual activation control must not be treated as the complete upgrade workflow.
- Current IHLINK Academy remains Starter. No subscription row, plan, price, or payment was modified.
- Next: finish and CI-validate this correction branch; inspect/implement the corresponding Central Admin upgrade queue and payment verification; reconcile the two plan catalogues; then finish the dashboard/role/navigation matrix and update this handover with exact CI, PR, migration, and Render outcomes. No Stage C work until the correction register's release gate is met.


- Additional dashboard defect found during the role review: `SchoolProLiveDashboard` previously queried student, class and invoice records for every operational role and always rendered fee totals/recent fee records. Roles without `students` or `finance` permission could receive RLS errors, and finance metrics were not permission-scoped. The correction branch now uses `useSchoolProPermissions` to conditionally fetch/render student, class and finance data and clears prior workspace data while permissions resolve. Added assertions to the Stage A-B correction regression test.


- Extended the dashboard correction to route specialist roles to their authorized workspaces (e.g. Game Master → Games, Discipline Master/Counsellor → Discipline, Bursar/Accountant → Fees, Exam Officer → Results, Registrar → Students, Admissions Officer/Receptionist → Admissions, Librarian → Library, Transport/Hostel/Inventory managers → their modules, Nurse → Medical, HR Officer → Staff, IT Admin → Roles & Permissions). Vice Principal and Head Teacher retain the filtered school administration dashboard.
- Found that the assigned-judge link was also filtered out of teacher/staff navigation because `permissionForSchoolPath` had no `judge` mapping. The correction maps the judge portal link to baseline dashboard access; the portal continues to verify active judge assignments and database policies restrict judge data/scoring.


- PR #116: https://github.com/Hassan-625/IHLink-SchoolPro/pull/116 (open, not merged). Latest branch head at this handover update: `8a7ade425e0de7159d0f2301c3819374067360b9`. Latest exact-head CI #2440 and payment validation #2166 are queued. No production migration or Render deployment has occurred.
 

- Follow-up found and corrected a second half of the standard-report plan gate: `permissionPlanFeature()` still mapped generic `reports` permission to Enterprise `advanced_reports`, even after the SQL function was corrected. It now maps only CBT and custom branding; the dedicated Advanced Reports route remains Enterprise-gated. Regression coverage asserts this separation.


- Added a Plans & Subscription entry to the school management navigation, visible only to proprietor, administrator, bursar and platform super-administrator roles. The subscription page continues to check billing-manager access. Regression coverage checks the menu item and role filter.
- Confirmed the Enterprise Advanced Reports route currently renders a generic "module is being configured" fallback: `SchoolProModulePage` has no `reports` definition. Recorded this as an explicit release blocker in the correction register; do not claim Advanced Reports is implemented until its actual analytics workspace, report catalogue, filters, aggregation and exports exist.
- Corrected the frontend plan-permission map so generic `reports` does not require Enterprise. Advanced Reports remains separately protected by the dedicated entitlement gate.


- Updated `scripts/test-school-dashboard-roles.mjs` to match the specialist role landing routes introduced in this correction pass; the prior test still expected all specialists to land on the generic administration dashboard.
- Latest PR #116 head: `a4fb67b1f5cce7f6fd850e0e5fedbbb10131dcd5`. Exact-head SchoolPro CI #2453 and payment validation #2179 are queued. Earlier payment validation #2171 passed on the preceding commit; do not treat it as validation of the current head.
- Added Plans & Subscription to school management navigation, with role filtering for proprietor, administrator, bursar and platform super-administrator. No production deployment or migration application has occurred.


## 2026-11-04 — Stage A–B upgrade credit policy confirmed

- User approved **proportional credit for the unused portion of the existing annual subscription** for school-initiated annual plan upgrades.
- The Stage A–B correction register now requires the review/payment breakdown to show the existing paid annual subscription, start/end dates, elapsed/unused period, proportional unused-term credit, target annual price and net outstanding balance.
- Implementation must define deterministic date-boundary and currency-rounding rules and cover them with disposable tests. A negative balance must not silently become a refund or transferable credit; that treatment requires a separate explicit policy.
- Higher-tier entitlements remain inactive through request, approval, invoice issuance and unverified payment. Activation occurs only after IHLink verifies payment and the plan/entitlement update succeeds atomically.
- Existing manual Control Center activation remains a separate audited override. IHLINK Academy remains on Starter; no subscription, payment, production database or school operational data was changed.
- Stage C remains deferred. Incremental subject/component score entry, result compilation, review, approval, publication, reopening and republication are Stage C requirements, not part of this Stage A–B implementation.
- Documentation commit on the existing correction branch: `8121e4a32760642e0f8727634da59c8a0c388d47` (correction register). No merge, production migration or Render deployment occurred.


## 2026-11-04 — Subscription upgrade workflow read-only verification

- Inspected the existing SchoolPro subscription UI, Central Admin subscription/onboarding screens, live Supabase table definitions and relevant PostgreSQL function bodies. This was read-only; no database rows or schema were changed.
- School-side `SchoolProSubscription` currently offers annual catalogue purchase/renewal through `prepare_schoolpro_bank_subscription`. The live RPC validates school billing authority and creates/reuses a pending full-price `schoolpro_subscription_intents` row. It does not represent a tier-upgrade request, calculate a proportional unused-term credit, or wait for IHLink approval.
- The existing intent table does not store the current-subscription snapshot, unused-term credit breakdown, upgrade review decision/reason, or a verified-payment activation relationship. The generic direct-transfer proof table can represent SchoolPro subscription proofs, but its exact verification-to-upgrade integration and idempotency are not yet established.
- Central Admin's `AdminSchoolProSubscriptions` currently exposes direct `control_center_activate_schoolpro` plan activation. The RPC is a privileged override that activates the tier directly; it is not payment-gated and must remain a separate, audited override rather than the normal school upgrade path.
- The online subscription finalizer explicitly rejects online activation; the supported subscription payment route is bank transfer with Finance-reviewed proof. Read-only inspection of the exact functions confirms the current proof route: `submit_service_bank_transfer` creates a SchoolPro subscription proof, `review_direct_bank_transfer` delegates to `private.review_school_subscription_transfer`, and that function immediately activates the normal full-price annual purchase/renewal after verification. This is not upgrade-aware and has no unused-term credit; preserve the ordinary renewal branch and add a separate upgrade branch.
- The correction register was updated with these concrete gaps in commit `1c492b3dadb2a8c501defec52a06e79e824a1ee6`. The approved credit policy remains proportional unused annual value. No production migration, subscription/payment change, merge or Render deployment occurred.
- Next implementation boundary: define a separate school upgrade-request record and audited state machine spanning request, IHLink approval/rejection, outstanding-balance invoice, payment-proof verification, and atomic activation. Include duplicate-request protection, stale-price/current-term snapshot protection, idempotent payment confirmation, and no entitlement increase before verified payment. Keep this in the Stage A–B correction pass; do not implement Stage C result workflows.


## 2026-11-04 — Annual upgrade workflow specification and handover

- Created `docs/database-migration/SCHOOLPRO-ANNUAL-UPGRADE-WORKFLOW.md` (commit `f00a8aaa57e1348edae18f85d3487c9277bd49f7`) as the implementation specification for the school-initiated annual upgrade flow.
- Important correction to the preceding read-only note: the existing SchoolPro subscription receipt integration is present and verified. The SchoolPro page uses the generic direct-transfer upload path; `submit_service_bank_transfer` creates a `schoolpro_subscription` proof; `review_direct_bank_transfer` delegates to `private.review_school_subscription_transfer`; Finance verification then settles the proof and activates the ordinary full-price annual subscription. The existing path is therefore not missing. It is **not upgrade-aware** and does not calculate proportional unused-term credit.
- The normal renewal path must remain intact. The upgrade path needs a dedicated request record and immutable quote snapshot, higher-tier validation, proportional unused-term credit, IHLink review/rejection, a linked invoice for the net outstanding balance, and an upgrade-specific branch in the existing verified-payment finalizer.
- Specification covers the quote formula and UTC boundaries, NGN rounding, stale snapshot/price handling, state machine, RLS and RPC boundaries, school-facing quote/status UI, Central Admin review queue, atomic/idempotent activation, manual override separation, and disposable regression/security tests.
- The correction register now links the specification and corrects the earlier statement about receipt integration (commit `d39c77351d3efdeeeadab3b7e1a95444a7b84385`).
- This turn was documentation and read-only inspection only. No production database schema/function/row, subscription, price, payment or school operational data changed. No migration was created or applied; no PR was merged and no Render deployment was triggered.
- **Next implementation step:** build the dedicated upgrade-request table/RLS/RPCs and the upgrade-aware branch of `private.review_school_subscription_transfer` as a forward-only migration on this correction branch, then implement the SchoolPro request/quote view and Central Admin upgrade queue. Test only with disposable fixtures; do not create production workspaces. Keep Stage C deferred.


## Exact-head validation snapshot — 2026-11-04

- Validation-triggering commit after the specification/register updates: `74bda5b28bffe1c5728eaccdd0b121a1492af14c`. PR #116 remains open and unmerged: https://github.com/Hassan-625/IHLink-SchoolPro/pull/116.
- SchoolPro CI run #2461 (`41847574639`) was queued at the last check. Payment-page validation run #2187 (`41847574643`) had moved to in progress; neither result was yet confirmed successful.
- A subsequent handover-only documentation commit (`ee5b25d5368e87330f1f3835400aa1b78a4e5f42`) returned no associated workflow runs. Therefore #2461/#2187 are not verified as checks for that final documentation head. Recheck CI against the current PR head before any merge decision.
- Do not merge, apply the correction migration, or deploy to Render until exact-head validations complete successfully and remaining release blockers are resolved.


## 2026-11-04 — Upgrade workflow database contract recheck

- Rechecked the live Supabase schema and exact production function definitions read-only before implementing the upgrade migration.
- Confirmed the annual catalogue currently exposes exactly Starter ₦50,000, Professional ₦100,000 and Enterprise ₦150,000; the subscription catalogue has no active Premium entry. Keep the upgrade tier ordering explicit as Starter < Professional < Enterprise; do not infer ordering from display names or expose the legacy Premium entitlement as a purchasable target.
- Confirmed `schoolpro_subscriptions` already stores the necessary current-term fields: tier, billing_cycle, paid amount, status, starts_at, renews_at and managed_by_ihlink. The existing paid amount, not the current catalogue price, is the proration base.
- Confirmed `schoolpro_subscription_intents` accepts only `invoice_kind IN ('subscription','demo')`, and subscription invoices must have a positive amount. The upgrade invoice can retain `invoice_kind='subscription'` while adding a dedicated unique `upgrade_request_id` link; the request table will hold the upgrade-only quote and lifecycle state. Do not introduce a zero/negative invoice or repurpose the demo invoice kind.
- Confirmed school billing authorization can use the existing `private.has_school_access(school_id, ARRAY['proprietor','administrator','bursar']::school_member_role[])` helper, which also recognizes the school owner and active platform admins. IHLink review continues to use the existing active-account and Super Admin/Finance checks.
- Re-read `private.review_school_subscription_transfer(uuid,text,text)`. Its ordinary annual purchase/renewal branch currently activates immediately after Finance approval, preserves an existing renewal date by extending it one year, and keeps the original start date. The upgrade branch must be separate: activate only a linked approved upgrade request after exact-balance verification, start the new annual term at the verification instant, and set renewal one year later. Leave the ordinary branch unchanged.
- Additional payment-review hardening required for the upgrade branch: recheck that the receiving bank account is still active at verification time (the existing verifier currently checks existence but not its active flag); enforce the agreed bank-reference replay scope; lock and revalidate the current subscription and target catalogue snapshot; and make request, invoice, payment, transfer proof, subscription and school-plan updates atomic and idempotent.
- This was a read-only schema/function inspection only. No production schema, rows, subscriptions, payments, catalogue prices, or workspaces were changed. No migration was created/applied, no PR was merged, and no Render deployment occurred.
- Implementation remains the next step. The available execution environment has no Supabase CLI installed and no checked-out repository, so the required `supabase migration new` workflow cannot yet be run here. Do not bypass this by inventing a migration file or applying SQL directly to production. Continue only when the migration-authoring environment is available; then create the forward-only migration, implement the isolated upgrade branch and RPCs, add disposable PostgreSQL regression/security tests, and update the SchoolPro and Central Admin interfaces. Stage C remains deferred.


## 2026-11-04 — Upgrade workflow exact-schema mapping

- Extended `docs/database-migration/SCHOOLPRO-ANNUAL-UPGRADE-WORKFLOW.md` with the exact live-schema column mapping for subscriptions, annual catalogue, subscription intents, bank-transfer submissions, receiving bank accounts, payment ledger and schools.
- Confirmed the existing intent constraints allow a positive annual subscription invoice and require any upgrade linkage to be additive: nullable unique `upgrade_request_id`, preserving `invoice_kind='subscription'` and leaving the ordinary renewal path intact.
- Confirmed the transfer proof binds `invoice_id`, `user_id`, amount, bank account, customer reference and customer-owned receipt path. The upgrade finalizer must validate all of these against the approved request and invoice.
- Added an explicit integrity rule: the existing transfer verifier's same-decision early return is not sufficient proof of successful upgrade settlement. The upgrade branch must verify the request, invoice and unique credited payment are already consistently paid before returning idempotently.
- Added consistent lock ordering and server-derived quote/tier/identity requirements to the specification. Receiving bank account must be locked and `is_active=true` at verification.
- No migration or function code has been written/applied. No production rows, subscriptions, payment records, catalogue values or workspaces were changed. No merge or deployment occurred.
- The remaining implementation depends on authoring and running the migration and regression tests against a disposable PostgreSQL environment. Do not use live production SQL as a substitute. Stage C remains deferred.


## 2026-11-04 — Stage A–B correction PR #116 merged

- User explicitly approved merging PR #116 after exact-head SchoolPro CI #2467 and payment-page validation #2193 both passed on head `c863831ca8c52028dd68093782816361730384ef`.
- PR #116 was squash-merged into `main` successfully. Merge commit: `04e18a260ee5ad5d3028a3414b91a54f41563147`. PR status: merged.
- The merged correction includes Games & Sports entitlement and registration selection, Game Master and judge navigation, standard-report access separated from the Enterprise Advanced Reports gate, annual plan pricing/feature display corrections, role-scoped dashboard data, specialist role landing routes, and Plans & Subscription navigation.
- Post-merge validation has started on the exact main merge commit: SchoolPro CI #2468 and payment-page validation #2194. At the last check both were still in progress. Tenant acceptance was skipped because no active school workspaces exist; no test school was created.
- Merge does not itself mean production rollout. No Supabase migration was applied and no Render deployment was triggered. Do not deploy until post-merge CI/payment validation completes and the remaining release blockers are reviewed.
- Remaining Stage A–B blockers include implementing the actual Enterprise Advanced Reports workspace before advertising it, completing the separate school-initiated annual upgrade workflow (proportional unused-term credit, IHLink approval, difference-only invoice, Finance-verified receipt and atomic activation), reconciling the entitlement and subscription catalogues, and closing the full role/dashboard matrix.
- Annual upgrade specification remains at `docs/database-migration/SCHOOLPRO-ANNUAL-UPGRADE-WORKFLOW.md`. Preserve the existing full-price annual purchase/renewal path; the upgrade workflow must be a separate branch and must not activate entitlements before verified payment.
- Stage C remains deferred. No Stage C score-entry, result calculation, review or publication implementation is authorized by this merge.

## 2026-11-04 — Post-merge Stage A–B validation and upgrade branch

- Post-merge SchoolPro CI run #2468 (41851796251) completed successfully on merge commit 04e18a260ee5ad5d3028a3414b91a54f41563147. All executed jobs passed, including frontend/typecheck/build validation, local Supabase receipt-storage isolation, payment-review RLS/concurrency, academic calendar, progression subject requirements, section leadership, Form Master attendance, subject assignment guard, houses/House Master allocation, graduation certificates, result-verification exposure, public-admission abuse controls, result-PIN rate limiting, and tenant-integrity integration.
- The live tenant-acceptance job was skipped because no active SchoolPro workspaces exist. No test school/workspace or operational records were created.
- Post-merge payment-page validation #2194 (41851796252) completed successfully.
- Created isolated implementation branch feat/schoolpro-annual-upgrade-workflow from the verified merge commit. No application code or SQL migration has yet been added to this branch.
- No production Supabase migration, schema/data write, subscription/payment change, Render deployment, or Stage C implementation occurred.
- Next: author the forward-only annual-upgrade migration and disposable PostgreSQL regression/security tests on this branch, then implement the SchoolPro upgrade request/quote interface and Central Admin review queue. Preserve the ordinary annual purchase/renewal path, the approved proportional unused-term credit policy, IHLink approval, difference-only invoice, and Finance-verified atomic activation. Stage C remains deferred.


## 2026-11-04 annual upgrade implementation — read-only payment-path verification

**Status:** Implementation not yet started. This step performed read-only production function inspection and documented concrete safety gaps. No production DDL/DML, migration application, subscription/payment mutation, merge, or Render deployment occurred.

### Existing RPC behaviour confirmed from live function definitions
- `public.prepare_schoolpro_bank_subscription(uuid,uuid)` creates/reuses a pending full-price annual bank-transfer intent. It checks the school owner or proprietor/administrator/bursar membership and an active annual catalogue price. It is the ordinary purchase/renewal entry point and must remain intact.
- `public.submit_service_bank_transfer(...)` validates a pending SchoolPro bank-transfer intent, exact amount, customer-owned receipt object, active receiving account at submission time, and duplicate pending/settled proof for that invoice.
- `public.review_direct_bank_transfer(uuid,text,text)` delegates `schoolpro_subscription` submissions to `private.review_school_subscription_transfer`.
- `private.review_school_subscription_transfer(uuid,text,text)` currently activates the plan as part of ordinary Finance approval, marks the intent paid, inserts a credited payment, and updates `schoolpro_schools.plan`. It is not upgrade-aware.

### Exact settlement gaps to close in the upgrade-only branch
1. The existing same-decision early return checks only the transfer status. Upgrade idempotency must additionally prove that the linked request is `paid`, the invoice is `paid`, and exactly one credited payment exists for the request/invoice before returning success.
2. The existing finalizer locks a receiving bank account but does not require `is_active=true` at verification. The upgrade branch must require an active account at settlement.
3. Existing duplicate-reference detection is scoped to the same bank account. The upgrade branch must reject a normalized duplicate reference across the agreed global reconciliation scope, while retaining bank-account context.
4. The existing ordinary purchase/renewal branch must retain its current pricing, renewal-date, payment, and audit semantics; do not route it through the upgrade quote logic.
5. School billing authorization must be explicit: owner or proprietor/administrator/bursar. Do not accidentally inherit the broader default role list of `private.has_school_access`, whose default includes teacher/accountant and whose helper also permits platform administrators.

### Implementation controls
- Continue on `feat/schoolpro-annual-upgrade-workflow`, based on Stage A–B merge commit `04e18a260ee5ad5d3028a3414b91a54f41563147`.
- Author migration and regression tests only; do not apply the migration to the shared production Supabase project.
- Before migration authoring, use the repository's Supabase CLI workflow to create the migration file. The current Supabase CLI v3 release (2026-11-02) changes database commands to local-by-default and requires explicit confirmation for hosted changes; any future hosted operation must be treated as a separately approved action.
- Security-definer RPCs must pin an empty search_path, schema-qualify all relations, and explicitly revoke/grant EXECUTE to intended roles. RLS must be enabled on the exposed request table, and direct client writes to quote/review/payment/activation fields must remain unavailable.
- Next implementation gate: inspect the exact repository migration/test harness and the current annual subscription UI + Central Admin invoice workbench; then author a forward-only migration and disposable PostgreSQL tests covering quote calculation, stale snapshots, access control, proof matching, active bank account, global reference replay, atomic settlement, and idempotency. Run the existing ordinary annual purchase/renewal regression before proposing a PR.

### Supabase documentation check
- Reviewed current Supabase database-function security guidance: prefer invoker; where definer is required, use `search_path = ''`, schema-qualify relations, and narrow EXECUTE grants.
- Reviewed current RLS/API guidance: exposed tables require RLS, and function EXECUTE privileges must be scoped separately because RLS does not protect function calls.
- Reviewed the 2026-11-02 Supabase CLI v3 breaking-change notice; local-by-default database commands and hosted confirmation requirements are relevant to release procedure.


### Annual-upgrade source/UI mapping follow-up — 2026-11-04
- Read-only source inspection confirmed `src/pages/schoolpro/SchoolProSubscription.tsx` currently offers only the ordinary `prepare_schoolpro_bank_subscription` purchase/renewal path and shared receipt upload; there is no upgrade quote/request/review state UI yet. The upgrade action must be separate and must never call the ordinary purchase RPC.
- `src/pages/schoolpro/SchoolProPricing.tsx` is informational and must not calculate authoritative upgrade quotes.
- Existing Node assertion scripts and disposable PostgreSQL tests are the repository's regression convention.
- Updated `docs/database-migration/SCHOOLPRO-ANNUAL-UPGRADE-WORKFLOW.md` with these source integration points, the current migration-ledger boundary, and the local CLI/test requirement (commit `27856f50f0e276392f193d5b95720f910cc0a110`).
- Environment limitation: GitHub/Supabase MCP is available, but no checked-out repository shell is exposed here to run `supabase migration new`, disposable PostgreSQL, or npm tests. Do not bypass that workflow by fabricating a migration blob. Implementation remains pending in the supported repository CLI/test environment; no migration or production change has been made.


### Annual-upgrade schema/RLS verification — 2026-11-04
- Read-only Supabase catalog inspection confirmed the current RLS boundary: subscription intents and payments are readable by scoped school roles/payer and IHLink Finance/super-admin; no direct client write policies were returned. Subscription writes remain super-admin-only at table-policy level. Upgrade implementation must preserve RPC-only writes and atomic settlement.
- Confirmed two existing partial unique indexes enforcing one pending subscription invoice per school. Upgrade invoices must respect this invariant; create them only after IHLink approval and after resolving any other pending school invoice. Refresh the quote at approval.
- Confirmed the payment ledger currently has unique reference/transaction_ref but no typed upgrade-request FK. The migration should add typed request linkage and a unique credited-payment-per-request guarantee rather than relying only on JSON metadata.
- Confirmed existing catalogue SELECT policy overlap (including an authenticated `true` policy); deliberately leave this unrelated drift untouched in the upgrade migration.
- Updated `docs/database-migration/SCHOOLPRO-ANNUAL-UPGRADE-WORKFLOW.md` with these verified schema/RLS constraints (commit `ecf35fe82f663e64a1aa4cd8665fdfc4fc944d6b`).
- All checks were catalog SELECTs only. No live data writes, DDL, migration application, or deployment occurred.

## 2026-11-04 annual-upgrade workflow continuation

- Re-read the live SchoolPro subscription page and the annual-upgrade specification on `feat/schoolpro-annual-upgrade-workflow`. The page still exposes only the ordinary `prepare_schoolpro_bank_subscription` purchase/renewal path and shared receipt uploader; no upgrade request UI or request-status panel has been implemented.
- Reviewed the documented Central Admin integration requirements. The intended queue remains separate from onboarding and from the privileged `control_center_activate_schoolpro` manual override. Code search in the connected Central Admin repository did not return the previously identified component names, so no Central Admin source changes are claimed; exact repository paths must be confirmed in its supported CLI environment.
- Corrected a schema-contract inconsistency in `docs/database-migration/SCHOOLPRO-ANNUAL-UPGRADE-WORKFLOW.md`: the payment ledger must use a typed nullable `upgrade_request_id` FK plus a partial uniqueness constraint for a credited payment. `provider_payload` is diagnostic metadata only, not the authoritative relationship/idempotency mechanism. Specification commit: `d339787738045766f8488534cd4ce319f4f99030`.
- No application code, SQL migration, database write, merge, or deployment was performed. The repository CLI/disposable-PostgreSQL environment is still unavailable through the current connector set. Continue by opening the repository in its supported CLI environment, implementing migration and regression tests locally, and separately inspecting Central Admin source before proposing a PR.

## 2026-11-04 Central Admin integration inspection

- Inspected the connected `Hassan-625/IHLink-Admin` repository directly (default branch `main`) rather than relying on earlier unsuccessful code-search results. Confirmed the actual integration files: `src/pages/admin/AdminSchoolProSubscriptions.tsx`, `src/components/InvoiceWorkbench.tsx`, `src/pages/admin/DirectTransferReview.tsx`, `src/App.tsx`, `src/pages/admin/adminShared.tsx`, `src/lib/adminNavigationPermissions.ts`, and `src/components/ProtectedRoute.tsx`.
- Confirmed `/admin/subscriptions` is the existing Super Admin-only manual plan activation page and calls `control_center_activate_schoolpro`; it must remain a separate reason-required, audited override.
- Confirmed `InvoiceWorkbench` already handles SchoolPro subscription intents and pending transfer proofs, then invokes `review_direct_bank_transfer`. The upgrade invoice should reuse this established Finance proof path; the upgrade-specific private finalizer branch must enforce request linkage and atomic activation. `DirectTransferReview` also calls the same RPC, so server-side finalization must be correct regardless of which existing review UI initiates it.
- Specified the new review route as `/admin/subscriptions/upgrades`, using the normal admin Guard so Finance and Super Admin can enter. Existing `canOpenAdminPath` classifies the `subscriptions` segment as Finance-only for non-super-admin roles; the existing `/admin/subscriptions` route remains Super Admin-only. Server-side RPC checks must independently restrict decisions to active Finance/Super Admin accounts.
- Added the Central Admin source integration map and delivery requirements to `SCHOOLPRO-ANNUAL-UPGRADE-WORKFLOW.md`. Specification commit: `8f8cd14774d35241fb0e5e78413e29c7106d365e`.
- Inspection only: no Central Admin code, SchoolPro application code, SQL migration, production schema/data, merge, or deployment was changed.

## Annual SchoolPro Subscription Upgrade Workflow — 2026-11-05

- Branch: `feat/schoolpro-annual-upgrade-workflow`
- Migration: `20261105100048_schoolpro_annual_upgrade_workflow.sql`
- Scope: annual tier upgrades, immutable prorated quote snapshots, IHLink Finance approval, bank-transfer invoice settlement, payment ledger, cancellation and stale-quote protection.
- Production migration status: NOT APPLIED.
- Disposable PostgreSQL migration execution: PASS.
- Disposable PostgreSQL lifecycle: PASS — request, prorated credit, approval, invoice, Finance settlement, payment ledger and repeat-settlement idempotency.
- Build: PASS.
- Typecheck: PASS.
- Stage A/B corrections: PASS.
- SQL parser: PASS.
- Negative-path integration: PASS — rejection without invoice, stale-quote protection, pending-request cancellation, approved-request/invoice cancellation.
- Duplicate bank-reference protection: PASS — case-insensitive and whitespace-normalized duplicate rejected without changing billing state.
- Complete disposable PostgreSQL integration fixture: PASS.
- Final production build: PASS (existing large-chunk advisory only).
- Final TypeScript typecheck: PASS.
- Final `git diff --check`: PASS.
- No production workspace or subscription records were created or modified.


## SchoolPro dashboard access and Super Admin workspace selection — 2026-11-05

- PR #119: `fix/schoolpro-pending-subscription-workspace-access` was merged into `main` on 2026-11-05 (squash commit `551d33ed6152dd0d900f704123f01ba02b464fa1`). Pending-payment schools can open the restricted core workspace while paid-plan entitlements remain independently gated. SchoolPro CI and payment-page validation both passed.
- Follow-up branch: `fix/schoolpro-super-admin-workspace-persistence`; PR #120 has been retargeted to `main` after PR #119 merged.
- Updated `SchoolProLiveDashboard` so the platform Super Admin's selected school is saved in `ihlink_schoolpro_admin_school`, restored on dashboard load, and broadcast through the existing `ihlink:school-refresh` event. The shared `useSchoolProContext` already resolves this key on subsequent routes and validates the selected school against `schoolpro_schools`; no new cross-tenant membership or ownership grant is introduced.
- Scope is limited to persistent workspace selection. Sports dashboard and House assignment/student visibility work, plus plan-versus-role UI indicators, remain outstanding.
- No SQL migration, production Supabase change, test workspace, or deployment was performed. PR #120 was merged into `main` on 2026-11-05 (squash commit `f70575d1351bf5925f8ede86d07c0e3ef1745e67`).


## SchoolPro Super Admin selector and House Master roster — 2026-11-05

- Working branch: `fix/schoolpro-house-master-and-super-admin-selector`, based on the merged `main` containing PRs #119 and #120.
- Super Admin selector finding: `DashboardLayout` rendered `SchoolSessionBar` and replaced all page children with the session-required message whenever no working session existed. This hid the Live Workspace school selector because it is rendered inside `SchoolProLiveDashboard`.
- Frontend correction on this branch: the Super Admin Live Workspace renders its school selector before the academic-session picker and is not blocked by the missing session. The selected school still resolves through the existing `ihlink_schoolpro_admin_school` context mechanism; no new membership, ownership, or tenant bypass is introduced.
- House Master frontend groundwork: added `/schoolpro/house-dashboard`, a teacher navigation entry, and a read-only roster component calling `schoolpro_house_master_roster`. The House Master route does not require a working academic session. The existing `/schoolpro/games` Game Master management dashboard remains unchanged.
- Verified production schema read-only: house assignments use `ended_at IS NULL`; current student-house allocation uses `effective_to IS NULL`; the relevant tables expose `school_id`, student name/admission/class fields, and the active assignment keys needed for a narrow roster.
- Migration and regression coverage are implemented. The migration is committed as `ed15018`; it was applied only to the isolated review database. The House Master security regression passed, including same-school roster access and rejection of unauthorized access.
- Production status: no DDL or data writes were made to Supabase production for this correction; no Render deployment was made. Apply the reviewed migration to the existing production project only as a separately approved rollout step.


## 2026-11-06 — Super Admin selector and House Master roster correction

**Branch:** `fix/schoolpro-house-master-and-super-admin-selector`  
**Base:** latest `main` after PRs #119 and #120 were merged.

- The Super Admin proprietor-dashboard content is rendered before the academic-session prompt so the school selector remains visible even when no working session is selected. The session gate is not globally bypassed.
- The House Master dashboard route and teacher navigation entry are present. It is read-only and calls `public.schoolpro_house_master_roster(p_school)`.
- Existing Games dashboard remains the management surface for Game Masters; no duplicate sports dashboard was introduced.
- Generated migration filename with the Supabase CLI as required: `supabase/migrations/20261106085018_schoolpro_house_master_roster.sql`.
- Added a private, narrowly scoped `SECURITY DEFINER` roster helper and authenticated-only public `SECURITY INVOKER` RPC. The helper checks the active account, exact school membership, teaching role, active appointment and current active student-house history; it returns only house/student/class roster fields. General student RLS was not modified.
- Added a disposable PostgreSQL fixture, `tests/security/house-master-roster-regression.sql`, and a dedicated GitHub Actions workflow. The regression asserts function security mode, search-path pinning, execute grants and return-column contract, then checks positive same-school roster access and rejects another school's user, staff without an appointment, inactive students, cross-school student references and historical assignments.
- Production schema was inspected read-only to confirm the relevant columns and existing House Master policies. No production DDL/DML was executed. The migration was applied only to the isolated review database.
- No test workspaces or fabricated student records were created.
- **Completed:** isolated PostgreSQL House Master security regression passed on 2026-11-06. Fixture rows were rolled back. No production DDL/DML or test workspaces were created.

### Super Admin workspace selector correction — 2026-11-06

- Removed automatic selection of the first SchoolPro workspace when a Super Admin has no saved school selection.
- Added an explicit workspace-selection screen and distinguished an empty workspace list from an unselected workspace.
- Preserved selection updates through `ihlink:school-refresh` so the shared SchoolPro context follows the selected school.
- Browser verification confirmed that the workspace dropdown now works.
- Frontend-only correction; no database schema changes or production data modifications.

### CI fixture corrections — 2026-11-06

- Completed the disposable House Master PostgreSQL fixture with the minimal Auth users, profiles, school, and default-house structures required by the regression. Synthetic house rows are seeded only inside the disposable test transaction.
- Updated the local receipt-storage integration harness to allocate distinct available ports for PostgreSQL and Supabase Inbucket SMTP/POP3 services, avoiding collisions with ports already occupied by hosted CI runners.
- These changes affect isolated test infrastructure only; no production schema, records, Supabase project, or Render deployment was changed.


### Supabase CLI v3 receipt-storage harness compatibility — 2026-11-06

- Updated the isolated receipt-storage test's generated Supabase config from the removed `[inbucket]` section to `[local_smtp]`, retaining the dynamically allocated web, SMTP, and POP3 ports.
- The failure was a Supabase CLI v3 config-breaking change, not a Storage policy failure. The test continues to start an isolated local stack and does not link to or contact the production Supabase project.

## 2026-11-07 — Stage C0 workspace deletion inventory (read-only)

- Added `docs/roadmap/STAGE-C0-WORKSPACE-DELETION-INVENTORY.md` on `feat/schoolpro-stage-c0-workspace-corrections` (commit `5b258d867c166e64d58085ba93a5b93f9527458a`).
- Read-only inspection of Supabase project `lnqsroyiybutkfngbyge` found two SchoolPro school rows, both currently marked active. This is a schema/status observation only; neither workspace is selected for deletion and no deletion was authorized or performed.
- The live FK catalog identified direct school references requiring special treatment rather than blind cascade: `ihlink_email_queue`, `schoolpro_custom_requests`, `schoolpro_demo_requests`, `schoolpro_document_issue_events`, `schoolpro_enrollment_history`, `schoolpro_onboarding_requests`, `schoolpro_result_events`, `schoolpro_transcript_issues`, and `schoolpro_transcript_settings`.
- Read-only Storage inventory found 95 objects across SchoolPro document-output, document-template, invoice-template, and result-output buckets. UUID path prefixes are not sufficient proof of tenant ownership; unclassified/shared objects must remain untouched. Storage deletion must use the supported Storage API, never direct SQL against `storage.objects`.
- The implementation must retain global profiles/Auth users, reusable role/permission definitions, global/default templates, unrelated tenants, DataSub/IHLink data, external payment ledger rows, and required financial/legal/audit evidence. School-scoped subscription/payment records and school audit logs must not be lost merely because their FK currently cascades.
- No production schema, rows, Storage objects, subscriptions, payments, or workspaces were changed. No migration was created/applied, no test workspace was created, no PR was merged, and no Render deployment occurred.
- Next bounded task: finish the full FK and record-retention matrix, resolve the exact ownership map for Storage objects, then design the request/approval/execution state machine and disposable PostgreSQL regression fixture. Do not apply production DDL/DML or delete any live workspace.


## Current production workspace state recheck — 2026-11-07

**Read-only evidence only; no rows or schema were changed.** A direct query of `public.schoolpro_schools` returned these two active rows:

| School | School ID | Created at (UTC) | Status |
|---|---|---|---|
| IHLINK Academy | `eb601205-cffd-420d-97d0-7d5ca081628a` | 2026-11-04 13:26:29 | active |
| HA ACADEMY | `ac7ac8a8-5035-4e39-8868-cad54add84a6` | 2026-11-05 13:37:52 | active |

These IDs do not match the two historical workspace IDs listed in the 2026-10-28 cleanup section. On 2026-11-07, the user explicitly confirmed that **both IHLINK Academy and HA ACADEMY must be retained** because they are actively being used for verification. Treat both as protected active workspaces. Do not submit, approve, archive, delete, or otherwise mutate either workspace as part of C0 lifecycle work unless the user gives separate, explicit authorization. The C0 deletion workflow and its tests must ensure these two workspaces are excluded from deletion by default.


## Stage C0 owner-managed record lifecycle — 2026-11-07

- Inspected the current student, class, staff and guardian management pages and the production FK catalog using read-only queries only.
- Confirmed student status already supports `active`, `graduated` and `withdrawn`; student exit uses the audited `schoolpro_transfer_student_out` RPC and retains enrollment history. The enrolment UI has no student hard-delete handler.
- Confirmed guardian links already support `active` and `suspended`. Updated `SchoolProParents.tsx` so authorised school managers suspend or restore a guardian link using a school-scoped update; removed the hard-delete action. The global guardian profile and Auth identity are not touched.
- Added regression assertions in `scripts/test-schoolpro-student-family-records.mjs` for scoped guardian status transitions, suspend/restore behaviour and absence of guardian-link hard deletion.
- Production schema inspection found student FKs with destructive `ON DELETE CASCADE` relationships (including attendance, results, invoices, fee records, health/discipline and generated outputs), so student hard deletion is prohibited. Class deletion also cascades to class-linked attendance, assignments, class-result submissions, CBT eligibility and timetable rows. Staff membership deletion cascades to operational records such as payroll, leave requests, board memberships, permissions and section leadership; competition judge and House Master references restrict deletion.
- Therefore class and staff hard-delete controls are not safe. They remain explicitly blocked from lifecycle implementation until a reviewed archive/deactivation schema and dependent-record behaviour are designed. No production schema or data was changed by these inspections.
- The two active verification workspaces, IHLINK Academy (`eb601205-cffd-420d-97d0-7d5ca081628a`) and HA ACADEMY (`ac7ac8a8-5035-4e39-8868-cad54add84a6`), remain protected from all lifecycle actions without separate explicit approval.
- Code and test changes are on `feat/schoolpro-stage-c0-workspace-corrections`; no PR merge, Render deployment, or production migration was performed.

- Follow-up safety correction: removed the class hard-delete handler/button and the staff-membership hard-delete handler/button from their management pages. Both now display “Archive pending” rather than offering destructive deletion. Extended the focused regression script to reject class/staff hard-delete handlers and retain the student non-delete and guardian suspend/restore checks.

- Additional read-only security finding (2026-11-07): production RLS still has authenticated DELETE policies on both `schoolpro_classes` and `schoolpro_members`, including a Super Admin all-operations policy. The earlier UI removal is not a backend security boundary. Production `schoolpro_classes` and `schoolpro_members` have no archive/status columns. `private.has_school_access(uuid, school_member_role[])` currently accepts any matching membership; `private.schoolpro_can_read_class(uuid)` also checks memberships directly. Therefore staff suspension requires coordinated helper, policy and assignment/write-path changes; class archive requires all active selectors and class-linked write paths to reject archived classes. These requirements are documented in `docs/roadmap/STAGE-C0-WORKSPACE-CORRECTIONS.md`. No production schema/data change was made. Do not treat archive lifecycle as complete or restore archive controls until the complete backend migration and regression suite are ready.

- Completed the class/staff lifecycle dependency inventory from the read-only production catalog. Class references span assignments, attendance, CBT eligibility/tests, subject assignments, timetable entries, class-result submissions, enrollment history, calendar events, lesson notes, question bank and student current-class references. Staff references span board membership, competition judges, House Master assignments, leave, library loans, member permissions, payroll, section leadership, subject assignments and Form Master links. The C0 roadmap now classifies operational versus potentially historical references and requires coordinated archive RPCs, RLS DELETE-policy removal, active-membership helper updates, assignment guards, selector filtering and SQL regression tests as one unit. No production schema/data change was made.

- Extended the read-only production inventory to the authorization call graph. `private.has_school_access` currently has no membership-active predicate; `private.schoolpro_can_read_class` and `private.schoolpro_member_leads_class` contain direct membership checks. Related class/member RPCs include staff directory, coordinator classes, House Master roster/eligibility, lesson author/leader scope, section leadership, Form Master assignment, board roles, teacher allocation, competition judges, library loans and result/promotion operations. Production class/member RLS also has overlapping permissive SELECT policies, school-leader DELETE policies, and Super Admin `FOR ALL` policies; authenticated table grants include DELETE. The C0 migration must replace Super Admin ALL policies with explicit operation policies and revoke DELETE table privileges as well as removing DELETE policies. Details are in the C0 roadmap. Commit: `45a89f7fb6b7a5560bc23c98dc13dbc60a93d061`.

- Confirmed exact live class/member schemas and privilege state on 2026-11-07. Classes have no archive columns; members have no active/suspended columns. Both tables currently grant DELETE to anon and authenticated, so C0 must revoke DELETE at the table privilege layer as well as drop DELETE RLS policies. Roadmap sequencing is now explicit: schema/audit foundation; RPC-only lifecycle transitions; authorization/RLS changes; operational eligibility guards; then UI and regression tests. Existing rows must backfill to active/unarchived, and historical records must remain intact. No migration was added or applied in this step. Roadmap commit: `a419cfdc3a1c9ffb2e41f0652d1c3bacf1a85f1b`.


- Extended the read-only deployed-function audit on 2026-11-07. Additional direct membership-derived authorization paths include `schoolpro_is_house_master`, `schoolpro_validate_house_master`, `schoolpro_lesson_author_scope`, `schoolpro_lesson_leader`, `schoolpro_teacher_allocation_visible`, `schoolpro_cached_access_schools`, `schoolpro_cached_staff_schools`, `schoolpro_cached_readable_students`, `schoolpro_cached_result_reader_keys`, `schoolpro_can_read_student`, `enforce_schoolpro_tenant_relations` and `schoolpro_archive_progression`. The migration must update cached and uncached authorization paths together, reject inactive members for new operational assignments, preserve owner/admin and student/guardian historic-read paths, and review class archival against progression/enrolment evidence. This is a dependency audit only; no production writes were performed. Roadmap detail committed as `ae98ab185f86d3b3023f874117a45e96dec2e7f9`.


- Completed a second deployed-function and RLS catalog pass on 2026-11-07. The C0 roadmap now enumerates additional direct membership/class references across read-scope caches, staff directory/coordinator scopes, House Master/section/Form Master/board assignments, lesson/result authority, attendance/CBT validation, progression and historical enrolment. It also records the exact permissive policies on `schoolpro_classes` and `schoolpro_members`, including their Super Admin `FOR ALL` policies and direct DELETE policies. The coordinated migration must replace ALL with explicit SELECT/INSERT/UPDATE policies, remove all DELETE policies and revoke DELETE grants from `anon` and `authenticated`. The policy and function names plus required classification are recorded in `docs/roadmap/STAGE-C0-WORKSPACE-CORRECTIONS.md`. Commit: `2606763`. No production schema or data was changed.


- Reviewed live lifecycle-table triggers on 2026-11-07. Classes are guarded by operational activation and immutable tenant ownership triggers. Staff memberships have proprietor-role protection plus role-change triggers that clear board membership, end House Master appointments and prune section leadership. Archive/suspension must preserve these invariants, add a final-proprietor suspension safeguard, explicitly end active operational appointments without deleting historic governance/payroll/leave evidence, and preserve trusted backend maintenance behavior. Details are recorded in the C0 roadmap; no production triggers or records were changed. Commit: `ec51629`.


- 2026-11-07: committed branch-only C0 lifecycle foundation migration `20261107130000_schoolpro_class_staff_lifecycle_foundation.sql` (commit `5f2c59c`). Adds class archive and school-member suspension metadata, consistency constraints/indexes, direct-client metadata guards, and audited tenant-scoped archive/restore and suspend/restore RPCs with row locks, reason validation and final-proprietor protection. This is **not** the complete lifecycle rollout: archive/read/write filtering, active-membership authorization updates, operational appointment handling, removal of direct DELETE policies/grants, and regression tests remain blockers. Do not expose lifecycle controls or mark C0 accepted yet. No production migration/data change, merge, or Render deploy occurred. Protected workspaces IHLINK Academy (`eb601205-cffd-420d-97d0-7d5ca081628a`) and HA ACADEMY (`ac7ac8a8-5035-4e39-8868-cad54add84a6`) remain untouched.


- 2026-11-07: post-foundation read-only authorization review found that deployed private.has_school_access(uuid, school_member_role[]) does not yet filter membership rows by lifecycle status, while the new archive/suspension RPCs rely on that helper. Once the foundation adds schoolpro_members.status, a suspended proprietor/administrator could still pass the management check unless the helper is updated. private.schoolpro_can_read_class, private.schoolpro_member_leads_class, House Master checks/validators, and all direct membership readers also need active-state predicates; preserve active owner and Super Admin paths plus historic student/guardian reads. Production still has no lifecycle metadata columns, confirming the branch foundation has not been applied. C0 remains blocked pending a coordinated follow-up migration, appointment cleanup, DELETE policy/grant removal, and regression coverage. No production mutation, merge, or Render deploy occurred.


- 2026-11-07: added branch-only follow-up migration `20261107143000_schoolpro_active_membership_authorization.sql` (commit `24a464d60a948d0bcb740fa88e738f3116d69d83`). After the lifecycle foundation, it requires active membership in the central school-access helper and core class-read, section-leader, House Master, and lesson authorization helpers, while retaining independent owner/Super Admin access and student/guardian historical reads. This is a partial dependency correction only: remaining direct membership readers/validators, suspension appointment cleanup, archived-class write blocking, DELETE policy/grant removal, explicit replacement of Super Admin ALL policies, and full SQL regression tests remain outstanding. Neither migration is approved for production application yet. No production mutation, merge, or Render deployment occurred.


- Follow-up review of live function privileges found authenticated EXECUTE grants on private helpers used directly by RLS policies. The initial C0 follow-up draft would have revoked these and broken policy evaluation; corrected the migration in commit `93fc97222e1d8d3790a791c0a448458c5a3a7db2` to preserve deployed grants. No production privileges were changed.


- 2026-11-07: added branch-only migration `20261107160000_schoolpro_active_staff_and_class_assignment_guards.sql` (commit `029acb9ede0fcad73f5c4eaae77f3c57ac7534f3`). Updates staff-directory/coordinator readers, teacher allocation visibility, Form Master and section-leader appointment RPCs, and class/subject assignment validators to require active staff and reject archived classes for new operational assignments. Existing academic/assignment history is retained; helper EXECUTE grants remain unchanged. Appointment termination on suspension, remaining membership consumers, DELETE policy/grant removal, broad Super Admin policy replacement, and full regression coverage remain outstanding. Branch only; no production changes.


- 2026-11-07 scope expansion: dedicated Staff Disciplinary workspace (warnings, investigations, performance actions, suspension/dismissal, staff response/appeal, restricted evidence and immutable history); improved Leave & Absence (planned leave vs retrospective/unexplained absence, staff self-service reason submission/update, HR decision notes and audit); and expanded Student Discipline case management (category/severity, reporter, student response, parent contact, follow-up and resolution). Code review confirms staff discipline is not a dedicated page, Leave is still the generic CRUD module without an own-request reason-update flow or reviewer notes, and student discipline only stores incident/action/status. These workflows are requirements only at this point; no disciplinary/absence schema or UI changes have been committed yet. Any suspension/dismissal must integrate with membership status and appointment termination before it can become an executable HR action.


- 2026-11-07: branch-only appointment lifecycle migrations committed. c987129d9e1ef9d74fbef37692a591b778bf8494 ends House Master, competition judge, board, section-leader and subject-teaching appointments on staff suspension; clears class Form Master pointers with audit evidence; preserves historical rows and does not auto-restore appointments after reactivation. ef44d1106bb491e34595936dc61e07495b768bdb updates core readers and assignment validators to ignore ended appointments and archived classes, and changes board/section appointment removal to end rows rather than delete them. These SQL files are untested and not applied to production. Staff UI currently needs to filter ended board/section/subject assignments; remaining membership consumers include leave/workflow validators and attendance/CBT/timetable/result write paths.


- Appointment history correction (2026-11-07): migration 20261107190000_schoolpro_staff_appointment_history.sql (commit b2fc3512321af3e1c3888bbf9a5645809b68ca80) adds immutable JSON snapshots for appointment assignment/end/reassignment/reappointment events, preserving prior board/section/subject/House Master/judge/Form Master details despite legacy unique keys that reuse current rows. Client writes to the history table are revoked; SELECT is scoped to leadership/HR or the affected staff member. Added scripts/test-schoolpro-lifecycle-appointment-contract.mjs and npm script test:schoolpro-lifecycle-appointments. It is a static source contract check and has not yet been run; it is not a substitute for SQL runtime/RLS regression in a disposable database.


- 2026-11-07: added branch-only migration `20261107200000_schoolpro_revoke_class_member_delete.sql` (commit `e6c592eeadcdd43294807cdf79f88115f7385d9f`). It drops the school-leader DELETE policies and broad Super Admin ALL policies on `schoolpro_classes` and `schoolpro_members`, replaces the Super Admin ALL policies with explicit SELECT/INSERT/UPDATE policies, and revokes API-role DELETE and TRUNCATE privileges. Production catalog inspection confirmed the exact policy names and existing DELETE/TRUNCATE grants before authoring. No production mutation occurred.
- Added `supabase/tests/schoolpro_class_member_delete_security.sql` (commit `d7055d9088bb0ab4be529f15df7d4cf0f13fe79e`) to assert no DELETE/TRUNCATE API grants, no DELETE or ALL RLS policies, and six explicit Super Admin operation policies. It has not been executed; a disposable PostgreSQL/Supabase test database is still required. The SQL file is a focused regression, not yet the complete lifecycle suite.
- Current production schema inspection confirms attendance, CBT, timetable, leave, results, and student-discipline objects remain on the pre-lifecycle schema (for example, production `schoolpro_members` has no `status` column and production `schoolpro_classes` has no `archived_at`). The lifecycle migrations are branch-only and must be tested as a complete ordered chain, not selectively applied to production.
- Outstanding: complete remaining direct membership readers and validators for attendance/CBT/timetable/leave/result; implement dedicated staff disciplinary, leave/absence and student discipline case-management UI plus audited backend workflows; add full SQL/RLS lifecycle regression coverage and execute it in an isolated disposable database. No production migrations, data changes, merge, or Render deployment occurred.

- 2026-11-07: C0 operational authorization follow-up added in **20261107210000_schoolpro_active_membership_operational_guards.sql** (latest commit **e13f2c1dccfb47b8715e0dad440133f4e14a6065**). It tightens attendance educator write policies to active Form Masters/leadership, rejects attendance for inactive/transferred pupils and archived classes, requires active student/class targets for new CBT eligibility, changes CBT author/manager helpers to active memberships, removes broad CBT plan-feature ALL access (retaining a SELECT-only plan-read policy), scopes timetable readers to active members and active teacher appointments while preserving family historical reads, requires active membership for new payroll/leave ownership, adds audited own-leave reason-update access, and routes result-lock authorization through active has_school_access. It is branch-only; no production migration was applied.
- 2026-11-07: added **20261107220000_schoolpro_staff_discipline_leave_workflows.sql** (latest commit **fdaafd83e3a0d3be484e7e049da0f216a7e5abe6**). This adds employment status (active, suspended, dismissed) with a guard preventing dismissal from being reversed through the ordinary suspension-restore path; staff disciplinary cases for verbal/written/final warnings, investigations, performance plans, suspension and dismissal; employee response and appeal submission/review; manager case closure; immutable case event snapshots; and dedicated leave/absence request metadata, immutable leave events, absence reporting without an initial reason, audited own-reason updates, HR review notes, and no direct leave/absence hard deletion. Suspension/dismissal calls the existing audited membership lifecycle transition; dismissal leaves the membership suspended and marks employment as dismissed. An accepted appeal does not automatically restore access or appointments; reinstatement must be a separate authorised workflow.
- 2026-11-07: added **20261107230000_schoolpro_student_discipline_case_management.sql** (latest commit **d13ef923284911c3840067319289b2706e9ee5f2**). It adds incident category/severity/location/time, student response, guardian-contact tracking, assigned follow-up staff/date/outcome, resolution metadata, immutable case event snapshots, and removes the broad manager ALL policy in favour of explicit SELECT/INSERT/UPDATE. Direct student-discipline DELETE/TRUNCATE is revoked.
- Frontend branch work: new SchoolProStaffDiscipline.tsx and SchoolProLeave.tsx pages/routes; teacher and school navigation now expose staff self-service case/leave routes; staff table distinguishes dismissed from suspended; SchoolProDiscipline.tsx now captures student incident category/severity/location, student response, guardian contact, assigned follow-up and resolution. These pages use the new audited RPCs or RLS-scoped manager updates. They depend on the ordered branch migrations and are not deployed.
- Regression additions: schoolpro_operational_membership_security.sql, schoolpro_c0_lifecycle_regression.sql, and scripts/test-schoolpro-c0-workspace-workflows.mjs. Added .github/workflows/schoolpro-c0-regression.yml to run typecheck/build/source contracts, start a disposable local Supabase, apply the complete migration chain and run the focused SQL regression files. The suite has **not yet been observed executing**; no pass is claimed. It must pass in CI or an isolated disposable database before C0 acceptance.
- Remaining direct membership consumer review is not complete. Continue with competition/judge operations, library loans, promotions/progression, result publication/review, staff access utilities and any remaining RPCs that query schoolpro_members without routing through active-membership helpers. Recheck all RLS permissive-policy OR paths, not just helper definitions.
- The workspace deletion inventory must retain the new restrictive dependencies: schoolpro_staff_disciplinary_cases, schoolpro_staff_disciplinary_events, schoolpro_leave_events, and schoolpro_discipline_events. Preserve employment and case history; do not cascade-delete them as ordinary operational rows.
- No production data/schema mutation, production migration, merge, or Render deployment occurred. The two verification workspaces remain protected and untouched.

- 2026-11-07 follow-up: migration **20261107235945_schoolpro_remaining_active_member_consumers.sql** (commit **1097247acc8053de633fc372c7d521b1fba076de**) closes additional direct membership paths in coordinator class lists, class staff directory, teacher allocation visibility, Form Master assignment, and both subject-assignment validators. Active members only; archived classes are excluded from current assignment/operational visibility.
- The central permission reader was corrected in commit **cba9889bdd2d6ec6b7f49c5dbfc7961e1b9ed79a** to preserve the existing role-to-permission matrix and only add active membership and active board-appointment checks. Do not replace the matrix wholesale or infer role permissions from the UI.
- Added regression assertions for these remaining readers/validators. The consolidated SQL suite still has not been observed executing successfully. The GitHub combined status currently shows only the unrelated blocked Vercel status; no C0 Actions run has been confirmed. The draft PR is **#122**; it is not merged and no production migration or Render deployment has occurred.

- 2026-11-07 disposable-database validation finding: CI passed Node setup, dependency installation, TypeScript, production build, C0 source contracts, appointment lifecycle source contracts, and Supabase CLI setup. Local Supabase startup then failed before C0 migrations or SQL tests ran: the first repository migration `20260916181940_configurable_school_assessments.sql` references `public.schoolpro_schools`, which is not created by any earlier checked-in migration.
- This is explained by the repository's explicit remote-sync boundary: `20260926114500_schoolpro_remote_migration_sync_ledger.sql` documents production migrations applied remotely and intentionally does not replay their DDL. The repo therefore has no complete empty-database bootstrap/schema snapshot. Do not "fix" this by skipping migrations, inserting dummy objects, marking historical migrations as applied on an empty database, or applying anything to production.
- Runtime SQL security/lifecycle regression remains BLOCKED until a sanitized, versioned schema baseline matching the remote-sync boundary is added to the repository or a separately disposable database can be initialized from a verified schema-only snapshot. This requires careful review; no production mutation is authorized. Current C0 run 42369636168 failed at local Supabase startup; SQL regression steps were skipped.

- Follow-up regression coverage added in commit **0aea0afadb0e3a53dbe33fd49ced8cec1b682346** and source-contract checks in **6e1445e1e28658019f9351298d14c0a04619bca6**. Coverage now explicitly asserts active-member and ended-appointment handling for House Master and section leadership readers/writers, board appointment history, cached school readers, and CBT authorization helpers. CI run **#55** again passed TypeScript, build, and both source-contract suites but failed at the same missing local baseline during Supabase startup; SQL tests were skipped.

- 2026-11-07 deeper migration-history inventory: the linked production project reports **518** applied migration records; the C0 branch contains **168** migration files. Comparing migration slugs after removing any filename timestamp prefix finds **132** local slugs represented remotely, **386** remote migration names without a corresponding local SQL file, and **36** local migration files without an exact remote slug match. This is not a safe basis for replaying the entire repository history into an empty database. The remote migration ledger and schema state are authoritative for production; do not repair migration history or mark migrations applied on production to make CI pass.
- The correct C0 runtime-test strategy is a **sanitized schema-only baseline** of the current production schema (no table rows, credentials, secrets or Storage objects), restored into a disposable local Supabase instance, followed by applying only the C0 migrations introduced after that baseline in timestamp order. This avoids replaying hundreds of missing historical/platform migrations and validates C0 against the actual pre-C0 schema shape. The repository currently has no such baseline artifact, and the available Supabase MCP cannot export a schema dump. Request an approved schema-only dump from the linked project's authorized CLI operator; no database password or service-role key should be shared in chat. Until the artifact is available, runtime migration and SQL regression execution remains blocked.

- Safe baseline acquisition command for the authorized operator (read-only export; do not use `--data-only` or `--role-only`): `supabase db dump --linked -f supabase/schema/schoolpro-c0-baseline.sql`. Supabase documents the default dump as schema-only (no table data or custom roles) and excludes managed schemas such as `auth`, `storage`, and extension-owned schemas. Review the output for any embedded literals before sharing; do not share DB passwords, access tokens, service-role keys or any data dump. Upload the reviewed SQL file here so it can be inspected and integrated into the disposable C0 test harness.

- 2026-11-07 C0 regression hardening: extended `scripts/test-schoolpro-c0-workspace-workflows.mjs` to assert the class/member DELETE/TRUNCATE revocation migration removes the four broad delete/full-access policies and that the focused SQL regression checks ACLs and RLS policy catalog state. Updated `.github/workflows/schoolpro-c0-regression.yml` to run the existing student/guardian/class/staff lifecycle source-contract suite alongside the C0 and appointment contracts. Commits: `f287acceb7654a4b876da680227b879922dd048f`, `6ec25c961ba3318d4773b0d4550ac6d793e9edd4`, `92b705f2180538fe1fc9fe3fbe39734c648170d0`. This is test-harness hardening only; it does not change production data or schema. The SQL runtime stage remains blocked by the missing verified baseline, and no test pass is claimed for this update.

- 2026-11-07 Leave & Absence usability improvement: added client-side search across staff name, leave type, request type, reason, HR note and date, plus status filtering and a visible filtered/total record count. Filtering is applied only after the existing role-scoped dataset is loaded; it does not broaden RLS or change database access. Added source-contract assertions for the controls and empty-filter state. Commits: `b3ff6f9bc3e7005afdac90260e3710fc2e0e35f9`, `cab3f55a07f6505ad61fd8a500c794c439b34919`. No production changes.

- 2026-11-07 Staff Disciplinary dashboard improvement: added case search across staff name, summary, investigation details, response, appeal/closure notes, action type and severity; added status and action-type filters; added authorised-view counts for open cases, appeals awaiting review and closed cases. Filtering operates only on the pre-existing role-scoped case collection and does not broaden database access. Added source-contract assertions for the new controls and metrics. Commits: `5fda8c2b647e90c87af8b2b9df1f796bc1d002eb`, `0ba0f7272401bdb8357127a3527e1dafa32abd9c`. No production changes.

- 2026-11-07 Student Discipline dashboard improvement: added search across student/class, incident description, location, intervention, student response, guardian-contact note and follow-up outcome; added status and incident-category filters; added scoped counts for open cases, cases with follow-up scheduled and resolved cases. Counts and filters respect the selected student filter and current academic session. Added source-contract assertions. Commits: `4f3768cc3f9c75a7f73c47a64c54dffbbf7f5a98`, `31746062b686f23dab29318f53f198f1e11ce82b`. No production changes.

- 2026-11-07 Leave & Absence review visibility: added authorised-view summary counts for requests awaiting review, approved requests and absence reports; added planned-leave vs absence-report filtering; displays absence-report and HR review timestamps; clarified the filtered/total count. Corrected literal escaped newline sequences in the page source while updating it. Added source-contract assertions. Commits: `e5117a2d1544524fc634e40ee4d307a520168aee`, `fb1f0bad8ed308bda2d9606d91ae85ae2d4de60b`, `6cb8e457d04f076dfd9ae47395e176b756ed4fb1`. No production changes.


- 2026-11-07 Staff Disciplinary runtime correction: moved the `memberNames` memo before the `visibleCases` memo. The previous declaration order referenced `memberNames` while its `const` binding was still in the temporal dead zone, which could prevent the dashboard from rendering. Also repaired literal escaped newline sequences in the C0 source-contract test file and added a regression assertion for the declaration order. This is a branch-only frontend/test correction; no production changes.


- 2026-11-07 Classes & Arms responsive layout: made the session/school/refresh toolbar wrap on narrow screens, set a deliberate minimum width for the full class grid inside its existing two-axis scroll region, and added a dedicated horizontal scroll wrapper plus minimum width for the selected-class student roster. This keeps all columns accessible on mobile without shrinking controls into unreadable widths. Added source-contract assertions. Branch-only UI/test change; no production data or schema changes.


- 2026-11-07 Staff dashboard responsive toolbar: made the workspace selector/refresh row wrap on narrow screens, constrained the selector to the available width, and labelled it for assistive technology. Preserved the existing keyboard-focusable horizontal table region and 920px minimum table width. Added source-contract assertions. Branch-only UI/test change; no production changes.


- 2026-11-07 Parents & Guardians responsive layout: workspace selector and refresh control now wrap on narrow screens; the two-column layout uses a shrink-safe `minmax(0,1fr)` content track; the links card/table container is shrink-safe; and the table has a keyboard-focusable, assistive-technology-labelled horizontal scroll region with a readable minimum width. Added C0 source-contract assertions. Branch-only UI/test change; no production changes.


- 2026-11-07 Houses, Games & Competitions responsive layout: made the house and event grids/cards shrink-safe, allowed House Master/standing rows and event titles to wrap, and added a keyboard-focusable horizontally scrollable competition results table with a readable minimum width and accessible label. Added C0 source-contract assertions. Branch-only UI/test change; no production changes.


- 2026-11-07 Students & Enrolment responsive layout and photo capture: made the workspace selector wrap, changed the enrolment form to a single-column mobile layout that expands to two columns, and added a keyboard-focusable horizontally scrollable student table. Added an optional student photograph field directly to the enrolment form (JPG/PNG/WebP, max 5 MB). After a student row is successfully created, the selected photo uploads to the existing school-scoped `school-result-templates` path (`<school_id>/student-photos/<student_id>.<ext>`) and `photo_storage_path` is saved against that exact student and school. If photo upload fails, the student enrolment remains saved and the user receives a clear warning; the existing post-enrolment photo control remains available. Added source-contract assertions. Branch-only UI/test change; no production data, storage objects, or schema changes.


- 2026-11-07 Optional enrolment photo guarantee and attendance responsiveness: added regression assertions proving student insertion occurs before the optional photo-upload branch, that upload is conditional on a selected file, and that the enrolment photo input is not required. Improved Daily Attendance filters to a responsive one/two/four-column grid and made the class register a keyboard-focusable horizontally scrollable table with a 760px minimum width and accessible label. Branch-only changes; no production data or Storage changes.


- 2026-11-07 Admissions responsiveness: application form now uses a shrink-safe one-column mobile/two-column tablet layout; applicant register remains scrollable within its bounded viewport, with a 900px table minimum width and non-wrapping decision actions to preserve usability on narrow screens. Added C0 source-contract regression assertions. Branch-only; no production records changed.


- 2026-11-07 C0 disposable regression baseline wiring: moved the existing schema-only snapshot without changing its blob content from `supabase/schoolpro-c0-baseline.sql` to `supabase/baselines/schoolpro-c0-baseline.sql` on `feat/schoolpro-stage-c0-workspace-corrections`. Updated `.github/workflows/schoolpro-c0-regression.yml` to avoid replaying the incomplete historical migration chain: CI starts disposable local Supabase, restores the baseline into a separate disposable database, applies only migration files newer than baseline cutoff `20261106164431` in filename order, then runs the three C0 SQL regression suites against that database. This is CI-only and does not connect to or modify the production Supabase project, production rows, Storage objects, Render deployment, or either retained verification workspace. The first workflow run must validate that the snapshot restores cleanly in the local Supabase PostgreSQL environment; no passing result is claimed until Actions reports success.


- 2026-11-07 C0 completion workstream expansion: implemented a dedicated `SchoolProAdvancedReports` page and replaced the generic `/schoolpro/reports` route. The Enterprise entitlement and reports permission remain enforced. The dashboard calls the existing class review-sheet RPC for selected class/term/session, calculates a weighted class subject average, subject averages and descriptive score-band distribution, supports student search, and exports Summary and Student Results worksheets to Excel. Added source-contract tests and included them in C0 CI.
- 2026-11-07 Class/staff lifecycle UI completion: the Classes page now loads `archived_at` and exposes reason-required archive/restore via `schoolpro_set_class_archive_state`; archived classes cannot receive new Form Master assignments and are filtered from new student enrolment. The Staff page exposes reason-required suspend/restore via `schoolpro_set_member_suspension_state`; dismissed staff are not offered the suspension restore control. Suspension ends active appointments and preserves immutable appointment history. Updated source contracts accordingly.
- 2026-11-07 Workspace removal lifecycle: added `20261107235950_schoolpro_workspace_deletion_lifecycle.sql`, `SchoolProWorkspaceDeletion`, and route/sidebar integration. A school Proprietor can request removal after entering a reason and exact school name; the requester can cancel while pending. A different platform Super Admin must approve/reject with a note; a third Super Admin must execute with exact school-name confirmation. Execution sets `schoolpro_schools.status='suspended'` and records a structured preflight/execution snapshot. This is an explicit **soft-deactivation**: student, staff, class, academic, financial, legal, audit and Storage records are retained. It performs no tenant-row cascade and no Storage deletion. Permanent purge is deliberately separate and requires retention review and explicit approval.
- 2026-11-07 Control Panel integration PR: `Hassan-625/IHLink-Admin` PR #70 adds a Super Admin-only read-only Staff Disciplinary Oversight page and a Workspace Removal Review queue. The latter calls only the audited review/execute RPCs, prevents requester self-review and prevents the approving reviewer from executing. Adds direct navigation, SchoolPro module links and source-contract tests. PR checks are pending; do not merge/deploy before validation and the corresponding Supabase migration.
- 2026-11-07 Universal table viewport: added global CSS for direct table containers to enforce bounded two-axis scrolling and preserve sticky headers; print media restores unbounded visible tables. Targeted responsive wrappers for Students, Admissions, Classes, Staff, Parents, Games and Attendance remain.
- 2026-11-07 Production migration safety review: the 14 C0 forward migrations are ordered after production migration `20261106164431`. Inspection found no migration-level hard-delete/truncate of production rows. DML occurrences in the migration files are function bodies, except a leave-request timestamp backfill limited to existing rows whose `request_type='absence_report'`; production currently has none of the new leave request columns, so the new default `planned_leave` means the backfill should affect no existing rows. This must still be validated by the disposable baseline CI before applying any production migration.
- 2026-11-07 Release sequencing: production Supabase migrations must be applied in timestamp order after disposable-baseline SQL tests pass and before merging/deploying the SchoolPro app. Render service `ihlink-schoolpro` is confirmed on `main` with commit-triggered auto-deploy. Control Panel service `ihlink-admin` is also on `main` with commit-triggered auto-deploy; its PR must merge only after the database migration exists. No PR merge, production migration or Render deployment has occurred as part of this C0 work yet.


- 2026-11-07 C0 validation continuation: the initial baseline workflow was corrected to temporarily withhold the incomplete historical migration directory during disposable Supabase startup, restore the schema-only snapshot, and then apply only the 14 post-baseline C0 migrations. On run **42381440363**, TypeScript, build, all four C0 source-contract suites, baseline restore, and all 14 migrations succeeded; the first two SQL regression files passed. The lifecycle SQL test exposed an assertion that expected a literal `m.status` reference even though `schoolpro_set_board_role` correctly filters `status='active'`; the assertion was corrected to validate the active-status predicate and ended-appointment history. A separate Stage B roster contract was corrected to match the implementation's stronger active-membership filter for teaching responsibilities. Latest branch head at this documentation update: `15042687f750572c350ff8d80cc6e8557118c96f`; fresh C0 and full SchoolPro CI runs are pending. No production Supabase migration, Render deployment or PR merge has occurred.


- 2026-11-07 C0 release-candidate acceptance: latest branch head before this handover update was `71f7ef9bcf83bc842813c7b0e635b0a78f969c73`. **SchoolPro CI** run `42382515708` passed, including TypeScript, production build, Stage A/B regression scripts, mobile/customer-layout checks, and all configured disposable PostgreSQL/local Supabase integration jobs. **C0 regression** run `42382515752` passed: local Supabase startup without replaying legacy migrations, schema-only baseline restore, all 14 post-baseline migrations, all C0 source-contract suites and all three SQL security/lifecycle regression files. **Payment-page validation** run `42382515792` passed. Tenant-acceptance remains intentionally skipped to avoid synthetic workspace creation or writes to the two retained verification workspaces. Control Panel PR #70 validation run `42380596124` passed. Production Supabase remains at migration version `20261106164431`; none of the 14 C0 migrations has been applied to production yet. No PR has been merged and neither Render service has been deployed. Next release sequence: apply the exact timestamped migrations while preserving migration-history parity; then merge/deploy Control Panel PR #70 and SchoolPro PR #122 to the existing Render main-branch services; verify both deployments and production schema.


## 2026-11-07 Stage B/C0 production release completion

- **Production Supabase:** Applied the 14 C0 migrations from `20261107130000` through `20261107235950` to project `lnqsroyiybutkfngbyge`. The migration ledger was repaired after each MCP migration application so its recorded versions exactly match the timestamped repository files; final read-only verification confirmed all 14 names/versions in order. The baseline remains `20261106164431`.
- **Production schema verification:** `schoolpro_workspace_deletion_requests` exists with RLS enabled; staff appointment history, staff disciplinary cases and student discipline events exist; direct authenticated DELETE privileges on SchoolPro classes and members are revoked; all four workspace-removal RPCs are executable by `authenticated` and not by `anon`.
- **Control Panel:** PR #70 merged as `4bef27e1d50b92a44aa5206fcfe3c16953e1a929`. Render service `ihlink-admin` deployment `dep-dbnjk6tg1s2s73fk96ug` completed successfully and is live.
- **SchoolPro:** PR #122 merged as `a10d96905a3b291af9f9534547952b5fb8e0c8af`. Render service `ihlink-schoolpro` deployment `dep-dbnjl28ae00c738qah2g` completed successfully and is live.
- **Final CI:** SchoolPro CI `42382868972`, C0 regression `42382869011`, payment-page validation `42382868992`, and Control Panel validation `42380596124` all passed. Tenant-acceptance remained intentionally skipped to avoid synthetic workspaces and production tenant writes.
- **Data protection:** No school/workspace was deleted or suspended during release; no tenant, financial, audit or Storage records were modified or purged. The two retained verification workspaces remain untouched.
- **Security-advisor note:** The project-wide advisor still reports existing security findings (including RLS-enabled service/internal tables with no policies, public token-based SECURITY DEFINER RPCs, authenticated SECURITY DEFINER RPCs and disabled leaked-password protection). These were not introduced by the C0 release. The four new workspace-removal RPCs specifically have no `anon` EXECUTE grant. Track the broader advisor findings separately; do not weaken the new lifecycle controls to silence generic advisor notices.
- **Stage status:** Stage A and Stage B/C0 are merged and deployed. Stage C has not started.


## 2026-11-07 — Permission reader and workspace module visibility follow-up

- PR #123 merged as `9d417bba9e7bca244e0a545fb663f81aee223893`.
- Production migration `20261107235955_schoolpro_fix_permission_reader_board_role` applied to Supabase project `lnqsroyiybutkfngbyge`; migration history reconciled to the repository version.
- Root cause: `schoolpro_user_permissions(uuid)` referenced `schoolpro_board_members.role`, a column that does not exist. The role is stored on the joined `schoolpro_members` row. The corrected function now checks `bm.role = 'administrator'` with active membership and non-ended appointment guards.
- Authenticated SQL simulation returned 31 permissions for a retained workspace without error.
- Render SchoolPro deploy for merge commit `9d417bba9e7bca244e0a545fb663f81aee223893` is live (`dep-dbnk6j7b9u1s73coso00`).

## 2026-11-07 — Follow-up PR #124 (merged and deployed)

- PR #124: workspace navigation, Principal role-catalogue visibility, admissions routes, school audit-log UI and trigger-based audit capture.
- Super Admin's live SchoolPro dashboard previously supplied a three-link sidebar (Dashboard, Students, Fees) rather than the full `schoolSections` navigation. PR #124 switches the live dashboard to the complete school workspace navigation.
- Principal remains compatible with the established authorization model: stored membership role `administrator` plus `position_title = 'Principal'`. The staff role editor already maps the Principal selection to that representation; PR #124 makes it visible in the role catalogue.
- The Admissions Workspace was already implemented and its database tables/RPCs exist, but its entry was not exposed consistently in navigation. The standalone Admission Operations component was not routed. PR #124 exposes the workspace links and mounts the page.
- Production schema inspection found `schoolpro_admission_events` and `schoolpro_admission_documents` are application-scoped through `application_id`, not `school_id`. IHLink Admin's generic control-panel query incorrectly applied a `school_id` filter; PR #71 scopes those tables through the selected school's application IDs.
- Production currently has the admission tables and event workflow objects, but zero application, event, offer or document rows. Empty tables are not missing backend objects.
- Production `schoolpro_audit_logs` existed but had zero rows and no audit-capture triggers. PR #124 added a security-definer trigger writer for core school operations. The production migration `20261107235956_schoolpro_audit_event_capture` has now been applied and its version/name reconciled in `supabase_migrations.schema_migrations`. Production verification confirms the private function exists, 46 audit triggers are installed (including admissions and admission events), and authenticated users cannot execute the trigger function directly. The school-scoped audit read simulation returned successfully under the authenticated role. No production test rows were inserted; new user activity will populate the audit ledger.
- SchoolPro audit page and operations link are added in PR #124. IHLink Admin central audit page actor attribution and SchoolPro Control Panel module links/query scoping are in IHLink-Admin PR #71.
- PR #124 merged as `44afbf6c26874d39263318a68dae1aa6e38812ec`; Render SchoolPro deploy `dep-dbnkh2vb9u1s73cp9o10` is live.
- IHLink Admin PR #71 merged as `a6c1f15f3c139d9f951e18c429dfc62c251595a3`; Render Admin deploy `dep-dbnkfm7avr4c73aiakk0` is live. The central audit log now resolves the 148 of 157 historical actor IDs that still have profiles; nine legacy records have no actor ID and remain explicitly unattributed.
- Stage C remains deferred until Stage B/C0 live acceptance is completed.

## 2026-11-07 — Complete module navigation, entitlements and Principal invitation rollout
- SchoolPro PR #132 merged as `1fdc0798d8af18944d03a217ddf22448ea04141e`. Render SchoolPro deployment `dep-dbnl7bqvcj2c738ho050` was live before the follow-up Principal release. The change gives platform Super Admin the complete school-administration sidebar even while school permissions are loading/failing, keeps the school selector available from the Admin Dashboard and Proprietor Dashboard, and separates Houses & House Allocation from Games & Competitions.
- School Operations is now a 39-module launchpad spanning student and former-student records, classes, subjects, attendance, timetable, admissions/events/documents, results, broadsheets, advanced reports, result design, CBT, question bank, finance, subscriptions, staff, guardians, documents/certificates, branding, roles/permissions, notifications, assignments/announcements, library, transport, hostel, inventory, payroll, discipline, calendar, lesson notes, leave, promotions, houses, games, staff disciplinary cases and audit logs. All 39 card destinations were checked against registered SchoolPro routes; production backing tables were checked read-only. Admission-event counts intentionally use the school-scoped admissions table because the event table is related through its application ID rather than a direct school_id.
- Subscription-gated modules (CBT, Advanced Reports and custom branding) remain visible to users with the relevant role permission when the school's plan does not include them. Opening a locked module now reaches its entitlement/upgrade guidance rather than silently removing the navigation entry. Standard Broadsheets remain separate from Enterprise Advanced Reports. Games was added to the individual permission-override matrix.
- IHLink Admin PR #75 merged as `22fa98c7ff96c7a7e337b293fc97e25a6e50bebd` and Render Admin deploy `dep-dbnl0kivcj2c738hghog` went live; the Control Panel now exposes the implemented SchoolPro module datasets. PR #76 merged as `535f3314e05b48658b97be8874e25ca61306411e`; Render Admin deploy `dep-dbnl77e8bjmc73acd660` went live with a direct Workspace Overview & Entitlements entry, separate from the platform-wide Subscriptions & Upgrades workflow.
- Production migration `20261107235957_schoolpro_admin_principal_games_permission` was applied and recorded in `supabase_migrations.schema_migrations`. Read-only verification confirms the correct `schoolpro_members` board-role reference, no invalid `b.role` reference, the Principal permission branch, and Games in the administrator/Principal permission sets.
- Principal is presented as a staff role but remains stored compatibly as `role='administrator'` plus `position_title='Principal'`. SchoolPro PR #131 merged as `6813b9e87d44df455328c94f59632273ab3b142b`. Production migration `20261107235958_schoolpro_principal_invitation_designation` adds the invitation position-title field and preserves it when an invitation is accepted. The migration is recorded in migration history. Production verification confirms the column, check constraint, acceptance-function mapping and migration-history row.
- The updated `invite-school-staff` Supabase Edge Function is deployed and ACTIVE at version 20 with JWT verification enabled. It maps Principal consistently across new-account, existing-account and pending-invitation paths.
- Validation: PR #132 and PR #131 both passed TypeScript, production build, source-contract checks, the disposable-Supabase C0 SQL regression and all required SchoolPro CI integration jobs. The tenant-acceptance job remains intentionally skipped; no test workspaces or production test rows were created.
- No tenant data, membership rows, financial evidence, Auth users, or Storage objects were modified as part of these navigation/Principal releases. The two retained verification workspaces remain untouched.

## 2026-11-08 — Stage C commencement (assessment, results, review and publication)

- Stage B/C0 live acceptance was explicitly confirmed by the user on 2026-11-08. Stage C is now authorized to begin. Stage D remains separate and out of scope: Result Design Studio, custom Excel workbooks, template authoring, logos, signatories and A4 print design.
- Created working branch `feat/schoolpro-stage-c-assessment-results-workflow` from `main`. No merge, deployment, production migration, production data write or test-workspace creation has occurred.
- Initial read-only source inventory confirms the existing implementation already includes configurable assessment schemes (100-point validation), component-by-component score entry with retained prior components, draft-only Excel score import, school/session/term-scoped result loading, class broadsheet review and publication controls, correction requests/reopening, and public verification restricted to published+locked aggregate snapshots.
- Existing role and workflow code includes teacher class/subject allocation scoping, a controlled `review_schoolpro_result` RPC, class/selected/school publication RPCs, and result correction audit/history UI. These capabilities must be tested against the current production schema and authorization contracts before adding duplicate workflow logic.
- Stage C work order: (1) reconcile all score-entry/calculation and import paths against database constraints and assigned teaching scope; (2) verify review/approval and class/session/term publication transitions, immutable locking and correction/republication audit; (3) verify class-subject averages and student totals/positions are calculated consistently and displayed once; (4) verify student/guardian result visibility and public verification only expose released results; (5) close gaps with targeted disposable PostgreSQL/source-contract regressions and update this handover.
- Safety boundary remains unchanged: Supabase only; Render hosting; preserve the two retained verification workspaces and all existing tenant, financial, audit, Auth and Storage records. Do not make production writes or apply migrations without explicit approval. Do not create synthetic workspaces or test accounts. Do not merge or deploy without explicit approval.

### Stage C — first implementation increment: assessment Excel import validation (2026-11-08)

- Hardened the SchoolPro Results Excel import preview in `src/pages/schoolpro/SchoolProResults.tsx`.
- Import now requires the identity/scheme columns, rejects duplicate headings, requires a column for every configured assessment component, and rejects blank/non-numeric/out-of-range component marks instead of silently converting blanks to zero.
- Import preview rejects duplicate student-subject rows and checks the selected session's class-subject allocation where allocations exist. Existing teacher subject/class assignment checks remain in force.
- Kept the existing controlled `import_schoolpro_results` RPC and Draft-only import workflow; no direct client insert path was introduced.
- Added `scripts/test-schoolpro-result-import-validation.mjs` and registered `npm run test:schoolpro-result-import-validation`.
- Existing incremental entry behavior is unchanged: entered components merge with previously saved components; empty submissions and edits to approved/published/locked results remain blocked.
- No SQL migration is included in this increment. No production database, school records, tenant data, Auth, financial, audit or Storage data were changed.
- Validation status: source and regression assertions have been added; automated CI/typecheck/build execution is pending the draft PR workflow. This increment is not merged or deployed.

### Stage C — second implementation increment: consistent class ranking (2026-11-08)

- Read-only comparison found `schoolpro_class_review_sheet` ranked staff review rows by average, while the published broadsheet and `schoolpro_result_class_rank` ranked by total score.
- Added migration `20261108100000_schoolpro_consistent_result_ranking_totals.sql` to change the staff review-sheet ranking basis to total score, retaining the existing roster, selected-session, status counts, subject summaries and authorization checks.
- Added `scripts/test-schoolpro-result-ranking-consistency.mjs` and `npm run test:schoolpro-result-ranking` to assert staff review, broadsheet and published report-card ranking all use total-score ordering.
- The migration is committed to the Stage C branch only. It has not been applied to production Supabase. No production data was changed.
- PR #133 remains draft and not merged/deployed; CI is being rerun against the updated branch.
### Stage C — database import boundary hardening (2026-11-08)

- Read-only inspection of the production `import_schoolpro_results` function found that its previous implementation treated missing component values as zero, accepted duplicate student-subject rows, and could replace an existing Draft result with a different assessment scheme. It also selected only currently active students without verifying selected-session enrolment history.
- Added migration `20261108101000_schoolpro_harden_result_import_rpc.sql` to enforce selected-session enrolment, complete numeric component maps, valid component keys/ranges, duplicate-row rejection, original-scheme preservation and Draft/unlocked-only replacement at the database boundary.
- The import RPC continues to call `private.schoolpro_can_write_result`, so existing school/module/teacher assignment authorization remains enforced. Valid imports remain Draft.
- The client preview now also flags existing locked/approved/published results and scheme mismatches before submission.
- Extended the import regression script to cover both client preview and database RPC contracts.
- This is a proposed migration only; production Supabase has not been modified. No school records were written.
### Stage C — atomic correction-request review (2026-11-08)

- Read-only production review found the client approved a correction request in two separate operations: reopen the published result, then update the request status. A failure between those operations could leave a reopened result with a still-pending request.
- Added migration `20261108102000_schoolpro_atomic_result_correction_review.sql` with `public.decide_schoolpro_result_correction_request`. The RPC locks the pending request, verifies the reviewer role and Results entitlement, reopens the published result when approved, and records the decision/reviewer/timestamp in the same transaction.
- Removed the direct UPDATE RLS policy for correction requests so clients cannot directly change request state or reviewer attribution; decision writes go through the security-definer RPC.
- Updated the Results UI to use the atomic RPC and added `scripts/test-schoolpro-correction-review-atomicity.mjs` with `npm run test:schoolpro-correction-review`.
- Proposed migration only; no production database writes. Existing correction requests and result records remain unchanged.
### Stage C — preserve assessment scheme calculation history (2026-11-08)

- Read-only code review identified that editing a used assessment scheme could change component definitions while existing result rows retained totals calculated under the previous definition.
- Added migration `20261108103000_schoolpro_immutable_used_assessment_schemes.sql`. Once any result references a scheme, its school level and component definitions cannot be changed; renaming and default selection remain allowed.
- Updated the Results UI to block component/level edits to a scheme already referenced by saved results and direct the user to create a new scheme for future assessments.
- Added `scripts/test-schoolpro-assessment-scheme-immutability.mjs` and `npm run test:schoolpro-assessment-scheme`.
- Proposed migration only; not applied to production. Existing assessment schemes and results were not modified.

### Stage C — released-result visibility and calculation workflow audit (2026-11-08)

- Read-only production inspection confirmed the family result-period manifest already exposes only rows with `status='published'` and `locked=true`; printable report-card RPC also requires published+locked rows, and subject statistics aggregate only published+locked results.
- The public PIN-check RPC had a release-boundary mismatch: its payload selected published rows without requiring `locked=true`. Added proposed migration `20261108104000_schoolpro_require_locked_results_for_pin_release.sql` to align the PIN checker with the family/report-card release boundary while retaining admission-key cooldown serialization, PIN failure accounting, finance/attendance holds, and service-role-only execution.
- Added `scripts/test-schoolpro-pin-release-lock.mjs` and registered it in CI.
- Updated the parent dashboard's result summary metric to count only locked, published rows, matching the child report-card manifest.
- Read-only production audit confirmed result totals are recalculated by the database trigger from the saved assessment scheme components; missing component keys are treated as zero for incremental draft entry, while the Stage C full-import RPC now requires every component. Published result edits remain blocked by the result workflow trigger and RLS update policy (which only permits unlocked Draft rows).
- Read-only production audit confirmed approval uses `review_schoolpro_result`, publication RPCs select only approved and unlocked rows, and the controlled correction RPC reopens only published results while recording the previous snapshot. The class publication RPC is class/session scoped; selected/school publication validates school membership and historical enrolment.
- Added the four Stage C source-contract regression scripts to the main `.github/workflows/ci.yml` validate job. The initial CI run was still queued at the time of the first review; the updated branch will trigger a fresh run including the newly wired checks.
- All four Stage C migrations remain proposed only. No production SQL/DDL or tenant data writes have been executed. No test workspaces or accounts created. No merge or Render deployment has occurred.

- Follow-up calculation review found the public PIN result checker used hard-coded A–F grade cutoffs while report cards use the school's configured grade scale. The PIN RPC now includes the active school grade bands in its response, and the checker uses those configured bands (with the legacy scale only as a fallback when no band matches). The focused release regression asserts this contract.
- Added a database-side assessment scheme/class-level compatibility check to the import RPC. The guard uses the selected-session historical class level (rather than trusting the workbook or client), allows the existing `all`/`custom` schemes and supported combined-level aliases, and rejects mismatched school-level schemes. The import regression now asserts this boundary.
- Further comparison with the family access policy found the public PIN checker also needed to enforce the same attendance and finance holds and respect the school leadership's per-student result-access exception. The PIN RPC now applies the configured attendance threshold and term date window, then the finance hold, unless an explicit allowed exception exists. Added regression assertions. This closes the mismatch rather than merely aligning the locked/published status filter.


### Stage C review follow-up — roster and attendance scope

- A source-to-source comparison against the established broadsheet/report rank migrations found that the new staff review-sheet roster query needed to preserve the existing historical-session fallback for active students who have no enrollment-history row. The proposed review-sheet migration now uses the same `coalesce(enrollment_history.class_id, students.class_id)` and active/no-history fallback as the published broadsheet and report rank readers.
- The PIN checker attendance aggregation now explicitly scopes attendance rows by both `school_id` and `student_id`, matching the family access policy and preventing cross-workspace attendance rows from entering the calculation.
- Added source-contract regression assertions for both corrections. These remain proposed branch changes; no production SQL has been run.


### Stage C published ranking and release-boundary alignment

- Added proposed migration `20261108105000_schoolpro_published_rank_requires_locked_results.sql`. Published class ranking and the staff broadsheet's published-result aggregate now include only rows that are both `status='published'` and `locked=true`, matching the existing printable report-card and family-period release boundary.
- Draft and approved records remain available in the staff review sheet for operational review, but cannot influence the published class position calculation or published class totals.
- Added a source-contract regression and wired it into the standard CI validation job. This migration is not applied to production.


### Stage C missing-component presentation correction

- Incremental assessment entry is intentionally supported: teachers may save one component at a time and previously saved components are merged rather than overwritten. A missing component is therefore not equivalent to a recorded score of zero.
- Updated the staff saved-score breakdown and printable report card to display an em dash for a missing component; an actual numeric zero continues to display as `0`. This avoids presenting an incomplete draft as if the learner received zero marks for an unentered component.
- Extended the existing result-import regression to assert both staff and report-card rendering. No score data or production records were changed.


### Stage C assessment completeness approval and publication boundary

- Read-only production inspection found that the result total trigger intentionally treats an unentered component as zero so teachers can save assessment components incrementally. That behavior is retained for Draft entry.
- The existing `review_schoolpro_result` RPC did not verify that every configured component had a valid score before changing a Draft to Approved. The three publication RPCs trusted the Approved status without rechecking component completeness.
- Added proposed migration `20261108110000_schoolpro_require_complete_assessments_for_approval_and_publication.sql`. Its private validation helper requires a valid same-school assessment scheme, a non-empty component list with unique keys, a numeric in-range score for every component, no unknown score keys, and a stored total equal to the component sum. Malformed data fails closed.
- Approval now rejects incomplete assessments with a clear error while rejection remains available. Class, selected-student and whole-period publication each revalidate all in-scope Approved rows and abort the transaction if any assessment is incomplete; they do not silently publish only a subset.
- Existing module entitlement, reviewer role, school/class/student scope, audit writes, publication timestamps and locked-result transitions are retained. The helper is private and direct client execution is revoked.
- Added `scripts/test-schoolpro-assessment-completeness-release-boundary.mjs`, registered it in `package.json` and the standard CI workflow. Added a disposable PostgreSQL integration test that applies the migration to a minimal isolated schema and exercises incomplete/complete approval, class publication, selected-student publication and whole-period publication. The publication RPCs lock their in-scope Approved rows before revalidating completeness to prevent a concurrent score edit from racing the release check.
- Follow-up hardening: the component `maxScore` type check now uses `IS DISTINCT FROM 'number'`, so a missing JSON property (SQL NULL) cannot slip through PL/pgSQL three-valued logic. The helper also coalesces the final total comparison to `false`, ensuring a NULL comparison can never be interpreted as complete. Added a disposable PostgreSQL case proving that a scheme missing `maxScore` cannot be approved and remains Draft. This fixture is committed but still awaits execution in CI.
- Production Supabase was inspected read-only only; the result table currently contains zero rows. The proposed migration has not been applied. No production rows, workspaces, Auth users, financial records or Storage objects were changed. PR #133 remains unmerged and undeployed pending validation.


### Stage C atomic bulk approval

- The broadsheet previously approved Draft result rows by calling the single-result review RPC in a client-side loop. If a later row failed completeness validation, earlier rows remained Approved, leaving a partially completed class/school approval operation.
- Added proposed migration `20261108113000_schoolpro_atomic_bulk_result_approval.sql` with `review_schoolpro_results(uuid[],text)`. It validates the authenticated reviewer, Results entitlement and school role; bounds and de-duplicates the requested IDs; locks the selected rows in deterministic ID order; requires every row to be an unlocked Draft in the same school; and validates every assessment before writing any approval.
- The RPC writes reviewer attribution, updates all selected result rows and records one audit event in the same database transaction. Any incomplete or out-of-scope row aborts the entire batch; no subset is approved.
- Updated the broadsheet approval action to use the bulk RPC instead of the sequential client loop. The single-result review RPC remains available for individual review workflows.
- Added a source-contract regression and extended the disposable PostgreSQL integration fixture to prove both rollback of a mixed complete/incomplete batch and successful approval of a fully complete batch. The test is wired into the standard CI validation job.
- This is a proposed migration only. It has not been applied to production, and no production result rows were changed. GitHub Actions execution remains pending.

### Stage C grade-scale and subject-statistics consistency

- Read-only production inspection confirmed that `private.schoolpro_subject_statistics` computes cumulative subject averages from published, locked rows and requires one result per term through the selected term. The unique result key on student/subject/term/session supports that denominator. Missing subject-term marks are not treated as zero.
- Corrected the current-subject rank edge case: when the pupil has no published score for the selected term in a subject, `current_position` is now NULL instead of incorrectly returning rank 1. Current subject class averages still use only pupils with an actual published score in that subject/term; cumulative class averages/ranks use pupils with all terms through the selected term.
- Added `src/lib/schoolproGradeScale.ts` as the shared grade-band resolver for staff Results, report cards and public PIN result checks. Active configured bands are inclusive at both endpoints; inactive bands are ignored. When a custom scale exists but a score falls in a configured gap, the result is shown as `Ungraded` rather than silently substituting the generic A-F scale. The generic scale remains the fallback only when no active custom bands exist.
- Added proposed migration `20261108111000_schoolpro_consistent_subject_statistics_and_grade_bands.sql`. It updates the subject-statistics RPC and installs a per-school serialized database trigger preventing inclusive overlap between active grade bands on insert/update. Intentional gaps remain allowed; the UI and public result checker report those scores as Ungraded.
- Extended the disposable PostgreSQL integration job to exercise overlapping grade-band inserts and updates, while allowing inactive historical bands to overlap. Added `scripts/test-schoolpro-grade-scale-and-subject-statistics.mjs` and wired it into the normal CI workflow.
- Production Supabase inspection was read-only. Neither proposed Stage C migration was applied. No production result, grade scale, workspace, Auth user, financial record or Storage object was changed.


### Stage C allocated-subject visibility and missing-mark coverage

- Added proposed migration `20261108112000_schoolpro_show_allocated_subjects_in_broadsheet.sql`. The staff class-review RPC now returns subjects allocated to the selected class/session even when no learner has a score recorded yet; previously it returned only subjects with result rows.
- The subject list also retains legacy recorded subjects that are not present in the allocation table, so historical results are not silently hidden. The RPC marks each subject as `assigned` or `recorded only` and reports its actual recorded count/average.
- Missing marks remain blank in the broadsheet and Excel exports. They are not coerced to zero and do not enter student totals, student averages, subject averages or the class average. The page explains the allocation/coverage distinction; Excel includes allocation status.
- Added `scripts/test-schoolpro-allocated-subjects-broadsheet.mjs`, registered it in `package.json` and the standard CI validation workflow.
- This is a proposed branch migration only. It has not been applied to Supabase production; no production rows were changed.


### Stage C allocated-subject, published-average and rank alignment

- Extended the class review RPC in proposed migration `20261108112000_schoolpro_show_allocated_subjects_in_broadsheet.sql` to include all subjects allocated to the selected class/session, even before any score exists. Legacy result subjects are retained as “recorded only”; duplicate teacher allocations are collapsed so marks are not double-counted.
- Missing marks remain blank and are excluded from totals/averages. Broadsheets and Excel exports identify allocation state and assessed counts.
- Added separate published-and-locked totals, averages, subject counts and per-subject score maps alongside the staff review aggregates. The broadsheet now distinguishes review metrics (which may include draft/approved marks) from published metrics; its published class average and per-subject averages use the same published+locked population as family/report-card output.
- Added a distinct published position based on published total, while retaining the review position based on all saved records. The UI labels both positions separately.
- Added and wired `scripts/test-schoolpro-allocated-subjects-broadsheet.mjs` in the normal CI validation step. CI has not yet reported a result for the latest branch revision.
- Proposed migration remains unapplied to production. No production data or workspace was changed.

- CI follow-up: the earlier validate job reached the Stage C completeness source-contract test and failed only because the test expected a literal `p_status='rejected'` expression, while the implementation validates allowed values with `p_status not in('approved','rejected')`. Updated the assertion to match the actual guard; this is a test-contract correction, not a runtime SQL failure. The corrected head has not yet been rerun by GitHub Actions.


### Stage C printable class-average denominator alignment

- Fixed the full-class printable workflow to calculate the class average as total published-and-locked score points divided by the number of published-and-locked subject result rows. It no longer averages each learner's average with equal weight when learners have different numbers of published subjects.
- Applied the same weighted denominator to the Excel workbook fallback calculation. Normal workbook output continues to use the class average returned by the published broadsheet; the fallback now uses the same score-row population.
- Individual report-card averages remain the mean of that learner's published printable subject rows. This now reconciles with the class average as the mean across all eligible published score rows, not the mean of individual averages.
- Added `scripts/test-schoolpro-printable-class-average-consistency.mjs`, registered it in `package.json` and the normal CI workflow.
- No production migration or data change was required for this frontend/workbook correction.


### Stage C report-card assessment-scheme correctness

- Corrected report cards to load every assessment scheme referenced by the student's published subject rows, instead of loading only the first row's scheme and reusing its component layout for every subject.
- The report table now builds a union of component keys, displays a component mark only when that component belongs to the row's actual scheme, and shows the correct maximum for consistent maxima or “Varies” when subject schemes differ.
- Overall maximum is now derived from the sum of configured component maxima for each subject result. Overall percentage is calculated as total earned points divided by that maximum, rather than assuming every subject is out of 100.
- Added `scripts/test-schoolpro-report-card-assessment-schemes.mjs`, registered it in `package.json` and the normal CI validation workflow.
- Frontend-only correction; no production migration or data change.

- Follow-up: subject totals now display their own configured maximum, and subject grades are normalized to a percentage using that subject's own scheme maximum before applying the school's grade bands. This avoids misgrading subjects whose component maxima do not sum to 100.


### Stage C broadsheet class-average weighting

- Corrected the interactive broadsheet's published class average to divide total published score points by the total number of published subject-result rows. It no longer takes an unweighted mean of each learner's average when learners have different numbers of published subjects.
- This matches the denominator used by the SQL broadsheet and the printable class-results page.
- Extended the allocated-subject broadsheet regression to reject the old unweighted calculation.
- Frontend and regression-only change; no production database or deployment action.


### Stage C broadsheet approval refresh

- After the atomic bulk approval RPC commits successfully, the class/selected-student broadsheet now reloads its review sheet so approval state and aggregates are refreshed immediately.
- If the post-commit read fails, the UI explicitly reports that approval succeeded and only the display refresh failed; it does not imply the committed approval was rolled back.
- Regression coverage added to `scripts/test-schoolpro-atomic-bulk-result-approval.mjs`.
- This is a frontend read-after-write consistency improvement; no production data or database migration was applied.


### Stage C class publication roster consistency

- Corrected the class-results publication scope to match the historical-session roster fallback already used by the review sheet and related report queries.
- A student with an active current roster and no enrollment-history row for the selected session remains eligible for class publication.
- Where a selected-session history row exists, that historical class assignment remains authoritative; an active current class does not override a different historical class.
- Applied the same roster predicate to the publication lock, completeness validation, and update so the three phases cannot disagree about which results are in scope.
- Extended the assessment-completeness source regression to guard the fallback and predicate consistency.
- Migration remains proposed only; no production database changes have been made.

### Stage C class-publication current-roster isolation

- A follow-up review found the active-roster fallback in class publication was too broad: it included active students with no selected-session history row without checking their current class assignment.
- Added proposed migration `20261108114000_schoolpro_class_publication_current_roster_scope.sql`. The fallback now requires `schoolpro_students.class_id = p_class`; where selected-session enrollment history exists, its historical class remains authoritative.
- Applied the identical predicate to the row-lock phase, completeness validation and final publication update so the three phases operate on the same class roster.
- Extended the source-contract regression and disposable PostgreSQL integration fixture with two active students who have no selected-session history and belong to different current classes. Publishing one class must publish only its own current-roster student and leave the other class's result Approved.
- Proposed migration only. No production database changes, merge or Render deployment.

### Stage C class-scoped atomic approval

- Found that the broadsheet's class-approval path selected Draft result IDs by student IDs only. If a student had additional result rows in the same school/session outside the selected class scope, those rows could be approved unintentionally.
- Added proposed migration `20261108115000_schoolpro_class_scoped_atomic_approval.sql` and RPC `review_schoolpro_class_results`.
- The RPC locks the selected-session roster, applies historical-enrolment precedence and the same current-class fallback used by class publication, then delegates the exact result-ID batch to the existing atomic approval RPC.
- Updated the class-level broadsheet action to use the class-scoped RPC. Selected-student and whole-school approval retain the existing atomic bulk RPC.
- Extended the source-contract regression and disposable PostgreSQL fixture to prove a class approval does not approve a Draft result belonging to another current class.
- Proposed migration only; no production database changes, merge or Render deployment.


### Stage C selected-student class-roster approval

- Tightened the selected-student approval path so selecting learners from one class cannot approve unrelated result rows for those learners outside that class/session roster.
- Extended `review_schoolpro_class_results` with an optional, bounded student-ID selection. The RPC validates uniqueness and confirms every selected student belongs to the requested historical/current class roster before selecting any Draft result rows.
- Updated the broadsheet's “Approve selected scores” action to call this class-scoped RPC directly. Whole-school approval remains on the atomic bulk RPC.
- Extended the source regression and disposable PostgreSQL integration fixture to prove selected learners are approved only within the selected class roster and out-of-class selections are rejected.
- Proposed migration only; no production database changes, merge or Render deployment.


### Stage C selected-student publication class-roster enforcement

- Found that selected-student publication accepted a learner ID list but did not constrain result rows to the class currently selected in the broadsheet. A learner with additional approved rows associated with another class could have those rows published unintentionally.
- Added proposed migration `20261108116000_schoolpro_selected_publication_class_scope.sql`. The legacy unscoped five-argument RPC overload is removed; selected publication now requires a valid class and verifies every selected learner against the selected-session historical roster or, when no history exists, the learner's active current class.
- Applied the same class predicate to result-row locking, completeness validation and publication update. Whole-school publication remains an explicit separate mode and rejects a supplied class/student selection.
- Updated the broadsheet to pass the selected class for learner publication and null class for the whole-school action.
- Extended the approval/publication regression and disposable PostgreSQL integration fixture to prove an in-class result publishes, another class's result remains Approved, and an out-of-class learner selection is rejected.
- Proposed migration only; no production database changes, merge or Render deployment.


### Stage C publication request bounds and academic-period guardrails

- Bounded selected-student publication to 5,000 learner IDs per request and explicitly rejects duplicate IDs before processing.
- Added a required nonblank term and session check to class-scoped publication, matching the guards already applied to class approval and selected/whole-period publication.
- Extended the selected-publication source regression for the size and duplicate-ID limits and the class-publication regression for required term/session values.
- These are proposed changes in the unmerged Stage C PR; no production migration, merge or Render deployment.


### Stage C historical-session roster consistency

- Fixed the class roster joins used by staff review sheets, published class ranks/broadsheets, and subject statistics.
- Historical enrollment is now joined through a single-row lateral lookup to prevent duplicate enrollment-history records from multiplying learner rows, marks, averages or ranks.
- When a selected-session enrollment exists, its class remains authoritative (including a null class value); current class is only a fallback when no enrollment-history row exists for that selected session.
- Active-student fallback now checks for missing history in the selected session, rather than incorrectly excluding learners merely because they have history from a different academic session.
- Extended the allocated-subject broadsheet regression to assert deduplication, session-scoped fallback and historical-class precedence.
- Proposed in Stage C PR #133 only; no production database migration, merge or Render deployment.


### Stage C family ranking release guard

- Updated `schoolpro_result_class_rank` so a student or active guardian can receive a class position only when that learner has at least one result for the requested term/session that is both published and locked.
- The existing result-output authorization helper remains mandatory, preserving attendance and finance release restrictions and configured overrides.
- Staff ranking access remains governed by the existing class/subject assignment and school-role checks.
- Added required nonblank term/session validation and a regression asserting both the release requirement and the existing release-policy helper.
- Implemented as proposed migration `20261108117000_schoolpro_hide_unreleased_student_rankings.sql` in Stage C PR #133; not applied to production.


### Stage C ranking population correction

- Tightened `schoolpro_result_class_rank`: the ranking population now includes only learners with at least one published-and-locked result in the requested term/session.
- Learners with no released score are no longer counted as zero-score competitors, which could otherwise distort class population and positions.
- The same released-result predicate remains on the score join; the learner/guardian release check and attendance/finance gate are preserved.
- Added a source regression assertion for the non-empty released-score population.
- Proposed migration `20261108117000_schoolpro_hide_unreleased_student_rankings.sql` remains unmerged and unapplied to production.


- Extended the ranking correction to the staff broadsheet: learners with no published subject rows remain visible in the roster with a blank class position, and are ordered after learners with released scores. Their blank rows no longer distort published ranking. Broadsheet score totals still include published-and-locked rows only.


## Stage C result workflow and section leadership correction — 2026-11-08

- Added migration `20261108118000_schoolpro_principal_section_leadership.sql`: explicit section appointments now support Head Teacher for Nursery/Primary and Vice Principal or Principal (stored as administrator + `position_title='Principal'`) for Junior/Senior Secondary. Database assignment RPC validates the role-to-section mapping, retains appointment history with `ended_at`, and removes active assignments when a staff member loses an eligible leadership role.
- Updated Staff & Access UI so appointed Principals also see and manage their active section assignments.
- Added migration `20261108119000_schoolpro_form_master_section_head_result_workflow.sql`: Form Master submission is a server-validated action tied to the class `form_teacher_id`; every submitted Draft result must pass assessment completeness. Per-result workflow state records submission, section-head approval and publication.
- Database trigger requires a Form Master submission before approval, requires the appointed section leader to approve, and requires approval before publication. Nursery/Primary approval is restricted to an assigned Head Teacher; Junior/Senior Secondary approval is restricted to an assigned Vice Principal or Principal. Score edits after submission invalidate that submission and require re-submission; reopening a result resets its workflow.
- Broadsheet UI now exposes submission only to the class Form Master, approval/publication only to the appointed section leader for the selected class, and whole-school bulk actions only to the IHLink Super Administrator.
- Regression source and disposable PostgreSQL fixture extended for Principal assignment, role-to-section restrictions, Form Master submission and the approval-to-publication transition. The section-leadership test is already included in normal CI.
- These are proposed migrations in PR #133 only. They have not been applied to Supabase production, merged, or deployed to Render. Disposable PostgreSQL integration execution and latest CI status remain pending.


- Follow-up hardening: role-to-section matching is now applied consistently to student/class read scopes and historical enrollment reads, not only to the assignment form. Legacy active appointments that conflict with the staff member's section role are ended while retaining appointment history. The Staff UI displays only the section options permitted for that role.
- The disposable PostgreSQL fixture now exercises the Form Master RPC and the complete Nursery result transition from Form Master submission through Head Teacher approval to publication. Junior Secondary Head Teacher approval is explicitly rejected.

- Final workflow hardening: active membership is required for Form Master submission and section-head approval; score totals and result identity/period changes invalidate pending submissions, and approved scores cannot be edited without the correction/reopen path. The PostgreSQL fixture now tests Form Master submission followed by Head Teacher, Vice Principal and Principal approval/publication for the relevant sections.

- Security/concurrency follow-up: section-assignment RLS now qualifies the outer school/member keys to prevent cross-school reads, and the IHLink Super Administrator is explicitly authorized to view/manage section appointments. Form Master submission locks the scoped Draft result rows before completeness validation and workflow insertion.

- Final roster consistency guard: approval now verifies that the learner's selected-session class still matches the class captured at Form Master submission. A class transfer after submission forces a fresh Form Master handoff instead of allowing approval under a stale class assignment.

## Stage C role-based result lifecycle hardening — 2026-11-08 (PR #133; proposed only)

- Extended the proposed Stage C result workflow in migration `20261108120000_schoolpro_role_responsibility_and_result_lifecycle.sql`: score writes are limited to the active teacher allocation for the exact class, subject and session; additional review/admin responsibilities do not grant a score-entry bypass.
- Added a scoped class subject-teacher roster RPC for Form Masters and authorized class/section/school reviewers. Ordinary subject teachers see only their own allocation.
- Broadsheet now loads active subject allocations through the RPC and shows class workflow status/correction instructions. Removed partial class/selected-result approval actions that bypassed the complete section handoff.
- Section approval now advances the class workflow state for the section. Final approval checks complete section-approved results. Approved/published result reopening is guarded by an Exam Officer-authorized class/section correction batch; the individual-result correction route is retired.
- Replaced the individual correction UI with a class-wide reopening request, explicitly warning that no score changes until the Exam Officer authorizes reopening.
- Added My School Responsibilities navigation to account settings so a staff account holding multiple teaching, Form Master, section leadership, Exam Officer or school administration responsibilities can move between its authorized workspace views. Navigation does not grant permissions.
- CI follow-up from run `42485443355` found three issues: the selected-student publication SQL had unbalanced parentheses; the disposable section-leadership fixture used invalid dollar quoting; and the staff responsibility source regression expected active teaching roles only. Corrected the publication migration, fixture quoting and staff role filter in subsequent commits. Payment-page validation passed; SchoolPro CI and Stage C0 regression failed on those identified issues in the earlier head and must be rerun against the corrected latest head.
- Latest fixes include commits `4224e5c`, `792c60b`, `c29c1c1`, and `45ee633`. These changes remain in PR #133 only. No production Supabase migration, production data change, merge or Render deployment has occurred.
- Required next validation: rerun SchoolPro CI, Stage C0 regression and the disposable PostgreSQL section-leadership lifecycle test against the current PR head; inspect any newly exposed migration or workflow failures before marking Stage C ready for review.


- Latest role/result authority follow-up: introduced a restrictive SELECT policy backed by `private.schoolpro_can_read_result`, so ordinary subject teachers can read only result rows for their own active class/subject/session assignment; Form Masters, appointed section leaders, Exam Officers and school administrators retain their permitted class review scope. Student and guardian result reads remain supported through the existing student/family gates.
- Added a subject-teacher score-write trigger for exact active allocations. Expanded its watched columns to include result status and lock state, and made the unchanged-score fast path require status and lock values to remain unchanged; teachers cannot bypass the lifecycle by changing only workflow metadata.
- Added a regression assertion for status/lock protection and aligned the report-card grade-scale source contract with normalized subject percentage grading.
- The current disposable CI attempt exposed a single-dollar SQL delimiter in the new result-read helper; corrected the opening and closing dollar quotes. The previous report-card assertion mismatch was updated to match the report card's normalized subject-grade calculation. These fixes are proposed only and must be validated on the new head before any readiness claim.
- No production Supabase migration, production data change, merge or Render deployment has occurred.


- Follow-up lifecycle hardening: the effective result-write helper now permits score writes only for the active teacher/class-teacher member with the exact active class, subject and session allocation. Form Masters, Section Heads, Exam Officers and school administrators retain review authority but do not gain score-write permission from those responsibilities alone.
- Added a restrictive result-row read gate: ordinary subject teachers see only their allocated subject rows; the Form Master for the class, appointed Section Head, Exam Officer, school administrator and Super Admin receive only their permitted review scope. The Broadsheet loads the active subject-teacher roster and workflow summary through scoped RPCs.
- Section Head approval, Exam Officer publication and Exam Officer correction reopening are controlled lifecycle transitions. The subject-write trigger requires transaction-local RPC markers for these status/lock changes, preventing direct client updates from bypassing the workflow.
- A Section Head can return submitted or section-approved class results for correction. If already approved, the RPC restores the class rows to unlocked Draft, records the correction note, and requires the Form Master to resubmit before section approval can happen again.
- Exam Officer final approval moves the workflow to `exam_approved`; only the Exam Officer publication RPC can publish and lock the whole school scope. The workflow status is then synchronized to `published`. Approved/published correction reopening requires a pending class/section batch containing the exact result row.
- Results lifecycle RPCs now enforce the Results module subscription gate. Disposable PostgreSQL coverage was expanded for own-subject read/write boundaries, Form Master review, section return/resubmission, direct status/lock bypass rejection, final Exam Officer publication and correction reopening.
- Latest validation attempt on the code head before this handover update: Stage C0 regression and SchoolPro CI were queued/in progress; do not mark the PR ready until the disposable migration and lifecycle tests finish on the latest code head. No production Supabase migration, production data change, merge or Render deployment has occurred.


### Stage C approval-authority consistency — 2026-11-08 (PR #133; proposed only)

- Corrected a gap in the section-wide and class-scoped Section Head approval RPCs. They previously checked only for an active appointment and could admit a staff member whose current role was not eligible for that section, or a Vice Principal whose authority had been superseded by an active Principal appointment.
- Both RPCs now call `private.schoolpro_member_leads_class`, the shared authorization predicate that validates the member's active role, section appointment, school/class scope and Principal-over-Vice-Principal precedence. Section-wide approval requires at least one class in the selected section for which the caller passes that same predicate.
- Added source-contract assertions so the two approval entry points cannot silently drift from the shared authority rule.
- This is a proposed SQL/source change in PR #133. No production migration, production data write, merge or Render deployment has occurred. The source-contract regression and the section-leadership disposable PostgreSQL job are included in the existing SchoolPro CI workflow; both are awaiting the current queued run.


- Validation clarification: the section-leadership PostgreSQL fixture has a second Stage C authority phase that does apply migration 20261108120000. That phase is extended to verify Principal precedence in both the section-wide and class-scoped approval RPCs. The separate earlier section-workflow phase continues to exercise the 20261108118000/20261108119000 migrations.

- Added disposable PostgreSQL coverage after migration 20261108120000 is applied: a Vice Principal and Principal are both actively appointed to Senior Secondary; the VP is denied both section-wide and class-scoped approval, while the Principal retains section authority. The source-contract regression requires these assertions.

- Latest CI at head `c25efb5029ab7cef25ff9acf4da94be19189fdef`: SchoolPro CI run `42494277979` (run #3024) is queued, including the `validate` source-contract job and the `Section leadership authorization (disposable PostgreSQL)` job. Stage C0 regression run `42494277970` and payment-page validation run `42494277889` are also queued. No test pass is claimed yet. The combined status still reports a legacy Vercel failure context; it is not a Render deployment result and Vercel is not the SchoolPro host.


### Section-head appointment eligibility clarification — 2026-11-08 (PR #133)

- Updated the policy per the user's clarification: an active school staff member may be formally appointed to Nursery, Primary, Junior Secondary, Senior Secondary, or more than one section. The only excluded staff role is ordinary `teacher` (Subject Teacher); parent and student accounts are also ineligible because they are not staff.
- This means Class Teachers/Form Masters, Head Teachers, Vice Principals, Principals, Exam Officers, administrators, proprietors, and other active school staff roles can be appointed. A Class Teacher appointment does not grant additional subject score-entry rights; those remain constrained by active subject allocation.
- An active Principal appointment still has precedence in that section. Other staff appointments cannot exercise section-head authority in a section with an appointed Principal.
- Updated the Staff & Access page to show section appointment controls for every eligible staff role, rather than only Head Teacher/VP/Principal. The database RPC, read/review predicates, and role-change pruning now apply the same eligibility rule.
- Added a disposable PostgreSQL integration assertion that Class Teacher is eligible and ordinary Subject Teacher remains ineligible.
- No production migration, production data write, merge, or Render deployment has occurred. CI must validate the latest branch head before merge.


### Result workflow immediate UI synchronization — 2026-11-08 (PR #133)

- Fixed a broadsheet usability gap: successful Form Master submission, Section Head class/section approval, correction return, Exam Officer final approval, and whole-school publication now reload the selected class review sheet and workflow summary immediately. Users no longer need to click Generate again just to see the committed lifecycle state.
- Refresh failures do not undo or misrepresent the database transition; the RPC remains authoritative, and the displayed sheet/workflow is updated only when its corresponding read succeeds.
- Added source-contract assertions for the refresh helper and successful-transition refresh calls.
- Proposed frontend/test changes only. No production migration, production data write, merge or Render deployment has occurred; CI validation is still required.


### Correction reopening queue live synchronization — 2026-11-08 (PR #133)

- The Broadsheet now refreshes the pending class/section correction queue immediately after a new reopening request is submitted and after the Exam Officer approves or rejects a request.
- When an approved request affects the currently selected class, the class review sheet and workflow summary are refreshed as well, so the newly reopened Draft state is visible without a manual Generate action.
- Added source-contract assertions for queue refresh and affected-class refresh. These are proposed frontend/test changes; CI has not yet validated the latest head. No production migration, production data write, merge or Render deployment has occurred.


### Stage C — section reopening decision refreshes affected class view (2026-11-08)

- Corrected the Exam Officer correction-reopening decision flow in `SchoolProBroadsheet.tsx`: after an approved or rejected section-wide reopening request, the currently selected class broadsheet and workflow summary now refresh when that class belongs to the requested section (same term/session). Previously, the correction queue refreshed but the selected class view refreshed only for class-scoped requests.
- The correction queue continues to refresh immediately after either decision. No extra database query or schema change was introduced.
- Added a source-contract regression asserting section-scope matching for the selected class.
- Changes are confined to PR #133's draft branch. No production data or Supabase schema was changed; no merge or Render deployment occurred. CI validation remains pending.


### Stage C — requester-visible correction request tracking (2026-11-08)

- Added `20261108121000_schoolpro_correction_requester_visibility.sql` with a narrow SELECT RLS policy allowing an authenticated user to read only correction-batch records where `requested_by = auth.uid()`. Existing Exam Officer, school administrator and Super Admin review visibility remains intact; correction-batch item snapshots remain restricted to reviewers.
- Added a **My result correction requests** panel to the staff broadsheet. It shows the signed-in staff member's latest 20 requests, scope, academic period, reason, pending/approved/rejected status and any Exam Officer review note. It does not grant requesters authority to approve, reject or reopen results.
- Request history refreshes after a new request and after a review decision. The existing Exam Officer pending queue remains separate.
- Extended `scripts/test-schoolpro-correction-review-atomicity.mjs` to assert the requester-only RLS predicate, user-scoped query and status/review-note UI. The existing CI job already invokes this regression script.
- Proposed migration and frontend changes are on PR #133 only. No production Supabase changes, merge or Render deployment occurred. CI has not yet validated this latest increment.


### Stage C CI correction — section leadership UI contract (2026-11-09; PR #133)

- Corrected `scripts/test-schoolpro-section-leadership.mjs` after the latest CI run exposed stale source assertions that still expected the former Head Teacher / Vice Principal / Principal-only UI rules.
- The regression now verifies that appointment controls are rendered only for active staff, that all staff roles other than ordinary Subject Teacher, parent and student are eligible, and that the old role-specific UI restrictions do not return. Existing database, integration, Principal-precedence, and score-entry boundary assertions remain in place.
- This is a test-only correction to match the already-implemented and user-confirmed appointment policy. Commit: `ac20ec30ab939db286cd903a24dd36304ae5b54b`. CI must rerun against this head; no production Supabase change, merge, or Render deployment has occurred.


### Stage C result lifecycle CI correction — 2026-11-09 (PR #133; proposed only)

- The 2026-11-09 CI run exposed that the result-row trigger did not enforce RPC-only transitions: a direct authenticated status update could attempt Section Head approval, and the trigger's old role list did not use the new all-active-staff appointment policy. It also left the workflow synchronization expecting the pre-Exam-Officer state during publication.
- Replaced the trigger logic in proposed migration 20261108120000_schoolpro_role_responsibility_and_result_lifecycle.sql. Section approval now requires the transaction-local marker set by the complete-section approval RPC, a submitted Form Master workflow row, and the shared role-/section-/Principal-aware schoolpro_member_leads_class predicate. Publication requires the Exam Officer publication marker, an exam_approved workflow row and Exam Officer authorization. Direct client status changes are rejected.
- Updated workflow synchronization so publication advances exam_approved to published. The source-contract test now asserts both RPC markers, the shared authority predicate and the corrected workflow state; fixed the escaped school_admin responsibility assertion.
- This is proposed migration/test code in PR #133 only. It has not been applied to Supabase production, merged or deployed to Render. CI must validate the latest head.


### Stage C CI follow-up — enum-safe staff eligibility and focused fixture scope — 2026-11-09

- CI confirmed the `school_member_role` enum contains school staff roles only; it has no `parent` or `student` values. The proposed authority migration now excludes the ordinary `teacher` enum role. Parent/student accounts remain ineligible because they are not school staff/member roles; the staff UI continues to exclude those account types. This removes invalid enum literals from the appointment predicates and role-change pruning trigger.
- Corrected the Principal-precedence source assertion to match the migration's actual dotted identifier syntax.
- The isolated section-leadership SQL fixture applies the section-appointment and Form Master workflow migrations, not the later final-authority migration. Removed direct status-update assertions from that older fixture rather than weakening production enforcement. The RPC-only approval/publication markers and trigger guards remain in the final authority migration and are asserted by the Stage C source-contract test; they must be exercised by the full migration/result-workflow integration path.
- CI had exposed a fixture/migration boundary mismatch: the isolated test was asserting behavior introduced only by a later migration. No production database changes, merge, or Render deployment.


### Stage C migration parser correction — 2026-11-09

- CI isolated a malformed dollar-quote terminator on the new `private.schoolpro_prune_section_leadership_role()` trigger function. It ended with `$;` instead of `$$;`, causing the following enrollment-reader SQL function's `WITH` clause to be parsed in the wrong context. Corrected the terminator; the eligibility predicate remains unchanged. This is a proposed migration correction only, not applied to production.


### Stage C repeat CI parser and assertion correction — 2026-11-09

- CI showed the active `private.schoolpro_prune_section_leadership_role()` terminator still contained `end\n$;` immediately before the trigger declaration. Corrected it to `end\n$$;`. This was the direct cause of PostgreSQL parsing the following enrollment-reader `WITH leaders AS MATERIALIZED` query as part of the preceding function body.
- Corrected the section-leadership source test's Principal-role regex to match the actual `principal_m.role='administrator'` identifier rather than requiring a literal backslash before the dot.
- Both changes are proposed on PR #133 only. Awaiting fresh CI; no production Supabase change, merge, or Render deployment.


### Section-leadership disposable integration fixture alignment — 2026-11-09

- The section-leadership integration fixture intentionally applies the appointment, Principal-role, and Form Master workflow migrations (through `20261108119000`), not the later full result-authority migration (`20261108120000`). Its SQL test incorrectly invoked section approval, Exam Officer, and reopening RPCs introduced only by that later migration; the disposable fixture consequently failed with a missing `schoolpro_approve_section_results` function even though the production migration itself parsed.
- Narrowed this fixture to the behavior its migration set actually installs: explicit Nursery/Primary/Junior Secondary/Senior Secondary appointments, per-section student/class read scope, rejection of ordinary Subject Teacher appointments, appointment removal, and automatic pruning after a staff-role change. Result lifecycle RPC and Principal-precedence source contracts remain asserted against the full authority migration by the companion source-contract test.
- This changes CI test scope only; no production schema/data, merge, or Render deployment.


- Follow-up fixture contract cleanup: removed stale source-test assertions for result-approval, Exam Officer, reopening, and enrollment-reader scenarios from the section-leadership disposable fixture. Those scenarios are not loaded by its migration set; the remaining assertions now match only the section appointment/read-scope cases actually executed by that fixture. The separate result-workflow source contract still asserts the full Stage C lifecycle RPC surface.


### Stage C enum comparison and Principal source-contract CI corrections — 2026-11-09

- C0 disposable Supabase migration execution found a comparison between the `schoolpro_result_status` enum column and a text parameter in `private.schoolpro_result_scope_matrix_state`. Added an explicit cast of `p_result_status` to `public.schoolpro_result_status`, preserving the RPC's text argument signature while making the comparison type-safe.
- Full CI source-contract failure was an over-escaped regular expression for `principal_m.position_title`; corrected the assertion to match the literal SQL identifier and Principal check.
- These are branch-only corrections on PR #133. No production Supabase migration, merge, or Render deployment.


### Stage C CI corrections — 2026-11-09 (latest)
- The latest Stage C CI exposed a real gap in `private.validate_subject_assignment()`: active allocations checked school ownership and teaching role but did not require an active staff membership or a non-archived class. The validator now enforces active membership and non-archived class state for active allocations, while preserving ended allocation history.
- The result-workflow source test expected an obsolete inline refresh expression. Updated it to assert the current explicit selected-class impact check and conditional refresh after the correction queue reload.
- Scope: branch-only migration and source-contract test updates. No production Supabase migration/data changes, PR merge, or Render deployment.
- Commit sequence: validator fix `e79fa8b9fbbe2dd0db3ef57456bd4ab080a7eef8`; workflow assertion fix `d199376b1f9befd048f98d0efcf41b27d060aa5b`.
- Fresh CI validation is pending; do not treat these fixes as passed until the new runs complete.


### Stage C follow-up — section reader active-class scope and appointment contract (2026-11-09)
- The C0 disposable Supabase regression found that the section-head class/student reader helpers checked active membership and active appointment but did not exclude archived classes. Both helpers now require the resolved class to be non-archived.
- Corrected the Stage C source-contract test to match the agreed eligibility policy: ordinary Subject Teacher role is excluded; Class Teachers/Form Masters and every other active staff role remain eligible for formal section appointment.
- No production migration, data write, merge or Render deployment. Fresh CI validation pending.


### Stage C final-authority schema regression — 2026-11-09
- Extended the C0 disposable-Supabase SQL regression to inspect the final Stage C section-authority functions installed by the complete migration chain.
- The regression now fails if the final appointment RPC does not require active membership, exclude only ordinary Subject Teachers, and require authorized school administration; it also checks that both current-class and historical-student section authority enforce Principal precedence.
- This closes a test-coverage gap: the older isolated section-leadership fixture stops before the final authority migration, so its role-specific appointment checks alone could not prove the final all-active-staff eligibility contract against the complete schema.
- Branch-only CI test change, commit `8c061f94e6d1cbb0485dace0ae6e01847a3ba04c`. No production Supabase migration/data changes, merge, or Render deployment.


### Stage C Principal-first section review UI correction — 2026-11-09
- The database already enforced Principal precedence, but the Class Broadsheet UI treated every active section appointee as an approver. This could expose approval/return/reopening controls to a Vice Principal or another appointee even when an active Principal was appointed to that same section; the RPC would reject the action, but the UI was misleading.
- The broadsheet now loads active section appointments and active administrator members, identifies sections with an appointed Principal, and exposes section-head controls only to that Principal for those sections. Other sections continue to honor their own explicit appointee. Principal identity is matched using the active administrator membership and normalized position_title.
- Added source-contract assertions for active Principal lookup and suppression of non-Principal section controls under Principal precedence.
- Branch-only frontend and test changes, UI commit c7283e2651fbc2c1b222e18b62e294dc65200b76; no production Supabase changes, merge, or Render deployment. CI validation is pending.


### Stage C Principal-first review UI typecheck correction — 2026-11-09
- The first CI run after the Principal-precedence UI change found a TypeScript narrowing issue: `member.data` was referenced after an awaited Principal lookup, where the compiler correctly no longer guaranteed it was non-null.
- Captured the validated active member ID before subsequent asynchronous queries and reused that stable ID for responsibility, teaching-allocation, and section-appointment filtering.
- Fix committed as `5ae50b7c3ca2921e5e3f70cd9127cbb7476ec4c4`. CI must rerun against the latest branch head; earlier failures on the preceding head are not treated as final validation.
- No production database writes, merge, or Render deployment.


## 2026-11-09 Stage C review-sheet ranking regression follow-up
- Latest Stage C head `debe93af27e20b2d98f758ce78bc0b800dd7894d` passed payment validation and C0 regression. Main SchoolPro CI failed only because the new ranking source-contract assertion expected a direct `LEFT JOIN schoolpro_results`, while the function correctly builds a roster CTE and then left-joins its `marks` CTE. Updated the assertion to verify the actual roster-preserving join (`schoolpro_students` roster plus `LEFT JOIN marks`). No application or database behavior changed in this correction.
- No production migration applied, no production data written, no merge, and no Render deployment.

- Follow-up review of the replacement function found it also needed to preserve the existing published-result columns/positions and allocated-subject summary introduced by the prior broadsheet migration. Rebuilt the new migration from that established function and changed only the rank eligibility/order behavior: full roster retained, unassessed class and published positions null, published totals/scores and pre-mark allocated subjects retained. Extended the source-contract test to protect these existing fields. This is still a draft-branch migration only; it has not been applied to production.


## 2026-11-09 Stage C workflow concurrency hardening
- Added `private.schoolpro_lock_result_scope` to lock the selected class/section/school classes, selected-session roster members, active subject allocations, saved result rows and workflow rows before completeness/state validation and lifecycle transitions.
- Form Master submission now performs its complete Draft-matrix check only after those locks are held. Section Head class/section approval, Exam Officer final approval and whole-school publication also acquire the exact scope locks before checking the workflow state. This closes the avoidable time-of-check/time-of-use window where a concurrent mark, roster or allocation edit could race a review transition.
- Added source-contract assertions that require the locking helper and all five transition call sites. Proposed migration only; no production Supabase changes, data writes, merge or Render deployment.


## 2026-11-09 — Stage C result-scope locking CI correction
- Corrected the result-scope lock helper's PL/pgSQL dollar-quote delimiter and the Node source-contract regex escaping after CI identified both issues.
- Re-run the full SchoolPro CI and Stage C0 migration replay before treating this head as validated. No production migration or deployment was performed.


## 2026-11-09 — Stage C result-scope lock CI corrections
- Corrected the PL/pgSQL function-body delimiter for `private.schoolpro_lock_result_scope` from `as $` to `as $$`; the disposable Supabase migration replay had stopped at this helper declaration.
- Corrected the `test-result-workflow.mjs` ordering assertion so it matches the actual SQL sequence using a single regex whitespace escape; the previous assertion was over-escaped and failed despite the lock call being in the correct position.
- Both changes are committed on `feat/schoolpro-stage-c-assessment-results-workflow`; CI must rerun against the new head before this concurrency hardening is considered validated. No production migration, merge, or Render deployment was performed.


## 2026-11-09 — Follow-up: result-scope lock delimiter replay
- The Stage C0 full migration replay confirmed the result-scope lock helper still had a single-dollar opening delimiter. Corrected that exact helper declaration to `as $$` and committed the migration correction.
- SchoolPro CI and payment validation passed on the preceding source-test correction commit; Stage C0 replay remained blocked by this SQL delimiter and is rerunning on the new migration commit. No production migration, merge, or Render deployment was performed.


### Result-scope lock helper delimiter correction — 2026-11-09
- The latest disposable-Supabase Stage C0 regression exposed a second SQL dollar-quote terminator typo in `private.schoolpro_lock_result_scope`: its PL/pgSQL body opened with `as $$` but closed with `$;`.
- Corrected the function terminator to `$$;` so the following SQL helper definition is parsed as a separate function rather than as stray SQL.
- Proposed migration only; no production database changes. CI rerun is required against the new branch head.


### Result-scope lock helper terminator replay correction — 2026-11-09
- The next full disposable-Supabase migration replay showed that the earlier delimiter correction had not reached the committed migration: `private.schoolpro_lock_result_scope` still ended with `$;`. Replaced that exact terminator with `$$;` in the branch migration file and verified the surrounding function boundary. This is the specific parser error reported at the subsequent `WITH roster` statement.
- Re-run the complete Stage C0 migration replay and main CI against the new branch head before marking PR #133 ready. No production migration, production data write, merge or Render deployment.


### Result-scope lock helper terminator replay correction — 2026-11-09 (verified file update)
- The disposable-Supabase replay showed `private.schoolpro_lock_result_scope` still ended with `$;` in the committed migration. Replaced that exact terminator with `$$;` and committed the migration file correction. This ensures the next `WITH roster` helper starts outside the preceding PL/pgSQL body.
- CI must complete against the corrected branch head before PR #133 is marked ready or merged. No production migration, production data write, merge or Render deployment.

### 2026-11-09 — C0 CI database-port isolation
- Latest-head SchoolPro CI and payment-page validation passed. The C0 regression job failed before database tests because the disposable Supabase PostgreSQL container could not bind default host port 54322 (already in use on the runner).
- Updated `.github/workflows/schoolpro-c0-regression.yml` to configure a dedicated local database port (54332) for this job and use that port for baseline restore, migration replay, and SQL regression tests. This is CI-only; it does not change production Supabase configuration or data.
- Commit: `92860d80dd8fd9a16c2dc2093ae29960af7a3368`. Fresh workflow validation is required on this new branch head before PR #133 can merge.


### Existing-student bulk onboarding — 2026-11-09 (PR #134)
- Added an Excel (.xlsx) and CSV bulk-import panel to the SchoolPro student workspace. The importer requires Admission Number, First Name, Last Name and Class; supports Middle Name, Gender, Guardian Name, Guardian Phone, Guardian Email and House; maps class/house labels only to active records in the selected school; assigns the selected working academic session; and marks every row as `existing`.
- Validation checks required columns, duplicate headings, duplicate admission numbers within the file, existing admission numbers in the same school, invalid gender/email values, unknown classes/houses, and a 500-row batch ceiling. No records are written during preview; the operator must explicitly run Import after a clean validation.
- A single school-scoped insert writes the validated batch. Explicit house selections are applied through the existing `schoolpro_assign_student_house` RPC; students without an explicit house retain the balanced automatic allocation trigger. If a post-insert manual house assignment fails, the UI reports it clearly rather than claiming all assignments succeeded.
- Corrected the individual-enrolment form reset to preserve the required `house_id` state field (CI had identified this TypeScript error on PR #134).
- Added a CI source-contract regression for spreadsheet parsing, validation, duplicate prevention, session assignment and batch limits. Branch-only changes; no production migration, production student writes, merge, or Render deployment.


### Existing-student CSV template — 2026-11-09
- Added a header-only downloadable CSV template directly in the existing-student bulk-import panel. Its columns match the importers required and optional field aliases, avoiding manual header typing and reducing spreadsheet-format errors.
- The template contains no sample student records; operators populate it with their schools real register. Class and house values must still match active records in the selected school workspace.
- Added source-contract assertions for the template filename and visible download link. This is a frontend-only improvement; no database schema, production data, migration, merge or deployment is included in this change.


## 2026-11-09 — Existing-student import register expansion and roster layout

- Expanded the existing-student download from a narrow CSV header list to a multi-sheet Excel workbook plus CSV alternative.
- Excel workbook fields: admission number; first, middle and last names; date of birth; formula-derived age; gender; section; class; arm; house; guardian first, middle and surname; guardian phone and email.
- Workbook includes an Instructions sheet and 500 prefilled age-formula rows. Age is derived from date of birth rather than stored as a stale age value.
- Import maps section/class/arm to active class records in the selected school, maps house names to active houses, combines separate guardian name fields into the existing guardian contact-name field, and stores date_of_birth using the existing column. No school/class/house/session IDs are required in the workbook.
- Existing admission number duplicate checks, 500-row batch limit, selected-session enrollment, and validation-before-write behavior remain in place.
- Expanded the student roster card across the full desktop grid. Its existing constrained horizontal-scroll region and minimum table width preserve usable mobile behavior.
- No production migration or production records were changed for this UI/import enhancement. Database inspection confirmed date_of_birth already exists; guardian name parts are combined into the existing guardian_name field.
- Pending: validate the latest PR #135 head through CI. Do not merge or deploy without explicit approval.


## 2026-11-09 — Stage C requirements: school calendar, activities and continuous academic sessions

### School calendar configuration
- During school onboarding, administrators must be able to configure the academic calendar, including the academic year/session, term boundaries, instructional days, weekends, holidays, vacations, staff/student activities, examination periods and other school-defined events.
- Provide a dedicated School Calendar page after onboarding so authorised school administrators can create, edit, review and publish calendar events throughout the year.
- Support recurring weekly activities with configurable weekday, start/end dates, time and activity details, alongside one-off dated events and full-year calendar planning.
- Calendar configuration must support the attendance engine: school-open/instructional dates are authoritative for attendance eligibility and denominator calculations. Holidays, weekends and non-instructional dates must not be counted as open school days unless explicitly configured as instructional.
- Keep calendar changes auditable and preserve historical calendar versions/records so past attendance and reports are not silently recalculated when a future calendar is edited.

### Continuous academic-session lifecycle
- Remove hard-coded assumptions that the active session is only 2026/2027. Schools must be able to configure successive sessions such as 2027/2028, 2028/2029 and later without code changes.
- When a school completes its current academic session, the system should support preparing the next sequential session. During plan configuration or successful annual plan renewal, it should guide the administrator to configure the next session and, where the school has enabled the policy, automatically create a draft next session using the next sequential year range.
- Session creation/activation must be idempotent and must not duplicate sessions on repeated renewal events. Subscription renewal must not silently activate a new academic session or overwrite dates; administrators must be able to review and confirm the proposed dates before activation.
- Preserve historical sessions, term calendars, enrolments, assessments, attendance, results and certificates. The selected working session remains explicit; changing the working session must not promote students or alter historical records.
- Support schools whose academic year does not follow a simple September-to-July pattern by allowing administrators to configure actual start/end dates and term boundaries rather than deriving dates solely from the session label.

### Dependencies and acceptance criteria
- Calendar and session configuration must be available during onboarding and remain editable through dedicated school administration pages.
- Attendance calculations must consume the configured calendar, not assume every weekday is an open school day.
- Next-session generation must be sequential, reviewable, idempotent and independent of destructive changes to the prior session.
- Add automated tests for weekly recurring events, full-year calendar coverage, holidays/non-instructional days, session rollover, repeated renewal idempotency, historical-session preservation and attendance calendar integration.
- These are requirements to implement and verify in Stage C; no production workspace data or calendar/session records are to be created until the user provides explicit end-to-end verification instructions.


## 2026-11-09 — Stage C requirements: calendar-driven attendance and punctuality

### Calendar-authoritative attendance
- Calculate the number of school-open/instructional days for a selected school, academic session and term from the published school calendar. Exclude weekends, holidays, vacations and non-instructional dates unless an authorised calendar entry explicitly marks the date as instructional.
- Track each learner's present days, absent days, late days and (where configured) excused/approved absences. Keep late arrivals distinct from absences; a late student is not automatically absent.
- Calculate attendance percentage using present days divided by eligible school-open days for the learner's enrolled period, multiplied by 100. Expose the denominator and the counts so staff and families can understand the calculation.
- Calculate punctuality separately from attendance. Punctuality needs an explicit count of on-time and late arrivals (or date-level arrival states); it cannot be inferred from present/absent totals alone. Schools configure punctuality thresholds and grade bands, with versioned rules applied consistently to the selected session/term.
- Prevent attendance entries on calendar dates marked closed/non-instructional. Reconcile present, absent, late and approved-excuse states against eligible dates and flag missing/unresolved dates rather than silently treating them as present or absent.

### Flexible attendance capture
- Retain the existing Form Master daily, class-scoped attendance workflow.
- Add an authorised cumulative/periodic attendance entry path so a school can record a verified term or date-range summary without requiring a Form Master to submit a daily screen for every date.
- Prefer date-level bulk capture/import for auditability. Where schools enter aggregate totals, retain the source period, operator, timestamp, approval/reconciliation status and the exact totals; do not fabricate individual daily records from an aggregate.
- Provide bulk class attendance entry for a selected date/range, validate dates against the calendar and roster, and support authorised corrections with an audit trail.
- Restrict daily and cumulative entry to authorised school roles; ordinary subject teachers must not receive attendance write access by default.

### Attendance reporting and acceptance
- Provide student, class, section and school summaries for open days, present, absent, late, approved absences, attendance percentage, punctuality percentage and punctuality grade.
- Make attendance and punctuality summaries available to authorised staff and, subject to school publication policy, student/guardian reports.
- Preserve historical attendance and the calendar/rule version used for each calculation so later calendar or grading changes do not silently rewrite prior reports.
- Add tests for holidays/weekends, mid-session enrolment, calendar changes, date-level bulk entry, cumulative entry reconciliation, late-versus-absent treatment, grade-band boundaries, corrections and role-based access.
- These are Stage C requirements to implement; no production attendance records or workspace data are to be created until the user supplies the end-to-end verification instructions.


## 2026-11-09 — Class section correction and duplicate feedback
- The Classes & Arms page now validates recognizable class-name prefixes against the selected academic section (for example, JSS/JS must be Junior Secondary; SSS/SS must be Senior Secondary; Nursery/Primary/Basic must match their corresponding sections) before inserting or updating a class.
- Added an Edit action for existing classes. Administrators can correct a mistaken section/level while preserving the class UUID, Form Master assignment, and all foreign-key-linked class history; this avoids creating a duplicate class or deleting the original record.
- Edit and create share the same school-scoped save path. Duplicate-key errors (PostgreSQL 23505) now receive a direct explanation that the class name/arm already exists and that the existing row should be edited. Other failures return a safe actionable message with the database error code rather than exposing raw SQL diagnostics or silently collapsing all failures into an opaque generic message.
- Added a source-contract regression to CI for section-name validation, stable-ID class updates, school scoping, duplicate feedback, and edit/cancel UI.
- Frontend and automated test changes only. No production class rows were edited, no production migration was applied, and no merge or Render deployment is included.


## 2026-11-09 — Canonical SchoolPro role labels
- Centralized the signed-in school role shown in the shared SchoolPro workspace sidebar. SchoolPro modules no longer display their own hard-coded identity label when the authenticated school role is available.
- Standardized the canonical display labels for `proprietor` (Proprietor) and `administrator` (Administrator). Stored role codes and authorization checks are unchanged; this is a presentation-only correction.
- The update does not change tenant access, permissions, RLS, production data, or Supabase configuration.
- Cross-product “Navigate to My Responsibilities” rollout is tracked separately and remains outside SchoolPro, per the user's instruction.


## 2026-11-10 — Existing-student import access preflight
- Investigated the HA ACADEMY bulk existing-student import failure. Spreadsheet validation succeeds, but the production INSERT is rejected by the `schoolpro_students` RLS policy with SQLSTATE `42501`.
- Confirmed the INSERT policy requires `private.has_school_access(school_id, ['proprietor','administrator'])`; the separate restrictive student-record policy applies to SELECT, not INSERT. A read-only check confirmed the HA ACADEMY owner and active Proprietor membership, and the access helper passed when evaluated with that owner's JWT identity.
- Added a pre-write client check in PR #141 to compare the authenticated Supabase user/session, selected school ID/name, active profile, and owner or active Proprietor/Administrator membership before any student INSERT. A mismatch stops the import with a specific explanation and no student rows are submitted.
- No RLS policy, grants, production student records, or Supabase schema were changed in PR #141. PR #141 was subsequently merged as `8f2204f87ba7bbcf8e47af327c5504dfa9a63757`; its Render deployment was reported Live, but the preflight did not resolve the INSERT rejection. The reported Vercel status is an obsolete integration and is not Render deployment verification.


## 2026-11-10 — Existing-student import database-identity diagnostic (PR preparation)
- Added a separate, explicit **Check Import Access** action to the existing-student bulk-import panel. It calls a read-only database RPC before any import and reports the authenticated database user ID, whether the school owner check passes, whether an active Proprietor/Administrator membership exists, and the shared school-access helper result.
- Added a `SECURITY INVOKER` / `STABLE` RPC design. It rejects unauthenticated or unauthorised callers, only reveals school ownership/membership detail after the shared access helper confirms leadership access, and performs no writes. Execution is revoked from `PUBLIC` and granted only to `authenticated`.
- The diagnostic is deliberately separate from the Import button. Running it cannot insert students or assign houses. The existing import remains unchanged and still requires an explicit operator action.
- Migration is proposed in source control only. It has not been applied to Supabase production; the diagnostic button will report that the RPC is unavailable until the migration is deliberately applied. No production student records or permissions were changed.


## 2026-11-10 — Existing-student import exact-batch RLS preflight (PR preparation)
- Added a read-only SECURITY INVOKER RPC that receives only the selected school UUID and the actual batch's school_id values, then evaluates each value against the same private.has_school_access(..., proprietor/administrator) helper used by the schoolpro_students INSERT policy.
- The importer calls this preflight immediately before each batch INSERT. It reports spreadsheet row numbers only and never sends student names, admission numbers, guardian details, or other student data to the diagnostic.
- The check distinguishes a tenant-ID mismatch in the actual payload from an authorization-context discrepancy. It does not bypass RLS or perform inserts/updates/deletes.
- Proposed source changes only. No production migration application, student writes, RLS policy changes, merge, or Render deployment.


## 2026-11-11 — Existing-student import payload diagnostic PostgreSQL coverage (PR #143)
- Added a dedicated PostgreSQL 16 disposable-database integration test that applies the exact-batch diagnostic migration and exercises the function under the authenticated role.
- Coverage includes an authorised matching batch, a mismatched tenant ID with exact failed-row reporting, malformed UUID input, an empty batch, a non-array payload, inactive account, and missing authentication identity.
- The test asserts the RPC is SECURITY INVOKER, executable by authenticated, not executable by anon or PUBLIC, and does not mutate a write-sentinel row.
- Added the integration test as a separate GitHub Actions job. This is CI-only test infrastructure; it does not create a SchoolPro workspace or touch production records.
- The migration and test remain proposed in PR #143. No production Supabase migration, production student write, merge, or Render deployment is authorised or performed by this change.


### PR #143 CI correction — 2026-11-11
- The first disposable PostgreSQL run exposed a test harness path issue: psql resolves `\\ir` relative to the test script's directory, so the migration include incorrectly resolved under `scripts/supabase/`.
- Corrected the workflow to apply the migration explicitly from the repository root, then run the assertion script separately. The assertion script no longer performs a relative migration include.
- This was a CI harness path failure, not a migration SQL or authorization assertion failure. The corrected job must pass before PR #143 can be considered validated.


### PR #143 disposable PostgreSQL role setup correction (2026-11-11)
- The first corrected CI attempt fixed the migration path, then exposed a second test-harness prerequisite: plain PostgreSQL 16 does not create Supabase API roles `anon` and `authenticated` automatically.
- The migration itself created the diagnostic function successfully; the job stopped at its privilege-revocation statement because the disposable database lacked role `anon`.
- CI now creates `anon` and `authenticated` as `NOLOGIN` roles in the disposable PostgreSQL job before applying the migration. This mirrors the minimum Supabase role names required by the migration and does not affect any hosted project.
- No production migration, permissions, or student data were changed. Awaiting the new CI run.
