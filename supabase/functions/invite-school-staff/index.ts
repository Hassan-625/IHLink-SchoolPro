import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.57.4";

const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};
Deno.serve(async(req:Request)=>{
 if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
 try{
  const authHeader=req.headers.get("Authorization");if(!authHeader)throw new Error("Authentication required");
  const url=Deno.env.get("SUPABASE_URL")!,anon=Deno.env.get("SUPABASE_ANON_KEY")!,service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const userClient=createClient(url,anon,{global:{headers:{Authorization:authHeader}}}),adminClient=createClient(url,service);
  const {data:{user},error:userError}=await userClient.auth.getUser();if(userError||!user)throw new Error("Invalid session");
  const {schoolId,email,role}=await req.json();if(!schoolId||!email||!["administrator","teacher","accountant"].includes(role))throw new Error("Valid school, email and role are required");
  const [{data:school},{data:member}]=await Promise.all([adminClient.from("schoolpro_schools").select("owner_id").eq("id",schoolId).maybeSingle(),adminClient.from("schoolpro_members").select("role").eq("school_id",schoolId).eq("user_id",user.id).maybeSingle()]);
  if(school?.owner_id!==user.id&&!["proprietor","administrator"].includes(member?.role||""))throw new Error("Only school leaders can invite staff");
  const normalizedEmail=String(email).trim().toLowerCase();const {data:existing}=await adminClient.from("profiles").select("id").eq("email",normalizedEmail).maybeSingle();let userId=existing?.id,invited=false;
  if(!userId){const {data,error}=await adminClient.auth.admin.inviteUserByEmail(normalizedEmail,{data:{requested_service:"schoolpro",school_id:schoolId,school_role:role}});if(error)throw error;userId=data.user?.id;invited=true;}
  if(!userId)throw new Error("Unable to create staff account");
  const {error}=await adminClient.from("schoolpro_members").upsert({school_id:schoolId,user_id:userId,role},{onConflict:"school_id,user_id"});if(error)throw error;
  return new Response(JSON.stringify({ok:true,invited,email:normalizedEmail,role}),{headers:{...cors,"Content-Type":"application/json"}});
 }catch(error){return new Response(JSON.stringify({error:error instanceof Error?error.message:"Unable to invite staff"}),{status:400,headers:{...cors,"Content-Type":"application/json"}});}
});
