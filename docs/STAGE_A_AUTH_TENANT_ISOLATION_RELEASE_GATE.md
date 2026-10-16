# SchoolPro Stage A — Authentication and Tenant Isolation Release Gate

**Status: IN PROGRESS — NOT MERGE-READY.** This document is the release gate for the isolated Stage A workstream. It does not replace the master handover.

## Verified release baseline

- Render service: `ihlink-schoolpro` (`srv-db0k11m0tbcc7386fmq0`)
- Production URL: https://ihlink-schoolpro.onrender.com
- Render is configured to deploy from `main`.
- Render deployment inspection identified live commit `29856dff17ea8a3bc8bb31b7900967b7df9d316b` (2026-10-13 18:56 UTC). Use this newer baseline rather than the older `4af35b34e4b70e407b058f9f18af5c18024c1d1d` reference.
- Dedicated branch: `release/stage-a-auth-tenant-isolation`
- Draft PR: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106

## Implemented in this isolated subtask

- Prevent stale profile-query responses from replacing the latest authenticated account's profile and product-access state.
- Ignore delayed auth callbacks when a newer auth event has occurred.
- Invalidate scheduled and in-flight profile work on sign-out.
- Add `scripts/test-auth-profile-race.mjs` and wire it into the existing SchoolPro CI workflow.

This is a narrow authentication-race correction only. It is not a declaration that Stage A is complete.

## Read-only production database audit (2026-10-15)

The Supabase production project was inspected read-only; no schema changes, migrations, or data writes were made.

- **107/107 `schoolpro_%` tables have RLS enabled.** No public-schema table was found with RLS disabled. None of those 107 tables currently has `FORCE ROW LEVEL SECURITY`; this is not automatically a client bypass, but table-owner execution paths and privileged routines still require review.
- The database reports **873 policies in `public`**, including **293 policies on SchoolPro tables** and **52 restrictive policies** across `public`. Because permissive policies OR together, policy-by-policy review remains mandatory; counts alone do not prove isolation.
- Live migration history contains tenant-hardening entries under different names than some source migration files, including `fix_schoolpro_guardian_rls_correlations` (`20260923184341`), `enforce_schoolpro_cross_table_tenant_integrity` (`20261003104729`), `enforce_schoolpro_cbt_eligibility_tenant_and_revocation_integrity` (`20261003112317`), `enforce_schoolpro_subject_assignment_tenant_and_teacher_integrity` (`20261003114251`), and `complete_schoolpro_results_assignment_cbt_integrity` (`20261003124002`). The latest migration recorded is `schoolpro_access_invitation_role_constraint` (`20261015161735`).
- The three source files below are present, but **their exact version/name pairs are not present in the live migration ledger**. Later tenant-hardening migrations exist, so treat this as source/ledger drift to reconcile rather than assuming those exact files ran:
  - `20261002234500_schoolpro_operational_tenant_isolation.sql`
  - `20261003000500_schoolpro_guardian_tenant_hardening.sql`
  - `20261003002000_schoolpro_cbt_permission_tenant_integrity.sql`
- Added a regression contract for the existing source migration guards and connected it to the already CI-invoked auth-race test script. This is a **source-contract check**, not live authenticated RLS acceptance.
- Added an isolated, unmerged migration at `supabase/migrations/20261015203000_schoolpro_payment_receipt_tenant_guard.sql`. It checks that a fee-payment receipt belongs to the submitting user and exists in the expected Storage bucket, verifies guardian links against the same school and student, and locks each same-school invoice during allocation validation. This is staged code only; it has **not** been applied to production. The pending-payment/review lifecycle and duplicate invoice allocations still need dedicated transaction-level acceptance tests before merge.


## Additional live security-advisor findings (2026-10-15)

- Supabase's security advisor reports 7 RLS-enabled tables with no direct policies: schoolpro_access_invitations, schoolpro_account_challenges, schoolpro_initial_credentials, schoolpro_login_attempts, schoolpro_student_activation_challenges, schoolpro_transcript_issues, and datasub_pin_recovery_attempts. A follow-up privilege audit confirmed anon has no SELECT grant and authenticated has no SELECT/INSERT/UPDATE/DELETE grants on any of these tables. This is intentionally fail-closed for direct client access; keep them RPC/trigger-only unless a specific supported direct-access use case is demonstrated. Do not add broad policies just to silence the advisor.
- The advisor reports 9 anonymous-callable SECURITY DEFINER RPCs. Several are intentionally public token workflows (admission offer, public application, result PIN/code verification, candidate CBT). Their public exposure is not automatically a defect, but token entropy/expiry, rate limiting, replay behavior, information disclosure, and school scoping must be tested. Candidate CBT RPCs validate access tokens and attempt state in their definitions; end-to-end negative tests are still required.
- The advisor reports 154 SECURITY DEFINER functions executable by authenticated users. This is not a blanket reason to revoke grants: review each exposed function's purpose, auth.uid() checks, role/module checks, tenant scope, search_path, and whether it returns or mutates cross-school data. Revoke only where the RPC is not part of the supported application contract.
- Storage policies inspected include caller-UID-prefixed upload/read rules for schoolpro-payment-receipts and school-scoped result-template access. Verify these using two authenticated identities; policy text alone is not runtime acceptance evidence.
- The payment-submission migration now subtracts amounts reserved by other pending submissions when validating an invoice allocation, in addition to row locking. This reduces duplicate pending claims on the same invoice, but review/reject/cancel transitions and parallel transaction behavior still require integration tests.


## Read-only transaction-scoped tenant checks (2026-10-15)

These checks ran in short SQL transactions as the authenticated database role with each selected active user's JWT subject claim set locally. Every transaction was rolled back; no application data was changed. They are database-policy acceptance checks, not browser/API requests with actual signed JWTs.

- School A proprietor: own-school student query returned 2 rows; queries for School B students, members, invoices and results each returned 0 rows.
- School B proprietor: own-school student query returned 1,212 rows; queries for School A students, members, invoices and results each returned 0 rows.
- Cross-school student update attempts in both directions returned 0 updated rows; both transactions were rolled back.
- Cross-school result-template Storage object lookup as School A proprietor returned 0 visible objects for a School B template.
- Cross-school broadsheet RPC attempts in both directions were denied with `Module permission denied`.
- A cross-school `schoolpro_current_academic_period` RPC call was denied with `School access required`; `schoolpro_can_view_result_output` returned `false` for a foreign-school student.
- A broad Storage bucket inventory query hit statement timeout in a recursive report-media policy; retrying with one exact Storage object ID succeeded and returned 0 visible rows. This is a performance/policy-composition concern to review, not evidence of an access leak.

These results establish useful positive/negative database-role evidence for core school tables, one write path, one RPC and one Storage object. They do not yet cover all 293 SchoolPro policies, every exposed SECURITY DEFINER RPC, payment receipt upload/read, invitations/first-login, or real HTTP/JWT request paths.

## Migration ledger/source reconciliation detail\n\nThe production ledger contains 476 migration entries and ends at version 20261015161735. These exact source filenames are not recorded under the same version/name pairs: `20261002234500_schoolpro_operational_tenant_isolation.sql`, `20261003000500_schoolpro_guardian_tenant_hardening.sql`, and `20261003002000_schoolpro_cbt_permission_tenant_integrity.sql`. The live ledger does contain later related entries: `20261003104729_enforce_schoolpro_cross_table_tenant_integrity`, `20261003112317_enforce_schoolpro_cbt_eligibility_tenant_and_revocation_integrity`, `20261003114251_enforce_schoolpro_subject_assignment_tenant_and_teacher_integrity`, and `20261003124002_complete_schoolpro_results_assignment_cbt_integrity`. Their presence suggests overlapping hardening, but does not prove byte-for-byte or behaviorally equivalent SQL.\n\nThe ledger also contains `20260924112325_schoolpro_secure_public_result_checker`, but that migration file is absent from both `main` and this release branch. The live function definition was inspected read-only; do not recreate the missing migration from a partial function snapshot. Reconcile the full original migration or create a reviewed baseline from authoritative source before claiming source/production parity.\n\n## Anonymous SECURITY DEFINER RPC review — concrete remaining risk\n\nRead-only inspection of the live database confirms these nine public-schema SECURITY DEFINER functions are executable by anon: accept_schoolpro_admission_offer, check_schoolpro_result_pin, get_candidate_cbt, get_schoolpro_admission_offer, save_candidate_cbt_answer, schoolpro_verify_result_code, submit_candidate_cbt, submit_schoolpro_application, and verify_schoolpro_document. Public access is intentional for some guest workflows, so grants must not be revoked indiscriminately.\n\n- The live definition of check_schoolpro_result_pin validates a PIN hash and expiry and returns only a generic error for unknown admissions/invalid PINs, but the function body has no attempt counter or cooldown. Since PIN entropy may be lower than UUID tokens, add a reliable rate limit before Stage A release. Do not assume a frontend-only throttle is sufficient.\n- The live schoolpro_verify_result_code uses a 24-byte random value encoded as 48 hexadecimal characters and suppresses the snapshot when revoked; retain these properties and test revoked/unknown codes.\n- Admission-offer and candidate-CBT RPCs use UUID public tokens and expiry/state checks in their definitions, but replay, expiration, abuse/rate limiting, and data-minimization tests remain required.\n- The source file for the live public result checker could not be located at the migration path suggested by the live ledger. This is part of the migration source/ledger drift and must be reconciled before altering or applying that function.\n\n## Prepared live two-account acceptance harness\n\n`scripts/test-schoolpro-tenant-isolation-live.mjs` now runs read-only checks through two real Supabase password-authenticated sessions. It verifies positive own-school student access, zero foreign-school rows across students/members/invoices/results, denial of foreign-school academic-period and result-output RPCs, and denial of foreign-school result-template and foreign-user payment-receipt Storage listings. It does not mutate application records.\n\nRun locally from the repository after supplying the two existing test accounts through environment variables (do not commit credentials):\n\n```sh\nSUPABASE_URL=... SUPABASE_ANON_KEY=... \\n  SCHOOL_A_EMAIL=... SCHOOL_A_PASSWORD=... SCHOOL_A_ID=... \\n  SCHOOL_B_EMAIL=... SCHOOL_B_PASSWORD=... SCHOOL_B_ID=... \\n  node scripts/test-schoolpro-tenant-isolation-live.mjs\n```\n\nThe script intentionally exits before making requests when any required variable is absent. An opt-in `tenant-acceptance` CI job is wired into `.github/workflows/ci.yml`; to enable it, set repository variable `RUN_LIVE_TENANT_ACCEPTANCE=true` and configure Actions secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SCHOOL_A_EMAIL`, `SCHOOL_A_PASSWORD`, `SCHOOL_A_ID`, `SCHOOL_B_EMAIL`, `SCHOOL_B_PASSWORD`, and `SCHOOL_B_ID`. Optional secrets `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` enable receipt-download denial checks only when those real objects already exist. The live receipt bucket currently contains zero objects, so receipt Storage acceptance remains untested without existing fixtures; do not upload dummy receipts to production. Optional variables `TENANT_TEST_TERM` and `TENANT_TEST_SESSION` select the result context. These credentials must be configured by an authorized repository administrator; they are not stored in source and have not been supplied to this workflow. The earlier SQL role-claim tests remain supplementary evidence, not a replacement.\n\n
## Live authenticated two-school acceptance update (2026-10-16)

The opt-in CI job ran with two real password-authenticated Supabase test accounts on PR #106's merge commit containing branch commit `a40297c7c113bbddc432c66c75631d85d4f9021e`.

**Passed before the Storage timeout:**
- Both test accounts signed in successfully and were distinct users.
- School A could read its own student fixture; School B could read its own student fixture.
- Both directions denied foreign-school reads for `schoolpro_students`, `schoolpro_members`, `schoolpro_invoices`, and `schoolpro_results`.
- Both accounts could call `schoolpro_current_academic_period` for their own school; foreign-school calls were denied.
- Both accounts received `false` from `schoolpro_can_view_result_output` for a foreign-school student.
- General `validate` job passed on this run.

**Still failed / not verified:**
- Listing School B's existing `school-result-templates` Storage object repeatedly timed out. The updated harness retried the transient timeout three times (initial request plus two retries), but the final attempt still failed with “The connection to the database timed out.” This is a failed acceptance check, not a pass and not evidence of a tenant data leak.
- The cross-school result-template Storage denial assertion therefore did not complete.
- Payment-receipt Storage download checks remain skipped because no existing receipt paths are configured. Do not create dummy production receipts for testing.
- No production schema/data writes, migrations, merge, or Render deployment occurred.

CI evidence:
- SchoolPro CI run #998: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38888587103 — validate passed; tenant-acceptance failed at Storage listing.
- Payment page validation run #724: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38888587087

The retry did not solve the Storage timeout. Next investigation should isolate the Storage listing request/policy/database path and test an exact known object (without weakening the negative assertion). Do not add longer unbounded retries or skip the Storage check.

## Latest exact-head CI and Storage root-cause update (2026-10-16)

- Tested code commit: `379c7fcb5fbd574c4ffc200d5a610cd2652359ed`.
- SchoolPro CI run #1025: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38894225771 — **`tenant-acceptance` passed**. General `validate` was still running at the last status check; the full workflow is not yet confirmed green.
- Authenticated two-account checks passed for both schools: own-school student access; foreign-school student/member/invoice/result reads blocked; own-school academic-period RPC allowed; foreign-school period RPC denied; and foreign-student result-output RPC returned false.
- Storage positive/negative check passed: School A downloaded its existing result-template workbook; School B received HTTP 400 for that exact foreign object. The test now uses raw HTTP status for the negative assertion because the Supabase JS Storage wrapper returned `StorageUnknownError` with no exposed status for an empty/non-JSON denial body.
- Payment-page validation run #751: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38894225604 — queued at the last status check.
- Payment-receipt Storage checks remain skipped because no existing receipt paths are configured. Do not upload dummy production receipts.

### Confirmed Storage-list timeout root cause

Supabase logs for the earlier timeout show SQLSTATE `57014`, Storage API status `544`, and the policy/function chain:

`Families read their report images` → `private.schoolpro_family_report_media(name)` → `public.schoolpro_can_view_result_output` → `private.schoolpro_result_access` → `public.schoolpro_can_read_student` / `public.schoolpro_operationally_active`.

That policy is attached to the same private `school-result-templates` bucket as .xlsx workbooks. The original function joins broad student/result sets and then matches a specific photo/signature/logo path. This caused Storage's folder-list query to invoke expensive report-authorization work for workbook objects. The timeout is a policy/query-performance defect, not merely a client/network issue.

### Draft remediation — not applied to production

Migration: `supabase/migrations/20261016110500_schoolpro_optimize_family_report_media_storage_policy.sql`.

It adds partial exact-path indexes, separates media path checks, and uses `CASE` branches so non-media paths such as .xlsx workbooks do not invoke the expensive family-media function. Static regression test: `scripts/test-schoolpro-family-report-media-policy.mjs`.

The exact-object tenant acceptance now passes, but that does **not** prove the folder-listing performance defect is fixed. Review the policy's path shapes and semantics, then validate the migration in a non-production database if available. It has not been applied or performance-tested in production.

### Result-PIN attempt cooldown — draft only

Migration: `supabase/migrations/20261016122000_schoolpro_result_pin_attempt_rate_limit.sql`.

The draft adds an eight-failure / 15-minute window with a 15-minute cooldown and stores only a one-way attempt key based on normalized admission identifier plus request network context. The attempt table is private and revoked from API roles. Static regression test: `scripts/test-schoolpro-result-pin-rate-limit.mjs`.

This migration has not been applied or runtime-tested. Before any production rollout, review whether the deployed gateway reliably provides the chosen client-IP headers, confirm fallback behavior, define cleanup/retention, and test concurrent failures/cooldown reset. Do not apply based on static tests alone.

### Existing fixtures and migration-source drift

- The live bucket has eight existing IHLink Academy workbooks and one template row. No production object or application row was created by the test.
- The authenticated Storage acceptance test uses School A's existing template, confirms School A can download it, and confirms School B receives an HTTP 400 for that exact object.
- Source migration files `20261002234500_schoolpro_operational_tenant_isolation.sql`, `20261003000500_schoolpro_guardian_tenant_hardening.sql`, and `20261003002000_schoolpro_cbt_permission_tenant_integrity.sql` exist on repository branches but have no matching version/name entries in the live migration ledger. Live DB has later tenant-integrity policies/triggers with different names; this suggests related hardening exists but does not prove the source files are equivalent.
- Ledger version `20260924112325` records `schoolpro_secure_public_result_checker`, but that migration source was not recovered from current branches/history. Do not reconstruct it from a partial live function snapshot or repair migration history by guesswork.
- The payment-receipt ownership/locking migration remains staged only. Payment review/reject/cancel lifecycle and concurrent transaction behavior still require dedicated tests.

## What this audit does not yet prove

- Two authenticated school accounts cannot read or mutate each other's rows, related IDs, RPC operations, or Storage objects.
- All 293 SchoolPro policies and all security-definer RPCs have been proven safe; the live advisor output includes security-definer RPC warnings that require function-by-function authorization review.
- The production database's actual policies and triggers are identical to the current Git source tree.

## Required before Stage A can be declared complete

- [ ] Exact-head general CI validation is still running for code commit `379c7fcb5fbd574c4ffc200d5a610cd2652359ed`; [x] live authenticated two-school DB/RPC and exact-object Storage acceptance passed in run #1025; [ ] receipt Storage, payment lifecycle, migration-source/ledger reconciliation, and draft SQL runtime validation remain open.
- [ ] Review current production schema and migration history; identify unapplied, partially applied or out-of-order migrations without applying changes.
- [ ] Inventory all school-scoped tables, RLS enable/force state, and every permissive policy (policies combine permissively with OR unless restrictive policy semantics are explicitly used).
- [ ] Inspect RPCs, triggers, Edge Functions and Storage policies for school-ID trust, membership checks and cross-tenant relationships.
- [x] Authenticated two-school database reads and key RPC positive/negative checks passed on 2026-10-16; [ ] Storage listing denial remains blocked by timeout; payment receipt Storage test remains skipped.
- [ ] Verify Super Admin platform access remains intentional and does not accidentally widen school-scoped writes.
- [ ] Confirm school-owner, staff, student and parent identity/portal paths; test account switch, token refresh, logout, invitation and first-login flows.
- [ ] Review the exact release diff and merge target. Do not merge accumulated PR #105 as a substitute for this A-only release.
- [ ] Merge the complete Stage A release only after all gates pass, then verify the merged commit, Render deploy and post-merge checks.

## Mandatory sequence gate

**Do not start Stage B (sessions, student population and class rosters) until Stage A is complete, merged, and verified after merge.** Do not apply a production migration or trigger a production deployment as part of this draft. Live authenticated two-school RLS/RPC acceptance evidence was collected on 2026-10-16; the result-template Storage step timed out and payment-receipt Storage remains untested. Stage A remains NOT MERGE-READY.
