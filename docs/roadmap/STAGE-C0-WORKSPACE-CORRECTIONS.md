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
