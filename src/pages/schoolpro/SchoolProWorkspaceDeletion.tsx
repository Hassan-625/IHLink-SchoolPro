import {useCallback,useEffect,useState} from 'react';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {schoolSections} from './schoolShared';
import {customerMessage} from '@/lib/customerMessage';

type RequestRow={id:string;status:string;request_reason:string;requested_at:string;review_note:string|null;reviewed_at:string|null;execution_note:string|null;executed_at:string|null;preflight_snapshot:Record<string,unknown>};
export function SchoolProWorkspaceDeletion(){
 const ctx=useSchoolProContext();
 const [rows,setRows]=useState<RequestRow[]>([]);
 const [reason,setReason]=useState('');
 const [confirmation,setConfirmation]=useState('');
 const [busy,setBusy]=useState(false);
 const [error,setError]=useState('');
 const [notice,setNotice]=useState('');
 const canRequest=ctx.role.toLowerCase()==='proprietor';

 const load=useCallback(async()=>{
  if(!supabase||!ctx.schoolId)return;
  const result=await supabase.from('schoolpro_workspace_deletion_requests')
   .select('id,status,request_reason,requested_at,review_note,reviewed_at,execution_note,executed_at,preflight_snapshot')
   .eq('school_id',ctx.schoolId).order('requested_at',{ascending:false});
  if(result.error)setError(customerMessage(result.error.message));
  else setRows((result.data||[]) as RequestRow[]);
 },[ctx.schoolId]);
 useEffect(()=>{void load()},[load]);

 async function submit(){
  if(!supabase||!ctx.schoolId||!canRequest||busy)return;
  if(reason.trim().length<20){setError('Explain why the school workspace should be removed (at least 20 characters).');return}
  if(confirmation.trim()!==ctx.schoolName){setError('Type the exact school name to confirm this request.');return}
  setBusy(true);setError('');setNotice('');
  const result=await supabase.rpc('schoolpro_request_workspace_deletion',{p_school:ctx.schoolId,p_reason:reason.trim(),p_confirmation:confirmation.trim()});
  setBusy(false);
  if(result.error){setError(customerMessage(result.error.message));return}
  setNotice('Workspace removal request submitted for independent platform review. The workspace remains active until an authorised reviewer approves and executes it.');
  setReason('');setConfirmation('');await load();
 }

 async function cancel(id:string){
  if(!supabase||busy)return;
  const note=window.prompt('Optional note for cancelling this request:');
  if(note===null)return;
  setBusy(true);setError('');setNotice('');
  const result=await supabase.rpc('schoolpro_cancel_workspace_deletion',{p_request:id,p_note:note||null});
  setBusy(false);
  if(result.error)setError(customerMessage(result.error.message));
  else{setNotice('Pending workspace removal request cancelled.');await load();}
 }

 return <ModulePage product="schoolpro" sections={schoolSections} title="Workspace Removal Request" description="Submit a formal request for independent platform review. Approved execution deactivates school access while retaining academic, financial, legal, audit and Storage history." userName={ctx.schoolName||'SchoolPro'} userRole={ctx.role} metrics={[{label:'Requests',value:String(rows.length)},{label:'Pending review',value:String(rows.filter(r=>r.status==='pending').length)},{label:'Approved',value:String(rows.filter(r=>r.status==='approved').length)},{label:'Executed',value:String(rows.filter(r=>r.status==='executed').length)}]}>
  {error&&<p role="alert" className="rounded-xl border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700">{error}</p>}
  {notice&&<p role="status" className="rounded-xl border p-3 text-sm">{notice}</p>}
  <Card>
   <h2 className="font-bold">Request workspace removal</h2>
   <p className="mt-2 text-sm text-muted">Only the school proprietor can submit this request. A separate IHLink Super Admin must review it. The requester cannot approve or execute their own request.</p>
   <p className="mt-2 rounded-lg border p-3 text-sm"><b>Important:</b> Execution is a safe deactivation, not an immediate physical purge. Student records, results, transcripts, financial records, audit evidence and Storage objects are retained. Any permanent purge requires a separate retention review and Storage inventory.</p>
   {!canRequest?<p className="mt-3 text-sm text-muted">This request is available to the school's Proprietor account.</p>:<div className="mt-4 grid gap-3">
    <label className="text-sm font-semibold">Reason for removal<textarea value={reason} onChange={e=>setReason(e.target.value)} rows={4} maxLength={2000} placeholder="Explain why this workspace should be removed and any relevant context." className="mt-1 w-full rounded-lg border p-3 text-sm"/></label>
    <label className="text-sm font-semibold">Confirm school name: {ctx.schoolName}<input value={confirmation} onChange={e=>setConfirmation(e.target.value)} placeholder="Type the exact school name" className="mt-1 w-full rounded-lg border p-3 text-sm"/></label>
    <Button disabled={busy||reason.trim().length<20||confirmation.trim()!==ctx.schoolName} onClick={()=>void submit()}>{busy?'Submitting…':'Submit removal request'}</Button>
   </div>}
  </Card>
  <Card padding="none" className="min-w-0 overflow-hidden">
   <div className="border-b p-4"><h2 className="font-bold">Request history</h2><p className="text-xs text-muted">Requests and platform decisions for this school workspace.</p></div>
   <div className="max-h-[60vh] overflow-auto" role="region" aria-label="Workspace removal request history; scroll horizontally and vertically" tabIndex={0}><table className="w-full min-w-[850px] text-left text-sm"><thead className="sticky top-0 bg-gray-50"><tr>{['Requested','Reason','Status','Platform review','Execution','Action'].map(x=><th key={x} className="p-3 text-xs uppercase text-muted">{x}</th>)}</tr></thead><tbody>{rows.map(row=><tr key={row.id} className="border-t"><td className="p-3 whitespace-nowrap">{new Date(row.requested_at).toLocaleString()}</td><td className="max-w-[280px] p-3">{row.request_reason}</td><td className="p-3 font-semibold">{row.status.replaceAll('_',' ')}</td><td className="max-w-[260px] p-3">{row.review_note||'Awaiting review'}</td><td className="max-w-[260px] p-3">{row.execution_note||'Not executed'}</td><td className="p-3">{row.status==='pending'&&canRequest?<Button size="sm" variant="secondary" disabled={busy} onClick={()=>void cancel(row.id)}>Cancel request</Button>:<span className="text-xs text-muted">—</span>}</td></tr>)}</tbody></table>{!rows.length&&<p className="p-8 text-center text-sm text-muted">No workspace removal requests have been submitted.</p>}</div>
  </Card>
 </ModulePage>;
}
