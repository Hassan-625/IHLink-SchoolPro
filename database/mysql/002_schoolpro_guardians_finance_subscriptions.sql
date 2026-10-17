-- SchoolPro finance, guardian and manual subscription receipt foundation.
-- Draft MySQL 8.4 migration. Apply only to disposable CI/development databases.
-- This migration deliberately models school fee receipt review and IHLink-admin
-- subscription receipt review. It does NOT port gateway/virtual-account intents:
-- BillStack remains DataSub-only and SchoolPro online gateway use is disabled.
-- All SchoolPro subscription cycles are annual; Demo carries no paid amount.

CREATE TABLE IF NOT EXISTS guardian_student_links (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  guardian_user_id CHAR(36) NOT NULL,
  relationship_code VARCHAR(40) NOT NULL,
  status ENUM('pending','active','revoked') NOT NULL DEFAULT 'pending',
  linked_by CHAR(36) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_guardian_student_pair (school_id, student_id, guardian_user_id),
  UNIQUE KEY uq_guardian_link_school_id (school_id, id),
  KEY idx_guardian_links_user_status (guardian_user_id, status),
  KEY idx_guardian_links_student_status (school_id, student_id, status),
  CONSTRAINT fk_guardian_link_student FOREIGN KEY (school_id, student_id)
    REFERENCES students(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_guardian_link_user FOREIGN KEY (guardian_user_id)
    REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_guardian_link_creator FOREIGN KEY (linked_by)
    REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT chk_guardian_relationship_nonempty CHECK (CHAR_LENGTH(TRIM(relationship_code)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS school_bank_accounts (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  bank_name VARCHAR(120) NOT NULL,
  account_name VARCHAR(160) NOT NULL,
  account_number VARCHAR(80) NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_bank_account_school_id (school_id, id),
  KEY idx_bank_accounts_school_active (school_id, active, is_primary),
  CONSTRAINT fk_bank_account_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE RESTRICT,
  CONSTRAINT fk_bank_account_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_bank_account_fields CHECK (
    CHAR_LENGTH(TRIM(bank_name)) > 0 AND CHAR_LENGTH(TRIM(account_name)) > 0
    AND CHAR_LENGTH(TRIM(account_number)) > 0
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS fee_structures (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  name VARCHAR(160) NOT NULL,
  class_id CHAR(36) NULL,
  session_id CHAR(36) NOT NULL,
  term_id CHAR(36) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  due_date DATE NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by CHAR(36) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_fee_structure_school_id (school_id, id),
  UNIQUE KEY uq_fee_structure_scope (school_id, name, class_id, session_id, term_id),
  KEY idx_fee_structure_term_active (school_id, session_id, term_id, is_active),
  CONSTRAINT fk_fee_structure_class FOREIGN KEY (school_id, class_id)
    REFERENCES school_classes(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_structure_session FOREIGN KEY (school_id, session_id)
    REFERENCES academic_sessions(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_structure_term FOREIGN KEY (school_id, term_id, session_id)
    REFERENCES academic_terms(school_id, id, session_id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_structure_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT chk_fee_structure_amount CHECK (amount >= 0),
  CONSTRAINT chk_fee_structure_name CHECK (CHAR_LENGTH(TRIM(name)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS fee_structure_items (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  fee_structure_id CHAR(36) NOT NULL,
  label VARCHAR(160) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  category_code VARCHAR(60) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_optional BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_fee_item_school_id (school_id, id),
  KEY idx_fee_items_structure_order (school_id, fee_structure_id, sort_order),
  CONSTRAINT fk_fee_item_structure FOREIGN KEY (school_id, fee_structure_id)
    REFERENCES fee_structures(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT chk_fee_item_amount CHECK (amount >= 0),
  CONSTRAINT chk_fee_item_label CHECK (CHAR_LENGTH(TRIM(label)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS fee_invoices (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  enrollment_id CHAR(36) NULL,
  fee_structure_id CHAR(36) NULL,
  title VARCHAR(200) NOT NULL,
  session_id CHAR(36) NOT NULL,
  term_id CHAR(36) NOT NULL,
  gross_amount DECIMAL(12,2) NOT NULL,
  discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  scholarship_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  waiver_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  amount_due DECIMAL(12,2) NOT NULL,
  amount_paid DECIMAL(12,2) NOT NULL DEFAULT 0,
  due_date DATE NULL,
  status ENUM('unpaid','part_paid','paid','waived') NOT NULL DEFAULT 'unpaid',
  result_hold BOOLEAN NOT NULL DEFAULT FALSE,
  charge_type VARCHAR(60) NOT NULL DEFAULT 'standard',
  notes VARCHAR(2000) NULL,
  created_by CHAR(36) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_invoice_school_id (school_id, id),
  UNIQUE KEY uq_invoice_school_student (school_id, id, student_id),
  UNIQUE KEY uq_invoice_school_student_term (school_id, id, student_id, term_id, session_id),
  KEY idx_invoices_school_term_status (school_id, session_id, term_id, status),
  KEY idx_invoices_student_term (school_id, student_id, session_id, term_id),
  KEY idx_invoices_due_status (school_id, status, due_date),
  CONSTRAINT fk_invoice_student FOREIGN KEY (school_id, student_id)
    REFERENCES students(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_invoice_enrollment_student_session FOREIGN KEY (school_id, enrollment_id, student_id, session_id)
    REFERENCES student_enrollments(school_id, id, student_id, session_id) ON DELETE RESTRICT,
  CONSTRAINT fk_invoice_session FOREIGN KEY (school_id, session_id)
    REFERENCES academic_sessions(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_invoice_term_session FOREIGN KEY (school_id, term_id, session_id)
    REFERENCES academic_terms(school_id, id, session_id) ON DELETE RESTRICT,
  CONSTRAINT fk_invoice_fee_structure FOREIGN KEY (school_id, fee_structure_id)
    REFERENCES fee_structures(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_invoice_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT chk_invoice_amounts CHECK (
    gross_amount >= 0 AND discount_amount >= 0 AND scholarship_amount >= 0
    AND waiver_amount >= 0 AND amount_due >= 0 AND amount_paid >= 0 AND amount_paid <= amount_due
  ),
  CONSTRAINT chk_invoice_title CHECK (CHAR_LENGTH(TRIM(title)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS school_fee_payment_submissions (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  submitted_by CHAR(36) NOT NULL,
  bank_account_id CHAR(36) NULL,
  total_amount DECIMAL(12,2) NOT NULL,
  payment_date DATE NOT NULL,
  payer_name VARCHAR(160) NULL,
  bank_reference VARCHAR(160) NULL,
  receipt_object_key VARCHAR(512) NOT NULL,
  receipt_owner_user_id CHAR(36) NOT NULL,
  receipt_mime VARCHAR(100) NULL,
  status ENUM('pending','confirmed','rejected') NOT NULL DEFAULT 'pending',
  review_note VARCHAR(2000) NULL,
  reviewed_by CHAR(36) NULL,
  reviewed_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_fee_submission_school_id (school_id, id),
  KEY idx_fee_submission_review (school_id, status, created_at),
  KEY idx_fee_submission_submitter (submitted_by, created_at),
  CONSTRAINT fk_fee_submission_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_submission_submitter FOREIGN KEY (submitted_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_submission_bank FOREIGN KEY (school_id, bank_account_id)
    REFERENCES school_bank_accounts(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_submission_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_fee_submission_amount CHECK (total_amount > 0),
  CONSTRAINT chk_fee_submission_receipt_owner CHECK (
    receipt_owner_user_id = submitted_by
    AND SUBSTRING_INDEX(receipt_object_key, '/', 1) = submitted_by
    AND CHAR_LENGTH(TRIM(receipt_object_key)) > 0
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS fee_payments (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  invoice_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  submission_id CHAR(36) NULL,
  amount DECIMAL(12,2) NOT NULL,
  method_code ENUM('bank_transfer','cash','pos','cheque','other') NOT NULL,
  reference VARCHAR(160) NOT NULL,
  notes VARCHAR(2000) NULL,
  paid_at DATETIME(6) NOT NULL,
  recorded_by CHAR(36) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_fee_payment_school_id (school_id, id),
  UNIQUE KEY uq_fee_payment_school_invoice_student (school_id, id, invoice_id, student_id),
  UNIQUE KEY uq_fee_payment_school_reference (school_id, reference),
  KEY idx_fee_payments_invoice_date (school_id, invoice_id, paid_at),
  CONSTRAINT fk_fee_payment_invoice_student FOREIGN KEY (school_id, invoice_id, student_id)
    REFERENCES fee_invoices(school_id, id, student_id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_payment_submission FOREIGN KEY (school_id, submission_id)
    REFERENCES school_fee_payment_submissions(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_payment_recorder FOREIGN KEY (recorded_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT chk_fee_payment_amount CHECK (amount > 0),
  CONSTRAINT chk_fee_payment_reference CHECK (CHAR_LENGTH(TRIM(reference)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS school_fee_payment_allocations (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  submission_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  invoice_id CHAR(36) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_id CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_fee_allocation_submission_invoice (school_id, submission_id, invoice_id),
  KEY idx_fee_allocation_invoice (school_id, invoice_id),
  CONSTRAINT fk_fee_allocation_submission FOREIGN KEY (school_id, submission_id)
    REFERENCES school_fee_payment_submissions(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_allocation_invoice_student FOREIGN KEY (school_id, invoice_id, student_id)
    REFERENCES fee_invoices(school_id, id, student_id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_allocation_payment_invoice_student FOREIGN KEY (school_id, payment_id, invoice_id, student_id)
    REFERENCES fee_payments(school_id, id, invoice_id, student_id) ON DELETE RESTRICT,
  CONSTRAINT chk_fee_allocation_amount CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS school_fee_payment_proofs (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  invoice_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  submitted_by CHAR(36) NOT NULL,
  bank_account_id CHAR(36) NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_date DATE NOT NULL,
  payer_name VARCHAR(160) NULL,
  bank_reference VARCHAR(160) NULL,
  receipt_object_key VARCHAR(512) NOT NULL,
  receipt_owner_user_id CHAR(36) NOT NULL,
  receipt_mime VARCHAR(100) NULL,
  status ENUM('pending','confirmed','rejected') NOT NULL DEFAULT 'pending',
  review_note VARCHAR(2000) NULL,
  reviewed_by CHAR(36) NULL,
  reviewed_at DATETIME(6) NULL,
  payment_id CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_fee_proof_school_id (school_id, id),
  KEY idx_fee_proof_review (school_id, status, created_at),
  CONSTRAINT fk_fee_proof_invoice_student FOREIGN KEY (school_id, invoice_id, student_id)
    REFERENCES fee_invoices(school_id, id, student_id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_proof_submitter FOREIGN KEY (submitted_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_proof_bank FOREIGN KEY (school_id, bank_account_id)
    REFERENCES school_bank_accounts(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_fee_proof_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_fee_proof_payment_invoice_student FOREIGN KEY (school_id, payment_id, invoice_id, student_id)
    REFERENCES fee_payments(school_id, id, invoice_id, student_id) ON DELETE RESTRICT,
  CONSTRAINT chk_fee_proof_amount CHECK (amount > 0),
  CONSTRAINT chk_fee_proof_receipt_owner CHECK (
    receipt_owner_user_id = submitted_by
    AND SUBSTRING_INDEX(receipt_object_key, '/', 1) = submitted_by
    AND CHAR_LENGTH(TRIM(receipt_object_key)) > 0
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS school_subscription_plans (
  code VARCHAR(40) NOT NULL,
  name VARCHAR(120) NOT NULL,
  billing_period ENUM('annual') NOT NULL DEFAULT 'annual',
  annual_price DECIMAL(12,2) NULL,
  is_demo BOOLEAN NOT NULL DEFAULT FALSE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  features JSON NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (code),
  CONSTRAINT chk_subscription_plan_price CHECK (
    (is_demo = TRUE AND annual_price IS NULL)
    OR (is_demo = FALSE AND annual_price IS NOT NULL AND annual_price >= 0)
  ),
  CONSTRAINT chk_subscription_demo_code CHECK (
    (code = 'demo' AND is_demo = TRUE) OR (code <> 'demo' AND is_demo = FALSE)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS school_subscriptions (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  plan_code VARCHAR(40) NOT NULL,
  billing_cycle ENUM('annual') NOT NULL DEFAULT 'annual',
  paid_amount DECIMAL(12,2) NULL,
  status ENUM('demo_active','active','grace','suspended','expired') NOT NULL,
  starts_at DATETIME(6) NOT NULL,
  renews_at DATETIME(6) NULL,
  grace_ends_at DATETIME(6) NULL,
  suspended_at DATETIME(6) NULL,
  managed_by_ihlink BOOLEAN NOT NULL DEFAULT TRUE,
  customization_level VARCHAR(40) NOT NULL DEFAULT 'standard',
  updated_by CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_school_subscription_school (school_id),
  UNIQUE KEY uq_school_subscription_school_id (school_id, id),
  KEY idx_school_subscription_status (status, renews_at, grace_ends_at),
  CONSTRAINT fk_school_subscription_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE RESTRICT,
  CONSTRAINT fk_school_subscription_plan FOREIGN KEY (plan_code) REFERENCES school_subscription_plans(code) ON DELETE RESTRICT,
  CONSTRAINT fk_school_subscription_updater FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_school_subscription_demo_amount CHECK (
    (plan_code = 'demo' AND paid_amount IS NULL)
    OR (plan_code <> 'demo' AND paid_amount IS NOT NULL AND paid_amount >= 0)
  ),
  CONSTRAINT chk_school_subscription_grace CHECK (status <> 'grace' OR grace_ends_at IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS school_subscription_receipts (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  subscription_id CHAR(36) NOT NULL,
  submitted_by CHAR(36) NOT NULL,
  receipt_object_key VARCHAR(512) NOT NULL,
  receipt_owner_user_id CHAR(36) NOT NULL,
  receipt_mime VARCHAR(100) NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_date DATE NOT NULL,
  bank_reference VARCHAR(160) NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  review_note VARCHAR(2000) NULL,
  reviewed_by CHAR(36) NULL,
  reviewed_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_subscription_receipt_school_id (school_id, id),
  KEY idx_subscription_receipts_review (school_id, status, created_at),
  CONSTRAINT fk_subscription_receipt_subscription FOREIGN KEY (school_id, subscription_id)
    REFERENCES school_subscriptions(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_subscription_receipt_submitter FOREIGN KEY (submitted_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_subscription_receipt_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_subscription_receipt_amount CHECK (amount > 0),
  CONSTRAINT chk_subscription_receipt_owner CHECK (
    receipt_owner_user_id = submitted_by
    AND SUBSTRING_INDEX(receipt_object_key, '/', 1) = submitted_by
    AND CHAR_LENGTH(TRIM(receipt_object_key)) > 0
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (version, description)
VALUES ('002_schoolpro_guardians_finance_subscriptions', 'Draft guardian, fee ledger, receipt review and annual subscription schema; disposable test only') AS incoming
ON DUPLICATE KEY UPDATE description = incoming.description;
