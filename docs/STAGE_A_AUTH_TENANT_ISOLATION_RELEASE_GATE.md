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

- Supabase's security advisor reports 7 RLS-enabled tables with no direct policies: schoolpro_access_invitations, schoolpro_account_challenges, schoolpro_initial_credentials, schoolpro_login_attempts, schoolpro_student_activation_challenges, schoolpro_transcript_issues, and datasub_pin_recovery_attempts. This is fail-closed for direct client queries, but each SchoolPro table must be classified as intentionally RPC/trigger-only or given an appropriately scoped policy. Do not add broad policies just to silence the advisor.
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

## What this audit does not yet prove

- Two authenticated school accounts cannot read or mutate each other's rows, related IDs, RPC operations, or Storage objects.
- All 293 SchoolPro policies and all security-definer RPCs have been proven safe; the live advisor output includes security-definer RPC warnings that require function-by-function authorization review.
- The production database's actual policies and triggers are identical to the current Git source tree.

## Required before Stage A can be declared complete

- [ ] CI passes on the exact PR head, including typecheck, build and the auth profile race regression.
- [ ] Review current production schema and migration history; identify unapplied, partially applied or out-of-order migrations without applying changes.
- [ ] Inventory all school-scoped tables, RLS enable/force state, and every permissive policy (policies combine permissively with OR unless restrictive policy semantics are explicitly used).
- [ ] Inspect RPCs, triggers, Edge Functions and Storage policies for school-ID trust, membership checks and cross-tenant relationships.
- [ ] Run authenticated positive and negative tests with two separate school identities: own-school access succeeds; other-school rows, IDs, RPC operations and Storage objects are denied.
- [ ] Verify Super Admin platform access remains intentional and does not accidentally widen school-scoped writes.
- [ ] Confirm school-owner, staff, student and parent identity/portal paths; test account switch, token refresh, logout, invitation and first-login flows.
- [ ] Review the exact release diff and merge target. Do not merge accumulated PR #105 as a substitute for this A-only release.
- [ ] Merge the complete Stage A release only after all gates pass, then verify the merged commit, Render deploy and post-merge checks.

## Mandatory sequence gate

**Do not start Stage B (sessions, student population and class rosters) until Stage A is complete, merged, and verified after merge.** Do not apply a production migration or trigger a production deployment as part of this draft. No live authenticated two-school RLS/RPC/Storage acceptance evidence has been collected by this task.
