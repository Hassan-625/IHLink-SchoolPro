import {useState} from 'react';
import {Button} from '@/components/ui/Button';
import {supabase} from '@/lib/supabase';
import {printSchoolDocument} from '@/lib/nativePrint';
import {saveSchoolFile,schoolFileName} from '@/lib/schoolDownloads';
import {customerMessage} from '@/lib/customerMessage';

function calendarText(value:unknown){return String(value??'').replace(/\\/g,'\\\\').replace(/\r?\n/g,'\\n').replace(/[,;]/g,'\\$&');}
function nextDay(day:string){const date=new Date(day+'T00:00:00Z');date.setUTCDate(date.getUTCDate()+1);return date.toISOString().slice(0,10).replaceAll('-','');}
export function SchoolProRecordActions({kind,record,schoolName,members,classes,canManage,preview,onPreviewChange,onRefresh}:{kind:string;record:any;schoolName:string;members:any[];classes:any[];canManage:boolean;preview:boolean;onPreviewChange:(open:boolean)=>void;onRefresh:()=>Promise<void>}){
 const [busy,setBusy]=useState(false),[message,setMessage]=useState(''),[reference,setReference]=useState('');
 const staff=members.find(m=>m.id===record.member_id),name=[staff?.profile?.first_name,staff?.profile?.last_name].filter(Boolean).join(' ')||'Staff member';
 const money=(value:number)=>new Intl.NumberFormat('en-NG',{style:'currency',currency:'NGN'}).format(Number(value||0));
 async function update(status:string){if(!supabase||busy)return;setBusy(true);setMessage('');try{
  const result=status==='approved'?await supabase.rpc('process_schoolpro_payroll',{p_record:record.id}):await supabase.from('schoolpro_payroll_records').update({status,payment_reference:reference.trim()}).eq('school_id',record.school_id).eq('id',record.id).in('status',['approved','processed']).select('id');
  if(result.error)throw result.error;if(status==='paid'&&!result.data?.length)throw new Error('Refresh this payroll record before trying again.');setMessage(status==='paid'?'Payment recorded.':'Payroll approved.');await onRefresh();
 }catch(error){setMessage(customerMessage(error instanceof Error?error.message:(error as any)?.message||'This payroll record could not be updated.'));}finally{setBusy(false);}}
 async function exportCalendar(){setBusy(true);try{
  const target=classes.find(c=>c.id===record.class_id);const text=['BEGIN:VCALENDAR','VERSION:2.0','PRODID:-//IHLink//SchoolPro//EN','BEGIN:VEVENT','UID:'+record.id+'@schoolpro.ihlink','DTSTAMP:'+new Date().toISOString().replace(/[-:]/g,'').replace(/\.\d{3}/,''),'DTSTART;VALUE=DATE:'+record.event_date.replaceAll('-',''),'DTEND;VALUE=DATE:'+nextDay(record.end_date||record.event_date),'SUMMARY:'+calendarText(record.title),'DESCRIPTION:'+calendarText([schoolName,target?.name||'Whole school',record.details].filter(Boolean).join('\n')),'END:VEVENT','END:VCALENDAR',''].join('\r\n');
  const saved=await saveSchoolFile(new Blob([text],{type:'text/calendar'}),schoolFileName([schoolName,record.title,record.event_date],'ics'));setMessage(saved?'Calendar file prepared.':'Saving cancelled.');
 }catch{setMessage('The calendar file could not be saved. Please try again.');}finally{setBusy(false);}}
 if(!['payroll','calendar'].includes(kind))return null;
 return <div className="mt-3 space-y-3 border-t pt-3">
 {kind==='calendar'?<Button disabled={busy} variant="secondary" onClick={()=>void exportCalendar()}>Save to calendar</Button>:<>
 <div className="flex flex-wrap gap-2">{canManage&&record.status==='draft'&&<Button disabled={busy} onClick={()=>void update('approved')}>Approve payroll</Button>}<Button variant="secondary" onClick={()=>onPreviewChange(!preview)}>{preview?'Close payslip':'View payslip'}</Button></div>
 {canManage&&['approved','processed'].includes(record.status)&&<div><label className="block text-sm font-semibold">Payment reference<input className="mt-1 w-full rounded-xl border p-3" value={reference} onChange={e=>setReference(e.target.value)} placeholder="Reference from your completed staff payment"/></label><Button className="mt-2" disabled={busy||!reference.trim()} onClick={()=>{if(confirm('Confirm this staff payment has already been made?'))void update('paid');}}>Record payment made</Button><p className="mt-2 text-xs">Record a completed payment to keep your payroll history up to date.</p></div>}
 {preview&&<div><div className="print-document rounded-xl p-5" style={{backgroundColor:"#ffffff",color:"#0f172a"}}><h2 className="text-lg font-black">{schoolName}</h2><h3 className="font-bold">Staff payslip · {record.period}</h3><p>{name}</p><p>Status: {record.status==='processed'?'Approved':record.status}</p><table className="mt-4 w-full"><tbody><tr><th className="text-left">Gross pay</th><td>{money(record.gross)}</td></tr><tr><th className="text-left">Deductions</th><td>{money(record.deductions)}</td></tr><tr><th className="text-left">Net pay</th><td>{money(record.net)}</td></tr></tbody></table>{record.paid_at&&<p className="mt-4">Paid: {new Date(record.paid_at).toLocaleDateString('en-NG')} · {record.payment_reference}</p>}{record.status!=='paid'&&<p className="mt-4 text-sm">Payment has not yet been recorded.</p>}</div><Button className="mt-2" variant="secondary" onClick={()=>void printSchoolDocument({name:schoolFileName([schoolName,name,record.period,'Payslip'],'pdf'),paperSize:'A4',orientation:'portrait'})}>Print / save payslip</Button></div>}
 </>}{message&&<p role="status" className="text-sm font-semibold">{message}</p>}
 </div>;
}
