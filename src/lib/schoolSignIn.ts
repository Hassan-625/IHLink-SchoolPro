import {supabase} from '@/lib/supabase';
export async function schoolSignInDestination(userId:string,superAdmin=false,schoolId?:string|null):Promise<string|null>{
 if(!supabase)return null;
 if(superAdmin)return '/schoolpro/admin-dashboard';
 const scope=(query:any,key:string)=>schoolId?query.eq(key,schoolId):query;
 const[owner,member,student,parent]=await Promise.all([
  scope(supabase.from('schoolpro_schools').select('id').eq('owner_id',userId),'id').limit(1).maybeSingle(),
  scope(supabase.from('schoolpro_members').select('role').eq('user_id',userId),'school_id').limit(1).maybeSingle(),
  scope(supabase.from('schoolpro_students').select('id').eq('user_id',userId),'school_id').limit(1).maybeSingle(),
  scope(supabase.from('schoolpro_guardian_links').select('id').eq('guardian_user_id',userId).eq('status','active'),'school_id').limit(1).maybeSingle()]);
 if([owner,member,student,parent].some(r=>r.error))throw new Error('School access could not be checked');
 const role=owner.data?'proprietor':member.data?.role||(student.data?'student':parent.data?'parent':'');
 if(role==='proprietor')return '/schoolpro/proprietor-dashboard';
 if(['teacher','class_teacher'].includes(role))return '/schoolpro/teacher-dashboard';
 if(role==='student')return '/schoolpro/student-dashboard';
 if(role==='parent')return '/schoolpro/parent-dashboard';
 return role?'/schoolpro/admin-dashboard':null;
}
