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
  if (req.method !== 'POST') return reply({ error: 'Use the school profile editor.' }, 405);

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
    const firstName = String(body.firstName || '').trim();
    const middleName = String(body.middleName || '').trim();
    const lastName = String(body.lastName || '').trim();
    const phone = String(body.phone || '').trim();

    if (!schoolId || !targetUserId || targetUserId === actor.id) {
      return reply({ error: 'Choose a valid school member or guardian account.' }, 400);
    }
    if (!firstName || !lastName || firstName.length > 100 || middleName.length > 100 || lastName.length > 100) {
      return reply({ error: 'First name and surname are required and must be 100 characters or fewer.' }, 400);
    }
    if (phone && !/^[+0-9() .-]{7,40}$/.test(phone)) {
      return reply({ error: 'Enter a valid phone number.' }, 400);
    }

    const { data, error } = await admin.rpc('schoolpro_correct_member_profile_atomic', {
      p_school_id: schoolId,
      p_target_user_id: targetUserId,
      p_actor_id: actor.id,
      p_first_name: firstName,
      p_middle_name: middleName || null,
      p_last_name: lastName,
      p_phone: phone || null,
    });

    if (error) {
      console.error('schoolpro profile correction rejected', error.message);
      return reply({ error: 'Profile correction was not saved. No partial update was committed; refresh and try again.' }, 403);
    }
    return reply({ ok: true, ...data });
  } catch (error) {
    console.error('schoolpro profile correction failed', error instanceof Error ? error.message : 'unknown');
    return reply({ error: 'Profile correction failed. Refresh and try again.' }, 500);
  }
});
