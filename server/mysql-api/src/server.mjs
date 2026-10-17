import {createServer as createHttpServer} from 'node:http';
import {createHash, randomBytes, scrypt as scryptCallback, timingSafeEqual} from 'node:crypto';
import {promisify} from 'node:util';
import mysql from 'mysql2/promise';

const scrypt = promisify(scryptCallback);
const SESSION_COOKIE = 'schoolpro_session';
const SESSION_SECONDS = 12 * 60 * 60;
const LOGIN_WINDOW_MS = 15 * 60 * 1000;
const MAX_LOGIN_ATTEMPTS = 10;
const LOGIN_BLOCK_MS = 15 * 60 * 1000;
const MAX_BODY_BYTES = 16 * 1024;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

export async function hashPassword(password) {
  const salt = randomBytes(16);
  const key = await scrypt(String(password), salt, 64, {N: 16384, r: 8, p: 1, maxmem: 128 * 1024 * 1024});
  return ['scrypt', 16384, 8, 1, salt.toString('hex'), Buffer.from(key).toString('hex')].join('$');
}

async function verifyPassword(password, encoded) {
  const parts = String(encoded || '').split('$');
  if (parts.length !== 6 || parts[0] !== 'scrypt') {
    await scrypt(String(password), Buffer.from('schoolpro-mysql-api-dummy-salt-v1'), 64, {N: 16384, r: 8, p: 1, maxmem: 128 * 1024 * 1024});
    return false;
  }
  const N = Number(parts[1]);
  const r = Number(parts[2]);
  const p = Number(parts[3]);
  const salt = Buffer.from(parts[4], 'hex');
  const expected = Buffer.from(parts[5], 'hex');
  if (!Number.isInteger(N) || N < 16384 || N > 65536 || !Number.isInteger(r) || r < 1 || r > 16
    || !Number.isInteger(p) || p < 1 || p > 4 || salt.length < 16 || expected.length !== 64) {
    await scrypt(String(password), Buffer.from('schoolpro-mysql-api-dummy-salt-v1'), 64, {N: 16384, r: 8, p: 1, maxmem: 128 * 1024 * 1024});
    return false;
  }
  const actual = Buffer.from(await scrypt(String(password), salt, expected.length, {N, r, p, maxmem: 128 * 1024 * 1024}));
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}

function cookieValue(request, name) {
  const cookieHeader = String(request.headers.cookie || '');
  for (const part of cookieHeader.split(';')) {
    const [key, ...rest] = part.trim().split('=');
    if (key === name) return rest.join('=');
  }
  return null;
}

function requestToken(request) {
  const authorization = String(request.headers.authorization || '');
  const bearer = authorization.match(/^Bearer\s+(.+)$/i);
  return bearer?.[1]?.trim() || cookieValue(request, SESSION_COOKIE);
}

function sendJson(response, status, payload, headers = {}) {
  const body = JSON.stringify(payload);
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    ...headers,
  });
  response.end(body);
}

async function readJson(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) {
      const error = new Error('Request body too large');
      error.status = 413;
      throw error;
    }
    chunks.push(chunk);
  }
  if (!chunks.length) return {};
  try {
    const value = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('JSON object required');
    return value;
  } catch {
    const error = new Error('Invalid JSON body');
    error.status = 400;
    throw error;
  }
}

function cookieHeader(token, secure) {
  return SESSION_COOKIE + '=' + token + '; Path=/; HttpOnly; SameSite=Lax; Max-Age=' + SESSION_SECONDS + (secure ? '; Secure' : '');
}

function clearCookieHeader(secure) {
  return SESSION_COOKIE + '=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0' + (secure ? '; Secure' : '');
}

async function isLoginBlocked(pool, identifierHash) {
  const [rows] = await pool.execute(
    'SELECT blocked_until, blocked_until > UTC_TIMESTAMP(6) AS is_blocked FROM auth_login_attempts WHERE identifier_hash = ?',
    [identifierHash],
  );
  return Boolean(rows[0]?.is_blocked);
}

async function recordFailedLogin(pool, identifierHash) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.execute(
      'INSERT IGNORE INTO auth_login_attempts (identifier_hash, attempts, window_started_at, updated_at) VALUES (?, 0, UTC_TIMESTAMP(6), UTC_TIMESTAMP(6))',
      [identifierHash],
    );
    const [rows] = await connection.execute(
      'SELECT attempts, window_started_at FROM auth_login_attempts WHERE identifier_hash = ? FOR UPDATE',
      [identifierHash],
    );
    const row = rows[0];
    const now = Date.now();
    const windowStarted = new Date(row.window_started_at).getTime();
    let attempts = Number(row.attempts || 0);
    let windowAt = row.window_started_at;
    if (!Number.isFinite(windowStarted) || now - windowStarted >= LOGIN_WINDOW_MS) {
      attempts = 0;
      windowAt = new Date(now);
    }
    attempts += 1;
    const blocked = attempts >= MAX_LOGIN_ATTEMPTS;
    const blockedUntil = blocked ? new Date(now + LOGIN_BLOCK_MS) : null;
    await connection.execute(
      'UPDATE auth_login_attempts SET attempts = ?, window_started_at = ?, blocked_until = ?, updated_at = UTC_TIMESTAMP(6) WHERE identifier_hash = ?',
      [attempts, windowAt, blockedUntil, identifierHash],
    );
    await connection.commit();
    return blocked;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

async function authenticateRequest(pool, request) {
  const token = requestToken(request);
  if (!token || token.length > 256) return null;
  const tokenHash = sha256(token);
  const [rows] = await pool.execute(
    'SELECT u.id, u.email, u.display_name, u.status, s.id AS session_id, s.token_hash ' +
    'FROM user_sessions s JOIN users u ON u.id = s.user_id ' +
    "WHERE s.token_hash = ? AND s.revoked_at IS NULL AND s.expires_at > UTC_TIMESTAMP(6) AND u.status = 'active' LIMIT 1",
    [tokenHash],
  );
  return rows[0] || null;
}

function isAllowedMutationOrigin(request, webOrigin) {
  const origin = String(request.headers.origin || '');
  if (origin) return origin === webOrigin;
  return String(request.headers['x-client-platform'] || '').toLowerCase() === 'native';
}

export function createAppServer({pool, env = process.env}) {
  if (!pool || typeof pool.execute !== 'function') throw new Error('A MySQL promise pool is required');
  const production = env.NODE_ENV === 'production';
  const webOrigin = String(env.WEB_ORIGIN || (production ? '' : 'http://localhost:5173')).replace(/\/$/, '');
  if (production && !webOrigin) throw new Error('WEB_ORIGIN must be configured in production');
  const secureCookie = production || String(env.COOKIE_SECURE || '').toLowerCase() === 'true';

  return createHttpServer(async (request, response) => {
    const origin = String(request.headers.origin || '');
    if (origin && origin === webOrigin) {
      response.setHeader('Access-Control-Allow-Origin', webOrigin);
      response.setHeader('Access-Control-Allow-Credentials', 'true');
      response.setHeader('Vary', 'Origin');
    }
    response.setHeader('Referrer-Policy', 'no-referrer');
    response.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');

    if (request.method === 'OPTIONS') {
      if (origin && origin !== webOrigin) return sendJson(response, 403, {error: 'Origin not allowed'});
      response.writeHead(204, {
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Platform',
        'Access-Control-Max-Age': '600',
      });
      return response.end();
    }
    if (origin && origin !== webOrigin) return sendJson(response, 403, {error: 'Origin not allowed'});

    const url = new URL(request.url || '/', 'http://localhost');
    try {
      if (request.method === 'GET' && url.pathname === '/healthz') {
        await pool.execute('SELECT 1');
        return sendJson(response, 200, {status: 'ok', database: 'reachable'});
      }

      if (request.method === 'POST' && url.pathname === '/v1/auth/login') {
        if (!isAllowedMutationOrigin(request, webOrigin)) return sendJson(response, 403, {error: 'Origin required'});
        const body = await readJson(request);
        const email = normalizeEmail(body.email);
        const password = String(body.password || '');
        if (!email || email.length > 320 || !password || password.length > 1024) {
          return sendJson(response, 400, {error: 'Email and password are required'});
        }
        const identifierHash = sha256('login:' + email);
        if (await isLoginBlocked(pool, identifierHash)) return sendJson(response, 429, {error: 'Too many login attempts. Try again later.'});

        const [users] = await pool.execute(
          'SELECT id, email, email_normalized, display_name, status, password_hash FROM users WHERE email_normalized = ? LIMIT 1',
          [email],
        );
        const user = users[0];
        const passwordValid = await verifyPassword(password, user?.password_hash);
        if (!user || user.status !== 'active' || !passwordValid) {
          const blocked = await recordFailedLogin(pool, identifierHash);
          return sendJson(response, blocked ? 429 : 401, {
            error: blocked ? 'Too many login attempts. Try again later.' : 'Invalid credentials',
          });
        }

        const token = randomBytes(32).toString('base64url');
        const tokenHash = sha256(token);
        await pool.execute(
          'INSERT INTO user_sessions (id, user_id, token_hash, expires_at) VALUES (UUID(), ?, ?, DATE_ADD(UTC_TIMESTAMP(6), INTERVAL ? SECOND))',
          [user.id, tokenHash, SESSION_SECONDS],
        );
        await pool.execute('DELETE FROM auth_login_attempts WHERE identifier_hash = ?', [identifierHash]);

        const nativeClient = String(request.headers['x-client-platform'] || '').toLowerCase() === 'native';
        const headers = nativeClient ? {} : {'Set-Cookie': cookieHeader(token, secureCookie)};
        return sendJson(response, 200, {
          user: {id: user.id, email: user.email, displayName: user.display_name},
          expiresIn: SESSION_SECONDS,
          ...(nativeClient ? {sessionToken: token} : {}),
        }, headers);
      }

      if (request.method === 'POST' && url.pathname === '/v1/auth/logout') {
        if (!isAllowedMutationOrigin(request, webOrigin)) return sendJson(response, 403, {error: 'Origin required'});
        const token = requestToken(request);
        if (token) await pool.execute('UPDATE user_sessions SET revoked_at = UTC_TIMESTAMP(6) WHERE token_hash = ? AND revoked_at IS NULL', [sha256(token)]);
        return sendJson(response, 200, {ok: true}, {'Set-Cookie': clearCookieHeader(secureCookie)});
      }

      if (request.method === 'GET' && url.pathname === '/v1/me') {
        const session = await authenticateRequest(pool, request);
        if (!session) return sendJson(response, 401, {error: 'Authentication required'});
        const [roles] = await pool.execute('SELECT role_code FROM platform_roles WHERE user_id = ? ORDER BY role_code', [session.id]);
        return sendJson(response, 200, {
          user: {id: session.id, email: session.email, displayName: session.display_name},
          platformRoles: roles.map((row) => row.role_code),
        });
      }

      const schoolMatch = url.pathname.match(/^\/v1\/schools\/([^/]+)\/context$/);
      if (request.method === 'GET' && schoolMatch) {
        const session = await authenticateRequest(pool, request);
        if (!session) return sendJson(response, 401, {error: 'Authentication required'});
        const schoolId = decodeURIComponent(schoolMatch[1]);
        if (!UUID_RE.test(schoolId)) return sendJson(response, 400, {error: 'Invalid school ID'});
        const [schools] = await pool.execute('SELECT id, name, status FROM schools WHERE id = ? LIMIT 1', [schoolId]);
        if (!schools[0]) return sendJson(response, 404, {error: 'School not found'});
        const [platformRoles] = await pool.execute(
          "SELECT role_code FROM platform_roles WHERE user_id = ? AND role_code IN ('super_admin', 'platform_admin') " +
          "ORDER BY CASE role_code WHEN 'super_admin' THEN 0 ELSE 1 END LIMIT 1",
          [session.id],
        );
        if (platformRoles[0]) {
          return sendJson(response, 200, {school: schools[0], access: {kind: 'platform', role: platformRoles[0].role_code}});
        }
        const [memberships] = await pool.execute(
          "SELECT role_code FROM school_memberships WHERE school_id = ? AND user_id = ? AND status = 'active' LIMIT 1",
          [schoolId, session.id],
        );
        if (!memberships[0]) return sendJson(response, 404, {error: 'School not found'});
        return sendJson(response, 200, {school: schools[0], access: {kind: 'school', role: memberships[0].role_code}});
      }

      return sendJson(response, 404, {error: 'Not found'});
    } catch (error) {
      if (error?.status === 400 || error?.status === 413) return sendJson(response, error.status, {error: error.message});
      return sendJson(response, 500, {error: 'Internal server error'});
    }
  });
}

export function createPoolFromEnv(env = process.env) {
  const required = ['MYSQL_HOST', 'MYSQL_DATABASE', 'MYSQL_USER', 'MYSQL_PASSWORD'];
  const missing = required.filter((key) => !env[key]);
  if (missing.length) throw new Error('Missing MySQL configuration: ' + missing.join(', '));
  const sslEnabled = String(env.MYSQL_SSL || '').toLowerCase() === 'true';
  if (env.NODE_ENV === 'production' && !sslEnabled) throw new Error('MYSQL_SSL=true is required in production');
  const ssl = sslEnabled ? {rejectUnauthorized: true} : undefined;
  return mysql.createPool({
    host: env.MYSQL_HOST,
    port: Number(env.MYSQL_PORT || 3306),
    database: env.MYSQL_DATABASE,
    user: env.MYSQL_USER,
    password: env.MYSQL_PASSWORD,
    ssl,
    timezone: 'Z',
    waitForConnections: true,
    connectionLimit: Math.max(2, Math.min(10, Number(env.MYSQL_CONNECTION_LIMIT || 5))),
    queueLimit: 50,
    enableKeepAlive: true,
    decimalNumbers: true,
  });
}

if (process.argv[1] && new URL(import.meta.url).pathname === new URL('file://' + process.argv[1]).pathname) {
  const pool = createPoolFromEnv();
  const server = createAppServer({pool});
  const port = Number(process.env.PORT || 3001);
  server.listen(port, '0.0.0.0', () => process.stdout.write('SchoolPro MySQL API listening on ' + port + '\n'));
  const shutdown = async () => {
    server.close();
    await pool.end();
    process.exit(0);
  };
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}
