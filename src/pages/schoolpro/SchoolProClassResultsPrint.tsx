import {useCallback,useEffect,useState} from 'react';
import {useSearchParams} from 'react-router-dom';
import {Button} from '@/components/ui/Button';
import {supabase} from '@/lib/supabase';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {SchoolProReportCard} from './SchoolProReportCard';
import {printSchoolDocument} from '@/lib/nativePrint';
import {schoolFileName} from '@/lib/schoolDownloads';
export function SchoolProClassResultsPrint(){
 const ctx=useSchoolProContext(),[params]=useSearchParams();const classId=params.get('class')||'',term=params.get('term')||'',session=params.get('session')||'';
 const [ready,setReady]=useState<Record<string,boolean>>({});const reportReady=useCallback((id:string,success:boolean)=>setReady(r=>r[id]===success?r:{...r,[id]:success}),[]);
 const [students,setStudents]=useState<{id:string;class_name:string}[]>([]),[error,setError]=useState(''),[loading,setLoading]=useState(true);
 useEffect(()=>{let current=true;setStudents([]);setReady({});setError('');setLoading(true);if(ctx.loading)return;
 void(async()=>{if(!supabase||!ctx.schoolId||!term||!session)throw Error('Choose a term and session first.');const db=supabase;
 let classes=db.from('schoolpro_classes').select('id').eq('school_id',ctx.schoolId);if(classId&&classId!=='all')classes=classes.eq('id',classId);const cl=await classes;if(cl.error)throw Error('Your classes could not be loaded.');
 const ids=(cl.data||[]).map(c=>c.id);if(!ids.length)throw Error('No authorised classes are available.');
 // Broadsheet permission must be checked separately for every class before loading any batch.
 for(const id of ids){const check=await db.rpc('schoolpro_broadsheet',{p_school:ctx.schoolId,p_class:id,p_term:term,p_session:session});if(check.error)throw Error('You do not have permission to print these class results.');}
 const st=await db.from('schoolpro_students').select('id,class_name').eq('school_id',ctx.schoolId).in('class_id',ids).eq('status','active').order('class_name').order('last_name');if(st.error)throw Error('Students could not be loaded.');
 const printable=[];for(const s of st.data||[]){const r=await db.rpc('schoolpro_printable_result',{p_student:s.id,p_term:term,p_session:session});if(r.error)throw Error('Published reports could not be loaded.');if(r.data?.length)printable.push(s);}
 if(current)setStudents(printable);
 })().catch(e=>{if(current)setError(e.message)}).finally(()=>{if(current)setLoading(false)});return()=>{current=false};},[ctx.schoolId,ctx.loading,classId,term,session]);
 return <main className="min-h-screen bg-slate-100 p-4 print:bg-white print:p-0"><header className="mx-auto mb-4 flex max-w-5xl flex-wrap items-center justify-between gap-3 print:hidden"><h1 className="text-xl font-bold">Full class reports · {term} · {session}</h1><Button disabled={loading||!!error||!students.length||students.some(s=>ready[s.id]!==true)} onClick={()=>void printSchoolDocument({name:schoolFileName([ctx.schoolName,classId==='all'?'All Classes':students[0]?.class_name,term,session,'Full Results'],'pdf')})}>Print / Save PDF</Button></header>{loading&&<p>Loading published reports…</p>}{error&&<p role="alert">{error}</p>}{!loading&&!error&&!students.length&&<p>No published reports in this selection.</p>}<div className="mx-auto max-w-5xl">{students.map(s=><SchoolProReportCard key={s.id} embedded onReady={reportReady} selection={{student:s.id,term,session}}/>)}</div></main>;
}
