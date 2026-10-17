import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.117.3';

const allowedOrigins = new Set(
  (Deno.env.get('SCHOOLPRO_ADMISSION_ALLOWED_ORIGINS') || '')
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
const action = 'schoolpro_public_admission';

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
  if (req.method !== 'POST') return reply({ error: 'Use the admission form to submit an application.' }, 405, origin);
  if (!origin || !allowedOrigins.has(origin)) return reply({ error: 'This admission form origin is not allowed.' }, 403);

  const secret = Deno.env.get('TURNSTILE_SECRET_KEY');
  const hostnames = allowedHostnames;
  if (!secret || hostnames.size === 0) {
    console.error('Public admissions blocked: Turnstile secret or allowed hostnames are not configured.');
    return reply({ error: 'Secure admission verification is not configured yet. Please contact the school.' }, 503, origin);
  }

  const contentLength = Number(req.headers.get('content-length') || '0');
  if (contentLength > 16_384) return reply({ error: 'Application request is too large.' }, 413, origin);

  let body: Record<string, unknown>;
  try {
    const raw = await req.text();
    if (raw.length > 16_384) return reply({ error: 'Application request is too large.' }, 413, origin);
    body = JSON.parse(raw);
    if (!body || typeof body !== 'object' || Array.isArray(body)) throw new Error('invalid body');
  } catch {
    return reply({ error: 'Invalid application request.' }, 400, origin);
  }

  const token = typeof body.turnstileToken === 'string' ? body.turnstileToken.trim() : '';
  if (!token || token.length > 2048) return reply({ error: 'Complete the secure verification before submitting.' }, 400, origin);

  let verification: { success?: boolean; action?: string; hostname?: string; 'error-codes'?: string[] };
  try {
    const response = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ secret, response: token }),
      signal: AbortSignal.timeout(8_000),
    });
    if (!response.ok) throw new Error('Siteverify unavailable');
    verification = await response.json();
  } catch {
    console.error('Turnstile Siteverify request failed.');
    return reply({ error: 'Secure verification is temporarily unavailable. Please try again.' }, 503, origin);
  }

  if (
    verification.success !== true ||
    verification.action !== action ||
    typeof verification.hostname !== 'string' ||
    !hostnames.has(verification.hostname.toLowerCase())
  ) {
    return reply({ error: 'Secure verification failed. Please verify again and retry.' }, 403, origin);
  }

  const school = typeof body.school === 'string' ? body.school : '';
  const first = typeof body.first_name === 'string' ? body.first_name : '';
  const last = typeof body.last_name === 'string' ? body.last_name : '';
  const gender = typeof body.gender === 'string' ? body.gender : '';
  const dob = typeof body.date_of_birth === 'string' && body.date_of_birth ? body.date_of_birth : null;
  const guardian = typeof body.guardian_name === 'string' ? body.guardian_name : '';
  const phone = typeof body.guardian_contact === 'string' ? body.guardian_contact : '';
  const email = typeof body.guardian_email === 'string' ? body.guardian_email : '';
  const appliedClass = typeof body.class_applied === 'string' ? body.class_applied : '';
  const previous = typeof body.previous_school === 'string' ? body.previous_school : null;

  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(school)) {
    return reply({ error: 'A valid school admission link is required.' }, 400, origin);
  }

  try {
    const url = Deno.env.get('SUPABASE_URL');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!url || !serviceKey) throw new Error('Edge function secrets are not configured');
    const admin = createClient(url, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await admin.rpc('submit_schoolpro_application', {
      p_school: school,
      p_first: first,
      p_last: last,
      p_gender: gender,
      p_dob: dob,
      p_guardian: guardian,
      p_phone: phone,
      p_email: email,
      p_class: appliedClass,
      p_previous: previous,
    });
    if (error) {
      const message = error.message || '';
      if (/too many applications|application limit reached/i.test(message)) {
        return reply({ error: 'Too many applications for these guardian details. Please try again later.' }, 429, origin);
      }
      if (/admissions are not currently open/i.test(message)) {
        return reply({ error: 'Admissions are not currently open.' }, 403, origin);
      }
      if (/required application|exceed the allowed length|must contain|valid guardian|gender option|valid date/i.test(message)) {
        return reply({ error: message }, 400, origin);
      }
      console.error('Public admissions RPC failed.');
      return reply({ error: 'The application could not be submitted. Please try again.' }, 500, origin);
    }
    return reply({ application_number: data?.application_number }, 200, origin);
  } catch {
    console.error('Public admissions gateway failed.');
    return reply({ error: 'The application could not be submitted. Please try again.' }, 500, origin);
  }
});
