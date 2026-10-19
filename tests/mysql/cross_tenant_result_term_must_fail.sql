-- Expected to fail on the result-record term/session consistency constraint.
-- School A result attempts to pair its enrollment/session with School B's term.
INSERT INTO result_records
  (id,school_id,enrollment_id,subject_id,session_id,term_id,total_score,status,created_by)
VALUES
  ('90000000-0000-4000-8000-000000000098',
   '10000000-0000-4000-8000-000000000001',
   '60000000-0000-4000-8000-000000000001',
   '70000000-0000-4000-8000-000000000001',
   '30000000-0000-4000-8000-000000000001',
   '31000000-0000-4000-8000-000000000003',
   12.00,'draft','00000000-0000-4000-8000-000000000001');
