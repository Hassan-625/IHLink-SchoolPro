import {schoolRoleLabel,schoolTeachingResponsibility} from '@/lib/schoolRoles';
import {useSchoolSession} from '@/hooks/useSchoolSession';
import {SchoolClassRoster} from '@/components/SchoolClassRoster';
import {SchoolClassCoordinators} from '@/components/SchoolClassCoordinators';
import {SchoolClassSelect} from '@/components/SchoolClassSelect';
import {customerMessage} from '@/lib/customerMessage';
import {AcademicPeriodSelect} from '@/components/AcademicPeriodSelect';
import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react";
import { BookOpen, Plus, RefreshCw, Trash2, UserRoundCheck } from "lucide-react";
import { ModulePage } from "@/components/ModulePage";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { useAuth } from "@/context/AuthContext";
import { supabase } from "@/lib/supabase";
import { schoolSections, status } from "./schoolShared";
import { useSchoolProContext } from "@/hooks/useSchoolProContext";

type School = { id:string; name:string };
type ClassRow = { id:string; name:string; arm:string;level?:string;form_teacher_id?:string|null };
type Subject = { id:string; name:string; code:string; class_name:string };
type Member = { id:string; user_id:string; role:string; name:string };
type Assignment = { id:string; class_id:string; subject_id:string; teacher_member_id:string|null; session:string };

export function SchoolProSubjects(){
  const {session}=useSchoolSession();const [viewClassId,setViewClassId]=useState("");const {user,profile}=useAuth();const ctx=useSchoolProContext();const normalizedRole=ctx.role.trim().toLowerCase().replaceAll(' ','_');const canManage=['proprietor','administrator','super_administrator','super_admin'].includes(normalizedRole);
  const [schools,setSchools]=useState<School[]>([]),[schoolId,setSchoolId]=useState("");
  const [classes,setClasses]=useState<ClassRow[]>([]),[subjects,setSubjects]=useState<Subject[]>([]),[members,setMembers]=useState<Member[]>([]),[assignments,setAssignments]=useState<Assignment[]>([]),[tableSearch,setTableSearch]=useState("");
  const [form,setForm]=useState({name:"",code:"",className:""});
  const [allocation,setAllocation]=useState({classId:"",subjectId:"",teacherId:"",session:""});
  const [targetClasses,setTargetClasses]=useState<string[]>([]);
  const [error,setError]=useState<string|null>(null),[message,setMessage]=useState<string|null>(null);
  const [savingAllocation,setSavingAllocation]=useState(false);
  const userName=profile?[profile.first_name,profile.last_name].filter(Boolean).join(" ")||profile.email:"School User";

  const loadSchools=useCallback(async()=>{if(ctx.loading)return;const next=ctx.schoolId?[{id:ctx.schoolId,name:ctx.schoolName}]:[];setSchools(next);setSchoolId(ctx.schoolId||'');},[ctx.loading,ctx.schoolId,ctx.schoolName]);
  const load=useCallback(async()=>{if(!supabase||!schoolId)return;setError(null);const [a,b,c,d]=await Promise.all([
    supabase.from("schoolpro_classes").select("id,name,arm,level,form_teacher_id").eq("school_id",schoolId).order("name"),
    supabase.from("schoolpro_subjects").select("id,name,code,class_name").eq("school_id",schoolId).order("name"),
    supabase.rpc("schoolpro_class_staff_directory",{p_school:schoolId}),
    supabase.from("schoolpro_subject_assignments").select("id,class_id,subject_id,teacher_member_id,session").eq("school_id",schoolId).eq("session",session).order("created_at")
  ]);const issue=a.error||b.error||c.error||d.error;if(issue){setError(customerMessage(issue.message));return;}const allClasses=(a.data||[]) as ClassRow[];const allAssignments=(d.data||[]) as Assignment[];const raw=(c.data||[]) as Member[];const memberId=raw.find(m=>m.user_id===user?.id)?.id||"";const coordinatedIds=new Set(allClasses.filter(x=>x.form_teacher_id===memberId).map(x=>x.id));const assignedIds=new Set(allAssignments.filter(x=>x.teacher_member_id===memberId).map(x=>x.class_id));const visibleClasses=canManage?allClasses:allClasses.filter(x=>coordinatedIds.has(x.id)||assignedIds.has(x.id)); const visibleAssignments=canManage?allAssignments:allAssignments.filter(x=>coordinatedIds.has(x.class_id)||x.teacher_member_id===memberId);setClasses(visibleClasses);setSubjects((b.data||[]) as Subject[]);setMembers(raw);setAssignments(visibleAssignments);setViewClassId(current=>visibleClasses.some(x=>x.id===current)?current:(visibleClasses[0]?.id||""));},[schoolId,canManage,user?.id,session]);
  useEffect(()=>{void loadSchools();},[loadSchools]);useEffect(()=>{void load();},[load]);
  async function addSubject(e:FormEvent){e.preventDefault();if(!supabase||!schoolId||!canManage)return;setMessage(null);const {error}=await supabase.from("schoolpro_subjects").insert({school_id:schoolId,name:form.name,code:form.code.toUpperCase(),class_name:form.className});if(error)setError(customerMessage(error.message));else{setForm({name:"",code:"",className:""});setMessage("Subject created.");await load();}}
  async function assign(e:FormEvent){
    e.preventDefault();
    setError(null);
    setMessage(null);
    if(!supabase||!schoolId||!canManage){setError("You do not have permission to manage allocations in this school.");return;}
    const ids=[...new Set([...targetClasses,allocation.classId].filter(Boolean))];
    if(!ids.length||!allocation.subjectId||!allocation.session){setError("Select a class, subject and academic session before saving.");return;}
    const selectedTeacher=allocation.teacherId||null;
    if(selectedTeacher&&!members.some(m=>m.id===selectedTeacher)){setError("The selected teacher is not a member of this school.");return;}
    setSavingAllocation(true);
    try{
      // The unique assignment is class + subject + session, NOT teacher or subject alone.
      // A teacher can teach multiple subjects/classes and a subject can have different teachers per class.
      const rows=ids.map(classId=>({school_id:schoolId,class_id:classId,subject_id:allocation.subjectId,teacher_member_id:selectedTeacher,session:allocation.session}));
      const {data,error:saveError}=await supabase.from("schoolpro_subject_assignments")
        .upsert(rows,{onConflict:"class_id,subject_id,session"})
        .select("id,class_id,subject_id,teacher_member_id,session");
      if(saveError)throw saveError;
      const saved=data||[];
      if(saved.length!==rows.length||rows.some(row=>!saved.some(x=>x.class_id===row.class_id&&x.subject_id===row.subject_id&&x.session===row.session&&x.teacher_member_id===row.teacher_member_id))){
        throw new Error("The database did not confirm all teacher assignments. Please refresh and try again.");
      }
      await load();
      setMessage(`Saved ${saved.length} class allocation${saved.length===1?"":"s"} for ${allocation.session}.`);
      setTargetClasses([]);
    }catch(err){
      const detail=err instanceof Error?err.message:String(err);
      setError(detail.includes("row-level security")||detail.includes("permission denied")?"Database permissions blocked this allocation. Confirm that you are a school administrator or proprietor, or that your Super Admin account is recognized.":customerMessage(detail));
    }finally{setSavingAllocation(false);}
  }
  async function remove(id:string){if(!supabase||!canManage||!window.confirm("Remove this allocation?"))return;const {error}=await supabase.from("schoolpro_subject_assignments").delete().eq("id",id);if(error)setError(customerMessage(error.message));else await load();}
  const classMap=useMemo(()=>new Map(classes.map(x=>[x.id,`${x.name}${x.arm?` ${x.arm}`:""}`])),[classes]),subjectMap=useMemo(()=>new Map(subjects.map(x=>[x.id,x.name])),[subjects]),memberMap=useMemo(()=>new Map(members.map(x=>[x.id,x.name])),[members]),memberRoleMap=useMemo(()=>new Map(members.map(x=>[x.id,schoolRoleLabel(x.role)])),[members]);
  return <ModulePage product="schoolpro" sections={schoolSections} title={canManage?"Subjects & Teacher Allocation":"My Classes & Subjects"} description={canManage?"Build the curriculum for each class and assign subject teachers separately from Form Masters.":"View your assigned subjects and class responsibilities. Form Masters can see every subject teacher assigned to their own class; other classes remain restricted."} userName={userName} userRole={ctx.role} primaryAction="Add Subject" metrics={[{label:"Subjects",value:String(subjects.length)},{label:"Allocations",value:String(assignments.length)},{label:"Teachers",value:String(members.filter(x=>["teacher","class_teacher"].includes(x.role)).length)},{label:"Unassigned",value:String(assignments.filter(x=>!x.teacher_member_id).length)}]}>
    {(error||message)&&<div className={`rounded-xl border p-3 text-sm ${error?"border-rose-200 bg-rose-50 text-rose-700":"border-emerald-200 bg-emerald-50 text-emerald-700"}`}>{error||message}</div>}
    <div className="flex justify-between gap-3"><select value={schoolId} onChange={e=>setSchoolId(e.target.value)} className="rounded-lg border bg-white px-3 py-2 text-sm">{schools.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select><Button variant="secondary" size="sm" onClick={()=>void load()} leftIcon={<RefreshCw className="h-4 w-4"/>}>Refresh</Button></div>
    {canManage&&<div className="grid gap-5 xl:grid-cols-2"><Card><div className="flex items-center gap-2"><BookOpen className="h-5 w-5 text-purple-700"/><h3 className="font-bold">Create subject</h3></div><form onSubmit={addSubject} className="mt-4 grid gap-3 sm:grid-cols-2"><input required value={form.name} onChange={e=>setForm({...form,name:e.target.value})} placeholder="Subject name" className="rounded-lg border p-2.5 text-sm"/><input required value={form.code} onChange={e=>setForm({...form,code:e.target.value})} placeholder="Code, e.g. MTH" className="rounded-lg border p-2.5 text-sm"/><input required value={form.className} onChange={e=>setForm({...form,className:e.target.value})} placeholder="Curriculum group, e.g. Primary" className="rounded-lg border p-2.5 text-sm sm:col-span-2"/><Button className="sm:col-span-2" leftIcon={<Plus className="h-4 w-4"/>}>Add Subject</Button></form></Card>
    <Card><div className="flex items-center gap-2"><UserRoundCheck className="h-5 w-5 text-purple-700"/><h3 className="font-bold">Allocate class, subject and teacher</h3></div><form onSubmit={assign} className="mt-4 grid gap-3 sm:grid-cols-2"><SchoolClassSelect classes={classes} value={allocation.classId} onChange={value=>setAllocation({...allocation,classId:value})} required/><select required value={allocation.subjectId} onChange={e=>setAllocation({...allocation,subjectId:e.target.value})} className="rounded-lg border p-2.5 text-sm"><option value="">Select subject</option>{subjects.map(x=><option key={x.id} value={x.id}>{x.name} · {x.class_name}</option>)}</select><select value={allocation.teacherId} onChange={e=>setAllocation({...allocation,teacherId:e.target.value})} className="rounded-lg border p-2.5 text-sm"><option value="">Teacher not assigned</option>{members.map(x=><option key={x.id} value={x.id}>{x.name} · {x.role}</option>)}</select><AcademicPeriodSelect kind="session" required value={allocation.session} onChange={e=>setAllocation({...allocation,session:e.target.value})} className="rounded-lg border p-2.5 text-sm"/><div className="sm:col-span-2"><Button type="button" variant="secondary" disabled={!allocation.classId} onClick={()=>setTargetClasses(v=>[...new Set([...v,allocation.classId])])}>Add class to selection</Button><p className="mt-2 text-sm">One teacher can teach this subject in every selected class.</p><div className="mt-2 flex flex-wrap gap-2">{targetClasses.map(id=><button type="button" className="rounded-lg border p-2 text-sm" key={id} onClick={()=>setTargetClasses(v=>v.filter(x=>x!==id))}>{classMap.get(id)} · Remove</button>)}</div></div><Button type="submit" disabled={savingAllocation} className="sm:col-span-2">{savingAllocation?"Saving allocation…":"Save Allocation"}</Button></form></Card></div>}
    <Card><h3 className="font-bold">My class workspace · {session}</h3><p className="mt-1 text-sm text-muted">{canManage?"Select a class to review its roster, coordinator and subject allocations.":"Only classes you coordinate or teach are shown here. A Form Master can review all subject allocations within their coordinated class."}</p>{classes.length?<SchoolClassSelect classes={classes} value={viewClassId} onChange={setViewClassId}/>:<p role="status" className="mt-3 rounded-lg border border-dashed p-4 text-sm text-muted">{canManage?"No classes are available in this school yet.":"No class is currently assigned to your staff account for this session. Ask school leadership to verify your Form Master or subject-teacher allocation. This does not change any school assignment."}</p>}</Card>{viewClassId&&<SchoolClassRoster schoolId={schoolId} classId={viewClassId} session={session}/>}<SchoolClassCoordinators classes={viewClassId?classes.filter(c=>c.id===viewClassId):classes} teachers={members} canManage={canManage} onSaved={load}/>
    <Card padding="none" className="overflow-hidden"><div className="border-b p-3"><input type="search" aria-label="Search allocations" placeholder="Search class, subject or teacher" value={tableSearch} onChange={e=>setTableSearch(e.target.value)} className="w-full max-w-sm rounded-lg border p-2 text-sm"/></div><div className="max-h-[70vh] overflow-auto"><div className="school-table-scroll"><table className="w-full text-left text-sm"><thead className="bg-gray-50"><tr>{["Class","Subject","Teacher","Staff Role","Teaching Responsibility","Session","Status",""].map(x=><th key={x} className="p-3 text-xs uppercase text-muted">{x}</th>)}</tr></thead><tbody>{assignments.filter(x=>(!viewClassId||x.class_id===viewClassId)&&[classMap.get(x.class_id),subjectMap.get(x.subject_id),x.teacher_member_id?memberMap.get(x.teacher_member_id):"",x.session].join(" ").toLowerCase().includes(tableSearch.toLowerCase())).map(x=><tr key={x.id} className="border-t"><td className="p-3 font-bold">{classMap.get(x.class_id)||"Class"}</td><td className="p-3">{subjectMap.get(x.subject_id)||"Subject"}</td><td className="p-3">{x.teacher_member_id?memberMap.get(x.teacher_member_id)||"Teacher":"Not assigned"}</td><td className="p-3">{x.teacher_member_id?memberRoleMap.get(x.teacher_member_id)||"Unknown":"Unassigned"}</td><td className="p-3">{x.teacher_member_id?schoolTeachingResponsibility(classes.some(c=>c.id===x.class_id&&c.form_teacher_id===x.teacher_member_id),true):"Not assigned"}</td><td className="p-3">{x.session}</td><td className="p-3">{status(x.teacher_member_id?"Ready":"Pending",x.teacher_member_id?"emerald":"amber")}</td><td className="p-3">{canManage&&<button aria-label="Remove allocation" onClick={()=>void remove(x.id)} className="text-rose-600"><Trash2 className="h-4 w-4"/></button>}</td></tr>)}</tbody></table></div>{!assignments.length&&<p className="p-10 text-center text-sm text-muted">No subject allocations yet.</p>}</div></Card>
  </ModulePage>;
}
