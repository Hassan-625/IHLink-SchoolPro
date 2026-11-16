import {useCallback,useEffect,useState} from 'react';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useAuth} from '@/context/AuthContext';
import {supabase} from '@/lib/supabase';

export function useSchoolSession(){
 const ctx=useSchoolProContext(),{user}=useAuth();
 const key='ihlink-school-session:'+user?.id+':'+ctx.schoolId;
 const [stored,setStored]=useState<{key:string;value:string}>({key:'',value:''});
 useEffect(()=>{
  let active=true;
  const load=()=>setStored({key,value:ctx.schoolId?localStorage.getItem(key)||'':''});
  load();
  window.addEventListener('ihlink:session-change',load);
  // Bootstrap only this user's selected school. A late response from a previous
  // workspace is ignored, and an existing explicit choice is never overwritten.
  if(ctx.schoolId&&!localStorage.getItem(key)&&supabase){
   void supabase.rpc('schoolpro_current_academic_period',{p_school:ctx.schoolId}).then(({data,error})=>{
    if(!active||error)return;
    const current=String(data?.current?.session||'');
    if(!current)return;
    const selected=localStorage.getItem(key)||'';
    if(selected){setStored({key,value:selected});return;}
    localStorage.setItem(key,current);
    setStored({key,value:current});
   });
  }
  return()=>{active=false;window.removeEventListener('ihlink:session-change',load)};
 },[key,ctx.schoolId]);
 const select=useCallback((value:string)=>{
  if(!ctx.schoolId||!value)return;
  localStorage.setItem(key,value);
  setStored({key,value});
  window.dispatchEvent(new Event('ihlink:session-change'));
 },[ctx.schoolId,key]);
 // Never expose the previous school's session during a workspace transition.
 const session=stored.key===key?stored.value:'';
 return {session,select,schoolId:ctx.schoolId};
}
