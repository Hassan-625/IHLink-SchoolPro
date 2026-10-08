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
const res='android/app/src/main/res',brand='public/brand/schoolpro-icon.png';
if(!existsSync(brand))throw new Error('Brand artwork missing');
mkdirSync(`${res}/drawable-nodpi`,{recursive:true});copyFileSync(brand,`${res}/drawable-nodpi/ihlink_emblem.png`);
for(const dir of readdirSync(res).filter(x=>/^mipmap-(mdpi|hdpi|xhdpi|xxhdpi|xxxhdpi)$/.test(x)))for(const name of ['ic_launcher.png','ic_launcher_round.png','ic_launcher_foreground.png'])rmSync(`${res}/${dir}/${name}`,{force:true});
mkdirSync(`${res}/mipmap-anydpi`,{recursive:true});mkdirSync(`${res}/mipmap-anydpi-v26`,{recursive:true});
const legacy=`<?xml version="1.0" encoding="utf-8"?><layer-list xmlns:android="http://schemas.android.com/apk/res/android"><item><shape android:shape="rectangle"><solid android:color="#FFFFFF"/></shape></item><item android:left="2dp" android:top="2dp" android:right="2dp" android:bottom="2dp"><bitmap android:src="@drawable/ihlink_emblem" android:gravity="fill" android:filter="true"/></item></layer-list>`;
for(const name of ['ic_launcher','ic_launcher_round'])writeFileSync(`${res}/mipmap-anydpi/${name}.xml`,legacy);
// Relative insets retain a 66/108 safe-zone ratio at every launcher render size.
writeFileSync(`${res}/mipmap-anydpi/ic_launcher_foreground.xml`,`<?xml version="1.0" encoding="utf-8"?><inset xmlns:android="http://schemas.android.com/apk/res/android" android:insetLeft="19.444444%" android:insetTop="19.444444%" android:insetRight="19.444444%" android:insetBottom="19.444444%"><bitmap android:src="@drawable/ihlink_emblem" android:gravity="fill" android:filter="true"/></inset>`);
for(const name of ['ic_launcher','ic_launcher_round'])writeFileSync(`${res}/mipmap-anydpi-v26/${name}.xml`,`<?xml version="1.0" encoding="utf-8"?><adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@android:color/white"/><foreground android:drawable="@mipmap/ic_launcher_foreground"/></adaptive-icon>`);

// Install the app-local secure session and biometric plugin on every generated project.
const javaRoot='android/app/src/main/java/com/ihlink/schoolpro';
mkdirSync(javaRoot,{recursive:true});copyFileSync('native/android/NativeVaultPlugin.java',`${javaRoot}/NativeVaultPlugin.java`);
writeFileSync(`${javaRoot}/MainActivity.java`,`package com.ihlink.schoolpro;\nimport android.os.Bundle;\nimport com.getcapacitor.BridgeActivity;\npublic class MainActivity extends BridgeActivity { @Override public void onCreate(Bundle state){registerPlugin(NativeVaultPlugin.class);super.onCreate(state);} }\n`);
let vaultGradle=readFileSync(gradle,'utf8');if(!vaultGradle.includes('androidx.biometric:biometric'))vaultGradle=vaultGradle.replace('dependencies {',"dependencies {\n    implementation 'androidx.biometric:biometric:1.1.0'");writeFileSync(gradle,vaultGradle);
let vaultManifest=readFileSync(manifest,'utf8');if(!vaultManifest.includes('android.permission.USE_BIOMETRIC'))vaultManifest=vaultManifest.replace('<application','<uses-permission android:name="android.permission.USE_BIOMETRIC"/><application');vaultManifest=vaultManifest.replace(/android:allowBackup="true"/,'android:allowBackup="false"');writeFileSync(manifest,vaultManifest);

mkdirSync(`${res}/xml`,{recursive:true});
writeFileSync(`${res}/xml/ihlink_data_extraction.xml`,`<?xml version="1.0" encoding="utf-8"?><data-extraction-rules><cloud-backup><exclude domain="root" path="."/><exclude domain="sharedpref" path="."/><exclude domain="database" path="."/><exclude domain="file" path="."/></cloud-backup><device-transfer><exclude domain="root" path="."/><exclude domain="sharedpref" path="."/><exclude domain="database" path="."/><exclude domain="file" path="."/></device-transfer></data-extraction-rules>`);
let backupManifest=readFileSync(manifest,'utf8');if(!backupManifest.includes('android:dataExtractionRules'))backupManifest=backupManifest.replace('<application','<application android:dataExtractionRules="@xml/ihlink_data_extraction"');writeFileSync(manifest,backupManifest);
const vaultTestRoot='android/app/src/androidTest/java/com/ihlink/schoolpro';mkdirSync(vaultTestRoot,{recursive:true});copyFileSync('native/android/NativeVaultSecurityTest.java',`${vaultTestRoot}/NativeVaultSecurityTest.java`);
// Capacitor's generated context test retains its template package unless corrected.
const templateContextTest='android/app/src/androidTest/java/com/getcapacitor/myapp/ExampleInstrumentedTest.java';if(existsSync(templateContextTest))writeFileSync(templateContextTest,readFileSync(templateContextTest,'utf8').replaceAll('com.getcapacitor.app',config.appId));


// Match the native inset background to the selected app appearance on old and new WebViews.
const systemRoot=`android/app/src/main/java/${config.appId.replaceAll('.', '/')}`;
mkdirSync(systemRoot,{recursive:true});
writeFileSync(`${systemRoot}/NativeSystemThemePlugin.java`,`package ${config.appId};
import android.graphics.Color;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
@CapacitorPlugin(name="NativeSystemTheme")
public class NativeSystemThemePlugin extends Plugin {
 @PluginMethod public void apply(PluginCall call) {
  boolean light=Boolean.TRUE.equals(call.getBoolean("light", false));
  getActivity().runOnUiThread(()->{getActivity().getWindow().getDecorView().setBackgroundColor(Color.parseColor(light ? "#f1f5f9" : "#10151d"));call.resolve();});
 }
}
`);
const activityPath=`${systemRoot}/MainActivity.java`;
let activity=readFileSync(activityPath,'utf8');
if(activity.includes('registerPlugin(NativeVaultPlugin.class);')) activity=activity.replace('registerPlugin(NativeVaultPlugin.class);','registerPlugin(NativeVaultPlugin.class);registerPlugin(NativeSystemThemePlugin.class);');
else activity=`package ${config.appId};
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;
public class MainActivity extends BridgeActivity { @Override public void onCreate(Bundle state){registerPlugin(NativeSystemThemePlugin.class);super.onCreate(state);} }
`;
writeFileSync(activityPath,activity);
const stylesPath=`${res}/values/styles.xml`;
let styles=readFileSync(stylesPath,'utf8');
styles=styles.replace(/(<style name="AppTheme.NoActionBar"[^>]*>)/,'$1\n        <item name="android:windowBackground">#10151d</item>');
writeFileSync(stylesPath,styles);

copyFileSync("native/android/NativePrintPlugin.java",`${systemRoot}/NativePrintPlugin.java`);
writeFileSync(activityPath,readFileSync(activityPath,"utf8").replace("registerPlugin(NativeSystemThemePlugin.class);","registerPlugin(NativeSystemThemePlugin.class);registerPlugin(NativePrintPlugin.class);"));

copyFileSync("native/android/NativePrintDialogTest.java",`${vaultTestRoot}/NativePrintDialogTest.java`);
