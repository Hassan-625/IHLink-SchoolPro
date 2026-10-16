# Stage A payment RLS review — 2026-10-16

**Status: BLOCKED pending real-role disposable PostgreSQL tests. Static review only; no database was modified.**

## Evidence inspected

- Branch: `release/stage-a-auth-tenant-isolation`
- PR: [#106 — Stage A security hardening](https://github.com/Hassan-625/IHLink-SchoolPro/pull/106), open, draft, unmerged.
- Inspected head: `ed7ff4d901bea0606fa778b2e1416b6ee940ea7d`.
- Payment validation: [run #878](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925886013), passed.
- SchoolPro CI: [run #1151](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925885963), passed. Passing CI does not close the real-role RLS gap.
- Migration under review: `supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql`.
- Existing regression: `scripts/test-schoolpro-payment-review-write-controls.mjs`; it asserts SQL source text, not effective PostgreSQL grants/policies.

## Findings

### 1. Payment submissions and proofs: mutable-column boundary not proven

The migration recreates a **restrictive FOR ALL** policy. Restrictive policies only narrow access already granted by applicable permissive policies; they do not independently grant or deny a command. The submission/proof `WITH CHECK` clauses allow a guardian-linked user to satisfy the row predicate when `submitted_by` remains that user. That predicate alone does not distinguish INSERT from UPDATE and does not make review-controlled columns immutable.

This is a concrete test gap and a potentially incomplete boundary, not a confirmed production exploit. The effective result depends on the complete policy set, grants, table ownership/bypass roles and RPC behavior, none of which the static test executes.

**Required disposable-role tests:**
- guardian can perform only the intended submission/proof actions;
- guardian direct UPDATE cannot change review status, approved amount, invoice/allocation linkage, school/student ownership, or receipt object path;
- guardian cannot directly INSERT/UPDATE/DELETE allocation rows except through the intended authorized flow;
- school finance can record school-side fee payments as intended but cannot bypass subscription receipt review or mutate protected review fields;
- platform Super Admin can inspect but cannot directly write fee-ledger rows;
- intended locked RPC succeeds for authorized transitions and rejects invalid state changes;
- unauthorized roles and cross-school IDs are denied.

### 2. Grants and policy inventory must be captured

Before changing policy SQL, inventory effective table privileges and every permissive/restrictive policy on all four tables:
- `schoolpro_payment_submissions`
- `schoolpro_payment_allocations`
- `schoolpro_payment_proofs`
- `schoolpro_fee_payments`

Also inspect the SECURITY DEFINER RPC owner, search path, grants, locking behavior, and every function caller. Do not assume the new restrictive policy alone proves command-level denial.

### 3. Fee payment ledger boundary

The draft intends Super Admin SELECT-only and school finance INSERT, with direct edits/deletes blocked. Verify this using actual authenticated database roles and the full existing policy set, including legitimate school-fee workflows and guardian reads.

## Next action

Add a disposable PostgreSQL integration fixture/workflow that loads the relevant schema/policies and runs assertions as distinct roles (guardian, school finance, Super Admin, and service/RPC context). Correct policies/grants only after the fixture exposes the exact failing command, then rerun the full Stage A suite against the resulting commit.

## Safety

No production SQL was run, no production records were changed, no PR was merged, and no Render deployment was triggered. Stage A remains not merge-ready.


## Product-scope correction — no SchoolPro online gateway
The product owner clarified on 2026-10-16 that SchoolPro has **no online/card payment gateway**. The earlier references in this audit to the Flutterwave finalizer as a required SchoolPro payment path were incorrect. The existing `supabase/migrations/20260920212500_schoolpro_online_fee_payments.sql` and `supabase/functions/schoolpro-payment/index.ts` are legacy/unintended scope and must not be treated as a feature acceptance requirement.

Keep the workflows distinct:
- SchoolPro subscription payment: receipt uploaded by the school; IHLink Super Admin verifies and marks paid.
- School fee payment: school-managed finance recording and receipt-based payment confirmation.
- BillStack: DataSub only.
- Guardian-to-school bank transfer receipt submission remains a valid receipt-based workflow; it is not online card checkout.

The gateway code must be traced through all UI/function/config references before a forward disable/removal change. Do not rewrite historical migrations or drop intent records blindly. Verify production deployment/reachability and preserve existing records; no gateway removal is claimed yet.

**Corrected test scope:** prioritize receipt submission/review, protected review fields, tenant isolation, school-finance recording, invoice/student/school cross-link integrity, RPC authorization and concurrency for legitimate receipt-based workflows. Do not make Flutterwave/card finalization an acceptance gate. Any retained legacy gateway objects must be unreachable from SchoolPro user flows and explicitly documented until safely retired.

This correction changes product scope only; the Stage A payment RLS/runtime test gap remains open. No production database was modified and no deployment was performed by this documentation update.
