import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import ExcelJS from "exceljs";
import { chromium } from "playwright";
import { spawn } from "node:child_process";
import { createClient } from "@supabase/supabase-js";

const url=process.env.API_URL??process.env.SUPABASE_URL;
const anonKey=process.env.ANON_KEY??process.env.SUPABASE_ANON_KEY;
const serviceKey=process.env.SERVICE_ROLE_KEY??process.env.SUPABASE_SERVICE_ROLE_KEY;
for(const [k,v] of Object.entries({url,anonKey,serviceKey}))assert(v,`Missing local Supabase ${k}`);
const admin=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
const email=`batch-${randomUUID()}@example.invalid`,password=`Local-test-${randomUUID()}-Aa9!`;
const ids={school:randomUUID(),member:randomUUID(),class:randomUUID(),student:randomUUID(),template:randomUUID(),assignment:randomUUID()};
const config={sheet:"Results"},mappings={subjectRows:[]},formula={engine:"hot-formula-parser",engineVersion:"4.0.0",formulaCount:0,calculationMode:"same-sheet-dependency-graph"};
const bucket="schoolpro-class-result-batches",uploaded=[];let userId,batchId,server,browser;
async function ok(p,label){const r=await p;if(r.error)throw new Error(label+": "+r.error.message);return r.data;}
async function workbook(label){const w=new ExcelJS.Workbook();w.addWorksheet("Results").getCell("A1").value=label;return Buffer.from(await w.xlsx.writeBuffer());}
try{
 const auth=await ok(admin.auth.admin.createUser({email,password,email_confirm:true}),"Create Auth fixture");userId=auth.user.id;
 await ok(admin.from("profiles").upsert({id:userId,email,status:"active",role:"customer"}),"Create active fixture profile");
 await ok(admin.from("schoolpro_schools").insert({id:ids.school,owner_id:userId,name:"Disposable Batch Integration School",code:"BATCH"+ids.school.replaceAll("-","").slice(0,16),status:"active"}),"Create school");
 await ok(admin.from("schoolpro_subscriptions").insert({school_id:ids.school,tier:"standard",billing_cycle:"termly",status:"active",renews_at:new Date(Date.now()+90*86400000).toISOString()}),"Create subscription");
 await ok(admin.from("schoolpro_members").insert({id:ids.member,school_id:ids.school,user_id:userId,role:"teacher",status:"active",employment_status:"active"}),"Create staff");
 await ok(admin.from("schoolpro_classes").insert({id:ids.class,school_id:ids.school,name:"Batch Fixture Class",level:"primary",form_teacher_id:ids.member}),"Create class");
 await ok(admin.from("schoolpro_students").insert({id:ids.student,school_id:ids.school,admission_number:"B"+ids.student.slice(0,10),first_name:"Amina",last_name:"Fixture",class_name:"Batch Fixture Class",class_id:ids.class}),"Create student");
 await ok(admin.from("schoolpro_enrollment_history").insert({school_id:ids.school,student_id:ids.student,session:"2026/2027",class_id:ids.class,class_name:"Batch Fixture Class",section:"Primary",status:"active"}),"Create enrollment");
 await ok(admin.from("schoolpro_result_template_library").insert({id:ids.template,school_id:ids.school,name:"Batch Integration Template",storage_path:ids.school+"/templates/batch.xlsx",sheet_name:"Results",template_config:config,created_by:userId,updated_by:userId}),"Create template");
 const a=await ok(admin.from("schoolpro_result_template_assignments").insert({id:ids.assignment,school_id:ids.school,class_id:ids.class,term:"First Term",session:"2026/2027",template_name:"Batch Integration Template",template_config:config,subject_row_mappings:mappings,updated_by:userId,template_id:ids.template}).select("id,updated_at,template_id,template_config,subject_row_mappings").single(),"Assign template");
 const client=createClient(url,anonKey,{auth:{persistSession:false,autoRefreshToken:false}});
 await ok(client.auth.signInWithPassword({email,password}),"Auth sign-in");
 batchId=await ok(client.rpc("schoolpro_create_class_result_batch",{p_school:ids.school,p_class:ids.class,p_term:"First Term",p_session:"2026/2027",p_template_assignment_id:a.id,p_template_id:a.template_id,p_template_assignment_updated_at:a.updated_at,p_template_config_snapshot:a.template_config,p_subject_row_mappings_snapshot:a.subject_row_mappings,p_formula_calculation_snapshot:formula,p_students:[{student_id:ids.student,student_order:1}]}),"Create batch");
 const register=ids.school+"/"+ids.class+"/"+batchId+"/workbook.xlsx",studentPath=ids.school+"/"+ids.class+"/"+batchId+"/students/"+ids.student+".xlsx";
 await ok(client.storage.from(bucket).upload(register,await workbook("Class register"),{contentType:"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}),"Upload register");uploaded.push(register);
 await ok(client.storage.from(bucket).upload(studentPath,await workbook("Amina Fixture"),{contentType:"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}),"Upload student workbook");uploaded.push(studentPath);
 assert.equal(await ok(client.rpc("schoolpro_mark_class_result_batch_ready",{p_batch_id:batchId}),"Mark ready"),"prepared");
 await ok(client.auth.signOut(),"Sign out for simulated reload");
 const reloaded=createClient(url,anonKey,{auth:{persistSession:false,autoRefreshToken:false}});
 await ok(reloaded.auth.signInWithPassword({email,password}),"Re-authenticate after reload");
 const b=await ok(reloaded.from("schoolpro_class_result_batches").select("id,status,expected_student_count").eq("id",batchId).single(),"Reload batch");
 assert.equal(b.status,"prepared");assert.equal(b.expected_student_count,1);
 const q=await ok(reloaded.from("schoolpro_class_result_batch_reviews").select("student_id,student_order,student_storage_path,review_status").eq("batch_id",batchId),"Reload review queue");
 assert.equal(q.length,1);assert.equal(q[0].student_id,ids.student);assert.equal(q[0].review_status,"pending");
 const file=await ok(reloaded.storage.from(bucket).download(studentPath),"Download workbook after reload");assert(file.size>100);
 const browserAuth=createClient(url,anonKey,{auth:{persistSession:true,autoRefreshToken:false}});
 await ok(browserAuth.auth.signInWithPassword({email,password}),"Create browser session");
 const {data:{session:browserSession}}=await browserAuth.auth.getSession();
 assert(browserSession,"Browser session was not created");
 const port=Number(process.env.SCHOOLPRO_E2E_PORT||5174);
 server=spawn("node",["node_modules/vite/bin/vite.js","--host","127.0.0.1","--port",String(port),"--strictPort"],{
  stdio:"ignore",
  env:{...process.env,VITE_SUPABASE_URL:url,VITE_SUPABASE_ANON_KEY:anonKey}
 });
 let ready=false;
 for(let i=0;i<120;i++){try{if((await fetch(`http://127.0.0.1:${port}/`)).ok){ready=true;break;}}catch{}await new Promise(resolve=>setTimeout(resolve,250));}
 assert(ready,"SchoolPro Vite server did not become ready");
 browser=await chromium.launch({headless:true});
 const page=await browser.newPage();
 await page.addInitScript(({key,session})=>{localStorage.setItem(key,JSON.stringify(session));},{key:browserAuth.auth.storageKey,session:browserSession});
 await page.goto(`http://127.0.0.1:${port}/schoolpro/result-templates`);
 await page.getByRole("heading",{name:"Custom Excel Results"}).waitFor({timeout:30000});
 await page.getByLabel("Working academic session",{exact:true}).selectOption({label:"2026/2027"});
 await page.getByLabel("Academic session",{exact:true}).selectOption({label:"2026/2027"});
 await page.getByLabel("School section").selectOption({label:"Primary"});
 await page.getByLabel("School class").selectOption({label:"Batch Fixture Class"});
 const studentSelect=page.locator("select").filter({hasText:"Amina Fixture"}).first();
 await studentSelect.waitFor({timeout:30000});
 await studentSelect.selectOption(ids.student);
 await page.getByRole("button",{name:"Resume saved class batch"}).click();
 await page.getByRole("heading",{name:"Review each student workbook before finalizing"}).waitFor({timeout:30000});
 assert.equal(await page.getByTestId("batch-review-item").count(),1,"The routed page did not restore the persisted student review");
 await page.getByRole("button",{name:"Reject Amina Fixture"}).click();
 await page.getByText("Student review was rejected and recorded.",{exact:false}).waitFor({timeout:30000});
 const finalBatch=await ok(reloaded.from("schoolpro_class_result_batches").select("status").eq("id",batchId).single(),"Reload UI-reviewed batch");
 const finalReview=await ok(reloaded.from("schoolpro_class_result_batch_reviews").select("review_status,reviewed_by").eq("batch_id",batchId).single(),"Reload UI-reviewed review");
 assert.equal(finalBatch.status,"needs_attention");assert.equal(finalReview.review_status,"rejected");assert.equal(finalReview.reviewed_by,userId);
 console.log("PASS: authenticated Supabase batch creation, private XLSX Storage, fresh-session reload, and real routed SchoolPro Results-template resume/reject UI with persisted review state.");
}finally{
 await browser?.close();server?.kill();
 if(userId){try{if(uploaded.length)await admin.storage.from(bucket).remove(uploaded);}catch{}try{await admin.from("schoolpro_schools").delete().eq("id",ids.school);}catch{}try{await admin.auth.admin.deleteUser(userId);}catch{}}
}
