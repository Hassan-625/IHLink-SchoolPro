-- SchoolPro student portal credentials and opaque session foundation.
-- Draft-only; student passwords must be server-hashed. Never store a surname/passcode in plaintext.
-- The roster/bootstrap service must initialize password_hash from the student's surname using
-- the same server-side scrypt format, with must_change_password=TRUE; students must then change it.

CREATE TABLE IF NOT EXISTS student_credentials (
  school_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  password_hash VARCHAR(255) NOT NULL COMMENT 'Server-generated scrypt hash; initial surname is hashed before storage',
  must_change_password BOOLEAN NOT NULL DEFAULT TRUE,
  status ENUM('active','locked','disabled') NOT NULL DEFAULT 'active',
  password_changed_at DATETIME(6) NULL,
  created_by CHAR(36) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (school_id, student_id),
  KEY idx_student_credentials_status (school_id, status, must_change_password),
  CONSTRAINT fk_student_credentials_student FOREIGN KEY (school_id, student_id)
    REFERENCES students(school_id, id) ON DELETE RESTRICT,
  CONSTRAINT fk_student_credentials_creator FOREIGN KEY (created_by)
    REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT chk_student_password_change_state CHECK (must_change_password = TRUE OR password_changed_at IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_sessions (
  id CHAR(36) NOT NULL,
  school_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  token_hash CHAR(64) NOT NULL COMMENT 'Hash of opaque student session token; never store raw bearer token',
  expires_at DATETIME(6) NOT NULL,
  revoked_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  last_seen_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_student_sessions_token_hash (token_hash),
  KEY idx_student_sessions_student_expiry (school_id, student_id, revoked_at, expires_at),
  CONSTRAINT fk_student_sessions_credentials FOREIGN KEY (school_id, student_id)
    REFERENCES student_credentials(school_id, student_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations(version, description)
VALUES ('008_schoolpro_student_credentials_sessions','Student credential and opaque session tables; surname bootstrap must be hashed by trusted server code')
AS incoming ON DUPLICATE KEY UPDATE description=incoming.description;
