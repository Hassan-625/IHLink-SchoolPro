# Live SchoolPro trigger definitions and handler bodies — 2026-10-17

**Source:** Supabase `lnqsroyiybutkfngbyge`, PostgreSQL 17.6. Read-only catalog capture. This file is evidence for review, not a migration script; do not execute it on Aiven. Refresh before any export because live definitions can change.

## Summary
- Relevant non-internal trigger bindings captured: 160.
- Unique handler routine names: 39.
- Handler overload definitions captured: 39.

## Trigger bindings and exact definitions (160)

- `public.schoolpro_academic_documents` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_academic_documents FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_academic_documents` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_academic_documents FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_admission_acceptances` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_admission_acceptances FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_admission_documents` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_admission_documents FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_admission_events` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_admission_events FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_admission_offers` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_admission_offers FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_admissions` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_admissions FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_admissions` / `trg_schoolpro_admission_notify` (enabled code `O`): `CREATE TRIGGER trg_schoolpro_admission_notify AFTER INSERT OR UPDATE OF status ON schoolpro_admissions FOR EACH ROW EXECUTE FUNCTION private.notify_school_staff()`; handler `private.notify_school_staff()`
- `public.schoolpro_admissions` / `trg_schoolpro_auto_admission_document` (enabled code `O`): `CREATE TRIGGER trg_schoolpro_auto_admission_document AFTER UPDATE OF enrollment_status, admitted_student_id ON schoolpro_admissions FOR EACH ROW EXECUTE FUNCTION schoolpro_auto_create_admission_document()`; handler `public.schoolpro_auto_create_admission_document()`
- `public.schoolpro_announcements` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_announcements FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_announcements` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_announcements FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_announcements` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_announcements FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_announcements` / `trg_schoolpro_announcement_notify` (enabled code `O`): `CREATE TRIGGER trg_schoolpro_announcement_notify AFTER INSERT ON schoolpro_announcements FOR EACH ROW EXECUTE FUNCTION private.notify_school_staff()`; handler `private.notify_school_staff()`
- `public.schoolpro_assessment_schemes` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_assessment_schemes FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_assessment_schemes` / `validate_schoolpro_assessment_scheme` (enabled code `O`): `CREATE TRIGGER validate_schoolpro_assessment_scheme BEFORE INSERT OR UPDATE ON schoolpro_assessment_schemes FOR EACH ROW EXECUTE FUNCTION private.validate_assessment_scheme()`; handler `private.validate_assessment_scheme()`
- `public.schoolpro_assignment_submissions` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_assignment_submissions FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_assignment_submissions` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_assignment_submissions FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_assignments` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_assignments FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_assignments` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_assignments FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_assignments` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_assignments FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_assignments` / `trg_validate_schoolpro_assignment_target` (enabled code `O`): `CREATE TRIGGER trg_validate_schoolpro_assignment_target BEFORE INSERT OR UPDATE OF school_id, class_id, subject_id, session, created_by ON schoolpro_assignments FOR EACH ROW EXECUTE FUNCTION private.validate_schoolpro_assignment_target()`; handler `private.validate_schoolpro_assignment_target()`
- `public.schoolpro_attendance` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_attendance FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_attendance` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_attendance FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_attendance` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_attendance FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_attendance` / `schoolpro_validate_activity_calendar` (enabled code `O`): `CREATE TRIGGER schoolpro_validate_activity_calendar BEFORE INSERT OR UPDATE ON schoolpro_attendance FOR EACH ROW EXECUTE FUNCTION private.schoolpro_validate_activity_calendar()`; handler `private.schoolpro_validate_activity_calendar()`
- `public.schoolpro_attendance` / `validate_schoolpro_attendance` (enabled code `O`): `CREATE TRIGGER validate_schoolpro_attendance BEFORE INSERT OR UPDATE ON schoolpro_attendance FOR EACH ROW EXECUTE FUNCTION private.validate_attendance_record()`; handler `private.validate_attendance_record()`
- `public.schoolpro_bank_accounts` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_bank_accounts FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_branding` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_branding FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_calendar_events` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_calendar_events FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_calendar_events` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_calendar_events FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_calendar_events` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_calendar_events FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_calendar_events` / `schoolpro_validate_activity_calendar` (enabled code `O`): `CREATE TRIGGER schoolpro_validate_activity_calendar BEFORE INSERT OR UPDATE ON schoolpro_calendar_events FOR EACH ROW EXECUTE FUNCTION private.schoolpro_validate_activity_calendar()`; handler `private.schoolpro_validate_activity_calendar()`
- `public.schoolpro_calendar_events` / `validate_schoolpro_calendar_workflow` (enabled code `O`): `CREATE TRIGGER validate_schoolpro_calendar_workflow BEFORE INSERT OR UPDATE ON schoolpro_calendar_events FOR EACH ROW EXECUTE FUNCTION private.validate_schoolpro_workflow_record()`; handler `private.validate_schoolpro_workflow_record()`
- `public.schoolpro_candidate_cbt_answers` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_candidate_cbt_answers FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_candidate_cbt_attempts` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_candidate_cbt_attempts FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_candidate_cbt_attempts` / `trg_candidate_cbt_tenant` (enabled code `O`): `CREATE TRIGGER trg_candidate_cbt_tenant BEFORE INSERT OR UPDATE OF application_id, test_id ON schoolpro_candidate_cbt_attempts FOR EACH ROW EXECUTE FUNCTION private.validate_candidate_cbt_tenant()`; handler `private.validate_candidate_cbt_tenant()`
- `public.schoolpro_cbt_answers` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_cbt_answers FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_cbt_attempts` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_cbt_attempts FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_cbt_eligibility` / `enforce_schoolpro_cbt_eligibility_relations` (enabled code `O`): `CREATE TRIGGER enforce_schoolpro_cbt_eligibility_relations BEFORE INSERT OR UPDATE OF school_id, test_id, student_id, class_id ON schoolpro_cbt_eligibility FOR EACH ROW EXECUTE FUNCTION private.enforce_schoolpro_tenant_relations()`; handler `private.enforce_schoolpro_tenant_relations()`
- `public.schoolpro_cbt_eligibility` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_cbt_eligibility FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_cbt_eligibility` / `schoolpro_cbt_eligibility_tenant_guard` (enabled code `O`): `CREATE TRIGGER schoolpro_cbt_eligibility_tenant_guard BEFORE INSERT OR UPDATE ON schoolpro_cbt_eligibility FOR EACH ROW EXECUTE FUNCTION private.validate_schoolpro_cbt_eligibility()`; handler `private.validate_schoolpro_cbt_eligibility()`
- `public.schoolpro_cbt_test_questions` / `enforce_schoolpro_cbt_question_relations` (enabled code `O`): `CREATE TRIGGER enforce_schoolpro_cbt_question_relations BEFORE INSERT OR UPDATE OF test_id, question_id ON schoolpro_cbt_test_questions FOR EACH ROW EXECUTE FUNCTION private.enforce_schoolpro_tenant_relations()`; handler `private.enforce_schoolpro_tenant_relations()`
- `public.schoolpro_cbt_test_questions` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_cbt_test_questions FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_cbt_tests` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_cbt_tests FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_charge_categories` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_charge_categories FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_classes` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_classes FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_demo_requests` / `schoolpro_demo_invoice` (enabled code `O`): `CREATE TRIGGER schoolpro_demo_invoice AFTER INSERT OR UPDATE OF school_id, status ON schoolpro_demo_requests FOR EACH ROW EXECUTE FUNCTION private.sync_schoolpro_demo_invoice()`; handler `private.sync_schoolpro_demo_invoice()`
- `public.schoolpro_discipline_records` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_discipline_records FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_discipline_records` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_discipline_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_discipline_records` / `schoolpro_notify_discipline` (enabled code `O`): `CREATE TRIGGER schoolpro_notify_discipline AFTER INSERT ON schoolpro_discipline_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_notify_discipline()`; handler `private.schoolpro_notify_discipline()`
- `public.schoolpro_discipline_records` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_discipline_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_discipline_records` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_discipline_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_document_issue_events` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_document_issue_events FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_document_issues` / `enforce_schoolpro_document_issue_relations` (enabled code `O`): `CREATE TRIGGER enforce_schoolpro_document_issue_relations BEFORE INSERT OR UPDATE OF school_id, template_id, student_id ON schoolpro_document_issues FOR EACH ROW EXECUTE FUNCTION private.enforce_schoolpro_tenant_relations()`; handler `private.enforce_schoolpro_tenant_relations()`
- `public.schoolpro_document_issues` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_document_issues FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_document_issues` / `trg_guard_schoolpro_document_issue_lifecycle` (enabled code `O`): `CREATE TRIGGER trg_guard_schoolpro_document_issue_lifecycle BEFORE INSERT OR UPDATE ON schoolpro_document_issues FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_document_issue_lifecycle()`; handler `private.guard_schoolpro_document_issue_lifecycle()`
- `public.schoolpro_document_templates` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_document_templates FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_fee_bank_accounts` / `school_fee_bank_sync` (enabled code `O`): `CREATE TRIGGER school_fee_bank_sync BEFORE INSERT OR UPDATE ON schoolpro_fee_bank_accounts FOR EACH ROW EXECUTE FUNCTION private.sync_school_fee_receiving_account()`; handler `private.sync_school_fee_receiving_account()`
- `public.schoolpro_fee_bank_accounts` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_fee_bank_accounts FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_fee_exceptions` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_fee_exceptions FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_fee_items` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_fee_items FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_fee_items` / `schoolpro_fee_items_auto_invoice` (enabled code `O`): `CREATE TRIGGER schoolpro_fee_items_auto_invoice AFTER INSERT OR DELETE OR UPDATE ON schoolpro_fee_items FOR EACH ROW EXECUTE FUNCTION private.schoolpro_auto_fee_invoices()`; handler `private.schoolpro_auto_fee_invoices()`
- `public.schoolpro_fee_payments` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_fee_payments FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_fee_payments` / `trg_schoolpro_payment_email` (enabled code `O`): `CREATE TRIGGER trg_schoolpro_payment_email AFTER INSERT ON schoolpro_fee_payments FOR EACH ROW EXECUTE FUNCTION queue_schoolpro_transactional_email()`; handler `public.queue_schoolpro_transactional_email()`
- `public.schoolpro_fee_records` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_fee_records FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_fee_structures` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_fee_structures FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_fee_structures` / `schoolpro_fee_schedule_auto_invoice` (enabled code `O`): `CREATE TRIGGER schoolpro_fee_schedule_auto_invoice AFTER INSERT OR UPDATE ON schoolpro_fee_structures FOR EACH ROW EXECUTE FUNCTION private.schoolpro_auto_fee_invoices()`; handler `private.schoolpro_auto_fee_invoices()`
- `public.schoolpro_finance_settings` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_finance_settings FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_generated_result_outputs` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_generated_result_outputs FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_grade_scale` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_grade_scale FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_guardian_links` / `schoolpro_guardian_school_scope` (enabled code `O`): `CREATE TRIGGER schoolpro_guardian_school_scope BEFORE INSERT OR UPDATE OF school_id, student_id ON schoolpro_guardian_links FOR EACH ROW EXECUTE FUNCTION private.schoolpro_guardian_school_scope()`; handler `private.schoolpro_guardian_school_scope()`
- `public.schoolpro_health_records` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_health_records FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_health_records` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_health_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_health_records` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_health_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_health_records` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_health_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_health_records` / `schoolpro_validate_activity_calendar` (enabled code `O`): `CREATE TRIGGER schoolpro_validate_activity_calendar BEFORE INSERT OR UPDATE ON schoolpro_health_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_validate_activity_calendar()`; handler `private.schoolpro_validate_activity_calendar()`
- `public.schoolpro_health_records` / `validate_schoolpro_clinic_workflow` (enabled code `O`): `CREATE TRIGGER validate_schoolpro_clinic_workflow BEFORE INSERT OR UPDATE ON schoolpro_health_records FOR EACH ROW EXECUTE FUNCTION private.validate_schoolpro_workflow_record()`; handler `private.validate_schoolpro_workflow_record()`
- `public.schoolpro_hostel_allocations` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_hostel_allocations FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_hostel_allocations` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_hostel_allocations FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_hostel_allocations` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_hostel_allocations FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_hostel_allocations` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_hostel_allocations FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_hostel_rooms` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_hostel_rooms FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_inventory_assets` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_inventory_assets FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_invoice_templates` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_invoice_templates FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_invoices` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_invoices FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_invoices` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_invoices FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_invoices` / `trg_schoolpro_invoice_notify` (enabled code `O`): `CREATE TRIGGER trg_schoolpro_invoice_notify AFTER INSERT ON schoolpro_invoices FOR EACH ROW EXECUTE FUNCTION private.notify_school_staff()`; handler `private.notify_school_staff()`
- `public.schoolpro_leave_requests` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_leave_requests FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_leave_requests` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_leave_requests FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_leave_requests` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_leave_requests FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_leave_requests` / `schoolpro_validate_activity_calendar` (enabled code `O`): `CREATE TRIGGER schoolpro_validate_activity_calendar BEFORE INSERT OR UPDATE ON schoolpro_leave_requests FOR EACH ROW EXECUTE FUNCTION private.schoolpro_validate_activity_calendar()`; handler `private.schoolpro_validate_activity_calendar()`
- `public.schoolpro_leave_requests` / `validate_schoolpro_leave` (enabled code `O`): `CREATE TRIGGER validate_schoolpro_leave BEFORE INSERT OR UPDATE ON schoolpro_leave_requests FOR EACH ROW EXECUTE FUNCTION private.validate_schoolpro_leave()`; handler `private.validate_schoolpro_leave()`
- `public.schoolpro_lesson_notes` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_lesson_notes FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_lesson_notes` / `schoolpro_lesson_workflow` (enabled code `O`): `CREATE TRIGGER schoolpro_lesson_workflow BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_lesson_notes FOR EACH ROW EXECUTE FUNCTION private.schoolpro_validate_lesson_workflow()`; handler `private.schoolpro_validate_lesson_workflow()`
- `public.schoolpro_lesson_notes` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_lesson_notes FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_lesson_notes` / `schoolpro_validate_activity_calendar` (enabled code `O`): `CREATE TRIGGER schoolpro_validate_activity_calendar BEFORE INSERT OR UPDATE ON schoolpro_lesson_notes FOR EACH ROW EXECUTE FUNCTION private.schoolpro_validate_activity_calendar()`; handler `private.schoolpro_validate_activity_calendar()`
- `public.schoolpro_library_books` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_library_books FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_library_loans` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_library_loans FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_library_loans` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_library_loans FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_library_loans` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_library_loans FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_library_loans` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_library_loans FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_library_loans` / `schoolpro_validate_activity_calendar` (enabled code `O`): `CREATE TRIGGER schoolpro_validate_activity_calendar BEFORE INSERT OR UPDATE ON schoolpro_library_loans FOR EACH ROW EXECUTE FUNCTION private.schoolpro_validate_activity_calendar()`; handler `private.schoolpro_validate_activity_calendar()`
- `public.schoolpro_members` / `protect_schoolpro_proprietor_role` (enabled code `O`): `CREATE TRIGGER protect_schoolpro_proprietor_role BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_members FOR EACH ROW EXECUTE FUNCTION private.protect_schoolpro_proprietor_role()`; handler `private.protect_schoolpro_proprietor_role()`
- `public.schoolpro_members` / `schoolpro_clear_changed_board_role` (enabled code `O`): `CREATE TRIGGER schoolpro_clear_changed_board_role AFTER UPDATE OF role ON schoolpro_members FOR EACH ROW EXECUTE FUNCTION private.schoolpro_clear_changed_board_role()`; handler `private.schoolpro_clear_changed_board_role()`
- `public.schoolpro_module_records` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_module_records FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_onboarding_requests` / `schoolpro_onboarding_demo_invoice` (enabled code `O`): `CREATE TRIGGER schoolpro_onboarding_demo_invoice AFTER UPDATE OF school_id, status, plan_key ON schoolpro_onboarding_requests FOR EACH ROW EXECUTE FUNCTION private.sync_schoolpro_onboarding_demo_invoice()`; handler `private.sync_schoolpro_onboarding_demo_invoice()`
- `public.schoolpro_payment_allocations` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_payment_allocations FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_payment_intents` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_payment_intents FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_payment_proofs` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_payment_proofs FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_payment_submissions` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_payment_submissions FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_payroll_records` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_payroll_records FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_payroll_records` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_payroll_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_payroll_records` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_payroll_records FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_payroll_records` / `validate_schoolpro_payroll_workflow` (enabled code `O`): `CREATE TRIGGER validate_schoolpro_payroll_workflow BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_payroll_records FOR EACH ROW EXECUTE FUNCTION private.validate_schoolpro_workflow_record()`; handler `private.validate_schoolpro_workflow_record()`
- `public.schoolpro_portal_invites` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_portal_invites FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_promotions` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_promotions FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_promotions` / `schoolpro_archive_applied_progression` (enabled code `O`): `CREATE TRIGGER schoolpro_archive_applied_progression AFTER UPDATE OF status ON schoolpro_promotions FOR EACH ROW EXECUTE FUNCTION private.schoolpro_archive_progression()`; handler `private.schoolpro_archive_progression()`
- `public.schoolpro_question_bank` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_question_bank FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_access_pins` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_access_pins FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_approvals` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_approvals FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_corrections` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_corrections FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_domain_definitions` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_domain_definitions FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_domain_ratings` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_domain_ratings FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_events` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_events FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_rating_scale` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_rating_scale FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_templates` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_templates FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_term_settings` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_term_settings FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_result_term_settings` / `schoolpro_validate_calendar` (enabled code `O`): `CREATE TRIGGER schoolpro_validate_calendar BEFORE INSERT OR UPDATE OF term_start_date, term_end_date ON schoolpro_result_term_settings FOR EACH ROW EXECUTE FUNCTION private.schoolpro_validate_calendar()`; handler `private.schoolpro_validate_calendar()`
- `public.schoolpro_result_verifications` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_result_verifications FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_results` / `calculate_schoolpro_result_total` (enabled code `O`): `CREATE TRIGGER calculate_schoolpro_result_total BEFORE INSERT OR UPDATE OF assessment_scheme_id, assessment_scores ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION private.calculate_result_total()`; handler `private.calculate_result_total()`
- `public.schoolpro_results` / `enforce_schoolpro_result_relations` (enabled code `O`): `CREATE TRIGGER enforce_schoolpro_result_relations BEFORE INSERT OR UPDATE OF school_id, student_id, subject_id, assessment_scheme_id ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION private.enforce_schoolpro_tenant_relations()`; handler `private.enforce_schoolpro_tenant_relations()`
- `public.schoolpro_results` / `enforce_schoolpro_result_workflow` (enabled code `O`): `CREATE TRIGGER enforce_schoolpro_result_workflow BEFORE UPDATE ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION private.enforce_result_workflow()`; handler `private.enforce_result_workflow()`
- `public.schoolpro_results` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_results` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_results` / `trg_schoolpro_result_email` (enabled code `O`): `CREATE TRIGGER trg_schoolpro_result_email AFTER UPDATE OF status ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION queue_schoolpro_transactional_email()`; handler `public.queue_schoolpro_transactional_email()`
- `public.schoolpro_results` / `trg_schoolpro_result_lifecycle_event` (enabled code `O`): `CREATE TRIGGER trg_schoolpro_result_lifecycle_event AFTER UPDATE ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION private.log_schoolpro_result_lifecycle()`; handler `private.log_schoolpro_result_lifecycle()`
- `public.schoolpro_results` / `trg_schoolpro_result_lock` (enabled code `O`): `CREATE TRIGGER trg_schoolpro_result_lock BEFORE UPDATE ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION enforce_schoolpro_result_lock()`; handler `public.enforce_schoolpro_result_lock()`
- `public.schoolpro_results` / `trg_validate_schoolpro_result_tenant` (enabled code `O`): `CREATE TRIGGER trg_validate_schoolpro_result_tenant BEFORE INSERT OR UPDATE OF school_id, student_id, subject_id, session, term ON schoolpro_results FOR EACH ROW EXECUTE FUNCTION private.validate_schoolpro_result_tenant()`; handler `private.validate_schoolpro_result_tenant()`
- `public.schoolpro_schools` / `create_default_school_assessment_scheme` (enabled code `O`): `CREATE TRIGGER create_default_school_assessment_scheme AFTER INSERT ON schoolpro_schools FOR EACH ROW EXECUTE FUNCTION private.create_default_school_assessment_scheme()`; handler `private.create_default_school_assessment_scheme()`
- `public.schoolpro_schools` / `initialize_assessments_after_activation` (enabled code `O`): `CREATE TRIGGER initialize_assessments_after_activation AFTER UPDATE OF status ON schoolpro_schools FOR EACH ROW WHEN (new.status = 'active'::school_status) EXECUTE FUNCTION private.create_default_school_assessment_scheme()`; handler `private.create_default_school_assessment_scheme()`
- `public.schoolpro_schools` / `sync_school_request_activation` (enabled code `O`): `CREATE TRIGGER sync_school_request_activation AFTER UPDATE OF status ON schoolpro_schools FOR EACH ROW EXECUTE FUNCTION private.sync_school_request_activation()`; handler `private.sync_school_request_activation()`
- `public.schoolpro_site_content` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_site_content FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_site_gallery` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_site_gallery FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_site_news` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_site_news FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_site_settings` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_site_settings FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_student_transport` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_student_transport FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_student_transport` / `schoolpro_active_pupil_activity` (enabled code `O`): `CREATE TRIGGER schoolpro_active_pupil_activity BEFORE INSERT OR UPDATE ON schoolpro_student_transport FOR EACH ROW EXECUTE FUNCTION private.schoolpro_reject_new_inactive_student_activity()`; handler `private.schoolpro_reject_new_inactive_student_activity()`
- `public.schoolpro_student_transport` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_student_transport FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_student_transport` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_student_transport FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_students` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_students FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_students` / `schoolpro_enrollment_calendar` (enabled code `O`): `CREATE TRIGGER schoolpro_enrollment_calendar AFTER INSERT ON schoolpro_students FOR EACH ROW EXECUTE FUNCTION private.schoolpro_enrollment_calendar()`; handler `private.schoolpro_enrollment_calendar()`
- `public.schoolpro_students` / `validate_schoolpro_student_class` (enabled code `O`): `CREATE TRIGGER validate_schoolpro_student_class BEFORE INSERT OR UPDATE OF class_id ON schoolpro_students FOR EACH ROW EXECUTE FUNCTION private.validate_student_class()`; handler `private.validate_student_class()`
- `public.schoolpro_subject_assignments` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_subject_assignments FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_subject_assignments` / `trg_validate_schoolpro_subject_assignment` (enabled code `O`): `CREATE TRIGGER trg_validate_schoolpro_subject_assignment BEFORE INSERT OR UPDATE ON schoolpro_subject_assignments FOR EACH ROW EXECUTE FUNCTION private.validate_schoolpro_subject_assignment()`; handler `private.validate_schoolpro_subject_assignment()`
- `public.schoolpro_subjects` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_subjects FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_timetable_entries` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_timetable_entries FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`
- `public.schoolpro_timetable_entries` / `schoolpro_preserve_activity_session` (enabled code `O`): `CREATE TRIGGER schoolpro_preserve_activity_session BEFORE UPDATE ON schoolpro_timetable_entries FOR EACH ROW EXECUTE FUNCTION private.schoolpro_preserve_activity_session()`; handler `private.schoolpro_preserve_activity_session()`
- `public.schoolpro_timetable_entries` / `schoolpro_stamp_activity_period` (enabled code `O`): `CREATE TRIGGER schoolpro_stamp_activity_period BEFORE INSERT ON schoolpro_timetable_entries FOR EACH ROW EXECUTE FUNCTION private.schoolpro_stamp_activity_period()`; handler `private.schoolpro_stamp_activity_period()`
- `public.schoolpro_transcript_issues` / `schoolpro_transcript_enrichment` (enabled code `O`): `CREATE TRIGGER schoolpro_transcript_enrichment BEFORE INSERT ON schoolpro_transcript_issues FOR EACH ROW EXECUTE FUNCTION private.schoolpro_transcript_enrichment()`; handler `private.schoolpro_transcript_enrichment()`
- `public.schoolpro_transport_routes` / `schoolpro_activation_before_write` (enabled code `O`): `CREATE TRIGGER schoolpro_activation_before_write BEFORE INSERT OR DELETE OR UPDATE ON schoolpro_transport_routes FOR EACH ROW EXECUTE FUNCTION private.guard_schoolpro_operational_write()`; handler `private.guard_schoolpro_operational_write()`

## Handler routine definitions (39)

Review each handler for tenant checks, actor identity, lock semantics, data changes, external side effects, function search_path, grants, RLS assumptions and PostgreSQL/Aiven compatibility. A captured body is not proof of semantic correctness or migration approval.

## `private.guard_schoolpro_operational_write()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.guard_schoolpro_operational_write()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare old_school uuid; new_school uuid;
begin
 -- Trusted background settlement/maintenance can still update historic records.
 if auth.uid() is null and coalesce(current_setting('request.jwt.claim.role',true),'')<>'anon' then
  if tg_op='DELETE' then return old; else return new; end if;
 end if;
 if tg_op<>'INSERT' then old_school:=private.schoolpro_record_school(tg_table_name,to_jsonb(old)); end if;
 if tg_op<>'DELETE' then new_school:=private.schoolpro_record_school(tg_table_name,to_jsonb(new)); end if;
 if (old_school is not null and not private.schoolpro_operationally_active(old_school))
 or (new_school is not null and not private.schoolpro_operationally_active(new_school)) then
  raise exception 'SchoolPro operational activation required: complete subscription payment or an audited Control Center activation';
 end if;
 if old_school is null and new_school is null and not coalesce(private.has_product_access('schoolpro','edit'),false) then raise exception 'School-linked operational record required'; end if;
 if tg_op='DELETE' then return old; else return new; end if;
end $function$

```

## `private.notify_school_staff()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.notify_school_staff()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare sid uuid;ttl text;msg text;href text;begin sid:=new.school_id;if tg_table_name='schoolpro_announcements' then ttl:='New announcement: '||new.title;msg:=left(new.body,240);href:='/schoolpro/announcements';elsif tg_table_name='schoolpro_admissions' then ttl:='Admissions update';msg:='Application '||coalesce(new.application_number,new.id::text)||' is now '||new.status;href:='/schoolpro/admissions';elsif tg_table_name='schoolpro_invoices' then
 insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href)
 select sid,recipient,'Fee invoice created',new.title||' · '||new.term||' · '||new.session,tg_table_name,'/schoolpro/invoices/'||new.id
 from (
 select sc.owner_id recipient from public.schoolpro_schools sc where sc.id=sid
 union select m.user_id from public.schoolpro_members m where m.school_id=sid and m.role::text in('proprietor','administrator','accountant','bursar')
 union select st.user_id from public.schoolpro_students st where st.id=new.student_id and st.school_id=sid
 union select g.guardian_user_id from public.schoolpro_guardian_links g where g.student_id=new.student_id and g.school_id=sid and g.status='active'
 ) recipients where recipient is not null;
 return new;else return new;end if;insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href) select sid,m.user_id,ttl,msg,tg_table_name,href from public.schoolpro_members m where m.school_id=sid union select sid,s.owner_id,ttl,msg,tg_table_name,href from public.schoolpro_schools s where s.id=sid and s.owner_id is not null;return new;end$function$

```

## `private.schoolpro_preserve_activity_session()`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_preserve_activity_session()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if nullif(old.session,'') is not null and old.session is distinct from new.session then raise exception 'Keep this record in its original academic session';end if;
 if nullif(new.session,'') is not null and not private.schoolpro_valid_session(new.session) then raise exception 'Select consecutive academic years';end if;
 return new;
end $function$

```

## `private.schoolpro_reject_new_inactive_student_activity()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_reject_new_inactive_student_activity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare pupil uuid;j jsonb:=to_jsonb(new);prior jsonb;begin if tg_op='UPDATE' then prior:=to_jsonb(old);end if;pupil:=nullif(j->>'student_id','')::uuid;if pupil is not null and(tg_op='INSERT' or j->>'student_id' is distinct from prior->>'student_id' or (j->>'active'='true' and prior->>'active'='false') or j->>'attendance_date' is distinct from prior->>'attendance_date') and exists(select 1 from public.schoolpro_students where id=pupil and(status<>'active' or transferred_out_at is not null)) then raise exception 'This pupil is no longer enrolled for new activities';end if;return new;end$function$

```

## `private.schoolpro_stamp_activity_period()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_stamp_activity_period()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare j jsonb:=to_jsonb(new);sid uuid;d date;t public.schoolpro_result_term_settings;selected text;
begin
 sid:=nullif(j->>'school_id','')::uuid;
 if sid is null and j->>'student_id' is not null then select school_id into sid from public.schoolpro_students where id=(j->>'student_id')::uuid;end if;
 d:=coalesce(nullif(j->>'attendance_date','')::date,nullif(j->>'lesson_date','')::date,nullif(j->>'event_date','')::date,nullif(j->>'start_date','')::date,nullif(j->>'recorded_at','')::timestamptz::date,nullif(j->>'borrowed_at','')::timestamptz::date,current_date);
 selected:=nullif(j->>'session','');
 if selected is null then
  select * into t from public.schoolpro_result_term_settings where school_id=sid and term_start_date<=d and term_end_date>=d order by term_start_date desc limit 1;
  selected:=t.session;
 end if;
 if selected is not null then
  if not private.schoolpro_valid_session(selected) then raise exception 'Select consecutive academic years';end if;
  j:=j||jsonb_build_object('session',selected);
  if j?'term' and nullif(j->>'term','') is null then
   select * into t from public.schoolpro_result_term_settings where school_id=sid and session=selected and term_start_date<=d and term_end_date>=d order by term_start_date desc limit 1;
   if t.id is not null then j:=j||jsonb_build_object('term',t.term);end if;
  end if;
  new:=jsonb_populate_record(new,j);
 end if;
 return new;
end $function$

```

## `private.schoolpro_validate_activity_calendar()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_validate_activity_calendar()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare j jsonb:=to_jsonb(new);prior jsonb;d date;begin_date date;end_date date;date_key text;
begin
 if nullif(j->>'session','') is null then return new;end if;
 date_key:=case when j?'attendance_date' then 'attendance_date' when j?'lesson_date' then 'lesson_date' when j?'event_date' then 'event_date' when j?'start_date' then 'start_date' when j?'recorded_at' then 'recorded_at' when j?'borrowed_at' then 'borrowed_at' end;
 if date_key is null or nullif(j->>date_key,'') is null then return new;end if;
 if tg_op='UPDATE' then prior:=to_jsonb(old);if j->>date_key is not distinct from prior->>date_key then return new;end if;end if;
 d:=(j->>date_key)::timestamptz::date;
 select min(term_start_date),max(term_end_date) into begin_date,end_date from public.schoolpro_result_term_settings where school_id=new.school_id and session=new.session;
 if begin_date is not null and (d<begin_date or d>end_date) then raise exception 'The activity date is outside the selected academic session';end if;
 return new;
end $function$

```

## `private.validate_assessment_scheme()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.validate_assessment_scheme()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare component jsonb; score_total numeric := 0; component_keys text[] := '{}';
begin
  if jsonb_typeof(new.components) <> 'array' or jsonb_array_length(new.components) = 0 then raise exception 'Assessment components must be a non-empty list'; end if;
  for component in select value from jsonb_array_elements(new.components) loop
    if coalesce(component->>'key','') = '' or coalesce(component->>'label','') = '' or jsonb_typeof(component->'maxScore') <> 'number' then raise exception 'Every component needs a key, label and numeric maximum score'; end if;
    if (component->>'key') = any(component_keys) then raise exception 'Assessment component keys must be unique'; end if;
    if (component->>'maxScore')::numeric <= 0 then raise exception 'Assessment weights must be greater than zero'; end if;
    component_keys := array_append(component_keys, component->>'key');
    score_total := score_total + (component->>'maxScore')::numeric;
  end loop;
  if score_total <> 100 then raise exception 'Assessment weights must total 100%%'; end if;
  if new.is_default then update public.schoolpro_assessment_schemes set is_default = false where school_id = new.school_id and id <> new.id and is_default; end if;
  new.updated_at := now();
  return new;
end; $function$

```

## `private.validate_attendance_record()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.validate_attendance_record()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare selected_student record; class_school uuid; historical_class uuid;
begin
 select school_id,class_id into selected_student from public.schoolpro_students where id=new.student_id;
 select school_id into class_school from public.schoolpro_classes where id=new.class_id;
 if selected_student.school_id is null or class_school is null or selected_student.school_id<>new.school_id or class_school<>new.school_id then raise exception 'Student and class must belong to the selected school';end if;
 if nullif(new.session,'') is not null then select class_id into historical_class from public.schoolpro_enrollment_history where school_id=new.school_id and student_id=new.student_id and session=new.session;end if;
 if coalesce(historical_class,selected_student.class_id) is distinct from new.class_id then raise exception 'Student is not enrolled in the selected class and session';end if;
 return new;
end $function$

```

## `private.validate_schoolpro_assignment_target()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.validate_schoolpro_assignment_target()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_member uuid;
begin
 new.session:=trim(new.session);
 if new.session='' then raise exception 'Academic session is required';end if;
 if not exists(select 1 from public.schoolpro_classes c where c.id=new.class_id and c.school_id=new.school_id)
 then raise exception 'Class does not belong to assignment school';end if;
 if not exists(select 1 from public.schoolpro_subjects s where s.id=new.subject_id and s.school_id=new.school_id)
 then raise exception 'Subject does not belong to assignment school';end if;
 if auth.uid() is not null and not private.has_school_access(new.school_id,array['proprietor'::public.school_member_role,'administrator'::public.school_member_role,'head_teacher'::public.school_member_role,'vice_principal'::public.school_member_role]) then
   select m.id into v_member from public.schoolpro_members m where m.school_id=new.school_id and m.user_id=auth.uid()
   and m.role in('teacher','class_teacher') limit 1;
   if v_member is null or not exists(select 1 from public.schoolpro_subject_assignments sa
     where sa.school_id=new.school_id and sa.class_id=new.class_id and sa.subject_id=new.subject_id
     and sa.teacher_member_id=v_member and trim(sa.session)=new.session)
   then raise exception 'Teacher is not assigned to this class, subject and session';end if;
 end if;
 return new;
end $function$

```

## `public.schoolpro_auto_create_admission_document()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.schoolpro_auto_create_admission_document()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare t public.schoolpro_document_templates; st public.schoolpro_students;
begin
 if new.enrollment_status='enrolled' and new.admitted_student_id is not null and (old.enrollment_status is distinct from new.enrollment_status or old.admitted_student_id is distinct from new.admitted_student_id) then
   select * into t from public.schoolpro_document_templates where school_id=new.school_id and document_type='admission_letter' and is_default=true and is_active=true order by version desc limit 1;
   if t.id is not null and not exists(select 1 from public.schoolpro_document_issues i where i.school_id=new.school_id and i.document_type='admission_letter' and i.payload->>'application_id'=new.id::text) then
     select * into st from public.schoolpro_students where id=new.admitted_student_id and school_id=new.school_id;
     insert into public.schoolpro_document_issues(school_id,template_id,student_id,document_type,title,payload,status,issued_by)
     values(new.school_id,t.id,new.admitted_student_id,'admission_letter',t.name,
       jsonb_build_object('application_id',new.id,'student_name',trim(coalesce(st.first_name,'')||' '||coalesce(st.last_name,'')),'first_name',st.first_name,'last_name',st.last_name,'admission_number',st.admission_number,'class_name',st.class_name,'guardian_name',new.guardian_name,'issue_date',current_date::text),
       'draft',auth.uid());
   end if;
 end if;
 return new;
end$function$

```

## `private.enforce_schoolpro_tenant_relations()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.enforce_schoolpro_tenant_relations()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_school uuid;
begin
 if tg_table_name='schoolpro_results' then
   if not exists(select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id) then raise exception 'Result student must belong to the same school';end if;
   if not exists(select 1 from public.schoolpro_subjects s where s.id=new.subject_id and s.school_id=new.school_id) then raise exception 'Result subject must belong to the same school';end if;
   if new.assessment_scheme_id is not null and not exists(select 1 from public.schoolpro_assessment_schemes a where a.id=new.assessment_scheme_id and a.school_id=new.school_id) then raise exception 'Assessment scheme must belong to the same school';end if;
 elsif tg_table_name='schoolpro_cbt_test_questions' then
   select t.school_id into v_school from public.schoolpro_cbt_tests t where t.id=new.test_id;
   if v_school is null or not exists(select 1 from public.schoolpro_question_bank q where q.id=new.question_id and q.school_id=v_school) then raise exception 'CBT question and test must belong to the same school';end if;
 elsif tg_table_name='schoolpro_cbt_eligibility' then
   if not exists(select 1 from public.schoolpro_cbt_tests t where t.id=new.test_id and t.school_id=new.school_id) then raise exception 'CBT test must belong to the eligibility school';end if;
   if new.student_id is not null and not exists(select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id) then raise exception 'Eligible student must belong to the same school';end if;
   if new.class_id is not null and not exists(select 1 from public.schoolpro_classes c where c.id=new.class_id and c.school_id=new.school_id) then raise exception 'Eligible class must belong to the same school';end if;
 elsif tg_table_name='schoolpro_document_issues' then
   if new.template_id is not null and not exists(select 1 from public.schoolpro_document_templates t where t.id=new.template_id and t.school_id=new.school_id) then raise exception 'Document template must belong to the same school';end if;
   if new.student_id is not null and not exists(select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id) then raise exception 'Document student must belong to the same school';end if;
 end if;
 return new;
end $function$

```

## `private.guard_schoolpro_document_issue_lifecycle()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.guard_schoolpro_document_issue_lifecycle()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if current_setting('ihlink.document_lifecycle_rpc',true)='on' then return new;end if;
 if tg_op='INSERT' then
  if new.status<>'draft' or new.issued_at is not null or new.output_storage_path is not null then raise exception 'Documents must be created as drafts';end if;
  if new.student_id is not null and not exists(select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id) then raise exception 'Student must belong to document school';end if;
  if new.template_id is not null and not exists(select 1 from public.schoolpro_document_templates t where t.id=new.template_id and t.school_id=new.school_id) then raise exception 'Template must belong to document school';end if;
 elsif old.status in('issued','revoked') then
  if new is distinct from old then raise exception 'Issued/revoked document records are immutable; use lifecycle RPCs';end if;
 elsif old.status='draft' then
  if new.school_id<>old.school_id or new.serial_number<>old.serial_number then raise exception 'Document identity cannot be changed';end if;
  if new.status not in('draft','issued') then raise exception 'Invalid document transition';end if;
 end if;return new;
end $function$

```

## `private.schoolpro_auto_fee_invoices()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_auto_fee_invoices()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if TG_TABLE_NAME='schoolpro_fee_structures' then
  if TG_OP='UPDATE' and (new.school_id,new.term,new.session,new.class_name) is distinct from (old.school_id,old.term,old.session,old.class_name)
   and exists(select 1 from public.schoolpro_invoices where fee_structure_id=new.id) then
   raise exception 'Create a new fee schedule for a different school, class, term or session; existing invoices retain their identity';
  end if;
  perform private.sync_schoolpro_fee_invoices(new.id,null);
 elsif TG_TABLE_NAME='schoolpro_fee_items' then
  if TG_OP='DELETE' and not exists(select 1 from public.schoolpro_fee_structures where id=old.fee_structure_id) then return null; end if;
  if TG_OP='UPDATE' and new.fee_structure_id is distinct from old.fee_structure_id then
   perform private.sync_schoolpro_fee_invoices(old.fee_structure_id,null);
  end if;
  perform private.sync_schoolpro_fee_invoices(case when TG_OP='DELETE' then old.fee_structure_id else new.fee_structure_id end,null);
 end if;
 return null;
end $function$

```

## `private.schoolpro_notify_discipline()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_notify_discipline()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 insert into public.schoolpro_notifications(school_id,user_id,title,message,kind,href)
 select new.school_id,recipient,'Student concern reported','A staff member reported a student concern. Review the report and decide the next action.','discipline','/schoolpro/discipline' from (
 select owner_id recipient from public.schoolpro_schools where id=new.school_id union select user_id from public.schoolpro_members where school_id=new.school_id and role::text in('proprietor','administrator')) r where recipient is not null;
 return new;
end $function$

```

## `private.sync_school_fee_receiving_account()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.sync_school_fee_receiving_account()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare account_id uuid;
begin
 if new.is_active and (nullif(trim(new.account_name),'') is null or nullif(trim(new.account_number),'') is null or nullif(trim(new.bank_name),'') is null) then
  raise exception 'Complete bank name, account name and account number before enabling school fee collection';
 end if;
 if nullif(trim(new.account_name),'') is null or nullif(trim(new.account_number),'') is null or nullif(trim(new.bank_name),'') is null then return new; end if;
 if TG_OP='UPDATE' and old.receiving_account_id is not null and old.account_number is distinct from new.account_number then
  update public.schoolpro_bank_accounts set is_primary=false,updated_at=now() where id=old.receiving_account_id;
 end if;
 insert into public.schoolpro_bank_accounts(school_id,bank_name,account_name,account_number,is_primary,active,created_by)
 values(new.school_id,trim(new.bank_name),trim(new.account_name),trim(new.account_number),new.is_active,new.is_active,new.updated_by)
 on conflict(school_id,account_number) do update set bank_name=excluded.bank_name,account_name=excluded.account_name,
  is_primary=excluded.is_primary,active=excluded.active,updated_at=now()
 returning id into account_id;
 new.receiving_account_id:=account_id;
 return new;
end $function$

```

## `private.sync_schoolpro_demo_invoice()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.sync_schoolpro_demo_invoice()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin perform private.create_schoolpro_demo_invoice(new.id); return new; end $function$

```

## `private.validate_candidate_cbt_tenant()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.validate_candidate_cbt_tenant()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare aschool uuid;tschool uuid; begin select school_id into aschool from public.schoolpro_admissions where id=new.application_id;select school_id into tschool from public.schoolpro_cbt_tests where id=new.test_id;if aschool is null or tschool is null or aschool<>tschool then raise exception 'Candidate CBT application and test must belong to the same school';end if;return new;end $function$

```

## `private.validate_schoolpro_cbt_eligibility()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.validate_schoolpro_cbt_eligibility()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not exists(select 1 from public.schoolpro_cbt_tests t where t.id=new.test_id and t.school_id=new.school_id) then
   raise exception 'CBT test does not belong to eligibility school';
 end if;
 if new.student_id is not null and not exists(
   select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id
 ) then raise exception 'Student does not belong to eligibility school'; end if;
 if new.class_id is not null and not exists(
   select 1 from public.schoolpro_classes c where c.id=new.class_id and c.school_id=new.school_id
 ) then raise exception 'Class does not belong to eligibility school'; end if;
 if new.student_id is null and new.class_id is null then
   raise exception 'Eligibility must target a student or class';
 end if;
 return new;
end $function$

```

## `private.validate_schoolpro_workflow_record()`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION private.validate_schoolpro_workflow_record()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if tg_op='DELETE' then
    if tg_table_name='schoolpro_payroll_records' and old.status<>'draft' then
      raise exception 'Only draft payroll records can be deleted';
    end if;
    return old;
  end if;
  if tg_op='UPDATE' and new.school_id is distinct from old.school_id then
    raise exception 'A record cannot be moved to another school';
  end if;
  if tg_table_name='schoolpro_payroll_records' then
    if new.member_id is null or not exists(select 1 from public.schoolpro_members where id=new.member_id and school_id=new.school_id) then
      raise exception 'Choose a staff member from this school';
    end if;
    if new.gross<0 or new.deductions<0 or new.deductions>new.gross or new.gross::text in ('NaN','Infinity','-Infinity') or new.deductions::text in ('NaN','Infinity','-Infinity') then
      raise exception 'Check the gross pay and deductions';
    end if;
    if new.status not in ('draft','approved','processed','paid') then raise exception 'Choose a valid payroll status'; end if;
    new.net:=new.gross-new.deductions;
    if tg_op='INSERT' then
      if new.status<>'draft' then raise exception 'Save payroll as a draft before approving it'; end if;
      new.approved_by:=null; new.approved_at:=null; new.paid_at:=null; new.payment_reference:=null;
    else
      if old.status='paid' then
if old.session is null and new.session is not null and (to_jsonb(new)-'session')=(to_jsonb(old)-'session') and (private.is_admin(array['super_admin'::public.user_role]) or private.has_school_access(new.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[])) then return new;end if;
raise exception 'Paid payroll records cannot be changed';end if;
      if old.status in ('approved','processed') and (new.member_id is distinct from old.member_id or new.period is distinct from old.period or new.gross is distinct from old.gross or new.deductions is distinct from old.deductions or new.status='draft') then
        raise exception 'Approved payroll details cannot be changed';
      end if;
      if new.status in ('approved','processed') and old.status='draft' then
        if auth.uid() is null or not private.has_school_access(new.school_id,array['proprietor','administrator','accountant','bursar']::public.school_member_role[]) then raise exception 'Payroll approval is not available for your account'; end if;
        new.approved_by:=auth.uid(); new.approved_at:=now();
      else
        new.approved_by:=old.approved_by; new.approved_at:=old.approved_at;
      end if;
      if new.status='paid' then
        if old.status not in ('approved','processed') or nullif(btrim(new.payment_reference),'') is null then raise exception 'Approve payroll and enter a payment reference before marking it paid'; end if;
        new.paid_at:=now();
      else
        new.paid_at:=old.paid_at; new.payment_reference:=old.payment_reference;
      end if;
    end if;
  elsif tg_table_name='schoolpro_health_records' then
    if not exists(select 1 from public.schoolpro_students where id=new.student_id and school_id=new.school_id) then raise exception 'Choose a student from this school'; end if;
    if new.status not in ('open','follow-up','closed') then raise exception 'Choose a valid clinic status'; end if;
    if new.status='follow-up' and new.follow_up_date is null then raise exception 'Choose a follow-up date'; end if;
    if tg_op='INSERT' then new.recorded_by:=auth.uid(); else new.recorded_by:=old.recorded_by; end if;
  elsif tg_table_name='schoolpro_calendar_events' then
    if new.end_date<new.event_date then raise exception 'The event end date must not be before its start date'; end if;
    if new.class_id is not null and not exists(select 1 from public.schoolpro_classes where id=new.class_id and school_id=new.school_id) then raise exception 'Choose a class from this school'; end if;
  end if;
  return new;
end $function$

```

## `public.queue_schoolpro_transactional_email()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION public.queue_schoolpro_transactional_email()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare sid uuid; sch uuid; email text; nm text; subj text; msg text; key text;
begin
 if tg_table_name='schoolpro_fee_payments' then sid:=new.student_id; sch:=new.school_id; key:='payment_receipt'; subj:='SchoolPro payment receipt'; msg:='A payment of NGN '||new.amount||' has been recorded. Reference: '||coalesce(new.reference,'N/A')||'.';
 elsif tg_table_name='schoolpro_results' and new.status::text='published' and old.status::text is distinct from 'published' then sid:=new.student_id; sch:=new.school_id; key:='result_published'; subj:='SchoolPro result published'; msg:='A result has been published for '||new.term||', '||new.session||'.';
 else return new; end if;
 select u.email,concat_ws(' ',s.first_name,s.last_name) into email,nm from schoolpro_students s left join auth.users u on u.id=s.user_id where s.id=sid;
 if email is not null then insert into schoolpro_email_queue(school_id,recipient_email,recipient_name,template_key,subject,payload,status) values(sch,email,nm,key,subj,jsonb_build_object('message',msg,'student_id',sid),'pending'); end if;
 return new;
end $function$

```

## `private.calculate_result_total()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.calculate_result_total()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare scheme record; component jsonb; component_key text; max_score numeric; entered_score numeric; calculated numeric := 0;
begin
  if new.assessment_scheme_id is null then return new; end if;
  select school_id,components into scheme from public.schoolpro_assessment_schemes where id = new.assessment_scheme_id;
  if scheme.school_id is null or scheme.school_id <> new.school_id then raise exception 'Assessment scheme does not belong to this school'; end if;
  for component in select value from jsonb_array_elements(scheme.components) loop
    component_key := component->>'key'; max_score := (component->>'maxScore')::numeric;
    entered_score := coalesce((new.assessment_scores->>component_key)::numeric,0);
    if entered_score < 0 or entered_score > max_score then raise exception '% must be between 0 and %', component->>'label', max_score; end if;
    calculated := calculated + entered_score;
  end loop;
  new.total_score := calculated;
  return new;
end; $function$

```

## `private.enforce_result_workflow()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.enforce_result_workflow()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if old.status = 'published' and (new.ca_score <> old.ca_score or new.exam_score <> old.exam_score or new.assessment_scores is distinct from old.assessment_scores or new.assessment_scheme_id is distinct from old.assessment_scheme_id) then
    raise exception 'Published results are locked';
  end if;
  if new.status is distinct from old.status and not (private.is_admin(array['super_admin']::public.user_role[]) or private.has_school_access(new.school_id, array['proprietor','administrator','exam_officer','head_teacher','vice_principal']::public.school_member_role[])) then
    raise exception 'Only school leaders can approve or publish results';
  end if;
  if new.status = 'approved' and old.status <> 'approved' then new.approved_by := auth.uid(); new.approved_at := now(); end if;
  if new.status = 'published' and old.status <> 'published' then new.published_at := now(); end if;
  return new;
end;
$function$

```

## `private.protect_schoolpro_proprietor_role()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.protect_schoolpro_proprietor_role()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_school uuid := coalesce(new.school_id, old.school_id);
  v_is_owner boolean;
begin
  select exists(
    select 1 from public.schoolpro_schools s
    where s.id=v_school and s.owner_id=auth.uid()
  ) into v_is_owner;

  if private.is_admin(array['super_admin'::public.user_role]) or v_is_owner then
    return coalesce(new,old);
  end if;

  if tg_op='INSERT' and new.role='proprietor'::public.school_member_role then
    raise exception 'Only the school owner or Super Administrator can assign the Proprietor role.';
  elsif tg_op='UPDATE' and (
    new.role='proprietor'::public.school_member_role
    or old.role='proprietor'::public.school_member_role
  ) and new.role is distinct from old.role then
    raise exception 'Only the school owner or Super Administrator can change the Proprietor role.';
  elsif tg_op='DELETE' and old.role='proprietor'::public.school_member_role then
    raise exception 'Only the school owner or Super Administrator can remove a Proprietor.';
  end if;

  return coalesce(new,old);
end;
$function$

```

## `private.schoolpro_archive_progression()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_archive_progression()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare oldclass public.schoolpro_classes; nextclass public.schoolpro_classes; nextsession text; yearstart integer;
begin
 if new.status<>'applied' or old.status='applied' then return new;end if;
 if new.session !~ '^[0-9]{4}/[0-9]{4}$' then raise exception 'Select a valid source academic session';end if;
 yearstart:=split_part(new.session,'/',1)::integer;
 if split_part(new.session,'/',2)::integer<>yearstart+1 then raise exception 'Academic session must span consecutive years';end if;
 select * into oldclass from public.schoolpro_classes where id=new.from_class_id and school_id=new.school_id;
 if oldclass.id is null then raise exception 'Source class does not belong to this school';end if;
 if not exists(select 1 from public.schoolpro_students where id=new.student_id and school_id=new.school_id) then raise exception 'Student does not belong to this school';end if;
 insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id,class_name,arm,section,status,graduation_year,promotion_id)
 values(new.school_id,new.student_id,new.session,oldclass.id,oldclass.name,oldclass.arm,oldclass.level,case when new.decision='graduated' then 'graduated' else 'completed' end,case when new.decision='graduated' then yearstart+1 end,new.id)
 on conflict(school_id,student_id,session) do update set status=excluded.status,graduation_year=excluded.graduation_year,promotion_id=excluded.promotion_id;
 if new.decision in ('promoted','repeated') then
 select * into nextclass from public.schoolpro_classes where id=new.to_class_id and school_id=new.school_id;
 if nextclass.id is null then raise exception 'Destination class does not belong to this school';end if;
 nextsession:=(yearstart+1)::text||'/'||(yearstart+2)::text;
 insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id,class_name,arm,section,status,promotion_id)
 values(new.school_id,new.student_id,nextsession,nextclass.id,nextclass.name,nextclass.arm,nextclass.level,'active',new.id)
 on conflict(school_id,student_id,session) do nothing;
 end if;
 return new;
end $function$

```

## `private.schoolpro_clear_changed_board_role()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_clear_changed_board_role()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$begin if new.role<>'administrator' then delete from public.schoolpro_board_members where member_id=new.id;end if;return new;end$function$

```

## `private.schoolpro_guardian_school_scope()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_guardian_school_scope()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not exists(select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id) then
 raise exception 'The student must belong to the selected school';end if;return new;
end;$function$

```

## `private.schoolpro_validate_calendar()`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_validate_calendar()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$begin if new.term_start_date is not null and new.term_end_date is not null then if new.term_end_date<new.term_start_date then raise exception 'Term ending must follow its beginning';end if;perform pg_advisory_xact_lock(hashtextextended(new.school_id::text,0));if exists(select 1 from public.schoolpro_result_term_settings t where t.school_id=new.school_id and (t.session,t.term) is distinct from(new.session,new.term) and t.id<>new.id and t.term_start_date<=new.term_end_date and t.term_end_date>=new.term_start_date) then raise exception 'Academic term dates cannot overlap in the same school';end if;end if;return new;end$function$

```

## `private.schoolpro_validate_lesson_workflow()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_validate_lesson_workflow()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare leader boolean;
begin
 if auth.uid() is null then raise exception 'Sign in to manage lesson notes';end if;
 leader:=private.schoolpro_lesson_leader(case when tg_op='DELETE' then old.school_id else new.school_id end);
 if tg_op='DELETE' then
  if old.status in('submitted','approved') then raise exception 'Reviewed or submitted lessons must be retained';end if;
  return old;
 end if;
 if new.status not in('draft','submitted','approved','changes_requested') then raise exception 'Choose a valid lesson status';end if;
 if tg_op='INSERT' then
  new.created_by:=auth.uid();
  if new.status not in('draft','submitted') then raise exception 'Save a draft or submit it for review first';end if;
  new.review_comment:=null;new.reviewed_by:=null;new.reviewed_at:=null;
 else
  if new.school_id<>old.school_id or new.created_by is distinct from old.created_by then raise exception 'Lesson ownership cannot be changed';end if;
  if old.status='approved' then raise exception 'Approved lessons must be retained; prepare a new copy';end if;
  if not leader then
   if old.status='submitted' then raise exception 'Wait for school review before editing this lesson';end if;
   if new.status not in('draft','submitted') then raise exception 'Only school leadership can review a lesson';end if;
   if new.review_comment is distinct from old.review_comment or new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at then raise exception 'School review cannot be changed';end if;
  elsif new.status in('approved','changes_requested') and new.status is distinct from old.status then
   if old.status<>'submitted' then raise exception 'Only a submitted lesson can be reviewed';end if;
   if new.status='changes_requested' and coalesce(trim(new.review_comment),'')='' then raise exception 'Explain the changes needed';end if;
   if (to_jsonb(new)-array['status','review_comment','reviewed_by','reviewed_at','updated_at']) is distinct from (to_jsonb(old)-array['status','review_comment','reviewed_by','reviewed_at','updated_at']) then raise exception 'Review the saved lesson without changing its content';end if;
   new.reviewed_by:=auth.uid();new.reviewed_at:=now();
  elsif old.status='submitted' then raise exception 'Approve the lesson or request changes';
  end if;
 end if;
 if not leader and not private.schoolpro_lesson_author_scope(new.school_id,new.class_id,new.subject_id) then raise exception 'Choose your assigned class and subject';end if;
 if new.week is not null and (new.week<1 or new.week>53) then raise exception 'Week must be between 1 and 53';end if;
 if new.duration_minutes is not null and (new.duration_minutes<1 or new.duration_minutes>480) then raise exception 'Choose a lesson duration between 1 and 480 minutes';end if;
 if jsonb_typeof(new.plan)<>'object' then raise exception 'Lesson plan must contain named fields';end if;
 if new.status='submitted' and (new.class_id is null or new.subject_id is null or new.lesson_date is null or coalesce(trim(new.term),'')='' or coalesce(trim(new.session),'')='' or coalesce(trim(new.title),'')='' or coalesce(trim(new.plan->>'objectives'),'')='' or coalesce(trim(new.content),'')='') then raise exception 'Complete the class, subject, date, period, objectives and lesson content before submission';end if;
 new.updated_at:=now();return new;
end;
$function$

```

## `private.sync_schoolpro_onboarding_demo_invoice()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.sync_schoolpro_onboarding_demo_invoice()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare demo uuid;
begin
 for demo in select id from public.schoolpro_demo_requests where school_id=new.school_id and user_id=new.user_id loop perform private.create_schoolpro_demo_invoice(demo); end loop;
 return new;
end $function$

```

## `private.validate_schoolpro_leave()`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION private.validate_schoolpro_leave()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if new.start_date is null or new.end_date is null or new.end_date<new.start_date then raise exception 'Choose valid leave dates'; end if;
 if not exists(select 1 from public.schoolpro_members m where m.id=new.member_id and m.school_id=new.school_id) then raise exception 'Choose a staff member from this school';end if;
 if new.status not in ('pending','approved','rejected','cancelled') then raise exception 'Choose a valid leave status';end if;
 if tg_op='INSERT' and (new.status<>'pending' or new.reviewed_by is not null or new.reviewed_at is not null) then raise exception 'New leave requests must await approval';end if;
 if tg_op='UPDATE' then
  if new.school_id<>old.school_id or new.member_id<>old.member_id then raise exception 'The school and requester cannot be changed';end if;
  if old.session is null and new.session is not null and (to_jsonb(new)-'session')=(to_jsonb(old)-'session') and (private.is_admin(array['super_admin']::public.user_role[]) or private.has_school_access(new.school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[])) then return new;end if;
  if old.status<>'pending' then raise exception 'A reviewed leave request cannot be changed';end if;
  if new.status in ('approved','rejected') then
   if auth.uid() is null or not private.schoolpro_module_allowed(new.school_id,'leave') or not private.has_school_access(new.school_id,array['proprietor','administrator','hr_officer']::public.school_member_role[]) then raise exception 'School approval is required';end if;
   if exists(select 1 from public.schoolpro_members m where m.id=new.member_id and m.user_id=auth.uid()) then raise exception 'Another authorised person must review your leave';end if;
   new.reviewed_by:=auth.uid();new.reviewed_at:=now();
  elsif new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at then raise exception 'Review details are set during approval';end if;
 end if;
 return new;
end $function$

```

## `private.create_default_school_assessment_scheme()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.create_default_school_assessment_scheme()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ begin perform private.seed_schoolpro_report_defaults(new.id);return new;end $function$

```

## `private.log_schoolpro_result_lifecycle()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.log_schoolpro_result_lifecycle()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare ev text; begin if old.status is distinct from new.status then ev:=case when new.status='approved' then 'approved' when new.status='published' then 'published' when old.status='published' and new.status='draft' then 'reopened' when old.status='approved' and new.status='draft' then 'rejected' else null end;if ev is not null then insert into public.schoolpro_result_events(school_id,result_id,event_type,actor_id,snapshot) values(new.school_id,new.id,ev,auth.uid(),to_jsonb(new));end if;end if;return new;end $function$

```

## `private.schoolpro_enrollment_calendar()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_enrollment_calendar()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$declare period text;c public.schoolpro_classes;begin
 period:=new.enrollment_session;
 if nullif(period,'') is null then select session into period from public.schoolpro_result_term_settings where school_id=new.school_id and term_start_date<=current_date and term_end_date>=current_date order by term_start_date desc limit 1;end if;
 if nullif(period,'') is null then return new;end if;
 if period!~'^[0-9]{4}/[0-9]{4}$' or split_part(period,'/',2)::int<>split_part(period,'/',1)::int+1 then raise exception 'Choose a valid enrolment session';end if;
 select * into c from public.schoolpro_classes where id=new.class_id and school_id=new.school_id;
 insert into public.schoolpro_enrollment_history(school_id,student_id,session,class_id,class_name,arm,section,status)values(new.school_id,new.id,period,new.class_id,c.name,coalesce(c.arm,''),coalesce(c.level,'unassigned'),'active') on conflict(school_id,student_id,session)do nothing;
 return new;end$function$

```

## `private.schoolpro_transcript_enrichment()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.schoolpro_transcript_enrichment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
new.snapshot:=new.snapshot||jsonb_build_object('records',(select jsonb_agg(jsonb_build_object('subject_id',r.subject_id,'subject',sub.name||case when nullif(sub.code,'') is null then '' else ' ('||sub.code||')' end,'session',r.session,'term',r.term,'score',r.total_score,'class_name',coalesce(e.class_name,s.class_name),'arm',e.arm)order by r.session,r.term,sub.name,sub.code) from public.schoolpro_results r join public.schoolpro_subjects sub on sub.id=r.subject_id and sub.school_id=r.school_id join public.schoolpro_students s on s.id=r.student_id left join public.schoolpro_enrollment_history e on e.student_id=r.student_id and e.school_id=r.school_id and e.session=r.session where r.student_id=new.student_id and r.school_id=new.school_id and r.status='published'),'school_id',new.school_id,'format_version',2,'officers',coalesce((select officers from public.schoolpro_transcript_settings where school_id=new.school_id),'[]'::jsonb),'logo_url',(select logo_url from public.schoolpro_branding where school_id=new.school_id limit 1),
'period_details',coalesce((select jsonb_agg(jsonb_build_object('session',p.session,'term',p.term,'attendance',(select jsonb_build_object('recorded',count(*),'present',count(*)filter(where a.status::text in('present','late')),'absent',count(*)filter(where a.status::text='absent'),'excused',count(*)filter(where a.status::text='excused')) from public.schoolpro_attendance a where a.school_id=new.school_id and a.student_id=new.student_id and a.session=p.session and a.term=p.term),
'ratings',coalesce((select jsonb_agg(jsonb_build_object('name',d.name,'domain',d.domain_type,'rating',coalesce(nullif(r.rating_label,''),r.rating::text))order by d.position)from public.schoolpro_result_domain_ratings r join public.schoolpro_result_domain_definitions d on d.id=r.definition_id and d.school_id=r.school_id where r.school_id=new.school_id and r.student_id=new.student_id and r.session=p.session and r.term=p.term),'[]'::jsonb),
'teacher_comments',coalesce((select jsonb_agg(distinct teacher_comment) filter(where nullif(teacher_comment,'')is not null)from public.schoolpro_results r where r.student_id=new.student_id and r.school_id=new.school_id and r.session=p.session and r.term=p.term and r.status='published'),'[]'::jsonb),
'principal_comments',coalesce((select jsonb_agg(distinct head_teacher_comment) filter(where nullif(head_teacher_comment,'')is not null)from public.schoolpro_results r where r.student_id=new.student_id and r.school_id=new.school_id and r.session=p.session and r.term=p.term and r.status='published'),'[]'::jsonb))
 order by p.session,p.term) from(select distinct r.session,r.term from public.schoolpro_results r where r.student_id=new.student_id and r.school_id=new.school_id and r.status='published')p),'[]'::jsonb));
return new;
end $function$

```

## `private.sync_school_request_activation()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.sync_school_request_activation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ begin
 if new.status='active' and private.schoolpro_operationally_active(new.id) then update public.schoolpro_onboarding_requests set status='active',updated_at=now() where school_id=new.id and status<>'active';end if;return new;end $function$

```

## `private.validate_schoolpro_result_tenant()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.validate_schoolpro_result_tenant()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not exists(select 1 from public.schoolpro_students s where s.id=new.student_id and s.school_id=new.school_id) then raise exception 'Student does not belong to result school';end if;
 if not exists(select 1 from public.schoolpro_subjects s where s.id=new.subject_id and s.school_id=new.school_id) then raise exception 'Subject does not belong to result school';end if;
 if nullif(trim(new.session),'') is null or nullif(trim(new.term),'') is null then raise exception 'Term and session are required';end if;
 new.session:=trim(new.session);new.term:=trim(new.term);return new;
end $function$

```

## `private.validate_schoolpro_subject_assignment()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.validate_schoolpro_subject_assignment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if nullif(trim(new.session),'') is null then raise exception 'Academic session is required';end if;
 new.session:=trim(new.session);
 if not exists(select 1 from public.schoolpro_classes c where c.id=new.class_id and c.school_id=new.school_id)
 then raise exception 'Class does not belong to this school';end if;
 if not exists(select 1 from public.schoolpro_subjects s where s.id=new.subject_id and s.school_id=new.school_id)
 then raise exception 'Subject does not belong to this school';end if;
 if not exists(select 1 from public.schoolpro_members m where m.id=new.teacher_member_id and m.school_id=new.school_id
   and m.role in('teacher','class_teacher','head_teacher','vice_principal','administrator','proprietor'))
 then raise exception 'Assigned teacher/member is not eligible in this school';end if;
 return new;
end $function$

```

## `private.validate_student_class()`
- Language: `plpgsql`; SECURITY DEFINER: `true`

```sql
CREATE OR REPLACE FUNCTION private.validate_student_class()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare selected_class record;
begin
  if new.class_id is null then return new; end if;
  select school_id,name,arm into selected_class from public.schoolpro_classes where id=new.class_id;
  if selected_class.school_id is null or selected_class.school_id<>new.school_id then raise exception 'Selected class does not belong to this school'; end if;
  new.class_name:=selected_class.name||case when selected_class.arm='' then '' else ' '||selected_class.arm end;
  return new;
end; $function$

```

## `public.enforce_schoolpro_result_lock()`
- Language: `plpgsql`; SECURITY DEFINER: `false`

```sql
CREATE OR REPLACE FUNCTION public.enforce_schoolpro_result_lock()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$ begin if old.locked=true and new.locked=true and (to_jsonb(new)-'locked'-'updated_at') is distinct from (to_jsonb(old)-'locked'-'updated_at') then raise exception 'Result is locked'; end if; return new; end $function$

```
