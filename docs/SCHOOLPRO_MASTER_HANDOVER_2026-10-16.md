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

**Scope correction:** The approved SchoolPro roadmap contains **A–J (ten stages)**. A–D is the immediate gated sequence, not the whole project. The earlier canonical guide has now been recovered from [`docs/SCHOOLPRO_MASTER_HANDOVER.md` at commit `1989a8e14d2bab69d758a231b532b7989857c40c](https://github.com/Hassan-625/IHLink-SchoolPro/commit/1989a8e14d2bab69d758a231b532b7989857c40c). The stage names and detailed acceptance focus below are reconciled against that source, with later approved requirements added without removing original scope. Do not mark E–J complete, remove them, or silently redefine them.

| Stage | Original workstream | Preserved acceptance focus |
|---|---|---|
| **A** | Core application, authentication and role access | Preserve standalone app, session handling, school workspace context, role permissions, routes, branding, portals and backend integration. Super Admin has platform-wide administration; school users remain school-scoped. Verify sign-in/session lifecycle, portal boundaries, workspace selection, RLS/policies/RPCs/Storage, migration/source parity and real two-school positive/negative tests. **Current release gate; open.** |
| **B** | Academic records, student population and class loading | Verify sessions, terms, school, class, arm, active enrolment, subject assignments and results for Super Admin and authorized staff, including Exam Officer. Test empty/populated states, paging, errors, refresh/navigation and roster integrity. Preserve the agreed IHLink Academy demo data without copying operational records into new schools. |
| **C** | Assessments, Class Subject Averages and approval workflow | Verify assessment entry, score edits, grading, averages, positions, broadsheets, review and publication. Required sequence: teacher submits → form master checks → section head compiles/reviews assigned section → Exam Officer reviews and publishes class-by-class. Support section-scoped permissions, partial publication and late submissions. Resolve the known Basic 5 A 2025/2026 subject-ID linkage anomaly before changing production data. |
| **D** | Result Design Studio and custom workbook templates | Each school can upload supported Excel workbooks, map fields, save/reload mappings, replace its applicable default and generate real student results. Nursery, Primary, Junior Secondary and Senior Secondary remain independent. Verify workbook paths, student/assessment mappings, persistence after reload, section isolation, same-school default fallback, correct student/term/session data, term-history columns and actual XLSX formulas/formatting. Return to deferred A4 print overflow/live print verification. |
| **E** | Document Studio and cross-school security | Review database RLS/policies, template-to-school relationships, storage upload/read policies, default-template RPC, finalization RPC, issuance authorization, signed-output access and audit records together. Test at least two schools and intended roles: neither may read/update the other's template, mapping, issued document, storage object or output. Align template-management and upload roles intentionally. Confirm issued documents cannot be overwritten and revoked documents cannot be rendered. |
| **F** | Historical data, academic-year rollover and progression | Preserve historical results, transcripts, certificates and audit trails. Verify transfer, promotion, graduation and new-year enrolment without losing historical identifiers or marks. Recorded rollover rule: 2025/2026 results may be unpublished without deleting marks/enrolments; 2026/2027 starts fresh; published 2000/2001–2024/2025 history remains preserved. Promotion preview must not auto-run on publish; graduated/transfer-out students are not promoted. |
| **G** | Other operational modules and portals | Maintain module-by-module acceptance for admissions, attendance, assignments, lessons, library, clinic, transport, hostel, payroll, leave, CBT/question bank, stores, documents/certificates, and parent/student/staff portals. Use controlled IHLink Academy test data where required. Verify each workflow, permissions, data mutations, loading/error states and role boundaries—not only whether a page loads. Recheck previously reported attendance/dashboard and enrolment-loading symptoms. |
| **H** | Fees, subscriptions and payment reconciliation | Verify school fee collection, allocations, receipts, arrears, bursar/proprietor controls, unpaid-fee result locks, subscription invoices, plan limits and reconciliation. Keep school-fee income separate from IHLink subscription revenue. Preserve the latest approved commercial rules: Demo and paid subscriptions are annual; hide paid amount while Demo is active; SchoolPro subscriptions use receipt upload and IHLink admin verification; school fees are handled by the school; BillStack is DataSub-only; two-week grace/suspension and upgrade balance calculations require acceptance tests. Resolve older conflicting price notes against the live approved configuration; do not guess. |
| **I** | Release, APK, Render deployment and support readiness | Verify approved source commit, release-artifact provenance, APK installation/launch, environment configuration, migrations, Render service health and critical live workflows. Verify current APK version rather than assuming the previously mentioned SchoolPro 1.0.4 is final. Maintain deployment, rollback, support, backup/recovery, DNS/email/hosting and operational guides. Render—not Vercel—is the production hosting target. |
| **J** | Platform-wide security, performance and resilience | Verify RLS, tenant isolation, sensitive document access, audit logging, backups/restore, failure handling, performance and known limitations. Confirm HTTPS, support/legal readiness, build/migration checks, payment settlement, transactional email, provider redundancy, backup/recovery and leaked-password protection limitations. Keep ecosystem-wide deployment tasks separate from SchoolPro-specific defects. Never expose service-role keys; BillStack webhook handling must use the intended Supabase Edge Function. |

**Execution order and completion rule**
- Continue from the Stage A blockers below. Do not start B until A is complete, reviewed and merged into the intended production branch with the user's explicit authorization, then verified after merge.
- Then complete and re-verify B, C and D in that order.
- Continue E, F, G, H, I and J in the original approved order. The historical source guide is recovered and the current table now preserves its A–J workstream/checklist scope; continue to carry forward explicit later requirements and deferrals.
- Stage-specific trackers may add implementation detail but must not narrow the A–J scope.
- This handover update does not authorize a production migration, production data change, merge or deployment.

## 3. Latest Stage A PR and CI state (16 October 2026)

PR #106: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106  
PR remains open, draft and unmerged. The exact current code-and-documentation head at this verification is `a622e28a0e9b209f7f7d5c02dc4ec25a459d16be`.

- **SchoolPro CI run #1047 passed** on that exact head. Both `validate` and live `tenant-acceptance` passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38896946134.
- **Payment-page validation run #773 passed** on the same exact head: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38896946151.
- Run #1041 also passed both CI jobs on earlier code commit `7c58c21d221ae6d26d63350f9851512a6ccf38af`: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38896381743.
- The recovered A–J roadmap is reconciled against the canonical historical guide at commit `1989a8e14d2bab69d758a231b532b7989857c40c`. The current table restores all ten original workstream titles and detailed acceptance focus while preserving later requirements.
- The authenticated two-school Storage test passed using an existing workbook: School A downloaded its own object; School B received HTTP 400 for that exact foreign object. The earlier folder-list timeout has a separate policy/query-performance cause; the proposed Storage migration remains draft-only.
- Payment receipt Storage tests remain skipped because `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` are not configured and no existing receipt fixtures are available. Do not upload dummy production receipts.
- Three source tenant-hardening migrations still lack matching ledger version/name pairs; the source for `20260924112325_schoolpro_secure_public_result_checker` was not found in the checked branches/history. Do not reconstruct it from a partial live function or repair migration history by guesswork.
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

Exact-head SchoolPro CI #1049 and payment-page validation #775 both passed on `b235e87a01abd53fd274895e4e7c560c6681d1d5` (2026-10-16). The next priority is a forward-only, non-production-tested repair for the confirmed cross-tenant relational-integrity gaps on lesson notes, result approvals, promotions and member permissions. Continue migration source/ledger reconciliation, review the Storage and result-PIN draft migrations, finish payment lifecycle/concurrency tests, and obtain valid existing receipt fixtures. Do not apply draft migrations to production from static tests alone.

## 4. Remaining Stage A release blockers

1. **Payment review write-boundary validation.** The new migration `20261016143000_schoolpro_payment_review_write_controls.sql` is draft-only. It needs reviewed runtime evidence that guardian submissions, school finance reads, Super Admin inspection and RPC-based confirmation/rejection still work while direct status/amount/allocation mutations are denied. Do not apply it to production on static CI alone.
2. **Migration source/ledger drift.** The production ledger contains 476 rows and ends at `20261015161735`. A read-only inventory of the current release branch found 127 migration SQL files: 79 exact version/name pairs, 24 files whose migration name exists in the ledger under a different version, and 24 source names with no matching ledger name. Conversely, 373 ledger names are not represented by same-named SQL files in this branch's migration directory. These counts describe repository/ledger correspondence, not proof that every unmatched migration is unapplied; renamed, historical and previously squashed sources must be traced before any repair. The three known tenant-hardening files below are not recorded under their source version/name pairs:
   - `20261002234500_schoolpro_operational_tenant_isolation.sql`
   - `20261003000500_schoolpro_guardian_tenant_hardening.sql`
   - `20261003002000_schoolpro_cbt_permission_tenant_integrity.sql`
   Never align names or repair the migration ledger by guesswork.
3. **Missing migration source.** The live ledger contains `20260924112325_schoolpro_secure_public_result_checker`, but the corresponding source migration file was not found in main, the release branch, the checked audit branches, or current repository history. Do not reconstruct it from a partial live-function snapshot. Recover authoritative source or establish a carefully reviewed baseline.
4. **Public result PIN brute-force protection.** A draft database-level attempt counter/cooldown migration is prepared. It is not applied or runtime-tested; review client-IP header trust, retention/cleanup, cooldown reset and concurrency behavior before release. Frontend-only throttling remains insufficient.
5. **Storage policy performance.** Exact-object cross-school acceptance passed. The earlier folder-list timeout root cause is confirmed, but the proposed policy migration is not applied or performance-tested; receipt download isolation remains untested until real, already-existing receipt fixtures are available.
6. **Payment lifecycle.** Pending/review/reject/cancel transitions, duplicate invoice allocations and concurrent receipt-submission behavior require dedicated transaction-level acceptance tests. The staged migration `20261015203000_schoolpro_payment_receipt_tenant_guard.sql` has not been applied to production.
7. **Broader authorization review.** Review exposed SECURITY DEFINER RPCs individually. Do not blanket-revoke public/authenticated execution because some guest/token workflows are intentional. Confirm Super Admin platform access without widening school-scoped actions.
8. **Post-merge production verification.** Only after explicit approval and every gate passing: verify merge SHA, Render deployment SHA/status, login and authorized/unauthorized workflows, and re-run relevant checks. No merge/deploy is currently authorized by this handover.

The detailed current checklist and evidence are in [Stage A release gate](https://github.com/Hassan-625/IHLink-SchoolPro/blob/release/stage-a-auth-tenant-isolation/docs/STAGE_A_AUTH_TENANT_ISOLATION_RELEASE_GATE.md).

### New read-only production integrity finding — 2026-10-16

The production catalog was inspected without inserting or changing data. Several later trigger implementations provide equivalent protection for some historical migration effects under different names: guardian links use `private.schoolpro_guardian_school_scope`; CBT test-question and eligibility relations use `private.enforce_schoolpro_tenant_relations` / `private.validate_schoolpro_cbt_eligibility`; result rows use `private.enforce_schoolpro_tenant_relations` and `trg_validate_schoolpro_result_tenant`; document issues use `private.enforce_schoolpro_tenant_relations`.

**A material relational-integrity gap remains confirmed by catalog inspection:** the current production database has no cross-table tenant guard trigger on `schoolpro_lesson_notes`, `schoolpro_result_approvals`, or `schoolpro_promotions`, and the historical function `private.schoolpro_validate_operational_tenant()` is absent. The `schoolpro_member_permissions` table also has no tenant-pair guard trigger or composite tenant/member constraint. Its separate foreign keys validate that the school exists and that the member exists, but do not enforce that the member belongs to the row's `school_id`. This is a structural cross-tenant integrity risk; no exploit or production row mutation was attempted.

A draft forward-only repair now exists at `supabase/migrations/20261016160000_schoolpro_repair_operational_tenant_integrity.sql`. It restores tenant validation for lesson-note subject/class references, result-approval result references, promotion student/source-class/destination-class references, and school/member permission pairs. Static regression coverage is in `scripts/test-schoolpro-operational-tenant-integrity.mjs` and is wired into `.github/workflows/ci.yml`. This is source-only work: it has not been applied to production. It must pass exact-head CI and reviewed runtime tests in a no-additional-cost non-production environment before release. Do not replay historical migrations wholesale or repair production migration history by guesswork.

## 5. Application requirements to preserve

### Authentication, roles and tenancy
- Super Admin is platform-wide and is not a school membership. School owner/proprietor/director/board/exam officer/IT/admin/staff identities are school-scoped.- Exam Officer uses the staff portal; directors and board members use the school-owner portal.
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
| A — Auth and tenant isolation | **In progress; not merge-ready** | Repair confirmed relational-integrity gaps; review Storage/PIN draft SQL; reconcile migration source/ledger; complete payment lifecycle and receipt tests |
| B — Sessions, population, rosters | **Not started in this release sequence** | Wait for A merged and post-merge verified |
| C — Assessments and results | **Re-verify after A/B gates** | Independent calculations, per-component saves, permissions, review/publication and history |
| D — Result Design Studio / custom Excel | **Deferred until A/B/C are re-verified** | Section templates, mapping, preview, tenant isolation and A4 output |
| Production migration / deployment | **Not performed in this work** | Requires completed release gate and explicit approval |


### Current verified application/test head — 2026-10-16

**Verified code/test head:** `6828de94852ac0de3e0cd7cc816c190b02be1d16`. Subsequent commits may refresh this handover and the Stage A release gate only. PR #106 remains open, draft and unmerged.

- SchoolPro CI run #1077 passed `validate`, live two-school `tenant-acceptance`, and disposable PostgreSQL integration: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38918517117.
- Payment-page validation run #803 passed on the same code/test head: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38918516989.
- The disposable PostgreSQL 16 job applied the draft migration to an ephemeral database and passed 13 negative tenant-integrity checks. It verifies trigger execution in a minimal fixture; it does not establish full Supabase/production-schema compatibility or authorize a production migration.
- The migration now takes shared locks while validating referenced parent rows and makes tenant ownership immutable for subjects, classes, students, results and members. This prevents later school reassignment from invalidating child relationships beyond the initially identified tables. Production catalog inspection was read-only and confirmed the named columns/relations; existing trigger ordering still requires full review.
- An intermediate integration run failed on a malformed function delimiter; the delimiter was corrected, then the full integration and exact-head CI passed. No production state was touched.
- **Stage A remains in progress and not merge-ready.** Continue the remaining Stage A blockers: full-schema/trigger review, migration source/ledger reconciliation, Storage policy performance, result-PIN cooldown review, payment review/lifecycle/concurrency, and receipt Storage tests where existing fixtures are available. Do not create dummy production data or a paid Supabase branch.
- Preserve the complete A–J roadmap. B waits for A; C and D remain gated in order; E–J remain open in the master handover. No production migration, row write, Render deployment or merge has been performed.


### Payment RLS policy semantics corrected — 2026-10-16

- Verified code/test head: `c599758d0a3fa92ec773ea3b63bb7c23f3e435fd`; subsequent commits in this branch are documentation-only.
- SchoolPro CI #1128 passed `validate`, live two-school tenant acceptance and disposable PostgreSQL tenant-integrity integration; payment validation #855 passed on the same code/test head.
- A read-only production policy audit showed `schoolpro_module_permission` is restrictive, not permissive. The unmerged payment-review migration was corrected so it does not treat dropping that policy as removal of a write grant. It explicitly recreates restrictive scopes for all four payment tables; preserves linked-guardian submission/proof checks and submitter-scoped allocation reads; adds explicit Super Admin SELECT-only inspection; removes the broad Super Admin ALL policy on fee payments; and denies Super Admin direct fee-ledger writes through the restrictive check.
- A first static regression run caught that three Super Admin SELECT policies were missing after the refactor. They were restored and the subsequent exact-head CI passed. This was branch-only; no production SQL was applied.
- Remaining caveat: no live production write test was attempted. Payment RLS checks are static/source contracts plus CI; a dedicated disposable PostgreSQL RLS-role integration test and payment lifecycle/concurrency tests are still required.
- Stage A remains not merge-ready. Full-schema/trigger review, migration provenance reconciliation, Storage performance, result-PIN cooldown, payment lifecycle/concurrency, and receipt-Storage acceptance remain open. No production migration, row write, Render deployment or merge occurred.


### Result PIN concurrency guard added — 2026-10-16

- Verified code/test head: `8ff7f389b651248675f6a5b15e1c834d7fa78c2d`; later commits on this branch may be documentation-only.
- SchoolPro CI #1140 passed `validate`, live two-school tenant acceptance and disposable PostgreSQL tenant-integrity integration. Payment-page validation #867 passed on the same exact code/test head.
- The result-PIN rate-limit migration now obtains a PostgreSQL transaction advisory lock based on the hashed admission/network attempt key before checking cooldown and looking up a student. This serializes concurrent checks sharing the same key; a static regression test asserts the lock ordering. Dedicated runtime cooldown/concurrency tests remain outstanding.
- **Unresolved network trust:** the draft currently prefers `x-forwarded-for` when deriving the attempt key. Confirm Supabase gateway header sanitization and trusted client-IP semantics before relying on the header; do not assume caller-supplied values are trustworthy.
- Read-only aggregate check at audit time found 1,214 student rows, zero normalized admission numbers reused across schools, and zero duplicates within a school. This is a current-state count only; because admission uniqueness is school-scoped, the public result checker still needs a school discriminator or fail-closed ambiguity handling for future tenants.
- Stage A remains not merge-ready. No production SQL, row write, Render deployment or merge occurred.


## Exact-head refresh — 2026-10-16 (payment RLS regression test alignment)

- Verified application/test head: `3fc09cd2fa0382a15bb48f4e134f0e2cf595df53`. PR #106 remains draft/open/unmerged.
- SchoolPro CI #1145 passed all three jobs, including the disposable PostgreSQL tenant-integrity integration and live two-school tenant acceptance: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925209603.
- Payment-page validation #872 passed on the same exact head: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925209600.
- The payment-review static regression test was aligned with the final draft policy implementation by removing stale comment-text assertions; it now asserts the actual restrictive-policy boundaries, guardian ownership checks, Super Admin SELECT-only policies, and no destructive data statements. The exact-head CI passed after this test correction.
- These are source/static and CI results only. The payment RLS migration has not been applied to production, and the payment policies have not been exercised under real authenticated roles in a disposable PostgreSQL RLS fixture. That role-based integration test, payment lifecycle/concurrency tests, and full-schema interaction review remain open.
- Stage A remains **NOT MERGE-READY**. The latest tested commit does not clear the existing Storage performance, result-PIN trusted-network/runtime, migration-provenance, payment lifecycle, or receipt-Storage gates. No production migration, row write, Render deployment or merge occurred.

---

## Continuation update — 2026-10-29

### Stage A — public result-PIN ambiguity hardening

- Code/test head before this handover update: `633df525feb695711cb89ff17bcf5a101008c470` on `release/stage-a-auth-tenant-isolation`, PR #106.
- Review found that `check_schoolpro_result_pin` selected the newest matching student after filtering by admission number and PIN. Admission numbers are only school-unique, and a PIN collision across schools could make that selection ambiguous.
- The draft migration `20261016122000_schoolpro_result_pin_attempt_rate_limit.sql` now counts active candidates matching admission number, term, session and PIN. More than one match returns the same generic failure and increments the attempt counter; it no longer chooses the newest row arbitrarily.
- Added a disposable PostgreSQL integration case that creates an identical admission/PIN pair across two synthetic schools, asserts fail-closed behavior, then restores a unique PIN and confirms the intended student's result can still be retrieved.
- On code/test head `633df525feb695711cb89ff17bcf5a101008c470`, the `result-pin-rate-limit-integration`, `result-verification-exposure-integration`, `payment-review-rls-integration`, `tenant-integrity-db-integration`, and `public-admission-abuse-integration` jobs passed; the static `validate` checks and local receipt-Storage job were still running at the last status check. Payment-page validation was also still running. Do not claim full exact-head CI until all jobs complete and the final documentation head is rechecked.
- This is draft-branch code only. No production migration, data write, merge or Render deployment was performed. PR #106 remains draft and unmerged.

### Preserve the user's detailed Stage B/C score-entry requirement

- Do not require a teacher or section head to wait until every assessment has been entered before saving or submitting scores. Support assessment-by-assessment entry and persistence (for example, first CA/assignment, subsequent assessment, then examination) with clear partial/incomplete states and safe resume/edit behavior.
- Section heads must be able to enter, compile and review scores for their assigned section/class assessment-by-assessment, not merely wait for a complete score bundle from all teachers. Enforce the assigned-section scope; retain Exam Officer review/publication class-by-class and preserve the approved teacher → form master check → section head → Exam Officer workflow.
- Keep all existing unmerged PR requirements and implementation notes under the Stage B planning register rather than dropping them. This clarification is recorded now, but implementation remains gated: continue Stage A first; do not start B until A is approved, merged and post-merge verified.

This update records source/test progress and preserves the roadmap; it does not authorize production migration, merge, deployment or production data changes.
### Exact-head CI and next Stage A gate — 2026-10-29

- Latest checked source/documentation head: `9e4d295294dd8e8d79423082f62e9e6645cd68bc` on `release/stage-a-auth-tenant-isolation`, PR #106.
- SchoolPro CI run [#40842375412](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40842375412) completed: all seven executable jobs passed, including disposable payment-review RLS, tenant-integrity/receipt-submission concurrency, local Supabase Storage isolation, result-PIN cooldown/ambiguity, public-admission abuse controls, result-verification exposure and full validation/build. The `tenant-acceptance` job was **skipped**, not passed.
- Payment-page validation [#40842375353](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40842375353) passed on the same checked head.
- This closes the exact-head CI check for the branch snapshot, but does **not** clear live production tenant acceptance. The prior read-only authenticated two-school probe timed out on `schoolpro_result_approvals`; the proposed `schoolpro_result_approvals(school_id)` index is still unapplied. The index, forward-only ENABLE/FORCE RLS migration and tenant-integrity trigger migration are source proposals only.
- Next Stage A sequence remains: obtain explicit approval for the reviewed production DDL; apply the six-index migration first; verify catalog and authenticated query plan; then apply the forward-only RLS posture migration and tenant-integrity migration; finally rerun read-only authenticated two-school acceptance and reconcile catalog/ledger/policies/triggers. Do not run these steps without explicit approval. Do not suppress the live acceptance check or substitute disposable CI for it.
- No production migration, row write, dummy account/school/receipt creation, Render deployment or merge occurred. PR #106 remains draft/open/unmerged. Stage B is still gated on explicit Stage A approval, merge and post-merge verification.
- Stage B/C requirement retained: teachers and section heads must save/submit assessments incrementally (CA/assignment, subsequent assessment, examination), with resumable partial states; section heads operate only within assigned sections/classes; retain teacher → Form Master check → section head → Exam Officer review/publication class-by-class. Keep all unmerged PR requirements in the Stage B planning register. Do not implement B before the A gate is cleared.

### Production rollout safety review — index locking and acceptance — 2026-10-29

A source-only review of the proposed operational index migration identified an execution consideration to address before any approved production rollout:

- `20261017180000_schoolpro_operational_tenant_indexes.sql` uses ordinary `CREATE INDEX IF NOT EXISTS` for six indexes. On PostgreSQL, a normal index build can block writes to its target table while the build runs. The affected tables include `schoolpro_result_approvals`, whose existing authenticated RLS query previously timed out.
- Do not assume this migration is non-blocking just because it does not change rows. Before production execution, choose and document an acceptable maintenance window or a separately reviewed `CREATE INDEX CONCURRENTLY` procedure. Concurrent index creation cannot run inside a transaction block, so do not blindly replace the statements in a normal transactional Supabase migration; rehearse the exact deployment mechanism and failure/retry cleanup first.
- For the approved rollout, capture pre-change index/catalog state, execute only the approved index operation, confirm each index is valid and attached to the intended table, and re-run the authenticated bounded two-school probe and query-plan inspection. If the result-approval probe still times out, stop and diagnose rather than continuing to the RLS/trigger migrations.
- Keep the subsequent RLS posture and tenant-integrity migrations as separate, explicitly approved steps. Do not combine all three into one unreviewed production batch. Preserve feature-specific policies and verify trigger/function ownership and execution behavior after each step.
- This is a deployment-safety review only. No production SQL was executed, no data or fixtures were created, and no deployment or merge was performed. PR #106 remains draft/open/unmerged; live tenant acceptance remains outstanding.

### Index rollout execution decision — 2026-10-29

- **Decision for the draft release plan:** do not rewrite the existing six-index migration to use `CREATE INDEX CONCURRENTLY` in place. Concurrent index creation cannot run inside a transaction block, while the current Supabase migration is a normal SQL migration and its transaction behavior must not be assumed away.
- Before any production rollout, rehearse the exact index operation on an isolated Supabase branch with representative schema/data and the same database version. If the branch confirms concurrent creation is supported through the chosen execution path, use individually reviewed `CREATE INDEX CONCURRENTLY IF NOT EXISTS` statements for the six tenant-leading indexes as a separately controlled operational step; then let the existing migration's `IF NOT EXISTS` statements verify/no-op against those indexes. Do not mark a migration applied manually or alter migration history by guesswork.
- For each index, verify catalog state after creation: the expected index exists on the intended table, its key begins with `school_id`, and `pg_index.indisvalid` is true. If a concurrent build fails and leaves an invalid index, stop and follow a reviewed cleanup/retry procedure; do not continue to RLS or trigger changes.
- Capture the pre-change catalog and query plan. After the result-approvals index is valid, rerun the bounded authenticated two-school acceptance probe and inspect the plan. A timeout or any ambiguous transport error remains a failed acceptance; do not suppress or skip it.
- Only after the index and acceptance evidence are reviewed should the separate forward-only RLS posture and tenant-integrity trigger migrations be considered, in that order, with explicit production-change approval. Preserve existing policies and reconcile the migration ledger/catalog after each approved step.
- This is a proposed execution method, not authorization to perform production DDL. No production changes, migrations, account creation, school creation, merges, or deployments were performed.

### Concurrent index rehearsal runbook and Supabase branch status — 2026-10-29

- Added [`docs/database-migration/STAGE-A-CONCURRENT-INDEX-ROLLOUT.md`](https://github.com/Hassan-625/IHLink-SchoolPro/blob/release/stage-a-auth-tenant-isolation/docs/database-migration/STAGE-A-CONCURRENT-INDEX-ROLLOUT.md) on the Stage A branch. It contains preflight/catalog checks, six one-at-a-time `CREATE INDEX CONCURRENTLY IF NOT EXISTS` statements for isolated rehearsal only, postflight validation, and explicit stop conditions for invalid indexes, query-plan regressions, and failed two-school acceptance.
- Read-only Supabase branch inventory returned only the default `main` branch; its reported status is `MIGRATIONS_FAILED`. No separate development branch is available in the listing. Do not reset or use this branch as the rehearsal target.
- Supabase branch creation may incur charges. Get the quoted cost and approval before creating an isolated branch; no branch was created.
- The runbook is documentation, not permission to run production DDL. The existing transactional six-index migration remains unchanged. Concurrent index creation must be rehearsed outside a transaction, and any failed build/invalid index requires reviewed cleanup before retry.
- No production SQL/migrations, data writes, test accounts/schools, merges, or deployments were performed. Stage A remains open until index verification and authenticated two-school acceptance pass; B remains gated.

### User decision — no additional Supabase branch — 2026-10-29

- User explicitly declined any additional Supabase branch. Do not create one or ask again.
- The concurrent-index runbook is retained as reference documentation only; its isolated-branch rehearsal step is not the chosen path. Do not treat the runbook as authorization to run SQL.
- Continue with repository/source review and available read-only evidence against the existing environment. No production DDL, migrations, row writes, test accounts/schools, migration-ledger edits, merges, or deployments without explicit approval.
- User has clarified that tenant-isolation acceptance already passed in their previous SchoolPro workspace across two existing workspaces. Record that prior two-workspace tenant-isolation test as passed; do not ask the user to repeat it, and do not create replacement test identities/workspaces. Keep the `schoolpro_result_approvals` timeout as a separate unresolved result-path/release check, not as evidence that tenant isolation failed. The missing index and sequential-scan plan remain diagnostic findings, not proof of the timeout's sole cause.

### Read-only production index catalog check — 2026-10-29

- Per user direction, no additional Supabase branch will be created. The runbook is reference-only; do not run its concurrent-index commands in production without explicit approval.
- Executed read-only catalog queries against the existing Supabase project `lnqsroyiybutkfngbyge`; no DDL or row writes were issued.
- All six target tables exist in `public`. None currently has the proposed `school_id` index:
  - `schoolpro_library_books`
  - `schoolpro_transport_routes`
  - `schoolpro_hostel_rooms`
  - `schoolpro_inventory_assets`
  - `schoolpro_result_approvals`
  - `schoolpro_promotions`
- Existing indexes observed on the target tables were primary-key indexes, plus existing uniqueness indexes on `schoolpro_result_approvals(result_id)` and `schoolpro_promotions(student_id, session)`. All observed indexes reported `indisvalid=true` and `indisready=true`.
- `schoolpro_result_approvals` heap size is approximately 5,976 kB; catalog row estimate was zero, which is stale/inconsistent with the heap size and must not be used to claim the table is empty. It has existing result-id indexes but no tenant-leading `school_id` index. This supports further read-only plan diagnosis; it does not by itself prove the missing index caused the earlier timeout.
- Several other target tables have an 8 kB or reported 0-byte heap with row estimates of zero or unknown; no data was read or changed. Catalog row estimates can be stale.
- Next safe step: inspect column definitions, policies, and a bounded non-executing `EXPLAIN` for the exact prior acceptance query, then document whether the plan can be improved. Do not run `EXPLAIN ANALYZE` or change production indexes as part of this diagnostic step.
- Stage A remains open. No test accounts/schools, additional branches, production migrations, DDL, data writes, merges, or deployments were performed.

### Read-only result-approvals plan and policy inspection — 2026-10-29

- Read-only inspection of `public.schoolpro_result_approvals` confirmed columns include `school_id uuid`, `result_id uuid`, `status`, review fields, `notes`, and `id`. Its authenticated SELECT policy requires `private.has_school_access(school_id)` and `private.schoolpro_module_allowed(school_id, 'results')`; the ALL policy also evaluates `schoolpro_member_can_manage(school_id)` or an authorized member-role existence check.
- Read-only `EXPLAIN (COSTS, VERBOSE, SETTINGS)` for a bounded lookup filtering `school_id` showed a sequential scan on `public.schoolpro_result_approvals` (estimated cost 0.00..747.00), because no school-leading index currently exists. This was plain EXPLAIN, not EXPLAIN ANALYZE; it did not execute the query to measure latency and used a placeholder UUID. It does not reproduce the authenticated PostgREST/RLS probe or prove the index alone will resolve the timeout.
- The access/module functions also consult profile status, school ownership/membership, account activity, operational state, and permissions. If the live probe continues timing out after a future approved index change, inspect those dependencies and their plans rather than assuming the tenant index is the only cause.
- No index was created and no policies/functions were changed. These findings came from read-only catalog/function inspection only.


### User clarification — prior two-workspace tenant-isolation acceptance passed — 2026-10-29

- User confirms that tenant isolation worked in the previously tested two-workspace SchoolPro acceptance. Carry this forward as passed evidence; do not re-run the same acceptance merely to recreate evidence and do not create additional Supabase branches, test accounts, or test schools.
- Keep the scope precise: this confirms the user's prior two-workspace acceptance result. It does not by itself close unrelated Stage A release checks, including the separate `schoolpro_result_approvals` timeout/index-plan investigation or review of the proposed RLS/tenant-integrity changes.
- Continue with source review and read-only diagnosis. No production DDL, migrations, data writes, migration-ledger edits, merges, or deployments are authorized by this clarification. Stage B remains gated until Stage A is formally approved, merged, and post-merge verified.

### Read-only result-policy dependency index review — 2026-10-29

- Inspected the current definitions of `private.has_school_access`, `private.schoolpro_module_allowed`, `private.schoolpro_operationally_active`, `private.is_admin`, `public.schoolpro_user_permissions`, and `public.schoolpro_member_can_manage`. These functions check the active profile, school owner/membership, subscription/operational status, role, board membership, and member permissions; the timeout may involve one or more of these policy dependencies, so the missing `school_id` index on `schoolpro_result_approvals` is not assumed to be the sole cause.
- Read-only catalog inspection found valid/ready supporting indexes on `profiles(id)`, `schoolpro_schools(id)` and `schoolpro_schools(owner_id)`, `schoolpro_subscriptions(school_id)`, `schoolpro_members(school_id,user_id)` and `(user_id,school_id)`, `schoolpro_board_members(school_id)`, and `schoolpro_member_permissions(member_id,permission)`. All indexes returned for these dependency tables reported `indisvalid=true` and `indisready=true`.
- This is catalog evidence only; it does not establish runtime latency or prove the policy functions are performant under the exact authenticated PostgREST/RLS request. No query execution benchmarks, DDL, policy changes, or data writes were performed.
- PR #106 remains open, draft, and unmerged. The latest PR head at that point was `6ef9792ff21e9d684a6d5369b9df12bb111152e2`; later updates are tracked in the review section below. No production deployment or merge was triggered.
- Acceptance tracking: user's prior two-workspace tenant-isolation acceptance is recorded as passed; the separate `schoolpro_result_approvals` result-path timeout/index investigation and remaining Stage A review gates remain open. Stage B stays gated pending explicit Stage A approval, merge, and post-merge verification.

### Stage A source review follow-up — 2026-10-29

- Re-read the Stage A operational index migration, forward-only RLS posture migration, tenant-integrity trigger migration, payment RLS review, and the existing static payment regression test. The index migration creates six normal (transactional) indexes; it is not a concurrent-index migration. Do not change it to `CREATE INDEX CONCURRENTLY` inside the normal Supabase migration transaction. The separate concurrent-index runbook remains rehearsal-only reference material.
- The operational tenant-integrity static test checks trigger names, same-school references, immutable tenant ownership, and the eight-table FORCE-RLS target list. The migration is also described by prior disposable PostgreSQL integration evidence, but full production-schema trigger-order/interaction review remains open.
- The payment RLS test currently asserts SQL source patterns and does not execute grants/policies as distinct PostgreSQL roles. The earlier payment review correctly keeps guardian update boundaries, school-finance operations, Super Admin read-only behavior, and authorized RPC transitions blocked pending a disposable real-role PostgreSQL test plus lifecycle/concurrency coverage. No concrete production exploit was established by this source review; the gap is lack of effective-policy runtime proof.
- Current PR metadata confirms PR #106 is open, draft, and unmerged at head `289c97b682d4cb18cfb96c53925022190a438a4d`. The latest documentation commit has no associated workflow runs. The combined commit status shows a failed `Vercel` context; SchoolPro production is hosted on Render, so this status is not evidence of a Render production deployment failure and must not be substituted for Render deployment/CI evidence.
- User-confirmed two-workspace tenant-isolation acceptance remains recorded as passed. Next implementation task is to add/strengthen disposable PostgreSQL real-role payment RLS coverage and lifecycle/concurrency tests, without using production, creating Supabase branches/accounts/schools, changing migration history, merging, or deploying. Stage B remains gated until Stage A's required checks and approval/merge/post-merge verification are complete.

### Correction — payment RLS disposable integration fixture already exists — 2026-10-29

- Follow-up inspection of `.github/workflows/ci.yml` and `scripts/test-schoolpro-payment-review-rls.integration.sql` found that the branch already contains a `payment-review-rls-integration` PostgreSQL 16 CI job. It runs the draft payment RLS migration against a disposable reduced schema, switches to the `authenticated` role, and asserts guardian scope, direct-write denial, finance write boundaries, Super Admin read-only behavior, RPC authorization, rollback atomicity, duplicate-review rejection, and email-queue rollback. The workflow also launches two concurrent review calls and expects exactly one confirmation/ledger payment.
- Therefore, do not create a duplicate fixture. The older static-only payment test note above is superseded on this branch by this additional integration coverage. The fixture explicitly uses a reduced schema and stubs for production helper functions, so it is meaningful behavioral coverage but not a complete restore of the production schema/policies/functions. Full-schema interaction and exact live behavior remain distinct gates.
- Latest documentation commit `f4b1440fc6502310ca237e241d889be68c623274` has no workflow run associated with it; the existence of a CI job is not the same as proof it passed at the current head. Verify the job result on the latest code-bearing PR head before closing this gate. No production SQL, account/school creation, branch creation, merge, or deployment was performed.

### Receipt Storage CI startup conflict isolated and harness adjusted — 2026-10-29

- Inspected failing SchoolPro CI run #2025 (run ID `40844374538`) and its `Receipt Storage isolation (local Supabase)` job. The job failed during `supabase start`, before the Storage assertions, because the disposable database container could not bind default host port `54322` (`address already in use`). The same job log also shows transient registry throttling, but the terminal failure was the database port bind. This is a test-environment startup failure, not a tenant-isolation assertion failure.
- Updated `scripts/test-schoolpro-receipt-storage-local.mjs` to allocate a free local database port and set it in the temporary Supabase config rather than hard-coding the CLI default. The script still creates its own temporary local Supabase stack and removes its temp directory; it does not connect to the remote project. Commit: `2fafacaa60cc9d98578038776e7aedca3eeb5ac4`.
- Existing CI evidence on prior code head `6c880ae5a6fa78a460064aeb91e9c7e22a72876d` shows `payment-review-rls-integration`, `result-pin-rate-limit-integration`, `tenant-integrity-db-integration`, `result-verification-exposure-integration`, `public-admission-abuse-integration`, and `validate` all passed; `tenant-acceptance` was skipped because it is manual-only. On the later run #2025, the same database/payment/result integration jobs passed, while receipt Storage failed at stack startup. This distinction is recorded so the failure is not misclassified as tenant isolation failing.
- Latest branch head is `2fafacaa60cc9d98578038776e7aedca3eeb5ac4`; PR #106 remains open, draft, and unmerged. No CI run was yet reported for this exact commit at the time of this note; the port fix is not considered verified until the receipt Storage job passes on a subsequent run. The Vercel status context remains unrelated to Render production hosting. No production SQL, data changes, account/school creation in the remote project, merge, or deployment occurred.

### Read-only FORCE RLS owner semantics check — 2026-10-29

- Queried the live catalog read-only for the eight operational tables in `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` and their policy-helper function owners. All eight tables are owned by role `postgres`, which has `rolbypassrls=true` (and `rolsuper=false`); the inspected SECURITY DEFINER policy helper functions are also owned by `postgres` with `BYPASSRLS`.
- Consequence: `FORCE ROW LEVEL SECURITY` does not constrain this live table owner or these helper functions because PostgreSQL roles with `BYPASSRLS` bypass RLS. The migration comment correctly notes this limitation in general. Therefore, FORCE RLS is not itself an effective additional barrier against the current `postgres` owner; client isolation still depends on correct grants, authenticated policies, and the explicit authorization checks inside privileged functions. This finding does not prove a client-side bypass, but it means the Stage A review must not present FORCE RLS as containment for privileged-owner paths.
- No migration was applied and no data was changed. Existing user-confirmed two-workspace acceptance remains passed. A deeper review of any exposed SECURITY DEFINER function must confirm that each function validates the caller/tenant itself and cannot be invoked to read or mutate cross-tenant data.

### CI refresh after receipt Storage port adjustment — 2026-10-29

- SchoolPro CI run #2029 (`40844812417`) is running on the handover/documentation update. At latest check, `payment-review-rls-integration`, `result-pin-rate-limit-integration`, `tenant-integrity-db-integration`, `result-verification-exposure-integration`, and `public-admission-abuse-integration` passed; `validate` and `Receipt Storage isolation (local Supabase)` were still in progress; manual live `tenant-acceptance` was skipped as configured. Payment-page validation #1756 passed.
- Do not call the receipt Storage port adjustment verified until that job reports success. PR #106 remains open, draft, and unmerged. No production change, merge, or deployment occurred.


### Receipt Storage CI fix verified and exposed result RPC review — 2026-10-29

- Exact code-fix commit `2fafacaa60cc9d98578038776e7aedca3eeb5ac4` now has successful SchoolPro CI run [#2029](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40844759790) and payment-page validation [#1756](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40844759789). All eight SchoolPro CI jobs completed: seven passed, and the manual-only `tenant-acceptance` job was skipped by design. Specifically, `Receipt Storage isolation (local Supabase)` passed, so the dynamic-port harness adjustment is verified on this code commit. This is local disposable-stack evidence, not a new live production tenant acceptance.- Read-only catalog/function review of the live Supabase project found `public.check_schoolpro_result_pin(text,text,text,text)` is SECURITY DEFINER, executable by `anon`, and still resolves duplicate active admission numbers using `ORDER BY st.created_at DESC LIMIT 1`. It then validates the PIN for only that arbitrarily selected student and can return published results. The Stage A branch has a proposed fail-closed ambiguity fix (count matching active candidates and return the same generic invalid-details/PIN response if more than one exists), but that migration has not been applied to production. This is a source/live drift and release blocker to reconcile; it is not evidence that a cross-tenant bypass has been demonstrated. Do not apply the migration without explicit production-change approval.
- The other inspected public result RPCs use authenticated EXECUTE grants; the public verification-code RPC is intentionally anonymous-readable and returns the saved result snapshot only for a matching valid code, returning no snapshot for revoked codes. Keep verification-code entropy and snapshot exposure in the existing review scope; no code was guessed and no rows were changed.
- No production DDL, data writes, test accounts/schools, extra Supabase branches, migration-ledger edits, merge, or deployment occurred. PR #106 remains draft/open/unmerged. The user's prior two-workspace tenant-isolation acceptance remains recorded as passed; the separate `schoolpro_result_approvals` timeout is still unresolved. Stage B remains gated pending explicit Stage A approval, merge, and post-merge verification.

### Result-PIN gateway compatibility confirmed from source — 2026-10-29

- Traced `src/pages/schoolpro/SchoolProResultChecker.tsx`: the browser invokes `schoolpro-result-pin-check` and does not call `check_schoolpro_result_pin` directly.
- `supabase/functions/schoolpro-result-pin-check/index.ts` performs Turnstile/origin checks and invokes the database RPC using `SUPABASE_SERVICE_ROLE_KEY`. The migration's revoke for `PUBLIC`, `anon`, and `authenticated`, with execute granted to `service_role`, is compatible with this tracked source path.
- `scripts/test-schoolpro-result-pin-edge-gateway.mjs` asserts the gateway call path and grant contract. This resolves the source-level compatibility question; it does not prove the Edge Function is deployed/configured in production or authorize the migration.
- The result-PIN migration remains a proposal and has not been applied to production. Preserve current production behavior until the migration is separately approved and deployed through the release process.
- Latest inspected Stage A head remains `9ecf3c3d85b7c9916f41e75a2a4105705d648eb4`; PR #106 remains draft/unmerged. Exact-head SchoolPro CI and payment-page validation passed on that head. No production DDL, data writes, deployment, or merge occurred.

### Exact-head CI and trusted-client-IP review — 2026-10-29

- Current PR #106 head is `73da7787f2388d2057df585a36cb9ced8cffaa52`. Exact-head SchoolPro CI [#2032](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40850468539) and payment-page validation [#1759](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/40850468306) both completed successfully. The manual-only live tenant-acceptance job is skipped unless explicitly enabled; green CI does not close the known live `schoolpro_result_approvals` timeout.
- Reviewed `schoolpro-account-login`, `schoolpro-student-login`, and `schoolpro-result-pin-check` against their regression checks. Login throttling is keyed by normalized account identity; the result-PIN database cooldown is keyed by a digest of the normalized admission identifier. These paths do not derive a security/rate-limit identity from caller-supplied forwarding headers. This avoids spoofable `X-Forwarded-For`/similar values, but does not provide IP-based throttling; do not add IP buckets until the trusted proxy provenance is established.
- The result-PIN Edge Function independently enforces origin allowlisting, Turnstile action/hostname validation, request-size bounds, and invokes the database RPC with `SUPABASE_SERVICE_ROLE_KEY`; the browser uses the Edge Function rather than direct RPC execution. This is source-level evidence only and does not confirm the production Edge Function secrets/configuration or authorize the database migration.
- No production SQL, data writes, deployments, account/school creation, branch creation, or merge occurred. PR #106 remains draft/unmerged. The result-PIN migration and operational index/RLS/integrity migrations remain unapplied; Stage A remains blocked by the live result-approvals query timeout and other open production-reconciliation gates.
