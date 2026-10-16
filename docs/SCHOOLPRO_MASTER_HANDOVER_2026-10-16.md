# IHLink SchoolPro — Master Handover and Continuation Tracker
**Last updated:** 16 October 2026  
**Purpose:** Preserve the verified working state and remaining acceptance gates. Audit-first continuation; do not rebuild or infer completion from code alone.

> This document is the maintained repository handover snapshot for the current workstream. Keep it synchronized with the Stage A release-gate document and the user's wider master handover. It does not authorize production migrations, production data changes, merges, or deployments.

## 1. Project identity and production baseline

- Repository: https://github.com/Hassan-625/IHLink-SchoolPro
- Production URL: https://ihlink-schoolpro.onrender.com
- Hosting: Render (not Vercel)
- Render service: `srv-db0k11m0tbcc7386fmq0`
- Render workspace: `tea-daruek7pn0mc73e372tg`
- Supabase project ref: `lnqsroyiybutkfngbyge`
- IHLink Academy demo school ID: `d342eb87-8d6a-477a-a380-7fab83f586b7`
- Production/main baseline confirmed during the Stage A audit: `29856dff17ea8a3bc8bb31b7900967b7df9d316b` (13 October 2026).
- Stage A work is isolated on branch `release/stage-a-auth-tenant-isolation`, draft PR #106: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106
- Do not merge PR #106 until every required gate passes and the user has been told the exact scope. Do not merge unrelated PRs as a substitute.

## 2. Mandatory delivery order

1. **A — Authentication and tenant isolation.** Complete the release gate, reconcile migration source/ledger drift, pass authenticated two-school DB/RPC/Storage and payment lifecycle checks, merge only after explicit review/authorization, then verify the merged commit and Render deployment.
2. **B — Academic sessions, student population and class rosters.** Start only after A is merged and post-merge verified. Preserve existing identity/password fixtures and workspace boundaries.
3. **C — Assessments, calculations, review and publication.** Strengthen score entry, assessment-by-assessment save, averages, review/publication, permissions and historical integrity.
4. **D — Result Design Studio and custom Excel workbooks.** Resume only after A/B/C are re-verified as requested. Support section-specific Nursery, Primary, JSS and SS designs; school-owned template upload, field mapping, logo/signatory placement, preview and replacement of defaults without changing other schools' templates. Revisit the deferred A4 print issue.

**Do not start B while A remains open.** The user explicitly requested A/B/C strengthening and verification before D resumes.

## 2A. Full master roadmap — A through J (scope preserved)

**Scope correction:** The approved SchoolPro roadmap contains **A–J (ten stages)**. A–D is the immediate gated sequence, not the whole project. The workstream names below are preserved from the prior master-handover summaries. The exact original E–J acceptance checklists have not yet been recovered from the source document; the summaries below are scope reminders, not a substitute for the original approved checklist. Do not mark E–J complete, remove them, or silently redefine them.

| Stage | Workstream retained in the master roadmap | Acceptance focus preserved in prior handover summaries |
|---|---|---|
| **A** | Authentication, permissions and tenant isolation | Verify sign-in/session lifecycle, roles and portal boundaries, Super Admin vs school-scoped roles, RLS/policies/RPCs/Storage, migration/source parity, and two-school positive/negative tests. Open; not merge-ready. |
| **B** | Academic sessions, student population, class arms and rosters | Verify session continuity, school-scoped student population, class/arm assignment, roster integrity and the agreed seeded demo data without copying operational records into new schools. |
| **C** | Assessment entry, averages, review and publication | Verify independent component saves, calculations and class-subject averages, form-master review/edit before exam-officer publication, correction requests after publication, historical integrity and role enforcement. |
| **D** | Result Design Studio and custom Excel workbooks | Support section-specific Nursery/Primary/JSS/SS standards, school-specific workbook upload/mapping/preview, logo/signatory placement and isolated template replacement. Revisit the deferred A4 print issue. |
| **E** | Document Studio and document security | Preserve the document/template mapping, generated-document security and cross-school access review. **Recover the exact original checklist before execution sign-off.** |
| **F** | Historical data, rollover and progression | Preserve historical records and verify academic-year rollover/progression. **Recover the exact original checklist before execution sign-off.** |
| **G** | Operational modules and portals | Verify student, parent, staff and operational workflows. **Recover the exact original checklist before execution sign-off.** |
| **H** | Fees, subscriptions and payment reconciliation | Verify SQL/payment behavior, annual billing, receipts, invoices, balances and grace/suspension rules, with BillStack limited to DataSub. **Recover the exact original checklist before execution sign-off.** |
| **I** | Release readiness, Android APK, Render deployment and support | Verify release artifacts, Android delivery, authorized Render deployment and support readiness. **Recover the exact original checklist before execution sign-off.** |
| **J** | Platform security, performance and resilience | Verify security, performance and recovery/resilience. **Recover the exact original checklist before execution sign-off.** |

**Execution order and completion rule**
- Continue from the Stage A blockers below. Do not start B until A is complete, reviewed and merged into the intended production branch with the user's explicit authorization, then verified after merge.
- Then complete and re-verify B, C and D in that order.
- Continue E, F, G, H, I and J in the original approved order. Restore each original checklist from the source handover before declaring its stage complete.
- Stage-specific trackers may add implementation detail but must not narrow the A–J scope.
- This handover update does not authorize a production migration, production data change, merge or deployment.

## 3. Latest Stage A PR and CI state (16 October 2026)

PR #106: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106  
Code/test-fix commit: `9b3b3513f0f27da878099f4749e252c8f1dcf537`; latest branch head when this note was refreshed: `2d112d5a2f1b257d1b0f6489fc15fa5f182ab36c` (documentation synchronization; draft PR remains open and unmerged).

- SchoolPro CI run #1007: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38892010470 — latest documentation-head run; live `tenant-acceptance` failed because School B has no existing `schoolpro_result_templates` row/path; general `validate` was still running at the time of this refresh.
- Run #1005: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38891749136 — general `validate` passed, including the new static family-media policy regression test; live `tenant-acceptance` failed only when it found the absent School B template fixture.
- Run #1004: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38891682515 — ran against the migration/harness draft commit; final workflow status must be checked before calling CI green.
- Runs #1000 and #1001 previously passed general validation and all database/RPC isolation checks, but failed on Storage listing timeout. Run #1002 repeated the old listing timeout.
- Run #1003 changed the harness to query the school-owned template row and download its exact object instead of listing a folder; it correctly exposed that School B has no saved template row/path. The exact-object test must not manufacture a production fixture.
- Latest payment-page validation run #731: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38891749307 — passed.
- CI accepts `SUPABASE_PUBLISHABLE_KEY` as fallback when `SUPABASE_ANON_KEY` is absent. Receipt Storage paths remain blank and there are no existing receipt fixtures. Do not add dummy production objects.
- A draft SQL migration now narrows the family-report-media Storage policy to known media path shapes and replaces the broad student/results join with indexed exact-path lookups. A static regression test is wired into CI. **The migration has not been applied to production**, and its live performance effect is not yet verified.
- A separate draft migration adds database-side result-PIN cooldown after eight failures in 15 minutes, keyed by a one-way hash of the admission identifier and request network context; no raw admission/PIN is stored. It is static-test-only so far and has not been applied or runtime-tested. Review the gateway-provided client-IP semantics and retention/cleanup before any production rollout.
- Supabase logs for the previous Storage-list timeout show SQLSTATE `57014` / Storage status `544`: `Families read their report images` invoked `private.schoolpro_family_report_media(name)` for objects in the shared `school-result-templates` bucket. The function's broad published-result scan entered `schoolpro_can_view_result_output` → `schoolpro_result_access` → `schoolpro_can_read_student` / `schoolpro_operationally_active` and timed out. This identifies a policy/query-performance defect, not a transient network-only issue.
- The live bucket currently has eight existing workbook objects, all belonging to IHLink Academy; the live template table has one row, also for IHLink Academy. School B has no existing template object/row. No production data was written.
- Storage acceptance remains blocked until the policy fix is validated and a legitimate existing own-school fixture is available for the two-account positive/negative check. Do not skip assertions, weaken isolation, or treat timeout/missing fixture as a pass.

### Authenticated two-school checks that passed before the Storage timeout

The workflow successfully signed into two distinct real Supabase password-authenticated test accounts and reported:
- School A and School B could read their own student fixture.
- Both directions returned zero foreign-school rows for `schoolpro_students`, `schoolpro_members`, `schoolpro_invoices`, and `schoolpro_results`.
- Both accounts could call `schoolpro_current_academic_period` for their own school; foreign-school calls were denied.
- Both accounts received `false` from `schoolpro_can_view_result_output` for a foreign-school student.

### What did not pass or remains unverified

- Storage list of the existing School B object in `school-result-templates` timed out three times. Because the positive fixture lookup did not finish, the paired foreign-school Storage denial assertion did not run. This is a failed acceptance check, not evidence of a tenant leak.
- Payment receipt Storage tests were skipped because no existing `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` values are configured. The production bucket was previously found to have no existing objects. **Do not upload dummy production receipts just to satisfy CI.**
- No production database writes, migration, merge, or Render deployment was performed as part of this work.

### Immediate next Stage A action

Root cause has been identified in Supabase logs: the permissive family-report-media policy on the shared template bucket runs an expensive report-access scan for workbook objects. A draft migration narrows the policy to known media paths and adds exact-path indexes. Next: finish exact-head CI, review the SQL carefully, then validate the migration and policy behavior in a non-production environment if available before any production rollout. Keep live tests read-only; no own-school fixture exists for School B, so do not upload dummy production files. Storage acceptance cannot be marked passed until both an authorized positive fixture and the foreign-school denial are verified.

## 4. Remaining Stage A release blockers

1. **Migration source/ledger drift.** Production ledger records 476 migrations and ends at version `20261015161735`. Three existing source filenames are not recorded under the same version/name pairs:
   - `20261002234500_schoolpro_operational_tenant_isolation.sql`
   - `20261003000500_schoolpro_guardian_tenant_hardening.sql`
   - `20261003002000_schoolpro_cbt_permission_tenant_integrity.sql`
   Later related hardening migrations exist, but that does not prove exact equivalence. Reconcile by reviewed SQL/source evidence; do not apply migrations just to align names.
2. **Missing migration source.** The live ledger contains `20260924112325_schoolpro_secure_public_result_checker`, but the corresponding source migration file was absent from main and the release branch. Do not reconstruct it from a partial live-function snapshot. Recover authoritative source or establish a carefully reviewed baseline.
3. **Public result PIN brute-force protection.** The live `check_schoolpro_result_pin` SECURITY DEFINER function has no database-level attempt counter/cooldown. Implement a reviewed rate-limit approach before release; frontend-only throttling is insufficient.
4. **Storage acceptance.** Fix/understand the result-template listing timeout and pass the cross-school Storage test. Receipt download isolation remains untested until real, already-existing receipt fixtures are available.
5. **Payment lifecycle.** Pending/review/reject/cancel transitions, duplicate invoice allocations and concurrent receipt-submission behavior require dedicated transaction-level acceptance tests. The staged migration `20261015203000_schoolpro_payment_receipt_tenant_guard.sql` has not been applied to production.
6. **Broader authorization review.** Review exposed SECURITY DEFINER RPCs individually. Do not blanket-revoke public/authenticated execution because some guest/token workflows are intentional. Confirm Super Admin platform access without widening school-scoped actions.
7. **Post-merge production verification.** Only after explicit approval and every gate passing: verify merge SHA, Render deployment SHA/status, login and authorized/unauthorized workflows, and re-run relevant checks. No merge/deploy is currently authorized by this handover.

The detailed current checklist and evidence are in [Stage A release gate](https://github.com/Hassan-625/IHLink-SchoolPro/blob/release/stage-a-auth-tenant-isolation/docs/STAGE_A_AUTH_TENANT_ISOLATION_RELEASE_GATE.md).

## 5. Application requirements to preserve

### Authentication, roles and tenancy
- Super Admin is platform-wide and is not a school membership. School owner/proprietor/director/board/exam officer/IT/admin/staff identities are school-scoped.
- Exam Officer uses the staff portal; directors and board members use the school-owner portal.
- Preserve protected Exam Officer identity and existing test identities/passwords. Never reset or disclose a real user's password unnecessarily.
- Students use admission number plus surname as initial password, then must change it. Do not introduce a first-use web passcode; passcode is mobile-app-only.
- A school owner must access only their own school. Super Admin can select/inspect the intended workspace while normal school-scoped restrictions remain enforced.
- Use “IH Academy” for the intended visible school label, not “IH Academy Testing”; keep the IHLink Academy demo workspace isolated.
- No demo/seed operational data should be copied into newly created customer workspaces.

### Commercial and payment rules
- BillStack is for **DataSub only**.
- SchoolPro subscription: school uploads payment receipt; IHLink admin verifies and marks paid.
- School fees: school-side receipt/verification workflow; do not route through BillStack.
- All subscription plans, including Demo, are annual. Demo activation must not display the paid plan amount while Demo is active. Paid subscriptions are annual; after expiry, invoice/payment flow and the two-week grace/suspension rules apply as specified in the commercial requirements.
- Never mark real payment as paid from a screenshot or frontend callback alone; preserve server-side ownership checks, verification and audit trail.
- Do not initiate real purchases/refunds or create production payment fixtures without explicit authorization.

### Academic sessions and student population (Stage B)
- Target demo/operational workspace is IHLink Academy, not new customer workspaces.
- Required sessions: 2001–2002 through 2025–2026, plus 2026–2027 as next session.
- Population target: 20 synthetic Muslim-named students per populated class for 2025–2026, superseding the earlier 10-student draft.
- Preserve existing test identities and passwords; maintain accurate class/arm rosters and existing historical snapshots.
- Operations are required for 2020–2021 through 2025–2026. New schools receive only starter defaults/templates, not IH Academy operational records.
- Promotion preview must not auto-apply on publish; graduated/transfer-out pupils must not be promoted. Provide transcripts by level and class-representative certificates.

### Assessments/results (Stage C)
- Allow individual assessment components to be entered and saved independently; users must not be forced to fill assignments, CAs, exams and every component in one combined save.
- Form master/class coordinator can edit before exam-officer publication and should generate/prepare results before publication. After publication, use correction request/reopen with reason, review and republication.
- Exam Officer must be able to manage/review, not be read-only. Board/principal/IT admin access follows intended roles; unrelated/unassigned teachers, librarians, parents and students must be denied.
- Subject average = total student scores for that subject divided by number of students, shown once (not duplicated).
- Fetch selected class/term/session instead of a 500-row whole-school query.
- Preserve published history and class/session snapshots. Verify result calculations independently.

### Result Design Studio (Stage D)
- Separate default templates by Nursery, Primary, JSS and SS.
- Schools can upload custom Excel/workbook or document templates, map fields/cells/areas to their desired standard, preview, and replace their own default without changing global defaults or another tenant's templates.
- Support logo, pupil photo, signatories, merged cells/ranges and accurate field mapping when present in the source template.
- Test full report generation and A4 portrait printing; one A4 print issue was deferred and must be revisited.
- Do not call a template feature complete based only on a saved template record; confirm preview and a real generated export.

## 6. Other known state and constraints

- PR #104 and annual subscription/payment-page work is separate from the Stage A sequence. Do not mix it into PR #106 without review.
- Existing test school creation previously succeeded with code `SP-ACAE6D18A499`; a staff sign-in issue was resolved by using a distinct real login instead of an example test email. Staff surname-first-login flow and seven-day initial-access expiry were verified at that point.
- Previous checks confirmed owner-only school access, Super Admin workspace selection, and cross-school database/storage denials in earlier scoped tests. Do not use those older checks as a substitute for the current failed live Storage test.
- The A4 print issue remains deferred/open.
- No production migrations, database writes, Render deployment or PR merge are authorized by this document.
- Keep claims evidence-based: distinguish implemented, CI-passed, live-verified, production-deployed and user-confirmed. Never claim full completion from a static/source test alone.

## 7. Current status summary

| Track | Status | Next gate |
|---|---|---|
| A — Auth and tenant isolation | **In progress; not merge-ready** | Diagnose Storage timeout; resolve migration drift and PIN rate limit; complete payment lifecycle tests; rerun authenticated acceptance |
| B — Sessions, population, rosters | **Not started in this release sequence** | Wait for A merged and post-merge verified |
| C — Assessments and results | **Re-verify after A/B gates** | Independent calculations, per-component saves, permissions, review/publication and history |
| D — Result Design Studio / custom Excel | **Deferred until A/B/C are re-verified** | Section templates, mapping, preview, tenant isolation and A4 output |
| Production migration / deployment | **Not performed in this work** | Requires completed release gate and explicit approval |
