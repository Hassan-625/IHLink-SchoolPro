import {useEffect,useState} from 'react';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {teacherSections} from './schoolShared';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useAuth} from '@/context/AuthContext';
import {supabase} from '@/lib/supabase';

type RosterRow={house_id:string;house_name:string;house_color:string;student_id:string|null;admission_number:string|null;first_name:string|null;middle_name:string|null;last_name:string|null;class_name:string|null;class_arm:string|null;assigned_at:string|null};
export function SchoolProHouseDashboard(){
 const ctx=useSchoolProContext();const {user,profile}=useAuth();
 const [records,setRecords]=useState<RosterRow[]>([]);const [loading,setLoading]=useState(false);const [error,setError]=useState('');
 useEffect(()=>{let active=true;
  if(!supabase||!ctx.schoolId||!user?.id){setRecords([]);return()=>{active=false};}
  setLoading(true);setError('');
  void supabase.rpc('schoolpro_house_master_roster',{p_school:ctx.schoolId}).then(({data,error})=>{
   if(!active)return;
   if(error){setError('Your House Master roster could not be loaded. Please refresh or contact the school administrator.');setRecords([]);}
   else setRecords((data||[]) as RosterRow[]);
   setLoading(false);
  });
  return()=>{active=false};
 },[ctx.schoolId,user?.id]);
 const house=records[0];const students=records.filter(r=>r.student_id);
 const name=profile?[profile.first_name,profile.last_name].filter(Boolean).join(' ')||profile.email:'Staff member';
 const rows=students.map(s=>({admission:s.admission_number||'—',student:[s.first_name,s.middle_name,s.last_name].filter(Boolean).join(' '),class:[s.class_name,s.class_arm].filter(Boolean).join(' ')||'—',assigned:s.assigned_at?new Date(s.assigned_at).toLocaleDateString():'—'}));
 return <ModulePage product="schoolpro" sections={teacherSections} title="My House & Students" description="View your active House Master appointment and the students currently assigned to your house. This roster is read-only and does not provide general access to student records." userName={name} userRole={ctx.role} metrics={[{label:'Assigned house',value:house?.house_name||'Not appointed'},{label:'Current students',value:String(students.length)},{label:'School',value:ctx.schoolName}]} columns={[{key:'admission',label:'Admission No.'},{key:'student',label:'Student'},{key:'class',label:'Class / Arm'},{key:'assigned',label:'Assigned'}]} rows={rows}>
  {error&&<p role="alert" className="rounded-xl border border-rose-200 bg-rose-50 p-3 text-sm text-rose-700">{error}</p>}
  {loading&&<p role="status" className="text-sm text-muted">Loading your assigned house and student roster…</p>}
  {!loading&&!error&&!house&&<Card><h3 className="font-semibold">No active House Master appointment</h3><p className="mt-2 text-sm text-muted">There is no active House Master appointment linked to your staff account in this school. Contact your school administrator if this is unexpected.</p></Card>}
  {!loading&&house&&<Card><div className="flex items-center gap-3"><span className="h-5 w-5 rounded-full" style={{backgroundColor:house.house_color}}/><div><h3 className="font-semibold">{house.house_name}</h3><p className="text-xs text-muted">Current active house assignment</p></div></div>{!students.length&&<p className="mt-4 text-sm text-muted">No active students are currently assigned to this house.</p>}</Card>}
 </ModulePage>;
}
