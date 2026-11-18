#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:?DATABASE_URL is required}"

# Hold the target membership row while the correction transaction attempts to
# acquire FOR KEY SHARE. Delete the membership before releasing the lock.
psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --quiet <<'SQL' &
BEGIN;
SELECT id FROM public.schoolpro_members
 WHERE school_id='20000000-0000-0000-0000-000000000001'
   AND user_id='10000000-0000-0000-0000-000000000002'
 FOR UPDATE;
SELECT set_config('application_name','schoolpro_member_lock_held',false);
SELECT pg_sleep(2);
DELETE FROM public.schoolpro_members
 WHERE school_id='20000000-0000-0000-0000-000000000001'
   AND user_id='10000000-0000-0000-0000-000000000002';
COMMIT;
SQL
locker=$!
for attempt in $(seq 1 200); do
  if psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --tuples-only --no-align --command "select 1 from pg_stat_activity where application_name='schoolpro_member_lock_held' and state='active' limit 1" | grep -q 1; then
    break
  fi
  if ! kill -0 "$locker" 2>/dev/null; then
    wait "$locker"
    echo "FAIL: membership lock transaction exited before acquiring its lock."
    exit 1
  fi
  sleep 0.05
done
if ! psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --tuples-only --no-align --command "select 1 from pg_stat_activity where application_name='schoolpro_member_lock_held' and state='active' limit 1" | grep -q 1; then
  kill "$locker" 2>/dev/null || true
  wait "$locker" || true
  echo "FAIL: timed out waiting for membership row lock."
  exit 1
fi
if psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --quiet <<'SQL'
SELECT set_config('request.jwt.claim.role','service_role',false);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);
SELECT public.schoolpro_correct_member_profile_atomic(
 '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',
 '10000000-0000-0000-0000-000000000001','Race','Must','Reject',null);
SQL
then
  wait "$locker"
  echo "FAIL: correction succeeded after concurrent membership removal."
  exit 1
fi
wait "$locker"
actual="$(psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --tuples-only --no-align --command "select first_name || ':' || count from public.profiles cross join (select count(*) from public.schoolpro_profile_change_audit where target_user_id='10000000-0000-0000-0000-000000000002') a(count) where id='10000000-0000-0000-0000-000000000002'")"
test "$actual" = "Staff:2"
echo "PASS: concurrent membership removal prevents profile correction and creates no additional audit row."

# Repeat the race against a guardian link and the email-change request RPC.
psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --quiet <<'SQL' &
BEGIN;
SELECT id FROM public.schoolpro_guardian_links
 WHERE school_id='20000000-0000-0000-0000-000000000001'
   AND guardian_user_id='10000000-0000-0000-0000-000000000003'
 FOR UPDATE;
SELECT set_config('application_name','schoolpro_guardian_lock_held',false);
SELECT pg_sleep(2);
DELETE FROM public.schoolpro_guardian_links
 WHERE school_id='20000000-0000-0000-0000-000000000001'
   AND guardian_user_id='10000000-0000-0000-0000-000000000003';
COMMIT;
SQL
locker=$!
for attempt in $(seq 1 200); do
  if psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --tuples-only --no-align --command "select 1 from pg_stat_activity where application_name='schoolpro_guardian_lock_held' and state='active' limit 1" | grep -q 1; then
    break
  fi
  if ! kill -0 "$locker" 2>/dev/null; then
    wait "$locker"
    echo "FAIL: guardian-link lock transaction exited before acquiring its lock."
    exit 1
  fi
  sleep 0.05
done
if ! psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --tuples-only --no-align --command "select 1 from pg_stat_activity where application_name='schoolpro_guardian_lock_held' and state='active' limit 1" | grep -q 1; then
  kill "$locker" 2>/dev/null || true
  wait "$locker" || true
  echo "FAIL: timed out waiting for guardian-link row lock."
  exit 1
fi
if psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --quiet <<'SQL'
SELECT set_config('request.jwt.claim.role','service_role',false);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);
SELECT public.schoolpro_request_member_email_change_atomic(
 '20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003',
 '10000000-0000-0000-0000-000000000001','guardian.new@example.test');
SQL
then
  wait "$locker"
  echo "FAIL: email change request succeeded after concurrent guardian-link removal."
  exit 1
fi
wait "$locker"
actual="$(psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --tuples-only --no-align --command "select count(*) from public.schoolpro_member_email_change_requests where target_user_id='10000000-0000-0000-0000-000000000003'")"
test "$actual" = "0"
echo "PASS: concurrent guardian-link removal prevents email change request creation."
