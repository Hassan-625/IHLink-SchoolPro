# SchoolPro MySQL schema gap audit
**Reviewed:** 2026-10-16  
**Branch:** `migration/mysql-schoolpro-foundation`  
**Status:** Inventory-based gap assessment; no production changes.

## Executive finding

The current MySQL migration is a **20-table foundation**, not a complete SchoolPro database migration. The only migration file surfaced in `database/mysql/` is `001_schoolpro_core.sql`. It explicitly describes itself as a core foundation. Existing disposable MySQL 8.4 CI validates schema creation and a set of cross-school foreign-key negative cases; those tests do not establish full application/API parity.

## Tables currently present in the draft

1. `schema_migrations`
2. `users`
3. `user_sessions`
4. `platform_roles`
5. `schools`
6. `school_memberships`
7. `school_member_permissions`
8. `academic_sessions`
9. `academic_terms`
10. `school_classes`
11. `students`
12. `student_enrollments`
13. `school_subjects`
14. `class_subject_assignments`
15. `assessment_components`
16. `result_records`
17. `result_scores`
18. `result_lifecycle_events`
19. `attendance_records`
20. `school_audit_events`

This list is based on the checked-in SQL, not on a claim that all relationships or behaviours are complete.

## High-priority schema and application gaps

| Domain | Current evidence | Work required before migration can be called complete |
|---|---|---|
| Identity and onboarding | Users, sessions, platform roles and school memberships exist as draft tables | Source auth configuration and call-site mapping; secure server-side API; invite/first-login/surname initial password/password-change/expiry/reset/lockout/session revocation; no portable-password assumption; super-admin separate from school membership |
| Academic structure | Sessions, terms, classes, students, enrollments, subjects and class-subject assignments exist | Map all live columns, constraints, class arms, academic history, roster/subject links and promotion/archive semantics; verify 2001–2002 through 2025–2026 plus 2026–2027 target sessions and tenant-specific population |
| Assessments and results | Components, result records, scores and lifecycle event table exist | Assessment schemes parity; independently save each assessment component; score bounds and calculations; grades/remarks/averages; approval/review/correction requests; publication locks and permissions; access PIN; transcript/broadsheet/report workflows; event atomicity and concurrency tests |
| Authorization | Membership and permission tables plus composite tenant FKs exist | MySQL has no automatic equivalent to source PostgreSQL RLS. Implement server-side authorization for every endpoint and file; explicit role matrix, source grant/policy inventory and negative runtime tests required |
| Templates and generated documents | No dedicated template/workbook/mapping/signatory/output tables surfaced in the 20-table SQL | School-owned Nursery/Primary/JSS/SSS templates, workbook upload and mapping, logos/signatories, output records, no cross-school/global overwrite, PDF/Excel/A4 parity |
| Finance and subscriptions | No invoice/payment/subscription/proof/review tables surfaced in the 20-table SQL | Invoices, allocations, school fee receipts/payments, subscription catalogue/status, annual demo and paid plan lifecycle, two-week grace/suspension, upload receipt + IHLink admin verification, audit and idempotency/concurrency controls |
| Guardians and parent access | No guardian/link tables surfaced in the 20-table SQL | Guardian identities, student links, status, parent permissions, fee receipt submission and published result/media access |
| Operations | Attendance only among the current 20 tables | Inventory and map assignments/submissions, CBT, admissions, lesson notes, timetable, library, transport, hostel, inventory, payroll, discipline, health, notifications, email queue and any other live feature confirmed by source inventory |
| Storage and media | No storage object metadata/path or signed-URL service surfaced in the draft core SQL | Inventory all buckets and policies; preserve object ownership/path rules, upload/download, signed URL expiry and tenant isolation; define migration/storage target separately |
| Database routines and side effects | No equivalent full target implementation is demonstrated by schema CI | Map all relevant live routines, trigger bindings/order, views, scheduled jobs, Edge Functions, webhook/retry semantics and transaction boundaries; implement and test target equivalents |
| Data transfer and reconciliation | Only synthetic disposable schema fixtures verified | Source/target counts, deterministic ID mapping, duplicate/orphan and cross-school checks, finance/result aggregate reconciliation, exclusions report, output comparisons and repeatable delta strategy |
| Operations and recovery | Target host not yet accepted for production | Verify exact MySQL version/limits, TLS, connection/runtime constraints, SaaS terms, backup retention/restore, monitoring, load/performance, rollback rehearsal and cost |

## Required sequencing

1. Continue the SchoolPro A security gates before merge: real-role payment RLS testing and trusted result-PIN network identity; no production writes.
2. Complete the source inventory and map each live table/object/call site to target table/API/policy/test.
3. Expand the schema and server-side API in small reviewed increments; add disposable MySQL integration tests for each domain.
4. Re-verify A authentication/tenant isolation, B academic sessions/students/rosters, and C assessment/calculation/review/publication before resuming D Result Design Studio/custom Excel.
5. Rehearse synthetic/anonymized data transfer, reconciliation, concurrency, performance, backup/restore and rollback.
6. Cut over only after all acceptance evidence and explicit owner approval. Keep Supabase authoritative and available for rollback until a separately approved retirement decision.

## Safety boundary

No production schema/data was changed; no live records were copied; no Render environment variable, deployment or production route was changed; no PR was merged. The MySQL branch and PR remain draft-only. SchoolPro production remains on Render and Supabase until the cutover gate passes. DataSub and other IHLink products are outside this SchoolPro-only MySQL scope; BillStack remains DataSub-only.
