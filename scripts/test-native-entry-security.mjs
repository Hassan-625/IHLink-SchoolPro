import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createRequire} from 'node:module';
import vm from 'node:vm';
import ts from 'typescript';
import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
const require=createRequire(import.meta.url);
const school=readFileSync(new URL('../src/lib/nativeEntry.ts',import.meta.url),'utf8').includes('/schoolpro');
const product=school?'schoolpro':'datasub';
const choices=new Map();const localStorage={getItem:key=>choices.get(key)??null,setItem:(key,value)=>choices.set(key,value)};
let user=null,loading=false,path='/'+product,native=true,states=[],cursor=0;
const node=(tag,props,children)=>React.createElement(tag,props,children);
function load(file){
 const output=ts.transpileModule(readFileSync(new URL('../src/'+file,import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,jsx:ts.JsxEmit.ReactJSX,target:ts.ScriptTarget.ES2022}}).outputText;
 const exports={};
 const custom=name=>{
  if(name==='react')return {...React,useEffect:()=>{},useState:initial=>[cursor<states.length?states[cursor++]:typeof initial==='function'?initial():initial,()=>{}]};
  if(name==='react-router-dom')return {useLocation:()=>({pathname:path}),useNavigate:()=>()=>{},Navigate:({to})=>node('div',{'data-redirect':to}),Link:({to,children,className,...props})=>node('a',{href:to,className:typeof className==='string'?className:undefined,...props},children),NavLink:({to,children})=>node('a',{href:to},children)};
  if(name==='@/context/AuthContext')return {useAuth:()=>({user,loading,profile:{id:user?.id,role:'super_admin'}})};
  if(name==='@/lib/nativeAuth')return {isNativeApp:()=>native};
  if(name==='@/lib/nativeEntry')return load('lib/nativeEntry.ts');
  if(name==='@/hooks/useSchoolProContext')return {useSchoolProContext:()=>({role:'proprietor',loading:false})};
  if(name==='@/hooks/useSchoolProPermissions')return {useSchoolProPermissions:()=>({can:()=>true})};
  if(name==='@/components/Logo')return {Logo:()=>node('img',{alt:'IHLink'})};
  if(name==='./MobileBrandPreview')return load('components/MobileBrandPreview.tsx');
  if(name==='./NativeSignedOutHome')return {NativeSignedOutHome:()=>node('div',{},'Welcome to '+product)};
  if(name==='@/lib/supabase')return {supabase:{}};
  if(name==='@/lib/nativeVault')return {securitySupported:true,NativeVault:{}};
  if(name.endsWith('NativeAppSecurity'))return {NativeAppSecurity:()=>node('div',{},'Set app passcode')};
  if(name.endsWith('/Modal'))return {Modal:({open,children})=>open?node('section',{role:'dialog'},children):null};
  if(name.endsWith('/Button'))return {Button:({children})=>node('button',{},children)};
  return require(name);
 };
 vm.runInNewContext(output,{exports,require:custom,console,localStorage});return exports;
}
function render(file,name,values=[],children='AUTH FORM',props={}){states=values;cursor=0;return renderToStaticMarkup(React.createElement(load(file)[name],props,children));}
let html=render('components/NativeAppShell.tsx','NativeAppShell');
assert(html.includes('Welcome to '+product));assert(!html.includes('App navigation'));
path=school?'/schoolpro/student-login':'/signin';
html=render('components/NativeAppShell.tsx','NativeAppShell');assert(html.includes('AUTH FORM'));assert(!html.includes('App navigation'));
path=school?'/schoolpro/results':'/datasub/wallet';
html=render('components/NativeAppShell.tsx','NativeAppShell');assert(html.includes('data-redirect'));assert(!html.includes('AUTH FORM'));
user={id:'staff-account'};html=render('components/NativeAppShell.tsx','NativeAppShell');assert(html.includes('App navigation'));assert(html.includes('AUTH FORM'));
user=null;loading=true;html=render('components/NativeAppShell.tsx','NativeAppShell');assert(html.includes('Opening your account'));assert(!html.includes('AUTH FORM'));
loading=false;native=false;html=render('components/NativeAppShell.tsx','NativeAppShell');assert.equal(html,'AUTH FORM');native=true;
user={id:'administrator-account'};
const promptFile=school?'components/AppSecuritySetup.tsx':'components/DataSubSecuritySetup.tsx';
const promptName=school?'AppSecuritySetup':'DataSubSecuritySetup';
const vault={enabled:false,biometricAvailable:false,biometricEnabled:false};
html=render(promptFile,promptName,school?[vault,false]:[null,vault,false]);assert(html.includes('role="dialog"'),'Administrators and pending wallet checks must not suppress passcode setup');
html=render(promptFile,promptName,school?[{...vault,enabled:true},false]:[true,{...vault,enabled:true},false]);assert(!html.includes('role="dialog"'),'Completed security setup closes the prompt');
user=null;html=render(promptFile,promptName,school?[vault,false]:[false,vault,false]);assert(!html.includes('role="dialog"'),'Never prompt before sign-in');
const entry=load('lib/nativeEntry.ts').signedOutNativeAccess;
assert.equal(entry(school?'/schoolpro/parents':'/datasub/transfer'),'signin');
assert.equal(entry('/auth/update-password'),'public');assert.equal(entry('/register'),'public');
console.log('PASS: signed-out navigation, private deep links, loading, browser layout, admin passcode prompts and completion');

user=null;
for(let index=0;index<3;index++){
 const welcome=render('components/NativeSignedOutHome.tsx','NativeSignedOutHome',[index]);
 assert(welcome.includes('welcome-screen'));assert(welcome.includes('IHLink '+(school?'SchoolPro':'DataSub')));
 assert(welcome.includes('/mobile/'));assert(!welcome.includes('App navigation'));
 if(!school){assert(welcome.includes('/brands/mtn.png'));assert(welcome.includes('/brands/airtel.png'));}
}
let entered='',fingerprint=false;states=[];cursor=0;
const keypad=load('components/AppUnlockScreen.tsx').AppUnlockScreen({pin:'12',busy:false,error:'',biometric:true,onPin:value=>entered=value,onUnlock:value=>fingerprint=value===true,onReset:()=>{}});
function buttons(element){if(!element||typeof element!=='object')return [];return [element,...[element.props?.children].flat(8).flatMap(buttons)];}
const controls=buttons(keypad);
controls.find(e=>e.props?.['aria-label']==='Digit 3').props.onClick();assert.equal(entered,'123');
controls.find(e=>e.props?.['aria-label']==='Delete last digit').props.onClick();assert.equal(entered,'1');
controls.find(e=>e.props?.['aria-label']==='Use fingerprint').props.onClick();assert.equal(fingerprint,true);
console.log('PASS: branded welcome slides and passcode keypad input, deletion and fingerprint action');

user={id:"returning-account"};
const enrollment={enabled:true,biometricAvailable:true,biometricEnabled:false};
html=render('components/NativeAppSecurity.tsx','NativeAppSecurity',[enrollment,'','','','',false],'',{setupOnly:true});
assert(!html.includes('Current app passcode'));assert(!html.includes('Change app passcode'));assert(html.includes('Enable fingerprint'));assert(html.includes('Continue with passcode'));
html=render('components/NativeAppSecurity.tsx','NativeAppSecurity',[enrollment,'','','','',false]);assert(html.includes('Current app passcode'));assert(html.includes('Change app passcode'));
if(!school){html=render(promptFile,promptName,[false,{...vault,enabled:false},false]);assert(!html.includes('Set your wallet transaction PIN'),'Wallet PIN must wait until device security setup finishes');html=render(promptFile,promptName,[false,{...enrollment,biometricEnabled:true},false]);assert(html.includes('Set your wallet transaction PIN'));}
choices.set('ihlink.'+product+'.fingerprint-choice','skipped');html=render(promptFile,promptName,school?[enrollment,false]:[true,enrollment,false]);assert(!html.includes('role="dialog"'),'Optional fingerprint choice must survive subsequent sign-ins');
const auth=readFileSync(new URL('../src/context/AuthContext.tsx',import.meta.url),'utf8');assert(!auth.slice(auth.indexOf('async signOut()')).includes('NativeVault.reset()'),'Ordinary sign-out must preserve device security');
console.log('PASS: setup uses fingerprint step instead of change-passcode form, wallet PIN follows device setup, and fingerprint skip persists');
