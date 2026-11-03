import {useCallback,useEffect,useState} from 'react';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useAuth} from '@/context/AuthContext';
import {supabase} from '@/lib/supabase';

export function useSchoolSession(){
 const ctx=useSchoolProContext(),{user}=useAuth();
 const key='ihlink-school-session:'+user?.id+':'+ctx.schoolId;
 const [session,setSession]=useState('');
 useEffect(()=>{
  let active=true;
  const load=()=>setSession(ctx.schoolId?localStorage.getItem(key)||'':'');
  load();
  window.addEventListener('ihlink:session-change',load);
  // Preserve an explicit working-session choice. Only bootstrap from the
  // school's current academic period when this user/school has no choice yet.
  if(ctx.schoolId&&!localStorage.getItem(key)&&supabase){
   void supabase.rpc('schoolpro_current_academic_period',{p_school:ctx.schoolId}).then(({data,error})=>{
    if(!active||error)return;
    const current=String(data?.current?.session||'');
    if(!current)return;
    const selected=localStorage.getItem(key)||'';
    if(selected){setSession(selected);return;}
    localStorage.setItem(key,current);
    setSession(current);
   });
  }
  return()=>{active=false;window.removeEventListener('ihlink:session-change',load)};
 },[key,ctx.schoolId]);
 const select=useCallback((value:string)=>{
  if(!ctx.schoolId)return;
  localStorage.setItem(key,value);
  setSession(value);
  window.dispatchEvent(new Event('ihlink:session-change'));
 },[ctx.schoolId,key]);
 return {session,select,schoolId:ctx.schoolId};
}
