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
