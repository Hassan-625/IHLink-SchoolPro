package com.ihlink.schoolpro;
import android.app.Activity;
import android.content.Intent;
import android.util.Base64;
import androidx.activity.result.ActivityResult;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.ActivityCallback;
import java.io.OutputStream;
@CapacitorPlugin(name="NativeFiles")
public class NativeFilesPlugin extends Plugin {
 private byte[] pending;
 @PluginMethod public void save(PluginCall call){
  String name=call.getString("name"),data=call.getString("data"),mime=call.getString("mimeType","application/octet-stream");
  if(pending!=null){call.reject("Finish saving the current file first.");return;}
  if(name==null||name.length()==0||name.length()>220||name.contains("/")||name.contains("\\")||data==null||data.length()>42000000){call.reject("The file could not be prepared.");return;}
  try{pending=Base64.decode(data,Base64.DEFAULT);}catch(Exception e){call.reject("The file could not be prepared.");return;}
  Intent intent=new Intent(Intent.ACTION_CREATE_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType(mime).putExtra(Intent.EXTRA_TITLE,name);
  try{startActivityForResult(call,intent,"fileSelected");}catch(Exception e){pending=null;call.reject("The save dialog could not be opened.");}
 }
 @ActivityCallback private void fileSelected(PluginCall call,ActivityResult result){
  byte[] bytes=pending;pending=null;if(call==null)return;
  if(result.getResultCode()!=Activity.RESULT_OK){JSObject answer=new JSObject();answer.put("saved",false);call.resolve(answer);return;}
  if(bytes==null||result.getData()==null||result.getData().getData()==null){call.reject("The file could not be saved.");return;}
  getBridge().execute(()->{try(OutputStream out=getContext().getContentResolver().openOutputStream(result.getData().getData(),"wt")){
   if(out==null)throw new IllegalStateException();out.write(bytes);out.flush();JSObject answer=new JSObject();answer.put("saved",true);call.resolve(answer);
  }catch(Exception e){call.reject("The file could not be saved. Please try another location.");}});
 }
}
