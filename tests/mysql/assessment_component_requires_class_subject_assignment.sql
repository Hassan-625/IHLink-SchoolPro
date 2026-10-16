-- A component must not be created for a class/subject/session tuple that is not assigned.
-- Expected rejection by fk_ac_class_subject_session.
INSERT INTO school_subjects (id,school_id,subject_name,education_level)
VALUES ('70000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000001','Unassigned Assessment Test','primary');

INSERT INTO assessment_components
  (id,school_id,session_id,term_id,class_id,subject_id,component_code,component_name,max_score)
VALUES
  ('80000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000001',
   '30000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001',
   '40000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000004',
   'UNASSIGNED-TEST','Unassigned subject assessment',20);
