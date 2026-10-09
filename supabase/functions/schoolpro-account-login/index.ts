import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import {createClient}from'npm:@supabase/supabase-js@2.117.3';
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Cache-Control':'no-store'};
const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json'}});
const hash=async(value:string)=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(value)))).map(v=>v.toString(16).padStart(2,'0')).join('');
Deno.serve(async(req)=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers:cors});
 if(req.method!=='POST')return reply({error:'Use school sign in.'},405);
 try{
  const body=await req.json(),email=String(body.email||'').trim().toLowerCase(),password=String(body.password||'');
  if(!/^\S+@\S+\.\S+$/.test(email)||email.length>254||!password||password.length>256)return reply({error:'Enter your email and password.'},400);
  const url=Deno.env.get('SUPABASE_URL')!,options={auth:{persistSession:false,autoRefreshToken:false}},admin=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,options),client=createClient(url,Deno.env.get('SUPABASE_ANON_KEY')!,options);
  const ip=req.headers.get('x-forwarded-for')?.split(',')[0]?.trim()||'unknown';
  for(const[bucket,limit]of[['email:'+email,8],['ip:'+ip,60]]as const){const{data,error}=await admin.rpc('schoolpro_take_login_attempt',{p_key:await hash('school-account:'+bucket),p_limit:limit});if(error)throw error;if(!data)return reply({error:'Too many attempts. Please try again in 15 minutes.'},429);}
  const {data:profile,error:pe}=await admin.from('profiles').select('id,status').eq('email',email).maybeSingle();if(pe)throw pe;
  if(!profile||profile.status!=='active')return reply({error:'Your sign-in details were not recognised. Please check with your school.'},401);
  const {data:credential,error:ce}=await admin.from('schoolpro_initial_credentials').select('user_id').eq('user_id',profile.id).gt('expires_at',new Date().toISOString()).is('consumed_at',null).maybeSingle();if(ce)throw ce;
  if(credential){
   if(body.challenge){
    if(password.length<10)return reply({error:'Choose a new password of at least 10 characters.'},400);
    const {data:identity,error:identityError}=await admin.auth.admin.getUserById(profile.id);if(identityError)throw identityError;
    const {data:valid,error}=await admin.rpc('schoolpro_consume_account_challenge',{p_user:profile.id,p_hash:await hash(String(body.challenge)),p_password:password});if(error)throw error;
    if(!valid)return reply({error:'Choose a password different from your surname, or restart activation if it expired.'},400);
    const {error:updateError}=await admin.auth.admin.updateUserById(profile.id,{password,ban_duration:'none',app_metadata:{...identity.user?.app_metadata,schoolpro_initial_login:false}});
    if(updateError){await admin.from('schoolpro_initial_credentials').update({consumed_at:null}).eq('user_id',profile.id);throw updateError;}
    const {error:deleteError}=await admin.from('schoolpro_initial_credentials').delete().eq('user_id',profile.id);if(deleteError)throw deleteError;
   }else{
    const challenge=crypto.randomUUID()+crypto.randomUUID();
    const {data:valid,error}=await admin.rpc('schoolpro_initial_challenge',{p_user:profile.id,p_surname:password,p_hash:await hash(challenge)});if(error)throw error;
    if(!valid)return reply({error:'Your sign-in details were not recognised. Please check with your school.'},401);
    return reply({requiresPasswordChange:true,challenge});
   }
  }else if(body.challenge)return reply({error:'Your activation expired or was already completed. Sign in again.'},401);
  const {data,error}=await client.auth.signInWithPassword({email,password});
  if(error||!data.session)return reply({error:'Your sign-in details were not recognised. Please check with your school.'},401);
  return reply({session:{access_token:data.session.access_token,refresh_token:data.session.refresh_token}});
 }catch{return reply({error:'Sign in could not be completed. Please try again or contact your school.'},400);}
});
