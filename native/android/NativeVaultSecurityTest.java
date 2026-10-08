package com.ihlink.schoolpro;
import androidx.test.core.app.ActivityScenario;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import com.getcapacitor.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

@RunWith(AndroidJUnit4.class)
public class NativeVaultSecurityTest {
 static class Result extends PluginCall {
  final CountDownLatch done=new CountDownLatch(1);volatile JSObject result;volatile String failure;
  Result(String method,JSObject data){super(null,"NativeVault","isolated-fixture",method,data);}
  @Override public void resolve(){done.countDown();}
  @Override public void resolve(JSObject value){result=value;done.countDown();}
  @Override public void reject(String message,String code,Exception ex,JSObject data){failure=message;done.countDown();}
  Result await() throws Exception {assertTrue("Native operation timed out",done.await(30,TimeUnit.SECONDS));return this;}
 }
 private JSObject data(String... entries){JSObject value=new JSObject();for(int i=0;i<entries.length;i+=2)value.put(entries[i],entries[i+1]);return value;}
 @Test public void encryptedSessionRequiresPasscodeAndFiveFailuresWipeOnlyLocalAccess() throws Exception {
  try(ActivityScenario<MainActivity> scenario=ActivityScenario.launch(MainActivity.class)){
   AtomicReference<NativeVaultPlugin> holder=new AtomicReference<>();scenario.onActivity(activity->holder.set((NativeVaultPlugin)activity.getBridge().getPlugin("NativeVault").getInstance()));NativeVaultPlugin vault=holder.get();assertNotNull(vault);
   Result reset=new Result("reset",data());vault.reset(reset);reset.await();
   try {
    Result write=new Result("setItem",data("key","fixture-session","value","isolated-fake-session-never-real-credentials"));vault.setItem(write);assertNull(write.await().failure);
    Result configure=new Result("configure",data("pin","123456"));vault.configure(configure);assertNull(configure.await().failure);
    AtomicReference<String> stored=new AtomicReference<>();scenario.onActivity(activity->stored.set(activity.getSharedPreferences("ihlink_native_vault",0).getString("payload","")));assertFalse(stored.get().contains("isolated-fake-session"));assertFalse(stored.get().contains("123456"));
    Result lock=new Result("lock",data());vault.lock(lock);lock.await();Result lockedRead=new Result("getItem",data("key","fixture-session"));vault.getItem(lockedRead);assertNotNull(lockedRead.await().failure);
    Result wrong=new Result("unlock",data("pin","999999"));vault.unlock(wrong);assertNotNull(wrong.await().failure);
    Result unlock=new Result("unlock",data("pin","123456"));vault.unlock(unlock);assertNull(unlock.await().failure);
    Result read=new Result("getItem",data("key","fixture-session"));vault.getItem(read);assertEquals("isolated-fake-session-never-real-credentials",read.await().result.getString("value"));
    Result changeWrong=new Result("configure",data("pin","654321","currentPin","000000"));vault.configure(changeWrong);assertNotNull(changeWrong.await().failure);
    Result change=new Result("configure",data("pin","654321","currentPin","123456"));vault.configure(change);assertNull(change.await().failure);
    Result lockAgain=new Result("lock",data());vault.lock(lockAgain);lockAgain.await();
    for(int i=0;i<5;i++){Result incorrect=new Result("unlock",data("pin","123456"));vault.unlock(incorrect);assertNotNull(incorrect.await().failure);}
    Result status=new Result("status",data());vault.status(status);assertFalse(status.await().result.getBool("enabled"));Result wiped=new Result("getItem",data("key","fixture-session"));vault.getItem(wiped);assertNull(wiped.await().result.getString("value"));
   } finally {Result clean=new Result("reset",data());vault.reset(clean);clean.await();}
  }
 }
}
