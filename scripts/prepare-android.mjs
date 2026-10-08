import {readFileSync,writeFileSync,copyFileSync,existsSync,readdirSync,mkdirSync,rmSync} from 'node:fs';
const config=JSON.parse(readFileSync('capacitor.config.json','utf8'));
if(!['com.ihlink.datasub','com.ihlink.schoolpro'].includes(config.appId))throw new Error('Unknown app identity');
const manifest='android/app/src/main/AndroidManifest.xml';
let xml=readFileSync(manifest,'utf8');
const filter=`<intent-filter><action android:name="android.intent.action.VIEW"/><category android:name="android.intent.category.DEFAULT"/><category android:name="android.intent.category.BROWSABLE"/><data android:scheme="${config.appId}" android:host="auth" android:path="/callback"/></intent-filter>`;
if(!xml.includes(`android:scheme="${config.appId}"`))xml=xml.replace('</activity>',filter+'</activity>');
if(!xml.includes(filter))throw new Error('Auth callback intent was not installed');
writeFileSync(manifest,xml);
const gradle='android/app/build.gradle';let source=readFileSync(gradle,'utf8');
const buildNumber=Number(process.env.GITHUB_RUN_NUMBER||1);
if(!Number.isInteger(buildNumber)||buildNumber<1||buildNumber>2100000000)throw new Error('Invalid build number');
source=source.replace(/versionCode\s+\d+/,`versionCode ${buildNumber}`).replace(/versionName\s+"[^"]+"/,`versionName "1.0.0-preview.${buildNumber}"`);
writeFileSync(gradle,source);
// Keep the original emblem. Legacy icons and adaptive layers have different bounds.
const res='android/app/src/main/res',brand='public/brand/ihlink-original.jpg';
if(!existsSync(brand))throw new Error('Brand artwork missing');
mkdirSync(`${res}/drawable-nodpi`,{recursive:true});copyFileSync(brand,`${res}/drawable-nodpi/ihlink_emblem.jpg`);
for(const dir of readdirSync(res).filter(x=>/^mipmap-(mdpi|hdpi|xhdpi|xxhdpi|xxxhdpi)$/.test(x)))for(const name of ['ic_launcher.png','ic_launcher_round.png','ic_launcher_foreground.png'])rmSync(`${res}/${dir}/${name}`,{force:true});
mkdirSync(`${res}/mipmap-anydpi`,{recursive:true});mkdirSync(`${res}/mipmap-anydpi-v26`,{recursive:true});
const legacy=`<?xml version="1.0" encoding="utf-8"?><layer-list xmlns:android="http://schemas.android.com/apk/res/android"><item><shape android:shape="rectangle"><solid android:color="#FFFFFF"/></shape></item><item android:left="2dp" android:top="2dp" android:right="2dp" android:bottom="2dp"><bitmap android:src="@drawable/ihlink_emblem" android:gravity="fill" android:filter="true"/></item></layer-list>`;
for(const name of ['ic_launcher','ic_launcher_round'])writeFileSync(`${res}/mipmap-anydpi/${name}.xml`,legacy);
// Relative insets retain a 66/108 safe-zone ratio at every launcher render size.
writeFileSync(`${res}/mipmap-anydpi/ic_launcher_foreground.xml`,`<?xml version="1.0" encoding="utf-8"?><inset xmlns:android="http://schemas.android.com/apk/res/android" android:insetLeft="19.444444%" android:insetTop="19.444444%" android:insetRight="19.444444%" android:insetBottom="19.444444%"><bitmap android:src="@drawable/ihlink_emblem" android:gravity="fill" android:filter="true"/></inset>`);
for(const name of ['ic_launcher','ic_launcher_round'])writeFileSync(`${res}/mipmap-anydpi-v26/${name}.xml`,`<?xml version="1.0" encoding="utf-8"?><adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@android:color/white"/><foreground android:drawable="@mipmap/ic_launcher_foreground"/></adaptive-icon>`);
