import {useEffect,useState} from 'react';
import {SchoolProLiveDashboard} from "./SchoolProLiveDashboard";
import {useAuth} from '@/context/AuthContext';
import {supabase} from '@/lib/supabase';

export function SchoolProAdminDashboard(){
 const {profile}=useAuth();const [schools,setSchools]=useState<{id:string;name:string}[]>([]);
 useEffect(()=>{if(profile?.role!=='super_admin'||!supabase)return;void supabase.from('schoolpro_schools').select('id,name').order('name').then(({data})=>setSchools(data||[]))},[profile?.role]);
 const selected=typeof window!=='undefined'?localStorage.getItem('ihlink_schoolpro_admin_school')||'':'';
 return <>{profile?.role==='super_admin'&&<div className="mx-auto max-w-7xl px-4 pt-4"><div className="rounded-xl border bg-white p-4 shadow-sm"><label className="text-sm font-bold text-slate-800">Super Admin — administer school</label><select className="ml-3 rounded-lg border px-3 py-2 text-sm" value={selected} onChange={e=>{if(e.target.value)localStorage.setItem('ihlink_schoolpro_admin_school',e.target.value);else localStorage.removeItem('ihlink_schoolpro_admin_school');window.location.reload()}}><option value="">Latest school</option>{schools.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select><p className="mt-2 text-xs text-slate-500">Your Super Admin account bypasses SchoolPro role and subscription feature gates. Choose the school whose CBT, Question Bank, results, branding, finance and operations you want to administer.</p></div></div>}<SchoolProLiveDashboard roleLabel={profile?.role==='super_admin'?"IHLink Super Administrator":"School Administrator"}/></>;
}