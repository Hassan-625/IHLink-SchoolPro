import {readFileSync,writeFileSync,copyFileSync,existsSync,readdirSync} from 'node:fs';
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

const brand='public/brand/ihlink-icon.png';
if(existsSync(brand)){for(const dir of readdirSync('android/app/src/main/res').filter(x=>/^mipmap-(mdpi|hdpi|xhdpi|xxhdpi|xxxhdpi)$/.test(x))){for(const name of ['ic_launcher.png','ic_launcher_round.png','ic_launcher_foreground.png'])copyFileSync(brand,'android/app/src/main/res/'+dir+'/'+name);}}
