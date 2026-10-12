type Entry={value:unknown;expires:number};const values=new Map<string,Entry>();const pending=new Map<string,Promise<any>>();let generation=0;
export function cachedSchoolAccess<T>(key:string,allowStale=false):T|undefined{const item=values.get(key);return item&&(allowStale||item.expires>Date.now())?item.value as T:undefined;}
export function saveSchoolAccess<T>(key:string,value:T){values.set(key,{value,expires:Date.now()+15000});}
export function schoolAccessRequest<T>(key:string,run:()=>Promise<T>):Promise<T>{const cached=cachedSchoolAccess<T>(key);if(cached!==undefined)return Promise.resolve(cached);const existing=pending.get(key);if(existing)return existing;const started=generation;const request=run().then(value=>{if(started===generation)saveSchoolAccess(key,value);return value}).finally(()=>{if(pending.get(key)===request)pending.delete(key)});pending.set(key,request);return request;}
export function clearSchoolAccess(){generation++;values.clear();pending.clear();}
if(typeof window!=='undefined'){window.addEventListener('ihlink:school-refresh',clearSchoolAccess);window.addEventListener('ihlink:account-change',clearSchoolAccess);}
