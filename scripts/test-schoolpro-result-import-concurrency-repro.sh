#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:?DATABASE_URL is required}"
student='JSS-RACE'
school='20000000-0000-0000-0000-000000000001'
user='50000000-0000-0000-0000-000000000001'
scheme_a='10000000-0000-0000-0000-000000000001'
scheme_b='10000000-0000-0000-0000-000000000003'
for attempt in 1 2; do
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
      echo accepted > "/tmp/schoolpro-result-import-race-$attempt.result"
    else
      echo rejected > "/tmp/schoolpro-result-import-race-$attempt.result"
    fi
  ) &
done
wait
accepted="$(grep -l '^accepted$' /tmp/schoolpro-result-import-race-*.result | wc -l)"
rejected="$(grep -l '^rejected$' /tmp/schoolpro-result-import-race-*.result | wc -l)"
actual="$(psql "$DATABASE_URL" --set ON_ERROR_STOP=1 --tuples-only --no-align --command "
  select assessment_scheme_id::text || ':' || assessment_scores->>'exam'
  from public.schoolpro_results
  where student_id='40000000-0000-0000-0000-000000000099'
    and subject_id='70000000-0000-0000-0000-000000000001'
    and term='First Term' and session='2026/2027'")"
if [[ "$accepted" -eq 2 && "$rejected" -eq 0 ]]; then
  echo "REPRODUCED: both concurrent imports were accepted; final draft: $actual"
  exit 0
fi
echo "Unexpected race outcome: accepted=$accepted rejected=$rejected final=$actual"
cat /tmp/schoolpro-result-import-race-*.log
exit 1
