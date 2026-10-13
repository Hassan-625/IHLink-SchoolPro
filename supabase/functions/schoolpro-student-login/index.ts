import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {createClient} from "npm:@supabase/supabase-js@2.57.4";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};
const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json","Cache-Control":"no-store"}});
const hash=async(value:string)=>Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(value)))).map(v=>v.toString(16).padStart(2,"0")).join("");
Deno.serve(async(req)=>{
 if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
 if(req.method!=="POST")return reply({error:"Use student sign in."},405);
 let stage="request_validation";
 try{
  const url=Deno.env.get("SUPABASE_URL")!,key=Deno.env.get("SUPABASE_ANON_KEY")!;
  const admin=createClient(url,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,{auth:{persistSession:false}});
  const client=createClient(url,key,{auth:{persistSession:false}});
  const body=await req.json();const code=String(body.schoolCode||"").trim(),admission=String(body.admissionNumber||"").trim(),password=String(body.password||"");
  if(!code||!admission||code.length>100||admission.length>100||password.length>256)return reply({error:"Enter your school code, admission number and password."},400);
  // Supabase gateway-provided client address; account bucket also limits IP rotation.
  const ip=req.headers.get("x-forwarded-for")?.split(",")[0]?.trim()||"unknown";
  for(const [bucket,limit] of [["account:"+code.toLowerCase()+":"+admission.toLowerCase(),8],["ip:"+ip,60]] as const){
   stage="rate_limit";const {data,error}=await admin.rpc("schoolpro_take_login_attempt",{p_key:await hash(bucket),p_limit:limit});if(error)throw error;if(!data){console.warn("[schoolpro-student-login] rejected",{stage:"rate_limited"});return reply({error:"Too many attempts. Please try again in 15 minutes."},429);}
  }
  stage="school_lookup";const {data:schools,error:se}=await admin.from("schoolpro_schools").select("id").eq("code",code).limit(2);if(se)throw se;
  if(schools?.length!==1){console.warn("[schoolpro-student-login] rejected",{stage:"school_lookup_not_unique",matches:schools?.length||0});return reply({error:"The sign-in details were not recognised. Check with your school."},401);}
  stage="student_lookup";const {data:students,error:ste}=await admin.from("schoolpro_students").select("id,user_id,last_name,first_name").eq("school_id",schools[0].id).eq("admission_number",admission).in("status",["active","graduated"]).limit(2);if(ste)throw ste;
  if(students?.length!==1){console.warn("[schoolpro-student-login] rejected",{stage:"student_lookup_not_unique",matches:students?.length||0});return reply({error:"The sign-in details were not recognised. Check with your school."},401);}
  const student=students[0];let email:string|undefined;
  if(!student.user_id){
   if(body.challenge){
    if(password.length<10||password.trim().toLowerCase()===String(student.last_name).trim().toLowerCase())return reply({error:"Choose a new password of at least 10 characters, different from your surname."},400);
    stage="challenge_consume";const {data:sid,error}=await admin.rpc("schoolpro_consume_student_challenge",{p_hash:await hash(String(body.challenge))});if(error)throw error;
    if(sid!==student.id){console.warn("[schoolpro-student-login] rejected",{stage:"activation_challenge_mismatch"});return reply({error:"Your activation expired. Sign in with your surname again."},401);}
    email=`student-${crypto.randomUUID()}@students.ihlink.invalid`;
    const {data:created,error:ce}=await admin.auth.admin.createUser({email,password,email_confirm:true,user_metadata:{requested_service:"schoolpro",first_name:student.first_name,last_name:student.last_name}});if(ce||!created.user)throw ce||new Error("create");
    const {data:linked,error:le}=await admin.from("schoolpro_students").update({user_id:created.user.id}).eq("id",student.id).is("user_id",null).select("id");
    if(le||linked?.length!==1){await admin.auth.admin.deleteUser(created.user.id);throw le||new Error("link");}
   }else{
    if(password.trim().toLowerCase()!==String(student.last_name).trim().toLowerCase())return reply({error:"The sign-in details were not recognised. Check with your school."},401);
    const challenge=crypto.randomUUID()+crypto.randomUUID();
    const {error}=await admin.from("schoolpro_student_activation_challenges").insert({token_hash:await hash(challenge),student_id:student.id});if(error)throw error;
    // No session or school records are returned while the surname is still the credential.
    return reply({requiresPasswordChange:true,challenge});
   }
  }else{
   if(body.challenge){console.warn("[schoolpro-student-login] rejected",{stage:"challenge_for_activated_account"});return reply({error:"Your account is already activated. Sign in with your chosen password."},401);}
   stage="linked_user_lookup";const {data,error}=await admin.auth.admin.getUserById(student.user_id);if(error)throw error;email=data.user?.email;
  }
  if(!email)throw new Error("identity");
  stage="password_auth";const {data,error}=await client.auth.signInWithPassword({email,password});
  if(error||!data.session){console.warn("[schoolpro-student-login] rejected",{stage:"password_auth_rejected",status:error?.status||null,code:error?.code||null,name:error?.name||null});return reply({error:"The sign-in details were not recognised. Check with your school."},401);}
  return reply({session:{access_token:data.session.access_token,refresh_token:data.session.refresh_token}});
 }catch(error){const e=error as {code?:string;name?:string;status?:number};console.error("[schoolpro-student-login] failed",{stage,code:e?.code||null,status:e?.status||null,name:e?.name||"Error"});return reply({error:"Student sign in could not be completed. Please try again or contact your school."},400);}
});

