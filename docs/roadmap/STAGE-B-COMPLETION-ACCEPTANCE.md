# Stage B Completion and Acceptance Matrix

**Status:** Baseline merged; final acceptance remains open pending the evidence below.  
**Related stabilization branch:** `feat/schoolpro-stage-c0-workspace-corrections`  
**Rule:** A merged feature is not marked complete until its user-facing behaviour, authorization, data integrity and focused regression evidence are recorded.

| Workstream | Current evidence | Acceptance still required | Status |
|---|---|---|---|
| Stage A authentication and tenant isolation | Previously accepted Stage A baseline; Turnstile acceptance recorded in the project handover | Preserve baseline; reopen only for a demonstrated regression | Accepted baseline |
| Academic sessions and calendar | Historical-session and calendar work is part of the merged Stage B baseline | Confirm selected historical session controls the working view without unintended promotion or data mutation | Verify |
| Students, classes, sections and rosters | Stage B schema and UI baseline includes middle name, classes/arms and staff assignments | Confirm owner workflows, section scope and roster integrity | Verify |
| Attendance and staff assignment | Form Master attendance scope and staff/subject assignment are in baseline | Confirm Form Master-only attendance write path and subject-teacher restrictions | Verify |
| Progression, former students and transcripts | Promotion/repeat/graduation and transcript/certificate requirements are in baseline | Confirm historical preservation, repeat thresholds and section-level operations | Verify |
| Houses and House Masters | PR #121 merged; security-scoped House Master roster RPC and dashboard implemented | Confirm Games/Competitions navigation, all house selectors, staff appointment and student assignment in active workspace | Verify / C0 |
| Games, Sports and Competitions | Games module and database workflows exist; route is registered | Confirm role permission, dashboard discoverability and end-to-end event/score/result lifecycle | Verify / C0 |
| Super Admin school selector | PR #121 merged; selector no longer auto-selects the first school; user previously confirmed selector behaviour | Preserve explicit school selection and verify no cross-school context leakage | Accepted UI baseline; retain regression test |
| Plan catalogue and subscription | Annual plan catalogue and subscription UI exist; upgrade request/payment/review database workflow migration exists | Verify plan entitlements in navigation and routes; expose actual upgrade request/payment workflow to authorised owners; ensure advanced reports visibility is entitlement-aware | Verify / C0 |
| Workspace and record lifecycle | No complete owner-initiated deletion lifecycle evidenced in the inspected files | Inventory dependencies/storage, implement request/review/tenant-scoped execution and owner record archive/delete controls | Not complete / C0 |
| Responsive tables and grids | No workspace-wide standardisation evidence recorded | Establish shared table overflow pattern and apply to high-use tables; test desktop/tablet/mobile | Not complete / C0 |

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
