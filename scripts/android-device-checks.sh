#!/usr/bin/env bash
set -uo pipefail
# Keep test execution and evidence collection in the same shell.
set +e
android/gradlew --no-daemon -p android :app:connectedDebugAndroidTest
test_status=$?
mkdir -p android-delivery/instrumentation
adb logcat -d > android-delivery/instrumentation/logcat.txt
adb exec-out screencap -p > android-delivery/instrumentation/final-screen.png
cp -R android/app/build/outputs/androidTest-results/connected android-delivery/instrumentation/results
cp -R android/app/build/reports/androidTests/connected android-delivery/instrumentation/reports
if [ "$test_status" -ne 0 ]; then exit "$test_status"; fi
set -e
python scripts/android-smoke.py
