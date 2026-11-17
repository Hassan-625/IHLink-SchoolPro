import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.117.3';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Cache-Control': 'no-store',
};
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (req.method !== 'POST') return reply({ error: 'Use the SchoolPro member profile editor.' }, 405);

  try {
    const token = req.headers.get('Authorization')?.match(/^Bearer (.+)$/i)?.[1];
    if (!token) return reply({ error: 'Please sign in again.' }, 401);

    const url = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const options = { auth: { persistSession: false, autoRefreshToken: false } };
    const caller = createClient(url, anonKey, options);
    const admin = createClient(url, serviceKey, options);
    const { data: { user: actor }, error: authError } = await caller.auth.getUser(token);
    if (authError || !actor) return reply({ error: 'Please sign in again.' }, 401);

    const body = await req.json();
    const schoolId = String(body.schoolId || '');
    const targetUserId = String(body.targetUserId || '');
    const newEmail = String(body.newEmail || '').trim().toLowerCase();
    if (!schoolId || !targetUserId || targetUserId === actor.id) {
      return reply({ error: 'Choose a valid staff or guardian account.' }, 400);
    }
    if (newEmail.length > 254 || !/^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(newEmail)) {
      return reply({ error: 'Enter a valid email address.' }, 400);
    }

    const { data, error } = await admin.rpc('schoolpro_request_member_email_change_atomic', {
      p_school_id: schoolId,
      p_target_user_id: targetUserId,
      p_actor_id: actor.id,
      p_new_email: newEmail,
    });
    if (error) {
      console.error('schoolpro email change request rejected', error.message);
      return reply({ error: 'Email change request was not saved. Refresh and try again.' }, 403);
    }
    return reply({ ok: true, ...data });
  } catch (error) {
    console.error('schoolpro email change request failed', error instanceof Error ? error.message : 'unknown');
    return reply({ error: 'Email change request failed. Refresh and try again.' }, 500);
  }
});
