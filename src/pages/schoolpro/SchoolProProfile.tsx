import {useEffect,useState} from 'react';
import {ModulePage} from '@/components/ModulePage';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {useAuth} from '@/context/AuthContext';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {supabase} from '@/lib/supabase';
import {schoolSections} from './schoolShared';
export function SchoolProProfile(){
 const {user,profile}=useAuth(),ctx=useSchoolProContext();
 const [first,setFirst]=useState(''),[last,setLast]=useState(''),[msg,setMsg]=useState(''),[busy,setBusy]=useState(false);
 const [appearance,setAppearance]=useState(()=>localStorage.getItem('ihlink-appearance')||'light');
 useEffect(()=>{setFirst(profile?.first_name||'');setLast(profile?.last_name||'');setMsg('');},[user?.id,profile?.first_name,profile?.last_name]);
 function theme(value:string){setAppearance(value);localStorage.setItem('ihlink-appearance',value);document.documentElement.dataset.appearance=value;}
 async function save(){if(!supabase||!user||busy)return;setBusy(true);try{const {error}=await supabase.from('profiles').update({first_name:first,last_name:last}).eq('id',user.id);setMsg(error?'Your profile could not be saved. Please try again.':'Profile updated.');}catch{setMsg('Your profile could not be saved. Please try again.');}finally{setBusy(false);}}
 async function requestDeletion(){if(!supabase||!user||busy||!window.confirm('Request permanent deletion of your IHLink account? This affects your account across IHLink services.'))return;setBusy(true);try{const {error}=await supabase.from('account_deletion_requests').upsert({user_id:user.id,status:'pending',requested_at:new Date().toISOString()},{onConflict:'user_id,status'});setMsg(error?'Your deletion request could not be submitted. Please try again.':'Account deletion requested. Your account remains accessible while the request is processed.');}catch{setMsg('Your deletion request could not be submitted. Please try again.');}finally{setBusy(false);}}
 return <ModulePage product="schoolpro" sections={schoolSections} title="My account" description="Manage your profile and preferences." userName={ctx.schoolName} userRole={ctx.role}>
  <Card><div className="grid gap-4 md:grid-cols-2"><label className="text-sm font-semibold">First name<input autoComplete="given-name" className="mt-1 w-full rounded-lg border p-2.5 font-normal" value={first} onChange={e=>setFirst(e.target.value)}/></label><label className="text-sm font-semibold">Last name<input autoComplete="family-name" className="mt-1 w-full rounded-lg border p-2.5 font-normal" value={last} onChange={e=>setLast(e.target.value)}/></label><label className="text-sm font-semibold">{user?.email?.endsWith('@students.ihlink.invalid')?'Sign-in method':'Email'}<input disabled className="mt-1 w-full rounded-lg border bg-slate-50 p-2.5 font-normal" value={user?.email?.endsWith('@students.ihlink.invalid')?'School code and admission number':user?.email||''}/></label><label className="text-sm font-semibold">School role<input disabled className="mt-1 w-full rounded-lg border bg-slate-50 p-2.5 font-normal" value={ctx.role}/></label></div><Button disabled={busy} className="mt-5" onClick={()=>void save()}>Save profile</Button></Card>
  <Card><h2 className="font-bold">Appearance</h2><div className="mt-4 flex gap-3">{['light','dark'].map(value=><button type="button" key={value} aria-pressed={appearance===value} className="min-h-12 rounded-xl border px-5 font-semibold capitalize" onClick={()=>theme(value)}>{value}</button>)}</div></Card>
  <Card><h2 className="font-bold">Account deletion</h2><p className="mt-2 text-sm text-muted">Request deletion of your IHLink account. School records that must be retained will be handled separately.</p><Button disabled={busy} variant="danger" className="mt-4" onClick={()=>void requestDeletion()}>Request account deletion</Button></Card>{msg&&<p role="status" className="text-sm">{msg}</p>}
 </ModulePage>;
}
