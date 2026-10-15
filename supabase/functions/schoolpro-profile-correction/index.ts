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
  const [{data:member},{data:guardian}]=await Promise.all([
   admin.from('schoolpro_members').select('id').eq('school_id',schoolId).eq('user_id',targetUserId).maybeSingle(),
   admin.from('schoolpro_guardian_links').select('id').eq('school_id',schoolId).eq('guardian_user_id',targetUserId).limit(1).maybeSingle()
  ]);
  if(!member&&!guardian)return reply({error:'This account is not linked to the selected school.'},404);
  const first=String(body.firstName||'').trim(),middle=String(body.middleName||'').trim(),last=String(body.lastName||'').trim();
  const phone=String(body.phone||'').trim(),email=String(body.email||'').trim().toLowerCase();
  if(!first||!last||first.length>100||middle.length>100||last.length>100)return reply({error:'First name and surname are required and must be 100 characters or fewer.'},400);
  if(phone&&!/^[+0-9() .-]{7,40}$/.test(phone))return reply({error:'Enter a valid phone number.'},400);
  if(email&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))return reply({error:'Enter a valid email address.'},400);
  const {data:before,error:beforeError}=await admin.from('profiles').select('first_name,middle_name,last_name,email,phone').eq('id',targetUserId).maybeSingle();
  if(beforeError||!before)return reply({error:'The profile could not be found.'},404);
  const emailChangeRequired=Boolean(email&&email!==String(before.email||'').toLowerCase());
  if(emailChangeRequired){const {data:existing,error:lookupError}=await admin.from('profiles').select('id').ilike('email',email).neq('id',targetUserId).limit(1).maybeSingle();if(lookupError)throw lookupError;if(existing)return reply({error:'That email is already linked to another IHLink account.'},409);}
  // Never mutate auth.users directly for a school-admin email correction. Supabase
  // admin updates bypass confirmation; until a verified email-change delivery flow
  // is available, preserve the existing sign-in email and save only safe fields.
  const next={first_name:first,middle_name:middle||null,last_name:last,email:before.email,phone:phone||null};
  const fields=Object.keys(next).filter(k=>(before as Record<string,unknown>)[k]!== (next as Record<string,unknown>)[k]);
  if(!fields.length)return reply({ok:true,changed:false,emailChangeRequired});
  const {error:updateError}=await admin.from('profiles').update(next).eq('id',targetUserId);
  if(updateError)throw updateError;
  if(guardian){
   const {error:phoneError}=await admin.from('schoolpro_guardian_links').update({phone:phone||null}).eq('school_id',schoolId).eq('guardian_user_id',targetUserId);
   if(phoneError)throw phoneError;
  }
  const {error:auditError}=await admin.from('schoolpro_profile_change_audit').insert({school_id:schoolId,target_user_id:targetUserId,changed_by:actor.id,changed_fields:fields,before_values:before,after_values:next});
  if(auditError)throw auditError;
  return reply({ok:true,changed:true,emailChangeRequired});
 }catch(error){console.error('schoolpro-profile-correction failed',error instanceof Error?error.message:'unknown');return reply({error:'Profile correction failed. Refresh and try again.'},500);}
});
