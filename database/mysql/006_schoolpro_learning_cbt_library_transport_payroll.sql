-- SchoolPro learning support, CBT, library, transport and payroll schema.
-- Draft only; disposable MySQL CI. Authorization and transaction workflows remain application responsibilities.

CREATE TABLE IF NOT EXISTS assignments (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, class_id CHAR(36) NOT NULL,
 subject_id CHAR(36) NOT NULL, title VARCHAR(200) NOT NULL, instructions TEXT NULL,
 due_at DATETIME(6) NULL, max_score DECIMAL(7,2) NOT NULL DEFAULT 100,
 session_id CHAR(36) NOT NULL, created_by CHAR(36) NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_assignment_school_id(school_id,id),
 KEY idx_assignment_class_due(school_id,class_id,session_id,due_at),
 CONSTRAINT fk_assignment_class FOREIGN KEY(school_id,class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_assignment_subject FOREIGN KEY(school_id,subject_id) REFERENCES school_subjects(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_assignment_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_assignment_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_assignment_title CHECK(CHAR_LENGTH(TRIM(title))>0),
 CONSTRAINT chk_assignment_max_score CHECK(max_score>0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS assignment_submissions (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, assignment_id CHAR(36) NOT NULL,
 student_id CHAR(36) NOT NULL, submission_text LONGTEXT NULL, file_storage_path VARCHAR(700) NULL,
 submitted_at DATETIME(6) NULL, score DECIMAL(7,2) NULL, feedback TEXT NULL,
 status ENUM('draft','submitted','graded','returned','late') NOT NULL DEFAULT 'draft',
 graded_by CHAR(36) NULL, graded_at DATETIME(6) NULL,
 PRIMARY KEY(id), UNIQUE KEY uq_assignment_submission_school_id(school_id,id),
 UNIQUE KEY uq_assignment_submission_student(school_id,assignment_id,student_id),
 KEY idx_assignment_submission_review(school_id,assignment_id,status,submitted_at),
 CONSTRAINT fk_submission_assignment FOREIGN KEY(school_id,assignment_id) REFERENCES assignments(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_submission_student FOREIGN KEY(school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_submission_grader FOREIGN KEY(graded_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_submission_score CHECK(score IS NULL OR score>=0),
 CONSTRAINT chk_submission_grade_state CHECK((status IN ('graded','returned') AND graded_at IS NOT NULL) OR status NOT IN ('graded','returned')),
 CONSTRAINT chk_submission_file_path CHECK(file_storage_path IS NULL OR SUBSTRING_INDEX(file_storage_path,'/',1)=school_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS question_bank (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, subject_id CHAR(36) NOT NULL,
 class_id CHAR(36) NOT NULL, question_type ENUM('multiple_choice','true_false','short_answer','essay') NOT NULL,
 question_text TEXT NOT NULL, options JSON NULL, correct_answer TEXT NULL, marks DECIMAL(7,2) NOT NULL,
 explanation TEXT NULL, created_by CHAR(36) NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_question_school_id(school_id,id),
 KEY idx_question_bank_class_subject(school_id,class_id,subject_id,question_type),
 CONSTRAINT fk_question_subject FOREIGN KEY(school_id,subject_id) REFERENCES school_subjects(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_question_class FOREIGN KEY(school_id,class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_question_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_question_text CHECK(CHAR_LENGTH(TRIM(question_text))>0),
 CONSTRAINT chk_question_marks CHECK(marks>0),
 CONSTRAINT chk_question_options CHECK(options IS NULL OR JSON_TYPE(options) IN ('ARRAY','OBJECT'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cbt_tests (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, title VARCHAR(200) NOT NULL,
 subject_id CHAR(36) NOT NULL, class_id CHAR(36) NOT NULL, session_id CHAR(36) NOT NULL,
 duration_minutes SMALLINT UNSIGNED NOT NULL, total_marks DECIMAL(8,2) NOT NULL,
 status ENUM('draft','scheduled','open','closed','archived') NOT NULL DEFAULT 'draft',
 created_by CHAR(36) NULL, instructions TEXT NULL, opens_at DATETIME(6) NULL, closes_at DATETIME(6) NULL,
 randomize_questions BOOLEAN NOT NULL DEFAULT FALSE, randomize_options BOOLEAN NOT NULL DEFAULT FALSE,
 attempts_allowed TINYINT UNSIGNED NOT NULL DEFAULT 1, test_type VARCHAR(60) NOT NULL DEFAULT 'practice',
 PRIMARY KEY(id), UNIQUE KEY uq_cbt_test_school_id(school_id,id),
 KEY idx_cbt_test_schedule(school_id,status,opens_at,closes_at),
 CONSTRAINT fk_cbt_test_subject FOREIGN KEY(school_id,subject_id) REFERENCES school_subjects(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_cbt_test_class FOREIGN KEY(school_id,class_id) REFERENCES school_classes(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_cbt_test_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_cbt_test_creator FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_cbt_duration CHECK(duration_minutes>0),
 CONSTRAINT chk_cbt_total_marks CHECK(total_marks>0),
 CONSTRAINT chk_cbt_attempts CHECK(attempts_allowed>0),
 CONSTRAINT chk_cbt_window CHECK(opens_at IS NULL OR closes_at IS NULL OR closes_at>opens_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cbt_test_questions (
 school_id CHAR(36) NOT NULL, test_id CHAR(36) NOT NULL, question_id CHAR(36) NOT NULL,
 position SMALLINT UNSIGNED NOT NULL,
 PRIMARY KEY(school_id,test_id,question_id), UNIQUE KEY uq_cbt_question_position(school_id,test_id,position),
 CONSTRAINT fk_cbt_tq_test FOREIGN KEY(school_id,test_id) REFERENCES cbt_tests(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_cbt_tq_question FOREIGN KEY(school_id,question_id) REFERENCES question_bank(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT chk_cbt_question_position CHECK(position>0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cbt_attempts (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, test_id CHAR(36) NOT NULL,
 student_id CHAR(36) NOT NULL, started_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 submitted_at DATETIME(6) NULL, score DECIMAL(8,2) NULL,
 status ENUM('in_progress','submitted','graded','expired','voided') NOT NULL DEFAULT 'in_progress',
 attempt_number TINYINT UNSIGNED NOT NULL DEFAULT 1, expires_at DATETIME(6) NULL,
 PRIMARY KEY(id), UNIQUE KEY uq_cbt_attempt_school_id(school_id,id),
 UNIQUE KEY uq_cbt_attempt_number(school_id,test_id,student_id,attempt_number),
 KEY idx_cbt_attempt_student(school_id,student_id,test_id,status),
 CONSTRAINT fk_cbt_attempt_test FOREIGN KEY(school_id,test_id) REFERENCES cbt_tests(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_cbt_attempt_student FOREIGN KEY(school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT chk_cbt_attempt_number CHECK(attempt_number>0),
 CONSTRAINT chk_cbt_attempt_score CHECK(score IS NULL OR score>=0),
 CONSTRAINT chk_cbt_attempt_submit CHECK((status IN ('submitted','graded','expired','voided') AND submitted_at IS NOT NULL) OR status='in_progress')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cbt_answers (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, attempt_id CHAR(36) NOT NULL,
 question_id CHAR(36) NOT NULL, answer LONGTEXT NULL, is_correct BOOLEAN NULL,
 marks_awarded DECIMAL(8,2) NULL, feedback TEXT NULL, marked_by CHAR(36) NULL, marked_at DATETIME(6) NULL,
 PRIMARY KEY(id), UNIQUE KEY uq_cbt_answer_question(school_id,attempt_id,question_id),
 CONSTRAINT fk_cbt_answer_attempt FOREIGN KEY(school_id,attempt_id) REFERENCES cbt_attempts(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_cbt_answer_question FOREIGN KEY(school_id,question_id) REFERENCES question_bank(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_cbt_answer_marker FOREIGN KEY(marked_by) REFERENCES users(id) ON DELETE SET NULL,
 CONSTRAINT chk_cbt_answer_marks CHECK(marks_awarded IS NULL OR marks_awarded>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS library_books (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, title VARCHAR(240) NOT NULL,
 author VARCHAR(200) NULL, isbn VARCHAR(40) NULL, copies INT UNSIGNED NOT NULL DEFAULT 1,
 available_copies INT UNSIGNED NOT NULL DEFAULT 1, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_library_book_school_id(school_id,id),
 UNIQUE KEY uq_library_book_isbn(school_id,isbn),
 KEY idx_library_book_title(school_id,title),
 CONSTRAINT fk_library_book_school FOREIGN KEY(school_id) REFERENCES schools(id) ON DELETE RESTRICT,
 CONSTRAINT chk_library_book_title CHECK(CHAR_LENGTH(TRIM(title))>0),
 CONSTRAINT chk_library_book_copies CHECK(available_copies<=copies)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS library_loans (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, book_id CHAR(36) NOT NULL,
 student_id CHAR(36) NULL, membership_id CHAR(36) NULL, borrowed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 due_at DATETIME(6) NOT NULL, returned_at DATETIME(6) NULL, fine DECIMAL(12,2) NOT NULL DEFAULT 0,
 status ENUM('borrowed','returned','overdue','lost') NOT NULL DEFAULT 'borrowed',
 session_id CHAR(36) NULL, term_id CHAR(36) NULL,
 PRIMARY KEY(id), UNIQUE KEY uq_library_loan_school_id(school_id,id),
 KEY idx_library_loan_due(school_id,status,due_at),
 CONSTRAINT fk_library_loan_book FOREIGN KEY(school_id,book_id) REFERENCES library_books(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_library_loan_student FOREIGN KEY(school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_library_loan_member FOREIGN KEY(school_id,membership_id) REFERENCES school_memberships(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_library_loan_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_library_loan_term FOREIGN KEY(school_id,term_id) REFERENCES academic_terms(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT chk_library_loan_borrower CHECK((student_id IS NOT NULL) <> (membership_id IS NOT NULL)),
 CONSTRAINT chk_library_loan_dates CHECK(due_at>=borrowed_at),
 CONSTRAINT chk_library_loan_fine CHECK(fine>=0),
 CONSTRAINT chk_library_loan_return CHECK((status='returned' AND returned_at IS NOT NULL) OR status<>'returned')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS transport_routes (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, name VARCHAR(160) NOT NULL,
 vehicle VARCHAR(160) NULL, driver_name VARCHAR(160) NULL, driver_phone VARCHAR(60) NULL,
 fee DECIMAL(12,2) NOT NULL DEFAULT 0, active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(id), UNIQUE KEY uq_transport_route_school_id(school_id,id),
 UNIQUE KEY uq_transport_route_name(school_id,name),
 CONSTRAINT fk_transport_route_school FOREIGN KEY(school_id) REFERENCES schools(id) ON DELETE RESTRICT,
 CONSTRAINT chk_transport_route_name CHECK(CHAR_LENGTH(TRIM(name))>0),
 CONSTRAINT chk_transport_route_fee CHECK(fee>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_transport_assignments (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, student_id CHAR(36) NOT NULL,
 route_id CHAR(36) NOT NULL, pickup_point VARCHAR(200) NULL, active BOOLEAN NOT NULL DEFAULT TRUE,
 session_id CHAR(36) NOT NULL, term_id CHAR(36) NULL,
 PRIMARY KEY(id), UNIQUE KEY uq_transport_assignment_school_id(school_id,id),
 KEY idx_transport_student(school_id,student_id,session_id,active),
 CONSTRAINT fk_transport_assignment_student FOREIGN KEY(school_id,student_id) REFERENCES students(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_transport_assignment_route FOREIGN KEY(school_id,route_id) REFERENCES transport_routes(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_transport_assignment_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_transport_assignment_term FOREIGN KEY(school_id,term_id) REFERENCES academic_terms(school_id,id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payroll_records (
 id CHAR(36) NOT NULL, school_id CHAR(36) NOT NULL, membership_id CHAR(36) NOT NULL,
 period_label VARCHAR(40) NOT NULL, gross DECIMAL(14,2) NOT NULL, deductions DECIMAL(14,2) NOT NULL DEFAULT 0,
 net DECIMAL(14,2) GENERATED ALWAYS AS (gross-deductions) STORED,
 status ENUM('draft','approved','paid','voided') NOT NULL DEFAULT 'draft',
 approved_by CHAR(36) NULL, approved_at DATETIME(6) NULL, paid_at DATETIME(6) NULL,
 payment_reference VARCHAR(160) NULL, session_id CHAR(36) NULL,
 PRIMARY KEY(id), UNIQUE KEY uq_payroll_school_id(school_id,id),
 UNIQUE KEY uq_payroll_member_period(school_id,membership_id,period_label),
 KEY idx_payroll_status(school_id,status,period_label),
 CONSTRAINT fk_payroll_member FOREIGN KEY(school_id,membership_id) REFERENCES school_memberships(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT fk_payroll_approver FOREIGN KEY(approved_by) REFERENCES users(id) ON DELETE RESTRICT,
 CONSTRAINT fk_payroll_session FOREIGN KEY(school_id,session_id) REFERENCES academic_sessions(school_id,id) ON DELETE RESTRICT,
 CONSTRAINT chk_payroll_gross CHECK(gross>=0),
 CONSTRAINT chk_payroll_deductions CHECK(deductions>=0 AND deductions<=gross),
 CONSTRAINT chk_payroll_approval CHECK((status IN ('approved','paid') AND approved_at IS NOT NULL AND approved_by IS NOT NULL) OR status IN ('draft','voided')),
 CONSTRAINT chk_payroll_paid CHECK((status='paid' AND paid_at IS NOT NULL) OR status<>'paid')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_migrations(version,description)
VALUES ('006_schoolpro_learning_cbt_library_transport_payroll','Draft assignment/submission, question bank/CBT, library, transport and payroll tables; disposable test only') AS incoming
ON DUPLICATE KEY UPDATE description=incoming.description;
