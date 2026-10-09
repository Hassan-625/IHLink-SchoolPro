import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {Card} from '@/components/ui/Card';
import {Button} from '@/components/ui/Button';
export function SchoolCodeCard({schoolId}:{schoolId:string}){
 const [code,setCode]=useState(''),[copied,setCopied]=useState(false);
 useEffect(()=>{let current=true;setCode('');setCopied(false);if(supabase&&schoolId)void supabase.from('schoolpro_schools').select('code').eq('id',schoolId).maybeSingle().then(({data})=>{if(current)setCode(data?.code||'')});return()=>{current=false}},[schoolId]);
 if(!code)return null;
 return <Card><div className="flex flex-wrap items-center justify-between gap-3"><div className="min-w-0"><h3 className="font-bold">School code</h3><p className="mt-1 break-words font-mono text-lg font-bold">{code}</p></div><Button variant="secondary" onClick={()=>void navigator.clipboard.writeText(code).then(()=>setCopied(true)).catch(()=>setCopied(false))}>{copied?'Copied':'Copy school code'}</Button></div><p className="mt-2 text-sm text-muted">Use this code when signing in to your school. Your school must invite staff and parents or enrol students first.</p></Card>
}
