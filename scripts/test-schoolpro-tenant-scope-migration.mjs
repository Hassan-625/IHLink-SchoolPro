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
files.push(['supabase/migrations/20261015203000_schoolpro_payment_receipt_tenant_guard.sql',[
  "split_part(p_receipt_path,'/',1)<>v_user::text",
  "o.bucket_id='schoolpro-payment-receipts'",
  'and o.name=p_receipt_path',
  'where id=(a->>\'invoice_id\')::uuid and school_id=p_school',
  'for update',
  'g.school_id=p_school and g.student_id=inv.student_id',
  'Each invoice may appear only once in a payment',
  'Payment allocations must be a list',
  'revoke all on function public.submit_schoolpro_payment'
]]);
for(const [path,needles] of files){
 const sql=readFileSync(path,'utf8');
 for(const needle of needles) assert.ok(sql.toLowerCase().includes(needle.toLowerCase()),path+' missing tenant guard: '+needle);
 assert.doesNotMatch(sql,/\b(drop table|truncate|delete from)\b/i,path+' must not delete production records or tables');
}
console.log('PASS: SchoolPro tenant migration contracts cover operational RLS, same-school guardian/CBT relationships, receipt-object ownership and locked same-school invoice allocations.');
