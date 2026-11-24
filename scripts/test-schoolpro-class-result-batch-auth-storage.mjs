import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import ExcelJS from "exceljs";
import { createClient } from "@supabase/supabase-js";

const url=process.env.API_URL??process.env.SUPABASE_URL;
const anonKey=process.env.ANON_KEY??process.env.SUPABASE_ANON_KEY;
const serviceKey=process.env.SERVICE_ROLE_KEY??process.env.SUPABASE_SERVICE_ROLE_KEY;
for(const [k,v] of Object.entries({url,anonKey,serviceKey}))assert(v,`Missing local Supabase ${k}`);
const admin=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
const email=`batch-${randomUUID()}@example.invalid`,password=`Local-test-${randomUUID()}-Aa9!`;
const ids={school:randomUUID(),member:randomUUID(),class:randomUUID(),student:randomUUID(),template:randomUUID(),assignment:randomUUID()};
const config={sheet:"Results"},mappings={subjectRows:[]},formula={engine:"hot-formula-parser",engineVersion:"4.0.0",formulaCount:0,calculationMode:"same-sheet-dependency-graph"};
const bucket="schoolpro-class-result-batches",uploaded=[];let userId,batchId;
async function ok(p,label){const r=await p;if(r.error)throw new Error(label+": "+r.error.message);return r.data;}
async function workbook(label){const w=new ExcelJS.Workbook();w.addWorksheet("Results").getCell("A1").value=label;return Buffer.from(await w.xlsx.writeBuffer());}
try{
 const auth=await ok(admin.auth.admin.createUser({email,password,email_confirm:true}),"Create Auth fixture");userId=auth.user.id;
 await ok(admin.from("profiles").update({status:"active",role:"customer"}).eq("id",userId),"Activate profile");
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
 assert.equal(await ok(reloaded.rpc("schoolpro_review_class_result_batch_student",{p_batch_id:batchId,p_student_id:ids.student,p_decision:"rejected",p_output_id:null}),"Persist rejection"),"needs_attention");
 const finalBatch=await ok(reloaded.from("schoolpro_class_result_batches").select("status").eq("id",batchId).single(),"Reload final batch");
 const finalReview=await ok(reloaded.from("schoolpro_class_result_batch_reviews").select("review_status,reviewed_by").eq("batch_id",batchId).single(),"Reload final review");
 assert.equal(finalBatch.status,"needs_attention");assert.equal(finalReview.review_status,"rejected");assert.equal(finalReview.reviewed_by,userId);
 console.log("PASS: real Supabase Auth, XLSX Storage uploads, ready transition, fresh-session batch/queue reload, download and persisted rejection.");
}finally{
 if(userId){try{if(uploaded.length)await admin.storage.from(bucket).remove(uploaded);}catch{}try{await admin.from("schoolpro_schools").delete().eq("id",ids.school);}catch{}try{await admin.auth.admin.deleteUser(userId);}catch{}}
}
