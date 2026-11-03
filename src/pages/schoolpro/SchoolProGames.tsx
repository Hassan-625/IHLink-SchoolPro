import {useCallback,useEffect,useMemo,useState} from 'react';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useSchoolSession} from '@/hooks/useSchoolSession';
import {supabase} from '@/lib/supabase';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {schoolSections} from './schoolShared';

type House={id:string;name:string;code:string;color:string;sort_order:number;is_active:boolean};
type Member={id:string;role:string;position_title:string|null;profile:{first_name:string|null;last_name:string|null;email:string}|null};
type Event={id:string;title:string;event_type:string;status:string;academic_session:string|null;term:string|null;judging_guidelines:string|null};
type Criterion={id:string;event_id:string;name:string;max_points:number;weight:number};
type Entry={id:string;event_id:string;house_id:string|null;entry_name:string};
type Judge={id:string;event_id:string;member_id:string;panel_role:string;ended_at:string|null};
type Student={id:string;first_name:string;last_name:string;admission_number:string|null};
const input='mt-1 w-full rounded-lg border border-border bg-white p-2.5 text-sm';
const label='block text-sm font-semibold text-ink';
export function SchoolProGames(){
 const ctx=useSchoolProContext(),{user}=useAuth(),{session}=useSchoolSession();
 const [houses,setHouses]=useState<House[]>([]),[members,setMembers]=useState<Member[]>([]),[students,setStudents]=useState<Student[]>([]);
 const [events,setEvents]=useState<Event[]>([]),[criteria,setCriteria]=useState<Criterion[]>([]),[entries,setEntries]=useState<Entry[]>([]),[judges,setJudges]=useState<Judge[]>([]);
 const [selected,setSelected]=useState(''),[message,setMessage]=useState(''),[error,setError]=useState(''),[busy,setBusy]=useState(false);
 const [houseName,setHouseName]=useState(''),[houseCode,setHouseCode]=useState(''),[houseColor,setHouseColor]=useState('#dc2626');
 const [masterHouse,setMasterHouse]=useState(''),[masterMember,setMasterMember]=useState('');
 const [manualStudent,setManualStudent]=useState(''),[manualHouse,setManualHouse]=useState(''),[manualReason,setManualReason]=useState('');
 const [title,setTitle]=useState(''),[eventType,setEventType]=useState('sports'),[guidelines,setGuidelines]=useState(''),[eventTerm,setEventTerm]=useState('');
 const [criterionName,setCriterionName]=useState(''),[criterionMax,setCriterionMax]=useState('10'),[criterionWeight,setCriterionWeight]=useState('1');
 const [entryName,setEntryName]=useState(''),[entryHouse,setEntryHouse]=useState('');
 const [judgeMember,setJudgeMember]=useState(''),[judgeRole,setJudgeRole]=useState('judge');
 const [scoreEntry,setScoreEntry]=useState(''),[scoreCriterion,setScoreCriterion]=useState(''),[scorePoints,setScorePoints]=useState(''),[scoreComments,setScoreComments]=useState('');
 const [awardHouse,setAwardHouse]=useState(''),[awardPointValue,setAwardPointValue]=useState(''),[awardReason,setAwardReason]=useState('');
 const canManage=['proprietor','administrator','super_administrator','game_master'].includes(ctx.role.toLowerCase().replaceAll(' ','_'));
 const load=useCallback(async()=>{
  if(!supabase||!ctx.schoolId)return;
  const [h,m,s,e]=await Promise.all([
   supabase.from('schoolpro_houses').select('id,name,code,color,sort_order,is_active').eq('school_id',ctx.schoolId).order('sort_order'),
   supabase.from('schoolpro_members').select('id,role,position_title,profile:profiles!schoolpro_members_user_id_fkey(first_name,last_name,email)').eq('school_id',ctx.schoolId).order('created_at'),
   supabase.from('schoolpro_students').select('id,first_name,last_name,admission_number').eq('school_id',ctx.schoolId).eq('status','active').order('last_name'),
   supabase.from('schoolpro_competition_events').select('id,title,event_type,status,academic_session,term,judging_guidelines').eq('school_id',ctx.schoolId).order('created_at',{ascending:false})
  ]);
  if(h.error||m.error||s.error||e.error){setError('Some Games records could not be loaded. Check your access and refresh.');return;}
  setHouses(h.data||[]);setMembers((m.data||[]) as unknown as Member[]);setStudents(s.data||[]);setEvents(e.data||[]);
 },[ctx.schoolId]);
 const loadEvent=useCallback(async(id:string)=>{
  if(!supabase||!ctx.schoolId||!id){setCriteria([]);setEntries([]);setJudges([]);return;}
  const [c,en,j]=await Promise.all([
   supabase.from('schoolpro_competition_criteria').select('id,event_id,name,max_points,weight').eq('school_id',ctx.schoolId).eq('event_id',id).order('sort_order'),
   supabase.from('schoolpro_competition_entries').select('id,event_id,house_id,entry_name').eq('school_id',ctx.schoolId).eq('event_id',id).order('created_at'),
   supabase.from('schoolpro_competition_judges').select('id,event_id,member_id,panel_role,ended_at').eq('school_id',ctx.schoolId).eq('event_id',id).order('assigned_at')
  ]);
  if(c.error||en.error||j.error){setError('Competition details could not be loaded.');return;}
  setCriteria(c.data||[]);setEntries(en.data||[]);setJudges(j.data||[]);
 },[ctx.schoolId]);
 useEffect(()=>{void load()},[load]);
 useEffect(()=>{void loadEvent(selected)},[selected,loadEvent]);
 const activeHouses=houses.filter(h=>h.is_active);
 const activeJudges=judges.filter(j=>!j.ended_at);
 const memberName=(id:string)=>{const m=members.find(x=>x.id===id);return [m?.profile?.first_name,m?.profile?.last_name].filter(Boolean).join(' ')||m?.profile?.email||'Staff member'};
 const houseNameOf=(id:string|null)=>houses.find(h=>h.id===id)?.name||'Unassigned';
 async function run(action:()=>Promise<{error:any;data?:any}> ,success:string){if(busy)return;setBusy(true);setError('');setMessage('');try{const r=await action();if(r.error)throw r.error;setMessage(success);await load();if(selected)await loadEvent(selected);}catch(e:any){setError(e?.message||'The change could not be saved. Please try again.')}finally{setBusy(false)}}
 async function createHouse(){if(!supabase||!ctx.schoolId||!houseName.trim()||!houseCode.trim())return;await run(()=>supabase!.rpc('schoolpro_save_house',{p_school:ctx.schoolId,p_name:houseName.trim(),p_code:houseCode.trim().toLowerCase().replace(/\\s+/g,'-'),p_color:houseColor,p_sort_order:houses.length+1,p_house:null,p_is_active:true}), 'House created.');setHouseName('');setHouseCode('');}
 async function assignMaster(){if(!supabase||!masterHouse||!masterMember)return;await run(()=>supabase!.rpc('schoolpro_set_house_master',{p_school:ctx.schoolId,p_house:masterHouse,p_member:masterMember}),'House Master appointed.')}
 async function assignStudent(){if(!supabase||!manualStudent||!manualHouse)return;await run(()=>supabase!.rpc('schoolpro_assign_student_house',{p_student:manualStudent,p_house:manualHouse,p_reason:manualReason||'Manual house assignment'}),'Student house assignment updated.');setManualStudent('');setManualReason('');}
 async function createEvent(){if(!supabase||!title.trim())return;await run(()=>supabase!.from('schoolpro_competition_events').insert({school_id:ctx.schoolId,title:title.trim(),event_type:eventType,status:'draft',academic_session:session||null,term:eventTerm||null,judging_guidelines:guidelines||null,created_by:user?.id}).select('id').single(),'Competition event created.');setTitle('');setGuidelines('');setEventTerm('');}
 async function addCriterion(){if(!supabase||!selected||!criterionName.trim())return;await run(()=>supabase!.from('schoolpro_competition_criteria').insert({school_id:ctx.schoolId,event_id:selected,name:criterionName.trim(),max_points:Number(criterionMax),weight:Number(criterionWeight)}),'Scoring criterion added.');setCriterionName('');}
 async function addEntry(){if(!supabase||!selected||!entryName.trim())return;await run(()=>supabase!.from('schoolpro_competition_entries').insert({school_id:ctx.schoolId,event_id:selected,entry_name:entryName.trim(),house_id:entryHouse||null}),'Competition entry added.');setEntryName('');}
 async function appointJudge(){if(!supabase||!selected||!judgeMember)return;await run(()=>supabase!.rpc('schoolpro_assign_competition_judge',{p_school:ctx.schoolId,p_event:selected,p_member:judgeMember,p_panel_role:judgeRole}),'Staff judge assigned to event.')}
 async function submitScore(){if(!supabase||!selected||!scoreEntry||!scoreCriterion||scorePoints==='')return;await run(()=>supabase!.rpc('schoolpro_record_competition_score',{p_school:ctx.schoolId,p_event:selected,p_entry:scoreEntry,p_criterion:scoreCriterion,p_points:Number(scorePoints),p_comments:scoreComments||null}),'Judge score saved.');setScorePoints('');setScoreComments('');}
 async function submitHouseAward(){if(!supabase||!awardHouse||!awardPointValue||!awardReason.trim())return;await run(()=>supabase!.rpc('schoolpro_award_house_points',{p_school:ctx.schoolId,p_house:awardHouse,p_points:Number(awardPointValue),p_reason:awardReason.trim(),p_event:selected||null,p_entry:null}),'House points recorded.');setAwardPointValue('');setAwardReason('');}
 const [standings,setStandings]=useState<any[]>([]);
 const loadStandings=useCallback(async()=>{if(!supabase||!ctx.schoolId)return;const r=await supabase.from('schoolpro_house_competition_standings').select('house_id,house_name,color,total_points,events_scored').eq('school_id',ctx.schoolId).order('total_points',{ascending:false});if(!r.error)setStandings(r.data||[])},[ctx.schoolId]);
 useEffect(()=>{void loadStandings()},[loadStandings,events,judges]);
 const teachingMembers=useMemo(()=>members.filter(m=>['teacher','class_teacher'].includes(m.role)),[members]);
 return <ModulePage product="schoolpro" sections={schoolSections} title="Houses, Games & Competitions" description="Manage house membership, appoint teaching staff as House Masters and event judges, configure competitions and scoring, and track inter-house standings." userName={ctx.schoolName} userRole={ctx.role} metrics={[{label:'Active houses',value:String(activeHouses.length)},{label:'Competition events',value:String(events.length)},{label:'Assigned event judges',value:String(activeJudges.length)},{label:'Active students',value:String(students.length)}]}>
  {(error||message)&&<div role="status" className={error?'rounded-xl border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700':'rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-700'}>{error||message}</div>}
  <div className="grid gap-5 xl:grid-cols-2">
   <Card><div className="flex items-center justify-between"><div><h3 className="font-bold">House configuration</h3><p className="text-xs text-muted">New schools start with Red, Green, Blue and Yellow.</p></div></div>
    <div className="mt-3 grid gap-2 sm:grid-cols-2">{houses.map(h=><div key={h.id} className="flex items-center gap-3 rounded-lg border p-3"><span className="h-4 w-4 rounded-full" style={{backgroundColor:h.color}}/><div className="min-w-0"><p className="font-semibold">{h.name}</p><p className="text-xs text-muted">{h.code} · {h.is_active?'Active':'Inactive'}</p></div></div>)}</div>
    {canManage&&<div className="mt-4 grid gap-2 sm:grid-cols-[1fr_1fr_80px_auto]"><input className={input} placeholder="House name" value={houseName} onChange={e=>setHouseName(e.target.value)}/><input className={input} placeholder="Code" value={houseCode} onChange={e=>setHouseCode(e.target.value)}/><input aria-label="House colour" type="color" className="h-10 w-full rounded-lg border" value={houseColor} onChange={e=>setHouseColor(e.target.value)}/><Button disabled={busy||!houseName.trim()||!houseCode.trim()} onClick={()=>void createHouse()}>Add house</Button></div>}
   </Card>
   <Card><h3 className="font-bold">House Masters</h3><p className="text-xs text-muted">Only teaching staff can be appointed. One active house per House Master.</p>
    {canManage&&<div className="mt-3 grid gap-2 sm:grid-cols-2"><select className={input} value={masterHouse} onChange={e=>setMasterHouse(e.target.value)}><option value="">Choose house</option>{activeHouses.map(h=><option key={h.id} value={h.id}>{h.name}</option>)}</select><select className={input} value={masterMember} onChange={e=>setMasterMember(e.target.value)}><option value="">Choose teaching staff</option>{teachingMembers.map(m=><option key={m.id} value={m.id}>{memberName(m.id)}</option>)}</select><Button disabled={busy||!masterHouse||!masterMember} onClick={()=>void assignMaster()}>Appoint House Master</Button></div>}
    <p className="mt-3 text-xs text-muted">Appointments are recorded in the House Master history table and closed when a staff member is moved or demoted.</p>
   </Card>
   <Card><h3 className="font-bold">Manual student house assignment</h3><p className="text-xs text-muted">Use this for transfer students or students admitted without automatic house placement.</p>
    {canManage&&<div className="mt-3 space-y-2"><select className={input} value={manualStudent} onChange={e=>setManualStudent(e.target.value)}><option value="">Choose student</option>{students.map(s=><option key={s.id} value={s.id}>{s.first_name} {s.last_name} · {s.admission_number||'No admission number'}</option>)}</select><select className={input} value={manualHouse} onChange={e=>setManualHouse(e.target.value)}><option value="">Choose house</option>{activeHouses.map(h=><option key={h.id} value={h.id}>{h.name}</option>)}</select><input className={input} placeholder="Reason (optional)" value={manualReason} onChange={e=>setManualReason(e.target.value)}/><Button disabled={busy||!manualStudent||!manualHouse} onClick={()=>void assignStudent()}>Assign house</Button></div>}
   </Card>
   <Card><h3 className="font-bold">Inter-house standings</h3><p className="text-xs text-muted">Calculated from the house-points ledger, including adjustments and penalties.</p><div className="mt-3 space-y-2">{standings.map((s,i)=><div key={s.house_id} className="flex items-center justify-between rounded-lg border p-3"><div className="flex items-center gap-3"><span className="font-bold text-muted">#{i+1}</span><span className="h-3 w-3 rounded-full" style={{backgroundColor:s.color}}/><span className="font-semibold">{s.house_name}</span></div><span className="font-bold tabular-nums">{s.total_points} pts</span></div>)}{!standings.length&&<p className="text-sm text-muted">No house points have been awarded yet.</p>}</div>
    {canManage&&<div className="mt-4 grid gap-2 sm:grid-cols-2"><select className={input} value={awardHouse} onChange={e=>setAwardHouse(e.target.value)}><option value="">House</option>{activeHouses.map(h=><option key={h.id} value={h.id}>{h.name}</option>)}</select><input className={input} type="number" step="0.5" placeholder="Points (+/-)" value={awardPointValue} onChange={e=>setAwardPoints(e.target.value)}/><input className={input+' sm:col-span-2'} placeholder="Reason / award / penalty" value={awardReason} onChange={e=>setAwardReason(e.target.value)}/><Button disabled={busy||!awardHouse||!awardPoints||!awardReason.trim()} onClick={()=>void submitHouseAward()}>Record house points</Button></div>}
   </Card>
  </div>
  <Card><h3 className="font-bold">Competition events</h3><p className="text-xs text-muted">Create sports, athletics, debate, quiz, cultural, academic or custom events.</p>
   {canManage&&<div className="mt-3 grid gap-2 md:grid-cols-2"><input className={input} placeholder="Event title" value={title} onChange={e=>setTitle(e.target.value)}/><select className={input} value={eventType} onChange={e=>setEventType(e.target.value)}>{['sports','athletics','debate','quiz','cultural','academic','custom'].map(t=><option key={t} value={t}>{t[0].toUpperCase()+t.slice(1)}</option>)}</select><input className={input} placeholder="Term (optional)" value={eventTerm} onChange={e=>setEventTerm(e.target.value)}/><textarea className={input} rows={2} placeholder="Event rules and judging guidelines" value={guidelines} onChange={e=>setGuidelines(e.target.value)}/><Button disabled={busy||!title.trim()} onClick={()=>void createEvent()}>Create event</Button></div>}
   <div className="mt-4 grid gap-2 md:grid-cols-2">{events.map(e=><button key={e.id} onClick={()=>setSelected(e.id)} className={'rounded-xl border p-3 text-left '+(selected===e.id?'border-blue-500 bg-blue-50':'')}><div className="flex justify-between gap-2"><span className="font-semibold">{e.title}</span><span className="text-xs text-muted">{e.status}</span></div><p className="mt-1 text-xs text-muted">{e.event_type} · {e.academic_session||'No session'} {e.term||''}</p></button>)}{!events.length&&<p className="text-sm text-muted">No competition events created yet.</p>}</div>
  </Card>
  {selected&&<div className="grid gap-5 xl:grid-cols-2">
   <Card><h3 className="font-bold">Scoring rubric</h3><div className="mt-3 grid gap-2 sm:grid-cols-3"><input className={input} placeholder="Criterion name" value={criterionName} onChange={e=>setCriterionName(e.target.value)}/><input className={input} type="number" min="0.01" step="0.01" placeholder="Max points" value={criterionMax} onChange={e=>setCriterionMax(e.target.value)}/><input className={input} type="number" min="0.01" step="0.1" placeholder="Weight" value={criterionWeight} onChange={e=>setCriterionWeight(e.target.value)}/></div><Button className="mt-2" disabled={!canManage||busy||!criterionName.trim()||Number(criterionMax)<=0||Number(criterionWeight)<=0} onClick={()=>void addCriterion()}>Add criterion</Button><div className="mt-3 space-y-2">{criteria.map(c=><div key={c.id} className="rounded-lg border p-3 text-sm"><b>{c.name}</b><span className="float-right">{c.max_points} max · ×{c.weight}</span></div>)}</div></Card>
   <Card><h3 className="font-bold">Entries / houses</h3><div className="mt-3 space-y-2"><input className={input} placeholder="Entry or team name" value={entryName} onChange={e=>setEntryName(e.target.value)}/><select className={input} value={entryHouse} onChange={e=>setEntryHouse(e.target.value)}><option value="">No house / individual entry</option>{activeHouses.map(h=><option key={h.id} value={h.id}>{h.name}</option>)}</select><Button disabled={!canManage||busy||!entryName.trim()} onClick={()=>void addEntry()}>Add entry</Button></div><div className="mt-3 space-y-2">{entries.map(e=><div key={e.id} className="rounded-lg border p-3 text-sm"><b>{e.entry_name}</b><span className="float-right">{houseNameOf(e.house_id)}</span></div>)}</div></Card>
   <Card><h3 className="font-bold">Staff judging panel</h3><p className="text-xs text-muted">Select a staff account and give it a role on this event's panel.</p><div className="mt-3 space-y-2"><select className={input} value={judgeMember} onChange={e=>setJudgeMember(e.target.value)}><option value="">Choose staff judge</option>{members.map(m=><option key={m.id} value={m.id}>{memberName(m.id)} · {m.role.replaceAll('_',' ')}</option>)}</select><select className={input} value={judgeRole} onChange={e=>setJudgeRole(e.target.value)}>{['chief_judge','judge','timekeeper','referee','moderator'].map(r=><option key={r} value={r}>{r.replaceAll('_',' ')}</option>)}</select><Button disabled={!canManage||busy||!judgeMember} onClick={()=>void appointJudge()}>Assign staff to panel</Button></div><div className="mt-3 space-y-2">{judges.map(j=><div key={j.id} className="flex justify-between rounded-lg border p-3 text-sm"><span>{memberName(j.member_id)}</span><span className="text-muted">{j.panel_role.replaceAll('_',' ')}{j.ended_at?' · ended':''}</span></div>)}</div></Card>
   <Card><h3 className="font-bold">Judge score entry</h3><p className="text-xs text-muted">A judge must be signed in and actively assigned to this event to submit a score.</p><div className="mt-3 space-y-2"><select className={input} value={scoreEntry} onChange={e=>setScoreEntry(e.target.value)}><option value="">Choose entry</option>{entries.map(e=><option key={e.id} value={e.id}>{e.entry_name}</option>)}</select><select className={input} value={scoreCriterion} onChange={e=>setScoreCriterion(e.target.value)}><option value="">Choose criterion</option>{criteria.map(c=><option key={c.id} value={c.id}>{c.name} (max {c.max_points})</option>)}</select><input className={input} type="number" min="0" step="0.01" placeholder="Points" value={scorePoints} onChange={e=>setScorePoints(e.target.value)}/><textarea className={input} rows={2} placeholder="Judge comments" value={scoreComments} onChange={e=>setScoreComments(e.target.value)}/><Button disabled={busy||!scoreEntry||!scoreCriterion||scorePoints===''||Number(scorePoints)<0||Number(scorePoints)>Number(criteria.find(c=>c.id===scoreCriterion)?.max_points)} onClick={()=>void submitScore()}>Submit score</Button></div></Card>
  </div>}
 </ModulePage>;
}
