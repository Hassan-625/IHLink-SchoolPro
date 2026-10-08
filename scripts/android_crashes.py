"""Fail on app/unknown crashes; identify the observed external UI-tool failure."""
import re
def verify_crashes(runtime, app, app_pids):
 for block in re.split(r'(?=^.*FATAL EXCEPTION)',runtime,flags=re.MULTILINE):
  if 'FATAL EXCEPTION' not in block:continue
  process=re.search(r'Process:\s*([^,\s]+)',block)
  if process:
   assert process.group(1)!=app and not process.group(1).startswith(app+':'), 'Application process crashed'
   continue
  pid=re.search(r'PID:\s*(\d+)',block)
  external_bridge=(pid is not None and pid.group(1) not in app_pids
   and 'FATAL EXCEPTION: UiAutomation' in block
   and 'java.lang.RuntimeException: Bad file descriptor' in block
   and 'android.accessibilityservice.' in block)
  assert external_bridge, 'Unidentified process crash'
