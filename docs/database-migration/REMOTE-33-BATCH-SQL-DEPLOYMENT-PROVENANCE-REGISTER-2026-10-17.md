# Remote 33-version migration SQL and deployment provenance register — 2026-10-17

**Production project:** `lnqsroyiybutkfngbyge`  
**Marker commit:** [a6da195](https://github.com/Hassan-625/IHLink-SchoolPro/commit/a6da195be8f969652b2f05135af04145f1122b82)  
**Current source branch:** `migration/mysql-schoolpro-foundation`

## Evidence status

The source marker states these migrations were applied directly to production through the Supabase migration API on or before 2026-09-26, and intentionally omits DDL. In this audit, the current live migration listing and current branch tree were read again. The rows below are a per-version ledger check; **ledger presence is not the same as recovered SQL or an independently verified deployment audit event**.

GitHub commit searches for representative original names (`schoolpro_admission_lifecycle`, `schoolpro_public_admission_and_candidate_cbt`, `schoolpro_completion_security_cleanup`, `schoolpro_new_tables_rls`) returned no original-source commit. Search for `schoolpro_remote_migration_sync_ledger` found only the marker restoration commit. No Supabase API request/response audit event with actor/timestamp/result was retrieved. Supabase migration listing provides version/name rows only.

## One-by-one evidence register

| Version | Marker migration name | Live ledger check | Source SQL in inspected branch | Deployment evidence |
|---|---|---|---|---|
| `20260926102630` | `schoolpro_completion_security_cleanup` | Present (`schoolpro_completion_security_cleanup`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925210820` | `schoolpro_admission_lifecycle` | Present (`schoolpro_admission_lifecycle`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925211458` | `expand_school_member_roles` | Present (`expand_school_member_roles`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925211509` | `schoolpro_admission_communications` | Present (`schoolpro_admission_communications`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925211837` | `schoolpro_public_admission_and_candidate_cbt` | Present (`schoolpro_public_admission_and_candidate_cbt`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925212303` | `schoolpro_custom_managed_websites` | Present (`schoolpro_custom_managed_websites`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925213322` | `schoolpro_managed_site_provisioning` | Present (`schoolpro_managed_site_provisioning`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925213536` | `schoolpro_new_tables_rls` | Present (`schoolpro_new_tables_rls`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925213705` | `schoolpro_admission_documents_candidate_tokens` | Present (`schoolpro_admission_documents_candidate_tokens`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925213836` | `schoolpro_enrollment_and_portal_invites` | Present (`schoolpro_enrollment_and_portal_invites`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925214057` | `schoolpro_candidate_cbt_secure_flow` | Present (`schoolpro_candidate_cbt_secure_flow`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925214223` | `schoolpro_admission_officer_workflow` | Present (`schoolpro_admission_officer_workflow`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925214636` | `schoolpro_document_verification_and_cbt_assignment` | Present (`schoolpro_document_verification_and_cbt_assignment`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925215753` | `schoolpro_management_authorization_helper` | Present (`schoolpro_management_authorization_helper`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925220129` | `schoolpro_broadsheet_reporting` | Present (`schoolpro_broadsheet_reporting`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925220153` | `schoolpro_offline_payment_recording` | Present (`schoolpro_offline_payment_recording`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260925220434` | `schoolpro_result_publication` | Present (`schoolpro_result_publication`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926084225` | `schoolpro_secure_offer_acceptance` | Present (`schoolpro_secure_offer_acceptance`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926084244` | `schoolpro_candidate_cbt_hardening` | Present (`schoolpro_candidate_cbt_hardening`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926084255` | `schoolpro_role_and_enrollment_hardening` | Present (`schoolpro_role_and_enrollment_hardening`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926084351` | `schoolpro_safe_public_application` | Present (`schoolpro_safe_public_application`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926090548` | `schoolpro_result_review_and_default_assessment` | Present (`schoolpro_result_review_and_default_assessment`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926090600` | `schoolpro_library_and_promotion_workflows` | Present (`schoolpro_library_and_promotion_workflows`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926090701` | `schoolpro_revoke_internal_workflows_from_anon` | Present (`schoolpro_revoke_internal_workflows_from_anon`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926091005` | `schoolpro_three_education_level_assessment_standards` | Present (`schoolpro_three_education_level_assessment_standards`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926091653` | `schoolpro_theory_marking_and_subscription_control` | Present (`schoolpro_theory_marking_and_subscription_control`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926092047` | `schoolpro_health_documents_and_entitlements` | Present (`schoolpro_health_documents_and_entitlements`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926092538` | `schoolpro_email_queue_reliability` | Present (`schoolpro_email_queue_reliability`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926101318` | `schoolpro_cbt_eligibility_controls` | Present (`schoolpro_cbt_eligibility_controls`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926101535` | `schoolpro_secure_student_cbt_execution` | Present (`schoolpro_secure_student_cbt_execution`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926101605` | `schoolpro_student_cbt_listing` | Present (`schoolpro_student_cbt_listing`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926101655` | `tighten_schoolpro_cbt_helper_grants` | Present (`tighten_schoolpro_cbt_helper_grants`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926102010` | `schoolpro_results_finance_operations_completion` | Present (`schoolpro_results_finance_operations_completion`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926102055` | `schoolpro_result_lock_enforcement` | Present (`schoolpro_result_lock_enforcement`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926102147` | `schoolpro_transactional_email_events` | Present (`schoolpro_transactional_email_events`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |
| `20260926102630` | `schoolpro_completion_security_cleanup` | Present (`schoolpro_completion_security_cleanup`) | **No executable source file in inspected branch** | Marker declaration only; original SQL blob and authoritative deployment event not recovered. |

## Disposition

- **Verified from live ledger:** 36 of 36 marker versions match exact version and name.
- **Original executable SQL recovered:** 0 from the inspected branch for these marker versions.
- **Independent deployment audit event recovered:** 0 in the inspected sources/tools so far.
- **Replay approval:** none. Do not fabricate replacement SQL from current catalog definitions. To recover originals, inspect Supabase CLI/developer machine artifacts, archived migration directories, CI artifacts, backups and retained audit logs outside the currently inspected branch; record immutable blob SHA and deployment event per version.

**Safety:** no migration replay, production write, export/import, configuration change, or merge occurred.
