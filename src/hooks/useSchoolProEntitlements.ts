import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
export function useSchoolProEntitlements(){
 const ctx=useSchoolProContext();
 const [state,setState]=useState<{schoolId:string|null;data:any;loading:boolean;error:string|null}>({schoolId:null,data:null,loading:true,error:null});
 useEffect(()=>{
  let active=true;
  setState({schoolId:ctx.schoolId,data:null,loading:true,error:null});
  if(ctx.loading)return()=>{active=false};
  if(!supabase||!ctx.schoolId){setState({schoolId:ctx.schoolId,data:null,loading:false,error:ctx.error});return()=>{active=false};}
  void supabase.rpc('schoolpro_subscription_entitlements',{p_school:ctx.schoolId}).then(({data,error})=>{
   if(active)setState({schoolId:ctx.schoolId,data:error?null:data,loading:false,error:error?.message||null});
  });
  return()=>{active=false};
 },[ctx.schoolId,ctx.loading,ctx.error]);
 const current=state.schoolId===ctx.schoolId;
 return {entitlements:current?state.data:null,loading:ctx.loading||!current||state.loading,error:current?state.error:null};
}
