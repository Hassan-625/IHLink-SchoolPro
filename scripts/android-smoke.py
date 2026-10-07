import os,re,subprocess,time,xml.etree.ElementTree as ET
from pathlib import Path
app=os.environ['ANDROID_APP_ID']
explore='Explore services' if app.endswith('datasub') else 'Explore SchoolPro'
heading='All DataSub Services' if app.endswith('datasub') else 'SchoolPro'
out=Path('android-delivery/device-checks');out.mkdir(parents=True,exist_ok=True)
def adb(*args):return subprocess.check_output(['adb',*args],text=True)
def screen():
 adb('shell','uiautomator','dump','/sdcard/window.xml')
 adb('pull','/sdcard/window.xml',str(out/'current.xml'))
 return ET.parse(out/'current.xml').getroot()
def find(label):
 for _ in range(30):
  root=screen()
  for node in root.iter('node'):
   if label in (node.attrib.get('text','')+' '+node.attrib.get('content-desc','')):return node
  time.sleep(1)
 raise AssertionError('Expected app screen missing: '+label)
def tap(node):
 x1,y1,x2,y2=map(int,re.findall(r'\d+',node.attrib['bounds']))
 adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
adb('install','-r','android-delivery/ihlink-preview.apk')
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
find(heading)
(out/'restart.png').write_bytes(subprocess.check_output(['adb','exec-out','screencap','-p']))
assert 'FATAL EXCEPTION' not in adb('logcat','-d','-s','AndroidRuntime:E')
(out/'RESULT.txt').write_text('PASS: install, launch, welcome at 360/390/412, Explore and restart. API35 emulator; no real-device or signed-production certification.\n')
print((out/'RESULT.txt').read_text())
