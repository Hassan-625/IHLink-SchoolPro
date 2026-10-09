package com.ihlink.schoolpro;

import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import com.getcapacitor.*;
import com.getcapacitor.annotation.CapacitorPlugin;
import org.json.JSONObject;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.security.SecureRandom;
import java.util.Arrays;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import javax.crypto.SecretKeyFactory;

@CapacitorPlugin(name="NativeVault")
public class NativeVaultPlugin extends Plugin {
 private SharedPreferences prefs; private byte[] unlockedKey; private JSONObject values; private boolean promptActive=false;
 private static final String DEVICE="ihlink.vault.device.v1",BIO="ihlink.vault.biometric.v1";
 @Override public void load(){prefs=getContext().getSharedPreferences("ihlink_native_vault",0);}
 private byte[] random(int n){byte[] b=new byte[n];new SecureRandom().nextBytes(b);return b;}
 private String b64(byte[] b){return Base64.encodeToString(b,Base64.NO_WRAP);}
 private byte[] un64(String s){return Base64.decode(s,Base64.NO_WRAP);}
 private SecretKey deviceKey(String alias,boolean bio)throws Exception{
  KeyStore store=KeyStore.getInstance("AndroidKeyStore");store.load(null);
  if(!store.containsAlias(alias)){
   KeyGenerator gen=KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore");
   KeyGenParameterSpec.Builder builder=new KeyGenParameterSpec.Builder(alias,KeyProperties.PURPOSE_ENCRYPT|KeyProperties.PURPOSE_DECRYPT).setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE);
   if(bio){builder.setUserAuthenticationRequired(true).setInvalidatedByBiometricEnrollment(true);if(android.os.Build.VERSION.SDK_INT>=30)builder.setUserAuthenticationParameters(0,KeyProperties.AUTH_BIOMETRIC_STRONG);else builder.setUserAuthenticationValidityDurationSeconds(-1);}
   gen.init(builder.build());gen.generateKey();
  }
  return (SecretKey)store.getKey(alias,null);
 }
 private String encrypt(byte[] data,SecretKey key)throws Exception{Cipher c=Cipher.getInstance("AES/GCM/NoPadding");c.init(Cipher.ENCRYPT_MODE,key);return b64(c.getIV())+":"+b64(c.doFinal(data));}
 private byte[] decrypt(String data,SecretKey key)throws Exception{String[] x=data.split(":",2);Cipher c=Cipher.getInstance("AES/GCM/NoPadding");c.init(Cipher.DECRYPT_MODE,key,new GCMParameterSpec(128,un64(x[0])));return c.doFinal(un64(x[1]));}
 private byte[] derive(String pin,byte[] salt)throws Exception{PBEKeySpec p=new PBEKeySpec(pin.toCharArray(),salt,310000,256);try{return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(p).getEncoded();}finally{p.clearPassword();}}
 private boolean enabled(){return prefs.contains("salt");}
 private void clearMemory(){if(unlockedKey!=null)Arrays.fill(unlockedKey,(byte)0);unlockedKey=null;values=null;}
 private void requireUnlocked()throws Exception{if(values==null){if(enabled())throw new Exception("Unlock required");String payload=prefs.getString("payload",null);values=payload==null?new JSONObject():new JSONObject(new String(decrypt(payload,deviceKey(DEVICE,false)),StandardCharsets.UTF_8));}}
 private void persist()throws Exception{byte[] plain=values.toString().getBytes(StandardCharsets.UTF_8);String payload=enabled()?encrypt(plain,new SecretKeySpec(unlockedKey,"AES")):new String(plain,StandardCharsets.UTF_8);if(enabled())payload=encrypt(payload.getBytes(StandardCharsets.UTF_8),deviceKey(DEVICE,false));else payload=encrypt(plain,deviceKey(DEVICE,false));if(!prefs.edit().putString("payload",payload).commit())throw new Exception("Storage unavailable");}
 private JSONObject unlockWithKey(byte[] key)throws Exception{String wrapped=new String(decrypt(prefs.getString("payload",""),deviceKey(DEVICE,false)),StandardCharsets.UTF_8);return new JSONObject(new String(decrypt(wrapped,new SecretKeySpec(key,"AES")),StandardCharsets.UTF_8));}
 private boolean biometricAvailable(){return BiometricManager.from(getContext()).canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)==BiometricManager.BIOMETRIC_SUCCESS;}
 @PluginMethod public void status(PluginCall call){JSObject r=new JSObject();r.put("enabled",enabled());r.put("locked",enabled()&&values==null);r.put("biometricEnabled",prefs.contains("biometric"));r.put("biometricAvailable",biometricAvailable());call.resolve(r);}
 @PluginMethod public void getItem(PluginCall call){try{requireUnlocked();JSObject r=new JSObject();r.put("value",values.optString(call.getString("key"),null));call.resolve(r);}catch(Exception e){call.reject("Unlock the app to continue");}}
 @PluginMethod public void setItem(PluginCall call){try{requireUnlocked();String key=call.getString("key"),value=call.getString("value");if(key==null||value==null)throw new Exception();values.put(key,value);persist();call.resolve();}catch(Exception e){call.reject("Secure storage unavailable");}}
 @PluginMethod public void removeItem(PluginCall call){try{requireUnlocked();values.remove(call.getString("key"));persist();call.resolve();}catch(Exception e){call.reject("Secure storage unavailable");}}
 @PluginMethod public void unlock(PluginCall call){getBridge().execute(()->{try{
  if(!enabled())throw new Exception();String pin=call.getString("pin","");if(!pin.matches("[0-9]{6}"))throw new Exception();
  byte[] candidate=derive(pin,un64(prefs.getString("salt","")));JSONObject data;
  try{data=unlockWithKey(candidate);}catch(Exception wrong){Arrays.fill(candidate,(byte)0);int failures=prefs.getInt("failures",0)+1;if(failures>=5){reset();call.reject("Sign in again to restore app access","RESET");return;}prefs.edit().putInt("failures",failures).commit();call.reject("Incorrect passcode. Please try again");return;}
  clearMemory();unlockedKey=candidate;values=data;prefs.edit().putInt("failures",0).commit();call.resolve();
 }catch(Exception e){call.reject("App access could not be restored. Sign in again");}});}
 @PluginMethod public void configure(PluginCall call){getBridge().execute(()->{try{
  requireUnlocked();String pin=call.getString("pin","");if(!pin.matches("[0-9]{6}")){call.reject("Enter a six digit passcode");return;}
  if(enabled()){byte[] current=derive(call.getString("currentPin",""),un64(prefs.getString("salt","")));try{unlockWithKey(current);}finally{Arrays.fill(current,(byte)0);}}
  byte[] salt=random(32),key=derive(pin,salt);JSONObject oldValues=values;clearMemory();values=oldValues;unlockedKey=key;prefs.edit().putString("salt",b64(salt)).remove("biometric").putInt("failures",0).commit();persist();deleteBiometricKey();call.resolve();
 }catch(Exception e){call.reject("Check your current passcode and try again");}});}
 private void deleteBiometricKey(){try{KeyStore k=KeyStore.getInstance("AndroidKeyStore");k.load(null);k.deleteEntry(BIO);}catch(Exception ignored){}}
 private void reset(){clearMemory();prefs.edit().clear().commit();deleteBiometricKey();}
 @PluginMethod public void reset(PluginCall call){reset();call.resolve();}
 @PluginMethod public void lock(PluginCall call){clearMemory();call.resolve();}
 @Override protected void handleOnPause(){clearMemory();}
 @PluginMethod public void disableBiometric(PluginCall call){prefs.edit().remove("biometric").commit();deleteBiometricKey();call.resolve();}
 @PluginMethod public void biometric(PluginCall call){getActivity().runOnUiThread(()->{try{
  boolean enabling=Boolean.TRUE.equals(call.getBoolean("enable",false));if(!enabled()||!biometricAvailable()||(enabling&&unlockedKey==null))throw new Exception();
  Cipher cipher=Cipher.getInstance("AES/GCM/NoPadding");
  if(enabling)cipher.init(Cipher.ENCRYPT_MODE,deviceKey(BIO,true));else{String saved=prefs.getString("biometric","");String[] parts=saved.split(":",2);cipher.init(Cipher.DECRYPT_MODE,deviceKey(BIO,true),new GCMParameterSpec(128,un64(parts[0])));}
  final byte[] enrollingKey=enabling?unlockedKey.clone():null;
  promptActive=true;
  BiometricPrompt prompt=new BiometricPrompt(getActivity(),ContextCompat.getMainExecutor(getContext()),new BiometricPrompt.AuthenticationCallback(){
   @Override public void onAuthenticationError(int code,CharSequence message){promptActive=false;if(enrollingKey!=null)Arrays.fill(enrollingKey,(byte)0);call.reject("Fingerprint authentication was cancelled or unavailable");}
   @Override public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result){promptActive=false;try{Cipher verified=result.getCryptoObject().getCipher();if(enabling){String saved=b64(verified.getIV())+":"+b64(verified.doFinal(enrollingKey));prefs.edit().putString("biometric",saved).commit();if(unlockedKey==null){values=unlockWithKey(enrollingKey);unlockedKey=enrollingKey.clone();}}else{String saved=prefs.getString("biometric","");byte[] key=verified.doFinal(un64(saved.split(":",2)[1]));JSONObject data=unlockWithKey(key);clearMemory();unlockedKey=key;values=data;prefs.edit().putInt("failures",0).commit();}call.resolve();}catch(Exception e){call.reject("Use your app passcode to continue");}finally{if(enrollingKey!=null)Arrays.fill(enrollingKey,(byte)0);}}
  });
  BiometricPrompt.PromptInfo info=new BiometricPrompt.PromptInfo.Builder().setTitle(enabling?"Enable IHLink fingerprint access":"Unlock IHLink SchoolPro").setSubtitle("Confirm your identity on this device").setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG).setNegativeButtonText("Use passcode").build();prompt.authenticate(info,new BiometricPrompt.CryptoObject(cipher));
 }catch(Exception e){promptActive=false;call.reject("Fingerprint unavailable. Use your app passcode");}});}
}
