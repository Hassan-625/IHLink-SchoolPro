import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useAuth} from '@/context/AuthContext';
export function useSchoolProEntitlements(){
 const ctx=useSchoolProContext(),{user}=useAuth();
 const key=String(user?.id||'')+':'+String(ctx.schoolId||'');
 const [state,setState]=useState<{key:string;data:any;loading:boolean;error:string|null}>({key:'',data:null,loading:true,error:null});
 useEffect(()=>{
  let active=true,request=0;
  setState({key,data:null,loading:true,error:null});
  if(ctx.loading)return()=>{active=false};
  if(!supabase||!ctx.schoolId||!user){setState({key,data:null,loading:false,error:ctx.error});return()=>{active=false};}
  const db=supabase,school=ctx.schoolId;
  async function refresh(){
   const sequence=++request;
   try{
    const {data,error}=await db.rpc('schoolpro_subscription_entitlements',{p_school:school});
    if(active&&sequence===request)setState({key,data:error?null:data,loading:false,error:error?'School access could not be checked.':null});
   }catch{if(active&&sequence===request)setState({key,data:null,loading:false,error:'School access could not be checked.'});}
  }
  void refresh();
  const onFocus=()=>{void refresh();};
  const interval=window.setInterval(onFocus,30000);
  window.addEventListener('focus',onFocus);
  return()=>{active=false;window.clearInterval(interval);window.removeEventListener('focus',onFocus);};
 },[key,ctx.loading,ctx.error]);
 const current=state.key===key;
 return {entitlements:current?state.data:null,loading:ctx.loading||!current||state.loading,error:current?state.error:null};
}
