export type SchoolClass={id:string;name:string;arm?:string|null;level?:string|null};
export function schoolSection(level:string|undefined|null,name=''){
 const value=(level||'').toLowerCase().replaceAll(' ','_');
 if(['nursery','pre_primary','pre-primary','kindergarten'].includes(value)||/nursery|pre.?primary|kindergarten/i.test(name))return 'Nursery';
 if(['junior_secondary','jss','junior'].includes(value)||/^(jss|js|junior)/i.test(name))return 'Junior Secondary';
 if(['senior_secondary','sss','ss','senior'].includes(value)||/^(sss|ss|senior)/i.test(name))return 'Senior Secondary';
 if(value==='primary'||/primary|basic/i.test(name))return 'Primary';
 return value?value.replaceAll('_',' ').replace(/\b\w/g,c=>c.toUpperCase()):'Other classes';
}
