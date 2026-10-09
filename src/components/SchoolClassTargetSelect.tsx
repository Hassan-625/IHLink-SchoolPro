import {useEffect,useState} from 'react';
import {supabase} from '@/lib/supabase';
import {SchoolClassSelect} from './SchoolClassSelect';
import {schoolSection,type SchoolClass} from '@/lib/schoolClassFilters';
export function SchoolClassTargetSelect({schoolId,value,onChange,onTargetsChange}:{schoolId:string;value:string;onChange:(name:string)=>void;onTargetsChange?:(names:string[])=>void}){
 const [section,setSection]=useState('');const [classes,setClasses]=useState<SchoolClass[]>([]);useEffect(()=>{let active=true;setClasses([]);if(supabase&&schoolId)void supabase.from('schoolpro_classes').select('id,name,arm,level').eq('school_id',schoolId).order('name').then(r=>{if(active)setClasses(r.data||[])});return()=>{active=false}},[schoolId]);
 const name=(c:SchoolClass)=>[c.name,c.arm].filter(Boolean).join(' ');const selected=classes.find(c=>name(c)===value);
 return <SchoolClassSelect classes={classes} value={selected?.id||''} emptyLabel={onTargetsChange?"All classes in selected section":"All classes in this school"} onSectionChange={next=>{setSection(next);onTargetsChange?.(classes.filter(c=>!next||schoolSection(c.level,c.name)===next).map(name))}} onChange={id=>{const c=classes.find(c=>c.id===id);onChange(c?name(c):'');onTargetsChange?.(c?[name(c)]:classes.filter(c=>!section||schoolSection(c.level,c.name)===section).map(name))}}/>;
}
