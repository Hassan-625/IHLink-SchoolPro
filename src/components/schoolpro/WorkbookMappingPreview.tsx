import {useEffect,useState,type CSSProperties} from 'react';
import ExcelJS from 'exceljs/dist/exceljs.min.js';
import {supabase} from '@/lib/supabase';
type Cell={address:string;text:string;formula:boolean;span:number;rows:number;style:CSSProperties};
const colour=(value:any)=>value?.argb?'#'+String(value.argb).slice(-6):undefined;
export function WorkbookMappingPreview({file,path,sheetName,onSelect}:{file:File|null;path?:string;sheetName:string;onSelect:(address:string)=>void}){
 const [rows,setRows]=useState<Cell[][]>([]),[notice,setNotice]=useState(''),[widths,setWidths]=useState<number[]>([]);
 useEffect(()=>{let current=true;setRows([]);setNotice('');void(async()=>{
  try{const source=file||(path&&supabase?(await supabase.storage.from('school-result-templates').download(path)).data:null);if(!source)return;
   const workbook=new ExcelJS.Workbook();await workbook.xlsx.load(await source.arrayBuffer());const sheet=workbook.getWorksheet(sheetName)||workbook.worksheets[0];if(!sheet)return;
   let lastRow=1,lastColumn=1;sheet.eachRow((row:any)=>row.eachCell((cell:any)=>{if(cell.value!==null){lastRow=Math.max(lastRow,row.number);lastColumn=Math.max(lastColumn,cell.col);}}));
   const count=Math.min(20,lastColumn+1),end=Math.min(60,lastRow+2),merges=new Map<string,{span:number;rows:number}>();
   for(const range of sheet.model.merges||[]){const [first,last]=range.split(':');const a=sheet.getCell(first),b=sheet.getCell(last);merges.set(first,{span:b.col-a.col+1,rows:b.row-a.row+1});}
   const preview:Cell[][]=[];for(let row=1;row<=end;row++){const line:Cell[]=[];for(let col=1;col<=count;col++){
    const cell=sheet.getCell(row,col);if(cell.isMerged&&cell.master.address!==cell.address)continue;
    const merge=merges.get(cell.address),font=cell.font||{},alignment=cell.alignment||{},border=cell.border||{};
    const style:CSSProperties={background:colour((cell.fill as any)?.fgColor),color:colour(font.color),fontFamily:font.name,fontSize:Math.max(9,Number(font.size)||11),fontWeight:font.bold?700:400,fontStyle:font.italic?'italic':'normal',textAlign:alignment.horizontal==='center'?'center':alignment.horizontal==='right'?'right':'left',verticalAlign:alignment.vertical==='top'?'top':'middle',whiteSpace:alignment.wrapText?'pre-wrap':'normal'};
    for(const side of ['Top','Right','Bottom','Left'] as const){const edge=(border as any)[side.toLowerCase()];if(edge?.style)(style as any)['border'+side]=`${edge.style==='thick'?3:edge.style==='medium'?2:1}px solid ${colour(edge.color)||'#111827'}`;}
    line.push({address:cell.address,text:cell.formula?(cell.result==null?'':String(cell.result)):String(cell.text||''),formula:Boolean(cell.formula),span:merge?.span||1,rows:merge?.rows||1,style});
   }preview.push(line);}
   if(current){setRows(preview);setWidths(Array.from({length:count},(_,i)=>Number(sheet.getColumn(i+1).width)||12));}
  }catch{if(current)setNotice('The workbook preview could not be opened. Please try again.');}
 })();return()=>{current=false};},[file,path,sheetName]);
 if(!file&&!path)return null;
 return <section aria-label="Workbook layout"><p className="mb-3 text-sm text-muted">Choose a detail above, then tap an empty cell to place it. Existing text and calculated cells are protected. This view shows the first 60 rows and 20 columns; images remain in your workbook.</p>{notice&&<p role="alert">{notice}</p>}<div className="school-table-scroll rounded-lg border bg-white"><table className="w-full min-w-[640px] table-fixed border-collapse"><colgroup>{widths.map((width,i)=><col key={i} style={{width:width/widths.reduce((a,b)=>a+b,0)*100+'%'}}/>)}</colgroup><tbody>{rows.map((row,i)=><tr key={i}>{row.map(cell=><td key={cell.address} colSpan={cell.span} rowSpan={cell.rows} style={cell.style} className="h-6 border border-slate-100"><button type="button" className="h-full min-h-6 w-full p-1 text-inherit hover:bg-purple-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-purple-500 disabled:cursor-default" disabled={cell.formula||Boolean(cell.text)} aria-label={`${cell.address}${cell.formula?' calculated cell':cell.text?' '+cell.text:' choose this cell'}`} onClick={()=>onSelect(cell.address)}>{cell.text||<span className="text-[9px] text-slate-300">{cell.address}</span>}</button></td>)}</tr>)}</tbody></table></div></section>;
}
