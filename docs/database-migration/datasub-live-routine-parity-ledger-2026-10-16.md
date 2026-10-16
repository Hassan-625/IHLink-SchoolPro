# DataSub live routine parity ledger — 2026-10-16

Status: **working audit artifact; not a migration or deployment instruction**.

Scope: compare deployed Supabase/PostgreSQL behavior to checked-in source before designing the MySQL/API equivalent. The live definition observations below came from the read-only catalog inspection recorded in MASTER-MIGRATION-HANDOVER.md and recovered-live-datasub-wallet-routines-2026-10-16.md. Exact source commit for the later wallet hardening remains unresolved.

## Evidence rules

- “Observed live” means the deployed routine definition/ACL was inspected; it does not mean concurrency tests have passed.
- “Candidate source” means a checked-in file was found, not that it is authoritative for current production.
- Do not port a weaker candidate migration as deployed truth.
- Do not infer authorization safety from ACLs alone; verify routine identity/permission checks and negative cases.
- Do not use production to run destructive or concurrency tests. Use a disposable isolated PostgreSQL environment first, then a disposable MySQL/API implementation test environment.

## Routine matrix

| Routine / surface | Live evidence observed | Source/provenance | Key invariants to preserve | Tests still required | Status |
|---|---|---|---|---|---|
| reserve_datasub_wallet | SECURITY DEFINER; empty search_path; validates user/transaction/amount/2dp; locks transaction and wallet; verifies owner, amount, exact RESERVE: reference and pending state; matching existing ledger is idempotent; mismatch rejected; inserts ledger before debit | Candidate: 20260924210000_datasub_transaction_safety.sql is materially weaker. Later hardening migration 20260925191607_harden_datasub_refund_idempotency exists in live ledger but original SQL not found on inspected refs | Single debit per transaction/reference; atomic ledger and balance; exact owner/amount/reference binding; row locks; safe replay | concurrent duplicate reservation; same ref/different amount; wrong owner; wrong status; missing wallet; rollback after ledger/debit failure | Partial: live behavior observed, source unresolved, tests pending |
| refund_datasub_wallet | SECURITY DEFINER; empty search_path; validates identity/amount/reference; locks transaction; requires non-success transaction and matching prior reserve ledger; locks wallet; matching refund ledger is idempotent; mismatch rejected; records refund ledger before credit | Same unresolved live-only hardening migration; initial checked-in transaction-safety file is not authoritative for deployed behavior | At-most-once credit; only matching reserved transaction can be refunded; no refund of success; amount/owner/reference equality; atomic refund ledger + wallet credit | concurrent duplicate refunds; refund racing callback success; refund without reserve; wrong amount/owner; duplicate reference mismatch; rollback/failure injection | Partial: live behavior observed, source unresolved, tests pending |
| datasub_transfer_wallet | Caller bound to auth.uid(); active profile; request ID/amount validation; advisory lock sender/request; duplicate consistency; PIN check; recipient restricted to active customer-visible DataSub BillStack virtual account; wallet rows locked in sorted user order | Exact authoritative source not yet mapped in this pass | One transfer per request key; atomic sender debit/recipient credit/ledger/audit; stable lock order; caller identity and recipient eligibility | full routine tail review; concurrent duplicate transfer; reverse sender/recipient lock order; invalid PIN/locked account; self-transfer; failure between debit and credit | Partial: live checks observed; tail and source parity pending |
| create_datasub_api_credential | Active account; active reseller with explicit API approval; active DataSub access; profile row lock before five-key cap; 32-byte random secret | Current-looking candidate: 20261010160508_datasub_api_access_callbacks.sql; initial 20260917210000_datasub_api_credentials_usage.sql is weaker | Only eligible reseller; atomic key cap; one-time secret disclosure; hashed/secure storage; revoke/expiry enforcement | unapproved reseller; concurrent sixth-key creation; inactive access; revoked key; secret not returned again | Partial: live behavior observed; exact source diff and tests pending |
| create_datasub_api_purchase | SECURITY DEFINER; observed EXECUTE ACL service_role + owner; checks live credential/user binding, approved API reseller, active DataSub access, recipient/reference, active product/server-owned API price; locks wallet and checks balance before pending transaction | Exact source mapping pending; search_path=pg_catalog, public flagged for object qualification/privilege review, not a confirmed exploit | Client cannot choose price; credential is bound to caller; sufficient balance; no duplicate reference purchase; safe object resolution; no direct client privilege | unauthorized credential/user; caller-chosen price; duplicate ref; low balance; concurrent spend; schema shadowing feasibility review | Partial: visible body/ACL observed; source and adversarial tests pending |
| process_datasub_provider_callback | Unique provider/event pair; duplicate event detection; locks transaction; only finalizes pending transactions; updates provider status/health; service_role-only EXECUTE | Exact authoritative source mapping pending | Authenticated worker; unique event idempotency; canonical transaction reference; monotonic terminal state; safe replay/out-of-order behavior; audit trail | duplicate same event; same transaction conflicting event IDs; success then failure; failure then success; reversal; refund/callback race; invalid worker | Partial: live behavior observed; tests pending |
| review_finance_refund | Corporate approval checks; locks refund request and canonical payment transaction; validates customer/platform/source ref/settlement/status/amount/currency; audits decision | Exact source mapping pending | Corporate authorization; immutable canonical payment match; one decision; auditability; separation from DataSub wallet refund | unauthorized role; stale request; amount/currency mismatch; duplicate decision; concurrent approval; platform/source mismatch | Partial: live behavior observed; tests pending |
| set_datasub_transaction_pin | Caller bound to auth.uid(); requires old PIN when replacing existing PIN; hashes via crypt; resets lockout counters | Exact source mapping pending | Never expose/store plaintext PIN; require old PIN for change; brute-force lockout; secure hashing and recovery boundary | wrong old PIN; locked account; concurrent change; lockout reset; PIN not logged/returned | Partial: live behavior observed; tests pending |
| claim_datasub_pin_recovery and datasub_pin_recovery_attempts | SECURITY INVOKER, empty search_path, service_role-only execute; table RLS enabled with no direct table policy | Recovery migration candidate: 20261009153414_datasub_pin_recovery.sql in DataSub main | Service-mediated access only; single-use, expiring claim; throttling; no direct client table reads/writes | identify Edge Function caller; invalid/expired/reused claim; rate limit; anon/authenticated direct table access denied | Partial: function/ACL observed; caller verification pending |

## Cross-cutting caller and runtime checks

1. Map each routine to every caller: frontend RPC, Edge Function, cron/job, server route and service-role worker. Record which identity context reaches the routine.
2. Capture exact live signature, pg_get_functiondef hash, owner, prosecdef, proconfig, ACL, return contract and relevant triggers for each routine.
3. For each candidate source migration, record repo, branch, commit SHA, file path, and whether the live definition is byte-equivalent, semantically equivalent, weaker, or unknown.
4. Build disposable PostgreSQL tests that exercise positive, negative, duplicate, concurrency and rollback cases. Never use the production database for adversarial/concurrency tests.
5. Only after the PostgreSQL behavior contract is verified, implement the MySQL-side server API and tests. Do not expose MySQL credentials or connect browser/mobile clients directly to MySQL.

## Known source-provenance gap

The live migration ledger records 20260925191607 harden_datasub_refund_idempotency. The exact file was not found in the inspected exact paths/trees for IHLink-DataSub main/local-migration or IHLink_Design_System_1 datasub-final-production-audit/complete-datasub-api-handoff/feat-datasub-production-phase4. This does not prove the file never existed. Continue with approved deployment/audit records and additional commit history. If the original cannot be recovered, retain this as an explicit unresolved provenance gap; do not reconstruct the original migration under its old timestamp/name.

## Change-control boundary

Read-only audit and documentation only. No production DDL/DML, environment changes, deployment, migration execution, PR merge or cutover was performed or authorized by this artifact.

## Supplemental live evidence — wallet transfer routine (read-only, 2026-10-16)

Exact catalog signature: `public.datasub_transfer_wallet(uuid,numeric,text,uuid)`.

- Definition MD5 observed: `ecfc51ef872d2c4816d13b4e52fe18d6`. Owner: `postgres`. `SECURITY DEFINER`: true. Function config: empty `search_path`. Observed EXECUTE ACL: `postgres`, `authenticated`, and `service_role`. These are audit facts, not by themselves a vulnerability.
- The full body confirms that it checks `auth.uid()` against an active profile; validates request ID, positive amount, two-decimal precision and numeric upper bound; takes an advisory transaction lock keyed by sender + request ID; and returns the previous transfer only when the request's recipient account and amount match. Reusing the same request ID with a different recipient or amount raises an exception.
- It verifies the transaction PIN, requires an active/customer-visible DataSub BillStack virtual account for another active user, and requires the sender to have an active customer-visible DataSub BillStack account. It creates the recipient wallet if absent, then locks sender and recipient wallet rows in sorted user-ID order before reading balances.
- It checks sufficient funds, inserts the transfer record, debits the sender, credits the recipient, writes paired debit/credit wallet-ledger rows with before/after balances and transfer metadata, then returns success. PostgreSQL function execution provides transaction atomicity unless the function or caller explicitly changes transaction behavior; the full body showed no such exception-handling block that would swallow a partial-write failure.
- Remaining test cases: concurrent same-request duplicate; same request ID with changed amount/recipient; two opposing A→B and B→A transfers to exercise lock order; insufficient funds; invalid/locked PIN; inactive or non-customer-visible account; injected error after transfer row / balance update / ledger insert in a disposable database to prove rollback; verify no direct client can mutate transfer/wallet/ledger tables to bypass the routine.
- This is a definition-level review only. No transfer was initiated, no wallet/balance/ledger rows were read, and no production write occurred.

## Supplemental caller, idempotency-index and RLS evidence — 2026-10-16

### Purchase and reconciliation callers

- Live Edge Function 'datasub-purchase' is ACTIVE, version 38, with verify_jwt=true. It separately requires an Authorization header and validates the user with auth.getUser(), checks active DataSub access, verifies the 4-digit PIN through the database RPC, and uses the service role for server-side data access.
- The purchase path reads existing transactions by (user_id, metadata.client_idempotency_key) before creating a transaction, then reserves funds through reserve_datasub_wallet. The database has a unique partial index idx_datasub_tx_user_client_key on (user_id, (metadata ->> 'client_idempotency_key')) when that metadata key exists. This database constraint protects against concurrent duplicate transaction creation even if two requests pass the initial lookup. A racing duplicate may receive a generic transaction-creation error rather than the original transaction response; verify retry UX in a disposable test. No duplicate purchase was attempted.
- Live datasub-reconcile is ACTIVE, version 23, verify_jwt=true. Its code processes pending RECONCILING and REFUND_PENDING transactions, queries provider status, and calls finalizeRefund for failed outcomes. _shared/refunds.ts claims the refund by conditionally updating a still-pending transaction to REFUND_PENDING, calls the idempotent refund_datasub_wallet, and only then marks the transaction failed/refunded. This is useful application-level race protection, but the two-worker and provider-result race cases still need isolated concurrency tests.
- Live datasub-provider-webhook is ACTIVE, version 12, verify_jwt=false. Its current handler accepts POST without validating a provider signature or shared secret, looks up a matching transaction by provider/reference, and inserts a PROVIDER_WEBHOOK_RECEIVED routing event. The code explicitly says the callback requires authenticated provider lookup and does not directly change purchase/refund state. **Review finding: an unauthenticated caller can potentially create arbitrary routing-event noise for known references (and repeatedly generate event rows); this is not evidence of a wallet debit/refund bypass.** Treat as a log-integrity/availability hardening issue. Before changing production, decide whether the endpoint should be disabled, require provider signature/authentication, or simply accept and discard untrusted events while the authenticated reconciliation worker remains authoritative. Add rate limiting and idempotency if this endpoint must remain public.
- datasub-api-callbacks is also verify_jwt=false, but its handler validates a worker bearer token obtained through ihlink_worker_token before claiming/delivering queued callbacks. Do not conflate this with the provider webhook; the observed worker-token check is a separate control.

### Direct table privileges versus RLS policies

- Catalog checks show RLS enabled on datasub_transactions, datasub_wallets, datasub_wallet_transfers, wallet_ledger, datasub_provider_attempts and datasub_routing_events.
- has_table_privilege reported broad underlying table privileges for anon/authenticated on several of these tables. The current pg_policies listing showed read policies only for ordinary authenticated access on the wallet/ledger/transaction/attempt/event surfaces, and no direct insert/update/delete policy for customer writes on wallet_ledger, datasub_provider_attempts or datasub_routing_events; datasub_wallet_transfers had a participant/admin SELECT policy and no customer write policy. datasub_transactions and datasub_wallets had owner/admin SELECT policies and super-admin ALL policies. This pattern means grants alone are not proof of a bypass because RLS is also applied, but it warrants an explicit negative authorization test using anon/authenticated JWTs against each table. Service-role access is expected for the server-side Edge Functions.
- No live rows were queried, no test transaction was created, and no production data was changed.

### Updated priority

1. P1 audit/test: verify the unique client idempotency index and purchase/reconciliation race behavior in disposable tests, including rollback of reserve/refund paths.
2. P1 hardening review: address unauthenticated datasub-provider-webhook event injection/noise without making this endpoint authoritative for financial state.
3. P1 authorization tests: prove direct customer writes to wallet, ledger, transaction, routing-event and provider-attempt tables are denied under real anon/authenticated JWT roles despite table grants.
4. Continue source provenance recovery for the missing wallet refund hardening migration. Do not apply speculative production changes.

## Follow-up tracking — 2026-10-16

Created DataSub issue [#47 — Security review: harden public provider webhook event ingestion](https://github.com/Hassan-625/IHLink-DataSub/issues/47). It records the observed behavior, acceptance criteria, and the requirement to confirm the actual provider authentication contract before choosing a signature or secret scheme. This issue is a tracking artifact only; no code or deployed configuration was changed.

## Isolated verification plan

The test matrix is now documented in [DataSub isolated financial-path security test plan](datasub-isolated-security-test-plan-2026-10-16.md). It is a specification only: direct writes, duplicate purchase retries, wallet-transfer concurrency, refund/reconciliation races, and webhook abuse have **not** been executed against a disposable database yet. Production is explicitly excluded as a test target.


## Supplemental live ACL, routine-hash and trigger inventory — 2026-10-16

Read-only catalog snapshot. Definition hashes identify the live routine version observed during this audit; they do not prove source parity or correctness.

| Routine | Live identity signature | MD5 of `pg_get_functiondef` | Owner / security / search_path | Observed EXECUTE ACL |
|---|---|---|---|---|
| `reserve_datasub_wallet` | `(p_user uuid, p_transaction uuid, p_amount numeric, p_reference text)` | `2c4137bc9bffeea279f16e28599e9ebe` | postgres / DEFINER / empty | postgres, service_role |
| `refund_datasub_wallet` | `(p_user uuid, p_transaction uuid, p_amount numeric, p_reference text)` | `05665ee774b88b9ada5469d4371dd54f` | postgres / DEFINER / empty | postgres, service_role |
| `datasub_transfer_wallet` | `(p_account_id uuid, p_amount numeric, p_pin text, p_request_id uuid)` | `ecfc51ef872d2c4816d13b4e52fe18d6` | postgres / DEFINER / empty | postgres, authenticated, service_role |
| `create_datasub_api_credential` | `(p_label text, p_mode text)` | `4e02d1e66e7659aa1e3a5600cde88654` | postgres / DEFINER / empty | postgres, authenticated, service_role |
| `create_datasub_api_purchase` | `(p_user_id uuid, p_credential_id uuid, p_product_code text, p_recipient text, p_reference text)` | `fd8d12b78c2237a1684806281c3bef34` | postgres / DEFINER / `pg_catalog, public` | postgres, service_role |
| `process_datasub_provider_callback` | `(p_provider_code text, p_external_event_id text, p_transaction_reference text, p_status text, p_provider_reference text, p_available_balance numeric, p_response_ms integer, p_payload jsonb)` | `6647d6b5d9bf25df13745dbfbaa2ad93` | postgres / DEFINER / empty | postgres, service_role |
| `review_finance_refund` | `(p_refund uuid, p_decision text, p_note text)` | `a2835fe9c181d16c72eb7cb4bad0e659` | postgres / DEFINER / empty | postgres, authenticated, service_role |
| `set_datasub_transaction_pin` | `(p_pin text, p_current_pin text)` | `8c1e445a9ec7e5a3231f61bb2210ade3` | postgres / DEFINER / empty | postgres, authenticated, service_role |
| `claim_datasub_pin_recovery` | `(p_user uuid)` | `5ba8eac86836e216e5218c4704698c00` | postgres / INVOKER / empty | postgres, service_role |

Source mapping notes:
- `create_datasub_api_credential` has a plausible checked-in candidate in DataSub `supabase/migrations/20261010160508_datasub_api_access_callbacks.sql`; it includes active-account checks, explicit reseller API approval, active DataSub access, profile-row locking before the five-key cap, and a 32-byte random secret stored by hash. Still compare full live/source definitions and grants before marking exact parity.
- `claim_datasub_pin_recovery` and `recover_datasub_transaction_pin` have a checked-in candidate in `supabase/migrations/20261009153414_datasub_pin_recovery.sql`. The active Edge Function `datasub-pin-recovery` calls them through a service-role client only after bearer-token validation, active-profile validation, MFA AAL2 when MFA is enrolled, rate-limit claim, and password re-verification. Unit tests cover handler behavior; production-runtime tests have not been run.
- `datasub_transfer_wallet` candidate exists in `docs/sql/datasub-wallet-transfer.sql`, but that document is not an authoritative applied migration. Treat it as a source candidate only; live hash and the documented stricter deployed behavior remain authoritative until a semantic diff proves parity.
- The original source for live wallet reservation/refund hardening and exact source mapping for `create_datasub_api_purchase`, `process_datasub_provider_callback`, `review_finance_refund`, and `set_datasub_transaction_pin` remain unresolved. Do not port the weaker candidate or reconstruct the missing historical migration by guesswork.

### Direct table privilege vs RLS snapshot

- `datasub_pin_recovery_attempts`: RLS enabled; zero direct policies; anon/authenticated have no SELECT/INSERT/UPDATE/DELETE grants. Service-role-only access is consistent with the PIN recovery Edge Function caller reviewed above.
- `datasub_api_credentials`: RLS enabled; anon/authenticated have no direct table privileges. The owner/admin SELECT policy does not itself grant SQL privileges; function/service access still needs to be mapped.
- `datasub_wallets`, `datasub_transactions`, and `datasub_provider_events`: RLS enabled, but underlying anon/authenticated table privileges report SELECT/INSERT/UPDATE/DELETE. Current policy snapshot shows ordinary authenticated policies are SELECT-only, plus Super Admin `ALL` policies; no ordinary anon policy was found. This is **not a demonstrated bypass**, because RLS applies, but direct anon/authenticated negative tests against a disposable clone are still mandatory. Do not test writes against production.
- Read-only trigger inventory: `datasub_provider_attempts` → `private.datasub_attempt_network_availability` (DEFINER, empty search_path, hash `c9995ed44e3adc8c1627e9123a8a4ac9`); `datasub_transactions` → `private.queue_datasub_api_callback` (hash `743bd57fbc794aa7cbd138e161766725`), `private.queue_ihlink_notification_email` (hash `a443b01923aa68be07b26931363605c2`), and `private.record_datasub_reseller_commission` (hash `802a5256bcb8c21f0a24989f6a2fff79`). Each observed trigger function is owned by postgres, SECURITY DEFINER, with empty search_path. Exact source parity, trigger ordering/side effects, and error/rollback tests remain open.

### Next controlled audit

1. Compare the four transaction-status triggers to their authoritative source and map each consumer of their side effects.
2. Find the authoritative deployed/source version for the API-purchase and wallet PIN routines; retain definition hashes and ACLs.
3. Build disposable PostgreSQL tests for direct-table write denial, duplicate purchase idempotency, transfer concurrency, refund/callback races and rollback injection. The tests have not yet been executed.
4. Keep the public provider webhook concern tracked in DataSub issue #47; no production change is authorized by this audit.
