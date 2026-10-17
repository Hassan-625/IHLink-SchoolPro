import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {createClient} from "npm:@supabase/supabase-js@2.57.4";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Content-Type":"application/json"};
Deno.serve(async(req)=>{if(req.method==="OPTIONS")return new Response("ok",{headers:cors});try{
const auth=req.headers.get("Authorization");if(!auth)throw new Error("Authentication required");
const sb=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_ANON_KEY")!,{global:{headers:{Authorization:auth}}});
const {data:{user}}=await sb.auth.getUser();if(!user)throw new Error("Invalid session");
const {student_id,term,session,format="pdf"}=await req.json();if(!student_id||!term||!session)throw new Error("student_id, term and session are required");
const {data:allowed,error:ae}=await sb.rpc("schoolpro_can_view_result_output",{p_student_id:student_id,p_term:term,p_session:session});if(ae)throw ae;if(!allowed)throw new Error("Result is unavailable, unpublished, held, or this account is not linked to the student.");
const {data:out,error:oe}=await sb.from("schoolpro_generated_result_outputs").select("storage_path,format,generated_at").eq("student_id",student_id).eq("term",term).eq("session",session).eq("format",format).maybeSingle();if(oe)throw oe;if(!out)throw new Error("A generated result file is not available yet.");
const signed=await sb.storage.from("school-result-templates").createSignedUrl(out.storage_path,120);if(signed.error)throw signed.error;
return new Response(JSON.stringify({ok:true,format:out.format,generated_at:out.generated_at,signed_url:signed.data.signedUrl,expires_in:120}),{headers:cors});
}catch(e){return new Response(JSON.stringify({ok:false,error:e instanceof Error?e.message:String(e)}),{status:403,headers:cors})}});