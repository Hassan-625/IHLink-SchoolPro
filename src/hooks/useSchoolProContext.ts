import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useAuth } from '@/context/AuthContext';

export type SchoolContext = { schoolId:string|null; schoolName:string; role:string; loading:boolean; error:string|null };

export function useSchoolProContext(): SchoolContext {
  const { user } = useAuth();
  const [state,setState]=useState<SchoolContext>({schoolId:null,schoolName:'SchoolPro',role:'User',loading:true,error:null});
  useEffect(()=>{ if(!supabase||!user){setState(s=>({...s,loading:false}));return;} void (async()=>{
    const owned=await supabase.from('schoolpro_schools').select('id,name').eq('owner_id',user.id).maybeSingle();
    if(owned.data){setState({schoolId:owned.data.id,schoolName:owned.data.name,role:'Proprietor',loading:false,error:null});return;}
    const member=await supabase.from('schoolpro_members').select('school_id,role,schoolpro_schools(name)').eq('user_id',user.id).maybeSingle();
    if(member.error){setState(s=>({...s,loading:false,error:member.error?.message||null}));return;}
    const school=member.data?.schoolpro_schools as unknown as {name?:string}|null;
    setState({schoolId:member.data?.school_id||null,schoolName:school?.name||'SchoolPro',role:member.data?.role||'User',loading:false,error:null});
  })(); },[user]);
  return state;
}
