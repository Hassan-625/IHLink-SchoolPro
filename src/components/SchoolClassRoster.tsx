import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {fetchSchoolRows} from '@/lib/schoolDataPaging';
import {schoolSessionStudents} from '@/lib/schoolSessionStudents';
import {Card} from '@/components/ui/Card';
export function SchoolClassRoster({schoolId,classId,session}:{schoolId:string;classId:string;session:string}){
 const [rows,setRows]=useState<any[]>([]),[error,setError]=useState(''),[loading,setLoading]=useState(false);
 useEffect(()=>{let active=true;setRows([]);setError('');if(!supabase||!schoolId||!classId||!session)return;
 setLoading(true);const db=supabase;void(async()=>{try{
 const pupils=await fetchSchoolRows(db.from('schoolpro_students').select('id,first_name,last_name,admission_number,class_id,class_name,status').eq('school_id',schoolId).order('last_name').order('id'));
 if(pupils.error)throw pupils.error;
 const next=await schoolSessionStudents(schoolId,session,pupils.data||[]);
 if(active)setRows(next.filter(s=>s.class_id===classId));
 }catch{if(active)setError('The class list could not be loaded. Please try again.');}finally{if(active)setLoading(false)}})();
 return()=>{active=false};
 },[schoolId,classId,session]);
 return <Card><h3 className="font-bold">Class pupils · {session}</h3><p className="mt-2 text-sm">Earlier session records stay with their original class after promotion or reassignment.</p>{error&&<p role="alert">{error}</p>}{loading?<p role="status">Loading class pupils…</p>:<div className="school-table-scroll mt-3"><table className="w-full whitespace-nowrap text-left text-sm"><thead><tr><th className="p-3">Admission number</th><th className="p-3">Student</th><th className="p-3">Progress</th></tr></thead><tbody>{rows.map(s=><tr key={s.id} className="border-t"><td className="p-3">{s.admission_number}</td><td className="p-3">{s.first_name} {s.last_name}</td><td className="p-3">{s.status==='graduated'?'Graduated':s.status==='transferred_out'?'Transferred out':s.current_class_id&&s.current_class_id!==s.class_id?'Moved to another class':s.session_status||'Enrolled'}</td></tr>)}</tbody></table>{!rows.length&&<p className="p-3">No pupils enrolled in this class for the selected session.</p>}</div>}</Card>;
}
