import assert from 'node:assert/strict';
const base='https://lnqsroyiybutkfngbyge.supabase.co/rest/v1/';
const headers={apikey:process.env.VITE_SUPABASE_PUBLISHABLE_KEY||'sb_publishable_VtL5RtPncmUXxxjrM_tFQw_T4cPPYDq'};
for(const table of ['schoolpro_students','schoolpro_guardian_links','schoolpro_members']){
 const select='school_id,schoolpro_schools!'+table+'_school_id_fkey(name)';
 const response=await fetch(base+table+'?'+new URLSearchParams({select,limit:'0'}),{headers,signal:AbortSignal.timeout(15000)});
 const body=await response.json();
 assert.equal(response.status,200,table+' relationship failed: '+JSON.stringify(body));
 assert.deepEqual(body,[],'Schema validation must not disclose any records');
}
console.log('PASS: student, parent and staff school embeddings resolve unambiguously in production.');
