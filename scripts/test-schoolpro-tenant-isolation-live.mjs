import assert from 'node:assert/strict';
import {createClient} from '@supabase/supabase-js';

const required = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'SCHOOL_A_EMAIL',
  'SCHOOL_A_PASSWORD',
  'SCHOOL_A_ID',
  'SCHOOL_B_EMAIL',
  'SCHOOL_B_PASSWORD',
  'SCHOOL_B_ID',
];
const missing = required.filter((key) => !process.env[key]);
if (missing.length) {
  console.error('Missing required environment variables:', missing.join(', '));
  console.error('No request was sent. This script performs read-only acceptance checks; it never writes application rows.');
  process.exit(2);
}

assert.notEqual(process.env.SCHOOL_A_ID, process.env.SCHOOL_B_ID, 'Use two different school IDs');

function clientFor(email, password) {
  const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY, {
    auth: {persistSession: false, autoRefreshToken: false, detectSessionInUrl: false},
  });
  return (async () => {
    const {data, error} = await client.auth.signInWithPassword({email, password});
    assert.ifError(error);
    assert.ok(data.session?.access_token, 'Sign-in must return a real access token');
    return {client, user: data.user};
  })();
}

async function countRows(client, table, schoolId) {
  const {count, error} = await client.from(table).select('id', {count: 'exact', head: true}).eq('school_id', schoolId);
  assert.ifError(error);
  return count ?? 0;
}

async function assertTenantReads(accountName, client, ownSchoolId, otherSchoolId) {
  const {data: ownStudents, error: ownError} = await client
    .from('schoolpro_students').select('id').eq('school_id', ownSchoolId).limit(1);
  assert.ifError(ownError);
  assert.ok(ownStudents?.length, accountName + ' must be able to read at least one own-school student');

  for (const table of ['schoolpro_students', 'schoolpro_members', 'schoolpro_invoices', 'schoolpro_results']) {
    const count = await countRows(client, table, otherSchoolId);
    assert.equal(count, 0, accountName + ' must not read foreign-school rows from ' + table);
    console.log('PASS', accountName, 'foreign-school read blocked:', table);
  }

  const {data: foreignPeriod, error: periodError} = await client.rpc('schoolpro_current_academic_period', {p_school: otherSchoolId});
  assert.ok(periodError || foreignPeriod == null, accountName + ' must not retrieve a foreign school academic period');
  console.log('PASS', accountName, 'foreign-school academic-period RPC denied');

  const {data: foreignTemplateObjects, error: storageError} = await client
    .storage.from('school-result-templates').list(otherSchoolId, {limit: 1});
  assert.ifError(storageError);
  assert.equal(foreignTemplateObjects?.length ?? 0, 0, accountName + ' must not list another school\'s result templates');
  console.log('PASS', accountName, 'foreign-school result-template Storage listing blocked');
}

async function main() {
  const a = await clientFor(process.env.SCHOOL_A_EMAIL, process.env.SCHOOL_A_PASSWORD);
  const b = await clientFor(process.env.SCHOOL_B_EMAIL, process.env.SCHOOL_B_PASSWORD);

  assert.ok(a.user?.id && b.user?.id && a.user.id !== b.user.id, 'The two test accounts must be distinct authenticated users');
  await assertTenantReads('School A', a.client, process.env.SCHOOL_A_ID, process.env.SCHOOL_B_ID);
  await assertTenantReads('School B', b.client, process.env.SCHOOL_B_ID, process.env.SCHOOL_A_ID);

  const [{data: studentA, error: studentAError}, {data: studentB, error: studentBError}] = await Promise.all([
    a.client.from('schoolpro_students').select('id').eq('school_id', process.env.SCHOOL_A_ID).limit(1).single(),
    b.client.from('schoolpro_students').select('id').eq('school_id', process.env.SCHOOL_B_ID).limit(1).single(),
  ]);
  assert.ifError(studentAError);
  assert.ifError(studentBError);

  for (const [name, client, foreignStudentId] of [
    ['School A', a.client, studentB.id],
    ['School B', b.client, studentA.id],
  ]) {
    const {data, error} = await client.rpc('schoolpro_can_view_result_output', {
      p_student_id: foreignStudentId,
      p_term: process.env.TENANT_TEST_TERM || 'First Term',
      p_session: process.env.TENANT_TEST_SESSION || '2025/2026',
    });
    assert.ifError(error);
    assert.equal(data, false, name + ' must not be allowed to view a foreign-school student result');
    console.log('PASS', name, 'foreign-student result-output RPC denied');
  }

  for (const [name, client, foreignUserId] of [
    ['School A', a.client, b.user.id],
    ['School B', b.client, a.user.id],
  ]) {
    const {data, error} = await client.storage.from('schoolpro-payment-receipts').list(foreignUserId, {limit: 1});
    assert.ifError(error);
    assert.equal(data?.length ?? 0, 0, name + ' must not list another user\'s payment receipts');
    console.log('PASS', name, 'foreign-user payment-receipt Storage listing blocked');
  }

  console.log('PASS: authenticated two-school tenant read/RPC/Storage acceptance checks completed.');
}

main().catch((error) => {
  console.error('FAIL: tenant acceptance check:', error?.message || error);
  process.exitCode = 1;
});
