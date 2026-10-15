import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.57.4";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
  "Vary": "Origin",
};
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
const sha256 = async (value: string) =>
  Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value))))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
  if (req.method !== "POST") return reply({ ok: false, message: "Use POST to check a result." }, 405);

  try {
    const body = await req.json();
    const admission = String(body.admission ?? "").trim();
    const term = String(body.term ?? "").trim();
    const session = String(body.session ?? "").trim();
    const pin = String(body.pin ?? "").trim().toUpperCase();

    if (!admission || !term || !session || !pin ||
        admission.length > 100 || term.length > 100 || session.length > 100 || pin.length > 64) {
      return reply({ ok: false, message: "Enter the admission number, term, session and access PIN." }, 400);
    }

    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !serviceKey) throw new Error("Missing server configuration");

    const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });

    // Supabase's gateway should append the real client address to X-Forwarded-For.
    // Use the last hop, not the first, so a client-supplied leading value cannot
    // trivially rotate the bucket. No IP or admission number is stored in clear text.
    const forwarded = (req.headers.get("x-forwarded-for") ?? "")
      .split(",").map((part) => part.trim()).filter(Boolean);
    const ip = (req.headers.get("cf-connecting-ip") ?? "").trim()
      || forwarded.at(-1)
      || "unknown";

    const buckets = [
      { key: "schoolpro-result-pin:ip:" + ip, limit: 60 },
      { key: "schoolpro-result-pin:pair:" + ip + ":" + admission.toLocaleLowerCase(), limit: 8 },
    ];
    for (const bucket of buckets) {
      const { data, error } = await admin.rpc("schoolpro_take_login_attempt", {
        p_key: await sha256(bucket.key),
        p_limit: bucket.limit,
      });
      if (error) throw error;
      if (data !== true) {
        return reply({ ok: false, message: "Too many attempts. Please try again in 15 minutes." }, 429);
      }
    }

    const { data, error } = await admin.rpc("check_schoolpro_result_pin", {
      p_admission: admission,
      p_term: term,
      p_session: session,
      p_pin: pin,
    });
    if (error) throw error;
    return reply(data ?? { ok: false, message: "Result details or access PIN are invalid." });
  } catch (error) {
    console.error("[schoolpro-result-pin-check] failed", {
      name: error instanceof Error ? error.name : "Error",
    });
    return reply({ ok: false, message: "Unable to check the result right now." }, 500);
  }
});
