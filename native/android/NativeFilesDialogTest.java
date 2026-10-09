package com.ihlink.schoolpro;
import androidx.test.core.app.ActivityScenario;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import android.app.Instrumentation;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import com.getcapacitor.JSObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;
import java.util.concurrent.atomic.AtomicReference;
@RunWith(AndroidJUnit4.class)
public class NativeFilesDialogTest {
 @Test public void namedDownloadOpensSaveDialogAndCancellationReturnsToApp() throws Exception {
  Instrumentation instrumentation=InstrumentationRegistry.getInstrumentation();
  try(ActivityScenario<MainActivity> scenario=ActivityScenario.launch(MainActivity.class)){
   AtomicReference<NativeFilesPlugin> holder=new AtomicReference<>();scenario.onActivity(activity->holder.set((NativeFilesPlugin)activity.getBridge().getPlugin("NativeFiles").getInstance()));assertNotNull(holder.get());
   JSObject data=new JSObject();data.put("name","IHLink Academy - Primary Testing - Result.txt");data.put("mimeType","text/plain");data.put("data","VEVTVCBPTkxZ");
   NativeVaultSecurityTest.Result result=new NativeVaultSecurityTest.Result("save",data);scenario.onActivity(activity->holder.get().save(result));
   boolean dialog=false;long deadline=System.currentTimeMillis()+15000;
   while(System.currentTimeMillis()<deadline){AccessibilityNodeInfo root=instrumentation.getUiAutomation().getRootInActiveWindow();if(root!=null&&String.valueOf(root.getPackageName()).contains("documentsui")){dialog=true;break;}Thread.sleep(200);}
   assertTrue("Android file save dialog did not open",dialog);
   // The first Back may dismiss the keyboard or leave a folder, rather than cancel.
   long cancelDeadline=System.currentTimeMillis()+10000;
   while(result.done.getCount()!=0 && System.currentTimeMillis()<cancelDeadline){
    instrumentation.getUiAutomation().injectInputEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_BACK),true);
    instrumentation.getUiAutomation().injectInputEvent(new KeyEvent(KeyEvent.ACTION_UP,KeyEvent.KEYCODE_BACK),true);
    Thread.sleep(600);
   }
   assertNull(result.await().failure);assertFalse(result.result.getBoolean("saved"));
   JSObject bad=new JSObject();bad.put("name","../outside.txt");bad.put("data","VEVTVCBPTkxZ");NativeVaultSecurityTest.Result rejected=new NativeVaultSecurityTest.Result("save",bad);holder.get().save(rejected);assertNotNull(rejected.await().failure);
  }
 }
}
