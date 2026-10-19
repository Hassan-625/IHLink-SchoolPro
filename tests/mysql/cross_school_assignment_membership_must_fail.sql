-- Cross-school staff membership reference must be rejected; expected MySQL foreign-key rejection by fk_csa_membership.
-- Use a new valid School A subject so the unique assignment key does not mask the membership FK.
INSERT INTO school_subjects (id,school_id,subject_name,education_level)
VALUES ('70000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000001','Science Membership Test','primary');

INSERT INTO class_subject_assignments (id,school_id,class_id,subject_id,membership_id,session_id,is_active)
VALUES ('72000000-0000-4000-8000-000000000094','10000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000001',TRUE);
