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
