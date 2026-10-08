import {customerMessage} from '@/lib/customerMessage';
import {printSchoolDocument} from '@/lib/nativePrint';
import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Button } from '@/components/ui/Button';
import { supabase } from '@/lib/supabase';
import { useSchoolProContext } from '@/hooks/useSchoolProContext';

type Student = { id:string; first_name:string; last_name:string; admission_number:string; class_name:string };
type Result = { id:string; student_id:string; subject_id:string; total_score:number; assessment_scores:Record<string,number>; assessment_scheme_id:string|null };
type Scheme = { id:string; components:{key:string;label:string;maxScore:number}[] };
const grade = (score:number) => score>=80?'A':score>=70?'B':score>=60?'C':score>=50?'D':score>=40?'E':'F';

export function SchoolProClassResultsPrint(){
 const ctx=useSchoolProContext();const [params]=useSearchParams();
 const classId=params.get('class')||'',term=params.get('term')||'',session=params.get('session')||'';
 const [students,setStudents]=useState<Student[]>([]),[results,setResults]=useState<Result[]>([]),[subjects,setSubjects]=useState<Record<string,string>>({}),[schemes,setSchemes]=useState<Record<string,Scheme>>({}),[school,setSchool]=useState<{name:string;address:string|null}|null>(null),[error,setError]=useState(''),[loading,setLoading]=useState(true);
 useEffect(()=>{let live=true;(async()=>{
  if(!supabase||!ctx.schoolId||!classId||!term||!session){if(live){setError('Choose a class, term and session in the broadsheet first.');setLoading(false)}return}
  const db=supabase;setLoading(true);setError('');
  const [cl,sc,st,sub,sch]=await Promise.all([
   db.from('schoolpro_classes').select('id,name,arm').eq('id',classId).eq('school_id',ctx.schoolId).maybeSingle(),
   db.from('schoolpro_schools').select('name,address').eq('id',ctx.schoolId).maybeSingle(),
   db.from('schoolpro_students').select('id,first_name,last_name,admission_number,class_name').eq('school_id',ctx.schoolId).eq('class_id',classId).order('last_name'),
   db.from('schoolpro_subjects').select('id,name').eq('school_id',ctx.schoolId),
   db.from('schoolpro_assessment_schemes').select('id,components').eq('school_id',ctx.schoolId),
  ]);
  const problem=cl.error||sc.error||st.error||sub.error||sch.error;
  if(problem||!cl.data){if(live){setError(customerMessage(problem?.message||'Class not found.'));setLoading(false)}return}
  const group=(st.data||[]) as Student[];
  const authz=await db.rpc('schoolpro_broadsheet',{p_school:ctx.schoolId,p_class:classId,p_term:term,p_session:session});if(authz.error){if(live){setError(customerMessage(authz.error.message));setLoading(false)}return}const chunks=await Promise.all(group.map(s=>db.rpc('schoolpro_printable_result',{p_student:s.id,p_term:term,p_session:session})));const failed=chunks.find(x=>x.error);if(failed?.error){if(live){setError(customerMessage(failed.error.message));setLoading(false)}return}const res={data:chunks.flatMap(x=>x.data||[]),error:null};
  if(!live)return;
  setSchool(sc.data);setStudents(group);setResults(((res?.data||[]) as Result[]).map(r=>({...r,total_score:Number(r.total_score)})));
  setSubjects(Object.fromEntries((sub.data||[]).map(s=>[s.id,s.name])));setSchemes(Object.fromEntries((sch.data||[]).map(s=>[s.id,s as Scheme])));setLoading(false);
 })();return()=>{live=false}},[ctx.schoolId,classId,term,session]);
 const printable=students.filter(s=>results.some(r=>r.student_id===s.id));
 return <main className="min-h-screen bg-slate-100 p-4 text-slate-900 print:bg-white print:p-0">
  <div className="mx-auto mb-4 flex max-w-4xl items-center justify-between print:hidden"><h1 className="text-xl font-bold">Class results · {term} {session}</h1><Button disabled={loading||!!error||!printable.length} onClick={()=>void printSchoolDocument()}>Print class / Save PDF</Button></div>
  {loading&&<p className="text-center">Loading published results…</p>}{error&&<p className="text-center text-red-700">{customerMessage(error)}</p>}{!loading&&!error&&!printable.length&&<p className="text-center">No published results for this class and period.</p>}
  <div className="print-document mx-auto max-w-4xl bg-white">{printable.map(student=>{const rows=results.filter(r=>r.student_id===student.id),average=rows.reduce((sum,r)=>sum+r.total_score,0)/rows.length;return <article key={student.id} className="result-print-page mb-5 bg-white p-8 text-slate-900 shadow print:mb-0 print:shadow-none">
   <header className="border-b-2 border-purple-700 pb-4 text-center"><h2 className="text-2xl font-extrabold">{school?.name||ctx.schoolName}</h2><p>{school?.address}</p><p className="mt-2 font-semibold">{term} report · {session} session</p></header>
   <div className="my-5 grid grid-cols-2 gap-2 text-sm"><p><b>Student:</b> {student.first_name} {student.last_name}</p><p><b>Admission no.:</b> {student.admission_number}</p><p><b>Class:</b> {student.class_name}</p><p><b>Subjects:</b> {rows.length}</p></div>
   <div className="school-table-scroll"><table className="w-full border-collapse text-left text-sm"><thead><tr className="bg-purple-700 text-white"><th className="border p-2">Subject</th><th className="border p-2">Assessment</th><th className="border p-2">Total</th><th className="border p-2">Grade</th></tr></thead><tbody>{rows.map(r=><tr key={r.id}><td className="border p-2">{subjects[r.subject_id]||'Subject'}</td><td className="border p-2">{(schemes[r.assessment_scheme_id||'']?.components||[]).map(c=>`${c.label}: ${r.assessment_scores?.[c.key]??0}/${c.maxScore}`).join(' · ')||'—'}</td><td className="border p-2">{r.total_score}</td><td className="border p-2">{grade(r.total_score)}</td></tr>)}</tbody></table></div>
   <footer className="mt-6 border-t pt-3 text-sm"><b>Average:</b> {average.toFixed(1)}%<span className="float-right">IHLink SchoolPro</span></footer>
  </article>})}</div>
 </main>;
}
