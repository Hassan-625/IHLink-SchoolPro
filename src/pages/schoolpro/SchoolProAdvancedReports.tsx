import {useCallback,useEffect,useMemo,useState} from 'react';
import ExcelJS from 'exceljs/dist/exceljs.min.js';
import {AcademicPeriodSelect} from '@/components/AcademicPeriodSelect';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {useSchoolSession} from '@/hooks/useSchoolSession';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {schoolSections} from './schoolShared';
import {customerMessage} from '@/lib/customerMessage';
import {saveSchoolFile,schoolFileName,XLSX_MIME} from '@/lib/schoolDownloads';

type SchoolClass={id:string;name:string;arm:string|null;level:string|null;archived_at:string|null};
type ReportStudent={student_id:string;admission_number:string;student_name:string;total:number;average:number;subjects:number;class_position:number;scores?:Record<string,number|null>};
type ReportSubject={id:string;name:string};
type ReportData={rows:ReportStudent[];subjects:ReportSubject[]};

const bands=[{label:'0–39',min:0,max:39},{label:'40–49',min:40,max:49},{label:'50–59',min:50,max:59},{label:'60–69',min:60,max:69},{label:'70–79',min:70,max:79},{label:'80–100',min:80,max:100}];

export function SchoolProAdvancedReports(){
 const ctx=useSchoolProContext();
 const {session:workingSession}=useSchoolSession();
 const [classes,setClasses]=useState<SchoolClass[]>([]);
 const [classId,setClassId]=useState('');
 const [term,setTerm]=useState('First Term');
 const [session,setSession]=useState('');
 const [report,setReport]=useState<ReportData|null>(null);
 const [query,setQuery]=useState('');
 const [busy,setBusy]=useState(false);
 const [notice,setNotice]=useState('');
 const [loadedAt,setLoadedAt]=useState('');

 useEffect(()=>{if(workingSession&&!session)setSession(workingSession)},[workingSession,session]);
 const loadClasses=useCallback(async()=>{
  if(!supabase||!ctx.schoolId)return;
  const result=await supabase.from('schoolpro_classes').select('id,name,arm,level,archived_at').eq('school_id',ctx.schoolId).order('name').order('arm');
  if(result.error){setNotice(customerMessage(result.error.message));return}
  const next=(result.data||[]) as SchoolClass[];
  setClasses(next);
  if(!classId&&next.length)setClassId(next.find(c=>!c.archived_at)?.id||next[0].id);
 },[ctx.schoolId,classId]);
 useEffect(()=>{void loadClasses()},[loadClasses]);

 const runReport=useCallback(async()=>{
  if(!supabase||!ctx.schoolId||!classId||!term||!session||busy)return;
  setBusy(true);setNotice('');setReport(null);
  const result=await supabase.rpc('schoolpro_class_review_sheet',{p_school:ctx.schoolId,p_class:classId,p_term:term,p_session:session});
  setBusy(false);
  if(result.error){setNotice(customerMessage(result.error.message));return}
  const data=result.data||{};
  setReport({rows:Array.isArray(data.rows)?data.rows:[],subjects:Array.isArray(data.subjects)?data.subjects:[]});
  setLoadedAt(new Date().toLocaleString());
 },[ctx.schoolId,classId,term,session,busy]);

 const assessed=useMemo(()=>report?.rows.filter(r=>Number(r.subjects)>0)||[],[report]);
 const average=useMemo(()=>assessed.length?assessed.reduce((sum,r)=>sum+Number(r.average||0),0)/assessed.length:0,[assessed]);
 const highest=useMemo(()=>assessed.length?Math.max(...assessed.map(r=>Number(r.average||0))):0,[assessed]);
 const lowest=useMemo(()=>assessed.length?Math.min(...assessed.map(r=>Number(r.average||0))):0,[assessed]);
 const subjectStats=useMemo(()=> (report?.subjects||[]).map(subject=>{
  const values=(report?.rows||[]).map(row=>row.scores?.[subject.id]).filter(v=>v!==null&&v!==undefined&&Number.isFinite(Number(v))).map(Number);
  return {id:subject.id,name:subject.name,count:values.length,average:values.length?values.reduce((a,b)=>a+b,0)/values.length:0,highest:values.length?Math.max(...values):0,lowest:values.length?Math.min(...values):0};
 }).sort((a,b)=>b.average-a.average),[report]);
 const scoreBands=useMemo(()=>bands.map(band=>({...band,count:assessed.filter(r=>Number(r.average)>=band.min&&Number(r.average)<=band.max).length})),[assessed]);
 const visibleRows=useMemo(()=>[...(report?.rows||[])].filter(row=>!query||[row.student_name,row.admission_number].join(' ').toLowerCase().includes(query.toLowerCase())).sort((a,b)=>Number(a.class_position)-Number(b.class_position)),[report,query]);
 const selectedClass=classes.find(c=>c.id===classId);
 const reportLabel=[ctx.schoolName,selectedClass?.name,selectedClass?.arm,term,session,'Advanced Report'].filter(Boolean);

 async function download(){
  if(!report||!selectedClass)return;
  try{
   const book=new ExcelJS.Workbook();
   const summary=book.addWorksheet('Summary');
   summary.addRows([[ctx.schoolName,'Advanced Academic Report'],['Class',[selectedClass.name,selectedClass.arm].filter(Boolean).join(' ')],['Term',term],['Academic session',session],['Students assessed',assessed.length],['Class average',Number(average.toFixed(2))],['Highest average',Number(highest.toFixed(2))],['Lowest average',Number(lowest.toFixed(2))]]);
   summary.addRow([]);
   summary.addRow(['Subject','Students assessed','Average','Highest','Lowest']);
   for(const item of subjectStats)summary.addRow([item.name,item.count,Number(item.average.toFixed(2)),item.highest,item.lowest]);
   summary.getRow(10).font={bold:true};
   summary.columns.forEach((column:any,index:number)=>column.width=index===0?30:20);
   const results=book.addWorksheet('Student Results');
   results.addRow(['Position','Admission number','Student',...report.subjects.map(s=>s.name),'Total','Average','Subjects assessed']);
   for(const row of report.rows)results.addRow([row.class_position||'',row.admission_number,row.student_name,...report.subjects.map(s=>row.scores?.[s.id]??''),row.total,row.average,row.subjects]);
   results.getRow(1).font={bold:true};results.views=[{state:'frozen',ySplit:1,xSplit:3}];
   results.columns.forEach((column:any,index:number)=>{column.width=index===2?30:18});
   const saved=await saveSchoolFile(new Blob([await book.xlsx.writeBuffer()],{type:XLSX_MIME}),schoolFileName(reportLabel,'xlsx'));
   if(!saved)setNotice('Workbook download was cancelled.');
  }catch{setNotice('The advanced report workbook could not be generated. Please try again.')}
 }

 return <ModulePage product="schoolpro" sections={schoolSections} title="Advanced Reports" description="Analyse class and subject performance for a selected academic session and term. Export a detailed Excel workbook for review and record keeping." userName={ctx.schoolName||'SchoolPro'} userRole={ctx.role} metrics={[{label:'Students assessed',value:String(assessed.length)},{label:'Class average',value:report?average.toFixed(1)+'%':'—'},{label:'Subjects',value:String(subjectStats.length)},{label:'Highest average',value:report?highest.toFixed(1)+'%':'—'}]}>
  <Card>
   <div className="grid min-w-0 gap-3 md:grid-cols-2 xl:grid-cols-4">
    <label className="min-w-0 text-sm font-semibold">Class<select aria-label="Report class" value={classId} onChange={e=>setClassId(e.target.value)} className="mt-1 w-full min-w-0 rounded-lg border bg-white p-3 text-sm"><option value="">Select class</option>{classes.map(c=><option key={c.id} value={c.id}>{c.name} {c.arm||''}{c.archived_at?' · Archived':''}</option>)}</select></label>
    <AcademicPeriodSelect kind="term" label="Term" value={term} onChange={e=>setTerm(e.target.value)} updateWorkingSession={false}/>
    <AcademicPeriodSelect kind="session" label="Academic session" value={session} onChange={e=>setSession(e.target.value)}/>
    <div className="flex items-end"><Button className="w-full" disabled={busy||!classId||!term||!session} onClick={()=>void runReport()}>{busy?'Generating…':'Generate report'}</Button></div>
   </div>
   {notice&&<p role="status" className="mt-3 rounded-lg border p-3 text-sm">{notice}</p>}
  </Card>

  {report&&<div className="space-y-5">
   <div className="flex flex-wrap items-center justify-between gap-3"><div><h2 className="font-bold">{[selectedClass?.name,selectedClass?.arm].filter(Boolean).join(' ')} · {term} · {session}</h2><p className="text-xs text-muted">Generated {loadedAt}. Results reflect the selected class and academic period.</p></div><Button variant="secondary" onClick={()=>void download()}>Download Excel report</Button></div>
   <div className="grid min-w-0 gap-4 sm:grid-cols-2 xl:grid-cols-4">
    <Card><p className="text-xs text-muted">Students assessed</p><p className="mt-1 text-2xl font-bold tabular-nums">{assessed.length}</p></Card>
    <Card><p className="text-xs text-muted">Class average</p><p className="mt-1 text-2xl font-bold tabular-nums">{average.toFixed(1)}%</p></Card>
    <Card><p className="text-xs text-muted">Highest average</p><p className="mt-1 text-2xl font-bold tabular-nums">{highest.toFixed(1)}%</p></Card>
    <Card><p className="text-xs text-muted">Lowest average</p><p className="mt-1 text-2xl font-bold tabular-nums">{lowest.toFixed(1)}%</p></Card>
   </div>
   <div className="grid min-w-0 gap-5 xl:grid-cols-2">
    <Card><h3 className="font-bold">Subject performance</h3><p className="mt-1 text-xs text-muted">Average score by subject, based on recorded marks.</p><div className="mt-4 space-y-4">{subjectStats.map(subject=><div key={subject.id}><div className="mb-1 flex flex-wrap justify-between gap-2 text-sm"><span className="font-medium">{subject.name}</span><span className="tabular-nums">{subject.average.toFixed(1)}% · {subject.count} assessed</span></div><div className="h-2 overflow-hidden rounded-full bg-gray-100"><div className="h-full rounded-full bg-blue-600" style={{width:Math.max(0,Math.min(100,subject.average))+'%'}}/></div></div>)}{!subjectStats.length&&<p className="text-sm text-muted">No subject scores are available for this period.</p>}</div></Card>
    <Card><h3 className="font-bold">Average-score distribution</h3><p className="mt-1 text-xs text-muted">Student counts by score band; these are descriptive bands, not grade boundaries.</p><div className="mt-4 space-y-3">{scoreBands.map(band=><div key={band.label} className="grid grid-cols-[64px_1fr_36px] items-center gap-3 text-sm"><span>{band.label}%</span><div className="h-3 overflow-hidden rounded-full bg-gray-100"><div className="h-full rounded-full bg-indigo-500" style={{width:assessed.length?band.count/assessed.length*100+'%':'0%'}}/></div><span className="text-right tabular-nums">{band.count}</span></div>)}</div></Card>
   </div>
   <Card padding="none" className="min-w-0 overflow-hidden">
    <div className="flex flex-wrap items-center justify-between gap-3 border-b p-4"><div><h3 className="font-bold">Student performance register</h3><p className="text-xs text-muted">Search, review and export the full class report above.</p></div><input aria-label="Search report students" type="search" value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search student or admission number" className="min-w-0 max-w-full rounded-lg border p-2 text-sm"/></div>
    <div className="max-h-[65vh] w-full min-w-0 overflow-auto" role="region" aria-label="Advanced report student table; scroll horizontally and vertically to view all columns" tabIndex={0}><table className="w-full min-w-[900px] text-left text-sm"><thead className="sticky top-0 z-10 bg-gray-50"><tr>{['Position','Admission number','Student',...report.subjects.map(s=>s.name),'Total','Average','Subjects'].map(label=><th key={label} className="whitespace-nowrap p-3 text-xs uppercase text-muted">{label}</th>)}</tr></thead><tbody>{visibleRows.map(row=><tr key={row.student_id} className="border-t"><td className="p-3">{row.class_position||'—'}</td><td className="p-3 whitespace-nowrap">{row.admission_number}</td><td className="p-3 whitespace-nowrap font-medium">{row.student_name}</td>{report.subjects.map(subject=><td key={subject.id} className="p-3 tabular-nums">{row.scores?.[subject.id]??'—'}</td>)}<td className="p-3 tabular-nums">{Number(row.total||0).toFixed(1)}</td><td className="p-3 tabular-nums">{Number(row.average||0).toFixed(1)}%</td><td className="p-3 tabular-nums">{row.subjects}</td></tr>)}</tbody></table>{!visibleRows.length&&<p className="p-8 text-center text-sm text-muted">No students match this search.</p>}</div>
   </Card>
  </div>}
 </ModulePage>;
}
