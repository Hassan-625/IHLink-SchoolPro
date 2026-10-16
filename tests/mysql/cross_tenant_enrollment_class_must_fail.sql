-- Expected to fail specifically on fk_enrollment_class.
-- Use a distinct School A student/session pair so the enrollment uniqueness
-- constraint cannot mask the intended cross-school class foreign-key failure.
INSERT INTO students (id,school_id,admission_number,first_name,last_name,status)
VALUES (
  '50000000-0000-4000-8000-000000000098',
  '10000000-0000-4000-8000-000000000001',
  'A-NEG-CLASS-001',
  'Synthetic',
  'ClassBoundary',
  'active'
);

INSERT INTO student_enrollments (id,school_id,student_id,session_id,class_id,status)
VALUES (
  '60000000-0000-4000-8000-000000000097',
  '10000000-0000-4000-8000-000000000001',
  '50000000-0000-4000-8000-000000000098',
  '30000000-0000-4000-8000-000000000001',
  '40000000-0000-4000-8000-000000000002',
  'active'
);
