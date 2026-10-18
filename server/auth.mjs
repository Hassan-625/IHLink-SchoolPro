export function readBearerToken(header) {
  if (typeof header !== "string") return null;
  const match = /^Bearer\s+([^\s]+)$/i.exec(header.trim());
  return match?.[1] || null;
}

export function isPlatformAdmin(userId, configuredIds = "") {
  if (typeof userId !== "string" || !userId) return false;
  const ids = new Set(
    String(configuredIds)
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean),
  );
  return ids.has(userId.toLowerCase());
}

export async function verifySupabaseAccessToken(token, env = process.env, fetchImpl = fetch) {
  const baseUrl = env.SUPABASE_URL?.replace(/\/+$/, "");
  const publishableKey = env.SUPABASE_PUBLISHABLE_KEY;
  if (!baseUrl || !publishableKey) {
    const error = new Error("Authentication provider is not configured");
    error.statusCode = 503;
    throw error;
  }

  let response;
  try {
    response = await fetchImpl(`${baseUrl}/auth/v1/user`, {
      method: "GET",
      headers: {
        apikey: publishableKey,
        authorization: `Bearer ${token}`,
        accept: "application/json",
      },
      signal: AbortSignal.timeout(5000),
    });
  } catch {
    const error = new Error("Authentication provider unavailable");
    error.statusCode = 503;
    throw error;
  }

  if (response.status === 401 || response.status === 403) {
    const error = new Error("Invalid or expired access token");
    error.statusCode = 401;
    throw error;
  }
  if (!response.ok) {
    const error = new Error("Authentication provider rejected the request");
    error.statusCode = 503;
    throw error;
  }

  const user = await response.json();
  if (!user || typeof user.id !== "string" || !/^[0-9a-f-]{36}$/i.test(user.id)) {
    const error = new Error("Authentication provider returned an invalid identity");
    error.statusCode = 401;
    throw error;
  }
  return { id: user.id, email: typeof user.email === "string" ? user.email : null };
}
