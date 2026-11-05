import {customerMessage} from '@/lib/customerMessage';
import {useEffect,useState} from 'react';
import {Link} from 'react-router-dom';
import {PageShell} from '@/components/PageShell';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
import {Badge} from '@/components/ui/Badge';
import {naira} from '@/lib/designTokens';
import {Check,ArrowRight} from 'lucide-react';
import {supabase} from '@/lib/supabase';
import {schoolProPlanFeatures} from '@/lib/schoolProPlanFeatures';

type Plan={code:string;name:string;annual:number;features:string[];popular:boolean};
const price=(value:number)=>value>0?naira(value):'Not configured';

export function SchoolProPricing(){
 const[plans,setPlans]=useState<Plan[]>([]),[loading,setLoading]=useState(true),[error,setError]=useState('');
 useEffect(()=>{
  let active=true;
  if(!supabase){setError('Pricing is unavailable.');setLoading(false);return()=>{active=false;};}
  void Promise.all([
   supabase.from('schoolpro_subscription_catalog').select('code,name,annual_price').eq('active',true).order('annual_price'),
   supabase.from('schoolpro_plan_catalog').select('tier,features')
  ]).then(([catalog,entitlements])=>{
   if(!active)return;
   if(catalog.error||entitlements.error){setError(customerMessage(catalog.error?.message||entitlements.error?.message||'Pricing could not be loaded.'));setLoading(false);return;}
   const rows=(catalog.data||[]).filter(p=>['starter','professional','enterprise'].includes(p.code));
   setPlans(rows.map(p=>{
    const flags=(entitlements.data||[]).find(x=>x.tier===p.code)?.features||{};
    return{code:p.code,name:p.name,annual:Number(p.annual_price||0),features:schoolProPlanFeatures(flags),popular:p.code==='professional'};
   }));
   setLoading(false);
  }).catch(()=>{if(active){setError('Pricing could not be loaded.');setLoading(false);}});
  return()=>{active=false;};
 },[]);
 return <PageShell product="schoolpro"><div className="mx-auto max-w-[1280px] px-6 py-12 lg:px-10">
  <div className="mb-10 text-center"><Badge className="mb-3 border-purple-200 bg-purple-50 text-purple-700">Pricing</Badge><h1 className="mb-3 text-4xl font-extrabold text-ink">Pricing That Scales With Your School</h1><p className="mx-auto max-w-2xl text-base text-muted">Compare the live SchoolPro packages, their included modules and annual subscription prices. Prices and plan entitlements are maintained by IHLink.</p></div>
  <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
   {loading&&<p role="status">Loading current subscription prices…</p>}{error&&<p role="alert" className="text-rose-700">Pricing could not be loaded: {error}</p>}{!loading&&!error&&!plans.length&&<p>No active public SchoolPro plans are available.</p>}
   {plans.map(plan=><Card key={plan.code} padding="lg" className={plan.popular?'relative border-2 border-purple-400 shadow-float':''}>
    {plan.popular&&<Badge className="absolute right-4 top-4 border-purple-600 bg-purple-600 text-white">Most Popular</Badge>}
    <h3 className="text-xl font-bold text-ink">{plan.name}</h3><p className="mb-4 text-sm text-muted">{plan.name} SchoolPro subscription</p>
    <div className="border-b border-border pb-4 text-sm"><p><span className="text-3xl font-extrabold">{price(plan.annual)}</span> <span className="text-muted">/ year</span></p></div>
    <Link to="/schoolpro/register"><Button fullWidth className="mt-4" themeClass={plan.popular?'bg-purple-600 hover:bg-purple-700':undefined} variant={plan.popular?undefined:'secondary'}>Register with {plan.name}</Button></Link>
    <div className="mt-6 space-y-3">{plan.features.map((feature,index)=><div key={index} className="flex items-start gap-2 text-sm text-ink"><Check className="mt-0.5 h-4 w-4 shrink-0 text-purple-500"/><span>{feature}</span></div>)}</div>
   </Card>)}
  </div>
  <div className="mt-12 text-center"><p className="mb-4 text-sm text-muted">Enterprise custom branding requires a separate request and IHLink approval. Subscription upgrades are reviewed and activated after the required payment is verified.</p><Link to="/schoolpro/book-demo"><Button variant="secondary" rightIcon={<ArrowRight className="h-4 w-4"/>}>Book a Demo First</Button></Link></div>
 </div></PageShell>;
}
