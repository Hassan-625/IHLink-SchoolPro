import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const files=[
  ['supabase/migrations/20261002234500_schoolpro_operational_tenant_isolation.sql',[
    'enable row level security','tenant read library','tenant manage library',
    'tenant read transport','tenant manage transport','tenant read hostel','tenant manage hostel'
  ]],
  ['supabase/migrations/20261003000500_schoolpro_guardian_tenant_hardening.sql',[
    'g.school_id=schoolpro_students.school_id','g.school_id=schoolpro_invoices.school_id',
    'g.school_id=schoolpro_fee_payments.school_id','g.school_id=schoolpro_attendance.school_id'
  ]],
  ['supabase/migrations/20261003002000_schoolpro_cbt_permission_tenant_integrity.sql',[
    'validate_schoolpro_cbt_question_tenant','validate_schoolpro_cbt_eligibility_tenant',
    'validate_schoolpro_member_permission_tenant','test_school<>question_school',
    'member_school<>new.school_id'
  ]]
];
for(const [path,needles] of files){
 const sql=readFileSync(path,'utf8');
 for(const needle of needles) assert.ok(sql.toLowerCase().includes(needle.toLowerCase()),path+' missing tenant guard: '+needle);
 assert.doesNotMatch(sql,/\b(drop table|truncate|delete from)\b/i,path+' must not delete production records or tables');
}
console.log('PASS: baseline SchoolPro tenant migrations retain operational RLS, same-school guardian links, and CBT/member relationship integrity guards.');
