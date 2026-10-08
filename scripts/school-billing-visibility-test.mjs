import {build} from 'esbuild';
import assert from 'node:assert/strict';
import {renderToStaticMarkup} from 'react-dom/server';
import {createElement} from 'react';
import {MemoryRouter} from 'react-router-dom';
import {mkdir,rm} from 'node:fs/promises';
const target=new URL('../.billing-test/',import.meta.url);await mkdir(target,{recursive:true});
try{
 for(const role of ['student','parent','teacher','proprietor','administrator','bursar']){
  const out=new URL(role+'.mjs',target);
  await build({stdin:{contents:`export {SchoolProActivationGate} from './src/components/SchoolProActivationGate';export {SchoolProEntitlementGate} from './src/components/SchoolProEntitlementGate';export {SchoolProSubscription} from './src/pages/schoolpro/SchoolProSubscription';`,resolveDir:process.cwd(),loader:'tsx'},outfile:out.pathname,bundle:true,packages:'external',define:{'import.meta.env':'{}'},jsx:'automatic',format:'esm',platform:'node',external:['react','react-dom','react-router-dom'],alias:{'@':new URL('../src',import.meta.url).pathname},plugins:[{name:'isolated-school-context',setup(b){b.onResolve({filter:/hooks\/useSchoolProContext|hooks\/useSchoolProEntitlements|context\/AuthContext/},a=>({path:a.path,namespace:'fixture'}));b.onLoad({filter:/.*/,namespace:'fixture'},a=>({loader:'js',contents:a.path.includes('useSchoolProContext')?`export const useSchoolProContext=()=>({role:${JSON.stringify(role)},schoolId:'fixture',loading:false,error:null});`:a.path.includes('useSchoolProEntitlements')?`export const useSchoolProEntitlements=()=>({entitlements:{active:false},loading:false,error:null});`:`export const useAuth=()=>({profile:{role:'customer'},user:null});`}))}}]});
  const m=await import(out.href);const render=(C,props={})=>renderToStaticMarkup(createElement(MemoryRouter,null,createElement(C,props,'protected-content')));
  const activation=render(m.SchoolProActivationGate),feature=render(m.SchoolProEntitlementGate,{feature:'cbt'});
  const billing=['proprietor','administrator','bursar'].includes(role);
  assert.equal(activation.includes('/schoolpro/subscription'),billing,role+' activation billing visibility');
  assert.equal(feature.includes('/schoolpro/subscription'),billing,role+' module billing visibility');
  assert(!feature.includes('Super Admin')&&!activation.includes('Control Center'),role+' customer technical prose');
  if(!billing){const sub=render(m.SchoolProSubscription);assert(!sub.includes('Subscribe / Renew')&&!sub.includes('Annual subscription'),role+' direct billing URL');assert(feature.includes(`/schoolpro/${role}-dashboard`),role+' own dashboard');}
 }
 console.log('PASS six school roles: billing controls, direct URL denial, own dashboards and customer-facing messages');
}finally{await rm(target,{recursive:true,force:true});}
