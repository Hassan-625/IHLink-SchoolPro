import { useEffect, useMemo, useState } from "react";
import { BookOpen, Check, RefreshCw } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { useAuth } from "@/context/AuthContext";
import { customerMessage } from "@/lib/customerMessage";
import { supabase } from "@/lib/supabase";

type ClassRow = { id:string; name:string; arm:string; form_teacher_id?:string|null };
type Subject = { id:string; name:string; code:string; class_name:string; is_catalogue_entry?:boolean };
type Member = { id:string; user_id:string; role:string; name:string };
type Assignment = { id:string; class_id:string; subject_id:string; teacher_member_id:string|null; session:string };

type Props = {
  schoolId:string;
  classes:ClassRow[];
  subjects:Subject[];
  members:Member[];
  session:string;
};

export function SchoolProFormMasterSubjects({schoolId,classes,subjects,members,session}:Props){
  const {user}=useAuth();
  const member=members.find(item=>item.user_id===user?.id);
  const assignedClasses=useMemo(
    ()=>member?classes.filter(item=>item.form_teacher_id===member.id):[],
    [classes,member]
  );
  const [classId,setClassId]=useState("");
  const [subjectId,setSubjectId]=useState("");
  const [assignments,setAssignments]=useState<Assignment[]>([]);
  const [busy,setBusy]=useState(false);
  const [error,setError]=useState<string|null>(null);
  const [message,setMessage]=useState<string|null>(null);

  useEffect(()=>{
    if(!assignedClasses.some(item=>item.id===classId))setClassId(assignedClasses[0]?.id||"");
  },[assignedClasses,classId]);

  async function load(){
    if(!supabase||!schoolId||!assignedClasses.length){setAssignments([]);return;}
    const {data,error:loadError}=await supabase
      .from("schoolpro_subject_assignments")
      .select("id,class_id,subject_id,teacher_member_id,session")
      .eq("school_id",schoolId)
      .eq("session",session)
      .in("class_id",assignedClasses.map(item=>item.id));
    if(loadError){setError(customerMessage(loadError.message));return;}
    setAssignments((data||[]) as Assignment[]);
  }

  useEffect(()=>{void load();},[schoolId,session,assignedClasses.map(item=>item.id).join("|")]);

  async function addSubject(){
    if(!supabase||!schoolId||!classId||!subjectId)return;
    setBusy(true);setError(null);setMessage(null);
    try{
      const {data,error:saveError}=await supabase.rpc("schoolpro_form_master_select_class_subject",{
        p_school:schoolId,p_class:classId,p_subject:subjectId,p_session:session
      });
      if(saveError)throw saveError;
      if(!data)throw new Error("The database did not confirm this subject selection.");
      setMessage("Subject selected for this class and session. Existing teacher allocation, if any, was preserved.");
      setSubjectId("");
      await load();
    }catch(err){
      setError(customerMessage(err instanceof Error?err.message:String(err)));
    }finally{setBusy(false);}
  }

  const catalogue=subjects.filter(item=>item.is_catalogue_entry);
  const selectedAssignments=assignments.filter(item=>item.class_id===classId);
  const assignedSubjectIds=new Set(selectedAssignments.map(item=>item.subject_id));
  const classLabel=(item:ClassRow)=>item.name+(item.arm?" "+item.arm:"");

  if(!assignedClasses.length)return null;

  return <Card>
    <div className="flex items-center gap-2"><BookOpen className="h-5 w-5 text-purple-700"/><h3 className="font-bold">Select subjects for your class</h3></div>
    <p className="mt-2 text-sm text-muted">Choose existing subjects from your school catalogue. This does not create new subject records or grant score-entry permissions.</p>
    {(error||message)&&<p role="status" className={"mt-3 rounded-lg border p-3 text-sm "+(error?"border-rose-200 bg-rose-50 text-rose-700":"border-emerald-200 bg-emerald-50 text-emerald-700")}>{error||message}</p>}
    <div className="mt-4 grid gap-3 sm:grid-cols-2">
      <label className="grid gap-1 text-sm font-medium">Assigned class
        <select value={classId} onChange={event=>setClassId(event.target.value)} className="rounded-lg border p-2.5">
          {assignedClasses.map(item=><option key={item.id} value={item.id}>{classLabel(item)}</option>)}
        </select>
      </label>
      <label className="grid gap-1 text-sm font-medium">School catalogue subject
        <select value={subjectId} onChange={event=>setSubjectId(event.target.value)} className="rounded-lg border p-2.5">
          <option value="">Select a subject</option>
          {catalogue.filter(item=>!assignedSubjectIds.has(item.id)).map(item=><option key={item.id} value={item.id}>{item.name} · {item.class_name}</option>)}
        </select>
      </label>
    </div>
    <div className="mt-3 flex flex-wrap items-center gap-2">
      <Button size="sm" disabled={busy||!subjectId||!classId} onClick={()=>void addSubject()}>{busy?"Saving…":"Add subject to class"}</Button>
      <Button size="sm" variant="secondary" disabled={busy} onClick={()=>void load()} leftIcon={<RefreshCw className="h-4 w-4"/>}>Refresh</Button>
    </div>
    <div className="mt-4">
      <p className="text-sm font-semibold">Selected subjects · {session}</p>
      {selectedAssignments.length?<ul className="mt-2 grid gap-2 sm:grid-cols-2">{selectedAssignments.map(item=>{
        const subject=subjects.find(candidate=>candidate.id===item.subject_id);
        return <li key={item.id} className="flex items-center gap-2 rounded-lg border p-2 text-sm"><Check className="h-4 w-4 text-emerald-600"/><span>{subject?.name||"Subject"}</span><span className="ml-auto text-xs text-muted">{subject?.code||""}</span></li>;
      })}</ul>:<p className="mt-2 text-sm text-muted">No subjects have been selected for this class and session yet.</p>}
    </div>
  </Card>;
}
