import {useEffect,useState} from 'react';
import {SchoolProLiveDashboard} from "./SchoolProLiveDashboard";
import {useAuth} from '@/context/AuthContext';
import {supabase} from '@/lib/supabase';

export function SchoolProAdminDashboard(){
 const {profile,user}=useAuth();
 const [schools,setSchools]=useState<{id:string;name:string}[]>([]);
 const [ownerEmail,setOwnerEmail]=useState('ihacademy.owner2@example.com');
 const [transferMessage,setTransferMessage]=useState('');
 const [transferring,setTransferring]=useState(false);
 useEffect(()=>{if(profile?.role!=='super_admin'||!supabase)return;void supabase.from('schoolpro_schools').select('id,name').order('name').then(({data})=>setSchools(data||[]))},[profile?.role]);
 const selected=typeof window!=='undefined'?(localStorage.getItem('ihlink_schoolpro_admin_school')||localStorage.getItem('ihlink_schoolpro_workspace_'+(user?.id||''))||''):'';
 const transferOwnership=async()=>{
  if(!supabase||profile?.role!=='super_admin'||!selected||!ownerEmail.trim())return;
  if(!window.confirm('Transfer ownership of the selected school to '+ownerEmail.trim()+'? The current owner will lose school-level membership, but your platform Super Admin role will remain unchanged.'))return;
  setTransferring(true);setTransferMessage('');
  try{
   const {data:target,error:lookupError}=await supabase.from('profiles').select('id,email,status').eq('email',ownerEmail.trim().toLowerCase()).maybeSingle();
   if(lookupError)throw lookupError;
   if(!target||target.status!=='active')throw new Error('No active profile was found for that exact email. Confirm the account exists and is active.');
   const {data,error}=await supabase.functions.invoke('schoolpro-transfer-ownership',{body:{school_id:selected,new_owner_id:target.id}});
   if(error)throw error;
   if(!data?.ok)throw new Error(data?.error||'Ownership transfer was not confirmed.');
   setTransferMessage('Ownership transfer completed. Refreshing school access…');
   window.setTimeout(()=>window.location.reload(),1200);
  }catch(error){
   setTransferMessage(error instanceof Error?error.message:'Ownership transfer failed. No success was confirmed.');
  }finally{setTransferring(false)}
 };
 return <>{profile?.role==='super_admin'&&<div className="mx-auto max-w-7xl px-4 pt-4 space-y-4"><div className="rounded-xl border bg-white p-4 shadow-sm"><label className="text-sm font-bold text-slate-800">Super Admin — administer school</label><select className="ml-3 rounded-lg border px-3 py-2 text-sm" value={selected} onChange={e=>{const next=e.target.value;if(next){localStorage.setItem('ihlink_schoolpro_admin_school',next);if(user?.id)localStorage.setItem('ihlink_schoolpro_workspace_'+user.id,next);}else{localStorage.removeItem('ihlink_schoolpro_admin_school');if(user?.id)localStorage.removeItem('ihlink_schoolpro_workspace_'+user.id);}window.location.reload()}}><option value="">Select a school</option>{schools.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select><p className="mt-2 text-xs text-slate-500">Your Super Admin account bypasses SchoolPro role and subscription feature gates. Choose the school whose CBT, Question Bank, results, branding, finance and operations you want to administer.</p></div><div className="rounded-xl border border-amber-200 bg-white p-4 shadow-sm"><h2 className="text-sm font-bold text-slate-900">Transfer school ownership</h2><p className="mt-1 text-sm text-slate-600">Transfers the selected school to an existing active account, grants the Proprietor membership, and removes the former owner’s school membership. Your platform Super Admin role is not changed.</p><label htmlFor="schoolpro-new-owner-email" className="mt-3 block text-sm font-medium text-slate-700">New Proprietor account email</label><input id="schoolpro-new-owner-email" type="email" value={ownerEmail} onChange={e=>setOwnerEmail(e.target.value)} className="mt-1 w-full max-w-lg rounded-lg border px-3 py-2 text-sm" placeholder="proprietor@example.com" /><div className="mt-3"><button type="button" disabled={!selected||!ownerEmail.trim()||transferring} onClick={transferOwnership} className="rounded-lg bg-amber-700 px-4 py-2 text-sm font-semibold text-white disabled:cursor-not-allowed disabled:opacity-50">{transferring?'Transferring…':'Transfer ownership'}</button></div>{transferMessage&&<p role="status" className="mt-3 text-sm text-slate-700">{transferMessage}</p>}</div></div>}<SchoolProLiveDashboard roleLabel={profile?.role==='super_admin'?"IHLink Super Administrator":"School Administrator"}/></>;
}
