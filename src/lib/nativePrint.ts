import {Capacitor,registerPlugin} from '@capacitor/core';
const NativePrint=registerPlugin<{print(options:{html:string}):Promise<void>}>('NativePrint');
export async function printSchoolDocument(){
 if(Capacitor.getPlatform()!=='android'){window.print();return;}
 const sections=Array.from(document.querySelectorAll('.print-document'));
 if(!sections.length){window.alert('Open a printable document first.');return;}
 const styles=Array.from(document.querySelectorAll('style,link[rel="stylesheet"]')).map(node=>node.outerHTML).join('');
 const content=sections.map(node=>node.outerHTML).join('');
 const html=`<!doctype html><html><head><meta charset="UTF-8">${styles}<style>body{background:white;color:#111;padding:16px}header.print\\:block{display:block}.overflow-auto,.overflow-x-auto,.school-table-scroll{overflow:visible;max-height:none}table{width:100%;min-width:0!important}th,td{padding:5px}.result-print-page{break-after:page}.result-print-page:last-child{break-after:auto}</style></head><body>${content}</body></html>`;
 try{await NativePrint.print({html});}catch{window.alert('The print dialog could not be opened. Please try again.');}
}
