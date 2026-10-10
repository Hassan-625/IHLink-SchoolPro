import {PageShell} from '@/components/PageShell';
import {Card} from '@/components/ui/Card';
import {QuickContact} from '@/components/QuickContact';
import {SupportTicketForm} from '@/components/SupportTicketForm';
import {SupportKnowledgeBase} from '@/components/SupportKnowledgeBase';
export function SchoolProSupport(){return <PageShell product="schoolpro"><main className="mx-auto max-w-6xl space-y-6 px-4 py-8"><header><h1 className="text-3xl font-extrabold">How can we help?</h1><p className="mt-2">Chat with us and send support requests 24 hours, every day.</p></header><QuickContact/><Card><SupportKnowledgeBase product="schoolpro"/></Card><Card><h2 className="mb-4 text-xl font-bold">Send a message</h2><p className="mb-4 text-sm">Your message is sent to IHLink support here. You can follow it in your support history.</p><SupportTicketForm product="schoolpro"/></Card></main></PageShell>}
