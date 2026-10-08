"""Configure the generated native iOS project without inventing signing credentials."""
import json,os,plistlib,subprocess
from pathlib import Path
config=json.loads(Path('capacitor.config.json').read_text())
assert config['appId'] in ('com.ihlink.datasub','com.ihlink.schoolpro')
info=Path('ios/App/App/Info.plist')
with info.open('rb') as f:p=plistlib.load(f)
p['CFBundleDisplayName']=config['appName']
p['CFBundleURLTypes']=[{'CFBundleURLName':config['appId']+'.auth','CFBundleURLSchemes':[config['appId']]}]
p['ITSAppUsesNonExemptEncryption']=False
with info.open('wb') as f:plistlib.dump(p,f)
icons=Path('ios/App/App/Assets.xcassets/AppIcon.appiconset');icons.mkdir(parents=True,exist_ok=True)
subprocess.run(['sips','-s','format','png','-z','1024','1024','public/brand/ihlink-original.jpg','--out',str(icons/'AppIcon-1024.png')],check=True)
(icons/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon-1024.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
project=Path('ios/App/App.xcodeproj/project.pbxproj');s=project.read_text()
import re
s=re.sub(r'CURRENT_PROJECT_VERSION = [^;]+;',f"CURRENT_PROJECT_VERSION = {int(os.environ.get('GITHUB_RUN_NUMBER','1'))};",s)
s=re.sub(r'MARKETING_VERSION = [^;]+;','MARKETING_VERSION = 1.0.0;',s)
project.write_text(s)

store=Path("ios-store-assets");store.mkdir(exist_ok=True)
for size,label in [(512,"google-play-icon.png"),(1024,"app-store-icon.png")]:
 subprocess.run(["sips","-s","format","png","-z",str(size),str(size),"public/brand/ihlink-original.jpg","--out",str(store/label)],check=True)
