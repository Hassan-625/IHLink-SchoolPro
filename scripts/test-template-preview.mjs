import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
import ts from 'typescript';
import ExcelJS from 'exceljs/dist/exceljs.min.js';
const source=ts.transpileModule(readFileSync('src/lib/workbookText.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {workbookCellText}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
assert.equal(workbookCellText({value:null,get text(){throw new Error('null getter');}}),'');
let inspected=0;
for(const section of ['Nursery','Primary','Junior-Secondary','Senior-Secondary']){
 const workbook=new ExcelJS.Workbook();await workbook.xlsx.load(readFileSync('public/templates/ihlink-academy/IHLink-Academy-'+section+'-Result.xlsx'));
 workbook.worksheets[0].eachRow(row=>row.eachCell(cell=>{assert.equal(typeof workbookCellText(cell),'string');inspected++;}));
 const formula=workbook.worksheets[0].getCell('Z200');formula.value={formula:'SUM(A1:A2)'};assert.equal(workbookCellText(formula),'');
 console.log(section+' preview cells parsed successfully.');
}
await assert.rejects(new ExcelJS.Workbook().xlsx.load(Buffer.from('This is an HTML error page, not a workbook.')));
console.log(inspected+' sample cells inspected; empty formula results and invalid sources verified.');
