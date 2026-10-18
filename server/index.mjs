import { createServer } from "node:http";
import { readBearerToken, isPlatformAdmin, verifySupabaseAccessToken } from "./auth.mjs";
import pg from "pg";

const { Pool } = pg;
const PORT = Number.parseInt(process.env.PORT || "8080", 10);
const allowedOrigins = new Set(
  (process.env.SCHOOLPRO_ALLOWED_ORIGINS || "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean),
);
let pool;

function sendJson(res, status, body) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(payload),
    "cache-control": "no-store",
    "x-content-type-options": "nosniff",
    "referrer-policy": "no-referrer",
    "content-security-policy": "default-src 'none'; frame-ancestors 'none'",
  });
  res.end(payload);
}

function getPool() {
  if (!process.env.DATABASE_URL || !process.env.DATABASE_CA_CERT) {
    const error = new Error("Database connection is not configured");
    error.statusCode = 503;
    throw error;
  }
  if (!pool) {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { ca: process.env.DATABASE_CA_CERT.replace(/\\n/g, "\n"), rejectUnauthorized: true },
      max: 5,
      connectionTimeoutMillis: 5000,
      idleTimeoutMillis: 10000,
      statement_timeout: 5000,
      query_timeout: 6000,
      application_name: "ihlink-schoolpro-api",
    });
    pool.on("error", () => {
      // Do not log connection strings, SQL parameters, or user data.
    });
  }
  return pool;
}

async function getUser(req) {
  const token = readBearerToken(req.headers.authorization);
  if (!token) {
    const error = new Error("Bearer access token required");
    error.statusCode = 401;
    throw error;
  }
  const user = await verifySupabaseAccessToken(token);
  return {
    ...user,
    platformAdmin: isPlatformAdmin(user.id, process.env.PLATFORM_ADMIN_USER_IDS),
  };
}

async function getVisibleSchools(user) {
  const db = getPool();
  // Schema is intentionally required to exist before this API can serve tenant data.
  // The query enforces owner/member scope even if the calling client supplies another school ID.
  const result = await db.query(
    `SELECT s.id, s.name, s.code, s.status::text AS status,
            CASE WHEN s.owner_id = $1::uuid THEN 'owner' ELSE m.role::text END AS role
       FROM public.schoolpro_schools AS s
       LEFT JOIN public.schoolpro_members AS m
         ON m.school_id = s.id AND m.user_id = $1::uuid
      WHERE s.owner_id = $1::uuid OR m.user_id = $1::uuid
      ORDER BY s.name ASC`,
    [user.id],
  );
  if (user.platformAdmin) {
    // Platform-wide visibility is granted only through the server-side UUID allowlist,
    // never a user-editable JWT metadata claim.
    const all = await db.query(
      `SELECT id, name, code, status::text AS status, 'platform_admin' AS role
         FROM public.schoolpro_schools ORDER BY name ASC`,
    );
    return all.rows;
  }
  return result.rows;
}

async function getVisibleSchool(user, schoolId) {
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(schoolId)) {
    return null;
  }
  const db = getPool();
  const result = await db.query(
    `SELECT s.id, s.name, s.code, s.status::text AS status,
            CASE WHEN s.owner_id = $1::uuid THEN 'owner' ELSE m.role::text END AS role
       FROM public.schoolpro_schools AS s
       LEFT JOIN public.schoolpro_members AS m
         ON m.school_id = s.id AND m.user_id = $1::uuid
      WHERE s.id = $2::uuid
        AND ($3::boolean OR s.owner_id = $1::uuid OR m.user_id = $1::uuid)
      LIMIT 1`,
    [user.id, schoolId, user.platformAdmin],
  );
  return result.rows[0] || null;
}

const server = createServer(async (req, res) => {
  const origin = req.headers.origin;
  if (origin && allowedOrigins.has(origin)) {
    res.setHeader("access-control-allow-origin", origin);
    res.setHeader("vary", "Origin");
    res.setHeader("access-control-allow-headers", "authorization, content-type");
    res.setHeader("access-control-allow-methods", "GET, OPTIONS");
  }
  if (req.method === "OPTIONS") {
    if (origin && !allowedOrigins.has(origin)) return sendJson(res, 403, { error: "origin_not_allowed" });
    res.writeHead(204);
    return res.end();
  }

  const url = new URL(req.url || "/", "http://localhost");
  try {
    if (req.method === "GET" && url.pathname === "/health/live") {
      return sendJson(res, 200, { status: "alive" });
    }
    if (req.method === "GET" && url.pathname === "/health/ready") {
      const db = getPool();
      const check = await db.query(
        `SELECT to_regclass('public.schoolpro_schools') IS NOT NULL AS schools_ready,
                to_regclass('public.schoolpro_members') IS NOT NULL AS members_ready`,
      );
      if (!check.rows[0]?.schools_ready || !check.rows[0]?.members_ready) {
        return sendJson(res, 503, { status: "not_ready", reason: "schema_not_migrated" });
      }
      return sendJson(res, 200, { status: "ready" });
    }
    if (req.method === "GET" && url.pathname === "/v1/me") {
      const user = await getUser(req);
      return sendJson(res, 200, {
        user: { id: user.id, email: user.email },
        platformAdmin: user.platformAdmin,
        schools: await getVisibleSchools(user),
      });
    }
    const schoolMatch = req.method === "GET" && url.pathname.match(/^\/v1\/schools\/([^/]+)$/);
    if (schoolMatch) {
      const user = await getUser(req);
      const school = await getVisibleSchool(user, decodeURIComponent(schoolMatch[1]));
      if (!school) return sendJson(res, 404, { error: "school_not_found" });
      return sendJson(res, 200, { school });
    }
    return sendJson(res, 404, { error: "not_found" });
  } catch (error) {
    const status = Number.isInteger(error?.statusCode) ? error.statusCode : 503;
    if (status === 401) return sendJson(res, 401, { error: "unauthorized" });
    if (status === 503) return sendJson(res, 503, { error: "service_unavailable" });
    return sendJson(res, 500, { error: "internal_error" });
  }
});

server.listen(PORT, "0.0.0.0", () => {
  // Avoid logging environment variables, credentials, or request data.
  console.log(`SchoolPro API listening on port ${PORT}`);
});

async function shutdown() {
  server.close();
  if (pool) await pool.end().catch(() => {});
}
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
