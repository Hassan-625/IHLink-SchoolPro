import {useEffect,useState,type ReactNode} from 'react';
import {useNavigate} from 'react-router-dom';
import {App as NativeApp} from '@capacitor/app';
import {Browser} from '@capacitor/browser';
import {Capacitor,registerPlugin,SystemBars,SystemBarsStyle} from '@capacitor/core';
import {useAuth} from '@/context/AuthContext';
import {supabase} from '@/lib/supabase';
import {isNativeApp,nativeCallbackCode} from '@/lib/nativeAuth';
const welcomeKey='ihlink.schoolpro.mobile.welcome.v1';
const processed=new Set<string>();
const nativeSystemTheme=registerPlugin<{apply:(options:{light:boolean})=>Promise<void>}>('NativeSystemTheme');
export function NativeMobileShell({children}:{children:ReactNode}){
 const {user,loading}=useAuth();const navigate=useNavigate();const [welcome,setWelcome]=useState(()=>isNativeApp()&&localStorage.getItem(welcomeKey)!=='done'),[error,setError]=useState('');
 useEffect(()=>{if(!isNativeApp())return;document.documentElement.classList.add('native-app');if(!localStorage.getItem('ihlink-appearance')){localStorage.setItem('ihlink-appearance','dark');document.documentElement.dataset.appearance='dark';}let disposed=false;const listeners:Promise<{remove:()=>Promise<void>}>[]=[];
  const appearance=()=>{const light=document.documentElement.dataset.appearance==='light';void SystemBars.setStyle({style:light?SystemBarsStyle.Light:SystemBarsStyle.Dark}).then(()=>Capacitor.getPlatform()==='android'?nativeSystemTheme.apply({light}):undefined).catch(()=>{});};
  appearance();void SystemBars.show().catch(()=>{});const observer=new MutationObserver(appearance);observer.observe(document.documentElement,{attributes:true,attributeFilter:['data-appearance']});
  listeners.push(NativeApp.addListener('appStateChange',event=>{if(event.isActive){appearance();void SystemBars.show().catch(()=>{});}}));
  async function callback(url:string){const code=nativeCallbackCode(url);if(!code||processed.has(code)||!supabase)return;processed.add(code);if(processed.size>16)processed.delete(processed.values().next().value!);try{const result=await supabase.auth.exchangeCodeForSession(code);if(result.error)throw result.error;if(disposed)return;localStorage.setItem(welcomeKey,'done');setWelcome(false);const next=sessionStorage.getItem('ih_auth_next');navigate(new URL(url).searchParams.get('flow')==='recovery'?'/auth/update-password':next&&next.startsWith('/schoolpro')?next:'/schoolpro',{replace:true});void Browser.close().catch(()=>{});}catch{if(!disposed)setError('App sign-in could not finish. Return to Sign in and try again.');}}
  listeners.push(NativeApp.addListener('appUrlOpen',event=>{void callback(event.url);}));
  void NativeApp.getLaunchUrl().then(result=>{if(result?.url&&!disposed)void callback(result.url);});
  listeners.push(NativeApp.addListener('backButton',event=>{if(event.canGoBack)window.history.back();else void NativeApp.minimizeApp();}));
  return()=>{disposed=true;observer.disconnect();for(const listener of listeners)void listener.then(h=>h.remove());};
 },[navigate]);
 function start(path:string){localStorage.setItem(welcomeKey,'done');setWelcome(false);navigate(path);}
 if(welcome&&!loading&&!user)return <main className="grid min-h-[100dvh] place-items-center bg-emerald-50 px-4 py-8"><section className="w-full max-w-md rounded-3xl bg-white p-6 shadow-lg"><p className="font-bold text-emerald-700">IHLink SchoolPro</p><h1 className="mt-3 text-3xl font-extrabold">Welcome to your school community</h1><p className="mt-4">Explore school management, fees and results. School owners can create a workspace; parents, students and staff should use the account linked by their school.</p><div className="mt-6 grid gap-3"><button type="button" className="min-h-12 rounded-xl bg-emerald-700 px-4 py-3 font-bold text-white" onClick={()=>start('/schoolpro/features')}>Explore SchoolPro</button><button type="button" className="min-h-12 rounded-xl border px-4 py-3 font-bold" onClick={()=>start('/register')}>Register a school · proprietor / director</button><button type="button" className="min-h-12 rounded-xl border px-4 py-3" onClick={()=>start('/schoolpro')}>I already have an account</button></div></section></main>;
 return <>{error&&<p role="alert" className="m-4 rounded-xl bg-red-50 p-4 text-red-900">{error}</p>}{children}</>;
}
