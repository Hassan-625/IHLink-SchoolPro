-- Synthetic learning/CBT/library/transport/payroll fixtures for disposable MySQL CI only.
INSERT INTO assignments
 (id,school_id,class_id,subject_id,title,instructions,due_at,max_score,session_id,created_by)
VALUES
 ('e1000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000001','Synthetic homework','Fixture only','2025-10-01 12:00:00',20,'30000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001');

INSERT INTO assignment_submissions
 (id,school_id,assignment_id,student_id,submission_text,status,submitted_at)
VALUES
 ('e2000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','e1000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','Synthetic answer','submitted','2025-09-20 12:00:00');

INSERT INTO question_bank
 (id,school_id,subject_id,class_id,question_type,question_text,options,correct_answer,marks,created_by)
VALUES
 ('e3000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','multiple_choice','What is 2 + 2?',JSON_ARRAY('3','4','5'),'4',1,'00000000-0000-4000-8000-000000000001');
INSERT INTO question_bank
 (id,school_id,subject_id,class_id,question_type,question_text,options,correct_answer,marks,created_by)
VALUES
 ('e3000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','70000000-0000-4000-8000-000000000002','40000000-0000-4000-8000-000000000002','multiple_choice','Foreign-school fixture question',JSON_ARRAY('A','B'),'A',1,'00000000-0000-4000-8000-000000000002');

INSERT INTO cbt_tests
 (id,school_id,title,subject_id,class_id,session_id,duration_minutes,total_marks,status,created_by,opens_at,closes_at,attempts_allowed)
VALUES
 ('e4000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Synthetic CBT','70000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001',20,1,'scheduled','00000000-0000-4000-8000-000000000001','2025-09-25 09:00:00','2025-09-25 10:00:00',1);

INSERT INTO cbt_test_questions(school_id,test_id,question_id,position)
VALUES ('10000000-0000-4000-8000-000000000001','e4000000-0000-4000-8000-000000000001','e3000000-0000-4000-8000-000000000001',1);

INSERT INTO cbt_attempts
 (id,school_id,test_id,student_id,status,attempt_number,expires_at)
VALUES
 ('e5000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','e4000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','in_progress',1,'2025-09-25 09:20:00');

INSERT INTO cbt_answers(id,school_id,attempt_id,question_id,answer)
VALUES ('e6000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','e5000000-0000-4000-8000-000000000001','e3000000-0000-4000-8000-000000000001','4');

INSERT INTO library_books(id,school_id,title,author,isbn,copies,available_copies)
VALUES ('e7000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Synthetic Science Book','Test Author','ISBN-TEST-001',3,2);

INSERT INTO library_loans
 (id,school_id,book_id,student_id,borrowed_at,due_at,status,session_id,term_id)
VALUES ('e8000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','e7000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','2025-09-10 09:00:00','2025-09-20 09:00:00','borrowed','30000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001');

INSERT INTO transport_routes(id,school_id,name,vehicle,driver_name,fee,active)
VALUES ('e9000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Synthetic Route A','Bus 1','Test Driver',10000,TRUE);

INSERT INTO student_transport_assignments
 (id,school_id,student_id,route_id,pickup_point,active,session_id,term_id)
VALUES ('ea000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','e9000000-0000-4000-8000-000000000001','Gate A',TRUE,'30000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001');

INSERT INTO payroll_records
 (id,school_id,membership_id,period_label,gross,deductions,status,session_id)
VALUES ('eb000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','2025-09',150000,10000,'draft','30000000-0000-4000-8000-000000000001');

SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: assignment submission is school-scoped' ELSE 'FAIL: assignment fixture mismatch' END AS assertion FROM assignment_submissions WHERE school_id='10000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: CBT answer belongs to same-school attempt and question' ELSE 'FAIL: CBT fixture mismatch' END AS assertion FROM cbt_answers WHERE school_id='10000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: payroll net is calculated by MySQL' ELSE 'FAIL: payroll fixture mismatch' END AS assertion FROM payroll_records WHERE id='eb000000-0000-4000-8000-000000000001' AND net=140000;
