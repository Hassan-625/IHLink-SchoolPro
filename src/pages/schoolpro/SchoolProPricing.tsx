import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { PageShell } from '@/components/PageShell';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { naira } from '@/lib/designTokens';
import { Check, ArrowRight } from 'lucide-react';
import { supabase } from '@/lib/supabase';

type Plan = { name:string; price:number; desc:string; features:string[]; popular:boolean };

export function SchoolProPricing() {
  const [plans,setPlans]=useState<Plan[]>([]);
  const [loading,setLoading]=useState(true),[error,setError]=useState('');
  useEffect(()=>{let active=true;if(!supabase){setError('Pricing is unavailable.');setLoading(false);return;}void supabase.from('schoolpro_subscription_catalog').select('code,name,annual_price,features').eq('active',true).order('annual_price').then(({data,error:issue})=>{if(!active)return;if(issue)setError(issue.message);setPlans((data||[]).filter(p=>Number(p.annual_price)>0).map(p=>({name:p.name,price:Number(p.annual_price),desc:`${p.name} SchoolPro annual subscription`,features:Array.isArray(p.features)?p.features:[],popular:p.code==='professional'})));setLoading(false)});return()=>{active=false}},[]);
  return (
    <PageShell product="schoolpro">
      <div className="px-6 lg:px-10 py-12 max-w-[1280px] mx-auto">
        <div className="text-center mb-10">
          <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">Pricing</Badge>
          <h1 className="text-4xl font-extrabold text-ink mb-3">Pricing That Scales With Your School</h1>
          <p className="text-base text-muted max-w-xl mx-auto">Compare the live SchoolPro annual packages. Prices are managed by IHLink from the Command Center.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {loading&&<p role="status">Loading current subscription prices…</p>}{error&&<p role="alert" className="text-rose-700">Pricing could not be loaded: {error}</p>}{!loading&&!error&&!plans.length&&<p>No active priced subscriptions are available.</p>}{plans.map((plan, i) => (
            <Card key={i} padding="lg" className={`relative ${plan.popular ? 'border-2 border-purple-400 shadow-float' : ''}`}>
              {plan.popular && <Badge className="absolute top-4 right-4 bg-purple-600 text-white border-purple-600">Most Popular</Badge>}
              <h3 className="text-xl font-bold text-ink">{plan.name}</h3>
              <p className="text-sm text-muted mb-4">{plan.desc}</p>
              <p className="text-4xl font-extrabold text-ink mb-1">{naira(plan.price)}<span className="text-sm font-normal text-muted">/year</span></p>
              <Link to="/schoolpro/register"><Button fullWidth themeClass={plan.popular ? 'bg-purple-600 hover:bg-purple-700' : undefined} variant={plan.popular ? undefined : 'secondary'}>Get Started</Button></Link>
              <div className="mt-6 space-y-3">
                {plan.features.map((f, j) => (
                  <div key={j} className="flex items-center gap-2 text-sm text-ink"><Check className="w-4 h-4 text-purple-500 shrink-0" /> {f}</div>
                ))}
              </div>
            </Card>
          ))}
        </div>

        <div className="mt-12 text-center">
          <p className="text-sm text-muted mb-4">Implementation, migration, training, support scope and service levels are confirmed in the school's final subscription agreement.</p>
          <Link to="/schoolpro/book-demo"><Button variant="secondary" rightIcon={<ArrowRight className="w-4 h-4" />}>Book a Demo First</Button></Link>
        </div>
      </div>
    </PageShell>
  );
}
