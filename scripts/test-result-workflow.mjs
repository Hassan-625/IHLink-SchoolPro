import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createRequire} from 'node:module';
import vm from 'node:vm';
import ts from 'typescript';
import React from 'react';
const require=createRequire(import.meta.url);
const source=ts.transpileModule(readFileSync('src/pages/schoolpro/SchoolProBroadsheet.tsx','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,jsx:ts.JsxEmit.ReactJSX}}).outputText;
const records=[{id:'existing',student_id:'one',status:'published',locked:true},{id:'new',student_id:'two',status:'draft',locked:false},{id:'outside',student_id:'other-school',status:'draft',locked:false}];
let states,cursor,messages;
const db={from(){const filters=[];return{select(){return this},eq(key,value){filters.push([key,value]);return this},in(key,value){filters.push([key,value]);return this},then(resolve){resolve({data:records.filter(r=>r.student_id!=='other-school'&&filters.every(([key,value])=>key==='school_id'||key==='term'||key==='session'||(Array.isArray(value)?value.includes(r[key]):r[key]===value))),error:null})}}},async rpc(name,params){if(name==='review_schoolpro_result'){const r=records.find(r=>r.id===params.p_result);assert.equal(r.status,'draft');r.status='approved';return{error:null}}if(name==='publish_schoolpro_class_results'){let count=0;for(const r of records.filter(r=>r.student_id!=='other-school'&&r.status==='approved')){r.status='published';r.locked=true;count++}return{data:count,error:null}}return{data:{rows:[{student_id:'one'},{student_id:'two'}],subjects:[]},error:null}}};
const exports={};vm.runInNewContext(source,{exports,confirm:()=>true,console,require(name){if(name==='react')return{...React,useEffect:()=>{},useState:()=>{const i=cursor++;return[states[i],value=>{if(i===6)messages.push(value)}]}};if(name==='react-router-dom')return{Link:'a',useNavigate:()=>()=>{}};if(name==='@/hooks/useSchoolProContext')return{useSchoolProContext:()=>({schoolId:'school',schoolName:'Fixture',role:'proprietor'})};if(name==='@/lib/supabase')return{supabase:db};if(name==='./schoolShared')return{schoolSections:[]};if(name.startsWith('@/lib/'))return{schoolFileName:()=>"Fixture.xlsx"};if(name.startsWith('@/components/'))return new Proxy({},{get:(_,key)=>String(key)});return require(name)}});
function controls(node){if(!node||typeof node!=='object')return[];return[node,...[node.props?.children].flat(10).flatMap(controls)]}
function render(){cursor=0;messages=[];states=[[], 'class', 'First Term','2026/2027',[{student_id:'one'},{student_id:'two'}],[], '',false,['two']];return controls(exports.SchoolProBroadsheet())}
function button(nodes,label){return nodes.find(n=>n.type==='Button'&&n.props.children===label)}
await button(render(),'Approve selected scores').props.onClick();await new Promise(r=>setTimeout(r,0));assert.equal(records[0].status,'published');assert.equal(records[1].status,'approved');assert.equal(records[2].status,'draft');assert(messages.some(m=>m.includes('1 score records approved')));
await button(render(),'Publish class results').props.onClick();await new Promise(r=>setTimeout(r,0));assert.equal(records[1].status,'published');assert.equal(records[0].status,'published');assert.equal(records[2].status,'draft');
await button(render(),'Publish class results').props.onClick();await new Promise(r=>setTimeout(r,0));assert(messages.some(m=>m.includes('No approved scores')));assert.equal(records[0].locked,true);
console.log('PASS: selected draft review, preservation of existing published pupil records, class publication and useful repeat-publication message. Synthetic fixtures.');
