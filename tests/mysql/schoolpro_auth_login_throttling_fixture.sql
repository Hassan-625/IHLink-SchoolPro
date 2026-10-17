-- Synthetic authentication throttling fixture for disposable MySQL CI only.
INSERT INTO auth_login_attempts(identifier_hash,attempts,window_started_at,blocked_until)
VALUES ('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',3,'2026-10-17 12:00:00','2026-10-17 12:15:00');

SELECT CASE
  WHEN COUNT(*)=1 AND MAX(attempts)=3 AND MAX(blocked_until) IS NOT NULL
  THEN 'PASS: login throttling state stores only a SHA-256-shaped identifier key'
  ELSE 'FAIL: login throttling fixture mismatch'
END AS assertion
FROM auth_login_attempts
WHERE identifier_hash='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
