import test from 'node:test';
import assert from 'node:assert/strict';
import {createAppServer, hashPassword} from '../src/server.mjs';

const SCHOOL_A = '10000000-0000-4000-8000-000000000001';
const SCHOOL_B = '10000000-0000-4000-8000-000000000002';
const USER_ID = '00000000-0000-4000-8000-000000000001';
const PASSWORD = 'Test-password-2026!';

async function fixture() {
  const passwordHash = await hashPassword(PASSWORD);
  const sessions = new Map();
  const attempts = new Map();
  const user = {
    id: USER_ID,
    email: 'owner@example.test',
    email_normalized: 'owner@example.test',
    display_name: 'Synthetic Owner',
    status: 'active',
    password_hash: passwordHash,
  };
  const pool = {
    async execute(sql, params = []) {
      const query = sql.replace(/\s+/g, ' ').trim();
      if (query === 'SELECT 1') return [[{1: 1}], []];
      if (query.startsWith('SELECT blocked_until, blocked_until > UTC_TIMESTAMP(6) AS is_blocked FROM auth_login_attempts')) {
        const row = attempts.get(params[0]);
        return [[{is_blocked: Boolean(row?.blockedUntil && row.blockedUntil > Date.now())}], []];
      }
      if (query.startsWith('SELECT id, email, email_normalized, display_name, status, password_hash FROM users')) {
        return [[params[0] === user.email_normalized ? user : undefined].filter(Boolean), []];
      }
      if (query.startsWith('INSERT INTO user_sessions')) {
        sessions.set(params[1], {id: params[0], userId: params[0] && user.id, revoked: false});
        return [{affectedRows: 1}, []];
      }
      if (query.startsWith('DELETE FROM auth_login_attempts WHERE identifier_hash')) {
        attempts.delete(params[0]);
        return [{affectedRows: 1}, []];
      }
      if (query.startsWith('UPDATE user_sessions SET revoked_at = UTC_TIMESTAMP(6) WHERE token_hash = ? AND revoked_at IS NULL')) {
        const session = sessions.get(params[0]);
        if (session && !session.revoked) session.revoked = true;
        return [{affectedRows: session && !session.revoked ? 1 : 0}, []];
      }
      if (query.startsWith('SELECT u.id, u.email, u.display_name, u.status, s.id AS session_id, s.token_hash FROM user_sessions')) {
        const session = sessions.get(params[0]);
        return [session && !session.revoked ? [{id: user.id, email: user.email, display_name: user.display_name, status: user.status, session_id: session.id, token_hash: params[0]}] : [], []];
      }
      if (query.startsWith('SELECT role_code FROM platform_roles')) return [[], []];
      if (query.startsWith('SELECT id, name, status FROM schools')) {
        const school = params[0] === SCHOOL_A ? {id: SCHOOL_A, name: 'Synthetic School A', status: 'active'}
          : params[0] === SCHOOL_B ? {id: SCHOOL_B, name: 'Synthetic School B', status: 'active'} : null;
        return [school ? [school] : [], []];
      }
      if (query.startsWith("SELECT role_code FROM school_memberships WHERE school_id = ? AND user_id = ? AND status = 'active'")) {
        return [params[0] === SCHOOL_A && params[1] === USER_ID ? [{role_code: 'proprietor'}] : [], []];
      }
      throw new Error('Unexpected SQL in mock pool: ' + query);
    },
    async getConnection() {
      return {
        async beginTransaction() {},
        async execute(sql, params = []) {
          const query = sql.replace(/\s+/g, ' ').trim();
          if (query.startsWith('INSERT IGNORE INTO auth_login_attempts')) {
            if (!attempts.has(params[0])) attempts.set(params[0], {attempts: 0, windowStartedAt: Date.now(), blockedUntil: 0});
            return [{affectedRows: 1}, []];
          }
          if (query.startsWith('SELECT attempts, window_started_at FROM auth_login_attempts')) {
            const row = attempts.get(params[0]);
            return [[{attempts: row.attempts, window_started_at: new Date(row.windowStartedAt)}], []];
          }
          if (query.startsWith('UPDATE auth_login_attempts SET attempts')) {
            attempts.set(params[3], {attempts: params[0], windowStartedAt: new Date(params[1]).getTime(), blockedUntil: params[2] ? new Date(params[2]).getTime() : 0});
            return [{affectedRows: 1}, []];
          }
          throw new Error('Unexpected transaction SQL in mock pool: ' + query);
        },
        async commit() {},
        async rollback() {},
        release() {},
      };
    },
    async end() {},
    _attempts: attempts,
  };
  const server = createAppServer({pool, env: {NODE_ENV: 'test', WEB_ORIGIN: 'http://localhost:5173'}});
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  const baseUrl = 'http://127.0.0.1:' + address.port;
  return {server, pool, baseUrl, close: () => new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()))};
}

test('web login creates an opaque HttpOnly session cookie and /v1/me resolves identity', async (t) => {
  const app = await fixture();
  t.after(app.close);
  const response = await fetch(app.baseUrl + '/v1/auth/login', {
    method: 'POST',
    headers: {'Content-Type': 'application/json', Origin: 'http://localhost:5173'},
    body: JSON.stringify({email: ' OWNER@EXAMPLE.TEST ', password: PASSWORD}),
  });
  assert.equal(response.status, 200);
  const cookie = response.headers.get('set-cookie');
  assert.match(cookie, /schoolpro_session=/);
  assert.match(cookie, /HttpOnly/);
  assert.match(cookie, /SameSite=Lax/);
  const payload = await response.json();
  assert.equal(payload.user.email, 'owner@example.test');
  assert.equal(Object.hasOwn(payload, 'sessionToken'), false);
  const me = await fetch(app.baseUrl + '/v1/me', {headers: {Cookie: cookie.split(';')[0]}});
  assert.equal(me.status, 200);
  assert.equal((await me.json()).user.id, USER_ID);
});

test('tenant context allows own active membership and hides foreign school', async (t) => {
  const app = await fixture();
  t.after(app.close);
  const login = await fetch(app.baseUrl + '/v1/auth/login', {
    method: 'POST',
    headers: {'Content-Type': 'application/json', Origin: 'http://localhost:5173'},
    body: JSON.stringify({email: 'owner@example.test', password: PASSWORD}),
  });
  const cookie = login.headers.get('set-cookie').split(';')[0];
  const own = await fetch(app.baseUrl + '/v1/schools/' + SCHOOL_A + '/context', {headers: {Cookie: cookie}});
  assert.equal(own.status, 200);
  assert.equal((await own.json()).access.role, 'proprietor');
  const foreign = await fetch(app.baseUrl + '/v1/schools/' + SCHOOL_B + '/context', {headers: {Cookie: cookie}});
  assert.equal(foreign.status, 404);
});

test('login rejects a foreign Origin before processing credentials', async (t) => {
  const app = await fixture();
  t.after(app.close);
  const response = await fetch(app.baseUrl + '/v1/auth/login', {
    method: 'POST',
    headers: {'Content-Type': 'application/json', Origin: 'https://attacker.example'},
    body: JSON.stringify({email: 'owner@example.test', password: PASSWORD}),
  });
  assert.equal(response.status, 403);
});

test('failed login uses a generic response and stores only a hashed identifier key', async (t) => {
  const app = await fixture();
  t.after(app.close);
  const response = await fetch(app.baseUrl + '/v1/auth/login', {
    method: 'POST',
    headers: {'Content-Type': 'application/json', Origin: 'http://localhost:5173'},
    body: JSON.stringify({email: 'missing@example.test', password: 'wrong-password'}),
  });
  assert.equal(response.status, 401);
  assert.deepEqual(await response.json(), {error: 'Invalid credentials'});
  assert.equal(app.pool._attempts.size, 1);
  const [key, row] = [...app.pool._attempts.entries()][0];
  assert.match(key, /^[0-9a-f]{64}$/);
  assert.equal(row.attempts, 1);
});


test('logout revokes the server-side session and clears the browser cookie', async (t) => {
  const app = await fixture();
  t.after(app.close);
  const login = await fetch(app.baseUrl + '/v1/auth/login', {
    method: 'POST',
    headers: {'Content-Type': 'application/json', Origin: 'http://localhost:5173'},
    body: JSON.stringify({email: 'owner@example.test', password: PASSWORD}),
  });
  assert.equal(login.status, 200);
  const cookie = login.headers.get('set-cookie').split(';')[0];
  const logout = await fetch(app.baseUrl + '/v1/auth/logout', {
    method: 'POST',
    headers: {Origin: 'http://localhost:5173', Cookie: cookie},
  });
  assert.equal(logout.status, 200);
  assert.match(logout.headers.get('set-cookie'), /Max-Age=0/);
  const me = await fetch(app.baseUrl + '/v1/me', {headers: {Cookie: cookie}});
  assert.equal(me.status, 401);
});

test('native login returns an opaque bearer token without setting a browser cookie', async (t) => {
  const app = await fixture();
  t.after(app.close);
  const login = await fetch(app.baseUrl + '/v1/auth/login', {
    method: 'POST',
    headers: {'Content-Type': 'application/json', 'X-Client-Platform': 'native'},
    body: JSON.stringify({email: 'owner@example.test', password: PASSWORD}),
  });
  assert.equal(login.status, 200);
  assert.equal(login.headers.get('set-cookie'), null);
  const payload = await login.json();
  assert.equal(typeof payload.sessionToken, 'string');
  assert.ok(payload.sessionToken.length >= 32);
  const me = await fetch(app.baseUrl + '/v1/me', {
    headers: {Authorization: 'Bearer ' + payload.sessionToken},
  });
  assert.equal(me.status, 200);
});
