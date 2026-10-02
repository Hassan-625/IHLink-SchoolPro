import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {useAuth} from '@/context/AuthContext';
export type SchoolContext={schoolId:string|null;schoolName:string;role:string;loading:boolean;error:string|null};
const empty:SchoolContext={schoolId:null,schoolName:'SchoolPro',role:'User',loading:false,error:null};
export function useSchoolProContext():SchoolContext{
 const {user,profile,loading:authLoading}=useAuth();
 const [state,setState]=useState<SchoolContext>({...empty,loading:true});
 useEffect(()=>{
  let current=true;
  setState({...empty,loading:authLoading||Boolean(user&&supabase)});
  if(authLoading||!supabase||!user)return;
  const db=supabase;
  const commit=(value:SchoolContext)=>{if(current)setState(value)};
  void(async()=>{
   if(profile?.role==='super_admin'){
    const params=new URLSearchParams(window.location.search);const requested=params.get('school_id');if(requested&&/^[0-9a-f-]{36}$/i.test(requested))localStorage.setItem('ihlink_schoolpro_admin_school',requested);const selected=requested||localStorage.getItem('ihlink_schoolpro_admin_school');
    let query=db.from('schoolpro_schools').select('id,name').order('created_at',{ascending:false}).limit(1);
    if(selected)query=db.from('schoolpro_schools').select('id,name').eq('id',selected).limit(1);
    const target=await query.maybeSingle();
    if(target.error)throw target.error;
    commit({schoolId:target.data?.id||null,schoolName:target.data?.name||'SchoolPro — select a school',role:'Super Administrator',loading:false,error:null});return;
   }
   const owned=await db.from('schoolpro_schools').select('id,name').eq('owner_id',user.id).limit(1).maybeSingle();
   if(owned.error)throw owned.error;
   if(owned.data){commit({schoolId:owned.data.id,schoolName:owned.data.name,role:'Proprietor',loading:false,error:null});return}
   const member=await db.from('schoolpro_members').select('school_id,role,schoolpro_schools(name)').eq('user_id',user.id).limit(1).maybeSingle();
   if(member.error)throw member.error;
   if(member.data){const school=member.data.schoolpro_schools as unknown as {name?:string}|null;commit({schoolId:member.data.school_id,schoolName:school?.name||'SchoolPro',role:member.data.role,loading:false,error:null});return}
   const student=await db.from('schoolpro_students').select('school_id,schoolpro_schools(name)').eq('user_id',user.id).limit(1).maybeSingle();
   if(student.error)throw student.error;
   if(student.data){const school=student.data.schoolpro_schools as unknown as {name?:string}|null;commit({schoolId:student.data.school_id,schoolName:school?.name||'SchoolPro',role:'student',loading:false,error:null});return}
   const guardian=await db.from('schoolpro_guardian_links').select('school_id,schoolpro_schools(name)').eq('guardian_user_id',user.id).eq('status','active').limit(1).maybeSingle();
   if(guardian.error)throw guardian.error;
   const school=guardian.data?.schoolpro_schools as unknown as {name?:string}|null;
   commit({...empty,schoolId:guardian.data?.school_id||null,schoolName:school?.name||'SchoolPro',role:guardian.data?'parent':'User'});
  })().catch((e:{message?:string})=>commit({...empty,error:e.message||'School access could not be loaded.'}));
  return()=>{current=false};
 },[user?.id,profile?.role,authLoading]);
 return state;
}
