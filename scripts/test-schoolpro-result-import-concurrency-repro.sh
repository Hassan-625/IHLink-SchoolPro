#!/usr/bin/env bash
set -uo pipefail
: "${DATABASE_URL:?DATABASE_URL is required}"
student='JSS-RACE'
school='20000000-0000-0000-0000-000000000001'
user='50000000-0000-0000-0000-000000000001'
scheme_a='10000000-0000-0000-0000-000000000001'
scheme_b='10000000-0000-0000-0000-000000000003'
for attempt in 1 2; do
  rm -f "/tmp/schoolpro-result-import-race-$attempt.log" "/tmp/schoolpro-result-import-race-$attempt.result"
  scheme="$scheme_a"
  [[ "$attempt" == 2 ]] && scheme="$scheme_b"
  (
    if psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --quiet --command "
      select set_config('request.jwt.claim.sub','$user',false);
      select public.import_schoolpro_results(
        '$school','First Term','2026/2027',
        jsonb_build_array(jsonb_build_object(
          'admission_number','$student',
          'subject_code','MATH',
          'assessment_scheme_id','$scheme',
          'assessment_scores',jsonb_build_object('exam',case when '$scheme'='$scheme_a' then 71 else 82 end)
        ))
      );" > "/tmp/schoolpro-result-import-race-$attempt.log" 2>&1; then
      printf 'accepted\n' > "/tmp/schoolpro-result-import-race-$attempt.result"
    else
      rc=$?
      printf 'rejected:%s\n' "$rc" > "/tmp/schoolpro-result-import-race-$attempt.result"
    fi
  ) &
  pids[$attempt]=$!
done
# Each worker records its own result. Do not let a failed psql exit code
# abort the parent before both session logs and the final database state print.
worker_wait_failures=0
for attempt in 1 2; do
  if wait "${pids[$attempt]}"; then :; else worker_wait_failures=$((worker_wait_failures + 1)); fi
done
accepted=0
rejected=0
for attempt in 1 2; do
  result="/tmp/schoolpro-result-import-race-$attempt.result"
  if [[ -f "$result" ]]; then
    case "$(cat "$result")" in
      accepted) accepted=$((accepted + 1)) ;;
      rejected:*) rejected=$((rejected + 1)) ;;
      *) echo "Session $attempt returned an unknown result: $(cat "$result")" ;;
    esac
  else
    echo "Session $attempt produced no result marker."
  fi
done
actual="$(psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --tuples-only --no-align --command "
  select assessment_scheme_id::text || ':' || assessment_scores->>'exam'
  from public.schoolpro_results
  where student_id='40000000-0000-0000-0000-000000000099'
    and subject_id='70000000-0000-0000-0000-000000000001'
    and term='First Term' and session='2026/2027'" 2>&1)"
printf 'Session outcomes: accepted=%s rejected=%s worker_wait_failures=%s\n' "$accepted" "$rejected" "$worker_wait_failures"
printf 'Final draft: %s\n' "${actual:-<no row or query failed>}"
for attempt in 1 2; do
  printf '%s\n' "--- session $attempt result ---"
  cat "/tmp/schoolpro-result-import-race-$attempt.result" 2>/dev/null || true
  printf '%s\n' "--- session $attempt log ---"
  cat "/tmp/schoolpro-result-import-race-$attempt.log" 2>/dev/null || true
done
if [[ "$accepted" -eq 2 && "$rejected" -eq 0 && "$worker_wait_failures" -eq 0 ]]; then
  echo "REPRODUCED: both concurrent imports were accepted; final draft: $actual"
  exit 0
fi
echo "Race not reproduced or test execution incomplete."
exit 1
