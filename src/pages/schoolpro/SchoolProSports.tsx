import {useCallback,useEffect,useMemo,useState} from 'react';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {schoolSections,teacherSections} from './schoolShared';
import {canManageSchoolOperation} from '@/lib/schoolOperationalRoles';

type Team={id:string;name:string;sport:string;age_group:string|null;section_key:string|null;house_id:string|null;exclusive_membership:boolean;is_active:boolean};
type Staff={id:string;role:string;profile:{first_name:string|null;last_name:string|null;email:string}|null};
type Student={id:string;first_name:string;middle_name:string|null;last_name:string;admission_number:string|null;class_name:string|null};
type Session={id:string;team_id:string;title:string;starts_at:string;ends_at:string|null;venue:string|null;status:string};
type Fixture={id:string;event_id:string|null;home_entry_id:string|null;away_entry_id:string|null;home_team_id:string;away_team_id:string;scheduled_at:string;venue:string|null;status:string;home_score:number|null;away_score:number|null;result_version:number;result_notes:string|null};
type Coach={id:string;team_id:string;member_id:string;ended_at:string|null};
type CompetitionEntry={id:string;event_id:string;entry_name:string;house_id:string|null};
type ResultHistory={id:string;fixture_id:string;version:number;home_score:number;away_score:number;status:string;result_notes:string|null;action:string;changed_at:string};
type FixtureAudit={id:string;fixture_id:string;previous_scheduled_at:string|null;new_scheduled_at:string|null;previous_venue:string|null;new_venue:string|null;previous_status:string|null;new_status:string|null;changed_at:string};
type Roster={id:string;team_id:string;student_id:string;ended_at:string|null;first_name?:string;middle_name?:string|null;last_name?:string;admission_number?:string|null;class_name?:string|null};
const field='mt-1 w-full rounded-lg border border-border bg-white p-2.5 text-sm';
const localDate=(value:string)=>{if(!value)return '';const d=new Date(value);return new Date(d.getTime()-d.getTimezoneOffset()*60000).toISOString().slice(0,16)};
export function SchoolProSports(){
 const ctx=useSchoolProContext(),{user}=useAuth();
 const roleCanManage=canManageSchoolOperation('games',ctx.role);
 const [hasGamesPermission,setHasGamesPermission]=useState(false);
 const canManage=roleCanManage||hasGamesPermission;
 const sections=['teacher','class_teacher'].includes(ctx.role.toLowerCase().replaceAll(' ','_'))?teacherSections:schoolSections;
 const [teams,setTeams]=useState<Team[]>([]),[houses,setHouses]=useState<{id:string;name:string}[]>([]);
 const [staff,setStaff]=useState<Staff[]>([]),[students,setStudents]=useState<Student[]>([]);
 const [coaches,setCoaches]=useState<Coach[]>([]),[roster,setRoster]=useState<Roster[]>([]);
 const [sessions,setSessions]=useState<Session[]>([]),[fixtures,setFixtures]=useState<Fixture[]>([]);
 const [resultHistory,setResultHistory]=useState<ResultHistory[]>([]),[fixtureAudit,setFixtureAudit]=useState<FixtureAudit[]>([]);
 const [events,setEvents]=useState<{id:string;title:string;event_type:string;status:string}[]>([]),[competitionEntries,setCompetitionEntries]=useState<CompetitionEntry[]>([]);
 const [message,setMessage]=useState(''),[error,setError]=useState(''),[busy,setBusy]=useState(false);
 const [teamForm,setTeamForm]=useState({name:'',sport:'',age_group:'',section_key:'',house_id:'',exclusive_membership:true});
 const [coachForm,setCoachForm]=useState({team_id:'',member_id:''}),[memberForm,setMemberForm]=useState({team_id:'',student_id:''});
 const [sessionForm,setSessionForm]=useState({team_id:'',title:'',starts_at:'',ends_at:'',venue:'',details:''});
 const [fixtureForm,setFixtureForm]=useState({event_id:'',home_entry_id:'',away_entry_id:'',home_team_id:'',away_team_id:'',scheduled_at:'',venue:''});
 const [resultForm,setResultForm]=useState({fixture_id:'',home_score:'',away_score:'',notes:'',complete:true});
 const [search,setSearch]=useState('');
 const [scheduleDrafts,setScheduleDrafts]=useState<Record<string,string>>({});
 useEffect(()=>{
  if(roleCanManage){setHasGamesPermission(false);return;}
  if(!supabase||!ctx.schoolId){setHasGamesPermission(false);return;}
  let current=true;
  void supabase.rpc('schoolpro_user_permissions',{p_school:ctx.schoolId}).then(({data,error})=>{
   if(current)setHasGamesPermission(!error&&Array.isArray(data)&&data.includes('games'));
  });
  return()=>{current=false;};
 },[ctx.schoolId,roleCanManage]);
 const load=useCallback(async()=>{
  if(!supabase||!ctx.schoolId)return;
  setError('');
  const [t,c,r,a,f,rh,fa]=await Promise.all([
   supabase.from('schoolpro_sports_teams').select('id,name,sport,age_group,section_key,house_id,exclusive_membership,is_active').eq('school_id',ctx.schoolId).order('sport').order('name'),
   supabase.from('schoolpro_sports_team_coaches').select('id,team_id,member_id,ended_at').eq('school_id',ctx.schoolId).is('ended_at',null),
   supabase.from('schoolpro_sports_team_members').select('id,team_id,student_id,ended_at').eq('school_id',ctx.schoolId).is('ended_at',null),
   supabase.from('schoolpro_sports_training_sessions').select('id,team_id,title,starts_at,ends_at,venue,status').eq('school_id',ctx.schoolId).order('starts_at',{ascending:false}).limit(250),
   supabase.from('schoolpro_sports_fixtures').select('id,event_id,home_entry_id,away_entry_id,home_team_id,away_team_id,scheduled_at,venue,status,home_score,away_score,result_version,result_notes').eq('school_id',ctx.schoolId).order('scheduled_at',{ascending:false}).limit(250),
   supabase.from('schoolpro_sports_fixture_result_history').select('id,fixture_id,version,home_score,away_score,status,result_notes,action,changed_at').eq('school_id',ctx.schoolId).order('changed_at',{ascending:false}).limit(500),
   supabase.from('schoolpro_sports_fixture_audit').select('id,fixture_id,previous_scheduled_at,new_scheduled_at,previous_venue,new_venue,previous_status,new_status,changed_at').eq('school_id',ctx.schoolId).order('changed_at',{ascending:false}).limit(500)
  ]);
  if([t,c,r,a,f,rh,fa].some(x=>x.error)){setError('Sports records could not all be loaded. Confirm your Games access and refresh.');return;}
  setTeams((t.data||[]) as Team[]);setCoaches((c.data||[]) as Coach[]);
  setSessions((a.data||[]) as Session[]);setFixtures((f.data||[]) as Fixture[]);
  setResultHistory((rh.data||[]) as ResultHistory[]);setFixtureAudit((fa.data||[]) as FixtureAudit[]);
  if(canManage){
   const [h,s,m,e,ce]=await Promise.all([
    supabase.from('schoolpro_houses').select('id,name').eq('school_id',ctx.schoolId).eq('is_active',true).order('sort_order'),
    supabase.from('schoolpro_students').select('id,first_name,middle_name,last_name,admission_number,class_name').eq('school_id',ctx.schoolId).eq('status','active').order('last_name').limit(2000),
    supabase.from('schoolpro_members').select('id,role,profile:profiles!schoolpro_members_user_id_fkey(first_name,last_name,email)').eq('school_id',ctx.schoolId).eq('status','active').eq('employment_status','active').in('role',['teacher','class_teacher']).order('created_at'),
    supabase.from('schoolpro_competition_events').select('id,title,event_type,status').eq('school_id',ctx.schoolId).in('event_type',['sports','athletics']).order('created_at',{ascending:false}),
    supabase.from('schoolpro_competition_entries').select('id,event_id,entry_name,house_id').eq('school_id',ctx.schoolId).order('created_at',{ascending:false})
   ]);
   if([h,s,m,e,ce].some(x=>x.error)){setError('School roster or canonical Houses/Competitions could not be loaded.');return;}
   setHouses(h.data||[]);setStudents((s.data||[]) as Student[]);setStaff((m.data||[]) as unknown as Staff[]);
   setEvents((e.data||[]) as typeof events);setCompetitionEntries((ce.data||[]) as CompetitionEntry[]);setRoster((r.data||[]) as Roster[]);
  }else{
   const coachRows=await Promise.all((t.data||[]).map(team=>supabase!.rpc('schoolpro_sports_coach_roster',{p_school:ctx.schoolId,p_team:team.id})));
   if(coachRows.some(x=>x.error)){setError('Your assigned team roster could not be loaded.');return;}
   const visible=(coachRows.flatMap(x=>x.data||[]) as any[]).map(x=>({
    id:x.student_id,team_id:x.team_id,student_id:x.student_id,ended_at:null,
    first_name:x.first_name,middle_name:x.middle_name,last_name:x.last_name,
    admission_number:x.admission_number,class_name:x.class_name
   }));
   setRoster(visible as Roster[]);
   setStudents(visible as unknown as Student[]);
   setHouses([]);setStaff([]);setEvents([]);setCompetitionEntries([]);
  }
 },[ctx.schoolId,canManage]);
 useEffect(()=>{setTeams([]);setHouses([]);setStaff([]);setStudents([]);setCoaches([]);setRoster([]);setSessions([]);setFixtures([]);setResultHistory([]);setFixtureAudit([]);setCompetitionEntries([]);void load()},[load]);
 const teamName=(id:string)=>teams.find(t=>t.id===id)?.name||'Team';
 const staffName=(id:string)=>{const s=staff.find(x=>x.id===id);return [s?.profile?.first_name,s?.profile?.last_name].filter(Boolean).join(' ')||s?.profile?.email||'Teaching staff';};
 const studentName=(id:string)=>{const s=students.find(x=>x.id===id);return s?[s.first_name,s.middle_name,s.last_name].filter(Boolean).join(' '):'Student';};
 const houseName=(id:string|null)=>houses.find(h=>h.id===id)?.name||'No house link';
 const activeTeams=teams.filter(t=>t.is_active);
 const filteredTeams=useMemo(()=>teams.filter(t=>!search||[t.name,t.sport,t.age_group,t.section_key].join(' ').toLowerCase().includes(search.toLowerCase())),[teams,search]);
 async function save(action:()=>PromiseLike<{error:any;data?:any}>,success:string){
  if(!supabase||busy)return;setBusy(true);setError('');setMessage('');
  try{const result=await action();if(result.error)throw result.error;setMessage(success);await load();}
  catch(e:any){setError(e?.message||'The sports operation could not be saved.');}
  finally{setBusy(false);}
 }
 async function createTeam(){
  if(!supabase||!ctx.schoolId||!teamForm.name.trim()||!teamForm.sport.trim())return;
  await save(()=>supabase!.from('schoolpro_sports_teams').insert({school_id:ctx.schoolId,name:teamForm.name.trim(),sport:teamForm.sport.trim(),age_group:teamForm.age_group.trim()||null,section_key:teamForm.section_key.trim()||null,house_id:teamForm.house_id||null,exclusive_membership:teamForm.exclusive_membership,created_by:user?.id||null}).select('id'),'Sports team created.');
  setTeamForm({name:'',sport:'',age_group:'',section_key:'',house_id:'',exclusive_membership:true});
 }
 async function appointCoach(){
  if(!supabase||!coachForm.team_id||!coachForm.member_id)return;
  await save(()=>supabase!.from('schoolpro_sports_team_coaches').insert({school_id:ctx.schoolId,team_id:coachForm.team_id,member_id:coachForm.member_id,assigned_by:user?.id||null}).select('id'),'Coach appointed to team.');
  setCoachForm({team_id:'',member_id:''});
 }
 async function enrollStudent(){
  if(!supabase||!memberForm.team_id||!memberForm.student_id)return;
  await save(()=>supabase!.from('schoolpro_sports_team_members').insert({school_id:ctx.schoolId,team_id:memberForm.team_id,student_id:memberForm.student_id,assigned_by:user?.id||null}).select('id'),'Student enrolled in sports team.');
  setMemberForm({team_id:'',student_id:''});
 }
 async function endCoach(id:string){if(!supabase)return;await save(()=>supabase!.from('schoolpro_sports_team_coaches').update({ended_at:new Date().toISOString(),ended_by:user?.id||null,end_reason:'Appointment ended by school management'}).eq('id',id).eq('school_id',ctx.schoolId).select('id'),'Coach appointment ended; history retained.');}
 async function removeMember(id:string){if(!supabase)return;await save(()=>supabase!.from('schoolpro_sports_team_members').update({ended_at:new Date().toISOString(),end_reason:'Squad membership ended by school management'}).eq('id',id).eq('school_id',ctx.schoolId).select('id'),'Student removed from active squad; enrollment history retained.');}
 async function scheduleTraining(){
  if(!supabase||!sessionForm.team_id||!sessionForm.title.trim()||!sessionForm.starts_at)return;
  await save(()=>supabase!.from('schoolpro_sports_training_sessions').insert({school_id:ctx.schoolId,team_id:sessionForm.team_id,title:sessionForm.title.trim(),starts_at:new Date(sessionForm.starts_at).toISOString(),ends_at:sessionForm.ends_at?new Date(sessionForm.ends_at).toISOString():null,venue:sessionForm.venue.trim()||null,details:sessionForm.details.trim()||null,created_by:user?.id||null}).select('id'),'Training session scheduled.');
  setSessionForm({team_id:'',title:'',starts_at:'',ends_at:'',venue:'',details:''});
 }
 async function createFixture(){
  if(!supabase||!fixtureForm.home_team_id||!fixtureForm.away_team_id||!fixtureForm.scheduled_at||fixtureForm.home_team_id===fixtureForm.away_team_id||(fixtureForm.event_id&&(!fixtureForm.home_entry_id||!fixtureForm.away_entry_id||fixtureForm.home_entry_id===fixtureForm.away_entry_id)))return;
  await save(()=>supabase!.from('schoolpro_sports_fixtures').insert({school_id:ctx.schoolId,event_id:fixtureForm.event_id||null,home_entry_id:fixtureForm.event_id?fixtureForm.home_entry_id:null,away_entry_id:fixtureForm.event_id?fixtureForm.away_entry_id:null,home_team_id:fixtureForm.home_team_id,away_team_id:fixtureForm.away_team_id,scheduled_at:new Date(fixtureForm.scheduled_at).toISOString(),venue:fixtureForm.venue.trim()||null,created_by:user?.id||null}).select('id'),'Fixture created.');
  setFixtureForm({event_id:'',home_entry_id:'',away_entry_id:'',home_team_id:'',away_team_id:'',scheduled_at:'',venue:''});
 }
 async function recordResult(){
  if(!supabase||!resultForm.fixture_id||resultForm.home_score===''||resultForm.away_score==='')return;
  const home=Number(resultForm.home_score),away=Number(resultForm.away_score);
  if(!Number.isInteger(home)||!Number.isInteger(away)||home<0||away<0){setError('Scores must be whole numbers of zero or greater.');return;}
  await save(()=>supabase!.rpc('schoolpro_record_sports_fixture_result',{p_school:ctx.schoolId,p_fixture:resultForm.fixture_id,p_home_score:home,p_away_score:away,p_notes:resultForm.notes||null,p_complete:resultForm.complete}),'Fixture result recorded with an audit version.');
  setResultForm({fixture_id:'',home_score:'',away_score:'',notes:'',complete:true});
 }
 async function updateTrainingStatus(id:string,status:string){
  if(!supabase)return;await save(()=>supabase!.from('schoolpro_sports_training_sessions').update({status,updated_at:new Date().toISOString()}).eq('id',id).eq('school_id',ctx.schoolId).select('id'),'Training session updated.');
 }
 async function cancelFixture(id:string){if(!supabase)return;await save(()=>supabase!.from('schoolpro_sports_fixtures').update({status:'cancelled',updated_at:new Date().toISOString()}).eq('id',id).eq('school_id',ctx.schoolId).select('id'),'Fixture cancelled; schedule audit retained.');}
 async function updateFixtureSchedule(id:string,scheduled:string,venue:string){
  if(!supabase||!scheduled)return;await save(()=>supabase!.from('schoolpro_sports_fixtures').update({scheduled_at:new Date(scheduled).toISOString(),venue:venue||null,status:'scheduled',updated_at:new Date().toISOString()}).eq('id',id).eq('school_id',ctx.schoolId).select('id'),'Fixture rescheduled; audit history retained.');
 }
 async function archiveTeam(team:Team){if(!supabase)return;await save(()=>supabase!.from('schoolpro_sports_teams').update({is_active:!team.is_active,updated_at:new Date().toISOString()}).eq('id',team.id).eq('school_id',ctx.schoolId).select('id'),team.is_active?'Team archived.':'Team reactivated.');}
 return <ModulePage product="schoolpro" sections={sections} title="Sports Teams & Operations" description="Manage school sports teams, teaching-staff coaches, active student squads, training sessions, fixtures and audited match results. Houses and competitions remain linked to the canonical Games model." userName={ctx.schoolName} userRole={ctx.role} metrics={[{label:'Active teams',value:String(activeTeams.length)},{label:'Active squad members',value:String(roster.length)},{label:'Training sessions',value:String(sessions.length)},{label:'Fixtures',value:String(fixtures.length)}]}>
  {(error||message)&&<div role="status" className={error?'rounded-xl border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700':'rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-700'}>{error||message}</div>}
  <p className="text-sm text-muted">Every operation is scoped to the selected school. Coaches can read only their appointed teams, rosters, sessions and fixtures. Team houses use the existing Houses catalogue; linked competition events continue to use the existing scoring and house-points workflow.</p>
  <input className={field} placeholder="Search teams and sports" value={search} onChange={e=>setSearch(e.target.value)}/>
  <div className="grid gap-5 xl:grid-cols-2">
   <Card><h3 className="font-bold">Sports teams / squads</h3>
    {canManage&&<div className="mt-3 grid gap-2 sm:grid-cols-2">
     <label className="text-sm">Team name<input className={field} value={teamForm.name} onChange={e=>setTeamForm(p=>({...p,name:e.target.value}))}/></label>
     <label className="text-sm">Sport<input className={field} placeholder="Football, Athletics, Basketball…" value={teamForm.sport} onChange={e=>setTeamForm(p=>({...p,sport:e.target.value}))}/></label>
     <label className="text-sm">Age group<input className={field} placeholder="U-12, U-15…" value={teamForm.age_group} onChange={e=>setTeamForm(p=>({...p,age_group:e.target.value}))}/></label>
     <label className="text-sm">Section / class grouping<input className={field} placeholder="Primary, JSS, SSS…" value={teamForm.section_key} onChange={e=>setTeamForm(p=>({...p,section_key:e.target.value}))}/></label>
     <label className="text-sm">Linked house<select className={field} value={teamForm.house_id} onChange={e=>setTeamForm(p=>({...p,house_id:e.target.value}))}><option value="">No house link</option>{houses.map(h=><option key={h.id} value={h.id}>{h.name}</option>)}</select></label>
     <label className="flex items-center gap-2 text-sm sm:col-span-2"><input type="checkbox" checked={teamForm.exclusive_membership} onChange={e=>setTeamForm(p=>({...p,exclusive_membership:e.target.checked}))}/>One active squad per student (exclusive membership)</label>
     <Button disabled={busy||!teamForm.name.trim()||!teamForm.sport.trim()} onClick={()=>void createTeam()}>Create team</Button>
    </div>}
    <div className="mt-4 space-y-2">{filteredTeams.map(t=><div key={t.id} className="rounded-lg border p-3"><div className="flex flex-wrap justify-between gap-2"><b>{t.name}</b><span className="text-xs text-muted">{t.is_active?'Active':'Archived'}</span></div><p className="text-xs text-muted">{t.sport} · {t.age_group||'Any age'} · {t.section_key||'All sections'} · {houseName(t.house_id)}</p><p className="mt-1 text-xs text-muted">{coaches.filter(c=>c.team_id===t.id).map(c=>staffName(c.member_id)).join(', ')||'No active coach appointed'}</p><p className="text-xs text-muted">{roster.filter(r=>r.team_id===t.id).length} active squad members</p>{canManage&&<Button size="sm" variant="secondary" className="mt-2" disabled={busy} onClick={()=>void archiveTeam(t)}>{t.is_active?'Archive team':'Reactivate team'}</Button>}</div>)}{!filteredTeams.length&&<p className="text-sm text-muted">No sports teams are available in this school.</p>}</div>
   </Card>
   <Card><h3 className="font-bold">Coach appointments & student enrollment</h3>
    {canManage&&<div className="mt-3 space-y-3">
     <div className="grid gap-2 sm:grid-cols-2"><select className={field} value={coachForm.team_id} onChange={e=>setCoachForm(p=>({...p,team_id:e.target.value}))}><option value="">Choose team</option>{activeTeams.map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select><select className={field} value={coachForm.member_id} onChange={e=>setCoachForm(p=>({...p,member_id:e.target.value}))}><option value="">Choose active teaching staff</option>{staff.map(s=><option key={s.id} value={s.id}>{staffName(s.id)} · {s.role.replaceAll('_',' ')}</option>)}</select></div><Button disabled={busy||!coachForm.team_id||!coachForm.member_id} onClick={()=>void appointCoach()}>Appoint coach</Button>
     <div className="grid gap-2 sm:grid-cols-2"><select className={field} value={memberForm.team_id} onChange={e=>setMemberForm(p=>({...p,team_id:e.target.value}))}><option value="">Choose team</option>{activeTeams.map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select><select className={field} value={memberForm.student_id} onChange={e=>setMemberForm(p=>({...p,student_id:e.target.value}))}><option value="">Choose active student</option>{students.map(s=><option key={s.id} value={s.id}>{[s.first_name,s.middle_name,s.last_name].filter(Boolean).join(' ')} · {s.admission_number||s.class_name||'Student'}</option>)}</select></div><Button disabled={busy||!memberForm.team_id||!memberForm.student_id} onClick={()=>void enrollStudent()}>Enroll student</Button>
    </div>}
    <div className="mt-4 space-y-2">{teams.map(t=><div key={t.id} className="rounded-lg border p-2"><b className="text-sm">{t.name}</b><div className="mt-1 space-y-1 text-xs text-muted">{coaches.filter(c=>c.team_id===t.id).map(c=><p key={c.id} className="flex flex-wrap items-center justify-between gap-2">Coach: {staffName(c.member_id)}{canManage&&<Button size="sm" variant="secondary" disabled={busy} onClick={()=>void endCoach(c.id)}>End appointment</Button>}</p>)}{roster.filter(r=>r.team_id===t.id).map(r=><p key={r.id} className="flex flex-wrap items-center justify-between gap-2">Student: {studentName(r.student_id)}{canManage&&<Button size="sm" variant="secondary" disabled={busy} onClick={()=>void removeMember(r.id)}>Remove from squad</Button>}</p>)}</div></div>)}</div>
   </Card>
   <Card><h3 className="font-bold">Training & activity schedule</h3>
    {canManage&&<div className="mt-3 grid gap-2 sm:grid-cols-2">
     <select className={field} value={sessionForm.team_id} onChange={e=>setSessionForm(p=>({...p,team_id:e.target.value}))}><option value="">Choose team</option>{activeTeams.map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select>
     <input className={field} placeholder="Session title" value={sessionForm.title} onChange={e=>setSessionForm(p=>({...p,title:e.target.value}))}/>
     <label className="text-sm">Starts<input type="datetime-local" className={field} value={sessionForm.starts_at} onChange={e=>setSessionForm(p=>({...p,starts_at:e.target.value}))}/></label>
     <label className="text-sm">Ends (optional)<input type="datetime-local" className={field} value={sessionForm.ends_at} onChange={e=>setSessionForm(p=>({...p,ends_at:e.target.value}))}/></label>
     <input className={field} placeholder="Venue" value={sessionForm.venue} onChange={e=>setSessionForm(p=>({...p,venue:e.target.value}))}/>
     <input className={field} placeholder="Details" value={sessionForm.details} onChange={e=>setSessionForm(p=>({...p,details:e.target.value}))}/>
     <Button disabled={busy||!sessionForm.team_id||!sessionForm.title.trim()||!sessionForm.starts_at} onClick={()=>void scheduleTraining()}>Schedule session</Button>
    </div>}
    <div className="mt-4 space-y-2">{sessions.map(s=><div key={s.id} className="rounded-lg border p-3 text-sm"><div className="flex flex-wrap justify-between gap-2"><b>{s.title}</b><span className="text-xs text-muted">{s.status}</span></div><p className="text-xs text-muted">{teamName(s.team_id)} · {new Date(s.starts_at).toLocaleString()} · {s.venue||'Venue not set'}</p>{canManage&&s.status==='scheduled'&&<Button size="sm" variant="secondary" className="mt-2" disabled={busy} onClick={()=>void updateTrainingStatus(s.id,'cancelled')}>Cancel session</Button>}</div>)}{!sessions.length&&<p className="text-sm text-muted">No training sessions scheduled.</p>}</div>
   </Card>
   <Card><h3 className="font-bold">Fixtures & match results</h3>
    {canManage&&<div className="mt-3 grid gap-2 sm:grid-cols-2">
     <select className={field} value={fixtureForm.event_id} onChange={e=>setFixtureForm(p=>({...p,event_id:e.target.value,home_entry_id:'',away_entry_id:''}))}><option value="">No linked competition event</option>{events.map(e=><option key={e.id} value={e.id}>{e.title} · {e.event_type}</option>)}</select>{fixtureForm.event_id&&<><select className={field} value={fixtureForm.home_entry_id} onChange={e=>setFixtureForm(p=>({...p,home_entry_id:e.target.value}))}><option value="">Canonical home entry</option>{competitionEntries.filter(x=>x.event_id===fixtureForm.event_id).map(x=><option key={x.id} value={x.id}>{x.entry_name}</option>)}</select><select className={field} value={fixtureForm.away_entry_id} onChange={e=>setFixtureForm(p=>({...p,away_entry_id:e.target.value}))}><option value="">Canonical away entry</option>{competitionEntries.filter(x=>x.event_id===fixtureForm.event_id).map(x=><option key={x.id} value={x.id}>{x.entry_name}</option>)}</select></>}
     <select className={field} value={fixtureForm.home_team_id} onChange={e=>setFixtureForm(p=>({...p,home_team_id:e.target.value}))}><option value="">Home team</option>{activeTeams.map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select>
     <select className={field} value={fixtureForm.away_team_id} onChange={e=>setFixtureForm(p=>({...p,away_team_id:e.target.value}))}><option value="">Away team</option>{activeTeams.map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select>
     <label className="text-sm">Kick-off<input type="datetime-local" className={field} value={fixtureForm.scheduled_at} onChange={e=>setFixtureForm(p=>({...p,scheduled_at:e.target.value}))}/></label>
     <input className={field} placeholder="Venue" value={fixtureForm.venue} onChange={e=>setFixtureForm(p=>({...p,venue:e.target.value}))}/>
     <Button disabled={busy||!fixtureForm.home_team_id||!fixtureForm.away_team_id||fixtureForm.home_team_id===fixtureForm.away_team_id||!fixtureForm.scheduled_at||(Boolean(fixtureForm.event_id)&&(!fixtureForm.home_entry_id||!fixtureForm.away_entry_id||fixtureForm.home_entry_id===fixtureForm.away_entry_id))} onClick={()=>void createFixture()}>Create fixture</Button>
    </div>}
    <div className="mt-4 space-y-2">{fixtures.map(f=><div key={f.id} className="rounded-lg border p-3 text-sm"><div className="flex flex-wrap justify-between gap-2"><b>{teamName(f.home_team_id)} vs {teamName(f.away_team_id)}</b><span className="text-xs text-muted">{f.status}</span></div><p className="text-xs text-muted">{new Date(f.scheduled_at).toLocaleString()} · {f.venue||'Venue not set'} · {f.home_score??'—'} : {f.away_score??'—'} · Result v{f.result_version}</p><div className="mt-2 space-y-1 text-xs text-muted">{resultHistory.filter(h=>h.fixture_id===f.id).map(h=><p key={h.id}>Result v{h.version} ({h.action}): {h.home_score}–{h.away_score} · {new Date(h.changed_at).toLocaleString()} {h.result_notes?`· ${h.result_notes}`:''}</p>)}{fixtureAudit.filter(a=>a.fixture_id===f.id).map(a=><p key={a.id}>Schedule audit: {a.previous_scheduled_at?new Date(a.previous_scheduled_at).toLocaleString():'—'} → {a.new_scheduled_at?new Date(a.new_scheduled_at).toLocaleString():'—'} · {a.previous_venue||'No venue'} → {a.new_venue||'No venue'}</p>)}</div>{canManage&&f.status==='scheduled'&&<Button size="sm" variant="secondary" className="mt-2" disabled={busy} onClick={()=>void save(()=>supabase!.from('schoolpro_sports_fixtures').update({status:'in_progress',updated_at:new Date().toISOString()}).eq('id',f.id).eq('school_id',ctx.schoolId).select('id'),'Fixture started.')}>Start fixture</Button>}{canManage&&['scheduled','in_progress','postponed'].includes(f.status)&&<Button size="sm" variant="secondary" className="mt-2" disabled={busy} onClick={()=>void cancelFixture(f.id)}>Cancel fixture</Button>}{canManage&&['scheduled','postponed'].includes(f.status)&&<div className="mt-2 flex flex-wrap items-center gap-2"><input aria-label="Rescheduled fixture date and time" type="datetime-local" className="rounded-lg border p-2 text-xs" defaultValue={localDate(f.scheduled_at)} onChange={e=>setScheduleDrafts(p=>({...p,[f.id]:e.target.value}))}/><Button size="sm" variant="secondary" disabled={busy||!(scheduleDrafts[f.id]||localDate(f.scheduled_at))} onClick={()=>void updateFixtureSchedule(f.id,scheduleDrafts[f.id]||localDate(f.scheduled_at),f.venue||'')}>Reschedule</Button></div>}</div>)}{!fixtures.length&&<p className="text-sm text-muted">No fixtures scheduled.</p>}</div>
    {canManage&&<div className="mt-4 border-t pt-4"><h4 className="font-semibold">Record or amend a result</h4><div className="mt-2 grid gap-2 sm:grid-cols-2"><select className={field} value={resultForm.fixture_id} onChange={e=>setResultForm(p=>({...p,fixture_id:e.target.value}))}><option value="">Choose in-progress / completed fixture</option>{fixtures.filter(f=>['in_progress','completed'].includes(f.status)).map(f=><option key={f.id} value={f.id}>{teamName(f.home_team_id)} vs {teamName(f.away_team_id)} · v{f.result_version}</option>)}</select><input type="number" min="0" step="1" className={field} placeholder="Home score" value={resultForm.home_score} onChange={e=>setResultForm(p=>({...p,home_score:e.target.value}))}/><input type="number" min="0" step="1" className={field} placeholder="Away score" value={resultForm.away_score} onChange={e=>setResultForm(p=>({...p,away_score:e.target.value}))}/><input className={field} placeholder="Result notes" value={resultForm.notes} onChange={e=>setResultForm(p=>({...p,notes:e.target.value}))}/><label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={resultForm.complete} onChange={e=>setResultForm(p=>({...p,complete:e.target.checked}))}/>Mark fixture completed</label><Button disabled={busy||!resultForm.fixture_id||resultForm.home_score===''||resultForm.away_score===''} onClick={()=>void recordResult()}>Save audited result</Button></div></div>}
   </Card>
  </div>
 </ModulePage>;
}
