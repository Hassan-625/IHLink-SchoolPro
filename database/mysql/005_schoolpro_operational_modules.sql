-- SchoolPro operational modules: attendance, timetable, calendar, announcements,
-- discipline/health, lesson notes, leave, inventory and hostel allocation.
-- Draft only; apply to disposable MySQL 8.4 CI until source/API parity is accepted.

-- Attendance is already defined by migration 001 as enrollment-scoped attendance_records.
CREATE TABLE IF NOT EXISTS timetable_entries (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, class_id CHAR(36) NOT NULL,
 subject_id CHAR(36) NOT NULL, session_id CHAR(36) NOT NULL, weekday TINYINT UNSIGNED NOT NULL,
 starts_at TIME NOT NULL, ends_at TIME NOT NULL, room VARCHAR(120) NULL,
 created_by CHAR(36) NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_timetable_school_id(school_id,id),
 KEY idx_timetable_class_session_day(school_id,class_id,session_id,weekday,starts_at),
 KEY idx_timetable_subject_session(school_id,subject_id,session_id,weekday,starts_at),
 CONSTRAINT fk_timetable_class FOREIGN KEY(school_id,class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_timetable_subject FOREIGN KEY(school_id,subject_id) REFERENCES school_subjects(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_timetable_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_timetable_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_timetable_weekday CHECK(weekday BETWEEN 1 AND 7),
 CONSTRAINT chk_timetable_time CHECK(starts_at < ends_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS calendar_events (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, title VARCHAR(200) NOT NULL,
 event_date DATE NOT NULL, end_date DATE NULL, event_type VARCHAR(80) NOT NULL,
 details TEXT NULL, class_id CHAR(36) NULL, session_id CHAR(36) NULL,
 created_by CHAR(36) NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_calendar_school_id(school_id,id),
 KEY idx_calendar_dates(school_id,event_date,end_date,session_id),
 CONSTRAINT fk_calendar_school FOREIGN KEY(school_id) REFERENCES schools(id) ON DELETE RESTRICT,
 CONSTRAINT fk_calendar_class FOREIGN KEY(school_id,class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_calendar_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_calendar_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_calendar_dates CHECK(end_date IS NULL OR end_date >= event_date),
 CONSTRAINT chk_calendar_title CHECK(CHAR_LENGTH(TRIM(title))>0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS announcements (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, title VARCHAR(200) NOT NULL,
 body TEXT NOT NULL, audience ENUM('all','staff','students','guardians','class') NOT NULL DEFAULT 'all',
 class_id CHAR(36) NULL, session_id CHAR(36) NULL, published BOOLEAN NOT NULL DEFAULT FALSE,
 created_by CHAR(36) NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 published_at DATETIME(6) NULL,
 PRIMARY KEY(id), UNIQUE KEY uq_announcement_school_id(school_id,id),
 KEY idx_announcement_publish(school_id,published,published_at),
 CONSTRAINT fk_announcement_school FOREIGN KEY(school_id) REFERENCES schools(id) ON DELETE RESTRICT,
 CONSTRAINT fk_announcement_class FOREIGN KEY(school_id,class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_announcement_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_announcement_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_announcement_publish_state CHECK((published=FALSE) OR published_at IS NOT NULL),
 CONSTRAINT chk_announcement_title CHECK(CHAR_LENGTH(TRIM(title))>0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS discipline_records (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, student_id CHAR(36) NOT NULL,
 incident TEXT NOT NULL, action_taken TEXT NULL,
 status ENUM('open','under_review','resolved','dismissed') NOT NULL DEFAULT 'open',
 session_id CHAR(36) NULL, term_id CHAR(36) NULL, created_by CHAR(36) NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_discipline_school_id(school_id,id),
 KEY idx_discipline_student(school_id,student_id,created_at,status),
 CONSTRAINT fk_discipline_student FOREIGN KEY(school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_discipline_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_discipline_term FOREIGN KEY(school_id,term_id) REFERENCES academic_terms(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_discipline_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_discipline_incident CHECK(CHAR_LENGTH(TRIM(incident))>0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_health_records (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, student_id CHAR(36) NOT NULL,
 recorded_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), complaint TEXT NULL,
 assessment TEXT NULL, treatment TEXT NULL, disposition TEXT NULL, follow_up_date DATE NULL,
 follow_up_notes TEXT NULL, status ENUM('open','follow_up','closed') NOT NULL DEFAULT 'open',
 session_id CHAR(36) NULL, term_id CHAR(36) NULL, recorded_by CHAR(36) NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_health_school_id(school_id,id),
 KEY idx_health_student_date(school_id,student_id,recorded_at),
 CONSTRAINT fk_health_student FOREIGN KEY(school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_health_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_health_term FOREIGN KEY(school_id,term_id) REFERENCES academic_terms(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_health_recorder FOREIGN KEY(recorded_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS lesson_notes (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, subject_id CHAR(36) NOT NULL,
 class_id CHAR(36) NOT NULL, title VARCHAR(200) NOT NULL, content LONGTEXT NULL,
 status ENUM('draft','submitted','approved','returned') NOT NULL DEFAULT 'draft',
 created_by CHAR(36) NULL, lesson_date DATE NULL, term_id CHAR(36) NULL,
 session_id CHAR(36) NULL, week_number SMALLINT UNSIGNED NULL, duration_minutes SMALLINT UNSIGNED NULL,
 plan JSON NULL, review_comment VARCHAR(2000) NULL, reviewed_by CHAR(36) NULL,
 reviewed_at DATETIME(6) NULL, updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_lesson_note_school_id(school_id,id),
 KEY idx_lesson_note_review(school_id,status,session_id,term_id,class_id),
 CONSTRAINT fk_lesson_subject FOREIGN KEY(school_id,subject_id) REFERENCES school_subjects(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_lesson_class FOREIGN KEY(school_id,class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_lesson_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_lesson_term FOREIGN KEY(school_id,term_id) REFERENCES academic_terms(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_lesson_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT fk_lesson_reviewer FOREIGN KEY(reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_lesson_title CHECK(CHAR_LENGTH(TRIM(title))>0),
 CONSTRAINT chk_lesson_week CHECK(week_number IS NULL OR week_number>0),
 CONSTRAINT chk_lesson_duration CHECK(duration_minutes IS NULL OR duration_minutes>0),
 CONSTRAINT chk_lesson_review_state CHECK((status IN ('draft','submitted') AND reviewed_at IS NULL) OR (status IN ('approved','returned') AND reviewed_at IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS leave_requests (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, membership_id CHAR(36) NOT NULL,
 leave_type VARCHAR(80) NOT NULL, start_date DATE NOT NULL, end_date DATE NOT NULL,
 reason TEXT NULL, status ENUM('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
 reviewed_by CHAR(36) NULL, reviewed_at DATETIME(6) NULL, session_id CHAR(36) NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_leave_school_id(school_id,id),
 KEY idx_leave_review_queue(school_id,status,start_date),
 CONSTRAINT fk_leave_member FOREIGN KEY(school_id,membership_id) REFERENCES school_memberships(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_leave_reviewer FOREIGN KEY(reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT fk_leave_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT chk_leave_dates CHECK(end_date>=start_date),
 CONSTRAINT chk_leave_review_state CHECK((status IN ('pending','cancelled') AND reviewed_at IS NULL) OR (status IN ('approved','rejected') AND reviewed_at IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inventory_assets (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, name VARCHAR(200) NOT NULL,
 category VARCHAR(120) NULL, quantity INT UNSIGNED NOT NULL DEFAULT 0,
 asset_condition ENUM('new','good','fair','poor','damaged','retired') NOT NULL DEFAULT 'good',
 location VARCHAR(200) NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_inventory_school_id(school_id,id),
 KEY idx_inventory_category(school_id,category,asset_condition),
 CONSTRAINT fk_inventory_school FOREIGN KEY(school_id) REFERENCES schools(id) ON DELETE RESTRICT,
 CONSTRAINT chk_inventory_name CHECK(CHAR_LENGTH(TRIM(name))>0),
 CONSTRAINT chk_inventory_quantity CHECK(quantity>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS hostel_rooms (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, hostel_name VARCHAR(160) NOT NULL,
 room_name VARCHAR(100) NOT NULL, capacity SMALLINT UNSIGNED NOT NULL,
 fee DECIMAL(12,2) NOT NULL DEFAULT 0, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_hostel_room_school_id(school_id,id),
 UNIQUE KEY uq_hostel_room_name(school_id,hostel_name,room_name),
 CONSTRAINT fk_hostel_room_school FOREIGN KEY(school_id) REFERENCES schools(id) ON DELETE RESTRICT,
 CONSTRAINT chk_hostel_room_capacity CHECK(capacity>0),
 CONSTRAINT chk_hostel_room_fee CHECK(fee>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS hostel_allocations (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, student_id CHAR(36) NOT NULL,
 room_id CHAR(36) NOT NULL, session_id CHAR(36) NOT NULL, active BOOLEAN NOT NULL DEFAULT TRUE,
 allocated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_hostel_allocation_school_id(school_id,id),
 KEY idx_hostel_allocation_room(school_id,room_id,session_id,active),
 KEY idx_hostel_allocation_student(school_id,student_id,session_id,active),
 CONSTRAINT fk_hostel_allocation_student FOREIGN KEY(school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_hostel_allocation_room FOREIGN KEY(school_id,room_id) REFERENCES hostel_rooms(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_hostel_allocation_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations(version,description)
VALUES ('005_schoolpro_operational_modules','Draft school-scoped timetable, calendar, announcements, discipline/health, lesson notes, leave, inventory and hostel tables; attendance remains in migration 001; disposable test only') AS incoming
ON DUPLICATE KEY UPDATE description=incoming.description;
