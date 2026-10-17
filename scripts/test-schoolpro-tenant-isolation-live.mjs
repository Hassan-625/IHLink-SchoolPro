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
    return {client, user: data.user, accessToken: data.session.access_token};
  })();
}

function describeError(error) {
  if (typeof error?.message === 'string' && error.message.length) return error.message;
  try { return JSON.stringify(error); } catch { return String(error); }
}

async function countRows(client, table, schoolId, maxAttempts = 3) {
  let result;
  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    result = await client.from(table).select('*', {count: 'exact', head: true}).eq('school_id', schoolId);
    if (!result.error) return result.count ?? 0;

    const message = describeError(result.error);
    const status = Number(result.error.statusCode || result.error.status || 0);
    const transient = /timeout|timed out|temporar|fetch failed|network|connection reset|ECONNRESET|ETIMEDOUT|502|503|504|429/i.test(message)
      || [429, 502, 503, 504].includes(status);
    if (!transient || attempt === maxAttempts) {
      throw new Error('Read-only tenant count failed for ' + table + ' (attempt ' + attempt + '/' + maxAttempts + ', status ' + status + '): ' + message);
    }
    const delayMs = 1000 * attempt;
    console.warn('WARN', table, 'transient count error on attempt', attempt + '/' + maxAttempts, '- retrying in', delayMs + 'ms');
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }
  throw new Error('Read-only tenant count failed for ' + table + ': no result');
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

  const {data: ownPeriod, error: ownPeriodError} = await client.rpc('schoolpro_current_academic_period', {p_school: ownSchoolId});
  assert.ifError(ownPeriodError);
  assert.ok(ownPeriod && typeof ownPeriod === 'object', accountName + ' must be able to call the own-school academic-period RPC');
  const {data: foreignPeriod, error: periodError} = await client.rpc('schoolpro_current_academic_period', {p_school: otherSchoolId});
  assert.ok(periodError, accountName + ' must be denied the foreign-school academic-period RPC');
  assert.match(periodError.message, /school access|required|permission|denied/i, accountName + ' must receive an authorization denial for the foreign-school RPC');
  assert.equal(foreignPeriod, null, accountName + ' must not receive foreign-school academic-period data');
  console.log('PASS', accountName, 'own-school academic-period allowed; foreign-school RPC denied');

  // The positive/negative Storage fixture check runs in main against an existing template object.

}


async function downloadStorageWithRetry(client, bucket, path, label, maxAttempts = 3) {
  let lastResult;
  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    lastResult = await client.storage.from(bucket).download(path);
    if (!lastResult.error) {
      if (attempt > 1) console.log('PASS', label, 'Storage download succeeded on retry', attempt);
      return lastResult;
    }

    const message = String(lastResult.error.message || lastResult.error);
    const status = Number(lastResult.error.statusCode || lastResult.error.status || 0);
    const transient = /timeout|timed out|temporar|fetch failed|network|connection reset|ECONNRESET|ETIMEDOUT|502|503|504|429/i.test(message)
      || [429, 502, 503, 504].includes(status);
    if (!transient || attempt === maxAttempts) return lastResult;

    const delayMs = 1500 * attempt;
    console.warn('WARN', label, 'transient Storage error on attempt', attempt + '/' + maxAttempts, '- retrying in', delayMs + 'ms');
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }
  return lastResult;
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

  // Use an already-existing template row belonging to either configured test school.
  // Production has a real IHLink Academy template but School B may not own one.
  // This remains a strict two-account positive/negative check: the account whose
  // own RLS-protected row supplies the fixture must download it; the other must be denied.
  const schoolATemplateResult = await a.client
    .from('schoolpro_result_templates')
    .select('storage_path')
    .eq('school_id', process.env.SCHOOL_A_ID)
    .limit(1)
    .maybeSingle();
  assert.ifError(schoolATemplateResult.error);

  const schoolBTemplateResult = await b.client
    .from('schoolpro_result_templates')
    .select('storage_path')
    .eq('school_id', process.env.SCHOOL_B_ID)
    .limit(1)
    .maybeSingle();
  assert.ifError(schoolBTemplateResult.error);

  const templateFixture = schoolATemplateResult.data?.storage_path
    ? {
        ownerName: 'School A',
        ownerClient: a.client,
        ownerSchoolId: process.env.SCHOOL_A_ID,
        foreignName: 'School B',
        foreignClient: b.client,
        storagePath: schoolATemplateResult.data.storage_path,
      }
    : schoolBTemplateResult.data?.storage_path
      ? {
          ownerName: 'School B',
          ownerClient: b.client,
          ownerSchoolId: process.env.SCHOOL_B_ID,
          foreignName: 'School A',
          foreignClient: a.client,
          storagePath: schoolBTemplateResult.data.storage_path,
        }
      : null;

  assert.ok(
    templateFixture,
    'At least one configured test school must own an existing result-template row; do not create a production fixture to satisfy this test',
  );
  assert.ok(
    templateFixture.storagePath.startsWith(templateFixture.ownerSchoolId + '/'),
    templateFixture.ownerName + ' template Storage path must be rooted under its own school ID',
  );

  const {data: ownTemplateObject, error: ownTemplateDownloadError} = await downloadStorageWithRetry(
    templateFixture.ownerClient,
    'school-result-templates',
    templateFixture.storagePath,
    templateFixture.ownerName + ' own-school template fixture',
  );
  assert.ifError(ownTemplateDownloadError);
  assert.ok(ownTemplateObject, templateFixture.ownerName + ' must download its own existing result-template object');

  // Use raw HTTP for the negative assertion so the test can inspect the actual HTTP
  // status. supabase-js can wrap an empty/non-JSON denial body as StorageUnknownError,
  // which hides the status and cannot distinguish a denial from a transport failure.
  const encodedObjectPath = templateFixture.storagePath.split('/').map(encodeURIComponent).join('/');
  const foreignResponse = await fetch(
    process.env.SUPABASE_URL.replace(/\/$/, '') + '/storage/v1/object/authenticated/school-result-templates/' + encodedObjectPath,
    {
      method: 'GET',
      headers: {
        apikey: process.env.SUPABASE_ANON_KEY,
        Authorization: 'Bearer ' + (templateFixture.foreignName === 'School A' ? a.accessToken : b.accessToken),
      },
    },
  );
  const foreignBody = await foreignResponse.text();
  assert.ok(
    [400, 401, 403, 404].includes(foreignResponse.status),
    templateFixture.foreignName + ' must receive an HTTP authorization/not-found denial for the foreign template; got ' +
      foreignResponse.status + ' with body ' + foreignBody.slice(0, 240),
  );
  console.log('PASS', templateFixture.ownerName, 'can download its own template;', templateFixture.foreignName,
    'received HTTP', foreignResponse.status, 'for the foreign object');
  if (process.env.SCHOOL_A_RECEIPT_PATH && process.env.SCHOOL_B_RECEIPT_PATH) {
    for (const [name, client, foreignPath] of [
      ['School A', a.client, process.env.SCHOOL_B_RECEIPT_PATH],
      ['School B', b.client, process.env.SCHOOL_A_RECEIPT_PATH],
    ]) {
      const {data, error} = await client.storage.from('schoolpro-payment-receipts').download(foreignPath);
      assert.ok(error || !data, name + ' must not download another account\'s payment receipt');
      console.log('PASS', name, 'foreign-user payment receipt download denied');
    }
  } else {
    console.log('SKIP payment-receipt Storage download test: provide two existing test receipt paths; do not create production fixtures just for this test');
  }

  console.log('PASS: authenticated two-school tenant read/RPC/Storage acceptance checks completed.');
}

main().catch((error) => {
  console.error('FAIL: tenant acceptance check:', error?.message || error);
  process.exitCode = 1;
});
