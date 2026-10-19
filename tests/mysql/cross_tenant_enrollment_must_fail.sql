-- Expected to FAIL with a foreign-key violation. CI treats failure as success.
-- This attempts to attach School B's student to School A's enrollment.
INSERT INTO student_enrollments (id,school_id,student_id,session_id,class_id,status)
VALUES (
  '60000000-0000-4000-8000-000000000099',
  '10000000-0000-4000-8000-000000000001',
  '50000000-0000-4000-8000-000000000002',
  '30000000-0000-4000-8000-000000000001',
  '40000000-0000-4000-8000-000000000001',
  'active'
);
