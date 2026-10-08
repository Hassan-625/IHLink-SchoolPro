package com.ihlink.schoolpro;
import android.content.Context;
import android.print.PrintAttributes;
import android.print.PrintManager;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
@CapacitorPlugin(name="NativePrint")
public class NativePrintPlugin extends Plugin {
 private WebView printView;
 @PluginMethod public void print(PluginCall call) {
  final String html=call.getString("html");
  if(html==null||html.length()==0){call.reject("No document to print");return;}
  getActivity().runOnUiThread(()->{
   if(printView!=null){call.reject("A print document is already open");return;}
   printView=new WebView(getActivity());
   printView.getSettings().setJavaScriptEnabled(false);
   printView.setWebViewClient(new WebViewClient(){
    boolean started=false;
    @Override public void onPageFinished(WebView view,String url){
     if(started)return;started=true;
     try{
      PrintManager manager=(PrintManager)getActivity().getSystemService(Context.PRINT_SERVICE);
      if(manager==null)throw new IllegalStateException("Printing unavailable");
      manager.print("SchoolPro Document",view.createPrintDocumentAdapter("SchoolPro Document"),new PrintAttributes.Builder().build());call.resolve();
     }catch(Exception error){call.reject("The print dialog could not be opened");}
     // Print adapter owns rendering after dispatch; release our busy guard.
     printView=null;
    }
   });
   printView.loadDataWithBaseURL("https://localhost/",html,"text/html","UTF-8",null);
  });
 }
}
