from android_crashes import verify_crashes
import os,re,subprocess,time,xml.etree.ElementTree as ET
from pathlib import Path
app=os.environ['ANDROID_APP_ID']
explore='Explore services' if app.endswith('datasub') else 'Explore SchoolPro'
heading='All DataSub Services' if app.endswith('datasub') else 'SchoolPro'
out=Path('android-delivery/device-checks');out.mkdir(parents=True,exist_ok=True)
def adb(*args):return subprocess.check_output(['adb',*args],text=True,timeout=25)
def screen():
 try:
  adb('shell','rm','-f','/sdcard/window.xml')
  adb('shell','uiautomator','dump','/sdcard/window.xml')
  adb('pull','/sdcard/window.xml',str(out/'current.xml'))
  return ET.parse(out/'current.xml').getroot()
 except (subprocess.SubprocessError,ET.ParseError):
  return None
def find(label):
 deadline=time.monotonic()+120
 while time.monotonic()<deadline:
  root=screen()
  for node in ([] if root is None else root.iter('node')):
   if label in (node.attrib.get('text','')+' '+node.attrib.get('content-desc','')):return node
  time.sleep(1)
 (out/'failure.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p'],timeout=25))
 (out/'failure-logcat.txt').write_text(adb('logcat','-d'))
 raise AssertionError('Expected app screen missing: '+label)
def tap(node):
 x1,y1,x2,y2=map(int,re.findall(r'\d+',node.attrib['bounds']))
 adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
adb('install','-r','android-delivery/ihlink-preview.apk')
adb('logcat','-c')
adb('shell','am','start','-W','-n',app+'/.MainActivity')
app_pids=set(adb('shell','pidof',app).split())
for width in [360,390,412]:
 adb('shell','wm','size',str(width)+'x800');adb('shell','wm','density','160')
 find(explore)
 (out/('welcome-'+str(width)+'.png')).write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
root=screen()
status=[n for n in root.iter('node') if n.attrib.get('resource-id')=='com.android.systemui:id/status_bar']
assert status, 'Phone status bar missing'
bar_bottom=int(re.findall(r'\d+',status[0].attrib['bounds'])[-1])
app_labels=[n for n in root.iter('node') if 'IHLink ' in n.attrib.get('text','')]
assert app_labels and all(int(re.findall(r'\d+',n.attrib['bounds'])[1])>=bar_bottom for n in app_labels), 'App header overlaps phone status bar'
(out/'system-bar-check.txt').write_text('PASS: visible phone status bar and app heading below its bounds.\n')
tap(find(explore))
find(heading)
(out/'explore.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
adb('shell','am','force-stop',app)
adb('shell','am','start','-W','-n',app+'/.MainActivity')
find('Your DataSub account' if app.endswith('datasub') else 'Run Your School Smarter')
app_pids.update(adb('shell','pidof',app).split())
assert not any('Welcome to your school community' in n.attrib.get('text','') for n in screen().iter('node'))
(out/'restart.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
runtime=adb('logcat','-d','-s','AndroidRuntime:E')
(out/'android-runtime.txt').write_text(runtime)
verify_crashes(runtime,app,app_pids)
assert app in adb('shell','dumpsys','activity','activities'), 'App activity missing after restart'
root=screen()
assert root is not None, 'App navigation snapshot missing'
texts=[n.attrib.get('text','') for n in root.iter('node')]
assert all(any(label==text for text in texts) for label in ['Home','Account']), 'Bottom navigation missing'
assert not any('© 2026 IHLink' in text for text in texts), 'Website footer present in app'
if app.endswith('schoolpro'):
 tap(find('Student sign in'))
 find('Admission number');find('School code')
 login_root=screen()
 assert login_root is not None
 assert not any('Secure access with encryption' in n.attrib.get('text','') for n in login_root.iter('node')), 'Website marketing panel present in native sign-in'
 (out/'student-sign-in.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
 adb('shell','wm','size','360x800')
 find('Admission number')
 (out/'student-sign-in-360.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
 adb('shell','input','keyevent','4')
 find('Run Your School Smarter')
adb('shell','am','start','-W','-a','android.settings.APPLICATION_DETAILS_SETTINGS','-d','package:'+app)
find('IHLink DataSub' if app.endswith('datasub') else 'IHLink SchoolPro')
(out/'app-icon.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
adb('shell','am','start','-W','-n',app+'/.MainActivity')
find('Home')
(out/'RESULT.txt').write_text('PASS: install, launch, welcome at 360/390/412, Explore and restart. API35 emulator; SchoolPro student sign-in layout checked without credentials; no real-device, authenticated-workflow or signed-production certification.\n')
print((out/'RESULT.txt').read_text())
