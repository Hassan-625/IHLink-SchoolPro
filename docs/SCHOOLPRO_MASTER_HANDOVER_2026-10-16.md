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

**Scope correction:** The approved SchoolPro roadmap contains **A–J (ten stages)**. A–D is the immediate gated sequence, not the whole project. The workstream names and acceptance-focus summaries below are restored from the prior master-handover summaries. The exact original E–J checklist wording has not yet been verified against the original source document; these summaries preserve scope and must not be represented as verbatim source text. Do not mark E–J complete, remove them, or silently redefine them.

| Stage | Workstream retained in the master roadmap | Acceptance focus preserved in prior handover summaries |
|---|---|---|
| **A** | Authentication, permissions and tenant isolation | Verify sign-in/session lifecycle, roles and portal boundaries, Super Admin vs school-scoped roles, RLS/policies/RPCs/Storage, migration/source parity, and two-school positive/negative tests. Open; not merge-ready. |
| **B** | Academic sessions, student population, class arms and rosters | Verify session continuity, school-scoped student population, class/arm assignment, roster integrity and the agreed seeded demo data without copying operational records into new schools. |
| **C** | Assessment entry, averages, review and publication | Verify independent component saves, calculations and class-subject averages, form-master review/edit before exam-officer publication, correction requests after publication, historical integrity and role enforcement. |
| **D** | Result Design Studio and custom Excel workbooks | Support section-specific Nursery/Primary/JSS/SS standards, school-specific workbook upload/mapping/preview, logo/signatory placement and isolated template replacement. Revisit the deferred A4 print issue. |
| **E** | Document Studio, storage, RLS and cross-school document isolation | Validate school-specific template/document mapping, generated-document access, Storage object ownership, RLS/RPC authorization, cross-school denial and no global template overwrite. **Exact original checklist still requires source verification.** |
| **F** | Historical data, academic-year rollover and progression | Preserve historical records; verify session continuity, rollover, promotion preview/publish behavior, graduated/transfer-out handling, transcript-by-level and historical-result integrity. **Exact original checklist still requires source verification.** |
| **G** | Admissions, attendance, assignments, CBT and operational portals | Validate admissions and attendance, assignment/assessment workflows, CBT permissions, student/parent/staff experiences and each operational portal's role boundaries. **Exact original checklist still requires source verification.** |
| **H** | School fees, annual subscriptions and payment reconciliation | Verify annual Demo/paid billing, receipt upload and admin verification, school-side fee receipts, invoices/balances, duplicate/concurrent payment handling, two-week grace/suspension and no BillStack use outside DataSub. **Exact original checklist still requires source verification.** |
| **I** | Android APK, release readiness, Render deployment, rollback and support | Verify APK build/delivery and mobile-only passcode/fingerprint/wallet-PIN expectations, release artifacts, authorized Render deploy SHA/status, rollback procedure and support handover. **Exact original checklist still requires source verification.** |
| **J** | Platform security, performance, backups and resilience | Verify least-privilege/RLS/RPC/Storage security, load/query performance, migration/source parity, backup/restore evidence, recovery procedures, monitoring and resilience under failure. **Exact original checklist still requires source verification.** |

**Execution order and completion rule**
- Continue from the Stage A blockers below. Do not start B until A is complete, reviewed and merged into the intended production branch with the user's explicit authorization, then verified after merge.
- Then complete and re-verify B, C and D in that order.
- Continue E, F, G, H, I and J in the original approved order. Restore each original checklist from the source handover before declaring its stage complete.
- Stage-specific trackers may add implementation detail but must not narrow the A–J scope.
- This handover update does not authorize a production migration, production data change, merge or deployment.

## 3. Latest Stage A PR and CI state (16 October 2026)

PR #106: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106  
Latest branch head at this refresh: `5d1ecffddb2424b0bdf7eb9333254fac63fb7103`; PR remains open, draft and unmerged.

- SchoolPro CI run #1038: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38895816281 — live `tenant-acceptance` passed; general `validate` was still running at the last check.
- Latest fully green code/security commit: `6b33eba01075b0e08bdca5765b95492b2cd7d1d5`; SchoolPro CI run #1036 passed both `validate` and `tenant-acceptance`: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38895439410.
- Run #1036 passed the static regression tests for family-media Storage policy performance, database-side result-PIN cooldown, and payment-review write boundaries.
- Payment-page validation run #764 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38895816329.
- The authenticated two-school Storage test passed using an existing workbook: School A downloaded its own object; School B received HTTP 400 for that exact foreign object. The earlier folder-list timeout still has a separate policy/query-performance cause; the proposed Storage migration remains draft-only.
- Payment receipt Storage tests remain skipped because `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` are not configured and no existing receipt fixtures are available. Do not upload dummy production receipts.
- Three source tenant-hardening migrations still lack matching ledger version/name pairs; the source for `20260924112325_schoolpro_secure_public_result_checker` was not recovered from checked branches/history. Do not reconstruct it from a partial live function or repair migration history by guesswork.
- The Storage-policy, result-PIN cooldown and payment-review write-boundary migrations are draft-only. None has been applied to production; runtime behavior still requires review and safe testing.

### Live authenticated two-school acceptance passed (exact-object Storage test)

SchoolPro CI run #1036 (branch head `6b33eba01075b0e08bdca5765b95492b2cd7d1d5`) passed both the `validate` and `tenant-acceptance` jobs:
https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38895439410

- The workflow signed into two distinct real Supabase password-authenticated test accounts.
- School A and School B could read their own student fixture.
- Both directions returned zero foreign-school rows for `schoolpro_students`, `schoolpro_members`, `schoolpro_invoices`, and `schoolpro_results`.
- Both accounts could call `schoolpro_current_academic_period` for their own school; foreign-school calls were denied.
- Both accounts received `false` from `schoolpro_can_view_result_output` for a foreign-school student.
- School A downloaded its existing result-template workbook; School B received HTTP 400 for that exact foreign object. The negative assertion now checks raw HTTP status, avoiding a client-wrapper error being misclassified as a denial.

### What did not pass or remains unverified

- The earlier broad Storage folder listing timed out three times because the existing family-report-media policy triggered an expensive report-access scan. The exact-object acceptance now passes, but that does **not** establish that folder listing is performant or that the proposed policy migration is correct. The migration is draft-only and not applied to production.
- Payment receipt Storage tests were skipped because no existing `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` values are configured. Do not upload dummy production receipts.
- The database-level result-PIN cooldown is a draft migration and static-test-only; gateway IP header behavior, cleanup/retention, cooldown reset and concurrent attempts have not been runtime-tested.
- A further draft migration, `20261016143000_schoolpro_payment_review_write_controls.sql`, removes generic finance-module `ALL` policies from payment submissions, allocations, proofs and fee-payment ledger rows so school finance roles cannot directly update/delete records outside the review/accounting RPCs. It adds explicit Super Admin read-only inspection policies for review records and replaces the fee-ledger Super Admin `ALL` policy with `SELECT` only. The static test passed in run #1036; no runtime policy test or production migration has been performed.
- General CI run #1030 passed both jobs on the latest fully green branch head. A further documentation-only refresh may trigger another validation run; no application code or production state was changed by the handover edits.
- No production database writes, migration, merge, or Render deployment was performed as part of this work.

### Immediate next Stage A action

Finish exact-head CI for the updated documentation commit. Then review the Storage policy and PIN cooldown SQL and validate them in a non-production environment if available; do not apply either migration to production from static tests alone. Reconcile migration source/ledger drift using reviewed live-object/source comparisons. Complete payment lifecycle/concurrency tests and obtain existing receipt fixtures before claiming the remaining gates passed.

## 4. Remaining Stage A release blockers

1. **Payment review write-boundary validation.** The new migration `20261016143000_schoolpro_payment_review_write_controls.sql` is draft-only. It needs reviewed runtime evidence that guardian submissions, school finance reads, Super Admin inspection and RPC-based confirmation/rejection still work while direct status/amount/allocation mutations are denied. Do not apply it to production on static CI alone.
2. **Migration source/ledger drift.** Production ledger records 476 migrations and ends at version `20261015161735`. Three existing source filenames are not recorded under the same version/name pairs:
   - `20261002234500_schoolpro_operational_tenant_isolation.sql`
   - `20261003000500_schoolpro_guardian_tenant_hardening.sql`
   - `20261003002000_schoolpro_cbt_permission_tenant_integrity.sql`
   Later live policies/triggers provide related tenant controls under different names, but exact equivalence has not been proven. Reconcile using reviewed SQL/source evidence; do not apply migrations just to align names.
3. **Missing migration source.** The live ledger contains `20260924112325_schoolpro_secure_public_result_checker`, but the corresponding source migration file was not found in main, the release branch, the checked audit branches, or current repository history. Do not reconstruct it from a partial live-function snapshot. Recover authoritative source or establish a carefully reviewed baseline.
4. **Public result PIN brute-force protection.** A draft database-level attempt counter/cooldown migration is prepared. It is not applied or runtime-tested; review client-IP header trust, retention/cleanup, cooldown reset and concurrency behavior before release. Frontend-only throttling remains insufficient.
5. **Storage policy performance.** Exact-object cross-school acceptance passed. The earlier folder-list timeout root cause is confirmed, but the proposed policy migration is not applied or performance-tested; receipt download isolation remains untested until real, already-existing receipt fixtures are available.
6. **Payment lifecycle.** Pending/review/reject/cancel transitions, duplicate invoice allocations and concurrent receipt-submission behavior require dedicated transaction-level acceptance tests. The staged migration `20261015203000_schoolpro_payment_receipt_tenant_guard.sql` has not been applied to production.
7. **Broader authorization review.** Review exposed SECURITY DEFINER RPCs individually. Do not blanket-revoke public/authenticated execution because some guest/token workflows are intentional. Confirm Super Admin platform access without widening school-scoped actions.
8. **Post-merge production verification.** Only after explicit approval and every gate passing: verify merge SHA, Render deployment SHA/status, login and authorized/unauthorized workflows, and re-run relevant checks. No merge/deploy is currently authorized by this handover.

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
