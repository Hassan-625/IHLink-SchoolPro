import {schoolRoleLabel} from '@/lib/schoolRoles';
import {useState} from 'react';
import {SchoolClassSelect} from '@/components/SchoolClassSelect';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {supabase} from '@/lib/supabase';
import {customerMessage} from '@/lib/customerMessage';
type Class={id:string;name:string;arm:string;level?:string;form_teacher_id?:string|null};
type Teacher={id:string;name:string;role:string};
export function SchoolClassCoordinators({classes,teachers,canManage,onSaved}:{classes:Class[];teachers:Teacher[];canManage:boolean;onSaved:()=>Promise<void>}){
 const [classId,setClassId]=useState(''),[teacher,setTeacher]=useState(''),[busy,setBusy]=useState(false),[message,setMessage]=useState('');
 async function save(){if(!supabase||!classId||busy)return;setBusy(true);try{const r=await supabase.rpc('schoolpro_set_form_master',{p_class:classId,p_member:teacher||null});if(r.error)throw r.error;setMessage('Class coordinator saved. Subject allocations are unchanged.');await onSaved();}catch(e){setMessage(customerMessage(e instanceof Error?e.message:'Class coordinator could not be saved.'));}finally{setBusy(false);}}
 return <Card><h3 className="font-bold">Form masters & class coordinators</h3><p className="mt-2 text-sm text-muted">A coordinator oversees the class and reviews its records. Subject teachers are assigned separately and can teach several classes. Only school leadership changes these assignments.</p>{canManage&&<div className="mt-4 grid gap-3 sm:grid-cols-2"><SchoolClassSelect classes={classes} value={classId} onChange={id=>{setClassId(id);setTeacher(classes.find(c=>c.id===id)?.form_teacher_id||'');}} required/><select aria-label="Class coordinator" value={teacher} onChange={e=>setTeacher(e.target.value)} className="rounded-lg border p-3"><option value="">No coordinator</option>{teachers.filter(t=>['teacher','class_teacher'].includes(t.role)).map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select><Button disabled={busy||!classId} onClick={()=>void save()}>{busy?'Saving…':'Save class coordinator'}</Button></div>}
 <div className="school-table-scroll mt-4"><table className="w-full text-left text-sm"><thead><tr><th className="p-3">Class & arm</th><th className="p-3">Coordinator</th><th className="p-3">School Role</th><th className="p-3">Class Responsibility</th></tr></thead><tbody>{classes.map(c=><tr key={c.id} className="border-t"><td className="whitespace-nowrap p-3">{c.name} {c.arm}</td><td className="whitespace-nowrap p-3">{teachers.find(t=>t.id===c.form_teacher_id)?.name||'Not assigned'}</td><td className="p-3">{schoolRoleLabel(teachers.find(t=>t.id===c.form_teacher_id)?.role)}</td><td className="p-3">{c.form_teacher_id?'Form Master / Class Coordinator':'Not assigned'}</td></tr>)}</tbody></table></div>{message&&<p role="status" className="mt-3 text-sm">{message}</p>}</Card>;
}
