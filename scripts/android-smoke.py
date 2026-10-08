from android_crashes import verify_crashes
import os,re,subprocess,time,struct,zlib,xml.etree.ElementTree as ET
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
def png_rgb(data):
 pos=8;raw=b''
 while pos<len(data):
  size=struct.unpack('>I',data[pos:pos+4])[0];kind=data[pos+4:pos+8];part=data[pos+8:pos+8+size];pos+=size+12
  if kind==b'IHDR':w,h,depth,color,_,_,_=struct.unpack('>IIBBBBB',part)
  if kind==b'IDAT':raw+=part
 assert depth==8 and color in [2,6], 'Unsupported screenshot PNG'
 bpp=3 if color==2 else 4;raw=zlib.decompress(raw);rows=[];previous=bytearray(w*bpp);offset=0
 for y in range(h):
  mode=raw[offset];offset+=1;row=bytearray(raw[offset:offset+w*bpp]);offset+=w*bpp
  for x in range(len(row)):
   a=row[x-bpp] if x>=bpp else 0;b=previous[x];c=previous[x-bpp] if x>=bpp else 0
   if mode==1:row[x]=(row[x]+a)%256
   elif mode==2:row[x]=(row[x]+b)%256
   elif mode==3:row[x]=(row[x]+(a+b)//2)%256
   elif mode==4:
    p=a+b-c;pa=abs(p-a);pb=abs(p-b);pc=abs(p-c);row[x]=(row[x]+(a if pa<=pb and pa<=pc else b if pb<=pc else c))%256
   else:assert mode==0
  rows.append(row);previous=row
 return w,h,bpp,rows
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
windows=adb('shell','dumpsys','window')
(out/'system-window-insets.txt').write_text(windows)
status_lines=[line for line in windows.splitlines() if 'statusBars' in line and re.search(r'(?:mVisible|visible)=true',line)]
assert status_lines, 'Phone status bar is not visible in system window insets'
frames=[re.search(r'(?:mFrame|frame)=\[0,0\]\[\d+,(\d+)\]',line) for line in status_lines]
heights=[int(f.group(1)) for f in frames if f]
assert heights, 'Phone status bar bounds unavailable'
bar_bottom=max(heights)
app_labels=[n for n in root.iter('node') if 'IHLink ' in n.attrib.get('text','')]
assert app_labels and all(int(re.findall(r'\d+',n.attrib['bounds'])[1])>=bar_bottom for n in app_labels), 'App header overlaps phone status bar'
shot=subprocess.check_output(['adb','exec-out','screencap','-p']);w,h,bpp,pixels=png_rgb(shot)
background=pixels[bar_bottom//2][(w//2)*bpp:(w//2)*bpp+3]
assert max(background)<60, 'Dark theme has a light native status-bar background'
bright=sum(1 for row in pixels[:bar_bottom] for x in range(0,w*bpp,bpp) if min(row[x:x+3])>180)
assert bright>20, 'Phone status icons lack contrast on dark background'
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
