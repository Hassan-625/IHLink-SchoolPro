-- Synthetic admissions/progression fixtures for disposable MySQL CI only.
INSERT INTO admissions
 (id,school_id,application_number,public_token,applicant_name,first_name,last_name,guardian_name,guardian_contact,class_applied,status,acceptance_fee_status,enrollment_status,submitted_at)
VALUES
 ('c1000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','APP-A-001','c1100000-0000-4000-8000-000000000001','Applicant A','Applicant','One','Guardian A','08000000001','Basic 5','offered','pending','not_enrolled','2025-08-20 10:00:00'),
 ('c1000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','APP-B-001','c1100000-0000-4000-8000-000000000002','Applicant B','Applicant','Two','Guardian B','08000000002','Basic 5','submitted','pending','not_enrolled','2025-08-21 10:00:00');

INSERT INTO admission_documents
 (id,school_id,application_id,document_type,storage_path,file_name,mime_type,file_size,verified)
VALUES
 ('c2000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','c1000000-0000-4000-8000-000000000001','birth_certificate','10000000-0000-4000-8000-000000000001/admissions/APP-A-001/birth.pdf','birth.pdf','application/pdf',2048,FALSE);

INSERT INTO admission_offers
 (id,school_id,application_id,offer_number,offered_class,issued_at,expires_at,status,public_token,acceptance_instructions,created_by)
VALUES
 ('c3000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','c1000000-0000-4000-8000-000000000001','OFFER-A-001','Basic 5','2025-08-22 10:00:00','2025-09-10 10:00:00','issued','c3100000-0000-4000-8000-000000000001','Accept before expiry','00000000-0000-4000-8000-000000000001');

INSERT INTO admission_events
 (id,school_id,application_id,event_type,scheduled_at,location,status,created_by)
VALUES
 ('c4000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','c1000000-0000-4000-8000-000000000001','entrance_test','2025-08-25 09:00:00','School A','scheduled','00000000-0000-4000-8000-000000000001');

INSERT INTO admission_acceptances
 (id,school_id,application_id,offer_id,accepted_by_name,accepted_by_email,accepted_at,terms_accepted)
VALUES
 ('c5000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','c1000000-0000-4000-8000-000000000001','c3000000-0000-4000-8000-000000000001','Guardian A','guardian-a@example.test','2025-08-23 10:00:00',TRUE);

INSERT INTO student_enrollment_history
 (id,school_id,student_id,session_id,class_id,class_name_snapshot,arm_snapshot,section_snapshot,status)
VALUES
 ('c6000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','Basic 5','A','Primary','active');

INSERT INTO student_promotions
 (id,school_id,student_id,from_class_id,to_class_id,session_id,status,decision,reason)
VALUES
 ('c7000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001',NULL,'30000000-0000-4000-8000-000000000001','previewed','hold','Awaiting promotion review');

SELECT CASE WHEN COUNT(*)=2 THEN 'PASS: admissions are tenant-scoped' ELSE 'FAIL: admission fixture mismatch' END AS assertion FROM admissions;
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: admission offer and acceptance reference the same application' ELSE 'FAIL: offer/acceptance fixture mismatch' END AS assertion FROM admission_acceptances WHERE school_id='10000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 AND MAX(status)='previewed' AND MAX(decision)='hold' THEN 'PASS: promotion starts as non-mutating preview' ELSE 'FAIL: promotion preview fixture mismatch' END AS assertion FROM student_promotions WHERE id='c7000000-0000-4000-8000-000000000001';
