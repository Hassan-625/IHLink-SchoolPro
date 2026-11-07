# Stage B Completion and Acceptance Matrix

**Status:** Baseline merged; Stage B and C0 code/database CI acceptance passed on C0 head `2df6b2d8a8873c99bb11b6bacfee92f178a43aed`; production migration and Render release remain pending.  
**Related stabilization branch:** `feat/schoolpro-stage-c0-workspace-corrections`  
**Rule:** A merged feature is not marked complete until its user-facing behaviour, authorization, data integrity and focused regression evidence are recorded.

| Workstream | Current evidence | Acceptance still required | Status |
|---|---|---|---|
| Stage A authentication and tenant isolation | Previously accepted Stage A baseline; Turnstile acceptance recorded in the project handover | Preserve baseline; reopen only for a demonstrated regression | Accepted baseline |
| Academic sessions and calendar | Stage B source tests and disposable PostgreSQL academic-calendar integration pass on the C0 head | Preserve selected historical session context without unintended promotion or data mutation; production release remains pending | CI validated / production pending |
| Students, classes, sections and rosters | Student/family lifecycle, session-roster and class/member lifecycle regression suites pass; no hard-delete UI remains for retained records | Preserve owner workflows, section scope, historical roster projection and tenant integrity in production | CI validated / production pending |
| Attendance and staff assignment | Disposable PostgreSQL Form Master attendance RLS and subject-assignment guard integrations pass; active membership/appointment guards pass C0 SQL regression | Preserve Form Master-only attendance writes and subject-teacher restrictions in production | CI validated / production pending |
| Progression, former students and transcripts | Progression threshold, subject requirements, historical roster, graduation certificate and section leadership integration tests pass | Preserve historical records and configured repeat/promotion rules in production | CI validated / production pending |
| Houses and House Masters | PR #121 baseline retained; house allocation, House Master/section leadership and Games/Sports source/SQL regressions pass | Preserve active-workspace selectors, staff appointments, student assignment and event/result lifecycle in production | CI validated / production pending |
| Games, Sports and Competitions | Stage A/B dashboard/plan regression and house allocation integration pass; Games/Sports routes and role guards remain in place | Confirm live tenant visibility and complete event/score/result lifecycle after release without creating synthetic workspaces | CI validated / production pending |
| Super Admin school selector | PR #121 merged; selector no longer auto-selects the first school; user previously confirmed selector behaviour | Preserve explicit school selection and verify no cross-school context leakage | Accepted UI baseline; retain regression test |
| Plan catalogue and subscription | Stage A/B plan catalogue, role navigation and standard-versus-advanced reports gate regression passes; annual upgrade workflow remains separate from existing subscription review | Confirm live plan entitlements and authorized upgrade/payment workflow after release | CI validated / production pending |
| Workspace and record lifecycle | Owner-proprietor request, independent platform review, separate safe-deactivation executor; audited class archive, staff suspension, student transfer/withdrawal, guardian-link suspension; C0 SQL lifecycle regression passes | Retain academic, financial, legal, audit and Storage history; physical purge remains a separate retention-reviewed process | CI validated / production pending |
| Responsive tables and grids | Shared bounded two-axis table viewport, targeted high-use page layouts, mobile/customer layout tests and print regressions pass in full SchoolPro CI | Confirm deployed desktop/tablet/mobile behaviour; print output remains unbounded and readable | CI validated / production pending |

## Stage B completion gate

Stage B may be declared complete only when every row above is either accepted with evidence or closed through a targeted correction, and the C0 workspace requirements that overlap Stage B are accepted. Evidence must identify the relevant commit/PR, focused tests, and user-visible behaviour. Production deployment is recorded separately and is not implied by a merge.

## Guardrails

- Supabase remains the SchoolPro database; Render remains the frontend host.
- No production migration, production data deletion, Storage deletion or deployment without explicit approval.
- Do not create test school workspaces or synthetic operational records.
- Preserve shared defaults/templates, global profiles/Auth users, unrelated tenant data and required financial/audit evidence.
- Stage C assessment/result-entry/calculation/publication work remains deferred until the Stage B completion gate and C0 acceptance gate both pass.

 
## 2026-11-07 C0 correction status supplement

The C0 branch now contains implementations for the previously outstanding workspace lifecycle and responsive requirements:
- Advanced Reports has a dedicated Enterprise-gated dashboard, subject/class analysis and Excel export; CI and runtime acceptance remain pending.
- Class archive/restore and staff suspension/restore controls use audited RPCs; active selectors exclude archived classes.
- Workspace removal uses owner request, independent Super Admin review and separate execution. Execution deactivates the workspace and retains all school-owned history and Storage; physical purge is not part of this safe workflow.
- Global CSS supplies bounded two-axis scrolling for direct table containers, in addition to the targeted page wrappers.
- The separate IHLink Admin PR adds Control Panel oversight for staff disciplinary cases and workspace removal.

These rows remain **implemented / acceptance pending** until the disposable-baseline C0 regression, application CI, production migration and Render deployment all complete successfully. Stage C is still blocked.
