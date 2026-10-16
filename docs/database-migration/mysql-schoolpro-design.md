# SchoolPro MySQL Migration Design (Draft 0.1)

## Purpose and non-negotiable safeguards

This work creates a parallel MySQL design for **SchoolPro only**. The existing Render application and Supabase project remain authoritative until the migration is fully tested and an explicit production cutover is approved.

- Do not change production environment variables or routes in this phase.
- Do not write to, delete from, or migrate production records in this phase.
- Do not include DataSub, Academy, Hosting, Consult, Engineering, or other IHLink platform modules in the SchoolPro database.
- Never copy production passwords, access tokens, payment secrets, or private student/guardian data into development.
- New schools must not inherit IHLink Academy operational records or another tenant's data.
- Do not merge this branch or deploy it without review.

## Confirmed baseline from read-only inspection

- Supabase migration ledger: 476 recorded migrations; latest recorded migration is `20261015161735 schoolpro_access_invitation_role_constraint`.
- Frontend package uses `@supabase/supabase-js`; the current client therefore relies on Supabase APIs and must not be switched to MySQL directly from the browser.
- Current public-schema SchoolPro inventory includes (estimated live rows from database metadata):
  - schools: 2; members: 94; students: 1,214; classes: 33; subjects: 284
  - attendance: 208,800; results: 34,803; result approvals: 33,603
  - result lifecycle events: 168,018; assignment submissions: 27,440
  - result domain ratings: 55,680; lesson notes: 10,108; notifications: 11,035
  - fee invoices: 3,362; fee payments: 4,045; guardian links: 843
- Counts are a starting inventory only. They are not a migration manifest or a promise that every row is valid. Exact counts, relationships, nulls, duplicate keys and orphan rows must be rechecked in a migration rehearsal.

## Architecture target

Browser / Android client -> authenticated SchoolPro API -> MySQL 8.x (InnoDB).

The API is the sole application access path to MySQL. Do not expose MySQL credentials or direct database connectivity to the browser/mobile bundle. The API must:
1. Verify the user session/token.
2. Resolve platform-level super-admin status separately from school membership.
3. Resolve school membership and effective permissions on the server.
4. Derive the tenant scope from the verified identity and authorized route context; never trust a client-supplied `school_id` as proof of authorization.
5. Include tenant scope in reads and writes and validate object ownership for uploads/downloads.
6. Use parameterized SQL, bounded pagination, transaction boundaries and explicit authorization tests.
7. Write security-sensitive changes to append-only audit history.
8. Keep password hashing, login throttling, reset flows, session revocation and expiry on the server. Supabase Auth password hashes are not assumed portable; users may require a controlled account migration/reset strategy.

MySQL does not replace PostgreSQL RLS automatically. Moving authorization to the API changes the security boundary and requires deliberate negative tests for every endpoint and object family.

## Proposed logical domains

1. Identity and tenancy: users, sessions, platform roles, schools, memberships, member permissions, invitations.
2. Academic setup: academic sessions, terms, classes, class arms, students, guardians, student-guardian links, enrollments, subjects and subject assignments.
3. Assessment/results: assessment schemes/components, score entries, calculated result records, review/approval, publication events, corrections, result-access events.
4. Operations: attendance, assignments/submissions, timetable, lesson notes, announcements, CBT, admissions, library, transport, hostel, inventory, payroll, discipline and health records.
5. Documents: school-owned templates, workbook field mappings, branding, generated outputs, document issues and signatures.
6. Finance: fee structures/items, invoices, fee receipts/payments, allocations, exceptions, school bank details, subscription plans/status, subscription payment proofs and review audit.
7. Platform operations: notifications, email queue, security events, audit logs, access invitations and operational queues.

The first SQL migration intentionally implements only the core tenancy and academic/results foundation. It is not the complete application schema. Other domains are added after their current table definitions, RPC/trigger semantics and frontend use have been inventoried.

## Data model rules

- IDs use UUID-compatible `CHAR(36)` in the draft for portability. Confirm actual MySQL host/version and collation before applying.
- InnoDB foreign keys protect relational integrity. Composite unique keys and composite foreign keys are used where needed to prevent cross-school references.
- Each tenant-owned record has `school_id`; every query is additionally scoped by the API.
- Use UTC timestamps and preserve source timestamps during migration.
- Scores use fixed-precision decimals; do not use floating-point for score or money arithmetic.
- Use explicit audit/event records for state transitions; do not silently replace historical result lifecycle events.
- Avoid JSON as a substitute for relational columns when data is queried, constrained or joined frequently. Use JSON only for genuinely variable snapshots/configuration.
- Indexes are workload-driven and must be confirmed with representative EXPLAIN plans and benchmarks. Excess indexes add write and storage cost.
- Soft deletion/archival policy must be mapped from existing semantics before deciding any delete behavior.

## Migration stages and exit gates

### M0 — Inventory (current)
Record table columns, primary/foreign keys, unique constraints, indexes, row counts, triggers, functions/RPCs, RLS policies, Storage buckets/object ownership, scheduled jobs, Edge Functions and every frontend use of Supabase. No production writes.

### M1 — Schema and static validation
Review the draft SQL against a confirmed MySQL version. Run it only in a disposable local/test database. Validate FK ordering, constraint support, migration re-run behavior and rollback/recreate instructions. Do not point it at production.

### M2 — API and authorization
Build a separate API service and test all role and tenant boundaries before connecting the UI. Use automated positive and negative tests, including cross-school IDs and storage object paths.

### M3 — Data rehearsal
Export only approved, anonymized/synthetic fixtures. Create deterministic mapping and reconciliation reports. Never run destructive transformation against Supabase. Any eventual production rehearsal requires a separately approved, encrypted, access-controlled backup and a written rollback plan.

### M4 — Feature parity and performance
Test authentication, students, roster, assessments, calculations, result review/publication, correction history, template upload/mapping, PDF/Excel output, fees, subscription receipt review and other in-scope modules. Benchmark identical queries and representative concurrency on both systems.

### M5 — Shadow comparison
Read-only shadow comparisons on safe test fixtures. Compare row counts, aggregates, score calculations, report outputs, authorization decisions and latency. MySQL must not be allowed to mutate production records.

### M6 — Cutover decision
Cutover only after all gates pass, backups and restore are verified, monitoring is in place, and the user explicitly approves. Retain Supabase as rollback source for an agreed observation window. Supabase is not removed as part of this branch.

## Required acceptance evidence

- Schema creation succeeds on the target MySQL version in a disposable database.
- No orphan or cross-school relationships in the rehearsal dataset.
- Cross-tenant access tests fail closed for each endpoint and object family.
- Super-admin platform access and ordinary school-scoped roles are tested independently.
- Results, averages, approvals, publication and report-card output match the reference fixtures exactly.
- Migration reconciliation report lists source count, target count, exclusions and reason for each domain.
- P50/P95 latency and error rates recorded for a defined workload; no performance claim without measured evidence.
- Backup restore drill succeeds.
- CI runs lint, typecheck, API tests, authorization tests and schema migration tests.

## Known risks requiring explicit resolution

- Existing Supabase Auth identities and session semantics need a safe replacement plan.
- Supabase Storage paths, signed URLs, upload ownership and file access must be migrated or replaced separately; SQL migration alone is insufficient.
- The live project includes non-SchoolPro services. Scope filtering must be explicit.
- Smartweb advertised webspace must not be interpreted as a MySQL database quota. Confirm actual DB size, execution-time, backup and commercial multi-tenant SaaS terms in writing before choosing a host.
- The logged slow Storage/RLS path is a candidate for redesign, not proof that changing database engines alone will fix all slow queries.
