import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {schoolAccessRequest} from '@/lib/schoolAccessCache';

type HouseAccess={allowed:boolean;error:string|null};

export function useSchoolProHouseMasterAccess(){
 const {user,profile}=useAuth();
 const ctx=useSchoolProContext();
 const key='house-master:'+String(user?.id||'')+':'+String(ctx.schoolId||'');
 const [state,setState]=useState<{key:string;value:HouseAccess|null;loading:boolean}>({key:'',value:null,loading:true});
 useEffect(()=>{
  let active=true;
  if(ctx.loading)return()=>{active=false};
  if(profile?.role==='super_admin'){
   setState({key,value:{allowed:true,error:null},loading:false});
   return()=>{active=false};
  }
  if(!supabase||!ctx.schoolId||!user?.id||!['teacher','class_teacher'].includes(ctx.role.toLowerCase())){
   setState({key,value:{allowed:false,error:null},loading:false});
   return()=>{active=false};
  }
  setState({key,value:null,loading:true});
  const db=supabase;
  void schoolAccessRequest(key,async()=>{
   const {data,error}=await db.rpc('schoolpro_house_master_roster',{p_school:ctx.schoolId});
   return {allowed:!error&&Array.isArray(data)&&data.length>0,error:error?.message||null} satisfies HouseAccess;
  }).then(value=>{if(active)setState({key,value,loading:false})});
  return()=>{active=false};
 },[key,ctx.loading,ctx.schoolId,ctx.role,user?.id,profile?.role]);
 return {
  allowed:state.key===key&&state.value?.allowed===true,
  loading:ctx.loading||(state.key!==key||state.loading),
  error:state.key===key?state.value?.error||null:null
 };
}
