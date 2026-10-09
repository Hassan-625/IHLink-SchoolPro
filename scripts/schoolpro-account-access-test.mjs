import fs from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
import assert from 'node:assert/strict';
import {webcrypto} from 'node:crypto';
const school='school-a',studentId='student-a';
function fixture(){return {schoolpro_schools:[{id:school,code:'SCHOOL-A',owner_id:'owner'}],schoolpro_students:[{id:studentId,school_id:school,admission_number:'ADM-1',first_name:'Fixture',last_name:'Example',user_id:null,status:'active'}],profiles:[{id:'owner',email:'owner@example.test',status:'active'},{id:'parent',email:'parent@example.test',status:'active'}],schoolpro_members:[],schoolpro_guardian_links:[],schoolpro_student_activation_challenges:[],schoolpro_initial_credentials:[],schoolpro_account_challenges:[],schoolpro_access_invitations:[]};}
async function harness(path){
 let handler;const tables=fixture();const accounts=new Map();let invites=0,creates=0,rateAllowed=true,caller='owner';
 class Query{
  constructor(table){this.table=table;this.filters=[];this.action='read';}
  select(columns){if(columns)this.columns=columns.split(',');return this;}neq(k,v){this.filters.push(r=>r[k]!==v);return this;}order(){return this;}eq(k,v){this.filters.push(r=>r[k]===v);return this;}is(k,v){return this.eq(k,v);}limit(n){this.n=n;return this;}in(k,v){this.filters.push(r=>v.includes(r[k]));return this;}gt(k,v){this.filters.push(r=>r[k]>v);return this;}delete(){this.action="delete";return this;}
  insert(v){this.action='insert';this.value=v;return this;}upsert(v){this.action='upsert';this.value=v;return this;}update(v){this.action='update';this.value=v;return this;}
  async run(single=false){let rows=(tables[this.table]||[]).filter(r=>this.filters.every(f=>f(r)));
   if(this.action==='insert'||this.action==='upsert'){const value={id:webcrypto.randomUUID(),accepted_at:null,expires_at:new Date(Date.now()+7*86400000).toISOString(),...this.value};tables[this.table].push(value);rows=[value];}
   if(this.action==='delete')tables[this.table]=tables[this.table].filter(r=>!rows.includes(r));
   if(this.action==='update')rows.forEach(r=>Object.assign(r,this.value));
   if(this.n)rows=rows.slice(0,this.n);return {data:single?rows[0]||null:rows.map(r=>this.columns?Object.fromEntries(this.columns.filter(k=>k in r).map(k=>[k,r[k]])):{...r}),error:null};
  }maybeSingle(){return this.run(true);}then(a,b){return this.run().then(a,b);}
 }
 const admin={from:t=>new Query(t),rpc:async(name,args)=>{
  if(name==='schoolpro_take_login_attempt')return {data:rateAllowed,error:null};
  if(name==='schoolpro_set_initial_credential'){tables.schoolpro_initial_credentials.push({user_id:args.p_user,school_id:args.p_school,surname:args.p_surname.toLowerCase(),consumed_at:null,expires_at:new Date(Date.now()+86400000).toISOString()});return {error:null};}
  if(name==='schoolpro_initial_challenge'){const row=tables.schoolpro_initial_credentials.find(x=>x.user_id===args.p_user&&x.surname===args.p_surname.trim().toLowerCase()&&x.consumed_at===null);if(row)tables.schoolpro_account_challenges.push({user_id:args.p_user,token_hash:args.p_hash});return {data:!!row,error:null};}
  if(name==='schoolpro_consume_account_challenge'){const row=tables.schoolpro_initial_credentials.find(x=>x.user_id===args.p_user&&x.consumed_at===null);const challenge=tables.schoolpro_account_challenges.find(x=>x.user_id===args.p_user&&x.token_hash===args.p_hash);const valid=!!row&&!!challenge&&args.p_password.length>=10&&args.p_password.trim().toLowerCase()!==row.surname;if(valid){row.consumed_at='consumed';tables.schoolpro_account_challenges=[];}return {data:valid,error:null};}
  if(name==='schoolpro_accept_access_invitation'){const profile=tables.profiles.find(x=>x.id===args.p_user);const invite=tables.schoolpro_access_invitations.find(x=>x.token_hash===args.p_hash&&x.email===profile?.email&&!x.accepted_at);if(!invite)return {data:false,error:null};if(invite.role==='parent'){for(const id of invite.student_ids){tables.schoolpro_guardian_links.push({school_id:invite.school_id,student_id:id,guardian_user_id:args.p_user});}}else if(!tables.schoolpro_members.some(x=>x.school_id===invite.school_id&&x.user_id===args.p_user)){tables.schoolpro_members.push({school_id:invite.school_id,user_id:args.p_user,role:invite.role});}invite.accepted_at='accepted';return {data:true,error:null};}

  const found=tables.schoolpro_student_activation_challenges.find(r=>r.token_hash===args.p_hash);
  if(found)tables.schoolpro_student_activation_challenges=tables.schoolpro_student_activation_challenges.filter(r=>r.student_id!==found.student_id);
  return {data:found?.student_id||null,error:null};
 },auth:{admin:{createUser:async(input)=>{creates++;const id=creates===1?'created':`created-${creates}`;accounts.set(id,{...input,id});tables.profiles.push({id,email:input.email,status:'active'});return {data:{user:{id}},error:null};},updateUserById:async(id,input)=>{Object.assign(accounts.get(id),input);return {data:{user:accounts.get(id)},error:null};},getUserById:async(id)=>({data:{user:accounts.get(id)},error:null}),deleteUser:async(id)=>{accounts.delete(id);return {error:null};},inviteUserByEmail:async(email)=>{invites++;return {data:{user:{id:'invited'}},error:null};}}}};
 const client={auth:{getUser:async()=>({data:{user:{id:caller}},error:null}),signInWithPassword:async({email,password})=>({data:{session:[...accounts.values()].some(a=>a.email===email&&a.password===password&&(!a.ban_duration||a.ban_duration==='none'))?{access_token:'fixture-access',refresh_token:'fixture-refresh'}:null},error:null})}};
 const source=fs.readFileSync(path,'utf8').replace(/^import .*;\s*$/gm,'');
 const script=ts.transpileModule(source,{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.None}}).outputText;
 vm.runInNewContext(script,{crypto:webcrypto,TextEncoder,Response,createClient:(_url,key)=>key==='service'?admin:client,Deno:{env:{get:k=>k==='SUPABASE_SERVICE_ROLE_KEY'?'service':'anon'},serve:fn=>{handler=fn;}}});
 return {tables,accounts,counts:()=>({invites,creates}),setCaller:id=>{caller=id;},setRateAllowed:value=>{rateAllowed=value;},post:async body=>{const res=await handler(new Request('https://fixture.test',{method:'POST',headers:{authorization:'Bearer fixture','content-type':'application/json','x-forwarded-for':'192.0.2.1'},body:JSON.stringify(body)}));return {status:res.status,data:await res.json()};}};
}
const login=await harness('supabase/functions/schoolpro-student-login/index.ts');
const input={schoolCode:'SCHOOL-A',admissionNumber:'ADM-1',password:'Example'};
let response=await login.post(input);assert.equal(response.data.requiresPasswordChange,true);assert.equal(response.data.session,undefined);assert.equal(login.counts().creates,0);
const challenge=response.data.challenge;
assert.equal((await login.post({...input,challenge})).status,400);
assert.equal((await login.post({...input,challenge:'wrong',password:'A-unique-fixture-password'})).status,401);
response=await login.post({...input,challenge,password:'A-unique-fixture-password'});assert.equal(response.status,200);assert.equal(response.data.session.access_token,'fixture-access');assert.equal(login.tables.schoolpro_students[0].user_id,'created');
assert.equal((await login.post({...input,challenge,password:'A-unique-fixture-password'})).status,401);
assert.equal((await login.post(input)).status,401);
assert.equal((await login.post({...input,password:'A-unique-fixture-password'})).status,200);
assert.equal((await login.post({...input,schoolCode:'OTHER'})).status,401);
login.tables.schoolpro_students.push({...login.tables.schoolpro_students[0],id:'duplicate'});assert.equal((await login.post(input)).status,401);
const invite=await harness('supabase/functions/invite-school-staff/index.ts');
const names={firstName:'Fixture',middleName:'Middle',surname:'Adu'};
assert.equal((await invite.post({schoolId:school,email:'parent@example.test',role:'parent',studentId:'foreign-student',...names})).status,400);assert.equal(invite.counts().invites,0);
response=await invite.post({schoolId:school,email:'parent@example.test',role:'parent',studentId,relationship:'mother',...names});assert.equal(response.status,200);assert.equal(response.data.requiresAcceptance,true);assert.equal(invite.tables.schoolpro_guardian_links.length,0);
const joiningCode=response.data.joiningCode;
invite.setCaller('uninvited');assert.equal((await invite.post({schoolId:school,email:'teacher@example.test',role:'teacher',...names})).status,403);assert.equal(invite.counts().creates,0);
assert.equal((await invite.post({action:'accept',code:joiningCode})).status,400);
invite.setCaller('parent');assert.equal((await invite.post({action:'accept',code:joiningCode})).status,200);assert.equal(invite.tables.schoolpro_guardian_links[0].student_id,studentId);assert.equal((await invite.post({action:'accept',code:joiningCode})).status,400);
invite.setCaller('owner');invite.tables.schoolpro_members.push({school_id:school,user_id:'parent',role:'accountant'});response=await invite.post({schoolId:school,email:'parent@example.test',role:'teacher',...names});assert.equal(response.data.requiresAcceptance,true);assert.equal(invite.tables.schoolpro_members[0].role,'accountant');
response=await invite.post({schoolId:school,email:'new-staff@example.test',role:'teacher',...names});assert.equal(response.status,200);assert.equal(response.data.created,true);assert.equal(invite.counts().invites,0);assert.equal(invite.counts().creates,1);assert.notEqual(invite.accounts.get('created').password,names.surname);assert.equal(invite.accounts.get('created').ban_duration,'876000h');assert.equal(invite.tables.schoolpro_members.find(x=>x.user_id==='created').role,'teacher');
invite.setRateAllowed(false);assert.equal((await invite.post({schoolId:school,email:'another-staff@example.test',role:'teacher',...names})).status,429);assert.equal(invite.counts().creates,1);
const initial=await harness('supabase/functions/schoolpro-account-login/index.ts');
initial.tables.profiles.push({id:'initial',email:'initial@example.test',status:'active'});
initial.accounts.set('initial',{id:'initial',email:'initial@example.test',password:'inaccessible-random-password',ban_duration:'876000h',app_metadata:{schoolpro_initial_login:true}});
initial.tables.schoolpro_initial_credentials.push({user_id:'initial',surname:'adu',consumed_at:null,expires_at:new Date(Date.now()+86400000).toISOString()});
const initialInput={email:'initial@example.test',password:'Adu'};
response=await initial.post(initialInput);assert.equal(response.data.requiresPasswordChange,true);assert.equal(response.data.session,undefined);
const staffChallenge=response.data.challenge;
assert.equal((await initial.post({...initialInput,challenge:staffChallenge,password:'short'})).status,400);
assert.equal((await initial.post({...initialInput,challenge:'wrong',password:'Unique-new-password!'})).status,400);
response=await initial.post({...initialInput,challenge:staffChallenge,password:'Unique-new-password!'});assert.equal(response.status,200);assert.equal(response.data.session.access_token,'fixture-access');assert.equal(initial.accounts.get('initial').ban_duration,'none');assert.equal(initial.accounts.get('initial').app_metadata.schoolpro_initial_login,false);
assert.equal((await initial.post(initialInput)).status,401);assert.equal((await initial.post({...initialInput,password:'Unique-new-password!'})).status,200);assert.equal((await initial.post({...initialInput,challenge:staffChallenge,password:'Unique-new-password!'})).status,401);
initial.setRateAllowed(false);assert.equal((await initial.post(initialInput)).status,429);
console.log('PASS: student and adult first-login sessions require new passwords; outsider/child isolation, existing-account acceptance, role preservation, no email delivery, random inaccessible initial Auth password, activation replay and rate limits.');

const managed=await harness('supabase/functions/invite-school-staff/index.ts');
managed.tables.profiles.push({id:'staff',email:'staff@example.test',status:'active'});
response=await managed.post({schoolId:school,email:'staff@example.test',role:'bursar',...names});assert.equal(response.data.requiresAcceptance,true);const oldCode=response.data.joiningCode;
response=await managed.post({action:'list',schoolId:school});assert.equal(response.status,200);assert.equal(response.data.invitations.length,1);assert.equal(response.data.invitations[0].token_hash,undefined,'Invitation secrets must never appear in list responses');
const id=response.data.invitations[0].id;
managed.setCaller('staff');assert.equal((await managed.post({action:'list',schoolId:school})).status,403);assert.equal((await managed.post({action:'regenerate',schoolId:school,invitationId:id})).status,403);
managed.setCaller('owner');assert.equal((await managed.post({action:'regenerate',schoolId:'foreign-school',invitationId:id})).status,403);
response=await managed.post({action:'regenerate',schoolId:school,invitationId:id});assert.equal(response.status,200);const freshCode=response.data.joiningCode;assert.notEqual(freshCode,oldCode);
managed.setCaller('staff');assert.equal((await managed.post({action:'accept',code:oldCode})).status,400);assert.equal((await managed.post({action:'accept',code:freshCode})).status,200);assert.equal(managed.tables.schoolpro_members[0].role,'bursar');
managed.setCaller('owner');assert.equal((await managed.post({action:'regenerate',schoolId:school,invitationId:id})).status,400);assert.equal((await managed.post({action:'list',schoolId:school})).data.invitations.length,0);
managed.setRateAllowed(false);assert.equal((await managed.post({action:'regenerate',schoolId:school,invitationId:id})).status,429);
console.log('PASS: pending staff persist, leaders-only listing, school-bound regeneration, old-code rejection, bursar acceptance and accepted invitations cannot regenerate');
