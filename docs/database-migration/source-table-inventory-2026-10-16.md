# Read-only source inventory — SchoolPro MySQL migration

Generated from the live Supabase public-schema table metadata on 2026-10-16. Row counts shown are database metadata estimates and must be reconciled with exact counts during a test rehearsal. This file contains no row data or secrets.

- Supabase project ref: `lnqsroyiybutkfngbyge`
- Recorded migrations: 476
- Latest recorded migration: `20261015161735 schoolpro_access_invitation_role_constraint`
- SchoolPro-prefixed tables found: 107
- Important shared tables to map: 17

## SchoolPro-prefixed tables

| Table | Metadata row count | RLS enabled |
|---|---:|---|
| `schoolpro_academic_documents` | 96 | yes |
| `schoolpro_access_invitations` | 10 | yes |
| `schoolpro_account_challenges` | 0 | yes |
| `schoolpro_admission_acceptances` | 0 | yes |
| `schoolpro_admission_documents` | 0 | yes |
| `schoolpro_admission_events` | 4 | yes |
| `schoolpro_admission_offers` | 0 | yes |
| `schoolpro_admissions` | 16 | yes |
| `schoolpro_announcements` | 1 | yes |
| `schoolpro_assessment_schemes` | 9 | yes |
| `schoolpro_assignment_submissions` | 27440 | yes |
| `schoolpro_assignments` | 896 | yes |
| `schoolpro_attendance` | 208800 | yes |
| `schoolpro_audit_logs` | 12 | yes |
| `schoolpro_bank_accounts` | 0 | yes |
| `schoolpro_board_members` | 7 | yes |
| `schoolpro_branding` | 0 | yes |
| `schoolpro_calendar_events` | 3 | yes |
| `schoolpro_candidate_cbt_answers` | 0 | yes |
| `schoolpro_candidate_cbt_attempts` | 0 | yes |
| `schoolpro_cbt_answers` | 2800 | yes |
| `schoolpro_cbt_attempts` | 280 | yes |
| `schoolpro_cbt_eligibility` | 28 | yes |
| `schoolpro_cbt_test_questions` | 280 | yes |
| `schoolpro_cbt_tests` | 28 | yes |
| `schoolpro_charge_categories` | 0 | yes |
| `schoolpro_class_result_submissions` | 0 | yes |
| `schoolpro_classes` | 33 | yes |
| `schoolpro_custom_requests` | 0 | yes |
| `schoolpro_demo_requests` | 1 | yes |
| `schoolpro_discipline_records` | 56 | yes |
| `schoolpro_document_issue_events` | 83 | yes |
| `schoolpro_document_issues` | 141 | yes |
| `schoolpro_document_templates` | 3 | yes |
| `schoolpro_email_queue` | 6 | yes |
| `schoolpro_enrollment_history` | 2292 | yes |
| `schoolpro_feature_overrides` | 0 | yes |
| `schoolpro_fee_bank_accounts` | 0 | yes |
| `schoolpro_fee_exceptions` | 0 | yes |
| `schoolpro_fee_items` | 504 | yes |
| `schoolpro_fee_payments` | 4045 | yes |
| `schoolpro_fee_records` | 0 | yes |
| `schoolpro_fee_structures` | 86 | yes |
| `schoolpro_finance_settings` | 1 | yes |
| `schoolpro_generated_result_outputs` | 1 | yes |
| `schoolpro_grade_scale` | 0 | yes |
| `schoolpro_guardian_links` | 843 | yes |
| `schoolpro_health_records` | 56 | yes |
| `schoolpro_hostel_allocations` | 24 | yes |
| `schoolpro_hostel_rooms` | 4 | yes |
| `schoolpro_initial_credentials` | 223 | yes |
| `schoolpro_inventory_assets` | 16 | yes |
| `schoolpro_invoice_templates` | 4 | yes |
| `schoolpro_invoices` | 3362 | yes |
| `schoolpro_leadership_settings` | 1 | yes |
| `schoolpro_leave_requests` | 12 | yes |
| `schoolpro_lesson_notes` | 10108 | yes |
| `schoolpro_library_books` | 30 | yes |
| `schoolpro_library_loans` | 168 | yes |
| `schoolpro_login_attempts` | 16 | yes |
| `schoolpro_member_permissions` | 0 | yes |
| `schoolpro_members` | 94 | yes |
| `schoolpro_module_records` | 0 | yes |
| `schoolpro_notifications` | 11035 | yes |
| `schoolpro_onboarding_requests` | 2 | yes |
| `schoolpro_payment_allocations` | 0 | yes |
| `schoolpro_payment_intents` | 0 | yes |
| `schoolpro_payment_proofs` | 0 | yes |
| `schoolpro_payment_submissions` | 0 | yes |
| `schoolpro_payroll_records` | 117 | yes |
| `schoolpro_plan_catalog` | 4 | yes |
| `schoolpro_portal_invites` | 0 | yes |
| `schoolpro_promotions` | 1160 | yes |
| `schoolpro_question_bank` | 1120 | yes |
| `schoolpro_result_access_events` | 84 | yes |
| `schoolpro_result_access_overrides` | 84 | yes |
| `schoolpro_result_access_pins` | 0 | yes |
| `schoolpro_result_approvals` | 33603 | yes |
| `schoolpro_result_correction_requests` | 2 | yes |
| `schoolpro_result_corrections` | 4 | yes |
| `schoolpro_result_domain_definitions` | 32 | yes |
| `schoolpro_result_domain_ratings` | 55680 | yes |
| `schoolpro_result_events` | 168018 | yes |
| `schoolpro_result_rating_scale` | 10 | yes |
| `schoolpro_result_templates` | 1 | yes |
| `schoolpro_result_term_settings` | 3 | yes |
| `schoolpro_result_verifications` | 0 | yes |
| `schoolpro_results` | 34803 | yes |
| `schoolpro_schools` | 2 | yes |
| `schoolpro_site_content` | 0 | yes |
| `schoolpro_site_gallery` | 0 | yes |
| `schoolpro_site_news` | 0 | yes |
| `schoolpro_site_settings` | 0 | yes |
| `schoolpro_student_activation_challenges` | 0 | yes |
| `schoolpro_student_transport` | 84 | yes |
| `schoolpro_students` | 1214 | yes |
| `schoolpro_subject_assignments` | 281 | yes |
| `schoolpro_subjects` | 284 | yes |
| `schoolpro_subscription_catalog` | 3 | yes |
| `schoolpro_subscription_intents` | 3 | yes |
| `schoolpro_subscription_payments` | 0 | yes |
| `schoolpro_subscription_plans` | 3 | yes |
| `schoolpro_subscriptions` | 2 | yes |
| `schoolpro_timetable_entries` | 280 | yes |
| `schoolpro_transcript_issues` | 161 | yes |
| `schoolpro_transcript_settings` | 0 | yes |
| `schoolpro_transport_routes` | 4 | yes |

## Shared platform tables/dependencies to inspect

| Table | Metadata row count | RLS enabled |
|---|---:|---|
| `profiles` | 242 | yes |
| `audit_logs` | 136 | yes |
| `finance_ledger_entries` | 0 | yes |
| `notification_templates` | 3 | yes |
| `notification_campaigns` | 0 | yes |
| `notification_deliveries` | 0 | yes |
| `security_events` | 0 | yes |
| `security_incidents` | 0 | yes |
| `payment_providers` | 1 | yes |
| `payment_provider_banks` | 4 | yes |
| `virtual_accounts` | 2 | yes |
| `payment_transactions` | 1 | yes |
| `webhook_events` | 1 | yes |
| `payment_admin_audit` | 0 | yes |
| `payment_fee_settings` | 2 | yes |
| `payment_platform_settings` | 12 | yes |
| `ihlink_email_queue` | 1 | yes |

## Inventory limitations

- Table presence and metadata row counts do not describe views, triggers, functions/RPCs, scheduled jobs, Edge Functions, bucket policies, Storage objects or frontend call sites.
- The schema contains tables with no rows as well as tables with significant historical/audit records. Empty tables must not be dropped without proving feature and migration dependencies.
- Do not blindly migrate every `schoolpro_*` table. Each table needs ownership, lifecycle, retention, source-of-truth and feature-use mapping.
- Row counts must be refreshed with exact count queries at the start of any authorized migration rehearsal.
- DataSub and other IHLink platform tables are out of scope for the SchoolPro MySQL database unless a shared integration boundary is explicitly documented.


## Second-pass database behavior inventory — 2026-10-16

Read-only catalog inspection was performed against the existing Supabase project. It found:

- **212 routines** matching the targeted name filter across `public` and `private` (names containing SchoolPro, result, student or school). This is a targeted filter, not the count of every database routine.
- **358 trigger event rows** on `public.schoolpro_%` tables. Because a trigger can fire for multiple events, this count represents information-schema trigger/event rows and should not be interpreted as 358 distinct trigger objects.
- **293 RLS policy rows** on `public.schoolpro_%` tables.
- These totals confirm that table-only schema translation would omit substantial application behavior. They are catalog counts; the full definitions and dependency graph still need to be captured and reviewed.

### High-priority routine behavior to map before API implementation

The read-only routine sample includes the following critical logic. The replacement API must preserve each rule in code and tests, or document an approved alternative:

| Existing routine / behavior | Migration concern |
|---|---|
| `private.enforce_schoolpro_tenant_relations` | Same-school validation across related student, subject, class and result records |
| `private.schoolpro_operationally_active` | School subscription/operational availability gate |
| `private.schoolpro_can_read_student`, `private.schoolpro_can_read_class` | Role- and relationship-scoped student/class access |
| `private.schoolpro_can_write_result`, `private.schoolpro_can_review_class` | Assessment entry and review permissions |
| `private.calculate_result_total` | Assessment component validation and total calculation |
| `private.enforce_result_workflow`, `private.log_schoolpro_result_lifecycle` | Published-result lock and lifecycle audit trail |
| `private.schoolpro_result_access`, `private.schoolpro_family_report_media` | Result access and family report file authorization |
| `private.schoolpro_bulk_academic_action`, `private.schoolpro_archive_progression` | Promotion/archive workflow and historical session integrity |
| `private.schoolpro_issue_transcript`, `private.schoolpro_revoke_transcript` | Transcript issue/revoke lifecycle |
| `private.schoolpro_auto_fee_invoices` | Fee invoice creation and schedule immutability constraints |
| `private.enforce_schoolpro_subscription_expiry` | Demo/annual renewal, grace period and suspension |
| `private.manage_schoolpro_subscription_invoice`, `private.review_school_subscription_transfer` | Subscription invoice/payment review and audit |

This list is illustrative, not a complete function inventory. Full function definitions, trigger-to-function links, grants, RPC callers and transaction semantics remain to be exported and mapped.

### RLS and trigger mapping status

- RLS policies currently define direct authenticated-client access in Supabase. In the MySQL target, the API must replace those guarantees with server-side authorization; merely translating policy names into endpoint names is insufficient.
- Trigger logic currently handles validation, result totals/status, notifications, fee invoicing, operational-write restrictions, document lifecycle and other side effects. Each trigger must be classified as (a) domain invariant, (b) audit event, (c) derived/calculated field, (d) notification/queue side effect, or (e) legacy/redundant behavior before moving it.
- The first schema CI proves only that the draft's current foreign keys reject the tested cross-school enrollment. It does not yet prove endpoint authorization, RLS equivalence, routine parity, result calculations, file access or complete data parity.

### Required next source artifacts

1. Full ordered list of public/private routine signatures and definitions, including dependencies and execute grants.
2. Full trigger list with trigger function definitions and event ordering.
3. Full RLS policy definitions including `USING` and `WITH CHECK`, grouped by domain and role.
4. Views/materialized views and dependent functions.
5. Storage buckets, policies, object path conventions, signed URL generation and upload/download call sites.
6. Scheduled jobs, Edge Functions and frontend `supabase.from`, `supabase.rpc`, `supabase.storage` call sites.
7. A source-to-target behavior matrix linking every artifact to MySQL schema, API handler and automated positive/negative test.
