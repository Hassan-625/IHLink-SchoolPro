import {useEffect,useState} from 'react';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useAuth} from '@/context/AuthContext';
export function useSchoolSession(){const ctx=useSchoolProContext(),{user}=useAuth();const key='ihlink-school-session:'+user?.id+':'+ctx.schoolId;const [session,setSession]=useState('');
useEffect(()=>{const load=()=>setSession(ctx.schoolId?localStorage.getItem(key)||'':'');load();window.addEventListener('ihlink:session-change',load);return()=>window.removeEventListener('ihlink:session-change',load)},[key,ctx.schoolId]);
function select(value:string){if(!ctx.schoolId)return;localStorage.setItem(key,value);setSession(value);window.dispatchEvent(new Event('ihlink:session-change'));}
return {session,select,schoolId:ctx.schoolId};}
