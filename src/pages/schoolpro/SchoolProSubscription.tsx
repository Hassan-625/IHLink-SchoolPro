import {Link} from 'react-router-dom';
import {canManageSchoolBilling,schoolDashboard} from '@/lib/schoolAccess';
import {BankTransferPayments} from '@/components/BankTransferPayments';
import {useEffect,useRef,useState} from "react";
import {ModulePage} from "@/components/ModulePage";
import {Card} from "@/components/ui/Card";
import {Button} from "@/components/ui/Button";
import {supabase} from "@/lib/supabase";
import {useAuth} from "@/context/AuthContext";
import {useSchoolProContext} from "@/hooks/useSchoolProContext";
import {schoolProPlanFeatures} from "@/lib/schoolProPlanFeatures";
const money=(n:number)=>new Intl.NumberFormat("en-NG",{style:"currency",currency:"NGN",maximumFractionDigits:2}).format(n);
export function SchoolProSubscription(){
 const ctx=useSchoolProContext(),{profile}=useAuth();
 if(ctx.loading)return <p role="status" className="p-6">Checking school access…</p>;
 if(ctx.error)return <p role="alert" className="p-6">School access could not be checked. Please try again.</p>;
 if(profile?.role!=='super_admin'&&!canManageSchoolBilling(ctx.role))return <main className="mx-auto max-w-lg space-y-4 p-6"><h1 className="text-xl font-bold">School subscription</h1><p>Your school administrator manages this subscription. Please contact them for help.</p><Link to={schoolDashboard(ctx.role)} className="inline-block rounded-xl border px-4 py-3">Back to your dashboard</Link></main>;
 return <SchoolBillingWorkspace/>;
}
function SchoolBillingWorkspace(){
 const {profile,user}=useAuth(),ctx=useSchoolProContext();
 const [intents,setIntents]=useState<any[]>([]);const [plans,setPlans]=useState<any[]>([]),[sub,setSub]=useState<any>(null),[upgrades,setUpgrades]=useState<any[]>([]),[msg,setMsg]=useState(""),[error,setError]=useState(""),[loading,setLoading]=useState(true),[busy,setBusy]=useState("");
 const schoolRef=useRef(ctx.schoolId);schoolRef.current=ctx.schoolId;
 useEffect(()=>{
  let current=true;setPlans([]);setIntents([]);setSub(null);setUpgrades([]);setMsg("");setError("");setBusy("");setLoading(true);
  if(ctx.loading)return()=>{current=false;};
  if(!supabase||!ctx.schoolId||!user){setError(ctx.error||(!supabase?"School billing is temporarily unavailable.":"Register or select your school to manage its subscription."));setLoading(false);return()=>{current=false;};}
  const db=supabase,school=ctx.schoolId;
  void Promise.all([
   db.from("schoolpro_subscription_catalog").select("*").eq("active",true).order("annual_price"),
   db.from("schoolpro_plan_catalog").select("tier,features"),
   db.from("schoolpro_subscriptions").select("*").eq("school_id",school).maybeSingle(),
   db.from("schoolpro_subscription_intents").select("*").eq("school_id",school).eq("payer_user_id",user!.id).eq("payment_method","bank_transfer").order("created_at",{ascending:false}),
   db.from("schoolpro_upgrade_requests").select("id,source_tier,target_tier,credit_amount,outstanding_amount,status,review_note,created_at,version").eq("school_id",school).order("created_at",{ascending:false})
  ]).then(([p,matrix,s,i,u])=>{
   if(!current)return;
   setPlans((p.data||[]).map(plan=>({...plan,planFeatures:matrix.data?.find(row=>row.tier===plan.code)?.features||{}})));setSub(s.data);setIntents(i.data||[]);setUpgrades(u.data||[]);
   setError(p.error||matrix.error||s.error||i.error||u.error?"Subscription details could not be loaded. Please try again.":"");setLoading(false);
  }).catch(e=>{if(current){setError("Subscription details could not be loaded. Please try again.");setLoading(false);}});
  return()=>{current=false;};
 },[ctx.schoolId,ctx.loading,ctx.error,user?.id]);
 async function requestUpgrade(planId:string){
  if(!supabase||!ctx.schoolId||busy||loading)return;
  setBusy(planId);setMsg("");setError("");
  try{
   const {data,error:requestError}=await supabase.rpc("request_schoolpro_upgrade",{p_school_id:ctx.schoolId,p_target_catalog_id:planId});
   if(requestError||!data)throw requestError||new Error("Upgrade request was not created.");
   const {data:rows,error:readError}=await supabase.from("schoolpro_upgrade_requests").select("id,source_tier,target_tier,credit_amount,outstanding_amount,status,review_note,created_at,version").eq("school_id",ctx.schoolId).order("created_at",{ascending:false});
   if(readError)throw readError;
   setUpgrades(rows||[]);
   setMsg("Upgrade request submitted for IHLink Finance review. The unused-term credit and amount due were calculated by the server. You will receive the bank-transfer invoice after approval.");
  }catch(e:any){setError(e?.message||"The upgrade request could not be submitted. Please try again.");}
  finally{setBusy("");}
 }
 async function cancelUpgrade(id:string){
  if(!supabase||busy||loading)return;
  setBusy(id);setMsg("");setError("");
  try{
   const {error:cancelError}=await supabase.rpc("cancel_schoolpro_upgrade",{p_request_id:id,p_note:"Cancelled by school billing administrator"});
   if(cancelError)throw cancelError;
   const {data:rows,error:readError}=await supabase.from("schoolpro_upgrade_requests").select("id,source_tier,target_tier,credit_amount,outstanding_amount,status,review_note,created_at,version").eq("school_id",ctx.schoolId).order("created_at",{ascending:false});
   if(readError)throw readError;
   setUpgrades(rows||[]);
   setMsg("Upgrade request cancelled.");
  }catch(e:any){setError(e?.message||"The upgrade request could not be cancelled.");}
  finally{setBusy("");}
 }
 async function pay(id:string){
  if(!supabase||!ctx.schoolId||busy||loading)return;
  const school=ctx.schoolId;setBusy(id);setMsg("");
  try{
   const {data,error:requestError}=await supabase.rpc("prepare_schoolpro_bank_subscription",{p_school:school,p_catalog:id});
   if(requestError||!data)throw requestError||new Error("No subscription instruction was created.");
   if(schoolRef.current===school){setIntents(current=>[data,...current.filter(x=>x.id!==data.id)]);setMsg("Annual subscription instruction ready. Transfer the exact amount to either company bank below, then submit your receipt. Finance verification activates or renews the subscription.");}

  }catch(e){if(schoolRef.current===school)setMsg("Payment instructions could not be prepared. Please try again or contact support.");}
  finally{if(schoolRef.current===school)setBusy("");}
 }
 const unavailable=Boolean(error);
 const paidAnnual=Boolean(sub?.status==="active"&&Number(sub?.amount)>0&&sub?.billing_cycle==="annual"&&sub?.renews_at&&new Date(sub.renews_at).getTime()>Date.now());
 const tierRank:Record<string,number>={starter:1,professional:2,enterprise:3};
 const openUpgrade=upgrades.some(r=>["pending_review","approved"].includes(r.status));
 const inGrace=sub?.status==='active'&&Number(sub?.amount)>0&&sub?.billing_cycle==='annual'&&new Date(sub.renews_at).getTime()<=Date.now()&&Date.now()<new Date(sub.renews_at).getTime()+14*86400000;
 const isDemo=sub?.status==='active' && Number(sub?.amount)===0;
 return <ModulePage product="schoolpro" sections={[]} title="SchoolPro Subscription" description="IHLink service subscription only. Student fees and school charges use the school's own bank accounts." userName={profile?.first_name||"School Administrator"} userRole="School Management" primaryAction="Bank transfer subscription" metrics={[
  {label:"Current plan",value:loading?"…":unavailable?"Unavailable":isDemo?`Demo · ${sub.tier}`:sub?.tier||"None"},
  {label:"Status",value:loading?"…":unavailable?"Unavailable":inGrace?"Renewal grace period":sub?.status||"Inactive"},
  {label:isDemo?"Demo ends":"Renewal",value:loading?"…":unavailable?"Unavailable":sub?.renews_at?new Date(sub.renews_at).toLocaleDateString("en-NG"):"—"}
 ]}>
  {error&&<div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm">{error}</div>}
  {msg&&<div role="status" className="rounded-xl border p-3 text-sm">{msg}</div>}
  <Card><p className="font-bold">Annual subscription</p><p className="mt-1 text-sm text-muted">Paid yearly plans include 14 days after expiry to renew before access is paused. Complete any pending payment before choosing another plan.</p></Card>
  <div className="grid gap-4 md:grid-cols-3">{plans.map(p=>{
   const price=Number(p.annual_price||0),valid=Number.isFinite(price)&&price>0;
   return <Card key={p.id}><h3 className="font-bold">{p.name}</h3><p className="mt-2 text-2xl font-bold">{valid?money(price)+" / year":"Not priced"}</p><ul className="mt-3 space-y-2 text-sm">{schoolProPlanFeatures(p.planFeatures||{}).map((feature,index)=><li key={index}>{feature}</li>)}</ul>{paidAnnual?(
    tierRank[p.code]>tierRank[String(sub.tier||"").toLowerCase()]?
     <Button className="mt-4" disabled={!valid||Boolean(busy)||loading||!ctx.schoolId||openUpgrade} onClick={()=>void requestUpgrade(p.id)}>{busy===p.id?"Submitting request…":openUpgrade?"Upgrade request pending":"Request upgrade"}</Button>:
     <p className="mt-4 rounded-lg border p-3 text-sm">{tierRank[p.code]===tierRank[String(sub.tier||"").toLowerCase()]?"Current plan":"Downgrade is not available here"}</p>
   ):<Button className="mt-4" disabled={!valid||Boolean(busy)||loading||!ctx.schoolId} onClick={()=>void pay(p.id)}>{busy===p.id?"Preparing payment…":"Subscribe / Renew"}</Button>}</Card>;
  })}{!loading&&!error&&!plans.length&&<Card><p className="text-sm text-muted">No SchoolPro subscription plan has been published by IHLink yet.</p></Card>}</div>
 {paidAnnual&&<Card><h3 className="font-bold">Annual plan upgrade</h3><p className="mt-1 text-sm text-muted">Choose a higher plan above to request an upgrade. IHLink reviews the request and, if approved, issues a bank-transfer invoice for the remaining difference after the unused-term credit. The current plan remains active until Finance verifies payment.</p></Card>}
  {upgrades.length>0&&<Card><h3 className="font-bold">Upgrade request history</h3><div className="mt-3 space-y-3">{upgrades.map(r=><div key={r.id} className="rounded-lg border p-3 text-sm"><div className="flex flex-wrap items-center justify-between gap-2"><b>{String(r.source_tier).toUpperCase()} → {String(r.target_tier).toUpperCase()}</b><span className="rounded-full border px-2 py-1">{r.status.replaceAll("_"," ")}</span></div><p className="mt-2">Unused-term credit: {money(Number(r.credit_amount))}</p><p>Amount due after approval: {money(Number(r.outstanding_amount))}</p>{r.review_note&&<p className="mt-1 text-muted">Review note: {r.review_note}</p>}{["pending_review","approved"].includes(r.status)&&<Button className="mt-2" variant="secondary" disabled={Boolean(busy)} onClick={()=>void cancelUpgrade(r.id)}>Cancel request</Button>}</div>)}</div></Card>}
 <BankTransferPayments key={ctx.schoolId||"no-school"} platform="schoolpro_subscription" instructions={intents}/></ModulePage>;
}
