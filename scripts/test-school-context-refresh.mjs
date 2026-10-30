import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
let user={id:'owner'},search='',pathname='/schoolpro/library',profileRole='super_admin',cursor=0,effects=[],states=[];
const selected=new Map([['ihlink_schoolpro_workspace_owner','school']]);
const source=ts.transpileModule(readFileSync('src/hooks/useSchoolProContext.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText;
const contextSource=readFileSync('src/hooks/useSchoolProContext.ts','utf8');
assert.ok(contextSource.includes("const selected=profile?.role==='super_admin'?null:"),'Platform Super Admin must not inherit a workspace from URL or local storage.');
assert.ok(!contextSource.includes("if(profile?.role==='super_admin'&&selected)"),'Platform Super Admin must not attach to a selected school workspace.');
const never=new Promise(()=>{}),query={select(){return this},eq(){return this},order(){return this},limit(){return this},maybeSingle(){return never}};
const cacheExports={};vm.runInNewContext(ts.transpileModule(readFileSync('src/lib/schoolAccessCache.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,{exports:cacheExports,window:{addEventListener(){}},Date,Map,Promise});
const exports={};vm.runInNewContext(source,{exports,URLSearchParams,document:{visibilityState:'visible'},window:{addEventListener(){},removeEventListener(){}},localStorage:{getItem:key=>selected.get(key)||null,setItem:(k,v)=>selected.set(k,v)},require(name){if(name==='@/lib/schoolAccessCache')return cacheExports;if(name==='react')return{useState:initial=>{const i=cursor++;if(states[i]===undefined)states[i]=typeof initial==='function'?initial():initial;return[states[i],next=>{states[i]=typeof next==='function'?next(states[i]):next}]},useEffect:effect=>effects.push(effect)};if(name==='react-router-dom')return{useLocation:()=>({search,pathname})};if(name==='@/context/AuthContext')return{useAuth:()=>({user,profile:{role:profileRole},loading:false})};return{supabase:{from:()=>query}}}});
function render(){cursor=0;effects=[];return exports.useSchoolProContext()}
states=[0,{key:'owner:school:general',schoolId:'school',schoolName:'Fixture',role:'Proprietor',loading:false,error:null}];render();effects.at(-1)();assert.equal(states[1].schoolId,'school');assert.equal(states[1].loading,false,'Returning from a file/print dialog must not blank the resolved workspace');
search='?school_id=11111111-1111-4111-8111-111111111111';render();effects.at(-1)();assert.equal(states[1].schoolId,null,'Switching schools must discard the previous workspace');
user={id:'different-user'};search='';render();effects.at(-1)();assert.equal(states[1].schoolId,null,'Account changes must never retain another account workspace');
console.log('PASS: same-workspace focus refresh preserves state; school and account changes clear it.');

cacheExports.clearSchoolAccess();
user={id:'parent'};search='';selected.set('ihlink_schoolpro_workspace_parent','school');selected.set('ihlink_schoolpro_portal_parent','parent');
states=[];cursor=0;effects=[];
pathname='/schoolpro/invoices/example';profileRole='customer';
cacheExports.saveSchoolAccess('context:parent:school:parent',{schoolId:'school',schoolName:'Fixture',role:'parent',loading:false,error:null});
assert.equal(render().role,'parent','Opening an invoice must retain the verified parent identity');
pathname='/schoolpro/transcript';assert.equal(render().role,'parent','Opening a transcript must retain the verified parent identity');
user={id:'another-parent'};assert.equal(render().schoolId,null,'Another account must not reuse the parent workspace cache');
console.log('PASS: parent invoice/transcript navigation retains the verified portal without crossing accounts.');
user={id:'teacher'};selected.set('ihlink_schoolpro_workspace_teacher','school');selected.set('ihlink_schoolpro_portal_teacher','staff');pathname='/schoolpro/results';cacheExports.saveSchoolAccess('context:teacher:school:staff',{schoolId:'school',schoolName:'Fixture',role:'teacher',loading:false,error:null});assert.equal(render().role,'teacher','Staff module navigation must preserve the verified staff context');pathname='/schoolpro/attendance';assert.equal(render().role,'teacher');console.log('PASS: staff module navigation reuses the verified staff workspace.');
