import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.57.4";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};
const respond=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});
Deno.serve(async(req:Request)=>{
 if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
 if(req.method!=="POST")return respond({error:"Use the invitation form."},405);
 try{
  const auth=req.headers.get("Authorization");if(!auth)return respond({error:"Please sign in again."},401);
  const url=Deno.env.get("SUPABASE_URL")!,anon=Deno.env.get("SUPABASE_ANON_KEY")!,service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const caller=createClient(url,anon,{global:{headers:{Authorization:auth}}}),admin=createClient(url,service);
  const {data:{user},error:ue}=await caller.auth.getUser();if(ue||!user)return respond({error:"Please sign in again."},401);
  const {schoolId,email,role,studentId,relationship="guardian"}=await req.json();
  const normalized=String(email||"").trim().toLowerCase();
  if(!schoolId||!/^\S+@\S+\.\S+$/.test(normalized)||normalized.length>254||!["administrator","teacher","accountant","parent"].includes(role))return respond({error:"Choose a school, valid email and access role."},400);
  const [{data:school,error:se},{data:member,error:me},{data:profile,error:pe}]=await Promise.all([admin.from("schoolpro_schools").select("owner_id").eq("id",schoolId).maybeSingle(),admin.from("schoolpro_members").select("role").eq("school_id",schoolId).eq("user_id",user.id).maybeSingle(),admin.from("profiles").select("status").eq("id",user.id).maybeSingle()]);
  if(se||me||pe)throw new Error("lookup");
  if(!school||profile?.status!=="active"||(school.owner_id!==user.id&&!["proprietor","administrator"].includes(member?.role||"")))return respond({error:"Only school leaders can invite accounts to this school."},403);
  if(role==="parent"){
   if(!studentId||!["mother","father","guardian","sponsor"].includes(relationship))return respond({error:"Choose a student and relationship."},400);
   const {data:student,error}=await admin.from("schoolpro_students").select("id").eq("id",studentId).eq("school_id",schoolId).eq("status","active").maybeSingle();
   if(error)throw error;if(!student)return respond({error:"Choose an active student from this school."},400);
  }
  const {data:existing,error:ee}=await admin.from("profiles").select("id").eq("email",normalized).maybeSingle();if(ee)throw ee;
  let userId=existing?.id,invited=false;
  if(!userId){
   const {data,error}=await admin.auth.admin.inviteUserByEmail(normalized,{redirectTo:"https://ihlink-schoolpro.onrender.com/auth/update-password",data:{requested_service:"schoolpro"}});
   if(error)throw error;userId=data.user?.id;invited=true;
  }
  if(!userId)throw new Error("invite");
  if(role==="parent"){
   const {error}=await admin.from("schoolpro_guardian_links").upsert({school_id:schoolId,student_id:studentId,guardian_user_id:userId,relationship,status:"active",linked_by:user.id},{onConflict:"student_id,guardian_user_id"});if(error)throw error;
  }else{
   if(userId===school.owner_id)return respond({error:"The proprietor already has access. Use staff invitations for another person."},400);
   const {data:prior,error}=await admin.from("schoolpro_members").select("role").eq("school_id",schoolId).eq("user_id",userId).maybeSingle();if(error)throw error;
   if(!prior){const {error}=await admin.from("schoolpro_members").insert({school_id:schoolId,user_id:userId,role});if(error)throw error;}
   else if(prior.role!==role)return respond({error:"This person already has a school role. Change their role in Staff & Access."},409);
  }
  return respond({ok:true,invited,email:normalized,role});
 }catch{return respond({error:"The invitation could not be completed. Please try again or contact support."},400);}
});
