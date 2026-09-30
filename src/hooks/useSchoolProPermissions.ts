import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from './useSchoolProContext';
import {studentReadPermissions,parentReadPermissions} from '@/lib/schoolPermissions';
export function useSchoolProPermissions(){
 const {user}=useAuth();const ctx=useSchoolProContext();
 const [state,setState]=useState<{key:string;permissions:string[];loading:boolean;error:string|null}>({key:'',permissions:[],loading:true,error:null});
 const key=String(user?.id||'')+':'+String(ctx.schoolId||'');
 useEffect(()=>{let active=true;setState({key,permissions:[],loading:true,error:null});
  if(ctx.loading)return;
  if(!supabase||!ctx.schoolId){setState({key,permissions:[],loading:false,error:ctx.error});return}
  void supabase.rpc('schoolpro_user_permissions',{p_school:ctx.schoolId}).then(({data,error})=>{if(active)setState({key,permissions:error?[]:(data||[]) as string[],loading:false,error:error?.message||null})});
  return()=>{active=false};
 },[key,ctx.loading,ctx.error]);
 const permissions=state.key===key?state.permissions:[];
 const role=ctx.role.toLowerCase();
 const portalPermissions=ctx.schoolId?(role==='student'?studentReadPermissions:role==='parent'?parentReadPermissions:[]):[];
 return {permissions,portalPermissions,loading:ctx.loading||state.key!==key||state.loading,role:ctx.role,error:state.error,
  can:(p:string|null)=>Boolean(p&&permissions.includes(p)),
  canPortal:(p:string|null)=>Boolean(p&&portalPermissions.includes(p))};
}
