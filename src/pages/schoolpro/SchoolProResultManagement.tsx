import { PageShell } from '@/components/PageShell';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Accordion } from '@/components/ui/Stepper';
import { Link } from 'react-router-dom';
import { FileText, Upload, CheckCircle2, Lock, MessageSquare, ClipboardList, FileBarChart, ScrollText, Eye, ArrowRight } from 'lucide-react';

const steps = [
  { icon: FileText, title: 'Score Entry', desc: 'Teachers enter CA and exam scores per subject and class.' },
  { icon: Upload, title: 'Excel Import', desc: 'Bulk import scores from Excel spreadsheets.' },
  { icon: CheckCircle2, title: 'Validation', desc: 'System validates scores against grading rules.' },
  { icon: ClipboardList, title: 'Approval', desc: 'Administrators review and approve results.' },
  { icon: FileBarChart, title: 'Broadsheet', desc: 'Generate class broadsheets and subject analysis.' },
  { icon: Eye, title: 'Report Card', desc: 'Preview and publish student report cards.' },
  { icon: Lock, title: 'Locking', desc: 'Lock results to prevent further changes.' },
];

const features = [
  { icon: FileText, title: 'Score Entry Table', desc: 'Enter CA (30) and Exam (70) scores for each student.' },
  { icon: Upload, title: 'Excel Import', desc: 'Import scores in bulk from Excel files.' },
  { icon: CheckCircle2, title: 'Result Validation', desc: 'Automatic validation against grading scale.' },
  { icon: ClipboardList, title: 'Result Approval', desc: 'Multi-level approval workflow for results.' },
  { icon: FileBarChart, title: 'Class Broadsheet', desc: 'Full class broadsheet with rankings.' },
  { icon: FileBarChart, title: 'Subject Analysis', desc: 'Detailed subject performance breakdown.' },
  { icon: Eye, title: 'Report Card Preview', desc: 'Professional report cards with school branding.' },
  { icon: Lock, title: 'Result Locking', desc: 'Lock published results to prevent tampering.' },
  { icon: MessageSquare, title: 'Comment Generator', desc: 'Auto-generate teacher and principal comments.' },
  { icon: ScrollText, title: 'Transcript Preview', desc: 'Generate academic transcripts for students.' },
];

export function SchoolProResultManagement() {
  return (
    <PageShell product="schoolpro">
      <section className="py-12 bg-gradient-to-br from-purple-50 to-indigo-50">
        <div className="px-6 lg:px-10 max-w-[1280px] mx-auto">
          <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">Result Management</Badge>
          <h1 className="text-4xl font-extrabold text-ink mb-3">Process Results in Hours, Not Weeks</h1>
          <p className="text-base text-muted max-w-xl">From score entry to published report cards — SchoolPro handles the entire result processing workflow.</p>
        </div>
      </section>

      <section className="py-12 px-6 lg:px-10 max-w-[1280px] mx-auto">
        <h2 className="text-xl font-bold text-ink mb-6">How It Works</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
          {steps.map((s, i) => (
            <Card key={i} padding="lg">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center font-bold">{i + 1}</div>
                <s.icon className="w-5 h-5 text-purple-600" />
              </div>
              <h3 className="text-sm font-bold text-ink">{s.title}</h3>
              <p className="text-xs text-muted mt-1">{s.desc}</p>
            </Card>
          ))}
        </div>

        <h2 className="text-xl font-bold text-ink mb-4">Result Management Features</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {features.map((f, i) => (
            <Card key={i} padding="lg" hover>
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center shrink-0"><f.icon className="w-5 h-5" /></div>
                <div><h3 className="text-sm font-bold text-ink">{f.title}</h3><p className="text-xs text-muted mt-0.5">{f.desc}</p></div>
              </div>
            </Card>
          ))}
        </div>
      </section>

      <section className="py-12 bg-schoolpro-soft">
        <div className="px-6 lg:px-10 max-w-[1280px] mx-auto text-center">
          <Card padding="lg" className="max-w-lg mx-auto bg-white">
            <h2 className="text-xl font-bold text-ink mb-2">See Result Management in Action</h2>
            <p className="text-sm text-muted mb-4">Book a demo and watch how fast result processing can be.</p>
            <Link to="/schoolpro/book-demo"><Button themeClass="bg-purple-600 hover:bg-purple-700" rightIcon={<ArrowRight className="w-4 h-4" />}>Book a Demo</Button></Link>
          </Card>
        </div>
      </section>
    </PageShell>
  );
}
