# IHLink ecosystem database migration — target architecture and programme plan

**Status:** planning / audit only. No production cutover approved.  
**Owner scope:** IHLink ecosystem, with SchoolPro as the first migration pilot.  
**Current production authority:** existing Supabase project(s) and current platform deployments remain authoritative until each platform independently passes its acceptance gates.

## Executive decision

Coordinate the platforms under one migration programme, but do not blindly combine all platform data into one undifferentiated MySQL database. The earlier ecosystem design keeps platform repositories and deployments separate while sharing some Supabase services. Preserve that application separation.

The preferred target to evaluate is:
- One central identity/account service only if the existing identity model and account lifecycle genuinely require it.
- Platform-owned databases or strictly isolated database schemas/credentials for SchoolPro, DataSub and each other platform.
- Explicit, narrow service-to-service interfaces for shared customer identity, entitlement, billing or platform administration.
- A single MySQL server is an optional deployment topology, not an architectural assumption. Separate database instances may be necessary for operational isolation, high-risk wallet transactions, independent backups/restores, different workloads, or hosting-plan limits.
- Never let a browser or mobile app connect directly to MySQL. All database access goes through authenticated server APIs.

## Platforms to inventory

The initial inventory scope is the known IHLink platform family:
1. SchoolPro — school tenancy, identity/membership, academic sessions, students/enrollments, assessment/results lifecycle, templates/files, fees and annual subscriptions.
2. DataSub — wallets/ledger, catalogue/pricing, reseller/service access, transaction idempotency, provider routing/integration, reconciliation and BillStack funding/virtual-account workflows. BillStack remains DataSub-only.
3. Corporate — platform-specific customer/company records and services.
4. Hosting — hosting accounts, plans, provisioning and lifecycle.
5. Consult — consultations, bookings and related records.
6. Engineering — project/service records and delivery workflows.
7. Other IHLink platform repositories discovered during the audit, including Print & Branding, 3D Fabrication, AI & Compute and Academy where active Supabase dependencies exist.

This list is a starting inventory, not proof that every listed platform currently uses the same Supabase project or the same database. Resolve actual project references from each repository, deployment configuration and Supabase metadata before choosing topology. Do not copy an entire shared monorepo's `src` or `supabase` directories into a platform repository; extract only that platform's code and dependencies.

## Data ownership and isolation

| Domain | Proposed owner | Required boundary |
|---|---|---|
| Account identity and login | Shared identity service only if account sharing is confirmed | Authentication identity is not an automatic grant to any platform |
| Platform roles and entitlements | Central entitlement service or platform-owned grants, after mapping existing semantics | A global platform administrator is distinct from a school membership or DataSub customer role |
| School academic records | SchoolPro | Every read/write is scoped to the authenticated user's active school membership and permission |
| School fees and SchoolPro subscription receipts | SchoolPro / IHLink admin review workflow | Do not route SchoolPro payments through BillStack |
| DataSub wallet and transaction ledger | DataSub | Append-only/immutable ledger semantics, idempotency, transactional balance updates, provider reconciliation |
| DataSub provider integrations | DataSub | Credentials isolated to server runtime; no provider secret exposed to clients |
| Other platform records | Each platform's service/database | No cross-platform table access by default |
| Shared files | File service or platform-owned storage areas | Object-level authorization, tenant/platform path isolation, expiring downloads |

## Migration stages and gates

### Stage 0 — establish the source-of-truth map
- Identify every repository, production deployment, Supabase project reference, environment-variable name (never values/secrets), migrations, tables, views, routines/RPCs, triggers, RLS policies/grants, Edge Functions, scheduled jobs, Storage buckets/policies and client call sites.
- Classify every table as platform-owned, shared identity/entitlement, shared commercial, legacy or unclear.
- Capture exact row counts by stable snapshot/transaction where feasible, data types, constraints, sequences/identity generators, unique indexes, nullability and foreign-key dependencies.
- Map each source object to an API handler, target schema, test and reconciliation query.
- Do not infer that multiple repos mean multiple databases or that one Supabase ref means all deployments share identical authorization.

### Stage 1 — prove target-host suitability
Before selecting a provider, obtain written confirmation of supported MySQL version, actual database-size cap (distinct from webspace quota), concurrent connection limits, statement/query timeout, CPU/memory, scheduled job support, TLS, backups, point-in-time recovery, restore process, egress, and permission for a multi-tenant SaaS workload. Benchmark the actual host. Do not assume shared hosting is suitable for wallet or academic transaction workloads.

### Stage 2 — platform pilot in isolation
- SchoolPro is the first pilot; complete schema and authorization mapping and API parity tests.
- DataSub is a separate high-risk workstream, not an add-on to the SchoolPro schema. Design ledger correctness, idempotent top-ups/purchases, atomic debit/refund, provider callbacks, reconciliation and replay protection before moving data.
- Run disposable MySQL CI and isolated staging databases with synthetic/anonymized data only.
- Keep current Supabase reads/writes authoritative; do not dual-write production without an explicit consistency/reconciliation design.

### Stage 3 — shadow/rehearsal and acceptance
For each platform separately:
- Reconcile row counts and key aggregates; validate timestamps, decimals/currency, nulls, Unicode, IDs, constraints and orphan records.
- Test role/tenant boundaries positively and negatively.
- Test workflows, uploads/downloads, scheduled tasks, webhooks, payment/ledger behavior, result calculations and lifecycle transitions.
- Benchmark representative high-volume queries and concurrency on the actual candidate host.
- Exercise backup restore and rollback.
- Require zero unexplained reconciliation differences and documented approval before cutover.

### Stage 4 — controlled platform cutover
Cut over one platform at a time with an explicit maintenance/read-only window or proven replication/catch-up mechanism. Keep an exportable rollback point. Do not remove Supabase tables, auth or storage until each platform's cutover is stable and rollback window is closed. Record a separate approval for every platform.

## SchoolPro current evidence and gaps

- Draft PR: https://github.com/Hassan-625/IHLink-SchoolPro/pull/107
- Disposable MySQL 8.4 schema test: https://github.com/Hassan-625/IHLink-SchoolPro/actions/runs/38899334105
- That CI validates the draft schema and one cross-school enrollment rejection. It does not establish complete schema, API, RLS, data, storage or feature parity.
- Read-only source catalog inventory currently reports 107 `schoolpro_%` tables, 17 additional shared dependencies, 293 RLS policy rows, 358 trigger/event rows, and 212 routines matching a targeted name filter. Counts are catalog inventory signals; they are not a complete behavior map and must be rechecked during the export.
- Routine and trigger definitions, grants, view dependencies, storage access, scheduled jobs, Edge Functions, and frontend call sites remain to be mapped to their target behavior.
- No production Supabase schema/data, Render configuration or deployment was changed by this work.

## Explicit non-goals / safety rules

- Do not replace Supabase globally in one release.
- Do not migrate DataSub wallet/payment state using a generic table-copy script without ledger invariants and reconciliation.
- Do not share platform database credentials between unrelated APIs.
- Do not copy secrets, password hashes or live customer data into test fixtures.
- Do not disable RLS or assume MySQL foreign keys alone replace authorization.
- Do not merge PR #107 or deploy anything as part of this planning document.
- Preserve the existing SchoolPro acceptance gates: A authentication + tenant isolation; B academic sessions/student population/class rosters; C assessments/calculations/review/publication; D Result Design Studio + custom Excel workbooks.
