import {cachedSchoolAccess,saveSchoolAccess,schoolAccessRequest} from '@/lib/schoolAccessCache';
import {getSchoolMembership} from '@/lib/schoolMembershipCache';
import {useEffect,useState} from 'react';
import {useLocation} from 'react-router-dom';
import {supabase} from '@/lib/supabase';
import {useAuth} from '@/context/AuthContext';
export type SchoolContext={schoolId:string|null;schoolName:string;role:string;loading:boolean;error:string|null};
const empty:SchoolContext={schoolId:null,schoolName:'SchoolPro',role:'User',loading:false,error:null};
export function useSchoolProContext():SchoolContext{
 const {user,profile,loading:authLoading}=useAuth();const {search,pathname}=useLocation();
 const rememberedPortal=user?localStorage.getItem('ihlink_schoolpro_portal_'+user.id):null;
 const sharedPortal=/^\/schoolpro\/(profile|report-card|transcript|receipts|invoices|payments|notifications)(\/|$)/.test(pathname);
 const studentPortal=/^\/schoolpro\/student-(dashboard|results|attendance|fees|timetable|assignments|cbt|library|announcements)(\/|$)/.test(pathname)||(sharedPortal&&rememberedPortal==='student');
 const parentPortal=/^\/schoolpro\/parent-(dashboard|results|attendance|fees|notifications)(\/|$)/.test(pathname)||(sharedPortal&&rememberedPortal==='parent');
 const staffPortal=pathname==='/schoolpro/teacher-dashboard'||(!studentPortal&&!parentPortal&&!/^\/schoolpro\/(proprietor|admin)-dashboard$/.test(pathname)&&rememberedPortal==='staff');
 const ownerPortal=pathname==='/schoolpro/proprietor-dashboard'||pathname==='/schoolpro/admin-dashboard';
 const portalScope=studentPortal?'student':parentPortal?'parent':staffPortal?'staff':ownerPortal?'owner':rememberedPortal==='owner'?'owner':'general';const requested=new URLSearchParams(search).get('school_id');
 const valid=requested&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(requested)?requested:null;
 const storageKey='ihlink_schoolpro_workspace_'+(user?.id||'');const selected=valid||(user?localStorage.getItem(storageKey):null)||(profile?.role==='super_admin'?localStorage.getItem('ihlink_schoolpro_admin_school'):null);
 const key=(user?.id||'')+':'+(selected||'')+':'+portalScope;const [revision,setRevision]=useState(0);
 const [state,setState]=useState<SchoolContext&{key:string}>(()=>{const cached=cachedSchoolAccess<SchoolContext>('context:'+key,true);return cached?{...cached,key}:{...empty,key:'',loading:true}});
 useEffect(()=>{const refresh=()=>setRevision(v=>v+1);window.addEventListener('ihlink:school-refresh',refresh);return()=>window.removeEventListener('ihlink:school-refresh',refresh);},[]);
 useEffect(()=>{
  let current=true;setState(previous=>!authLoading&&user&&previous.key===key&&previous.schoolId?previous:{...empty,key,loading:authLoading||Boolean(user&&supabase)});
  if(authLoading||!supabase||!user)return()=>{current=false};
  const db=supabase;const uid=user.id;
  const commit=(value:SchoolContext)=>{if(!current)return;if(value.schoolId){localStorage.setItem(storageKey,value.schoolId);if(portalScope!=='general')localStorage.setItem('ihlink_schoolpro_portal_'+uid,portalScope);saveSchoolAccess('context:'+uid+':'+value.schoolId+':'+portalScope,value);}saveSchoolAccess('context:'+key,value);setState({...value,key});};
  void schoolAccessRequest<SchoolContext>('context:'+key,async()=>{
   if(profile?.role==='super_admin'&&selected){const r=await db.from('schoolpro_schools').select('id,name').eq('id',selected).maybeSingle();if(r.error)throw r.error;if(r.data){return ({schoolId:r.data.id,schoolName:r.data.name,role:'Super Administrator',loading:false,error:null});}return ({schoolId:null,schoolName:'Select a school',role:'Super Administrator',loading:false,error:'The selected school is unavailable. Choose a school from the Super Admin workspace selector.'});}
   // Platform Super Admin is a global identity, never a school owner/member fallback.
   // Without an explicit workspace selection, do not silently attach it to an owned school.
   if(profile?.role==='super_admin'&&!selected){return ({schoolId:null,schoolName:'Select a school',role:'Super Administrator',loading:false,error:null});}
   // A verified student identity takes precedence on student-only routes, even if
   // another school role or a remembered workspace was previously selected.
   if(studentPortal){
    let studentPortalQuery=db.from('schoolpro_students').select('school_id,schoolpro_schools!schoolpro_students_school_id_fkey(name)').eq('user_id',uid);if(selected)studentPortalQuery=studentPortalQuery.eq('school_id',selected);const studentPortalRecord=await studentPortalQuery.limit(1).maybeSingle();
    if(studentPortalRecord.error)throw studentPortalRecord.error;
    if(studentPortalRecord.data){const school=studentPortalRecord.data.schoolpro_schools as unknown as {name?:string}|null;
     return ({schoolId:studentPortalRecord.data.school_id,schoolName:school?.name||'SchoolPro',role:'student',loading:false,error:null});}
   }
   // Parent portal identity must be backed by an active guardian link; never infer
   // parent access from ownership or staff membership.
   if(parentPortal){
    let parentPortalQuery=db.from('schoolpro_guardian_links').select('school_id,schoolpro_schools!schoolpro_guardian_links_school_id_fkey(name)').eq('guardian_user_id',uid).eq('status','active');if(selected)parentPortalQuery=parentPortalQuery.eq('school_id',selected);const parentRecord=await parentPortalQuery.limit(1).maybeSingle();
    if(parentRecord.error)throw parentRecord.error;
    if(parentRecord.data){const school=parentRecord.data.schoolpro_schools as unknown as {name?:string}|null;
     return ({schoolId:parentRecord.data.school_id,schoolName:school?.name||'SchoolPro',role:'parent',loading:false,error:null});}
   }
   // Staff portal: resolve actual staff membership before any remembered owner
   // workspace; only recognized educator roles can enter the teacher dashboard.
   if(staffPortal){
    const staffRecord=await getSchoolMembership(db,uid,selected);
    if(staffRecord){const school=staffRecord.schoolpro_schools as unknown as {name?:string}|null;
     return ({schoolId:staffRecord.school_id,schoolName:school?.name||'SchoolPro',role:staffRecord.role,loading:false,error:null});}
   }
   let oq=db.from('schoolpro_schools').select('id,name').eq('owner_id',uid).order('created_at',{ascending:false}).limit(1);if(selected)oq=oq.eq('id',selected);
   const owned=await oq.maybeSingle();if(owned.error)throw owned.error;if(owned.data){return ({schoolId:owned.data.id,schoolName:owned.data.name,role:'Proprietor',loading:false,error:null});}
   const member=await getSchoolMembership(db,uid,selected);if(member){const s=member.schoolpro_schools as unknown as {name?:string}|null;return ({schoolId:member.school_id,schoolName:s?.name||'SchoolPro',role:member.role,loading:false,error:null});}
   let sq=db.from('schoolpro_students').select('school_id,schoolpro_schools!schoolpro_students_school_id_fkey(name)').eq('user_id',uid).limit(1);if(selected)sq=sq.eq('school_id',selected);
   const student=await sq.maybeSingle();if(student.error)throw student.error;if(student.data){const s=student.data.schoolpro_schools as unknown as {name?:string}|null;return ({schoolId:student.data.school_id,schoolName:s?.name||'SchoolPro',role:'student',loading:false,error:null});}
   let gq=db.from('schoolpro_guardian_links').select('school_id,schoolpro_schools!schoolpro_guardian_links_school_id_fkey(name)').eq('guardian_user_id',uid).eq('status','active').limit(1);if(selected)gq=gq.eq('school_id',selected);
   const guardian=await gq.maybeSingle();if(guardian.error)throw guardian.error;if(guardian.data){const s=guardian.data.schoolpro_schools as unknown as {name?:string}|null;return ({schoolId:guardian.data.school_id,schoolName:s?.name||'SchoolPro',role:'parent',loading:false,error:null});}
   if(selected&&!valid){localStorage.removeItem(storageKey);setRevision(v=>v+1);}
   return ({...empty,error:selected?'This school workspace is not linked to your account.':null});
  }).then(commit).catch(()=>commit({...empty,error:'School access could not be loaded. Please try again.'}));
  return()=>{current=false};
 },[key,profile?.role,authLoading,revision,studentPortal,parentPortal,staffPortal]);
 const cached=cachedSchoolAccess<SchoolContext>('context:'+key,true);return state.key===key?state:cached?{...cached,loading:false}:{...empty,loading:authLoading||Boolean(user)};
}
