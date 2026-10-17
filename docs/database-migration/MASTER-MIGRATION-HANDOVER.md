# IHLink Master Database Migration Handover

> **Latest audit checkpoint (2026-10-17):** Continue from [MASTER-MIGRATION-HANDOVER-STATUS-ADDENDUM-2026-10-17.md](MASTER-MIGRATION-HANDOVER-STATUS-ADDENDUM-2026-10-17.md). It records the 35-version provenance gap, 397 live-only inventory progress, the draft-only issued-document RLS correction, generated FK/tenant consistency checks, storage ownership findings, and current export/import gates. The addendum is supporting evidence; it does not authorize production changes or export/import.

**Last updated:** 17 October 2026
**Status:** Audit and isolated schema-pilot stage — NOT approved for production cutover  
**Working PR:** https://github.com/Hassan-625/IHLink-SchoolPro/pull/107  
**Working branch:** `migration/mysql-schoolpro-foundation`  
**Source of truth:** live Supabase project `lnqsroyiybutkfngbyge` until each platform independently passes acceptance and the owner explicitly approves cutover.

## 1. Non-negotiable operating rules
- Preserve current application behaviour and repositories. No wholesale rewrite or PHP rewrite as a shortcut.
- Production remains unchanged during this work: no production schema/data edits, no environment-variable changes, no deployment, no migration of live records, and no PR merge without explicit approval.
- **Platform-specific database direction (owner decision, 2026-10-16): SchoolPro is the only platform in the current migration scope targeting MySQL. DataSub and the other existing IHLink platforms remain on their current Supabase-backed architecture.** Supabase remains the production source of truth for SchoolPro until its MySQL target passes acceptance and the owner explicitly approves a platform-specific cutover. MySQL work must use disposable CI/local databases and synthetic fixtures until then.
- Do not treat repository migration files as proof that the same migrations are deployed. Compare file contents, applied migration ledger, deployed Edge Function code/versions, triggers, routines, RLS, storage policies and application call sites.
- Do not place all platform data into one undifferentiated schema with broad credentials. Keep platform-owned data and least-privilege access boundaries; share a narrowly defined identity/account interface only where dependency evidence justifies it.
- Do not expose MySQL credentials to browser or mobile code. Use authenticated server-side APIs.
- Cost matters: prefer the lowest sustainable cost, but do not assume cPanel webspace quota equals database quota or that a shared hosting plan supports long-running API/webhook workloads. Verify actual limits and backup/restore capability before choosing a host.
- DataSub preserves the existing frontend and backend behaviour during migration; no rewrite as a prerequisite. BillStack is DataSub-only. SchoolPro subscription payments remain receipt upload plus IHLink admin verification; school-fee payments remain school-managed.
- Never claim completion from a passing schema-only CI run. State exact scope tested.

## 2. Confirmed baseline on 2026-10-16
- Live shared Supabase project ref: `lnqsroyiybutkfngbyge`.
- Live migration ledger observed: 476 applied migrations; latest recorded entry at audit time: `20261015161735 schoolpro_access_invitation_role_constraint`.
- Live public schema metadata observed: 308 tables. Prefix inventory included SchoolPro 107, DataSub 49, Hosting 18, Consult 21, Engineering 19 and Business 11. Prefix counts are discovery hints, not full ownership mapping.
- Live project listed 41 ACTIVE Edge Functions at audit time, covering several products and shared workflows. Re-check before relying on these counts.
- SchoolPro catalog query found 293 RLS-policy rows, 358 trigger/event rows, and 212 routines matching a targeted name filter. These are not a complete semantic dependency map.
- SchoolPro production hosting is Render: https://ihlink-schoolpro.onrender.com. Do not describe SchoolPro as deployed on Vercel.
- DataSub source `src/lib/supabase.ts` references the same project ref. DataSub README mentions Vercel, but this is not proof of its current live deployment. Verify every platform's actual deployment separately.
- Repo migration counts do not have to match the live project's global ledger: several platform repos share the same database, and some migrations/functions may be deployed from a different repository or historical workflow.

## 3. Repository inventory started
A recursive tree check and direct src/lib/supabase.ts read were completed for the following 14 repositories. All 14 files currently default to the same URL https://lnqsroyiybutkfngbyge.supabase.co and use VITE_SUPABASE_URL plus a publishable/anon browser key fallback. This confirms the same project is wired into these 14 codebases at source level; it does not prove every production deployment uses the current branch/config, and it does not complete runtime call-site or deployed-function parity.

| Repository | Initial evidence | Remaining audit |
|---|---|---|
| `IHLink-SchoolPro` | App client, migrations and Edge Functions | Full source-to-live parity; RLS/grants, triggers/routines/views, Storage, scheduled jobs, RPC/frontend call sites |
| `IHLink-DataSub` | App client, 51 SQL migration files, provider/wallet functions and tests | Compare all migrations and each function to live deployment; wallet/payment invariants; all frontend/server call sites |
| `IHLink-Corporate` | App client; `vercel.json` | Resolve actual live deployment, exact Supabase ref, schema/function dependencies |
| `IHLink-Hosting` | App client; `vercel.json` | Resolve actual live deployment, host provisioning/billing/credentials and provider functions |
| `IHLink-Consult` | App client; `vercel.json` | Resolve actual live deployment, consult booking/payment/data dependencies |
| `IHLink-Engineering` | App client; `vercel.json` | Resolve actual live deployment, engineering payment and project data dependencies |
| `IHLink-Admin` | App client, SQL migrations/tests, BillStack and shared email/payment functions | Separate control-plane permissions from product-owned data; trace all cross-platform RPCs |
| `IHLink-Print-Branding` | App client; `vercel.json` | Resolve actual deployment, print payment/storage/order dependencies |
| `IHLink-3D-Fabrication` | App client; `vercel.json` | Resolve actual deployment, quote/order/payment dependencies |
| `IHLink-AI-Compute` | App client and at least one SQL migration; `vercel.json` | Compute usage metering, request limits, billing, storage and actual deployment |
| `IHLink-Academy` | App client, migrations and certificate function; `vercel.json` | Learning/enrolment/submission/certificate dependencies, actual deployment |
| `IHLink-Digital-Business` | App client, SQL migration; `vercel.json` | Quote/fulfilment lifecycle and actual deployment |
| `IHLink-Business-Innovation-Centre` | App client; `vercel.json` | Exact data/function ownership and actual deployment |
| `IHLink_Design_System_1` | Legacy/umbrella repo containing broad Supabase functions, migrations, backups and runbooks | Determine whether active deployment/source, historical snapshot, or shared operations repo; never assume it is authoritative over product repos |

This is a starter inventory, not a claim that every IHLink repository has been discovered. The next inventory pass must inspect all accessible repositories and search source files for Supabase URL/project refs, SQL clients, Storage, RPCs, auth and deployment settings. Mark each as **active**, **legacy**, **shared/control plane**, or **unknown** only with evidence.

## 4. Current SchoolPro pilot status
- Draft PR #107 is open and unmerged: https://github.com/Hassan-625/IHLink-SchoolPro/pull/107.
- Branch: `migration/mysql-schoolpro-foundation`; last inspected head: `063b31281331def191cbdd09860be296f5683a63`.
- Draft MySQL schema and synthetic fixture are tested on disposable MySQL 8.4 CI. The cross-school enrollment negative test passed. This validates only the current foundation schema and that particular constraint, not complete application parity.
- Latest observed MySQL schema workflow: run #8, success: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38900062579.
- Latest observed SchoolPro CI on migration branch at that check: run #1059, success: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38900062382.
- Latest observed payment validation on migration branch at that check: run #785, success: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38900062409.
- Other newer SchoolPro CI runs on `release/stage-a-auth-tenant-isolation` are a separate branch/workstream and must not be conflated with migration-branch validation.
- No live customer data copied, no production schema/data changed, no Render deployment or environment variables changed.
- The initial MySQL schema is incomplete by design. APIs, complete feature parity, data transfer, auth migration, Storage migration, deployment, rollback rehearsal and performance tests remain outstanding.

## 5. Ordered work backlog and acceptance gates

### M0 — Protect the source and establish evidence
- [ ] Re-fetch PR head and workflow status at the start of every work session; do not rely on cached status or old handover notes.
- [ ] Keep an append/update log here and update the PR body when scope/status changes.
- [ ] Capture read-only schema/table/column/constraint inventory, migration ledger, RLS policies and grants, triggers and trigger functions, views, routines, scheduled jobs, Edge Functions (including deployed version), Storage buckets/policies, auth flows and frontend call sites.
- [ ] Save source commit SHAs and audit timestamps for every repository and live object comparison.
- [ ] Determine exact project ref for every platform and identify any different Supabase projects rather than assuming all use this one.

### M1 — Complete cross-platform source map
- [ ] Build a table-by-table ownership map: platform, repo, source migration(s), live object, reads/writes, tenant key, data sensitivity, target schema/API, migration owner and parity tests.
- [ ] Diff each repo's migration files against the live migration ledger and actual database definitions; explain missing, remote-only, duplicate, changed or out-of-order migrations.
- [ ] Compare checked-in Edge Function code with deployed function name/version and source SHA where available. Inventory secrets by name only; never print secret values.
- [ ] Trace shared dependencies across SchoolPro, DataSub, Admin/control plane, Hosting, Consult, Engineering, Corporate, Print, 3D, AI/Compute, Academy, Digital Business and Business Innovation Centre.
- [ ] Identify Storage buckets, object references, signed URL flows, retention rules and policy dependencies.
- [ ] Identify cron/pg_cron, scheduled jobs, webhooks, retries, queues, email workflows and external provider callbacks.
- [ ] Confirm which repos/platforms are active and which are legacy/duplicated.

### M2 — Hosting and cost decision (no purchase/cutover until evidence)
- [ ] Confirm candidate host's MySQL version/edition, actual database quota and storage quota separately, max connections, query/runtime timeouts, CPU/RAM/process limits, TLS, outbound networking, cron/background workers, webhook reachability and concurrent API support.
- [ ] Obtain written backup frequency, retention, point-in-time recovery if any, restore procedure and evidence of a test restore.
- [ ] Confirm multi-tenant SaaS is allowed under the provider terms.
- [ ] Compare total sustainable cost, not just advertised monthly price; include backups, bandwidth, domains, worker/runtime and migration downtime.
- [ ] If one physical server is chosen for cost, retain separate databases/users/credentials and enforce least privilege; test backup/restore and resource contention isolation.

### M3 — SchoolPro schema/API parity pilot
- [ ] Map all SchoolPro tables and tenant constraints; include all role/permission and platform-super-admin semantics.
- [ ] Convert RLS policies into explicit server-side authorization tests; do not assume MySQL itself supplies PostgreSQL RLS behaviour.
- [ ] Convert and test every relevant trigger, RPC/routine, view, scheduled task and Storage operation.
- [ ] Build the server-side API layer before redirecting any client from Supabase; no direct browser/mobile MySQL connections.
- [ ] Preserve auth and onboarding rules, role-scoped access, password reset/expiry, school isolation and super-admin controls.
- [ ] Expand schema for all finance/subscription/receipt flows, result templates, results publication, attendance, documents, parent/guardian, CBT, reporting and other live features based on the source map.
- [ ] Run synthetic contract tests for every major workflow and cross-school denial.
- [ ] Re-run SchoolPro acceptance gates A/B/C before resuming D:
  - **A:** authentication + tenant isolation.
  - **B:** academic sessions, student population + class rosters.
  - **C:** assessment entry/save workflows, calculations, review + publication.
  - **D:** Result Design Studio + custom Excel workbooks (resume only after A/B/C re-verification as requested).
- [ ] Preserve SchoolPro-specific requirements in the existing product handover: one assessment at a time can be entered and saved; class subject average appears once; scoped class/session/term loading rather than whole-school result fetch; user-uploaded templates per Nursery/Primary/JSS/SS section; no customer workspace seeded with IH Academy operational data; annual subscription/demo and receipt verification rules.

### M4 — DataSub wallet/payment migration (separate high-risk pilot)
- [ ] Keep current frontend/provider integrations and business behaviour; no rewrite as a shortcut.
- [ ] Model wallet ledger as immutable/append-only with transactional balance changes and a reconciliation strategy.
- [ ] Prove atomic debit/credit, idempotent purchase/top-up/refund operations, uniqueness keys, duplicate callback handling, signature verification, replay protection, timeout/retry rules, compensating refund entries and provider reconciliation.
- [ ] Preserve exact money precision using integer minor units or fixed-precision DECIMAL; never floating point.
- [ ] Test CashSub, DataStation and LegitDataway request/response/webhook paths with safe fixtures or provider sandbox evidence.
- [ ] Validate API credential scope, PIN/recovery paths, reseller commissions, catalog/price authority, purchase state transitions, reconciliation and audit logs.
- [ ] Keep BillStack ONLY for DataSub; do not route SchoolPro subscription or school fees through BillStack.
- [ ] Compare all 51 repo SQL migration files and each deployed DataSub-related function against live source before implementing target schema.

### M5 — Other platform migration lanes
- [ ] For each platform, finish M1 ownership/dependency inventory before designing target tables.
- [ ] Keep data/API ownership boundaries independent for Hosting, Consult, Engineering, Corporate, Print & Branding, 3D Fabrication, AI & Compute, Academy, Digital Business, Business Innovation Centre and any additional active apps.
- [ ] Map payment, order, subscription, metering, provider, email, identity, document, certificate, storage and control-plane dependencies explicitly.
- [ ] Do not migrate shared Admin/control-plane routines until all consumers and authorization contracts are identified.
- [ ] Decide if any shared identity/entitlement service is genuinely required from dependency evidence; do not duplicate user records blindly or merge all domains into one broad schema.

### M6 — Data migration and cutover rehearsal (per platform, only after approval)
- [ ] Use synthetic data first; then create an approved, repeatable export/import plan that preserves IDs, timestamps, money precision, status history, file references and audit relationships.
- [ ] Reconcile row counts and business aggregates; check orphaned FKs, duplicate IDs, nullability changes, tenant ownership, wallet balances and financial totals.
- [ ] Test incremental sync/freeze window strategy, duplicate-write handling and outage/downtime estimates.
- [ ] Run full restore rehearsal and rollback rehearsal; establish objective acceptance thresholds and a named go/no-go checkpoint.
- [ ] Run API/security regression, performance benchmark on representative workloads, concurrency tests and tenant-isolation tests.
- [ ] Cut over one platform at a time only after explicit owner approval; keep a viable rollback route and retain Supabase source until the platform is accepted.
- [ ] Never disable or delete the Supabase project merely because one platform has migrated.

## 6. Session update log
- **2026-10-16:** Opened/continued PR #107 as a draft. Added SchoolPro MySQL foundation, synthetic tenant-isolation fixture/CI, source inventory, DataSub inventory and ecosystem architecture.
- **2026-10-16:** Rechecked current PR metadata and migration-branch CI. PR remains open, draft and unmerged. Migration workflow #8, SchoolPro CI #1059 and payment validation #785 passed on the inspected migration branch head. Separate Stage A release-branch runs were in progress and are not migration evidence.
- **2026-10-16:** Recursively inventoried 14 product/umbrella repositories; found Supabase client files in each. Follow-up must verify exact refs and deployment state and expand the inventory to all accessible repositories. No production changes made.

## 7. Update protocol for every future session
1. Read this handover before doing work.
2. Recheck the PR head, latest CI and source/deployed state.
3. Select the next unchecked task; do not skip dependency mapping or claim unverified items done.
4. Make the smallest safe change on an isolated branch and run the relevant tests.
5. Update checkboxes, evidence links, commit SHAs, outstanding risks and session log here; update PR description to match.
6. Report: **done**, **verified**, **blocked**, and **next** separately.
7. Keep production unchanged unless the user explicitly authorizes a clearly scoped operation after reviewing the evidence.


## 8. Follow-up verification — shared project references
- **2026-10-16:** Directly read src/lib/supabase.ts on each of the 14 repositories listed above. All 14 currently default to https://lnqsroyiybutkfngbyge.supabase.co and use Vite environment variables for URL and publishable/anon browser key configuration.
- The publishable/anon browser key is intended to be public; it is not a service-role secret. Never copy or expose service-role keys, database passwords, provider credentials or other server secrets into this handover.
- This confirms source-level coupling to one shared Supabase project across the inspected repositories. It increases migration coordination risk: a global source cutover would affect multiple products. Keep each product on its existing project until its own backend/API and acceptance tests are ready.
- **Important design constraint:** the existing client code uses Supabase directly. A MySQL transition cannot be achieved by changing only the URL or swapping the client library. A server-side API/auth layer and explicit authorization contracts must be implemented and tested before client requests are redirected. Do not begin broad frontend replacement before mapping all .from(...), .rpc(...), Auth, Storage and Edge Function calls.
- Remaining unknowns: actual live URLs/deployments, production env values (inspect names/config only; never reveal secret values), each repository's current deployed commit, all Supabase call sites, and whether any repository has alternate project references outside src/lib/supabase.ts.
- Current migration branch head after the master handover commit is 4497586856a29e5252584c26963350c6075db2d4. At the latest check, its MySQL schema run #9, SchoolPro CI #1063 and payment validation #789 were still in progress. Refresh before reporting results.


## 9. Parallel SchoolPro Stage A signal to retain (not part of migration PR)
- **2026-10-16:** The separate branch `release/stage-a-auth-tenant-isolation` had SchoolPro CI failures at run #1062 (commit `9bbcf1eb5af674b97a38c88c6cbd0b506ab93343`) and #1060 (commit `8834bf7e9941d152b46c343786c0622f9aa97f5e`). Links: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38900336581 and https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38900263029.
- These are **not** migration-branch failures and do not invalidate the MySQL schema test, but they must not be ignored because the owner requires Stage A (authentication + tenant isolation) to be re-verified before returning to SchoolPro Stage D. Inspect the failed job logs, fix only after identifying the root cause, and re-run Stage A acceptance/security tests. Do not assume the payment-validation successes mean SchoolPro CI passed.


## 10. Stage A tenant-acceptance failure analysis — logs inspected 2026-10-16
- Inspected the failed tenant-acceptance job logs for runs #1062 and #1060 (release branch). The `validate` job passed in both runs; the failure is in the live two-school tenant-acceptance job, not TypeScript/build or the local test suite.
- Run #1062 progressed through several positive cross-school denials and then failed while checking a read-only count for `schoolpro_invoices`: attempt 1/3 returned status 0 with `[object Object]`. This looks like an unclassified request/transport/API error in the test's error reporting; the logs alone do not establish an RLS bypass.
- Run #1060 passed multiple foreign-school read denials, both schools' academic-period/RPC checks, and foreign-student result-output RPC denial. It then failed while requesting a foreign template for School B: expected HTTP authorization/not-found denial, received HTTP 544 `DatabaseTimeout` from the database connection. A timeout is **not** a valid authorization-denial result, so the check correctly failed closed; it does not by itself prove cross-tenant data leakage.
- The two failures are not identical. The common signal is that live tenant acceptance is being disrupted by unstable/slow database/API requests. Earlier observations of slow Storage/template-related requests make latency and policy query cost a hypothesis, not a proven root cause. Need inspect request timing, query/policy plans where available, request IDs/server logs and the exact helper that converts non-2xx responses into errors.
- **Next diagnostic action:** inspect the tenant acceptance script and workflow at the exact release commit; improve diagnostics so HTTP status, response body, endpoint category and retry attempt are surfaced without logging credentials or student data. Separate transport/timeouts (inconclusive; fail) from explicit 401/403/404 denials. Retry only transient network/5xx/timeout cases with bounded backoff; never turn timeouts into passes. Re-run both-school acceptance read-only after evidence gathering.
- **Do not** weaken RLS, turn a timeout into a pass, or make production schema/policy changes to quiet the test. Do not run broad expensive live queries or add load while diagnosing. Check whether the two-school test secrets' optional receipt path/session/term variables are intentionally required for any assertions; the logs show those optional variables empty, but no evidence yet that they caused these failures.
- Source retrieval of the release-branch script path was not successful in this pass, so exact code-level root cause remains unresolved. The two run logs are evidence; diagnosis is not complete.


## 11. DataSub live catalog inventory — read-only, 2026-10-16
- Re-queried live public-schema metadata through read-only catalog SQL. It currently reports 49 `datasub_` base tables and 96 `datasub_` policy rows. These are live metadata counts, not proof of correct policy semantics.
- All 49 `datasub_` base tables in the returned inventory had row-level security enabled. `datasub_pin_recovery_attempts` currently has zero entries in `pg_policies` while RLS is enabled. This is not automatically a vulnerability (no matching policy normally means ordinary client roles cannot see rows), but it is a **review item**: verify the intended access path, function `claim_datasub_pin_recovery`, grants and whether service-role-only access is deliberate. Do not add a broad policy merely to make the count nonzero.
- The live catalog also exposes important wallet/payment routines including `reserve_datasub_wallet`, `refund_datasub_wallet`, `finalize_datasub_transaction`, `process_datasub_provider_callback`, `review_datasub_wallet_funding`, `review_finance_refund`, `queue_failed_fulfilment_refund`, `datasub_transfer_wallet`, `create_datasub_api_purchase`, and credential/webhook/PIN operations. Routine names are a starting index only; next inspect full definitions, security-definer status, owner, grants, search_path, transaction boundaries and idempotency behaviour.
- The live inventory includes tables for transactions (18 columns), wallets, funding requests, transfers, provider attempts/events/webhooks, purchase deliveries, provider connections, API credentials/usage, reseller commissions, referrals, scheduled purchases, spending limits and PIN recovery. This broadens DataSub parity requirements beyond the initial purchase path.
- Non-internal `datasub_` table triggers were observed on catalog offerings/routes, network availability, provider attempts/health/providers, upstream catalog and transactions (10 trigger rows total; transactions has three). Capture each trigger definition and underlying trigger function in the target parity matrix.
- **Next DataSub audit:** compare live object definitions with the 51 checked-in repository migration files; inspect policies for `datasub_wallets`, `datasub_transactions`, `datasub_wallet_funding_requests`, `datasub_wallet_transfers`, `datasub_pin_recovery_attempts`, `datasub_provider_webhook_events`, `datasub_webhook_deliveries` and API credentials. Test access for anonymous, authenticated customer, reseller, admin and server/service roles without exposing secret values. Confirm no provider token/credential fields can be selected by browser roles.
- These are catalog-only checks. No row contents, wallet balances, customer information or provider secrets were read; no production objects were modified.


## 12. DataSub critical routine metadata — read-only, 2026-10-16
- Catalog metadata was queried for 16 wallet/payment/PIN/API routines. The routines are owned by `postgres`; many sensitive operations are `SECURITY DEFINER` and have an explicitly empty `search_path` setting, which is a useful hardening signal but does not prove their function bodies are safe.
- `create_datasub_api_purchase` is `SECURITY DEFINER` with `search_path=pg_catalog, public`; this is a focused manual-review item. Confirm whether any relevant objects in `public` are user-writable/replaceable and whether every object reference is schema-qualified. Do not label it exploitable from metadata alone.
- Catalog ACL metadata lists `authenticated` as an execute grantee for `create_datasub_api_credential`, `datasub_transfer_wallet`, `review_finance_refund` and `set_datasub_transaction_pin`. These grants may be intentional if function bodies enforce user ownership/role and validate arguments. Verify each function's full definition, `auth.uid()` ownership checks, admin-role checks, argument validation, idempotency/locking and any direct browser call sites. The routine ACL by itself does not establish that authorization is broken.
- `claim_datasub_api_callbacks`, `consume_datasub_api_request`, `process_datasub_provider_callback`, `reserve_datasub_wallet`, `refund_datasub_wallet` and `queue_failed_fulfilment_refund` are also `SECURITY DEFINER`, with service-role-only execution visible in the returned ACL for the inspected signatures. Verify function overloads separately and compare ACLs with repository migrations; this snapshot covers only matching routines/signatures returned by the catalog query.
- **Next safety rule:** do not fetch/print entire function bodies into user-facing notes if they may contain embedded credentials or sensitive business logic. Inspect source in a controlled pass, redact secrets, and record only the relevant authorization/transaction/search_path findings plus the exact routine signature and evidence commit.


## 13. Current-head CI verification and next audit checkpoint — 2026-10-16
- Re-fetched PR #107 metadata and the handover file before updating. PR remains open, draft, unmerged; current inspected head before this note was `04e7ce2aabd951b6977f37df0914599f2449ff97`.
- Queried GitHub Actions runs associated with that exact commit. All three completed successfully:
  - SchoolPro CI #1068: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38910091949
  - Payment validation #794: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38910091230
  - SchoolPro MySQL schema draft #14: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38910091041
- These results validate the current migration-branch code/schema checks only. They do not validate live production cutover, DataSub parity, restore, or Stage A tenant acceptance. Stage A release-branch failures #1062/#1060 remain unresolved and must not be marked passed.
- Attempted repository code search for the five DataSub routine names flagged by live catalog ACL metadata; GitHub code search returned no indexed matches for these queries. This is not evidence that the routines are absent from source. Next, locate the exact checked-in migration/function files through repository tree/history or inspect the corresponding live definitions in a controlled read-only audit, then compare signatures, grants, SECURITY DEFINER/search_path, ownership/role checks, argument validation, transaction boundaries, idempotency and locking. Do not print raw bodies into this handover if they could contain sensitive material.
- Immediate next migration task: produce a DataSub source-to-live routine/trigger/policy matrix with evidence references and a confidence column; prioritize wallet reservation/refund/transfer, API purchase/credential, PIN, finance refund, and provider callback/replay handling. No schema or data changes are authorized.


## 14. DataSub routine source-to-live comparison — read-only, 2026-10-16

- Re-fetched live definitions for reserve_datasub_wallet, refund_datasub_wallet, datasub_transfer_wallet, create_datasub_api_purchase, create_datasub_api_credential, process_datasub_provider_callback, review_finance_refund and set_datasub_transaction_pin. No production changes were made.
- IMPORTANT CORRECTION — reservation/refund: the deployed reserve_datasub_wallet is stricter than the checked-in 20260924210000_datasub_transaction_safety.sql version in the DataSub repository. Live reservation locks the transaction and wallet, verifies user/transaction/amount/reference consistency, validates a RESERVE: reference, checks pending state, checks for an existing matching ledger entry and only then debits. Repeated matching references are treated idempotently; mismatched prior entries are rejected. Do not describe deployed reservation as double-debit vulnerable based on the older file.
- The deployed refund_datasub_wallet validates transaction owner, amount, exact REFUND: reference, reserve ledger entry and transaction status, then locks the wallet and records the refund ledger entry before crediting the balance. A prior matching refund is idempotent; a prior mismatched refund returns false. This is materially stricter than the checked-in initial transaction-safety migration.
- The live migration ledger contains 20260925191607 harden_datasub_refund_idempotency, but that named migration was not found in the inspected DataSub repository tree or the inspected IHLink_Design_System_1 tree. This is an unexplained source-provenance gap, not proof of drift or a defect. Find the authoritative source commit/repository or recover the exact migration content from Git history/approved deployment records before target conversion. Do not reconstruct it by guessing.
- Live create_datasub_api_credential matches the later approval-gated design in 20261010160508_datasub_api_access_callbacks.sql more closely than the earlier 20260917210000_datasub_api_credentials_usage.sql version: it requires an active account, an active reseller with explicitly approved API access, active DataSub access, locks the profile row before enforcing the five-key cap, and generates a 32-byte random secret. The checked-in initial migration is not a sufficient source for the deployed definition.
- Live create_datasub_api_purchase is SECURITY DEFINER and its observed ACL is restricted to service_role plus owner. Its visible body checks an active live credential bound to the supplied user, approved API-enabled reseller tier, active DataSub access, valid recipient/reference, active product and server-owned API price, then locks the wallet and checks balance before creating the pending transaction. search_path=pg_catalog, public remains a hardening review item; inspect schema CREATE privileges and fully qualify object references if any untrusted object-shadowing path exists. ACL alone does not establish a vulnerability.
- Live datasub_transfer_wallet verifies caller from auth.uid(), requires an active profile, validates request ID and amount, takes an advisory transaction lock for sender/request ID, checks duplicate request consistency, verifies PIN, restricts recipient to an active customer-visible DataSub BillStack virtual account, and locks wallet rows in sorted user order. Continue review of the full tail for atomic ledger/debit/credit/audit parity and add concurrent duplicate-request tests to the MySQL target.
- Live process_datasub_provider_callback records a unique provider/event pair, returns duplicate for an already-recorded event, locks the transaction and only finalizes pending transactions, and updates provider status/health metadata. Its ACL is service-role-only. Still test conflicting callbacks for the same transaction, out-of-order success/failure/reversal events, and interaction between callback refunds and reservation/refund ledger invariants.
- review_finance_refund is not a DataSub wallet-refund primitive: the live body validates corporate approval permission, locks the refund request and canonical payment transaction, verifies customer/platform/source reference/settlement/status/amount/currency, then audits the decision. Preserve that control-plane/payment contract separately from DataSub wallet refund behavior.
- set_datasub_transaction_pin is caller-bound to auth.uid() and requires the current PIN when changing an existing PIN; PIN is hashed with crypt and resets lockout counters on change. Keep PIN material service-only in the MySQL/API design and test failed-attempt lockout and recovery paths.
- claim_datasub_pin_recovery has SECURITY INVOKER, an empty search path, and service-role-only execute grant; datasub_pin_recovery_attempts has RLS enabled and no direct table policy. This is consistent with a function/service-only path, but confirm Edge Function/service-role call sites before treating it as fully verified.
- ACL snapshot for create_datasub_api_credential, datasub_transfer_wallet, review_finance_refund and set_datasub_transaction_pin includes authenticated execute, with explicit identity/permission checks visible in inspected definitions. Continue to test negative authorization paths; do not label these grants a vulnerability without a failing test.
- Current confidence: live behavior was inspected from catalog definitions and compared to selected checked-in migrations. Full provenance is incomplete because repository code search did not find the later hardening migration. No transaction simulation or customer-data read was performed. No schema/data changes, deployments, or environment changes were made.
- Next: locate authoritative source for live-only hardening migrations; build a per-routine matrix with live signature/definition hash, source file and commit, ACL, transaction/locking behavior, idempotency behavior, and positive/negative/concurrency test. Then inspect trigger definitions and callback event ordering. Do not start MySQL financial logic implementation from the older migration file alone.


## 15. Recovery follow-up — deployed wallet definitions preserved, original migration still missing

- Recovery search expanded to GitHub exact-path commit history in IHLink-DataSub, IHLink-SchoolPro and IHLink_Design_System_1. The exact artifact `20260925191607_harden_datasub_refund_idempotency.sql` was not found in those exact paths or inspected repository trees. Do not claim the original migration file/commit has been recovered.
- The **live deployed definitions themselves have now been recovered** from the read-only Supabase catalog and preserved for audit/port design at [recovered-live-datasub-wallet-routines-2026-10-16.md](recovered-live-datasub-wallet-routines-2026-10-16.md). That document contains the exact current definitions of `reserve_datasub_wallet` and `refund_datasub_wallet`, their observed behavior and provenance limitations. It is a forensic snapshot, not a replayable migration.
- The checked-in `20260924210000_datasub_transaction_safety.sql` was confirmed to be an earlier, materially weaker implementation: its reservation can debit before the ledger insert's `ON CONFLICT DO NOTHING`, and its refund path credits without the current live ownership/amount/reservation checks. Do not port or replay that file as if it represented the deployed behavior.
- The Git history includes commit `2a9390e69f498c804f5d772ca4f60401f2d69b13` in IHLink_Design_System_1, titled “Harden DataSub transaction idempotency and wallet ledger,” which added that initial transaction-safety migration. This is useful historical context but is **not** the missing later hardening artifact.
- Next recovery paths: inspect Supabase deployment logs/audit records if available; inspect all branches and historical trees across the ecosystem repositories; correlate live function definition hashes and surrounding migrations; ask repository owner for the source branch/commit if the migration was applied from a local SQL editor. Until its original artifact is found, label provenance unresolved and use the captured live definition only as a reviewed reference.
- No production DDL/DML, deployment, environment change or migration execution occurred. The documentation recovery commit is on the unmerged migration branch only.

## 16. Expanded DataSub migration-provenance recovery — 2026-10-16

- Checked the exact expected path `supabase/migrations/20260925191607_harden_datasub_refund_idempotency.sql` on the following relevant refs: IHLink_Design_System_1 branches `datasub-final-production-audit`, `complete-datasub-api-handoff`, and `feat/datasub-production-phase4`; IHLink-DataSub branches `datasub-local-migration` and `main`. GitHub returned not-found for the exact path on each ref.
- Inspected recursive migration trees for IHLink_Design_System_1:`datasub-final-production-audit` (88 migration files) and IHLink-DataSub:`main` (51 migration files). Both include the older `20260924210000_datasub_transaction_safety.sql`; neither contains the exact missing 20260925191607 migration. The checked Design System branch's latest DataSub-specific migrations include `20260926145500_datasub_market_pricing_control.sql`, `20260926150500_datasub_secure_transaction_pin.sql`, `20260926151500_datasub_route_scope_hardening.sql`, and `20260926152000_datasub_pin_pgcrypto_fix.sql`. The DataSub main branch additionally contains the October reconciliation, legacy RPC removal, PIN recovery and API callback migrations, but these do not establish the missing refund migration's source.
- GitHub commit search found DataSub commit `8a78193c398defa4e5addf198b798e861a4132d0` (“Confirm wallet refunds before completion and verify provider callbacks through reconciliation”). Its visible diff changes provider-adapter reconciliation/classification logic, not the missing wallet refund SQL; it is not evidence for the migration's provenance.
- This expands the checked refs/trees but does **not** prove the migration never existed: it could have been applied from another branch, a local SQL editor, an uninspected commit/tree, or a deployment artifact. Source provenance remains unresolved. No SQL was executed against production and no repository migration was reconstructed by guesswork.
- Next action: build the routine parity ledger from the deployed catalog, starting with `reserve_datasub_wallet` and `refund_datasub_wallet`, and capture for each routine: live signature and definition hash, owner/security mode/search_path, EXECUTE ACL, checked-in candidate files/commits, caller paths (RPC/Edge Function/frontend), locking and idempotency invariants, and positive/negative/concurrency test status. For the missing migration specifically, inspect Supabase migration/deployment audit records and commit histories on additional refs; if those do not preserve the SQL, record the original migration as unrecoverable and use the captured live definition only as a reviewed reference for a newly authored, separately named target migration.
- Boundary remains unchanged: audit-first, no production DDL/DML, no deployment, no environment edits, no merge/cutover without explicit authorization. The SchoolPro MySQL foundation PR remains draft/unmerged.

- **New working artifact:** [DataSub live routine parity ledger — 2026-10-16](datasub-live-routine-parity-ledger-2026-10-16.md). It records the currently observed live routine invariants, source candidates/provenance gaps, and required negative/concurrency/rollback tests. It is deliberately marked partial: no test is counted as passed merely because a live definition was inspected.
- Recommended execution order from this ledger: finish the full `datasub_transfer_wallet` tail and map all routine callers; capture definition hashes/ACL/owner/search_path for the core routines; then build disposable PostgreSQL tests for reservation/refund/callback race conditions. Only after that should the MySQL/API equivalent be implemented and tested.

- **Further live-definition evidence:** read-only catalog inspection captured the complete `datasub_transfer_wallet(uuid,numeric,text,uuid)` body plus owner/ACL/security configuration. Definition MD5: `ecfc51ef872d2c4816d13b4e52fe18d6`; owner `postgres`; SECURITY DEFINER; empty search_path; EXECUTE granted to `authenticated` and `service_role` as well as owner. The body performs caller/active-profile checks, sender+request advisory locking, duplicate argument consistency, PIN validation, recipient eligibility, sorted wallet-row locking, sufficient-funds check, transfer-row insert, debit/credit, and paired ledger writes. No transfer or balance/ledger row was accessed. Remaining rollback/concurrency and direct-table-bypass tests are listed in the parity ledger.
- Current PR #107 head after these audit-document commits is `d640dffa04c37f88461af9bddbf11cf03670be57`; PR remains draft/open/unmerged. Do not infer latest-head CI success from earlier runs; the latest changes are documentation-only and workflow status has not been verified for this exact head.

- DataSub caller/RLS review added to the routine parity ledger: live purchase and reconciliation paths, the unique partial idempotency index, and current RLS-policy observations are documented. Duplicate-purchase concurrency and retry behavior still require isolated tests.
- Security review item: the deployed datasub-provider-webhook endpoint is active with JWT verification disabled and its handler accepts POSTs without provider signature/shared-secret validation. The inspected handler only records a routing event and does not change purchase/refund state. This is a potential event-log noise/integrity issue, not evidence of financial-state bypass. Review authentication, idempotency and rate limiting before any production change. The separate datasub-api-callbacks endpoint checks a worker bearer token.
- RLS is enabled on the inspected wallet/transaction/ledger/attempt/event tables. Some underlying grants are broad, but customer write policies were not present on the inspected financial mutation surfaces. Confirm with explicit anon/authenticated JWT negative tests in an isolated environment; grants alone do not prove a bypass.
- Updated ledger: [DataSub live routine parity ledger](datasub-live-routine-parity-ledger-2026-10-16.md). No live transaction rows, balances, or wallet ledger rows were queried. No production data/schema changes or deployments occurred.

- **DataSub follow-up opened:** [IHLink-DataSub issue #47 — Security review: harden public provider webhook event ingestion](https://github.com/Hassan-625/IHLink-DataSub/issues/47). It documents the unauthenticated event-ingestion concern and acceptance criteria. The deployed handler only records an event; it does not directly settle or refund transactions. Provider authentication requirements must be confirmed before choosing a fix. No code or production configuration was changed.

- **Isolated DataSub security/concurrency test plan added (2026-10-16):** [test plan](datasub-isolated-security-test-plan-2026-10-16.md). It defines synthetic-only tests for direct-write/RLS denial, idempotent purchases, concurrent transfers, duplicate refunds, reconciliation races, and public webhook abuse. This is a specification, **not an executed test suite**; no case is marked PASS and production was not used.

- **Refund migration provenance search update (2026-10-16):** additional GitHub commit searches for `harden_datasub_refund_idempotency`, `refund idempotency wallet`, and `datasub refund hardening` returned no matching commits in the checked SchoolPro/DataSub repositories. This does **not** prove the migration was never applied; the original source may be in another repository, an unindexed/deleted branch, or deployment history. Keep the provenance gap open. Do not fabricate the historical SQL, rename speculative SQL to the old timestamp, or treat the live routine as fully explained until the applied migration/deployed function definition and intended invariants are reconciled.

- **MySQL cross-tenant negative-test quality fix (2026-10-16):** tightened `.github/workflows/mysql-schoolpro-schema.yml` so the test passes only when MySQL reports the expected foreign-key violation (`ERROR 1452`). Previously, any SQL failure—including syntax, connection, or setup failures—could be misreported as a successful rejection. The updated check is on commit `90dba5c838ad649330249113462edfab8c9c1680`; schema workflow #33 and related CI/payment workflows have been triggered, but their final results are not yet confirmed. This improves test diagnostics; it does not by itself prove the entire tenant-isolation model.

- **Tenant negative-test evidence update (2026-10-16):** MySQL schema workflow #34 completed successfully on commit `2bf7b329d7b265aad9352168046d57f54f05778e`. Its logs explicitly show MySQL `ERROR 1452` for `fk_enrollment_student` and the assertion `PASS: ... rejected by the expected foreign-key constraint`; this confirms the earlier broad false-positive path is fixed for the student relationship. Extended the disposable CI test set to separately attempt cross-school student, academic-session, and class relationships, requiring each named composite foreign key to reject the row. The additional session/class assertions are in commit `536d894973f9b4b04657cf03b3917ccd8cbea210`; their workflow result is pending/not yet visible. This remains a database-constraint test, not a substitute for API-level tenant authorization tests.

- **Cross-school class test diagnostic (2026-10-16):** schema workflow #42 failed on the new class test for the right reason: the attempted row hit the existing `uq_enrollment_student_session` duplicate constraint before reaching the intended class-ownership constraint. This was a test-fixture flaw, not evidence that the cross-school class relationship was accepted. Corrected `tests/mysql/cross_tenant_enrollment_class_must_fail.sql` to use a separate synthetic School A student and a unique student/session pair so the assertion can reach `fk_enrollment_class`. Correction commit: `c494d554b1d6b66ef180e9833845e6ec3064c00b`. The corrected commit's workflow run is not yet visible in the workflow lookup; do not mark the class test passed until its CI log explicitly shows the expected `ERROR 1452` naming `fk_enrollment_class`. Session test did pass in run #42, naming `fk_enrollment_session`; the existing student test also passed.

- **Tenant test verification and next coverage (2026-10-16):** MySQL schema workflow #46 passed on commit `61f12b180009608325e4ea190662c6bed2d51abf`. Its log explicitly confirmed the expected `ERROR 1452` constraint names for all three enrollment boundaries: `fk_enrollment_student`, `fk_enrollment_session`, and (after correcting the fixture to avoid a duplicate enrollment) `fk_enrollment_class`. Payment validation #831 also passed; SchoolPro CI #1104 was still in progress at the last check. Added `tests/mysql/cross_tenant_result_term_must_fail.sql` and wired it into the disposable MySQL workflow, requiring `fk_result_term_session` to reject a result whose term belongs to another school/session. This newer result/term assertion is not yet verified by CI. Latest migration branch commit at handover edit time: `f2db906b1803395a705e8cc75de35b7052beccbf`; PR #107 remains open/draft/unmerged. No production changes.

- **Result/term integrity verified and score-component test added (2026-10-16):** MySQL schema workflow #51 passed and its log confirms `tests/mysql/cross_tenant_result_term_must_fail.sql` was rejected by the expected `fk_result_term_session`. Together with the three previously verified enrollment constraints, four relationship assertions are now evidenced by CI. Added `tests/mysql/result_score_component_term_must_match.sql`, which attempts to attach a Second Term assessment component to a First Term result in the same school/session; the disposable MySQL workflow now requires rejection by `fk_result_scores_component`. This fifth assertion is pending CI. Payment validation #834 passed; SchoolPro CI #1107 was still in progress at the last check. No production changes; PR #107 remains draft/unmerged.

- **Assessment component consistency verified; assignment isolation tests added (2026-10-16):** MySQL schema workflow #56 passed. Logs confirm the score/component mismatch was rejected by `fk_result_scores_component`; this makes five confirmed negative relationship assertions (student, session, class, result term, result score component). Added four further disposable CI tests for cross-school class, subject, session and staff-membership references in `class_subject_assignments`, requiring `fk_csa_class`, `fk_csa_subject`, `fk_csa_session`, and `fk_csa_membership` respectively. Those four assertions have been wired into the schema workflow but await CI results. Latest workflow edit commit: `df3044e0039f09dbb58e8f1be3378540a66d1af0`; PR #107 remains draft/unmerged and no production changes were made. SchoolPro CI #1111 was still running at the last check; payment validation #838 passed.


- **Supplemental DataSub catalog snapshot (2026-10-16):** refreshed exact live routine signatures, owner/security/search_path, definition MD5 hashes and EXECUTE ACLs for nine wallet/API/PIN/refund routines in the DataSub parity ledger. The PIN recovery caller was traced to the active `datasub-pin-recovery` Edge Function: service-role-only database RPCs are invoked after bearer token and active-profile validation, MFA AAL2 when applicable, attempt throttling, and password re-verification. The corresponding handler test is a unit test, not a live database test.
- **DataSub RLS/grant clarification:** `datasub_pin_recovery_attempts` and `datasub_api_credentials` have no direct anon/authenticated table grants; wallet, transaction and provider-event tables report broad underlying table grants, but the observed RLS policies for ordinary clients are SELECT-only and Super Admin has separate ALL policies. No bypass has been demonstrated. Explicit anon/authenticated write-denial tests against a disposable clone remain open; do not test direct writes against production.
- **DataSub trigger inventory:** `datasub_transactions` has three SECURITY DEFINER AFTER triggers for API callback queueing, purchase email and reseller commission; `datasub_provider_attempts` has a network-availability trigger. All inspected trigger functions are postgres-owned and use empty search_path. Source parity and rollback/error tests remain open.
- Next controlled DataSub task is to compare these four transaction-status trigger functions with authoritative source, map their consumers, and then build disposable PostgreSQL tests for direct-write denial, duplicate purchase, transfer concurrency, refund/callback races and rollback. No production DDL/DML, transaction, deployment, environment change or cutover was performed.


- **Assignment membership test fixture correction (2026-10-16):** MySQL schema workflow #65 failed on the new cross-school membership test because the test reused an existing School A class/subject/session tuple and hit uq_class_subject_assignment before reaching fk_csa_membership. This was a fixture-ordering issue, not a successful cross-school write. Updated tests/mysql/cross_school_assignment_membership_must_fail.sql to create a separate synthetic School A subject first, preserving valid class/session references while the membership still points to School B. Correction commit: c7e11de37f0e30697c07c890da06985c2be52aa2. The corrected membership assertion and all downstream workflow checks are pending; only mark it passed when CI logs show ERROR 1452 naming fk_csa_membership. The three assignment class/subject/session assertions passed in workflow #65; five earlier enrollment/result assertions also passed in workflow #56. PR #107 remains draft/open/unmerged. No production changes.


- **Assignment relationship test suite verified (2026-10-16):** MySQL schema workflow #69 passed on corrected test fixture. Its log explicitly shows MySQL ERROR 1452 with the expected constraint names for all nine negative relationship assertions: fk_enrollment_student, fk_enrollment_session, fk_enrollment_class, fk_result_term_session, fk_result_scores_component, fk_csa_class, fk_csa_subject, fk_csa_session and fk_csa_membership. The membership assertion now reaches fk_csa_membership instead of failing early on a duplicate unique key. This validates these relational constraints in disposable MySQL 8.4 CI only; it does not establish API authorization, full schema parity, production-host suitability or migration readiness. Payment validation #845 also passed; SchoolPro CI #1118 remained in progress at the latest check. PR #107 remains open/draft/unmerged; production Supabase and Render are unchanged.


- **Next assessment-integrity assertion added (2026-10-16):** Added tests/mysql/assessment_component_requires_class_subject_assignment.sql and wired it into the disposable MySQL workflow. It creates a synthetic subject for School A without assigning it to the target class/session, then expects the assessment-component insert to be rejected by fk_ac_class_subject_session. This extends testing beyond tenant ownership to ensure assessments cannot be defined for an unassigned class/subject tuple. The new assertion is pending workflow verification. It remains a schema constraint test, not proof of application/API authorization or full schema parity.


- **MySQL 8.4 compatibility cleanup (2026-10-16):** Replaced the deprecated VALUES(column) expression in the draft schema-migration upsert with the supported INSERT row alias form. This removes a MySQL 8.4 deprecation warning without changing the migration record's intended values. Commit e09ea2fcec001d7832dae8e714b4f0f25f598067; rerun schema CI to verify alongside the new assessment assignment assertion.


- **DataSub trigger source mapping update (2026-10-16):** located candidate source migrations for `private.record_datasub_reseller_commission` (`20260920161000_datasub_reseller_commissions.sql`), `private.datasub_attempt_network_availability` (`20261008221800_network_outage_events.sql`), and `private.queue_datasub_api_callback` (`20261010160508_datasub_api_access_callbacks.sql`). These are source candidates; semantic/live parity still requires a definition diff and tests. The fourth live trigger function, `private.queue_ihlink_notification_email`, remains unmapped after checking the DataSub main tree and initial Design System/Admin source search; treat it as shared-function provenance work, not an absent or broken function.
- All four observed trigger functions are postgres-owned SECURITY DEFINER routines with empty search_path. DataSub callback delivery, reseller commission, and network-availability trigger side effects need duplicate/retry/rollback tests before the MySQL/API equivalent is designed. No production transaction, schema/data change, deployment, or environment change was made.


- **Assessment/class-subject consistency verified (2026-10-16):** MySQL schema workflow #77 passed. The log explicitly shows tests/mysql/assessment_component_requires_class_subject_assignment.sql rejected by fk_ac_class_subject_session (ERROR 1452), bringing the verified negative relational assertions to ten. The same run applied the schema without the earlier VALUES(column) deprecation warning after the alias syntax cleanup. Evidence: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38922824469. This is disposable MySQL 8.4 schema evidence only; it does not certify the full SchoolPro schema, API authorization, production hosting readiness or data migration. PR #107 remains open/draft/unmerged; no production change.


- **Source-to-target table parity matrix added (2026-10-16):** Created `docs/database-migration/source-to-target-table-parity-matrix-2026-10-16.md` from the read-only source inventory. It lists all 107 SchoolPro-prefixed source tables by domain, identifies ten conceptual candidate mappings to the normalized MySQL draft, and leaves every unaccepted mapping explicitly unmapped pending DDL, keys, RLS, trigger/routine, call-site, lifecycle and retention review. The draft currently contains 20 tables including migration metadata/auth/tenant foundations; this matrix does not claim parity. Shared platform dependencies are explicitly separated, and DataSub wallet/payment internals remain out of scope. Commit `727ef012b530edfcdd4dc2c8cb3a4ff08bab0538`. PR #107 remains draft/open/unmerged; production Supabase and Render unchanged.


- **High-priority DataSub callback/ledger review (2026-10-16):** the live service-role-only `process_datasub_provider_callback` routine (definition MD5 `6647d6b5d9bf25df13745dbfbaa2ad93`) deduplicates provider/event IDs and locks pending transactions, but directly credits wallet balance for failed/reversed callbacks without writing `wallet_ledger`, and does not bind the supplied provider code to the matched transaction's provider. Candidate source is `IHLink-DataSub/supabase/migrations/20260920170000_datasub_provider_operations.sql`, which has the same pattern. A targeted scan of 11 relevant active deployed Edge Functions found no call to this routine; the public provider webhook only records a routing event and the LegitDataway webhook does not call the routine. This is a high-priority legacy financial-path integrity risk, **not a demonstrated public exploit or proof of current reachability**.
- Before any MySQL/API port, prove all SQL/worker callers and whether the routine is still required; add disposable PostgreSQL tests for provider mismatch, duplicate/conflicting callbacks, refund-worker races and transaction rollback. Target behavior must update canonical ledger and balance atomically and bind provider identity to the transaction. No production function, schema, wallet, ledger or transaction was changed.


- **MySQL relationship test evidence update (2026-10-16):** disposable MySQL 8.4 schema workflow #85 passed on commit `b3f2b7d59fea159a4b51f08def45eb9e64ca40c9`. Its log confirms nine negative cases fail for their expected named foreign keys: cross-school enrollment student/session/class; result term/session mismatch; result-score component term mismatch; class-subject assignment class/subject/session/member mismatch; and assessment component without a matching class/subject/session assignment. The workflow now rejects tests that fail for the wrong reason; each case requires MySQL error 1452 plus the expected constraint name. This is structural relational-integrity evidence only; it does not test API authorization, full schema parity, live-data migration, or cutover readiness. Latest general SchoolPro CI #1132 on this documentation-era branch head was still running at the last check.


- **SchoolPro behavior/authorization parity matrix added (2026-10-16):** Added [behavior-and-authorization-parity-matrix-2026-10-16.md](./behavior-and-authorization-parity-matrix-2026-10-16.md) in commit 8a6c050e924813cc8156d646a87b931eec62fe6e. It translates the known critical tenant, authentication, role, results-publication, file-access, progression, transcript, subscription and trigger invariants into target responsibilities and minimum positive/negative tests. It explicitly labels source definitions and semantic parity as unverified; no behavior is claimed complete from the table/FK tests alone. Next source task is to capture the actual SchoolPro routine signatures/definitions, RLS USING/WITH CHECK and grants, trigger-to-function ordering, and app/RPC/Storage call sites before implementing API authorization. PR #107 remains draft/open/unmerged; no production changes.


- **Latest session status refresh (2026-10-16):** PR #107 head is now `0bb2c4e71c2111334ddadcace8c87eef55d82293`, open/draft/unmerged, with 24 changed files. The behavior matrix was added in `8a6c050e924813cc8156d646a87b931eec62fe6e`; the master handover update is `0bb2c4e71c2111334ddadcace8c87eef55d82293`. Workflow lookup for the immediately preceding code head `5b5fa6ed55e49084e8fb76db4240868954b7affc` showed MySQL schema run #86 passed (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924175061), payment validation #860 passed (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924175098), and SchoolPro CI #1133 still in progress (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924175053). The latest two commits are documentation-only; no workflow runs were returned for the handover commit by the PR-run lookup. Do not report SchoolPro CI as passed on the latest head until its run completes or a relevant run is confirmed. The schema workflow's new assessment/class-subject-assignment assertion must also be checked in run #86 logs before claiming it passed. No production changes.


- **Current CI log review and relational-test refresh (2026-10-16):** Inspected disposable MySQL schema workflow #86 logs directly: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924175061. All ten negative relational assertions passed, including `assessment_component_requires_class_subject_assignment.sql` rejected by `fk_ac_class_subject_session`; the workflow requires both MySQL `ERROR 1452` and the expected constraint name. SchoolPro CI #1133 also completed successfully across typecheck, startup/context/role/result/template tests, build and layout checks: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924175053. Payment validation #860 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924175098. These are workflow results for the code state tested before the latest documentation-only commits; they are not proof of complete schema parity or API-level tenant authorization. The behavior matrix evidence boundary was updated in commit e68f2f0edf7a4db137c3538330594de148f1d351. PR #107 remains open/draft/unmerged; no production changes.
- **Routine-definition discovery limitation:** GitHub code search queries for `schoolpro_can_write_result`, `enforce_schoolpro_tenant_relations`, and `schoolpro_can_read_student` returned no results in the accessible default-branch search. The catalog inventory only summarizes these routines and does not include their full definitions. Do not invent definitions or implement a behavior port from names alone. Next step must obtain the source definitions from an authorized read-only schema/migration export or locate the exact migration files in the source repository, then map each definition to its trigger/RPC/app caller and grants.


- **Latest MySQL schema CI confirmation (2026-10-16):** disposable MySQL 8.4 schema run #90 passed on code/test head `e68f2f0edf7a4db137c3538330594de148f1d351`. Logs confirm all nine negative relationship cases were rejected by their expected named foreign keys, including the class/subject/session assignment constraint. Payment validation #868 was in progress and SchoolPro CI #1141 was in progress at the last exact-head check. A later documentation-only commit records the DataSub callback/trigger audit; refresh all workflows for the current head before calling the full migration branch green. This remains schema/relationship evidence only, not API security, feature parity, data migration, or cutover readiness.


- **Live SchoolPro routine/trigger/RLS inspection (2026-10-16):** Used read-only catalog queries against active Supabase project `lnqsroyiybutkfngbyge` (PostgreSQL 17.6.1). Captured 17 critical routine signatures, owner/security/search_path/ACL/definition hashes; 21 selected trigger bindings across result, student/class, document, finance and transcript tables; and detailed RLS policies on key class/student/result/template/finance tables. Added [live-routine-trigger-rls-behavior-snapshot-2026-10-16.md](./live-routine-trigger-rls-behavior-snapshot-2026-10-16.md) in commit 7d7a80a83d7e4acf10ab968412faaf29f4f3c4c4. This was read-only; no production writes or policy changes.
- **Source findings now grounded in live definitions:** result totals are computed from JSON assessment-scheme components while the draft MySQL schema uses normalized component/score tables; results have both workflow and separate lock triggers; student/class/result access depends on role and relationship checks, modules and cached RLS scopes; finance fee triggers sync invoices; result lifecycle writes audit snapshots. Target behavior is not yet implemented or proven equivalent.
- **Business-rule discrepancy to resolve before port:** live `schoolpro_operationally_active(uuid)` grants a 14-day grace only when `amount > 0` and `billing_cycle='annual'`; `enforce_schoolpro_subscription_expiry()` suspends expired trial subscriptions immediately at `renews_at`. This conflicts with the stated product requirement that demo access is annual and receives the two-week grace period. Recorded as a target specification gap only; do not change live production behavior in this pilot.
- **RLS review item:** live `schoolpro_subscription_catalog` includes an authenticated permissive SELECT policy with `USING (true)` alongside active-only SELECT policies. Since permissive PostgreSQL policies OR together, inactive catalog rows may be visible unless a restrictive policy also applies. This is a review item, not a confirmed exploit; inspect intended catalog fields and all policy interactions before any fix.
- **Latest workflow status refresh:** new runs triggered on the latest inspected PR merge ref are still in progress: MySQL schema #91 https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924804331; SchoolPro CI #1142 https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924804962; payment validation #869 https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924804511. Prior run #86, #1133 and #860 passed, but do not substitute those for these current runs. PR #107 remains open/draft/unmerged; no production change.


- **Verification after live-source audit (2026-10-16):** PR #107 head before this handover refresh was `3684ec71513633c31ebb2cdc2a95416e62a9b27e`. Runs triggered for that head completed successfully: MySQL schema #91 https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924804331, SchoolPro CI #1142 https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924804962, and payment validation #869 https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38924804511. Schema logs confirm ten expected named FK rejection assertions on the earlier inspected code run #86; #91 confirms schema/fixture job success, but detailed ten-assertion logs should be used if exact per-constraint evidence is needed. Current commit-triggered runs for the just-inspected head are #95 (MySQL schema), #1148 (SchoolPro CI), and #875 (payment validation) and were still in progress at the last check: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925404852, https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925405426, https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925405025. This entry is a documentation update; do not infer the new commit's CI result from earlier green runs. PR #107 remains draft/open/unmerged and production remains unchanged.


- **Follow-up run completion (2026-10-16):** After the prior status note, MySQL schema workflow #95 completed successfully (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925404852) and payment validation #875 completed successfully (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925405025). SchoolPro CI #1148 was still in progress at the last check (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925405426). These workflows ran against the PR merge ref at the time, before this handover-only refresh. Do not infer CI success for the latest documentation commit from these results.


- **Result-publication contract audit (2026-10-16):** Added [result-publication-contract-audit-2026-10-16.md](./result-publication-contract-audit-2026-10-16.md) in commit 688fd7430b7116fc974a0e2714a95c5e2c19f9da. The report records nine enabled result-table triggers, their names/functions, key RLS effective-policy rules, source score-calculation behavior, and the lock-trigger interaction. It flags the `locked=true → locked=false` path as a static review question only: no exploit has been demonstrated, no write probe was run, and no production policy or data was changed. It defines disposable-clone tests for published/locked edits, score bounds, cross-tenant relations, lifecycle audit, notifications and privileged writers. Target parity remains unverified.
- **Current check refresh:** MySQL schema draft #97 passed https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925590580; payment validation #877 passed https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925590527. SchoolPro CI #1150 remained in progress at last inspection https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925590492. These runs were started before commit 688fd7430b7116fc974a0e2714a95c5e2c19f9da; do not treat them as exact-head CI evidence. PR #107 remains open/draft/unmerged, and production remains unchanged.


## Session continuation — 2026-10-16 (after connection interruption)

### Current migration branch and validation
- PR #107 remains **open, draft and unmerged**: https://github.com/Hassan-625/IHLink-SchoolPro/pull/107.
- Migration branch head at this handover edit: `0f2fd2147440badbd95951d4b595f6c70d916799`.
- Disposable MySQL 8.4 schema workflow #99 **passed** on this exact head: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925934224.
- Payment-page validation #880 **passed** on this exact head: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925934159.
- SchoolPro CI #1153 was still **in progress** on this exact head at handover update time: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925933945. Refresh before describing the complete branch as green.
- Separately, Stage A PR #106 had SchoolPro CI #1145 and payment validation #872 pass on code/test head `3fc09cd2fa0382a15bb48f4e134f0e2cf595df53`; subsequent documentation-only commit `ed7ff4d901bea0606fa778b2e1416b6ee940ea7d` triggered CI #1151 (in progress) and payment validation #878 (passed). Do not conflate the Stage A release branch with the MySQL pilot branch.

### DataSub callback/ledger finding — source review
- Re-read DataSub source migration `supabase/migrations/20260920170000_datasub_provider_operations.sql`, the current `datasub-provider-webhook` Edge Function, `datasub-reconcile`, and `_shared/refunds.ts`.
- The legacy `public.process_datasub_provider_callback` routine is service-role-only in the source migration. It de-duplicates provider event IDs and locks the pending transaction, but on `failed`/`reversed` it directly increments `datasub_wallets.balance` without a matching `wallet_ledger` refund entry, and it does not verify that the supplied provider code matches the transaction's provider. These are high-priority financial-integrity defects **if this RPC is invoked**.
- The checked-in `datasub-provider-webhook` does **not** call this routine; it records a routing event and returns 202, leaving transaction changes to the reconciliation worker. Searches in DataSub, Admin, Design System and SchoolPro source found no direct textual call. This supports “legacy/unreferenced in inspected source,” not proof that no deployed/external service can call it. Do not call this a current public exploit or claim proven reachability.
- Do not port this routine into MySQL/API as-is. Next, create a disposable PostgreSQL regression fixture for duplicate events, provider mismatch, failed/reversed ledger entries and rollback; verify all actual callers/deployment provenance; then design one atomic, idempotent ledger-and-balance transition or formally retire the legacy RPC only after dependency evidence.
- DataSub's current reconciliation/refund code uses `refund_datasub_wallet` with `REFUND:<transaction reference>` idempotency and claims the transaction into `REFUND_PENDING`. Unit tests exist in `IHLink-DataSub/tests/payment-refund.test.ts`, but they do not prove database ledger/lock behavior. The legacy callback RPC must not bypass the canonical refund path.

### Next actions (ordered)
1. Recheck SchoolPro CI #1153 for PR #107 exact head and inspect logs if it fails.
2. Build the disposable PostgreSQL test around the DataSub callback RPC and canonical wallet ledger, without touching production; verify call graph/deployment provenance before proposing a forward migration.
3. Continue DataSub source-to-live mapping for callback queueing, reseller commission and network-availability triggers; retain source SHAs and definition hashes.
4. Continue SchoolPro Stage A separately: full-schema/trigger review, migration source/ledger reconciliation, Storage folder-list performance, result-PIN trusted-network/runtime tests, payment lifecycle/RLS-role tests, and receipt Storage acceptance when valid fixtures exist.
5. Keep MySQL as a disposable pilot only. Supabase remains authoritative; no production data/schema edits, environment changes, deployment, data copy or cutover without explicit approval. Do not merge PR #106 or #107 without explicit approval.

### Safety status
No production schema/data change, production RPC call, wallet mutation, Render/Vercel deployment, environment change, live data copy, or PR merge was performed during this continuation. BillStack remains DataSub-only. SchoolPro production remains on Render.


## Session continuation — 2026-10-16 (CI refresh and DataSub callback provenance)

### SchoolPro migration pilot — exact-head CI refreshed
- PR #107 head at the prior session checkpoint was `0f2fd2147440badbd95951d4b595f6c70d916799`; PR remains open, draft and unmerged: https://github.com/Hassan-625/IHLink-SchoolPro/pull/107.
- MySQL schema draft #99 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925934224. Its disposable MySQL job applied the draft schema, inserted valid isolated fixtures, and verified cross-school enrollment relationships fail on expected foreign keys.
- Payment validation #880 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925934159.
- SchoolPro CI #1153 has now completed successfully: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925933945. Its job passed typecheck, app test scripts (including school context, access cache, roles, result workflow, export, templates and billing visibility), layout checks and build.
- These results are for the inspected prior code/test head, not for this subsequent handover-only update. No one workflow establishes full product parity or re-verifies all Stage A/B/C acceptance criteria.

### DataSub provider callback — migration/deployment provenance refinement
- Read-only live catalog query against shared project `lnqsroyiybutkfngbyge` confirms `public.process_datasub_provider_callback` exists, is owned by `postgres`, is SECURITY DEFINER, and has EXECUTE ACL only for `postgres` and `service_role` (no PUBLIC/anon/authenticated grant in the current catalog result).
- The live migration ledger records `20260920144207 datasub_provider_operations`; the inspected DataSub repository file is `supabase/migrations/20260920170000_datasub_provider_operations.sql`. These timestamps differ. Do not assume they are identical source/deployed migration records: compare migration contents and actual live definition hashes, and locate the deployment source/provenance.
- Repository source review of `supabase/functions/datasub-provider-webhook/index.ts` shows it records a routing event and returns HTTP 202; it does not call the legacy callback RPC. The shared refund path in `supabase/functions/_shared/refunds.ts` claims `REFUND_PENDING`, calls `refund_datasub_wallet` with idempotency reference `REFUND:<transaction reference>`, and only then marks the transaction refunded. Existing `tests/payment-refund.test.ts` tests the application orchestration with a mock database; it is not a PostgreSQL transaction/ledger regression test.
- **Execution limitation:** the available working runtime has Node.js but no `psql`, `postgres`, or `docker` binary, so a genuine disposable PostgreSQL database test was not executed in this session. No production RPC invocation was attempted. The correct next engineering task is to add/run a dedicated CI job using an isolated PostgreSQL/Supabase-compatible fixture, including the minimum real schema/functions and assertions for duplicate event IDs, provider mismatch, failure/reversal ledger entries, transaction rollback and reconciliation idempotency. A mock-only unit test must not be presented as database evidence.
- Until a complete caller/deployment provenance review and regression test are available, treat the legacy RPC as a high-priority unverified legacy path, not a confirmed reachable production exploit. Do not port it into MySQL/API as-is, revoke its live grant, or change production data/schema during this pilot.


### DataSub ledger/refund routine follow-up (2026-10-16)
- Inspected checked-in source migration `20260924210000_datasub_transaction_safety.sql` (blob `0894aece1cbf18e0709bb3d20e31697337ca2e4f`). It defines `public.refund_datasub_wallet(p_user, p_transaction, p_amount, p_reference)` as SECURITY DEFINER with EXECUTE revoked from PUBLIC/anon/authenticated and granted to service_role only.
- The routine first checks whether any `wallet_ledger.reference` matches the supplied reference, then credits `datasub_wallets.balance` and inserts a `refund` ledger row. Its source body does not independently verify that `p_user` owns `p_transaction`, that `p_amount` equals the original reserved transaction amount, that the transaction is in a refundable state, or that the supplied reference is the canonical `REFUND:<transaction reference>` value. Because the function is service-role-only, this is a trusted-caller contract concern rather than evidence of a public-user exploit; all callers must be traced and their argument derivation validated.
- The same migration's `reserve_datasub_wallet` debits the wallet and then inserts a `reserve` ledger row using `ON CONFLICT(reference) DO NOTHING`; review idempotency ordering and balance reconciliation in a disposable database before porting. Do not change live functions based on this source-only observation.
- The provider callback migration source does not append a ledger entry when it directly credits the wallet on failed/reversed transactions. The canonical refund worker does call `refund_datasub_wallet` using the deterministic `REFUND:<transaction reference>` key, but its orchestration mock test is not proof of SQL transaction/ledger correctness.
- **Required disposable PostgreSQL regression coverage:** (1) refund rejects transaction-owner mismatch; (2) refund amount must match the eligible transaction/reservation amount; (3) only an eligible pending/refund state can be credited; (4) deterministic reference makes retries idempotent under concurrent calls; (5) wallet balance delta equals sum of ledger deltas; (6) transaction failure rolls back both balance and ledger; (7) provider callback mismatch is rejected; (8) failed/reversed callback cannot bypass canonical refund; (9) duplicate event and concurrent callback attempts produce exactly one terminal state and one financial effect. Use isolated PostgreSQL CI with minimal faithful schema and actual SQL functions; no local PostgreSQL/docker runtime was available in this session, so these tests are specified but **not yet executed**.
- Migration provenance remains unresolved: live ledger entry `20260920144207 datasub_provider_operations` does not match the timestamp in checked-in filename `20260920170000_datasub_provider_operations.sql`. Compare the live routine definition/hash and the migration's exact deployed source before deciding whether the routine is legacy, remotely modified, or represented by a differently named migration. Do not infer non-deployment from the timestamp mismatch alone.


### Exact-head validation checkpoint (2026-10-16)
- Re-checked pull-request-triggered GitHub Actions for SchoolPro migration handover commit `81d74be819789859371102e52f9d9c4addb468bf`. All three runs completed successfully: [SchoolPro CI #1156](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38926797752), [MySQL schema draft #102](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38926798326), and [payment-page validation #883](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38926797959).
- These results validate the exact handover/docs commit against the existing automated workflows. They do **not** establish that a PostgreSQL database harness ran, that the DataSub callback/refund concerns are fixed, or that the MySQL schema is production-ready.
- PR #107 remains draft/open/unmerged. No production database writes, migrations, deployments, environment changes, or live financial operations were performed.
- Next action: build a dedicated, disposable PostgreSQL CI harness for DataSub refund/callback invariants, using actual SQL functions and a minimal faithful schema. Keep it separate from the SchoolPro MySQL pilot until the shared-Supabase financial contract is evidenced; do not use production RPCs or encode known unsafe behavior as a passing regression test.


### DataSub callback regression harness progress (2026-10-16)
- Opened draft PR #48 in `Hassan-625/IHLink-DataSub`: https://github.com/Hassan-625/IHLink-DataSub/pull/48.
- Added forward migration `20261016160000_datasub_provider_callback_ledger_integrity.sql` on branch `security/provider-callback-ledger-integrity`. It verifies transaction-provider binding, routes failed/reversed callback refunds through `refund_datasub_wallet`, rejects missing reservation evidence without changing transaction/wallet state, retains event de-duplication, and keeps EXECUTE restricted to `service_role`.
- Dedicated PostgreSQL 16 workflow passed on DataSub commit `e4722c17ff6273f99e5c61997af3dac4180d4b93`: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38927261693. Assertions cover failed and reversed refunds, one ledger credit on duplicate event, provider mismatch rejection, missing reservation rejection, rollback atomicity, and function EXECUTE ACLs.
- Evidence boundary: the callback function comes from the proposed migration; the fixture's refund helper is a copy of the read-only live `refund_datasub_wallet` definition observed during this audit, not the complete Supabase migration chain. This is stronger than a mock-only unit test but remains a minimal-schema integration test; concurrent-call tests, complete deployed-schema parity and migration provenance remain outstanding.
- Live provenance still requires reconciliation: the live migration ledger has `20260920144207 datasub_provider_operations`, while the checked-in source file is named `20260920170000_datasub_provider_operations.sql`. No production RPC was invoked, and no live migration/grant/data was changed. Do not merge/deploy PR #48 until call graph, provider codes and deployed definition are confirmed.

### Exact-head status after DataSub test addition (2026-10-16)
- SchoolPro migration handover branch head before this entry: `83fa8b2c354089ed5cbac03aded7979feab84869`.
- The immediately preceding handover commit `81d74be819789859371102e52f9d9c4addb468bf` passed SchoolPro CI #1156, disposable MySQL schema #102 and payment validation #883. The subsequent docs-only head has its own workflow results; recheck after this entry commit before claiming exact-head CI green.
- PR #107 remains open/draft/unmerged. PR #106 remains open/draft/unmerged. PR #48 is also draft/open/unmerged. No production schema/data writes, production RPC calls, wallet mutations, environment changes, deployments, or cutovers were performed.


### PostgreSQL characterization harness opened (2026-10-16)
- Created DataSub branch `audit/postgres-refund-regression-harness` and draft PR [DataSub #49](https://github.com/Hassan-625/IHLink-DataSub/pull/49). This is separate from SchoolPro PR #107 and remains unmerged.
- Added an ephemeral PostgreSQL 16 GitHub Actions workflow at `.github/workflows/postgres-refund-regression.yml`, a minimum disposable fixture at `tests/postgres/00_fixture.sql`, and SQL characterization at `tests/postgres/10_refund_callback_characterization.sql`.
- The job applies the checked-in DataSub provider-routing, transaction-safety, and provider-callback migrations to the ephemeral database, then characterizes two already-documented behaviors: (1) the current refund routine accepts a caller-supplied user/amount/reference that do not match the transaction; (2) the legacy callback directly credits a failed transaction without using the canonical refund ledger path. These are deliberately labelled **known gaps reproduced**, not safe behavior and not fixes.
- **CI status is pending initial run at handover update time.** The harness must first prove that all three actual migrations apply against the minimal fixture. If it fails, inspect and correct fixture/migration compatibility; do not report a successful PostgreSQL test until the workflow finishes green.
- Safety: only the disposable GitHub Actions PostgreSQL service is used. No production Supabase RPCs, production DB writes, migrations, deployments, environment changes, or financial operations were performed. This characterization PR is not a security fix; after hardening the SQL routines, change these checks into regression assertions that unsafe refunds/callbacks are rejected.


### Disposable PostgreSQL harness — first successful run (2026-10-16)
- Updated DataSub PR [#49](https://github.com/Hassan-625/IHLink-DataSub/pull/49), head commit `8251fbd9aa263e4059914f425b961a49916e9ecb`, after the first two CI attempts exposed missing Supabase compatibility prerequisites in the fixture (first roles `anon`/`authenticated`/`service_role`, then schema/function `private.has_product_access`). These were fixture bootstrap errors, not production failures; the fixture now defines the minimum required roles and an authorization stub for policy compilation.
- The disposable PostgreSQL 16 run [#4](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38928193874) completed successfully: fixture creation, application of the three checked-in DataSub migrations, and characterization SQL all passed.
- The successful characterization reproduced two known gaps in the checked-in source: the refund function accepts a mismatched owner/amount/arbitrary reference; and the legacy failed-transaction callback changes wallet balance without inserting a canonical refund ledger row. This is a real PostgreSQL execution of the checked-in SQL in a minimal isolated fixture, but it is **not** proof of full production schema parity, exploit reachability, or remediation. The assertions currently characterize unsafe behavior so CI can establish reproducibility; they must be converted to rejection/safety assertions when the functions are hardened.
- DataSub's broader validation workflow for the same head was still in progress at the time of this update; do not claim it passed until its final result is checked.
- No production Supabase RPCs, database writes, schema changes, deployments, environment changes, or financial operations were performed. PR #49 remains draft/open/unmerged; SchoolPro PR #107 remains draft/open/unmerged.


## 10. Owner decision — platform-specific database strategy (2026-10-16)
- **Confirmed direction:** only **SchoolPro** should move to MySQL. **DataSub and the other existing IHLink platforms should continue using Supabase**; do not expand the MySQL migration into a shared-platform migration.
- Treat the existing shared Supabase project as a cross-platform dependency. Do not rename, migrate, restructure or delete shared tables, Auth, Storage buckets, Edge Functions, RPCs, triggers, or policies on the assumption they belong exclusively to SchoolPro.
- Before any SchoolPro cutover, complete an evidence-backed ownership/dependency map separating SchoolPro-owned data and workflows from shared identity, control-plane and cross-platform dependencies. Design the MySQL API boundary for SchoolPro without redirecting DataSub or other products.
- DataSub work remains a **Supabase security and financial-integrity audit/remediation lane**, not a database migration. Continue testing refund/callback invariants in disposable PostgreSQL CI. Do not use BillStack for anything except DataSub.
- Cutover status is unchanged: SchoolPro's MySQL branch is a draft pilot only. Supabase stays authoritative for production SchoolPro until the owner approves cutover after acceptance gates; no live changes or merges are implied by this architecture decision.
- DataSub validation workflow #322 completed successfully on the inspected head: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38928193831. The separate PostgreSQL characterization workflow #4 also passed: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38928193874. These establish automated checks and reproduction of the documented gaps, **not remediation**.


### Architecture-scope decision and exact-head CI refresh (2026-10-16)
- Owner confirmed the platform strategy: **SchoolPro alone is in the MySQL migration lane; DataSub and the other existing IHLink platforms remain on Supabase.** Updated the handover's non-negotiable rules and added a dedicated architecture decision section in commit `c9197d3f2d641380d372986034575507e1268cde`.
- Exact-head workflows for that SchoolPro docs commit completed successfully: [MySQL schema draft #107](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38928610600), [SchoolPro CI #1161](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38928610643), and [payment-page validation #888](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38928610548). These remain bounded CI checks, not full A/B/C acceptance or production parity.
- DataSub's broader validation #322 and isolated PostgreSQL characterization #4 passed on the prior characterization head. Then, on DataSub draft PR #49, a forward hardening migration and safety assertions were added: migration `20261016180000_datasub_wallet_refund_contract_hardening.sql`; updated disposable fixture/workflow; tests now reject mismatched refund owner/amount/reference, enforce canonical reservation evidence and provider binding, route failed/reversed callbacks through the canonical refund ledger, and check retry/idempotency and role grants.
- DataSub hardening work is still under CI validation at the latest check: [Validate DataSub #326](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38929594672) and [Disposable PostgreSQL refund/callback regression #8](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38929594708). Do not call the hardening verified until both runs finish and any failures are addressed.
- Safety boundary unchanged: DataSub migration exists only on its draft branch; no live Supabase function/migration was run or deployed. PR #49 and SchoolPro PR #107 remain unmerged. Supabase stays production-authoritative; MySQL remains a SchoolPro-only disposable pilot pending explicit cutover approval.


### DataSub refund/callback hardening — isolated PostgreSQL regression passed (2026-10-16)
- DataSub draft PR #49 branch `audit/postgres-refund-regression-harness` now includes migration `20261016180000_datasub_wallet_refund_contract_hardening.sql` (commit currently after the prior characterization head; verify current branch head before further changes).
- Disposable PostgreSQL 16 workflow [run #8](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38929594708) **passed** after applying the three existing checked-in migrations and the new hardening migration, then running the revised safety assertions. Tests reject mismatched refund owner/amount/arbitrary reference, check idempotent reserve/refund retries, require canonical reservation and refund references, ensure failed callback refunds through the ledger, reject provider mismatch and missing reservation evidence, verify duplicate callback has one financial effect, and check function EXECUTE grants.
- This validates the new SQL against the minimal disposable fixture only. It does **not** prove full production-schema parity, concurrency correctness under parallel sessions, the live deployed function hash, or caller compatibility. The broader DataSub validation #326 was still running at the latest check: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38929594672.
- Do not deploy or merge the new migration yet. Next: review exact SQL diff and migration ordering/provenance, add true concurrent refund/reservation tests if feasible, and validate caller/state compatibility against the full DataSub schema. All live Supabase objects remain unchanged.


### DataSub hardening validation — final CI refresh (2026-10-16)
- Follow-up to the preceding checkpoint: DataSub validation #326 has now **passed** as well as disposable PostgreSQL refund/callback regression #8. Links: [DataSub validation #326](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38929594672), [PostgreSQL regression #8](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38929594708).
- The new hardening migration remains on DataSub draft PR #49 only. It has not been deployed to Supabase. Passing CI does not establish full live-schema compatibility or safe parallel/concurrent behavior; those are required before merge/deployment consideration.
- Keep next actions focused on: (1) validate function contracts against every actual caller and the live deployed routine definition, including the migration-ledger timestamp mismatch; (2) add multi-session concurrency coverage for simultaneous reserve/refund/callback retries; (3) run tests against a fuller disposable schema that matches the real DataSub tables, triggers, constraints and enum/status values; (4) review the SQL diff and PR #49 without merging. Do not mutate live Supabase or perform financial operations during this audit.


### DataSub simultaneous-refund regression — passed (2026-10-16)
- Added a disposable PostgreSQL test that invokes the same canonical refund from **two independent PostgreSQL sessions at the same time**, with a test-only delay widening the race window. It asserts the wallet receives exactly one credit and exactly one refund ledger row is created.
- The expanded PostgreSQL regression workflow [run #10](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38929979304) passed all steps, including applying the actual checked-in migration chain used by this fixture, the refund/callback safety assertions, and the concurrent-session test.
- Scope caveat: this is targeted concurrency evidence for two simultaneous retries of the same refund on the minimal fixture. It is not a full load/concurrency campaign across reserve-vs-refund, callback-vs-reconciliation, all provider outcomes, or production triggers/constraints.
- The new migration and test remain on DataSub draft PR #49. No live Supabase object was changed, and no PR was merged. Before deployment consideration, still verify the live function definition/provenance and every caller against the full schema, then expand race tests for competing reservation and callback/reconciliation transitions.


### DataSub caller-contract review found and corrected two pre-merge compatibility issues (2026-10-16)
- While reviewing the hardening SQL against the checked-in legacy callback and finalizeRefund helper, I found two issues in the initial draft before any deployment:
  1. The callback accepted reversed but mapped the transaction's terminal status to failed, losing the provider's distinct reversed state.
  2. Reservation idempotency was checked only after requiring routing_state='ROUTING', which could reject a legitimate retry after the transaction advanced.
- Corrected both on the DataSub draft branch: the callback now preserves normalized_status (including reversed) while setting routing_state='REFUNDED'; exact prior reservation retries are checked before the routing-state guard. Provider comparison now uses IS DISTINCT FROM to fail closed for null/mismatched provider values.
- Added regression assertions for reversed-state preservation and reservation retries after routing advances. Fresh CI runs are queued: [DataSub validation #330](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38930599867) and [PostgreSQL regression #12](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38930599823). Wait for these results and resolve any failure before further hardening.
- This demonstrates why the migration remains draft: passing earlier tests did not guarantee all business-state semantics. Still outstanding: full live routine/source provenance, all callers and enum/state compatibility, richer schema parity, concurrency across reservation/refund/callback/reconciliation, and complete diff review. No live Supabase mutation or deployment occurred.


### Regression follow-up — SQL quoting defect found and corrected (2026-10-16)
- The first run after adding reversed-state assertions failed at the test-script layer, not in the migration: malformed dollar quoting in the new DO block caused a PostgreSQL syntax error after the preceding refund/callback assertions had passed. The run is recorded transparently as failed: [PostgreSQL regression #12](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38930599823).
- Corrected the test script's dollar-quoted blocks in DataSub commit `9eb18f310dd1c3aeac058a8bfecf8cd641978b84`. The next isolated PostgreSQL run is queued: [regression #15](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38930875049). Do not treat the latest test suite as passing until this run finishes successfully.
- The broader DataSub validation #330 had passed all completed unit/type/security/build steps at last inspection; final run completion was still in progress. The production database remains untouched.


### Regression syntax fix verified (2026-10-16)
- DataSub PostgreSQL regression #15 passed: [workflow run #15](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38930875049). All steps completed successfully, including applying the existing migration chain plus the hardening migration, the revised owner/amount/reference checks, reversed-status preservation, reservation retry after routing advances, provider-binding/missing-reservation checks, and simultaneous refund retries from two PostgreSQL sessions.
- DataSub validation #330 also completed successfully: [workflow run #330](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38930599867).
- The previous run #12 failed due to malformed dollar quoting in the added test block; this was corrected and #15 is the successful rerun. Keep the failure visible in history rather than describing every run as green.
- New SchoolPro handover commit checks were queued at last inspection: [SchoolPro CI #1167](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38930929281), [MySQL schema draft #113](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38930929788), [payment-page validation #894](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38930929286).
- Status remains draft/pre-merge. Passing tests are still against a minimal disposable fixture; no live Supabase object was changed and no deployment or merge occurred.


### Latest CI verification and DataSub live-catalog provenance (2026-10-16)
- SchoolPro CI #1167 completed successfully, including TypeScript checks, school context/tenant-related tests, role/workflow tests, template preview, billing visibility, account access, and production build: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38930929281
- SchoolPro MySQL schema draft #113 passed against disposable MySQL: schema applied, valid isolated fixtures inserted, and cross-school enrollment foreign-key checks failed as expected: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38930929788
- SchoolPro payment-page validation #894 passed TypeScript and production build: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38930929286
- Read-only Supabase catalog verification for DataSub project `lnqsroyiybutkfngbyge` confirms the deployed callback signature exactly matches the checked-in eight-argument routine; it is SECURITY DEFINER, owned by postgres, and EXECUTE is limited to postgres/service_role (anon and authenticated are denied). The live enum labels are exactly `pending`, `success`, `failed`, `reversed`. The checked-in hardening migration therefore matches the observed routine signature and enum labels, but remains un-deployed.
- The live callback body still directly updates the wallet balance for failed/reversed outcomes without inserting a matching `wallet_ledger` refund row. This supports the priority of replacing that legacy path with the canonical ledger-backed refund; it is not evidence that an untrusted role can invoke the RPC, since the current ACL is restricted.
- Live migration ledger reports `20260920144207`, while the checked-in source migration is named `20260920170000_datasub_provider_operations.sql`. Treat this as a provenance/timestamp discrepancy to reconcile against the deployed migration body/hash, not proof that the routine is absent or that the migration failed.
- These catalog checks were read-only. No production function, table, policy, wallet, transaction, migration, or deployment was changed.
- Current evidence remains bounded: SchoolPro MySQL schema validation is a draft-schema CI check, not a migration/cutover; DataSub refund regressions use a minimal disposable PostgreSQL fixture, not a full clone of the live production schema. PR #107 and DataSub PR #49 remain draft/unmerged.


### Additional DataSub concurrency coverage in progress (2026-10-16)
- Expanded the disposable PostgreSQL regression to exercise two independent sessions attempting the same canonical wallet reservation concurrently. The expected invariant is one debit and one `reserve` ledger row, with the retry returning idempotently after it acquires the transaction lock.
- New setup file: `tests/postgres/21_concurrent_reserve_setup.sql`; workflow update adds the simultaneous reservation race before the existing concurrent refund race.
- Fresh checks are queued: [DataSub PostgreSQL regression #17](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38931700923) and [DataSub validation #335](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38931700943). Do not count the new race assertion as passed until #17 completes.
- The latest SchoolPro checks noted above passed, including the disposable MySQL schema/tenant foreign-key tests and payment-page build. The master handover change itself will trigger another CI cycle; the MySQL foundation remains a partial draft, not a complete port.


### Concurrent reservation regression result (2026-10-16)
- DataSub PostgreSQL regression #17 passed with both new race paths: two simultaneous reservations of one transaction produced a single wallet debit and single reserve ledger row; two simultaneous refunds produced a single wallet credit and single refund ledger row. All migration application and contract assertions in the disposable fixture also passed: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38931700923
- DataSub validation #335 was still running at the time of this update; the test/type/security steps passed, with layout and build steps pending. Recheck final conclusion before treating the whole validation workflow as green.
- This is specific concurrency evidence for duplicate reservation/refund retries, not proof for all interleavings with provider callback and reconciliation workers. The live project remains unchanged.


### DataSub broader validation completed; callback race test added (2026-10-16)
- DataSub validation #335 completed successfully, including tests, typecheck, native-entry/browser-vault/idle-lock/PIN recovery checks, layout checks and production build: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38931700943
- Added a further disposable PostgreSQL race test that runs a success callback and a reversed callback concurrently for the same reserved transaction. Accepted outcomes are deliberately order-dependent, but must be internally consistent: success + SETTLED + one reservation debit/no refund, or reversed + REFUNDED + exactly one refund ledger row and restored balance.
- New setup file: `tests/postgres/22_callback_race_setup.sql`; workflow step races two separate psql sessions. Results are pending: [DataSub PostgreSQL regression #19](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932062420) and [DataSub validation #337](https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932062470).
- Previous SchoolPro handover-triggered checks #116, #1170, #897 were still running at last inspection; schema draft and payment-page validation steps had passed, while full SchoolPro CI was finishing layout/build. Recheck before marking the cycle green.
- No production changes. DataSub tests use disposable PostgreSQL with a minimal fixture; the callback/reconciliation race coverage remains targeted and is not full production-schema parity.


### Provider callback terminal-state race regression passed (2026-10-16)
- DataSub PostgreSQL regression #19 passed, including the new simultaneous success-versus-reversed callback race plus concurrent reserve and refund retry tests: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932062420
- The callback race assertion accepts only coherent lock-order outcomes: either success/SETTLED with one reservation debit and no refund, or reversed/REFUNDED with exactly one refund ledger row and restored balance. The test passed against the disposable PostgreSQL fixture.
- DataSub validation #337 was still in progress after unit/type/security checks passed; layout/build remain pending at this timestamp. Recheck before final green status: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932062470
- SchoolPro CI #1170 completed successfully, including application tests and build. New handover-triggered checks #1172/#118/#899 are running; the earlier #1170 run passed before the latest documentation-only update.
- This does not yet test every callback-versus-reconciliation implementation or use a full clone of production schema. No live database changes, deployment, or merge.


### Reconciliation caller review and stale-write regression (2026-10-16)
- Inspected DataSub's actual `datasub-reconcile` edge function, shared `finalizeRefund`, provider status normalizer and webhook receiver. Reconciliation reads pending `RECONCILING`/`REFUND_PENDING` rows, then uses conditional state updates; failed outcomes funnel through canonical `refund_datasub_wallet`. Provider webhook currently records receipt and intentionally defers state changes to authenticated reconciliation/provider lookup.
- Added `tests/postgres/23_stale_reconciliation_after_callback.sql`: a provider success callback settles a reserved transaction, then a stale reconciliation failure write using its old `status=pending, routing_state=RECONCILING` snapshot must update zero rows, leave balance debited once, and create no refund ledger entry.
- Added this test to the disposable PostgreSQL workflow. New regression run is pending: Regression run #21 is in progress: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932488323. DataSub validation #339 is also in progress: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932488193.
- Confirmed latest DataSub validation #337 passed, including app tests, typecheck, security checks, mobile layout checks and build: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932062470
- SchoolPro MySQL schema draft #118 and payment-page validation #899 passed; SchoolPro CI #1172 was still in progress at last poll. These checks validate the migration draft and existing app, not a production migration.
- No production changes, deploy, merge or cutover. DataSub remains Supabase; SchoolPro MySQL remains draft-only.


### Stale reconciliation regression: first run failed due to fixture setup; corrected and rerunning (2026-10-16)
- DataSub validation #339 passed fully: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932488193
- PostgreSQL regression #21 failed at the new stale-reconciliation test. Log review identified a test-fixture defect, not evidence of a production-code defect: the test inserted the transaction in `RECONCILING` before calling `reserve_datasub_wallet`, but the hardened reservation contract correctly requires `ROUTING`. Reservation therefore returned false and the test's expected balance invariant was invalid.
- Corrected `tests/postgres/23_stale_reconciliation_after_callback.sql` to reserve while in `ROUTING`, then move the test transaction to `RECONCILING` before applying the success callback. Rerun triggered from DataSub commit `3487014ef724e57c232fa63851575f8f3a0bd736`; pending result must be verified before claiming pass.
- SchoolPro MySQL schema draft #120 passed disposable schema application and cross-school FK rejection checks: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38932526151
- SchoolPro payment-page validation #901 passed typecheck/build: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38932526173
- SchoolPro CI #1174 remained in progress at last poll; app tests had passed, layout check/build pending: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38932526176
- No production changes, deployment, merge, or cutover.


### Corrected stale reconciliation regression passed (2026-10-16)
- DataSub PostgreSQL regression #22 passed all steps, including hardened SQL migration application, callback/refund safety assertions, stale reconciliation write rejection after callback settlement, concurrent success-versus-reversed callbacks, and simultaneous reservation/refund retries: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932887542
- This validates the corrected test fixture and conditional-write invariant on the disposable minimal PostgreSQL schema. It does not constitute full production-schema parity or an end-to-end test of a running scheduled worker.
- DataSub validation #340 remains in progress; tests, typecheck and security checks passed, with mobile layout and build steps still running: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38932887787
- SchoolPro CI #1174, MySQL schema draft #120, and payment-page validation #901 all passed. This validates the app checks and draft schema only; migration/cutover remains unapproved.
- No production database changes, deployment, merge, or cutover.


### DataSub callback/refund ordering review — 2026-10-16
- The refund helper claims REFUND_PENDING, invokes a wallet-refund RPC, then makes a separate request to mark the transaction failed/refunded. This creates a timing gap after wallet credit commits but before transaction finalization.
- The callback SQL success path checks pending status but does not first check whether the canonical refund ledger entry already exists. A late success callback in that gap may cause status/balance disagreement. This is a code-review finding, not a confirmed production incident.
- Added disposable test tests/postgres/24_late_success_after_refund_credit.sql and workflow step. Regression #24 and validation #342 are running: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38933498680 and https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38933498684.
- Next fix should make an existing canonical refund ledger row authoritative over late success, then verify callback event audit and retry behavior. No production changes, deployment, merge, or cutover.


### Confirmed DataSub late-success/refund split-state defect in draft regression (2026-10-16)
- Disposable PostgreSQL regression #24 failed as intended and confirmed the race: after the canonical refund RPC credited the wallet, a late success callback left transaction status=success and routing_state=SETTLED while the refund ledger row still existed and the wallet balance was restored. This is a confirmed defect in the draft SQL path under test, not evidence of a production incident.
- Evidence: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38933498680. The failure was exactly: status success, routing SETTLED, balance 70, refunds 1.
- Root cause: refund wallet credit and Edge Function transaction finalization are separate requests; callback success does not check for the canonical refund ledger row before settling.
- Required correction: under the callback's transaction-row lock, check for the exact canonical refund ledger row before success handling; if present, retain/restore failed + REFUNDED and record the event as late-after-refund rather than marking success. Add assertions for both status and wallet/ledger consistency, then rerun the full disposable suite.
- Attempted to apply the corrective SQL patch through the connected GitHub file-update action, but the action blocked the write. No patch was applied; this remains an open blocker, and should not be represented as fixed. DataSub validation #342 was still running at last check: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38933498684.
- SchoolPro master handover updated on this branch to retain the finding. No production database changes, deployment, merge or cutover.


### DataSub validation #342 final result (2026-10-16)
- DataSub validation #342 completed successfully, including app tests, typecheck, native/browser security checks, PIN recovery, mobile layout checks, and build: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38933498684.
- This passing app validation does not override the separate failing SQL race regression #24. The late-success-after-refund defect remains open until a corrective SQL change and passing PostgreSQL regression are available.


### DataSub corrective migration added on draft branch (2026-10-16)
- Added forward migration `20261016193000_datasub_late_refund_callback_guard.sql` to the DataSub draft branch. It replaces `process_datasub_provider_callback` so the callback, while holding the transaction row lock, checks for the exact canonical refund ledger entry before terminal success handling. If the refund is already credited, it retains/restores `failed / REFUNDED` and marks the callback event `late_after_refund` rather than settling success.
- Updated `.github/workflows/postgres-refund-regression.yml` to apply this forward migration after the draft hardening migration and before running the disposable PostgreSQL regression suite.
- This is draft branch code only. The prior regression #24 demonstrated the bug (`success / SETTLED` while one refund ledger row existed); the new correction is not considered validated until the rerun passes. No production migration or deployment.
- DataSub validation #342 passed independently: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38933498684. Keep the SQL regression result separate from application CI status.


### Draft corrective migration follow-up: provider-event enum constraint (2026-10-16)
- The first rerun after adding `20261016193000_datasub_late_refund_callback_guard.sql` reached the new guard, but the regression failed because `late_after_refund` is not an allowed value for `datasub_provider_events.processing_result` (CHECK constraint). This is a compatibility defect in the patch, not a failure of the refund-state guard itself.
- Added `20261016200000_datasub_late_refund_event_status_compat.sql`, which retains the late-refund protection but records the ignored late callback using the already-supported `duplicate` processing result. Updated the disposable workflow to apply it after the prior draft migrations.
- Next validation is pending on the new commit; do not call the correction complete until regression #24 and the full remaining SQL suite pass. No production migration or deployment.


### DataSub regression #28 passed (2026-10-16)
- Disposable PostgreSQL refund/callback regression #28 passed: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38934448071. The late-success-after-refund test and the other SQL regression steps passed.
- The first guard draft used an unsupported provider-event result value. The follow-up draft migration now uses the existing allowed `duplicate` value. Regression confirms the refunded transaction is not settled as successful and wallet/ledger state remains consistent.
- DataSub application validation #346 was still in progress at last poll: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38934447658. Draft-only; no production migration or deployment.


### DataSub application validation #346 passed (2026-10-16)
- DataSub validation #346 passed: https://github.com/Hassan-625/IHLink-DataSub/actions/runs/38934447658. Application tests, typecheck, security checks, mobile layout checks and build passed.
- Current draft status: PostgreSQL regression #28 passed and application validation #346 passed. The new callback guard and compatibility migration are on the audit branch only; production remains unchanged and owner review is still required before merge/deploy.


## SchoolPro priority reset — next active workstream (2026-10-16)
**Owner direction:** Pause additional DataSub work unless a blocker affects the SchoolPro priority. Continue SchoolPro audit and completion first. DataSub's draft regression #28 and validation #346 are recorded above; no production changes were made.

### Immediate sequence (do not skip gates)
1. **Re-verify A — authentication and tenant isolation on the active SchoolPro code path.** Re-fetch the active release/stage-A branch, current Render production commit and CI results. Verify owner/director/proprietor/board/exam officer/staff/student and platform super-admin paths, school context switching, invitation/first-login/password-change/expiry, role restrictions, inactive accounts, and cross-school database/storage denial. Distinguish code/CI evidence from owner-run live sign-in evidence. Do not change production credentials or data.
2. **Re-verify B — academic sessions, student population and class rosters.** Read-only inspect IHLink Academy's existing demo workspace. Confirm sessions 2001–2002 through 2025–2026 plus 2026–2027 next, class roster/student links and counts, no cross-school links, and no operational data seeded into customer workspaces. Resolve the previously observed Basic 5 A First Term 2025/2026 anomaly: 40 students/400 results but 37 subject records linked to Basic 4 A subject IDs and 3 to Basic 5 A IDs. Never repair production data without a separately reviewed and explicitly approved repair plan.
3. **Re-verify C — assessment entry, score calculation, class averages, review and publication.** Ensure each assessment (entrance/assignment/CA/exam) can be selected, entered and saved independently; no forced all-at-once workflow; score bounds and total calculation are correct; class subject average is displayed once; form master/coordinator edit-before-publication requirements, exam officer review/publish, correction-after-publication and audit history are enforced; fetch only selected class/session/term, not whole-school result sets. Include role and cross-school negative tests.
4. **Only after A/B/C pass, resume D — Result Design Studio and custom Excel workbooks.** Section-specific Nursery/Primary/JSS/SS standards, upload/preview/mapping, logo/signatory, custom workbook import/export, no global template overwrite, and A4 print verification (previously deferred).
5. **After A–D parity, finish MySQL migration foundation.** Complete table/source-to-target map, API authorization contract, all trigger/RPC/view/storage/scheduled-job parity, subscription/receipt flows, disposable integration tests, representative synthetic data migration, backup/restore and rollback rehearsal, and load/performance tests. Existing MySQL schema CI is only a foundation check; no production cutover until owner approval.

### Known outstanding SchoolPro blockers / acceptance requirements
- Complete source-to-live parity inventory: all 293 RLS policies, triggers, routines, grants, Storage policies/buckets, deployed Edge Function versions, scheduled jobs, and application call sites. Current targeted snapshots are incomplete and cannot certify parity.
- Subscription/demo mismatch: user rule is annual demo/annual paid plans with two-week grace and no paid amount shown while demo is active. Live operational-active and expiry routines appear inconsistent (grace only for positive annual amount; trial may suspend at renew time). Specify desired state machine and test it in disposable fixtures before proposing a production change.
- Confirm whether permissive authenticated SELECT on `schoolpro_subscription_catalog` exposes inactive plans in combination with other policies; verify effective policy behaviour, do not label it an exploit without proof.
- Result calculations/workflow: reconcile JSON assessment schemes versus normalized MySQL components, trigger ordering, result-lock behaviour, correction/reopen audit reason, transactional lifecycle/email outbox and privileged-writer behaviour.
- Billing: maintain SchoolPro subscription receipt upload + IHLink admin verification and school-fee receipt/admin workflow; BillStack is DataSub-only. Verify receipt-path ownership, invoice locking, duplicate submission/idempotency and annual subscription/grace rules.
- Data integrity: plan a read-only diagnostic for the Basic 5 A/Basic 4 A subject-ID mismatch; no automatic cleanup or guessed reassignment.
- UX/business rules: no visible “Testing” labels; one assessment saved at a time; class averages shown once; avoid whole-school fetch; no first-use web passcode for students; keep mobile passcode/fingerprint/wallet PIN mobile-only; no IH Academy operational records in new customer workspaces.
- MySQL pilot remains incomplete: current draft schema covers only a subset of features and tests only selected constraints. Auth, APIs, complete data migration, storage, host fit, recovery, performance, rollout and rollback are not accepted.

### Execution reporting rules
- For each A/B/C/D item, record the exact branch/commit, CI run, test coverage, failures and owner-confirmation dependency. A passing CI run on the migration branch is not evidence that Render production runs that commit.
- First next task: verify current active SchoolPro release/stage-A branch, Render commit and latest relevant CI; then produce the A/B/C evidence checklist and work through failed/missing evidence before touching D.
- Production Render and Supabase remain unchanged. No merges, migration writes, environment changes, or cutover without explicit owner approval.


### SchoolPro priority audit — exact active release and Render state (2026-10-16)
- Owner priority confirmed: SchoolPro is the active workstream; pause further DataSub follow-up unless it blocks SchoolPro.
- Read-only Render inspection confirms the production static site service `srv-db0k11m0tbcc7386fmq0` uses repository `Hassan-625/IHLink-SchoolPro`, branch `main`, auto-deploy enabled, URL https://ihlink-schoolpro.onrender.com. Current live Render deploy is commit `29856dff17ea8a3bc8bb31b7900967b7df9d316b` (2026-10-13, “Fix Results portal session selection and roster access”). This is not the Stage A branch. No deploy was triggered.
- Current Stage A branch head inspected: `ed7ff4d901bea0606fa778b2e1416b6ee940ea7d`; PR #106 is open, draft, unmerged: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106. SchoolPro CI #1151 passed all three jobs and payment validation #878 passed on that docs-only descendant: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925885963 and https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38925886013.
- Important release distinction: passing draft CI does not mean Stage A is live on Render or merge-ready. The Stage A release gate explicitly remains blocked on full-schema/trigger-order review, migration source/ledger reconciliation, Storage folder-list performance, result-PIN cooldown runtime + trusted gateway client-IP verification, payment lifecycle/concurrency tests, and receipt Storage isolation tests. Existing exact-object Storage isolation success does not clear the folder-list timeout or untested receipt-object isolation.
- Immediate next work is A only: inspect the current Stage A code and release gate, close those blockers one by one with disposable/runtime evidence, then re-verify auth and tenant boundaries. Do not start B until A is approved, merged, and post-merge verified. After that, address B and C before D as requested.
- Stage B/C work remains outstanding: B requires read-only validation of sessions, student population and class rosters, including the known Basic 5 A subject-ID mismatch; C requires assessment-by-assessment save, calculation/average, review/publish, correction/audit, role-denial and scoped-query acceptance. D (Result Design Studio/custom Excel and A4 print) remains gated.
- This inspection did not access or modify production student records, apply SQL, change environment variables, merge PRs, or deploy code.


### Stage A code-review pass — payment RLS and result-PIN limiter (2026-10-16)
**Review scope:** PR #106 draft migrations and their current regression tests. This was static source review only; no database was changed.

1. **Payment review write boundary is not proven by the current test.** `scripts/test-schoolpro-payment-review-write-controls.mjs` uses source-text assertions only; it does not instantiate the real table grants and full set of permissive/restrictive policies or attempt INSERT/UPDATE/DELETE as authenticated roles. PostgreSQL permissive policies OR together, while restrictive policies AND with the permissive result. Therefore the new restrictive policy does not by itself prove that finance users cannot directly mutate submission/allocation/proof rows: the draft explicitly allows the finance-module predicate in `USING` and `WITH CHECK` for those rows. It also permits a guardian-owned submission row to pass `WITH CHECK` while the submitter remains linked; this alone does not constrain mutable columns such as status/amount/receipt path. Treat direct-write denial and immutable review fields as **unverified and potentially incomplete**, not as a passed security control. Before approval, inventory the full current policy/grant set and run a disposable PostgreSQL RLS test with guardian, school-finance, Super Admin and service-role contexts. Verify that review state/amount/allocation changes can occur only through the intended locked RPC, while approved school-side payment recording remains functional. If necessary, redesign as command-specific policies/grants rather than one broad `FOR ALL` policy.

2. **Result-PIN rate limit has an unresolved network-identity trust dependency.** The draft chooses `x-forwarded-for` before `cf-connecting-ip` and `x-real-ip`. A caller-controlled forwarded header would let an attacker rotate the limiter key; trusting a gateway header without proving it is sanitized is also unsafe. No trust guarantee has been established by this review. Keep this migration draft-only until gateway header behavior is documented and runtime-tested. If a trustworthy client identifier cannot be established, use a server-controlled edge/gateway-derived key or a conservative fallback design; do not claim IP-scoped brute-force protection is effective yet.

3. **Operational tenant-integrity trigger migration remains only partially proven.** The disposable integration script covers the newly added tables/relationships, but it is not the complete live schema and does not prove coexistence with every existing trigger or legacy workflow. Review trigger names/order, table columns, relation lifecycle (including legitimate transfers), lock ordering/deadlock behavior and existing source/ledger discrepancies before any rollout. Do not apply this to production as part of this review.

**Next Stage A action:** close the payment RLS gap with a real-role disposable database test and correct command-specific boundaries if the test confirms broad direct writes; separately establish a trusted rate-limit network key. Re-run all CI against the resulting exact head and update the release gate. Stage A remains **NOT MERGE-READY**. No production migration, data write, merge or Render deployment occurred.


## 6. Explicit answer: SchoolPro MySQL migration completion status (reviewed 2026-10-16)
**Decision: NOT COMPLETE. No production cutover is approved.** The MySQL work is an isolated schema foundation/pilot, not a complete database migration or an application running on MySQL.

Verified repository evidence at this review:
- The only file surfaced in `database/mysql/` is `001_schoolpro_core.sql`; it is a core tenancy/academic/results foundation and not a complete schema for all live SchoolPro modules.
- `docs/database-migration/mysql-migration-checklist.md` still has its source inventory, host readiness, server-side API/auth, academic/results parity, finance/module parity, rehearsal/performance, and cutover checklists unchecked.
- `docs/database-migration/mysql-schoolpro-design.md` explicitly states the first SQL migration implements only the core foundation and that the current browser client still uses `@supabase/supabase-js`; an authenticated server-side API and controlled identity migration/reset strategy are still required.
- Draft PR #107 remains open, draft and unmerged. It is not production release approval.
- Prior evidence only demonstrates disposable MySQL 8.4 schema validation and ten cross-tenant/relational negative assertions on the foundation. That does not prove application feature parity, source-data reconciliation, runtime authorization, or readiness to cut over.
- No approved production record transfer, Render environment change, production deployment or cutover has occurred. Supabase remains SchoolPro's production source of truth.

### MySQL work remaining before cutover
1. Finish the full live source inventory and source-to-target map: all SchoolPro tables/columns, constraints/indexes, policies/grants, triggers/routines/views, Storage buckets/object ownership, scheduled jobs, Edge Functions and frontend/server call sites; reconcile the applied migration ledger against deployed definitions.
2. Expand the MySQL schema beyond the current core foundation to cover every in-scope live module and relationship, including identity/membership/permissions, full assessments/results lifecycle, finance and subscription proofs, admissions, attendance, assignments, CBT, templates/workbooks, documents, notifications and operational modules confirmed by the inventory.
3. Implement the authenticated server-side API and authorization boundary. Test every endpoint/object family for school-to-school denial, school-scoped roles and platform Super Admin behavior. Browser/mobile clients must never receive MySQL credentials.
4. Decide and test the identity/session migration strategy; Supabase Auth password hashes/sessions are not assumed portable.
5. Implement feature/behavior parity for A, B and C and then D: individual assessment save; score/grade/average calculations; review/publication/correction history; section-specific school-owned templates and custom Excel mapping; A4/PDF output; annual demo/paid subscriptions, two-week grace/suspension rules, SchoolPro receipt upload/admin verification, and school-managed fee receipts. BillStack stays DataSub-only.
6. Run a controlled synthetic or separately approved anonymized data rehearsal with deterministic ID mapping, row-count reconciliation, duplicate/orphan/cross-school checks, financial/result aggregate checks, exclusions report and report-output comparisons. Do not copy live data until separately approved.
7. Test concurrency/transaction behavior, representative load and p50/p95/p99 latency; complete backup/restore and rollback drills; confirm target host's MySQL version, actual database quota, connection/runtime limits, TLS, SaaS terms and backup/restore capability.
8. Pass the full acceptance suite in disposable/staging environments, obtain security/performance sign-off and explicit owner approval. Only then plan a separate cutover; retain Supabase through the agreed rollback window.

### Next execution order
Keep SchoolPro priority. Continue the Stage A security gates (first, real-role payment RLS integration tests and trusted result-PIN network identity) without production writes. In parallel, continue MySQL source/target inventory and core-schema gap mapping on the migration branch. Do not represent the MySQL migration as done until all items above have evidence and cutover is explicitly authorized.


### Follow-up artifact: concrete MySQL schema gap audit (2026-10-16)
Created [mysql-schoolpro-schema-gap-audit-2026-10-16.md](./mysql-schoolpro-schema-gap-audit-2026-10-16.md) at commit `a833a5c03de881827a19198f607ba199e7bdd25e`. It enumerates the 20 tables currently present in `database/mysql/001_schoolpro_core.sql` and identifies missing/unfinished schema and application domains: template/workbook mapping, finance/subscriptions, guardians, broader operations, storage, full routines/jobs/API authorization, data reconciliation and recovery. This is an inventory artifact, not implementation completion. The migration remains incomplete and cutover is not authorized.



### Stage A payment RLS follow-up — disposable runtime test still required (2026-10-16)
- Rechecked PR #106: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106 remains open, draft and unmerged at inspected head `ed7ff4d901bea0606fa778b2e1416b6ee940ea7d`. Stage A CI #1151 and payment validation #878 passed, but neither proves real-role payment RLS behavior.
- Static review of `supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql` found a remaining test gap: the restrictive `FOR ALL` policies narrow access but do not independently grant/deny commands. Guardian `WITH CHECK` predicates can still match a guardian-owned row; the current source-text test does not prove review-controlled columns (status, amount, allocation/invoice links, school/student ownership, receipt object path) cannot be directly changed under the complete effective grants and policy set.
- This is **not confirmed as a production exploit**: effective behavior depends on all permissive/restrictive policies, grants, roles and RPC execution. The correct next step is a disposable PostgreSQL integration fixture exercising actual INSERT/UPDATE/DELETE as guardian, school finance, platform Super Admin and authorized RPC/service context, including cross-school denials and successful intended payment flows.
- Detailed static findings and exact acceptance assertions recorded on Stage A branch in [stage-a-payment-rls-review-2026-10-16.md](https://github.com/Hassan-625/IHLink-SchoolPro/blob/release/stage-a-auth-tenant-isolation/docs/security/stage-a-payment-rls-review-2026-10-16.md), commit `409f9a31d0869802413b615766beea3098f9b0fe`.
- MySQL branch recheck: schema draft CI #135 passed on commit `0671addfcfae7e86a0a5daaa0eeebc18e90a9a8f` (https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38943731364). This remains schema-foundation validation only and does not change the NOT COMPLETE migration status.
- Production remains unchanged: no SQL against production, no record migration, no environment change, no merge, and no Render deployment. Stage A remains not merge-ready; A/B/C gates remain before D.


### Continuation session — re-read handover and resume from payment-RLS blocker (2026-10-16)
**Scope of this continuation:** read the existing master handover on `migration/mysql-schoolpro-foundation`, re-check both relevant open PRs, and inspect the exact Stage A payment-policy migration and its test. Existing sections and the A–J roadmap are retained; this is an additive status entry, not a replacement or reduction of prior requirements.

#### Verified current state
- Master handover read from `migration/mysql-schoolpro-foundation`; the existing document contains 674 lines before this continuation update and retains the prior ecosystem inventory, migration backlog, SchoolPro A→B→C→D gate, and DataSub-only notes.
- PR #106, Stage A security hardening, is still **OPEN / DRAFT / UNMERGED**. Its latest PR metadata reports head `409f9a31d0869802413b615766beea3098f9b0fe`, not the older head quoted in some earlier handover entries. Treat the PR's current metadata as the reference and refresh it again before any release decision. PR: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106
- PR #107, MySQL migration foundation, is still **OPEN / DRAFT / UNMERGED**. It is a separate migration workstream and must not be confused with the Stage A release branch. PR: https://github.com/Hassan-625/IHLink-SchoolPro/pull/107
- Re-read `supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql` and `scripts/test-schoolpro-payment-review-write-controls.mjs` on the Stage A branch. The current test uses Node source-text assertions; it does not instantiate PostgreSQL grants/policies and does not execute attempted writes as authenticated roles. This confirms the documented evidence gap remains open.
- The current policy migration recreates restrictive `FOR ALL` policies on payment submissions, allocations, proofs and fee payments. These restrictive policies are not standalone grants; effective access depends on the full permissive policy set, table grants, role attributes, and RPC execution privileges. Static inspection alone cannot prove that review-controlled fields are immutable or that intended payment flows remain functional.
- The current Stage A PR description still records the known blockers: full-schema/trigger-order review, migration provenance, Storage folder-list performance and receipt-object isolation, result-PIN cooldown/concurrency and trusted gateway identity, and payment lifecycle/direct-write/concurrency tests.
- The current PR #106 metadata records CI #1151 and payment validation #878 as passing on a previously inspected commit. Do not state these validate a newer head unless a fresh check confirms the exact SHA. A queried combined status for older SHA `ed7ff4d901bea0606fa778b2e1416b6ee940ea7d` reports a Vercel check only; it is not a substitute for the full required CI suite and does not establish that Stage A is deployed to Render.
- The MySQL branch's schema workflow currently applies `database/mysql/001_schoolpro_core.sql` to disposable MySQL 8.4 and runs synthetic relationship-negative tests. Its own workflow comments and migration checklist make clear that this is schema/constraint foundation evidence only. The browser app still uses Supabase client code; no server-side MySQL API, full parity, production data transfer, or cutover is complete.

#### Next required implementation — do not mark complete yet
1. Build a disposable PostgreSQL integration test that applies the actual relevant payment schema, grants and complete policy set. Execute as distinct guardian, school-finance, platform Super Admin and authorized RPC/service contexts; do not simulate these roles only with source-text matching.
2. For guardians, assert direct INSERT/UPDATE/DELETE cannot alter review status, approved amount, invoice/allocation linkage, school/student ownership, submitter identity or receipt-object path; verify allowed guardian submission and read behavior remains intact.
3. For school finance, prove intended payment recording/review/rejection/cancellation paths work, but direct mutation of protected submission/proof/allocation fields cannot bypass the intended locked review RPC. Verify duplicate allocation and concurrent review/approval are transaction-safe.
4. For platform Super Admin, verify intended cross-school inspection is read-only and cannot directly mutate fee/payment records. For unauthorized school members and cross-school IDs, assert denial.
5. Exercise the authorized RPC with correct role/EXECUTE grants and confirm it locks the relevant rows, validates school/receipt ownership and invoice state, prevents duplicate allocations, and writes audit/history atomically. Inspect the exact existing function implementation before defining the expected contract; do not invent an RPC name or assume it is safe.
6. If the runtime fixture exposes an effective-policy gap, make the smallest draft-only correction using command-specific policies/grants and re-run the complete disposable suite. Do not apply SQL to production.
7. In parallel only where it does not obscure the release blocker, continue read-only Stage A trigger/provenance/Storage/result-PIN reviews and the separate MySQL source-to-target inventory. Keep all status items explicitly labelled verified, unverified, blocked or not started.

#### Release and migration status after this continuation
- **Stage A:** NOT MERGE-READY; payment RLS runtime evidence is still missing. A remains the first gate.
- **Stage B:** not re-verified in this continuation; retain the session/student/roster checks and the Basic 5 A subject-ID anomaly diagnostic as open.
- **Stage C:** not re-verified in this continuation; retain individual assessment save, score calculations, single class-subject average, permissions, publication/correction/audit and scoped-query tests as open.
- **Stage D:** remains gated until A, B and C are re-verified; preserve custom Nursery/Primary/JSS/SS templates, workbook mapping, school-owned template isolation and A4 print.
- **SchoolPro MySQL migration:** NOT COMPLETE. Only the draft foundation is present; no live data moved and no cutover authorized.
- **Production safety:** no production SQL/data changes, no secrets/configuration changes, no merge, and no Render deployment were performed during this continuation.

#### Update protocol carried forward
Keep every previous detailed requirement in this handover. For every next step, append concrete evidence, exact branch/commit and workflow URL, outcomes and remaining limitations. Do not replace a comprehensive checklist with a short summary or check off an item based only on static inspection or a schema-only CI pass.


### Continuation session — payment-RLS harness feasibility review (2026-10-16, next step)
This entry supplements the previous continuation; no previous checklist or roadmap items are removed.

#### Files and wiring inspected
- Re-read `docs/security/stage-a-payment-rls-review-2026-10-16.md` on `release/stage-a-auth-tenant-isolation`.
- Re-read the payment write-control migration `supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql`.
- Re-read the receipt and allocation guard migration `supabase/migrations/20261015203000_schoolpro_payment_receipt_tenant_guard.sql`.
- Re-read `.github/workflows/ci.yml` and the existing disposable trigger fixture `scripts/test-schoolpro-operational-tenant-integrity.integration.sql`.
- The existing PostgreSQL 16 CI service is wired only to the operational tenant-integrity SQL fixture. The payment RLS test in the normal CI job is still `node scripts/test-schoolpro-payment-review-write-controls.mjs`, a source-text assertion. There is no current payment-specific PostgreSQL integration job in the inspected workflow.
- The existing trigger fixture creates simplified synthetic tables and applies only the operational trigger migration. It cannot be treated as evidence for payment RLS, because it does not install the production-equivalent payment tables, all existing permissive/restrictive policies, effective grants, JWT claim context, and payment RPCs.
- The receipt guard function was inspected. It checks that a receipt path is non-empty, starts with the authenticated user's UUID, and matches an object in the expected receipt bucket owned by that user; it checks guardian linkage, validates the optional bank account, rejects repeated invoice IDs, locks invoice rows in UUID order, reserves pending allocations, validates the total, and inserts the submission and allocations. This is source inspection only: transaction behavior, actual grants, RLS interaction, concurrency and storage-owner representation have not been runtime-verified here.

#### Findings and decisions
1. Do **not** repurpose the existing simplified trigger fixture as a payment RLS test; that would create false confidence.
2. Before building the payment runtime fixture, inventory the actual schema and policy provenance for the four payment tables, their table/sequence privileges, all applicable policies (including policies created in earlier migrations), relevant functions and EXECUTE grants. The migration's restrictive policies alone do not show effective command access.
3. The disposable test must use a faithful schema/policy setup and actual PostgreSQL roles. Supabase JWT claims such as `auth.uid()` must be supplied through the same supported test pattern as the repository's local Supabase/Postgres environment; do not invent claim behavior or rely on a superuser session that bypasses RLS.
4. Keep separate tests for INSERT, SELECT, UPDATE and DELETE. Specifically test guardian attempts to alter `status`, reviewed/approved amounts, invoice and allocation links, `school_id`, `student_id`, `submitted_by`, and `receipt_path`; test Super Admin direct writes; test finance-role fee-ledger insert versus direct update/delete; and test intended RPC execution with correct grants.
5. Exercise concurrent allocation in two independent transactions against the same invoice and verify that the invoice lock and pending reservation prevent over-allocation. Include invalid receipt owner/path, foreign-school invoice/bank account, inactive guardian link, duplicate invoice allocation, total mismatch and invalid status-transition cases.
6. No policy correction was committed in this step because the exact effective permissive-policy/grant baseline has not yet been established. A guessed policy replacement could break legitimate guardian submission or school-finance workflows. No disposable database was available to execute the runtime assertions during this step; therefore no runtime test pass is claimed.

#### Updated work status
- **Completed this step:** source and workflow feasibility review; confirmed that the current PostgreSQL CI service can host a new disposable payment integration job, but the existing trigger fixture is not sufficient.
- **Still blocked:** real-role payment RLS integration test and full effective-policy/grant inventory.
- **Next action:** inspect the complete migration history and policy/function definitions for the four payment tables; assemble a disposable fixture from the real relevant schema/policy/function definitions; then add a dedicated PostgreSQL CI job and run it before making any policy change.
- **Safety:** no production database access or writes were performed in this step; no merge, Render deployment, or production migration was performed.


#### Additional migration-history evidence — payment paths are distinct
- Inspected `supabase/migrations/20260920212500_schoolpro_online_fee_payments.sql`. It defines a separate online card-payment intent/finalization path: `finalize_schoolpro_payment(...)` is revoked from PUBLIC/anon/authenticated and granted to `service_role`. It locks the payment intent and invoice, rejects amount mismatch/overpayment and writes the fee ledger and invoice state in one function transaction. This is source evidence only; no live invocation or concurrency test was run.
- Inspected `supabase/migrations/20261003000500_schoolpro_guardian_tenant_hardening.sql`: guardian policies on invoices and fee payments are SELECT-only and scope access through active guardian links matching student and school. Inspected `20261011092231_schoolpro_operational_staff_and_fee_breakdown_access.sql`, which later alters invoice/payment read policies for authorized finance roles and guardian-owned invoice students.
- These earlier migrations demonstrate why the runtime fixture must load the effective policy state in migration order. Testing only the new restrictive policy or writing a reduced hand-crafted approximation would miss permissive policies that combine with it.
- The online card gateway finalizer is not a substitute for SchoolPro's manual receipt-review workflow. Keep the workflows separate in test cases and preserve the rule that BillStack is DataSub-only.
- No source changes were made to payment policy SQL in this step. The next implementation remains a dedicated disposable PostgreSQL job that loads the real migration/policy history (or a reviewed, complete snapshot of the relevant effective schema), runs distinct authenticated role tests and concurrency tests, and records the exact CI run. Until that executes, the payment RLS gate remains blocked.


#### Payment audit continuation — legacy fee-ledger grants and RPC boundary (2026-10-16)
Additional files reviewed on `release/stage-a-auth-tenant-isolation`:
- `supabase/migrations/20260920152000_schoolpro_finance_and_result_access.sql` (blob `3231b11feac2cd972dbd03e56b09e8c55f160521`)
- `supabase/migrations/20260927170000_schoolpro_explicit_fee_exceptions.sql`
- `supabase/migrations/20261002123000_schoolpro_super_admin_action_access_and_document_rls_fix.sql`
- `supabase/migrations/20261002234500_schoolpro_operational_tenant_isolation.sql`

Specific source findings:
1. The initial fee-ledger table grant gives `authenticated` SELECT and INSERT, while the initial permissive `School finance records payments` policy authorizes INSERT when the caller has a qualifying school role and `recorded_by=auth.uid()`. The new migration adds a restrictive finance-module gate and disallows Super Admin writes through that policy layer. The effective policy set and role grants still need runtime confirmation.
2. The earlier `public.record_schoolpro_payment(uuid,numeric,text,text,text)` function is not SECURITY DEFINER. It locks the target invoice, checks finance-role access, amount and method, inserts a payment ledger row and updates invoice balance in the same transaction. It is granted to authenticated callers. This is distinct from the guardian receipt-submission function and the service-role-only online card finalizer.
3. The earlier ledger INSERT policy's visible check verifies role/school access and caller identity, but does not itself visibly cross-check that the supplied `invoice_id`, `student_id`, and `school_id` all identify the same tenant/child, nor does a bare INSERT policy update the invoice balance. This is a **source-level integrity question requiring a full trigger/constraint/RPC and effective-policy check**, not a confirmed exploitable vulnerability. Do not remove legitimate direct insert behavior without proving whether the application depends on it.
4. The operational tenant-isolation migration uses permissive policies alongside restrictive policies on some modules; therefore the same rule applies to payments: inspect all permissive policies, restrictive policies, table grants, function grants, triggers, and actual caller paths together.

Next concrete test additions:
- Under an authenticated finance role, attempt a direct fee-ledger insert with (a) invoice from another school, (b) student from another school, (c) mismatched student and invoice within one school, and (d) valid same-school data; capture whether each insert is rejected and whether invoice balance consistency remains intact.
- Test the intended `record_schoolpro_payment` RPC with the same invalid cross-links and valid data, including two concurrent transactions targeting one invoice.
- Check whether a constraint/trigger elsewhere already blocks these mismatches before deciding on a code change.
- Keep manual receipt review, direct finance ledger entry, and online card finalization as separate test suites.
No policy or application code was changed in this audit step. No PostgreSQL runtime result is claimed. This continuation preserves the existing roadmap and does not mark Stage A complete.


### Product-scope correction — SchoolPro has no online payment gateway (2026-10-16)
**Authoritative product decision from the user:** SchoolPro must NOT offer online/card payment or a payment gateway. The earlier audit mistakenly described the existing Flutterwave/card-payment code as an intended SchoolPro workflow. Correct that interpretation across future implementation, testing, and documentation.

#### Intended SchoolPro payment model
- **SchoolPro annual subscription:** customer school uploads payment receipt/proof; IHLink platform Super Admin verifies and marks the subscription paid. Demo activation and annual plan rules remain as previously recorded.
- **School fees:** each school handles its own collections and records the payment/receipt through the school finance workflow. Do not route SchoolPro school-fee or subscription payments through BillStack or an online card gateway.
- **BillStack:** DataSub only; it is not part of SchoolPro payments.

#### Repository evidence and required handling
- `supabase/migrations/20260920212500_schoolpro_online_fee_payments.sql` creates `schoolpro_payment_intents` and `finalize_schoolpro_payment(...)`, with Flutterwave/card references and service-role-only finalization. This is legacy/unintended product scope unless the user explicitly changes the decision. Do NOT treat its presence as a requirement or acceptance criterion.
- `supabase/functions/schoolpro-payment/index.ts` is a gateway-adjacent function. It must be dependency-traced and classified for removal/disablement.
- `src/pages/schoolpro/SchoolProPayments.tsx` is receipt-based guardian-to-school fee payment, not an online gateway. Preserve and secure this school-owned transfer/receipt workflow; do not remove it just because its name contains “Payments”.
- The general `src/components/BankTransferPayments.tsx` contains cross-product receipt-based bank transfer functionality, including a `schoolpro_subscription` platform code path. That path represents receipt upload/review, not online checkout; keep it distinct from the unintended card-payment path.
- The historical migration file must not be rewritten as if it had never existed. First trace deployed migration state, all callers, references, and any existing intent records. Then implement a forward, non-destructive change that disables/removes the online gateway path and unused UI/edge-function references while preserving records unless a separately approved retention plan says otherwise. Do not drop payment-intent data or production objects as part of a blind cleanup.
- Update payment security tests so they validate receipt submission/review, school fee recording, tenant isolation, protected review fields and authorized RPCs only. Online/card intent creation and gateway finalization are not SchoolPro acceptance requirements. If legacy objects remain temporarily for compatibility, explicitly document them as disabled/unreachable and keep them out of user-facing flows.

#### Corrected next action and status
1. Trace all references to `schoolpro_payment_intents`, `finalize_schoolpro_payment`, Flutterwave, and `supabase/functions/schoolpro-payment` across UI, edge-function configuration, tests, workflows, and migration history.
2. Confirm whether the online path is referenced by any currently reachable SchoolPro UI or production function deployment; do not infer reachability from file existence.
3. Prepare a forward cleanup/disable change on the draft Stage A branch, preserving historical migrations and any existing records. Add regression checks proving SchoolPro has no online checkout/card gateway while receipt upload, school finance recording, subscription review and Super Admin verification remain functional.
4. Run static/CI validation and the relevant receipt/RLS tests. Report exact evidence; do not claim production gateway removal until deployment/configuration has been verified.
5. Continue the full Stage A audit. This scope correction does not mark A complete and does not reduce the existing A–J roadmap. B/C must still be re-verified before D.

No production changes, data deletion, merge, or deployment were performed by recording this correction.


#### Follow-up reference trace after payment-scope correction (2026-10-16)
Reviewed the current Stage A branch's `src/App.tsx`, `src/pages/schoolpro/SchoolProPayments.tsx`, and `src/pages/schoolpro/SchoolProSubscription.tsx`:
- `src/App.tsx` routes `/schoolpro/payments` to `SchoolProPayments`.
- `SchoolProPayments` is explicitly receipt/transfer-based: it uploads to `schoolpro-payment-receipts` and invokes `submit_schoolpro_payment`; it does not perform online card checkout in the inspected code. Preserve this workflow.
- `SchoolProSubscription` queries subscription intents filtered to `payment_method = 'bank_transfer'` and renders `BankTransferPayments` with platform `schoolpro_subscription`; this is receipt-upload/review functionality, not a gateway.
- The `supabase/functions/schoolpro-payment/index.ts` gateway-adjacent function and historical Flutterwave migration remain in the repository. This limited trace did not establish their production deployment status or prove that no other references exist. A repository-wide reference/deployment trace remains required before safely disabling/removing them.
- Attempt to fetch `supabase/config.toml` on this branch returned 404; therefore no function deployment configuration was confirmed by that path. Do not infer that the function is or is not deployed from this result.

Corrected current decision: no online payment gateway is a SchoolPro requirement. Receipt-based school fee and subscription workflows remain in scope. Next, complete repository-wide call/reference search, inspect function deployment configuration and production reachability using approved evidence, then prepare a forward non-destructive cleanup if the gateway code is unused. Preserve historical migration files and any data; no production cleanup has been applied.


### Receipt-only payment scope — forward disablement prepared (2026-10-16)
Following the explicit product correction, a **draft-branch code change** now disables the legacy online/card finalizer without deleting its historical migration or payment-intent records.

- Stage A branch: `release/stage-a-auth-tenant-isolation`.
- Forward migration added: `supabase/migrations/20261016170000_schoolpro_disable_online_payment_gateway.sql`.
- Migration commit: `d788b345701c893d7ec1fa96976721fd55c78e31`.
- Regression check added: `scripts/test-schoolpro-no-online-gateway.mjs`, commit `f6b615ce5bf22de536a555c0c59d8ac2428e8159`.
- CI invokes the regression check in `.github/workflows/ci.yml`, commit `d555fcb967d2126d8fd684eaef371f7ddd3dacd6`.
- Forward migration replaces `public.finalize_schoolpro_payment(...)` with a fail-closed exception and revokes execute from PUBLIC, anon, authenticated, and service_role. The legacy intent table and original migration remain intact. This is deliberately non-destructive; no payment-intent data is deleted.
- Regression check asserts the forward disablement and that school subscription and school-fee receipt workflows remain in source. It is a static source test, not runtime PostgreSQL proof.

**Verification state:** files and CI insertion were re-fetched from GitHub and confirmed present. No CI result for these latest commits has yet been observed, and the migration has not been applied to any database. Therefore this is a proposed forward fix on the draft Stage A branch, not a production fix or proof of deployed behavior. Production Render/Supabase were not changed; no PR was merged or deployed.

**Next:** confirm the new CI run for the latest Stage A head, correct any failing assertions, then validate the forward migration against a disposable PostgreSQL instance with the relevant schema and roles. Independently finish tracing whether the old Edge Function is deployed/reachable; its inspected body only returns bank-transfer instructions and does not perform card checkout. Do not delete that function until deployment and caller status are established.


#### CI evidence for the receipt-only forward-disable change (2026-10-16)
- Workflow run: [SchoolPro CI #38946396648](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38946396648), inspected at head `d555fcb967d2126d8fd684eaef371f7ddd3dacd6`.
- The new `scripts/test-schoolpro-no-online-gateway.mjs` step completed successfully.
- The separate disposable PostgreSQL tenant-integrity job completed successfully, but it does not apply the payment disablement migration or validate payment RLS.
- The optional live two-school tenant-acceptance job failed in the same workflow. Its failure cause was not established during this step; investigate it separately rather than attributing it to the payment migration.
- The full workflow was still in progress when checked, so no overall CI pass is claimed.
- Security review follow-up commit: `60aab0c9fb8ec63852ed01e7f15c11e933cf63d0`, in `docs/security/stage-a-payment-rls-review-2026-10-16.md`.
- The online-payment disablement remains draft-branch only and has not been applied to production. No merge or Render deploy.


#### Runtime test added for online-payment disablement (2026-10-16)
- Added `scripts/test-schoolpro-online-payment-disable.integration.sql` (commit `9e6610e39279c8e7b229db0a9cc16a702b8c4581`) and wired it into the disposable PostgreSQL CI job in `.github/workflows/ci.yml` (commit `68f75c26167540d94ccbfb971cdc72064351d40a`).
- This integration test creates missing API roles only in the dedicated throwaway PostgreSQL CI database, applies the forward migration, verifies `anon`, `authenticated`, and `service_role` lack EXECUTE on the legacy finalizer, and asserts direct invocation raises the expected disabled-feature SQLSTATE/message.
- This adds actual PostgreSQL execution/privilege validation beyond the static source test. It does not touch production.
- CI run at prior head `60aab0c9fb8ec63852ed01e7f15c11e933cf63d0` showed the optional live two-school tenant acceptance succeeding, correcting the earlier run's transient/isolated failure; the overall workflow was still in progress when checked. New integration-test workflow status must be checked at head `68f75c26167540d94ccbfb971cdc72064351d40a` before claiming a pass.
- The edge function `supabase/functions/schoolpro-payment/index.ts` was inspected directly: it authenticates the caller and only supports the `instructions` action for fetching invoice and active school's bank-transfer account details; all other actions return `unsupported_action`. It does not initiate card checkout in its current source. Production deployment/reachability is still unverified, so preserve it for now rather than deleting it.
- Current next steps: verify latest CI run and fix any SQL test issues; then resume the payment RLS/runtime review for the actual receipt-submission/review and school finance flows. No merge, production migration, or Render deployment has occurred.


#### Verified CI result and integration-test refinement (2026-10-16)
- Full SchoolPro CI run [#38946577460](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38946577460) completed with **success** at head `60aab0c9fb8ec63852ed01e7f15c11e933cf63d0). The live two-school tenant-acceptance job that failed on the earlier `d555fcb` run succeeded on this later run. The failure appears run-specific; no root cause was established, so retain monitoring rather than asserting a code fix.
- On head `68f75c26167540d94ccbfb971cdc72064351d40a`, the dedicated PostgreSQL job also completed successfully, including the new gateway-disable integration test. The test applied the forward migration, verified API-role EXECUTE privileges are revoked, and confirmed invocation fails closed.
- A small follow-up test-fixture edit on `cdb96ae787aea9e99beb2f40044620681efe4a43` changed conditional role creation to explicit dynamic SQL inside PL/pgSQL. This is a robustness refinement; CI for that exact latest head is queued/in progress as of this note. Do not carry the earlier pass forward as evidence for the newer commit until its run finishes.
- Latest integration test: `scripts/test-schoolpro-online-payment-disable.integration.sql`; latest CI wiring is in `.github/workflows/ci.yml`.
- The gateway finalizer disablement is proven in disposable PostgreSQL on the earlier tested revision, not production. Apply remains pending. The payment RLS runtime gap for receipt submissions and school finance workflows remains open.


## Receipt-only payment enforcement — latest verification (2026-10-16)

### CI confirmation
- GitHub Actions run **38947005526** completed with conclusion **success** on Stage A head `cdb96ae787aea9e99beb2f40044620681efe4a43`: [run details](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38947005526).
- Confirmed jobs: `validate`, `tenant-integrity-db-integration`, and `tenant-acceptance` all succeeded. This validates the source/static suite, disposable PostgreSQL tenant-integrity checks, receipt-only online-gateway disablement integration test, and configured live two-school read-only tenant acceptance for that exact commit.
- The forward migration disabling the legacy `public.finalize_schoolpro_payment(...)` gateway finalizer is still on the unmerged Stage A branch. CI success does **not** mean it has been merged, applied to production, or verified against the live production database.

### Receipt-based payment security audit — source review
Reviewed:
- `supabase/migrations/20261015203000_schoolpro_payment_receipt_tenant_guard.sql`
- `supabase/migrations/20261011092231_schoolpro_operational_staff_and_fee_breakdown_access.sql`
- `supabase/migrations/20261003000500_schoolpro_guardian_tenant_hardening.sql`
- `supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql`
- `scripts/test-schoolpro-payment-review-write-controls.mjs`

Source-level controls observed in `submit_schoolpro_payment`:
- requires an authenticated caller and a non-empty receipt object path under the caller's UUID;
- checks the object belongs to the caller in `schoolpro-payment-receipts`;
- requires an active guardian link to the school and separately validates each allocated invoice's student belongs to that guardian;
- validates any selected bank account belongs to the same school and is active;
- rejects duplicate invoice IDs, non-positive allocations, invalid invoices, and a total that does not equal the allocation sum;
- locks invoice rows in UUID order and accounts for pending allocations to limit duplicate/concurrent over-allocation;
- revokes direct execution from `PUBLIC` and `anon`, granting execution to `authenticated`.

The payment-review migration uses restrictive RLS policies to preserve the finance-module gate, scope guardian submissions/proofs, and make Super Admin ledger access inspection-only rather than direct write access. Guardian policies also bind student/payment/result records to both the guardian link and school tenant.

### Remaining gap — do not mark payment security complete
- `scripts/test-schoolpro-payment-review-write-controls.mjs` is a **static source assertion**, not a live PostgreSQL RLS/RPC behavior test.
- The current disposable PostgreSQL CI job applies the tenant-integrity and gateway-disablement integration SQL, but does not provision the complete SchoolPro schema and execute `submit_schoolpro_payment` as realistic guardian, unrelated guardian, school-finance, and Super Admin roles.
- Therefore the receipt-path ownership check, cross-tenant/cross-student rejection, pending allocation concurrency behavior, effective RLS policies, and review/write boundaries remain **source-reviewed but not runtime-verified**. Do not describe these as fully tested.
- Next action: map the migration dependencies and required auth/storage fixtures, then add a disposable integration test only if it can faithfully apply the relevant schema/functions/policies without copying production data or requiring a paid database. Include valid guardian submission; missing/foreign receipt; inactive or wrong-school guardian; invoice/student tenant mismatch; duplicate invoice; amount mismatch; pending-balance over-allocation; and role-based SELECT/INSERT/UPDATE/DELETE checks. If a minimal harness would bypass the real policies/functions, record the limitation instead of claiming coverage.

### Product rule reaffirmed
SchoolPro has **no online payment gateway**. SchoolPro annual subscriptions use uploaded payment evidence and IHLink Super Admin verification; school fees are recorded and receipted through the school-managed finance workflow. BillStack remains DataSub-only. Historical gateway code/migrations and records are not to be blindly deleted; trace callers, deployed function reachability, and migration history before any cleanup. No production migration, deployment, or PR merge was performed by this CI verification.


### Additional receipt-upload validation gap found during source review (2026-10-16)
- The guardian UI advertises JPEG, PNG, WebP, and PDF, but the `submit_schoolpro_payment` RPC checks the receipt object's path and owner only; it does not independently validate the object's stored MIME metadata or byte size against the UI's accepted formats.
- A browser `accept` attribute is only a user-interface hint, not a security boundary. Before closing this item, verify the effective `schoolpro-payment-receipts` bucket configuration (allowed MIME types and file-size limit) in both repository migrations/configuration and the target Supabase project. If those server-side bucket restrictions are not demonstrably configured, add a forward migration and test the enforcement. Also consider comparing the uploaded object's stored MIME metadata to `p_receipt_mime`; do not trust the RPC argument by itself.
- This is a **source-review finding / verification task**, not proof that arbitrary file types currently pass in production. Production bucket configuration was not changed or queried in this step.


### Receipt storage server-side limits — implemented on Stage A branch (2026-10-16)
- Added forward migration `supabase/migrations/20261016180000_schoolpro_payment_receipt_storage_limits.sql` (commit `42f881412d1d70cd7effd6f0c8b6168b7c261b6e`). It configures `schoolpro-payment-receipts` as private, caps each object at 10 MiB, and restricts accepted MIME types to JPEG, PNG, WebP and PDF. The upsert also corrects existing bucket settings when the migration is applied.
- Extended `scripts/test-schoolpro-no-online-gateway.mjs` (commit `fbde78dce38e40d1a8feb879f2862fc04d09da5c`) so CI statically checks that the forward migration retains privacy, size limit and accepted MIME types.
- This is a source change on the unmerged Stage A branch. The static test does not execute Supabase Storage itself or inspect the actual production bucket. Wait for CI and verify effective bucket settings after an approved deployment before claiming runtime enforcement.
- Scope note: MIME allow-lists validate the upload's declared content type at the Storage API; they are not malware scanning or cryptographic file-content sniffing. Receipt-path ownership and real RLS/RPC runtime coverage remain open as recorded above.


### CI follow-up for receipt storage assertion (2026-10-16)
- The initial storage-migration static test failed because the new test regex was over-escaped; the PostgreSQL integration job and two-school tenant-acceptance job both passed in that run. This was a test assertion defect, not evidence that the migration itself failed.
- Corrected the regex assertions in `scripts/test-schoolpro-no-online-gateway.mjs` in commit `c0adc5f0d0ec20c701ae40cbd9fc0bdb7ce1c3d2`.
- CI for the corrected head is running: [run 38948315236](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948315236). Do not mark the corrected test as passing until this run completes successfully.


- Follow-up: the corrected static `validate` workflow completed successfully on `c0adc5f0d0ec20c701ae40cbd9fc0bdb7ce1c3d2` ([run 38948315236](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948315236)). The parallel tenant-integration/acceptance run for the same head was still in progress at handover update time ([run 38948315276](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948315276)); wait for its final status before reporting all CI green for this head.


## 2026-10-16 continuation — receipt storage restrictions and CI confirmation

- **Receipt-storage migration source cleanup:** On Stage A branch `release/stage-a-auth-tenant-isolation`, commit `bf75637fb3f40785b5a54b1707dfc64c5eed2ee8` removes an unnecessary `COMMENT ON TABLE storage.buckets` statement. This avoids changing a global Supabase system-table comment; the targeted upsert for the `schoolpro-payment-receipts` bucket remains unchanged (private bucket, 10 MiB maximum, JPEG/PNG/WebP/PDF MIME allowlist).
- **Confirmed CI:** GitHub Actions run [#38948315276](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948315276), head `c0adc5f0d0ec20c701ae40cbd9fc0bdb7ce1c3d2`, completed with overall conclusion `success`. All three jobs passed: `validate`, `tenant-integrity-db-integration`, and `tenant-acceptance`. This verifies the prior commit only; the follow-up cleanup commit `bf75637...` still requires its own CI run.
- **Scope limitation:** These CI results do not establish that the Storage migration has been applied to production or that the effective production bucket configuration is correct. The migration remains unmerged/unapplied pending explicit approval and deployment checks. MIME allowlisting/size limits are Storage API configuration, not malware scanning or byte-level file-content validation.
- **Payment model remains:** SchoolPro has no online gateway checkout. SchoolPro subscriptions are paid by receipt upload and IHLink admin verification; school fees are recorded/receipted by the school. BillStack is DataSub-only. Keep the legacy gateway finalizer disabled by the Stage A migration; do not remove historical migrations or payment records without dependency/deployment evidence.


## Follow-up CI for receipt-storage comment cleanup — 2026-10-16

- Cleanup commit: `bf75637fb3f40785b5a54b1707dfc64c5eed2ee8` on `release/stage-a-auth-tenant-isolation`.
- Payment-page validation run [#38948907506](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948907506) completed successfully on that commit.
- SchoolPro CI run [#38948907551](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948907551) was still in progress at the time of this update. Its disposable PostgreSQL tenant-integrity/gateway-disablement job had passed; the main validation and live tenant acceptance jobs had not yet completed. Do not treat this as a full green run until the run reaches a final successful conclusion.
- Receipt submission RPC tests remain a separate gap: current CI does not provision the complete SchoolPro invoice/guardian/storage/auth fixture needed to exercise the RPC's success and rejection paths against PostgreSQL. Existing source assertions are not substitutes for those behavioral tests.


## Final CI confirmation for receipt-storage cleanup — 2026-10-16

- SchoolPro CI run [#38948907551](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948907551) completed successfully on Stage A commit `bf75637fb3f40785b5a54b1707dfc64c5eed2ee8`. All jobs passed: `validate`, `tenant-integrity-db-integration`, and `tenant-acceptance`.
- Payment-page validation run [#38948907506](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948907506) also completed successfully on the same commit.
- This is CI evidence for the Stage A branch commit only. It does not mean the changes are merged, deployed, or applied to production. Receipt RPC behavior under the full production-equivalent schema and effective Storage bucket settings still needs separate verification.


## MySQL migration reality check — source inspected 2026-10-16

- Rechecked `src/lib/supabase.ts` and `package.json` on `migration/mysql-schoolpro-foundation`. The running frontend still imports `@supabase/supabase-js`, creates a browser Supabase client, and defaults to the production Supabase URL/project ref `lnqsroyiybutkfngbyge`. The package manifest has no MySQL driver or server API framework in its dependencies.
- Therefore, **SchoolPro has not been migrated to MySQL at the application/runtime level**. The branch contains a draft MySQL schema and architecture/parity documentation, not a production-ready replacement for Supabase Auth, database RPCs, RLS, Storage, Edge Functions, and frontend calls. A MySQL schema passing relational checks does not equal application migration or cutover readiness.
- Do not point the browser directly at MySQL and do not put database credentials in Vite/browser environment variables. The next safe implementation milestone is a server-side API/authentication vertical slice in an isolated branch, with session validation and tenant authorization tested before moving any business module. Keep Supabase production live until all feature/security/data parity and rollback gates are explicitly approved.
- CI update: SchoolPro CI run [#38948907551](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948907551) is now confirmed fully successful on `bf75637fb3f40785b5a54b1707dfc64c5eed2ee8`; `validate`, `tenant-integrity-db-integration`, and `tenant-acceptance` all passed. Payment-page validation run [#38948907506](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38948907506) also passed. Both runs are branch CI only, not production deployment evidence.


## Receipt-submission regression guard added — 2026-10-16

- Added `scripts/test-schoolpro-receipt-submission-guards.mjs` on Stage A commit `f0063e126ff92e3aae75c653ee7310b6b90c1c3d`, then wired it into `.github/workflows/ci.yml` in commit `15930b6655cf5ab75edfc9fcd62f8fa1de6d65dd`. The source-contract checks assert authentication, receipt-object ownership/path, active guardian relationship, same-school active bank account, invoice locking, duplicate-allocation rejection, pending reservation accounting, allocation-total reconciliation and RPC execute grants.
- The new test is explicitly a **static regression guard**, not a live RPC/RLS integration test. It cannot prove runtime policy interaction, file-byte/MIME integrity, transaction behavior, or real Storage configuration.
- CI run [#38950847321](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38950847321) for `15930b6655cf5ab75edfc9fcd62f8fa1de6d65dd` was still in progress at this handover update. Wait for a final result before describing the new test as passing.
- MySQL migration remains a draft foundation only. Source review confirmed the frontend still instantiates `@supabase/supabase-js` against the current Supabase project; a server-side API/auth layer and complete parity/cutover remain prerequisite work. Production remains on Render + Supabase until an approved migration plan and rollback gate are satisfied.


## Receipt guard CI failure diagnosed and corrected — 2026-10-17

- The first CI run for the newly added receipt guard test, [#38950847321](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38950847321), failed only in `validate` at `scripts/test-schoolpro-receipt-submission-guards.mjs`. The two tenant integration/acceptance jobs passed. Root cause was a test-regex typo: it expected SQL `count()` while the migration correctly uses `count(*)`; this was a test defect, not a detected production failure.
- Corrected the assertion in commit `0e2ac8cd1618f2df41b6ead9a3d38526329989f7`. Rechecked all 12 guard patterns against the current migration source; all 12 match. Updated the CI step name in commit `143ed2aed9cd341e7d2234e4fedf89d2a7d9bf1a` to trigger fresh workflow validation.
- Fresh SchoolPro CI [#38989637673](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38989637673) and payment-page validation [#38989637689](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38989637689) were still in progress when this note was written. Do not call the corrected test CI-green until both have final results.
- Even if green, this test is static source-contract coverage only. It does not replace the pending real PostgreSQL/RLS/RPC receipt submission and payment review integration fixture. No production changes or PR merges were made.



## Receipt guard CI confirmed green — 2026-10-17

- Rechecked the completed runs after the last handover entry. SchoolPro CI [#38989637673](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38989637673) completed with conclusion **success** on head `0e2ac8cd1618f2df41b6ead9a3d38526329989f7`; all three jobs passed: `validate`, `tenant-integrity-db-integration`, and `tenant-acceptance`.
- Payment-page validation [#38989637689](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38989637689) also completed with conclusion **success** on the same head.
- These runs verify the corrected static receipt-submission guard and the existing disposable tenant/gateway checks on that commit. The later workflow-step naming commit `143ed2aed9cd341e7d2234e4fedf89d2a7d9bf1a` is newer than the head reported by these two runs, so do not claim those runs tested that newer commit.
- PR #106 remains open, draft, and unmerged. No production migration, Storage bucket change, deployment, or live payment record change was performed.
- Next: create a dedicated disposable PostgreSQL behavioral fixture for `submit_schoolpro_payment`, applying the actual migration to minimal test-only schemas and exercising both valid and rejected submissions. Keep static source assertions labelled as static. Then extend coverage to effective payment-review RLS policies/grants. Do not use production credentials or mutate the production Supabase project for this work.
- MySQL migration remains incomplete at application/runtime level; the frontend still uses the Supabase browser client. This receipt-security task does not advance or imply MySQL cutover.


## Disposable PostgreSQL receipt-RPC behavioral test added — 2026-10-17

- Added `scripts/test-schoolpro-payment-receipt-rpc.integration.sql` on Stage A branch and wired it into the disposable PostgreSQL CI job after the tenant-integrity and legacy-gateway checks. The fixture applies the **actual** `20261015203000_schoolpro_payment_receipt_tenant_guard.sql` migration against test-only minimal tables and exercises a valid receipt submission plus rejection cases for foreign receipt ownership, an invoice belonging to an unlinked student, duplicate invoice allocations, allocation-total mismatch, pending-allocation over-reservation, and an inactive school bank account.
- CI was triggered by the new fixture and is pending final result. Current fixture edits continued after the first workflow trigger; verify the run head SHA matches the latest Stage A commit before considering the final version validated. If CI fails, inspect the PostgreSQL job logs and correct the fixture before proceeding.
- This is a disposable behavioral test of the RPC logic against a minimal schema, **not yet** a full production-equivalent schema/RLS test, concurrency test, Storage API byte/MIME validation test, or effective payment-review policy test. The fixture runs with a local PostgreSQL superuser to set up the isolated test database; it simulates caller identity through the test `auth.uid()` implementation. Do not overstate it as a complete authorization-stack proof.
- No production Supabase calls, migrations, bucket changes, record mutations, deployments, or PR merges were performed. PR #106 remains draft/open/unmerged. The MySQL application/runtime migration remains incomplete.


## Receipt RPC integration CI passed — 2026-10-17

- Verified [SchoolPro CI #38990160428](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990160428) completed **successfully** on Stage A head `0d1294d03a90f9a5ee601d83645cbe9b1ff34c70`. All jobs passed: `validate`, `tenant-integrity-db-integration`, and `tenant-acceptance`.
- Verified [payment-page validation #38990160500](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990160500) completed **successfully** on that same head.
- The CI workflow's disposable PostgreSQL job ran the new receipt-submission RPC integration fixture. This establishes that the fixture and its valid/rejected RPC cases pass against its minimal test schema; it does **not** establish full production schema parity or effective RLS behavior, because the fixture uses a test `auth.uid()` implementation and setup superuser.
- Next priority: add a separate isolated PostgreSQL job to exercise effective payment-review RLS policies using authenticated role switching and stubbed, test-only authorization helpers, while clearly recording the fixture's scope. Include SELECT/INSERT/UPDATE/DELETE checks for guardian, school-finance, and Super Admin identities on submissions, allocations, proofs, and fee-payment ledger rows.
- No production changes or merges occurred. PR #106 remains draft/open/unmerged. MySQL migration is still incomplete; no production data cutover has been performed.


## Payment-review RLS runtime fixture added — 2026-10-17

- Added `scripts/test-schoolpro-payment-review-rls.integration.sql` on the Stage A branch and added a separate `payment-review-rls-integration` GitHub Actions job using its own ephemeral PostgreSQL 16 service database.
- The fixture applies the actual `20261016143000_schoolpro_payment_review_write_controls.sql` migration against minimal test-only tables and switches to the `authenticated` role with row-level security enabled. Test-only authorization helpers model three identities: a linked guardian, school finance access, and platform Super Admin.
- Intended coverage: guardian reads only their own submission/allocation/proof and linked fee-payment row; guardian cannot alter payment-review records; school finance can review/update the school's rows; Super Admin can read across the fixture but cannot mutate ledger/submission records. This is a focused policy behavior fixture, not a full application schema/auth integration or a substitute for two-school live acceptance.
- CI was triggered by the fixture/workflow addition. A follow-up adjustment now checks affected row counts for denied UPDATE/DELETE actions, because RLS can silently filter rows instead of raising an exception. Verify the newest run's head SHA matches the final fixture commit before treating this test as passed.
- No production database, storage bucket, payment records, or deployments were changed. PR #106 remains draft/open/unmerged; MySQL migration/cutover remains incomplete.


## RLS integration test failure diagnosed and corrected — 2026-10-17

- The first run of the new `payment-review-rls-integration` job failed before policy assertions, due to a malformed dollar-quote delimiter in the test helper `pg_temp.assert_no_rows_affected` (SQL syntax error at the function body). This was a test-fixture syntax defect, not evidence of a product-policy failure.
- Corrected the helper to use an explicit named dollar delimiter (`$assert$...$assert$`). Current correction commit: `13712c209883e24a697d29d9da56277825350be8`.
- Fresh runs for that exact commit are queued/in progress: SchoolPro CI [#38990676105](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990676105) and payment-page validation [#38990676100](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990676100). Do not mark the RLS fixture green until the database job and all required CI jobs complete successfully.
- The prior receipt-RPC fixture passed on commit `0d1294d03a90f9a5ee601d83645cbe9b1ff34c70`; the RLS fixture is separate and not yet validated. No production changes, deployment, or merge occurred.


## Follow-up verification: RLS fixture access and tenant acceptance diagnostics — 2026-10-17

- The named SQL delimiter correction allowed the RLS fixture to proceed further. The next failure is a missing fixture permission: authenticated test role cannot SELECT `schoolpro_guardian_links` while the policy under test evaluates its guardian-link predicate. The disposable fixture now enables RLS on that table, adds a scoped guardian/finance SELECT policy, and grants SELECT to the test role (commit `6ba6fde9f028e4d7e553b4ecb520e6f21db96e7a`). This is test-fixture setup only, not a production policy change.
- The live two-school acceptance job also failed while counting foreign-school `schoolpro_invoices` rows. Its logger printed `[object Object]`, hiding the useful structured API error. Added structured error formatting to the read-only acceptance script (commit `b7075b732c26a8c80f4bf79565a5fe199257500f`) so the next run exposes the actual status/message rather than obscuring the cause.
- Latest corrective commits are queued for CI; do not treat either test as passing until fresh jobs complete. Earlier tenant checks passed for students, members, and the academic-period RPC before the invoice-count error.
- No production writes, deployment, migration application, or PR merge was performed.


## RLS policy defect found and fixed from runtime fixture — 2026-10-17

- Runtime execution reached the policy assertions after the fixture's guardian-link permissions were corrected. It exposed a real policy mismatch: the restrictive `schoolpro_module_permission` policy on `schoolpro_fee_payments` allowed Super Admin and finance-module reads, but omitted guardian reads for a linked student, despite the migration comment stating guardian-readable ledger entries.
- Updated `supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql` to include an active guardian-link predicate in the restrictive policy's `USING` clause. The `WITH CHECK` remains finance-only and explicitly excludes Super Admin writes, preserving the intended read-only Super Admin behavior and finance-controlled mutations.
- Fix commit: `82cc647d71014db1683e4d0f13a8a2cd1ff56efc`. Fresh CI will run on push; the RLS test remains pending until that run completes.
- The tenant acceptance and tenant-integrity database jobs passed on the prior run `38990776439`; only `payment-review-rls-integration` failed. That failure is now treated as a product-policy defect, not merely fixture setup.
- No production migration was applied, no deployment occurred, and no PR was merged.


## Guardian fee-payment RLS fix — integration results — 2026-10-17

- On Stage A head `82cc647d71014db1683e4d0f13a8a2cd1ff56efc`, CI run [#38990991453](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990991453) now reports **success** for `payment-review-rls-integration`, `tenant-integrity-db-integration`, and `tenant-acceptance`.
- The runtime RLS fixture now verifies guardian visibility is scoped to linked student fee-payment rows; it also exercises submission/allocation/proof visibility and mutation restrictions for guardian, finance, and Super Admin roles. This is a minimal disposable PostgreSQL fixture applying the actual review-policy migration, not a full production database/auth stack.
- The overall workflow is not yet complete: `validate` was still running at the time of this update. Do not mark the whole workflow green until the final result is confirmed.
- The separate payment-page validation run [#38990991474](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990991474) passed on the same commit.
- No production migration, deployment, or merge occurred.


## Exact-head CI confirmation — payment RLS correction — 2026-10-17

- The complete SchoolPro CI workflow [#38990991453](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990991453) has now completed **successfully** on exact Stage A head `82cc647d71014db1683e4d0f13a8a2cd1ff56efc`. All four jobs passed: `validate`, `tenant-acceptance`, `tenant-integrity-db-integration`, and `payment-review-rls-integration`.
- Payment-page validation [#38990991474](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990991474) also passed on the same exact head.
- This resolves the outstanding workflow status from the preceding entry. It does not make PR #106 merge-ready: the passing integration fixtures are targeted/minimal, and the release gate still lists full-schema interaction, migration provenance, Storage performance/acceptance, result-PIN runtime/trusted-network semantics, and payment lifecycle/concurrency as open.
- A source audit of `20261016122000_schoolpro_result_pin_attempt_rate_limit.sql` reconfirmed the current rate limiter uses `x-forwarded-for` first, then `cf-connecting-ip` and `x-real-ip`. Trusted gateway overwrite/normalization of those headers is **not yet verified**, and the static test does not execute the checker or prove concurrency/cooldown behavior at runtime. Add a disposable PostgreSQL integration test for the actual result-PIN migration and explicitly verify network-header trust before claiming this security control is complete.
- No production migration, data write, Render deployment, or merge occurred. PR #106 remains draft/open/unmerged.


## Result-PIN runtime test added to Stage A — 2026-10-17 (pending CI)

- Added `scripts/test-schoolpro-result-pin-rate-limit.integration.sql` to execute the actual `20261016122000_schoolpro_result_pin_attempt_rate_limit.sql` migration in an isolated PostgreSQL 16 fixture. It tests eight incorrect PIN attempts, hashed attempt-key storage, rejection during cooldown, unknown-admission failure counting, successful published-result retrieval after cooldown expiry, and clearing the attempt counter.
- Added a separate `result-pin-rate-limit-integration` job to `.github/workflows/ci.yml` on Stage A branch. Commit: `13e24eae6c3de863ff042e1f477cf63251a6b93f`.
- CI validation is **pending**; do not count this runtime test as passed until its job completes. This sequential test does not yet prove concurrent requests serialize correctly.
- Trusted network-header provenance remains open. The SQL currently prefers `x-forwarded-for`; this fixture simulates request metadata and cannot prove that the production gateway overwrites spoofable client-supplied headers. Verify gateway behavior before treating network-scoped throttling as a security boundary.
- The previous exact-head Stage A workflow passed fully at `82cc647d71014db1683e4d0f13a8a2cd1ff56efc` (all four jobs). The new commit adds the runtime fixture and CI job; it has not yet been verified.
- No production migration, data write, Render deployment, or merge occurred. PR #106 remains draft/open/unmerged.


## Result-PIN runtime fixture first-run failure and correction — 2026-10-17

- First runtime attempt on commit `13e24eae6c3de863ff042e1f477cf63251a6b93f` failed before exercising the rate limiter because the minimal PostgreSQL fixture had not created the Supabase API roles `anon` and `authenticated` required by the actual migration's REVOKE statements. The failure is fixture setup, not evidence of a result-PIN logic failure.
- Added idempotent creation of those two test roles before applying the actual migration in commit `56657886334889c95c810e1fb43ac32013db9374`.
- Fresh SchoolPro CI/payment-page validation for the corrected head must complete before this test can be marked passing. The prior tenant-acceptance, tenant-integrity, payment-review RLS jobs had passed on the earlier head.
- Header provenance/trusted-proxy validation and true concurrent-request testing remain open; this sequential fixture does not prove either.
- No production migration, data write, Render deployment, or merge occurred.


## Result-PIN fixture SQL syntax correction — 2026-10-17

- The follow-up run on `56657886334889c95c810e1fb43ac32013db9374` failed at fixture setup because the generated SQL contained malformed dollar-quoted role creation statements (`DO $` rather than a valid tagged block). The migration logic still was not reached.
- Removed role creation from the SQL fixture and moved it to explicit idempotency-by-fresh-database `psql --command` steps in CI before the fixture executes. Since each job receives a new disposable database, `CREATE ROLE anon NOLOGIN` and `CREATE ROLE authenticated NOLOGIN` are expected to run once. Changes: fixture commit `5f614fa5ab6dfed2a8958d8d0a49a49a7613960a`; workflow commit `2a9110523860a68e95881b039f307564963deb96`.
- The next CI run must validate the correction; do not treat the result-PIN runtime test as passed yet. No production migration/deployment or merge occurred.


## Result-PIN CI role setup moved out of SQL fixture — fresh verification pending — 2026-10-17

- Corrected the malformed PL/pgSQL role-creation block that caused the second test attempt to stop at fixture setup. Role creation now occurs as separate `psql --command` steps in the CI job, then the SQL fixture applies the migration. Current Stage A head: `2a9110523860a68e95881b039f307564963deb96`.
- [SchoolPro CI run #38991451449](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991451449) has started but is still in progress; its `result-pin-rate-limit-integration` job has not reported a final result yet. Do not mark this control tested until the job completes successfully.
- [Payment-page validation #38991451545](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991451545) was in progress when this note was added.
- No production migration, data write, Render deployment, or merge occurred. Trusted-proxy/header provenance and concurrency acceptance remain separate open requirements.


## Result-PIN rate-limit integration passed; concurrent-request assertion added — 2026-10-17

- Confirmed [SchoolPro CI #38991451449](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991451449) passed all five jobs on `2a9110523860a68e95881b039f307564963deb96`: validation, tenant acceptance, tenant-integrity DB integration, payment-review RLS integration, and result-PIN rate-limit integration. The separate [payment-page validation #38991451545](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991451545) also passed.
- The rate-limit fixture now has verified sequential coverage for eight failed attempts, hashed key storage, cooldown rejection, unknown-admission failures, and clearing the failure counter after successful published-result access. This is a disposable minimal PostgreSQL fixture, not production-schema or gateway validation.
- Added a CI assertion that launches eight independent concurrent PostgreSQL sessions with the same admission/network key and then verifies one serialized failure counter reaches eight and a cooldown is active. Workflow change commit is pending fresh CI: this check must not be described as passed until a new run succeeds.
- Trusted proxy/header provenance is still unresolved. The function currently derives its network identifier from request headers including `x-forwarded-for`; database fixture success does not establish that the deployed gateway overwrites or safely normalizes client-supplied values. Validate the deployed request path before treating IP-based throttling as spoof-resistant.
- No merge, production migration, or deployment was performed.


## Result-PIN trusted-header hardening — fresh CI pending — 2026-10-17

- Confirmed [SchoolPro CI #38991643911](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991643911) passed all five jobs on `60779433d54f56cc83814202b701fba2bff9d9b1`, including the new eight-concurrent-failure cooldown assertion. [Payment-page validation #38991643964](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991643964) also passed.
- Investigated the forwarded-IP risk. The result checker invokes `check_schoolpro_result_pin` directly through the browser Supabase RPC client. Supabase documentation/community reports indicate a caller can prepend a spoofed value to `X-Forwarded-For`; therefore choosing its leftmost value is not acceptable as a security rate-limit identity. Reference: Supabase API security guide and the reported hosted-gateway behavior discussed at https://github.com/orgs/supabase/discussions/34647.
- Updated the draft migration to use only `cf-connecting-ip` for the request-network component, with `unknown` fallback, rather than trusting `x-forwarded-for` or `x-real-ip`. Updated the disposable SQL fixture and concurrent CI requests to include a conflicting spoofed XFF value, and added static assertions to prevent regression. Commits: migration `0d55b276c4378f381e536c3b861f0b558647bbf7`; SQL fixture `fa4b37108b95009c46a56f6d150239db0bbee230`; CI workflow `161507deed42233881d3cd722a0f41a9cd263866`; static test `pending` at handover edit time.
- This is a stronger implementation assumption for the Supabase-hosted gateway, but the disposable fixture cannot prove the production gateway overwrites `cf-connecting-ip`. Before calling the control production-verified, perform a safe request-header provenance check against the deployed Supabase gateway or use an edge/server endpoint that supplies a verified client address.
- New CI for the changed migration and fixtures is pending. No production migration, merge, or deployment occurred. SchoolPro-to-MySQL migration remains incomplete; DataSub remains on Supabase.


### Follow-up — static guard committed and CI queued/running

- Added static assertions in `scripts/test-schoolpro-result-pin-rate-limit.mjs` to require `cf-connecting-ip` as the rate-limit network identifier and reject regression to extracting the identifier from `x-forwarded-for`. Commit: `764d990cf8c28e014ddc06ed96c9591049ad0f4f`.
- CI runs on earlier intermediate commits are still in progress: [SchoolPro CI #38991895687](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991895687) and [payment validation #38991895714](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991895714) at workflow head `161507deed42233881d3cd722a0f41a9cd263866). These runs do not include the later static-test commit `764d990...`; the final branch head must be checked for its own CI result before accepting the changes.


## 2026-10-17 follow-up — result-PIN trusted-header guard CI review

- Latest Stage A head reviewed: `764d990cf8c28e014ddc06ed96c9591049ad0f4f` (`test: guard against spoofable result PIN IP headers`). The payment-page validation workflow passed on this head: [run #38991905578](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991905578).
- The SchoolPro CI run [#38991905579](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991905579) did **not** pass as a whole: static validation, result-PIN integration, tenant-integrity DB integration, and payment-review RLS integration passed, but live tenant acceptance failed during a read-only invoice count for School B with HTTP status 0 and an empty transport message after earlier cross-tenant checks had passed. This looks like a transient transport/API failure, but it is not being marked as a pass without evidence.
- Retried only the failed live tenant-acceptance job (GitHub accepted the rerun request). Verify that job's final conclusion before treating this commit's full CI as green.
- The spoofed-XFF fixture and concurrent cooldown test are covered in CI; however, the disposable fixture does not prove that the production Supabase/Cloudflare gateway always overwrites or securely supplies `cf-connecting-ip`. Treat the trusted-header provenance check as an open production-verification item. Do not apply the migration to production or merge PR #106 without explicit approval.
- Roadmap remains unchanged and additive: finish Stage A evidence and production-safe review, then strengthen/reverify B and C before resuming D (Result Design Studio + custom Excel workbooks). SchoolPro-to-MySQL migration remains incomplete; DataSub remains on Supabase.


## 2026-10-17 follow-up — trusted-header commit CI rerun confirmed green

- Final status check for [SchoolPro CI run #38991905579](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991905579): **completed successfully** on Stage A head `764d990cf8c28e014ddc06ed96c9591049ad0f4f`. The previously failing `tenant-acceptance` job succeeded on retry; all five jobs are green: `validate`, `result-pin-rate-limit-integration`, `tenant-integrity-db-integration`, `tenant-acceptance`, and `payment-review-rls-integration`.
- Payment-page validation on the same head also passed: [run #38991905578](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991905578).
- This closes the transient CI transport failure for this run only. Keep production verification of `cf-connecting-ip` provenance open: the disposable CI fixture does not prove the deployed Supabase/Cloudflare edge header cannot be caller-influenced. No production migration, merge, or deployment is authorized or recorded.
- Continue with Stage A production-safe review and A/B/C verification before Stage D. The SchoolPro MySQL migration remains incomplete; DataSub remains on Supabase.


## 2026-10-17 follow-up — evidence review for trusted result-PIN client IP

- Reviewed current Supabase documentation on [captured gateway request headers](https://supabase.com/docs/guides/observability/log-field-reference), which lists `cf-connecting-ip` among API Gateway log fields, and the Supabase community report [#34647](https://github.com/orgs/supabase/discussions/34647), where a caller-supplied `x-forwarded-for` value was observed as spoofed data followed by the real address while `cf-connecting-ip` held the real client address.
- This is supporting platform/community evidence, not a guarantee for this project's deployed configuration. Logs showing the header exists do not establish that the value read by `current_setting('request.headers')` cannot be supplied or altered by a caller. Production provenance is therefore still unverified.
- Safe next validation should use a controlled staging/project endpoint and inspect both the database-visible `request.headers` and gateway logs for requests with conflicting caller-supplied headers. Do not perform test writes against the production result-PIN RPC just to probe this, because failed attempts mutate production rate-limit state. If provenance cannot be demonstrated, move the public PIN check behind a trusted server/Edge Function or use a gateway-supported rate limit rather than treating a caller-visible header as authoritative.
- Latest CI status remains green on Stage A head `764d990cf8c28e014ddc06ed96c9591049ad0f4f`: [SchoolPro CI #38991905579](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991905579) and [payment validation #38991905578](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38991905578). This does not authorize merge or production rollout.


## 2026-10-17 follow-up — read-only production migration and security-advisor snapshot

- Read-only inspection of Supabase project `lnqsroyiybutkfngbyge` found 476 recorded migrations. The newest recorded production migration is `20261015161735_schoolpro_access_invitation_role_constraint`; the Stage A draft migrations dated 2026-10-15/16 that add receipt-RPC guards, payment-review write controls, result-PIN cooldown, gateway disablement, receipt bucket limits, and operational tenant-integrity repairs are **not present in the production migration ledger**. This confirms those draft changes have not been applied to this project through the inspected migration ledger. Do not infer that a migration is safe to apply merely because it is absent.
- The only Supabase branch returned by the branch listing was the default `main` branch; the API reported its status as `MIGRATIONS_FAILED`. No separate development branch was listed. Do not create a paid branch; investigate the branch status through read-only diagnostics before any branch operation.
- The production security advisor returned these items requiring triage:
  - **7 tables with RLS enabled and no policies:** `datasub_pin_recovery_attempts`, `schoolpro_access_invitations`, `schoolpro_account_challenges`, `schoolpro_initial_credentials`, `schoolpro_login_attempts`, `schoolpro_student_activation_challenges`, and `schoolpro_transcript_issues`. No-policy can be an intentional deny-all posture for server-only tables; inspect grants, service-role paths, and intended access before adding policies.
  - **9 anonymous-executable SECURITY DEFINER functions** and **154 authenticated-executable SECURITY DEFINER function findings** were reported by the advisor. These are broad execute-grant warnings, not 163 confirmed exploitable vulnerabilities. Review each function's intended public contract, internal authorization checks, search path, and role grants; do not mass-revoke access because tokenized public workflows may intentionally use anon execution.
  - **Leaked-password protection is disabled** in Supabase Auth. Treat this as an authentication-hardening backlog item; enabling it is a project setting change and is not performed by this read-only audit.
- This advisor output is a point-in-time scan (observed 2026-10-17). The broad SECURITY DEFINER warnings mean Stage A is not considered complete based only on the focused CI tests. Next: triage the seven no-policy tables and the highest-risk SchoolPro anon-executable functions against their source migrations, then add targeted regression checks and rerun CI. In parallel, trusted `cf-connecting-ip` provenance still requires a controlled staging/project verification; do not probe via production wrong-PIN RPC calls.
- No SQL writes, migration application, branch creation, merge, or deployment was performed during this inspection. Production remains on Supabase; the SchoolPro-to-MySQL cutover remains incomplete and DataSub remains on Supabase.


## 2026-10-17 follow-up — live read-only RLS/grant/function audit

- Queried production catalog metadata and function definitions using read-only SQL. No production data was modified. Results clarify the advisor findings:
  - All seven advisor-flagged tables have RLS enabled, zero policies, and no `anon` or `authenticated` SELECT/INSERT grants in the inspected privileges; `service_role` has SELECT and UPDATE. This is consistent with intentional server-only/deny-by-default access, but service-role consumers and expected insert/delete paths still need source-level verification before closing the findings.
  - The inspected SchoolPro public verification RPCs `accept_schoolpro_admission_offer`, `get_schoolpro_admission_offer`, `schoolpro_verify_result_code`, and `verify_schoolpro_document` are SECURITY DEFINER with an empty configured search path and executable by anon/authenticated. That is not automatically a vulnerability: each is a deliberately public/tokenized or serial-based flow, but token entropy, expiry/revocation, data minimization, and returned fields must be reviewed. The acceptance RPC locks the offer and application, checks token/expiry/status and validates name/email before recording acceptance. The read-only audit did not exercise those RPCs with real tokens.
  - Most importantly, the **live production** `check_schoolpro_result_pin(text,text,text,text)` definition does not contain the new failed-attempt cooldown logic. It validates admission number + term + session + PIN, applies fee/result holds, returns published results, and updates `last_used_at`; it does not read request headers or increment a rate-limit table. The migration ledger also does not contain the draft `20261016122000_schoolpro_result_pin_attempt_rate_limit` migration. Therefore, the cooldown and trusted-header changes are CI-validated draft work only and are **not active in production**.
- The live function selects a student by normalized admission number alone (latest `created_at` wins), then validates the PIN against that student's row. Because admission numbers may be reused by different schools, add a targeted review/test for duplicate admission numbers across tenants and decide whether the public checker needs a school identifier or globally unique admission-number constraint. This observation is not proof of a cross-tenant authorization bypass; it is an ambiguity and account-selection risk that should be tested.
- Security priority updated: (1) resolve production result-PIN brute-force protection safely without mutating production with failed attempts; (2) review public verification/token RPC contracts; (3) inspect server-only tables and service-role consumers; (4) continue full Stage A function/tenant audit. The broad advisor warning about 154 authenticated-executable SECURITY DEFINER functions remains a triage list, not a reason to revoke all grants.
- The read-only SQL audit initially failed due to an invalid `has_table_privilege(..., 'ALL')` probe; the corrected SELECT/INSERT/UPDATE privilege query succeeded. No schema or privilege changes were made. No migration, deployment, merge, or paid branch was created.


## 2026-10-17 follow-up — result-PIN duplicate-admission resolution regression

- Live catalog confirmed `schoolpro_students` has a unique constraint on `(school_id, admission_number)`, not a global unique admission number. The read-only duplicate scan found zero currently active admission-number groups shared across schools, but the schema expressly permits such duplicates, so the checker must handle them safely.
- Updated the **draft-only** `20261016122000_schoolpro_result_pin_attempt_rate_limit.sql` to resolve the student by the supplied admission number **and** an active, unexpired PIN matching the requested term/session, before selecting a student row. This prevents a newer student in another school with the same admission number from shadowing the intended student's valid PIN. Existing generic invalid-details response and hashed per-admission/network cooldown remain.
- Extended `scripts/test-schoolpro-result-pin-rate-limit.integration.sql` with two schools that deliberately share `SP-TEST-001`, where the second school has the newer student record and a different PIN. The fixture asserts that the older student's valid PIN returns the correct student and school. Added a static regression assertion in `scripts/test-schoolpro-result-pin-rate-limit.mjs`.
- Draft code commits: migration `d44f7bd61198926ce7aeaea106ed3f7f561c1f1c`; duplicate-admission fixture `c0e8392c9d7884f216b996e7bc20c357b460290e`; static guard `47d966c1bcb3a5210b442ca70cf224e3f5cae344`. Latest Stage A head: `47d966c1bcb3a5210b442ca70cf224e3f5cae344`.
- CI was queued/running for the latest head when this note was written: [SchoolPro CI #38992554112](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38992554112); [payment-page validation #38992554128](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38992554128). Do not mark this regression fixed until the full latest-head CI result is confirmed.
- No production migration, merge, deployment, or database data change occurred. Production's deployed checker still lacks the cooldown until a reviewed migration is separately approved and applied; do not test this by sending failed PINs to production.


## 2026-10-17 follow-up — duplicate-admission regression passed; public verification RPC review

- Latest Stage A head `47d966c1bcb3a5210b442ca70cf224e3f5cae344` passed all five SchoolPro CI jobs, including `result-pin-rate-limit-integration`, `payment-review-rls-integration`, `tenant-integrity-db-integration`, `tenant-acceptance`, and `validate`: [run #38992554112](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38992554112). Payment-page validation also passed on that exact head: [run #38992554128](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38992554128).
- The disposable result-PIN fixture now proves the duplicate-admission scenario: two fixture schools share `SP-TEST-001`, the newer student's PIN differs, and the older student's correct PIN returns the older student's school and identity. This is draft CI evidence only; production still runs the older function until reviewed and approved migration application.
- Read-only review of public SECURITY DEFINER verification functions:
  - Admission-offer lookup/acceptance uses a UUID public token with a unique index; acceptance locks offer and application rows, checks expiry/status, and writes acceptance. The offer table currently has zero rows, so no live token records were exposed by this audit. Follow-up should still verify token generation is cryptographically random, acceptance is idempotent as intended, and returned offer/application fields are limited to public-facing data.
  - Result verification uses a globally unique `verification_code` and document verification uses a serial number that is unique **per school**. The live document verifier searches by serial alone, which is potentially ambiguous by design if a duplicate serial is later issued by another school. Current read-only data check found zero cross-school duplicate serials across 141 document records, and zero result-verification rows. Keep a regression test for duplicate serials or make the public serial globally unique before considering this path closed.
  - The public application-submission RPC accepts `p_school` and checks published site settings/admissions-open before inserting. Continue checking rate limiting, spam controls, and public data exposure; no unauthenticated test submissions were created.
  - All inspected public functions pin an empty `search_path`; that reduces object-shadowing risk but does not replace function-specific authorization, token entropy, expiry, data minimization, or abuse-control review.
- The result-PIN cooldown/trusted-header migration is still draft-only and absent from production's migration ledger. Its static + disposable PostgreSQL checks pass, including eight concurrent wrong-PIN calls on a shared spoofed-XFF/Cloudflare-IP fixture, but the actual production gateway's `cf-connecting-ip` provenance has not yet been independently verified. Do not send failed PIN attempts to production to test it.
- Next: add/verify public-RPC abuse-control and document-serial ambiguity regression coverage; then continue Stage A authorization review and A/B/C acceptance before D. No production migration, SQL write, merge, deployment, or paid branch was performed.


## 2026-10-17 follow-up — global document serial uniqueness hardening (draft CI pending)

- The public `verify_schoolpro_document(p_serial)` RPC accepts a serial without a school ID and normalizes it case-insensitively, while the existing unique constraint only guarantees uniqueness of the raw serial within each school. Read-only production audit found 141 document records and zero duplicate normalized serials (including case/whitespace normalization), so current data passes the proposed preflight.
- Added draft migration `supabase/migrations/20261017103000_schoolpro_document_serial_global_uniqueness.sql` on Stage A branch. It fails closed if normalized duplicates already exist, then creates a global unique index on `upper(trim(serial_number))`, preventing future cross-school/case-normalized ambiguity in the public verifier. It does not alter serials or document records.
- Added static guard `scripts/test-schoolpro-document-serial-uniqueness.mjs` and disposable PostgreSQL integration fixture `scripts/test-schoolpro-document-serial-uniqueness.integration.sql`; wired both into CI. The integration fixture checks that a case-normalized duplicate from a different school is rejected by the index.
- Stage A code commits: migration `c3095b439560ec0979628843997890d60013b81b`, static guard `03532f4b7040ced6737899687c84fd28902cd320`, workflow/static wiring `facb54d2a103a0de8640eb0e52d70c155fff0f20`, integration fixture `21964022fc132266dac245d25505eb3b4b97a5d4`, and integration workflow wiring `ce11a747aefa5bb080489b61421af1770aa0ac77`. Latest changes are draft-only and must be validated by the latest-head CI before treating the hardening as complete.
- Prior result-PIN duplicate-admission fix was confirmed green on head `47d966c1bcb3a5210b442ca70cf224e3f5cae344` with all five CI jobs successful and payment-page validation successful. The newer document-serial migration has its own pending CI run and does not change production until separately reviewed and approved.
- No production migration, database write, merge, or deployment occurred. Do not apply the global index to production until latest-head CI passes and the migration plan is explicitly approved.


### CI progress update — 2026-10-17 (latest document-serial migration head)

- Latest Stage A head `ce11a747aefa5bb080489b61421af1770aa0ac77`: [SchoolPro CI #38992801989](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38992801989) has completed successfully for `result-pin-rate-limit-integration` (including the new global document-serial uniqueness integration step), `payment-review-rls-integration`, and `tenant-integrity-db-integration`.
- At the last check, `validate` and `tenant-acceptance` were still running with no reported failure. Do not call the entire workflow green until those two jobs finish successfully. Payment-page validation for the same head is queued/running at [#38992801845](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38992801845).


### CI completion update — 2026-10-17 (global document-serial uniqueness)

- Rechecked [SchoolPro CI #38992801989](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38992801989) on Stage A head `ce11a747aefa5bb080489b61421af1770aa0ac77`. All five jobs are now **successful**: `validate`, `result-pin-rate-limit-integration` (including the global document-serial uniqueness integration and concurrent result-PIN cooldown test), `payment-review-rls-integration`, `tenant-integrity-db-integration`, and `tenant-acceptance`.
- [Payment-page validation #38992801845](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38992801845) also completed successfully on the same head.
- Scope of evidence: static checks, build/typecheck, disposable PostgreSQL integration fixtures, and the configured read-only two-school tenant acceptance checks. This does **not** establish production gateway provenance for `cf-connecting-ip`, apply draft migrations, or prove full production schema parity.
- Next Stage A review item: audit service-role consumers and expected write paths for the seven RLS-enabled/no-policy tables; keep public verification RPC abuse controls and production result-PIN cooldown rollout under review. Continue A/B/C re-verification before D. SchoolPro MySQL migration remains incomplete; DataSub remains on Supabase.
- No production SQL write/migration, merge, deployment, or paid branch creation occurred. PR #106 and PR #107 remain separate draft workstreams pending explicit owner approval.


## 2026-10-17 follow-up — SchoolPro login rate-limit header review (CI pending)

- During the server-only table consumer audit, read-only production function definitions showed `schoolpro_take_login_attempt` is callable only by `service_role`, and the account/staff/student login Edge Functions use it to throttle attempts. Source review found both `supabase/functions/schoolpro-account-login/index.ts` and `supabase/functions/schoolpro-student-login/index.ts` derived the IP bucket from the leftmost `X-Forwarded-For` value, which can be caller-influenced and therefore should not be treated as a trusted rate-limit identity.
- Draft Stage A code now uses `cf-connecting-ip` (fallback `unknown`) for the network bucket in both functions while retaining the separate email/account+school/admission buckets. Added `scripts/test-schoolpro-login-rate-limit-trusted-ip.mjs` and wired it into the validation job.
- Commits on `release/stage-a-auth-tenant-isolation`: account login `2fabf1c74ffef9bd4d86e490c33adc9922b04412`; student login `0c0c82844e67bf0b5064a87630c8e62ed5004ca8`; static guard `f02532a73cf83d71ef8ef1f71168797b19e502e6`; CI wiring `f98a695db99014a465a3f6c4744cfddb2b8089ca`. Verify current branch head and latest workflow run before marking tests passed.
- **Trust boundary remains open:** using `cf-connecting-ip` is safer than using the caller's XFF value only if the deployed gateway securely supplies/overwrites that header. The prior production provenance caveat applies here too. The static guard checks source selection, not gateway behavior. Do not use production login attempts to probe header provenance; use a controlled staging/project endpoint and compare database/Edge-visible headers with gateway logs. If provenance cannot be established, enforce IP rate limiting at a trusted gateway or server boundary.
- Read-only production catalog inspection also found service-role-only RPCs for account challenge/credential handling, student activation challenges, invitation acceptance, and DataSub PIN recovery. This is a preliminary source-to-consumer review, not yet a closure of the seven no-policy-table advisor findings; continue verifying expected service-role call paths and lifecycle/cleanup behaviour. No production write, migration, merge, deployment, or paid branch creation occurred.


### CI follow-up — live tenant-acceptance transport failure on login-IP change

- SchoolPro CI run [#38993238868](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38993238868) on head `f98a695db99014a465a3f6c4744cfddb2b8089ca`: `payment-review-rls-integration`, `tenant-integrity-db-integration`, and `result-pin-rate-limit-integration` passed; payment-page validation [#38993238902](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38993238902) passed. The live `tenant-acceptance` job failed at the School B read-only invoice count after its three attempts with HTTP status 0 and an empty message; preceding tenant checks passed. This resembles the prior transient network/transport failure, not a demonstrated authorization bypass. Do not label the full run green until the validation job completes and the failed live job is rerun successfully.
- An attempt to rerun the failed job while the workflow remained in progress was rejected by GitHub; retry after the run concludes.
- Latest source changes still need a successful full-head CI result. No production mutation or deployment occurred.


### CI completion update — login rate-limit trusted-IP change (2026-10-17)

- Rechecked [SchoolPro CI #38993238868](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38993238868) on Stage A head `f98a695db99014a465a3f6c4744cfddb2b8089ca`. The workflow initially failed only at live `tenant-acceptance`; after the run finished, rerunning that failed job succeeded. Final run status is **completed / success**, with all five jobs green: `validate`, `tenant-acceptance`, `payment-review-rls-integration`, `tenant-integrity-db-integration`, and `result-pin-rate-limit-integration`.
- [Payment-page validation #38993238902](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38993238902) also passed on the same head. The successful rerun resolves the transient HTTP status 0 transport failure for this CI run; it is not evidence that the tenant test itself was skipped.
- The new trusted-IP source guard confirms both account and student login Edge Functions use `cf-connecting-ip` instead of caller-controlled leftmost `X-Forwarded-For`, retaining their existing account/school/admission buckets. **Production gateway header provenance is still unverified**, so do not treat this as a production-ready IP trust boundary until verified safely in controlled staging or moved behind a trusted server/gateway boundary.
- Follow-up: continue reviewing the seven RLS-enabled/no-policy tables against all service-role consumers and lifecycle/cleanup paths; review public verification RPC abuse controls; then run explicit A/B/C acceptance before D. The SchoolPro-to-MySQL migration remains incomplete; DataSub remains on Supabase.
- All changes remain on draft/unmerged branches. No production migration, SQL write, merge, deployment, or paid branch creation was performed.


## 2026-10-17 follow-up — service-role consumer audit (partial; remaining tables not closed)

- Reviewed the current Stage A branch source for `supabase/functions/invite-school-staff/index.ts`, `schoolpro-account-login/index.ts`, `schoolpro-student-login/index.ts`, and `schoolpro-render-transcript/index.ts` to map several server-only table accesses found during the read-only production audit.
- Confirmed call paths:
  - `schoolpro_access_invitations`: the staff-access Edge Function authenticates the caller with `auth.getUser(token)`; its invitation listing/update/create paths are scoped by the supplied/authorized school ID, and acceptance delegates token-hash validation to `schoolpro_accept_access_invitation`. Continue validating the full school-role authorization path in this function before considering it closed.
  - `schoolpro_initial_credentials`: account login checks an unconsumed, unexpired initial credential before entering the forced password-change path; staff invitation flow checks/renews the credential for the existing user. These accesses use the service-role client and depend on Edge Function authorization and narrow filters.
  - `schoolpro_account_challenges`: staff invitation flow deletes stale challenges for a user before issuing/reissuing access. The account-login function consumes a challenge through `schoolpro_consume_account_challenge`; inspect the database function's one-time-use/expiry/password rules as part of final closure.
  - `schoolpro_student_activation_challenges`: student login inserts a hashed activation challenge after its rate-limit and school/student lookup stages; review challenge expiry, consumption, cleanup, and binding to the authenticated student before closing.
  - `schoolpro_transcript_issues`: transcript rendering first calls the caller-scoped `schoolpro_student_transcripts` RPC and requires a matching allowed, non-revoked snapshot before its service-role lookup by issue and student ID. Keep the RPC's role/tenant predicate as the primary authorization boundary; the service-role lookup alone is not sufficient authorization.
  - Both account and student login call `schoolpro_take_login_attempt` through service role. Their new source selection for IP buckets is covered by the static test, but secure `cf-connecting-ip` provenance at the deployed gateway remains unverified (see preceding entry).
- The seven production RLS-enabled/no-policy tables remain a **partial audit finding, not automatically a vulnerability and not yet closed**. Current read-only privilege findings showed no direct `anon`/`authenticated` table grants and service-role access only, consistent with server-only intent. This still requires checking every consumer, RPC implementation, expected insert/update/delete path, cleanup/retention and error behavior. In particular, the current Edge Function review does not yet fully close `datasub_pin_recovery_attempts`, `schoolpro_login_attempts`, or all lifecycle paths for the challenge/credential tables.
- No schema, grant, RLS policy, production row, or secret was changed. Do not mass-revoke service-role access or add broad policies merely to silence the advisor. Next: inspect the relevant challenge-consumption and invitation RPC definitions plus DataSub PIN-recovery consumer paths, then record a per-table disposition; separately continue public RPC abuse-control review and A/B/C acceptance before D.


### Read-only database function/privilege follow-up — challenge lifecycle (2026-10-17)

- Read-only production SQL confirmed these functions are executable by `service_role` and the database owner, not by `anon` or `authenticated`: `schoolpro_accept_access_invitation`, `schoolpro_consume_account_challenge`, `schoolpro_consume_student_challenge`, `schoolpro_initial_challenge`, `schoolpro_set_initial_credential`, and `schoolpro_take_login_attempt`. The public-facing transcript wrapper `schoolpro_student_transcripts(uuid)` is executable by authenticated callers and delegates to a private SECURITY DEFINER function with empty `search_path` and explicit active-account/student-or-guardian-or-authorized-staff checks.
- `schoolpro_consume_account_challenge` locks an active, unconsumed, unexpired initial credential, enforces a 10-character minimum and rejects the surname as the new password, validates the unexpired token hash, deletes the challenge and marks the initial credential consumed. `schoolpro_initial_challenge` locks the initial credential, validates the surname hash, deletes prior challenges and stores the new hash. These are source-level findings; no production writes were performed.
- `schoolpro_consume_student_challenge` locks an unexpired challenge, verifies the student remains unlinked and active/graduated, then deletes challenges for that student. `schoolpro_take_login_attempt` removes login-attempt rows older than one day and expired student activation challenges; cleanup of expired account challenges is not performed in that RPC and should be checked against the challenge issuance/consumption lifecycle.
- `schoolpro_accept_access_invitation` locks a matching unexpired, unaccepted invitation bound to the active profile email, validates every linked student belongs to the invitation's school before guardian linking, then marks the invitation accepted. The Edge Function separately authenticates the caller and checks school leadership/super-admin authority before listing, regenerating or creating invitations; this is a layered control, not a replacement for database grants.
- `claim_datasub_pin_recovery(uuid)` is also service-role-only and writes to `datasub_pin_recovery_attempts`; its DataSub caller/consumer was not available in the SchoolPro repository audit. Do not modify DataSub or its production project as part of SchoolPro work; track that table separately and inspect the DataSub repo/Edge Function before closing its finding.
- Current conclusion: the no-policy tables appear intentionally server-only based on grants and inspected consumers, but the finding remains **partially open** pending full consumer enumeration, account-challenge cleanup/retention review, and DataSub PIN-recovery caller review. Do not add broad RLS policies or change grants merely to silence the advisor. No production mutation, migration, merge, deployment, or paid branch creation occurred.


## 2026-10-17 follow-up — public verification/admission RPC review (read-only; follow-up required)

- Read-only production catalog inspection confirmed `accept_schoolpro_admission_offer(uuid,text,text,text)`, `get_schoolpro_admission_offer(uuid)`, `schoolpro_verify_result_code(text)`, and `verify_schoolpro_document(text)` are SECURITY DEFINER functions with empty `search_path`, and EXECUTE is granted to `anon` and `authenticated` (intended public entry points). No changes were made.
- Admission offer tokens default to `gen_random_uuid()`; the public lookup returns offer number, offered class, letter text, issue/expiry timestamps, status, instructions, applicant name and application number. It rejects expired non-accepted offers. Acceptance locks the offer and application rows, checks token, expiry, status and required name/email, records acceptance and updates offer/application status. **Expiry is nullable**, so offer creation paths must be checked to ensure offers intended to expire always receive an expiry. The RPCs have no visible per-token/IP rate-limit call in their bodies; assess trusted gateway protection and add safe abuse-control coverage if missing. Bearer-token possession is the authorization model, so token secrecy and minimal returned applicant data matter.
- Public result-code verification normalizes the code and returns school/student names, admission number, class, term/session, issue time, and the stored `snapshot` JSON when status is valid and not revoked. The table default uses `gen_random_bytes(24)` encoded as hex (192 bits of random material). No per-code/IP throttling is present in the inspected function body. Review the snapshot schema for unnecessary personal data and confirm intended public disclosure; keep token guessing controls at a trusted edge/gateway or server boundary.
- Public document verification normalizes case/whitespace, returns serial, title, document type, status, issue time and school name, and returns student name only for issued documents. The draft global normalized serial unique index is covered by successful disposable PostgreSQL CI but is not applied to production. Existing read-only audit found 141 document records and no normalized duplicates.
- These findings are **review items, not a claim of confirmed exploitation**. Empty `search_path` and token entropy are positive controls but do not replace rate limits, expiry policy, payload minimization, or production gateway validation. Next: inspect offer creation paths for nullable expiry, review result snapshot fields, and design/verify public-RPC abuse controls in CI before any migration approval. No production SQL write, migration, merge, deployment, or paid branch creation occurred.


### Admission-offer expiry source check — 2026-10-17

- Read-only inspection of production `issue_schoolpro_admission_offer(uuid,text,timestamptz,text)` found it is SECURITY DEFINER with empty `search_path`, requires an authenticated caller, locks the application, checks admissions module permission and a school-scoped proprietor/administrator/admissions-officer/registrar role, and rejects a supplied expiry in the past.
- The function deliberately permits `p_expiry IS NULL`; therefore the nullable expiry found on `schoolpro_admission_offers` is not a schema mismatch but an explicit API behavior. The product/security decision remains open: confirm whether indefinite bearer-link offers are intended. If not, require a future expiry in the RPC and UI with a migration + regression fixture; do not silently change production behavior.
- Each issue/reissue generates a fresh UUID token and replaces the prior token; public lookup/acceptance lock rows where required. Reissue resets offer status to offered and clears accepted_at, so confirm the UI makes reissue semantics clear to school staff and the recipient. No offer was issued/reissued and no production row was changed during this audit.


## 2026-10-17 — public RPC abuse-control and result snapshot review (draft remediation in Stage A)

### Read-only production findings

- Catalog inspection of the live Supabase project found **0** rows in `schoolpro_result_verifications`, **141** document issues, **16** admission applications, and **0** admission offers at audit time. Therefore no stored live result snapshot could be sampled; the review used the actual issuer/verifier function definitions and public UI contract. No PII values were copied into this handover.
- `issue_schoolpro_result_verification(uuid,text,text)` currently builds `snapshot.results[]` with `subject_id`, `total_score`, and `assessment_scores`, and generates a code by truncating a UUID to 16 hex characters (64 bits). The public verifier returns the full snapshot to anyone holding the code. This is unnecessary assessment-level disclosure, and the snapshot shape conflicts with `src/pages/schoolpro/SchoolProResultChecker.tsx`, which reads `snapshot.total` and `snapshot.average`. The live column default already uses 24 random bytes, but the issuer overrides it with the shorter token.
- Draft migration `supabase/migrations/20261017120000_schoolpro_result_verification_minimal_snapshot.sql` replaces the issuer to preserve the existing authenticated, school-scoped result-manager authorization and locked/published-only rule, stores only aggregate `total` and `average` fields consumed by the public page, and uses 24 random bytes (192 bits) for the verification code. Static regression guard `scripts/test-schoolpro-result-verification-exposure.mjs` checks token entropy, minimal snapshot fields, role/module checks and the UI contract; it is wired into the Stage A CI workflow. This migration is draft-only and has not been applied to production.
- `verify_schoolpro_document(text)` returns only issued/revoked document metadata, and suppresses student name for revoked documents. It has no function-level rate limiter. Serial defaults use a 12-hex suffix (~48 random bits); draft migration `20261017103000_schoolpro_document_serial_global_uniqueness.sql` enforces normalized global uniqueness but is not in the production migration ledger. Consider trusted-edge throttling/monitoring for repeated invalid serials.
- `get_schoolpro_admission_offer(uuid)` exposes offer/applicant display fields only, and `accept_schoolpro_admission_offer(...)` locks rows and validates status/expiry/name/email. Offer tokens are UUIDs (~122 random bits); expiry can be null by design in the current issuer. Neither function body shows per-IP/token throttling. Review product policy on indefinite links and apply trusted-edge limits for repeated invalid tokens.
- `submit_schoolpro_application(...)` is an anonymous-executable SECURITY DEFINER RPC. It checks that the target school's admissions page is published and open and requires basic fields, but its current body has no explicit request rate limit, strict per-field length limits, or robust email/phone/date/gender validation. It returns an application ID, application number, and public token. This is the highest-priority remaining public abuse-control gap because submissions are cheap to repeat and may create spam/operational load.
- The public result-code verifier is also anonymous-executable and has no function-level rate limiter. The live issuer's 64-bit token and detailed snapshot were identified as concrete fixes above. The draft 192-bit code materially reduces guessing risk, but gateway abuse controls/monitoring remain advisable; the public RPC should not trust caller-supplied `X-Forwarded-For` for database rate-limit identity. Production provenance of `cf-connecting-ip` is not yet independently verified.

### Status / next steps

- Static regression checks are in the current Stage A CI run (head `28abee591fc2d33be8b12075fc7612813e84d194`); record final job outcomes before declaring the draft fix validated.
- The result-snapshot data-exposure review is complete at source/schema level, with a targeted draft remediation and test. Production rows could not be inspected for actual snapshot shape because the table was empty.
- The public abuse-control review is complete enough to rank gaps, but remediation remains open: prioritize rate limiting and input bounds for anonymous admission submission, then trusted-edge throttling/monitoring for document and offer/result-code verification. Do not derive a DB security key from an unverified request header. Prefer a trusted edge/gateway rate limit or a server/Edge Function boundary until header provenance is verified.
- No production migration, data write, deployment, merge, or paid development branch was performed. All changes remain on the open draft Stage A PR. Do not mark production remediated until approved migrations are applied and verified.


### Result-verification remediation test coverage added — 2026-10-17

- Added disposable PostgreSQL integration fixture `scripts/test-schoolpro-result-verification-exposure.integration.sql`, which executes the actual draft migration `20261017120000_schoolpro_result_verification_minimal_snapshot.sql` against minimal test-only dependencies. It checks 48-character uppercase hex codes, aggregate snapshot equals the locked/published rows only, absence of detailed assessment keys, and rejection when no locked published results exist.
- Added CI job `result-verification-exposure-integration` in `.github/workflows/ci.yml` to run that fixture against PostgreSQL 16, in addition to the static source/UI guard. CI must complete successfully on the commit containing the workflow wiring before calling this test coverage verified.
- Code is still draft-only on `release/stage-a-auth-tenant-isolation`; the master handover is updated on `migration/mysql-schoolpro-foundation`. No production schema or rows were changed.


### Result-verification integration fixture correction — 2026-10-17

- First execution of new job `result-verification-exposure-integration` in [SchoolPro CI #38994175325](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38994175325) failed before applying the migration because the psql include directive lost its leading backslash in the committed fixture. The other completed database integration jobs passed; live tenant acceptance independently hit the previously observed intermittent HTTP status 0 on School B invoice reads.
- Fixed the fixture directive to the literal psql `\\ir ../supabase/migrations/20261017120000_schoolpro_result_verification_minimal_snapshot.sql` in commit `e9eafa043845e5500f17e508161c11e12c40f8f0`. A fresh CI run on this corrected commit is required before considering the new integration fixture successful. Do not infer test success from the static guard or from the earlier failed fixture run.


### Result-verification integration outcome — 2026-10-17

- Corrected-fixture run [SchoolPro CI #38994246728](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38994246728), head `e9eafa043845e5500f17e508161c11e12c40f8f0`, has **passed** the new `result-verification-exposure-integration` job on disposable PostgreSQL 16. The same run's `payment-review-rls-integration` and `result-pin-rate-limit-integration` jobs also passed. At the time of this note, `validate`, `tenant-integrity-db-integration`, and live `tenant-acceptance` were still running; the run is not yet a full CI pass.
- The disposable fixture validates 192-bit token format and minimal aggregate snapshot against actual migration SQL. It does not apply the migration to production or prove production behavior until approved migration rollout.


### Latest CI checkpoint — 2026-10-17

- On corrected fixture head `e9eafa043845e5500f17e508161c11e12c40f8f0`, [SchoolPro CI #38994246728](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38994246728) now reports successful `tenant-acceptance`, `payment-review-rls-integration`, `result-verification-exposure-integration`, `result-pin-rate-limit-integration`, and `tenant-integrity-db-integration` jobs. This run's `validate` job remains in progress at the mobile-layout/browser test step, so do not mark the entire workflow green until that job finishes.
- The intermittent tenant HTTP status 0 seen in the prior attempt did not recur in this corrected-fixture run; the live two-school acceptance job completed successfully.


### Anonymous admissions RPC abuse-control remediation — 2026-10-17

- Added draft migration `supabase/migrations/20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql` on the open Stage A branch. It replaces the existing `public.submit_schoolpro_application(...)` function in place, preserving its response keys (`application_id`, `application_number`, `public_token`), published/open admissions check, SECURITY DEFINER boundary and empty `search_path`. `CREATE OR REPLACE` preserves the existing function grants; this is not a production change.
- Server-side validation now caps first/last names at 80 characters, guardian name at 120, class at 80, previous school at 160, phone text at 32, email at 254, and gender at 32. It requires alphanumeric content for name/class fields, validates phone characters and 7–15 normalized digits, validates a provided email, restricts gender to supported normalized options, and rejects future or pre-1900 dates of birth.
- Adds rolling contact-based limits: at most 3 submissions per normalized guardian phone/email contact per hour and 5 per 24 hours, scoped to the target school. Transaction-scoped advisory locks are acquired in stable order for normalized phone and email so concurrent submissions sharing either contact serialize before counting. Phone formatting differences normalize to the same digits. No caller-controlled `X-Forwarded-For`, `X-Real-IP`, or `CF-Connecting-IP` value is used as a database identity.
- Added static guard `scripts/test-schoolpro-public-admission-abuse-controls.mjs` and disposable PostgreSQL integration fixture `scripts/test-schoolpro-public-admission-abuse-controls.integration.sql`. The fixture exercises the actual migration, verifies the unchanged response contract, permits three same-contact submissions, rejects the fourth even with phone formatting changed, confirms another school is not blocked by the first school's submissions, and rejects oversized names, malformed email, and future date of birth. Both tests are wired into `.github/workflows/ci.yml`.
- CI run: [SchoolPro CI #38994773696](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38994773696), commit `fbe6ee66ee439e74509b27ae4f406b51681d77c2`, includes the new `public-admission-abuse-integration` job and static guard. At handover update time the run was still in progress; record the final job outcomes before treating this remediation as test-verified.
- **Limitations/open follow-up:** this is contact-based throttling, not a substitute for trusted-edge IP/device throttling. A determined attacker can rotate contact details; apply gateway/Edge Function rate limits and monitoring when the production trusted-client-IP provenance is verified. Also check real admissions form gender values against the supported list before release. Do not apply this draft migration to production until the Stage A PR is reviewed and explicitly approved. No production migration, data write, merge, deployment, or paid Supabase branch was performed.


### Public admissions abuse-control CI checkpoint — 2026-10-17

- The first SchoolPro CI attempt, [#38994773696](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38994773696) on `fbe6ee66ee439e74509b27ae4f406b51681d77c2`, correctly caught a static-test assertion that expected nullable `previous_school` and `guardian_email` lengths to be checked without their `coalesce(...)` wrappers. The actual disposable PostgreSQL integration job passed; the static guard was corrected to assert those nullable-field bounds explicitly.
- On corrected head `f7da65efec68efdac88e2383f918d9de84815798`, [SchoolPro CI #38994877405](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38994877405) reports **success** for `public-admission-abuse-integration`, `result-verification-exposure-integration`, `payment-review-rls-integration`, `tenant-integrity-db-integration`, and `result-pin-rate-limit-integration`. At the time of this checkpoint, the `validate` job and live `tenant-acceptance` job were still running; do not call the complete workflow green until both finish.
- The new integration fixture runs the migration in disposable PostgreSQL, confirms three submissions can be accepted and the fourth is rejected despite phone-format variation, confirms limits are school-scoped, and rejects overlong names, malformed email and future date of birth. It does not alter or test live production rows.


### Final CI result for admission abuse-control remediation — 2026-10-17

- Rechecked [SchoolPro CI #38994877405](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38994877405): workflow status is `completed`, conclusion `success`; all seven jobs passed, including `validate` and live `tenant-acceptance`. Head: `f7da65efec68efdac88e2383f918d9de84815798`. The earlier in-progress note above is superseded by this final result.

### Trusted-edge public admissions gateway — draft implementation, CI pending

- Public application UI previously called `submit_schoolpro_application` directly from the browser. The current draft routes the UI through `supabase.functions.invoke('schoolpro-public-admission', ...)` and adds `supabase/functions/schoolpro-public-admission/index.ts`.
- The Edge Function verifies Cloudflare Turnstile server-side using Siteverify, and fails closed if the secret or expected hostname configuration is missing, Siteverify fails, the token is invalid/expired/replayed, the action differs from `schoolpro_public_admission`, or the returned hostname is not allowlisted. It caps the request body, applies a bounded Siteverify timeout, checks an explicit origin allowlist, and does not read client IP headers or send `remoteip` to Siteverify. Cloudflare requires server-side Siteverify; client-side widget completion alone is not sufficient. See [Cloudflare server-side validation](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/).
- Draft migration `20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql` now revokes direct execution from `PUBLIC`, `anon`, and `authenticated`, and grants execution only to `service_role`. The Edge Function calls the RPC using its server-side service-role key after token verification. The existing contact-based rolling limits and input validation remain as defense in depth.
- The browser now renders a Turnstile widget from `VITE_TURNSTILE_SITE_KEY`; the Supabase function is configured with `verify_jwt = false` because it is an anonymous public endpoint protected by its own mandatory challenge verification and explicit origin/hostname checks. Static guard `scripts/test-schoolpro-public-admission-edge-gateway.mjs` checks the fail-closed Siteverify flow, expected action/hostname, bounded body and timeout, no IP-based identity, no direct browser RPC, and service-role-only function grant. It is wired into SchoolPro CI. The disposable PostgreSQL integration test also asserts the anon/authenticated execution grants are denied and service_role execution is allowed.
- **CI for the new gateway changes is pending** at handover update time: latest branch head `11c5d0c6d05995ee22f49294860c604c5dc373c7`, [SchoolPro CI #38995267896](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38995267896). Do not call the gateway test-verified until all relevant jobs pass.
- **Required configuration before deployment:** create a Turnstile widget in Cloudflare and configure the public Render build variable `VITE_TURNSTILE_SITE_KEY`; set Supabase Edge Function secrets `TURNSTILE_SECRET_KEY`, `TURNSTILE_ALLOWED_HOSTNAMES` (comma-separated exact production hostnames), and `SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS` (comma-separated exact allowed origins including scheme). Confirm the actual customer-facing hostname(s) before setting allowlists. Keep the secret server-side only. Do not deploy the frontend change without these values because the form intentionally fails closed while unconfigured.
- **Trust boundary:** no IP-based database rate key has been added, and no assumption has been made that `cf-connecting-ip` is trustworthy at this service boundary. This implementation is a challenge-verified gateway plus origin/hostname checks and contact-based rate limiting; it is not a network-layer request-rate limiter against volumetric floods. Consider provider-native gateway/WAF rate limiting only after the actual production proxy chain and header provenance are verified.
- No production migration, function deployment, frontend deployment, branch merge, or production data write was performed. The implementation is on the open Stage A draft branch and requires CI review plus configuration before any deployment approval.


### Trusted-edge gateway CI checkpoint — 2026-10-17

- Latest Stage A head under test: `11c5d0c6d05995ee22f49294860c604c5dc373c7`; [SchoolPro CI #38995267896](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38995267896).
- Confirmed successful so far: `npm run typecheck`; new static `test-schoolpro-public-admission-edge-gateway.mjs`; existing public-admission abuse-control static guard; disposable PostgreSQL public-admission abuse/grant test; result-verification exposure integration; result-PIN integration; tenant-integrity integration; payment-review RLS integration; live tenant acceptance.
- The `validate` job was still running its mobile/customer-layout Playwright checks; `npm run build` had not started yet. Therefore this new gateway change is **not yet fully CI-green**. Recheck the run and append the final result after it completes.

## 11. Stage A public-RPC abuse controls — CI and trusted-edge checkpoint (2026-10-17)

- **Verified CI evidence:** SchoolPro CI run [#38994877405](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38994877405), commit `f7da65efec68efdac88e2383f918d9de84815798`, completed successfully. Queried the run's jobs directly: all seven jobs completed with `success`: `validate`, `tenant-acceptance`, `public-admission-abuse-integration`, `result-verification-exposure-integration`, `result-pin-rate-limit-integration`, `tenant-integrity-db-integration`, and `payment-review-rls-integration`. This is CI evidence for that exact commit only; it is not evidence that its draft migrations are applied to production.
- **Admission RPC protections in the tested draft:** normalized guardian contact limits of 3 submissions/hour and 5 submissions/24 hours per school; transaction-level serialization for matching normalized phone/email; bounded field lengths and validation of phone/email/gender/date-of-birth; published/open-admissions check retained. These controls do not prevent an attacker from rotating contact details.
- **Trusted-edge work status:** Turnstile/edge throttling was reported as implemented in the parallel Stage A workstream, but production trust boundaries and the current source-to-deployment configuration have not yet been independently verified in this checkpoint. Treat it as implementation-in-progress until the relevant source, tests, deployment configuration, and request flow are inspected.
- **Security invariant:** do **not** use `cf-connecting-ip`, `x-forwarded-for`, or any other client-supplied forwarding header as a database security principal or database-side rate-limit key unless the trusted proxy chain is proven and the application accepts the header only from that trusted edge. A caller must not be able to choose the identity used for throttling. Prefer edge-managed Turnstile/rate limiting and server-verified request metadata; retain contact-based RPC limits as a separate layer. Do not add an unverified IP-based database mechanism.
- **Required trusted-edge verification before marking complete:** (1) inspect the edge/function source and configuration; (2) establish which component terminates public traffic and strips/replaces spoofable forwarding headers; (3) verify Turnstile tokens server-side, including hostname/action/expiry and fail-closed behaviour where required; (4) confirm rate-limit keys and thresholds, including missing/invalid-token handling; (5) run automated tests for forged forwarding headers, absent/malformed tokens, replayed tokens, repeated requests and legitimate traffic; (6) document which checks are source/unit tests versus live edge tests. Do not claim production header integrity from CI source tests alone.
- **No production operation:** no production migration, deployment, secret/config change, database write, or PR merge was performed by this checkpoint. PR #106 remains a separate unmerged Stage A workstream; PR #107 remains the draft MySQL foundation workstream. SchoolPro's MySQL migration remains incomplete.
- **Next:** independently inspect the Turnstile and trusted-edge implementation and its tests on the exact Stage A branch head; address only demonstrated gaps, rerun the relevant CI, and append the commit/run evidence here. Then close the server-only/no-policy table findings only after checking all consumers and cleanup paths, and reverify acceptance gates A/B/C before resuming D.


## 12. Stage A trusted-edge, rate-limit and server-only table audit — 2026-10-17

### Exact draft source checkpoint and verified gap corrections

- Latest Stage A draft source commit at this checkpoint: `79db2134cf9ba151b0279e2b216a2b1919f86c04` on `release/stage-a-auth-tenant-isolation`. The last source changes in this series are isolated to login rate-limit identity handling, the public-admission Turnstile verifier/test harness, and CI wiring. PR #106 remains draft and unmerged.
- **Confirmed trusted-metadata gap:** the draft account and student login functions had used `cf-connecting-ip` as a database rate-limit identity, but the existing static test only excluded `x-forwarded-for`; it did not establish that the Supabase Edge Function receives a spoof-resistant value. Removed the IP buckets from both draft handlers. Account login continues to throttle a normalized email key; student login continues to throttle a normalized school-code/admission-number key; both call the server-only `schoolpro_take_login_attempt` RPC with a limit of 8. No forwarding header is treated as a principal.
- Added/updated `scripts/test-schoolpro-login-rate-limit-trusted-ip.mjs` to require the account-scoped throttles and fail if an unverified forwarding-header identity or IP bucket returns. This test is source-level; it does not prove provider/network rate limiting.
- **Turnstile behavioral coverage improved:** extracted the shared verifier into `supabase/functions/schoolpro-public-admission/turnstile.mjs` and added `scripts/test-schoolpro-turnstile-verifier.behavior.mjs`, wired into `.github/workflows/ci.yml`. The behavioral test injects a mocked Siteverify fetch and covers valid action+hostname, missing/oversized token or configuration, invalid/replayed-token responses, wrong action/hostname, HTTP failure, network failure, request body and bounded timeout. It is a mocked behavioral test, not a live Cloudflare challenge/replay test. The static gateway test was aligned to the shared verifier.
- Gateway source review: the Edge Function fails closed when Turnstile secret/hostname config is missing, rejects tokens not accepted by Siteverify, requires action `schoolpro_public_admission`, checks the returned hostname against the exact allowlist, caps request body size, uses an 8-second Siteverify timeout, checks an explicit origin allowlist, and does not use forwarding headers or send `remoteip`. The public RPC is intended to be callable only by `service_role`; browser code invokes the gateway rather than the RPC directly.
- Cloudflare reference: server-side Siteverify is mandatory; tokens expire after five minutes and are single-use. https://developers.cloudflare.com/turnstile/get-started/server-side-validation/

### Source-to-deployment parity — production remains unchanged

- Read-only inspection of the live Supabase project `lnqsroyiybutkfngbyge` listed active Edge Functions. **`schoolpro-public-admission` is absent from the deployed function list**, so the draft Turnstile gateway is not deployed and must not be represented as active production protection.
- Read-only inspection of the deployed `schoolpro-account-login` (version 2) and `schoolpro-student-login` (version 3) source showed both still derive the IP bucket from the leftmost `x-forwarded-for` value. This confirms a source-to-deployment mismatch: the draft branch is being corrected, while deployed code has not changed. Do not rely on that header for security or assume the draft fixes production until a separately approved deployment and trusted-proxy provenance check.
- No production function was deployed, no production secret/configuration was changed, no production migration/data write was run, no Render deployment was triggered, and no PR was merged. The user has not approved deployment.
- Latest CI for the updated draft head: SchoolPro CI [#1338](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39021368691) was queued when this handover checkpoint was written. The previous run [#1331](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39021195812) passed all seven jobs, including `validate`, `tenant-acceptance`, and the five disposable PostgreSQL integration jobs, but it predates the Turnstile verifier extraction/behavioral test. Do not call the new exact head CI-green until run #1338 completes successfully.

### Login rate-limit behavior observed in live catalog

- Read-only catalog inspection confirmed `public.schoolpro_take_login_attempt(text, integer)` is executable only by `service_role` (plus owner `postgres`), uses an atomic upsert keyed by the caller-supplied digest, rejects invalid limits outside 1–60, resets the window after 15 minutes, returns true only while attempts are within the limit, deletes `schoolpro_login_attempts` rows older than one day, and opportunistically deletes expired `schoolpro_student_activation_challenges`.
- This is evidence for the live function's current behavior, not proof of a full isolated concurrency test for login keys. The existing login regression is static. Do not introduce IP-based DB keys until the real trusted proxy chain is documented and spoof resistance is tested. A provider-native edge/WAF rate limit remains separate follow-up work; the draft currently provides account-key throttling, not an IP-wide/volumetric limiter.

### Seven RLS-enabled/no-policy tables — consumer and lifecycle trace

- Read-only production catalog inspection reconfirmed all seven tables have RLS enabled, **zero policies**, no `anon` or `authenticated` table grants, and table privileges only for `service_role` and owner `postgres`. These are intentionally server-only/deny-by-default objects, not evidence of public table exposure. No broad RLS policies or grants were added.
- `public.datasub_pin_recovery_attempts` — DataSub-only. Deployed `datasub-pin-recovery` Edge Function (version 1) authenticates the user, checks active profile/MFA assurance where configured, and calls service-role RPC `claim_datasub_pin_recovery`. The RPC upserts one row per user and allows at most five claims in a 15-minute window; the window resets in place, so this is bounded per user rather than an unbounded attempt log. The account-deletion Edge Functions do not explicitly delete this row; residual rows for deleted/soft-deleted users are a retention hygiene item, not a client-access path. Keep this in the separate DataSub workstream.
- `public.schoolpro_access_invitations` — `invite-school-staff` uses service-role access to list, create, and regenerate invitations. `schoolpro_accept_access_invitation` locks the matching row and requires matching authenticated email, `expires_at > now()`, and `accepted_at is null`, then records `accepted_at`. `schoolpro_join_school_code` only selects unaccepted, unexpired invitations. Expired unaccepted rows can be regenerated; accepted rows are retained as audit history. No scheduled delete was found; this matches the current regenerate/audit workflow.
- `public.schoolpro_account_challenges` — `schoolpro_initial_challenge` deletes prior challenges for the same user before inserting a 10-minute token hash; `schoolpro_consume_account_challenge` validates the hash/expiry and deletes that user's challenge; staff invitation renewal also clears that user's challenge. No global expiry sweep was found, so abandoned expired hashes can remain until the user's next challenge/renewal. One active row per user is maintained by the per-user delete/insert path; no client table grants exist.
- `public.schoolpro_initial_credentials` — `schoolpro_set_initial_credential` creates the row; login only reads an unconsumed, unexpired row; successful account activation deletes it after password update. The invite flow intentionally renews an expired, unconsumed credential row to permit a school to reissue activation, so automatic deletion of all expired credentials would break that recovery path. No global cleanup was found; expired unconsumed rows are retained for reissue and remain service-role-only.
- `public.schoolpro_login_attempts` — consumed by account login, student login, and the invitation Edge Function via `schoolpro_take_login_attempt`. The RPC atomically upserts each hashed key, resets after 15 minutes, and deletes rows older than one day. No direct anon/authenticated table grant exists.
- `public.schoolpro_student_activation_challenges` — student login inserts only a token hash; `schoolpro_consume_student_challenge` requires an unexpired token and an eligible, unlinked student, then deletes that student's challenges; `schoolpro_take_login_attempt` also deletes expired rows. No direct client table grants exist.
- `public.schoolpro_transcript_issues` — created through `private.schoolpro_issue_transcript`, read through `private.schoolpro_student_transcripts`, and revoked by setting `revoked_at`/`revoked_by` through `private.schoolpro_revoke_transcript`. `schoolpro-render-transcript` requires an authorized, unrevoked record and renders the stored snapshot. Issue rows are durable issuance/revocation audit records; hard deletion is not the cleanup mechanism. Access is via controlled RPCs/Edge Function, not direct table grants.
- **Disposition:** close the *no-policy/public-exposure* classification for these seven tables: the live grant inventory and consumer trace support intentional server-only access, and no direct anon/authenticated table grants were found. Lifecycle/retention notes above are recorded rather than silently deleting invitation, credential, PIN-recovery, or transcript records. No production mutation was made. Any future retention policy change must be separately tested against invitation regeneration, first-login activation, transcript audit/history, account deletion, and DataSub recovery behavior.

### Stage A A-gate re-verification status

- Latest completed live two-school acceptance and disposable database suite is CI #1331, all seven jobs successful on the preceding draft commit. That run revalidated authentication/tenant acceptance and payment/tenant integrity tests before the new Turnstile test harness was added.
- The updated exact-head run #1338 must pass, including live `tenant-acceptance`, `validate`, `payment-review-rls-integration`, `tenant-integrity-db-integration`, `result-pin-rate-limit-integration`, `result-verification-exposure-integration`, and `public-admission-abuse-integration`, before Stage A is marked reverified. The Turnstile behavior test is mock-backed and does not close the deployed gateway/header provenance gap.
- Stage A is **not production-complete**: production still has the old X-Forwarded-For login implementation and no deployed public-admission gateway. Stage A remains unmerged and undeployed. Reverify B/C only after exact-head A evidence is green; D remains blocked behind A/B/C.


### Stage A rate-limit behavior test added — 2026-10-17 follow-up

- Added `scripts/test-schoolpro-login-rate-limit.integration.sql`, a disposable PostgreSQL regression fixture based on the read-only production definition of `schoolpro_take_login_attempt(text, integer)`. It verifies the service-role-only function ACL, rejection of invalid limits, eight allowed attempts followed by denial on the ninth for limit 8, independent key counters, 15-minute reset, deletion of login rows older than one day, and expiry cleanup of student activation challenges. CI also runs 12 concurrent calls against one key and asserts the atomic counter reaches 12.
- Wired this fixture and concurrency assertion into the existing disposable PostgreSQL rate-limit integration job in `.github/workflows/ci.yml`. This is a contract fixture for the observed function behavior; it does not claim to test a deployed function by mutating production.
- Latest Stage A branch commit after this addition: `ea6186b400ec9ae0514641296f5c43f0cda30f86`. CI for this exact head must be checked and all jobs must finish successfully before claiming the latest login/Turnstile test changes are verified.
- Read-only Supabase migration ledger lists 476 migrations and ends at version `20261015161735` (`schoolpro_access_invitation_role_constraint`). The draft versions `20261016122000`, `20261017103000`, `20261017120000`, and `20261017133000` are not present in the live ledger. This confirms the corresponding draft migrations must not be described as applied in production; the migration ledger may not reflect all historical/manual changes, so reconcile drift through the existing audit process rather than replaying or guessing.
- No production function deployment, schema migration, row mutation, secret/configuration change, or PR merge was performed. Production still lacks the draft public-admission gateway and retains the older X-Forwarded-For login functions until an explicitly approved deployment.


### Production admissions RPC reachability — confirmed high-priority parity gap

- A read-only live catalog query confirmed the currently deployed `public.submit_schoolpro_application(uuid,text,text,date,...)` remains `SECURITY DEFINER` and its effective ACL currently permits `anon`, `authenticated`, and `service_role` to execute it. The live function body has the original required-field/admissions-open checks but does not contain the draft's contact throttles or field length/format validation.
- The live Edge Function inventory does not include `schoolpro-public-admission`; the draft revocation migration `20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql` is absent from the live migration ledger. Therefore the Turnstile gateway and service-role-only RPC boundary are **not active in production**. Do not claim the public admissions abuse gap is closed for production.
- **Do not apply the revoke migration before the gateway is deployed and verified**, or the existing public admissions form may fail. A separately approved rollout must: (1) confirm actual customer-facing hostname/origins and configure `VITE_TURNSTILE_SITE_KEY` plus server-side `TURNSTILE_SECRET_KEY`, `TURNSTILE_ALLOWED_HOSTNAMES`, and `SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS`; (2) deploy the Edge Function and frontend in a controlled sequence; (3) exercise valid/invalid/replayed token and legitimate application paths; (4) only then apply the RPC revocation/validation migration and confirm anon/authenticated cannot execute the RPC while service_role can. No production action was taken in this audit.
- This is a confirmed production exposure/abuse-control gap based on live ACL and source inspection, not a claim that a data breach occurred. Keep it at the top of the Stage A rollout checklist and obtain explicit approval before any production deployment or migration.


### Exact-head CI progress — 2026-10-17

- SchoolPro CI [#1341](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39021469332) is running for Stage A commit `ea6186b400ec9ae0514641296f5c43f0cda30f86`.
- Completed successfully so far: `tenant-acceptance` (read-only two-school acceptance), `payment-review-rls-integration`, `tenant-integrity-db-integration`, `result-verification-exposure-integration`, `public-admission-abuse-integration`, and `result-pin-rate-limit-integration`. The latter includes the new login rate-limit behavior fixture and concurrent-key assertion; both steps passed.
- In `validate`, the new mocked Turnstile behavioral test and the no-unverified-forwarding-header login regression test both passed. The job is still running its combined Playwright/mobile-layout checks; artifact upload and `npm run build` have not yet run. Do not mark exact-head CI fully green until `validate` and the full workflow finish successfully.
- The payment-page validation run [#1068](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39021469275) completed successfully.


### Final result — Stage A exact-head CI #1341 (2026-10-17)

- **Final outcome: SUCCESS.** GitHub Actions run [#1341](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39021469332) completed with all seven jobs successful on exact Stage A draft head `ea6186b400ec9ae0514641296f5c43f0cda30f86`.
- Job results:
  - `validate` — success, including the new Turnstile verifier behavior test, trusted-forwarding-header regression test, mobile/layout checks, artifact upload, and `npm run build`.
  - `tenant-acceptance` — success; read-only two-school acceptance checks passed.
  - `payment-review-rls-integration` — success.
  - `tenant-integrity-db-integration` — success.
  - `result-verification-exposure-integration` — success.
  - `result-pin-rate-limit-integration` — success, including login-attempt throttling/cleanup fixture, 12 concurrent calls on one key, and wrong-PIN cooldown concurrency checks.
  - `public-admission-abuse-integration` — success.
- This closes the **draft exact-head CI validation checkpoint** for the listed tests. It does not establish live Cloudflare challenge/replay behavior, provider-native volumetric rate limiting, or production source-to-deployment parity.
- Stage A remains **not production-complete**: live account/student login functions still use the deployed `X-Forwarded-For` implementation; the draft `schoolpro-public-admission` gateway is not deployed; and the live admissions RPC still permits `anon`/`authenticated` execution until the gateway and revocation migration are safely rolled out. No production change or merge was performed.
- Next: review the exact Stage A diff and rollout sequence, obtain explicit approval before production actions, and reverify A/B/C at the required release gate before resuming D. The seven RLS-enabled/no-policy tables remain classified as intentionally server-only based on the observed grants and consumer/lifecycle trace; retention changes are not authorized by this audit.


## 13. Stage A release-gate review and re-verification — 2026-10-17

### Exact-head verification — PASS for draft CI, NOT a production release approval

- Re-fetched PR #106 immediately before this review. It remains **open, draft, unmerged**; base commit `29856dff17ea8a3bc8bb31b7900967b7df9d316b`; exact head `ea6186b400ec9ae0514641296f5c43f0cda30f86`.
- Re-queried GitHub Actions run [#1341](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39021469332) for that exact head. All seven jobs are now completed with `success`:
  1. `validate` — typecheck, Stage A source guards, Turnstile mocked behavior test, untrusted-forwarding-header regression, mobile/layout checks, artifact upload and production build.
  2. `tenant-acceptance` — live, read-only two-school acceptance harness.
  3. `payment-review-rls-integration` — disposable PostgreSQL policy/grant test.
  4. `tenant-integrity-db-integration` — disposable PostgreSQL tenant-integrity, disabled-online-gateway and receipt-submission RPC tests.
  5. `result-verification-exposure-integration` — disposable snapshot/exposure test.
  6. `result-pin-rate-limit-integration` — disposable PIN cooldown, login attempt/cleanup, 12 concurrent login-key calls, and 8 concurrent wrong-PIN requests.
  7. `public-admission-abuse-integration` — disposable admissions limits, validation and RPC grant-boundary test.
- Payment-page validation [#1068](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39021469275) also completed successfully.
- **A draft test/CI checkpoint is reverified on this exact head. A is not cleared for merge, deployment or production completion.** CI does not close live source-to-deployment mismatches, live Cloudflare token/replay behavior, the verified public admissions RPC reachability gap, or missing production rollout evidence.

### Release-gate matrix

| Gate | Current finding | Release disposition / evidence still required |
|---|---|---|
| Authentication and school context | Draft auth/profile-race, role/access, normalized account-key throttling and no-untrusted-forwarding-header tests pass. Live two-school acceptance passed in run #1341. | Draft evidence passes. After any approved merge/deploy, repeat positive and negative login/session/role/workspace checks against the deployed commit and Render service. |
| Tenant integrity and result exposure | Disposable tenant-integrity and result-verification integration jobs passed; tenant acceptance passed. | Keep the known Basic 5 A 2025/2026 subject-ID linkage anomaly protected; do not alter records as part of this release gate. Verify production schema/source parity and intended RPC/RLS/Storage access after a separately approved rollout. |
| Payment review RLS | Disposable PostgreSQL integration job passed. Fixture executes the draft migration against minimal test-only tables, models permissive policies/grants, and switches to an authenticated role to check guardian read scope/direct-write denial, school-finance review/write behavior and Super Admin read-only behavior. | Useful runtime evidence, but **not a full clone of the live schema or every actual role/RPC/caller path**. Still test submit/review/reject/cancel, immutable review-controlled columns, cross-school IDs, receipt-object ownership/path, duplicate allocations and transaction concurrency against the full relevant schema/policy/grant set in a disposable environment. Do not claim production exploit or complete production parity from the fixture alone. |
| Receipt storage isolation | No valid, safe two-school receipt-object fixture is configured in the live acceptance harness. | Blocked. Configure known, existing test-owned paths only; verify own-school read/write and cross-school denial. Do not upload dummy receipts or mutate customer records in production. |
| Family report-media Storage | Static regression guard passes and enforces indexed exact-path checks/short-circuit for non-media objects. Earlier folder-listing performance issue was not closed by exact-object tests alone. | Blocked pending disposable/runtime policy and performance test for exact-object reads, folder listing, cross-school objects, student photos, signatures, logos and workbook-path short-circuit. Capture latency/query evidence; do not infer performance from source assertions. |
| Result PIN and login throttling | Disposable cooldown and concurrency assertions pass; account/student draft handlers no longer use unverified forwarding headers as database rate-limit identity. | Draft gate passes. Provider-native edge/WAF volumetric throttling is still unverified; do not add a caller-controlled IP database key. Establish trusted proxy/header provenance before considering any IP-based control. |
| Public admissions abuse control | Disposable contact-limit/validation/RPC-grant tests pass; Turnstile verifier behavioral tests pass with mocked Siteverify. | **Production blocker:** live `submit_schoolpro_application` remains SECURITY DEFINER and executable by `anon`/`authenticated`; `schoolpro-public-admission` is absent from the deployed Edge Function inventory. Live migration ledger does not contain draft revoke migration `20261017133000`. Do not revoke the RPC before the gateway/frontend is deployed and verified, or the public form may break. |
| Trigger and migration integrity | Draft migrations are tested in isolated fixtures. Read-only live ledger ended at `20261015161735`; draft versions `20261016122000`, `20261017103000`, `20261017120000`, `20261017133000` are absent from the observed live ledger. | Blocked. Compare each proposed migration with live schema, trigger definitions/order, dependent routines and operational workflows. Reconcile source/ledger drift using authoritative history/catalog evidence; do not guess, renumber, or replay historical migrations. |
| Production parity and deployment | No approved production change occurred in this workstream. Live account login v2 and student login v3 still use the leftmost `x-forwarded-for` value; the draft removed that unverified identity. | Blocked pending explicit approval, reviewed release scope, controlled rollout, post-deployment checks and rollback plan. Do not represent draft code as production protection. |

### Required controlled rollout — in this order, after explicit approval

1. **Confirm deployment targets and allowed origins.** Verify the actual public/customer-facing hostnames and scheme-qualified origins, including the Render production domain and any real custom domain. Do not guess hostnames.
2. **Prepare challenge configuration.** Create the Cloudflare Turnstile widget and configure Render build variable `VITE_TURNSTILE_SITE_KEY`; configure server-only Supabase Edge secrets `TURNSTILE_SECRET_KEY`, `TURNSTILE_ALLOWED_HOSTNAMES`, and `SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS`. Never put the secret in frontend build variables.
3. **Deploy the public-admission gateway and frontend in a controlled sequence.** Confirm the deployed function is present and the frontend submits only through the gateway; preserve the existing application path until a working replacement is verified.
4. **Exercise the live challenge flow.** Verify valid, invalid, expired/replayed token rejection; wrong action/hostname rejection; missing-config fail-closed behavior; allowed/blocked origins; and successful legitimate admission. Record live evidence separately from the mocked CI test.
5. **Only after the gateway is confirmed healthy, apply the reviewed admissions RPC grant/validation migration.** Verify `anon` and `authenticated` cannot execute the public RPC and `service_role` can; re-run the public form end-to-end. Never revoke first.
6. **Deploy the reviewed login-handler changes** only after the source, environment and operational plan are approved. Do not claim IP-wide or volumetric protection unless the actual trusted edge and provider-native limits are configured and tested.
7. **Apply the remaining reviewed migrations** only after trigger/source-to-ledger reconciliation and receipt/Storage/payment tests close. Keep migrations ordered and reversible where practical; capture the exact production migration identifiers and resulting schema evidence.
8. **Post-deploy verification:** test both school workspaces, role-specific positive and negative paths, payments/receipt isolation, results and student login; confirm Render is running the intended commit; inspect errors and rollback readiness. Do not merge/deploy as a side effect of a green draft CI run.

### Stage A decision

- **Draft CI:** PASS on exact head `ea6186b400ec9ae0514641296f5c43f0cda30f86`, run #1341, 7/7 jobs.
- **Stage A release gate:** **BLOCKED / NOT MERGE-READY** until receipt Storage isolation, family-media runtime/performance evidence, complete payment lifecycle/role boundary coverage, full-schema trigger and migration-drift review, and a safe admissions/login rollout plan are addressed and reviewed.
- **Production:** unchanged by this checkpoint. No production migration, row mutation, Supabase function/secret change, Render deployment, merge or cutover was performed.
- **Sequence remains A → B → C → D.** Do not start B until Stage A has passed the outstanding release gates, been explicitly approved and merged to the intended production branch, and then been verified post-merge/deployment. Reverify B and C before resuming D. Preserve the full E–J roadmap.


## 14. Stage A blocker-remediation work started — 2026-10-17

### Payment review boundary: prevent guardian-created pre-reviewed submissions

- Stage A PR #106 remains open/draft/unmerged. Current head after this isolated draft change: `0c1186b3ba346b30a19f7d13f4c8563adf098963`.
- Updated draft migration `supabase/migrations/20261016143000_schoolpro_payment_review_write_controls.sql` (commit `ba0a26965a577311712753c2de209c8a4d372966`) so a guardian-owned branch of the restrictive submission policy's `WITH CHECK` requires `status = 'pending'`. This blocks an authenticated guardian from using a direct INSERT policy to create a submission already marked reviewed/approved, while leaving authorized school-finance workflow and Super Admin read-only policy unchanged.
- Added a disposable PostgreSQL regression assertion to `scripts/test-schoolpro-payment-review-rls.integration.sql` (commit `0c1186b3ba346b30a19f7d13f4c8563adf098963`) that attempts a guardian insert with status `reviewed` and an unverified receipt path and requires an RLS denial.
- **Validation status at handover update:** changes pushed to the isolated Stage A branch. GitHub workflow run was not yet returned for this newest head when checked; do not call the new assertion passed until the corresponding CI job completes successfully.
- This closes only the narrow pre-reviewed INSERT path in the draft policy. It does not close all payment gates: verify direct INSERT grant necessity against actual client call sites; test status/amount/receipt path/tenant/student/allocation direct writes, finance review transitions, rejected/cancelled states, duplicate allocation, invoice-lock concurrency, receipt ownership, and cross-school attempts against the fuller schema/policy set. Do not infer full payment lifecycle correctness from this narrow fix.

### Remaining work order

1. Wait for and inspect CI on the latest Stage A head; fix any failure before claiming this change is validated.
2. Finish payment role/lifecycle tests and decide—using source call-site evidence—whether direct table INSERT should be revoked in favor of the SECURITY DEFINER submission RPC. Do not change grants blindly.
3. Build a safe disposable Storage-policy test for receipt own-school/cross-school object isolation, and a runtime/performance test for family report-media exact reads and folder listing. Keep live customer storage untouched.
4. Inspect live schema and triggers read-only; reconcile source migrations against the live migration ledger/catalog without replaying historical versions or guessing.
5. Treat live admissions gateway rollout and login source/deployment mismatch as operational gates requiring approved configuration and deployment. Do not revoke admissions RPC before the gateway works. Do not treat untrusted forwarded headers as client identity.
6. Update this handover with every new test result. Stage A stays **BLOCKED / NOT MERGE-READY** until all gates pass and the owner explicitly approves the release. No production mutation/deployment was performed by this remediation.


### Receipt Storage acceptance made non-skippable

- Updated `scripts/test-schoolpro-tenant-isolation-live.mjs` on the isolated Stage A branch (latest commit `9c84946b10bf0dbef677418ab6f2cbffc4d4ed5b`) to require both `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` instead of silently skipping receipt isolation when either is absent.
- The acceptance test now requires two distinct **existing** receipt objects rooted under each authenticated account's user ID, verifies each account can download its own object, and verifies each cannot download the other account's object. It remains read-only and explicitly does not create production fixtures.
- This is a gate-strengthening change, **not a passed runtime test**. At the time of this note, GitHub did not return a workflow run for the newest PR head; CI execution is pending/unavailable through the queried run listing. The gate must not be called closed until the live acceptance job passes with the two valid path secrets configured.
- If the paths are not available, use a dedicated disposable Supabase/Storage environment or create test-owned objects only in an approved test environment. Do not point these secrets at arbitrary customer receipts and do not upload dummy receipts into production.



## 15. Exact-head CI diagnosis and payment/Storage test remediation — 2026-10-17

### CI run #1344 — failure causes confirmed from job logs

- PR #106 was still open/draft/unmerged. At the time of this diagnosis, its exact head was `9c84946b10bf0dbef677418ab6f2cbffc4d4ed5b`.
- SchoolPro CI [run #1344](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022220584) did **not** pass:
  - `validate` was still running its mobile-layout/build tail when inspected; earlier source-level checks, including `test-schoolpro-payment-review-write-controls.mjs`, passed.
  - `tenant-acceptance` failed immediately before making any Supabase request because repository Actions secrets `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` were empty. This is an environment/fixture-availability failure, not a Storage policy denial or proof that isolation works.
  - `payment-review-rls-integration` failed with a SQL syntax error at the new guardian pre-reviewed INSERT assertion: the dynamic SQL dollar-quote delimiter was opened as `$insert` rather than a valid PostgreSQL dollar-quoted string. The failure occurred before that assertion could exercise RLS; therefore the payment RLS test had not passed.
  - The completed tenant-integrity, public-admission abuse, result-verification exposure, and result-PIN/login-rate-limit integration jobs succeeded in this run.
- Payment-page validation [run #1069](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022220591) succeeded.

### Payment test syntax correction and rerun

- Corrected the test statement delimiter in `scripts/test-schoolpro-payment-review-rls.integration.sql` to use matching `$insert$ ... $insert$` delimiters. Isolated branch commit: `2f9bccfc141ec136673025d4995086970afe908e`.
- GitHub started fresh workflows for this commit: SchoolPro CI [run #1345](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022362975) and payment-page validation [run #1070](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022362976). Both were in progress at the time this entry was written. Do not report the corrected SQL or the full workflow as passing until run #1345's payment job and final workflow conclusion are successful.
- The payment fixture still tests a deliberately limited representative policy/grant schema. After syntax repair, inspect the full run output for the new guardian pre-reviewed INSERT denial and existing guardian-read, finance-review, and Super Admin read-only checks. Further lifecycle assertions remain necessary before calling payment testing complete: direct write/receipt path boundary, cross-school identifiers, reject/cancel behavior, duplicate allocation, and invoice-lock/concurrent review behavior. Compare actual application call sites before changing direct table grants.

### Receipt Storage isolation — blocked by missing safe fixture paths

- The live acceptance workflow's environment dump showed both receipt-path secrets blank. The script correctly failed closed before sending any request. No object was downloaded and no production data was changed.
- To complete the runtime test, configure `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` to two distinct, existing **test-owned** objects in `schoolpro-payment-receipts`, each rooted under the matching authenticated test user's UUID. Verify the paths belong to the two configured test accounts before rerunning. Do not use arbitrary customer receipts or create dummy production objects.
- If safe existing objects are unavailable, provision a dedicated disposable Supabase/Storage environment with test-owned fixtures and exercise own-object download success plus cross-account denial there. The current live two-school job cannot be marked green by skipping this test or making the required paths optional.
- The result-template Storage assertion is a separate existing-object check and does not substitute for receipt-object isolation. Family report-media folder-listing/runtime performance remains a separate open gate as well.

### Current disposition

- The syntax correction is committed to the isolated PR branch; its validation is pending the new CI run.
- Receipt Storage runtime isolation remains **BLOCKED** until valid test-owned fixture paths or a dedicated disposable Storage test environment are available and the test passes.
- Stage A remains **BLOCKED / NOT MERGE-READY**. No production migration, production row/object mutation, Render deployment, Supabase function/secret change, or PR merge was performed. Keep the full A–J roadmap and A → B → C → D release order intact.


### Follow-up correction — payment RLS regression statement body

- Follow-up run [#1345](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022362975) showed the first delimiter correction still omitted the SQL keyword `INSERT` from the dynamic statement body; PostgreSQL failed at `into`. This is a test-harness defect, and the assertion still had not reached the RLS policy.
- Corrected the dynamic body to `$insert$ insert into ... $insert$` in commit `641625cb84a2cc97000391e915d0d3578b446ba4`. Await the newly triggered CI on this exact head and inspect the payment job logs before considering the assertion passed.
- The same run's tenant-acceptance job again failed because both receipt path secrets remain empty; no Supabase request was sent by that test. The older successful tenant acceptance run [38990160428](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38990160428) explicitly logged **SKIP payment-receipt Storage download test** and therefore is not receipt Storage-isolation evidence. The non-skippable check is correctly surfacing a missing fixture configuration.


### Latest CI on corrected payment test head — pending

- Exact PR #106 head: `641625cb84a2cc97000391e915d0d3578b446ba4`.
- Fresh SchoolPro CI [run 39022424247](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022424247) and payment-page validation [run 39022424240](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022424240) were triggered for this exact commit and remained in progress at the latest query. No success is claimed yet.
- The previous payment integration failure was diagnosed as a malformed test string; the current run is the required proof that the corrected SQL executes and reaches the policy assertion. Recheck the payment job's final logs and the overall run conclusion before closing that sub-gate.
- Receipt Storage remains blocked: the latest live acceptance log showed both required receipt-path secrets empty and exited before sending a request. A prior run's green tenant acceptance is not evidence for receipts because it skipped the receipt-download portion. No safe test-owned receipt paths are currently available through the observed workflow environment. Do not weaken the required test or use customer objects.


## 16. CI result established — payment RLS passes; receipt Storage still blocked (2026-10-17)

### Exact-head run 39022424247

- PR #106 head `641625cb84a2cc97000391e915d0d3578b446ba4`, still open and unmerged.
- SchoolPro CI [run 39022424247](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022424247) completed with overall **failure**, because the required live tenant acceptance job failed on missing fixture configuration.
- Completed successful jobs:
  - `payment-review-rls-integration` — passed. PostgreSQL executed the corrected test and emitted: `PASS: payment-review RLS restricted guardian scope, allowed school-finance review, and kept Super Admin read-only.`
  - `tenant-integrity-db-integration` — passed.
  - `result-verification-exposure-integration` — passed.
  - `public-admission-abuse-integration` — passed.
  - `result-pin-rate-limit-integration` — passed.
  - `validate` — passed, including static source guards and mobile/build checks.
  - `tenant-acceptance` — failed before receipt Storage requests because both `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` are empty/missing.
- Payment-page validation [run 39022424240](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39022424240) passed.
- This resolves the previous payment-test syntax failure. The RLS integration assertions now execute successfully. This is still a focused disposable-schema RLS test; it does not by itself prove every receipt object ownership, invoice concurrency, duplicate allocation, or reject/cancel lifecycle path. Source-level guards for receipt ownership, invoice locks, pending reservations and amount reconciliation passed in the validation job, but these are static checks, not live end-to-end payment settlement evidence.

### Receipt Storage isolation: remaining action is fixture provisioning

- The live tenant acceptance job reports the two receipt-path environment variables as blank and exits with `Missing required environment variables: SCHOOL_A_RECEIPT_PATH, SCHOOL_B_RECEIPT_PATH`.
- It successfully verifies school A's own template download and blocks school B from that foreign template object, but this is **not** receipt-object isolation evidence.
- Required next step: configure the two GitHub Actions secrets to distinct, existing test-owned receipt object paths for the matching configured school test accounts. Each path must be rooted at that account's authenticated user UUID, as required by `scripts/test-schoolpro-tenant-isolation-live.mjs`. Validate that the paths exist and correspond to the expected account before rerunning CI. Do not record path values or credentials in the handover.
- If no suitable test-owned receipt objects exist, use a dedicated disposable Supabase/Storage environment and fixture accounts. Do not create dummy objects in production or use customer receipts. The mandatory test must remain fail-closed and must not be converted to a skip.
- Until the runtime receipt test passes, overall CI is red and Stage A remains **BLOCKED / NOT MERGE-READY**. No production mutation, migration application, deployment, secret change, or PR merge was performed by this work.



## 17. Receipt Storage fixture provisioning investigation — 2026-10-17

### Result of requested secret configuration / environment investigation

- The available GitHub connection is read-only for repository secrets: its documented fetch endpoint explicitly excludes sensitive secret APIs, and no secret-write action is exposed in the connected GitHub tool set. Therefore this assistant session cannot set or inspect the values of `SCHOOL_A_RECEIPT_PATH` or `SCHOOL_B_RECEIPT_PATH`. Do not mistake this limitation for proof that no suitable objects exist.
- The tenant acceptance script was inspected directly at `scripts/test-schoolpro-tenant-isolation-live.mjs`. It requires two distinct existing objects in bucket `schoolpro-payment-receipts`; each path must begin with the matching authenticated test user's UUID. It checks each user's own download and the other account's denial. It performs no uploads or other writes.
- The available Supabase tool set does not expose Storage bucket object listing or object upload/download operations. The project inventory showed the active shared production project `lnqsroyiybutkfngbyge` and one unrelated inactive project `vfooxxdksbomqyglzsyd` (the user's IoT project). The unrelated project is not a suitable SchoolPro test environment and was not modified. No dedicated disposable SchoolPro Storage project is currently established by this evidence.
- No secret values were read or written; no Storage object was listed, downloaded, uploaded, or deleted; no project was created; no production change was made. A new Supabase project can incur charges, and the project-creation workflow requires the owner to choose an organization and handle any quoted nonzero cost. Do not create one or assume it is free without that check.
- The failed tenant acceptance run must **not** be rerun yet: the same missing fixture secrets will predictably fail before any request. Do not rerun merely to produce another identical red result.

### Required next action

1. In GitHub repository **Settings → Secrets and variables → Actions**, add/update the two repository Actions secrets `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` with verified object paths only if the owner/test maintainer can confirm that the objects already exist, are non-customer test fixtures, and belong to the two matching configured test users. Keep the values out of this handover and logs.
2. If no suitable objects exist, establish a dedicated disposable Storage environment with test accounts and two synthetic receipt objects. Prefer a no-additional-cost local/CI-compatible Supabase Storage test harness if it exercises the actual Storage policies; otherwise obtain a project cost quote and owner approval before creating a hosted project. Do not reuse the unrelated IoT project or write dummy objects into production.
3. Provide CI with the disposable project's URL/anon key and the two test-account credentials/IDs through appropriately scoped Actions secrets/variables, plus the two test-owned receipt paths. Confirm the environment's Storage policies match the policies under test; a blank/new bucket without the relevant policies is not valid isolation evidence.
4. Rerun the tenant acceptance job/workflow only after fixture configuration is in place. Record the exact run, commit, job conclusion and own/foreign download assertions. If it fails, diagnose the actual response; do not weaken or skip the test.
5. Stage A remains **BLOCKED / NOT MERGE-READY** until the mandatory receipt Storage test passes and the other release gates are satisfied.



### Follow-up — receipt bucket confirmed empty by maintainer (2026-10-17)

- The maintainer reports that the production Supabase Storage bucket `schoolpro-payment-receipts` is empty. This is user-reported confirmation; this assistant did not independently list the bucket.
- Therefore there are currently no existing receipt objects available to populate `SCHOOL_A_RECEIPT_PATH` and `SCHOOL_B_RECEIPT_PATH` safely. Do not set these secrets to illustrative paths, and do not upload dummy receipts to the shared production bucket.
- The prior “use existing test-owned objects” path is unavailable unless the maintainer later identifies valid non-customer fixtures. The next safe engineering action is to establish a no-additional-cost local/CI-compatible Storage test environment that applies the relevant receipt bucket policies and uses two disposable test users plus synthetic receipts. Verify that this actually exercises the same policy definitions used by the application before treating it as acceptance evidence.
- If the required policy-level test cannot be run locally/within existing CI infrastructure, pause and present the owner with any hosted-environment cost before creating a separate Supabase project. The unrelated IoT project is not to be reused.
- CI remains red and Stage A remains **BLOCKED / NOT MERGE-READY**. No secrets were changed, no production objects were created, and no production changes or merges were made.


## 18. Non-production receipt Storage isolation test — implementation in progress (2026-10-17)

### Read-only production policy inspection

- Queried only \`pg_policies\` metadata for \`storage.objects\` in the active SchoolPro Supabase project; no object listing, receipt download/upload, secret read/write, row mutation, or schema mutation was performed.
- The live database currently defines:
  - \`guardian upload payment receipts\`: authenticated upload restricted to a first path folder matching \`auth.uid()\`.
  - \`guardian read own payment receipts\`: authenticated download restricted to a first path folder matching \`auth.uid()\`.
  - \`school finance read payment receipts\`: read access only when the object path matches a row in \`schoolpro_payment_proofs\` and the caller has an allowed school-finance/leadership role for that school.
- The previously inspected \`20261016180000_schoolpro_payment_receipt_storage_limits.sql\` configures the private bucket, 10 MiB limit and allowed MIME types, but does not itself declare these three \`storage.objects\` policies. This was a migration-source parity gap; the policy metadata above came from a read-only production query.

### Non-production implementation committed to the Stage A branch

- Added \`supabase/migrations/20261017150000_schoolpro_payment_receipt_storage_policies.sql\` to represent the observed policy definitions in migration history and keep the bucket configuration/policies together. It is **unmerged and unapplied to production**.
- Added \`scripts/receipt-storage-local/fixture.sql\`, which provides minimal synthetic schema/function dependencies solely for the isolated test project. The fixture creates no customer or school data and is not a production migration.
- Added \`scripts/test-schoolpro-receipt-storage-local.mjs\`. It creates a temporary Supabase CLI project, copies only the test fixture and receipt-policy migration into that project, starts the local Supabase stack, creates two disposable test users, uploads synthetic receipts, and asserts own-upload/own-download success plus cross-user upload/download denial. The test uses the actual Supabase Storage API and the repository's policy migration rather than writing test files into the production bucket.
- Added the \`receipt-storage-isolation\` CI job to \`.github/workflows/ci.yml\`, using \`supabase/setup-cli@v3\` and no production secrets or remote project link.
- Relevant Stage A branch commits: \`843107fd876361d55528f750ddcb85d30741952a\` (policy migration), \`14177ea1ed00b5ee99d17efe964556d4a2cf2490\` (isolated SQL fixture), \`7f8a5edc358ab07446d65c8b1f9adecc66814f3b\` (local Storage API test), \`a6a76ddf6142141450414d7244c06cc1e80acbec\` (CI job).
- **Validation is pending.** The current execution environment has no Docker or Supabase CLI available, so the local stack has not been started here. Do not mark this test as passed until GitHub Actions runs the new job and its logs confirm the two-user assertions. The new policy migration remains draft/unmerged and must receive review before any eventual production application.
- The live tenant acceptance test still requires existing test-owned receipt paths and remains a separate production read-only acceptance check. Do not configure those paths with invented values and do not add dummy objects to the production bucket. Stage A remains **BLOCKED / NOT MERGE-READY** until the non-production test passes, source/ledger drift is reconciled, and all other Stage A gates pass.


## 19. Receipt Storage CI verification result and production-fixture-free acceptance (2026-10-17)

- GitHub Actions SchoolPro CI run [#1363](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39023324540) completed **failure overall**, but the new \`Receipt Storage isolation (local Supabase)\` job completed **success**. Job logs show:
  - both disposable users uploaded synthetic receipts into their own UUID folders;
  - each user downloaded their own receipt and was denied the other user's receipt;
  - cross-user upload into the other user's UUID folder was denied;
  - local Supabase stack was stopped after the test.
- Other integration jobs in run #1363 completed success: result-PIN rate limit, public admission abuse, payment-review RLS, tenant-integrity DB integration, result-verification exposure, and static \`validate\`.
- The only failed job was \`tenant-acceptance\`, which exited before sending any request because \`SCHOOL_A_RECEIPT_PATH\` and \`SCHOOL_B_RECEIPT_PATH\` were empty. This is expected given the maintainer-confirmed empty production receipt bucket; it is not a failed Storage policy assertion.
- Updated \`scripts/test-schoolpro-tenant-isolation-live.mjs\` in commit \`fb3807042dc7f29bafe1958a58a07e9664a9a147\`: receipt object paths must now be supplied together or both omitted. If omitted, the live two-school tenant read/RPC/template checks still run and the script prints an explicit \`SKIP\` for production receipt-object checks, pointing to the separate local Storage integration job. If paths are supplied, the live positive/negative receipt download checks still execute. This avoids blocking all tenant acceptance on unavailable production fixtures without misreporting live receipt-object verification as passed.
- The local test verifies the policies from the new, unmerged repository migration in an isolated Supabase stack; it does not prove that the production database has been reconciled to this migration or that production receipt objects exist. No production receipt objects were created and no production migration was applied.
- The updated acceptance script is awaiting its new CI run. Stage A remains **BLOCKED / NOT MERGE-READY** until the new run completes, all other required gates pass, and the receipt-policy migration is reviewed for parity with the current application schema/role model.


## 20. Updated live tenant acceptance — run #1365 (2026-10-17)

- Exact Stage A PR head under validation: `fb3807042dc7f29bafe1958a58a07e9664a9a147`; PR #106 remains open/unmerged.
- SchoolPro CI [run #1365](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39023594211) has completed the live `tenant-acceptance` job successfully. Logs confirm both configured school accounts were tested:
  - School A foreign-school reads were denied for students, members, invoices and results; its own academic-period access succeeded and foreign-school RPC access was denied.
  - School B foreign-school reads were denied for students, members, invoices and results; its own academic-period access succeeded and foreign-school RPC access was denied.
  - Both accounts were denied foreign-student result-output RPC access.
  - School A downloaded its own result template; School B's foreign-template request was rejected with HTTP 400.
  - Because both receipt path variables remain blank and the production receipt bucket is reported empty, the script explicitly skipped only live production receipt-object checks. The job did not create, upload, download, or delete production receipt objects. This skip is not production receipt-object test evidence.
- The separate payment-page validation workflow [run #1092](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39023594275) completed successfully.
- In run #1365, the following disposable-database integration jobs were completed successfully: result-verification exposure, result-PIN/login rate limiting, payment-review RLS, public-admission abuse controls, and tenant-integrity/receipt-submission RPC. The local Supabase receipt Storage isolation job and general `validate` job were still in progress at the latest status check; do not record the whole CI run as passed until both finish and the overall conclusion is available.
- This improves the live tenant read/RPC/template acceptance gate despite the absence of production receipt fixtures. The independent local Storage job remains required to test receipt-object policy behaviour without production objects.
- Outstanding safeguards remain unchanged: inspect the completed run and any failures; review the draft receipt Storage policy migration against current application role/schema semantics and production definitions; reconcile migration-ledger/source parity; preserve the explicit no-production-change/no-merge rule. Stage A is **NOT MERGE-READY** while required checks or migration review remain open.


## 21. Run #1365 complete — all listed SchoolPro CI jobs passed (2026-10-17)

- SchoolPro CI [run #1365](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39023594211) completed with overall **success** for the PR #106 merge commit containing head `fb3807042dc7f29bafe1958a58a07e9664a9a147`.
- All eight listed jobs completed successfully: `tenant-acceptance`, `Receipt Storage isolation (local Supabase)`, `tenant-integrity-db-integration`, `payment-review-rls-integration`, `result-verification-exposure-integration`, `public-admission-abuse-integration`, `result-pin-rate-limit-integration`, and `validate` (including typecheck, source tests, layout checks and production build).
- The local Storage job logs explicitly show the isolated Supabase stack applied the test fixture and repository receipt-policy migration, then confirmed:
  - each disposable user could upload a synthetic receipt under its own UUID folder;
  - each could download its own receipt but not the other user's receipt;
  - cross-user receipt upload was denied by the Storage API policy;
  - the local stack was stopped after testing.
- The live two-school acceptance checks also passed as recorded in section 20. Live production receipt-object checks remain explicitly skipped because there are no safe test fixtures; the separate local test provides isolated runtime evidence against the repository policy migration.
- Payment-page validation [run #1092](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39023594275) also completed successfully.
- **Scope limitation:** this CI success validates the tested code, disposable database scenarios, live tenant read/RPC/template checks and local Storage-policy behaviour. It does **not** prove the draft receipt-policy migration is already applied to production, nor does it complete schema/role parity review, migration-ledger reconciliation or the broader Stage A release acceptance. No production migration, object write, secret change, deployment or PR merge was performed.
- **Disposition:** the prior CI failures caused by missing production receipt fixture paths are resolved without adding objects to production. Keep PR #106 open/unmerged while the receipt-policy migration is reviewed against the production role/schema definitions and remaining Stage A gates are checked. Do not mark Stage A merge-ready solely from this successful run.


## 22. Stage A receipt-Storage migration review and production-ledger reconciliation (2026-10-17)

### Read-only production facts

- Production Supabase project `lnqsroyiybutkfngbyge` was inspected read-only. The `schoolpro-payment-receipts` bucket exists, is private, has a **5,242,880-byte (5 MiB)** object limit, and allows only JPEG, PNG, WebP and PDF. No bucket settings were changed.
- Production currently has these three matching `storage.objects` policies, all scoped to `authenticated`:
  - `guardian upload payment receipts`: INSERT only when the first object-path segment equals `auth.uid()`.
  - `guardian read own payment receipts`: SELECT only when the first object-path segment equals `auth.uid()`.
  - `school finance read payment receipts`: SELECT when the object path is referenced by `schoolpro_payment_proofs.receipt_path` and `private.has_school_access` succeeds for proprietor, administrator, accountant or bursar.
- The live `private.has_school_access(uuid, school_member_role[])` helper exists, uses `SECURITY DEFINER` with an empty search path, and checks active profile status plus platform-admin, school-owner or school-member role. The four role enum values used by the receipt policy are valid in production.
- Production also has the current `public.schoolpro_payment_submissions` table, which is written by the fee-payment submission RPC `public.submit_schoolpro_payment`. That RPC validates that the receipt object exists in `schoolpro-payment-receipts`, is under the caller's UID prefix and is owned by that caller. Its receipt path is stored in `schoolpro_payment_submissions.receipt_path`, not necessarily in the legacy `schoolpro_payment_proofs` table.
- **Confirmed policy coverage gap:** the original draft finance-read policy checked only `schoolpro_payment_proofs`. A finance user whose receipt is linked through the current `schoolpro_payment_submissions` flow could therefore fail to download that receipt through Storage. This is a schema/workflow mismatch, not evidence that a cross-school disclosure occurred.

### Draft remediation committed to Stage A branch

- Updated `20261017150000_schoolpro_payment_receipt_storage_policies.sql` so finance receipt reads can be authorized against either the legacy `schoolpro_payment_proofs` row or the current `schoolpro_payment_submissions` row, with the school/role check required in both branches. The bucket-id check encloses both branches to avoid accidentally permitting a match outside the receipt bucket.
- Updated both draft receipt bucket migrations to preserve the production-observed 5 MiB limit instead of silently increasing it to 10 MiB. The allowed MIME list and private-bucket setting remain aligned with production.
- Extended the isolated local Supabase fixture/test to include a current payment-submission row, a finance member in each of two synthetic schools, and assertions that finance can read its own school's linked receipt but cannot read the other school's receipt. The existing own-user upload/download and cross-user denial checks remain.
- Commits on `release/stage-a-auth-tenant-isolation`: policy schema/flow alignment `5a8b509cfb8d3b05f86ceed8d60077f71bdffaf1`; bucket limit alignment `acad6479eedbd7b448675b5b901bce63db008091`; fixture `cab664b0123532391895e929b5886aa7936e0b0b`; finance isolation test `6683ece5f6cbbffca5a00362d4777c63a3b7acbf`; final bucket-scope predicate correction `2e062df65e3b39abe5c840e1ca16d9063929d867`.
- New validation triggered on final policy commit: SchoolPro CI #1373 and payment-page validation #1100. They were queued at the time this entry was written; do not mark the new finance assertion passed until #1373 finishes and its local Storage job log is inspected.

### Migration source/ledger drift — explicit hold

- The production migration API returned **476 recorded migrations**, with the latest exact version/name pair `20261015161735 / schoolpro_access_invitation_role_constraint`. No source migration versions dated 2026-10-16 or 2026-10-17 in this Stage A PR are recorded in that ledger.
- Exact source files present in the PR but not recorded under their exact version/name pair in the production ledger include:
  - `20261015203000_schoolpro_payment_receipt_tenant_guard.sql`
  - `20261016110500_schoolpro_optimize_family_report_media_storage_policy.sql`
  - `20261016122000_schoolpro_result_pin_attempt_rate_limit.sql`
  - `20261016143000_schoolpro_payment_review_write_controls.sql`
  - `20261016160000_schoolpro_repair_operational_tenant_integrity.sql`
  - `20261016170000_schoolpro_disable_online_payment_gateway.sql`
  - `20261016180000_schoolpro_payment_receipt_storage_limits.sql`
  - `20261017103000_schoolpro_document_serial_global_uniqueness.sql`
  - `20261017120000_schoolpro_result_verification_minimal_snapshot.sql`
  - `20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql`
  - `20261017150000_schoolpro_payment_receipt_storage_policies.sql`
- The production receipt policy names already exist even though the recent source files are absent from the ledger. This establishes source/ledger drift; it does **not** establish which historical SQL created the live policies or prove every source migration is unapplied in behavior. Do not replay this list wholesale or use migration version insertion to conceal drift. Build a migration-by-migration reconciliation against actual live definitions, constraints, triggers, grants, functions and bucket configuration; map equivalent behavior only when evidenced, then prepare an explicit reviewed baseline/forward-only migration plan.
- The draft policy migration remains unapplied to production. No production schema, bucket, row, secret, deployment or merge was changed during this review.

### Remaining Stage A security/release gates

1. Await and inspect CI #1373 after the finance-path Storage assertions were added; require all jobs to pass at the latest PR head.
2. Complete per-migration source/ledger reconciliation; the 11-file list above is an inventory, not permission to apply them.
3. Execute complete payment lifecycle tests for submit, review, reject/cancel, direct-write denials, receipt ownership, duplicate allocations and concurrent transactions using the current schema/policies. Existing disposable RPC/RLS tests cover only part of this lifecycle.
4. Complete runtime/performance acceptance for the family report-media Storage policy, and verify trusted client-IP provenance for login throttling (do not trust caller-controlled forwarding headers without evidence).
5. Finish authenticated invitations/first-login checks and the nine anonymous-callable SECURITY DEFINER RPC abuse/data-minimization review; keep the seven policy-less RLS tables fail-closed because production confirms anon/authenticated direct table privileges are absent.
6. Review the full trigger/constraint set and actual trigger order against operational workflows. CI success alone is not production migration parity.
7. Keep PR #106 draft/open and Stage A **NOT MERGE-READY** until all required evidence is reviewed and the user explicitly approves the release. Stage B remains blocked.


## 23. Additional production grant audit — anonymous finance-table grants (2026-10-17)

- A read-only ACL audit of production showed explicit `anon` grants for SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES and TRIGGER on each of `schoolpro_invoices`, `schoolpro_payment_allocations`, `schoolpro_payment_proofs`, and `schoolpro_payment_submissions`. `schoolpro_fee_payments` is also included in the same financial-workflow hardening scope.
- These tables have RLS enabled, and the reviewed policies for these finance/payment workflows target `authenticated`; this observation alone is **not evidence that anonymous requests currently read or mutate rows**. However, the grants are unnecessary excess privilege and create avoidable dependence on every RLS policy remaining correct.
- Updated the draft `20261016143000_schoolpro_payment_review_write_controls.sql` to revoke table privileges from `PUBLIC` and `anon` for invoices, allocations, proofs, submissions and fee-payment ledger rows while retaining explicit authenticated grants. No production grant was changed.
- Extended the disposable payment-review RLS integration fixture to simulate the broad grants observed in production, then assert that the migration removes anonymous SELECT/INSERT access while authenticated submission SELECT/INSERT privileges remain. CI on the latest code head must pass before this remediation can be considered validated.
- This finding is added to the Stage A risk register. The migration is still draft/unapplied; do not apply it independently of the full source/ledger reconciliation and reviewed release plan.


## 24. Public result-verification data-minimization gap found and patched in draft (2026-10-17)

- Read-only inspection of the live production definitions found `public.issue_schoolpro_result_verification` stores legacy snapshots shaped as `results[]` with `subject_id`, `total_score` and `assessment_scores`. The live anonymous-callable `public.schoolpro_verify_result_code(text)` returned `v.snapshot` unchanged for valid codes.
- The draft migration `20261017120000_schoolpro_result_verification_minimal_snapshot.sql` had changed the issuer to store only `total` and `average`, but did not change the public reader. That meant any legacy detailed snapshot could still be returned raw if an old valid code existed. Production currently has **zero** rows in `schoolpro_result_verifications`, so no existing snapshot records were exposed in this read-only check; the function-level disclosure path was nevertheless real and needed closure.
- Updated the draft migration to replace the public reader as well as the issuer. The reader now returns only aggregate `total`/`average` for new aggregate snapshots, derives only those two fields from legacy `results[]` snapshots, returns no snapshot for revoked/non-valid records, and returns null for unrecognized snapshot formats. It does not pass through subject identifiers or assessment breakdowns.
- Extended the disposable PostgreSQL integration test to assert the 192-bit code format, the aggregate snapshot from the issuer, aggregate-only output for new codes, sanitization of a synthetic legacy detailed snapshot, and null snapshot after revocation. The latest source commit for this fix is `f71cfed3db2b097cef2b53ff05c25fb43a9a145a`; require the corresponding SchoolPro CI run to pass before counting it as validated.
- The production `schoolpro_document_issues` table has no global normalized serial index today; the current unique index is only `(school_id, serial_number)`. A read-only duplicate check found **zero** groups colliding on `upper(trim(serial_number))`, so the draft global-uniqueness migration's duplicate precondition is currently satisfied. The global index remains unapplied/unrecorded until migration drift is reconciled and approved.
- Production also has no `private.schoolpro_result_pin_attempts` table or `private.record_schoolpro_result_pin_failure(text)` function, while the live anonymous `check_schoolpro_result_pin` returns subject totals and assessment-score detail after admission/PIN validation but has no database-level cooldown. The draft cooldown migration is not live; verify trusted network-identity provenance before relying on IP-derived throttling.
- The live `submit_schoolpro_application` definition also lacks the draft hourly/daily database abuse controls. Public admission rate-limit migration remains a forward-only draft, and its caller/network-key design must be reviewed against trusted edge provenance before release.
- The live `finalize_schoolpro_payment` function already fails closed for online/card payment, consistent with the product requirement that SchoolPro uses receipt upload and finance/admin review, not BillStack. Its draft source migration is still absent from the exact production ledger and must be reconciled rather than blindly replayed.
- These findings reinforce the hold: PR #106 is still draft/open; no production SQL, row, Storage object, or deployment was changed. Public RPC hardening and the exact migration plan remain release blockers.


## 25. Live function/index marker reconciliation — release blockers confirmed (2026-10-17)

This is a read-only comparison of key behaviors in production against the draft migrations. It deliberately distinguishes an object existing from the proposed migration being recorded or equivalent.

| Draft source | Production evidence | Reconciliation status |
|---|---|---|
| `20261015203000_schoolpro_payment_receipt_tenant_guard.sql` | `public.submit_schoolpro_payment(uuid,uuid,numeric,date,text,text,text,text,jsonb)` exists, but live function definition does **not** contain the receipt-owner check, UID path-prefix check, pending-allocation reservation, or deterministic invoice row lock from the draft. | **Critical live gap.** Draft is not recorded and these guards are not present in the inspected live function. Keep as first release blocker; do not apply until migration drift and full schema are reconciled. |
| `20261016110500_schoolpro_optimize_family_report_media_storage_policy.sql` | Live family report-media Storage policy and helper exist, but none of the four proposed exact-path indexes exists. | Optimization is not present by those index names; the previously documented Storage-list timeout/performance concern remains. |
| `20261016122000_schoolpro_result_pin_attempt_rate_limit.sql` | Neither `private.schoolpro_result_pin_attempts` nor `private.record_schoolpro_result_pin_failure(text)` exists. | Cooldown is not live. Do not rely on the draft's request-network identifier until trusted-edge provenance is independently verified. |
| `20261016143000_schoolpro_payment_review_write_controls.sql` | Live review RPC has row locking, and restrictive finance-module policies already exist on payment tables. Anonymous grants are nevertheless present on sensitive financial tables. | Partial/equivalent live behavior exists, but exact migration parity is unproven. Draft now also revokes unnecessary `PUBLIC`/`anon` table privileges and tests that authenticated grants remain. |
| `20261016160000_schoolpro_repair_operational_tenant_integrity.sql` | Proposed `private.schoolpro_validate_operational_tenant()` helper is absent. Six triggers with tenant-related names exist, but the exact live definitions must be compared table-by-table before assuming equivalent protection. | Do not apply blindly; reconcile existing trigger functions, trigger timing/order, and all affected relations. |
| `20261016170000_schoolpro_disable_online_payment_gateway.sql` | Live `public.finalize_schoolpro_payment` already raises a fail-closed exception for the unsupported online-payment flow. | Desired behavior appears present; exact source/ledger provenance still missing, so record as likely equivalent behavior pending full definition/grant comparison rather than reapplying automatically. |
| `20261016180000_schoolpro_payment_receipt_storage_limits.sql` and `20261017150000_schoolpro_payment_receipt_storage_policies.sql` | Live bucket is private, 5 MiB, and allows JPEG/PNG/WebP/PDF; all three named receipt policies exist. | Bucket metadata and policy names exist, but source migration entries are absent from the ledger. The draft now preserves the 5 MiB live limit and expands finance-read coverage to the current submission table; local runtime test is pending on the latest head. |
| `20261017103000_schoolpro_document_serial_global_uniqueness.sql` | Only per-school serial uniqueness exists; no global normalized index. A read-only duplicate check found zero duplicate groups for `upper(trim(serial_number))`. | Forward migration's precondition is currently satisfied; index still absent/unrecorded. |
| `20261017120000_schoolpro_result_verification_minimal_snapshot.sql` | Live issuer stores `results[]` including subject IDs and assessment scores; live public reader returns stored snapshot raw. Production has zero verification rows currently. | Public-reader data-minimization fix is necessary for future/legacy codes; the draft now sanitizes both newly issued and legacy snapshots and has disposable integration coverage. Not live. |
| `20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql` | Live public application RPC has no database-level hourly/daily contact limits. Existing edge-gateway Turnstile checks are a separate layer and do not prove the RPC itself is rate-limited. | DB abuse controls remain absent from production. Review and test draft contact-key serialization; avoid relying on unverified client IP headers. |

### Additional privilege and workflow observations

- Production direct ACLs grant `anon` broad table privileges on the five finance tables listed in section 23. RLS currently remains enabled and reviewed policies are role-scoped, but this should be corrected by the forward migration, then tested using real database grants plus RLS in disposable PostgreSQL.
- The legacy `schoolpro_payment_proofs` table and current `schoolpro_payment_submissions` table coexist. Receipt-storage authorization must handle both explicitly; the current fee-payment RPC writes the latter.
- Production has no receipt objects in `schoolpro-payment-receipts`; all production receipt-object tests remain skipped. Local tests must cover guardian own/cross-user access and finance own-school/cross-school reads without adding production fixtures.
- The production migration ledger still ends at `20261015161735 / schoolpro_access_invitation_role_constraint`; the source/ledger mismatch is not resolved by these object-presence checks. Several proposed behaviors are absent, while others appear to exist from unrecorded/manual/overlapping SQL. Reconstruct provenance and compare full live definitions before any application.
- **Priority order:** (1) receipt-submission RPC ownership/locking guard; (2) latest CI including local Storage, payment RLS and result snapshot integration; (3) public RPC abuse/data-minimization and trusted-edge review; (4) family Storage policy performance; (5) full trigger/index/migration-ledger reconciliation. Stage A remains draft/open and no production change is authorized.


## 26. Receipt RPC transaction-concurrency acceptance added (2026-10-17)

- Extended the disposable PostgreSQL receipt-submission fixture with a third isolated invoice that has a 1,000-unit balance, separate from invoices used by the ordinary positive/negative cases.
- Added a CI step that launches two independent PostgreSQL sessions concurrently, each attempting a 600-unit allocation against that same invoice. Acceptance requires exactly one submission to succeed and exactly one pending allocation totaling 600; the losing request must not over-reserve the invoice.
- Test changes: fixture commit `4ba918d26770a900efbe0937b5b398b700567b41`; workflow commit `b8b29feb02930e6662b94aacf21423903fa807e9`. The current PR head inspected is `dc6ac60f325620097cbcb6ada200c6374e0e72aa`.
- At the time of this entry, payment-page validation run #39025103288 was still in progress. The latest confirmed passing runtime evidence remains the earlier local receipt-Storage isolation run; this newly added concurrency assertion is **not yet counted as passing** until the PostgreSQL integration job has run and its log/result has been inspected.
- The new concurrency test is disposable-only and does not create or alter production payment rows. No production migration was applied and PR #106 remains draft/open.


## 27. Latest run check after concurrency-test addition (2026-10-17 11:29 +01:00)

- PR #106 remains open and draft at head `dc6ac60f325620097cbcb6ada200c6374e0e72aa`; it has 48 changed files and is **not merge-ready**.
- Payment-page validation run #39025103288 completed successfully. This validates that workflow's payment-page checks only; it does not execute the PostgreSQL receipt-RPC race test, payment-review RLS fixture, local Supabase Storage policy test, or the complete SchoolPro CI matrix.
- The workflow-run lookup for this exact head returned only the payment-page validation run. Therefore, the newly added database integration test has no confirmed execution evidence on the current head. Do not describe the overall Stage A security CI as green based solely on the payment-page result.
- The receipt-RPC integration fixture now contains a third isolated invoice for the 600+600 concurrency case. The test harness records each independent RPC result, requires one accepted/one rejected request, and asserts the resulting allocation sum is exactly 600. This source-level review looks internally consistent; runtime evidence is still required.
- Next gate: obtain a full SchoolPro CI run against the current PR head and inspect the actual job logs for receipt RPC concurrency, payment-review RLS grant revocation, local Storage finance-path isolation, result-snapshot sanitization, result-PIN cooldown, admission abuse controls and tenant integrity. If workflow dispatch is unavailable, do not substitute a prior commit's green run for current-head evidence.
- The master handover was updated on `migration/mysql-schoolpro-foundation` at commit `327dc1cfb72b04ba8dcd5a832f94de8c120cb375` before this latest run check. This entry is the follow-up record; no production change was made.


## 28. Public-admission RPC execution-boundary check (2026-10-17)

- Read-only production function metadata confirms `public.submit_schoolpro_application(...)` currently grants EXECUTE to both `anon` and `authenticated`, while the draft abuse-control migration intends to revoke those direct grants and grant EXECUTE only to `service_role`.
- Reviewed `supabase/functions/schoolpro-public-admission/index.ts` on the Stage A branch: the Edge Function verifies the Turnstile token first, then constructs its Supabase client using `SUPABASE_SERVICE_ROLE_KEY` and invokes `submit_schoolpro_application`. This supports the proposed RPC boundary: public clients use the Turnstile-verifying Edge Function; the server-side Edge Function invokes the database RPC.
- The edge-to-RPC integration was confirmed by source inspection only. It does not prove the deployed Edge Function version matches this branch, nor that production function grants have been changed. Do not apply the migration or claim the direct-anonymous path is closed until post-application grant checks and a deployed-path smoke test are approved and completed.
- Production function metadata also confirms the public result-verification reader has the expected nine-column table result and is intentionally executable by `anon`; its data minimization must therefore be enforced inside the function body, not by removing anonymous execute.
- Current migration ledger still ends at `20261015161735 / schoolpro_access_invitation_role_constraint`; no new source migration is marked as applied. No production SQL or deployment was changed in this check.


## 26. Concurrent payment acceptance added to CI (2026-10-17)

- Extended the disposable receipt-submission RPC fixture with a third invoice for concurrency testing.
- Added a CI step that launches two concurrent submissions of 600 units against the same 1,000-unit invoice and asserts exactly one submission/allocation is accepted and exactly 600 units remain reserved. This exercises the draft RPC's row-lock and pending-allocation reservation behavior instead of relying only on source assertions.
- Added a static CI-wiring assertion to `scripts/test-schoolpro-receipt-submission-guards.mjs`.
- Commits: fixture `4ba918d26770a900efbe0937b5b398b700567b41`; workflow `b8b29feb02930e6662b94aacf21423903fa807e9`, quoting correction `dc6ac60f325620097cbcb6ada200c6374e0e72aa`; wiring assertion `a7c5d459add760368641b5305d55ed63f3a9427a`.
- The prior exact-head CI run passed payment RLS, result-snapshot integration, tenant acceptance and local Storage on commit `37ee1c1d766056f49e04cbd77f329a79b529530e`, but it preceded the new concurrency step. At the latest check, the new head had payment-page validation in progress and a new SchoolPro CI run had not yet appeared in the workflow-run lookup. **Do not count the concurrency test as passed until a run actually executes that step.**


## 29. Operational tenant-trigger review against production (2026-10-17)

- Read-only schema inspection confirmed that all columns referenced by the draft tenant validator exist on the corresponding production tables: lesson note `school_id/subject_id/class_id`; result approval `school_id/result_id`; promotion `school_id/student_id/from_class_id/to_class_id`; and permission row `school_id/member_id`.
- Production has existing BEFORE triggers on lesson notes for activation, lesson workflow, activity-session preservation and activity-calendar validation; promotions have activation protection plus an AFTER trigger that archives applied progression; result approvals have activation protection. The two draft helper functions `private.schoolpro_validate_operational_tenant()` and `private.validate_schoolpro_member_permission_tenant()` are absent from production.
- The draft trigger names sort after the existing `schoolpro_*` BEFORE trigger names under PostgreSQL's alphabetical trigger-order rule. Source review of the existing trigger functions found they validate activation/workflow/calendar/session or archive progression; they do not rewrite the tenant ownership columns being checked by the new validator. The proposed AFTER promotion archive trigger remains after all BEFORE validations.
- The draft adds tenant checks for lesson subject/class, approval result, promotion student/source/destination class, immutable `school_id` on subjects/classes/students/results/members, and the member-permission/member school match. The current production schema has the referenced IDs and tenant columns, but production FK/constraint definitions and the complete set of cross-tenant data rows still require a full relation-by-relation audit before application.
- This is a positive source/schema compatibility check, **not** proof that the migration is safe to apply over all production data. The live migration ledger remains behind source, and the migration must be exercised against a production-shaped disposable schema plus cross-tenant negative cases before any approval.
- No production writes or trigger changes were performed. Stage A remains draft/open.


## 30. Read-only preflight for existing cross-tenant operational references (2026-10-17)

The following aggregate-only production preflight returned zero mismatched rows for each checked relationship:

| Relationship | Mismatched rows |
|---|---:|
| Lesson note → subject school | 0 |
| Lesson note → class school | 0 |
| Result approval → result school | 0 |
| Promotion → student school | 0 |
| Promotion → source class school | 0 |
| Promotion → destination class school | 0 |
| Member permission → member school | 0 |
| School member with null school ID | 0 |

This is useful preflight evidence that the proposed tenant-integrity triggers should not immediately reject existing rows on these specific relationships. It is not a full data-integrity certification: it only covers rows with a resolvable referenced record, and does not replace foreign-key validation, null/orphan detection, trigger tests, or the complete source/ledger reconciliation. The query returned counts only and did not modify data.


## 31. Removed unverified request-IP dependency from result-PIN cooldown (2026-10-17)

- A focused security review found the draft result-PIN migration was deriving its rate-limit key from `request.headers ->> 'cf-connecting-ip'`. Although the source comments described that header as Cloudflare-provided, we had not independently established the exact trusted-proxy overwrite semantics reaching the database. That was not strong enough evidence for an IP-based database security control.
- Changed the draft key to a SHA-256 digest of normalized admission number + term + session. The raw admission/PIN values are not stored in the attempt table; the existing advisory transaction lock, eight-failure threshold, 15-minute cooldown, generic wrong/unknown error and success reset remain. The implementation no longer reads `request.headers` or uses any IP/forwarding header.
- Updated static migration checks, disposable PostgreSQL integration assertions and the concurrent wrong-PIN CI step to use the deterministic admission-period key. Changes on `release/stage-a-auth-tenant-isolation`: migration `f310bc33b796473315ed86768fd09bf79a83996c`, static test `21ed9c9d9e8c3ce238fc66969c4e9c0b53e77e5b`, integration test `d716e2927cee3479abab5db615fe24b0f78076d7`, workflow `2d65f8031259778a7975e0a869a9dee4abb6dd25`.
- Trade-off explicitly accepted for this draft: an attacker who knows an admission number and period could trigger the per-period cooldown for that identifier, and duplicate admission numbers across schools can share a bucket because the public RPC has no school identifier. This is preferable to relying on an unverified caller-supplied network identity, but before release consider whether the public result flow should require a school code/slug and bind the cooldown to school + admission + term + session. Do not claim the production abuse-control gap is closed until this draft passes CI, the client contract is reviewed, and the migration is approved/applied through the reconciled release plan.
- No production SQL was applied. Stage A remains draft/open.


## 32. Result-PIN cooldown key finalized against period-switch bypass (2026-10-17)

- A follow-up adversarial review found that a key containing admission + term + session could be evaded by changing the requested term/session on each attempt. The draft has therefore been tightened to hash **only the normalized admission identifier**, independent of caller-selected period and request headers.
- Updated the migration to use `extensions.digest(lower(trim(coalesce(p_admission, ''))), 'sha256')`; updated static assertions, the disposable SQL integration test, and the concurrent wrong-PIN CI assertion to expect that same key.
- Commits: migration `e4e5e7435d7f04b51f3461da9f76fea81a938c87`; static test `96dae531b32a6589eb2f32e4b5b3d5b3f3d7bacc`; integration test `9c8b08589f572f71447ec8bdd68e867bf41144af`; workflow `45c63b6ba9bb07a34b2b5759fff65b1da0827d7b`.
- Security trade-off: identical admission numbers across schools share one cooldown bucket because the current public RPC contract has no school identifier. A future UI/RPC change can scope the hash to school + admission while retaining protection against term/session switching. This limitation is explicit and should be weighed in release review; do not restore unverified IP headers as a workaround.
- The previous section's admission-period-key wording is superseded by this entry. No production SQL was applied.


## 33. CI #39025648709 failure analysis and follow-up fixes (2026-10-17)

Run: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39025648709

| Job | Result | Evidence / action |
|---|---|---|
| Tenant acceptance | PASS | Live read-only two-school checks completed; production receipt-object checks remain explicitly skipped because the bucket has no safe fixture objects. |
| Payment-review RLS integration | PASS | Disposable PostgreSQL executed the grants/policies and verified the intended role boundaries. |
| Public-admission abuse integration | PASS | Disposable PostgreSQL assertions passed. |
| Result-PIN cooldown integration | PASS | The no-IP, admission-key draft executed successfully; concurrent cooldown assertion is included in the job. |
| Result-verification exposure integration | PASS | New aggregate and legacy snapshot sanitization assertions passed. |
| Receipt Storage isolation (local Supabase) | PASS | Runtime API test passed for own upload/download, cross-user denial, and school-finance own-school/cross-school receipt reads. |
| Tenant-integrity DB integration | FAIL | The receipt RPC test intentionally deactivated bank account `...0001`; the new race step reused it, so both requests failed before invoice locking. Added a second active disposable bank account `...0002` and switched the race step to that account. No production records were involved. |
| Static validate | FAIL | `scripts/test-schoolpro-receipt-submission-guards.mjs` had an over-escaped regex that did not match the actual workflow step. Corrected the regex to use the intended any-character matcher. |

- The fixes are on `release/stage-a-auth-tenant-isolation`; latest inspected PR head after the static-test correction is `33a2ef17155092290f55a9644e710e3720eabcc3`.
- Run #39025751460 was queued on the immediately preceding head before the final static-test correction; its result cannot validate the current head. A new full CI run on `33a2ef1...` must confirm both fixes and re-run all jobs before the overall CI can be called green.
- Current positive evidence from #39025648709: five security/integration jobs plus tenant acceptance and local Storage isolation passed. The overall run failed and Stage A remains **NOT MERGE-READY**.


## 27. Result-PIN abuse control redesigned without trusting request IP headers (2026-10-17)

- The initial draft rate-limit migration used `request.headers` / `cf-connecting-ip` as a database rate-limit identity. That was removed because this project has not independently proven the exact request-header provenance for direct PostgREST calls. The migration now hashes normalized admission + term + session, serializes same-key attempts, counts unknown admissions and wrong PINs, applies an eight-failure/15-minute cooldown, and clears the key on successful result access. It does not read `request.headers`, `cf-connecting-ip`, `x-forwarded-for` or `x-real-ip`.
- To prevent a browser from bypassing Turnstile and calling the SECURITY DEFINER RPC directly, the draft migration now revokes execution of `public.check_schoolpro_result_pin(text,text,text,text)` from `PUBLIC`, `anon` and `authenticated`, granting execution only to `service_role`.
- Added `supabase/functions/schoolpro-result-pin-check/index.ts`. It checks POST/origin allowlist, request-body size, a dedicated Turnstile action/hostname through the shared server-side verifier, and then calls the database RPC using the service-role client. It does not use client IP headers. Its origin allowlist uses `SCHOOLPRO_RESULT_CHECK_ALLOWED_ORIGINS` when set and falls back to the existing `SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS`; it reuses `TURNSTILE_SECRET_KEY`, `TURNSTILE_ALLOWED_HOSTNAMES` and the existing public site key.
- Updated `SchoolProResultChecker.tsx` to render the Turnstile challenge and invoke the Edge Function instead of calling the database RPC directly. Added `[functions.schoolpro-result-pin-check] verify_jwt = false` in local Supabase config; the function implements its own origin/challenge controls.
- Added integration assertions that anonymous/authenticated roles cannot execute the RPC and the service role can. Added static gateway checks and CI wiring. Updated the concurrent cooldown test to use the admission-period hash rather than a request IP.
- Current Stage A head after these draft changes: `4b13a0dce42890448d34ae11b78223d4c9cb7899`. SchoolPro CI run `39025908106` and payment-page validation `39025908128` were queued at the time of this update; require completion and inspect failures before counting this change as validated.
- **Residual trade-off:** the no-IP database cooldown is keyed by admission and result period, so a targeted person who can repeatedly pass Turnstile may still cause a temporary lockout for that specific admission/period. The eight-failure threshold and 15-minute window are explicit draft settings and must be reviewed against school support/abuse expectations. Do not replace them with an unverified IP-header identity.
- No production function grants, Edge Function deployments, secrets or app deployments were changed. Production continues to expose the old direct result-PIN RPC until the reviewed migration and Edge Function are approved and deployed together; this is a release blocker, not a completed production fix.


## 34. Follow-up after CI #39025648709 — fixture and static-test corrections queued for rerun (2026-10-17)

- Fixed the race-test fixture isolation by adding a second active bank account (`30000000-0000-0000-0000-000000000002`) and using it in the concurrent 600+600 invoice-reservation test. The prior negative-case test still deactivates the first account intentionally; the race test no longer depends on that mutable fixture state.
- Fixed the static workflow assertion's over-escaped regular expression so it actually matches the concurrency CI step rather than testing for literal backslash sequences.
- Reconciled a stale result-PIN test expectation: the migration, SQL integration test, concurrent workflow assertion and static migration test now all use the **admission-only SHA-256 key**. The key does not depend on IP headers or caller-selected term/session, preventing cooldown bypass by changing the requested period. The cross-school duplicate-admission trade-off remains as documented in section 32.
- Current PR head at the latest check: `6122719194519ffd463f93f484e654d9a239cb2f`. SchoolPro CI run #39026007562 is queued and payment-page validation #39026007491 is in progress for this head. The prior run's passing jobs remain evidence for the code at its own head only.
- Do not mark the two corrected failures resolved until the new CI run finishes. Stage A remains draft/open, no production SQL or migration was applied, and no merge was performed.


## 28. Anonymous SECURITY DEFINER RPC inventory and direct-bypass findings (2026-10-17)

Read-only privilege inspection found nine `public` SECURITY DEFINER functions callable by `anon` in production. This inventory separates intentional bearer-token/public verification functions from high-risk paths; it does not imply that all nine are exploitable.

- **`submit_schoolpro_application(...)` — high priority:** anon can execute the RPC directly today. The live definition lacks database-level hourly/daily contact limits, so callers can bypass the public page's Turnstile Edge Function by invoking PostgREST directly. The draft admission-abuse migration revokes direct API execution and grants it only to `service_role`, with serialized contact-key limits. This migration is absent from the production ledger and has not been applied.
- **`check_schoolpro_result_pin(...)` — high priority:** anon can execute the RPC directly today, and the live function has no database cooldown while returning published subject/assessment scores after admission/PIN validation. The draft now adds a hashed admission-period cooldown, revokes direct anon/authenticated execution, and introduces the Turnstile-gated `schoolpro-result-pin-check` Edge Function. The function grant change, Edge Function deployment, configuration, and UI change must ship together; none has been deployed to production.
- **`schoolpro_verify_result_code(text)` — public bearer-code reader:** intended public verification, with a high-entropy verification code. The live reader returns snapshots raw; the draft result-verification migration now sanitizes legacy and new snapshots. Production currently has zero verification rows.
- **`verify_schoolpro_document(text)` — public serial lookup:** no database rate limit was found. Production only has per-school serial uniqueness; the global normalized serial index is absent, although a read-only duplicate check currently found zero duplicate groups. The public lookup's `limit 1` is not a substitute for global uniqueness.
- **`get_schoolpro_admission_offer(uuid)` / `accept_schoolpro_admission_offer(uuid,...)` — bearer-token flows:** both are anon-callable, but the inspected definitions check the public token and expiry; acceptance also row-locks the offer and application. Continue validating token generation entropy, expiry and replay behavior. Do not remove their public access without an explicit replacement workflow.
- **`get_candidate_cbt(uuid)`, `save_candidate_cbt_answer(uuid,...)`, `submit_candidate_cbt(uuid)` — bearer-token CBT flows:** inspected definitions check access-token existence, expiry/test status/deadline and lock the attempt row. Keep these token-based routes in the acceptance suite and verify the rate-limit guards are actually present in the live definitions rather than inferred from the draft migration.

### Required production acceptance before Stage A release

1. Apply no migrations until the 11-entry source/ledger drift is reconciled against actual live definitions and the user approves a forward-only plan.
2. The result-PIN gateway change requires a successful CI run including the static gateway test and disposable RPC privilege assertions, then a coordinated production migration + Edge Function deployment + frontend release. Verify the existing `VITE_TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY`, `TURNSTILE_ALLOWED_HOSTNAMES`, and admission-origin allowlist are configured without printing or changing secret values.
3. Test direct anonymous RPC calls after migration: application submission and result-PIN RPC must be denied; the corresponding Edge Functions must enforce Turnstile and return generic errors. Preserve public result verification and token-based admission/CBT flows where required.
4. Add/retain abuse tests for public document serial lookup and admission-offer token expiry/replay; do not trust unverified IP headers as a database security boundary.
5. The production payment-submission RPC ownership/locking gap remains the top database correctness/security blocker. Keep Stage A and Stage B blocked until the new CI concurrency check passes and the migration plan is approved.

No production RPC grants, data, Storage objects, secrets, or deployments were changed by this inventory.


## 35. Source/test parity rechecked at current Stage A head (2026-10-17)

- Re-fetched all six relevant files at exact commit `cb2fe8ad841b0b2699859750e215b9b905d81114`. Confirmed the result-PIN migration, static test, SQL integration test and concurrent CI assertion all consistently use the SHA-256 digest of normalized admission number only. No request-IP header and no caller-selected term/session participates in the cooldown key.
- Confirmed the concurrent receipt-submission test uses the second active fixture bank account `30000000-0000-0000-0000-000000000002`; the receipt-RPC integration fixture inserts that account before its intentional deactivation of the first account. The static workflow assertion now uses a valid JavaScript any-character matcher and targets the concurrency step.
- SchoolPro CI run #39026167994 is queued for the exact current PR head `cb2fe8ad841b0b2699859750e215b9b905d81114`; payment-page validation #39026168066 is in progress. No pass is attributed to the current head until its CI jobs complete and logs are checked.
- No production change or merge occurred. PR #106 remains draft/open; migration-ledger reconciliation, full payment lifecycle review, family media-policy runtime/performance review and trusted-edge/public-RPC review remain release gates.


## 29. Result-PIN cooldown key scope clarification (2026-10-17)

- The latest Stage A draft now intentionally hashes **normalized admission number only** for the 8-failure / 15-minute cooldown. It does not use request headers or any client-IP value. The migration comments, static assertion, SQL integration fixture and concurrent test use the same admission-only key.
- This scope prevents attackers from varying term/session inputs to obtain separate failure counters, but it also means a targeted attacker who passes Turnstile can temporarily block result checks for that admission across all periods. That is a known residual denial-of-service trade-off; the new Turnstile gateway and service-role-only RPC grant reduce direct automation/bypass but do not eliminate targeted lockout.
- Keep this behavior as a release-review item. Before production deployment, decide whether the broader lockout scope is acceptable or whether a verified, non-spoofable edge identity is available and can be proven end-to-end. Do not substitute an unverified request header. No production grant or cooldown was changed.


## 36. Family report-media path-index production preflight (2026-10-17)

- Read-only schema/index inspection confirmed all four path columns referenced by the draft optimization exist. Production has no existing index on `photo_storage_path`, `principal_signature_path`, `form_teacher_signature_path`, or `logo_storage_path`; the workbook `storage_path` column is already covered by a separate unique index and is not the same lookup column.
- Aggregate counts on the active production data returned: student photo paths 0; principal signature paths 0; form-teacher signature paths 0; result-template logo paths 0; workbook storage paths 1. No path values were retrieved.
- These counts suggest low current data volume for the four indexed media lookups, but they do not prove policy evaluation is cheap: Storage policy checks can run against the bucket's object population and the authorization helper still contains nested result-access checks. Keep the draft indexes/policy change subject to disposable query-plan/runtime testing, especially at representative bucket-object scale; do not benchmark destructively or create fake objects in production.
- No production change was made.


## 30. Full Stage A CI evidence after receipt/payment/result hardening (2026-10-17)

- SchoolPro CI [run #1421](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39025908106) completed **successfully** on code head `4b13a0dce42890448d34ae11b78223d4c9cb7899`; payment-page validation [run #1148](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39025908128) also passed.
- All eight SchoolPro CI jobs passed: `validate`, `tenant-acceptance`, `tenant-integrity-db-integration`, `payment-review-rls-integration`, `public-admission-abuse-integration`, `result-pin-rate-limit-integration`, `result-verification-exposure-integration`, and `Receipt Storage isolation (local Supabase)`.
- Verified log evidence includes:
  - local Storage: own-user synthetic upload/download works; cross-user download/upload is denied; finance can read its own school's linked submission receipt and is denied another school's receipt;
  - payment RPC: valid receipt submission persisted; six invalid cases were rejected; two concurrent 600-unit submissions against the same 1,000-unit invoice produced exactly one pending reservation;
  - tenant integration: cross-tenant child writes/unsafe parent reassignment were rejected, legacy online finalizer is fail-closed, and the disposable receipt RPC tests passed;
  - result verification: aggregate-only snapshot and legacy-snapshot sanitization integration passed;
  - payment RLS: anonymous finance-table grants were revoked in the disposable migration fixture while authenticated access remained;
  - result-PIN: eight concurrent wrong-PIN requests serialized into one cooldown key in that run.
- **Latest-head qualification:** subsequent commits changed the result-PIN cooldown key from admission+period to admission-only, aligned the static/integration assertions, and corrected the migration comments. The passing run above predates that final key-scope choice. The corresponding latest-code SchoolPro CI run `39026135034` was queued when checked, and run `39026200592` for the comment-only follow-up was also queued. Do not call the latest head fully green until the queued latest-code run executes and passes.
- The successful run validates the draft/local acceptance suite only. It does not prove the draft migrations have been applied to production or reconcile the missing production migration-ledger entries. The live payment-submission guard gap, direct public RPC bypasses, and remaining schema/ledger review are still release blockers. PR #106 remains draft/unmerged and Stage B remains blocked.


## 37. Added explicit result-PIN cooldown period-switch regression (2026-10-17)

- Strengthened `scripts/test-schoolpro-result-pin-rate-limit.integration.sql` so its eight wrong-PIN attempts deliberately alternate caller-supplied term/session values. This verifies that a caller cannot evade the admission-only cooldown by changing the period parameters between attempts.
- Test commit: `290803b74cce2e41ac4e34fa023b7bb0e2b87ee9`.
- SchoolPro CI #39026357858 and payment-page validation #39026357837 are queued for the current head. This test is not considered passed until the SQL integration job runs and the logs confirm success.
- The cooldown's known cross-school duplicate-admission trade-off remains documented in section 32. Do not add an IP component without verified trusted-edge provenance; if the trade-off is unacceptable, redesign the public RPC/UI contract to include an explicit school identifier and scope the key to school + normalized admission.


## 31. Exact live RPC grants checked against forward migrations (2026-10-17)

- The production `public.finalize_schoolpro_payment(text,text,numeric,text,jsonb)` function is SECURITY DEFINER and currently has `EXECUTE` privilege for `service_role`, but not `anon` or `authenticated`. Its live body fails closed for the unsupported online-gateway path. The draft disable-gateway migration also revokes the remaining service-role grant; this grant difference is still outstanding and should be reconciled explicitly rather than assuming the live grants already match the draft.
- Production `public.submit_schoolpro_application(...)` currently has `EXECUTE` privilege for `anon`, `authenticated` and `service_role`. Its live definition has no contact rate limiter or Turnstile verification. A caller can bypass the existing browser-facing admission Edge Function by invoking the RPC directly until the forward migration revokes direct API grants.
- Production `public.verify_schoolpro_document(text)` is callable by `anon` and `authenticated`; it normalizes the serial and returns document status, school name and (only for issued records) student name. It is intentionally a public verifier, but without global serial uniqueness the `LIMIT 1` query is not deterministic if cross-school serial collisions are introduced. The global uniqueness migration remains necessary.
- The draft receipt Storage policy was checked against the actual `school_member_role` enum values and `private.has_school_access(uuid, school_member_role[])` helper. The live finance-read policy uses the same proprietor/administrator/accountant/bursar role set but references only `schoolpro_payment_proofs`; the draft extends it to the active `schoolpro_payment_submissions` workflow.
- The current live finance table policies include a restrictive `schoolpro_module_permission` policy and role-scoped policies for invoice, allocation, proof and submission reads/writes. The extra `anon` table ACLs are not an authorization grant to see rows while RLS has no anon policy, but they are excess privileges and are explicitly revoked by the draft migration.
- These are observed current-state facts, not proof that all draft migrations have been applied. No production grants or function definitions were changed.


## 32. Latest result-PIN period-switching regression test and CI queue (2026-10-17)

- Added a regression to `scripts/test-schoolpro-result-pin-rate-limit.integration.sql` that deliberately alternates term/session values across eight wrong-PIN attempts for the same admission. The cooldown must still count all eight against one admission-wide key; varying caller-selected period inputs must not bypass the lockout.
- Latest Stage A PR head at this checkpoint: `290803b74cce2e41ac4e34fa023b7bb0e2b87ee9`. SchoolPro CI [run #1443](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026357858) is queued; payment-page validation [run #1170](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026357837) completed successfully.
- Previous full SchoolPro CI [run #1421](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39025908106) passed all eight jobs, including the Turnstile gateway static checks, direct-RPC grant assertions, local Storage finance/guardian isolation, and concurrent payment reservation. That run predates the latest period-switching regression, so run #1443 must execute before this latest test is considered proven.
- Continue to treat admission-wide lockout as an explicit residual trade-off and production migrations as unapplied. No production change has been made.


## 38. Payment allocation write-path and latest CI status (2026-10-17)

- A read-only production catalog search for function bodies that insert into `public.schoolpro_payment_allocations` found exactly one writer: `public.submit_schoolpro_payment(...)`. Production metadata confirms it is SECURITY DEFINER, executable by authenticated users and not executable by anon. This narrows the over-allocation review to that RPC plus any privileged maintenance path outside public function bodies.
- The live submission RPC still lacks the draft receipt-object ownership/prefix checks, pending-allocation reservation and invoice `FOR UPDATE` lock identified in section 25. The draft integration now tests a valid submission, multiple negative cases and two concurrent submissions against the same invoice; the concurrent test uses a second active synthetic bank account so it is independent of the intentionally deactivated account from the earlier negative test.
- The latest PR head is `290803b74cce2e41ac4e34fa023b7bb0e2b87ee9`. Payment-page validation #39026357837 passed. SchoolPro CI #39026357858 is still queued; all eight jobs are queued, so there is no new runtime result to report yet. This is a runner/queue wait, not a pass or failure.
- Source parity at the exact head was rechecked: result-PIN migration + static test + integration test + concurrent workflow assertion all use the admission-only hash; the SQL integration alternates term/session values during wrong-PIN attempts; the receipt race uses the second active account; the static workflow assertion regex is corrected.
- Handover updated on `migration/mysql-schoolpro-foundation`; no production write, migration application, deployment or merge was performed. Keep PR #106 draft/open and do not advance to Stage B until the full current-head CI run completes and the remaining release gates are signed off.


## 33. Family report-media Storage policy — exact production expression confirmed (2026-10-17)

- The live policy `Families read their report images` is authenticated SELECT on `storage.objects` with the predicate `bucket_id = 'school-result-templates' AND private.schoolpro_family_report_media(name)`. It invokes the expensive authorization helper for every object in that bucket, including non-media workbook/template objects.
- The draft optimization migration adds a path-shape `CASE` before calling the helper, so non-media paths short-circuit to false, and adds four partial exact-path indexes for student photos, principal signatures, form-teacher signatures and result-template logos.
- Production currently has the helper and the policy but none of the four proposed indexes; the live policy has no path-shape `CASE`. The exact draft optimization is therefore **not present** despite matching policy/helper names. The production migration ledger has no exact entry for the draft version.
- Do not apply the indexes/definition until the migration drift plan is reviewed. Keep a runtime test for template listing and guardian report-image access/performance; static CI alone does not establish production query-plan improvement.

## Session continuation — 2026-10-17 (Stage A security review continuation)

### Current evidence carried forward
- Stage A PR #106 is a separate release/security workstream from MySQL migration PR #107 and remains draft/open/unmerged pending review: https://github.com/Hassan-625/IHLink-SchoolPro/pull/106.
- Latest user-provided evidence reports Stage A CI run #1365 completed with all 8 jobs passing, including local Supabase receipt Storage isolation, live cross-school database/RPC/template acceptance, typecheck, source tests, layout checks and production build. Payment-page validation #1092 also passed. These results are recorded as supplied evidence; refresh the exact run/job details before treating them as independently re-verified in this session.
- Receipt Storage isolation used disposable local Supabase users and synthetic receipts. Live production receipt-object checks were deliberately skipped because there are no safe production receipt fixtures. No production receipt objects were created and no production migration was applied.
- Prior read-only production inspection reported guardian receipt upload/download rules constrained by the authenticated user's ownership folder, and school-finance download access tied to a matching payment-proof record plus the school-finance role. The proposed repository migration still needs comparison with live bucket names, object path conventions, role model, grants, and complete policy expressions. A bucket privacy/size/MIME migration does not itself prove correct object policies.
- The local policy test proves only the draft policy behavior in that local fixture. It does not prove production policies were applied or that all production policy interactions are equivalent.

### Stage A review gates — still open
- [ ] Compare the draft receipt Storage migration with a fresh read-only production snapshot: bucket IDs/names, relevant Storage tables, current policy names and full USING/WITH CHECK expressions, role/grant assumptions, and exact guardian/payment-proof path formats. Resolve mismatches explicitly.
- [ ] Reconcile repository migration files against the live migration ledger and deployed object definitions. Distinguish absent ledger entries, remote-only changes, changed historical files, and ordering conflicts. Do not replay or rewrite historical migrations just to align counts.
- [ ] Expand policy tests for owner upload/read/list/update/delete, cross-user denial, school-finance positive access only with matching school/role/proof record, malformed paths, metadata/object-path mismatch, and unauthorized mutation. Test exact-object and folder-list operations separately.
- [ ] Test the complete payment-proof write path: direct table writes, Storage upload, submit RPC, review/approve/reject/cancel, invoice/allocation links, tenant/student ownership, duplicate submission and rollback. Use actual disposable PostgreSQL roles and the complete relevant grant/RLS set; source-text assertions alone are insufficient.
- [ ] Review trigger definitions/order against the full live schema, including payment status, receipt ownership, invoice allocation and audit history. Add disposable integration tests for relevant positive and negative transitions.
- [ ] Finish Stage A acceptance/security review and record each test's environment, actor role, assertion, result and commit. Keep Stage A blocked until these gates pass and the owner explicitly approves merge.

### Safety and workstream separation
- Production remains unchanged: no production migration, receipt upload, production write probe, Render deployment, environment edit, or PR merge was performed as part of this handover update.
- Do not introduce an unverified IP-based database security mechanism. Trusted-edge rate limiting must rely on verified gateway semantics, not caller-controlled forwarding headers.
- Keep PR #106 (Stage A application/security work) separate from PR #107 (MySQL migration foundation). A green workflow for one branch does not certify the other.
- Preserve the full SchoolPro release sequence A → B → C → D and E–J roadmap. Do not resume D until A/B/C are re-verified and accepted.
- Next: inspect current Stage A migration, policy/test files and latest run/job logs on the exact branch head; perform read-only production/source reconciliation; add missing disposable runtime tests; then update this handover with exact paths, commit SHAs, run IDs and findings before changing merge readiness.



## 34. Payment RLS review found direct pending-row and legacy-proof receipt-path bypasses (2026-10-17)

- A closer comparison of the live permissive and restrictive policies found a second issue beyond the missing RPC guard. The draft `20261016143000_schoolpro_payment_review_write_controls.sql` previously allowed a guardian to insert a `pending` row directly into `schoolpro_payment_submissions` with an arbitrary receipt path, bypassing the ownership/Storage-object validation in `submit_schoolpro_payment`. The migration now drops the direct guardian-submission policy and revokes authenticated INSERT privilege on `schoolpro_payment_submissions`; the SECURITY DEFINER RPC remains the intended guardian submission path.
- The legacy `guardian submits proof` policy on `schoolpro_payment_proofs` previously checked the guardian link and submitter identity but did not check receipt object ownership. The draft now requires the receipt path's first segment to match `auth.uid()` and an object in `schoolpro-payment-receipts` owned by that user, in addition to the active guardian/student/school link.
- Extended the disposable payment-review RLS fixture to model `storage.objects` ownership, assert authenticated direct submission INSERT is revoked, reject a pending fake-path submission, and reject attaching another account's receipt path to a legacy proof row. Existing guardian/finance/Super Admin read/write assertions remain.
- Draft changes: migration commit `876916c9ba26c7f778c813186cdae5ae9e9718be`; integration test commit `7c087a8784464a626e8f5d348245f86ea5709168`.
- Latest SchoolPro CI run [#1450](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026655882) and payment-page validation [#1177](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026656033) were queued at the time of writing. Do not count the new direct-insert/path-denial assertions as passed until run #1450 finishes and the `payment-review-rls-integration` job is inspected.
- No production policies, grants, rows, Storage objects, secrets or deployments were changed. This forward migration remains part of the unresolved source/ledger drift and is not authorized for standalone application.


## 35. Payment RLS integration failure triage — fixture policy name corrected (2026-10-17)

- SchoolPro CI run [#1450](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026655882) exposed a test-fixture mismatch: the fixture called the legacy proof INSERT policy `guardian_own_insert_proofs`, while production and the migration use `guardian submits proof`. Consequently, the migration's `DROP POLICY` did not replace the fixture's permissive policy, and the synthetic foreign-receipt-path insert was incorrectly allowed by the test setup.
- Corrected the fixture policy name to match production exactly in commit `26f013bd0d7589c24606d5abe930b2f0e773220c`. The failure is a fixture fidelity issue, not a reason to relax the receipt-owner assertion. The next CI run must prove the foreign-path insert is rejected under the correctly replaced policy.
- Other completed jobs in run #1450 passed: tenant acceptance, tenant-integrity/RPC concurrency, result-verification exposure, and public-admission abuse controls. Local Storage isolation, result-PIN integration and general validation were still running at the last check; do not infer their outcomes from this partial status.


## 36. Read-only production reconciliation — receipt Storage and payment controls (2026-10-17)

**Status: Stage A remains BLOCKED. This is a production catalog/source comparison only; no production writes, migration applications, receipt uploads, deployments or merges were performed.** Production target was verified as active Supabase project `lnqsroyiybutkfngbyge` (IHLink Platform). PR #106 head inspected: `26f013bd0d7589c24606d5abe930b2f0e773220c`; PR #106 is open, draft and unmerged.

### Receipt bucket and Storage policies — live catalog evidence

Read-only queries against `storage.buckets` and `pg_policies` returned:

- Bucket `schoolpro-payment-receipts` is private (`public=false`), with a 5,242,880-byte file limit and MIME allowlist `image/jpeg`, `image/png`, `image/webp`, `application/pdf`. These values match `supabase/migrations/20261017150000_schoolpro_payment_receipt_storage_policies.sql`.
- Live policy `guardian upload payment receipts`: PERMISSIVE INSERT to `authenticated`; bucket must match and first `storage.foldername(name)` segment must equal `auth.uid()`.
- Live policy `guardian read own payment receipts`: PERMISSIVE SELECT with the same bucket and first-folder ownership restriction.
- Live policy `school finance read payment receipts`: PERMISSIVE SELECT currently checks only a matching `schoolpro_payment_proofs.receipt_path` plus `private.has_school_access(...)` for proprietor/administrator/accountant/bursar.
- Draft migration SHA `1580d24656df0fb8b407dcb4e094ad61aadc54e0` adds a second finance-read branch through `schoolpro_payment_submissions.receipt_path`. That branch is **absent from the current live policy expression**. The deployed policy therefore differs from the draft; do not claim migration parity. This difference may cause legitimate submission-receipt access to depend on another path/role and must be verified against the UI/RPC workflow before applying any forward migration.
- The local Storage fixture `scripts/receipt-storage-local/fixture.sql` models a reduced test membership table and minimal payment proof/submission tables; it is not the complete production schema or complete policy/grant inventory. The local Storage test proves disposable-user object isolation for the configured fixture only, not production object-level acceptance.
- No valid, safe production receipt-object fixture was configured, so production receipt download/upload isolation remains deliberately untested. Do not create production dummy receipts.

### Migration ledger versus source

- Read-only query of `supabase_migrations.schema_migrations` found the newest production ledger entry among the inspected recent window was `20261015161735 / schoolpro_access_invitation_role_constraint`. No migration with a later 2026-10-16/17 timestamp from the current Stage A branch appears in the production ledger.
- This means the Stage A migrations below are repository proposals, not deployed changes; the absence is not by itself corruption and must not be “fixed” by replaying historical migrations:
  - `20261015203000_schoolpro_payment_receipt_tenant_guard.sql`
  - `20261016143000_schoolpro_payment_review_write_controls.sql`
  - `20261016170000_schoolpro_disable_online_payment_gateway.sql`
  - `20261016180000_schoolpro_payment_receipt_storage_limits.sql`
  - `20261017150000_schoolpro_payment_receipt_storage_policies.sql`
  - and other later Stage A migrations visible in PR #106.
- Next reconciliation must compare all repository migration filenames/versions to the complete production ledger and then compare deployed definitions for every discrepancy. Do not mark a migration “applied” or manually insert ledger rows without evidence of its exact effects.

### Actual production payment table grants, RLS and RPCs

Read-only catalog inspection found:

- RLS is enabled on `schoolpro_payment_submissions`, `schoolpro_payment_allocations`, `schoolpro_payment_proofs`, `schoolpro_fee_payments` and `schoolpro_invoices`; `FORCE ROW LEVEL SECURITY` is false and the owner is `postgres`.
- `anon`, `authenticated` and `service_role` each currently have broad table privileges (SELECT/INSERT/UPDATE/DELETE plus other table privileges) on the four payment tables inspected. RLS therefore remains critical, and the draft's forward revocation of `PUBLIC, anon` is not yet live. This audit did not attempt direct writes using production roles.
- Live restrictive policy `schoolpro_module_permission` on submissions, allocations, proofs and fee payments uses `private.schoolpro_module_allowed(school_id,'finance')` in its effective predicates. Live permissive policies also exist, so the result is the intersection of the restrictive policy and applicable permissive policies, plus SQL grants. The draft test fixture must reproduce the relevant production policy set accurately.
- Production `submit_schoolpro_payment(uuid,uuid,numeric,date,text,text,text,text,jsonb)` is SECURITY DEFINER, owned by `postgres`, with an empty search path; EXECUTE is granted to `authenticated` and `service_role`, not `anon` or PUBLIC. The deployed function definition is still the older implementation: it checks active guardian linkage, bank account, invoice/student linkage and allocation totals, but does **not** check that `p_receipt_path` exists in `storage.objects` and belongs to `auth.uid()`, does not reject duplicate invoice IDs, and does not lock invoice rows while checking/reserving pending balances. The forward migration `20261015203000...` adds these guards, but is not in the production ledger and its definition is not the deployed definition. Treat this as a high-priority live/source mismatch; do not describe the receipt-owner guard as production-enforced.
- Production `review_schoolpro_payment_submission` and `review_schoolpro_payment_proof` are SECURITY DEFINER functions with empty search paths and EXECUTE granted to `authenticated` and `service_role`. The submission-review RPC locks the submission, checks finance-module access and an approved school role, accepts only `confirmed` or `rejected`, rejects non-pending submissions, locks invoice rows and writes fee payments/invoice balances within one transaction. These are useful transition guards, but no real-role disposable test has yet proven the full grant/RLS/function/trigger interaction.
- No function named `cancel_schoolpro_payment_submission` or `cancel_schoolpro_payment` was found in the queried public function names. Cancellation semantics must be defined and tested against actual product workflow rather than assumed. The current review RPC decision set is confirm/reject, not cancel.
- Trigger catalog shows `schoolpro_activation_before_write` on submissions, allocations, proofs, fee payments and invoices, plus the fee-payment transactional-email trigger and invoice notification/active-pupil triggers. Full trigger order and rollback behavior have not yet been runtime-tested with the complete schema.

### Test-fidelity gaps and blockers

- `scripts/test-schoolpro-payment-review-rls.integration.sql` is a disposable fixture, not a full production schema restore. Its simulated permissive policies include direct finance UPDATE policies on submissions, allocations and proofs; the script then directly updates submission status, allocation amount and proof receipt path as finance. That contradicts its own stated design intent that review-controlled mutations occur through the locked RPC. The test must be corrected to assert intended direct-write denial (or the product owner must explicitly define which finance fields may be edited directly); it must not silently pass by exercising broad direct updates.
- The same fixture uses test-only `private.schoolpro_module_allowed` and `private.is_admin` implementations, so it cannot by itself prove the production role mapping. Use disposable PostgreSQL with the actual relevant DDL/policies/grants/functions and explicit JWT claim setup; no production role impersonation or mutation.
- Existing `scripts/test-schoolpro-payment-receipt-rpc.integration.sql` executes the proposed receipt RPC migration against synthetic minimal tables and covers valid submission plus receipt owner, guardian/student, duplicate invoice, total mismatch, pending reservation and inactive-bank cases. It does not prove those guards are deployed to production, nor does its current scope test review/reject/cancel, real grants, trigger rollback or concurrent duplicate review end-to-end.
- Need runtime tests for: (1) guardian direct INSERT/UPDATE/DELETE denial on protected submission/proof/allocation fields; (2) authorized RPC submission and cross-tenant denial; (3) finance review/reject through RPC and direct mutation denial; (4) Super Admin read-only; (5) fee-payment legitimate insert; (6) cancellation behavior if supported; (7) two-session duplicate submission/review and invoice allocation race; (8) trigger side effects rolled back on failure; and (9) exact object path/ownership across guardian, same-school finance and foreign-school finance.
- Do not introduce caller-controlled `X-Forwarded-For` / forwarded-IP trust as a database security primitive. Trusted-edge controls remain gated on verified gateway semantics.

### Acceptance decision and next actions

1. **Do not merge PR #106.** Green CI does not close the production/source mismatch or the real-role runtime gaps.
2. Build a disposable PostgreSQL fixture that reproduces the relevant production schema, table grants, all applicable permissive/restrictive policies, SECURITY DEFINER functions and triggers. Correct the existing fixture's direct-finance-write expectations first.
3. Reconcile the complete repository migration inventory against the production ledger and deployed catalog. Separate expected unapplied draft migrations from genuine source/ledger drift; do not replay history or write the production ledger.
4. Verify and test the draft Storage policy's submission-based finance branch, exact object-path semantics and role enum/access helper against the actual schema. Do not apply the migration to production as part of this audit.
5. Run and inspect the resulting CI jobs on the exact updated PR #106 head, then append exact commit/run/job evidence here.
6. Stage A remains BLOCKED until these gates pass and the owner explicitly approves merge. No production writes, migration applications, receipt object creation, deployment or merge occurred during this session. Preserve A→B→C→D and E–J; do not resume D until A/B/C are re-verified and accepted.


## 36. Stage A CI run #1453 passed; valid legacy-proof path added as a final positive control (2026-10-17)

- SchoolPro CI [run #1453](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026729616) completed successfully on head `26f013bd0d7589c24606d5abe930b2f0e773220c`; payment-page validation [run #1180](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026729614) also passed.
- All eight SchoolPro jobs passed, including the corrected payment-review RLS test, local Supabase Storage isolation, admission-wide PIN cooldown, result snapshot minimization, live tenant acceptance, tenant-integrity RPC/concurrency tests, public admission abuse controls, and general typecheck/static/build validation.
- After that pass, added one final positive assertion to the payment-review RLS fixture: a guardian with an active school/student link can still insert a legacy proof row when the receipt object is actually owned by that guardian. The test removes its synthetic row before subsequent assertions. Commit `c29de6c35f04dca737d5bb9c13a16252b0d476ca`.
- Latest SchoolPro CI [run #1456](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026915662) and payment-page validation [run #1183](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026915641) were in progress when recorded. Require #1456 to pass before considering the new positive proof-path assertion validated.
- These are draft/isolated test results. The production receipt RPC ownership/locking guard, direct public RPC restrictions, Storage finance-read update, payment-review policy changes and other missing source/ledger migrations remain unapplied. Stage A is not merge-ready until migration reconciliation, the latest run, and user release approval are complete.


## 37. Corrected payment RLS fixture policy fidelity — awaiting exact-head CI (2026-10-17)

- After comparing the integration fixture with the live `pg_policies` catalog, found that the fixture had invented permissive direct UPDATE/DELETE policies for finance on submissions, allocations, proofs and fee payments. Those broad policies were not present in the live policy inventory and made the fixture permit direct finance mutation of review status, allocation amount and receipt path.
- Corrected `scripts/test-schoolpro-payment-review-rls.integration.sql` on PR #106 to remove those invented UPDATE/DELETE policies, use production policy names and core predicates for submitter/finance reads, guardian proof submission, finance fee-payment INSERT and Super Admin fee-payment access, and use a disposable membership table for `private.has_school_access`. Added explicit assertions that finance cannot directly change submission review status, allocation amount, proof receipt path or fee-payment ledger amount, nor delete a ledger row; the intended school-finance INSERT remains tested.
- Test fixture update commit: `31d5d0665145ff34d990b44d7b31892466377c98`.
- PR #106 now points at that exact head and remains draft/open/unmerged. At the last read, the commit combined status reported a pending `Vercel` check; the GitHub Actions workflow-run listing had not yet returned runs for the new SHA. **No CI pass is claimed for this fixture correction yet.** Inspect the next exact-head SchoolPro CI run, especially `payment-review-rls-integration`, and correct any runtime failures rather than loosening the assertions.
- Scope limit: this is a better disposable fixture with production policy names/core predicates and broad grants, not a full production schema restore. It does not establish runtime behavior of the live SECURITY DEFINER review RPCs, trigger order, rollback, cancellation or concurrent submissions. Those remain acceptance blockers.
- The read-only production/source findings in section 36 remain in force: the live receipt submission RPC lacks the receipt object ownership check and deterministic invoice locking present in the draft forward migration; recent Stage A migrations are not present in the inspected production ledger; live table grants remain broad; and the Storage finance policy currently references proofs but not submissions.
- No production mutation, migration application, storage upload, Render deployment or merge occurred. Stage A remains blocked.


## 37. Final proof-positive test syntax correction (2026-10-17)

- SchoolPro CI [run #1456](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026915662) exposed malformed dollar-quoted SQL in the expanded payment-review fixture. The issue came from a replacement that reduced PostgreSQL `$$...$` delimiters to single-dollar delimiters; the payment-review integration job failed before validating the positive proof case.
- Restored all six affected `assert_no_rows_affected` statement delimiters in commit `f8355758d6a94a467b28f600d8c160a649743e20`. The latest SchoolPro CI [run #1461](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027022726) is queued; it must pass the payment-review RLS job and the full suite before this correction is considered complete.
- Run #1456's other jobs were not a basis for claiming full success because payment-review failed. No production changes were made.


## 38. Exact-head PostgreSQL fixture triage and production path-count check (2026-10-17)

- Read-only aggregate integrity query against production found **zero** rows in `schoolpro_payment_submissions`, `schoolpro_payment_proofs` and `schoolpro_payment_allocations` at query time. Therefore production currently provides no existing receipt/payment rows suitable for safely exercising object-path ownership or payment transition behavior. No production fixture was created.
- `storage.objects` has RLS enabled (owner `supabase_storage_admin`, FORCE RLS false). Catalog grants show `anon` and `authenticated` have SELECT/INSERT/UPDATE/DELETE privileges and `service_role` has broader table privileges; the three receipt policies are therefore material to actual access. No production Storage object was changed.
- Read-only `private.has_school_access(uuid, school_member_role[])` definition confirms that it checks active profiles and allows school ownership, an explicitly assigned school member role, **or platform Super Admin via `private.is_admin()`**. Thus the role-array argument in the finance receipt policy is not the only path to authorization: Super Admin bypass is part of the helper's effective semantics and should be stated explicitly in the policy tests/documentation.
- Disposable RLS fixture runs exposed setup defects in the new test itself rather than evidence of a production behavior change:
  - SchoolPro CI run [#1459](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39026983581) failed the `payment-review-rls-integration` job because dollar-quote delimiters were emitted incorrectly in the fixture.
  - SchoolPro CI run [#1463](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027087463) progressed further and then failed because `private.schoolpro_owns_invoice_student` was declared before its referenced fixture table existed; its helper body also retained one malformed dollar quote.
  - Corrected dependency ordering and SQL delimiters in follow-up commits; current PR #106 head at this note is `cca3ada552bdcc86919a4da95f396e75e3d42258`. The exact-head CI for this commit must be inspected before treating the fixture as executable or passing. No test failure was hidden or marked successful.
- This reinforces that the payment RLS fixture is still under construction. Do not claim direct-write denial, authorized RPC behavior, cancellation, trigger rollback or duplicate-review concurrency as proven until the corrected exact-head disposable PostgreSQL tests actually pass and cover those assertions.


## 39. Payment RLS fixture reached role assertions; count corrected (2026-10-17)

- On SchoolPro CI run [#1466](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027225164), the payment-review integration fixture successfully progressed through setup, role switching, guardian isolation checks, finance direct-write denials, and the authorized finance fee-payment INSERT. It then failed at the Super Admin fee-payment visibility count because the fixture correctly contained three fee-payment rows after the authorized INSERT while the assertion still expected two.
- This is a test expectation error, not a production behavior finding. Corrected the assertion to expect three rows in commit `87ecedd9fabb51a8d7e522ae9038b176091600a0`. The exact-head SchoolPro CI/payment validation for this commit is still required; no pass is claimed yet.
- The failed run is retained as evidence and was not reclassified as a pass. Continue to inspect the exact `payment-review-rls-integration` logs; once this count is corrected, any next failure must be diagnosed from the SQL/runtime evidence rather than weakening the security assertions.


## 40. Payment RLS fixture passes after policy-fidelity corrections (2026-10-17)

- SchoolPro CI [run #1468](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027293191), exact tested Stage A commit `87ecedd9fabb51a8d7e522ae9038b176091600a0`, reports `payment-review-rls-integration` **success**. The disposable PostgreSQL 16 job now exercises the migration against broad grants and the fixture's production-named/core policy predicates.
- Passing assertions include guardian read isolation; guardian direct submission insert denial after the RPC-only boundary; rejection of another account's receipt path for legacy proof insertion; guardian direct update/delete denial; finance read scope; finance direct update denial for submission review status, allocation amount, proof receipt path and fee-payment amount; finance direct fee-ledger delete denial; authorized finance fee-payment INSERT; and Super Admin read-only behavior.
- Other completed jobs in run #1468 at the last poll: `tenant-integrity-db-integration`, `result-pin-rate-limit-integration`, `tenant-acceptance`, `public-admission-abuse-integration` and `result-verification-exposure-integration` passed. `validate` and local Supabase receipt Storage isolation were still running at that poll; no whole-workflow green claim is made until they finish.
- This is meaningful disposable PostgreSQL evidence, but it is **not** a production write test or a full schema restore. The fixture does not yet execute the actual deployed `review_schoolpro_payment_submission` / `review_schoolpro_payment_proof` SECURITY DEFINER functions under production grants and triggers, and does not test reject/confirm rollback or cancellation end-to-end. Those remain separate blockers.
- Production aggregate queries returned zero rows for payment submissions, proofs and allocations at audit time, so there were no existing receipt rows to safely sample for object-path ownership. The live RPC/source mismatch and missing newer migrations from the production ledger described in section 36 remain unresolved.
- No production changes, migration applications, receipt uploads, deployments or merges occurred. PR #106 remains draft and not merge-ready.


## 41. Exact-head Stage A CI completed after RLS fixture correction (2026-10-17)

- **SchoolPro CI #1468 completed successfully on exact PR #106 head `87ecedd9fabb51a8d7e522ae9038b176091600a0`**: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027293191. All eight jobs passed: `validate`, `payment-review-rls-integration`, local Supabase receipt Storage isolation, tenant-integrity DB integration, result-PIN rate-limit integration, tenant acceptance, public-admission abuse integration and result-verification exposure integration.
- **Payment-page validation #1195 passed** on the same tested head: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027293135.
- This resolves the immediate test-fixture syntax/dependency/count failures and confirms the reduced disposable payment RLS fixture plus local Supabase Storage isolation job execute successfully. It does **not** resolve the live/source mismatch or convert the reduced fixture into a full production schema restore.
- Acceptance is still **BLOCKED** by the live submission RPC lacking receipt-object ownership and deterministic invoice reservation locks, the draft-vs-live Storage policy difference, broad live financial-table grants, absence of end-to-end actual review RPC/trigger/rollback/cancellation/concurrency tests, and incomplete full migration-source/ledger reconciliation.
- No production migration, row write, receipt upload, deployment or merge occurred. PR #106 remains draft/open/unmerged. The green CI is evidence for the tested disposable harness and source suite, not evidence that the proposed migrations are deployed or that production acceptance is complete.


## 42. Disposable review RPC behavioral coverage added; final rollback assertion under revalidation (2026-10-17)

- Extended `scripts/test-schoolpro-payment-review-rls.integration.sql` to execute a test-only snapshot of the currently deployed `review_schoolpro_payment_submission` function under a distinct `authenticated` role and the disposable finance membership/module gate.
- Added behavioral assertions for: guardian cannot invoke review; `confirmed` and `rejected` are the only accepted review decisions; a `cancelled` decision is rejected (no dedicated cancellation RPC was found in the live public function inventory); rejection transitions only pending submissions; confirmation creates a fee-payment row, updates invoice paid amount/status, links the allocation and confirms the submission; duplicate review is rejected; and a synthetic failing invoice trigger must roll back earlier fee-payment insertion plus all later state changes.
- The review RPC snapshot/test extension passed the disposable PostgreSQL job in SchoolPro CI [run #1474](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027699543) at tested commit `ce293c80b4f5ee18937018e0b17878ea1750b577`. That version's failure trigger was earlier in the write sequence. Improved it in follow-up commit `d3f99f344d2d3fcfb4813bcafb36a5436864c35f` to raise during invoice UPDATE after the fee-payment INSERT, so rollback covers an already attempted ledger write. Exact-head SchoolPro CI [run #1475](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027734477) is in progress at the last poll; do not mark the stronger rollback assertion passed until its `payment-review-rls-integration` job succeeds.
- Evidence boundary: the fixture uses a snapshot of the deployed review function with reduced disposable tables, production-named/core policies and broad grants. The synthetic trigger validates PostgreSQL transaction rollback, but it does not recreate the actual production activation/email/notification triggers or prove their complete trigger-order interactions. Full production-schema trigger replay and two-session duplicate-review concurrency remain open.
- The live source/ledger mismatch, draft-vs-live Storage policy difference, broad live table grants and missing receipt-object fixtures described above remain blockers. No production writes, migration applications, receipt uploads, deployments or merges occurred.


## 43. Stronger review rollback assertion passed; overall run still active (2026-10-17)

- The strengthened `payment-review-rls-integration` job in SchoolPro CI [run #1475](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39027734477), tested PR #106 commit `d3f99f344d2d3fcfb4813bcafb36a5436864c35f`, has completed **successfully**.
- This run's disposable test now forces an invoice-update trigger to fail after the review RPC has attempted the fee-payment INSERT. Assertions verify the submission remains pending, invoice amount/status remain unchanged, allocation remains unlinked, and the attempted fee-payment row is rolled back. The same job covers authorized confirm/reject, duplicate-review rejection, guardian review denial, direct table-write denial, and that cancellation is rejected as an unsupported review decision.
- The test's invoice trigger is synthetic and the RPC is a test snapshot of the currently deployed definition. This is stronger transaction-behavior evidence, but it does not prove actual production activation/email/notification trigger ordering or concurrent review behavior under a full production schema.
- At the last poll, the other jobs in run #1475 and payment-page validation #1202 were still running. Wait for the exact-head run to complete before recording overall CI status.
- Acceptance remains blocked by the live submission RPC's missing receipt object owner check/invoice reservation locks, draft-vs-live Storage finance policy difference, broad deployed financial-table grants, incomplete full migration-source/ledger/catalog reconciliation, and lack of two-session review concurrency tests. No production changes or merge occurred.


## 44. Production catalog reconciliation, receipt-path fix and trigger/concurrency harness (2026-10-17)

### Migration-source vs production-ledger classification

Read-only query of `supabase_migrations.schema_migrations` confirms the latest production ledger row remains `20261015161735 / schoolpro_access_invitation_role_constraint`. The following Stage A source files are present in PR #106 but their exact version/name pairs are **not in the production ledger**:

- `20261015203000_schoolpro_payment_receipt_tenant_guard.sql`
- `20261016110500_schoolpro_optimize_family_report_media_storage_policy.sql`
- `20261016122000_schoolpro_result_pin_attempt_rate_limit.sql`
- `20261016143000_schoolpro_payment_review_write_controls.sql`
- `20261016160000_schoolpro_repair_operational_tenant_integrity.sql`
- `20261016170000_schoolpro_disable_online_payment_gateway.sql`
- `20261016180000_schoolpro_payment_receipt_storage_limits.sql`
- `20261017103000_schoolpro_document_serial_global_uniqueness.sql`
- `20261017120000_schoolpro_result_verification_minimal_snapshot.sql`
- `20261017133000_schoolpro_public_admission_rpc_abuse_controls.sql`
- `20261017150000_schoolpro_payment_receipt_storage_policies.sql`

These are **expected unapplied proposals on an open, unmerged PR**, not evidence that production should have them. The corresponding production definitions are still the pre-proposal definitions in the areas directly compared below. Do not apply these migrations or alter the ledger during this audit. Older source/ledger name mismatches noted in the Stage A release gate are a separate historical reconciliation task: where later ledger entries appear to implement similar behavior, classify as possible supersession only after comparing function/policy/trigger definitions and constraints, never by name alone.

### Exact deployed receipt bucket and policy semantics

- Bucket `schoolpro-payment-receipts` is private, has a 5,242,880-byte limit (5 MiB), and allows JPEG, PNG, WebP and PDF. This matches the draft bucket settings.
- The live `storage.objects` policies are: authenticated guardian INSERT when the first path folder equals `auth.uid()`; authenticated guardian SELECT with the same folder check; and finance SELECT only where the exact object name matches a `schoolpro_payment_proofs.receipt_path` and `private.has_school_access(... proprietor/administrator/accountant/bursar ...)` succeeds.
- The live finance policy does **not** include `schoolpro_payment_submissions`; the draft does. The draft was tightened in commit `6c603ba37ecf5ae1df6947ddd7081b8237c14acf` to require both first-folder = recorded `submitted_by` and `coalesce(objects.owner_id, objects.owner::text)` = `submitted_by` for both proof and submission branches. This blocks a finance-readable row from pointing at another user's receipt object.
- Effective role semantics matter: `private.has_school_access(uuid, school_member_role[])` requires an active profile and allows a school owner, an assigned member with an allowed role, **or an active platform Super Admin via `private.is_admin()`**. The Super Admin bypass is intentional platform-wide read/inspection behavior and must remain explicit in tests; the role array alone does not exclude Super Admin.
- The local Supabase fixture now models active profiles, finance memberships, school ownership and Super Admin helper bypass, and inserts proof as well as submission links. An initial run on older commit `8366ecbcae2b7f7ba58d60359e1c4ff6f9f9946c` failed because the fixture had not yet gained the `submitted_by` proof column. The updated fixture and policy changes are under revalidation in CI #1485; do not claim the revised Storage tests passed until that exact run finishes.

### Deployed payment trigger chain observed in catalog

Read-only `pg_trigger` / `pg_get_triggerdef` inspection found these enabled triggers:

- `schoolpro_payment_submissions`, `schoolpro_payment_allocations`, `schoolpro_payment_proofs`, `schoolpro_fee_payments`, and `schoolpro_invoices`: BEFORE INSERT/UPDATE/DELETE `schoolpro_activation_before_write` → `private.guard_schoolpro_operational_write()`.
- `schoolpro_invoices`: BEFORE INSERT/UPDATE `schoolpro_active_pupil_activity` → `private.schoolpro_reject_new_inactive_student_activity()`; AFTER INSERT `trg_schoolpro_invoice_notify` → `private.notify_school_staff()`.
- `schoolpro_fee_payments`: AFTER INSERT `trg_schoolpro_payment_email` → `public.queue_schoolpro_transactional_email()`.

The payment-review test fixture now snapshots the relevant production trigger function bodies and uses minimal disposable dependency tables/stubs. Its rollback assertion checks that a synthetic invoice-trigger failure after the fee-payment INSERT rolls back the fee-payment row, invoice balance/status, allocation payment link, submission status, and transactional-email queue side effect. This is deliberately **not described as a full production schema clone**: the activation-state helper is stubbed to active, and notification/email integrations are represented by local tables. The full exact-head CI result is pending at the time of this note.

### Cancellation support

The deployed `review_schoolpro_payment_submission(uuid,text,text)` and `review_schoolpro_payment_proof(uuid,text,text)` functions accept only `confirmed` and `rejected`. The live function catalog has no payment-cancellation/reversal RPC by name. Therefore **cancellation is not a supported submission-review transition in the deployed database contract**; the integration test correctly expects `cancelled` to be rejected. Do not implement cancellation as an alias for rejection or mutate confirmed fee-ledger rows. If cancellation is a product requirement, it needs a separate audited state machine/RPC and accounting reversal design.

### Two-session duplicate-review race

- Added a third pending submission plus a deterministic test-only delay trigger to the disposable payment-review fixture.
- Added a CI step that launches two separate PostgreSQL connections reviewing the same submission concurrently, then asserts exactly one call confirms, the other is rejected as already reviewed, and only one fee-payment row/allocation link is produced.
- The new Storage policy fixture, actual-trigger snapshots and two-session review race are included in Stage A head `ae189d47389047337e2681fccb9dd5bdf03fdb7c` / preceding test changes; SchoolPro CI #1485 is running at this note. Record its exact final status in a follow-up handover section before making a release decision.

No production DDL/DML, receipt upload, deployment, migration replay or merge occurred.


## 45. Exact-head CI results for receipt-path and concurrent review tests (2026-10-17)

- SchoolPro CI [#1487](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39028618496) completed with all **8/8 jobs successful** on tested commit `e21d52b43e24724384bbbd94587d318755680502`: general validation/build, local Supabase receipt Storage isolation, payment-review RLS, tenant-integrity DB integration, result-PIN rate-limit integration, tenant acceptance, public-admission abuse controls and result-verification exposure.
- Payment-page validation [#1214](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39028618404) passed on that same tested commit.
- Payment-review job step results include both `Exercise payment-review RLS using authenticated role switching` and `Exercise two-session duplicate payment review concurrency` = success. Two independent PostgreSQL sessions produced one successful confirmation and one `Already reviewed` rejection, with exactly one fee-payment row and one allocation link.
- Local Supabase Storage isolation passed after the fixture was corrected to include `submitted_by`, active profiles, school ownership and the Super Admin helper bypass. The runtime test verifies guardian own-folder upload/download, cross-user upload/download denial, finance access to own-school proof/submission receipt paths, denial for another school's receipt, and active Super Admin read access to both.
- The same run passed the trigger-snapshot rollback assertions: attempted fee-payment and email-queue writes, invoice balance/status, allocation link and submission status are rolled back when a later invoice trigger raises. The trigger function bodies are snapshots with minimal dependency stubs, not a full restore of production's activation/subscription and notification integrations.
- Follow-up commit `499fe19aa476723f1e6a3d151e71eedc13e12ea4` adds a direct negative assertion that the production activation-guard function rejects a review transition when the school is inactive. Its exact-head SchoolPro CI #1488 and payment validation #1215 are in progress at the time of this update; do not transfer the #1487 pass to this newer head.

### Acceptance decision after run #1487

CI on `e21d52b` passes the disposable runtime assertions, including Storage policy behavior and concurrent review. Stage A is nevertheless **NOT MERGE-READY** until run #1488 validates the additional activation-guard test and remaining full-schema/source-history caveats are either closed or explicitly accepted. The migration source/ledger comparison for Stage A is complete: the eleven listed 2026-10-15 20:30 through 2026-10-17 files are unapplied PR proposals, while older historical filename mismatches remain possible supersession cases requiring object-level equivalence review. No production migration, DML, receipt upload, deployment or merge occurred.


## 46. Latest exact-head acceptance and historical source/ledger comparison (2026-10-17)

### Exact-head results

- SchoolPro CI [#1488](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39028829240) completed all functional jobs successfully on tested commit `499fe19aa476723f1e6a3d151e71eedc13e12ea4`: validation/build, local Supabase receipt Storage isolation, payment-review RLS plus two-session review concurrency, tenant-integrity DB integration, result-PIN rate-limit integration, tenant acceptance, public-admission abuse controls and result-verification exposure.
- Payment-page validation [#1215](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39028829224) passed on the same head.
- The payment-review integration now also tests that the actual activation-guard function body rejects a review transition when the test school is inactive; that test passed. The active-state helper is deliberately stubbed via a session setting, while the production guard body is the copied live definition. This is not a live production write.
- The local Storage job passed with uploader-owned object-path checks on both proof and submission branches, cross-school finance denial, own-school finance access, guardian folder isolation, and active Super Admin helper bypass.

### Older repository migration name mismatches

Read-only comparison of the three historical source files with current production catalog definitions gives the following classification; none should be replayed simply to match names:

1. `20261003000500_schoolpro_guardian_tenant_hardening.sql` is not an exact ledger entry. Its same-school guardian/student relation intent is currently enforced by live `private.schoolpro_guardian_school_scope()` trigger on `schoolpro_guardian_links`; current guardian policies also use active links and the invoice/payment ownership helper. This is evidence of later/alternate implementation, not proof that the old migration itself ran.
2. `20261003002000_schoolpro_cbt_permission_tenant_integrity.sql` is not an exact ledger entry. Current live triggers use `private.enforce_schoolpro_tenant_relations()` on CBT question relations and eligibility, `private.validate_schoolpro_cbt_eligibility()`, and `private.validate_candidate_cbt_tenant()` for candidate application/test school matching. Their deployed function bodies cover the central same-school invariants in the historical source migration under different names.
3. `20261002234500_schoolpro_operational_tenant_isolation.sql` is not an exact ledger entry. Its current target tables have RLS enabled, but **FORCE ROW LEVEL SECURITY is false** and the exact trigger function `private.schoolpro_validate_operational_tenant()` is absent from the inspected catalog. Existing activation/workflow triggers and current policies provide some protection, but are not proven equivalent to that migration's policy replacement and FORCE-RLS posture. This is a genuine enforcement-posture difference that requires an explicit design decision and tests, not blind replay of a migration that drops and recreates policies.

### Final Stage A decision

The Stage A proposal set is reconciled against the production ledger and deployed definitions; unapplied PR migrations are classified as expected pending changes, not ledger corruption. Historical filename mismatches are now classified into two likely superseded cases (guardian and CBT relation guards) and one unresolved operational-RLS posture difference. Do not replay historical migrations or hand-edit the ledger. If Stage A is to ship, explicitly review the operational RLS/FORCE-RLS gap and the pending repair migration as a forward-only change with role/owner-trigger tests.

**Stage A remains NOT MERGE-READY.** The exact-head CI is green, but CI success is not equivalent to production migration acceptance. Outstanding release decision: approve a safe forward-only operational tenant integrity repair and verify its full schema/trigger interactions; confirm migration history/provenance for the historical operational isolation migration; and keep all production changes behind explicit approval. No production migration, DML, receipt upload, deployment or merge occurred.


## Stage A operational tenant-isolation forward repair — 2026-10-17

**Current Stage A candidate:** `release/stage-a-auth-tenant-isolation`, head `2ace61eafd070b3618d9f57ceaf3fdac606edd8e`. PR #106 remains draft/open/unmerged while exact-head CI runs. Production has not been modified.

### Production facts rechecked read-only

- The eight historical operational tables (`schoolpro_library_books`, `schoolpro_transport_routes`, `schoolpro_hostel_rooms`, `schoolpro_inventory_assets`, `schoolpro_calendar_events`, `schoolpro_lesson_notes`, `schoolpro_result_approvals`, `schoolpro_promotions`) have RLS enabled but `relforcerowsecurity=false`.
- Live policy catalog is not equivalent to the old `20261002234500_schoolpro_operational_tenant_isolation.sql` policy set. Current feature-specific policies include family borrowed-book read access, calendar member read access, author/leadership lesson-note paths, and separate result-approval/promotion policies. The historical migration drops all policies on these tables before replacing them, so replaying it would risk removing live feature semantics. **Do not replay it.**
- Production table owner is `postgres`. FORCE RLS is defense-in-depth for non-BYPASSRLS owners; it does not constrain superusers or BYPASSRLS roles such as the service role. Authenticated clients must continue to use scoped policies and must never receive service-role credentials.
- The separate forward-only relational repair `20261016160000_schoolpro_repair_operational_tenant_integrity.sql` already adds fixed-search-path SECURITY DEFINER trigger functions, cross-school reference checks for lesson notes/result approvals/promotions/member permissions, and immutable tenant ownership for referenced parent rows. Its disposable PostgreSQL test covers 13 negative cross-tenant/reassignment cases.

### New forward-only posture repair

- Added `supabase/migrations/20261017170000_schoolpro_forward_operational_tenant_isolation.sql` on the Stage A branch. It validates that all eight expected tables exist, then enables and forces RLS without dropping, creating, or rewriting any existing feature policy. It intentionally does not mutate application rows.
- Extended `scripts/test-schoolpro-operational-tenant-integrity.integration.sql` to apply both forward migrations in disposable PostgreSQL, assert ENABLE/FORCE RLS for all eight tables, confirm representative existing feature policy names remain present, and exercise own-school row visibility as the ordinary `authenticated` role across the operational fixture tables.
- Extended `scripts/test-schoolpro-operational-tenant-integrity.mjs` to assert the forward migration fails closed for missing tables, preserves policies, and documents FORCE RLS limits.
- CI run #1493 (SchoolPro CI) and payment-page validation #1220 were started for head `2ace61eafd070b3618d9f57ceaf3fdac606edd8e`; results must be read from the completed run before claiming acceptance:
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39029530039
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39029529982

### Stage A closure status and remaining guardrails

- The old migration-name mismatch is now addressed by an explicit forward-only source migration rather than by replaying destructive historical policy replacement. This is **source-level repair only** until disposable PostgreSQL tests pass and exact-head CI is green.
- Recheck the complete current PR diff, all CI jobs, payment validation, and production catalog/trigger interactions after the run finishes. Production remains on the old schema and migration ledger until explicit cutover approval; do not apply the proposed migrations or merge/deploy automatically.
- Cancellation remains unsupported in the deployed payment-review contract (only `confirmed`/`rejected`); do not represent rejection as cancellation or rewrite confirmed ledger rows.
- Once Stage A is accepted and merged with explicit owner approval and post-merge verification, prioritize the separate SchoolPro-to-MySQL foundation track (PR #107 / `migration/mysql-schoolpro-foundation`). Keep DataSub and other IHLink platforms on Supabase; preserve the current SchoolPro architecture and records; use synthetic disposable MySQL fixtures first; map tenant/role rules, routines, triggers, Storage replacement and transactional payment flows before any production cutover. Do not start Stage B operational data population until Stage A is verified after merge, and re-verify B and C before resuming D. Preserve the full A–J backlog.


### Follow-up CI defect/fix record — 2026-10-17

- CI #1493 on intermediate head `2ace61eafd070b3618d9f57ceaf3fdac606edd8e` correctly caught two defects in the newly added tests: the fixture's dollar-quoted DO block was reduced to a single dollar delimiter by the GitHub file-update replacement operation, and the static documentation assertion expected a phrase split across SQL comment lines.
- Fixed the SQL delimiter and relaxed the static assertion to check the substantive documented limit (superusers/BYPASSRLS). The corrected current Stage A head is `70b779f45dcbe306a5f15b1abbecab343ac7620e`.
- Do not count CI #1493 as passing: its tenant-integrity integration and validation jobs failed on the intermediate test defects. A new exact-head CI/payment-page run must pass on `70b779f45dcbe306a5f15b1abbecab343ac7620e` before this repair is accepted. No production state changed.


### Expanded operational ownership invariant and final CI rerun — 2026-10-17

- Read-only production trigger inspection confirms the eight operational tables already have activation guards; calendar and lesson notes also have activity/workflow triggers; promotions have an after-update progression-archive trigger; the result/member/class/student/subject tables have their own existing validation/lifecycle triggers. The forward repair adds distinct trigger names and does not drop existing activation/workflow triggers.
- Tightened `20261016160000_schoolpro_repair_operational_tenant_integrity.sql`: `school_id` is now immutable not only on referenced parent entities but also on all eight operational tables. This prevents a privileged update from moving a row across schools even if the destination foreign keys would be valid. Added eight disposable-PostgreSQL negative reassignment cases and static trigger-contract assertions.
- Current Stage A candidate head: `7110e0273001d07be1c09f673e90ee8653b6f2d3`.
- SchoolPro CI run #1500 is in progress for that head: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39029802906. The prior corrected head's tenant-integrity job passed, but #1500 is the required run for the expanded immutability tests. Do not claim Stage A closed until all jobs and payment-page validation complete successfully on the final head.
- Production remains read-only/unchanged. The forward migrations have not been applied to the production ledger. The historical source/ledger mismatch is reconciled as a deliberate forward-repair plan, not as proof that the historical migration ran.


### Latest test-harness correction — 2026-10-17

- CI #1500 failed only in the new eight-case tenant-reassignment test block because its SQL statement delimiters were emitted as single-dollar delimiters. The production migration logic and earlier relational cases passed up to that point; do not record #1500 as green.
- Corrected the SQL dollar quoting in commit `78b6db3368ae24f5c02d8af9e2a557701084024d`.
- Exact-head SchoolPro CI #1502 and payment-page validation #1229 are queued:
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39029917432
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39029917397
- Final acceptance is pending these exact-head results. The handover remains deliberately explicit that no production migration has been applied.


### Production role semantics confirmed — 2026-10-17

Read-only `pg_roles` inspection confirms `anon`, `authenticated` and `authenticator` have neither SUPERUSER nor BYPASSRLS; `postgres` and `service_role` have BYPASSRLS. This supports the migration's explicit caveat: FORCE RLS governs non-bypass owners, but it is not a substitute for scoped RLS policies, explicit RPC authorization, and keeping service-role credentials server-side. The new disposable integration tests exercise visibility as `authenticated`; they do not claim to constrain the privileged service role.


### Exact-head Stage A CI result — 2026-10-17

Final tested Stage A head: `78b6db3368ae24f5c02d8af9e2a557701084024d`.

- SchoolPro CI [#1502](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39029917432): all eight jobs passed — validation/build, live two-school tenant acceptance, local receipt Storage isolation, disposable PostgreSQL tenant integrity, payment-review RLS/concurrency, result-PIN cooldown, result-verification exposure, and public-admission abuse controls.
- Payment-page validation [#1229](https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39029917397): passed on the same head.
- Operational tenant integration passed the authenticated own-school visibility check, ENABLE/FORCE RLS checks on all eight tables, preservation of representative existing feature policies, cross-school relationship rejection, and immutable school ownership tests for operational and parent rows.
- CI #1493 and #1500 failed on intermediate test-harness defects; their fixes are included before #1502. Do not report the intermediate runs as green.
- This closes the operational tenant-isolation **source/test blocker** on the draft branch. Production rollout is still pending: the Stage A migrations have not been applied to production, no production writes or receipt uploads occurred, and PR #106 remains unmerged. Do not claim production Stage A closed until an approved rollout and post-deploy catalog/tenant checks are complete.
- No live receipt-submission object was available for a production Storage test; local Storage API isolation passed without creating dummy production data. Payment cancellation remains unsupported; review decisions are confirmed/rejected only.
- Stage B stays gated on Stage A merge and post-merge verification. The separate SchoolPro MySQL foundation/audit may continue with disposable fixtures only; no production backend switch is authorized.


## MySQL workstream resumed after Stage A source/test closure — 2026-10-17

Stage A's operational tenant-isolation source/test blocker is closed at exact-head CI #1502 and payment validation #1229 (see the Stage A section above). PR #106 remains draft/unmerged because its production migrations have not been rolled out. The separate SchoolPro MySQL foundation work now continues using disposable fixtures only; no Stage B academic data population or production backend switch has started.

### New source-informed MySQL migration slice

- Read-only production catalog inspection captured the current column sets for guardian links, fee structures/items, invoices, fee payments, payment submissions/allocations/proofs, bank accounts, subscription catalog/plans/subscriptions, and invoice/result templates.
- Added `database/mysql/002_schoolpro_guardians_finance_subscriptions.sql`. It introduces guardian-to-student links, school bank accounts, fee structures/items, fee invoices, payment submissions, fee payment ledger, allocations, legacy per-invoice payment proofs, annual subscription plans/status, and subscription receipt review.
- The target models SchoolPro's manual receipt-based payment flows. It intentionally does **not** port the old gateway/virtual-account subscription intent flow because the current business rule is annual subscriptions with receipt upload and IHLink admin verification; BillStack remains DataSub-only and the SchoolPro online gateway is disabled.
- Demo plan is reserved as `code='demo'`, has no annual price and stores `paid_amount=NULL`; all subscription billing cycles are annual. Grace/suspension timestamps and states are represented for the agreed two-week grace lifecycle. API behavior and state-transition transactions still need implementation/tests.
- Receipt records retain an object key and explicit owner; CHECK constraints require the first object-key folder and owner to match the submitting user. These database checks complement, but do not replace, server-side object ownership authorization.
- Updated `001_schoolpro_core.sql` with the composite enrollment key needed to ensure an invoice's student/session matches its enrollment.
- Added synthetic fixture `tests/mysql/schoolpro_finance_fixture.sql` and negative tests for cross-school guardian links, fee structure class, invoice student/enrollment, payment bank account, payment invoice/student, allocation invoice/student, subscription receipt tenant, receipt owner/path mismatch, Demo price, and non-annual billing cycles.
- Updated `.github/workflows/mysql-schoolpro-schema.yml` to apply migrations 001 and 002 in disposable MySQL 8.4, load synthetic fixtures, and assert named foreign-key/check/ENUM rejections. This migration remains schema-only; it does not yet implement transactional review RPC/API behavior or reconcile production rows.

### Exact-head validation currently running

Candidate PR #107 head: `cf419bf94e353f2cb9b5c0647aa3e7932ed68195`.

- MySQL schema workflow #294: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39030626322
- SchoolPro CI #1517: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39030626304
- Payment-page validation #1244: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39030626313

Do not mark this slice accepted until the disposable MySQL workflow passes on the exact head and any failures are fixed/retested. No production database or application configuration was changed.


### MySQL finance test fixture correction — 2026-10-17

- MySQL schema run #294 failed on the intended invoice/enrollment mismatch case because its fixture used a student from the other school; the invoice's direct student FK correctly rejected it first, so the test did not isolate the composite enrollment constraint.
- Added a second synthetic student inside School A and changed the negative case to use that same-school student with School A's different enrollment. The test should now reach `fk_invoice_enrollment_student_session` and prove the student/enrollment/session tuple must match.
- Exact-head rerun after the fixture correction: MySQL schema workflow #299, SchoolPro CI #1520, and payment validation #1247 are queued:
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39030722203
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39030722204
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39030722216
- Do not mark the new MySQL schema slice accepted until #299 passes. No production database changes occurred.


### MySQL allocation negative-test isolation fix — 2026-10-17

- MySQL workflow #300 failed because the allocation negative test reused the same submission/invoice pair as a valid fixture, so the unique key fired before the intended invoice/student composite foreign key.
- Added a second independent pending School A submission and changed the negative test to use it with a same-school but mismatched student/invoice pair. This isolates the intended `fk_fee_allocation_invoice_student` constraint rather than accepting an unrelated duplicate-key failure.
- Payment page validation #1248 passed at its recorded head, but it predates this latest fixture correction. New exact-head MySQL and application CI runs must pass before acceptance.
- Production remains untouched; all MySQL tests use disposable CI data.


## MySQL result workflow and template schema slice — 2026-10-17

Read-only production schema inspection confirmed the source columns for assessment schemes, grade scale, result approvals, correction requests/snapshots, result templates, transcript issues and transcript settings. Added a draft-only MySQL target migration at `database/mysql/003_schoolpro_assessment_review_templates_transcripts.sql`.

- Assessment schemes are school-scoped, education-level-specific, JSON component definitions with validation.
- Grade scales enforce 0–100 ranges and school-local label/position uniqueness.
- Result approvals and correction requests/snapshots reference result rows through composite school/result foreign keys; request state and score constraints are represented.
- Result/workbook templates are school-owned, have JSON mappings for fields/components/custom fields, preserve logo/photo/signatory/QR settings, and require workbook/logo object paths to begin with the owning school ID. This prevents accidental cross-school/global template reuse at the schema layer.
- Transcript settings and issued transcript snapshots are included. Transcript serials are globally unique; revocation actor/time must be recorded together.
- Added disposable synthetic fixtures and negative tests for cross-school result approval, cross-school transcript student, foreign-school workbook object path, and grade maximum above 100. Wired migration 003 and these checks into the MySQL 8.4 workflow.
- This is relational schema coverage only. Application authorization, score calculations, approval transitions, immutable audit/event atomicity, actual Excel parsing/rendering, file-store permissions, transcript-level-specific content and source-row data reconciliation still need implementation and contract tests.
- MySQL schema workflow #307, SchoolPro CI #1525 and payment-page validation #1252 passed on the prior finance-schema head `4579a7cf49b0112d3b783e903a64ee98dc263d87`. The new schema slice is not yet accepted; wait for fresh CI on this migration/fixture commit.
- No production database, live files, Render configuration or production routes were changed.


### MySQL migration 003 schema validation — 2026-10-17

- Disposable MySQL schema workflow #321 passed after adding migration 003 and the assessment/template/transcript fixture suite: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031138541
- Payment-page validation #1259 passed on the same migration/fixture commit: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031138556
- SchoolPro CI #1532 was still running its final mobile-layout/build steps at the time of this entry: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031138503. Do not call the complete application CI green until the terminal conclusion is confirmed.
- The schema test proves that migration 003 creates in MySQL 8.4, valid synthetic rows insert, and selected cross-school result approval/transcript references, foreign-school template paths and grade values above 100 are rejected by the expected constraints.
- This does not yet prove API authorization, result calculation, workflow transactionality, immutable event logging, workbook import/export/rendering, or transcript issuance/revocation parity. Migrations 001–003 remain draft proposals, not production schema changes.
- Updated the schema-gap audit to reflect all three current draft migrations and the remaining application/parity gaps.


### Final result for migration 003 validation — 2026-10-17

The earlier “still running” status is superseded by terminal outcomes. On the code-bearing migration/fixture/workflow commit `21a8d7731c3dab9de27c7a91ab5ddbd0a34a52b4`:
- MySQL schema workflow #321 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031138541
- SchoolPro CI #1532 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031138503
- Payment-page validation #1259 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031138556

Only documentation/PR description updates followed that code-bearing commit; no migration, fixture, or workflow source changed afterward. Therefore the tested schema code is unchanged, though the latest branch tip is a documentation-only descendant. Migrations 001–003 remain draft-only and do not authorize production cutover.


## MySQL admissions and progression slice — 2026-10-17

Added draft migration `database/mysql/004_schoolpro_admissions_progression.sql` based on a read-only source column inventory for admissions, documents, offers, events, acceptances, enrollment history and promotions.

- Admissions, offers, documents, events and acceptances are explicitly school-scoped; child records use composite school/application or school/offer foreign keys.
- Public admission/offer tokens and school-local application/offer numbers are unique. Entrance scores are bounded 0–100.
- Admission document storage paths must begin with the owning school ID.
- Student enrollment history references the same school's student, session and class, and retains class/arm/section snapshots plus graduation/transfer/repeat state.
- Promotion decisions are represented separately from application of a promotion. A record starts as `previewed`/decision `hold`; applying requires `applied_by` and `applied_at`. This schema does not run automatic promotion when results publish; API logic must enforce preview, review and explicit apply.
- Added synthetic fixtures and negative tests for cross-school admission documents, enrollment history student links, promotion target class, and foreign-school admission object paths. CI now installs migration 004 after migrations 001–003.
- Validation pending: run MySQL schema, full SchoolPro CI, and payment-page validation on the migration 004 code-bearing commit. No production rows or routes have changed.


### MySQL migration 004 first-run correction — 2026-10-17

- MySQL schema workflow #339 caught a MySQL 8.4 DDL incompatibility in `student_promotions`: the `applied_by` column participated in a CHECK requiring a non-null actor for applied rows while its FK used `ON DELETE SET NULL`. MySQL rejects this combination because the referential action can violate the check.
- Changed the applied-actor FK to `ON DELETE RESTRICT`. This is also the safer audit behavior: an actor cannot be deleted if doing so would erase the required actor on an applied promotion.
- This was caught before acceptance; migration 004 is not yet accepted. Re-run the MySQL schema, SchoolPro CI and payment validation on the corrected source.


### MySQL migration 004 schema test passed — 2026-10-17

- Corrected MySQL schema workflow #342 passed on the migration 004 code-bearing commit `870259ceec5c2bb8e0026ad6598a88f826c23a32`: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031582992
- Payment-page validation #1272 also passed on that commit: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031583006
- SchoolPro CI #1545 was still running its final application build checks at this checkpoint: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39031583118
- Schema CI verifies migrations 001–004 install on disposable MySQL 8.4, the synthetic admissions/progression fixtures insert, and selected cross-school application/document/student/class references and foreign-school object paths are rejected.
- This is not production acceptance. Admissions APIs, public-token protections, offer/acceptance transactions, explicit promotion preview/review/apply, result workflow authorization, and complete source parity remain outstanding.


## MySQL operational modules slice — 2026-10-17

Added draft migration `database/mysql/005_schoolpro_operational_modules.sql` using the production source's read-only column inventory. It adds timetable entries, calendar events, announcements, discipline records, student health records, lesson notes/review state, leave requests, inventory assets, hostel rooms and hostel allocations. Attendance already exists in migration 001 as enrollment-scoped `attendance_records`, so migration 005 intentionally does not redefine it.

- Domain rows carry `school_id`; student, class, subject, session, term and membership relations use school-scoped composite foreign keys where the target model supports them.
- Added synthetic fixtures for timetable, calendar, announcements, discipline, health, lesson notes, leave, inventory and hostel. Attendance fixture asserts the existing core enrollment link.
- Added negative tests for cross-school timetable class, cross-school hostel student and invalid timetable weekday/time. MySQL 8.4 workflow now applies migration 005 and runs the fixtures/negative tests.
- Important limitation: schema constraints do not replace application authorization. Health and discipline require particularly strict role-level access; timetable overlap, hostel capacity/occupancy, attendance batch rules, leave review permissions, and notification/audit transaction behavior need service-level tests.
- Migrations 001–005 are draft-only. No production schema or records were changed. Awaiting exact-head MySQL schema workflow, SchoolPro CI and payment-page validation for this slice.


### MySQL migration 005 first validation correction — 2026-10-17

- Initial MySQL schema workflow #361 correctly caught an assertion-quality issue, not a migration DDL failure: the negative timetable fixture invalidated both weekday and time range, and MySQL reported `chk_timetable_time` first while the test expected `chk_timetable_weekday`.
- Split the test inputs so invalid weekday is tested with a valid time range, and added a separate invalid time-range fixture. CI now expects each precise check constraint independently. The initial run is recorded as failed and is not counted as acceptance.
- Re-run all workflows on the corrected fixture/workflow commit before considering migration 005 validated.


### MySQL migration 005 validated — 2026-10-17

Corrected exact-head validation completed successfully on code-bearing commit `1c37d77962eb8b48de3c33288a45da1ef6d035a0`:
- MySQL schema workflow #368 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032033651
- SchoolPro CI #1560 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032033656
- Payment-page validation #1287 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032033647

This validates migrations 001–005 and their selected synthetic tests in disposable MySQL 8.4. The first schema run #361 failed because a test asserted the wrong CHECK constraint for an input violating two constraints; the isolated weekday/time tests now pass. The operational tables are still proposals, and application behavior/security parity remains open.

## MySQL learning, CBT, library, transport and payroll slice — 2026-10-17

Added draft migration `database/mysql/006_schoolpro_learning_cbt_library_transport_payroll.sql` for assignments/submissions, question bank, CBT tests/questions/attempts/answers, library books/loans, transport routes/student assignments and payroll records.

- Added synthetic fixture coverage for each domain and a generated payroll net calculation.
- Added negative cross-tenant tests for assignment submission student, CBT question, and library loan book relationships.
- Workflow updated to apply migration 006 after 001–005 and run the new fixtures/negative cases.
- This remains schema-level only. CBT eligibility/token security, attempt locking and timing, answer grading, question disclosure control, assignment grading permissions, library copy-count concurrency, route capacity, payroll approval/payment authorization and audit transactions require service-level contracts.
- Migration 006 validation is pending; do not infer success from earlier green workflow runs.


### MySQL migration 006 first validation correction — 2026-10-17

- MySQL workflow #385 installed the new migration and valid fixtures but stopped in the negative-test harness because the expected foreign-key name for assignment student isolation was written as `fk_assignment_submission_student`; the actual migration names it `fk_submission_student`.
- Corrected the workflow assertion to the actual constraint name. The failed run is not counted as a pass. A new exact-head schema run is required; payment-page validation had passed on the earlier code-bearing migration 006 commit, but that does not validate the corrected workflow assertion or schema suite.


### MySQL migration 006 validation update — 2026-10-17

Corrected the assignment-submission negative-test assertion to expect the actual constraint name `fk_submission_student`. On code-bearing commit `1e4ac4940a315717969baec8d64f3e25bbd89fdf`:
- MySQL schema workflow #389 passed, applying migrations 001–006, inserting synthetic fixtures, and executing the selected cross-school/check-constraint negatives: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032356443
- Payment-page validation #1299 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032356474
- SchoolPro CI #1572 was still running at handover update time: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032356436

The earlier failed schema run #385 remains recorded as a failed test-harness expectation and is not counted as acceptance. Migration 006 is validated only at the MySQL schema/fixture/selected relational-constraint level once the stated schema run completed; it does not establish application authorization or full behavior parity. Do not claim all workflows green until #1572 completes on this same code-bearing commit.

Next MySQL work should be driven by the source-to-target parity matrix and actual application call paths, not by expanding tables without mapped source behavior. Highest-value gaps after schema slice: API authorization and transaction contracts, assessment calculation/publication parity, admissions/promotion preview/apply, receipt/storage authorization, result template import/export, and operational role restrictions. Preserve A→B→C→D acceptance order; MySQL schema CI does not close Stage A's separate production operational RLS/catalog blocker.


### Migration 006 exact-head CI closed — 2026-10-17

SchoolPro CI #1572 completed successfully on code-bearing commit `1e4ac4940a315717969baec8d64f3e25bbd89fdf`: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032356436. Together with MySQL schema #389 and payment-page validation #1299, all three workflows passed on that code-bearing commit. The subsequent handover/PR documentation commit does not change schema code. Migration 006 therefore passes the current disposable MySQL 8.4 schema/fixture/selected constraint CI gate. This is not an application/API authorization acceptance or a production migration approval.


## Stage A operational tenant isolation — fresh production catalog reconciliation (2026-10-17)

Read-only catalog checks were repeated against production Supabase project `lnqsroyiybutkfngbyge` after Stage A PR #106's exact-head CI completed.

**Confirmed production state:**
- All eight operational tables targeted by the forward-only RLS repair have RLS enabled but `FORCE ROW LEVEL SECURITY = false`: `schoolpro_library_books`, `schoolpro_transport_routes`, `schoolpro_hostel_rooms`, `schoolpro_inventory_assets`, `schoolpro_calendar_events`, `schoolpro_lesson_notes`, `schoolpro_result_approvals`, and `schoolpro_promotions`.
- All eight are owned by `postgres`, whose current role has `BYPASSRLS = true`. Therefore FORCE RLS is defense in depth against future non-BYPASSRLS table owners, not a restriction on the current postgres owner or service-role credentials.
- Existing feature-specific policies are present and materially differ by table. Examples: family reads for borrowed library book details; calendar school read plus management write; lesson-note author and leadership access; result-approval leadership write and school read; promotion manager read. The historical migration `20261002234500_schoolpro_operational_tenant_isolation` drops all policies on its target tables and must not be replayed over this catalog.
- `private.schoolpro_validate_operational_tenant()` and `private.validate_schoolpro_member_permission_tenant()` are absent from production. The exact ledger query returned no rows for versions `20261002234500`, `20261016160000`, `20261017170000`, or `20261017150000`.
- Current `private.has_school_access` is SECURITY DEFINER with fixed empty search_path and grants active platform-admin access as designed. This must remain explicit in role/tenant tests.

**Source and CI status:** Stage A PR #106 head `78b6db3368ae24f5c02d8af9e2a557701084024d` passed SchoolPro CI #1502 and payment-page validation #1229. The forward-only migration `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` changes only RLS flags, fails closed if a required table is missing, and preserves all current policies. The separate `20261016160000_schoolpro_repair_operational_tenant_integrity.sql` adds tenant relationship/ownership triggers. Disposable integration tests verify eight ENABLE/FORCE flags, representative policy preservation, authenticated tenant-scoped reads, cross-school relationship rejection, and tenant immutability.

**Release decision:** source/test acceptance is green, but Stage A is **not production-closed**. Production remains on the prior catalog: neither repair migration has been applied, and no post-deployment catalog/behavior verification exists. Do not mark A closed until the owner explicitly authorizes applying the two reviewed forward-only migrations in the intended order, followed by read-only catalog reconciliation and authenticated cross-school smoke tests. No production writes were made during this audit. This is the sole outstanding operational tenant-isolation release blocker before the project can treat Stage A as complete; other Stage A security checks remain subject to the release gate's full checklist.


### Stage A live tenant smoke-test expansion — 2026-10-17

Extended `scripts/test-schoolpro-tenant-isolation-live.mjs` so the optional read-only two-school acceptance checks now test foreign-school row visibility for the eight operational tables as well as students, members, invoices and results: library books, transport routes, hostel rooms, inventory assets, calendar events, lesson notes, result approvals and promotions. This does not write production rows. It is intended to catch policy regressions against real School A/School B authenticated sessions after the reviewed migrations are deployed.

- New code-bearing head: `9c43acd268c4edd7a3c6422e66bd9d8627763588`.
- SchoolPro CI #1576 and payment-page validation #1303 were running when this entry was prepared:
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032935243
  - https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39032935258
- Do not count these runs until complete. The live two-school job only runs when `RUN_LIVE_TENANT_ACCEPTANCE=true` is configured; static CI parsing alone is not evidence that production tenant queries were executed.


### Live tenant acceptance retry correction — 2026-10-17

The first run of expanded live acceptance (CI #1576) verified foreign-school reads were denied across the added operational tables for School A and for most of School B's table list, then failed on a single query to `schoolpro_result_approvals` with an empty error message and status 0. This is not yet classifiable as an authorization failure or a pass. Updated the read-only count query to select only `id` and retry empty, status-0 transport errors while continuing to fail immediately for explicit database/API errors. Corrected code head: `de02a07404ddc39c86fd3278fbed820227d399da`. Await a fresh exact-head run; do not count CI #1576 as passing.


### Live tenant probe correction 2 — 2026-10-17

The retry correction alone did not resolve the live `schoolpro_result_approvals` probe: CI #1578 again timed out/returned an empty status-0 error on the School B exact-count request, after the other operational-table denial checks passed. Replaced exact `COUNT(*)` with a bounded `SELECT id ... LIMIT 1` negative probe; this tests the required security property directly (no foreign row is returned) without requiring a full count under RLS policies. Updated head: `e35365fbe9ff05ca4ce7da40a2c1cb4cfe9a94ce`. New exact-head CI/payment validation must pass, and the live test remains unaccepted until then.


### Stage A operational RLS probe performance finding and forward index repair — 2026-10-17

The live two-school acceptance test repeatedly timed out when School B queried `schoolpro_result_approvals`, even after replacing exact count with a bounded `LIMIT 1` probe. The surfaced database error was `canceling statement due to statement timeout`, not a row returned to the wrong tenant. A read-only index inventory showed approximately 33,603 estimated rows / 9.7 MiB in `schoolpro_result_approvals` and no index beginning with `school_id`; the table only had unique indexes on `id` and `result_id`. Other operational tables `schoolpro_library_books`, `schoolpro_transport_routes`, `schoolpro_hostel_rooms`, `schoolpro_inventory_assets`, and `schoolpro_promotions` also lacked a leading `school_id` index.

Added draft forward-only migration `20261017180000_schoolpro_operational_tenant_indexes.sql` to add a tenant-leading index to those six tables, with fail-closed table existence checks. Added the migration to the disposable operational integration test, added catalog assertions for all six indexes, and expanded the static test. No data or RLS policy is changed by this index migration. New code-bearing PR #106 head: `c9115f20ca81e129d8ce2e7311d5948465fb6df6`. Exact-head CI/payment validation are pending; neither previous live smoke failure is counted as a pass. Production remains unchanged.


### Stage A production index/catalog reconciliation — 2026-10-17

A read-only production catalog query confirmed the RLS acceptance timeout is correlated with missing tenant-leading indexes, not an observed foreign-row leak. Approximate live catalog statistics: `schoolpro_result_approvals` ~33,603 rows / 9.7 MiB, `schoolpro_promotions` ~1,120 rows; result approvals had only ID and result_id unique indexes, with no `school_id`-leading index. Library books, transport routes, hostel rooms and inventory assets likewise had only primary-key indexes; calendar and lesson notes already had school_id-leading indexes.

The live two-school acceptance run on corrected code head `e35365fbe9ff05ca4ce7da40a2c1cb4cfe9a94ce` passed foreign-school read denial for School A across all 12 tested tables, and for School B through lesson notes; it then timed out probing `schoolpro_result_approvals` after three attempts (final message: “canceling statement due to statement timeout”). This is **not a pass** and is not evidence of unauthorized row exposure.

The repository already contains a dedicated forward-only index migration, `supabase/migrations/20261017180000_schoolpro_operational_tenant_indexes.sql`, which fails closed if any required table is missing and adds school_id indexes to the six unindexed operational tables. I briefly created a redundant alternative migration while investigating, then removed it before acceptance; only the existing canonical index migration should remain. The index migration is not applied in production and must not be treated as live until the owner approves the reviewed deployment and catalog verification confirms it.

- Current Stage A run: CI #1580 and payment-page validation #1307 were still running when this note was added. CI #1578 on the prior retry-only head failed at the same result-approval probe after a status-0 timeout. Exact-head run results must be checked before acceptance.
- Next acceptance step: let the canonical index migration be included in disposable local migration tests, rerun the two-school acceptance only after authorized deployment (or use an isolated Supabase branch first), then verify the index definitions via read-only catalog query and repeat the same authenticated role/tenant matrix. Do not drop or weaken the result-approval policies to make the test pass.
- No production schema, rows, or settings were changed by these catalog queries or repository edits.


### Operational tenant index regression-test correction — 2026-10-17

The first CI attempt for the index repair caught two harness-only defects: a dollar-quoted SQL assertion block was authored with a single `$` delimiter, and the static JavaScript regex over-escaped its pattern. Corrected the SQL block to use `$assert$` delimiters and replaced the brittle regex with exact DDL-string assertions. These failed attempts are not accepted. Latest code-bearing Stage A head is `7416aa218634e5e095b46ef4a6ac328718db9346`; SchoolPro CI #1590 and payment-page validation #1317 are queued. The six-index migration is still draft-only; production remains unchanged.


### MySQL migrations 001–006 exact-head revalidation — 2026-10-17

Current PR #107 head 627a163fbad728c0665d56cffe965edb60de7a64 has:
- MySQL schema workflow #394 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033057013
- SchoolPro CI #1579 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033056969
- Payment-page validation #1306 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033057076

This confirms the current draft MySQL 8.4 migration chain 001–006 installs and selected synthetic/negative relational tests pass. It does NOT mean the React application is using MySQL: the current frontend still imports the Supabase browser client and Supabase Auth. A SchoolPro-only server-side API/data-access boundary is the next migration phase; do not point browser/mobile clients directly at MySQL, and do not switch DataSub or other IHLink products off Supabase. Existing Supabase-auth password hashes must not be copied into MySQL as if they were portable; plan explicit account migration/reset or a controlled transition.

### Stage A post-index test harness correction — 2026-10-17

A Stage A CI run after the canonical operational index migration was added to the integration test caught two test-harness defects before production deployment:
1. Static regex assertions overescaped \s/\S, so they did not match the actual tenant-leading index DDL even though the canonical migration contains the expected indexes.
2. The SQL index assertion block used an inconsistent dollar-quote delimiter and failed parsing.

Corrected the static regexes to use [\s\S] and normalized the SQL block to DO $$ ... $$;. This is a test-only correction; the canonical forward-only migration remains supabase/migrations/20261017180000_schoolpro_operational_tenant_indexes.sql. The failed run #1585 is not counted as acceptance. New exact-head Stage A CI #1592 and payment validation #1319 were queued at the time of this note:
- https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033592982
- https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033592955

Production still lacks the reviewed indexes, and the live RLS probe has not passed due to the result-approval query timing out. No production changes were made. Keep Stage A open until exact-head local integration passes and production deployment is explicitly authorized, followed by catalog verification and a successful two-school authenticated smoke test.


### Final index assertion harness adjustment — 2026-10-17

A concurrent branch edit normalized the PL/pgSQL dollar delimiter to a single `$`, which caused PostgreSQL syntax failure in the previous CI run. To avoid delimiter/escaping fragility entirely, replaced the procedural assertion with a psql `\gset / \if / \quit` check requiring all six expected indexes. Static assertions now use literal DDL-string checks for the two critical index definitions. Corrected code head: `2aa67f6f4715e9e8653041a313bda4e4ea2e6ceb`. Fresh exact-head CI and payment-page validation are required; previous failures remain unaccepted. Production is unchanged.


### Index migration static-check correction — 2026-10-17

The static assertion that the index migration fails closed had an over-escaped regular expression and was corrected to match `to_regclass` through `raise exception`. Latest code-bearing Stage A head is now `eeac24a9e1820272ef673f59afd053a81408f193`; SchoolPro CI #1596 is queued and payment validation #1323 is running. The live acceptance probe is still expected to be sensitive to the index deployment state; no production migration has been applied.


### Exact-head revalidation after migration 006 FK assertion correction — 2026-10-17

The assignment-submission negative test now expects the actual MySQL constraint name `fk_submission_student` (the previous expected name was incorrect). The latest branch head observed during this recheck is `1964131c0e62075dbcc9f767c7299cb73aa60cc3`. Exact-head runs were started:
- SchoolPro CI #1597: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033739286
- MySQL schema draft #400: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033739279
- Payment-page validation #1324: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033739281

At the last check, all three were still in progress. Earlier MySQL run #385 failed on the incorrect assertion and is not accepted; the payment-page run #1296 passed, but that does not replace the fresh exact-head run. Await #400 and verify all six migrations plus fixtures and the cross-school negative cases. Do not call migration 006 accepted until the corrected run finishes successfully. This note is evidence of run status, not an acceptance claim.


### Migration 006 corrected schema result — 2026-10-17, follow-up

The corrected MySQL schema workflow #400 has now completed successfully on code-bearing head `1964131c0e62075dbcc9f767c7299cb73aa60cc3`:
- MySQL schema draft #400: PASS — https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033739279
- Payment-page validation #1324: PASS — https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033739281
- SchoolPro CI #1597 was still running at the time of this update: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033739286

The schema job log confirms the expected cross-school FK/check rejection tests passed, including the corrected `fk_submission_student` assertion, foreign-school CBT question, foreign-school library book, and annual-only subscription check. The schema workflow's negative-test helper prints MySQL ERROR lines as expected; each is followed by a PASS assertion naming the expected constraint. This is not a schema failure.

Acceptance is partial until SchoolPro CI #1597 completes. The run was triggered on code head `1964131...`; this handover-only update does not change the tested schema/code. Migrations 001–006 remain proposals for disposable MySQL CI only; no production database has been modified.


### Stage A current-head verification refresh — 2026-10-17

The Stage A PR #106 head has advanced to `eeac24a9e1820272ef673f59afd053a81408f193`. On this exact head:
- Payment-page validation #1323 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033727069
- SchoolPro CI #1596 was still running at the last check: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033727021

This is a separate branch from the MySQL migration PR #107. Stage A is still not closed: the production catalog gap and live authenticated two-school smoke-test timeout remain unresolved; no production migration is authorized or applied. Wait for #1596, then inspect the result-approval probe rather than treating timeout as a pass or assuming a leak. The reviewed forward-only tenant-index migration remains pending explicit production approval.


## MySQL migration 007 — authentication throttling state — 2026-10-17

Extended the existing draft `database/mysql/007_schoolpro_auth_login_throttling.sql` with a format constraint requiring the identifier key to be a lowercase 64-character hexadecimal SHA-256 digest. The table deliberately does not store raw email/login identifiers or trust caller-supplied IP headers. Added a disposable valid fixture and a negative test for malformed identifier keys, and wired migration 007 into the MySQL 8.4 schema workflow after migration 006.

- This is persistence/schema support only; it does not implement rate limiting by itself. Server-side atomic counter/window updates, lockout behavior, enumeration-safe responses, password reset/first-login limits, audit events, concurrency tests and API authorization remain to be implemented and verified in `server/mysql-api`.
- The previous exact-head MySQL migration 006 run #400 passed, and payment validation #1324 passed; SchoolPro CI #1597 subsequently completed successfully. Those results do not cover migration 007, whose exact-head validation is now required.
- No production schema, users, login attempts or credentials were changed. Migrations remain draft-only, PR #107 remains open/draft, and Supabase remains authoritative until explicit migration/cutover acceptance.


### Migration 007 DDL failure and correction — 2026-10-17

The first migration-007 validation attempt (#415) failed at `Apply authentication login throttling schema`. Inspection of the exact file showed the previous automated text edit had malformed the CHECK expression and duplicated part of the table/ledger DDL. This was a real migration-file defect, not a test-only mismatch. Replaced the whole file with a clean, single CREATE TABLE plus ledger upsert, including:
- `CHECK (attempts >= 0)`
- `CHECK (identifier_hash REGEXP '^[0-9a-f]{64}$')`
- one InnoDB table definition and one `schema_migrations` upsert.

Corrected code commit: `2575687c7440a7d4d054901dab9131b0896a2718`. The corrected exact-head workflow results have not yet been returned at the time of this entry. Do not count #415 as a pass. The valid fixture and malformed-hash negative test remain wired to the MySQL schema workflow. No production database was touched.


### Migration 007 corrected exact-head result — 2026-10-17

The clean DDL correction was validated on code-bearing commit `2575687c7440a7d4d054901dab9131b0896a2718`:
- MySQL schema draft #419 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034087917
- Payment-page validation #1337 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034087929
- SchoolPro CI #1610 was still in progress at last check: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034087944

Migration 007 now installs in disposable MySQL 8.4 with the hash-format CHECK. The schema job passed its fixture and malformed-hash negative test. This establishes only that the throttling-state table and format constraint install; it does not yet prove production-grade rate-limit semantics or the full authentication/API authorization contract. Keep PR #107 draft/unmerged and all migrations unapplied to production.


## MySQL API/authentication foundation — 2026-10-17

Moved the next MySQL increment from table expansion into a server-side boundary. Added draft `server/mysql-api/` with a Node HTTP service using `mysql2`, and migration `database/mysql/007_schoolpro_auth_login_throttling.sql`.

**Implemented in this draft:**
- `GET /healthz` checks DB reachability without exposing connection details.
- `POST /v1/auth/login` normalizes email, verifies only the documented scrypt password-hash format, uses generic invalid-credential responses, and issues an opaque random session token while storing only its SHA-256 hash in `user_sessions`.
- Browser login uses an HttpOnly, SameSite=Lax cookie; native login can receive an opaque token for later secure native-vault integration. Production cookies are Secure.
- `POST /v1/auth/logout` revokes the session; `GET /v1/me` requires an active user and unexpired, non-revoked session.
- `GET /v1/schools/:schoolId/context` requires an active school membership or a separately assigned `super_admin`/`platform_admin` platform role. Platform admin access is not represented as school membership.
- Per-normalized-identifier login throttling persists only a hashed identifier in MySQL. The implementation does not trust caller-controlled forwarded IP headers.
- CI installs this isolated service's dependency and runs a real MySQL integration contract against the disposable MySQL 8.4 schema after migrations 001–007 and synthetic fixtures.

**Not yet complete:** This is not wired into the React frontend, Android secure vault, or Render service. Existing Supabase Auth is still the live identity system. Student admission-number/surname first-login, invitation/activation, password reset/change, session/device management, permission overrides, audit events, global edge abuse controls, and all school feature endpoints remain to be implemented and reviewed. Never copy Supabase password hashes or expose MySQL credentials to clients. Production database/runtime configuration and TLS must be explicitly provisioned before any deployment. Migrations 001–007 and the API are draft-only; no production change or cutover has occurred.

Exact-head validation for this increment is pending on code-bearing commit `f25eb89d4ed2d2fda8c92ec4c9028d4c7b4ddb4e`:
- MySQL schema workflow #427: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034221642
- SchoolPro CI #1617: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034221522
- Payment-page validation #1344: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034221613


## MySQL API runtime-test gate — 2026-10-17

Added `server/mysql-api/test/server.test.mjs` and a dedicated Node 22 `mysql-api-test` job to SchoolPro CI. The tests use a mocked MySQL pool and synthetic identities; they do not connect to production. Current coverage:
- Web login normalizes email and returns an opaque HttpOnly/SameSite=Lax session cookie, not a bearer token in JSON.
- `/v1/me` resolves an authenticated session.
- School context allows an active own-school membership and hides a foreign school with 404.
- Cross-origin login is rejected before credentials are processed.
- Failed login returns a generic error and stores only a SHA-256-shaped identifier key in the mock throttling state.

This is an initial contract test slice, not a full authentication acceptance suite. Still needed: session expiry/revocation tests, platform Super Admin access tests, inactive/suspended membership behavior, concurrent failed-login counter behavior, rate-limit threshold/reset tests, malformed/oversized body handling, CSRF/origin behavior for cookie-authenticated mutations, and API-backed role-by-role endpoint authorization. Migration 007 schema support is not a replacement for these behaviors.

The test job is newly wired and awaits exact-head CI. Keep the MySQL API disconnected from production and do not switch SchoolPro away from Supabase until A/B/C acceptance, data reconciliation, backup/restore, and explicit cutover approval.


### MySQL API production TLS guard — 2026-10-17

The MySQL API pool now refuses to start in `NODE_ENV=production` unless `MYSQL_SSL=true`, and uses certificate verification (`rejectUnauthorized: true`) when TLS is enabled. This prevents accidentally deploying the new database API with plaintext MySQL transport. It remains unconnected to the live frontend and undeployed. Latest API code head: `1ab8dd093d83ff520098da6e6e67e27d87c0200c`; new exact-head CI is required because this security guard changed the code.


### MySQL API CI harness correction — 2026-10-17

The first new `mysql-api-test` job failed because it ran the existing `server/mysql-api/test/api.test.mjs` integration suite without a MySQL service (`ECONNREFUSED 127.0.0.1:3306`). The four new mock-pool tests themselves passed; the existing integration test legitimately requires disposable MySQL and synthetic owner/school fixtures. Updated the job to start MySQL 8.4, apply migration 001 and migration 007, insert the core synthetic tenant fixture, then run the API test suite. No production connection is configured.

The first install command also pinned `mysql2@3.15.3` despite the API package declaring a semver range; the workflow now resolves the declared dependency instead of forcing that older exact version. CI reported one high-severity npm audit finding during the pinned install; re-run dependency resolution and review the current resolved dependency audit before treating the runtime as security-accepted.

This is a CI harness correction, not yet a pass. The latest workflow change is commit `26e3ec065425cfbbfe07492b3ff20b4c0d0b2b2d`; fresh exact-head SchoolPro CI, MySQL schema, and payment-page validation results are required.


### Stage A CI #1596 final result — 2026-10-17

Stage A CI #1596 completed with 7 jobs passing and `tenant-acceptance` failing: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033727021. Receipt Storage isolation, tenant-integrity DB integration, payment-review RLS integration, result-PIN rate limiting, public-admission abuse controls, result-verification exposure checks and general validation passed. The read-only live two-school acceptance probe failed after three retries on `schoolpro_result_approvals` with `canceling statement due to statement timeout`. Earlier checks in the same run did confirm foreign-school result-approval reads were blocked, own-school academic-period RPC was allowed, and foreign-school RPC was denied; nevertheless, the repeated timeout means full acceptance is incomplete.

Do not label this a tenant leak or a pass. The six-index migration includes `schoolpro_result_approvals(school_id)`, but it has not been applied to production. The next safe gate is explicit approval for the production index migration (or a reviewed isolated production-like rehearsal), followed by read-only catalog verification and a repeat of the authenticated two-school probe. No production changes were made.


### MySQL migration 007 and API tests — corrected harness passes — 2026-10-17

On code-bearing commit `26e3ec065425cfbbfe07492b3ff20b4c0d0b2b2d`:
- MySQL schema workflow #435 passed, applying migrations 001–007 and their synthetic fixtures/negative assertions: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034411770
- Payment-page validation #1352 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034411749
- New `mysql-api-test` job passed all 5 tests, including the existing disposable-MySQL integration test and four mocked contract tests: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034411801

The API job initially failed because the MySQL service was absent. It now starts a disposable MySQL 8.4 service, applies migrations 001 and 007, loads synthetic core tenant fixtures, and runs the tests under Node 22. The earlier fixed `mysql2@3.15.3` install logged a high-severity audit finding; removing that exact-version pin and resolving the declared package range produced a successful test run with no audit warning in the observed log. This is not a formal full dependency audit; run `npm audit` on a lockfile-pinned dependency tree before release.

SchoolPro's main `validate` job #1625 was still running at the time of this note: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39034411801. Do not claim all CI green until it finishes. The migration remains schema/API-foundation work only; no production MySQL deployment or Supabase cutover has occurred.


## MySQL API session lifecycle contract tests — 2026-10-17

Extended `server/mysql-api/test/server.test.mjs` with two focused runtime contracts:
- Browser logout revokes the server-side session and returns a cookie-clearing header; a follow-up `/v1/me` request with the formerly valid cookie must return 401.
- Native login returns an opaque bearer token without a browser `Set-Cookie` header, and that token authenticates `/v1/me`.

The mock pool now tracks revoked session state so the logout test checks subsequent authentication behavior rather than only response formatting. These are mock-pool API contract tests, not a replacement for disposable-MySQL session-revocation integration or mobile secure-vault integration. Exact-head MySQL schema/API tests, SchoolPro CI and payment validation are required before acceptance. No production change or deployment.


### MySQL API tenant-role boundary tests — 2026-10-17

Added two more isolated API contract tests in `server/mysql-api/test/server.test.mjs`:
- A platform Super Admin can inspect either synthetic school through the platform role path even when the fixture has no active school membership.
- A user whose only school membership is suspended receives the same not-found response for that tenant as a user with no active membership.

The fixture now supports explicit platform-role and membership-status variants. These tests check the API's role-branching logic with a mock pool; they do not establish that the deployed production role catalog is migrated or that every data endpoint enforces the same boundary. Exact-head SchoolPro CI, MySQL schema workflow, and payment validation are required. PR #107 remains draft/unmerged; no production migration or deployment.


### MySQL API production fail-closed configuration tests — 2026-10-17

Added configuration contract tests confirming:
- Production API construction fails if `WEB_ORIGIN` is not explicitly configured.
- Production MySQL pool construction fails if `MYSQL_SSL=true` is absent, preserving the verified-TLS requirement.

These tests exercise fail-closed configuration branches without connecting to a production host. They do not verify a live TLS handshake, certificate rotation, secret provisioning, or deployment environment. Exact-head CI is pending; no production configuration was changed.


## MySQL student portal authentication foundation — 2026-10-17

Added draft migration `database/mysql/008_schoolpro_student_credentials_sessions.sql` with a separate `student_credentials` table and opaque `student_sessions` table. Student identity remains linked to the school-scoped student row using composite foreign keys. The schema records a server-generated password hash, initial-password-change requirement, credential status, and revocable/expiring sessions. The roster/bootstrap service must hash the student's surname before storage; plaintext surnames/passcodes must never be written as credentials.

Added a synthetic MySQL fixture and a negative cross-school credential FK test, then wired migration 008 and its fixture into disposable MySQL 8.4 CI. Removed the duplicate migration-007 apply step from that workflow while wiring migration 008.

Added server API endpoints:
- `POST /v1/student/auth/login`: school code + admission number + password; checks active school, active student and active credential; uses the shared hashed-identifier throttle; issues a separate student cookie or native bearer token.
- `GET /v1/student/me`: resolves the student session and reports `mustChangePassword`.
- `POST /v1/student/password`: verifies the current password and requires a new password of at least 12 characters, then stores a scrypt hash and clears the initial-change flag.
- `POST /v1/student/auth/logout`: revokes the student session and clears the separate student cookie.

Added mock-pool API tests for student admission login, separate student cookie namespace, mandatory password-change state and rejection of the old initial password after a change. These are starter contracts only. Remaining hardening: atomic/locked password-change transaction, revoke other sessions on password change, login abuse tests against disposable MySQL, account provisioning that hashes surname at roster import, native secure-vault integration, student authorization for future data endpoints, and explicit integration tests for inactive/locked students and schools. Migration 008 and routes are draft-only, not deployed, and no production data was changed. Exact-head schema/API CI, SchoolPro CI and payment validation are required before acceptance.


### Student authentication upgraded to disposable-MySQL integration coverage — 2026-10-17

Added a real MySQL-backed API integration test in `server/mysql-api/test/api.test.mjs`. It sets a synthetic student's initial surname password as a server-generated scrypt hash, then verifies:
- School-code + admission-number login succeeds and issues a separate `schoolpro_student_session` cookie.
- The persisted student session stores only SHA-256 of the opaque token.
- `/v1/student/me` reports the initial password-change requirement.
- A short new password is rejected.
- A strong password change clears the requirement; the old surname password is rejected and the new password succeeds.
- Student logout revokes the session and subsequent `/v1/student/me` returns 401.

Updated `.github/workflows/ci.yml` to apply migration 008 and the synthetic student credential fixture in the disposable MySQL 8.4 API job. This supplements the mock-pool tests with actual MySQL persistence and relational behavior. Exact-head CI/schema/payment validation is pending for this increment. Remaining student-auth security work: make password update + session invalidation transactional, revoke other student sessions on password change, enforce forced-change gate on all future student data routes, and test locked/inactive student/school states against MySQL. No production migration, deployment or cutover.


### Student password-change transaction hardening — 2026-10-17

Changed `POST /v1/student/password` to run inside a MySQL transaction: it locks the active credential row with `SELECT ... FOR UPDATE`, verifies the current password while holding the lock, updates the scrypt hash and initial-change state, revokes other active sessions for the same student while preserving the current session, then commits. Invalid current passwords roll back without changing credentials; exceptions roll back and release the connection.

Added an assertion to the disposable-MySQL API integration test that the seeded second student session is revoked after a password change. The mock-pool transaction harness was extended to model credential update and sibling-session revocation. Exact-head MySQL schema/API tests, SchoolPro CI and payment validation are pending; no production deployment or cutover.


### Student-auth MySQL CI failure diagnosis and fixture correction — 2026-10-17

Exact-head schema run #463 exposed a genuine disposable-MySQL integration-test fixture issue in the student admission login test, not a production incident. The test expected `POST /v1/student/auth/login` to return 200 for initial password `One`, but the seeded scrypt hash did not correspond to that password, so the route correctly rejected the login. Recomputed the expected scrypt hash using the same parameters declared by the API (`N=16384, r=8, p=1, dklen=64`) and the fixture's fixed test salt, then updated only the synthetic fixture. This makes the fixture's stated initial password and stored hash consistent. The corrected schema/API workflow must pass before the change is accepted.

- Latest failed schema workflow at diagnosis: #463, run https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39035405442.
- Payment-page validation on the same code head passed: #1376, https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39035405408.
- SchoolPro CI was still running when that failure was first inspected; it is not counted as green until its final result is checked.
- Prior cross-school assignment test assertion was also corrected to expect the actual MySQL constraint name `fk_submission_student`; do not treat the earlier failed schema run as acceptance.
- No production migration, credential, data or deployment was changed.


### Corrected root cause: MySQL schema workflow fixture ordering — 2026-10-17

Follow-up investigation of schema run #465 found the primary reason the student admission login integration test returned 401: the workflow ran `npm test --prefix server/mysql-api` **before** inserting `schoolpro_student_credentials_fixture.sql`. The API test's `before()` setup attempted to update the synthetic credential row before it existed, so no credential was available for login. This is a workflow ordering defect; the hash correction alone could not fix it.

Moved both the synthetic login-throttling fixture and student credential/session fixture before the MySQL API test step. This makes the test database setup deterministic and ensures the test's `before()` hash update affects an existing credential row. The fixture's static scrypt hash for `One` was also made mathematically correct, but the test setup regenerates the password hash with the API's own `hashPassword` helper.

- Workflow correction commit: `93060c0a929ec2eff8873b80f8f00b43320f344a`.
- Corrected schema/API workflow, SchoolPro CI and payment-page validation must be checked on the new code-bearing commit. Previous failed run #465 is not acceptance evidence.
- No production database, credential, or deployment was changed.


### MySQL schema/auth fixture-order correction validated — 2026-10-17

The corrected workflow commit `93060c0a929ec2eff8873b80f8f00b43320f344a` has now passed the disposable MySQL 8.4 schema/API workflow:
- MySQL schema draft run #468 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39035805926
- The `mysql-api-test` job in SchoolPro CI #1652 passed, including the real-MySQL student authentication/session integration tests: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39035805864
- Payment-page validation #1379 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39035805877
- At handover update time, SchoolPro CI's separate `validate` job was still running; therefore overall CI was not yet recorded as green.

This confirms the student credential fixture ordering correction resolved the observed login-test failure. The migration/schema workflow now applies migrations 001–008, inserts the required synthetic fixtures before API tests, then exercises cross-school relationship constraints. This remains disposable CI only; migrations 001–008 have not been applied to production, and the MySQL application cutover is not approved.


### Production catalog read-only reconciliation — Stage A remains blocked — 2026-10-17

Read-only catalog inspection of Supabase project `lnqsroyiybutkfngbyge` confirmed all eight targeted operational tables have RLS enabled but **FORCE ROW LEVEL SECURITY is false**. The following tables have no tenant-leading `school_id` index: `schoolpro_library_books`, `schoolpro_transport_routes`, `schoolpro_hostel_rooms`, `schoolpro_inventory_assets`, and `schoolpro_result_approvals`; `schoolpro_promotions` has only its primary key and student/session unique index. `schoolpro_calendar_events` and `schoolpro_lesson_notes` have other non-tenant-leading indexes, but not the proposed general `school_id` index. This catalog evidence matches the read-only two-school acceptance failure: all prior table probes passed until `schoolpro_result_approvals`, where the request timed out three times.

The draft forward repair is correctly separated into:
1. `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` — enables and forces RLS on the eight target tables while preserving existing feature-specific policies;
2. `20261017180000_schoolpro_operational_tenant_indexes.sql` — adds six tenant-leading indexes to support RLS query plans;
3. `20261016160000_schoolpro_repair_operational_tenant_integrity.sql` — adds relationship/immutable-tenant trigger guards.

The live migration ledger still ends at `20261015161735`; none of these proposed repairs is recorded as applied. No production DDL was executed. Stage A is **not accepted**: CI #1596 has a real timeout in the live two-school probe on `schoolpro_result_approvals`, despite the other Stage A security jobs passing. A forward-only migration rehearsal, table-owner/BYPASSRLS/SECURITY DEFINER role tests, post-migration catalog reconciliation and a successful authenticated two-school probe remain required. Production application is still pending explicit approval and a controlled rollout window; do not infer success from source tests alone.


### Stage A targeted FORCE RLS owner-role test added — 2026-10-17

Expanded `scripts/test-schoolpro-operational-tenant-integrity.integration.sql` on the Stage A branch to test a non-superuser, non-`BYPASSRLS` table-owner role. The integration test transfers ownership of the eight operational target tables to a disposable `schoolpro_test_table_owner` role, confirms that role cannot read tenant rows without an applicable policy, and fails if FORCE RLS is bypassed. This supplements the existing authenticated two-tenant visibility checks, policy-preservation assertions, cross-tenant trigger rejection tests, and six-index assertions. This matters because production catalog inspection showed the current table owner is `postgres` with `rolbypassrls=true`; PostgreSQL's FORCE RLS does not constrain superusers or BYPASSRLS roles. The test is designed to verify the separate non-bypass owner case rather than misrepresenting FORCE RLS as a barrier against privileged service credentials.

The new Stage A integration test is committed on `release/stage-a-auth-tenant-isolation` at `077d7999f61fd70bdaa4da10a0d90a6c344725d7`. Exact-head CI is pending. No production DDL was run; the production operational RLS/index gap remains unresolved until the reviewed forward-only migrations are approved and applied, then catalog and live two-school acceptance are rerun.


### MySQL migration set 001–008 exact-head validation fully green — 2026-10-17

The exact branch-head run set for the MySQL migration foundation is now fully green on the code-bearing state preceding this handover-only update:
- MySQL schema draft #470 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39035911530
- SchoolPro CI #1654 passed, including both `validate` and `mysql-api-test`: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39035911512
- Payment-page validation #1381 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39035911515

The MySQL API test confirms the synthetic credential fixture is seeded before API tests and student auth/session/password-change checks pass against disposable MySQL. The schema workflow applies migrations 001–008, seeds synthetic records, validates cross-school foreign-key rejection for the covered relations, and runs the API integration suite. This is CI evidence only—not production parity or cutover acceptance. Application modules beyond the current API skeleton still need implementation and role/service-level authorization tests. No production DDL or deployment was performed.


### Stage A live policy/scale diagnosis and role-test result — 2026-10-17

Additional read-only production inspection established why the live tenant acceptance can be slow and why the proposed index is relevant:
- `schoolpro_result_approvals` has approximately 33,603 rows and about 9.7 MiB total relation size in current PostgreSQL statistics, but no `school_id`-leading index. Its current policies invoke `private.schoolpro_module_allowed(school_id, 'results')`; the SELECT policy also invokes `private.has_school_access(school_id)`. The live acceptance probe passed for School A but repeatedly timed out when probing this table for School B. These are approximate planner statistics, not an exact row count.
- Production catalog confirms the eight operational tables have RLS enabled and FORCE RLS disabled. The table owner is `postgres` with `rolbypassrls=true`; PostgreSQL FORCE RLS does not constrain BYPASSRLS roles. This is explicitly documented in the forward migration and must not be described as protection against privileged service credentials.
- The Stage A disposable PostgreSQL integration job passed the forward RLS repair, six tenant-index assertions, authenticated tenant-row scoping, cross-tenant trigger guards, and the newly added non-`BYPASSRLS` table-owner test: run #1656 tenant-integrity job logs show `PASS: FORCE RLS blocks a non-BYPASSRLS table owner from reading tenant rows without an applicable policy.`
- The live two-school acceptance still failed on the School B `schoolpro_result_approvals` probe after three statement-timeout attempts. The other Stage A jobs passed, but this prevents Stage A acceptance. A passing disposable test cannot substitute for live catalog/application evidence.

No production DDL was executed. The forward RLS and six-index migrations remain unapplied proposals. Once explicitly approved for a controlled rollout, apply the reviewed migrations in the approved order, re-read the catalog and policy definitions, then rerun the live two-school acceptance. If the index alone does not remove the timeout, inspect the query plan and policy helper cost before claiming closure; do not weaken or skip the negative tenant probe.


### Stage A query-plan evidence strengthens the timeout diagnosis — 2026-10-17

Ran read-only `EXPLAIN (COSTS, VERBOSE, SETTINGS)` as the ordinary `authenticated` role against `schoolpro_result_approvals`. The current production plan is a sequential scan with estimated cost approximately `0.00..2456622.25` and 8,712 estimated qualifying rows. The filter combines the tenant predicate with `private.schoolpro_module_allowed(school_id, 'results')`, `private.has_school_access(school_id)`, `schoolpro_member_can_manage(school_id)`, and a membership subplan. The membership subplan itself estimates a small scan; the dominant risk is evaluating the policy/helper expression over many rows without a tenant-leading index.

This confirms the six-index migration is a justified performance prerequisite, but **it is not yet proof that the live timeout will be resolved**. The query plan was captured before applying any index and no `EXPLAIN ANALYZE` or data-changing query was run. After approved rollout, re-run `EXPLAIN` and the live acceptance probe. If the indexed plan still times out, review the repeated row-dependent helper evaluation and consider a carefully equivalent policy optimization with role-parity tests; do not weaken access rules or skip the result-approvals probe.


### Stage A controlled rollout sequence prepared — 2026-10-17

Given the production query plan and existing live policy semantics, the proposed controlled sequence is:
1. Apply `20261017180000_schoolpro_operational_tenant_indexes.sql` first, to create the six tenant-leading indexes, including the missing index on the 33k-row `schoolpro_result_approvals` table.
2. Reconcile the index catalog and capture a fresh read-only `EXPLAIN` plan for the same authenticated query.
3. Apply `20261017170000_schoolpro_forward_operational_tenant_isolation.sql` to enable and force RLS on the eight reviewed operational tables without dropping/replacing their existing policies.
4. Apply `20261016160000_schoolpro_repair_operational_tenant_integrity.sql` to enforce same-school references and immutable tenant ownership.
5. Re-read the migration ledger, RLS flags, index definitions, trigger definitions, and policy names; run the two-school acceptance suite and all Stage A CI jobs against the resulting live catalog.

This order is a proposed runbook, not an execution record. All three migrations remain unapplied in production. Because the table owner `postgres` has `BYPASSRLS`, FORCE RLS is defense in depth for non-bypass table owners, not a replacement for the authenticated policies or a constraint on privileged service credentials. If the live query still times out after indexes, stop and optimize the exact policy/helper path with role-equivalence tests before accepting Stage A.

### Continuation checkpoint — 2026-10-17 (session resumed)

This entry preserves the current stopping point; it does not mark any blocked gate as complete.

**Stage A production security acceptance**
- **Status: BLOCKED / awaiting explicit owner authorization for production DDL.** The latest documented live authenticated two-school probe timed out on `schoolpro_result_approvals`; the pre-change authenticated query plan was a sequential scan with estimated cost approximately `0.00..2456622.25`.
- Production catalog evidence in this handover shows the eight targeted operational tables have RLS enabled but FORCE RLS disabled; six tenant-leading indexes are proposed, not applied. The live table owner `postgres` has `rolbypassrls=true`, so FORCE RLS is not a control against superuser/BYPASSRLS access.
- The reviewed forward-only repair remains a proposal: (1) six tenant-leading indexes, (2) FORCE RLS posture on the eight reviewed tables while preserving existing policies, and (3) same-school relationship/immutable-tenant trigger guards. The previously recorded rollout sequence is operational guidance only; reconcile the migration files, live catalog and ledger before execution.
- Do not run the production migrations, change policies, or report Stage A accepted without explicit authorization. After authorized execution, capture the resulting catalog/ledger, inspect the new authenticated query plan, rerun the complete two-school test (including the result-approvals table), and require exact-head CI. If the probe still times out, stop and investigate equivalent policy/helper optimization rather than weakening or skipping tenant checks.

**MySQL foundation / PR #107**
- The documented exact-head validation for migrations 001–008 passed disposable MySQL 8.4 schema/API workflow #470, SchoolPro CI #1654, and payment-page validation #1381 on the code-bearing state then tested. Those runs prove only the listed draft schema/API test scope; they do not establish complete feature parity, production migration, or cutover readiness.
- MySQL migration PR #107 remains draft and unmerged. The application is not fully migrated to MySQL: production SchoolPro remains on Supabase and Render, with no production database changes, environment changes, deployment, live-data copy, or cutover performed.
- Continue by refreshing PR #106/#107 heads and exact-head CI before changing code. Keep Stage A release-branch evidence separate from migration-branch evidence. Do not reuse earlier run numbers as current status without checking them.
- The initial MySQL foundation remains incomplete for full application parity, including authorization coverage across every data endpoint, operational workflows, result/template modules, payment/subscription flows, storage/file handling, jobs/webhooks, migration reconciliation, performance, backup/restore and rollback rehearsal.

**Next actions**
1. Refresh the current PR heads and workflow outcomes for Stage A PR #106 and MySQL PR #107; record exact commit SHAs and links.
2. Complete the Stage A migration-source review against live schema, policies, role semantics, trigger definitions and migration ledger before any production execution.
3. Obtain explicit owner authorization for the narrowly scoped three-migration production rollout. Until then, keep production read-only.
4. After the security blocker is resolved and A/B/C are re-verified, continue MySQL parity work without treating the pilot as a cutover.
5. Keep this handover append-only for material evidence and update status claims only when supported by exact artifacts.

**Safety statement:** No production DDL, production data writes, Render deployment, environment-variable changes, PR merge, or MySQL cutover was performed as part of this continuation checkpoint.


### Authorized Stage A rollout preflight — STOPPED before production changes (2026-10-17)

**Authorization:** The project owner explicitly authorized the reviewed three-migration Stage A production rollout, conditional on checking exact source contents, live schema and migration ledger, rollback implications, and current CI, and stopping on any material discrepancy.

**Outcome: NO MIGRATION EXECUTED.** The authorization was honored, but the preflight found blockers that fail the owner's stop condition. No production DDL, data writes, policy changes, deployments, environment changes, merges, or cutover were performed.

#### Exact-head CI status checked

- Stage A security commit checked: `eeac24a9e1820272ef673f59afd053a81408f193`.
- SchoolPro CI #1596 failed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033727021. The documented `tenant-acceptance` job exhausted retries and timed out on the authenticated `schoolpro_result_approvals` probe. This is a live acceptance blocker, not a pass.
- Payment-page validation #1323 passed: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39033727069. This does not override the failed tenant-acceptance gate.
- The separate migration-branch handover commit `fe0346c39a104fc1c4172a95d305dd1b682765fb` has green documentation-triggered runs: SchoolPro CI #1662 (including `mysql-api-test` and `validate`) https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39036911633; MySQL schema draft #477 https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39036911606; payment-page validation #1389 https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/39036911676. These test the MySQL migration branch's draft scope and do **not** constitute Stage A production acceptance or prove the Stage A migration set is ready.

#### Read-only production catalog and ledger review

- All six index-target tables exist: `schoolpro_library_books`, `schoolpro_transport_routes`, `schoolpro_hostel_rooms`, `schoolpro_inventory_assets`, `schoolpro_result_approvals`, and `schoolpro_promotions`.
- None currently has a valid, ready index whose leading column is `school_id`, per the read-only catalog query. `schoolpro_result_approvals` is estimated at 33,603 rows; `schoolpro_promotions` at 1,160. The four remaining index targets are currently small.
- The eight RLS-target tables are present and RLS is enabled, but FORCE RLS is false on the sampled target tables. Their owner is `postgres`; it has `BYPASSRLS`, so FORCE RLS does not constrain that privileged owner or other bypass roles.
- Existing feature-specific policies are present, including the library family-read policy, calendar access policies, lesson-note author/leadership policies, and result-approval read/write policies. The RLS migration's stated policy-preservation approach is important; do not substitute the historical policy-replacing migration.
- The live migration ledger currently ends at version `20261015161735` in the sampled latest 15 entries; no `20261016%` or `20261017%` versions were returned. This supports that the three proposed migrations are not recorded as applied. Do not infer a clean ledger reconciliation from this alone; verify the full ledger/source parity immediately before any later execution.
- The previously observed owner `postgres` with `BYPASSRLS` and the unresolved live result-approval timeout remain explicit acceptance risks.

#### Exact migration source reviewed

- Index migration `20261017180000_schoolpro_operational_tenant_indexes.sql`, source blob `a0db0fa32de1ee1368cf4fc380cc56b36bcd4be6`: https://github.com/Hassan-625/IHLink-SchoolPro/blob/2aa67f6f4715e9e8653041a313bda4e4ea2e6ceb/supabase/migrations/20261017180000_schoolpro_operational_tenant_indexes.sql. It checks the six target tables and creates six ordinary (non-concurrent) indexes. The ordinary index builds can take table locks; schedule and monitor this impact, especially on `schoolpro_result_approvals`. No index was created during this preflight.
- RLS migration `20261017170000_schoolpro_forward_operational_tenant_isolation.sql`, source blob `8018c92bd1196ff9d85a05fec44fe608897768eb`: https://github.com/Hassan-625/IHLink-SchoolPro/blob/2aa67f6f4715e9e8653041a313bda4e4ea2e6ceb/supabase/migrations/20261017170000_schoolpro_forward_operational_tenant_isolation.sql. It enables and forces RLS on eight named tables and does not replace policies. No RLS flags were changed during this preflight.
- Integrity migration `20261016160000_schoolpro_repair_operational_tenant_integrity.sql`, source blob `5bcf64a155aee9a92fb2b6cbfcd3b6c3a634473a`: https://github.com/Hassan-625/IHLink-SchoolPro/blob/2aa67f6f4715e9e8653041a313bda4e4ea2e6ceb/supabase/migrations/20261016160000_schoolpro_repair_operational_tenant_integrity.sql. All 13 directly referenced core/operational tables were confirmed present, and `schoolpro_member_permissions` also exists. Static review flagged its final trigger declaration, `BEFORE INSERT OR UPDATE OF school_id, member_id`, for explicit PostgreSQL grammar/runtime validation in disposable CI before production; do not assume the migration is executable merely because some prior tenant-integrity assertions passed. The target guard functions do not yet exist in production, as expected for an unapplied migration. No functions or triggers were created.

#### Rollback and operational implications

- Indexes are individually removable, but dropping them would restore the known slow access path; ordinary index creation can hold locks while building. Prefer a reviewed lock/timeout plan and observe the production impact before proceeding.
- RLS posture can technically be reverted with `NO FORCE ROW LEVEL SECURITY` / `DISABLE ROW LEVEL SECURITY`, but doing so may reduce defense in depth. Treat rollback as an emergency, reviewed action only; preserve current policies and capture catalog state first.
- Trigger/function rollback requires exact object-name inventory and a tested rollback script. Removing tenant-integrity guards reopens cross-school reference and tenant-ownership mutation risks. The current migration uses `CREATE OR REPLACE FUNCTION` and drops/recreates named triggers, so pre-existing trigger definitions and ordering must be captured and compared before application.
- The three migrations have timestamp names whose lexical order differs from the authorized operational sequence. Apply only by explicit, reviewed per-migration order (indexes, then RLS posture, then integrity triggers), and verify the resulting ledger entries; never bulk-apply by filename order.

#### Required gates before retrying

1. Fix or conclusively validate the trigger-event syntax in a disposable PostgreSQL environment, then rerun the full migration application and operational tenant-integrity tests against the exact Stage A head.
2. Re-run Stage A CI and resolve the live `schoolpro_result_approvals` tenant-acceptance timeout; a passing payment workflow alone is insufficient.
3. Reconcile the full production migration ledger against the exact release branch and inspect the existing triggers/functions and trigger ordering before touching any object.
4. Prepare and rehearse per-migration rollback/lock handling. Re-run the read-only catalog snapshot immediately before execution.
5. Only after all gates pass, proceed in the owner's authorized order and stop immediately on unexpected catalog/ledger differences or a failed acceptance probe.

**Current decision:** Owner authorization is on record, but the conditional safety gate has not passed. Stage A remains blocked and the three migrations remain unapplied in production. Preserve the authorization for a future retry; do not ask the owner to authorize the same planned scope again unless the scope materially changes.

### Architecture decision proposal — SchoolPro PostgreSQL on Aiven, application on Render (2026-10-17)

**Owner's requested direction:** Stop spending effort on the draft MySQL migration and evaluate moving SchoolPro's existing PostgreSQL data from Supabase to Aiven PostgreSQL, while keeping the SchoolPro frontend and application/API hosted on Render. This is a SchoolPro-only decision; DataSub and its Supabase project remain untouched.

**Recommended direction: APPROVE AS THE TARGET ARCHITECTURE, but migrate only through a staged, verified cutover.** PostgreSQL-to-PostgreSQL avoids the ongoing MySQL schema/application translation work and preserves PostgreSQL features such as RLS, PL/pgSQL functions, triggers, UUIDs, and relational constraints. It does not automatically make the application portable away from Supabase.

#### Important service boundaries

- **Render:** host the website/frontend and backend/API. The backend should own database access and enforce authentication/authorization; do not expose Aiven credentials or a privileged database connection to browser/mobile clients.
- **Aiven PostgreSQL:** target for SchoolPro application data after schema/extension/role/RLS compatibility review and verified migration. The stated $5/month Developer plan and 8 GB storage are the owner's intended budget/plan, not independently verified here. Confirm the exact Aiven service plan, current data size, CPU/RAM, connection cap, backup/recovery features, network reachability, TLS and storage headroom in the console before committing to production.
- **Supabase:** source remains the production system until cutover acceptance. Determine which Supabase services SchoolPro currently uses. PostgreSQL dump/restore does not migrate Supabase Auth users/configuration, Storage objects/buckets/policies, Edge Functions, secrets, Realtime configuration, scheduled jobs, or dashboard settings as a complete working service.
- **DataSub:** out of scope. Do not change its Supabase project, database, secrets, deployment or data.
- **MySQL draft PR #107 and migrations 001–008:** pause further feature/schema work pending this pivot; keep the branch, draft PR, tests and documentation for audit/history. Do not merge or delete it until the PostgreSQL/Aiven replacement path is proven and the owner explicitly approves cleanup.

#### Required implementation discovery before coding/cutover

1. Inventory the production SchoolPro code for Supabase JS/client usage, direct REST/RPC calls, auth.uid() and Supabase role assumptions, Auth/admin APIs, Storage buckets and signed URLs, Edge Functions, Realtime, cron/jobs, webhooks and environment variables.
2. Verify Aiven's actual plan/cluster details and network connection from Render. Confirm supported PostgreSQL major version, required extensions, connection/TLS settings and database-size headroom.
3. Build a dedicated Aiven migration path using the existing PostgreSQL schema and source migrations. Reconcile source schema, full migration ledger, extensions, roles/grants, policies, functions, triggers, sequences and storage-related references. Do not assume a generic full-cluster dump can recreate Supabase-managed roles or platform services.
4. Choose explicitly whether to keep Supabase Auth/Storage temporarily or replace those dependencies. Keeping Supabase Auth while the application data moves to Aiven is possible only with an intentionally designed trust boundary and server-side authorization; database policies relying on Supabase JWT claims and auth.uid() must not be assumed to work unchanged on Aiven.
5. Restore into a separate empty Aiven database for rehearsal, compare schema and per-table row counts, validate constraints/indexes/sequences/RLS/functions/triggers, run tenant isolation and role tests, test results/publication, payment/subscription workflows, receipts/storage references, backup/restore and performance.
6. Use a rehearsed cutover plan: freeze writes for final snapshot or use a supported continuous migration only after verifying its prerequisites; take a source backup; run final reconciliation; change Render server-side secrets only after acceptance; smoke-test; keep a documented rollback to the source database. Never dual-write casually or let both databases accept independent production writes.
7. After Aiven target tests pass, return to Stage A security review against the actual target architecture. The current live Supabase timeout and proposed Supabase-specific migrations must not be blindly executed on Aiven or declared resolved merely because the provider changed.

#### Current status and guardrails

- No Aiven database has been provisioned or connected by this action.
- No source dump/restore, production database change, Render environment change, deployment, PR merge or cutover has been performed.
- Supabase remains the live SchoolPro source of truth. Do not disable it or change Render's production database URL until a verified rollback-capable cutover is explicitly approved.
- The previous Stage A production rollout remains unexecuted. Its Supabase-specific three-migration plan must be re-evaluated against the Aiven target rather than applied blindly.
- This architecture pivot supersedes continuing active development on the MySQL migration as the preferred path, but does not erase its audit trail or the unfinished SchoolPro feature-parity/security requirements. A/B/C acceptance and the later Result Design Studio/custom Excel work remain required.

**Next step:** read-only inventory of application Supabase dependencies and current source database footprint; then prepare the Aiven PostgreSQL rehearsal/cutover plan. Do not request credentials in chat; use Render/Aiven dashboards or approved secret-management controls.
