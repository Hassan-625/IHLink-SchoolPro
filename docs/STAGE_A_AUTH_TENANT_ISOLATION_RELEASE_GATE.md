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
