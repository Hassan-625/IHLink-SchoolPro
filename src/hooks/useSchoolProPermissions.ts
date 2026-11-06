
import {cachedSchoolAccess,schoolAccessRequest} from '@/lib/schoolAccessCache';
import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from './useSchoolProContext';
import {useSchoolProEntitlements} from './useSchoolProEntitlements';
import {permissionPlanFeature} from '@/lib/schoolPermissions';
import {studentReadPermissions,parentReadPermissions} from '@/lib/schoolPermissions';

export function useSchoolProPermissions(){
 const {user,profile}=useAuth();
 const ctx=useSchoolProContext();
 const plan=useSchoolProEntitlements();

 const isPlanAllowed=(permission:string)=>{
  const feature=permissionPlanFeature(permission);
  return !feature||
   profile?.role==='super_admin'||
   (!plan.loading&&!plan.error&&
    plan.entitlements?.active===true&&
    plan.entitlements?.[feature]===true);
 };

 const [state,setState]=useState<{
  key:string;
  permissions:string[];
  loading:boolean;
  error:string|null;
 }>({key:'',permissions:[],loading:true,error:null});

 const key=String(user?.id||'')+':'+String(ctx.schoolId||'')+':'+ctx.role;

 useEffect(()=>{
  let active=true;
  const cached=cachedSchoolAccess<any>('permissions:'+key,true);

  setState(cached
   ?{key,permissions:cached.data||[],loading:false,error:cached.error?.message||null}
   :{key,permissions:[],loading:true,error:null}
  );

  if(ctx.loading)return;

  if(!supabase||!ctx.schoolId){
   setState({key,permissions:[],loading:false,error:ctx.error});
   return;
  }

  // Student and parent portals have fixed, least-privilege read scopes.
  if(['student','parent'].includes(ctx.role.toLowerCase())){
   setState({key,permissions:[],loading:false,error:null});
   return;
  }

  const db=supabase;
  void schoolAccessRequest(
   'permissions:'+key,
   async()=>await db.rpc('schoolpro_user_permissions',{p_school:ctx.schoolId})
  ).then(({data,error})=>{
   if(active){
    setState({
     key,
     permissions:error?[]:(data||[]) as string[],
     loading:false,
     error:error?.message||null
    });
   }
  });

  return()=>{active=false};
 },[key,ctx.loading,ctx.error,ctx.role]);

 const cached=cachedSchoolAccess<any>('permissions:'+key,true);
 const permissions=state.key===key?state.permissions:cached?.data||[];
 const role=ctx.role.toLowerCase();

 const portalPermissions=ctx.schoolId
  ?role==='student'
   ?studentReadPermissions
   :role==='parent'
    ?parentReadPermissions
    :[]
  :[];

 const hasRolePermission=(permission:string|null,portal=false)=>{
  if(!permission)return false;
  if(profile?.role==='super_admin')return true;
  return portal
   ?portalPermissions.includes(permission)
   :permissions.includes(permission);
 };

 const can=(permission:string|null)=>
  Boolean(permission&&hasRolePermission(permission)&&isPlanAllowed(permission));

 const canPortal=(permission:string|null)=>
  Boolean(permission&&hasRolePermission(permission,true)&&isPlanAllowed(permission));

 return {
  permissions,
  portalPermissions,
  loading:ctx.loading||(!['student','parent'].includes(role)&&!cached&&(state.key!==key||state.loading)),
  role:ctx.role,
  error:state.error,
  planLoading:plan.loading,
  planError:plan.error,
  hasRolePermission,
  isPlanAllowed,
  can,
  canPortal
 };
}
