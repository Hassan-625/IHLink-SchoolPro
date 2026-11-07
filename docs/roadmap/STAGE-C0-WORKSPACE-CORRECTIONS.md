# Stage C0 — School Workspace Corrections

**Status:** In progress  
**Base:** `main` at the Stage B merge baseline  
**Working branch:** `feat/schoolpro-stage-c0-workspace-corrections`  
**Production changes:** None authorized or performed by this stage kickoff.

Stage C0 is a mandatory stabilization and workspace-administration phase. Stage C (assessments and results) must not begin until C0 acceptance is complete.

## Scope and acceptance criteria

### C0.1 — Active workspace feature visibility
- Make Houses, Games, Sports and Competitions visible to the appropriate school workspace roles.
- Make Plan Upgrade / Subscription visible to authorised school billing managers and workspace owners.
- Expose Advanced Reports when the active school's entitlement includes it and the user's role permits it.
- Distinguish feature entitlement from role permission; do not grant access merely by showing a navigation item.
- Restricted paid features must show an understandable upgrade path where appropriate.

### C0.2 — House selectors
- Replace free-text house selection with a dropdown populated from the active school's active houses.
- Apply consistently to student allocation, competition entries, house points and other house-related forms.
- Persist house IDs, not display labels.

### C0.3 — Workspace deletion request and execution
- Provide an owner-initiated deletion request with reason, explicit confirmation and duplicate-request protection.
- Provide a separate authorised platform review/approval or rejection workflow.
- Execute only approved requests through a server-side, tenant-scoped, auditable process.
- Inventory and handle child records, foreign-key dependencies and school-owned Storage objects.
- Preserve shared platform defaults, global profiles and Auth accounts, unrelated schools, DataSub/IHLink data, required financial evidence and platform audit/security history.
- Define retention exceptions and a recoverable pending/deletion state; do not use broad unscoped deletes.

### C0.4 — School-owned record lifecycle
- Give authorised workspace owners controlled view/edit/archive/delete operations for students, classes, teachers, staff, memberships, parents/guardians and other school-owned records.
- Enforce school scope and role permissions in the database, not only in the UI.
- Use archive/deactivate where hard deletion would break historical academic, financial, safeguarding or audit records.
- Guardian access is a school-owned relationship, not ownership of the global parent profile: suspend or restore the school-scoped link; never delete the global profile or Auth account from this workflow.
- Student exits must use the existing audited transfer/withdrawal lifecycle; do not hard-delete students from the enrolment UI.
- Do not hard-delete classes or staff memberships until a reviewed archive lifecycle and all dependent-record retention rules are implemented.
- Until then, their destructive UI actions must remain unavailable and clearly indicate that archive support is pending.
- Show dependency impact and require confirmation for destructive actions.

### C0.5 — Consistent table scrolling
- Standardise tables/data grids to support horizontal and vertical scrolling when content exceeds the available viewport.
- Preserve usable headers and responsive behaviour on desktop, tablet and mobile.
- Avoid clipping, page-wide overflow and inaccessible columns/rows.

### C0.6 — Security and acceptance
- Add targeted frontend, database/RLS and regression tests for each workstream.
- Verify tenant isolation, role permissions, plan entitlements, deletion dependencies and audit evidence.
- Record actual code, migration, test and deployment outcomes in the master migration handover.

## Implementation sequence

1. Trace current route registration, sidebar filtering, plan entitlements and existing report/competition pages; fix navigation only where backed by existing authorization.
2. Standardise house dropdowns and shared table overflow behaviour.
3. Inventory school-owned entities, foreign keys, triggers, storage paths and existing deletion capabilities before implementing owner deletion.
4. Implement deletion requests, platform review and a narrowly scoped server-side execution mechanism.
5. Run focused acceptance tests and update the master handover.

## Non-negotiable safeguards

- Supabase remains the only SchoolPro database; Render remains the frontend host.
- No production schema migration, production data deletion, Storage deletion, or deployment without explicit user approval.
- Do not create test school workspaces or fabricate operational records.
- Do not delete global `profiles` or `auth.users`, shared templates/permissions, unrelated tenant data, or required financial/audit evidence.
- Preserve unrelated untracked Codespace files; do not stage or delete them.
- A UI control is not considered complete unless the corresponding backend authorization and data-integrity behaviour are verified.


### C0.4 implementation findings — class and staff lifecycle

Read-only production inspection on 2026-11-07 found that neither `schoolpro_classes` nor `schoolpro_members` currently has archive/deactivation columns. Their existing RLS policies still include authenticated DELETE policies for school leaders (and a Super Admin all-operations policy). Hiding destructive UI controls is therefore only a UI safeguard; it does not close the backend deletion path.

**Class lifecycle requirements before enabling archive actions**
- Add a school-scoped archive state and audit metadata; keep the class row and its UUID so historical attendance, assignments, result submissions, enrollment history, promotions, lesson notes, CBT records and timetables remain linked.
- Remove direct authenticated DELETE policies for classes; retain the existing owner/admin authorization for create/update only.
- Provide a narrowly scoped archive/reactivate RPC that validates the active school, role, class ID and reason, records actor/time, and cannot alter `school_id` or historical child rows.
- Prevent new enrolments, attendance, assignments, timetables, Form Master assignments and other operational writes against archived classes. Existing history must remain readable by users with legitimate historical access.
- Update every active-class selector and write path, not only the Classes page, before exposing the archive action.

**Staff membership lifecycle requirements before enabling archive actions**
- Add a membership-level active/suspended state and audit metadata; do not delete the membership row, global profile or Auth account.
- Remove direct authenticated DELETE policies for memberships; retain only scoped owner/admin create/update operations.
- Update `private.has_school_access` and every direct membership/role check so suspended memberships cannot authenticate into that school's operational data or receive new assignments, while ownership and Super Admin access continue to work.
- End or detach active teaching, House Master, section-leader, judge and governance assignments through audited, school-scoped transitions; retain payroll, leave, board, permission and other historical records.
- Preserve self-membership reads only where needed for account/workspace discovery; do not let that policy restore operational access.

**Acceptance blocker:** The production helper `private.has_school_access(uuid, school_member_role[])` currently treats any matching membership as active because `schoolpro_members` has no status column. `private.schoolpro_can_read_class(uuid)` also reads membership rows directly. A partial archive migration would therefore be unsafe. Implement the schema, helper/policy changes, all relevant assignment/write guards, UI filters and SQL regression tests together in one reviewed migration series. Do not enable archive/reactivation UI until that complete path is validated.


### Class and staff lifecycle dependency inventory — 2026-11-07

The current production catalog exposes the following direct class references, which must be classified before archive guards are enabled:

- Operational/assignment candidates: `schoolpro_assignments`, `schoolpro_attendance`, `schoolpro_cbt_eligibility`, `schoolpro_subject_assignments`, `schoolpro_timetable_entries`.
- Potentially historical or mixed-purpose references requiring per-workflow review: `schoolpro_calendar_events`, `schoolpro_cbt_tests`, `schoolpro_class_result_submissions`, `schoolpro_enrollment_history`, `schoolpro_lesson_notes`, `schoolpro_question_bank`, `schoolpro_students`.

Direct staff membership references include `schoolpro_board_members`, `schoolpro_competition_judges`, `schoolpro_house_master_assignments`, `schoolpro_leave_requests`, `schoolpro_library_loans`, `schoolpro_member_permissions`, `schoolpro_payroll_records`, `schoolpro_section_leaders`, and `schoolpro_subject_assignments.teacher_member_id`; `schoolpro_classes.form_teacher_id` is also a membership reference. These must not be bulk-deleted during suspension. Active appointment rows need an audited end/revoke transition, while payroll, leave and governance history must remain.

The next migration must be delivered as a coordinated unit: additive lifecycle columns and append-only audit records; safe archive/reactivate RPCs; removal of direct DELETE policies; updated active-membership authorization helpers; assignment eligibility guards; and SQL regression tests. The application must then filter active classes/members from operational selectors while retaining historical records in history/report views. Do not ship a partial migration that changes `has_school_access` without updating direct membership checks and the House Master, Form Master, section leadership, competition judge, payroll and leave workflows.


### Authorization call-graph and RLS policy findings — 2026-11-07

Read-only production catalog inspection confirmed that the current class/member authorization cannot be safely fixed by changing one helper:

- `private.has_school_access(uuid, school_member_role[])` currently accepts a membership row based on school, user and role only; it does not test membership lifecycle state. It also intentionally grants active profile access to Super Admins and school owners. Preserve those owner/platform-admin semantics while excluding suspended memberships.
- `private.schoolpro_can_read_class(uuid)` has direct membership-role, Form Master and subject-assignment checks, plus the section-leader helper. Each membership-derived branch must require an active membership. Guardian/student historical reads need separate treatment and must not be suppressed merely because a class is archived.
- `private.schoolpro_member_leads_class(uuid,uuid)` directly joins section leadership to membership and likewise needs active-membership enforcement.
- Additional production functions directly depend on class/member rows, including `schoolpro_class_staff_directory`, `schoolpro_coordinator_classes`, `schoolpro_house_master_roster`, `schoolpro_is_house_master`, `schoolpro_lesson_author_scope`, `schoolpro_lesson_leader`, `schoolpro_member_leads_student_section`, `schoolpro_set_board_role`, `schoolpro_set_form_master`, `schoolpro_set_section_leader`, `schoolpro_teacher_allocation_visible`, `schoolpro_validate_house_master`, `schoolpro_validate_operational_tenant`, `validate_schoolpro_member_permission_tenant`, `validate_schoolpro_subject_assignment`, and public operational RPCs for competition judges, library loans, promotions, result publication and staff access. Their current definitions must be reviewed before replacing any of them.
- Production currently has overlapping permissive SELECT policies on classes (`Authorized class lists`, `School users read classes`, `Scoped class lists`) and a Super Admin `FOR ALL` policy. Both classes and members also have a direct school-leader DELETE policy. Dropping only the named school-leader DELETE policy is insufficient while the Super Admin `FOR ALL` policy remains; replace it with explicit SELECT/INSERT/UPDATE policies and retain separate audited platform operations only where required.
- The class/member table grants currently include DELETE to `authenticated`; RLS policy removal must be paired with privilege revocation so there is no alternate API path.

This inventory is a migration design gate. The migration must preserve school-owner and Super Admin access, retain appropriate read access to historic records, block all new operational assignments to archived classes or suspended memberships, and remove direct DELETE capability at both policy and table-privilege layers. No production writes were performed.


### Lifecycle schema baseline and migration sequencing — 2026-11-07

The live schema baseline is now confirmed precisely:

- `schoolpro_classes` currently has only: `id`, `school_id`, `name`, `arm`, `level`, `capacity`, `form_teacher_id`, `created_at`, `updated_at`. It has no archive metadata.
- `schoolpro_members` currently has only: `id`, `school_id`, `user_id`, `role`, `created_at`, `position_title`. It has no active/suspended state.
- Existing member lifecycle cannot be represented by a UI-only filter. Additive schema is required, with all existing memberships backfilled as active and all existing classes backfilled as unarchived.
- The existing table grants expose DELETE to both `anon` and `authenticated` on these two tables. The migration must revoke DELETE from both roles; policy changes alone are insufficient. The migration should also explicitly verify the final table privileges rather than assume default grants.

Implementation sequencing is now fixed to avoid a partially secure rollout:

1. **Schema and audit foundation:** additive lifecycle columns; append-only audit events; constraints/indexes; existing rows remain active/unarchived.
2. **RPC-only transitions:** security-definer archive/reactivate and suspend/reactivate operations; school leadership authorization; non-empty reason; lock target row; record actor/time and before/after state; reject cross-school IDs and self-suspension of the final proprietor; prevent direct lifecycle-column edits outside the RPC.
3. **Authorization and RLS:** active membership in every membership-derived helper; preserve owner/Super Admin paths; preserve student/guardian historic reads; remove DELETE policies and table privileges; replace Super Admin `FOR ALL` policies with explicit operation policies.
4. **Operational eligibility:** update all direct membership readers and assignment validators, including section leaders, Form Masters, subject allocations, House Masters, competition judges, lesson author scope, payroll/leave operations and class-linked attendance/CBT/timetable/result writes. Historical records remain readable and are never cascaded by archive/suspension.
5. **UI and tests:** active/archived filters and restore actions; suspended-member display; SQL tests for owner/admin authorization, cross-tenant isolation, direct DELETE denial, lifecycle audit, operational write denial, history preservation and reactivation.

No migration file is added until the complete dependent-function definitions and table-specific policy/privilege set have been reconciled. This avoids introducing a partially applied lifecycle model that could disable valid roles or leave an alternate access path.


### Extended membership-reader audit — 2026-11-07

A further read-only production function-definition pass confirmed that the lifecycle migration must cover more than the first-line permission helpers:

- `private.schoolpro_is_house_master` joins current House Master assignments to `schoolpro_members` and currently checks school, user, role and unended assignment but no member lifecycle state.
- `private.schoolpro_validate_house_master` validates only that the selected member is a same-school teacher/class teacher; it must reject archived/suspended members for new or changed assignments.
- `private.schoolpro_lesson_author_scope` and `private.schoolpro_lesson_leader` derive write/leadership scope directly from memberships and need active-member checks.
- `private.schoolpro_teacher_allocation_visible` resolves the caller's teaching membership without a lifecycle predicate. Its owner/admin fallback must remain unchanged.
- `private.schoolpro_cached_access_schools`, `private.schoolpro_cached_staff_schools`, `private.schoolpro_cached_readable_students`, and `private.schoolpro_cached_result_reader_keys` cache access scopes using direct membership joins. These are authorization functions, not merely display helpers, and must be updated consistently.
- `private.schoolpro_can_read_student` and `private.schoolpro_can_read_class` also contain direct membership-derived access. Student self/guardian and historical-read paths must not be accidentally removed when disabling a staff membership.
- `private.enforce_schoolpro_tenant_relations` and `private.schoolpro_archive_progression` validate tenant relationships and historical progression; their class references must be reviewed so archiving a class does not erase or invalidate historical enrolment/progression evidence.

This extends the migration dependency checklist: search all deployed function definitions for direct `schoolpro_members` joins and all policies for direct member existence checks; do not assume updating `has_school_access` alone closes the access graph. In particular, cached scope functions must be changed in the same migration as their uncached counterparts to avoid stale authorization paths. No production writes were performed.


### Complete direct-reference function and policy inventory — 2026-11-07

A second catalog pass over deployed `pg_proc` definitions found the following additional direct readers/writers of `schoolpro_members` and/or `schoolpro_classes`. These must be classified in the coordinated migration rather than handled by a blanket helper change:

- Access/read scope: `schoolpro_can_read_student`, `schoolpro_can_read_class`, `schoolpro_class_staff_directory`, `schoolpro_coordinator_classes`, `schoolpro_enrollment_reader_keys`, `schoolpro_result_reader_matches`, `schoolpro_cached_access_schools`, `schoolpro_cached_staff_schools`, `schoolpro_cached_readable_students` and `schoolpro_cached_result_reader_keys`.
- Assignment/operational eligibility: `schoolpro_set_form_master`, `schoolpro_set_section_leader`, `schoolpro_set_board_role`, `schoolpro_validate_house_master`, `schoolpro_is_house_master`, `schoolpro_house_master_roster`, `validate_schoolpro_assignment_target`, `validate_schoolpro_subject_assignment`, `validate_subject_assignment`, `validate_schoolpro_leave`, `validate_schoolpro_workflow_record` and `schoolpro_teacher_allocation_visible`.
- Lesson/section/result authority: `schoolpro_lesson_author_scope`, `schoolpro_lesson_leader`, `schoolpro_member_leads_class`, `schoolpro_member_leads_student_section`, `schoolpro_can_write_result` and `schoolpro_send_school_notice`.
- Class lifecycle/history interactions: `schoolpro_archive_progression`, `schoolpro_enrollment_calendar`, `validate_attendance_record`, `validate_student_class`, `validate_schoolpro_cbt_eligibility`, `schoolpro_can_review_class` and `schoolpro_bulk_academic_action`. Trigger functions and historical processing must preserve past attendance, assessment, promotion and enrolment references while rejecting new writes to archived classes.
- Membership utility/registration/notifications: `schoolpro_can_register`, `notify_school_staff` and `schoolpro_notify_discipline`. These require explicit classification so lifecycle status does not accidentally block unrelated registration or notification delivery.

The live RLS inventory is also exact: classes have SELECT policies `Authorized class lists`, `School users read classes` and `Scoped class lists`; INSERT/UPDATE school-leader policies; DELETE policy `School leaders delete classes`; and Super Admin `ALL` policy `Super admin full access schoolpro_classes`. Members have SELECT policies `School staff read own membership` and `School users read members`; INSERT/UPDATE school-leader policies; DELETE policy `School leaders delete members`; and Super Admin `ALL` policy `Super admin full access schoolpro_members`. Because PostgreSQL permissive policies OR together, retaining either DELETE policy or the Super Admin ALL policy would defeat a UI-only or partial policy removal. The migration must explicitly replace ALL with separate SELECT/INSERT/UPDATE policies and remove DELETE table grants for `anon` and `authenticated`.

No production writes were performed. This inventory is a migration design input, not a production migration.


### Lifecycle trigger interactions — 2026-11-07

Read-only inspection of triggers on the two lifecycle tables found additional invariants that the archive/suspension RPC must preserve:

- `schoolpro_classes` has `schoolpro_activation_before_write` (`private.guard_schoolpro_operational_write`), which checks school operational activation on INSERT/UPDATE/DELETE, and `validate_schoolpro_classes_tenant` for immutable school ownership. Lifecycle changes must coexist with this activation guard; do not disable or bypass it for client calls.
- `schoolpro_members` has `protect_schoolpro_proprietor_role` on INSERT/UPDATE/DELETE. It protects proprietor assignment/removal except for the school owner or Super Admin. Suspension must add a stricter final-proprietor safeguard, not weaken this existing control.
- Role-change triggers clear board membership, end House Master appointments, and prune section leadership. Archive/suspension is not a role change, so lifecycle RPCs must explicitly end active operational assignments (with timestamps/status) without deleting board/governance, payroll, leave or other historic evidence.
- Both tables have tenant-ownership validation triggers. Lifecycle RPCs must keep `school_id` immutable and lock the exact target row before recording audit state.
- `guard_schoolpro_operational_write` explicitly permits trusted backend operations when `auth.uid()` is null and the request role is not `anon`. The lifecycle design must preserve legitimate service maintenance while preventing browser clients from editing lifecycle metadata directly.

This trigger review is now a prerequisite in the migration checklist. No trigger or production data was changed.


## 2026-11-07 — lifecycle foundation migration committed (not production-applied)

Branch-only migration: `supabase/migrations/20261107130000_schoolpro_class_staff_lifecycle_foundation.sql` (commit `5f2c59c`). It adds nullable archive metadata to classes; an `active|suspended` state plus suspension metadata to school memberships; partial indexes for active classes/members; metadata consistency constraints; and audited, school-scoped SECURITY DEFINER RPCs to archive/restore classes and suspend/restore memberships. The RPCs lock the exact tenant-scoped row, require an active account and proprietor/administrator access, validate a 10–1000 character reason, write `schoolpro_audit_logs`, and prevent suspension of the final active proprietor. A trigger blocks authenticated browser sessions from inserting or directly changing lifecycle metadata; the RPCs execute under their owner context.

**Important: this is a schema/RPC foundation, not an enabled end-user lifecycle rollout.** It does not yet make archived classes invisible/ineligible in all class readers and operational writes; it does not yet enforce active membership across the full authorization/function dependency graph; it does not remove existing DELETE policies or DELETE grants; and it does not end all operational appointments on staff suspension. Do not expose Archive/Suspend controls or treat lifecycle acceptance as passed until the coordinated follow-up migration covers the dependency inventory above, replaces Super Admin ALL policies with explicit operation policies, removes direct DELETE access, and adds SQL regression coverage. Existing guardian-link suspend/restore is a separate workflow.

No production migration was applied, no production data was changed, and no PR was merged or Render deployment triggered. The protected active verification workspaces remain untouched: IHLINK Academy (`eb601205-cffd-420d-97d0-7d5ca081628a`) and HA ACADEMY (`ac7ac8a8-5035-4e39-8868-cad54add84a6`).


### Post-foundation authorization review — 2026-11-07

A read-only comparison of the committed lifecycle foundation against the currently deployed production function definitions identified a critical authorization dependency that must be corrected before the foundation migration can be applied or its controls exposed:

- The live private.has_school_access(uuid, school_member_role[]) helper currently checks the profile is active, then grants access through Super Admin, school ownership, or a matching schoolpro_members row. Its membership branch does **not** check a membership lifecycle state. The committed foundation adds schoolpro_members.status, but the foundation itself does not replace this helper.
- Both private.schoolpro_set_class_archive_state(...) and private.schoolpro_set_member_suspension_state(...) authorize leadership through private.has_school_access(...). Consequently, after the foundation migration is applied, a suspended proprietor/administrator membership could still satisfy this authorization helper; suspension would not reliably revoke school-level management access.
- private.schoolpro_can_read_class(...) also contains direct membership and assignment checks that do not yet filter m.status = 'active'. private.schoolpro_member_leads_class(...), private.schoolpro_is_house_master(...), private.schoolpro_validate_house_master(), and the direct membership readers/validators in the dependency inventory also require active-state enforcement. The historic student/guardian read paths must remain intact.
- The corrective implementation must preserve access for an active school owner and authorized Super Admin independently of staff membership, while requiring an active membership for every membership-derived school role. It must also handle proprietor suspension safely and keep trusted backend maintenance behavior intact.
- The current production schema still has no schoolpro_members.status or class archive columns; this confirms the branch foundation has not been applied to production. No production mutation was performed during this review.

**Release gate:** do not apply 20261107130000_schoolpro_class_staff_lifecycle_foundation.sql, expose archive/suspend controls, or accept C0 until a follow-up migration updates the central helper and every direct membership reader/validator, ends operational appointments on suspension, closes direct DELETE policies/grants, and passes tenant-isolation and lifecycle regression tests. The helper replacement must be based on the exact deployed definition and reviewed for all callers, not copied from an older migration. This is a branch-only review finding; no production data/schema changed, no PR merged, and no Render deployment triggered.


### Core active-membership authorization migration — 2026-11-07

Committed branch-only migration `20261107143000_schoolpro_active_membership_authorization.sql` (commit `24a464d60a948d0bcb740fa88e738f3116d69d83`). It must run **after** the lifecycle foundation migration. It replaces the deployed central `private.has_school_access` helper so role-based membership access requires `schoolpro_members.status = 'active'`, while preserving independent active-profile Super Admin and school-owner access. It also updates class-read membership paths, section-leader class/student scope, House Master authorization/validation, and lesson author/leader scope to require active membership. Student/guardian historical class reads are explicitly retained.

This migration is intentionally partial. It does not yet update every direct membership reader/validator in the dependency inventory (including class staff directory/coordinator classes, board/form-master/section-leader appointment RPCs, teacher allocation, subject-assignment and general assignment validators, payroll/leave/competition access paths). It does not yet end active House Master, board, section-leader, judge, Form Master, or other operational appointments on suspension; it does not block new writes against archived classes; it does not remove class/member DELETE policies or grants; and it has no complete SQL regression suite yet.

**Do not apply this migration or the preceding foundation to production, expose archive/suspend controls, or mark C0 accepted yet.** The next migration must cover remaining direct membership consumers and appointment cleanup, then a separate reviewed RLS/grant correction must remove direct DELETE access and replace broad Super Admin ALL policies with explicit operation policies. Add database regression coverage before production approval. No production schema/data change, PR merge, or Render deployment occurred.


#### EXECUTE-grant compatibility correction — 2026-11-07

A read-only privilege check showed that authenticated users currently have EXECUTE on several private helpers because they are invoked directly by RLS policies. The first draft of the follow-up migration would have revoked those grants and broken policy evaluation. Corrected the branch migration in commit `93fc97222e1d8d3790a791c0a448458c5a3a7db2` to preserve existing helper EXECUTE grants; no privilege revocation is included. Trigger-only validator remains ungranted. This correction is based on live `has_function_privilege` results; production privileges were only inspected, not changed.


### Active staff and class-assignment guard migration — 2026-11-07

Committed branch-only migration `20261107160000_schoolpro_active_staff_and_class_assignment_guards.sql` (commit `029acb9ede0fcad73f5c4eaae77f3c57ac7534f3`). It updates the class staff directory and coordinator-class reader to exclude suspended memberships and archived classes; prevents suspended staff from passing teacher-allocation visibility; requires active membership for Form Master and section-leader appointments; and blocks new assignment/subject-assignment writes against archived classes or inactive staff. Existing assignment history is not deleted.

The migration preserves the current helper EXECUTE grants and does not alter production. It is sequenced after the lifecycle foundation and core active-membership helper migration.

**Still not complete:** this does not yet end active appointments when a member is suspended (House Master, board, section leader, competition judge, Form Master, and other operational roles), update every remaining direct membership consumer, remove direct class/member DELETE policies and grants, replace broad Super Admin ALL policies, or provide the full SQL regression suite. Do not apply migrations to production, expose lifecycle controls, or mark C0 accepted yet.


### Staff and student welfare workflows — scope added 2026-11-07

The user has expanded C0 to include dedicated, auditable staff and student welfare workflows. These are implementation requirements, not yet accepted or implemented.

**Staff disciplinary workspace (dedicated dashboard page):**
- Record verbal/written/final warnings, misconduct allegations/investigations, performance-improvement actions, suspension, dismissal/termination, commendations and other documented employment actions.
- Each case must capture staff membership, category, incident/effective dates, factual reason, description, issuing/reviewing authority, status, supporting evidence references, staff response/acknowledgement, appeal/review notes, and immutable event history.
- Sensitive cases must be restricted to authorised school leadership/HR; the affected staff member may see their own case and submit a response/appeal, but must not edit the official action or reviewer decision.
- Suspension/dismissal must be linked to the school-scoped membership lifecycle and operational appointment termination. Do not delete global profiles/Auth users, payroll, leave, or historic records. Do not expose a suspension/dismissal action as final until the membership restriction and appointment cleanup are transactionally implemented.

**Staff Leave & Absence improvements:**
- Separate planned leave requests from retrospective absence reports and unexplained absence records.
- Staff must be able to report an absence and later add/update the reason or supporting explanation; retain the original report time and reason-update history.
- HR/leadership review should capture decision, reviewer, timestamp and note; staff can see their own requests and decisions, while only authorised reviewers can decide.
- Validate date ranges and membership ownership; prevent one staff member editing another's request. Unexplained absence must remain distinct from approved leave and must not silently become approved leave.

**Student discipline improvements:**
- Extend the existing basic incident/action/status record into a case workflow with incident category, severity, location/date, reporter, involved student, factual narrative, student response, action/intervention, parent/guardian contact status and notes, responsible reviewer, follow-up date/outcome, resolution and immutable case history.
- Retain session and school scoping; preserve existing records and current reporter/leadership visibility rules. Sensitive case details must be restricted to authorised roles and provide appropriate parent/guardian communication without exposing other students' records.

**Current implementation gaps confirmed by code inspection:**
- Staff discipline is not a dedicated page; /schoolpro/discipline currently serves only student concerns.
- /schoolpro/leave is routed through the generic operational CRUD module. It allows staff to create requests but does not provide an own-request reason-update flow; the existing review card only lists pending requests and provides approve/decline without reviewer notes.
- Student discipline currently captures only incident, action_taken and status; no severity/category, response, parent contact or follow-up workflow is present.
- These gaps must be addressed with dedicated UI, narrowly scoped RPC/RLS policies, audit trails and regression tests. Avoid reusing generic delete/edit controls for disciplinary or absence evidence.


### Appointment termination and ended-appointment access guards — 2026-11-07

Added two branch-only migrations:
- 20261107180000_schoolpro_end_appointments_on_suspension.sql (commit c987129d9e1ef9d74fbef37692a591b778bf8494): adds end metadata to board, section-leader and subject assignments (plus actor/reason metadata to existing House Master and competition-judge assignments); replaces the audited membership suspension transition so it ends all current operational appointments, clears current Form Master pointers while recording each former assignment in school audit logs, and retains the appointment rows. Reactivation intentionally does not resurrect appointments.
- 20261107183000_schoolpro_ended_appointment_access_guards.sql (commit ef44d1106bb491e34595936dc61e07495b768bdb): updates class/section/student/result/lesson/House Master readers and assignment validators to require active membership, active (not ended) appointments and non-archived classes. Board and section-leader appointment changes now end/reactivate rows instead of deleting section history or deleting board history. Existing helper EXECUTE grants are unchanged.

These migrations have not been run against any database. They require SQL syntax/runtime validation in an isolated local test database before any production approval. The Staff UI must also filter ended appointment rows, and all remaining direct membership consumers/operational RPCs still need review. In particular, validate_schoolpro_leave, validate_schoolpro_workflow_record and the attendance/CBT/timetable/result write paths remain in the outstanding dependency list.
