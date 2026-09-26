import { PageShell } from '@/components/PageShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Accordion } from '@/components/ui/Stepper';
import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/Button';

const faqs = [
  { question: 'How long does setup take?', answer: 'Setup time depends on school size, selected modules and migration requirements. A rollout schedule is confirmed during onboarding.' },
  { question: 'Can parents pay fees online?', answer: 'The parent portal supports school fee workflows. Available online payment methods depend on the production payment gateway configured for the school.' },
  { question: 'Does SchoolPro support CBT?', answer: 'CBT is part of the SchoolPro module catalogue and becomes available when that production module is enabled for the school.' },
  { question: 'Can I customize report cards?', answer: 'Yes. Report cards are fully customizable with your school logo, grading scale, and comment templates.' },
  { question: 'Is there a mobile app for parents?', answer: 'Parents can use the responsive SchoolPro web portal. Native iOS and Android applications are not represented as released unless separately published.' },
  { question: 'What happens to my data if I cancel?', answer: 'Data export, retention and deletion are handled according to the school\'s applicable agreement and production data-retention policy.' },
  { question: 'Do you offer training for staff?', answer: 'Training format, location and scope are agreed during onboarding based on the school\'s implementation plan.' },
  { question: 'Can I manage multiple campuses?', answer: 'Yes. The Enterprise plan supports multi-campus management with centralized reporting.' },
];

export function SchoolProFaq() {
  return (
    <PageShell product="schoolpro">
      <div className="px-6 lg:px-10 py-12 max-w-[800px] mx-auto">
        <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">FAQ</Badge>
        <h1 className="text-3xl font-extrabold text-ink mb-2">SchoolPro FAQ</h1>
        <p className="text-sm text-muted mb-8">Everything you need to know about IHLink SchoolPro.</p>
        <Accordion items={faqs} defaultOpen={0} />
        <Card padding="lg" className="mt-8 text-center bg-schoolpro-soft">
          <h3 className="text-lg font-bold text-ink mb-2">Still have questions?</h3>
          <p className="text-sm text-muted mb-4">Our team is ready to help.</p>
          <Link to="/schoolpro/support"><Button themeClass="bg-purple-600 hover:bg-purple-700">Contact Support</Button></Link>
        </Card>
      </div>
    </PageShell>
  );
}
