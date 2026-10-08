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
for width in [360,390,412]:
 adb('shell','wm','size',str(width)+'x800');adb('shell','wm','density','160')
 find(explore)
 (out/('welcome-'+str(width)+'.png')).write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
tap(find(explore))
find(heading)
(out/'explore.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
adb('shell','am','force-stop',app)
adb('shell','am','start','-W','-n',app+'/.MainActivity')
find('Your DataSub account' if app.endswith('datasub') else 'Run Your School Smarter')
assert not any('Welcome to your school community' in n.attrib.get('text','') for n in screen().iter('node'))
(out/'restart.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
runtime=adb('logcat','-d','-s','AndroidRuntime:E')
(out/'android-runtime.txt').write_text(runtime)
for block in re.split(r'(?=^.*FATAL EXCEPTION)',runtime,flags=re.MULTILINE):
 if 'FATAL EXCEPTION' not in block:continue
 process=re.search(r'Process:\s*([^,\s]+)',block)
 assert process is not None, 'Unidentified process crash'
 assert process.group(1)!=app and not process.group(1).startswith(app+':'), 'Application process crashed'
root=screen()
assert root is not None, 'App navigation snapshot missing'
texts=[n.attrib.get('text','') for n in root.iter('node')]
assert all(any(label==text for text in texts) for label in ['Home','Account']), 'Bottom navigation missing'
assert not any('© 2026 IHLink' in text for text in texts), 'Website footer present in app'
adb('shell','am','start','-W','-a','android.settings.APPLICATION_DETAILS_SETTINGS','-d','package:'+app)
find('IHLink DataSub' if app.endswith('datasub') else 'IHLink SchoolPro')
(out/'app-icon.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
adb('shell','am','start','-W','-n',app+'/.MainActivity')
find('Home')
(out/'RESULT.txt').write_text('PASS: install, launch, welcome at 360/390/412, Explore and restart. API35 emulator; no real-device or signed-production certification.\n')
print((out/'RESULT.txt').read_text())
