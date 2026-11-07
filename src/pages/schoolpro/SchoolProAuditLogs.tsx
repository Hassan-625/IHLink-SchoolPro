import { useEffect, useMemo, useState } from 'react';
import { RefreshCw, Search } from 'lucide-react';
import { ModulePage } from '@/components/ModulePage';
import { Card } from '@/components/ui/Card';
import { schoolSections } from './schoolShared';
import { supabase } from '@/lib/supabase';
import { useSchoolProContext } from '@/hooks/useSchoolProContext';

type AuditRow = {
  id: number;
  actor_id: string | null;
  action: string;
  entity_type: string | null;
  entity_id: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
  actor?: { name: string; role: string; email: string } | null;
};

export function SchoolProAuditLogs() {
  const ctx = useSchoolProContext();
  const [rows, setRows] = useState<AuditRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [query, setQuery] = useState('');

  async function load() {
    if (!supabase || !ctx.schoolId) {
      setRows([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    setError('');
    const result = await supabase
      .from('schoolpro_audit_logs')
      .select('id,actor_id,action,entity_type,entity_id,metadata,created_at')
      .eq('school_id', ctx.schoolId)
      .order('created_at', { ascending: false })
      .limit(300);
    if (result.error) {
      setError(result.error.message);
      setRows([]);
      setLoading(false);
      return;
    }
    const logs = (result.data || []) as Omit<AuditRow, 'actor'>[];
    const actorIds = [...new Set(logs.map(row => row.actor_id).filter((id): id is string => Boolean(id)))];
    let actors = new Map<string, AuditRow['actor']>();
    if (actorIds.length) {
      const profiles = await supabase
        .from('profiles')
        .select('id,first_name,middle_name,last_name,role,email')
        .in('id', actorIds);
      if (profiles.error) {
        setError('Audit events loaded, but actor names and roles could not be resolved.');
      } else {
        actors = new Map((profiles.data || []).map(profile => [
          profile.id,
          {
            name: [profile.first_name, profile.middle_name, profile.last_name].filter(Boolean).join(' ') || profile.email || 'Unknown user',
            role: String(profile.role || 'School staff').replaceAll('_', ' '),
            email: profile.email || ''
          }
        ]));
      }
    }
    setRows(logs.map(row => ({ ...row, actor: row.actor_id ? actors.get(row.actor_id) || null : null })));
    setLoading(false);
  }

  useEffect(() => { void load(); }, [ctx.schoolId]);

  const filtered = useMemo(() => {
    const term = query.trim().toLowerCase();
    return term ? rows.filter(row => JSON.stringify(row).toLowerCase().includes(term)) : rows;
  }, [rows, query]);

  return (
    <ModulePage product="schoolpro" sections={schoolSections} title="School Audit Logs" description="Review school-scoped activity records, including the actor, role, affected record and event details." userName={ctx.schoolName} userRole={ctx.role} metrics={[
      { label: 'Recorded events', value: String(rows.length) },
      { label: 'Visible events', value: String(filtered.length) },
      { label: 'Workspace', value: ctx.schoolName }
    ]}>
      {error && <div role="status" className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">{error}</div>}
      <Card padding="lg">
        <div className="mb-4 flex flex-wrap gap-3">
          <label className="relative min-w-[220px] flex-1">
            <Search className="absolute left-3 top-3 h-4 w-4 text-muted" />
            <input value={query} onChange={event => setQuery(event.target.value)} placeholder="Search activity, staff or record" className="w-full rounded-xl border border-slate-300 py-2.5 pl-10 pr-4 text-sm" />
          </label>
          <button onClick={() => void load()} className="inline-flex items-center gap-2 rounded-xl border px-4 py-2.5 text-sm font-semibold">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />Refresh
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px] text-left text-sm">
            <thead className="bg-slate-100"><tr>{['Activity','Performed by','Role','Affected record','Details','Date & time'].map(label => <th key={label} className="p-3">{label}</th>)}</tr></thead>
            <tbody>
              {filtered.map(row => <tr key={row.id} className="border-t align-top">
                <td className="p-3 font-semibold">{row.action}</td>
                <td className="p-3">{row.actor?.name || (row.actor_id ? 'Staff profile unavailable' : 'System')}<div className="text-xs text-muted">{row.actor?.email || ''}</div></td>
                <td className="p-3 capitalize">{row.actor?.role || '—'}</td>
                <td className="p-3">{row.entity_type || '—'}<div className="text-xs text-muted">{row.entity_id || ''}</div></td>
                <td className="max-w-[320px] whitespace-pre-wrap break-words p-3 text-xs">{row.metadata ? JSON.stringify(row.metadata, null, 2) : '—'}</td>
                <td className="p-3 whitespace-nowrap">{new Date(row.created_at).toLocaleString()}</td>
              </tr>)}
            </tbody>
          </table>
        </div>
        {!loading && !filtered.length && <p className="py-10 text-center text-sm text-muted">No audit events have been recorded for this workspace yet.</p>}
      </Card>
    </ModulePage>
  );
}
