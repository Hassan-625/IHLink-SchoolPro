import {useEffect,useState} from 'react';
import {SchoolStudentFilters,type FilterStudent} from './SchoolStudentFilters';
type Student=FilterStudent&{first_name?:string;last_name?:string;admission_number?:string};
export function SchoolStudentSelect({schoolId,students,value,onChange,required=false}:{schoolId:string|null;students:Student[];value:string;onChange:(id:string)=>void;required?:boolean}){
 const [ids,setIds]=useState<string[]>([]);
 useEffect(()=>{if(value&&!ids.includes(value))onChange('')},[value,ids,onChange]);
 return <div className="space-y-2"><SchoolStudentFilters requireClass schoolId={schoolId} students={students} onChange={setIds}/><label className="block text-sm font-semibold">Student<select aria-label="Student" required={required} disabled={!ids.length} value={value} onChange={e=>onChange(e.target.value)} className="mt-1 w-full min-w-0 rounded-lg border p-2.5 text-sm disabled:opacity-50"><option value="">{ids.length?'Select student':'Choose section, class and arm first'}</option>{students.filter(s=>ids.includes(s.id)).map(s=><option key={s.id} value={s.id}>{[s.first_name,s.last_name].filter(Boolean).join(' ')}{s.admission_number?` · ${s.admission_number}`:''}</option>)}</select></label></div>
}
