# IHLink Master Database Migration Handover
**Last updated:** 2026-10-16  
**Status:** Audit and isolated schema-pilot stage — NOT approved for production cutover  
**Working PR:** https://github.com/Hassan-625/IHLink-SchoolPro/pull/107  
**Working branch:** `migration/mysql-schoolpro-foundation`  
**Source of truth:** live Supabase project `lnqsroyiybutkfngbyge` until each platform independently passes acceptance and the owner explicitly approves cutover.

## 1. Non-negotiable operating rules
- Preserve current application behaviour and repositories. No wholesale rewrite or PHP rewrite as a shortcut.
- Production remains unchanged during this work: no production schema/data edits, no environment-variable changes, no deployment, no migration of live records, and no PR merge without explicit approval.
- Keep Supabase authoritative. MySQL work must use disposable CI/local databases and synthetic fixtures until approved.
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
A recursive tree check was completed for the following 14 repositories. Each listed platform repository exposes a `src/lib/supabase.ts` file; its exact URL/project reference, runtime call sites, deployed URL and secret/config names still need to be extracted and compared before classifying it as fully inventoried.

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
