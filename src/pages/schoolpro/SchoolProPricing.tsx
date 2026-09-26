import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { PageShell } from '@/components/PageShell';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { naira } from '@/lib/designTokens';
import { Check, ArrowRight } from 'lucide-react';
import { supabase } from '@/lib/supabase';

const fallbackPlans = [
  { name: 'Starter', price: 15000, perStudent: 0, desc: 'For small schools under 200 students', features: ['Student management', 'Attendance', 'Result processing', 'Fee collection', 'Parent portal', 'Email support'], popular: false },
  { name: 'Professional', price: 35000, perStudent: 50, desc: 'For growing schools up to 500 students', features: ['Everything in Starter', 'CBT module', 'SMS centre (1000/month)', 'Library management', 'Transportation', 'Report card branding', 'Priority support'], popular: true },
  { name: 'Enterprise', price: 75000, perStudent: 100, desc: 'For large schools and multi-campus', features: ['Everything in Professional', 'Multi-campus support', 'Hostel management', 'Payroll', 'Inventory', 'Custom domains', 'Dedicated account manager', '24/7 phone support'], popular: false },
];

export function SchoolProPricing() {
  const [plans,setPlans]=useState(fallbackPlans);
  useEffect(()=>{if(!supabase)return;void supabase.from('schoolpro_plan_catalog').select('tier,display_name,term_price,per_student_price,features').eq('is_active',true).order('term_price').then(({data})=>{if(data?.length)setPlans(data.map((p:any)=>({name:p.display_name,price:Number(p.term_price),perStudent:Number(p.per_student_price),desc:`${p.display_name} SchoolPro subscription`,features:Object.entries(p.features||{}).filter(([,v])=>v).map(([k])=>k.replaceAll('_',' ')),popular:p.tier==='professional'})))})},[]);
  return (
    <PageShell product="schoolpro">
      <div className="px-6 lg:px-10 py-12 max-w-[1280px] mx-auto">
        <div className="text-center mb-10">
          <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">Pricing</Badge>
          <h1 className="text-4xl font-extrabold text-ink mb-3">Pricing That Scales With Your School</h1>
          <p className="text-base text-muted max-w-xl mx-auto">Compare the proposed SchoolPro packages. Final commercial terms are confirmed during onboarding.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {plans.map((plan, i) => (
            <Card key={i} padding="lg" className={`relative ${plan.popular ? 'border-2 border-purple-400 shadow-float' : ''}`}>
              {plan.popular && <Badge className="absolute top-4 right-4 bg-purple-600 text-white border-purple-600">Most Popular</Badge>}
              <h3 className="text-xl font-bold text-ink">{plan.name}</h3>
              <p className="text-sm text-muted mb-4">{plan.desc}</p>
              <p className="text-4xl font-extrabold text-ink mb-1">{naira(plan.price)}<span className="text-sm font-normal text-muted">/term</span></p>
              {plan.perStudent > 0 && <p className="text-xs text-muted mb-6">+ {naira(plan.perStudent)}/student</p>}
              {!plan.perStudent && <p className="text-xs text-muted mb-6">No per-student fee</p>}
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
