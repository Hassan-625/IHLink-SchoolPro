# Supabase migration-ledger reconciliation — SchoolPro Aiven migration gate

**Date:** 2026-10-17  
**Branch:** `migration/mysql-schoolpro-foundation`  
**Source project:** `lnqsroyiybutkfngbyge`  
**Mode:** read-only comparison of Supabase migration ledger and repository filenames. No migrations were applied or replayed.

## Summary

- Live ledger rows: **476**
- Tracked `supabase/migrations/*.sql` files: **123** (unique versions 123)
- Exact version intersection: **79**
- Live ledger versions absent from branch: **397**
- Branch versions absent from live ledger: **44**
- Latest live record: `20261015161735 schoolpro_access_invitation_role_constraint`
- Latest tracked file: `20261013100000 schoolpro_result_leaders_read_session_enrolment`

This is material schema-history drift. A migration ledger is not necessarily a full SQL archive; applied migrations may have been introduced outside this branch, and branch-only migrations may be drafts, reverted migrations, or migrations intended for another environment. Names/version strings alone do not resolve those possibilities. **Do not replay any set based solely on this diff.** Obtain the authoritative migration source/CI deployment history and compare actual deployed catalog definitions.

## Live ledger entries missing from the active branch (397)

- `20260916133310` — create_auth_roles_and_access_control
- `20260916133414` — optimize_access_policies_and_indexes
- `20260917000302` — index_subject_allocations_by_subject
- `20260917002849` — website_content_management
- `20260917003439` — website_content_media_storage
- `20260917005129` — seed_managed_homepage_heroes
- `20260917104456` — customer_service_access
- `20260917105841` — scoped_platform_access
- `20260917180631` — harden_reseller_applications
- `20260920140119` — datasub_api_credentials_usage
- `20260920140219` — datasub_advisor_fixes
- `20260920142124` — t2_and_datasub_api_gateway
- `20260920143437` — datasub_reseller_commissions
- `20260920144207` — datasub_provider_operations
- `20260920145208` — datasub_automated_wallet_payments
- `20260920193850` — schoolpro_finance_and_result_access
- `20260920195100` — datasub_catalog_categories_and_complete_admin
- `20260920195234` — public_active_datasub_catalog
- `20260920195305` — remove_security_definer_catalog_view
- `20260920200325` — schoolpro_parent_portal
- `20260920201042` — schoolpro_online_fee_payments
- `20260921112435` — host_commerce_operations
- `20260921113908` — domain_registry_policies
- `20260921113940` — consult_project_operations
- `20260921114031` — consult_policy_performance
- `20260921115428` — consult_delivery_workspace
- `20260921165940` — engineering_operations
- `20260921171802` — central_support_operations
- `20260921173330` — central_finance_operations
- `20260921215944` — notification_centre
- `20260921220139` — notification_advisor_repairs
- `20260921221657` — security_centre_operations
- `20260921222945` — launch_readiness_and_recovery
- `20260921223103` — optimize_launch_readiness_rls
- `20260922115146` — import_supplied_datasub_catalog_add_new_only
- `20260922120551` — datasub_upgrade_promotions
- `20260922120649` — optimize_datasub_upgrade_promotions
- `20260922162610` — customer_profile_and_smart_earner
- `20260922162644` — fix_customer_profile_update_policy
- `20260922202415` — password_login_lockout_tracking
- `20260922203710` — schoolpro_result_template_builder
- `20260923105146` — business_innovation_foundation
- `20260923165350` — consult_business_operations
- `20260923165549` — consult_operations_index_hardening
- `20260923170417` — platform_internal_backend_and_superadmin_full_access
- `20260923170502` — core_platform_internal_workflow_completion
- `20260923171133` — expand_platform_integration_products
- `20260923171149` — engineering_complete_operations_v2
- `20260923171714` — host_complete_operations
- `20260923173158` — business_innovation_complete_backend_v2
- `20260923182030` — expand_business_innovation_catalog
- `20260923184341` — fix_schoolpro_guardian_rls_correlations
- `20260923184347` — complete_internal_rls_policies
- `20260924112325` — schoolpro_secure_public_result_checker
- `20260924112435` — schoolpro_complete_internal_modules_and_student_accounts
- `20260924114318` — harden_datasub_api_credential_functions
- `20260924144655` — harden_rpc_and_customer_platform_access
- `20260924145010` — complete_platform_signup_access_and_function_defaults
- `20260924191111` — datasub_multi_provider_routing_core
- `20260925191607` — harden_datasub_refund_idempotency
- `20260925202150` — datasub_airtime_catalog_and_account_deletion_requests
- `20260925203416` — schoolpro_core_academic_workflows_v2
- `20260925203812` — expand_schoolpro_and_datasub_feature_foundations
- `20260925205250` — schoolpro_learning_and_white_label_foundations
- `20260925205302` — schoolpro_learning_white_label_rls
- `20260925205450` — schoolpro_cbt_submission_rls
- `20260925210820` — schoolpro_admission_lifecycle
- `20260925211458` — expand_school_member_roles
- `20260925211509` — schoolpro_admission_communications
- `20260925211837` — schoolpro_public_admission_and_candidate_cbt
- `20260925212303` — schoolpro_custom_managed_websites
- `20260925213322` — schoolpro_managed_site_provisioning
- `20260925213536` — schoolpro_new_tables_rls
- `20260925213705` — schoolpro_admission_documents_candidate_tokens
- `20260925213836` — schoolpro_enrollment_and_portal_invites
- `20260925214057` — schoolpro_candidate_cbt_secure_flow
- `20260925214223` — schoolpro_admission_officer_workflow
- `20260925214636` — schoolpro_document_verification_and_cbt_assignment
- `20260925215753` — schoolpro_management_authorization_helper
- `20260925220129` — schoolpro_broadsheet_reporting
- `20260925220153` — schoolpro_offline_payment_recording
- `20260925220434` — schoolpro_result_publication
- `20260926084225` — schoolpro_secure_offer_acceptance
- `20260926084244` — schoolpro_candidate_cbt_hardening
- `20260926084255` — schoolpro_role_and_enrollment_hardening
- `20260926084351` — schoolpro_safe_public_application
- `20260926090548` — schoolpro_result_review_and_default_assessment
- `20260926090600` — schoolpro_library_and_promotion_workflows
- `20260926090701` — schoolpro_revoke_internal_workflows_from_anon
- `20260926091005` — schoolpro_three_education_level_assessment_standards
- `20260926091653` — schoolpro_theory_marking_and_subscription_control
- `20260926092047` — schoolpro_health_documents_and_entitlements
- `20260926092538` — schoolpro_email_queue_reliability
- `20260926101318` — schoolpro_cbt_eligibility_controls
- `20260926101535` — schoolpro_secure_student_cbt_execution
- `20260926101605` — schoolpro_student_cbt_listing
- `20260926101655` — tighten_schoolpro_cbt_helper_grants
- `20260926102010` — schoolpro_results_finance_operations_completion
- `20260926102055` — schoolpro_result_lock_enforcement
- `20260926102147` — schoolpro_transactional_email_events
- `20260926102630` — schoolpro_completion_security_cleanup
- `20260926114442` — schoolpro_remote_migration_sync_ledger
- `20260926114927` — schoolpro_operational_authorization_cleanup
- `20260926115529` — schoolpro_document_template_studio
- `20260926125923` — schoolpro_document_lifecycle_completion
- `20260926134501` — datasub_market_pricing_control
- `20260926134812` — datasub_secure_transaction_pin
- `20260926134915` — datasub_route_scope_hardening
- `20260926135256` — datasub_pin_pgcrypto_fix
- `20260926195324` — harden_datasub_privileged_rpc_execution
- `20260926201214` — fix_public_datasub_catalogue_startup_permissions
- `20260926201714` — fix_datasub_public_pricing_policy
- `20260927100016` — harden_billstack_atomic_wallet_credit
- `20260927100046` — protect_billstack_provider_payload_from_customers
- `20260927100625` — configurable_billstack_wallet_funding_fee
- `20260927100952` — billstack_net_wallet_credit_and_margin_accounting
- `20260927101406` — central_payment_platform_registry
- `20260927103424` — fix_schoolpro_invoice_exception_semantics
- `20260927103449` — schoolpro_billstack_gateway_policy
- `20260927104522` — schoolpro_billstack_invoice_transfer_intents
- `20260927104648` — schoolpro_single_pending_billstack_transfer
- `20260927105705` — schoolpro_direct_school_bank_collection
- `20260927113116` — schoolpro_parent_payment_proof_review
- `20260927113220` — schoolpro_subscription_payments_and_receipt_policies
- `20260927113707` — schoolpro_multi_child_general_school_payments
- `20260927113725` — schoolpro_multi_child_payment_workflows
- `20260927114957` — schoolpro_ihlink_subscription_catalog
- `20260927115005` — schoolpro_ihlink_subscription_intents
- `20260927115014` — schoolpro_subscription_catalog_seed
- `20260927115024` — schoolpro_subscription_finalize_rpc
- `20260927115058` — schoolpro_subscription_rls
- `20260927115924` — host_billstack_payment_and_provisioning_separation
- `20260927120000` — host_authoritative_order_creation
- `20260927120050` — host_renewal_and_provisioning_lifecycle
- `20260927120440` — host_provisioning_role_and_adapter_access
- `20260927120500` — host_provisioning_authorized_roles
- `20260927120547` — host_billstack_registry_policy
- `20260927120833` — host_prevent_client_price_tampering
- `20260927120851` — host_domain_availability_before_payment
- `20260927131035` — host_provider_automation_jobs
- `20260927131252` — host_invoice_payment_provisioning_lifecycle
- `20260927132841` — consult_proposal_document_center
- `20260927133225` — consult_proposal_workflow_and_invoice_acceptance
- `20260927133320` — consult_billstack_invoice_payment_lifecycle
- `20260927133403` — consult_extended_business_features
- `20260927151121` — engineering_payment_documents_completion
- `20260929124719` — 20260929112500_business_orders_unit_scope
- `20260929124720` — 20260929120500_host_order_type_from_plan
- `20260929193851` — payment_integrity_exact_amounts_and_wallet_replay
- `20260929203708` — print_staff_permission_separation
- `20260929203846` — schoolpro_module_permission_enforcement
- `20260930005507` — business_specialist_workflows
- `20260930011331` — business_invoice_payments
- `20260930011507` — business_quote_approval
- `20260930012144` — schoolpro_rpc_module_guards
- `20260930012406` — print_atomic_requests
- `20260930012455` — schoolpro_broadsheet_module_guard
- `20260930013054` — print_public_catalog
- `20260930013637` — business_fulfilment_and_content
- `20260930015944` — print_invoice_verified_guard
- `20260930020027` — print_paid_invoice_status_guard
- `20260930103812` — print_guarded_operational_actions_20260930
- `20260930144045` — business_public_active_catalog_20260930
- `20261001132820` — schoolpro_enforce_active_profile_access
- `20261001133457` — account_deletion_request_hardening
- `20261001142751` — account_deletion_super_admin_review
- `20261001144333` — schoolpro_broadsheet_published_results_only
- `20261001144349` — fix_schoolpro_document_cross_school_rls
- `20261001144946` — restrict_consult_payment_writes_to_verified_settlement
- `20261001145938` — remove_overbroad_specialist_active_account_policies
- `20261001160039` — enable_business_centre_backend_parity
- `20261001183459` — add_isolated_ecosystem_qa_harness
- `20261001185746` — configure_commercial_pricing_and_school_fee_bank_details_v2
- `20261001190233` — central_template_studio_and_schoolpro_dual_invoice_model
- `20261001190522` — central_template_rendering_api
- `20261001191917` — enhance_central_document_templates_and_datasub_receipt
- `20261001192446` — payment_outcome_and_idempotent_refund_queue
- `20261001192532` — auto_queue_refund_on_failed_paid_fulfilment
- `20261001193211` — central_direct_bank_transfer_option
- `20261001193535` — exclude_datasub_from_direct_transfer_and_secure_platform_allowlist
- `20261002103931` — configure_ihlink_local_bank_accounts_oct_2026
- `20261002104725` — document_template_precedence_and_branding
- `20261002104907` — expand_template_studio_document_family
- `20261002105500` — automatic_ihlink_document_registry_v2
- `20261002105510` — schoolpro_school_owned_branding_rules
- `20261002111026` — schoolpro_super_admin_action_access_and_document_rls_fix
- `20261002112222` — embed_ihlink_logo_inside_document_templates
- `20261002115217` — academy_certificate_template_designer
- `20261002115935` — expand_website_builder_and_platform_feature_content
- `20261002120149` — site_navigation_builder
- `20261002120427` — website_section_templates
- `20261002120615` — academy_learning_operations
- `20261002122138` — security_tighten_template_and_payment_rpcs
- `20261002122612` — academy_certificate_rendered_outputs
- `20261002132708` — academy_course_commerce
- `20261002132721` — academy_payment_reconciliation
- `20261002132735` — academy_use_shared_commerce
- `20261002132827` — academy_course_checkout_and_access
- `20261002133307` — schoolpro_atomic_library_and_hostel_operations
- `20261002134138` — secure_print_admin_helper
- `20261002134348` — tighten_customer_payment_rpc_execution
- `20261002134701` — direct_transfer_proof_and_finance_review
- `20261002134713` — direct_transfer_receipt_storage
- `20261002135612` — remove_obsolete_academy_order_finalizer
- `20261002135813` — harden_schoolpro_subscription_billstack_finalizer
- `20261002135831` — academy_session_paid_access_rls
- `20261002142128` — datasub_provider_automatic_routing_control
- `20261002143519` — schedule_datasub_transaction_reconciliation
- `20261002143824` — remove_legacy_flutterwave_datasub_payment
- `20261002143940` — remove_obsolete_datasub_purchase_rpc
- `20261002144053` — remove_obsolete_manual_datasub_provider_activation
- `20261002144239` — academy_assignment_enrollment_and_submission_rls
- `20261002144307` — academy_scoped_assignment_grading_rpc
- `20261002145248` — restrict_datasub_pending_service_request_mutation
- `20261002145614` — academy_course_scoped_instructor_assignment_access
- `20261002145839` — restrict_trigger_only_academy_enrollment_activation
- `20261002145955` — scope_direct_transfer_review_to_platform_access
- `20261002150108` — tighten_host_provisioning_and_global_payment_governance
- `20261002150517` — schoolpro_configurable_result_domains_and_ratings
- `20261002150734` — schoolpro_result_media_and_term_settings
- `20261002152201` — schoolpro_result_class_rank_rpc
- `20261002153057` — schoolpro_generated_result_outputs
- `20261002153856` — schoolpro_secure_result_output_access
- `20261002154148` — schoolpro_result_verification_registry
- `20261002155051` — schoolpro_configurable_grade_scale
- `20261002160359` — schoolpro_overall_grade_and_configurable_remarks
- `20261002160921` — schoolpro_result_media_super_admin_storage_access
- `20261003102726` — revoke_anon_set_default_template
- `20261003102803` — direct_transfer_read_compatibility_view
- `20261003102859` — harden_direct_transfer_invoice_ownership
- `20261003102948` — harden_direct_transfer_approval_integrity
- `20261003103133` — harden_schoolpro_billstack_transfer_transaction_binding
- `20261003103243` — harden_failed_fulfilment_refund_amount
- `20261003103342` — controlled_finance_refund_transitions
- `20261003103817` — remove_public_template_rpc_execution
- `20261003103915` — route_schoolpro_transfers_to_dedicated_workflow
- `20261003104014` — make_super_admin_limit_concurrency_safe
- `20261003104448` — harden_schoolpro_hostel_library_tenant_bindings
- `20261003104500` — harden_schoolpro_library_borrower_tenant_binding
- `20261003104601` — harden_schoolpro_rank_and_theory_marking
- `20261003104729` — enforce_schoolpro_cross_table_tenant_integrity
- `20261003104939` — tighten_schoolpro_sensitive_rls_composition
- `20261003105207` — secure_schoolpro_generated_output_storage
- `20261003105451` — align_result_output_storage_with_academic_roles
- `20261003105627` — harden_verified_wallet_credit_and_retire_legacy_schoolpro_settlement
- `20261003105730` — restrict_account_deletion_queue_to_super_admin
- `20261003105834` — force_direct_transfer_writes_through_validated_rpcs
- `20261003110226` — canonicalize_refunds_to_payment_transaction
- `20261003110355` — restrict_internal_template_renderers_to_service_role
- `20261003110503` — fix_schoolpro_academic_health_rls_tenant_binding
- `20261003110519` — fix_schoolpro_module_records_rls_tenant_binding
- `20261003110653` — tighten_schoolpro_audit_payroll_invite_rls
- `20261003111212` — tighten_schoolpro_discipline_hostel_inventory_library_rls
- `20261003111312` — tighten_schoolpro_transport_promotions_leave_lessons_calendar_rls
- `20261003111450` — harden_schoolpro_assignment_cbt_direct_table_access
- `20261003111622` — restrict_schoolpro_question_bank_and_test_question_visibility
- `20261003111726` — split_schoolpro_cbt_authoring_and_exam_control_authority
- `20261003111821` — separate_schoolpro_cbt_draft_authoring_from_publication
- `20261003112006` — secure_schoolpro_cbt_theory_marking_and_score_finalization
- `20261003112059` — serialize_schoolpro_cbt_answer_save_and_submission
- `20261003112209` — serialize_schoolpro_cbt_attempt_creation
- `20261003112317` — enforce_schoolpro_cbt_eligibility_tenant_and_revocation_integrity
- `20261003112424` — harden_candidate_cbt_token_lifecycle_and_concurrency
- `20261003112541` — tighten_candidate_cbt_results_and_admissions_score_integrity
- `20261003112640` — add_candidate_cbt_theory_marking_and_finalization
- `20261003112741` — close_schoolpro_admission_helper_bypass
- `20261003112913` — rotate_schoolpro_admission_offer_tokens_on_reissue
- `20261003113029` — bind_schoolpro_acceptance_to_current_offer
- `20261003113140` — strengthen_schoolpro_enrollment_student_class_binding
- `20261003113308` — preserve_admission_profile_data_on_student_enrollment
- `20261003113430` — restore_secure_schoolpro_assignment_submission_rpc
- `20261003113817` — secure_schoolpro_assignment_authoring_and_grading
- `20261003114112` — enforce_schoolpro_assignment_class_subject_targeting
- `20261003114251` — enforce_schoolpro_subject_assignment_tenant_and_teacher_integrity
- `20261003114407` — bind_schoolpro_assignments_to_academic_session
- `20261003114552` — bind_schoolpro_result_writes_to_teaching_assignment
- `20261003114648` — harden_schoolpro_result_approval_publication_lifecycle
- `20261003114754` — add_audited_schoolpro_result_correction_workflow
- `20261003115133` — add_secure_schoolpro_bulk_result_import
- `20261003115430` — harden_schoolpro_result_output_and_verification_privacy
- `20261003115527` — scope_schoolpro_teacher_result_reads_to_assignments
- `20261003115654` — scope_schoolpro_broadsheet_to_teacher_class_session
- `20261003115813` — secure_schoolpro_printable_result_output
- `20261003120008` — harden_schoolpro_generated_result_output_access
- `20261003120150` — harden_schoolpro_document_studio_access_and_storage
- `20261003120343` — enforce_schoolpro_document_issuance_lifecycle
- `20261003120357` — make_document_lifecycle_guard_concurrency_safe
- `20261003122217` — centralize_schoolpro_grading_authority
- `20261003122834` — harden_schoolpro_promotion_progression_integrity
- `20261003123016` — bind_document_progression_and_finalize_graduation_state
- `20261003123652` — close_schoolpro_result_mutation_and_deletion_bypasses
- `20261003124002` — complete_schoolpro_results_assignment_cbt_integrity
- `20261003124137` — finish_assignment_storage_and_commercial_guards
- `20261003160942` — schoolpro_annual_subscription_and_four_month_demo_window
- `20261003161108` — schoolpro_catalog_command_center_editing
- `20261003161802` — schoolpro_once_only_four_month_demo_and_expiry_grace
- `20261003161809` — separate_demo_end_from_paid_subscription_grace
- `20261003165518` — secure_academy_learner_assignment_submission
- `20261003165734` — allow_academy_learner_certificate_download
- `20261003170343` — harden_digital_business_quote_and_fulfilment_lifecycle
- `20261003170926` — harden_compute_request_and_usage_integrity
- `20261006091422` — consult_issue_quotation_and_safe_invoice
- `20261006091433` — consult_respond_quotation
- `20261006092714` — schoolpro_paid_or_control_center_activation_gate
- `20261006100434` — consult_commercial_transition_safety
- `20261006102811` — consult_atomic_request_conversion
- `20261006105136` — consult_delivery_and_proposal_linkage
- `20261006105138` — service_invoice_payment_intent_safety
- `20261006110159` — business_print_atomic_invoices
- `20261006110727` — schoolpro_operational_activation_gate
- `20261006111019` — engineering_proposal_invoice_workflow
- `20261006111732` — host_confirmed_provisioning
- `20261006112305` — print_engineering_settlement_receipts
- `20261006112306` — specialist_execution_payment_gate
- `20261006112814` — print_client_approval_and_production_safety
- `20261006113425` — direct_transfer_atomic_reconciliation
- `20261006121031` — require_confirmed_provider_settlement
- `20261006121327` — school_fee_confirmed_settlement
- `20261006153205` — school_subscription_instruction_safety
- `20261006161558` — school_fee_automatic_invoices
- `20261006161559` — school_receiving_account_sync
- `20261006161600` — account_closure_admin_completion
- `20261006161601` — consult_visible_quotation_invoices
- `20261006163113` — super_admin_operational_records
- `20261006205323` — datasub_only_bank_transfers
- `20261006213237` — public_catalogue_role_scope
- `20261007113050` — restore_customer_payment_view_columns
- `20261007155648` — restrict_customer_feature_audiences
- `20261007163659` — lock_invoice_during_bank_proof_submission
- `20261007164143` — school_invoice_customer_read_boundaries
- `20261007175805` — service_invoice_lifecycle_controls
- `20261007181705` — preserve_cancelled_invoice_approval_state
- `20261007203449` — billstack_pending_funding_reconciliation
- `20261007205354` — billstack_verified_paid_wallet_credit
- `20261007210126` — restore_billstack_settlement_gate
- `20261007210536` — billstack_audited_settlement_hold_release
- `20261008051239` — billstack_successful_payment_wallet_credit
- `20261008090331` — schoolpro_invitation_only_workspace_and_student_activation
- `20261008100241` — schoolpro_onboarding_control_center_review
- `20261008101621` — datasub_atomic_ihlinker_wallet_transfer
- `20261008102310` — datasub_verified_referral_program_and_invitation_codes
- `20261008103443` — schoolpro_onboarding_invited_account_provisioning_guard
- `20261008111345` — repair_schoolpro_and_referral_audit_log_targets
- `20261008114404` — defer_default_assessment_setup_until_school_activation
- `20261008114611` — school_workspace_invoice_and_admin_demo_workflow
- `20261008115010` — schoolpro_paid_year_starts_after_demo_conversion
- `20261008121905` — approved_school_owner_demo_and_paid_options
- `20261008122104` — sync_demo_activation_to_supported_request_status
- `20261008152205` — schoolpro_plan_access
- `20261008152951` — schoolpro_free_demo_invoices
- `20261008153324` — schoolpro_student_plan_policy
- `20261008213501` — calendar_reviewed_term_demo
- `20261008213607` — lock_submitted_demo_calendar
- `20261008215815` — schoolpro_paid_annual_grace_consistent_access
- `20261008220257` — datasub_network_availability_and_route_refresh
- `20261008220749` — datasub_explicit_network_outage_events
- `20261008221430` — datasub_network_availability_authorized_review
- `20261009114652` — complete_school_report_presets
- `20261009153654` — datasub_pin_recovery
- `20261009161603` — schoolpro_surname_onboarding
- `20261009171319` — app_device_security_preferences
- `20261009185331` — schoolpro_staff_role_defaults
- `20261009222410` — family_results_and_scoped_classes
- `20261009222815` — private_family_result_rpcs
- `20261009223804` — attendance_result_release_policy
- `20261009224005` — school_code_guardian_access
- `20261009224114` — scoped_attendance_records
- `20261009225347` — school_notice_targeting
- `20261010095532` — structured_lesson_notes
- `20261010160508` — datasub_api_access_callbacks
- `20261010160509` — ecosystem_email_readiness
- `20261010181156` — support_and_school_class_workflows
- `20261010181315` — schoolpro_atomic_fee_bundle
- `20261010181438` — schoolpro_class_publication
- `20261010221217` — schoolpro_edit_fee_bundle
- `20261010221331` — schoolpro_edit_fee_bundle_payment_guard
- `20261010222311` — schoolpro_preserve_class_arm_on_progression
- `20261010224834` — schoolpro_selected_result_publication
- `20261011171831` — datasub_extra_services_and_private_delivery
- `20261011172554` — datasub_keep_vitel_removed_from_customer_catalogue
- `20261012142604` — schoolpro_result_correction_requests_20261012
- `20261012143821` — schoolpro_correction_historical_class_access_20261012
- `20261012143831` — schoolpro_correction_proposed_marks_20261012
- `20261012151121` — schoolpro_publish_class_historical_enrollment_20261012
- `20261012155004` — schoolpro_authorized_staff_read_result_catalogues_20261012
- `20261012155853` — schoolpro_restrict_score_writes_to_authorized_educators_20261012
- `20261012160114` — schoolpro_result_authorized_leadership_score_write_20261012
- `20261012160715` — schoolpro_selected_publication_historical_enrolment_20261012
- `20261012162055` — schoolpro_class_result_submission_records_20261012
- `20261013130436` — restrict_schoolpro_class_result_submission
- `20261013130652` — fix_schoolpro_class_result_submission_school_scope
- `20261013130821` — audit_schoolpro_schoolwide_result_publication
- `20261013175902` — allow_director_position_title_for_school_admin
- `20261013175913` — allow_proprietor_position_title_for_school_owner
- `20261013181250` — secure_schoolpro_ownership_transfer
- `20261013184713` — schoolpro_ownership_transfer_upsert_leadership_title
- `20261015161735` — schoolpro_access_invitation_role_constraint

## Active-branch migration files absent from the live ledger (44)

- `20260920152000` — schoolpro_finance_and_result_access (`supabase/migrations/20260920152000_schoolpro_finance_and_result_access.sql`)
- `20260920210500` — schoolpro_parent_portal (`supabase/migrations/20260920210500_schoolpro_parent_portal.sql`)
- `20260920212500` — schoolpro_online_fee_payments (`supabase/migrations/20260920212500_schoolpro_online_fee_payments.sql`)
- `20260922213500` — schoolpro_result_template_builder (`supabase/migrations/20260922213500_schoolpro_result_template_builder.sql`)
- `20260924112500` — schoolpro_completion (`supabase/migrations/20260924112500_schoolpro_completion.sql`)
- `20260925210000` — expand_schoolpro_datasub_features (`supabase/migrations/20260925210000_expand_schoolpro_datasub_features.sql`)
- `20260926114500` — schoolpro_remote_migration_sync_ledger (`supabase/migrations/20260926114500_schoolpro_remote_migration_sync_ledger.sql`)
- `20260926115500` — schoolpro_operational_authorization_cleanup (`supabase/migrations/20260926115500_schoolpro_operational_authorization_cleanup.sql`)
- `20260926123000` — schoolpro_document_template_studio (`supabase/migrations/20260926123000_schoolpro_document_template_studio.sql`)
- `20260926134500` — schoolpro_document_lifecycle_completion (`supabase/migrations/20260926134500_schoolpro_document_lifecycle_completion.sql`)
- `20260927100500` — schoolpro_role_and_workflow_hardening (`supabase/migrations/20260927100500_schoolpro_role_and_workflow_hardening.sql`)
- `20260927123000` — schoolpro_class_billing_and_subscription_controls (`supabase/migrations/20260927123000_schoolpro_class_billing_and_subscription_controls.sql`)
- `20260927143000` — schoolpro_invoice_permissions_notifications (`supabase/migrations/20260927143000_schoolpro_invoice_permissions_notifications.sql`)
- `20260927170000` — schoolpro_explicit_fee_exceptions (`supabase/migrations/20260927170000_schoolpro_explicit_fee_exceptions.sql`)
- `20260930173000` — capture_result_cbt_hardening (`supabase/migrations/20260930173000_capture_result_cbt_hardening.sql`)
- `20261002123000` — schoolpro_super_admin_action_access_and_document_rls_fix (`supabase/migrations/20261002123000_schoolpro_super_admin_action_access_and_document_rls_fix.sql`)
- `20261002193000` — result_custom_domains_and_term_boundaries (`supabase/migrations/20261002193000_result_custom_domains_and_term_boundaries.sql`)
- `20261002200000` — result_template_media_and_qr_mapping (`supabase/migrations/20261002200000_result_template_media_and_qr_mapping.sql`)
- `20261002213000` — harden_document_verification (`supabase/migrations/20261002213000_harden_document_verification.sql`)
- `20261002233000` — schoolpro_branding_storage (`supabase/migrations/20261002233000_schoolpro_branding_storage.sql`)
- `20261002234500` — schoolpro_operational_tenant_isolation (`supabase/migrations/20261002234500_schoolpro_operational_tenant_isolation.sql`)
- `20261002235500` — schoolpro_operational_rpc_role_alignment (`supabase/migrations/20261002235500_schoolpro_operational_rpc_role_alignment.sql`)
- `20261003000500` — schoolpro_guardian_tenant_hardening (`supabase/migrations/20261003000500_schoolpro_guardian_tenant_hardening.sql`)
- `20261003002000` — schoolpro_cbt_permission_tenant_integrity (`supabase/migrations/20261003002000_schoolpro_cbt_permission_tenant_integrity.sql`)
- `20261003003500` — schoolpro_results_documents_storage_integrity (`supabase/migrations/20261003003500_schoolpro_results_documents_storage_integrity.sql`)
- `20261003170500` — annual_subscription_demo_pricing (`supabase/migrations/20261003170500_annual_subscription_demo_pricing.sql`)
- `20261003173500` — demo_trial_subscription_grace (`supabase/migrations/20261003173500_demo_trial_subscription_grace.sql`)
- `20261008163000` — schoolpro_plan_access (`supabase/migrations/20261008163000_schoolpro_plan_access.sql`)
- `20261008164000` — schoolpro_free_demo_invoices (`supabase/migrations/20261008164000_schoolpro_free_demo_invoices.sql`)
- `20261008165000` — schoolpro_student_plan_policy (`supabase/migrations/20261008165000_schoolpro_student_plan_policy.sql`)
- `20261008214000` — calendar_reviewed_term_demo (`supabase/migrations/20261008214000_calendar_reviewed_term_demo.sql`)
- `20261008221500` — paid_annual_grace (`supabase/migrations/20261008221500_paid_annual_grace.sql`)
- `20261009114332` — complete_school_report_presets (`supabase/migrations/20261009114332_complete_school_report_presets.sql`)
- `20261009160708` — schoolpro_surname_onboarding (`supabase/migrations/20261009160708_schoolpro_surname_onboarding.sql`)
- `20261009170819` — app_device_security_preferences (`supabase/migrations/20261009170819_app_device_security_preferences.sql`)
- `20261009193000` — schoolpro_staff_role_defaults (`supabase/migrations/20261009193000_schoolpro_staff_role_defaults.sql`)
- `20261009221843` — family_results_and_scoped_classes (`supabase/migrations/20261009221843_family_results_and_scoped_classes.sql`)
- `20261009222727` — private_family_result_rpcs (`supabase/migrations/20261009222727_private_family_result_rpcs.sql`)
- `20261009223139` — attendance_result_release_policy (`supabase/migrations/20261009223139_attendance_result_release_policy.sql`)
- `20261009223949` — school_code_guardian_access (`supabase/migrations/20261009223949_school_code_guardian_access.sql`)
- `20261009224048` — scoped_attendance_records (`supabase/migrations/20261009224048_scoped_attendance_records.sql`)
- `20261009225204` — school_notice_targeting (`supabase/migrations/20261009225204_school_notice_targeting.sql`)
- `20261010001000` — structured_lesson_notes (`supabase/migrations/20261010001000_structured_lesson_notes.sql`)
- `20261013100000` — schoolpro_result_leaders_read_session_enrolment (`supabase/migrations/20261013100000_schoolpro_result_leaders_read_session_enrolment.sql`)

## Exact version matches (79)

- `20260916181940` — live: configurable_school_assessments; repository: configurable_school_assessments
- `20260916182533` — live: school_leaders_read_staff_profiles; repository: school_leaders_read_staff_profiles
- `20260916182615` — live: optimize_school_staff_access; repository: optimize_school_staff_access
- `20260916184238` — live: school_result_templates; repository: school_result_templates
- `20260916184554` — live: school_classes; repository: school_classes
- `20260916184746` — live: result_template_indexes; repository: result_template_indexes
- `20260916185703` — live: link_students_to_classes; repository: link_students_to_classes
- `20260916190636` — live: school_academics_attendance_and_superadmin_access; repository: school_academics_attendance_and_superadmin_access
- `20261010110755` — live: school_operations_review; repository: school_operations_review
- `20261010113033` — live: school_allocation_safety; repository: school_allocation_safety
- `20261010113515` — live: school_transport_reassignment; repository: school_transport_reassignment
- `20261010115347` — live: school_payroll_clinic_calendar; repository: school_payroll_clinic_calendar
- `20261011075958` — live: schoolpro_authorized_subject_statistics; repository: schoolpro_authorized_subject_statistics
- `20261011081839` — live: schoolpro_consistent_broadsheet_positions; repository: schoolpro_consistent_broadsheet_positions
- `20261011090930` — live: schoolpro_preserve_graduating_class; repository: schoolpro_preserve_graduating_class
- `20261011091048` — live: schoolpro_target_invoice_notifications; repository: schoolpro_target_invoice_notifications
- `20261011092231` — live: schoolpro_operational_staff_and_fee_breakdown_access; repository: schoolpro_operational_staff_and_fee_breakdown_access
- `20261011124255` — live: schoolpro_board_and_class_coordinator_roles; repository: schoolpro_board_and_class_coordinator_roles
- `20261011124444` — live: schoolpro_form_master_result_review; repository: schoolpro_form_master_result_review
- `20261011124906` — live: schoolpro_coordinator_broadsheet_access; repository: schoolpro_coordinator_broadsheet_access
- `20261011131249` — live: schoolpro_principal_staff_designation; repository: schoolpro_principal_staff_designation
- `20261011131410` — live: schoolpro_academic_leader_result_corrections; repository: schoolpro_academic_leader_result_corrections
- `20261011131448` — live: schoolpro_principal_module_permissions; repository: schoolpro_principal_module_permissions
- `20261011165248` — live: schoolpro_preserve_academic_enrollment_history; repository: schoolpro_preserve_academic_enrollment_history
- `20261011165344` — live: schoolpro_broadsheets_use_session_enrollment_history; repository: schoolpro_broadsheets_use_session_enrollment_history
- `20261011170620` — live: schoolpro_issued_transcript_workflow; repository: schoolpro_issued_transcript_workflow
- `20261011170836` — live: schoolpro_transcript_active_access; repository: schoolpro_transcript_active_access
- `20261011170959` — live: schoolpro_broadsheet_explicit_session_enrollment; repository: schoolpro_broadsheet_explicit_session_enrollment
- `20261011171439` — live: schoolpro_transcript_session_access; repository: schoolpro_transcript_session_access
- `20261011175009` — live: schoolpro_cache_request_access_for_large_registers; repository: schoolpro_cache_request_access_for_large_registers
- `20261011175424` — live: schoolpro_short_circuit_result_reader_permissions; repository: schoolpro_short_circuit_result_reader_permissions
- `20261011175553` — live: schoolpro_keep_result_reader_checks_in_private_lookup; repository: schoolpro_keep_result_reader_checks_in_private_lookup
- `20261011175842` — live: schoolpro_estimate_single_result_access_check; repository: schoolpro_estimate_single_result_access_check
- `20261011180013` — live: schoolpro_avoid_whole_result_row_permission_materialization; repository: schoolpro_avoid_whole_result_row_permission_materialization
- `20261011180051` — live: schoolpro_reject_inactive_result_requests_before_scan; repository: schoolpro_reject_inactive_result_requests_before_scan
- `20261011183101` — live: schoolpro_allow_graduate_account_activation; repository: schoolpro_allow_graduate_account_activation
- `20261011183413` — live: schoolpro_finalize_authorized_testing_certificates; repository: schoolpro_finalize_authorized_testing_certificates
- `20261011183448` — live: schoolpro_accept_testing_academy_certificate_brand_name; repository: schoolpro_accept_testing_academy_certificate_brand_name
- `20261011183604` — live: schoolpro_preserve_assigned_teacher_historical_result_access; repository: schoolpro_preserve_assigned_teacher_historical_result_access
- `20261011183754` — live: schoolpro_cache_authorized_result_student_scope; repository: schoolpro_cache_authorized_result_student_scope
- `20261011184043` — live: schoolpro_compute_teacher_and_family_result_scope_once; repository: schoolpro_compute_teacher_and_family_result_scope_once
- `20261011184141` — live: schoolpro_index_authorized_result_registers; repository: schoolpro_index_authorized_result_registers
- `20261011184249` — live: schoolpro_cache_family_result_holds_by_academic_period; repository: schoolpro_cache_family_result_holds_by_academic_period
- `20261011184316` — live: schoolpro_index_family_result_hold_lookup; repository: schoolpro_index_family_result_hold_lookup
- `20261011215950` — live: schoolpro_academic_calendar_and_student_transfers; repository: schoolpro_academic_calendar_and_student_transfers
- `20261011220307` — live: schoolpro_stamp_calendar_period_on_new_activities; repository: schoolpro_stamp_calendar_period_on_new_activities
- `20261011220422` — live: schoolpro_allow_updates_to_existing_academic_calendar; repository: schoolpro_allow_updates_to_existing_academic_calendar
- `20261011220501` — live: schoolpro_guard_calendar_leadership_and_transfer_reactivation; repository: schoolpro_guard_calendar_leadership_and_transfer_reactivation
- `20261011223200` — live: schoolpro_end_transport_and_hostel_assignments_on_transfer_out; repository: schoolpro_end_transport_and_hostel_assignments_on_transfer_out
- `20261011223631` — live: schoolpro_align_calendar_staff_permissions_with_management_controls; repository: schoolpro_align_calendar_staff_permissions_with_management_controls
- `20261011225048` — live: schoolpro_scope_fee_generation_to_session_enrolment_history; repository: schoolpro_scope_fee_generation_to_session_enrolment_history
- `20261011225122` — live: schoolpro_use_enrolment_query_alias_for_session_fee_scope; repository: schoolpro_use_enrolment_query_alias_for_session_fee_scope
- `20261011230828` — live: schoolpro_print_historical_results_with_caller_row_permissions; repository: schoolpro_print_historical_results_with_caller_row_permissions
- `20261011231101` — live: schoolpro_rank_and_report_using_historical_session_class; repository: schoolpro_rank_and_report_using_historical_session_class
- `20261012070029` — live: schoolpro_bulk_year_end_academic_actions; repository: schoolpro_bulk_year_end_academic_actions
- `20261012071752` — live: schoolpro_transcript_attendance_ratings_and_officers; repository: schoolpro_transcript_attendance_ratings_and_officers
- `20261012072149` — live: schoolpro_transcript_snapshot_signature_scope; repository: schoolpro_transcript_snapshot_signature_scope
- `20261012073159` — live: schoolpro_validate_attendance_against_session_enrolment; repository: schoolpro_validate_attendance_against_session_enrolment
- `20261012073516` — live: schoolpro_transcript_preserve_subject_identity_and_upgrade_copies; repository: schoolpro_transcript_preserve_subject_identity_and_upgrade_copies
- `20261012075706` — live: schoolpro_operational_session_history; repository: schoolpro_operational_session_history
- `20261012075811` — live: schoolpro_selected_session_library_and_transport; repository: schoolpro_selected_session_library_and_transport
- `20261012080212` — live: schoolpro_guard_operational_dates_in_selected_session; repository: schoolpro_guard_operational_dates_in_selected_session
- `20261012081004` — live: schoolpro_timetable_session_history; repository: schoolpro_timetable_session_history
- `20261012081154` — live: schoolpro_allow_safe_legacy_payroll_session_annotation; repository: schoolpro_allow_safe_legacy_payroll_session_annotation
- `20261012081155` — live: schoolpro_family_historical_assignment_and_timetable_access; repository: schoolpro_family_historical_assignment_and_timetable_access
- `20261012081350` — live: schoolpro_require_historical_enrolment_for_family_activity; repository: schoolpro_require_historical_enrolment_for_family_activity
- `20261012082643` — live: schoolpro_historical_attendance_class_scope; repository: schoolpro_historical_attendance_class_scope
- `20261012082742` — live: schoolpro_family_read_selected_session_activity; repository: schoolpro_family_read_selected_session_activity
- `20261012082824` — live: schoolpro_family_timetable_read_without_staff_write_access; repository: schoolpro_family_timetable_read_without_staff_write_access
- `20261012083056` — live: schoolpro_safe_legacy_leave_session_annotation; repository: schoolpro_safe_legacy_leave_session_annotation
- `20261012112531` — live: schoolpro_family_read_own_attendance_subjects_and_library; repository: schoolpro_family_read_own_attendance_subjects_and_library
- `20261012112730` — live: schoolpro_family_borrowed_book_details; repository: schoolpro_family_borrowed_book_details
- `20261012112914` — live: schoolpro_bound_family_class_checks_without_nested_rls_scans; repository: schoolpro_bound_family_class_checks_without_nested_rls_scans
- `20261012121241` — live: schoolpro_bounded_teacher_allocation_policy; repository: schoolpro_bounded_teacher_allocation_policy
- `20261012124052` — live: schoolpro_teacher_roster_and_coordinator_draft_scope; repository: schoolpro_teacher_roster_and_coordinator_draft_scope
- `20261012124406` — live: schoolpro_coordinator_class_review_scope; repository: schoolpro_coordinator_class_review_scope
- `20261012124407` — live: schoolpro_coordinator_read_issued_transcripts; repository: schoolpro_coordinator_read_issued_transcripts
- `20261012124738` — live: schoolpro_unpublished_class_result_preview; repository: schoolpro_unpublished_class_result_preview
- `20261012124900` — live: schoolpro_full_class_reports_require_coordinator; repository: schoolpro_full_class_reports_require_coordinator

## Reconciliation procedure (required before allowlist approval)

1. Identify the repository/branch/commit that generated each missing live migration and obtain immutable SQL artifacts or CI deployment records. Do not infer migration SQL from migration names.
2. Identify why each branch-only migration version is absent from the production ledger; check whether it is intentionally draft, failed, reverted, superseded, or deployed to a different environment.
3. For every available SQL artifact, compare intended DDL/DML with the current live catalog. Mark already-reflected changes separately from missing changes; never replay blindly against production.
4. Compare object definitions directly: table/column types/defaults, constraints, indexes, enum/domain types, routines and security settings, triggers, policies/grants, extensions, storage buckets/policies and cron jobs.
5. Produce a reconciled manifest with source artifact SHA, ledger version, deployed object evidence, scope (SchoolPro/shared/DataSub), and disposition (candidate include/exclude/manual mapping).
6. Review the 107 candidate SchoolPro tables and 79 boundary-crossing FKs against that reconciled schema before approving export.
7. Keep all comparison read-only. Only after explicit approval, create a disposable rehearsal from the actual source schema/data using the reviewed allowlist.

**Disposition:** P0 blocker remains open. This document records the complete version-name diff; it does not claim schema parity or authorize source export/import.


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


## Direct schema-to-migration comparison sample — 2026-10-17

The branch-only migration `20261002234500_schoolpro_operational_tenant_isolation.sql` is a concrete example of why version names cannot be treated as deployment proof. Its SQL says it will set `FORCE ROW LEVEL SECURITY` on eight operational tables, drop existing policies on those tables, and create policies named `tenant read library`, `tenant manage library`, and corresponding tenant policies for transport, hostel, inventory, calendar, lesson notes, result approvals and promotions.

A fresh read-only query of the live Supabase catalog for those same eight tables found:

- RLS is enabled on all eight, but `relforcerowsecurity=false` on all eight.
- Current policy names are different from the policy names the migration creates. Examples: library has `Families read borrowed book details` and `library books authorized access`; calendar has `calendar management write` and `calendar school read`; lesson notes has `lesson notes author access` and `lesson notes leadership access`.
- The migration version is in the branch-only set (absent from the live ledger).

**Disposition for this version:** not reflected as written in the current live catalog, or later superseded/reverted. The exact historical path is unresolved until the deployment artifact/history is recovered. Do not apply it to production or replay it on a target as a historical migration. Instead, compare the intended authorization semantics with the live policy expressions and design a reviewed forward migration for the target.

This is one verified comparison sample, not a full comparison of all 397 live-only and 44 branch-only versions. Continue the same object-level check for each recoverable artifact: columns/types/defaults, indexes/constraints, routines/security settings, triggers, policies/grants, storage policies and scheduled jobs.

## Cross-links to current audit artifacts

- [Machine-readable application call-site manifest](APPLICATION-CALLSITE-MANIFEST-INDEX-2026-10-17.md)
- [Per-table ownership decision register](SCHOOLPRO-PER-TABLE-OWNERSHIP-REGISTER-2026-10-17.md)
