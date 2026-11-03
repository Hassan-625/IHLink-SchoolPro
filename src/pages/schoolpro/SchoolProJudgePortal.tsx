import {useCallback,useEffect,useState} from 'react';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {schoolSections} from './schoolShared';
type Assignment={id:string;event_id:string;panel_role:string;ended_at:string|null};
type Event={id:string;title:string;event_type:string;status:string;judging_guidelines:string|null};
type Criterion={id:string;name:string;max_points:number;weight:number};
type Entry={id:string;entry_name:string;house_id:string|null};
type Score={id:string;entry_id:string;criterion_id:string;points:number;comments:string|null;scored_at:string};
const input='mt-1 w-full rounded-lg border border-border bg-white p-2.5 text-sm';
export function SchoolProJudgePortal(){
 const {user}=useAuth(),ctx=useSchoolProContext();
 const [assignments,setAssignments]=useState<Assignment[]>([]),[events,setEvents]=useState<Event[]>([]);
 const [selected,setSelected]=useState(''),[criteria,setCriteria]=useState<Criterion[]>([]),[entries,setEntries]=useState<Entry[]>([]),[scores,setScores]=useState<Score[]>([]);
 const [memberIds,setMemberIds]=useState<string[]>([]),[entry,setEntry]=useState(''),[criterion,setCriterion]=useState(''),[points,setPoints]=useState(''),[comments,setComments]=useState('');
 const [error,setError]=useState(''),[message,setMessage]=useState(''),[busy,setBusy]=useState(false);
 const load=useCallback(async()=>{
  if(!supabase||!ctx.schoolId||!user)return;
  const m=await supabase.from('schoolpro_members').select('id').eq('school_id',ctx.schoolId).eq('user_id',user.id);
  if(m.error){setError('Your staff membership could not be verified.');return;}
  const ids=(m.data||[]).map(x=>x.id);setMemberIds(ids);
  if(!ids.length){setAssignments([]);setEvents([]);return;}
  const a=await supabase.from('schoolpro_competition_judges').select('id,event_id,panel_role,ended_at').eq('school_id',ctx.schoolId).in('member_id',ids).is('ended_at',null).order('assigned_at',{ascending:false});
  if(a.error){setError('Your judging assignments could not be loaded.');return;}
  setAssignments(a.data||[]);
  const eventIds=[...new Set((a.data||[]).map(x=>x.event_id))];
  if(!eventIds.length){setEvents([]);return;}
  const e=await supabase.from('schoolpro_competition_events').select('id,title,event_type,status,judging_guidelines').eq('school_id',ctx.schoolId).in('id',eventIds);
  if(e.error){setError('Assigned competition details could not be loaded.');return;}
  setEvents(e.data||[]);
 },[ctx.schoolId,user]);
 const loadSelected=useCallback(async(id:string)=>{
  if(!supabase||!ctx.schoolId||!id){setCriteria([]);setEntries([]);setScores([]);return;}
  const [c,en,s]=await Promise.all([
   supabase.from('schoolpro_competition_criteria').select('id,name,max_points,weight').eq('school_id',ctx.schoolId).eq('event_id',id).order('sort_order'),
   supabase.from('schoolpro_competition_entries').select('id,entry_name,house_id').eq('school_id',ctx.schoolId).eq('event_id',id),
   supabase.from('schoolpro_competition_scores').select('id,entry_id,criterion_id,points,comments,scored_at').eq('school_id',ctx.schoolId).eq('event_id',id).order('scored_at',{ascending:false})
  ]);
  if(c.error||en.error||s.error){setError('This judging panel data could not be loaded.');return;}
  setCriteria(c.data||[]);setEntries(en.data||[]);setScores(s.data||[]);
 },[ctx.schoolId]);
 useEffect(()=>{void load()},[load]);useEffect(()=>{void loadSelected(selected)},[selected,loadSelected]);
 async function submit(){if(!supabase||!selected||!entry||!criterion||points===''||busy)return;setBusy(true);setError('');setMessage('');try{const r=await supabase.rpc('schoolpro_record_competition_score',{p_school:ctx.schoolId,p_event:selected,p_entry:entry,p_criterion:criterion,p_points:Number(points),p_comments:comments||null});if(r.error)throw r.error;setMessage('Your score has been saved.');setPoints('');setComments('');await loadSelected(selected)}catch(e:any){setError(e?.message||'Score submission failed. Check that the event is accepting scores and your panel assignment is active.')}finally{setBusy(false)}}
 const current=events.find(e=>e.id===selected);
 return <ModulePage product="schoolpro" sections={schoolSections} title="My Judging Panel" description="Review competitions assigned to you, read the event guidelines and submit criterion-based scores. Your judging access is limited to active panel assignments." userName={ctx.schoolName} userRole={ctx.role} metrics={[{label:'Active assignments',value:String(assignments.length)},{label:'Events available',value:String(events.length)},{label:'Scores submitted',value:String(scores.length)}]}>
  {(error||message)&&<div role="status" className={error?'rounded-xl border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700':'rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-700'}>{error||message}</div>}
  <Card><h3 className="font-bold">Your assigned events</h3><div className="mt-3 grid gap-2 md:grid-cols-2">{events.map(e=><button key={e.id} onClick={()=>setSelected(e.id)} className={'rounded-xl border p-3 text-left '+(selected===e.id?'border-blue-500 bg-blue-50':'')}><p className="font-semibold">{e.title}</p><p className="text-xs text-muted">{e.event_type} · {e.status} · {assignments.filter(a=>a.event_id===e.id).map(a=>a.panel_role.replaceAll('_',' ')).join(', ')}</p></button>)}{!events.length&&<p className="text-sm text-muted">No active judging assignments have been made for your staff account.</p>}</div></Card>
  {current&&<div className="grid gap-5 xl:grid-cols-2"><Card><h3 className="font-bold">{current.title}</h3><p className="mt-1 text-xs text-muted">Status: {current.status}</p><h4 className="mt-4 text-sm font-semibold">Judging guidelines</h4><p className="mt-1 whitespace-pre-wrap text-sm">{current.judging_guidelines||'No additional judging guidelines were supplied.'}</p><h4 className="mt-4 text-sm font-semibold">Scoring criteria</h4><div className="mt-2 space-y-2">{criteria.map(c=><div key={c.id} className="rounded-lg border p-3 text-sm"><b>{c.name}</b><span className="float-right">{c.max_points} max · weight {c.weight}</span></div>)}</div></Card>
  <Card><h3 className="font-bold">Submit / revise your score</h3><p className="mt-1 text-xs text-muted">Scores are attributed to your active judge assignment. Maximum points are enforced by the database.</p><div className="mt-3 space-y-2"><label className="block text-sm font-semibold">Entry<select className={input} value={entry} onChange={e=>setEntry(e.target.value)}><option value="">Choose entry</option>{entries.map(x=><option key={x.id} value={x.id}>{x.entry_name}</option>)}</select></label><label className="block text-sm font-semibold">Criterion<select className={input} value={criterion} onChange={e=>setCriterion(e.target.value)}><option value="">Choose criterion</option>{criteria.map(x=><option key={x.id} value={x.id}>{x.name} · max {x.max_points}</option>)}</select></label><label className="block text-sm font-semibold">Points<input className={input} type="number" min="0" step="0.01" max={criteria.find(x=>x.id===criterion)?.max_points} value={points} onChange={e=>setPoints(e.target.value)}/></label><label className="block text-sm font-semibold">Comments<textarea className={input} rows={3} value={comments} onChange={e=>setComments(e.target.value)} maxLength={2000}/></label><Button disabled={busy||!entry||!criterion||points===''||Number(points)<0||Number(points)>Number(criteria.find(x=>x.id===criterion)?.max_points)||!['open','scoring'].includes(current.status)} onClick={()=>void submit()}>{busy?'Saving…':'Submit score'}</Button>{!['open','scoring'].includes(current.status)&&<p className="text-xs text-muted">This event is not currently accepting scores.</p>}</div></Card>
  <Card><h3 className="font-bold">Your submitted scores</h3><div className="mt-3 space-y-2">{scores.filter(s=>assignments.some(a=>a.event_id===selected)).map(s=><div key={s.id} className="rounded-lg border p-3 text-sm"><b>{entries.find(e=>e.id===s.entry_id)?.entry_name||'Entry'}</b><p>{criteria.find(c=>c.id===s.criterion_id)?.name||'Criterion'} · {s.points} points</p>{s.comments&&<p className="text-muted">{s.comments}</p>}</div>)}{!scores.length&&<p className="text-sm text-muted">No scores submitted for this event yet.</p>}</div></Card></div>}
 </ModulePage>;
}
