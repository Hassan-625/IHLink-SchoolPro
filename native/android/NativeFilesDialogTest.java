package com.ihlink.schoolpro;
import androidx.test.core.app.ActivityScenario;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import android.app.Instrumentation;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import com.getcapacitor.JSObject;
import com.getcapacitor.PluginCall;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import android.accessibilityservice.AccessibilityService;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;
import java.util.concurrent.atomic.AtomicReference;
@RunWith(AndroidJUnit4.class)
public class NativeFilesDialogTest {
 static class Result extends PluginCall {
  final CountDownLatch done=new CountDownLatch(1);volatile JSObject result;volatile String failure;
  Result(String method,JSObject data){super(null,"NativeFiles","files-fixture-"+method,method,data);}
  @Override public void resolve(JSObject value){result=value;done.countDown();}
  @Override public void reject(String message,String code,Exception ex,JSObject data){failure=message;done.countDown();}
  Result await() throws Exception {assertTrue("File-save cancellation callback timed out",done.await(30,TimeUnit.SECONDS));return this;}
 }
 @Test public void namedDownloadOpensSaveDialogAndCancellationReturnsToApp() throws Exception {
  Instrumentation instrumentation=InstrumentationRegistry.getInstrumentation();
  try(ActivityScenario<MainActivity> scenario=ActivityScenario.launch(MainActivity.class)){
   AtomicReference<NativeFilesPlugin> holder=new AtomicReference<>();scenario.onActivity(activity->holder.set((NativeFilesPlugin)activity.getBridge().getPlugin("NativeFiles").getInstance()));assertNotNull(holder.get());
   JSObject data=new JSObject();data.put("name","IHLink Academy - Primary Testing - Result.txt");data.put("mimeType","text/plain");data.put("data","VEVTVCBPTkxZ");
   Result result=new Result("save",data);scenario.onActivity(activity->holder.get().save(result));
   boolean dialog=false;long deadline=System.currentTimeMillis()+30000;
   while(System.currentTimeMillis()<deadline){AccessibilityNodeInfo root=instrumentation.getUiAutomation().getRootInActiveWindow();if(root!=null&&String.valueOf(root.getPackageName()).contains("documentsui")){dialog=true;break;}Thread.sleep(200);}
   assertTrue("Android file save dialog did not open",dialog);
   // A cold emulator can take seconds to finish the picker transition.
   // Do not keep sending Back into the app while its cancellation callback is pending.
   long cancelDeadline=System.currentTimeMillis()+30000;
   while(result.done.getCount()!=0 && System.currentTimeMillis()<cancelDeadline){
    AccessibilityNodeInfo active=instrumentation.getUiAutomation().getRootInActiveWindow();
    if(active!=null&&String.valueOf(active.getPackageName()).contains("documentsui"))
     instrumentation.getUiAutomation().performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK);
    result.done.await(4,TimeUnit.SECONDS);
   }
   assertNull(result.await().failure);assertFalse(result.result.getBoolean("saved"));
   AccessibilityNodeInfo after=null;long foregroundDeadline=System.currentTimeMillis()+10000;
   while(System.currentTimeMillis()<foregroundDeadline){
    after=instrumentation.getUiAutomation().getRootInActiveWindow();
    if(after!=null&&"com.ihlink.schoolpro".equals(String.valueOf(after.getPackageName())))break;
    Thread.sleep(200);
   }
   assertNotNull("No foreground screen after cancellation",after);
   assertEquals("App did not regain focus after file-save cancellation","com.ihlink.schoolpro",String.valueOf(after.getPackageName()));
   JSObject bad=new JSObject();bad.put("name","../outside.txt");bad.put("data","VEVTVCBPTkxZ");Result rejected=new Result("save",bad);holder.get().save(rejected);assertNotNull(rejected.await().failure);
  }
 }
}
