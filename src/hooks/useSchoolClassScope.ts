import {useEffect,useState} from 'react';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from './useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {cachedSchoolAccess,schoolAccessRequest} from '@/lib/schoolAccessCache';
export function useSchoolClassScope(){
 const {user}=useAuth(),ctx=useSchoolProContext(),key='coordinators:'+user?.id+':'+ctx.schoolId;
 const [state,setState]=useState<{key:string;ids:string[];loading:boolean}>({key:'',ids:[],loading:true});
 useEffect(()=>{let active=true;
 if(ctx.loading)return;
 if(!supabase||!ctx.schoolId){setState({key,ids:[],loading:false});return;}
 const cached=cachedSchoolAccess<any>(key,true);setState({key,ids:cached?.data||[],loading:!cached});
 const db=supabase;void schoolAccessRequest(key,async()=>await db.rpc('schoolpro_coordinator_classes',{p_school:ctx.schoolId})).then(r=>{if(active)setState({key,ids:r.error?[]:r.data||[],loading:false});});
 return()=>{active=false};
 },[key,ctx.loading]);
 const cached=cachedSchoolAccess<any>(key,true);
 return {coordinatorClassIds:state.key===key?state.ids:cached?.data||[],loading:ctx.loading||(state.key!==key&&!cached)||state.loading};
}
