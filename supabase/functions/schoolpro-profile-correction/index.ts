import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import {createClient} from 'npm:@supabase/supabase-js@2.117.3';
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Cache-Control':'no-store'};
const reply=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json'}});
Deno.serve(async(req:Request)=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers:cors});
 if(req.method!=='POST')return reply({error:'Use the profile editor.'},405);
 try{
  const token=req.headers.get('Authorization')?.match(/^Bearer (.+)$/i)?.[1];if(!token)return reply({error:'Please sign in again.'},401);
  const url=Deno.env.get('SUPABASE_URL')!,anon=Deno.env.get('SUPABASE_ANON_KEY')!,key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const options={auth:{persistSession:false,autoRefreshToken:false}};
  const caller=createClient(url,anon,options),admin=createClient(url,key,options);
  const {data:{user:actor},error:authError}=await caller.auth.getUser(token);if(authError||!actor)return reply({error:'Please sign in again.'},401);
  const body=await req.json();const schoolId=String(body.schoolId||''),targetUserId=String(body.targetUserId||'');
  if(!schoolId||!targetUserId||targetUserId===actor.id)return reply({error:'Choose a valid school member or parent account.'},400);
  const [{data:school,error:schoolError},{data:actorMember,error:memberError},{data:actorProfile,error:profileError}]=await Promise.all([
   admin.from('schoolpro_schools').select('owner_id').eq('id',schoolId).maybeSingle(),
   admin.from('schoolpro_members').select('role').eq('school_id',schoolId).eq('user_id',actor.id).maybeSingle(),
   admin.from('profiles').select('role,status').eq('id',actor.id).maybeSingle()
  ]);
  if(schoolError||memberError||profileError)throw new Error('authorization lookup failed');
  const globalAdmin=actorProfile?.role==='super_admin'&&actorProfile?.status==='active';
  const schoolLeader=school?.owner_id===actor.id||['proprietor','administrator'].includes(actorMember?.role||'');
  if(!school||(!globalAdmin&&!schoolLeader))return reply({error:'Only the school owner or administrator can correct these profile details.'},403);
  const first=String(body.firstName||'').trim(),middle=String(body.middleName||'').trim(),last=String(body.lastName||'').trim();
  const phone=String(body.phone||'').trim(),email=String(body.email||'').trim().toLowerCase();
  if(!first||!last||first.length>100||middle.length>100||last.length>100)return reply({error:'First name and surname are required and must be 100 characters or fewer.'},400);
  if(phone&&!/^[+0-9() .-]{7,40}$/.test(phone))return reply({error:'Enter a valid phone number.'},400);
  if(email&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))return reply({error:'Enter a valid email address.'},400);
  const {data:before,error:beforeError}=await admin.from('profiles').select('first_name,middle_name,last_name,email,phone').eq('id',targetUserId).maybeSingle();
  if(beforeError||!before)return reply({error:'The profile could not be found.'},404);
  const emailChangeRequired=Boolean(email&&email!==String(before.email||'').toLowerCase());
  if(emailChangeRequired){const {data:existing,error:lookupError}=await admin.from('profiles').select('id').ilike('email',email).neq('id',targetUserId).limit(1).maybeSingle();if(lookupError)throw lookupError;if(existing)return reply({error:'That email is already linked to another IHLink account.'},409);}
  const {error:updateError}=await admin.rpc('schoolpro_correct_member_profile_atomic',{p_school_id:schoolId,p_target_user_id:targetUserId,p_actor_id:actor.id,p_first_name:first,p_middle_name:middle||null,p_last_name:last,p_phone:phone||null});
  if(updateError){console.error('schoolpro-profile-correction rpc failed',updateError.message);return reply({error:'Profile correction was not saved. No partial update was committed; refresh and try again.'},400);}
  return reply({ok:true,changed:true,emailChangeRequired});
 }catch(error){console.error('schoolpro-profile-correction failed',error instanceof Error?error.message:'unknown');return reply({error:'Profile correction failed. Refresh and try again.'},500);}
});