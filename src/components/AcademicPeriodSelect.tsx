import {useEffect} from 'react';
import {useSchoolSession} from '@/hooks/useSchoolSession';
import {academicSessionOptions} from '@/lib/academicSessions';
import type {SelectHTMLAttributes} from 'react';
type Props=SelectHTMLAttributes<HTMLSelectElement>&{kind:'term'|'session';label?:string;placeholder?:string};
export function AcademicPeriodSelect({kind,label,placeholder,value,className='',...props}:Props){
 const scope=useSchoolSession();useEffect(()=>{if(kind==='session'&&scope.session&&String(value||'')!==scope.session)props.onChange?.({target:{value:scope.session}} as any)},[kind,scope.session]);
 const current=String(value||'');
 const defaults=kind==='term'?['First Term','Second Term','Third Term']:academicSessionOptions();
 const options=Array.from(new Set([...defaults,...(current?[current]:[])]));
 const select=<select {...props} onChange={e=>{if(kind==='session')scope.select(e.target.value);props.onChange?.(e)}} aria-label={props['aria-label']||label||(kind==='term'?'Term':'Academic session')} className={className||'w-full rounded-xl border p-3'} value={current}><option value="">{placeholder||`Select ${kind==='term'?'term':'academic session'}`}</option>{options.map(option=><option value={option} key={option}>{option}</option>)}</select>;
 return label?<label className="block text-sm font-semibold">{label}<div className="mt-1.5">{select}</div></label>:select;
}
