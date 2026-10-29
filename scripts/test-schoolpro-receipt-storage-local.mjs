import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {mkdtemp, mkdir, readFile, rm, writeFile, copyFile} from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import net from 'node:net';
import {fileURLToPath} from 'node:url';
import {createClient} from '@supabase/supabase-js';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const policyMigration = path.join(repoRoot, 'supabase/migrations/20261017150000_schoolpro_payment_receipt_storage_policies.sql');
const fixtureSql = path.join(repoRoot, 'scripts/receipt-storage-local/fixture.sql');
const tempRoot = await mkdtemp(path.join(os.tmpdir(), 'schoolpro-receipt-storage-'));
const supabaseDir = path.join(tempRoot, 'supabase');
const migrationDir = path.join(supabaseDir, 'migrations');
const bucket = 'schoolpro-payment-receipts';
let stackStarted = false;

async function allocateAvailablePort(excluded = new Set()) {
  for (let attempt = 0; attempt < 20; attempt++) {
    const server = net.createServer();
    const port = await new Promise((resolve, reject) => {
      server.once('error', reject);
      server.listen(0, '0.0.0.0', () => {
        const address = server.address();
        resolve(typeof address === 'object' && address ? address.port : null);
      });
    });
    await new Promise((resolve, reject) => server.close(error => error ? reject(error) : resolve()));
    if (port && !excluded.has(port)) return port;
  }
  throw new Error('Could not allocate a unique local Supabase database port');
}

function runSupabase(args, options = {}) {
  return execFileSync('supabase', args, {
    cwd: tempRoot,
    encoding: 'utf8',
    stdio: options.stdio || ['ignore', 'pipe', 'pipe'],
    ...options,
  });
}

function parseEnvOutput(output) {
  const values = {};
  for (const line of output.split(/\r?\n/)) {
    const match = line.match(/^([A-Z_]+)=(.*)$/);
    if (!match) continue;
    let value = match[2].trim();
    if (value.startsWith('"') && value.endsWith('"')) value = value.slice(1, -1);
    values[match[1]] = value;
  }
  return values;
}

async function createTestUser(admin, email, password) {
  const {data, error} = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  assert.ifError(error);
  assert.ok(data.user?.id, 'Local Supabase must create a disposable test user');
  return data.user;
}

async function signIn(url, anonKey, email, password) {
  const client = createClient(url, anonKey, {
    auth: {persistSession: false, autoRefreshToken: false, detectSessionInUrl: false},
  });
  const {data, error} = await client.auth.signInWithPassword({email, password});
  assert.ifError(error);
  assert.ok(data.session?.access_token, 'Disposable user must authenticate against local Supabase');
  return {client, user: data.user};
}

try {
  await mkdir(migrationDir, {recursive: true});
  // Supabase CLI defaults to 54322, which can already be occupied on hosted CI runners.
  // Select a free local port so this isolated stack does not collide with runner services.
  const dbPort = await allocateAvailablePort();
  await writeFile(path.join(supabaseDir, 'config.toml'), [
    'project_id = "schoolpro-receipt-storage-test"',
    '',
    '[db]',
    `port = ${dbPort}`,
    '',
    '[db.migrations]',
    'enabled = true',
    '',
    '[storage]',
    'enabled = true',
    'file_size_limit = "5MiB"',
    '',
    '[auth]',
    'enabled = true',
    'site_url = "http://127.0.0.1:3000"',
    'enable_signup = true',
    '',
    '[auth.email]',
    'enable_signup = true',
    'enable_confirmations = false',
    '',
  ].join('\n'));
  await copyFile(fixtureSql, path.join(migrationDir, '20261017145900_receipt_storage_test_fixture.sql'));
  await copyFile(policyMigration, path.join(migrationDir, path.basename(policyMigration)));

  console.log('Starting isolated Supabase stack. No remote project is linked or contacted.');
  runSupabase(['start'], {stdio: 'inherit'});
  stackStarted = true;

  const status = runSupabase([
    'status', '-o', 'env',
    '--override-name', 'api.url=SUPABASE_URL',
    '--override-name', 'auth.anon_key=SUPABASE_ANON_KEY',
    '--override-name', 'auth.service_role_key=SUPABASE_SERVICE_ROLE_KEY',
  ]);
  const env = parseEnvOutput(status);
  assert.ok(env.SUPABASE_URL, 'Local Supabase URL must be available');
  assert.ok(env.SUPABASE_ANON_KEY, 'Local Supabase anon key must be available');
  assert.ok(env.SUPABASE_SERVICE_ROLE_KEY, 'Local Supabase service role key must be available');

  const admin = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: {persistSession: false, autoRefreshToken: false, detectSessionInUrl: false},
  });
  const password = 'LocalOnly-Test-Password-9!';
  const suffix = Date.now().toString(36);
  const userA = await createTestUser(admin, 'receipt-a-' + suffix + '@example.test', password);
  const userB = await createTestUser(admin, 'receipt-b-' + suffix + '@example.test', password);
  const financeA = await createTestUser(admin, 'receipt-finance-a-' + suffix + '@example.test', password);
  const financeB = await createTestUser(admin, 'receipt-finance-b-' + suffix + '@example.test', password);
  const superAdmin = await createTestUser(admin, 'receipt-super-admin-' + suffix + '@example.test', password);
  assert.notEqual(userA.id, userB.id, 'Receipt isolation requires two distinct users');

  const a = await signIn(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, 'receipt-a-' + suffix + '@example.test', password);
  const b = await signIn(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, 'receipt-b-' + suffix + '@example.test', password);
  const financeClientA = await signIn(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, 'receipt-finance-a-' + suffix + '@example.test', password);
  const financeClientB = await signIn(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, 'receipt-finance-b-' + suffix + '@example.test', password);
  const superAdminClient = await signIn(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, 'receipt-super-admin-' + suffix + '@example.test', password);
  const bytes = Buffer.from('%PDF-1.4\n% synthetic receipt fixture\n%%EOF\n', 'utf8');
  const pathA = a.user.id + '/receipt-a.pdf';
  const pathB = b.user.id + '/receipt-b.pdf';

  const ownUploadA = await a.client.storage.from(bucket).upload(pathA, bytes, {
    contentType: 'application/pdf', upsert: false,
  });
  assert.ifError(ownUploadA.error);
  assert.ok(ownUploadA.data, 'User A must upload a receipt under their own UUID');

  const ownUploadB = await b.client.storage.from(bucket).upload(pathB, bytes, {
    contentType: 'application/pdf', upsert: false,
  });
  assert.ifError(ownUploadB.error);
  assert.ok(ownUploadB.data, 'User B must upload a receipt under their own UUID');
  console.log('PASS: each disposable user can upload a synthetic receipt under their own UUID.');

  const ownDownloadA = await a.client.storage.from(bucket).download(pathA);
  assert.ifError(ownDownloadA.error);
  assert.ok(ownDownloadA.data, 'User A must download their own receipt');

  const ownDownloadB = await b.client.storage.from(bucket).download(pathB);
  assert.ifError(ownDownloadB.error);
  assert.ok(ownDownloadB.data, 'User B must download their own receipt');

  const foreignDownloadA = await a.client.storage.from(bucket).download(pathB);
  assert.ok(foreignDownloadA.error || !foreignDownloadA.data, 'User A must be denied User B receipt');

  const foreignDownloadB = await b.client.storage.from(bucket).download(pathA);
  assert.ok(foreignDownloadB.error || !foreignDownloadB.data, 'User B must be denied User A receipt');
  console.log('PASS: each user can download their own receipt and is denied the other user receipt.');

  const crossUpload = await a.client.storage.from(bucket).upload(userB.id + '/foreign-upload.pdf', bytes, {
    contentType: 'application/pdf', upsert: false,
  });
  assert.ok(crossUpload.error, 'User A must not upload into User B UUID folder');
  console.log('PASS: cross-user receipt upload is denied by the live Storage API policy.');

  const schoolA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const schoolB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const {error: profileInsertError} = await admin.from('profiles').insert([
    {id: financeClientA.user.id, status: 'active', role: 'user'},
    {id: financeClientB.user.id, status: 'active', role: 'user'},
    {id: superAdminClient.user.id, status: 'active', role: 'super_admin'},
  ]);
  assert.ifError(profileInsertError);
  const {error: schoolInsertError} = await admin.from('schoolpro_schools').insert([
    {id: schoolA, owner_id: financeClientA.user.id},
    {id: schoolB, owner_id: financeClientB.user.id},
  ]);
  assert.ifError(schoolInsertError);
  const {error: memberInsertError} = await admin.from('schoolpro_test_storage_memberships').insert([
    {user_id: financeClientA.user.id, school_id: schoolA, role: 'accountant'},
    {user_id: financeClientB.user.id, school_id: schoolB, role: 'accountant'},
  ]);
  assert.ifError(memberInsertError);
  const {error: submissionInsertError} = await admin.from('schoolpro_payment_submissions').insert([
    {school_id: schoolA, submitted_by: userA.id, receipt_path: pathA},
    {school_id: schoolB, submitted_by: userB.id, receipt_path: pathB},
  ]);
  assert.ifError(submissionInsertError);
  const {error: proofInsertError} = await admin.from('schoolpro_payment_proofs').insert([
    {school_id: schoolA, submitted_by: userA.id, receipt_path: pathA},
    {school_id: schoolB, submitted_by: userB.id, receipt_path: pathB},
  ]);
  assert.ifError(proofInsertError);

  const financeOwnReceipt = await financeClientA.client.storage.from(bucket).download(pathA);
  assert.ifError(financeOwnReceipt.error);
  assert.ok(financeOwnReceipt.data, 'School finance must read a receipt linked to its own school submission');
  const financeForeignReceipt = await financeClientA.client.storage.from(bucket).download(pathB);
  assert.ok(financeForeignReceipt.error || !financeForeignReceipt.data, 'School finance must not read another school submission receipt');
  console.log('PASS: school finance can read a receipt linked to its own school submission and is denied another school receipt.');
  const superAdminReceiptA = await superAdminClient.client.storage.from(bucket).download(pathA);
  assert.ifError(superAdminReceiptA.error);
  const superAdminReceiptB = await superAdminClient.client.storage.from(bucket).download(pathB);
  assert.ifError(superAdminReceiptB.error);
  console.log('PASS: active platform Super Admin can inspect both schools through the explicit helper bypass.');

  console.log('PASS: local Supabase Storage receipt-isolation integration completed using the repository policy migration.');
} finally {
  if (stackStarted) {
    try { runSupabase(['stop', '--no-backup'], {stdio: 'inherit'}); }
    catch (error) { console.error('WARN: local Supabase cleanup failed:', error.message); }
  }
  await rm(tempRoot, {recursive: true, force: true});
}
