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


## 9. Live catalog routine and trigger name inventory (read-only)

The following are catalog-derived names from the current Supabase source. This is an inventory of **names and flags**, not a reviewed DDL export or proof that each object should be copied unchanged. PostgreSQL reports `prosecdef=true` for SECURITY DEFINER routines; these require especially careful authorization/tenant-boundary review before porting.

### Public routines whose names contain `schoolpro` (127)

- `accept_schoolpro_admission_offer(p_token uuid, p_name text, p_email text, p_notes text)` — SECURITY DEFINER: `true`
- `activate_schoolpro_demo(p_request uuid, p_school uuid)` — SECURITY DEFINER: `true`
- `activate_schoolpro_demo(p_school uuid, p_tier text, p_days integer, p_reason text)` — SECURITY DEFINER: `true`
- `adjust_schoolpro_inventory(p_asset uuid, p_delta integer, p_condition text, p_location text)` — SECURITY DEFINER: `true`
- `admit_schoolpro_applicant(p_application uuid)` — SECURITY DEFINER: `true`
- `allocate_schoolpro_hostel(p_room uuid, p_student uuid, p_session text)` — SECURITY DEFINER: `true`
- `apply_schoolpro_promotion(p_promotion uuid)` — SECURITY DEFINER: `true`
- `assign_schoolpro_entrance_cbt(p_application uuid, p_test uuid)` — SECURITY DEFINER: `true`
- `assign_schoolpro_transport(p_route uuid, p_student uuid, p_pickup text)` — SECURITY DEFINER: `false`
- `assign_schoolpro_transport(p_route uuid, p_student uuid, p_pickup text, p_session text)` — SECURITY DEFINER: `true`
- `borrow_schoolpro_library_book(p_book uuid, p_student uuid, p_member uuid, p_due timestamp with time zone)` — SECURITY DEFINER: `true`
- `borrow_schoolpro_library_book(p_book uuid, p_student uuid, p_member uuid, p_due timestamp with time zone, p_session text)` — SECURITY DEFINER: `true`
- `check_schoolpro_result_pin(p_admission text, p_term text, p_session text, p_pin text)` — SECURITY DEFINER: `true`
- `claim_schoolpro_onboarding()` — SECURITY DEFINER: `true`
- `control_center_activate_schoolpro(p_school uuid, p_tier text, p_reason text)` — SECURITY DEFINER: `true`
- `create_schoolpro_fee_bundle(p_school uuid, p_name text, p_classes text[], p_term text, p_session text, p_due date, p_items jsonb)` — SECURITY DEFINER: `true`
- `create_schoolpro_portal_invite(p_student uuid, p_email text, p_type text)` — SECURITY DEFINER: `true`
- `create_schoolpro_progression(p_student uuid, p_session text, p_decision text, p_to_class uuid, p_reason text)` — SECURITY DEFINER: `true`
- `create_schoolpro_result_pin(target_student uuid, target_term text, target_session text)` — SECURITY DEFINER: `true`
- `create_schoolpro_workspace(p_request uuid, p_tier text)` — SECURITY DEFINER: `true`
- `delete_schoolpro_draft_result(p_result uuid, p_reason text)` — SECURITY DEFINER: `true`
- `edit_schoolpro_fee_bundle(p_structure uuid, p_name text, p_due date, p_items jsonb)` — SECURITY DEFINER: `true`
- `edit_schoolpro_fee_invoice(p_invoice uuid, p_title text, p_amount numeric, p_due date, p_notes text)` — SECURITY DEFINER: `true`
- `enforce_schoolpro_result_lock()` — SECURITY DEFINER: `false`
- `ensure_schoolpro_default_assessment_scheme(p_school uuid)` — SECURITY DEFINER: `true`
- `ensure_schoolpro_standard_assessment_schemes(p_school uuid)` — SECURITY DEFINER: `true`
- `finalize_schoolpro_billstack_transfer(p_intent uuid, p_transaction_ref text, p_verified_amount numeric, p_payload jsonb)` — SECURITY DEFINER: `true`
- `finalize_schoolpro_document_issue(p_issue uuid, p_output_path text)` — SECURITY DEFINER: `true`
- `finalize_schoolpro_enrollment(p_application uuid)` — SECURITY DEFINER: `true`
- `finalize_schoolpro_payment(p_reference text, p_gateway_transaction_id text, p_verified_amount numeric, p_status text, p_payload jsonb)` — SECURITY DEFINER: `true`
- `finalize_schoolpro_subscription(p_intent uuid, p_transaction_ref text, p_amount numeric)` — SECURITY DEFINER: `true`
- `generate_schoolpro_class_invoices(p_structure uuid, p_class text)` — SECURITY DEFINER: `true`
- `get_schoolpro_admission_offer(p_token uuid)` — SECURITY DEFINER: `true`
- `grade_schoolpro_assignment_submission(p_submission uuid, p_score numeric, p_feedback text)` — SECURITY DEFINER: `true`
- `import_schoolpro_results(p_school uuid, p_term text, p_session text, p_rows jsonb)` — SECURITY DEFINER: `true`
- `issue_schoolpro_admission_offer(p_application uuid, p_letter text, p_expiry timestamp with time zone, p_instructions text)` — SECURITY DEFINER: `true`
- `issue_schoolpro_result_verification(p_student uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `link_schoolpro_guardian(target_student uuid, guardian_email text, guardian_relationship text)` — SECURITY DEFINER: `false`
- `link_schoolpro_student_account(target_student uuid, target_email text)` — SECURITY DEFINER: `true`
- `list_available_schoolpro_cbts()` — SECURITY DEFINER: `true`
- `manage_schoolpro_subscription_invoice(p_invoice uuid, p_action text, p_version timestamp with time zone, p_reason text)` — SECURITY DEFINER: `false`
- `mark_schoolpro_cbt_theory(p_attempt uuid, p_question uuid, p_marks numeric, p_feedback text)` — SECURITY DEFINER: `true`
- `mark_schoolpro_theory_answer(p_answer uuid, p_marks numeric, p_feedback text)` — SECURITY DEFINER: `true`
- `prepare_schoolpro_bank_subscription(p_school uuid, p_catalog uuid)` — SECURITY DEFINER: `true`
- `prepare_schoolpro_subscription_payment(p_user uuid, p_school uuid, p_catalog uuid, p_account uuid)` — SECURITY DEFINER: `true`
- `process_schoolpro_payroll(p_record uuid)` — SECURITY DEFINER: `false`
- `publish_schoolpro_class_results(p_school uuid, p_class uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `publish_schoolpro_results(p_school uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `publish_schoolpro_selected_results(p_school uuid, p_term text, p_session text, p_students uuid[], p_all boolean)` — SECURITY DEFINER: `true`
- `queue_schoolpro_email(p_school uuid, p_email text, p_name text, p_template text, p_subject text, p_payload jsonb)` — SECURITY DEFINER: `true`
- `queue_schoolpro_transactional_email()` — SECURITY DEFINER: `true`
- `record_schoolpro_payment(target_invoice uuid, payment_amount numeric, payment_method text, payment_reference text, payment_notes text)` — SECURITY DEFINER: `false`
- `reopen_schoolpro_result_for_correction(p_result uuid, p_reason text)` — SECURITY DEFINER: `true`
- `request_schoolpro_workspace_demo(p_request uuid, p_tier text)` — SECURITY DEFINER: `true`
- `retry_schoolpro_email(p_job uuid)` — SECURITY DEFINER: `true`
- `return_schoolpro_library_book(p_loan uuid, p_fine numeric)` — SECURITY DEFINER: `true`
- `review_schoolpro_leave(p_request uuid, p_status text)` — SECURITY DEFINER: `false`
- `review_schoolpro_onboarding(p_request uuid, p_action text, p_expected_status text, p_note text, p_tier text)` — SECURITY DEFINER: `true`
- `review_schoolpro_payment_proof(p_proof uuid, p_decision text, p_note text)` — SECURITY DEFINER: `true`
- `review_schoolpro_payment_submission(p_submission uuid, p_decision text, p_note text)` — SECURITY DEFINER: `true`
- `review_schoolpro_result(p_result uuid, p_status text, p_notes text)` — SECURITY DEFINER: `true`
- `revoke_schoolpro_document_issue(p_issue uuid, p_reason text)` — SECURITY DEFINER: `true`
- `save_schoolpro_cbt_answer(p_attempt uuid, p_question uuid, p_answer text)` — SECURITY DEFINER: `true`
- `schedule_schoolpro_admission_event(p_application uuid, p_type text, p_at timestamp with time zone, p_location text, p_notes text)` — SECURITY DEFINER: `true`
- `schoolpro_academic_summary(p_student uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_accept_access_invitation(p_user uuid, p_hash text)` — SECURITY DEFINER: `false`
- `schoolpro_allocate_hostel(p_school uuid, p_student uuid, p_room uuid, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_auto_create_admission_document()` — SECURITY DEFINER: `true`
- `schoolpro_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_bulk_academic_action(p_school uuid, p_session text, p_action text, p_students uuid[])` — SECURITY DEFINER: `false`
- `schoolpro_can_author_cbt(p_school uuid)` — SECURITY DEFINER: `true`
- `schoolpro_can_manage_cbt(p_school uuid)` — SECURITY DEFINER: `true`
- `schoolpro_can_release_result(p_student uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_can_view_result_output(p_student_id uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_cbt_is_eligible(p_test uuid, p_student uuid)` — SECURITY DEFINER: `true`
- `schoolpro_class_broadsheet(p_school uuid, p_class uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_class_review_sheet(p_school uuid, p_class uuid, p_term text, p_session text)` — SECURITY DEFINER: `false`
- `schoolpro_class_staff_directory(p_school uuid)` — SECURITY DEFINER: `false`
- `schoolpro_consume_account_challenge(p_user uuid, p_hash text, p_password text)` — SECURITY DEFINER: `false`
- `schoolpro_consume_student_challenge(p_hash text)` — SECURITY DEFINER: `false`
- `schoolpro_coordinator_classes(p_school uuid)` — SECURITY DEFINER: `false`
- `schoolpro_current_academic_period(p_school uuid)` — SECURITY DEFINER: `true`
- `schoolpro_family_result_periods(p_student uuid)` — SECURITY DEFINER: `false`
- `schoolpro_finalize_testing_certificate(p_issue uuid, p_output_path text)` — SECURITY DEFINER: `true`
- `schoolpro_grade_for_score(p_school uuid, p_score numeric)` — SECURITY DEFINER: `true`
- `schoolpro_initial_challenge(p_user uuid, p_surname text, p_hash text)` — SECURITY DEFINER: `false`
- `schoolpro_issue_library_loan(p_school uuid, p_book uuid, p_student uuid, p_member uuid, p_due timestamp with time zone)` — SECURITY DEFINER: `true`
- `schoolpro_issue_transcript(p_student uuid)` — SECURITY DEFINER: `false`
- `schoolpro_join_school_code(p_user uuid, p_school_code text)` — SECURITY DEFINER: `false`
- `schoolpro_member_can_manage(p_school uuid)` — SECURITY DEFINER: `true`
- `schoolpro_overall_grade(p_student_id uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_printable_result(p_student uuid, p_term text, p_session text)` — SECURITY DEFINER: `false`
- `schoolpro_progression_summary(p_student uuid, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_record_offline_payment(p_invoice uuid, p_amount numeric, p_method text, p_reference text, p_notes text)` — SECURITY DEFINER: `true`
- `schoolpro_report_details(p_student uuid, p_term text, p_session text)` — SECURITY DEFINER: `false`
- `schoolpro_result_access(target_student uuid, target_term text, target_session text)` — SECURITY DEFINER: `false`
- `schoolpro_result_class_rank(p_student_id uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_result_comment(p_score numeric)` — SECURITY DEFINER: `false`
- `schoolpro_return_library_loan(p_loan uuid)` — SECURITY DEFINER: `true`
- `schoolpro_review_result(p_student uuid, p_term text, p_session text)` — SECURITY DEFINER: `false`
- `schoolpro_revoke_transcript(p_issue uuid)` — SECURITY DEFINER: `false`
- `schoolpro_save_academic_calendar(p_school uuid, p_session text, p_term text, p_start date, p_end date)` — SECURITY DEFINER: `true`
- `schoolpro_send_school_notice(p_school uuid, p_title text, p_message text, p_classes uuid[], p_students uuid[], p_audience text)` — SECURITY DEFINER: `false`
- `schoolpro_set_board_role(p_school uuid, p_member uuid, p_title text)` — SECURITY DEFINER: `false`
- `schoolpro_set_form_master(p_class uuid, p_member uuid)` — SECURITY DEFINER: `false`
- `schoolpro_set_initial_credential(p_user uuid, p_school uuid, p_surname text)` — SECURITY DEFINER: `false`
- `schoolpro_set_result_access_exception(p_student uuid, p_term text, p_session text, p_allowed boolean, p_reason text)` — SECURITY DEFINER: `false`
- `schoolpro_set_result_lock(p_school uuid, p_term text, p_session text, p_locked boolean)` — SECURITY DEFINER: `true`
- `schoolpro_student_transcripts(p_student uuid)` — SECURITY DEFINER: `false`
- `schoolpro_subject_statistics(p_student uuid, p_term text, p_session text)` — SECURITY DEFINER: `false`
- `schoolpro_submit_class_results(p_school uuid, p_class uuid, p_term text, p_session text)` — SECURITY DEFINER: `true`
- `schoolpro_subscription_entitlements(p_school uuid)` — SECURITY DEFINER: `true`
- `schoolpro_take_login_attempt(p_key text, p_limit integer)` — SECURITY DEFINER: `false`
- `schoolpro_transfer_ownership(p_school_id uuid, p_new_owner_id uuid)` — SECURITY DEFINER: `true`
- `schoolpro_transfer_student_out(p_student uuid, p_destination text, p_reason text)` — SECURITY DEFINER: `true`
- `schoolpro_user_permissions(p_school uuid)` — SECURITY DEFINER: `true`
- `schoolpro_vacate_hostel(p_allocation uuid)` — SECURITY DEFINER: `true`
- `schoolpro_verify_result_code(p_code text)` — SECURITY DEFINER: `true`
- `set_schoolpro_default_document_template(p_template uuid)` — SECURITY DEFINER: `true`
- `start_schoolpro_cbt(p_test uuid)` — SECURITY DEFINER: `true`
- `submit_schoolpro_application(p_school uuid, p_first text, p_last text, p_gender text, p_dob date, p_guardian text, p_phone text, p_email text, p_class text, p_previous text)` — SECURITY DEFINER: `true`
- `submit_schoolpro_assignment(p_assignment uuid, p_submission_text text, p_file_url text)` — SECURITY DEFINER: `true`
- `submit_schoolpro_cbt(p_attempt uuid)` — SECURITY DEFINER: `true`
- `submit_schoolpro_payment(p_school uuid, p_bank_account uuid, p_total numeric, p_payment_date date, p_payer_name text, p_bank_reference text, p_receipt_path text, p_receipt_mime text, p_allocations jsonb)` — SECURITY DEFINER: `true`
- `submit_schoolpro_term_demo(p_request uuid, p_tier text, p_term_start date, p_term_end date, p_exam_start date, p_exam_end date, p_calendar text, p_letter text)` — SECURITY DEFINER: `true`
- `verify_schoolpro_admission_document(p_document uuid, p_verified boolean, p_notes text)` — SECURITY DEFINER: `true`
- `verify_schoolpro_document(p_serial text)` — SECURITY DEFINER: `true`

### Non-internal triggers on `schoolpro_*` tables or calling a function named `%schoolpro%` (160)

- `schoolpro_academic_documents` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_academic_documents` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_admission_acceptances` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_admission_documents` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_admission_events` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_admission_offers` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_admissions` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_admissions` → trigger `trg_schoolpro_admission_notify` → function `notify_school_staff` (enabled code: `O`)
- `schoolpro_admissions` → trigger `trg_schoolpro_auto_admission_document` → function `schoolpro_auto_create_admission_document` (enabled code: `O`)
- `schoolpro_announcements` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_announcements` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_announcements` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_announcements` → trigger `trg_schoolpro_announcement_notify` → function `notify_school_staff` (enabled code: `O`)
- `schoolpro_assessment_schemes` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_assessment_schemes` → trigger `validate_schoolpro_assessment_scheme` → function `validate_assessment_scheme` (enabled code: `O`)
- `schoolpro_assignment_submissions` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_assignment_submissions` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_assignments` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_assignments` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_assignments` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_assignments` → trigger `trg_validate_schoolpro_assignment_target` → function `validate_schoolpro_assignment_target` (enabled code: `O`)
- `schoolpro_attendance` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_attendance` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_attendance` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_attendance` → trigger `schoolpro_validate_activity_calendar` → function `schoolpro_validate_activity_calendar` (enabled code: `O`)
- `schoolpro_attendance` → trigger `validate_schoolpro_attendance` → function `validate_attendance_record` (enabled code: `O`)
- `schoolpro_bank_accounts` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_branding` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_calendar_events` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_calendar_events` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_calendar_events` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_calendar_events` → trigger `schoolpro_validate_activity_calendar` → function `schoolpro_validate_activity_calendar` (enabled code: `O`)
- `schoolpro_calendar_events` → trigger `validate_schoolpro_calendar_workflow` → function `validate_schoolpro_workflow_record` (enabled code: `O`)
- `schoolpro_candidate_cbt_answers` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_candidate_cbt_attempts` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_candidate_cbt_attempts` → trigger `trg_candidate_cbt_tenant` → function `validate_candidate_cbt_tenant` (enabled code: `O`)
- `schoolpro_cbt_answers` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_cbt_attempts` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_cbt_eligibility` → trigger `enforce_schoolpro_cbt_eligibility_relations` → function `enforce_schoolpro_tenant_relations` (enabled code: `O`)
- `schoolpro_cbt_eligibility` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_cbt_eligibility` → trigger `schoolpro_cbt_eligibility_tenant_guard` → function `validate_schoolpro_cbt_eligibility` (enabled code: `O`)
- `schoolpro_cbt_test_questions` → trigger `enforce_schoolpro_cbt_question_relations` → function `enforce_schoolpro_tenant_relations` (enabled code: `O`)
- `schoolpro_cbt_test_questions` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_cbt_tests` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_charge_categories` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_classes` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_demo_requests` → trigger `schoolpro_demo_invoice` → function `sync_schoolpro_demo_invoice` (enabled code: `O`)
- `schoolpro_discipline_records` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_discipline_records` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_discipline_records` → trigger `schoolpro_notify_discipline` → function `schoolpro_notify_discipline` (enabled code: `O`)
- `schoolpro_discipline_records` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_discipline_records` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_document_issue_events` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_document_issues` → trigger `enforce_schoolpro_document_issue_relations` → function `enforce_schoolpro_tenant_relations` (enabled code: `O`)
- `schoolpro_document_issues` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_document_issues` → trigger `trg_guard_schoolpro_document_issue_lifecycle` → function `guard_schoolpro_document_issue_lifecycle` (enabled code: `O`)
- `schoolpro_document_templates` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_fee_bank_accounts` → trigger `school_fee_bank_sync` → function `sync_school_fee_receiving_account` (enabled code: `O`)
- `schoolpro_fee_bank_accounts` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_fee_exceptions` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_fee_items` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_fee_items` → trigger `schoolpro_fee_items_auto_invoice` → function `schoolpro_auto_fee_invoices` (enabled code: `O`)
- `schoolpro_fee_payments` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_fee_payments` → trigger `trg_schoolpro_payment_email` → function `queue_schoolpro_transactional_email` (enabled code: `O`)
- `schoolpro_fee_records` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_fee_structures` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_fee_structures` → trigger `schoolpro_fee_schedule_auto_invoice` → function `schoolpro_auto_fee_invoices` (enabled code: `O`)
- `schoolpro_finance_settings` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_generated_result_outputs` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_grade_scale` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_guardian_links` → trigger `schoolpro_guardian_school_scope` → function `schoolpro_guardian_school_scope` (enabled code: `O`)
- `schoolpro_health_records` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_health_records` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_health_records` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_health_records` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_health_records` → trigger `schoolpro_validate_activity_calendar` → function `schoolpro_validate_activity_calendar` (enabled code: `O`)
- `schoolpro_health_records` → trigger `validate_schoolpro_clinic_workflow` → function `validate_schoolpro_workflow_record` (enabled code: `O`)
- `schoolpro_hostel_allocations` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_hostel_allocations` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_hostel_allocations` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_hostel_allocations` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_hostel_rooms` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_inventory_assets` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_invoice_templates` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_invoices` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_invoices` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_invoices` → trigger `trg_schoolpro_invoice_notify` → function `notify_school_staff` (enabled code: `O`)
- `schoolpro_leave_requests` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_leave_requests` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_leave_requests` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_leave_requests` → trigger `schoolpro_validate_activity_calendar` → function `schoolpro_validate_activity_calendar` (enabled code: `O`)
- `schoolpro_leave_requests` → trigger `validate_schoolpro_leave` → function `validate_schoolpro_leave` (enabled code: `O`)
- `schoolpro_lesson_notes` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_lesson_notes` → trigger `schoolpro_lesson_workflow` → function `schoolpro_validate_lesson_workflow` (enabled code: `O`)
- `schoolpro_lesson_notes` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_lesson_notes` → trigger `schoolpro_validate_activity_calendar` → function `schoolpro_validate_activity_calendar` (enabled code: `O`)
- `schoolpro_library_books` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_library_loans` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_library_loans` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_library_loans` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_library_loans` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_library_loans` → trigger `schoolpro_validate_activity_calendar` → function `schoolpro_validate_activity_calendar` (enabled code: `O`)
- `schoolpro_members` → trigger `protect_schoolpro_proprietor_role` → function `protect_schoolpro_proprietor_role` (enabled code: `O`)
- `schoolpro_members` → trigger `schoolpro_clear_changed_board_role` → function `schoolpro_clear_changed_board_role` (enabled code: `O`)
- `schoolpro_module_records` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_onboarding_requests` → trigger `schoolpro_onboarding_demo_invoice` → function `sync_schoolpro_onboarding_demo_invoice` (enabled code: `O`)
- `schoolpro_payment_allocations` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_payment_intents` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_payment_proofs` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_payment_submissions` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_payroll_records` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_payroll_records` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_payroll_records` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_payroll_records` → trigger `validate_schoolpro_payroll_workflow` → function `validate_schoolpro_workflow_record` (enabled code: `O`)
- `schoolpro_portal_invites` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_promotions` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_promotions` → trigger `schoolpro_archive_applied_progression` → function `schoolpro_archive_progression` (enabled code: `O`)
- `schoolpro_question_bank` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_access_pins` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_approvals` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_corrections` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_domain_definitions` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_domain_ratings` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_events` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_rating_scale` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_templates` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_term_settings` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_result_term_settings` → trigger `schoolpro_validate_calendar` → function `schoolpro_validate_calendar` (enabled code: `O`)
- `schoolpro_result_verifications` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_results` → trigger `calculate_schoolpro_result_total` → function `calculate_result_total` (enabled code: `O`)
- `schoolpro_results` → trigger `enforce_schoolpro_result_relations` → function `enforce_schoolpro_tenant_relations` (enabled code: `O`)
- `schoolpro_results` → trigger `enforce_schoolpro_result_workflow` → function `enforce_result_workflow` (enabled code: `O`)
- `schoolpro_results` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_results` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_results` → trigger `trg_schoolpro_result_email` → function `queue_schoolpro_transactional_email` (enabled code: `O`)
- `schoolpro_results` → trigger `trg_schoolpro_result_lifecycle_event` → function `log_schoolpro_result_lifecycle` (enabled code: `O`)
- `schoolpro_results` → trigger `trg_schoolpro_result_lock` → function `enforce_schoolpro_result_lock` (enabled code: `O`)
- `schoolpro_results` → trigger `trg_validate_schoolpro_result_tenant` → function `validate_schoolpro_result_tenant` (enabled code: `O`)
- `schoolpro_schools` → trigger `create_default_school_assessment_scheme` → function `create_default_school_assessment_scheme` (enabled code: `O`)
- `schoolpro_schools` → trigger `initialize_assessments_after_activation` → function `create_default_school_assessment_scheme` (enabled code: `O`)
- `schoolpro_schools` → trigger `sync_school_request_activation` → function `sync_school_request_activation` (enabled code: `O`)
- `schoolpro_site_content` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_site_gallery` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_site_news` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_site_settings` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_student_transport` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_student_transport` → trigger `schoolpro_active_pupil_activity` → function `schoolpro_reject_new_inactive_student_activity` (enabled code: `O`)
- `schoolpro_student_transport` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_student_transport` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_students` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_students` → trigger `schoolpro_enrollment_calendar` → function `schoolpro_enrollment_calendar` (enabled code: `O`)
- `schoolpro_students` → trigger `validate_schoolpro_student_class` → function `validate_student_class` (enabled code: `O`)
- `schoolpro_subject_assignments` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_subject_assignments` → trigger `trg_validate_schoolpro_subject_assignment` → function `validate_schoolpro_subject_assignment` (enabled code: `O`)
- `schoolpro_subjects` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_timetable_entries` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)
- `schoolpro_timetable_entries` → trigger `schoolpro_preserve_activity_session` → function `schoolpro_preserve_activity_session` (enabled code: `O`)
- `schoolpro_timetable_entries` → trigger `schoolpro_stamp_activity_period` → function `schoolpro_stamp_activity_period` (enabled code: `O`)
- `schoolpro_transcript_issues` → trigger `schoolpro_transcript_enrichment` → function `schoolpro_transcript_enrichment` (enabled code: `O`)
- `schoolpro_transport_routes` → trigger `schoolpro_activation_before_write` → function `guard_schoolpro_operational_write` (enabled code: `O`)

**Interpretation:** preserve the behavior only after inspecting each complete function body, its dependencies, callers, grants, RLS assumptions, external side effects and transaction semantics. Triggers such as operational-write guards, activity/session stamping, assessment/attendance validation, tenant-relation enforcement, result locking, automatic admission documents and notification hooks are likely behavior-critical. Do not bulk-copy them before replacing Supabase-specific helpers and validating isolation. Catalog names can change as production evolves; refresh this inventory immediately before any export.


## 10. Active-branch application dependency scan — targeted findings

**Branch inspected:** `migration/mysql-schoolpro-foundation`. Source files were fetched and inspected in batches across the `src/` tree, with particular attention to authentication context, school context/permissions, academic/result workflows, fee/payment, staff/invitations, document rendering, storage, student login, and subscription pages. This was a static source scan; no app behavior was executed. The following is a dependency map of confirmed call sites, not a claim that every indirect/dynamic call or non-`src/` script has been exhaustively resolved.

### Direct browser-side database access is a migration blocker

- `src/lib/supabase.ts` initializes `@supabase/supabase-js` in the Vite client using `VITE_SUPABASE_URL` and the public publishable/anon key. This is expected for Supabase public APIs, but it cannot be repointed at a private Aiven database. **Never place Aiven credentials in Vite variables or a mobile bundle.**
- `src/context/AuthContext.tsx` reads shared `profiles`, `admin_product_access`, and `customer_service_access`, and uses Supabase Auth state changes, password sign-in, sign-up, sign-out and password-reset APIs.
- `src/hooks/useSchoolProContext.ts` reads `schoolpro_schools`, `schoolpro_students`, and `schoolpro_guardian_links`; permissions/entitlements/class-scope hooks call `schoolpro_user_permissions`, `schoolpro_subscription_entitlements`, and `schoolpro_coordinator_classes` RPCs.
- Academic screens directly select/insert/update/delete SchoolPro records as well as calling RPCs: examples confirmed include `schoolpro_results`, `schoolpro_classes`, `schoolpro_students`, `schoolpro_subjects`, `schoolpro_assessment_schemes`, `schoolpro_grade_scale`, `schoolpro_result_domain_ratings`, `schoolpro_result_term_settings`, `schoolpro_enrollment_history`, `schoolpro_result_approvals`, and result publication/review/pin RPCs. Direct table calls are widespread, so an API layer will require a systematic adapter/refactor, not just a connection-string change.
- Fee/subscription paths use `schoolpro_invoices`, `schoolpro_fee_payments`, `schoolpro_fee_structures`, `schoolpro_fee_exceptions`, `schoolpro_fee_bank_accounts`, `schoolpro_payment_submissions`, `schoolpro_subscription_catalog`, `schoolpro_plan_catalog`, `schoolpro_subscriptions`, and `schoolpro_subscription_intents`; they call `record_schoolpro_payment`, `generate_schoolpro_class_invoices`, `review_schoolpro_payment_submission`, and related RPCs.
- Other confirmed direct domains include admissions/enrollment, attendance, guardian links, staff/member permissions, assignments/submissions, CBT questions/tests/attempts, question bank, discipline/health, lesson notes, timetable/calendar, hostel/library/transport/payroll, document issues/templates, result templates, transcript settings/issues, notifications, branding and public result/admission paths.
- Shared-profile writes are present: `SchoolProProfile.tsx` updates `profiles`; platform profile/access reads also occur in auth and admin paths. These must remain under the shared identity contract and cannot be indiscriminately moved with SchoolPro tables.

### Confirmed Auth, Storage and Edge Function call sites

- Auth/session: `auth.getUser`, `onAuthStateChange`, `signInWithPassword`, `signUp`, `signOut`, `resetPasswordForEmail`, `setSession`, `verifyOtp`, and `getSession` are used in browser/native flows. Preserve Supabase Auth in the first rehearsal and design server-side token validation before moving database access.
- Storage buckets seen in app source include `direct-transfer-proofs`, `schoolpro-document-templates`, `schoolpro-document-outputs`, `school-result-templates`, and SchoolPro branding/document paths. Storage calls include upload, download and signed URL creation. Bucket/policy/key ownership needs a separate complete inventory.
- Edge Function invokes confirmed include `invite-school-staff`, `schoolpro-student-login`, `schoolpro-account-login`, `schoolpro-email-worker`, `schoolpro-render-document`, `schoolpro-transfer-ownership`, and `auth-handoff`. Additional public-form and operational functions need to be reconciled from the remaining repository and Edge Function list.
- Read-only source retrieval of deployed Edge Function code confirmed `schoolpro-payment` and `schoolpro-subscription` currently return HTTP 410 with a bank-transfer/Finance-review message; their current deployed behavior must be preserved as a contract until deliberately changed. `invite-school-staff` and `auth-handoff` have `verify_jwt=false` but implement explicit token/user validation in code; the flag alone is not a vulnerability verdict. `schoolpro-email-worker` and `schoolpro-render-document` are configured with JWT verification and perform additional identity/record checks. Each still needs full endpoint authorization, storage-ownership, idempotency and side-effect review before porting.

## 11. Foreign-key boundary and tenant ownership

A read-only catalog query found **274 foreign-key constraints involving SchoolPro-prefixed tables**, of which **79 cross the simple SchoolPro-only boundary** (including relationships to shared schemas/tables or tables without a SchoolPro prefix). Examples include:

- SchoolPro actors/owners to `auth.users` and `public.profiles`.
- `schoolpro_payment_intents.virtual_account_id` and subscription payment paths to shared `public.virtual_accounts`.
- Shared `public.payment_transactions` referencing `schoolpro_payment_intents`.
- Shared `public.ihlink_email_queue` referencing `schoolpro_schools`.
- `private.schoolpro_academic_clock` referencing `public.schoolpro_schools`.

This proves the boundary is not a clean prefix-only table dump. For first rehearsal, retain Auth, profiles, virtual accounts, shared payment/queue services and Storage in Supabase. The payment/queue references need an explicit integration contract or narrowly scoped data mapping; do not copy entire shared tables. Preserve stable user UUID references only as IDs, not by cloning Auth credential/session rows.

A column-level scan found 107 public `schoolpro_*` tables; **89 contain a direct `school_id` column and 18 do not**. Missing direct `school_id` does not mean unrelated: some are child tables whose tenant is inherited through a parent FK (e.g. assignment submissions, admission offers/documents, CBT answers, fee items). Others are global/platform catalogs or account-level controls (e.g. `schoolpro_plan_catalog`, `schoolpro_subscription_catalog`, `schoolpro_subscription_plans`, `schoolpro_login_attempts`, `schoolpro_account_challenges`). These need explicit classification rather than being auto-included as tenant data. `schoolpro_schools` is the tenant root and is owner-scoped via `owner_id`.

## 12. Routines, triggers, policies, views, grants and jobs — inspection status

- Live catalog counts: 127 public routines whose names contain `schoolpro`; 160 non-internal triggers on `schoolpro_*` tables or calling a routine whose name contains `schoolpro`; 293 RLS policy rows on SchoolPro-prefixed tables; all 107 SchoolPro-prefixed tables have RLS enabled, but `FORCE ROW LEVEL SECURITY` is false on those tables in the observed catalog.
- Full definitions were fetched and reviewed for a targeted set of 20 high-impact routines, including result-total calculation, result workflow locking, tenant-relation enforcement, result lifecycle logging, subscription expiry, result PIN creation/checking, result review/publication, payment finalization/recording, access invitation acceptance, login throttling, user permissions, subscription entitlements and coordinator class scope. The broader routine/trigger inventories include names/flags, but **all 127 function bodies and all 160 trigger bindings have not yet received complete semantic review**.
- Important observed behavior to preserve: published result score changes are blocked by a trigger; result totals validate component maxima and require assessment scheme school match; tenant relation guards validate result student/subject/scheme and CBT question/test relationships; result publication checks role/module access and writes audit records; fee payment locks the invoice row and checks balance/method/reference; payment gateway finalization routines currently raise a bank-transfer/Finance-review exception.
- 293 SchoolPro RLS policies need full expression/grant semantic review before any Aiven equivalent is accepted. Policies rely on Supabase helpers including `auth.uid()` and `private.*` authorization routines; copying them unchanged to vanilla Aiven would not preserve security. Grants, object owners, default privileges, sequences, types and non-SchoolPro-named views that depend on SchoolPro are still open review items.
- The current `cron.job` inspection returned 7 matching jobs: `schoolpro-expiry-grace-daily` (daily), `schoolpro-academic-calendar` (hourly), shared `ihlink-email-delivery-2m`, and four DataSub/BillStack jobs. DataSub/BillStack jobs are excluded; SchoolPro jobs must be ported only after the target routine/API exists and duplicate execution/side effects are controlled. Supabase Vault and `pg_net` are dependencies in the job commands and are not assumed available on Aiven.

## 13. Migration-ledger drift — blocking discrepancy

A live `list_migrations` read returned **476 recorded Supabase migrations**, latest `20261015161735 schoolpro_access_invitation_role_constraint`. The active branch contains **123 tracked `supabase/migrations/*.sql` files**, latest `20261013100000_schoolpro_result_leaders_read_session_enrolment`. Comparing version strings found **397 live migration versions absent from the branch** and **44 branch migration versions not present in the live ledger**. These sets overlap only partially, so this is not safely explained as a simple lag. Do not replay migrations or generate a dump from repository files as if this branch were a complete source snapshot. Reconcile missing/applied history, deployment provenance and actual catalog schema before creating the final export plan. This discrepancy is a P0 blocker for allowlist approval.

## 14. Allowlist review decision

**Decision: NOT APPROVED FOR EXPORT/IMPORT.** The candidate boundary is sufficiently documented to plan the next reconciliation, but it cannot responsibly be called finalized for migration while (1) migration-ledger drift is unresolved, (2) application call sites have not yet been transformed into a complete machine-readable table/RPC/Auth/Storage/Edge Function manifest, (3) all routine bodies/trigger bindings/policies/grants/dependent views have not been semantically reviewed, and (4) row ownership for inherited-child and global-catalog tables is not signed off.

Before export, complete these exact gates:
- [ ] Reconcile 476 live migration records against 123 branch files; explain all 397 live-only and 44 branch-only versions.
- [ ] Generate a complete application call-site manifest (static scan + review dynamic table/function names), including file/line, operation, role context and owning domain.
- [ ] Export/read all relevant live function definitions, trigger definitions, policies, grants, dependent views/types/sequences and extension dependencies to an audit artifact; review security-definer search paths and callers.
- [ ] Approve a per-table row policy: tenant-owned rows, inherited child rows, global plan/catalog rows, account-level challenge/throttle rows, audit/history, and shared-system references.
- [ ] Resolve all 79 boundary-crossing FKs and define how references to Auth/profiles/virtual accounts/payment transactions/shared queue are preserved without cross-database FK assumptions.
- [ ] Approve a separate Storage decision and object/policy map; keep Supabase Storage for the first rehearsal.
- [ ] Restrict the Aiven target's reported open public allowlist before importing any real data or credentials.
- [ ] Obtain explicit review approval of the allowlist, then rehearse only on the isolated target. No production cutover without separate approval.

No source export, Aiven import, production DDL/DML, Render configuration change, deployment, or PR merge was performed for this review. Supabase remains production source of truth; Render remains application host; DataSub/BillStack remain on Supabase and out of scope.


## 15. Catalog evidence artifacts and final review disposition

The following full read-only catalog evidence artifacts are now committed on this branch and should be used together with this allowlist:

- [Live SchoolPro routine definitions](./LIVE-SCHOOLPRO-ROUTINE-DEFINITIONS-2026-10-17.md) — 127 overloads captured across 124 public routine names containing `schoolpro`; 95 SECURITY DEFINER.
- [Live SchoolPro trigger definitions and handler bodies](./LIVE-SCHOOLPRO-TRIGGER-DEFINITIONS-2026-10-17.md) — 160 trigger bindings and 39 unique handler names/definitions.
- [Boundary catalog snapshot](./SCHOOLPRO-BOUNDARY-CATALOG-SNAPSHOT-2026-10-17.md) — all 293 public SchoolPro RLS policy expressions, 274 foreign keys involving SchoolPro-prefixed tables, 2,816 table-grant rows, seven relevant scheduled jobs, and seven extensions.
- [Routine ACL, ownership and sequence snapshot](./SCHOOLPRO-ROUTINE-ACL-OWNERSHIP-SEQUENCES-2026-10-17.md) — 512 routine ACL rows, relation owners/RLS flags, and sequence inventory.
- [Migration-ledger reconciliation](./SUPABASE-MIGRATION-LEDGER-RECONCILIATION-2026-10-17.md) — complete version-name diff between live ledger and branch migration files.

### Final allowlist review

The candidate table list is reviewed as a **migration-planning boundary only**, not a final import list. Current recommendation is to preserve these categories: (A) school-owned operational records and their inherited child records, subject to per-table ownership and FK review; (B) global SchoolPro plan/catalog data as reviewed seed/configuration, not tenant records; (C) shared identity/payment/Storage/queue dependencies excluded from bulk copy; (D) DataSub/BillStack and other IHLink product records excluded.

**Approval is withheld (P0) until migration-ledger drift is reconciled.** The live ledger has 476 entries; this branch has 123 migration files; only 79 versions match, with 397 live-only and 44 branch-only. The exact lists are in the reconciliation document. Also, the call-site scan confirms widespread direct browser-side Supabase table/RPC use, but a line-by-line machine-readable call-site manifest has not yet been generated. Therefore the migration boundary is not yet finalized for export. Do not export/import any data until the ledger diff, call-site manifest and object semantics have been signed off.


## Provenance investigation update — 2026-10-17

### Evidence found in repository history and active GitHub Actions

- The current branch tree contains 123 numbered `supabase/migrations/*.sql` files, but **no `supabase/config.toml` and no Supabase deployment workflow**. The visible workflows are app CI, mobile builds, payment validation, and a draft MySQL schema test; none establishes a complete automated history of applying the 476 production ledger entries.
- The current `.github/workflows/ci.yml` tests the app and a disposable MySQL API/schema. It does not run `supabase db push`, apply Supabase migrations to production, or reconcile the production migration ledger.
- The current `.github/workflows/mysql-schoolpro-schema.yml` is explicitly a draft-schema CI workflow and applies only `database/mysql/*.sql` to a disposable MySQL 8.4 service. It is not provenance for the historical Supabase ledger.
- Repository migration `supabase/migrations/20260926114500_schoolpro_remote_migration_sync_ledger.sql` states that a batch of remote migrations was applied directly to production through the Supabase migration API after `20260925210000_expand_schoolpro_datasub_features`. The file explicitly says it does **not** replay the inferred production DDL; it records a synchronization boundary through `20260926102630 schoolpro_completion_security_cleanup` and ends with `select 1;`. Therefore this file is a ledger/provenance note, **not executable schema source** for the migrations it names.
- PR #79 (“Align operational migration filenames with applied history”, merged 2026-10-10) states that four operational migration filenames were aligned with versions already recorded in live history and that SQL contents were unchanged. This proves at least one historical reconciliation was filename/ledger-oriented, but it does not explain the current 397 live-only and 44 branch-only version sets as a whole. The PR's recorded preview deployment is legacy Vercel evidence, not evidence of database deployment; Render remains the current app host.
- Recent GitHub Actions runs on 2026-10-17 are PR-triggered validation runs for SchoolPro CI, MySQL schema draft, and payment pages. These validate the current code branch but are not production Supabase migration-application records.

### Current provenance conclusion

The **authoritative source for current object state is the live Supabase catalog**, and the **live migration ledger is authoritative only for which versions the database records as applied**. Neither alone identifies the exact SQL artifact and commit that produced every live object. Repository filenames, commit messages, and PR success are not sufficient to infer missing SQL. The 397 live-only versions remain without complete immutable SQL/CI provenance in the inspected branch; the 44 branch-only versions remain unexplained as applied/not-applied dispositions.

### Required disposition for the 397/44 sets

For each version, add a row to the reconciliation register with: version/name; ledger status; exact SQL artifact URL + blob SHA if recovered; repository/branch/commit; CI run ID and deployment actor/time if available; target object(s); live catalog evidence; schema-diff result; scope (SchoolPro/shared/DataSub); disposition (already reflected, absent, superseded, intentionally draft, duplicate/renamed, or unresolved); reviewer and evidence link. Use “unresolved” rather than guessing when artifact or deployment proof is missing.

Do not run historical SQL to “catch up”, replay any ledger entry, reset migration history, or reconstruct SQL from migration names. The safe path is read-only catalog-to-artifact reconciliation, then a reviewed forward-only target schema plan. Export/import remains blocked.


## Follow-up artifacts added — 2026-10-17

- [Application call-site manifest index](APPLICATION-CALLSITE-MANIFEST-INDEX-2026-10-17.md) links 13 machine-readable JSONL shards covering a static line scan of all 190 `src/` TypeScript/JavaScript files. This is a candidate manifest, not an exhaustive AST/runtime call graph; dynamic, aliased and multiline call sites remain a review item.
- [Per-table ownership register](SCHOOLPRO-PER-TABLE-OWNERSHIP-REGISTER-2026-10-17.md) classifies the 89 direct-`school_id` candidate tables and records proposed ownership dispositions for all 18 tables without that column. It does not claim row-level validation is complete.
- The 18 exceptions are classified as tenant root, inherited-parent child rows, platform-wide catalogues, account-level challenges, and unscoped security telemetry. Parent/child school consistency, secret/token handling, catalog source-of-truth and retention still require read-only validation before export.
- Provenance investigation found no Supabase deploy workflow in the branch's workflow inventory. The current CI workflows do not prove historical production database deployment. The 397 live-only and 44 branch-only migration versions remain unresolved at artifact/commit/disposition level.

**Decision unchanged:** no export/import, migration replay, production writes, Render changes, or cutover until provenance reconciliation and row-level ownership validation are approved.


## Provenance follow-up — 2026-10-17

The migration reconciliation addendum now records additional immutable evidence: `main` and `migration/mysql-schoolpro-foundation` both contain the same 123 numbered migration files; current CI validates app code and a disposable MySQL draft, not production Supabase migration deployment; commit `a6da195` documents a 33-version direct-to-production Supabase API batch but intentionally omits its DDL; PR #79 provides only narrow filename reconciliation evidence; and commit `61afde6` captures some live result/CBT parity but is not a complete deployment log. These findings narrow provenance for a subset but do not resolve the 397/44 sets. All other version dispositions remain unresolved unless individually evidenced. Export/import remains blocked.


## Migration provenance disposition register — 2026-10-17

See [Branch-only migration disposition register](BRANCH-ONLY-MIGRATION-DISPOSITION-REGISTER-2026-10-17.md) for one-by-one source-history and live-catalog evidence on all 44 branch-only versions. It identifies the 33-version production sync marker as non-replayable provenance documentation and records the current schema mismatches for tenant-isolation, guardian/CBT/document integrity, family-result and subscription-plan objects. Current object presence must not be interpreted as exact migration deployment evidence.

The source inventory remains an allowlist proposal only. Export/import is not approved until original SQL/deployment provenance is recovered and the full schema/tenant ownership review is signed off.


## Alternate-branch/source-history search — 2026-10-17

Inspected `fix/operational-migration-history-oct10` as well as `migration/mysql-schoolpro-foundation`; the alternate branch has 55 numbered migrations and does not recover the original 33-version SQL batch. Code/commit search for two representative remote-only names (`schoolpro_admission_lifecycle`, `schoolpro_completion_security_cleanup`) returned no indexed matches. Several of the 44 branch-only files were added to current history by “Restore … migration” commits; these are not deployment proofs. Full source/deployment evidence remains outstanding.


## Scope-classified live-only ledger — 2026-10-17

Added [Live-only migration version inventory](LIVE-ONLY-MIGRATION-VERSION-INVENTORY-2026-10-17.md) with all 397 versions, one row per exact live-ledger version, and provisional buckets separating SchoolPro candidates (161), DataSub/BillStack (65), shared-platform/other product (95) and unclassified/mixed (76). These are name-based triage labels only; each SQL's touched objects/dependencies still need inspection before a final scope assignment.

Added [remote-batch provenance register](REMOTE-BATCH-SQL-DEPLOYMENT-PROVENANCE-REGISTER-2026-10-17.md). It corrects a count discrepancy: the sync marker enumerates 35 distinct versions, not 33. All 35 match the live ledger, but original SQL and independent deployment audit events remain unrecovered. The source inventory remains a proposal, not export approval.

See [live tenant-relation reconciliation](LIVE-TENANT-RELATION-CATALOG-RECONCILIATION-2026-10-17.md) for current replacement trigger functions, 17 zero-mismatch cross-school checks, missing-object model differences and the issued-document policy predicate defect. No production changes were made.