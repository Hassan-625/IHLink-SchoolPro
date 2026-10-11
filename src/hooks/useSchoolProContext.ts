import {useEffect,useState} from 'react';
import {useLocation} from 'react-router-dom';
import {supabase} from '@/lib/supabase';
import {useAuth} from '@/context/AuthContext';
export type SchoolContext={schoolId:string|null;schoolName:string;role:string;loading:boolean;error:string|null};
const empty:SchoolContext={schoolId:null,schoolName:'SchoolPro',role:'User',loading:false,error:null};
export function useSchoolProContext():SchoolContext{
 const {user,profile,loading:authLoading}=useAuth();const {search}=useLocation();const requested=new URLSearchParams(search).get('school_id');
 const valid=requested&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(requested)?requested:null;
 const storageKey='ihlink_schoolpro_workspace_'+(user?.id||'');const selected=valid||(user?localStorage.getItem(storageKey):null);
 const key=(user?.id||'')+':'+(selected||'');const [revision,setRevision]=useState(0);
 const [state,setState]=useState<SchoolContext&{key:string}>({...empty,key:'',loading:true});
 useEffect(()=>{const refresh=()=>{if(document.visibilityState==='visible')setRevision(v=>v+1);};window.addEventListener('focus',refresh);window.addEventListener('ihlink:school-refresh',refresh);return()=>{window.removeEventListener('focus',refresh);window.removeEventListener('ihlink:school-refresh',refresh);};},[]);
 useEffect(()=>{
  let current=true;setState(previous=>!authLoading&&user&&previous.key===key&&previous.schoolId?previous:{...empty,key,loading:authLoading||Boolean(user&&supabase)});
  if(authLoading||!supabase||!user)return()=>{current=false};
  const db=supabase;const uid=user.id;
  const commit=(value:SchoolContext)=>{if(!current)return;if(value.schoolId)localStorage.setItem(storageKey,value.schoolId);setState({...value,key});};
  void(async()=>{
   if(profile?.role==='super_admin'&&selected){const r=await db.from('schoolpro_schools').select('id,name').eq('id',selected).maybeSingle();if(r.error)throw r.error;if(r.data){commit({schoolId:r.data.id,schoolName:r.data.name,role:'Super Administrator',loading:false,error:null});return;}}
   let oq=db.from('schoolpro_schools').select('id,name').eq('owner_id',uid).order('created_at',{ascending:false}).limit(1);if(selected)oq=oq.eq('id',selected);
   const owned=await oq.maybeSingle();if(owned.error)throw owned.error;if(owned.data){commit({schoolId:owned.data.id,schoolName:owned.data.name,role:'Proprietor',loading:false,error:null});return;}
   let mq=db.from('schoolpro_members').select('school_id,role,schoolpro_schools(name)').eq('user_id',uid).limit(1);if(selected)mq=mq.eq('school_id',selected);
   const member=await mq.maybeSingle();if(member.error)throw member.error;if(member.data){const s=member.data.schoolpro_schools as unknown as {name?:string}|null;commit({schoolId:member.data.school_id,schoolName:s?.name||'SchoolPro',role:member.data.role,loading:false,error:null});return;}
   let sq=db.from('schoolpro_students').select('school_id,schoolpro_schools(name)').eq('user_id',uid).limit(1);if(selected)sq=sq.eq('school_id',selected);
   const student=await sq.maybeSingle();if(student.error)throw student.error;if(student.data){const s=student.data.schoolpro_schools as unknown as {name?:string}|null;commit({schoolId:student.data.school_id,schoolName:s?.name||'SchoolPro',role:'student',loading:false,error:null});return;}
   let gq=db.from('schoolpro_guardian_links').select('school_id,schoolpro_schools(name)').eq('guardian_user_id',uid).eq('status','active').limit(1);if(selected)gq=gq.eq('school_id',selected);
   const guardian=await gq.maybeSingle();if(guardian.error)throw guardian.error;if(guardian.data){const s=guardian.data.schoolpro_schools as unknown as {name?:string}|null;commit({schoolId:guardian.data.school_id,schoolName:s?.name||'SchoolPro',role:'parent',loading:false,error:null});return;}
   if(profile?.role==='super_admin'&&!selected){const r=await db.from('schoolpro_schools').select('id,name').order('created_at',{ascending:false}).limit(1).maybeSingle();if(r.error)throw r.error;commit({schoolId:r.data?.id||null,schoolName:r.data?.name||'SchoolPro',role:'Super Administrator',loading:false,error:null});return;}
   if(selected&&!valid){localStorage.removeItem(storageKey);setRevision(v=>v+1);}
   commit({...empty,error:selected?'This school workspace is not linked to your account.':null});
  })().catch(()=>commit({...empty,error:'School access could not be loaded. Please try again.'}));
  return()=>{current=false};
 },[key,profile?.role,authLoading,revision]);
 return state.key===key?state:{...empty,loading:authLoading||Boolean(user)};
}
