import { PageShell } from '@/components/PageShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import {
  DollarSign, FileText, ClipboardCheck, MessageSquare, BarChart3,
  Shield, BookOpen, Calendar, Bell, Award, Users, GraduationCap,
  Cpu, Library, Bus, BedDouble, Package, CreditCard, Plane, HeartPulse,
  Gavel, CalendarDays, ScrollText, MessageCircle,
} from 'lucide-react';

const featureGroups = [
  {
    title: 'Core Management',
    features: [
      { icon: Users, name: 'Student Management', desc: 'Admissions, profiles, and records' },
      { icon: ClipboardCheck, name: 'Attendance', desc: 'Daily and class attendance tracking' },
      { icon: FileText, name: 'Result Processing', desc: 'Score entry, broadsheets, report cards' },
      { icon: DollarSign, name: 'Fee Collection', desc: 'Invoices, payments, and receipts' },
      { icon: Calendar, name: 'Timetables', desc: 'Class and exam scheduling' },
      { icon: BookOpen, name: 'Subjects & Classes', desc: 'Manage classes, arms, and subjects' },
    ],
  },
  {
    title: 'Communication',
    features: [
      { icon: MessageSquare, name: 'Parent Portal', desc: 'Results, fees, and messaging' },
      { icon: Bell, name: 'Announcements', desc: 'School-wide and class-level notices' },
      { icon: MessageCircle, name: 'SMS Centre', desc: 'Bulk SMS to parents and staff' },
    ],
  },
  {
    title: 'Academic',
    features: [
      { icon: Cpu, name: 'CBT Module', desc: 'Computer-based testing and grading' },
      { icon: Library, name: 'Library', desc: 'Book catalog and lending management' },
      { icon: ScrollText, name: 'Transcripts', desc: 'Academic transcripts and records' },
    ],
  },
  {
    title: 'Additional Modules',
    features: [
      { icon: Bus, name: 'Transportation', desc: 'Bus routes and tracking' },
      { icon: BedDouble, name: 'Hostel', desc: 'Boarding house management' },
      { icon: Package, name: 'Inventory', desc: 'School assets and supplies' },
      { icon: CreditCard, name: 'Payroll', desc: 'Staff salary management' },
      { icon: HeartPulse, name: 'Medical Records', desc: 'Student health tracking' },
      { icon: Gavel, name: 'Discipline', desc: 'Behaviour and incident records' },
      { icon: CalendarDays, name: 'Events', desc: 'School calendar and events' },
      { icon: Award, name: 'Certificates', desc: 'Certificate generation' },
    ],
  },
];

export function SchoolProFeatures() {
  return (
    <PageShell product="schoolpro">
      <div className="px-6 lg:px-10 py-12 max-w-[1280px] mx-auto">
        <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">Features</Badge>
        <h1 className="text-3xl font-extrabold text-ink mb-2">Complete School Management Features</h1>
        <p className="text-sm text-muted mb-10 max-w-xl">Every tool you need to run your school efficiently — from admissions to graduation.</p>

        {featureGroups.map((group, gi) => (
          <div key={gi} className="mb-10">
            <h2 className="text-xl font-bold text-ink mb-4">{group.title}</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {group.features.map((f, i) => (
                <Card key={i} padding="lg" hover>
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center shrink-0"><f.icon className="w-5 h-5" /></div>
                    <div>
                      <h3 className="text-sm font-bold text-ink">{f.name}</h3>
                      <p className="text-xs text-muted mt-0.5">{f.desc}</p>
                    </div>
                  </div>
                </Card>
              ))}
            </div>
          </div>
        ))}
      </div>
    </PageShell>
  );
}
