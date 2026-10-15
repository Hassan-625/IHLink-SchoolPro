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
 const [intents,setIntents]=useState<any[]>([]);const [plans,setPlans]=useState<any[]>([]),[sub,setSub]=useState<any>(null),[upgradeRequests,setUpgradeRequests]=useState<any[]>([]),[msg,setMsg]=useState(""),[error,setError]=useState(""),[loading,setLoading]=useState(true),[busy,setBusy]=useState("");
 const schoolRef=useRef(ctx.schoolId);schoolRef.current=ctx.schoolId;
 useEffect(()=>{
  let current=true;setPlans([]);setIntents([]);setSub(null);setUpgradeRequests([]);setMsg("");setError("");setBusy("");setLoading(true);
  if(ctx.loading)return()=>{current=false;};
  if(!supabase||!ctx.schoolId||!user){setError(ctx.error||(!supabase?"School billing is temporarily unavailable.":"Register or select your school to manage its subscription."));setLoading(false);return()=>{current=false;};}
  const db=supabase,school=ctx.schoolId;
  void Promise.all([
   db.from("schoolpro_subscription_catalog").select("*").eq("active",true).order("annual_price"),
   db.from("schoolpro_plan_catalog").select("tier,features"),
   db.from("schoolpro_subscriptions").select("*").eq("school_id",school).maybeSingle(),
   db.from("schoolpro_subscription_intents").select("*").eq("school_id",school).eq("payer_user_id",user!.id).eq("payment_method","bank_transfer").order("created_at",{ascending:false}),\n   db.from("schoolpro_upgrade_requests").select("*,schoolpro_schools(name)").order("created_at",{ascending:false})
  ]).then(([p,matrix,s,i,u])=>{
   if(!current)return;
   setPlans((p.data||[]).map(plan=>({...plan,planFeatures:matrix.data?.find(row=>row.tier===plan.code)?.features||{}})));setSub(s.data);setIntents(i.data||[]);setUpgradeRequests((u.data||[]).filter((r:any)=>profile?.role==="super_admin"||r.school_id===school));
   setError(p.error||matrix.error||s.error||i.error||u.error?"Subscription details could not be loaded. Please try again.":"");setLoading(false);
  }).catch(e=>{if(current){setError("Subscription details could not be loaded. Please try again.");setLoading(false);}});
  return()=>{current=false;};
 },[ctx.schoolId,ctx.loading,ctx.error,user?.id]);
 async function requestUpgrade(id:string){
  if(!supabase||!ctx.schoolId||busy||loading||!sub||Number(sub.amount)<=0||sub.status!=="active")return;
  setBusy(id);setMsg("");setError("");
  try{
   const {data,error:requestError}=await supabase.rpc("request_schoolpro_plan_upgrade",{p_school:ctx.schoolId,p_catalog:id});
   if(requestError||!data)throw requestError||new Error("Upgrade request was not saved.");
   setUpgradeRequests(current=>[data,...current.filter(x=>x.id!==data.id)]);
   setMsg("Upgrade request sent to IHLink Super Admin for review. No payment is due until the request is approved and an invoice is issued.");
  }catch(e){setError(e instanceof Error?e.message:"Upgrade request could not be submitted. Please try again.");}
  finally{setBusy("");}
 }
 async function reviewUpgrade(id:string,decision:"approve"|"reject"){
  if(!supabase||busy||profile?.role!=="super_admin")return;
  const reason=window.prompt(decision==="approve"?"Reason for approving this upgrade and issuing its balance invoice:":"Reason for rejecting this upgrade:");
  if(!reason||reason.trim().length<3)return;
  setBusy(id);setError("");setMsg("");
  try{
   const {data,error:reviewError}=await supabase.rpc("review_schoolpro_plan_upgrade",{p_request:id,p_decision:decision,p_reason:reason.trim()});
   if(reviewError||!data)throw reviewError||new Error("Upgrade review was not saved.");
   setUpgradeRequests(rows=>rows.map(row=>row.id===id?{...row,status:data.status||"invoiced",invoice_id:data.invoice_id||row.invoice_id}:row));
   setMsg(decision==="approve"?"Upgrade approved. The balance invoice is now available in the school billing dashboard and Control Center.":"Upgrade request rejected and the reason recorded.");
   if(decision==="approve"&&ctx.schoolId){const {data:rows}=await supabase.from("schoolpro_subscription_intents").select("*").eq("school_id",ctx.schoolId).eq("payer_user_id",user?.id||"").order("created_at",{ascending:false});if(rows)setIntents(rows);}
  }catch(e){setError(e instanceof Error?e.message:"Upgrade review failed. No success was confirmed.");}
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
 const inGrace=sub?.status==='active'&&Number(sub?.amount)>0&&sub?.billing_cycle==='annual'&&new Date(sub.renews_at).getTime()<=Date.now()&&Date.now()<new Date(sub.renews_at).getTime()+14*86400000;
 const isDemo=sub?.status==='active' && Number(sub?.amount)===0;
 return <ModulePage product="schoolpro" sections={[]} title="SchoolPro Subscription" description="IHLink service subscription only. Student fees and school charges use the school's own bank accounts." userName={profile?.first_name||"School Administrator"} userRole="School Management" primaryAction="Bank transfer subscription" metrics={[
  {label:"Current plan",value:loading?"…":unavailable?"Unavailable":isDemo?`Demo · ${sub.tier}`:sub?.tier||"None"},
  {label:"Status",value:loading?"…":unavailable?"Unavailable":inGrace?"Renewal grace period":sub?.status||"Inactive"},
  {label:isDemo?"Demo ends":"Renewal",value:loading?"…":unavailable?"Unavailable":sub?.renews_at?new Date(sub.renews_at).toLocaleDateString("en-NG"):"—"}
 ]}>
  {error&&<div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm">{error}</div>}
  {msg&&<div role="status" className="rounded-xl border p-3 text-sm">{msg}</div>}
  <Card><p className="font-bold">Annual subscription</p><p className="mt-1 text-sm text-muted">Demo access lasts one year. Paid subscriptions renew annually and include a 14-day grace period after expiry. While Demo is active, no paid subscription price or payable invoice is shown. SchoolPro uses uploaded receipts and manual Finance verification.</p></Card>
  <div className="grid gap-4 md:grid-cols-3">{plans.map(p=>{
   const price=Number(p.annual_price||0),valid=Number.isFinite(price)&&price>0;
   return <Card key={p.id}><h3 className="font-bold">{p.name}</h3><p className="mt-2 text-2xl font-bold">{isDemo?"Demo active · no fee due":valid?money(price)+" / year":"Not priced"}</p><ul className="mt-3 space-y-2 text-sm"><li>Core school management</li>{Object.entries({website:'School website',cbt:'CBT and online tests',advanced_reports:'Advanced reports',custom_branding:'Custom branding'}).map(([feature,label])=><li key={feature} className={p.planFeatures[feature]===true?'text-emerald-700':'text-muted'}>{p.planFeatures[feature]===true?'Included: ':'Not included: '}{label}</li>)}</ul><Button className="mt-4" disabled={!valid||Boolean(busy)||loading||!ctx.schoolId||isDemo||(Number(sub?.amount)>0&&sub?.status==="active"&&price<=Number(plans.find(x=>x.code===sub?.tier)?.annual_price||sub?.amount))} onClick={()=>Number(sub?.amount)>0&&sub?.status==="active"?void requestUpgrade(p.id):void pay(p.id)}>{busy===p.id?"Processing…":isDemo?"Demo active":Number(sub?.amount)>0&&sub?.status==="active"?(price>Number(plans.find(x=>x.code===sub?.tier)?.annual_price||sub?.amount)?"Request upgrade":"Current/lower plan"):"Subscribe / Renew"}</Button></Card>;
  })}{!loading&&!error&&!plans.length&&<Card><p className="text-sm text-muted">No SchoolPro subscription plan has been published by IHLink yet.</p></Card>}</div>
 {profile?.role==="super_admin"&&<Card><h2 className="font-bold text-lg">Super Admin · plan upgrade requests</h2><p className="mt-1 text-sm text-muted">Review requests from school proprietors. Approval issues an invoice for the difference between annual plan prices; the current annual renewal date is preserved after Finance verifies payment.</p><div className="mt-3 space-y-3">{upgradeRequests.map((r:any)=><article key={r.id} className="rounded-lg border p-3"><p className="font-semibold">{r.schoolpro_schools?.name||r.school_id}: {r.from_plan} → {plans.find((p:any)=>p.id===r.to_catalog_id)?.name||r.to_catalog_id}</p><p className="text-sm">Balance due: {money(Number(r.balance_due))} · Status: {r.status}</p>{r.invoice_id&&<p className="text-xs break-all">Invoice: {r.invoice_id}</p>}{r.status==="pending"&&<div className="mt-2 flex gap-2"><Button disabled={Boolean(busy)} onClick={()=>void reviewUpgrade(r.id,"approve")}>Approve and issue invoice</Button><Button variant="secondary" disabled={Boolean(busy)} onClick={()=>void reviewUpgrade(r.id,"reject")}>Reject</Button></div>}</article>)}{!upgradeRequests.length&&<p className="text-sm text-muted">No upgrade requests are awaiting review.</p>}</div></Card>}
 {isDemo?<Card><p className="font-semibold">Demo service is active</p><p className="mt-1 text-sm text-muted">Your selected commercial plan is retained, but payable subscription invoices and amounts remain hidden until Demo access expires.</p></Card>:<BankTransferPayments key={ctx.schoolId||"no-school"} platform="schoolpro_subscription" instructions={intents.filter(i=>i.invoice_kind!=="demo")}/>}</ModulePage>;
}
