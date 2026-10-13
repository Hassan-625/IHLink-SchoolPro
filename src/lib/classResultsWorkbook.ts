import ExcelJS from 'exceljs/dist/exceljs.min.js';
import type {Cell,Column,Row} from 'exceljs';

type Report = {ranking?:{class_position:number|string;class_average:number|string};student:{first_name:string;last_name:string;admission_number:string;class_name:string};results:{subject_id:string;total_score:number|string;assessment_scores?:Record<string,number>;teacher_comment?:string;head_teacher_comment?:string}[]};
export function buildClassResultsWorkbook({schoolName,term,session,reports,subjectNames,subjectAverageLabel='CLASS SUBJECT AVERAGE'}:{schoolName:string;term:string;session:string;reports:Report[];subjectNames:Map<string,string>;subjectAverageLabel?:string}) {
 const book=new ExcelJS.Workbook();
 book.creator='IHLink SchoolPro';
 const summary=book.addWorksheet('Class Results');
 summary.addRow([schoolName,term,session]);
 const subjectIds=[...new Set(reports.flatMap(report=>report.results.map(result=>result.subject_id)))];
 const subjectLabels=subjectIds.map(id=>subjectNames.get(id)||'Unmapped subject');
 const classAverages=new Map<string,number[]>();const classTotals=new Map<string,number[]>();
 for(const report of reports){
  const scores=report.results.map(result=>Number(result.total_score));
  if(!scores.length||scores.some(score=>!Number.isFinite(score)||score<0||score>100))throw new Error('Invalid result scores');
  const total=scores.reduce((sum,score)=>sum+score,0),average=total/scores.length;
  classTotals.set(report.student.class_name,[...(classTotals.get(report.student.class_name)||[]),total]);
  classAverages.set(report.student.class_name,[...(classAverages.get(report.student.class_name)||[]),average]);
 }
 summary.addRow(['Admission number','Student','Class','Total','Average (%)','Subjects',...subjectLabels,'Class position','Class average (%)']);
 const subjectMarks=new Map<string,number[]>();
 for(const report of reports){
  for(const result of report.results){
   const key=JSON.stringify([report.student.class_name,result.subject_id]);
   const score=Number(result.total_score);
   if(Number.isFinite(score)&&score>=0&&score<=100)subjectMarks.set(key,[...(subjectMarks.get(key)||[]),score]);
  }
 }
 for(const [index,report] of reports.entries()){
  const s=report.student;
  const totals=report.results.map(result=>Number(result.total_score));
  const total=totals.reduce((sum,score)=>sum+score,0),average=total/totals.length;
  const marks=new Map(report.results.map(result=>[result.subject_id,Number(result.total_score)]));
  const classmates=classAverages.get(s.class_name)||[];
  const position=report.ranking?Number(report.ranking.class_position):1+(classTotals.get(s.class_name)||[]).filter(value=>value>total).length;
  const classAverage=report.ranking?Number(report.ranking.class_average):classmates.reduce((sum,value)=>sum+value,0)/classmates.length;
  summary.addRow([s.admission_number,[s.first_name,s.last_name].join(' '),s.class_name,total,average,totals.length,...subjectIds.map(id=>marks.get(id)??''),position,classAverage]);
  const title=`${index+1} ${s.admission_number||s.first_name}`.replace(/[\\/?*\[\]:]/g,'-').slice(0,31);
  const sheet=book.addWorksheet(title);
  sheet.addRow([schoolName]);sheet.addRow([[s.first_name,s.last_name].join(' '),s.admission_number,s.class_name]);sheet.addRow([term,session]);
  const keys=[...new Set(report.results.flatMap(result=>Object.keys(result.assessment_scores||{})))];
  const label=(key:string)=>key.replace(/[_-]+/g,' ').replace(/\b\w/g,c=>c.toUpperCase());
  sheet.addRow(['Subject',...keys.map(label),'Total','Teacher comment','Head teacher comment']);
  for(const result of report.results)sheet.addRow([subjectNames.get(result.subject_id)||'Unmapped subject',...keys.map(key=>result.assessment_scores?.[key]??''),Number(result.total_score),result.teacher_comment||'',result.head_teacher_comment||'']);
  sheet.addRow(['Average (%)',average]);
  sheet.columns.forEach((column:Column)=>{column.width=20});sheet.getColumn(1).width=28;sheet.getRow(4).font={bold:true};
  sheet.eachRow((row:Row)=>{row.alignment={vertical:'top',wrapText:true}});
  sheet.pageSetup={paperSize:9,orientation:'portrait',fitToPage:true,fitToWidth:1,fitToHeight:1,printArea:`A1:${sheet.getColumn(sheet.columnCount).letter}${sheet.rowCount}`};
 }
 for(const className of [...new Set(reports.map(report=>report.student.class_name))]){
  const averages=subjectIds.map(subjectId=>{
   const values=subjectMarks.get(JSON.stringify([className,subjectId]))||[];
   return values.length?values.reduce((sum,value)=>sum+value,0)/values.length:'';
  });
  const row=summary.addRow(['',subjectAverageLabel,className,'','',averages.filter(value=>value!=='').length,...averages,'','']);
  row.font={bold:true};
  row.eachCell((cell:Cell)=>{cell.fill={type:'pattern',pattern:'solid',fgColor:{argb:'FFEAF2F8'}};cell.border={top:{style:'thin',color:{argb:'FF78909C'}}}});
  row.eachCell((cell:Cell,columnNumber:number)=>{if(columnNumber>=7&&columnNumber<7+subjectIds.length&&typeof cell.value==='number')cell.numFmt='0.00'});
 }
 summary.columns.forEach((column:Column)=>{column.width=24});summary.getRow(2).font={bold:true};summary.getColumn(5).numFmt='0.00';summary.views=[{state:'frozen',ySplit:2}];
 for(let column=7;column<7+subjectIds.length;column++)summary.getColumn(column).numFmt='0.00';
 summary.pageSetup={paperSize:9,orientation:'landscape',fitToPage:true,fitToWidth:1,fitToHeight:0,printTitlesRow:'1:2'};
 return book;
}
