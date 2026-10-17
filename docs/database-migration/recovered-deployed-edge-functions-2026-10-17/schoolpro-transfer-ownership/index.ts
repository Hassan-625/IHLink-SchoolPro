import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const response = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return response({ ok: true });
  if (req.method !== "POST") return response({ error: "Method not allowed" }, 405);

  const authorization = req.headers.get("Authorization");
  if (!authorization) return response({ error: "Sign in as a Super Administrator first" }, 401);

  try {
    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!url || !anonKey) return response({ error: "Server configuration unavailable" }, 503);

    const client = createClient(url, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: { user }, error: authError } = await client.auth.getUser();
    if (authError || !user) return response({ error: "Valid sign-in required" }, 401);

    const body = await req.json().catch(() => null);
    const schoolId = body?.school_id;
    const newOwnerId = body?.new_owner_id;
    const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (typeof schoolId !== "string" || !uuid.test(schoolId) ||
        typeof newOwnerId !== "string" || !uuid.test(newOwnerId)) {
      return response({ error: "Valid school_id and new_owner_id are required" }, 400);
    }

    const { data, error } = await client.rpc("schoolpro_transfer_ownership", {
      p_school_id: schoolId,
      p_new_owner_id: newOwnerId,
    });
    if (error) {
      const status = /Super Administrator|Authentication required/i.test(error.message) ? 403 : 400;
      return response({ error: error.message }, status);
    }
    return response(data);
  } catch {
    return response({ error: "Ownership transfer could not be completed" }, 500);
  }
});