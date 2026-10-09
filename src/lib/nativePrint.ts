import {Capacitor,registerPlugin} from '@capacitor/core';
const NativePrint=registerPlugin<{print(options:{html:string;paperSize?:string;orientation?:string;name?:string}):Promise<void>}>('NativePrint');
export async function printSchoolDocument(options:{paperSize?:string;orientation?:string;name?:string}={}){
 if(Capacitor.getPlatform()!=='android'){const previous=document.title;if(options.name)document.title=options.name;try{window.print();}finally{document.title=previous;}return;}
 const sections=Array.from(document.querySelectorAll('.print-document'));
 if(!sections.length){window.alert('Open a printable document first.');return;}
 // A separate print WebView cannot serve Capacitor's local asset URLs.
 const css=Array.from(document.styleSheets).map(sheet=>{try{return Array.from(sheet.cssRules).map(rule=>rule.cssText).join('\n');}catch{return '';}}).join('\n');
 const styles=`<style>${css}</style>`;
 const clones=sections.map(node=>node.cloneNode(true) as HTMLElement);
 try{for(const section of clones)for(const image of Array.from(section.querySelectorAll<HTMLImageElement>('img'))){const url=new URL(image.src,document.baseURI);if(url.origin!==window.location.origin)continue;const response=await fetch(url.href);if(!response.ok)throw new Error('Image unavailable');const blob=await response.blob();image.src=await new Promise<string>((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(String(reader.result));reader.onerror=()=>reject(new Error('Image unavailable'));reader.readAsDataURL(blob);});}}catch{window.alert('A document image could not be prepared. Please reload the document and try again.');return;}
 const content=clones.map(node=>node.outerHTML).join('');
 const html=`<!doctype html><html><head><meta charset="UTF-8">${styles}<style>body{background:white;color:#111;padding:16px}header.print\\:block{display:block}.overflow-auto,.overflow-x-auto,.school-table-scroll{overflow:visible;max-height:none}table{width:100%;min-width:0!important}th,td{padding:5px}.result-print-page{break-after:page}.result-print-page:last-child{break-after:auto}</style></head><body>${content}</body></html>`;
 try{await NativePrint.print({html,...options});}catch{window.alert('The print dialog could not be opened. Please try again.');}
}
