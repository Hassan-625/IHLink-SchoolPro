import {Capacitor,registerPlugin} from '@capacitor/core';
export const XLSX_MIME='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
const NativeFiles=registerPlugin<{save(options:{name:string;mimeType:string;data:string}):Promise<{saved:boolean}>}>('NativeFiles');
export function schoolFileName(parts:Array<string|null|undefined>,extension:string){
 const name=parts.filter(Boolean).join(' - ').normalize('NFKC').replace(/[\\/:*?"<>|\u0000-\u001f]/g,'-').replace(/\s+/g,' ').replace(/[. ]+$/g,'').slice(0,180)||'SchoolPro document';
 return name+'.'+extension.replace(/[^a-zA-Z0-9]/g,'');
}
export async function saveSchoolFile(blob:Blob,name:string):Promise<boolean>{
 if(Capacitor.getPlatform()==='android'){
  if(blob.size>30*1024*1024)throw new Error('This file is too large to save in the app. Please download it from the website.');
  const data=await new Promise<string>((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(String(reader.result).split(',')[1]);reader.onerror=()=>reject(new Error('The file could not be prepared.'));reader.readAsDataURL(blob);});
  return (await NativeFiles.save({name,mimeType:blob.type||'application/octet-stream',data})).saved;
 }
 const url=URL.createObjectURL(blob),link=document.createElement('a');link.href=url;link.download=name;link.style.display='none';document.body.append(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),60000);return true;
}
export async function downloadSchoolFile(url:string,name:string,mimeType?:string){
 const response=await fetch(url);if(!response.ok)throw new Error('The file could not be downloaded. Please try again.');
 const blob=await response.blob();if(/text\/html/i.test(blob.type)&&!name.endsWith('.html'))throw new Error('The file is unavailable. Please refresh and try again.');
 return saveSchoolFile(mimeType?new Blob([blob],{type:mimeType}):blob,name);
}
