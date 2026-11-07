import {useCallback,useEffect,useMemo,useState} from 'react';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {schoolSections} from './schoolShared';

type Member={id:string;user_id:string;role:string;status:string;employment_status:string;profile?:{first_name:string|null;last_name:string|null;email:string}|null};
type CaseRow={id:string;member_id:string;action_type:string;severity:string;summary:string;details:string|null;status:string;effective_at:string;staff_response:string|null;response_at:string|null;appeal_status:string;appeal_review_note:string|null;closure_note:string|null;created_at:string};

const managers=['proprietor','administrator','hr_officer','super administrator','super_admin'];
const label=(v:string)=>v.replaceAll('_',' ').replace(/^./,x=>x.toUpperCase());

export function SchoolProStaffDiscipline(){
 const ctx=useSchoolProContext(),{user}=useAuth();
 const canManage=managers.includes(ctx.role.toLowerCase().replaceAll(' ','_'))||managers.includes(ctx.role.toLowerCase());
 const [members,setMembers]=useState<Member[]>([]),[cases,setCases]=useState<CaseRow[]>([]);
 const [memberId,setMemberId]=useState(''),[action,setAction]=useState('verbal_warning'),[severity,setSeverity]=useState('moderate'),[summary,setSummary]=useState(''),[details,setDetails]=useState('');
 const [responses,setResponses]=useState<Record<string,string>>({}),[appealNotes,setAppealNotes]=useState<Record<string,string>>({}),[reviewNotes,setReviewNotes]=useState<Record<string,string>>({});
 const [busy,setBusy]=useState(false),[message,setMessage]=useState('');
 const load=useCallback(async()=>{
  if(!supabase||!ctx.schoolId)return;
  const [m,c]=await Promise.all([
   supabase.from('schoolpro_members').select('id,user_id,role,status,employment_status,profile:profiles!schoolpro_members_user_id_fkey(first_name,last_name,email)').eq('school_id',ctx.schoolId).order('created_at'),
   supabase.from('schoolpro_staff_disciplinary_cases').select('id,member_id,action_type,severity,summary,details,status,effective_at,staff_response,response_at,appeal_status,appeal_review_note,closure_note,created_at').eq('school_id',ctx.schoolId).order('created_at',{ascending:false}).limit(200)
  ]);
  if(m.error||c.error){setMessage('Staff disciplinary records could not be loaded.');return;}
  setMembers((m.data||[]) as Member[]);setCases((c.data||[]) as CaseRow[]);
 },[ctx.schoolId]);
 useEffect(()=>{setMembers([]);setCases([]);setMessage('');void load();},[load]);
 const ownMemberIds=useMemo(()=>new Set(members.filter(m=>m.user_id===user?.id).map(m=>m.id)),[members,user?.id]);
 const visibleCases=useMemo(()=>canManage?cases:cases.filter(c=>ownMemberIds.has(c.member_id)),[cases,canManage,ownMemberIds]);
 const memberNames=useMemo(()=>new Map(members.map(m=>[m.id,[m.profile?.first_name,m.profile?.last_name].filter(Boolean).join(' ')||m.profile?.email||m.role])),[members]);
 async function createCase(){
  if(!supabase||!ctx.schoolId||!memberId||!summary.trim()||busy)return;
  setBusy(true);setMessage('');
  const {error}=await supabase.rpc('schoolpro_create_staff_disciplinary_case',{p_school:ctx.schoolId,p_member:memberId,p_action:action,p_severity:severity,p_summary:summary.trim(),p_details:details.trim()||null,p_effective_at:new Date().toISOString()});
  setBusy(false);
  if(error){setMessage(error.message.includes('Only the proprietor')?'Suspension and dismissal must be executed by the proprietor or administrator.': 'The disciplinary action could not be recorded. Check your role and the selected staff member.');return;}
  setSummary('');setDetails('');setMessage('Disciplinary action recorded. Any suspension or dismissal also updated staff access and ended active appointments.');await load();
 }
 async function respond(id:string,appeal:boolean){
  if(!supabase||!responses[id]?.trim()||busy)return;
  setBusy(true);const {error}=await supabase.rpc('schoolpro_submit_staff_disciplinary_response',{p_case:id,p_response:responses[id].trim(),p_appeal:appeal});setBusy(false);
  setMessage(error?'Your response could not be submitted.':'Your response was submitted and recorded in the case history.');if(!error){setResponses(x=>({...x,[id]:''}));await load();}
 }
 async function closeCase(id:string){
  if(!supabase||!reviewNotes[id]?.trim()||busy)return;
  setBusy(true);const {error}=await supabase.rpc('schoolpro_close_staff_disciplinary_case',{p_case:id,p_note:reviewNotes[id].trim()});setBusy(false);
  setMessage(error?'The case could not be closed.':'Case closed with an audit note.');if(!error){setReviewNotes(x=>({...x,[id]:''}));await load();}
 }
 async function reviewAppeal(id:string,decision:'accepted'|'rejected'){
  if(!supabase||!appealNotes[id]?.trim()||busy)return;
  setBusy(true);const {error}=await supabase.rpc('schoolpro_review_staff_appeal',{p_case:id,p_decision:decision,p_note:appealNotes[id].trim()});setBusy(false);
  setMessage(error?'The appeal review could not be saved.':'Appeal review recorded.');if(!error){setAppealNotes(x=>({...x,[id]:''}));await load();}
 }
 return <ModulePage product="schoolpro" sections={schoolSections} title="Staff disciplinary management" description="Record investigations, warnings, performance concerns, suspension, dismissal, staff responses and appeals with an auditable case history." userName={ctx.schoolName} userRole={ctx.role}>
  {canManage&&<Card><h2 className="font-bold">Open a staff case</h2><div className="mt-3 grid gap-3 md:grid-cols-2">
   <label className="text-sm font-semibold">Staff member<select className="mt-1 w-full rounded-xl border p-3" value={memberId} onChange={e=>setMemberId(e.target.value)}><option value="">Select active staff</option>{members.filter(m=>action==='dismissal'?m.employment_status!=='dismissed':m.status==='active').map(m=><option key={m.id} value={m.id}>{memberNames.get(m.id)} · {label(m.role)} · {label(m.employment_status||m.status)}</option>)}</select></label>
   <label className="text-sm font-semibold">Action<select className="mt-1 w-full rounded-xl border p-3" value={action} onChange={e=>setAction(e.target.value)}>{['verbal_warning','written_warning','final_warning','investigation','performance_plan','suspension','dismissal'].map(v=><option key={v} value={v}>{label(v)}</option>)}</select></label>
   <label className="text-sm font-semibold">Severity<select className="mt-1 w-full rounded-xl border p-3" value={severity} onChange={e=>setSeverity(e.target.value)}>{['low','moderate','high','critical'].map(v=><option key={v} value={v}>{label(v)}</option>)}</select></label>
   <label className="text-sm font-semibold md:col-span-2">Case summary<input className="mt-1 w-full rounded-xl border p-3" maxLength={500} value={summary} onChange={e=>setSummary(e.target.value)} placeholder="Brief, factual summary (10–500 characters)"/></label>
   <label className="text-sm font-semibold md:col-span-2">Investigation details and evidence summary<textarea className="mt-1 w-full rounded-xl border p-3" rows={4} maxLength={8000} value={details} onChange={e=>setDetails(e.target.value)} placeholder="Record relevant dates, findings, witnesses and supporting evidence references."/></label>
  </div><p className="mt-2 text-xs text-muted">Suspension and dismissal are restricted to the proprietor or administrator. They revoke operational membership and end active appointments; historical appointment records are retained.</p><Button className="mt-3" disabled={busy||!memberId||summary.trim().length<10} onClick={()=>void createCase()}>{busy?'Saving…':'Record disciplinary action'}</Button></Card>}
  {message&&<p role="status" className="text-sm font-semibold">{message}</p>}
  <div className="grid gap-4">{visibleCases.map(c=><Card key={c.id}>
   <div className="flex flex-wrap items-start justify-between gap-2"><div><h3 className="font-bold">{canManage?memberNames.get(c.member_id)||'Staff member':'My disciplinary case'}</h3><p className="text-xs text-muted">{label(c.action_type)} · {label(c.severity)} · {new Date(c.created_at).toLocaleString()}</p></div><span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold">{label(c.status)}</span></div>
   <p className="mt-3 font-semibold">{c.summary}</p>{c.details&&<p className="mt-2 whitespace-pre-wrap text-sm">{c.details}</p>}
   {c.staff_response&&<div className="mt-3 rounded-lg bg-slate-50 p-3"><b className="text-sm">Staff response</b><p className="mt-1 whitespace-pre-wrap text-sm">{c.staff_response}</p></div>}
   {c.appeal_status!=='not_submitted'&&<div className="mt-3 rounded-lg border p-3"><p className="text-sm font-semibold">Appeal: {label(c.appeal_status)}</p>{c.appeal_review_note&&<p className="mt-1 text-sm">{c.appeal_review_note}</p>}</div>}{c.closure_note&&<p className="mt-2 text-sm"><b>Closure note:</b> {c.closure_note}</p>}
   {!canManage&&c.status!=='closed'&&<div className="mt-3 space-y-2"><label className="block text-sm font-semibold">Your response / appeal<textarea className="mt-1 w-full rounded-xl border p-3" rows={3} value={responses[c.id]||''} onChange={e=>setResponses(x=>({...x,[c.id]:e.target.value}))} placeholder="Provide your response or appeal grounds."/></label><div className="flex flex-wrap gap-2"><Button disabled={busy||!responses[c.id]?.trim()} onClick={()=>void respond(c.id,false)}>Submit response</Button><Button variant="secondary" disabled={busy||!responses[c.id]?.trim()||c.appeal_status==='pending'} onClick={()=>void respond(c.id,true)}>Submit appeal</Button></div></div>}
   {canManage&&c.status!=='closed'&&<div className="mt-3 space-y-2"><label className="block text-sm font-semibold">Case closure note<textarea className="mt-1 w-full rounded-xl border p-3" rows={2} value={reviewNotes[c.id]||''} onChange={e=>setReviewNotes(x=>({...x,[c.id]:e.target.value}))}/></label><Button variant="secondary" disabled={busy||!reviewNotes[c.id]?.trim()} onClick={()=>void closeCase(c.id)}>Close case</Button></div>}
   {canManage&&c.appeal_status==='pending'&&<div className="mt-3 space-y-2"><label className="block text-sm font-semibold">Appeal review note<textarea className="mt-1 w-full rounded-xl border p-3" rows={2} value={appealNotes[c.id]||''} onChange={e=>setAppealNotes(x=>({...x,[c.id]:e.target.value}))}/></label><div className="flex flex-wrap gap-2"><Button disabled={busy||!appealNotes[c.id]?.trim()} onClick={()=>void reviewAppeal(c.id,'accepted')}>Accept appeal</Button><Button variant="secondary" disabled={busy||!appealNotes[c.id]?.trim()} onClick={()=>void reviewAppeal(c.id,'rejected')}>Reject appeal</Button></div></div>}
  </Card>)}</div>
  {!visibleCases.length&&<Card><p className="text-sm text-muted">No disciplinary cases are available for this school or staff account.</p></Card>}
 </ModulePage>;
}
