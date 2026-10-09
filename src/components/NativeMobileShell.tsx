import {useEffect,useState,type ReactNode} from 'react';
import {useNavigate} from 'react-router-dom';
import {App as NativeApp} from '@capacitor/app';
import {Browser} from '@capacitor/browser';
import {Capacitor,registerPlugin,SystemBars,SystemBarsStyle} from '@capacitor/core';
import {supabase} from '@/lib/supabase';
import {isNativeApp,nativeCallbackCode} from '@/lib/nativeAuth';
const welcomeKey='ihlink.schoolpro.mobile.welcome.v1';
const processed=new Set<string>();
const nativeSystemTheme=registerPlugin<{apply:(options:{light:boolean})=>Promise<void>}>('NativeSystemTheme');
export function NativeMobileShell({children}:{children:ReactNode}){
 const navigate=useNavigate();const [error,setError]=useState('');
 useEffect(()=>{if(!isNativeApp())return;document.documentElement.classList.add('native-app');if(!localStorage.getItem('ihlink-appearance')){localStorage.setItem('ihlink-appearance','dark');document.documentElement.dataset.appearance='dark';}let disposed=false;const listeners:Promise<{remove:()=>Promise<void>}>[]=[];
  const appearance=()=>{const light=document.documentElement.dataset.appearance==='light';void SystemBars.setStyle({style:light?SystemBarsStyle.Light:SystemBarsStyle.Dark}).then(()=>Capacitor.getPlatform()==='android'?nativeSystemTheme.apply({light}):undefined).catch(()=>{});};
  appearance();void SystemBars.show().catch(()=>{});const observer=new MutationObserver(appearance);observer.observe(document.documentElement,{attributes:true,attributeFilter:['data-appearance']});
  listeners.push(NativeApp.addListener('appStateChange',event=>{if(event.isActive){appearance();void SystemBars.show().catch(()=>{});}}));
  async function callback(url:string){const code=nativeCallbackCode(url);if(!code||processed.has(code)||!supabase)return;processed.add(code);if(processed.size>16)processed.delete(processed.values().next().value!);try{const result=await supabase.auth.exchangeCodeForSession(code);if(result.error)throw result.error;if(disposed)return;localStorage.setItem(welcomeKey,'done');const next=sessionStorage.getItem('ih_auth_next');navigate(new URL(url).searchParams.get('flow')==='recovery'?'/auth/update-password':next&&next.startsWith('/schoolpro')?next:'/schoolpro',{replace:true});void Browser.close().catch(()=>{});}catch{if(!disposed)setError('App sign-in could not finish. Return to Sign in and try again.');}}
  listeners.push(NativeApp.addListener('appUrlOpen',event=>{void callback(event.url);}));
  void NativeApp.getLaunchUrl().then(result=>{if(result?.url&&!disposed)void callback(result.url);});
  listeners.push(NativeApp.addListener('backButton',event=>{if(event.canGoBack)window.history.back();else void NativeApp.minimizeApp();}));
  return()=>{disposed=true;observer.disconnect();for(const listener of listeners)void listener.then(h=>h.remove());};
 },[navigate]);
 return <>{error&&<p role="alert" className="m-4 rounded-xl bg-red-50 p-4 text-red-900">{error}</p>}{children}</>;
}
