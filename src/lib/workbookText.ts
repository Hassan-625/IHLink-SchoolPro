// ExcelJS can throw from cell.text for styled empty cells in uploaded workbooks.
export function workbookCellText(cell:any):string {
 const value=cell.value;
 if(value===null||value===undefined)return '';
 if(cell.formula)return cell.result===null||cell.result===undefined?'':String(cell.result);
 if(typeof value==='object'){
  if(value.richText)return value.richText.map((part:any)=>part.text||'').join('');
  if('text' in value)return String(value.text??'');
  if('error' in value)return String(value.error??'');
 }
 return String(cell.text??'');
}
