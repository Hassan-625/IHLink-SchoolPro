-- Synthetic finance/guardian/subscription fixtures for disposable MySQL CI only.
INSERT INTO guardian_student_links
  (id,school_id,student_id,guardian_user_id,relationship_code,status,linked_by)
VALUES
  ('a1000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','parent','active','00000000-0000-4000-8000-000000000001');

INSERT INTO school_bank_accounts
  (id,school_id,bank_name,account_name,account_number,is_primary,active,created_by)
VALUES
  ('a2000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Test Bank','School A Fees','0001112223',TRUE,TRUE,'00000000-0000-4000-8000-000000000001'),
  ('a2000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','Test Bank','School B Fees','0001112224',TRUE,TRUE,'00000000-0000-4000-8000-000000000002');

INSERT INTO fee_structures
  (id,school_id,name,class_id,session_id,term_id,amount,is_active,created_by)
VALUES
  ('a3000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','First Term Fees','40000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001',1000,TRUE,'00000000-0000-4000-8000-000000000001'),
  ('a3000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','First Term Fees','40000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000002','31000000-0000-4000-8000-000000000003',1000,TRUE,'00000000-0000-4000-8000-000000000002');

INSERT INTO fee_invoices
  (id,school_id,student_id,enrollment_id,fee_structure_id,title,session_id,term_id,gross_amount,amount_due,amount_paid,status,created_by)
VALUES
  ('a4000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','60000000-0000-4000-8000-000000000001','a3000000-0000-4000-8000-000000000001','First Term Invoice','30000000-0000-4000-8000-000000000001','31000000-0000-4000-8000-000000000001',1000,1000,600,'part_paid','00000000-0000-4000-8000-000000000001'),
  ('a4000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','50000000-0000-4000-8000-000000000002','60000000-0000-4000-8000-000000000002','a3000000-0000-4000-8000-000000000002','First Term Invoice','30000000-0000-4000-8000-000000000002','31000000-0000-4000-8000-000000000003',1000,1000,0,'unpaid','00000000-0000-4000-8000-000000000002');

INSERT INTO school_fee_payment_submissions
  (id,school_id,submitted_by,bank_account_id,total_amount,payment_date,payer_name,bank_reference,receipt_object_key,receipt_owner_user_id,receipt_mime,status)
VALUES
  ('a5000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','a2000000-0000-4000-8000-000000000001',600,'2025-09-10','Parent A','BANK-A-001','00000000-0000-4000-8000-000000000001/receipt-a.pdf','00000000-0000-4000-8000-000000000001','application/pdf','confirmed');

INSERT INTO fee_payments
  (id,school_id,invoice_id,student_id,submission_id,amount,method_code,reference,paid_at,recorded_by)
VALUES
  ('a6000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','a4000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','a5000000-0000-4000-8000-000000000001',600,'bank_transfer','PAY-A-001','2025-09-10 10:00:00','00000000-0000-4000-8000-000000000001');

INSERT INTO school_fee_payment_allocations
  (id,school_id,submission_id,student_id,invoice_id,amount,payment_id)
VALUES
  ('a7000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','a5000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','a4000000-0000-4000-8000-000000000001',600,'a6000000-0000-4000-8000-000000000001');

INSERT INTO school_fee_payment_proofs
  (id,school_id,invoice_id,student_id,submitted_by,bank_account_id,amount,payment_date,payer_name,bank_reference,receipt_object_key,receipt_owner_user_id,receipt_mime,status,payment_id)
VALUES
  ('a8000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','a4000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001','a2000000-0000-4000-8000-000000000001',600,'2025-09-10','Parent A','BANK-A-PROOF-001','00000000-0000-4000-8000-000000000001/proof-a.pdf','00000000-0000-4000-8000-000000000001','application/pdf','confirmed','a6000000-0000-4000-8000-000000000001');

INSERT INTO school_subscription_plans
  (code,name,billing_period,annual_price,is_demo,active,features)
VALUES
  ('demo','Demo Access','annual',NULL,TRUE,TRUE,JSON_OBJECT('demo',TRUE)),
  ('standard','Standard Annual','annual',150000,FALSE,TRUE,JSON_OBJECT('results',TRUE,'finance',TRUE));

INSERT INTO school_subscriptions
  (id,school_id,plan_code,billing_cycle,paid_amount,status,starts_at,renews_at,managed_by_ihlink,updated_by)
VALUES
  ('a9000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','demo','annual',NULL,'demo_active','2025-09-01 00:00:00','2026-09-01 00:00:00',TRUE,'00000000-0000-4000-8000-000000000001'),
  ('a9000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','standard','annual',150000,'active','2025-09-01 00:00:00','2026-09-01 00:00:00',TRUE,'00000000-0000-4000-8000-000000000002');

INSERT INTO school_subscription_receipts
  (id,school_id,subscription_id,submitted_by,receipt_object_key,receipt_owner_user_id,receipt_mime,amount,payment_date,bank_reference,status)
VALUES
  ('aa000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002','a9000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000002/subscription-annual.pdf','00000000-0000-4000-8000-000000000002','application/pdf',150000,'2025-09-01','SUB-B-001','pending');

SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: guardian link is school-scoped' ELSE 'FAIL: guardian fixture mismatch' END AS assertion
FROM guardian_student_links WHERE school_id='10000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: fee payment and allocation reconcile' ELSE 'FAIL: fee payment fixture mismatch' END AS assertion
FROM school_fee_payment_allocations WHERE school_id='10000000-0000-4000-8000-000000000001' AND payment_id='a6000000-0000-4000-8000-000000000001';
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: Demo subscription stores no paid amount' ELSE 'FAIL: Demo subscription amount mismatch' END AS assertion
FROM school_subscriptions WHERE school_id='10000000-0000-4000-8000-000000000001' AND plan_code='demo' AND paid_amount IS NULL;
SELECT CASE WHEN COUNT(*)=1 THEN 'PASS: annual subscription receipt awaits IHLink review' ELSE 'FAIL: subscription receipt fixture mismatch' END AS assertion
FROM school_subscription_receipts WHERE school_id='10000000-0000-4000-8000-000000000002' AND status='pending';
