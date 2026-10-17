# SchoolPro source-to-MySQL table parity matrix — 2026-10-16

## Purpose and rules

This matrix compares the read-only source inventory of 107 `schoolpro_*` tables with the 20 tables currently present in `database/mysql/001_schoolpro_core.sql`. The MySQL draft intentionally uses normalized names, so an absent same-name table is **not** proof of missing functionality, and a candidate mapping is **not** proof of parity.

- No source rows or secrets are included.
- “Candidate mapping” means only a plausible conceptual relationship; definitions, keys, constraints, triggers, RLS policies, callers, retention and data cardinality must be compared before acceptance.
- “Unmapped” means no target equivalent has been accepted yet. Do not auto-create or drop tables solely from this matrix.
- Empty source tables remain in scope until feature and dependency evidence supports a disposition.
- Production remains Supabase; this is planning only.

## Current draft baseline

- Source tables inventoried: **107**
- Target MySQL tables in the draft: **20** (including migration metadata and normalized auth/tenant tables).
- Explicit conceptual candidate mappings listed below: **10**
- All other source tables remain **unmapped / requiring investigation**.
- Related catalog scan found 212 targeted routine names, 358 trigger event rows, and 293 RLS policy rows. These are catalog row counts, not counts of all routines or distinct triggers. See the source inventory for limitations.

## Table-by-table register

| Source table | Domain | Current draft candidate | Status / required check |
|---|---|---|---|
| `schoolpro_academic_documents` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_access_invitations` | Identity, tenant, access and audit | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_account_challenges` | Identity, tenant, access and audit | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_admission_acceptances` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_admission_documents` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_admission_events` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_admission_offers` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_admissions` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_announcements` | Teaching, attendance and timetable | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_assessment_schemes` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_assignment_submissions` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_assignments` | Teaching, attendance and timetable | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_attendance` | Teaching, attendance and timetable | `attendance_records` | candidate; compare uniqueness, attendance states and audit rules |
| `schoolpro_audit_logs` | Identity, tenant, access and audit | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_bank_accounts` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_board_members` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_branding` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_calendar_events` | Teaching, attendance and timetable | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_candidate_cbt_answers` | CBT and question bank | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_candidate_cbt_attempts` | CBT and question bank | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_cbt_answers` | CBT and question bank | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_cbt_attempts` | CBT and question bank | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_cbt_eligibility` | CBT and question bank | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_cbt_test_questions` | CBT and question bank | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_cbt_tests` | CBT and question bank | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_charge_categories` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_class_result_submissions` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_classes` | Academic records, results and progression | `school_classes` | candidate; compare class-level fields, ordering, levels and soft-delete |
| `schoolpro_custom_requests` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_demo_requests` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_discipline_records` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_document_issue_events` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_document_issues` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_document_templates` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_email_queue` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_enrollment_history` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_feature_overrides` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_fee_bank_accounts` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_fee_exceptions` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_fee_items` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_fee_payments` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_fee_records` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_fee_structures` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_finance_settings` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_generated_result_outputs` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_grade_scale` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_guardian_links` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_health_records` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_hostel_allocations` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_hostel_rooms` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_initial_credentials` | Identity, tenant, access and audit | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_inventory_assets` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_invoice_templates` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_invoices` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_leadership_settings` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_leave_requests` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_lesson_notes` | Teaching, attendance and timetable | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_library_books` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_library_loans` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_login_attempts` | Identity, tenant, access and audit | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_member_permissions` | Identity, tenant, access and audit | `school_member_permissions` | candidate; verify permission inheritance and deny semantics |
| `schoolpro_members` | Identity, tenant, access and audit | `school_memberships` | candidate; compare role/status/invitation fields and uniqueness |
| `schoolpro_module_records` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_notifications` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_onboarding_requests` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_payment_allocations` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_payment_intents` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_payment_proofs` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_payment_submissions` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_payroll_records` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_plan_catalog` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_portal_invites` | Identity, tenant, access and audit | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_promotions` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_question_bank` | CBT and question bank | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_access_events` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_access_overrides` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_access_pins` | Identity, tenant, access and audit | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_approvals` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_correction_requests` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_corrections` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_domain_definitions` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_domain_ratings` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_events` | Academic records, results and progression | `result_lifecycle_events` | candidate; compare event schema, actor and immutable audit semantics |
| `schoolpro_result_rating_scale` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_templates` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_term_settings` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_result_verifications` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_results` | Academic records, results and progression | `result_records` | candidate; compare result grain, status and publication workflow |
| `schoolpro_schools` | Identity, tenant, access and audit | `schools` | candidate; compare school identifiers, status lifecycle, and tenant constraints |
| `schoolpro_site_content` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_site_gallery` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_site_news` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_site_settings` | Admissions, documents and communications | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_student_activation_challenges` | Identity, tenant, access and audit | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_student_transport` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_students` | Academic records, results and progression | `students` | candidate; compare identity, admission number, credentials and sensitive fields |
| `schoolpro_subject_assignments` | Academic records, results and progression | `class_subject_assignments` | candidate; confirm whether source assignment grain includes teacher/session/class |
| `schoolpro_subjects` | Academic records, results and progression | `school_subjects` | candidate; compare subject codes, education level and lifecycle |
| `schoolpro_subscription_catalog` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_subscription_intents` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_subscription_payments` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_subscription_plans` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_subscriptions` | Fees, finance and subscriptions | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_timetable_entries` | Teaching, attendance and timetable | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_transcript_issues` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_transcript_settings` | Academic records, results and progression | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |
| `schoolpro_transport_routes` | Other school modules | — | Unmapped; inspect schema, constraints, RLS, trigger dependencies, callers, data lifecycle and retention before deciding target design |

## Shared platform dependencies

The separate inventory lists 17 shared tables, including `profiles`, platform audit/security events, payment provider configuration, virtual accounts, payment transactions, webhook events, and email queues. These must be handled through explicit integration boundaries. Do **not** absorb DataSub wallet/payment internals into SchoolPro's MySQL pilot. BillStack remains DataSub-only; SchoolPro subscription receipts and school fee payments retain their separate approval flows.

## Required acceptance record per table

Before a source table can be marked mapped, deferred, retired, or excluded, record:
1. Source DDL and column types/defaults/nullability.
2. Primary/unique/foreign keys, indexes and cross-tenant invariants.
3. RLS policies and grants; replacement API authorization checks and negative tests.
4. Trigger/function dependencies and transaction boundaries.
5. Read/write call sites (frontend, server routes, RPCs, jobs, Edge Functions).
6. Data sensitivity, retention, storage/file references and audit obligations.
7. Migration transformation, exact-count reconciliation and rollback strategy.
8. Evidence link and reviewer/date.

## Recommended order

1. **Tenant identity and authentication:** schools, memberships, invitations, role grants, account challenges, credentials, login attempts and audit.
2. **Academic identity and enrollment:** classes, students, sessions/terms, enrollment history, subjects and teacher assignments.
3. **Assessment and publication:** schemes, grade scales, results, component scores, approvals, lifecycle events, corrections, domain ratings, access controls, templates and generated outputs.
4. **Finance/subscriptions:** fees, invoices, payment allocations/proofs/submissions, subscription plans/renewals/grace/suspension and audit. Preserve receipt-review flows; no BillStack integration for SchoolPro.
5. **Admissions, CBT, teaching and operations:** map each module based on actual usage and source dependencies; no blanket migration.
6. **Shared services and storage:** notification/email, files/buckets, provider tables and platform RPC boundaries.
7. Only after the matrix is accepted: isolated migration rehearsal, exact row reconciliation, authorization tests, backup/restore, performance/load checks and host cost/security review.

## Current decision

**Not ready for data migration or cutover.** The draft's passing MySQL tests validate a small set of relational constraints only. They do not establish feature parity, application authorization, data correctness, full schema coverage, production hosting suitability, or rollback readiness.


## Draft MySQL target mapping update — 2026-10-17

The original matrix above was accurate when first written but is now stale for the operational domains below. Draft target tables have been added in migrations 005–007 and are validated only in disposable MySQL CI. Update these entries to **draft schema mapped / behavior not yet accepted**, not “complete”:

| Source table/domain | Draft MySQL target | Evidence and remaining acceptance |
|---|---|---|
| `schoolpro_attendance` | `attendance_records` (001) | Enrollment-scoped relation exists; verify full source columns, attendance states, batch writes, correction history and role rules |
| `schoolpro_timetable_entries` | `timetable_entries` (005) | Synthetic fixture and weekday/time/cross-school class negative tests pass; overlap and teacher/room conflict behavior open |
| `schoolpro_calendar_events` | `calendar_events` (005) | Basic synthetic fixture only; audience visibility, recurrence, event lifecycle and notifications open |
| `schoolpro_announcements` | `announcements` (005) | Basic synthetic fixture only; publisher permissions, audience rules and delivery/read tracking open |
| `schoolpro_discipline_records` | `discipline_records` (005) | Tenant FK tested indirectly; highly restricted role access, retention and audit semantics open |
| `schoolpro_health_records` | `student_health_records` (005) | Tenant FK fixture only; sensitive-record authorization, retention, access logging and privacy review open |
| `schoolpro_lesson_notes` | `lesson_notes` (005) | Synthetic fixture only; lesson planning, review/approval and teacher assignment behavior open |
| `schoolpro_leave_requests` | `leave_requests` (005) | Synthetic fixture only; requester identity, approver roles, state transitions and audit open |
| `schoolpro_inventory_assets` | `inventory_assets` (005) | Synthetic fixture only; stock/asset transactions, adjustments and audit open |
| `schoolpro_hostel_rooms`, `schoolpro_hostel_allocations` | `hostel_rooms`, `hostel_allocations` (005) | Cross-school student allocation negative test passes; capacity/occupancy concurrency and allocation lifecycle open |
| `schoolpro_assignments`, `schoolpro_assignment_submissions` | `assignments`, `assignment_submissions` (006) | Synthetic fixtures and cross-school submission/student negative test pass; file access, late handling, grading permissions and re-submission lifecycle open |
| `schoolpro_question_bank`, `schoolpro_cbt_tests`, `schoolpro_cbt_test_questions`, `schoolpro_cbt_attempts`, `schoolpro_cbt_answers` | `question_bank`, `cbt_tests`, `cbt_test_questions`, `cbt_attempts`, `cbt_answers` (006) | Cross-school question FK negative test passes; candidate CBT tables and eligibility remain unmapped; answer-key disclosure, eligibility, attempt locking, timing, scoring and concurrent submission need tests |
| `schoolpro_library_books`, `schoolpro_library_loans` | `library_books`, `library_loans` (006) | Cross-school book FK negative test passes; atomic available-copy accounting, overdue/fine lifecycle and role authorization open |
| `schoolpro_transport_routes`, `schoolpro_student_transport` | `transport_routes`, `student_transport_assignments` (006) | Synthetic fixtures only; capacity, term changes, transport billing and authorized access open |
| `schoolpro_payroll_records` | `payroll_records` (006) | Generated net amount fixture passes; approval separation, payment transaction, reversals, period locking and audit open |
| `schoolpro_login_attempts` | `auth_login_attempts` (007) | Only the new target hash-state schema/format test is mapped; do not copy raw source attempts until source columns, hash inputs, retention and privacy semantics are inspected |
| MySQL API identity/session/context | `users`, `user_sessions`, `platform_roles`, `school_memberships` (001), `auth_login_attempts` (007) | Initial API contract tests pass in disposable MySQL and mock-pool tests; invitation, first-login credential, account challenge, password reset, student activation and audit lifecycle remain open |

Migrations 005–007 passed the disposable MySQL schema workflow through run #435; payment validation #1352 passed, and the new MySQL API test job passed five tests on code-bearing commit `26e3ec065425cfbbfe07492b3ff20b4c0d0b2b2d`. SchoolPro's separate main validation/build job was still in progress at last check. Treat all mappings above as draft schema coverage, not production migration readiness or feature parity.
