// Local browser unlock protects an existing signed-in session. It does not
// replace server authentication or authorize wallet transactions.
const prefix='ihlink.schoolpro.browser.vault.v1.';
const metaKey=prefix+'meta';
const authKey=(key:string)=>prefix+'session.'+key;
const encode=(bytes:ArrayBuffer|Uint8Array)=>btoa(String.fromCharCode(...new Uint8Array(bytes)));
const decode=(value:string)=>Uint8Array.from(atob(value),char=>char.charCodeAt(0));
const random=(size:number)=>crypto.getRandomValues(new Uint8Array(size));
let master:CryptoKey|null=null;
const metadata=()=>JSON.parse(localStorage.getItem(metaKey)||'null');
async function pinKey(pin:string,salt:Uint8Array){
 const material=await crypto.subtle.importKey('raw',new TextEncoder().encode(pin),'PBKDF2',false,['deriveKey']);
 return crypto.subtle.deriveKey({name:'PBKDF2',salt:salt as BufferSource,iterations:600000,hash:'SHA-256'},material,{name:'AES-GCM',length:256},false,['encrypt','decrypt']);
}
async function seal(key:CryptoKey,value:Uint8Array){const iv=random(12);return {iv:encode(iv),data:encode(await crypto.subtle.encrypt({name:'AES-GCM',iv},key,value as BufferSource))};}
async function open(key:CryptoKey,value:any){return crypto.subtle.decrypt({name:'AES-GCM',iv:decode(value.iv)},key,decode(value.data));}
const importMaster=(value:ArrayBuffer)=>crypto.subtle.importKey('raw',value,'AES-GCM',true,['encrypt','decrypt']);
const persist=(value:any)=>localStorage.setItem(metaKey,JSON.stringify(value));
async function biometricAvailable(){try{return !!globalThis.PublicKeyCredential&&await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();}catch{return false;}}
export const BrowserVault={
 async status(){const value=metadata();return {enabled:!!value,locked:!!value&&!master,biometricEnabled:!!value?.biometric,biometricAvailable:await biometricAvailable()};},
 async getItem({key}:{key:string}){if(!metadata())return {value:localStorage.getItem(key)};if(!master)throw Error('Locked');const value=localStorage.getItem(authKey(key));return {value:value?new TextDecoder().decode(await open(master,JSON.parse(value))):null};},
 async setItem({key,value}:{key:string;value:string}){if(!metadata()){localStorage.setItem(key,value);return;}if(!master)throw Error('Locked');localStorage.setItem(authKey(key),JSON.stringify(await seal(master,new TextEncoder().encode(value))));localStorage.removeItem(key);},
 async removeItem({key}:{key:string}){localStorage.removeItem(authKey(key));localStorage.removeItem(key);},
 async configure({pin,currentPin}:{pin:string;currentPin?:string}){
  if(!/^\d{6}$/.test(pin))throw Error('Six digits required');
  const previous=metadata();
  if(previous){if(!currentPin)throw Error('Current passcode required');await this.unlock({pin:currentPin});}
  const nextMaster=master||await crypto.subtle.generateKey({name:'AES-GCM',length:256},true,['encrypt','decrypt']);
  const salt=random(16),wrapped=await seal(await pinKey(pin,salt),new Uint8Array(await crypto.subtle.exportKey('raw',nextMaster)));
  const pending:Array<[string,string]>=[];
  for(const key of Object.keys(localStorage))if(/^sb-.*-auth-token(?:-code-verifier)?$/.test(key))pending.push([key,JSON.stringify(await seal(nextMaster,new TextEncoder().encode(localStorage.getItem(key)||'')))]);
  for(const [key,value]of pending)localStorage.setItem(authKey(key),value);
  persist({salt:encode(salt),wrapped,attempts:0,biometric:previous?.biometric});master=nextMaster;
  for(const [key]of pending)localStorage.removeItem(key);
 },
 async unlock({pin}:{pin:string}){
  const value=metadata();if(!value)return;
  try{const key=await importMaster(await open(await pinKey(pin,decode(value.salt)),value.wrapped));master=key;value.attempts=0;persist(value);}
  catch{value.attempts=(value.attempts||0)+1;if(value.attempts>=5)await this.reset();else persist(value);throw Error('Unable to unlock');}
 },
 async lock(){master=null;},
 async reset(){master=null;for(const key of Object.keys(localStorage))if(key.startsWith(prefix))localStorage.removeItem(key);},
 async disableBiometric(){const value=metadata();if(!value||!master)throw Error('Unlock first');delete value.biometric;persist(value);},
 async biometric({enable=false}:{enable?:boolean}){
  const value=metadata();if(!value)throw Error('Set a passcode first');
  if(enable&&!master)throw Error('Unlock first');
  const salt=enable?random(32):decode(value.biometric?.salt||'');
  let credential:any;
  if(enable){
   credential=await navigator.credentials.create({publicKey:{challenge:random(32),rp:{name:'IHLink SchoolPro'},user:{id:random(32),name:'IHLink SchoolPro device',displayName:'IHLink SchoolPro'},pubKeyCredParams:[{type:'public-key',alg:-7},{type:'public-key',alg:-257}],authenticatorSelection:{authenticatorAttachment:'platform',userVerification:'required',residentKey:'required'},attestation:'none',extensions:{prf:{eval:{first:salt}}} as any}});
   if(!credential)throw Error('Device unlock cancelled');
  }
  const credentialId=enable?credential.rawId:decode(value.biometric?.id||'');
  // Enrollment alone never enables unlock: require an actual PRF result.
  if(!credential?.getClientExtensionResults()?.prf?.results?.first)credential=await navigator.credentials.get({publicKey:{challenge:random(32),allowCredentials:[{type:'public-key',id:credentialId}],userVerification:'required',extensions:{prf:{eval:{first:salt}}} as any}});
  const secret=credential?.getClientExtensionResults()?.prf?.results?.first;
  if(!secret)throw Error('Secure device unlock is not supported by this authenticator');
  const key=await crypto.subtle.importKey('raw',secret,'AES-GCM',false,['encrypt','decrypt']);
  if(enable){value.biometric={id:encode(credentialId),salt:encode(salt),wrapped:await seal(key,new Uint8Array(await crypto.subtle.exportKey('raw',master!)))};persist(value);}
  else{master=await importMaster(await open(key,value.biometric.wrapped));value.attempts=0;persist(value);}
 },
};
