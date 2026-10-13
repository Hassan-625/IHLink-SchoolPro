import {type ReactNode} from "react";
function InlineReport({children}:{children:ReactNode;product?:string;showFooter?:boolean}){return <>{children}</>}
import {schoolFileName} from '@/lib/schoolDownloads';
import {customerMessage} from '@/lib/customerMessage';
import {printSchoolDocument} from '@/lib/nativePrint';
import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { Printer } from "lucide-react";
import { PageShell } from "@/components/PageShell";
import { Button } from "@/components/ui/Button";
import { supabase } from "@/lib/supabase";

type Component={key:string;label:string;maxScore:number};
type Row={subject_id:string;id:string;assessment_scores:Record<string,number>;assessment_scheme_id:string|null;total_score:number;status:string;teacher_comment?:string;head_teacher_comment?:string;subject:{name:string}|null};
type RawRow=Omit<Row,"total_score"> & {total_score:number|string};
type Student={id:string;first_name:string;last_name:string;admission_number:string;class_name:string;school_id:string};
type School={name:string;address:string|null};
const grade=(score:number)=>score>=80?"A":score>=70?"B":score>=60?"C":score>=50?"D":score>=40?"E":"F";

export function SchoolProReportCard({selection,embedded=false,onReady}:{selection?:{student:string;term:string;session:string};embedded?:boolean;onReady?:(id:string,success:boolean)=>void}={}){
 const Wrapper=embedded?InlineReport:PageShell;
 const [ready,setReady]=useState(false);
 const [details,setDetails]=useState<any>(null);const [subjectStats,setSubjectStats]=useState<Record<string,any>>({}); const [images,setImages]=useState<Record<string,string>>({});
 const [params]=useSearchParams(); const [student,setStudent]=useState<Student|null>(null); const [school,setSchool]=useState<School|null>(null); const [rows,setRows]=useState<Row[]>([]); const [components,setComponents]=useState<Component[]>([]); const [error,setError]=useState<string|null>(null); const [access,setAccess]=useState<{allowed:boolean;outstanding:number;reason:string|null}|null>(null);
 const term=selection?.term||params.get("term")||"First Term",session=selection?.session||params.get("session")||"",studentId=selection?.student||params.get("student");
 // @ts-expect-error The RPC response type becomes available after the new database migration is generated.
 useEffect(()=>{let current=true;async function load(){setReady(false);setStudent(null);setSchool(null);setRows([]);setComponents([]);setAccess(null);setDetails(null);setSubjectStats({});setImages({});setError(null);if(!supabase||!studentId)return;const {data:s,error:e}=await supabase.from("schoolpro_students").select("id,first_name,last_name,admission_number,class_name,school_id").eq("id",studentId).maybeSingle();if(!current)return;if(e||!s){setError(customerMessage(e?.message||"Student not found"));return;}setStudent(s as Student);const accessResult=await supabase.rpc("schoolpro_result_access",{target_student:studentId,target_term:term,target_session:session}).maybeSingle();if(!current)return;if(accessResult.error||!accessResult.data){setError("Your report is not available. Please contact your school.");return;}setAccess({allowed:Boolean(accessResult.data.allowed),outstanding:Number(accessResult.data.outstanding),reason:accessResult.data.reason});if(!accessResult.data.allowed)return;const [schoolResult,resultResult]=await Promise.all([supabase.from("schoolpro_schools").select("name,address").eq("id",s.school_id).maybeSingle(),supabase.rpc("schoolpro_printable_result",{p_student:studentId,p_term:term,p_session:session})]);if(!current)return;if(schoolResult.error||resultResult.error){setError("Your report could not be loaded. Please try again.");return;}const rawBase=(resultResult.data||[]) as any[];const subjectIds=[...new Set(rawBase.map(r=>r.subject_id).filter(Boolean))];const subjectMap:Record<string,string>={};if(subjectIds.length){const q=await supabase.from("schoolpro_subjects").select("id,name").in("id",subjectIds);(q.data||[]).forEach(x=>subjectMap[x.id]=x.name);}const rawRows=rawBase.map(r=>({...r,subject:{name:subjectMap[r.subject_id]||"Subject"}})) as unknown as RawRow[];const resultRows=rawRows.map(r=>({...r,total_score:Number(r.total_score),assessment_scores:r.assessment_scores||{}}));setSchool(schoolResult.data as School|null);setRows(resultRows);const schemeId=resultRows[0]?.assessment_scheme_id;if(schemeId){const {data}=await supabase.from("schoolpro_assessment_schemes").select("components").eq("id",schemeId).maybeSingle();if(!current)return;setComponents((data?.components||[]) as Component[]);}const detailResult=await (supabase as any).rpc("schoolpro_report_details",{p_student:studentId,p_term:term,p_session:session});if(!current)return;if(detailResult.error){setError("Full report details could not be loaded. Please try again.");return;}const stats=await (supabase as any).rpc("schoolpro_subject_statistics",{p_student:studentId,p_term:term,p_session:session});if(!current)return;if(stats.error){setError("Subject positions and term history could not be loaded. Please try again.");return;}setSubjectStats(stats.data||{});setDetails(detailResult.data);setStudent({...s,class_name:detailResult.data?.class_name||s.class_name} as Student);setRows(resultRows.map(r=>({...r,subject:{name:detailResult.data?.subject_names?.[(r as any).subject_id]||r.subject?.name||"Subject"}})));const d=detailResult.data||{},paths={logo:d.logo_storage_path,photo:d.photo_storage_path,teacher:d.settings?.form_teacher_signature_path,principal:d.settings?.principal_signature_path};const imageEntries=await Promise.all(Object.entries(paths).filter(([,path])=>path).map(async([key,path])=>{const r=await supabase!.storage.from("school-result-templates").createSignedUrl(String(path),900);return [key,r.data?.signedUrl||""] as const;}));if(current){setImages(Object.fromEntries(imageEntries));setReady(true);}}void load();return()=>{current=false};},[studentId,term,session]);
 useEffect(()=>{if(studentId&&(ready||error||access?.allowed===false))onReady?.(studentId,ready&&!error&&access?.allowed===true)},[studentId,ready,error,access?.allowed,onReady]);
 const display=(value:any)=>value===null||value===undefined||value===""?"":String(value);
 const band=(score:number)=>(details?.grade_scale||[]).find((g:any)=>score>=Number(g.min_score)&&score<=Number(g.max_score));
 const average=useMemo(()=>rows.length?rows.reduce((sum,r)=>sum+r.total_score,0)/rows.length:0,[rows]);
 if(student&&access?.allowed===false)return <Wrapper product="schoolpro" showFooter={false}><div className={embedded?"result-print-wrapper bg-white":"school-report-host min-h-screen bg-surface p-4 md:p-8"}><div className="mx-auto max-w-2xl rounded-2xl border border-amber-200 bg-amber-50 p-8 text-center shadow-float"><h1 className="text-2xl font-black text-amber-900">Report card access paused</h1><p className="mt-2 text-amber-800">{access.reason}</p><p className="mt-4 font-bold text-amber-900">Outstanding balance: {new Intl.NumberFormat("en-NG",{style:"currency",currency:"NGN"}).format(access.outstanding)}</p><p className="mt-2 text-sm text-amber-700">Please contact the school bursary after payment.</p></div></div></Wrapper>;
 return <Wrapper product="schoolpro" showFooter={false}><style>{`
@page {
  size: A4 portrait;
  margin: 5mm;
}

@media print {
  html,
  body {
    width: 100% !important;
    height: auto !important;
    margin: 0 !important;
    padding: 0 !important;
  }

  body {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }

  .school-report-host,
  .result-print-wrapper,
  .print-document {
    background: #fff !important;
    box-shadow: none !important;
  }

  .school-report-host,
  .result-print-wrapper {
    min-height: 0 !important;
    margin: 0 !important;
    padding: 0 !important;
    overflow: visible !important;
  }

  .school-report {
    box-sizing: border-box !important;
    width: 100% !important;
    max-width: none !important;
    min-height: 0 !important;
    height: auto !important;
    margin: 0 !important;
    padding: 2mm !important;
    box-shadow: none !important;
    font-size: 8px !important;
    line-height: 1.08 !important;
    break-after: auto !important;
    page-break-after: auto !important;
  }

  .school-report header {
    padding-bottom: 2px !important;
    border-bottom-width: 2px !important;
  }

  .school-report header > div {
    width: 24px !important;
    height: 24px !important;
    font-size: 11px !important;
  }

  .school-report header img {
    max-height: 24px !important;
    object-fit: contain !important;
  }

  .school-report h1 {
    margin-top: 2px !important;
    font-size: 13px !important;
    line-height: 1.05 !important;
  }

  .school-report h2 {
    margin-top: 2px !important;
    font-size: 8px !important;
    line-height: 1.05 !important;
  }

  .school-report h3 {
    font-size: 7.5px !important;
    line-height: 1.05 !important;
  }

  .school-report p,
  .school-report footer {
    font-size: 6.5px !important;
    line-height: 1.05 !important;
    margin-top: 1px !important;
  }

  .school-report section {
    margin-top: 2px !important;
    margin-bottom: 2px !important;
    font-size: 7px !important;
    line-height: 1.05 !important;
    break-inside: avoid !important;
    page-break-inside: avoid !important;
  }

  .school-report section > div,
  .school-report section.rounded-xl {
    padding: 2px !important;
  }

  .school-report section[aria-label="Student information"] {
    margin: 3px 0 !important;
    grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
    gap: 2px 5px !important;
  }

  .school-report table {
    width: 100% !important;
    table-layout: fixed !important;
    font-size: 6.5px !important;
    line-height: 1 !important;
    border-collapse: collapse !important;
  }

  .school-report td,
  .school-report th {
    padding: 2px !important;
    overflow-wrap: anywhere !important;
  }

  .school-report tr {
    break-inside: avoid !important;
    page-break-inside: avoid !important;
  }

  .school-report section[aria-label="Attendance"] > div {
    grid-template-columns: repeat(4, minmax(0, 1fr)) !important;
    gap: 2px !important;
  }

  .school-report section[aria-label="Behaviour and practical skills"],
  .school-report section[aria-label="Remarks and signatures"] {
    grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
    gap: 3px !important;
  }

  .school-report section[aria-label="Behaviour and practical skills"] td {
    padding: 1px !important;
  }

  .school-report section[aria-label="Remarks and signatures"] img {
    max-height: 20px !important;
    margin-top: 1px !important;
    object-fit: contain !important;
  }

  .school-report footer {
    padding-top: 1px !important;
    margin-top: 2px !important;
  }

  .school-table-scroll,
  .overflow-x-auto {
    overflow: visible !important;
  }

  .school-report button {
    display: none !important;
    }
}`}
</style><div className={embedded?"result-print-wrapper bg-white":"school-report-host min-h-screen bg-surface p-4 md:p-8"}>{!embedded&&<div className="mx-auto mb-4 flex max-w-6xl justify-end"><Button variant="secondary" leftIcon={<Printer className="h-4 w-4"/>} disabled={!student||!rows.length||access?.allowed!==true||!!error} onClick={()=>void printSchoolDocument({name:schoolFileName([school?.name,student?.class_name,student?[student.first_name,student.last_name].join(" "):null,term,session,"Result"],"pdf")})}>Print / Save PDF</Button></div>}<article className={"school-report print-document mx-auto max-w-6xl bg-white p-6 shadow-float md:p-10"+(embedded?" result-print-page":"")}>{error&&<p className="text-rose-600">{customerMessage(error)}</p>}{!studentId&&<p className="text-center text-muted">Open a result to view its report card.</p>}{student&&rows.length>0&&<><header className="grid grid-cols-[56px_minmax(0,1fr)_48px] items-center gap-2 border-b-4 border-purple-600 pb-2 text-center"><div className="flex justify-start">{images.logo?<img src={images.logo} alt="School logo" className="h-12 w-12 object-contain"/>:<div className="grid h-12 w-12 place-items-center rounded-lg bg-purple-700 text-sm font-black text-white">{school?.name?.slice(0,2)||"SP"}</div>}</div><div><h1 className="text-xl font-black leading-tight text-navy-900">{school?.name||"IHLink SchoolPro"}</h1><p className="text-xs text-muted">{school?.address||"Nigeria"}</p><p className="mt-1 text-xs font-bold text-purple-700">{term.toUpperCase()} REPORT • {session} SESSION</p></div><div className="flex justify-end">{images.photo&&<img src={images.photo} alt="Student photograph" className="h-12 w-10 object-cover"/>}</div></header><section aria-label="Student information" className="my-2 grid grid-cols-2 gap-x-3 gap-y-1 text-xs sm:grid-cols-3"><div><b>Student:</b> {student.first_name} {student.last_name}</div><div><b>Gender:</b> {display(details?.gender)}</div><div><b>Admission No:</b> {student.admission_number}</div><div><b>DOB:</b> {display(details?.date_of_birth)}</div><div><b>Class:</b> {student.class_name}</div><div><b>Session / Term:</b> {session} · {term}</div></section><div className="overflow-x-auto"><div className="school-table-scroll"><table className="w-full border-collapse text-sm"><thead><tr className="bg-purple-700 text-white"><th className="border border-purple-500 p-1">Subject</th>{components.map(c=><th key={c.key} className="border border-purple-500 p-3">{c.label}<br/>/ {c.maxScore}</th>)}<th className="border border-purple-500 p-1">Total</th><th className="border border-purple-500 p-1">Subject position</th><th className="border border-purple-500 p-1">Grade</th><th className="border border-purple-500 p-1">Class average</th></tr></thead><tbody>{rows.map(r=><tr key={r.id}><td className="border p-1 font-semibold">{r.subject?.name||"Subject"}</td>{components.map(c=><td key={c.key} className="border p-1">{r.assessment_scores[c.key]??0}</td>)}<td className="border p-1 font-bold">{r.total_score}</td><td className="border p-1">{display(subjectStats[r.subject_id]?.current_position)}</td><td className="border p-1 font-bold">{band(r.total_score)?.label||grade(r.total_score)}</td><td className="border p-1">{display(subjectStats[r.subject_id]?.current_class_average)}</td></tr>)}</tbody></table></div></div>{!rows.length&&<p className="py-8 text-center text-sm text-muted">No result records for this term and session.</p>}<section aria-label="Overall result" className="my-4 grid grid-cols-2 gap-2 rounded-xl border p-3 text-sm sm:grid-cols-4"><div><b>Total:</b> {rows.reduce((sum,r)=>sum+r.total_score,0).toFixed(1)} / {rows.length*100}</div><div><b>Average:</b> {average.toFixed(1)}%</div><div><b>Grade:</b> {band(average)?.label||grade(average)}</div><div><b>Position:</b> {display(details?.rank?.class_position)} / {display(details?.rank?.class_population)}</div></section>
<section aria-label="Attendance" className="my-4 rounded-xl border p-3 text-sm"><h3 className="font-bold">Attendance and term dates</h3><div className="mt-2 grid grid-cols-2 gap-2 sm:grid-cols-4"><span>School days: {display(details?.settings?.class_days)}</span><span>Present: {details?.attendance?.recorded?display(details.attendance.present):''}</span><span>Absent: {details?.attendance?.recorded?display(details.attendance.absent):''}</span><span>Leave: {details?.attendance?.recorded?display(details.attendance.leave):''}</span><span>Term begins: {display(details?.settings?.term_start_date)}</span><span>Term ends: {display(details?.settings?.term_end_date)}</span><span>Next term: {display(details?.settings?.next_term_begins)}</span></div></section>
<section aria-label="Behaviour and practical skills" className="my-4 grid gap-4 sm:grid-cols-2">{['affective','psychomotor'].map(type=><div key={type} className="rounded-xl border p-3"><h3 className="font-bold">{type==='affective'?'Behaviour and attitudes':'Practical skills'}</h3><table className="mt-2 w-full text-sm"><thead><tr><th className="text-left">Area</th><th className="text-right">Rating</th></tr></thead><tbody>{(details?.domains||[]).filter((d:any)=>d.type===type).map((d:any)=><tr key={d.name} className="border-t"><td className="py-1">{d.name}</td><td className="text-right">{display(d.rating)}</td></tr>)}</tbody></table></div>)}</section>
<p className="text-xs text-muted">Rating guide: {((details?.domains||[]).some((d:any)=>/^[A-F]$/.test(String(d.rating)))?"ABCDEF".split("").map((rating,i)=>({rating,description:["Excellent","Very good","Good","Satisfactory","Fair","Needs improvement"][i]})):details?.rating_scale||[]).map((r:any)=>r.rating+' — '+r.description).join('; ')||''}</p>
<section aria-label="Remarks and signatures" className="mt-4 grid gap-4 text-sm sm:grid-cols-2"><div className="rounded-xl border p-3"><h3 className="font-bold">Class teacher’s remark</h3><p className="mt-2">{display(rows.find(r=>r.teacher_comment)?.teacher_comment||details?.settings?.form_master_remark_template)}</p>{images.teacher&&<img src={images.teacher} alt="Class teacher signature" className="mt-3 h-12 max-w-full object-contain"/>}<p className="mt-3 border-t pt-2">Class teacher</p></div><div className="rounded-xl border p-3"><h3 className="font-bold">School head’s remark</h3><p className="mt-2">{display(rows.find(r=>r.head_teacher_comment)?.head_teacher_comment||details?.settings?.principal_remark_template||band(average)?.overall_remark)}</p>{images.principal&&<img src={images.principal} alt="School head signature" className="mt-3 h-12 max-w-full object-contain"/>}<p className="mt-3 border-t pt-2">{display(details?.settings?.principal_name)} · School head</p></div></section><footer className="mt-4 border-t pt-3 text-center text-xs text-muted">Generated by IHLink SchoolPro</footer></>}</article></div></Wrapper>;
}
