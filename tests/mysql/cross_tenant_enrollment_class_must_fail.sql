-- Expected to fail specifically on fk_enrollment_class.
-- School A student/session are paired with School B's class.
INSERT INTO student_enrollments (id,school_id,student_id,session_id,class_id,status)
VALUES (
  '60000000-0000-4000-8000-000000000097',
  '10000000-0000-4000-8000-000000000001',
  '50000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001',
  '40000000-0000-4000-8000-000000000002',
  'active'
);
