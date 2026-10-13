import {supabase} from '@/lib/supabase';
import {fetchSchoolRows} from '@/lib/schoolDataPaging';
import {getSchoolData} from '@/lib/schoolDataCache';
export async function schoolSessionStudents<T extends {id:string;class_id?:string|null;class_name?:string|null}>(schoolId:string,session:string,students:T[],userId?:string):Promise<T[]>{
 const db=supabase;if(!db||!session)return [];
 const history=await getSchoolData('school:'+(userId||'anonymous')+':'+schoolId+':enrollment-history:'+session,()=>fetchSchoolRows(db.from('schoolpro_enrollment_history').select('student_id,class_id,class_name,arm,section,status').eq('school_id',schoolId).eq('session',session).order('student_id')));
 if(history.error)throw new Error('The selected session could not be loaded. Please try again.');
 const rows=history.data||[];
 if(!rows.length){const known=await getSchoolData('school:'+(userId||'anonymous')+':'+schoolId+':enrollment-history-exists',()=>db.from('schoolpro_enrollment_history').select('student_id').eq('school_id',schoolId).limit(1));if(known.error)throw new Error('School enrolments could not be loaded.');return known.data?.length?[]:students;}
 const map=new Map(rows.map((row:any)=>[row.student_id,row]));
 return students.filter(student=>map.has(student.id)).map(student=>{const row:any=map.get(student.id);return {...student,current_class_id:student.class_id,session_status:row.status,class_id:row.class_id,class_name:[row.class_name,row.arm].filter(Boolean).join(' '),class_level:row.section};});
}
