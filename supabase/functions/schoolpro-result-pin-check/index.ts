import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.117.3';
import { verifyTurnstile } from '../schoolpro-public-admission/turnstile.mjs';

const allowedOrigins = new Set(
  (Deno.env.get('SCHOOLPRO_RESULT_CHECK_ALLOWED_ORIGINS') || Deno.env.get('SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS') || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
);
const allowedHostnames = new Set(
  (Deno.env.get('TURNSTILE_ALLOWED_HOSTNAMES') || '')
    .split(',')
    .map((hostname) => hostname.trim().toLowerCase())
    .filter(Boolean),
);
const action = 'schoolpro_result_pin_check';

function reply(body: unknown, status = 200, origin?: string | null) {
  const headers = new Headers({
    'Content-Type': 'application/json',
    'Cache-Control': 'no-store',
    'Vary': 'Origin',
  });
  if (origin && allowedOrigins.has(origin)) {
    headers.set('Access-Control-Allow-Origin', origin);
    headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    headers.set('Access-Control-Allow-Headers', 'authorization, apikey, content-type, x-client-info');
  }
  return new Response(JSON.stringify(body), { status, headers });
}

Deno.serve(async (req) => {
  const origin = req.headers.get('origin');
  if (req.method === 'OPTIONS') {
    if (!origin || !allowedOrigins.has(origin)) return new Response(null, { status: 403 });
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
        'Access-Control-Max-Age': '600',
        'Vary': 'Origin',
      },
    });
  }
  if (req.method !== 'POST') return reply({ ok: false, message: 'Use the result checker to submit a request.' }, 405, origin);
  if (!origin || !allowedOrigins.has(origin)) return reply({ ok: false, message: 'This result-check origin is not allowed.' }, 403);

  const secret = Deno.env.get('TURNSTILE_SECRET_KEY');
  if (!secret || allowedHostnames.size === 0) {
    console.error('Result PIN checks blocked: Turnstile secret or allowed hostnames are not configured.');
    return reply({ ok: false, message: 'Secure result verification is not configured. Please contact the school.' }, 503, origin);
  }

  const contentLength = Number(req.headers.get('content-length') || '0');
  if (contentLength > 8_192) return reply({ ok: false, message: 'Result-check request is too large.' }, 413, origin);

  let body: Record<string, unknown>;
  try {
    const raw = await req.text();
    if (raw.length > 8_192) return reply({ ok: false, message: 'Result-check request is too large.' }, 413, origin);
    body = JSON.parse(raw);
    if (!body || typeof body !== 'object' || Array.isArray(body)) throw new Error('invalid body');
  } catch {
    return reply({ ok: false, message: 'Invalid result-check request.' }, 400, origin);
  }

  const token = typeof body.turnstileToken === 'string' ? body.turnstileToken.trim() : '';
  if (!token || token.length > 2_048) {
    return reply({ ok: false, message: 'Complete the secure verification before checking the result.' }, 400, origin);
  }

  const verification = await verifyTurnstile({ token, secret, action, hostnames: allowedHostnames });
  if (verification.unavailable) {
    console.error('Result PIN Turnstile Siteverify request failed.');
    return reply({ ok: false, message: 'Secure verification is temporarily unavailable. Please try again.' }, 503, origin);
  }
  if (!verification.ok) {
    return reply({ ok: false, message: 'Secure verification failed. Please verify again and retry.' }, 403, origin);
  }

  const admission = typeof body.admission === 'string' ? body.admission.trim() : '';
  const term = typeof body.term === 'string' ? body.term.trim() : '';
  const session = typeof body.session === 'string' ? body.session.trim() : '';
  const pin = typeof body.pin === 'string' ? body.pin.trim() : '';
  if (!admission || admission.length > 80 || !term || term.length > 40 || !session || session.length > 40 || !pin || pin.length > 32) {
    return reply({ ok: false, message: 'Result details or access PIN are invalid.' }, 400, origin);
  }

  try {
    const url = Deno.env.get('SUPABASE_URL');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!url || !serviceKey) throw new Error('Edge function secrets are not configured');
    const admin = createClient(url, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await admin.rpc('check_schoolpro_result_pin', {
      p_admission: admission,
      p_term: term,
      p_session: session,
      p_pin: pin,
    });
    if (error) {
      console.error('Result PIN RPC failed.');
      return reply({ ok: false, message: 'Unable to check the result right now. Please try again.' }, 500, origin);
    }
    return reply(data || { ok: false, message: 'Result details or access PIN are invalid.' }, 200, origin);
  } catch {
    console.error('Result PIN gateway failed.');
    return reply({ ok: false, message: 'Unable to check the result right now. Please try again.' }, 500, origin);
  }
});
