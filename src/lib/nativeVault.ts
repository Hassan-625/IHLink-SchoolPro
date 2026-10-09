import {BrowserVault} from './browserVault';
import {Capacitor,registerPlugin} from '@capacitor/core';
export type VaultStatus={enabled:boolean;locked:boolean;biometricEnabled:boolean;biometricAvailable:boolean};
export const androidVault=Capacitor.getPlatform()==='android';
const AndroidVault=registerPlugin<{status():Promise<VaultStatus>;getItem(options:{key:string}):Promise<{value:string|null}>;setItem(options:{key:string;value:string}):Promise<void>;removeItem(options:{key:string}):Promise<void>;configure(options:{pin:string;currentPin?:string}):Promise<void>;unlock(options:{pin:string}):Promise<void>;biometric(options:{enable?:boolean}):Promise<void>;disableBiometric():Promise<void>;lock():Promise<void>;reset():Promise<void>}>('NativeVault');
export const securitySupported=androidVault||(Capacitor.getPlatform()==='web'&&globalThis.isSecureContext===true&&!!globalThis.crypto?.subtle);
export const NativeVault=androidVault?AndroidVault:BrowserVault;
let ready=false;let release:(()=>void)|undefined;let waiting=new Promise<void>(resolve=>{release=resolve;});
export function vaultReady(){ready=true;release?.();}
export function vaultLocked(){if(!ready)return;ready=false;waiting=new Promise<void>(resolve=>{release=resolve;});}
export const nativeAuthStorage={
 async getItem(key:string){await waiting;return (await NativeVault.getItem({key})).value;},
 async setItem(key:string,value:string){await waiting;await NativeVault.setItem({key,value});},
 async removeItem(key:string){await waiting;await NativeVault.removeItem({key});}
};
