-- SchoolPro MySQL authentication attempt throttling foundation.
-- Stores only a one-way key hash for a normalized login identifier; do not key trust
-- from X-Forwarded-For or other caller-controlled network headers.
-- This is schema-only. Server enforcement and API contract tests are separate.

CREATE TABLE IF NOT EXISTS auth_login_attempts (
  identifier_hash CHAR(64) NOT NULL COMMENT 'SHA-256 of normalized login identifier; never store raw identifier here',
  attempts SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  window_started_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  blocked_until DATETIME(6) NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (identifier_hash),
  KEY idx_auth_login_attempts_blocked (blocked_until),
  CONSTRAINT chk_auth_login_attempts_nonnegative CHECK (attempts >= 0),
  CONSTRAINT chk_auth_login_identifier_hash CHECK (identifier_hash REGEXP '^[0-9a-f]{64}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations(version,description)
VALUES ('007_schoolpro_auth_login_throttling','Persistent per-identifier authentication throttling state for MySQL API foundation') AS incoming
ON DUPLICATE KEY UPDATE description=incoming.description;
