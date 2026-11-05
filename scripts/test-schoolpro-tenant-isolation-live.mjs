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
const receiptPathsConfigured = Boolean(process.env.SCHOOL_A_RECEIPT_PATH && process.env.SCHOOL_B_RECEIPT_PATH);
assert.equal(
  Boolean(process.env.SCHOOL_A_RECEIPT_PATH),
  Boolean(process.env.SCHOOL_B_RECEIPT_PATH),
  'Configure both receipt paths together or leave both unset; partial receipt fixtures are not allowed',
);
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

async function assertNoForeignRows(client, table, schoolId, accountName, maxAttempts = 3) {
  let result;
  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    // A bounded row probe is enough to prove denial; exact COUNT(*) can be expensive
    // under layered RLS policies and adds no value to this negative assertion.
    result = await client.from(table).select('id').eq('school_id', schoolId).limit(1);
    if (!result.error) {
      assert.equal(result.data?.length ?? 0, 0, accountName + ' must not read foreign-school rows from ' + table);
      console.log('PASS', accountName, 'foreign-school read blocked:', table);
      return;
    }

    const message = describeError(result.error);
    const status = Number(result.error.statusCode || result.error.status || 0);
    const transient = /timeout|timed out|temporar|fetch failed|network|connection reset|ECONNRESET|ETIMEDOUT|502|503|504|429/i.test(message)
      || [429, 502, 503, 504].includes(status)
      || (status === 0 && !String(result.error.message || '').trim() && !result.error.code);
    if (!transient || attempt === maxAttempts) {
      throw new Error('Read-only tenant probe failed for ' + table + ' (attempt ' + attempt + '/' + maxAttempts + ', status ' + status + '): ' + message);
    }
    const delayMs = 1000 * attempt;
    console.warn('WARN', table, 'transient probe error on attempt', attempt + '/' + maxAttempts, '- retrying in', delayMs + 'ms');
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }
  throw new Error('Read-only tenant probe failed for ' + table + ': no result');
}

async function assertTenantReads(accountName, client, ownSchoolId, otherSchoolId) {
  // Do not assume operational rows exist in either school: the live acceptance
  // test is read-only and must never seed students or memberships merely as fixtures.
  const {data: ownStudents, error: ownStudentError} = await client
    .from('schoolpro_students').select('id').eq('school_id', ownSchoolId).limit(1);
  assert.ifError(ownStudentError);
  if (ownStudents?.length) {
    console.log('PASS', accountName, 'own-school student read available');
  } else {
    console.warn('LIMITATION', accountName, 'has no own-school student row; student positive-read behavior is not exercised without creating data');
  }

  for (const table of [
    'schoolpro_students', 'schoolpro_members', 'schoolpro_invoices', 'schoolpro_results',
    'schoolpro_library_books', 'schoolpro_transport_routes', 'schoolpro_hostel_rooms',
    'schoolpro_inventory_assets', 'schoolpro_calendar_events', 'schoolpro_lesson_notes',
    'schoolpro_result_approvals', 'schoolpro_promotions',
  ]) {
    await assertNoForeignRows(client, table, otherSchoolId, accountName);
  }

  const {data: currentUserResult, error: currentUserError} = await client.auth.getUser();
  assert.ifError(currentUserError);
  const currentUserId = currentUserResult.user?.id;
  assert.ok(currentUserId, accountName + ' must have an authenticated user ID');
  const [
    {data: ownProfile, error: ownProfileError},
    {data: ownPermissions, error: ownPermissionsError},
    {data: ownMembership, error: ownMembershipError},
    {data: ownSchool, error: ownSchoolError},
    {data: ownSubscription, error: ownSubscriptionError},
  ] = await Promise.all([
    client.from('profiles').select('id,status').eq('id', currentUserId).maybeSingle(),
    client.rpc('schoolpro_user_permissions', {p_school: ownSchoolId}),
    client.from('schoolpro_members').select('role').eq('school_id', ownSchoolId).eq('user_id', currentUserId).maybeSingle(),
    client.from('schoolpro_schools').select('owner_id,status').eq('id', ownSchoolId).maybeSingle(),
    client.from('schoolpro_subscriptions').select('status,renews_at').eq('school_id', ownSchoolId).order('updated_at', {ascending: false}).limit(1).maybeSingle(),
  ]);
  assert.ifError(ownProfileError);
  assert.ifError(ownPermissionsError);
  console.log('DIAGNOSTIC', accountName, 'profile status:', ownProfile?.status ?? 'not visible');
  console.log('DIAGNOSTIC', accountName, 'own-school dashboard permission:', Array.isArray(ownPermissions) && ownPermissions.includes('dashboard'));
  console.log('DIAGNOSTIC', accountName, 'own membership role:', ownMembershipError ? 'query denied/error' : (ownMembership?.role ?? 'no visible matching membership'));
  console.log('DIAGNOSTIC', accountName, 'configured school ownership matches user:', ownSchoolError ? 'query denied/error' : (ownSchool ? ownSchool.owner_id === currentUserId : 'school not visible'));
  console.log('DIAGNOSTIC', accountName, 'configured school status:', ownSchoolError ? 'query denied/error' : (ownSchool?.status ?? 'not visible'));
  const subscriptionCurrentlyValid = Boolean(
    ownSubscription && ownSubscription.status === 'active' &&
    (!ownSubscription.renews_at || new Date(ownSubscription.renews_at).getTime() >= Date.now() - 14 * 24 * 60 * 60 * 1000),
  );
  console.log('DIAGNOSTIC', accountName, 'active subscription currently valid:', ownSubscriptionError ? 'query denied/error' : subscriptionCurrentlyValid);

  const {data: ownPeriod, error: ownPeriodError} = await client.rpc('schoolpro_current_academic_period', {p_school: ownSchoolId});
  if (ownPeriodError) {
    throw new Error(
      accountName + ' own-school academic-period RPC denied: ' + describeError(ownPeriodError) +
      '; profile status=' + (ownProfile?.status ?? 'not visible') +
      '; dashboard permission=' + (Array.isArray(ownPermissions) && ownPermissions.includes('dashboard')) +
      '. Read-only membership, ownership, school-status and subscription diagnostics above should identify whether the configured test identity/ID mapping or school operational state is the cause; do not treat this as a tenant-isolation defect without evidence.',
    );
  }
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
  if (receiptPathsConfigured) {
    const receiptFixtures = [
      {name: 'School A', owner: a, ownPath: process.env.SCHOOL_A_RECEIPT_PATH, foreignPath: process.env.SCHOOL_B_RECEIPT_PATH},
      {name: 'School B', owner: b, ownPath: process.env.SCHOOL_B_RECEIPT_PATH, foreignPath: process.env.SCHOOL_A_RECEIPT_PATH},
    ];
    assert.notEqual(
      process.env.SCHOOL_A_RECEIPT_PATH,
      process.env.SCHOOL_B_RECEIPT_PATH,
      'Use two distinct existing receipt objects owned by the two test accounts',
    );
    for (const fixture of receiptFixtures) {
      assert.ok(
        fixture.ownPath.startsWith(fixture.owner.user.id + '/'),
        fixture.name + ' receipt fixture must be rooted under the authenticated owner user ID',
      );
      const ownReceipt = await downloadStorageWithRetry(
        fixture.owner.client,
        'schoolpro-payment-receipts',
        fixture.ownPath,
        fixture.name + ' own receipt fixture',
      );
      assert.ifError(ownReceipt.error);
      assert.ok(ownReceipt.data, fixture.name + ' must be able to download its own existing receipt');
      const foreignReceipt = await downloadStorageWithRetry(
        fixture.owner.client,
        'schoolpro-payment-receipts',
        fixture.foreignPath,
        fixture.name + ' foreign receipt fixture',
      );
      assert.ok(
        foreignReceipt.error || !foreignReceipt.data,
        fixture.name + ' must not download another account\'s payment receipt',
      );
      console.log('PASS', fixture.name, 'own receipt allowed; other account receipt denied');
    }
  } else {
    console.log('SKIP: live production receipt-object checks omitted because the receipt bucket has no safe test fixtures; the separate local Supabase Storage isolation job covers receipt policies without production objects.');
  }

  console.log('PASS: authenticated two-school tenant read/RPC/Storage acceptance checks completed (receipt object checks may be skipped when no safe fixtures exist).');
}

main().catch((error) => {
  console.error('FAIL: tenant acceptance check:', error?.message || error);
  process.exitCode = 1;
});
