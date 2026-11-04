# SchoolPro Annual Subscription Upgrade Workflow

**Status:** Implementation specification — not yet implemented or applied  
**Scope:** Stage A–B subscription correction only  
**Payment model:** Annual bank transfer with IHLink Finance verification  
**Approved credit policy:** Proportional credit for the unused portion of the existing paid annual subscription

## 1. Existing production behaviour (verified read-only)

The current SchoolPro subscription purchase path is:

1. School billing page calls `prepare_schoolpro_bank_subscription`.
2. The RPC creates/reuses a pending full-price annual `schoolpro_subscription_intents` row.
3. School uploads a receipt through `submit_service_bank_transfer`, which creates a `direct_transfer_submissions` row with `platform_code='schoolpro_subscription'`.
4. Central Admin's `InvoiceWorkbench` lists the proof and calls `review_direct_bank_transfer`.
5. That RPC delegates SchoolPro proofs to `private.review_school_subscription_transfer`.
6. On approval, the existing private function verifies the proof and bank reference, then immediately activates the catalogue tier and records a credited `schoolpro_subscription_payments` row.

This is a working annual purchase/renewal path. It is **not** an upgrade-request workflow: it has no prior IHLink upgrade decision, no proportional unused-term credit, and no distinction between target plan price and amount due. Do not describe the existing receipt path as absent; extend it with an explicit upgrade-specific branch.

## 2. Commercial and lifecycle rules

- Annual billing only. Do not enable monthly or termly upgrade requests.
- A request must target a strictly higher tier according to an explicit server-side tier ordering. Same-tier renewals stay on the existing renewal path; downgrades are not part of this workflow.
- The credit is the unused proportional value of the existing paid annual subscription.
- Use the subscription's recorded paid amount, `starts_at`, and `renews_at`; do not derive the credit from the current catalogue price.
- Calculate elapsed/unused time using a deterministic UTC instant and the half-open interval [starts_at, renews_at). Credit = paid annual amount × unused seconds ÷ total subscription seconds. Round the credit to NGN two decimal places using PostgreSQL numeric rounding. Clamp unused seconds to [0,total seconds].
- The outstanding balance is target annual catalogue price minus the unused-term credit. Do not silently convert a negative balance into a cash refund, transferable balance, or extra subscription time. Until a separate commercial policy exists, reject upgrade requests whose credit is greater than or equal to the target price and require IHLink commercial review rather than issuing a negative/zero invoice.
- Snapshot the current subscription row, target catalogue row, calculation instant, credit and target price at request time. Revalidate the active subscription and target catalogue price before approval/invoice issuance; stale snapshots must be rejected and recalculated through a new request.
- Approval is not activation. Request, review approval, invoice creation and receipt upload must not change the active plan or entitlements.
- Only successful Finance verification of the exact outstanding balance can activate the target plan, in the same database transaction that marks the request paid and records the payment. Activation must be idempotent and reject replayed bank references.
- On successful upgrade, set the target tier and paid amount to the target annual price, start the new annual term at the verified activation instant, and set renewal to one year after that instant. Preserve the full request/payment/audit history and prior subscription snapshot.
- Existing Control Center `control_center_activate_schoolpro` remains a separate, explicit, reason-required, audited manual override. It must not be used by the normal school upgrade request flow.

## 3. Proposed persistence model (migration design; not yet created)

Add a dedicated `public.schoolpro_upgrade_requests` table rather than overloading ordinary subscription intents.

Required fields:
- Identity/scope: `id`, `school_id`, `requested_by`, `target_catalog_id`, `billing_cycle='annual'`.
- Immutable current-term snapshot: current subscription ID, current tier, paid amount, starts_at, renews_at, managed_by_ihlink, and captured_at.
- Immutable quote snapshot: target tier, target annual price, elapsed/unused seconds, total term seconds, unused-term credit, outstanding amount, currency NGN, quote timestamp and quote version/hash.
- Lifecycle: `status` constrained to `requested`, `reviewing`, `rejected`, `approved_pending_payment`, `paid`, `cancelled`, `stale`.
- Review: reviewer, reviewed_at, decision reason.
- Payment linkage: unique subscription-intent/invoice ID, linked direct-transfer submission ID, verified payment ID/reference, paid_at.
- Timestamps and immutable audit metadata.

Add a nullable unique `upgrade_request_id` reference to `schoolpro_subscription_intents` (or an equivalent one-to-one invoice link) so existing invoice/receipt UI can display the upgrade balance without confusing it with a full-price renewal. Enforce one open request and one unpaid upgrade invoice per school with partial unique indexes. Keep all references tenant-bound with composite foreign keys where the existing schema permits.

Enable RLS. School users may read their own school's request and create a request only through a narrow authenticated RPC that verifies proprietor/authorized billing-manager access. They must not directly update status, quote, reviewer, payment, or activation fields. IHLink review and payment verification must be restricted to active platform Super Admin/Finance roles using existing server-side role helpers. Revoke direct table writes and grant only required reads; all state transitions occur through narrowly scoped RPCs.

## 4. RPC boundaries

1. `request_schoolpro_upgrade(p_school, p_target_catalog)`
   - Authenticated school billing role; active school; active paid annual subscription; target is strictly higher; target has valid annual price.
   - Locks school, subscription and target catalogue rows.
   - Rejects existing open request/invoice.
   - Captures the immutable quote and returns the breakdown. No entitlement changes.

2. `review_schoolpro_upgrade(p_request, p_decision, p_reason, p_expected_version)`
   - Active IHLink Super Admin/Finance only; locks request, school, subscription and catalogue.
   - Decision is approve/reject; require reason.
   - Revalidates snapshot and price. Stale request becomes `stale` and cannot be invoiced.
   - On approval, creates exactly one pending annual subscription invoice intent for the outstanding balance and links it to the request. It does not activate the target plan.

3. Extend the existing `private.review_school_subscription_transfer` with an explicit upgrade-invoice branch.
   - Continue using the existing `submit_service_bank_transfer` and `review_direct_bank_transfer` entry points.
   - Before any activation, lock and verify the linked request, invoice, school, subscription and proof; require approved-pending-payment state, exact invoice/quote amount, matching payer/school, saved customer-owned receipt, active receiving bank account and globally unreconciled bank reference.
   - Verify current subscription and target price still match the approved snapshot.
   - In one transaction: mark proof approved, record credited payment, mark invoice paid, mark upgrade request paid, update subscription and school plan, and write audit events.
   - Repeated identical successful verification returns an already-settled result without duplicate payment or activation; a different/replayed bank reference is rejected.
   - The ordinary renewal branch remains unchanged.

4. `cancel_schoolpro_upgrade_request`
   - School billing manager may cancel only a requested/reviewing request; IHLink may cancel an approved unpaid request with reason. Never cancel a paid request.

## 5. UI work

### SchoolPro
- Add an Upgrade action only when a paid annual subscription is active and a higher annual tier is available.
- Show a quote breakdown: current tier/paid amount, current term dates, elapsed/unused period, proportional credit, target annual price, and outstanding balance.
- Show request state, IHLink decision/reason, invoice reference, receipt status and verification result.
- Use the existing receipt upload component for the upgrade invoice; do not expose an activation button to the school.
- Keep renewal/first-purchase actions separate from upgrade requests.

### Central Admin
- Add a dedicated SchoolPro Upgrade Requests queue; do not repurpose the onboarding queue or manual activation table.
- Show the immutable quote snapshot and current live values side-by-side.
- Allow review/approve/reject with mandatory reason; stale quotes must be refreshed through a new request, not edited.
- Approved requests appear with their linked invoice and receipt status. Finance verifies bank statement through the existing proof workbench; the upgrade branch performs atomic activation only after verification.
- Keep the existing manual activation control visibly labelled as a privileged override with a mandatory reason.

## 6. Required disposable tests

- Correct unused-value credit at start, midpoint, just before expiry and at expiry.
- Leap-year and different term lengths; exact UTC boundaries; NGN two-decimal rounding.
- Invalid/missing/zero/negative/non-finite prices and malformed term dates.
- Same-tier/downgrade requests rejected; inactive/demo/expired/unpaid subscription rejected.
- Target catalogue price change after request makes quote stale.
- Subscription renewal or manual override after request makes quote stale.
- Duplicate open requests and duplicate invoices prevented under concurrent transactions.
- School A cannot read/create/modify School B requests.
- Ordinary staff/teachers cannot request upgrades unless explicitly authorized billing roles.
- Request, approval, invoice creation and receipt upload never activate entitlements.
- Wrong amount, wrong school/payer, missing receipt, inactive bank account, duplicate bank reference and rejected proof cannot activate.
- Successful verification atomically updates request, intent, payment, subscription and school plan.
- Repeated identical verification is idempotent; different replay is rejected.
- Manual override remains separately audited and cannot be mistaken for paid upgrade.

## 7. Release gates

- Migration and RPCs reviewed; RLS and function grants checked; Supabase advisors clean.
- Disposable PostgreSQL tests pass without creating production schools or operational records.
- SchoolPro and Central Admin UI tests/builds pass on exact PR heads.
- Existing annual purchase/renewal proof path regression passes.
- No production migration is applied until explicit approval. No merge or Render deployment without explicit approval.
- Stage C result entry/review/publication is outside this specification and remains deferred.


## 8. Exact live-schema mapping (read-only recheck, 2026-11-04)

The implementation was cross-checked against live `information_schema.columns`, constraints, and function definitions. These are the confirmed integration points:

- `schoolpro_subscriptions`: `id, school_id, tier, billing_cycle, amount, status, starts_at, renews_at, managed_by_ihlink, customization_level, updated_at`. The existing row has one current subscription per school and is the authoritative proration snapshot.
- `schoolpro_subscription_catalog`: `id, code, name, monthly_price, termly_price, annual_price, active, features, updated_at`. Active annual catalogue rows currently resolve to Starter ₦50,000, Professional ₦100,000, Enterprise ₦150,000.
- `schoolpro_subscription_intents`: `id, school_id, payer_user_id, catalog_id, billing_cycle, amount, virtual_account_id, reference, status, transaction_ref, paid_at, created_at, updated_at, payment_method, replaces_invoice_id, invoice_kind, demo_request_id`. Existing constraints allow only invoice kinds `subscription` and `demo`; subscription invoice amount must be positive. Add a nullable unique `upgrade_request_id` FK and preserve all existing constraints and the ordinary purchase RPC.
- `direct_transfer_submissions`: `id, user_id, platform_code, invoice_id, source_reference, bank_account_id, amount, sender_name, sender_bank, customer_reference, transferred_at, proof_storage_path, status, admin_note, verified_by, verified_at, created_at, updated_at`. The upgrade path must match invoice ID, payer user ID and exact amount against this row before settlement.
- `ihlink_bank_accounts`: `id, label, bank_name, account_name, account_number, is_active, is_default, created_by, created_at, updated_at`. The payment finalizer must lock this row and require `is_active=true`; existence alone is insufficient.
- `schoolpro_subscription_payments`: `id, school_id, subscription_id, payer_user_id, provider, reference, amount, status, virtual_account_id, transaction_ref, provider_payload, verified_at, credited_at, created_at, updated_at`. Record upgrade request and invoice identifiers in provider_payload and enforce unique payment identity/reference as supported by existing constraints.
- `schoolpro_schools` contains `id, owner_id, name, code, address, plan, status, created_at, updated_at`; upgrade settlement must update `plan` only in the same transaction as the subscription and payment records.

Security and concurrency requirements:
- Existing school billing helper is `private.has_school_access(uuid, school_member_role[])`; invoke with only proprietor, administrator and bursar roles. This helper checks active profile and school ownership/member role.
- Existing IHLink reviewer gate in the payment finalizer is active account plus `private.is_admin(ARRAY['super_admin','finance']::public.user_role[])`.
- The transfer verifier currently returns early when a submission is already in the requested decision state. Upgrade settlement must not use that early return as proof of a paid upgrade: it must verify the linked upgrade request, paid invoice and unique credited payment are all already settled, otherwise raise an integrity exception.
- The existing bank-reference collision check is scoped to same bank account and approved/verified submissions. The upgrade branch must use the agreed global reconciliation scope (normalized reference across active/reconciled transfer records, with bank account context retained), and must remain compatible with the ordinary branch's established behavior.
- Lock ordering should be consistent across request, review and settlement RPCs (school → subscription → catalogue → upgrade request → invoice → transfer proof → bank account) to reduce deadlocks. Recheck the quote snapshot after locks are acquired.
- Do not rely on client-supplied quote amounts, tier order, term seconds, or reviewer identity. All are server-derived.

No production rows were written by this inspection. This section is an implementation contract, not a migration or deployment.


## 9. Application integration points (read-only source inspection, 2026-11-04)

### SchoolPro subscription page
- Current page: `src/pages/schoolpro/SchoolProSubscription.tsx`.
- It loads active `schoolpro_subscription_catalog` rows, plan entitlements, the current `schoolpro_subscriptions` row, and the signed-in payer's bank-transfer intents.
- The only purchase action currently calls `prepare_schoolpro_bank_subscription(p_school,p_catalog)`; every plan card exposes the same Subscribe / Renew action.
- The page then passes the intents to the shared `BankTransferPayments` component for receipt upload. It has no upgrade-request list, quote breakdown, IHLink decision state, upgrade invoice distinction, or request cancellation control.
- The upgrade UI must be a separate panel/action shown only when a paid annual subscription is active and a higher tier exists. It must call the dedicated upgrade RPC and must not call the ordinary prepare RPC for an upgrade.
- Do not display the target plan as active until the request is settled by Finance. Keep the existing purchase/renewal cards and receipt upload flow unchanged for ordinary intents.

### Public pricing page
- `src/pages/schoolpro/SchoolProPricing.tsx` reads the live annual catalogue and feature flags and is informational. It should not be used to calculate or submit upgrade quotes.

### Test harness
- The repository already uses Node assertion scripts under `scripts/test-*.mjs` and npm scripts in `package.json`.
- The current scripts include disposable-PostgreSQL checks for progression/section leadership and source-contract checks for Stage A–B corrections. Add upgrade quote/settlement regression coverage to the same established test conventions, and include an existing ordinary annual-purchase regression so the legacy path remains protected.

## 10. Migration sequencing and current deployment boundary

- The read-only Supabase migration ledger currently ends at `20261104113534 schoolpro_split_onboarding_insert_policies`. This is a ledger observation only; it does not authorize applying a new migration.
- The Stage A–B dashboard/report entitlement correction is committed on the feature branch as part of PR #116, but no annual-upgrade migration has been created or applied.
- Supabase CLI v3.0.0 was released on 2026-11-02. Before any local migration workflow, confirm the installed CLI version and use the v3 local-by-default command semantics. Do not use a hosted database command implicitly; hosted changes require a separately approved operation.
- This environment exposes GitHub and Supabase MCP actions but not a checked-out repository shell in which to run `supabase migration new`, disposable PostgreSQL, or the app's npm scripts. Therefore the next code step must be performed in the repository's supported CLI/test environment; creating a migration blob directly through GitHub would bypass the required migration-generation and local verification workflow. No migration file has been fabricated as a substitute.


## 11. Live schema/RLS verification — read-only, 2026-11-04

The following was confirmed through catalog-only SELECT queries against the configured Supabase project. No rows were inserted, updated, or deleted.

### Existing payment ledger and indexes
- `schoolpro_subscription_payments` has unique indexes on `reference` and `transaction_ref`, but no request/invoice foreign key today. The upgrade migration must add a nullable typed `upgrade_request_id` FK to `schoolpro_upgrade_requests` and a partial unique index for one credited payment per upgrade request. `provider_payload` may retain reconciliation metadata, but it is not the authoritative relationship and must not replace the typed FK.
- `schoolpro_subscription_intents` has a unique `reference`, unique nullable `transaction_ref`, unique `replaces_invoice_id`, and unique `demo_request_id`. There are two partial unique indexes enforcing one pending invoice per school: `schoolpro_one_pending_ihlink_subscription` and `schoolpro_subscription_pending_school_unique`. Do not create the upgrade invoice while an unrelated pending purchase invoice exists; the approved-upgrade invoice should use the existing one-pending-per-school invariant and must not weaken it.
- `direct_transfer_submissions` currently has a unique key on `(user_id, platform_code, source_reference, customer_reference)`; it does not have a unique index for normalized customer bank references across receiving accounts. Upgrade verification needs a concurrency-safe duplicate-reference control scoped to the intended platform reconciliation policy.

### Current RLS observations
- `schoolpro_subscription_intents` currently exposes SELECT only to the payer, school proprietor/administrator/bursar, or IHLink super_admin/finance. No direct client INSERT/UPDATE/DELETE policy was returned. Preserve RPC-only writes for the new workflow.
- `schoolpro_subscription_payments` exposes SELECT to payer, proprietor/administrator/accountant/bursar, or IHLink super_admin/finance; no direct client write policy was returned. Preserve server-only settlement writes.
- `schoolpro_subscriptions` has member-read policies and a super_admin-only write policy; do not widen client writes for upgrades. The authoritative settlement RPC must update the subscription and school plan atomically.
- `schoolpro_subscription_catalog` has overlapping authenticated SELECT policies (active-only and unrestricted `true`) plus an anon active-only policy. This is existing catalogue policy drift; it is not required to implement upgrades and should not be silently changed in this migration.
- `schoolpro_audit_logs` is readable by IHLink super_admin or school proprietor/administrator/IT admin scope. Record the request/approval/rejection/settlement events through the existing audit table without granting client writes.

### Design consequences
1. Model the upgrade request separately from `schoolpro_subscription_intents`; do not broaden `invoice_kind` or relax its existing positive-amount subscription constraint.
2. Only after IHLink approves a request should the system create a positive difference-only annual subscription invoice linked by a typed `upgrade_request_id`. If the computed balance is zero/negative, reject the request into commercial review and do not create an invoice.
3. Keep existing one-pending-invoice-per-school constraints intact. A pending ordinary renewal/purchase must be resolved before issuing an upgrade invoice; the quote should be refreshed at approval because subscription dates/prices may have changed.
4. Add typed linkage and uniqueness to the payment ledger so replay/idempotency can be proven by database constraints, not JSON-only metadata.
5. Keep client access read-only; expose narrowly scoped security-definer RPCs for quote/request, IHLink decision, and Finance settlement, with explicit EXECUTE grants and audit metadata.
6. Avoid unrelated catalogue RLS cleanup in the upgrade migration; track that separately.

## 12. Typed payment linkage clarification (2026-11-04)

This section resolves an inconsistency between the earlier schema-mapping bullet and the later design consequences. The implementation contract is:

- Add nullable `upgrade_request_id uuid REFERENCES public.schoolpro_upgrade_requests(id)` to `schoolpro_subscription_payments`.
- Add a partial unique index on `upgrade_request_id` for rows representing a credited/verified payment (use the exact existing ledger status values confirmed in the migration's preflight assertions).
- Keep the nullable unique `upgrade_request_id` FK on `schoolpro_subscription_intents` as the one-to-one approved-upgrade invoice link.
- `provider_payload` may carry a diagnostic snapshot of invoice/reference/receipt reconciliation details, but cannot be the sole relationship or idempotency mechanism.
- The settlement RPC must prove the same request, invoice, direct-transfer submission and credited payment are linked before treating a repeated verification as successful. A request with a paid invoice but no corresponding unique credited ledger row is an integrity failure, not a successful idempotent replay.
- Preserve the ordinary annual purchase/renewal rows with `upgrade_request_id IS NULL`; do not alter their existing unique reference/transaction constraints or their activation behaviour.

This clarification is authoritative over the permissive parenthetical alternative in the earlier version of section 11. No schema change has been made.

## 13. Central Admin source integration map (read-only inspection, 2026-11-04)

The connected Central Admin repository is `Hassan-625/IHLink-Admin` (default branch `main`). The relevant source files were fetched directly and inspected; no Central Admin files were changed.

- `src/pages/admin/AdminSchoolProSubscriptions.tsx` is the existing commercial-control page. It loads the catalogue, schools and subscriptions and exposes `control_center_activate_schoolpro` through a reason-required privileged manual activation action. Keep this page and its manual override semantics separate from customer-requested upgrades.
- `src/components/InvoiceWorkbench.tsx` is the existing payment-proof workbench. For `schoolpro_subscription`, it reads `schoolpro_subscription_intents` and pending `direct_transfer_submissions`, and calls `review_direct_bank_transfer` for Finance approval. Reuse the existing workbench for approved upgrade invoices; the SchoolPro-specific finalizer branch must perform the linked request/invoice/proof/payment integrity checks and atomic activation. Do not add a second independent proof-verification path.
- `src/pages/admin/DirectTransferReview.tsx` is the general transfer review list and calls the same `review_direct_bank_transfer` RPC. It is not the upgrade decision queue; keep the existing Finance proof-verification route and make the database finalizer recognize the typed upgrade invoice linkage regardless of which existing supported proof workbench initiates verification.
- `src/App.tsx` currently routes `/admin/subscriptions` to `AdminSchoolProSubscriptions` behind `<Guard superOnly>`. Preserve this route as the privileged manual-override page. A dedicated upgrade-review route can be `/admin/subscriptions/upgrades`, with a new page component and the normal `<Guard>` role set (super_admin, platform_admin, support, finance); the existing `canOpenAdminPath` maps the `subscriptions` path segment to Finance-only for non-super-admin roles, while super_admin is allowed. Confirm backend RPC authorization independently; only active super_admin/finance may approve/reject requests.
- `src/pages/admin/adminShared.tsx` defines the central navigation. Add the dedicated upgrade queue beside Finance/Subscriptions, not inside the onboarding queue. Ensure `canOpenAdminPath` filters the link consistently.
- `src/lib/adminNavigationPermissions.ts` and `src/components/ProtectedRoute.tsx` are the client route gates. The new route should use the `subscriptions` path segment so Finance can access it without requiring a SchoolPro product grant; server-side reviewer authorization remains authoritative. Do not weaken the existing `/admin/subscriptions` super-admin-only override route.

### Central Admin delivery requirements

1. New `AdminSchoolProUpgradeRequests` page: list requests by status, school, requested target tier and request date; open a request detail panel showing immutable quote snapshot beside current live subscription/catalogue values.
2. Decision controls: approve/reject only, mandatory reason, optimistic version check; stale quote must transition to stale and require a fresh school request. No editing quote amounts or manually activating tiers.
3. After approval, display the linked difference-only invoice and payment status. Do not treat approval or receipt upload as activation.
4. Reuse `InvoiceWorkbench` / existing `review_direct_bank_transfer` flow for Finance bank-statement reconciliation. The finalizer's upgrade branch is the only normal activation mechanism.
5. Preserve `AdminSchoolProSubscriptions` and `control_center_activate_schoolpro` as an explicitly labelled, reason-required, separately audited emergency/manual override.
6. Add navigation and route tests proving Finance and Super Admin access the review queue, while support/platform_admin and school users cannot approve/reject; only Super Admin retains the manual override route.

No Central Admin application code or route was changed during this inspection.