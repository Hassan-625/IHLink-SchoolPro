import {supabase} from '@/lib/supabase';
import {fetchSchoolRows} from '@/lib/schoolDataPaging';
import {getSchoolData} from '@/lib/schoolDataCache';
import {resolveSchoolSessionRoster, type SessionRosterStudent} from '@/lib/schoolSessionRoster';

export async function schoolSessionStudents<T extends SessionRosterStudent>(schoolId:string,session:string,students:T[],userId?:string):Promise<T[]> {
 if(!supabase||!session)return [];
 const history=await getSchoolData('school:'+(userId||'anonymous')+':'+schoolId+':enrollment-history:'+session,()=>fetchSchoolRows(supabase!.from('schoolpro_enrollment_history').select('student_id,class_id,class_name,arm,section,status').eq('school_id',schoolId).eq('session',session).order('student_id')));
 if(history.error)throw new Error('The selected session could not be loaded. Please try again.');
 const rows=history.data||[];
 let schoolHasAnyHistory=rows.length>0;
 if(!schoolHasAnyHistory){
  const known=await getSchoolData('school:'+(userId||'anonymous')+':'+schoolId+':enrollment-history-exists',()=>supabase!.from('schoolpro_enrollment_history').select('student_id').eq('school_id',schoolId).limit(1));
  if(known.error)throw new Error('School enrolments could not be loaded.');
  schoolHasAnyHistory=Boolean(known.data?.length);
 }
 return resolveSchoolSessionRoster(students,rows,schoolHasAnyHistory) as T[];
}
