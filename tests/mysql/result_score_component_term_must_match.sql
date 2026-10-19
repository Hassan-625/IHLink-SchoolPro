-- Expected to fail: result belongs to First Term but component belongs to Second Term.
-- Both components are from the same school/session; this specifically tests term consistency.
INSERT INTO result_scores
  (id,school_id,result_id,assessment_component_id,session_id,term_id,score,entered_by)
VALUES
  ('91000000-0000-4000-8000-000000000098',
   '10000000-0000-4000-8000-000000000001',
   '90000000-0000-4000-8000-000000000001',
   '80000000-0000-4000-8000-000000000002',
   '30000000-0000-4000-8000-000000000001',
   '31000000-0000-4000-8000-000000000001',
   8.00,'00000000-0000-4000-8000-000000000001');
