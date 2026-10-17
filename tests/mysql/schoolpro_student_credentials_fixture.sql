-- Synthetic student credentials/session rows for disposable MySQL CI only.
INSERT INTO student_credentials
 (school_id,student_id,password_hash,must_change_password,status,created_by)
VALUES
 ('10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001',
  'scrypt$16384$8$1$00112233445566778899aabbccddeeff$b29491a3832d27b3e94fb4608985c5e3be4a430c893c9e161117c4c31d6d418ccca571f7ea273ab8d92964e7e8f0d4c04694de498162f68414cd0ffa83c7bd29',
  TRUE,'active','00000000-0000-4000-8000-000000000001');

INSERT INTO student_sessions
 (id,school_id,student_id,token_hash,expires_at)
VALUES
 ('f1000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001',
  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa','2026-10-18 00:00:00');

SELECT CASE WHEN COUNT(*)=1 AND MAX(must_change_password)=1 THEN 'PASS: student account requires initial password change' ELSE 'FAIL: student credential fixture mismatch' END AS assertion
FROM student_credentials WHERE school_id='10000000-0000-4000-8000-000000000001' AND student_id='50000000-0000-4000-8000-000000000001';
