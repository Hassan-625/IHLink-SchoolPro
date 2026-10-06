import {useEffect,useRef,useState} from "react";
import {ModulePage} from "@/components/ModulePage";
import {Card} from "@/components/ui/Card";
import {Button} from "@/components/ui/Button";
import {supabase} from "@/lib/supabase";
import {useAuth} from "@/context/AuthContext";
import {useSchoolProContext} from "@/hooks/useSchoolProContext";
const money=(n:number)=>new Intl.NumberFormat("en-NG",{style:"currency",currency:"NGN",maximumFractionDigits:2}).format(n);
export function SchoolProSubscription(){
 const {profile}=useAuth(),ctx=useSchoolProContext();
 const [plans,setPlans]=useState<any[]>([]),[sub,setSub]=useState<any>(null),[msg,setMsg]=useState(""),[error,setError]=useState(""),[loading,setLoading]=useState(true),[busy,setBusy]=useState("");
 const schoolRef=useRef(ctx.schoolId);schoolRef.current=ctx.schoolId;
 useEffect(()=>{
  let current=true;setPlans([]);setSub(null);setMsg("");setError("");setBusy("");setLoading(true);
  if(ctx.loading)return()=>{current=false;};
  if(!supabase||!ctx.schoolId){setError(ctx.error||(!supabase?"Supabase is not configured.":"Register or select your school to manage its subscription."));setLoading(false);return()=>{current=false;};}
  const db=supabase,school=ctx.schoolId;
  void Promise.all([
   db.from("schoolpro_subscription_catalog").select("*").eq("active",true).order("annual_price"),
   db.from("schoolpro_subscriptions").select("*").eq("school_id",school).maybeSingle()
  ]).then(([p,s])=>{
   if(!current)return;
   setPlans(p.data||[]);setSub(s.data);
   setError(p.error?.message||s.error?.message||"");setLoading(false);
  }).catch(e=>{if(current){setError(e?.message||"Subscription data could not be loaded.");setLoading(false);}});
  return()=>{current=false;};
 },[ctx.schoolId,ctx.loading,ctx.error]);
 async function pay(id:string){
  if(!supabase||!ctx.schoolId||busy||loading)return;
  const school=ctx.schoolId;setBusy(id);setMsg("");
  try{
   const {data,error:requestError}=await supabase.functions.invoke("schoolpro-subscription",{body:{school_id:school,catalog_id:id,billing_cycle:"annual"}});
   if(requestError){
    const response=(requestError as {context?:Response}).context;
    const detail=response instanceof Response?await response.clone().json().catch(()=>null):null;
    throw new Error(detail?.message||detail?.error||data?.message||data?.error||requestError.message);
   }
   if(data?.error)throw new Error(data.message||data.error);
   const intent=data?.data?.intent,bank=data?.data?.bank,amount=Number(intent?.amount);
   if(!intent?.reference||!Number.isFinite(amount)||amount<=0||!bank?.bank_name||!bank.account_number||!bank.account_name)throw new Error("Complete payment instructions could not be obtained.");
   if(schoolRef.current===school)setMsg("Transfer exactly "+money(amount)+" to "+bank.bank_name+" "+bank.account_number+" ("+bank.account_name+"). Reference: "+intent.reference+". Repeated clicks reuse this instruction. The subscription activates after confirmed BillStack settlement.");
  }catch(e){if(schoolRef.current===school)setMsg(e instanceof Error?e.message:"Payment instructions could not be obtained.");}
  finally{if(schoolRef.current===school)setBusy("");}
 }
 const unavailable=Boolean(error);
 return <ModulePage product="schoolpro" sections={[]} title="SchoolPro Subscription" description="IHLink service subscription only. Student fees and school charges use the school's own bank accounts." userName={profile?.first_name||"School Administrator"} userRole="School Management" primaryAction="BillStack subscription" metrics={[
  {label:"Current plan",value:loading?"…":unavailable?"Unavailable":sub?.tier||"None"},
  {label:"Status",value:loading?"…":unavailable?"Unavailable":sub?.status||"Inactive"},
  {label:"Renewal",value:loading?"…":unavailable?"Unavailable":sub?.renews_at?new Date(sub.renews_at).toLocaleDateString("en-NG"):"—"}
 ]}>
  {error&&<div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm">{error}</div>}
  {msg&&<div role="status" className="rounded-xl border p-3 text-sm">{msg}</div>}
  <Card><p className="font-bold">Annual subscription</p><p className="mt-1 text-sm text-muted">Plans and prices come from the published IHLink catalogue. An existing pending transfer must be reconciled before changing its plan or payer.</p></Card>
  <div className="grid gap-4 md:grid-cols-3">{plans.map(p=>{
   const price=Number(p.annual_price||0),valid=Number.isFinite(price)&&price>0;
   return <Card key={p.id}><h3 className="font-bold">{p.name}</h3><p className="mt-2 text-2xl font-bold">{valid?money(price)+" / year":"Not priced"}</p><Button className="mt-4" disabled={!valid||Boolean(busy)||loading||!ctx.schoolId} onClick={()=>void pay(p.id)}>{busy===p.id?"Preparing payment…":"Subscribe / Renew"}</Button></Card>;
  })}{!loading&&!error&&!plans.length&&<Card><p className="text-sm text-muted">No SchoolPro subscription plan has been published by IHLink yet.</p></Card>}</div>
 </ModulePage>;
}
