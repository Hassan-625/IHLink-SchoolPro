import {useCallback,useEffect,useRef,useState} from 'react';
import {Link} from 'react-router-dom';
import {useAuth} from '@/context/AuthContext';
import {supabase} from '@/lib/supabase';
const labels:Record<string,string>={submitted:'Awaiting review',reviewing:'Under review',approved:'Approved — workspace pending',provisioning:'Workspace created — activation pending',active:'Ready to use',rejected:'Please contact support'};
type Request={id:string;school_name:string;status:string;school_id:string|null};
export function SchoolProOnboardingStatus(){
 const {user}=useAuth();const announced=useRef('');const [state,setState]=useState<{userId:string;rows:Request[];error:boolean}>({userId:'',rows:[],error:false});const [busy,setBusy]=useState(false);
 const load=useCallback(async()=>{if(!supabase||!user)return;setBusy(true);try{
  await supabase.rpc('claim_schoolpro_onboarding');
  const {data,error}=await supabase.from('schoolpro_onboarding_requests').select('id,school_name,status,school_id').eq('user_id',user.id).order('created_at',{ascending:false}).limit(10);
  setState({userId:user.id,rows:error?[]:data||[],error:Boolean(error)});
  const signature=user.id+':'+(data||[]).filter(r=>r.school_id).map(r=>r.school_id).sort().join(',');if(data?.some(r=>r.school_id)&&signature!==announced.current){announced.current=signature;window.dispatchEvent(new Event('ihlink:school-refresh'));}
 }catch{setState({userId:user.id,rows:[],error:true});}finally{setBusy(false);}},[user?.id]);
 useEffect(()=>{if(!user)return;void load();const refresh=()=>{if(document.visibilityState==='visible')void load();};const timer=window.setInterval(refresh,30000);window.addEventListener('focus',refresh);return()=>{window.clearInterval(timer);window.removeEventListener('focus',refresh);};},[load,user?.id]);
 if(!user||state.userId!==user.id||(!state.error&&!state.rows.length))return null;
 return <section className="app-card rounded-2xl border p-4"><div className="flex items-center justify-between gap-3"><h2 className="font-bold">My school requests</h2><button type="button" disabled={busy} className="min-h-11 text-sm font-semibold" onClick={()=>void load()}>{busy?'Refreshing…':'Refresh'}</button></div>{state.error?<p role="status" className="mt-3 text-sm">Your school request status could not be loaded. Please try again.</p>:state.rows.map(r=><div key={r.id} className="mt-3 rounded-xl border p-3"><h3 className="font-semibold">{r.school_name.trim()}</h3><p className="mt-1 text-sm">{labels[r.status]||'Under review'}</p><p className="mt-1 text-xs text-muted">Reference: {r.id.slice(0,8).toUpperCase()}</p>{r.school_id&&<Link to={`/schoolpro/proprietor-dashboard?school_id=${r.school_id}`} className="mt-3 inline-flex min-h-11 items-center font-semibold">Open school workspace</Link>}</div>)}</section>;
}
