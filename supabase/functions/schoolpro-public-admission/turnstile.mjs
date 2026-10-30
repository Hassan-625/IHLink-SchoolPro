/**
 * Server-side Cloudflare Turnstile verification shared by the Edge Function and
 * Node regression tests. The caller must fail closed when ok is false.
 */
export async function verifyTurnstile({
  token,
  secret,
  action,
  hostnames,
  fetchImpl = fetch,
}) {
  if (
    typeof token !== 'string' ||
    token.length === 0 ||
    token.length > 2048 ||
    typeof secret !== 'string' ||
    secret.length === 0 ||
    typeof action !== 'string' ||
    action.length === 0 ||
    !(hostnames instanceof Set) ||
    hostnames.size === 0
  ) {
    return { ok: false, unavailable: false };
  }

  let verification;
  try {
    const response = await fetchImpl('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ secret, response: token }),
      signal: AbortSignal.timeout(8_000),
    });
    if (!response.ok) return { ok: false, unavailable: true };
    verification = await response.json();
  } catch {
    return { ok: false, unavailable: true };
  }

  const valid =
    verification?.success === true &&
    verification?.action === action &&
    typeof verification?.hostname === 'string' &&
    hostnames.has(verification.hostname.toLowerCase());

  return { ok: valid, unavailable: false };
}
