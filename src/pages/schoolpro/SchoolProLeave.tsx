import {useCallback,useEffect,useMemo,useState} from 'react';
import {useAuth} from '@/context/AuthContext';
import {useSchoolSession} from '@/hooks/useSchoolSession';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {schoolSections} from './schoolShared';

type Member={id:string;user_id:string;role:string;status:string;profile?:{first_name:string|null;last_name:string|null;email:string}|null};
type LeaveRow={id:string;member_id:string;leave_type:string;request_type:string;start_date:string;end_date:string;reason:string|null;status:string;absence_reported_at:string|null;reason_updated_at:string|null;review_note:string|null;reviewed_at:string|null;created_at:string};

const managerRoles=['proprietor','administrator','hr_officer','super administrator','super_admin'];
const pretty=(v:string)=>v.replaceAll('_',' ').replace(/^./,x=>x.toUpperCase());

export function SchoolProLeave(){
 const {user}=useAuth();const {session}=useSchoolSession();const ctx=useSchoolProContext();
 const canReview=managerRoles.includes(ctx.role.toLowerCase().replaceAll(' ','_'))||managerRoles.includes(ctx.role.toLowerCase());
 const [members,setMembers]=useState<Member[]>([]),[rows,setRows]=useState<LeaveRow[]>([]);
 const [start,setStart]=useState(''),[end,setEnd]=useState(''),[reason,setReason]=useState(''),[kind,setKind]=useState('planned_leave'),[leaveType,setLeaveType]=useState('Annual leave');
 const [reasonDraft,setReasonDraft]=useState<Record<string,string>>({}),[reviewNotes,setReviewNotes]=useState<Record<string,string>>({});
 const [busy,setBusy]=useState(false),[message,setMessage]=useState('');
 const load=useCallback(async()=>{
  if(!supabase||!ctx.schoolId)return;
  const [m,r]=await Promise.all([
   supabase.from('schoolpro_members').select('id,user_id,role,status,profile:profiles!schoolpro_members_user_id_fkey(first_name,last_name,email)').eq('school_id',ctx.schoolId).order('created_at'),
   supabase.from('schoolpro_leave_requests').select('id,member_id,leave_type,request_type,start_date,end_date,reason,status,absence_reported_at,reason_updated_at,review_note,reviewed_at,created_at').eq('school_id',ctx.schoolId).order('created_at',{ascending:false}).limit(250)
  ]);
  if(m.error||r.error){setMessage('Leave and absence records could not be loaded.');return;}
  setMembers((m.data||[]) as Member[]);setRows((r.data||[]) as LeaveRow[]);
 },[ctx.schoolId]);
 useEffect(()=>{setRows([]);setMembers([]);setMessage('');void load();},[load]);
 const ownMembers=useMemo(()=>members.filter(m=>m.user_id===user?.id),[members,user?.id]);
 const ownIds=useMemo(()=>new Set(ownMembers.map(m=>m.id)),[ownMembers]);
 const memberNames=useMemo(()=>new Map(members.map(m=>[m.id,[m.profile?.first_name,m.profile?.last_name].filter(Boolean).join(' ')||m.profile?.email||m.role])),[members]);
 const visible=canReview?rows:rows.filter(r=>ownIds.has(r.member_id));
 async function submit(){
  if(!supabase||!ctx.schoolId||!start||!end||end<start||busy)return;
  setBusy(true);setMessage('');
  let error:any=null;
  if(kind==='absence_report'){
   const result=await supabase.rpc('schoolpro_report_own_absence',{p_school:ctx.schoolId,p_start:start,p_end:end,p_reason:reason.trim()||null});error=result.error;
  }else{
   const member=ownMembers.find(m=>m.status==='active');
   if(!member){setBusy(false);setMessage('An active staff membership is required to submit a leave request.');return;}
   const result=await supabase.from('schoolpro_leave_requests').insert({school_id:ctx.schoolId,member_id:member.id,leave_type:leaveType,start_date:start,end_date:end,reason:reason.trim()||null,status:'pending',request_type:'planned_leave',session}).select('id');
   error=result.error;
  }
  setBusy(false);setMessage(error?'The request could not be submitted. Check your membership and try again.':'Your request was recorded. You can add or update the reason while it is awaiting review.');
  if(!error){setStart('');setEnd('');setReason('');await load();}
 }
 async function updateReason(id:string){
  if(!supabase||!reasonDraft[id]?.trim()||busy)return;
  setBusy(true);const {error}=await supabase.rpc('schoolpro_update_own_leave_reason',{p_request:id,p_reason:reasonDraft[id].trim()});setBusy(false);
  setMessage(error?'The reason could not be updated.':'Absence reason updated and added to the record history.');if(!error){setReasonDraft(x=>({...x,[id]:''}));await load();}
 }
 async function review(id:string,decision:'approved'|'rejected'){
  if(!supabase||busy)return;setBusy(true);
  const {error}=await supabase.rpc('schoolpro_review_leave_request',{p_request:id,p_decision:decision,p_note:reviewNotes[id]?.trim()||null});setBusy(false);
  setMessage(error?'The leave decision could not be saved.':'Review decision recorded.');if(!error){setReviewNotes(x=>({...x,[id]:''}));await load();}
 }
 return <ModulePage product="schoolpro" sections={schoolSections} title="Leave & absence" description="Submit planned leave, report an absence even when the reason is not yet known, update explanations later and record HR decisions." userName={ctx.schoolName} userRole={ctx.role}>
  <Card><h2 className="font-bold">Submit leave or report an absence</h2><div className="mt-3 grid gap-3 md:grid-cols-2">
   <label className="text-sm font-semibold">Record type<select className="mt-1 w-full rounded-xl border p-3" value={kind} onChange={e=>setKind(e.target.value)}><option value="planned_leave">Planned leave request</option><option value="absence_report">Absence report (reason may follow)</option></select></label>
   {kind==='planned_leave'&&<label className="text-sm font-semibold">Leave type<select className="mt-1 w-full rounded-xl border p-3" value={leaveType} onChange={e=>setLeaveType(e.target.value)}>{['Annual leave','Sick leave','Casual leave','Maternity/Paternity leave','Study leave','Other'].map(x=><option key={x}>{x}</option>)}</select></label>}
   <label className="text-sm font-semibold">Start date<input type="date" className="mt-1 w-full rounded-xl border p-3" value={start} onChange={e=>setStart(e.target.value)}/></label>
   <label className="text-sm font-semibold">End date<input type="date" className="mt-1 w-full rounded-xl border p-3" value={end} onChange={e=>setEnd(e.target.value)}/></label>
   <label className="text-sm font-semibold md:col-span-2">{kind==='absence_report'?'Reason (optional; you can submit it later)':'Reason / supporting explanation'}<textarea className="mt-1 w-full rounded-xl border p-3" rows={3} maxLength={4000} value={reason} onChange={e=>setReason(e.target.value)} placeholder={kind==='absence_report'?'You may leave this blank and update it after reporting the absence.':'Explain the reason for your leave request.'}/></label>
  </div><Button className="mt-3" disabled={busy||!start||!end||end<start} onClick={()=>void submit()}>{busy?'Submitting…':kind==='absence_report'?'Report absence':'Submit leave request'}</Button>{message&&<p role="status" className="mt-3 text-sm">{message}</p>}</Card>
  <div className="grid gap-4">{visible.map(r=><Card key={r.id}>
   <div className="flex flex-wrap justify-between gap-2"><div><h3 className="font-bold">{canReview?memberNames.get(r.member_id)||'Staff member':'My request'} · {r.request_type==='absence_report'?'Absence report':r.leave_type}</h3><p className="text-xs text-muted">{r.start_date} to {r.end_date} · Submitted {new Date(r.created_at).toLocaleDateString()}</p></div><span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold">{pretty(r.status)}</span></div>
   {r.reason?<p className="mt-3 whitespace-pre-wrap text-sm">{r.reason}</p>:<p className="mt-3 text-sm italic text-muted">No reason supplied yet.</p>}
   {r.reason_updated_at&&<p className="mt-1 text-xs text-muted">Reason last updated {new Date(r.reason_updated_at).toLocaleString()}</p>}
   {r.review_note&&<div className="mt-3 rounded-lg bg-slate-50 p-3"><b className="text-sm">HR review note</b><p className="mt-1 text-sm">{r.review_note}</p></div>}
   {!canReview&&ownIds.has(r.member_id)&&r.status==='pending'&&<div className="mt-3 space-y-2"><label className="block text-sm font-semibold">Add or update your reason<textarea className="mt-1 w-full rounded-xl border p-3" rows={2} value={reasonDraft[r.id]??r.reason??''} onChange={e=>setReasonDraft(x=>({...x,[r.id]:e.target.value}))}/></label><Button variant="secondary" disabled={busy||!reasonDraft[r.id]?.trim()} onClick={()=>void updateReason(r.id)}>Update reason</Button></div>}
   {canReview&&r.status==='pending'&&<div className="mt-3 space-y-2"><label className="block text-sm font-semibold">Review note<textarea className="mt-1 w-full rounded-xl border p-3" rows={2} value={reviewNotes[r.id]||''} onChange={e=>setReviewNotes(x=>({...x,[r.id]:e.target.value}))} placeholder="Optional note for the staff member."/></label><div className="flex flex-wrap gap-2"><Button disabled={busy} onClick={()=>void review(r.id,'approved')}>Approve</Button><Button variant="secondary" disabled={busy} onClick={()=>void review(r.id,'rejected')}>Decline</Button></div></div>}
  </Card>)}</div>
  {!visible.length&&<Card><p className="text-sm text-muted">No leave or absence records are available yet.</p></Card>}
 </ModulePage>;
}
