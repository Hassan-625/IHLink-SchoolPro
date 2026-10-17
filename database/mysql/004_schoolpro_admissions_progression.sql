-- SchoolPro admissions and student progression history.
-- Draft MySQL 8.4 schema, built from a read-only source column inventory.
-- No live rows are copied; promotion remains preview/decision/apply, never auto-promoted by result publication.

CREATE TABLE IF NOT EXISTS admissions (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  application_number VARCHAR(100) NOT NULL,
  public_token CHAR(36) NOT NULL,
  applicant_name VARCHAR(200) NOT NULL,
  first_name VARCHAR(100) NULL,
  last_name VARCHAR(100) NULL,
  gender VARCHAR(40) NULL,
  date_of_birth DATE NULL,
  guardian_name VARCHAR(200) NULL,
  guardian_contact VARCHAR(100) NULL,
  guardian_email VARCHAR(254) NULL,
  previous_school VARCHAR(200) NULL,
  class_applied VARCHAR(120) NULL,
  status ENUM('submitted','under_review','entrance_test','offered','accepted','rejected','withdrawn','enrolled') NOT NULL DEFAULT 'submitted',
  notes TEXT NULL,
  reviewed_by CHAR(36) NULL,
  reviewed_at DATETIME(6) NULL,
  admitted_student_id CHAR(36) NULL,
  entrance_test_id CHAR(36) NULL,
  entrance_score DECIMAL(7,2) NULL,
  acceptance_fee_status ENUM('not_required','pending','paid','waived','rejected') NOT NULL DEFAULT 'pending',
  submitted_at DATETIME(6) NULL,
  accepted_at DATETIME(6) NULL,
  enrollment_status ENUM('not_enrolled','pending','enrolled','cancelled') NOT NULL DEFAULT 'not_enrolled',
  enrolled_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_admission_school_id (school_id,id),
  UNIQUE KEY uq_admission_application_number (school_id,application_number),
  UNIQUE KEY uq_admission_public_token (public_token),
  KEY idx_admissions_review_queue (school_id,status,created_at),
  KEY idx_admissions_enrollment (school_id,enrollment_status,accepted_at),
  CONSTRAINT fk_admission_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE RESTRICT,
  CONSTRAINT fk_admission_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_admission_student FOREIGN KEY (school_id,admitted_student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT chk_admission_applicant_name CHECK (CHAR_LENGTH(TRIM(applicant_name)) > 0),
  CONSTRAINT chk_admission_application_number CHECK (CHAR_LENGTH(TRIM(application_number)) > 0),
  CONSTRAINT chk_admission_entrance_score CHECK (entrance_score IS NULL OR (entrance_score >= 0 AND entrance_score <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admission_documents (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  application_id CHAR(36) NOT NULL,
  document_type VARCHAR(80) NOT NULL,
  storage_path VARCHAR(700) NOT NULL,
  file_name VARCHAR(255) NULL,
  mime_type VARCHAR(120) NULL,
  file_size BIGINT UNSIGNED NULL,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  verified_by CHAR(36) NULL,
  verified_at DATETIME(6) NULL,
  verification_notes VARCHAR(2000) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_admission_document_school_id (school_id,id),
  KEY idx_admission_documents_application (school_id,application_id,created_at),
  CONSTRAINT fk_admission_document_application FOREIGN KEY (school_id,application_id) REFERENCES admissions(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_admission_document_verifier FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_admission_document_path CHECK (SUBSTRING_INDEX(storage_path,'/',1)=school_id),
  CONSTRAINT chk_admission_document_size CHECK (file_size IS NULL OR file_size > 0),
  CONSTRAINT chk_admission_document_verification CHECK ((verified=FALSE) OR (verified_at IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admission_offers (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  application_id CHAR(36) NOT NULL,
  offer_number VARCHAR(100) NOT NULL,
  offered_class VARCHAR(120) NULL,
  letter_body TEXT NULL,
  issued_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  expires_at DATETIME(6) NULL,
  accepted_at DATETIME(6) NULL,
  status ENUM('draft','issued','accepted','declined','expired','revoked') NOT NULL DEFAULT 'draft',
  public_token CHAR(36) NOT NULL,
  acceptance_instructions TEXT NULL,
  created_by CHAR(36) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_admission_offer_school_id (school_id,id),
  UNIQUE KEY uq_admission_offer_number (school_id,offer_number),
  UNIQUE KEY uq_admission_offer_public_token (public_token),
  KEY idx_admission_offer_status (school_id,status,issued_at),
  CONSTRAINT fk_admission_offer_application FOREIGN KEY (school_id,application_id) REFERENCES admissions(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_admission_offer_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_admission_offer_dates CHECK (expires_at IS NULL OR expires_at >= issued_at),
  CONSTRAINT chk_admission_offer_acceptance CHECK ((status<>'accepted') OR accepted_at IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admission_events (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  application_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  scheduled_at DATETIME(6) NULL,
  location VARCHAR(255) NULL,
  notes TEXT NULL,
  status ENUM('scheduled','completed','cancelled','missed') NOT NULL DEFAULT 'scheduled',
  created_by CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_admission_event_school_id (school_id,id),
  KEY idx_admission_event_schedule (school_id,scheduled_at,status),
  CONSTRAINT fk_admission_event_application FOREIGN KEY (school_id,application_id) REFERENCES admissions(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_admission_event_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_admission_event_type CHECK (CHAR_LENGTH(TRIM(event_type)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admission_acceptances (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  application_id CHAR(36) NOT NULL,
  offer_id CHAR(36) NULL,
  accepted_by_name VARCHAR(200) NOT NULL,
  accepted_by_email VARCHAR(254) NULL,
  accepted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  terms_accepted BOOLEAN NOT NULL DEFAULT FALSE,
  notes TEXT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_admission_acceptance_school_id (school_id,id),
  UNIQUE KEY uq_admission_acceptance_application (school_id,application_id),
  CONSTRAINT fk_admission_acceptance_application FOREIGN KEY (school_id,application_id) REFERENCES admissions(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_admission_acceptance_offer FOREIGN KEY (school_id,offer_id) REFERENCES admission_offers(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT chk_admission_acceptor CHECK (CHAR_LENGTH(TRIM(accepted_by_name)) > 0),
  CONSTRAINT chk_admission_terms CHECK (terms_accepted=TRUE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_enrollment_history (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  session_id CHAR(36) NOT NULL,
  class_id CHAR(36) NOT NULL,
  class_name_snapshot VARCHAR(120) NOT NULL,
  arm_snapshot VARCHAR(80) NOT NULL DEFAULT '',
  section_snapshot VARCHAR(80) NOT NULL DEFAULT '',
  status ENUM('active','promoted','graduated','transferred_out','repeated','withdrawn') NOT NULL,
  graduation_year SMALLINT UNSIGNED NULL,
  promotion_id CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_enrollment_history_school_id (school_id,id),
  UNIQUE KEY uq_enrollment_history_student_session (school_id,student_id,session_id),
  KEY idx_enrollment_history_class (school_id,session_id,class_id,status),
  CONSTRAINT fk_enrollment_history_student FOREIGN KEY (school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_enrollment_history_session FOREIGN KEY (school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_enrollment_history_class FOREIGN KEY (school_id,class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT chk_enrollment_history_class_name CHECK (CHAR_LENGTH(TRIM(class_name_snapshot)) > 0),
  CONSTRAINT chk_enrollment_history_graduation CHECK ((status='graduated' AND graduation_year IS NOT NULL) OR (status<>'graduated'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_promotions (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  from_class_id CHAR(36) NULL,
  to_class_id CHAR(36) NULL,
  session_id CHAR(36) NOT NULL,
  status ENUM('previewed','pending','approved','rejected','applied','graduated','transferred_out','repeated','cancelled') NOT NULL DEFAULT 'previewed',
  decision ENUM('promote','repeat','graduate','transfer_out','hold') NOT NULL DEFAULT 'hold',
  decided_by CHAR(36) NULL,
  applied_by CHAR(36) NULL,
  applied_at DATETIME(6) NULL,
  reason VARCHAR(2000) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_student_promotion_school_id (school_id,id),
  UNIQUE KEY uq_student_promotion_session (school_id,student_id,session_id),
  KEY idx_student_promotion_queue (school_id,session_id,status,decision),
  CONSTRAINT fk_student_promotion_student FOREIGN KEY (school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_student_promotion_from_class FOREIGN KEY (school_id,from_class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_student_promotion_to_class FOREIGN KEY (school_id,to_class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_student_promotion_session FOREIGN KEY (school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_student_promotion_decider FOREIGN KEY (decided_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_student_promotion_applier FOREIGN KEY (applied_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_student_promotion_apply_state CHECK ((status='applied' AND applied_at IS NOT NULL AND applied_by IS NOT NULL) OR (status<>'applied')),
  CONSTRAINT chk_student_promotion_target CHECK (
    (decision='promote' AND to_class_id IS NOT NULL)
    OR (decision IN ('repeat','graduate','transfer_out','hold') )
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (version,description)
VALUES ('004_schoolpro_admissions_progression','Draft admissions workflow, student enrollment history and explicit promotion decisions; disposable test only') AS incoming
ON DUPLICATE KEY UPDATE description=incoming.description;
