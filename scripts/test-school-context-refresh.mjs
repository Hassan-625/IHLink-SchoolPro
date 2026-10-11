import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import ts from 'typescript';
let user={id:'owner'},search='',cursor=0,effects=[],states=[];
const selected=new Map([['ihlink_schoolpro_workspace_owner','school']]);
const source=ts.transpileModule(readFileSync('src/hooks/useSchoolProContext.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText;
const never=new Promise(()=>{}),query={select(){return this},eq(){return this},order(){return this},limit(){return this},maybeSingle(){return never}};
const exports={};vm.runInNewContext(source,{exports,URLSearchParams,document:{visibilityState:'visible'},window:{addEventListener(){},removeEventListener(){}},localStorage:{getItem:key=>selected.get(key)||null,setItem:(k,v)=>selected.set(k,v)},require(name){if(name==='react')return{useState:initial=>{const i=cursor++;if(states[i]===undefined)states[i]=typeof initial==='function'?initial():initial;return[states[i],next=>{states[i]=typeof next==='function'?next(states[i]):next}]},useEffect:effect=>effects.push(effect)};if(name==='react-router-dom')return{useLocation:()=>({search})};if(name==='@/context/AuthContext')return{useAuth:()=>({user,profile:{role:'super_admin'},loading:false})};return{supabase:{from:()=>query}}}});
function render(){cursor=0;effects=[];return exports.useSchoolProContext()}
states=[0,{key:'owner:school',schoolId:'school',schoolName:'Fixture',role:'Proprietor',loading:false,error:null}];render();effects.at(-1)();assert.equal(states[1].schoolId,'school');assert.equal(states[1].loading,false,'Returning from a file/print dialog must not blank the resolved workspace');
search='?school_id=11111111-1111-4111-8111-111111111111';render();effects.at(-1)();assert.equal(states[1].schoolId,null,'Switching schools must discard the previous workspace');
user={id:'different-user'};search='';render();effects.at(-1)();assert.equal(states[1].schoolId,null,'Account changes must never retain another account workspace');
console.log('PASS: same-workspace focus refresh preserves state; school and account changes clear it.');
