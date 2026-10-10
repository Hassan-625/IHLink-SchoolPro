import ExcelJS from 'exceljs/dist/exceljs.min.js';
import type {Column,Row} from 'exceljs';

type Report = {student:{first_name:string;last_name:string;admission_number:string;class_name:string};results:{subject_id:string;total_score:number|string;assessment_scores?:Record<string,number>;teacher_comment?:string;head_teacher_comment?:string}[]};
export function buildClassResultsWorkbook({schoolName,term,session,reports,subjectNames}:{schoolName:string;term:string;session:string;reports:Report[];subjectNames:Map<string,string>}) {
 const book=new ExcelJS.Workbook();
 book.creator='IHLink SchoolPro';
 const summary=book.addWorksheet('Class Results');
 summary.addRow([schoolName,term,session]);
 summary.addRow(['Admission number','Student','Class','Total','Average (%)','Subjects']);
 for(const [index,report] of reports.entries()){
  const s=report.student;
  const totals=report.results.map(r=>Number(r.total_score));
  if(!totals.length||totals.some(n=>!Number.isFinite(n)||n<0||n>100))throw new Error('Invalid result scores');
  const total=totals.reduce((sum,n)=>sum+n,0),average=total/totals.length;
  summary.addRow([s.admission_number,[s.first_name,s.last_name].join(' '),s.class_name,total,average,totals.length]);
  const title=`${index+1} ${s.admission_number||s.first_name}`.replace(/[\\/?*\[\]:]/g,'-').slice(0,31);
  const sheet=book.addWorksheet(title);
  sheet.addRow([schoolName]);sheet.addRow([[s.first_name,s.last_name].join(' '),s.admission_number,s.class_name]);sheet.addRow([term,session]);
  const keys=[...new Set(report.results.flatMap(r=>Object.keys(r.assessment_scores||{})))];
  const label=(key:string)=>key.replace(/[_-]+/g,' ').replace(/\b\w/g,c=>c.toUpperCase());
  sheet.addRow(['Subject',...keys.map(label),'Total','Teacher comment','Head teacher comment']);
  for(const r of report.results)sheet.addRow([subjectNames.get(r.subject_id)||'Subject',...keys.map(k=>r.assessment_scores?.[k]??''),Number(r.total_score),r.teacher_comment||'',r.head_teacher_comment||'']);
  sheet.addRow(['Average (%)',average]);
  sheet.columns.forEach((c:Column)=>{c.width=20});sheet.getColumn(1).width=28;sheet.getRow(4).font={bold:true};
  sheet.eachRow((row:Row)=>{row.alignment={vertical:'top',wrapText:true}});
  sheet.pageSetup={paperSize:9,orientation:'landscape',fitToPage:true,fitToWidth:1,fitToHeight:1,printArea:`A1:${sheet.getColumn(sheet.columnCount).letter}${sheet.rowCount}`};
 }
 summary.columns.forEach((c:Column)=>{c.width=24});summary.getRow(2).font={bold:true};summary.getColumn(5).numFmt='0.00';summary.views=[{state:'frozen',ySplit:2}];
 summary.pageSetup={paperSize:9,orientation:'landscape',fitToPage:true,fitToWidth:1,fitToHeight:0,printTitlesRow:'1:2'};
 return book;
}
