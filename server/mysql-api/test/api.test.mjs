import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {after, before, test} from 'node:test';
import mysql from 'mysql2/promise';
import {createAppServer, hashPassword} from '../src/server.mjs';

const env = {
  MYSQL_HOST: process.env.MYSQL_HOST || '127.0.0.1',
  MYSQL_PORT: process.env.MYSQL_PORT || '3306',
  MYSQL_DATABASE: process.env.MYSQL_DATABASE || 'schoolpro_test',
  MYSQL_USER: process.env.MYSQL_USER || 'root',
  MYSQL_PASSWORD: process.env.MYSQL_PASSWORD || 'root-test-password',
};
const ownerAId = '00000000-0000-4000-8000-000000000001';
const ownerBId = '00000000-0000-4000-8000-000000000002';
const adminId = 'f0000000-0000-4000-8000-000000000001';
const schoolAId = '10000000-0000-4000-8000-000000000001';
const schoolBId = '10000000-0000-4000-8000-000000000002';
const webOrigin = 'http://localhost:5173';
let pool;
let server;
let baseUrl;

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

async function request(path, options = {}) {
  const response = await fetch(baseUrl + path, options);
  const text = await response.text();
  return {response, body: text ? JSON.parse(text) : null};
}

function jsonOptions(body, extraHeaders = {}) {
  return {
    method: 'POST',
    headers: {'Content-Type': 'application/json', Origin: webOrigin, ...extraHeaders},
    body: JSON.stringify(body),
  };
}

function cookieFrom(response) {
  const value = response.headers.get('set-cookie') || '';
  return value.split(';', 1)[0];
}

before(async () => {
  pool = mysql.createPool({
    host: env.MYSQL_HOST,
    port: Number(env.MYSQL_PORT),
    database: env.MYSQL_DATABASE,
    user: env.MYSQL_USER,
    password: env.MYSQL_PASSWORD,
    timezone: 'Z',
    connectionLimit: 5,
  });

  const ownerHash = await hashPassword('SchoolPro-Test-Password-2026!');
  await pool.execute('UPDATE users SET password_hash = ?, email_verified_at = UTC_TIMESTAMP(6) WHERE id IN (?, ?)', [ownerHash, ownerAId, ownerBId]);

  const adminHash = await hashPassword('Platform-Admin-Test-Password-2026!');
  await pool.execute(
    'INSERT INTO users (id,email,email_normalized,display_name,password_hash,status,email_verified_at) VALUES (?,?,?,?,?,\\'active\\',UTC_TIMESTAMP(6)) ON DUPLICATE KEY UPDATE password_hash=VALUES(password_hash), status=\\'active\\', email_verified_at=UTC_TIMESTAMP(6)',
    [adminId, 'platform-admin@example.test', 'platform-admin@example.test', 'Synthetic Platform Admin', adminHash],
  );
  await pool.execute(
    'INSERT INTO platform_roles (user_id,role_code) VALUES (?,\\'super_admin\\') ON DUPLICATE KEY UPDATE role_code=VALUES(role_code)',
    [adminId],
  );

  server = createAppServer({pool, env: {NODE_ENV: 'test', WEB_ORIGIN: webOrigin}});
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  baseUrl = 'http://127.0.0.1:' + server.address().port;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (pool) await pool.end();
});

test('MySQL API enforces sessions, origin, account throttling and tenant-scoped school context', async () => {
  const health = await request('/healthz');
  assert.equal(health.response.status, 200);
  assert.deepEqual(health.body, {status: 'ok', database: 'reachable'});

  const wrongOrigin = await request('/v1/auth/login', jsonOptions(
    {email: 'owner-a@example.test', password: 'SchoolPro-Test-Password-2026!'},
    {Origin: 'https://attacker.example'},
  ));
  assert.equal(wrongOrigin.response.status, 403);

  const wrongPassword = await request('/v1/auth/login', jsonOptions({email: 'owner-a@example.test', password: 'wrong-password'}));
  assert.equal(wrongPassword.response.status, 401);
  assert.equal(wrongPassword.body.error, 'Invalid credentials');

  const ownerLogin = await request('/v1/auth/login', jsonOptions({
    email: ' OWNER-A@EXAMPLE.TEST ',
    password: 'SchoolPro-Test-Password-2026!',
  }));
  assert.equal(ownerLogin.response.status, 200);
  assert.equal(ownerLogin.body.user.id, ownerAId);
  assert.equal(ownerLogin.body.sessionToken, undefined, 'Browser login must not expose the session token to JavaScript');
  const ownerCookie = cookieFrom(ownerLogin.response);
  assert.match(ownerCookie, /^schoolpro_session=[A-Za-z0-9_-]+$/);

  const [storedSessions] = await pool.execute('SELECT token_hash FROM user_sessions WHERE user_id = ? ORDER BY created_at DESC LIMIT 1', [ownerAId]);
  const rawToken = ownerCookie.slice('schoolpro_session='.length);
  assert.equal(storedSessions[0].token_hash, sha256(rawToken), 'Only the one-way session-token hash is persisted');

  const me = await request('/v1/me', {headers: {Cookie: ownerCookie, Origin: webOrigin}});
  assert.equal(me.response.status, 200);
  assert.equal(me.body.user.id, ownerAId);
  assert.deepEqual(me.body.platformRoles, []);

  const ownContext = await request('/v1/schools/' + schoolAId + '/context', {headers: {Cookie: ownerCookie, Origin: webOrigin}});
  assert.equal(ownContext.response.status, 200);
  assert.deepEqual(ownContext.body.access, {kind: 'school', role: 'proprietor'});

  const foreignContext = await request('/v1/schools/' + schoolBId + '/context', {headers: {Cookie: ownerCookie, Origin: webOrigin}});
  assert.equal(foreignContext.response.status, 404, 'School membership must not cross tenant boundaries');

  const adminLogin = await request('/v1/auth/login', jsonOptions({
    email: 'platform-admin@example.test',
    password: 'Platform-Admin-Test-Password-2026!',
  }));
  assert.equal(adminLogin.response.status, 200);
  const adminCookie = cookieFrom(adminLogin.response);
  const adminContext = await request('/v1/schools/' + schoolBId + '/context', {headers: {Cookie: adminCookie, Origin: webOrigin}});
  assert.equal(adminContext.response.status, 200);
  assert.deepEqual(adminContext.body.access, {kind: 'platform', role: 'super_admin'});
  const [adminMemberships] = await pool.execute('SELECT id FROM school_memberships WHERE user_id = ?', [adminId]);
  assert.equal(adminMemberships.length, 0, 'Platform Super Admin must not be modelled as a school membership');

  const nativeLogin = await request('/v1/auth/login', {
    method: 'POST',
    headers: {'Content-Type': 'application/json', 'X-Client-Platform': 'native'},
    body: JSON.stringify({email: 'owner-b@example.test', password: 'SchoolPro-Test-Password-2026!'}),
  });
  assert.equal(nativeLogin.response.status, 200);
  assert.equal(typeof nativeLogin.body.sessionToken, 'string', 'Native clients receive an opaque token for secure native storage');
  assert.equal(nativeLogin.response.headers.get('set-cookie'), null, 'Native token is not put in a browser cookie');

  const expiredToken = 'synthetic-expired-session-token';
  await pool.execute(
    'INSERT INTO user_sessions (id,user_id,token_hash,expires_at) VALUES (UUID(),?,?,DATE_SUB(UTC_TIMESTAMP(6), INTERVAL 1 HOUR))',
    [ownerAId, sha256(expiredToken)],
  );
  const expiredMe = await request('/v1/me', {headers: {Authorization: 'Bearer ' + expiredToken}});
  assert.equal(expiredMe.response.status, 401);

  const ownerBKey = sha256('login:owner-b@example.test');
  await pool.execute(
    'INSERT INTO auth_login_attempts (identifier_hash,attempts,window_started_at,blocked_until) VALUES (?,10,UTC_TIMESTAMP(6),DATE_ADD(UTC_TIMESTAMP(6), INTERVAL 10 MINUTE)) ON DUPLICATE KEY UPDATE attempts=10,window_started_at=UTC_TIMESTAMP(6),blocked_until=DATE_ADD(UTC_TIMESTAMP(6), INTERVAL 10 MINUTE)',
    [ownerBKey],
  );
  const throttledLogin = await request('/v1/auth/login', jsonOptions({
    email: 'owner-b@example.test',
    password: 'SchoolPro-Test-Password-2026!',
  }));
  assert.equal(throttledLogin.response.status, 429);

  const logout = await request('/v1/auth/logout', {method: 'POST', headers: {Cookie: ownerCookie, Origin: webOrigin}});
  assert.equal(logout.response.status, 200);
  const afterLogout = await request('/v1/me', {headers: {Cookie: ownerCookie, Origin: webOrigin}});
  assert.equal(afterLogout.response.status, 401);
});
