import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.117.3';
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS','Cache-Control':'no-store'};
const respond=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,'Content-Type':'application/json'}});
const hash=async(value:string)=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(value)))).map(v=>v.toString(16).padStart(2,'0')).join('');
Deno.serve(async(req:Request)=>{
 if(req.method==='OPTIONS')return new Response(null,{status:204,headers:cors});
 if(req.method!=='POST')return respond({error:'Use the school access form.'},405);
 try{
  const token=req.headers.get('Authorization')?.match(/^Bearer (.+)$/i)?.[1];if(!token)return respond({error:'Please sign in again.'},401);
  const url=Deno.env.get('SUPABASE_URL')!,anon=Deno.env.get('SUPABASE_ANON_KEY')!,key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const options={auth:{persistSession:false,autoRefreshToken:false}};
  const caller=createClient(url,anon,options),admin=createClient(url,key,options);
  const {data:{user},error:ue}=await caller.auth.getUser(token);if(ue||!user)return respond({error:'Please sign in again.'},401);
  const body=await req.json();
  if(body.action==='accept'){
   const code=String(body.code||'').trim();if(code.length<20||code.length>120)return respond({error:'Enter the joining code supplied by your school.'},400);
   const {data:allowed,error:re}=await admin.rpc('schoolpro_take_login_attempt',{p_key:await hash('school-accept:'+user.id),p_limit:8});if(re)throw re;if(!allowed)return respond({error:'Too many attempts. Please try again in 15 minutes.'},429);
   const {data,error}=await admin.rpc('schoolpro_accept_access_invitation',{p_user:user.id,p_hash:await hash(code)});if(error)throw error;
   return data?respond({ok:true}):respond({error:'This joining code is invalid, expired or belongs to another email.'},400);
  }
  const {schoolId,email,role,relationship='guardian'}=body;
  const normalized=String(email||'').trim().toLowerCase();
  const firstName=String(body.firstName||'').trim(),middleName=String(body.middleName||'').trim(),surname=String(body.surname||'').trim();
  if(!schoolId||!/^\S+@\S+\.\S+$/.test(normalized)||normalized.length>254||!['administrator','teacher','accountant','parent'].includes(role)||!firstName||!middleName||!surname||[firstName,middleName,surname].some(x=>x.length>100))return respond({error:'Enter first name, middle name, surname, valid email and school role.'},400);
  const [{data:school,error:se},{data:member,error:me},{data:profile,error:pe}]=await Promise.all([admin.from('schoolpro_schools').select('owner_id').eq('id',schoolId).maybeSingle(),admin.from('schoolpro_members').select('role').eq('school_id',schoolId).eq('user_id',user.id).maybeSingle(),admin.from('profiles').select('status,role').eq('id',user.id).maybeSingle()]);
  if(se||me||pe)throw new Error('lookup');
  if(!school||profile?.status!=='active'||(profile.role!=='super_admin'&&school.owner_id!==user.id&&!['proprietor','administrator'].includes(member?.role||'')))return respond({error:'Only school leaders can add accounts to this school.'},403);
  const {data:allowed,error:rateError}=await admin.rpc('schoolpro_take_login_attempt',{p_key:await hash('school-add:'+user.id),p_limit:60});if(rateError)throw rateError;if(!allowed)return respond({error:'Please wait 15 minutes before adding more accounts.'},429);
  const studentIds=Array.from(new Set(Array.isArray(body.studentIds)?body.studentIds:body.studentId?[body.studentId]:[])) as string[];
  if(role==='parent'){
   if(!studentIds.length||studentIds.length>50||!['mother','father','guardian','sponsor'].includes(relationship))return respond({error:'Choose at least one enrolled child and a relationship.'},400);
   const {data:students,error}=await admin.from('schoolpro_students').select('id').in('id',studentIds).eq('school_id',schoolId).eq('status','active');if(error)throw error;
   if(students?.length!==studentIds.length)return respond({error:'Choose enrolled children from this school.'},400);
  }
  const {data:existing,error:ee}=await admin.from('profiles').select('id,last_name').eq('email',normalized).maybeSingle();if(ee)throw ee;
  if(existing?.id===school.owner_id)return respond({error:'The proprietor already has school access.'},400);
  const code=crypto.randomUUID()+crypto.randomUUID(),tokenHash=await hash(code);
  if(existing){
   const {data:initial,error:initialError}=await admin.from('schoolpro_initial_credentials').select('user_id').eq('user_id',existing.id).eq('school_id',schoolId).is('consumed_at',null).maybeSingle();if(initialError)throw initialError;
   if(initial){
    const {data:identity,error:identityError}=await admin.auth.admin.getUserById(existing.id);if(identityError)throw identityError;
    if(identity.user?.app_metadata.schoolpro_initial_login===true){
     const {data:renewed,error:renewError}=await admin.from('schoolpro_initial_credentials').update({expires_at:new Date(Date.now()+7*86400000).toISOString()}).eq('user_id',existing.id).eq('school_id',schoolId).is('consumed_at',null).select('user_id');if(renewError||renewed?.length!==1)throw renewError||new Error('renew');
     const {error:challengeError}=await admin.from('schoolpro_account_challenges').delete().eq('user_id',existing.id);if(challengeError)throw challengeError;
     const {error:invitationError}=await admin.from('schoolpro_access_invitations').insert({school_id:schoolId,email:normalized,role,student_ids:role==='parent'?studentIds:[],relationship,token_hash:tokenHash,created_by:user.id});if(invitationError)throw invitationError;
     const {data:linked,error:linkError}=await admin.rpc('schoolpro_accept_access_invitation',{p_user:existing.id,p_hash:tokenHash});if(linkError||!linked)throw linkError||new Error('link');
     return respond({ok:true,created:true,email:normalized,role,initialPassword:'surname',surname:existing.last_name,expiresInDays:7});
    }
   }
   const {error}=await admin.from('schoolpro_access_invitations').insert({school_id:schoolId,email:normalized,role,student_ids:role==='parent'?studentIds:[],relationship,token_hash:tokenHash,created_by:user.id});if(error)throw error;
   return respond({ok:true,created:false,requiresAcceptance:true,joiningCode:code,email:normalized,role});
  }
  // A random inaccessible Auth password and ban prevent surname sessions or OAuth bypass.
  const {data:created,error:ce}=await admin.auth.admin.createUser({email:normalized,password:crypto.randomUUID()+crypto.randomUUID(),email_confirm:true,ban_duration:'876000h',app_metadata:{schoolpro_initial_login:true},user_metadata:{requested_service:'schoolpro',first_name:firstName,middle_name:middleName,last_name:surname}});
  if(ce||!created.user)throw ce||new Error('create');
  const uid=created.user.id;
  try{
   const {error:profileError}=await admin.from('profiles').update({first_name:firstName,middle_name:middleName,last_name:surname}).eq('id',uid);if(profileError)throw profileError;
   const {error:credentialError}=await admin.rpc('schoolpro_set_initial_credential',{p_user:uid,p_school:schoolId,p_surname:surname});if(credentialError)throw credentialError;
   const {error:inviteError}=await admin.from('schoolpro_access_invitations').insert({school_id:schoolId,email:normalized,role,student_ids:role==='parent'?studentIds:[],relationship,token_hash:tokenHash,created_by:user.id});if(inviteError)throw inviteError;
   const {data:linked,error:linkError}=await admin.rpc('schoolpro_accept_access_invitation',{p_user:uid,p_hash:tokenHash});if(linkError||!linked)throw linkError||new Error('link');
  }catch(error){await admin.auth.admin.deleteUser(uid);throw error;}
  return respond({ok:true,created:true,email:normalized,role,initialPassword:'surname',expiresInDays:7});
 }catch{return respond({error:'School access could not be created. Please check the details or contact support.'},400);}
});
