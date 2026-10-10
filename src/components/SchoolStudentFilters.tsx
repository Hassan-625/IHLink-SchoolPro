import {useEffect,useMemo,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {schoolSection,studentClass,filterSchoolStudents,SCHOOL_SECTIONS,type SchoolClass} from '@/lib/schoolClassFilters';
export type FilterStudent={id:string;class_id?:string|null;class_name?:string|null;class_level?:string|null};
export function SchoolStudentFilters({schoolId,students,onChange,requireClass=false}:{schoolId:string|null;students:FilterStudent[];onChange:(ids:string[])=>void;requireClass?:boolean}){
 const [classes,setClasses]=useState<SchoolClass[]>([]),[section,setSection]=useState(''),[classId,setClassId]=useState(''),[arm,setArm]=useState('');
 useEffect(()=>{let active=true;setClasses([]);setSection('');setClassId('');setArm('');if(schoolId&&supabase)void supabase.from('schoolpro_classes').select('id,name,arm,level').eq('school_id',schoolId).order('name').then(r=>{if(active)setClasses(r.data||[])});return()=>{active=false}},[schoolId]);
 const options=useMemo(()=>{const map=new Map<string,{id:string;name:string;section:string}>();for(const c of classes)map.set(c.id,{id:c.id,name:[c.name,c.arm].filter(Boolean).join(' '),section:schoolSection(c.level,c.name)});for(const s of students){const c=studentClass(s,classes),id=c?.id||s.class_name||'';if(id)map.set(id,{id,name:c?[c.name,c.arm].filter(Boolean).join(' '):s.class_name||'',section:schoolSection(c?.level||s.class_level,c?.name||s.class_name||'')})}return [...map.values()]},[classes,students]);
 const groups=useMemo(()=>[...new Set(options.filter(c=>!section||c.section===section).map(c=>classes.find(x=>x.id===c.id)?.name||c.name))],[options,classes,section]);
 const arms=useMemo(()=>options.filter(c=>c.section===section&&(classes.find(x=>x.id===c.id)?.name||c.name)===classId).map(c=>({id:c.id,arm:classes.find(x=>x.id===c.id)?.arm||''})),[options,classes,section,classId]);
 const hasArms=arms.some(c=>c.arm);
 const visible=useMemo(()=>filterSchoolStudents(students,classes,{section,className:classId,armId:arm,requireClass}).map(s=>s.id),[students,classes,section,classId,arm,requireClass]);
 useEffect(()=>{onChange(visible)},[visible,onChange]);
 return <div className="grid min-w-0 grid-cols-1 gap-2 sm:grid-cols-3">
  <label className="min-w-0 text-xs font-semibold">Section<select aria-label="School section" className="mt-1 w-full min-w-0 rounded-lg border p-2.5 text-sm" value={section} onChange={e=>{setSection(e.target.value);setClassId('');setArm('');onChange([])}}><option value="">{requireClass?'Select section':'All sections'}</option>{[...new Set([...SCHOOL_SECTIONS,...options.map(c=>c.section)])].map(x=><option key={x}>{x}</option>)}</select></label>
  <label className="min-w-0 text-xs font-semibold">Class<select aria-label="School class" disabled={!section} className="mt-1 w-full min-w-0 rounded-lg border p-2.5 text-sm disabled:opacity-50" value={classId} onChange={e=>{setClassId(e.target.value);setArm('');onChange([])}}><option value="">{requireClass?'Select class':'All classes'}</option>{groups.map(name=><option key={name} value={name}>{name}</option>)}</select></label>
  {hasArms&&<label className="min-w-0 text-xs font-semibold">Class arm<select aria-label="School class arm" className="mt-1 w-full min-w-0 rounded-lg border p-2.5 text-sm" value={arm} onChange={e=>{setArm(e.target.value);onChange([])}}><option value="">{requireClass?'Select arm':'All arms'}</option>{arms.map(c=><option key={c.id} value={c.id}>{c.arm||'Main class'}</option>)}</select></label>}
 </div>
}
