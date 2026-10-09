import {useEffect,useState} from 'react';
import {Link} from 'react-router-dom';
import {supabase} from '@/lib/supabase';
import {Button} from './ui/Button';
type Period={term:string;session:string;allowed:boolean;reason:string|null};
/** Uses a score-free manifest; full report authorization is checked again on opening. */
export function PublishedSchoolResults({studentId}:{studentId:string}){
 const [periods,setPeriods]=useState<Period[]>([]),[loading,setLoading]=useState(true),[error,setError]=useState('');
 useEffect(()=>{let active=true;setPeriods([]);setLoading(true);setError('');if(!supabase){setLoading(false);return;}void (supabase as any).rpc('schoolpro_family_result_periods',{p_student:studentId}).then((r:any)=>{if(!active)return;setLoading(false);if(r.error)setError('Your results could not be loaded. Please try again.');else setPeriods(r.data||[])});return()=>{active=false}},[studentId]);
 return <section className="min-w-0 space-y-3" aria-label="Published report cards"><h3 className="font-bold">Published report cards</h3>{loading?<p className="text-sm text-muted">Loading results…</p>:error?<p role="alert" className="text-sm text-rose-700">{error}</p>:!periods.length?<p className="text-sm text-muted">Your school has not published a report card yet.</p>:periods.map(p=><div key={p.term+'|'+p.session} className="rounded-xl border p-3"><p className="font-semibold">{p.term} · {p.session}</p>{p.allowed?<><p className="mt-1 text-xs text-muted">View scores, behaviour, attendance and the complete report.</p><Link to={`/schoolpro/report-card?student=${encodeURIComponent(studentId)}&term=${encodeURIComponent(p.term)}&session=${encodeURIComponent(p.session)}`}><Button size="sm" className="mt-3">View / print report card</Button></Link></>:<p className="mt-2 text-sm text-amber-700">{p.reason||'Please contact your school about access to this report.'}</p>}</div>)}</section>;
}
