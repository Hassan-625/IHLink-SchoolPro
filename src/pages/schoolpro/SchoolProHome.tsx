import { Link } from 'react-router-dom';
import { PageShell } from '@/components/PageShell';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Accordion } from '@/components/ui/Stepper';
import { useToast } from '@/components/ui/Toast';
import { ExperiencePhoto } from '@/components/ExperiencePhoto';
import { ManagedContentSections } from '@/components/ManagedContentSections';
import { IH_LINK_LOGO } from '@/assets/ihlinkLogo';
import { useManagedHero } from '@/hooks/useManagedHero';
import {
  GraduationCap, Users, DollarSign, ClipboardCheck, MessageSquare,
  BarChart3, Shield, BookOpen, Calendar, FileText, Bell, Award,

} from 'lucide-react';

const features = [
  { icon: DollarSign, title: 'Revenue Collection', desc: 'Share school bank details, review transfer receipts and track outstanding balances.', color: 'bg-purple-50 text-purple-600' },
  { icon: FileText, title: 'Result Processing', desc: 'Process, validate, and publish results in hours, not weeks.', color: 'bg-indigo-50 text-indigo-600' },
  { icon: ClipboardCheck, title: 'Administrative Automation', desc: 'Automate attendance, timetables, and daily school operations.', color: 'bg-amber-50 text-amber-600' },
  { icon: MessageSquare, title: 'Parent Communication', desc: 'Send SMS, in-app messages, and announcements to parents instantly.', color: 'bg-sky-50 text-sky-600' },
  { icon: BarChart3, title: 'Academic Performance', desc: 'Track and analyze student, class, and subject performance trends.', color: 'bg-emerald-50 text-emerald-600' },
  { icon: Shield, title: 'Student Safety', desc: 'Monitor attendance and get alerts for absences and incidents.', color: 'bg-rose-50 text-rose-600' },
];

const faqs = [
  { question: 'How long does it take to set up SchoolPro for my school?', answer: 'Setup timing depends on your school size, selected modules and migration requirements. The onboarding team confirms the implementation plan after review.' },
  { question: 'Can parents access results on their phones?', answer: 'Yes. SchoolPro includes a responsive parent web portal for linked student information, results and configured fee workflows.' },
  { question: 'Is my school data secure?', answer: 'SchoolPro uses authenticated access and database access controls. Production backup, retention and privacy controls are applied according to the deployed environment and school agreement.' },
  { question: 'Do you support CBT (Computer-Based Testing)?', answer: 'CBT is included in the SchoolPro module catalogue and is completed as part of the school\'s enabled production modules.' },
  { question: 'Can I customize the report card format?', answer: 'Yes. Report cards are fully customizable with your school logo, grading scale, and comment templates.' },
];

export function SchoolProHome() {
  const hero = useManagedHero('schoolpro');
  const { showToast } = useToast();
  return (
    <PageShell product="schoolpro">
      {/* Hero */}
      <section className="relative overflow-hidden bg-gradient-to-br from-purple-700 via-indigo-600 to-purple-500 text-white">
        <div className="absolute inset-0 grid-pattern opacity-10" />
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-purple-400/20 rounded-full blur-[120px]" />
        <div className="relative px-6 lg:px-10 pt-16 pb-20 max-w-[1280px] mx-auto">
          <div className="grid grid-cols-12 gap-8 items-center">
            <div className="col-span-12 lg:col-span-7">
              <Badge className="bg-white/10 text-white border-white/20 mb-4">{hero?.eyebrow || 'School Management Platform'}</Badge>
              <h1 className="text-5xl font-extrabold mb-4 leading-tight">{hero?.title || 'Run Your School Smarter, Faster and More Profitably'}</h1>
              <p className="text-lg text-purple-50 mb-6 max-w-xl">{hero?.body || 'From fee collection and result processing to parent communication and attendance — IHLink SchoolPro handles it all in one platform built for Nigerian schools.'}</p>
              <div className="flex flex-wrap gap-4">
                <Link to={hero?.cta_link || '/schoolpro/book-demo'}><Button size="xl" variant="secondary" className="!bg-white !text-purple-700 hover:!bg-purple-50 border-white">{hero?.cta_label || 'Book a Demo'}</Button></Link>
                <Link to="/schoolpro/register"><Button size="xl" variant="secondary" className="bg-white/10 text-white border-white/20 hover:bg-white/20">Register Your School</Button></Link><Link to="/schoolpro/custom"><Button size="xl" variant="secondary" className="bg-white/10 text-white border-white/20 hover:bg-white/20">Request Custom SchoolPro</Button></Link>
              </div>
            </div>
            <div className="col-span-12 lg:col-span-5">
              <div className="rounded-2xl border border-white/15 bg-white/10 p-6 backdrop-blur">
                <div className="mb-5 flex items-center gap-3"><img src={IH_LINK_LOGO} alt="IHLink" className="h-11 w-11 rounded-xl bg-white object-contain p-1"/><div><b className="block">SchoolPro by IHLink</b><span className="text-xs text-purple-100">Connected school management</span></div></div>
                <p className="text-sm text-purple-50">One workspace for school operations, results and school-owned fee records.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <ExperiencePhoto src="/images/service-scene-clean.webp" alt="IHLink SchoolPro branded school and exam concept" illustration eyebrow="Built around the classroom" title="Technology that gives educators more time to teach" text="SchoolPro connects administrators, teachers, parents and students while keeping the experience familiar, friendly and easy to learn." accentClass="text-purple-700" />

      {/* Features */}
      <section className="py-16 px-6 lg:px-10 max-w-[1280px] mx-auto">
        <div className="text-center mb-10">
          <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">Features</Badge>
          <h2 className="text-3xl font-extrabold text-ink mb-3">Everything Your School Needs in One Platform</h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {features.map((f, i) => (
            <Card key={i} padding="lg" hover>
              <div className={`w-11 h-11 rounded-xl ${f.color} flex items-center justify-center mb-4`}><f.icon className="w-5 h-5" /></div>
              <h3 className="text-base font-bold text-ink mb-1">{f.title}</h3>
              <p className="text-sm text-muted">{f.desc}</p>
            </Card>
          ))}
        </div>
      </section>

      {/* Portals */}
      <section className="py-16 bg-schoolpro-soft">
        <div className="px-6 lg:px-10 max-w-[1280px] mx-auto">
          <div className="text-center mb-10">
            <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">Portals</Badge>
            <h2 className="text-3xl font-extrabold text-ink mb-3">Built for Every Role in Your School</h2>
          </div>
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
            {[
              { icon: Award, label: 'Proprietor', href: '/schoolpro/login', desc: 'School oversight & finances' },
              { icon: ClipboardCheck, label: 'Administrator', href: '/schoolpro/login', desc: 'Manage students & staff' },
              { icon: BookOpen, label: 'Teacher', href: '/schoolpro/teacher-login', desc: 'Enter scores & attendance' },
              { icon: Users, label: 'Parent', href: '/schoolpro/parent-login', desc: 'View results & submit fee receipts' },
              { icon: GraduationCap, label: 'Student', href: '/schoolpro/student-login', desc: 'Check results & assignments' },
            ].map((p, i) => (
              <Link key={i} to={p.href}>
                <Card padding="lg" hover className="text-center h-full">
                  <div className="w-12 h-12 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center mx-auto mb-3"><p.icon className="w-6 h-6" /></div>
                  <h3 className="text-sm font-bold text-ink">{p.label}</h3>
                  <p className="text-xs text-muted mt-1">{p.desc}</p>
                </Card>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16 px-6 lg:px-10 max-w-[1280px] mx-auto">
        <Card padding="lg" className="bg-gradient-to-br from-purple-600 to-indigo-600 text-white border-0">
          <div className="flex items-center justify-between flex-wrap gap-6">
            <div>
              <h2 className="text-2xl font-bold mb-2">Ready to Transform Your School?</h2>
              <p className="text-sm text-purple-50">Bring your school operations, results, fees and communication into one managed platform.</p>
            </div>
            <div className="flex gap-3">
              <Link to="/schoolpro/book-demo"><Button size="lg" className="bg-white text-purple-600 hover:bg-gray-100">Book a Demo</Button></Link>
              <Link to="/schoolpro/pricing"><Button size="lg" variant="secondary" className="bg-white/10 text-white border-white/20 hover:bg-white/20">View Pricing</Button></Link>
            </div>
          </div>
        </Card>
      </section>

      {/* FAQ */}
      <section className="py-16 bg-schoolpro-soft">
        <div className="px-6 lg:px-10 max-w-[800px] mx-auto">
          <div className="text-center mb-8">
            <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">FAQ</Badge>
            <h2 className="text-3xl font-extrabold text-ink">Frequently Asked Questions</h2>
          </div>
          <Accordion items={faqs} defaultOpen={0} />
        </div>
      </section>
      <ManagedContentSections pageKey="schoolpro" />
    </PageShell>
  );
}
