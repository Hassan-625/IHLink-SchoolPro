import {useCallback,useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {Button} from '@/components/ui/Button';
import {AcademicPeriodSelect} from '@/components/AcademicPeriodSelect';
import {academicSessionStatus} from '@/lib/academicSessions';

type SessionRow={id:string;session:string;start_date:string;end_date:string;status:string;notes:string|null};
type HistoryRow={id:number;session:string;term:string|null;change_type:string;before_state:Record<string,unknown>|null;after_state:Record<string,unknown>;changed_at:string};

export function SchoolAcademicSessionManager({schoolId,canEdit=true,selectedSession}:{schoolId:string;canEdit?:boolean;selectedSession?:string}){
  const [rows,setRows]=useState<SessionRow[]>([]);
  const [history,setHistory]=useState<HistoryRow[]>([]);
  const [form,setForm]=useState({session:selectedSession||'',start:'',end:'',notes:''});
  const [busy,setBusy]=useState(false);
  const [message,setMessage]=useState('');
  const load=useCallback(async()=>{
    if(!supabase||!schoolId)return;
    const [sessions,changes]=await Promise.all([
      supabase.from('schoolpro_academic_sessions').select('id,session,start_date,end_date,status,notes').eq('school_id',schoolId).order('start_date',{ascending:false}),
      supabase.from('schoolpro_academic_calendar_history').select('id,session,term,change_type,before_state,after_state,changed_at').eq('school_id',schoolId).order('changed_at',{ascending:false}).limit(30)
    ]);
    if(sessions.error||changes.error){setMessage('Session details or calendar history could not be loaded. Apply the proposed B1 migration before using session lifecycle management.');return;}
    setRows((sessions.data||[]) as SessionRow[]);
    setHistory((changes.data||[]) as HistoryRow[]);
  },[schoolId]);
  useEffect(()=>{if(selectedSession)setForm(v=>({...v,session:selectedSession}));},[selectedSession]);
  useEffect(()=>{void load();},[load]);
  async function save(){
    if(!supabase||busy)return;
    setBusy(true);setMessage('');
    try{
      const result=await supabase.rpc('schoolpro_save_academic_session',{p_school:schoolId,p_session:form.session,p_start:form.start,p_end:form.end,p_notes:form.notes||null});
      if(result.error){setMessage(result.error.message||'The academic session could not be saved.');return;}
      setMessage('Academic session dates saved. Previous values are retained in calendar history.');
      await load();
    }catch{setMessage('The academic session could not be saved.');}
    finally{setBusy(false);}
  }
  async function archive(session:string){
    if(!supabase||busy)return;
    setBusy(true);setMessage('');
    try{
      const result=await supabase.rpc('schoolpro_archive_academic_session',{p_school:schoolId,p_session:session});
      if(result.error){setMessage(result.error.message||'Only a completed session can be archived.');return;}
      setMessage(session+' archived. Its calendar history remains available.');
      await load();
    }catch{setMessage('The academic session could not be archived.');}
    finally{setBusy(false);}
  }
  const now=new Date();
  const today=now.getFullYear()+'-'+String(now.getMonth()+1).padStart(2,'0')+'-'+String(now.getDate()).padStart(2,'0');
  return <section className="mb-5 rounded-xl border p-4">
    <h2 className="text-lg font-bold">Academic sessions</h2>
    <p className="mt-1 text-sm text-slate-600">Set the official beginning and ending dates for each school session. Session selection never changes student enrolment. Editing dates preserves the previous calendar version.</p>
    {canEdit&&<div className="mt-4 grid gap-3 sm:grid-cols-2">
      <AcademicPeriodSelect kind="session" value={form.session} label="Session" onChange={e=>setForm(v=>({...v,session:e.target.value}))}/>
      <label className="text-sm font-semibold">Session begins<input aria-label="Session begins" type="date" className="mt-1 w-full rounded-xl border p-3" value={form.start} onChange={e=>setForm(v=>({...v,start:e.target.value}))}/></label>
      <label className="text-sm font-semibold">Session ends<input aria-label="Session ends" type="date" className="mt-1 w-full rounded-xl border p-3" value={form.end} onChange={e=>setForm(v=>({...v,end:e.target.value}))}/></label>
      <label className="text-sm font-semibold">Notes (optional)<input aria-label="Session notes" className="mt-1 w-full rounded-xl border p-3" value={form.notes} maxLength={500} onChange={e=>setForm(v=>({...v,notes:e.target.value}))} placeholder="e.g. approved school calendar"/></label>
      <div className="sm:col-span-2"><Button disabled={busy||!form.session||!form.start||!form.end} onClick={()=>void save()}>{busy?'Saving…':'Save session dates'}</Button></div>
    </div>}
    {message&&<p role="status" className="mt-3 text-sm">{message}</p>}
    <div className="mt-4 overflow-x-auto"><table className="w-full text-left text-sm"><thead><tr className="border-b"><th className="p-2">Session</th><th className="p-2">Begins</th><th className="p-2">Ends</th><th className="p-2">Status</th><th className="p-2">Action</th></tr></thead><tbody>{rows.map(row=><tr key={row.id} className="border-b"><td className="p-2">{row.session}</td><td className="p-2">{row.start_date}</td><td className="p-2">{row.end_date}</td><td className="p-2 capitalize">{academicSessionStatus(row.start_date,row.end_date,today,row.status==='archived')}</td><td className="p-2">{canEdit&&academicSessionStatus(row.start_date,row.end_date,today)==='completed'&&<Button size="sm" variant="secondary" disabled={busy} onClick={()=>void archive(row.session)}>Archive</Button>}</td></tr>)}</tbody></table>{!rows.length&&<p className="p-3 text-sm text-slate-500">No session date ranges have been configured yet.</p>}</div>
    <h3 className="mt-5 font-semibold">Calendar change history</h3>
    <p className="mt-1 text-xs text-slate-500">Latest 30 recorded changes, including previous and new calendar values.</p>
    <div className="mt-2 max-h-64 overflow-auto"><table className="w-full text-left text-xs"><thead><tr className="border-b"><th className="p-2">Changed</th><th className="p-2">Session / term</th><th className="p-2">Change</th><th className="p-2">Previous → new</th></tr></thead><tbody>{history.map(item=><tr key={item.id} className="border-b align-top"><td className="p-2 whitespace-nowrap">{new Date(item.changed_at).toLocaleString()}</td><td className="p-2">{item.session}{item.term?' · '+item.term:''}</td><td className="p-2">{item.change_type.replaceAll('_',' ')}</td><td className="p-2"><span className="text-slate-500">{item.before_state?JSON.stringify(item.before_state):'—'}</span><span className="block mt-1">{JSON.stringify(item.after_state)}</span></td></tr>)}</tbody></table>{!history.length&&<p className="p-3 text-sm text-slate-500">No calendar changes have been recorded yet.</p>}</div>
  </section>;
}
