-- SchoolPro assessment schemes, grade scales, result review/correction,
-- school-owned workbook/result templates and transcript records.
-- Draft only; apply in disposable MySQL CI until full source parity is accepted.

CREATE TABLE IF NOT EXISTS assessment_schemes (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  name VARCHAR(160) NOT NULL,
  school_level ENUM('nursery','primary','jss','sss') NOT NULL,
  components JSON NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_by CHAR(36) NULL,
  updated_by CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_assessment_scheme_school_id (school_id,id),
  UNIQUE KEY uq_assessment_scheme_name (school_id,name),
  KEY idx_assessment_scheme_level_default (school_id,school_level,is_default),
  CONSTRAINT fk_assessment_scheme_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE RESTRICT,
  CONSTRAINT fk_assessment_scheme_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_assessment_scheme_updater FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_assessment_scheme_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT chk_assessment_scheme_components CHECK (JSON_TYPE(components)='ARRAY' AND JSON_LENGTH(components)>0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS grade_scales (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  label VARCHAR(40) NOT NULL,
  min_score DECIMAL(6,2) NOT NULL,
  max_score DECIMAL(6,2) NOT NULL,
  remark VARCHAR(240) NULL,
  overall_remark VARCHAR(240) NULL,
  position INT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_grade_scale_school_id (school_id,id),
  UNIQUE KEY uq_grade_scale_school_label (school_id,label),
  UNIQUE KEY uq_grade_scale_school_position (school_id,position),
  KEY idx_grade_scale_active_position (school_id,is_active,position),
  CONSTRAINT fk_grade_scale_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE RESTRICT,
  CONSTRAINT chk_grade_scale_range CHECK (min_score >= 0 AND max_score <= 100 AND min_score <= max_score),
  CONSTRAINT chk_grade_scale_label CHECK (CHAR_LENGTH(TRIM(label)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS result_approvals (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  result_id CHAR(36) NOT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  reviewed_by CHAR(36) NULL,
  reviewed_at DATETIME(6) NULL,
  notes VARCHAR(2000) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_result_approval_school_result (school_id,result_id),
  CONSTRAINT fk_result_approval_result FOREIGN KEY (school_id,result_id) REFERENCES result_records(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_result_approval_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_result_approval_review_state CHECK (
    (status='pending' AND reviewed_at IS NULL) OR (status<>'pending' AND reviewed_at IS NOT NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS result_correction_requests (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  result_id CHAR(36) NOT NULL,
  requested_by CHAR(36) NOT NULL,
  reason VARCHAR(2000) NOT NULL,
  status ENUM('pending','approved','rejected','applied','withdrawn') NOT NULL DEFAULT 'pending',
  reviewed_by CHAR(36) NULL,
  reviewed_at DATETIME(6) NULL,
  review_notes VARCHAR(2000) NULL,
  component_key VARCHAR(120) NULL,
  proposed_score DECIMAL(7,2) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_correction_request_school_id (school_id,id),
  KEY idx_correction_request_review (school_id,status,created_at),
  KEY idx_correction_request_result (school_id,result_id,created_at),
  CONSTRAINT fk_correction_request_result FOREIGN KEY (school_id,result_id) REFERENCES result_records(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_correction_request_requester FOREIGN KEY (requested_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_correction_request_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_correction_reason CHECK (CHAR_LENGTH(TRIM(reason)) > 0),
  CONSTRAINT chk_correction_score_nonnegative CHECK (proposed_score IS NULL OR proposed_score >= 0),
  CONSTRAINT chk_correction_review_state CHECK (
    (status IN ('pending','withdrawn') AND reviewed_at IS NULL)
    OR (status IN ('approved','rejected','applied') AND reviewed_at IS NOT NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS result_correction_snapshots (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  result_id CHAR(36) NOT NULL,
  reopened_by CHAR(36) NOT NULL,
  reason VARCHAR(2000) NOT NULL,
  previous_snapshot JSON NOT NULL,
  reopened_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY idx_correction_snapshot_history (school_id,result_id,reopened_at),
  CONSTRAINT fk_correction_snapshot_result FOREIGN KEY (school_id,result_id) REFERENCES result_records(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_correction_snapshot_actor FOREIGN KEY (reopened_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT chk_correction_snapshot_reason CHECK (CHAR_LENGTH(TRIM(reason)) > 0),
  CONSTRAINT chk_correction_snapshot_json CHECK (JSON_TYPE(previous_snapshot)='OBJECT')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS result_templates (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  name VARCHAR(160) NOT NULL,
  education_level ENUM('nursery','primary','jss','sss') NOT NULL,
  template_kind ENUM('starter','uploaded_workbook','generated_layout') NOT NULL DEFAULT 'starter',
  storage_path VARCHAR(700) NOT NULL,
  sheet_name VARCHAR(160) NOT NULL,
  start_row INT NOT NULL DEFAULT 1,
  field_cells JSON NOT NULL,
  columns_mapping JSON NOT NULL,
  component_columns JSON NOT NULL,
  custom_fields JSON NOT NULL,
  logo_storage_path VARCHAR(700) NULL,
  logo_cell VARCHAR(32) NOT NULL DEFAULT 'A1',
  logo_width INT NOT NULL DEFAULT 100,
  logo_height INT NOT NULL DEFAULT 60,
  photo_cell VARCHAR(32) NULL,
  photo_width INT NULL,
  photo_height INT NULL,
  principal_signature_cell VARCHAR(32) NULL,
  teacher_signature_cell VARCHAR(32) NULL,
  signature_width INT NULL,
  signature_height INT NULL,
  qr_cell VARCHAR(32) NULL,
  qr_size INT NULL,
  updated_by CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_result_template_school_id (school_id,id),
  UNIQUE KEY uq_result_template_school_name (school_id,name),
  UNIQUE KEY uq_result_template_storage_path (storage_path),
  KEY idx_result_template_level (school_id,education_level,template_kind),
  CONSTRAINT fk_result_template_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE RESTRICT,
  CONSTRAINT fk_result_template_updater FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_result_template_start_row CHECK (start_row > 0),
  CONSTRAINT chk_result_template_name CHECK (CHAR_LENGTH(TRIM(name)) > 0),
  CONSTRAINT chk_result_template_owner_path CHECK (
    SUBSTRING_INDEX(storage_path,'/',1)=school_id
    AND (logo_storage_path IS NULL OR SUBSTRING_INDEX(logo_storage_path,'/',1)=school_id)
  ),
  CONSTRAINT chk_result_template_dimensions CHECK (
    logo_width > 0 AND logo_height > 0
    AND (photo_width IS NULL OR photo_width > 0)
    AND (photo_height IS NULL OR photo_height > 0)
    AND (signature_width IS NULL OR signature_width > 0)
    AND (signature_height IS NULL OR signature_height > 0)
    AND (qr_size IS NULL OR qr_size > 0)
  ),
  CONSTRAINT chk_result_template_json CHECK (
    JSON_TYPE(field_cells)='OBJECT' AND JSON_TYPE(columns_mapping)='OBJECT'
    AND JSON_TYPE(component_columns)='OBJECT' AND JSON_TYPE(custom_fields)='ARRAY'
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS transcript_settings (
  school_id CHAR(36) NOT NULL,
  officers JSON NOT NULL,
  updated_by CHAR(36) NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (school_id),
  CONSTRAINT fk_transcript_settings_school FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE RESTRICT,
  CONSTRAINT fk_transcript_settings_updater FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_transcript_officers_array CHECK (JSON_TYPE(officers)='ARRAY')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS transcript_issues (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  serial_number VARCHAR(120) NOT NULL,
  snapshot JSON NOT NULL,
  issued_by CHAR(36) NOT NULL,
  issued_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  revoked_at DATETIME(6) NULL,
  revoked_by CHAR(36) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_transcript_serial_global (serial_number),
  UNIQUE KEY uq_transcript_school_id (school_id,id),
  KEY idx_transcript_student_history (school_id,student_id,issued_at),
  CONSTRAINT fk_transcript_student FOREIGN KEY (school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
  CONSTRAINT fk_transcript_issuer FOREIGN KEY (issued_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_transcript_revoker FOREIGN KEY (revoked_by) REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT chk_transcript_snapshot_object CHECK (JSON_TYPE(snapshot)='OBJECT'),
  CONSTRAINT chk_transcript_revocation CHECK ((revoked_at IS NULL AND revoked_by IS NULL) OR (revoked_at IS NOT NULL AND revoked_by IS NOT NULL)),
  CONSTRAINT chk_transcript_serial_nonempty CHECK (CHAR_LENGTH(TRIM(serial_number)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations (version,description)
VALUES ('003_schoolpro_assessment_review_templates_transcripts','Draft assessment scheme, grade, result review/correction, school-owned workbook/template and transcript schema; disposable test only') AS incoming
ON DUPLICATE KEY UPDATE description=incoming.description;
