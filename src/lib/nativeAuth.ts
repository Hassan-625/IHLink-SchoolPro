import {Capacitor} from '@capacitor/core';
import {Browser} from '@capacitor/browser';
export const isNativeApp=()=>Capacitor.isNativePlatform();
export const nativeAuthRedirect='com.ihlink.schoolpro://auth/callback';
export function nativeCallbackCode(value:string):string|null{
 try{const url=new URL(value);if(url.protocol!=='com.ihlink.schoolpro:'||url.hostname!=='auth'||url.pathname!=='/callback')return null;const code=url.searchParams.get('code');return code&&code.length<4096?code:null;}catch{return null;}
}
export async function openNativeOAuth(url:string){const target=new URL(url);if(target.protocol!=='https:')throw new Error('Secure sign-in URL required');await Browser.open({url:target.toString()});}

export const publicAppOrigin="https://ihlink-schoolpro.onrender.com";
export const nativeOAuthEnabled=import.meta.env.VITE_NATIVE_OAUTH_ENABLED==='true';
