import {useCallback,useEffect,useMemo,useState} from 'react';
import {useSchoolSession} from '@/hooks/useSchoolSession';
import {schoolSessionStudents} from '@/lib/schoolSessionStudents';
import {fetchSchoolRows} from '@/lib/schoolDataPaging';
import {SchoolStudentSelect} from '@/components/SchoolStudentSelect';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {ModulePage} from '@/components/ModulePage';
import {SchoolStudentFilters} from '@/components/SchoolStudentFilters';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {schoolSections} from './schoolShared';

type Student={id:string;first_name:string;last_name:string;class_id:string|null;class_name:string};
type Member={id:string;role:string;profile?:{first_name:string|null;last_name:string|null}[]|null};
type Concern={
 id:string;student_id:string;incident:string;action_taken:string|null;status:string;created_at:string;assigned_to:string|null;
 category:string;severity:string;location:string|null;incident_at:string;student_response:string|null;
 guardian_contact_status:string;guardian_contacted_at:string|null;guardian_contact_note:string|null;
 follow_up_at:string|null;follow_up_outcome:string|null;resolved_at:string|null;
};
type Draft={action_taken:string;severity:string;student_response:string;guardian_contact_status:string;guardian_contact_note:string;follow_up_at:string;follow_up_outcome:string;assigned_to:string};

const categories=['general','misconduct','bullying','violence','truancy','property_damage','academic_misconduct','substance_concern','safeguarding','other'];
const severities=['low','moderate','high','critical'];
const label=(v:string)=>v.replaceAll('_',' ').replace(/^./,x=>x.toUpperCase());

export function SchoolProDiscipline(){
 const {session}=useSchoolSession();const ctx=useSchoolProContext(),{user}=useAuth();
 const leadership=['proprietor','administrator','super administrator','super_admin','vice principal','head teacher','counsellor','discipline master','discipline_master'].includes(ctx.role.toLowerCase().replaceAll('_',' '))||['super_admin'].includes(ctx.role.toLowerCase());
 const [students,setStudents]=useState<Student[]>([]),[members,setMembers]=useState<Member[]>([]),[ids,setIds]=useState<string[]>([]),[rows,setRows]=useState<Concern[]>([]);
 const [student,setStudent]=useState(''),[incident,setIncident]=useState(''),[category,setCategory]=useState('general'),[severity,setSeverity]=useState('moderate'),[location,setLocation]=useState(''),[incidentAt,setIncidentAt]=useState('');
 const [message,setMessage]=useState(''),[busy,setBusy]=useState(false),[drafts,setDrafts]=useState<Record<string,Draft>>({});
 const load=useCallback(async()=>{
  if(!supabase||!ctx.schoolId||!session)return;
  const [a,b,m]=await Promise.all([
   fetchSchoolRows(supabase.from('schoolpro_students').select('id,first_name,last_name,class_id,class_name').eq('school_id',ctx.schoolId).order('id')),
   supabase.from('schoolpro_discipline_records').select('id,student_id,incident,action_taken,status,created_at,session,category,severity,location,incident_at,student_response,guardian_contact_status,guardian_contacted_at,guardian_contact_note,follow_up_at,follow_up_outcome,resolved_at,assigned_to').eq('school_id',ctx.schoolId).eq('session',session).order('created_at',{ascending:false}).limit(250),
   supabase.from('schoolpro_members').select('id,role,profile:profiles!schoolpro_members_user_id_fkey(first_name,last_name)').eq('school_id',ctx.schoolId).eq('status','active').order('created_at')
  ]);
  if(a.error||b.error){setMessage('Student discipline cases could not be loaded.');return;}
  setStudents(await schoolSessionStudents(ctx.schoolId,session,a.data||[]));setMembers((m.data||[]) as Member[]);
  const records=(b.data||[]) as Concern[];setRows(records);
  setDrafts(Object.fromEntries(records.map(r=>[r.id,{action_taken:r.action_taken||'',severity:r.severity||'moderate',student_response:r.student_response||'',guardian_contact_status:r.guardian_contact_status||'not_required',guardian_contact_note:r.guardian_contact_note||'',follow_up_at:r.follow_up_at||'',follow_up_outcome:r.follow_up_outcome||'',assigned_to:r.assigned_to||''}])));
 },[ctx.schoolId,session]);
 useEffect(()=>{setStudents([]);setRows([]);void load();},[load]);
 useEffect(()=>{if(ids.length>0&&student&&!ids.includes(student))setStudent('')},[ids,student]);
 const names=useMemo(()=>new Map(students.map(s=>[s.id,`${s.first_name} ${s.last_name} · ${s.class_name}`])),[students]);
 async function report(){
  if(!supabase||!user||!student||incident.trim().length<5||busy)return;
  setBusy(true);
  const {error}=await supabase.from('schoolpro_discipline_records').insert({
   school_id:ctx.schoolId,student_id:student,incident:incident.trim(),session,status:'open',created_by:user.id,
   category,severity,location:location.trim()||null,incident_at:incidentAt?new Date(incidentAt).toISOString():new Date().toISOString(),
   guardian_contact_status:'pending'
  });
  setBusy(false);
  if(error)setMessage('The incident could not be recorded. Check your school role and student access.');
  else{setIncident('');setLocation('');setIncidentAt('');setMessage('Incident reported. The case and subsequent updates are retained in the discipline history.');await load();}
 }
 function updateDraft(id:string,key:keyof Draft,value:string){setDrafts(x=>({...x,[id]:{...(x[id]||{action_taken:'',severity:'moderate',student_response:'',guardian_contact_status:'not_required',guardian_contact_note:'',follow_up_at:'',follow_up_outcome:''}),[key]:value}}));}
 async function review(row:Concern,close:boolean){
  if(!supabase||!leadership||busy)return;
  const d=drafts[row.id];if(!d)return;
  setBusy(true);
  const {error}=await supabase.from('schoolpro_discipline_records').update({
   action_taken:d.action_taken.trim()||null,severity:d.severity,student_response:d.student_response.trim()||null,
   guardian_contact_status:d.guardian_contact_status,
   guardian_contacted_at:d.guardian_contact_status==='contacted'?(row.guardian_contacted_at||new Date().toISOString()):null,
   guardian_contact_note:d.guardian_contact_note.trim()||null,
   follow_up_at:d.follow_up_at||null,follow_up_outcome:d.follow_up_outcome.trim()||null,assigned_to:d.assigned_to||null,
   status:close?'resolved':'open'
  }).eq('id',row.id).eq('school_id',ctx.schoolId).select('id').maybeSingle();
  setBusy(false);
  setMessage(error?'The case update could not be saved.':'Case update saved to the discipline history.');
  if(!error)await load();
 }
 return <ModulePage product="schoolpro" sections={schoolSections} title="Student discipline & case management" description="Record incidents by category and severity, capture student responses, parent or guardian contact, interventions, follow-up and case resolution." userName={ctx.schoolName} userRole={ctx.role}>
  <Card><h2 className="font-bold">Report a student incident</h2><SchoolStudentFilters schoolId={ctx.schoolId||''} students={students} session={session} onChange={setIds}/>
   <div className="mt-3 grid gap-3 md:grid-cols-2">
    <div><SchoolStudentSelect schoolId={ctx.schoolId} students={students} session={session} value={student} onChange={setStudent}/></div>
    <label className="text-sm font-semibold">Incident category<select className="mt-1 w-full rounded-xl border p-3" value={category} onChange={e=>setCategory(e.target.value)}>{categories.map(x=><option key={x} value={x}>{label(x)}</option>)}</select></label>
    <label className="text-sm font-semibold">Severity<select className="mt-1 w-full rounded-xl border p-3" value={severity} onChange={e=>setSeverity(e.target.value)}>{severities.map(x=><option key={x} value={x}>{label(x)}</option>)}</select></label>
    <label className="text-sm font-semibold">Incident date and time<input type="datetime-local" className="mt-1 w-full rounded-xl border p-3" value={incidentAt} onChange={e=>setIncidentAt(e.target.value)}/></label>
    <label className="text-sm font-semibold">Location<input className="mt-1 w-full rounded-xl border p-3" value={location} onChange={e=>setLocation(e.target.value)} placeholder="Classroom, playground, route…"/></label>
    <label className="text-sm font-semibold md:col-span-2">Factual incident description<textarea className="mt-1 w-full rounded-xl border p-3" rows={4} value={incident} onChange={e=>setIncident(e.target.value)} maxLength={4000} placeholder="Record what was observed, when and by whom. Avoid assumptions."/></label>
   </div>
   <Button className="mt-3" disabled={busy||!student||incident.trim().length<5} onClick={()=>void report()}>Report incident</Button>
   {message&&<p role="status" className="mt-3 text-sm">{message}</p>}
  </Card>
  <div className="grid gap-4">{rows.filter(r=>!r.student_id||ids.length===0||ids.includes(r.student_id)).map(r=>{
   const d=drafts[r.id]||{action_taken:'',severity:r.severity||'moderate',student_response:'',guardian_contact_status:'pending',guardian_contact_note:'',follow_up_at:'',follow_up_outcome:'',assigned_to:r.assigned_to||''};
   return <Card key={r.id}>
    <div className="flex flex-wrap justify-between gap-2"><div><h3 className="font-bold">{names.get(r.student_id)||'Student concern'}</h3><p className="text-xs text-muted">{new Date(r.incident_at||r.created_at).toLocaleString()} · {label(r.category||'general')} · {label(r.severity||'moderate')}</p></div><span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold">{label(r.status)}</span></div>
    {r.location&&<p className="mt-2 text-sm">Location: {r.location}</p>}<p className="mt-3 whitespace-pre-wrap text-sm">{r.incident}</p>
    {r.action_taken&&<p className="mt-2 text-sm"><b>Intervention:</b> {r.action_taken}</p>}{r.assigned_to&&<p className="mt-1 text-sm"><b>Assigned follow-up:</b> {members.find(m=>m.id===r.assigned_to)?.profile?.[0]?[members.find(m=>m.id===r.assigned_to)?.profile?.[0]?.first_name,members.find(m=>m.id===r.assigned_to)?.profile?.[0]?.last_name].filter(Boolean).join(' '):'Assigned staff member'}</p>}
    {r.student_response&&<p className="mt-2 whitespace-pre-wrap text-sm"><b>Student response:</b> {r.student_response}</p>}
    {r.guardian_contact_note&&<p className="mt-2 text-sm"><b>Parent/guardian contact:</b> {label(r.guardian_contact_status)} · {r.guardian_contact_note}</p>}
    {r.follow_up_at&&<p className="mt-2 text-sm"><b>Follow-up:</b> {r.follow_up_at} {r.follow_up_outcome||''}</p>}
    {leadership&&r.status!=='resolved'&&<div className="mt-4 space-y-3 border-t pt-3">
     <div className="grid gap-3 md:grid-cols-2">
      <label className="text-sm font-semibold">Severity<select className="mt-1 w-full rounded-xl border p-3" value={d.severity} onChange={e=>updateDraft(r.id,'severity',e.target.value)}>{severities.map(x=><option key={x}>{x}</option>)}</select></label>
      <label className="text-sm font-semibold">Parent/guardian contact<select className="mt-1 w-full rounded-xl border p-3" value={d.guardian_contact_status} onChange={e=>updateDraft(r.id,'guardian_contact_status',e.target.value)}>{['pending','contacted','unable_to_contact','not_required'].map(x=><option key={x} value={x}>{label(x)}</option>)}</select></label>
      <label className="text-sm font-semibold md:col-span-2">Action / intervention<textarea className="mt-1 w-full rounded-xl border p-3" rows={2} value={d.action_taken} onChange={e=>updateDraft(r.id,'action_taken',e.target.value)}/></label>
      <label className="text-sm font-semibold md:col-span-2">Student response<textarea className="mt-1 w-full rounded-xl border p-3" rows={2} value={d.student_response} onChange={e=>updateDraft(r.id,'student_response',e.target.value)}/></label>
      <label className="text-sm font-semibold md:col-span-2">Parent/guardian contact note<textarea className="mt-1 w-full rounded-xl border p-3" rows={2} value={d.guardian_contact_note} onChange={e=>updateDraft(r.id,'guardian_contact_note',e.target.value)}/></label>
      <label className="text-sm font-semibold">Assigned staff member<select className="mt-1 w-full rounded-xl border p-3" value={d.assigned_to} onChange={e=>updateDraft(r.id,'assigned_to',e.target.value)}><option value="">Unassigned</option>{members.map(m=><option key={m.id} value={m.id}>{[m.profile?.[0]?.first_name,m.profile?.[0]?.last_name].filter(Boolean).join(' ')||m.role}</option>)}</select></label>
      <label className="text-sm font-semibold">Follow-up date<input type="date" className="mt-1 w-full rounded-xl border p-3" value={d.follow_up_at} onChange={e=>updateDraft(r.id,'follow_up_at',e.target.value)}/></label>
      <label className="text-sm font-semibold">Follow-up outcome<input className="mt-1 w-full rounded-xl border p-3" value={d.follow_up_outcome} onChange={e=>updateDraft(r.id,'follow_up_outcome',e.target.value)}/></label>
     </div>
     <div className="flex flex-wrap gap-2"><Button disabled={busy} onClick={()=>void review(r,false)}>Save case update</Button><Button variant="secondary" disabled={busy} onClick={()=>void review(r,true)}>Resolve case</Button></div>
    </div>}
    {r.status==='resolved'&&r.resolved_at&&<p className="mt-3 text-xs text-muted">Resolved {new Date(r.resolved_at).toLocaleString()}</p>}
   </Card>;
  })}</div>
  {!rows.length&&<Card><p className="text-sm text-muted">No student discipline cases are recorded for this session.</p></Card>}
 </ModulePage>;
}
