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
