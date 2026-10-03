import { PageShell } from "@/components/PageShell";
import { Card } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { SupportTicketForm } from "@/components/SupportTicketForm";
import { QuickContact } from "@/components/QuickContact";
import { Button } from "@/components/ui/Button";
import { platformExploreUrl } from "@/lib/platformUrls";
import {
  Mail,
  Phone,
  MessageSquare,
  Clock,
  Search,
  FileText,
  ChevronRight,
} from "lucide-react";

const helpCategories = [
  { title: "Getting Started", desc: "Setup and onboarding" },
  {
    title: "Result Processing",
    desc: "Scores, broadsheets, report cards",
  },
  { title: "Fee Management", desc: "Invoices, payments, receipts" },
  { title: "Parent Portal", desc: "Access, results, communication" },
];

const popularArticles = [
  "How to set up grading scales",
  "Importing student data from Excel",
  "Publishing results to parents",
  "Setting up fee structures",
  "Configuring CBT exams",
  "Customizing report card templates",
];

export function SchoolProSupport() {
  return (
    <PageShell product="schoolpro">
      <section className="py-12 bg-gradient-to-br from-purple-50 to-indigo-50">
        <div className="px-6 lg:px-10 max-w-[1280px] mx-auto text-center">
          <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">
            Support Centre
          </Badge>
          <h1 className="text-3xl font-extrabold text-ink mb-3">
            How Can We Help?
          </h1>
          <p className="text-sm text-muted mb-6 max-w-lg mx-auto">
            Search our knowledge base or contact our support team.
          </p>
          <div className="max-w-xl mx-auto relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted" />
            <input
              type="text"
              placeholder="Search for help articles..."
              className="w-full pl-12 pr-4 py-3 text-sm rounded-xl border border-border bg-white shadow-card focus:outline-none focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500"
            />
          </div>
        </div>
      </section>

      <section className="py-12 px-6 lg:px-10 max-w-[1280px] mx-auto">
        <Card padding="lg" className="mb-8 overflow-hidden"><div className="grid gap-6 md:grid-cols-[1fr_280px] md:items-center"><div><Badge className="mb-3 bg-amber-50 text-amber-700 border-amber-200">IHLink Print & Branding</Badge><h2 className="text-2xl font-extrabold text-ink">Need report cards, ID cards, banners, signage or school branding?</h2><p className="mt-2 text-sm text-muted">Patronize IHLink Print & Branding for your school printing, identity and branding requirements.</p><a href={platformExploreUrl("print")}><Button className="mt-4">Contact us for branding & printing</Button></a></div><div className="overflow-hidden rounded-2xl border border-amber-100 bg-white shadow-sm"><img src="/images/IHLink%20School%20Branding%20Showcase.png" alt="IHLink Print & Branding services for schools" className="block h-auto w-full object-contain" loading="lazy" /></div></div></Card>
        <QuickContact className="mb-8" />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
          {helpCategories.map((c, i) => (
            <Card key={i} padding="lg" hover>
              <div className="w-11 h-11 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center mb-4">
                <FileText className="w-5 h-5" />
              </div>
              <h3 className="text-base font-bold text-ink mb-1">{c.title}</h3>
              <p className="text-xs text-muted mb-3">{c.desc}</p>
              <div className="flex items-center justify-between">
                <Badge>Help topic</Badge>
                <ChevronRight className="w-4 h-4 text-muted" />
              </div>
            </Card>
          ))}
        </div>

        <div className="grid grid-cols-12 gap-6">
          <div className="col-span-12 lg:col-span-7">
            <Card padding="lg">
              <h2 className="text-lg font-bold text-ink mb-4">
                Popular Articles
              </h2>
              <div className="space-y-2">
                {popularArticles.map((a, i) => (
                  <div
                    key={i}
                    className="flex items-center justify-between p-3 rounded-lg border border-border hover:bg-gray-50 cursor-pointer"
                  >
                    <span className="text-sm font-medium text-ink">{a}</span>
                    <ChevronRight className="w-4 h-4 text-muted" />
                  </div>
                ))}
              </div>
            </Card>
          </div>
          <div className="col-span-12 lg:col-span-5">
            <Card padding="lg" className="mb-4">
              <h2 className="text-lg font-bold text-ink mb-4">Contact Us</h2>
              <div className="space-y-3">
                {[
                  {
                    icon: MessageSquare,
                    label: "Live Chat",
                    value: "Availability depends on active support channels",
                    color: "bg-purple-50 text-purple-600",
                  },
                  {
                    icon: Mail,
                    label: "Email",
                    value: "hassanisahassan12@gmail.com",
                    color: "bg-sky-50 text-sky-600",
                  },
                  {
                    icon: Phone,
                    label: "Phone",
                    value: "0814 667 6278",
                    color: "bg-amber-50 text-amber-600",
                  },
                  {
                    icon: Clock,
                    label: "Hours",
                    value: "Response times vary by request",
                    color: "bg-emerald-50 text-emerald-600",
                  },
                ].map((c, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <div
                      className={`w-10 h-10 rounded-lg ${c.color} flex items-center justify-center`}
                    >
                      <c.icon className="w-5 h-5" />
                    </div>
                    <div>
                      <p className="text-sm font-bold text-ink">{c.label}</p>
                      <p className="text-xs text-muted">{c.value}</p>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
            <Card padding="lg">
              <h2 className="text-lg font-bold text-ink mb-4">
                Send a Message
              </h2>
              <SupportTicketForm
                product="schoolpro"
                accentClass="bg-purple-600 hover:bg-purple-700"
              />
            </Card>
          </div>
        </div>
      </section>
    </PageShell>
  );
}
