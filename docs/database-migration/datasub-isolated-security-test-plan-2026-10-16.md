# DataSub financial-path authorization and concurrency test plan — 2026-10-16

Status: **test specification only; not executed**. This is not a migration, production runbook, or permission to modify the live Supabase project.

## Safety boundary

- Run only against a disposable local PostgreSQL/Supabase-compatible stack or an explicitly approved isolated test project with synthetic users and synthetic transactions.
- Do not use the production project ref `lnqsroyiybutkfngbyge` as the test target.
- Do not read, alter, or replay production wallet balances, transactions, ledger entries, PINs, callbacks, or provider references.
- Never copy production service-role keys into CI. Use local ephemeral secrets or CI-managed test-only credentials.
- The tests must fail closed if the target database is not positively identified as disposable/test. Production endpoint URLs and production project identifiers must be rejected by the harness.
- Any financial-path test must create its own fixture and clean it up transactionally where possible. Preserve failed-run artifacts without exposing secrets or personal data.

## Evidence currently established (read-only inspection)

- The live wallet-transfer RPC locks the sender/request pair and locks the two wallet rows in sorted user-ID order before balance checks and ledger writes.
- The purchase handler authenticates the user, checks active DataSub access, verifies the wallet PIN, and uses a DB unique partial index on user ID plus `metadata.client_idempotency_key` to prevent duplicate purchase transaction creation.
- The public provider webhook (`verify_jwt=false`) records a routing event from a supplied transaction reference; it does not itself change purchase/refund state.
- Reconciliation is authenticated and handles pending/reconciling/refund-pending states; refund logic conditionally claims the transaction before invoking the idempotent refund RPC.
- These observations are source/catalog findings, not concurrency-test results. No production transaction rows or balances were read.

## Test fixture model

Create synthetic identities and records exclusively inside the disposable target:

- `user_sender_a`, `user_sender_b`, `user_recipient_c`, `user_unrelated_d`
- Active and inactive DataSub profile/access fixtures
- Wallets with fixed test balances and an isolated ledger
- One disposable provider record and one synthetic transaction per scenario
- Distinct idempotency keys per scenario, reused only where a duplicate/retry is intended
- A synthetic provider callback identifier only if the provider contract defines one

Use the project's real schema and RPC signatures from that test database. Do not guess columns or substitute simplified fake routines for the implementation under test.

## Required test matrix

| ID | Scenario | Execution | Required assertion |
|---|---|---|---|
| AUTH-01 | Anonymous direct writes | With anon role and no user JWT, attempt INSERT/UPDATE/DELETE on `datasub_transactions`, `datasub_wallets`, `datasub_wallet_transfers`, `wallet_ledger`, `datasub_provider_attempts`, and `datasub_routing_events`. | Every customer-facing mutation is denied. No rows or balances change. Capture SQLSTATE/error without secrets. |
| AUTH-02 | Authenticated owner direct financial writes | With a real synthetic authenticated JWT, attempt direct wallet balance, ledger, transfer, provider-attempt, routing-event, and transaction-state mutations. | Denied unless the documented policy explicitly permits a narrowly scoped operation. No direct client mutation can create value or mark a purchase paid/refunded. |
| AUTH-03 | Cross-user visibility | As sender, recipient, and unrelated user, query each financial table through the client role. | Each user sees only permitted own/participant records; unrelated user cannot enumerate transactions, balances, or routing events. |
| AUTH-04 | RPC identity spoofing | Call transfer/reserve/refund RPCs with mismatched caller identity or unauthorised target IDs. | RPC rejects mismatched identity and unauthorized action; balances and ledger remain unchanged. |
| PUR-01 | Same idempotency key, sequential retry | Submit the same synthetic purchase twice with identical user and idempotency key. | At most one financial reservation/transaction is created; retry returns stable prior outcome or documented safe retry response. |
| PUR-02 | Same idempotency key, concurrent retry | Launch N concurrent requests with same user/key against the disposable DB. | Exactly one logical purchase/reservation and one debit at most; no duplicate provider submission that could cause double spend. Record all response classes. |
| PUR-03 | Same key, different payload | Reuse a key for a different amount/product/recipient. | Request is rejected as key/payload conflict; original transaction is not overwritten. |
| WAL-01 | Concurrent transfers, shared sender | Run two transfers whose combined amount exceeds the sender balance. | No negative balance; no overspend; each accepted transfer has balanced debit/credit ledger entries. |
| WAL-02 | Opposite-direction transfers | Run A→B and B→A concurrently with bounded timeout. | No deadlock beyond defined retry policy; row lock ordering and retry behavior are documented; total value conserved. |
| WAL-03 | Transfer duplicate request ID | Repeat a transfer request ID with same parameters and then with changed parameters. | Same request is idempotent; changed parameters are rejected; no second debit/credit pair. |
| REF-01 | Refund RPC repeated | Invoke refund twice for the same eligible synthetic transaction. | One net refund only, one consistent set of ledger effects; second call is idempotent or returns a safe already-processed result. |
| REF-02 | Refund versus reconciliation race | Run two reconciliation workers plus a refund retry for the same synthetic transaction. | One authoritative state transition; no double credit; terminal state and ledger agree. |
| REF-03 | Provider failure after reservation | Simulate provider failure/timeout then run the approved reconciliation/refund path. | Reservation is released/refunded once; retry does not double-credit or strand funds without an observable recoverable state. |
| WEB-01 | Unauthenticated provider webhook | Send malformed, empty, oversized, unknown-reference and repeated requests to the local test function. | Input limits enforced; no transaction/wallet state changes. Routing-event writes are authenticated, bounded, idempotent or rate-limited according to the chosen design. |
| WEB-02 | Callback authenticity | Exercise only the provider-authentication scheme verified from the actual provider contract. | Missing/invalid signatures or secrets rejected; valid callback can only enqueue/record a hint, not settle or refund financial state. |
| WEB-03 | Event replay/flood | Replay same valid synthetic event and send a bounded burst of random references. | Duplicate handling and rate limits behave as designed; event storage remains bounded; no financial state changes. |
| RLS-01 | Tenant/profile state changes | Deactivate a synthetic profile/access record and retry purchase/transfer operations. | Operations fail closed when active access is required; previously created records remain auditable. |
| AUD-01 | Invariants after every scenario | Recompute from synthetic rows only. | Wallet balances reconcile with ledger; transfer debit/credit totals balance; no duplicate idempotency key, double refund, negative wallet or orphan financial mutation. |

## Harness and evidence requirements

1. Confirm test target identity before every test run. Abort if the target is production, if its identity cannot be established, or if any production secret is present.
2. Seed deterministic synthetic fixtures. Do not print tokens, PINs, keys, or personal data in logs.
3. Run each scenario individually first, then concurrency scenarios repeatedly with fixed seeds and recorded worker counts.
4. Assert both HTTP/RPC results and postcondition queries. An error response alone is not proof of safety; verify that no rows, balances, ledger entries, or state transitions changed.
5. Capture database version, migration revision, schema hash, function definitions, test commit SHA, and CI run URL.
6. Include negative tests for missing rows and permission errors; do not interpret a timeout or infrastructure failure as a successful authorization denial.
7. Tear down only the synthetic fixture namespace created by the test run. Never run broad cleanup against shared environments.
8. Mark each case PASS only when its postconditions pass. If it cannot be run safely, mark BLOCKED/NOT RUN, not PASS.

## Exit criteria before MySQL parity work

- AUTH-01 through AUTH-04 and RLS-01 pass.
- PUR-01 through PUR-03 pass under both sequential and concurrent execution.
- WAL-01 through WAL-03 pass and ledger invariants hold.
- REF-01 through REF-03 pass under repeated and concurrent execution.
- WEB-01 through WEB-03 pass against the provider contract; public webhook behavior has a documented security decision.
- CI executes the suite against a disposable database with no production secrets.
- The MySQL design maps each proven invariant to transaction isolation, row locks, unique constraints, idempotency records, and server-only financial mutation endpoints.

## Open blockers

- The original SQL/source provenance for the deployed refund-hardening migration remains unresolved. Do not recreate it under the historical name/timestamp or assume the live behavior matches an unverified checked-in file.
- The provider authentication/signature contract for `datasub-provider-webhook` has not yet been verified. See [DataSub issue #47](https://github.com/Hassan-625/IHLink-DataSub/issues/47).
- These tests have not yet been executed. No result should be reported as passing until an isolated test run produces evidence.
