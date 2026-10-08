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
public class NativePrintDialogTest {
 @Test public void printableDocumentOpensAndroidPrintDialog() throws Exception {
  Instrumentation instrumentation=InstrumentationRegistry.getInstrumentation();
  try(ActivityScenario<MainActivity> scenario=ActivityScenario.launch(MainActivity.class)){
   AtomicReference<NativePrintPlugin> holder=new AtomicReference<>();
   scenario.onActivity(activity->holder.set((NativePrintPlugin)activity.getBridge().getPlugin("NativePrint").getInstance()));
   assertNotNull("Native print plugin not registered",holder.get());
   JSObject data=new JSObject();data.put("html","<!doctype html><html><body><h1>SchoolPro isolated print fixture</h1><table><tr><th>Student</th><th>Average</th></tr><tr><td>Test only</td><td>80</td></tr></table></body></html>");
   NativeVaultSecurityTest.Result result=new NativeVaultSecurityTest.Result("print",data);
   holder.get().print(result);assertNull(result.await().failure);
   boolean dialog=false;long deadline=System.currentTimeMillis()+15000;
   while(System.currentTimeMillis()<deadline){AccessibilityNodeInfo root=instrumentation.getUiAutomation().getRootInActiveWindow();if(root!=null&&"com.android.printspooler".contentEquals(root.getPackageName()==null?"":root.getPackageName())){dialog=true;break;}Thread.sleep(200);}
   assertTrue("Android print dialog did not open",dialog);
  } finally {
   instrumentation.getUiAutomation().injectInputEvent(new KeyEvent(KeyEvent.ACTION_DOWN,KeyEvent.KEYCODE_BACK),true);
   instrumentation.getUiAutomation().injectInputEvent(new KeyEvent(KeyEvent.ACTION_UP,KeyEvent.KEYCODE_BACK),true);
  }
 }
}
