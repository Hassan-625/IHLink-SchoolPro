-- Cross-school session reference must be rejected; expected MySQL foreign-key rejection by fk_csa_session.
INSERT INTO class_subject_assignments (id,school_id,class_id,subject_id,membership_id,session_id,is_active)
VALUES ('72000000-0000-4000-8000-000000000093','10000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000002',TRUE);
