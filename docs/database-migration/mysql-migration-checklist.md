# SchoolPro MySQL Migration Checklist

This checklist is evidence-driven. Do not mark a box complete without an attached test result or reviewed artifact.

## A. Source inventory
- [ ] Export complete table/column inventory for SchoolPro tables only.
- [ ] Inventory primary keys, foreign keys, unique constraints, check constraints and indexes.
- [ ] Inventory views, triggers, functions/RPCs, scheduled jobs and Edge Functions used by SchoolPro.
- [ ] Map each frontend repository call to its source table/RPC/storage operation.
- [ ] Inventory all Storage buckets and prove object-level tenant ownership.
- [ ] Record row counts and source consistency checks for each table.
- [ ] Confirm source ID types, nullable fields, enum values, JSON usage, timestamps and delete semantics.

## B. MySQL target readiness
- [ ] Confirm host permits a production multi-tenant SaaS workload in writing.
- [ ] Confirm MySQL version, actual database quota, max packet, connection limits, execution timeout, backup/restore process and outbound access.
- [ ] Provision a separate development database and least-privilege app/migration accounts.
- [ ] Keep credentials only in environment secrets; never commit them.
- [ ] Execute schema migration 001 only against a disposable database.
- [ ] Confirm repeatable migration strategy, rollback/recreate process and CI validation.

## C. API and identity
- [ ] Create server-side API; browser/mobile must never connect directly to MySQL.
- [ ] Implement secure password hashing, login throttling, session expiry/revocation, reset flow and audit events.
- [ ] Define separate platform super-admin authorization and school membership authorization.
- [ ] Enforce school scope server-side on every query and object/file operation.
- [ ] Add automated deny tests for another tenant's IDs, guessed UUIDs, changed school IDs and storage paths.
- [ ] Ensure public result-checking and candidate workflows use scoped, expiring tokens and rate limits.

## D. Academic/results parity
- [ ] Verify session/term/class roster selection and persistence.
- [ ] Verify each assessment component can be entered and saved independently.
- [ ] Verify score bounds, rounding, total calculations, grades and remarks against fixed fixtures.
- [ ] Verify class subject averages are calculated once and use the correct denominator.
- [ ] Verify class coordinator edits before publication and correction request after publication.
- [ ] Verify exam officer review/manage and publication permissions.
- [ ] Verify result lifecycle history is preserved.
- [ ] Verify A4 print output, PDFs, Excel exports and custom workbook mapping.
- [ ] Verify Nursery, Primary, JSS and SSS templates remain school-owned and isolated.

## E. Finance and other modules
- [ ] Verify fee invoices, payments, receipts, allocation and audit history.
- [ ] Verify subscription demo/annual/grace/suspension behavior.
- [ ] Verify SchoolPro subscription receipt upload and IHLink admin verification.
- [ ] Verify school-fee receipt workflow and role permissions.
- [ ] Ensure BillStack is used only for DataSub.
- [ ] Inventory and test admissions, CBT, assignment submissions, attendance, lesson notes, library, transport, hostel, inventory, payroll, discipline, health, notifications and email queues before declaring feature parity.

## F. Migration rehearsal and performance
- [ ] Use synthetic or approved anonymized fixture data in test only.
- [ ] Generate deterministic source-to-target ID mapping.
- [ ] Reconcile counts, duplicate keys, orphan checks and key aggregates.
- [ ] Compare result calculations and generated reports byte/field-wise where practical.
- [ ] Benchmark equivalent query workloads and record p50/p95/p99 latency and error rates.
- [ ] Run explain plans and tune only based on observed query plans.
- [ ] Test concurrent score entry, publication and payment updates for transaction safety.
- [ ] Restore a backup into a clean test database and verify integrity.

## G. Cutover gate (not authorized by this branch)
- [ ] All acceptance tests pass in CI and staging.
- [ ] Security review signs off on tenant isolation and API authorization.
- [ ] Performance and hosting-cost review signed off.
- [ ] Backup, restore and rollback drill passed.
- [ ] Cutover window, data freeze/delta strategy and rollback threshold agreed.
- [ ] Explicit user approval obtained.
- [ ] Supabase retained during agreed observation/rollback window.
- [ ] Supabase resources only retired after a separate explicit approval.
