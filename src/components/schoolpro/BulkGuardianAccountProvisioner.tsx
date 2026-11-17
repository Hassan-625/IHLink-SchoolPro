import {useState} from 'react';
import {Button} from '@/components/ui/Button';
import {supabase} from '@/lib/supabase';

type GuardianResult={email:string;status:string;children:number;detail?:string};
type Props={schoolId:string;onComplete:()=>Promise<void>};

export function BulkGuardianAccountProvisioner({schoolId,onComplete}:Props){
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');
 const [schoolCode,setSchoolCode]=useState('');
 const [results,setResults]=useState<GuardianResult[]>([]);
 async function provision(){
  if(!supabase||!schoolId||busy)return;
  setBusy(true);setMessage('');setResults([]);setSchoolCode('');
  try{
   const {data,error}=await supabase.functions.invoke('invite-school-staff',{body:{action:'bulk-provision-guardians',schoolId}});
   if(error||data?.error){
    let detail=data?.error;
    if(!detail&&error?.context instanceof Response){const body=await error.context.clone().json().catch(()=>null);detail=body?.error;}
    setMessage(detail||'Guardian accounts could not be processed. Please try again.');
    return;
   }
   const rows=Array.isArray(data?.results)?data.results as GuardianResult[]:[];
   setResults(rows);setSchoolCode(String(data?.schoolCode||''));
   const created=rows.filter(row=>row.status==='created-awaiting-first-login').length;
   const existing=rows.filter(row=>row.status==='existing-account-pending'||row.status==='invitation-already-pending').length;
   const linked=rows.filter(row=>row.status==='already-linked').length;
   const attention=rows.filter(row=>row.status==='needs-attention'||row.status==='inactive-account'||row.status==='failed').length;
   setMessage(`Processed ${rows.length} unique guardian email(s): ${created} new account(s) created; awaiting first login and verified school-code acceptance, ${existing} existing account(s) awaiting guardian sign-in, ${linked} already linked, and ${attention} needing attention.`);
   await onComplete();
  }catch{
   setMessage('Guardian accounts could not be processed. Please try again.');
  }finally{setBusy(false);}
 }
 return <section className="rounded-xl border p-4">
  <div className="flex flex-wrap items-start justify-between gap-3">
   <div className="min-w-0">
    <h3 className="font-bold">Create & Link Parent/Guardian Accounts</h3>
    <p className="mt-1 text-sm text-muted">Use guardian names, email addresses and phone numbers already imported with student records. One account is created per unique email, and siblings are linked to the same guardian.</p>
   </div>
   <Button disabled={busy||!schoolId} onClick={()=>void provision()}>{busy?'Processing guardians…':'Create & Link Accounts'}</Button>
  </div>
  <p className="mt-2 text-xs text-muted">New accounts use the imported guardian surname as the first-login password. They must change it and complete verified school-code acceptance before accessing children’s records. Existing IHLink accounts keep their current passwords and must sign in to this school using the school code to accept pending child links.</p>
  {message&&<p role="status" className="mt-3 rounded-lg bg-purple-50 p-3 text-sm">{message}</p>}
  {schoolCode&&<p className="mt-2 text-sm">School code for guardians with existing accounts: <strong>{schoolCode}</strong></p>}
  {!!results.length&&<div className="mt-3 max-h-72 overflow-auto rounded-lg border">
   <table className="w-full text-left text-xs"><thead className="bg-gray-50"><tr><th className="p-2">Guardian email</th><th className="p-2">Children</th><th className="p-2">Outcome</th></tr></thead>
    <tbody>{results.map(row=><tr key={row.email} className="border-t"><td className="p-2">{row.email}</td><td className="p-2">{row.children}</td><td className="p-2"><span className="font-semibold">{row.status.replaceAll('-',' ')}</span>{row.detail&&<p className="mt-1 text-rose-700">{row.detail}</p>}</td></tr>)}</tbody>
   </table>
  </div>}
 </section>;
}
