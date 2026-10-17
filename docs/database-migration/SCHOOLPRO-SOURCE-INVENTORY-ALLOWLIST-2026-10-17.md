# SchoolPro source inventory and migration allowlist — 2026-10-17

## Status and decision

**Version:** v0.1 — source-catalog-derived candidate allowlist; not yet approved for export/import.  
**Source:** Supabase project `lnqsroyiybutkfngbyge`, PostgreSQL 17.6. Read-only catalog inspection via the connected Supabase tools.  
**Target:** Aiven PostgreSQL 18.6 rehearsal service; no migration has been run.  
**Production safety:** no DDL/DML, exports, target imports, Render changes, or cutover occurred during this inventory.

The source has 346 relations across the inspected `public`, `auth`, `storage`, and `private` schemas; 107 public tables use the `schoolpro_` prefix. Prefix matching is a useful starting boundary, not proof of exclusive ownership. The allowlist below is therefore a **candidate object list** pending source-code, foreign-key, routine, trigger, scheduled-job, storage-key and row-ownership reconciliation.

## 1. Candidate SchoolPro table allowlist (107)

These `public.schoolpro_*` tables are the initial SchoolPro-owned candidate set. Include the table schema/definition and SchoolPro-owned rows only after confirming each table's foreign-key dependencies and whether it contains platform-wide catalogue/configuration rows.

- `public.schoolpro_academic_documents`
- `public.schoolpro_access_invitations`
- `public.schoolpro_account_challenges`
- `public.schoolpro_admission_acceptances`
- `public.schoolpro_admission_documents`
- `public.schoolpro_admission_events`
- `public.schoolpro_admission_offers`
- `public.schoolpro_admissions`
- `public.schoolpro_announcements`
- `public.schoolpro_assessment_schemes`
- `public.schoolpro_assignment_submissions`
- `public.schoolpro_assignments`
- `public.schoolpro_attendance`
- `public.schoolpro_audit_logs`
- `public.schoolpro_bank_accounts`
- `public.schoolpro_board_members`
- `public.schoolpro_branding`
- `public.schoolpro_calendar_events`
- `public.schoolpro_candidate_cbt_answers`
- `public.schoolpro_candidate_cbt_attempts`
- `public.schoolpro_cbt_answers`
- `public.schoolpro_cbt_attempts`
- `public.schoolpro_cbt_eligibility`
- `public.schoolpro_cbt_test_questions`
- `public.schoolpro_cbt_tests`
- `public.schoolpro_charge_categories`
- `public.schoolpro_class_result_submissions`
- `public.schoolpro_classes`
- `public.schoolpro_custom_requests`
- `public.schoolpro_demo_requests`
- `public.schoolpro_discipline_records`
- `public.schoolpro_document_issue_events`
- `public.schoolpro_document_issues`
- `public.schoolpro_document_templates`
- `public.schoolpro_email_queue`
- `public.schoolpro_enrollment_history`
- `public.schoolpro_feature_overrides`
- `public.schoolpro_fee_bank_accounts`
- `public.schoolpro_fee_exceptions`
- `public.schoolpro_fee_items`
- `public.schoolpro_fee_payments`
- `public.schoolpro_fee_records`
- `public.schoolpro_fee_structures`
- `public.schoolpro_finance_settings`
- `public.schoolpro_generated_result_outputs`
- `public.schoolpro_grade_scale`
- `public.schoolpro_guardian_links`
- `public.schoolpro_health_records`
- `public.schoolpro_hostel_allocations`
- `public.schoolpro_hostel_rooms`
- `public.schoolpro_initial_credentials`
- `public.schoolpro_inventory_assets`
- `public.schoolpro_invoice_templates`
- `public.schoolpro_invoices`
- `public.schoolpro_leadership_settings`
- `public.schoolpro_leave_requests`
- `public.schoolpro_lesson_notes`
- `public.schoolpro_library_books`
- `public.schoolpro_library_loans`
- `public.schoolpro_login_attempts`
- `public.schoolpro_member_permissions`
- `public.schoolpro_members`
- `public.schoolpro_module_records`
- `public.schoolpro_notifications`
- `public.schoolpro_onboarding_requests`
- `public.schoolpro_payment_allocations`
- `public.schoolpro_payment_intents`
- `public.schoolpro_payment_proofs`
- `public.schoolpro_payment_submissions`
- `public.schoolpro_payroll_records`
- `public.schoolpro_plan_catalog`
- `public.schoolpro_portal_invites`
- `public.schoolpro_promotions`
- `public.schoolpro_question_bank`
- `public.schoolpro_result_access_events`
- `public.schoolpro_result_access_overrides`
- `public.schoolpro_result_access_pins`
- `public.schoolpro_result_approvals`
- `public.schoolpro_result_correction_requests`
- `public.schoolpro_result_corrections`
- `public.schoolpro_result_domain_definitions`
- `public.schoolpro_result_domain_ratings`
- `public.schoolpro_result_events`
- `public.schoolpro_result_rating_scale`
- `public.schoolpro_result_templates`
- `public.schoolpro_result_term_settings`
- `public.schoolpro_result_verifications`
- `public.schoolpro_results`
- `public.schoolpro_schools`
- `public.schoolpro_site_content`
- `public.schoolpro_site_gallery`
- `public.schoolpro_site_news`
- `public.schoolpro_site_settings`
- `public.schoolpro_student_activation_challenges`
- `public.schoolpro_student_transport`
- `public.schoolpro_students`
- `public.schoolpro_subject_assignments`
- `public.schoolpro_subjects`
- `public.schoolpro_subscription_catalog`
- `public.schoolpro_subscription_intents`
- `public.schoolpro_subscription_payments`
- `public.schoolpro_subscription_plans`
- `public.schoolpro_subscriptions`
- `public.schoolpro_timetable_entries`
- `public.schoolpro_transcript_issues`
- `public.schoolpro_transcript_settings`
- `public.schoolpro_transport_routes`

## 2. Cross-cutting objects: do not bulk-migrate

| Object / service | Decision for first rehearsal | Reason / required handling |
|---|---|---|
| `auth.*` (including `auth.users`, identities, sessions, refresh tokens, MFA, audit logs) | **Exclude** | Supabase Auth remains the identity provider initially. Do not copy password hashes, refresh/session tokens, MFA state, or Auth internals into Aiven. Validate Supabase access tokens server-side and resolve identity/role/membership authoritatively. |
| `public.profiles` | **Exclude from bulk copy; keep as live identity/role source initially** | Shared platform profiles, including platform-wide roles, are not SchoolPro-only. App/API must query authoritative role data safely. Any later split requires a separate approved mapping. |
| `public.virtual_accounts`, `public.payment_transactions`, shared wallet/ledger and provider tables | **Exclude** | Shared financial boundary and payment integration. Preserve in the existing owning system. Do not copy financial balances or transaction history as a side effect of SchoolPro migration. |
| `public.datasub_*`, `private.datasub_*`, DataSub/BillStack tables and Edge Functions | **Exclude** | DataSub remains on Supabase and is explicitly out of scope. No shared-project-wide dump/restore. |
| `storage.*` schema and `storage.objects` rows | **Exclude** | Supabase Storage service owns object metadata and behavior. Retain Supabase Storage for the first rehearsal; inventory SchoolPro bucket/object keys and policies separately. Do not treat metadata rows as the actual files. |
| Other IHLink product tables (`host_*`, `consult_*`, `engineering_*`, `business_*`, `academy_*`, etc.) | **Exclude** | Belong to other platform products and are outside the SchoolPro migration boundary. |
| Shared `public.audit_logs`, `admin_product_access`, security/notification/platform tables | **Exclude by default; review each dependency** | Shared cross-product records or access control. Include only a narrowly scoped SchoolPro-owned subset if proven necessary and approved. |
| `public.ihlink_email_queue` | **Do not copy wholesale; conditional integration** | Has a SchoolPro school reference but is a shared email delivery queue. Keep the worker/queue in its owning system initially or define a reviewed SchoolPro-only integration. Prevent duplicate email delivery during rehearsal. |

## 3. Foreign-key and identity boundary

Catalog inspection confirms SchoolPro records reference shared identity objects, including `auth.users` and `public.profiles`; some payment-related paths also reference shared `public.virtual_accounts` and shared payment records. Cross-database foreign keys cannot remain enforced between Aiven and Supabase.

Before any data import, produce a constraint-by-constraint map:
1. Keep the original user UUIDs as identifiers where required, but do not copy Auth credentials or sessions.
2. Replace cross-database foreign-key enforcement with an explicitly reviewed API/identity contract, or an approved minimal identity-reference design. Do not create fake Auth users or duplicate profiles to satisfy foreign keys.
3. Keep payment and virtual-account ownership in the source system; the Aiven SchoolPro data model must not independently mutate shared financial records.
4. Validate every school-owned row is bound to the correct `school_id`; never infer tenant ownership from a client-supplied value.
5. Review nullable references, delete/update actions, unique constraints and triggers before changing any FK.

## 4. Routines, triggers, RLS and grants

The source catalog contains many public SchoolPro RPCs, including security-definer routines for admissions, demo/subscription activation, fee/payment processing, result pins, result locking, promotions, documents and other school workflows. These are behavior-bearing objects, not optional decoration.

**Not yet export-ready:** complete definitions and dependency closure for all SchoolPro-relevant routines, triggers, views, types/enums, sequences, extensions, grants, RLS policies and scheduled jobs still need to be captured and mapped. Do not copy all `public` or `private` functions wholesale. For each included routine, record its callers, tables touched, role/tenant checks, side effects, and whether its Supabase-specific behavior can run on vanilla Aiven PostgreSQL.

RLS policies often call Supabase-specific helpers such as `auth.uid()` and project-private authorization functions. Do not copy policies unchanged and assume they provide protection on Aiven. The target must have a deliberate server-side authorization design and negative tenant-isolation tests before application access is enabled.

## 5. Edge Functions, cron, storage and external side effects

- SchoolPro-relevant Edge Functions identified in the source inventory: `schoolpro-payment`, `schoolpro-subscription`, `schoolpro-email-worker`, `schoolpro-render-document`, `invite-school-staff`, plus shared `auth-handoff`. Inspect each source and its calls before assigning it to the new architecture. A `verify_jwt=false` setting alone is not a vulnerability finding, but each endpoint needs explicit authentication, authorization, tenant binding, signature/secret checks where applicable, and idempotency review.
- SchoolPro expiry/grace and academic-calendar cron jobs, plus the shared email worker schedule, must not be blindly replayed. Keep only approved SchoolPro jobs and prevent duplicate billing/email side effects.
- Retain Supabase Storage in the first rehearsal. Inventory SchoolPro-related buckets, object keys, RLS/policies, signed URL use and upload ownership; do not migrate actual files until an independent storage plan is approved.
- Supabase-specific extensions/services (Auth helpers, Storage, Vault, `pg_net`, `pg_cron`, and other extensions) require a compatibility map. Vanilla Aiven PostgreSQL is not a drop-in replacement for Supabase service APIs.

## 6. Required before this candidate allowlist becomes final

- [ ] Static scan of the active application branch for every Supabase `.from()`, `.rpc()`, Auth, Storage, Edge Function, Realtime and direct SQL call site. Existing GitHub code-search attempts returned no usable matches, so the call graph is **not complete**.
- [ ] Retrieve and review complete definitions for relevant routines, triggers, views, types/enums, sequences, constraints, policies and grants.
- [ ] Map all foreign keys from/to candidate tables, especially `auth.users`, `profiles`, `virtual_accounts`, shared payment and queue tables.
- [ ] Decide row-level ownership for each candidate table; identify shared catalog/configuration data and per-school rows.
- [ ] Map cron jobs, Edge Functions, storage buckets/objects, webhooks, email, payment and document-render side effects.
- [ ] Reconcile candidate objects against repository migrations and deployed production catalog to detect schema drift.
- [ ] Review and sign off this allowlist before exporting source data.
- [ ] Secure the rehearsal target network; the reported Aiven target was public with IP allowlist open to all. Do not load real data or credentials until restricted.
- [ ] Only then perform a controlled rehearsal; compare schema, counts/checksums, critical records, constraints, routines and behavior.

## 7. Explicit exclusions checklist

- [ ] No `auth.*` bulk copy.
- [ ] No shared `profiles` bulk copy.
- [ ] No virtual-account, wallet, payment-provider or shared ledger copy.
- [ ] No DataSub/BillStack tables, functions, jobs or data.
- [ ] No global `public`/ `private` schema dump.
- [ ] No Storage metadata/file copy in the first rehearsal.
- [ ] No production writes, Render environment changes, deployment, PR merge or cutover.

## 8. Current outcome

**Inventory result:** 107 candidate `schoolpro_` tables identified from the live Supabase catalog; shared systems and major integration boundaries documented.  
**Allowlist state:** **DRAFT / NOT APPROVED FOR EXPORT** pending code-call-graph and dependency review.  
**Migration state:** **NOT STARTED** — no SchoolPro schema or data has been migrated to Aiven.  
**Production source of truth:** Supabase. **Application host:** Render. **DataSub:** remains on Supabase and out of scope.  
**Acceptance gates A/B/C:** not approved.
