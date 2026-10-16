# IHLink DataSub — source inventory for a future MySQL migration

**Status:** repository inspection only; no DataSub production/database changes.  
**Repository inspected:** `Hassan-625/IHLink-DataSub`, branch `main`.  
**Role in programme:** separate platform workstream; do not import DataSub tables into the SchoolPro database schema.

## Repository evidence

A recursive read-only tree inspection returned 326 tracked paths, including:
- 51 SQL migration files under `supabase/migrations/`.
- 11 named Supabase Edge Function folders (not counting the shared helper folder).
- Existing SQL audits/tests and application tests covering payment integrity, API callback security, wallet transactions, refunds, pricing, provider contracts and extra services.
- Frontend direct Supabase client entry point at `src/lib/supabase.ts`, customer transaction code at `src/lib/dataSubCustomerTransaction.ts`, wallet and transaction pages, access/permission hooks, and auth context.

This is a repository file inventory, not proof that every migration is applied to production or every function is deployed. Compare repository migration history with the live project's migration ledger and deployed Edge Functions before any migration.

## DataSub high-risk domains

1. **Identity and scoped access:** shared account profile/role semantics, platform entitlements and `customer_service_access`. Authentication alone must not grant DataSub access.
2. **Wallet funding and review:** funding intent, payment/virtual-account callback, review status and ledger movement. Keep every funding request idempotent and auditable.
3. **Purchases and provider fulfilment:** purchase request, reserved/debited balance, provider request, callback, final status, retry/reversal and customer receipt. Exactly-once external fulfilment cannot be assumed; use idempotency keys and reconciliation.
4. **Wallet transfers and reseller commission:** atomic debit/credit, immutable ledger entries, transfer limits, fee/commission accounting and concurrency-safe balance checks.
5. **Pricing/catalogue/provider routing:** server-authoritative prices, service visibility, provider plan mappings, routing decisions and provider credential isolation.
6. **Refunds and disputes:** explicit state machine, immutable compensating ledger entries, permission checks and provider/customer reconciliation.
7. **API access and callbacks:** credential hashing/rotation, rate limits, signature verification, replay protection, per-customer scope and audit trail.
8. **PIN and account security:** secure PIN storage/verification, lockout/throttling, recovery, session revocation and device-specific behavior.
9. **Scheduled reconciliation and health checks:** current scheduled jobs/cron configuration, provider health, missed callback recovery and alerting.
10. **File/receipt delivery:** object ownership, private delivery and expiring URLs; storage migration is independent of database migration.

## Identified Supabase Edge Functions

- `auth-handoff`
- `datasub-api`
- `datasub-api-callbacks`
- `datasub-catalog-sync`
- `datasub-pin-recovery`
- `datasub-provider-health`
- `datasub-provider-webhook`
- `datasub-purchase`
- `datasub-reconcile`
- `legitdataway-catalog-sync`
- `legitdataway-webhook`

Shared helpers include provider adapters and reconciliation/refund logic for CashSub, DataStation and LegitDataway. Their current behavior must be reviewed from source and tested against provider sandbox contracts before porting.

## Required migration mapping per function and domain

For each SQL migration, table, view, RPC, trigger, Edge Function and scheduled task record:
- current deployed version and callers;
- input/output and authorization requirements;
- transaction boundaries, lock order, idempotency key and retry behavior;
- money/currency precision and immutable ledger invariants;
- provider callback authenticity, replay prevention and failure handling;
- source-to-target reconciliation query and positive/negative automated tests;
- rollback and operational alerting behavior.

## Target design constraints

- Keep DataSub in its own database and API boundary unless evidence proves a shared central service is needed. A shared physical MySQL server is only acceptable if credentials, grants, backups, resource caps and blast radius remain suitably isolated.
- Use InnoDB transactions and explicit row locking for balance mutations; represent money with exact decimal/minor-unit semantics, never floating point.
- Use a durable idempotency record and unique constraint for top-ups, purchases, callbacks and provider request IDs. A repeated request must not debit twice.
- Never treat an external provider callback as trusted solely because it reaches the endpoint. Verify signature/secret, timestamp/replay, expected order, amount, currency and status transition.
- Keep a ledger that can reconstruct wallet balance and reconcile it against stored balance; do not rely only on a mutable balance column.
- Keep provider secrets server-side. Never expose MySQL credentials or privileged database keys to browser/mobile code.
- Preserve BillStack as DataSub-only. SchoolPro subscriptions remain receipt upload plus IHLink-admin verification; SchoolPro school fees remain under the school-side receipt workflow.
- No production dual writes, live data copy, secret copy or cutover during this audit.

## Acceptance gates before DataSub cutover

1. Reconcile source schema and applied migration ledger.
2. Export and map all RLS policies/grants, RPCs, triggers, functions, Edge Functions, cron jobs and Storage policies.
3. Prove atomic debit/credit, concurrent purchase safety, duplicate webhook handling, callback replay rejection, refund compensation and provider timeout/retry behavior.
4. Prove customer-to-customer and cross-platform data isolation.
5. Reconcile wallet balances against ledger history and payment/provider statements; explain every difference.
6. Test backups and restore, load/performance, observability and on-call recovery.
7. Obtain explicit approval for DataSub's own cutover after its acceptance criteria pass.

## Next action

Continue by comparing all 51 repository migrations and 11 Edge Function folders against the live Supabase project's applied migration ledger, deployed functions, relevant table/RLS metadata and scheduled jobs. Then build the DataSub source-to-target matrix before designing the DataSub MySQL schema. Do not use the SchoolPro core schema as the DataSub schema.


## Confirmed project reference and deployment documentation note

The DataSub repository's `src/lib/supabase.ts` hard-codes the shared public Supabase URL `https://lnqsroyiybutkfngbyge.supabase.co` as a fallback. This resolves to the same project reference used by the SchoolPro migration audit: `lnqsroyiybutkfngbyge`. The browser publishable key in that file is public client configuration, not a service-role secret.

The DataSub README currently describes deployment through Vercel. This is a repository documentation observation, not a deployment verification. Do not assume DataSub is on Render just because SchoolPro is; verify each platform's actual live deployment before making hosting changes. The shared database project is confirmed for DataSub and SchoolPro, but the other platform repositories still need the same project-reference audit.

## DataSub source-of-truth caution

The 51 checked-in SQL migrations and 11 named Edge Function folders are repository evidence only. Before migrating, retrieve the live project's applied migration ledger and deployed function list, then compare them to this repository. A source file existing in Git does not prove it is deployed, and a deployed object may be absent from the current repository branch.


## Live project comparison — read-only inspection on 2026-10-16

The DataSub fallback URL confirms it uses the same Supabase project reference as SchoolPro: `lnqsroyiybutkfngbyge`. The live project currently reports:
- 476 applied migrations across the shared ecosystem (latest: `20261015161735 schoolpro_access_invitation_role_constraint)).
- 41 ACTIVE Edge Functions across multiple platforms, not just DataSub.
- 49 public tables whose names start with `datasub_` in current table metadata; additional shared tables such as `profiles`, `customer_service_access`, `audit_logs` and finance/notification/security tables may be dependencies.
- The repository contains 51 DataSub-named or relevant migration files, but this number is not expected to equal the whole shared project's 476 migration ledger. Some repository migration filenames differ from the applied ledger versions/names, so a migration-by-migration comparison is required.

Deployed DataSub-related functions seen in the live project include `datasub-api` (v29), `datasub-purchase` (v38), `datasub-reconcile` (v23), `datasub-provider-health` (v38), `datasub-catalog-sync` (v19), `datasub-provider-webhook` (v12), `datasub-payment` (v13), `datasub-pin-recovery` (v1), `datasub-api-callbacks` (v1), `legitdataway-webhook` (v7), and `legitdataway-catalog-sync` (v2). Treat deployed function versions as source-audit targets; repository presence alone does not establish code parity with these deployed versions.
