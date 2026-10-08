import fs from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
import assert from 'node:assert/strict';
import {webcrypto} from 'node:crypto';
const school='school-a',studentId='student-a';
function fixture(){return {schoolpro_schools:[{id:school,code:'SCHOOL-A',owner_id:'owner'}],schoolpro_students:[{id:studentId,school_id:school,admission_number:'ADM-1',first_name:'Fixture',last_name:'Example',user_id:null,status:'active'}],profiles:[{id:'owner',email:'owner@example.test',status:'active'},{id:'parent',email:'parent@example.test',status:'active'}],schoolpro_members:[],schoolpro_guardian_links:[],schoolpro_student_activation_challenges:[]};}
async function harness(path){
 let handler;const tables=fixture();const accounts=new Map();let invites=0,creates=0,caller='owner';
 class Query{
  constructor(table){this.table=table;this.filters=[];this.action='read';}
  select(){return this;}eq(k,v){this.filters.push(r=>r[k]===v);return this;}is(k,v){return this.eq(k,v);}limit(n){this.n=n;return this;}
  insert(v){this.action='insert';this.value=v;return this;}upsert(v){this.action='upsert';this.value=v;return this;}update(v){this.action='update';this.value=v;return this;}
  async run(single=false){let rows=(tables[this.table]||[]).filter(r=>this.filters.every(f=>f(r)));
   if(this.action==='insert'||this.action==='upsert'){tables[this.table].push({...this.value});rows=[this.value];}
   if(this.action==='update')rows.forEach(r=>Object.assign(r,this.value));
   if(this.n)rows=rows.slice(0,this.n);return {data:single?rows[0]||null:rows.map(r=>({...r})),error:null};
  }maybeSingle(){return this.run(true);}then(a,b){return this.run().then(a,b);}
 }
 const admin={from:t=>new Query(t),rpc:async(name,args)=>{
  if(name==='schoolpro_take_login_attempt')return {data:true,error:null};
  const found=tables.schoolpro_student_activation_challenges.find(r=>r.token_hash===args.p_hash);
  if(found)tables.schoolpro_student_activation_challenges=tables.schoolpro_student_activation_challenges.filter(r=>r.student_id!==found.student_id);
  return {data:found?.student_id||null,error:null};
 },auth:{admin:{createUser:async({email,password})=>{creates++;accounts.set('created',{email,password});return {data:{user:{id:'created'}},error:null};},getUserById:async(id)=>({data:{user:accounts.get(id)},error:null}),deleteUser:async(id)=>{accounts.delete(id);return {error:null};},inviteUserByEmail:async(email)=>{invites++;return {data:{user:{id:'invited'}},error:null};}}}};
 const client={auth:{getUser:async()=>({data:{user:{id:caller}},error:null}),signInWithPassword:async({email,password})=>({data:{session:[...accounts.values()].some(a=>a.email===email&&a.password===password)?{access_token:'fixture-access',refresh_token:'fixture-refresh'}:null},error:null})}};
 const source=fs.readFileSync(path,'utf8').replace(/^import .*;\s*$/gm,'');
 const script=ts.transpileModule(source,{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.None}}).outputText;
 vm.runInNewContext(script,{crypto:webcrypto,TextEncoder,Response,createClient:(_url,key)=>key==='service'?admin:client,Deno:{env:{get:k=>k==='SUPABASE_SERVICE_ROLE_KEY'?'service':'anon'},serve:fn=>{handler=fn;}}});
 return {tables,accounts,counts:()=>({invites,creates}),setCaller:id=>{caller=id;},post:async body=>{const res=await handler(new Request('https://fixture.test',{method:'POST',headers:{authorization:'Bearer fixture','content-type':'application/json','x-forwarded-for':'192.0.2.1'},body:JSON.stringify(body)}));return {status:res.status,data:await res.json()};}};
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
assert.equal((await invite.post({schoolId:school,email:'parent@example.test',role:'parent',studentId:'foreign-student'})).status,400);assert.equal(invite.counts().invites,0);
response=await invite.post({schoolId:school,email:'parent@example.test',role:'parent',studentId,relationship:'mother'});assert.equal(response.status,200);assert.equal(invite.tables.schoolpro_guardian_links[0].student_id,studentId);
invite.setCaller('uninvited');assert.equal((await invite.post({schoolId:school,email:'teacher@example.test',role:'teacher'})).status,403);assert.equal(invite.counts().invites,0);
invite.setCaller('owner');invite.tables.schoolpro_members.push({school_id:school,user_id:'parent',role:'accountant'});assert.equal((await invite.post({schoolId:school,email:'parent@example.test',role:'teacher'})).status,409);assert.equal(invite.tables.schoolpro_members[0].role,'accountant');
console.log('PASS: student activation has no initial session; password choice, replay rejection, subsequent login, school/duplicate isolation; guardian scope, outsider denial, existing-role preservation.');
