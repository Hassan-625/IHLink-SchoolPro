import {useEffect} from 'react';
import {Capacitor} from '@capacitor/core';
import {useAuth} from '@/context/AuthContext';
import {NativeVault,securitySupported} from '@/lib/nativeVault';
import {supabase} from '@/lib/supabase';
const product='schoolpro';
export function AppSecurityStatusSync(){
 const {user}=useAuth();
 useEffect(()=>{
  if(!user||!supabase||!securitySupported)return;
  let active=true,revision=0;
  async function sync(){
   const current=++revision;
   try{
    const status=await NativeVault.status();if(!active||current!==revision)return;
    const key=`ihlink.${product}.security-device.v1`;
    let device=localStorage.getItem(key);if(!device){device=crypto.randomUUID();localStorage.setItem(key,device);}
    await supabase!.from('app_device_security_preferences').upsert({user_id:user!.id,product,device_id:device,platform:Capacitor.getPlatform(),passcode_enabled:status.enabled,biometric_enabled:status.enabled&&status.biometricEnabled,updated_at:new Date().toISOString()},{onConflict:'user_id,product,device_id'});
   }catch{/* Device access remains available while offline. Retry on reconnection. */}
  }
  void sync();window.addEventListener('ihlink:security-changed',sync);window.addEventListener('online',sync);
  return()=>{active=false;window.removeEventListener('ihlink:security-changed',sync);window.removeEventListener('online',sync)};
 },[user?.id]);
 return null;
}
