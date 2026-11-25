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
const ids={school:randomUUID(),member:randomUUID(),class:randomUUID(),student:randomUUID(),subject:randomUUID(),template:randomUUID(),assignment:randomUUID()};
// Explicit empty media anchors prevent application defaults from colliding with fixture input/result cells.
const config={name:"Batch Integration Template",sheet_name:"Results",storage_path:"",start_row:10,field_cells:{student_name:"A1",admission_number:"A2",class_name:"A3",term:"A4",session:"A5"},columns:{subject:"A",total:"G",grade:"H",status:""},component_columns:{assignment_1:"B",assignment_2:"C",test_1:"D",test_2:"E",exam:"F"},custom_fields:[],logo_cell:"",photo_cell:"",principal_signature_cell:"",teacher_signature_cell:"",qr_cell:""},mappings={},formula={engine:"hot-formula-parser",engineVersion:"4.0.0",formulaCount:0,calculationMode:"same-sheet-dependency-graph"};
const bucket="schoolpro-class-result-batches",batchPaths=[],officialPaths=[];let userId,batchId,server,browser;
async function ok(p,label){const r=await p;if(r.error)throw new Error(label+": "+r.error.message);return r.data;}
async function workbook(label){const w=new ExcelJS.Workbook();w.addWorksheet("Results").getCell("A1").value=label;return Buffer.from(await w.xlsx.writeBuffer());}
try{
 const buckets=await ok(admin.storage.listBuckets(),"List fixture Storage buckets");
 if(!buckets.some(bucket=>bucket.name==="school-result-templates")) await ok(admin.storage.createBucket("school-result-templates",{public:false,fileSizeLimit:52428800,allowedMimeTypes:["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]}),"Create private result-template bucket");
 const auth=await ok(admin.auth.admin.createUser({email,password,email_confirm:true}),"Create Auth fixture");userId=auth.user.id;
 await ok(admin.from("profiles").upsert({id:userId,email,status:"active",role:"customer"}),"Create active fixture profile");
 await ok(admin.from("schoolpro_schools").insert({id:ids.school,owner_id:userId,name:"Disposable Batch Integration School",code:"BATCH"+ids.school.replaceAll("-","").slice(0,16),status:"active"}),"Create school");
 await ok(admin.from("schoolpro_subscriptions").insert({school_id:ids.school,tier:"standard",billing_cycle:"termly",status:"active",renews_at:new Date(Date.now()+90*86400000).toISOString()}),"Create subscription");
 await ok(admin.from("schoolpro_members").insert({id:ids.member,school_id:ids.school,user_id:userId,role:"teacher",status:"active",employment_status:"active"}),"Create staff");
 await ok(admin.from("schoolpro_classes").insert({id:ids.class,school_id:ids.school,name:"Batch Fixture Class",level:"primary",form_teacher_id:ids.member}),"Create class");
 await ok(admin.from("schoolpro_subjects").insert({id:ids.subject,school_id:ids.school,name:"Mathematics",code:"MTH",class_name:"Primary",is_catalogue_entry:true}),"Create canonical subject");
 await ok(admin.from("schoolpro_subject_assignments").insert({school_id:ids.school,class_id:ids.class,subject_id:ids.subject,teacher_member_id:ids.member,session:"2026/2027"}),"Allocate subject to fixture class");
 const scheme=await ok(admin.from("schoolpro_assessment_schemes").insert({school_id:ids.school,name:"Batch E2E Assessment Scheme",school_level:"nursery_primary",components:[{key:"assignment_1",label:"1st CA Assignment",maxScore:10},{key:"assignment_2",label:"2nd CA Assignment",maxScore:10},{key:"test_1",label:"1st CA Test",maxScore:10},{key:"test_2",label:"2nd CA Test",maxScore:10},{key:"exam",label:"Examination",maxScore:60}],is_default:true}).select("id,components").single(),"Create fixture assessment scheme");
 mappings[ids.subject]=10;
 const templatePath=ids.school+"/templates/batch.xlsx";
 await ok(admin.storage.from("school-result-templates").upload(templatePath,await workbook("School result template"),{contentType:"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}),"Upload private result template");
 config.storage_path=templatePath;
 await ok(admin.from("schoolpro_students").insert({id:ids.student,school_id:ids.school,admission_number:"B"+ids.student.slice(0,10),first_name:"Amina",last_name:"Fixture",class_name:"Batch Fixture Class",class_id:ids.class}),"Create student");
 await ok(admin.from("schoolpro_enrollment_history").insert({school_id:ids.school,student_id:ids.student,session:"2026/2027",class_id:ids.class,class_name:"Batch Fixture Class",section:"Primary",status:"active"}),"Create enrollment");
 await ok(admin.from("schoolpro_result_template_library").insert({id:ids.template,school_id:ids.school,name:"Batch Integration Template",storage_path:templatePath,sheet_name:"Results",template_config:config,created_by:userId,updated_by:userId}),"Create template");
 await ok(admin.from("schoolpro_result_template_section_mappings").insert({school_id:ids.school,template_id:ids.template,section_key:"primary",mapped_by:userId}),"Map template to Primary section");
 const a=await ok(admin.from("schoolpro_result_template_assignments").insert({id:ids.assignment,school_id:ids.school,class_id:ids.class,term:"First Term",session:"2026/2027",template_name:"Batch Integration Template",template_config:config,subject_row_mappings:mappings,updated_by:userId,template_id:ids.template}).select("id,updated_at,template_id,template_config,subject_row_mappings").single(),"Assign template");
 const resultRow={school_id:ids.school,student_id:ids.student,subject_id:ids.subject,term:"First Term",session:"2026/2027",total_score:82,status:"published",assessment_scheme_id:scheme.id,assessment_scores:{assignment_1:9,assignment_2:9,test_1:8,test_2:8,exam:48}};
 const browserAuth=createClient(url,anonKey,{auth:{persistSession:true,autoRefreshToken:false}});
 await ok(browserAuth.auth.signInWithPassword({email,password}),"Create browser session");
 const {data:{session:browserSession}}=await browserAuth.auth.getSession();
 assert(browserSession,"Browser session was not created");
 const storedTemplateObjects=await ok(admin.storage.from("school-result-templates").list(ids.school+"/templates"),"Verify uploaded private template object");
 assert(storedTemplateObjects.some(item=>item.name==="batch.xlsx"),"Service-role Storage listing did not find the uploaded template object");
 const authenticatedIdentity=await ok(browserAuth.auth.getUser(),"Resolve authenticated Storage fixture identity");
 assert.equal(authenticatedIdentity.user.id,userId,"Authenticated Storage client resolved a different fixture user");
 const authenticatedSchool=await ok(browserAuth.from("schoolpro_schools").select("id,owner_id").eq("id",ids.school).maybeSingle(),"Verify authenticated fixture school visibility");
 assert(authenticatedSchool,"Authenticated fixture user cannot read its own school row");
 assert.equal(authenticatedSchool.owner_id,userId,"Fixture school owner does not match the authenticated user");
 const authenticatedTemplate=await ok(browserAuth.storage.from("school-result-templates").download(templatePath),"Verify authenticated school-folder template download");
 assert(authenticatedTemplate.size>100,"Authenticated fixture template download was empty");
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
 const browserErrors=[];
 page.on("console",message=>{if(message.type()==="error")browserErrors.push(message.text());});
 page.on("response",async response=>{if(response.status()>=400){let body="";try{body=(await response.text()).slice(0,1200);}catch{}browserErrors.push("HTTP "+response.status()+" "+response.url()+" "+body);}});
 await page.addInitScript(({key,session})=>{localStorage.setItem(key,JSON.stringify(session));},{key:browserAuth.auth.storageKey,session:browserSession});
 await page.route(/\/rest\/v1\/schoolpro_results\?/,route=>route.request().method()==="GET"?route.fulfill({status:200,contentType:"application/json",body:JSON.stringify([resultRow])}):route.continue());
 await page.route("**/rest/v1/rpc/schoolpro_printable_result",route=>route.fulfill({status:200,contentType:"application/json",body:JSON.stringify([resultRow])}));
 await page.route("**/functions/v1/schoolpro-issue-result-verification",route=>route.fulfill({status:200,contentType:"application/json",body:JSON.stringify({verification_code:"LOCAL-E2E-VERIFICATION"})}));
 await page.goto(`http://127.0.0.1:${port}/schoolpro/result-templates`);
 await page.getByRole("heading",{name:"Custom Excel Results"}).waitFor({timeout:30000});
 await page.locator("select").filter({hasText:"2001/2002"}).selectOption({label:"2026/2027"});
 await page.locator("select").filter({hasText:"2036/2037"}).selectOption({label:"2026/2027"});
 await page.getByLabel("School section").selectOption({label:"Primary"});
 await page.getByLabel("School class").selectOption({label:"Batch Fixture Class"});
 const studentSelect=page.locator("select").filter({hasText:"Amina Fixture"}).first();
 await studentSelect.waitFor({timeout:30000});
 await studentSelect.selectOption(ids.student);
 const createBatchButton=page.getByRole("button",{name:/Generate separate workbooks for all 1 students/});
 await createBatchButton.click({timeout:60000});
 try{await page.getByRole("heading",{name:"Review each student workbook before finalizing"}).waitFor({timeout:90000});}catch(error){const visible=await page.locator("body").innerText().catch(()=>"<body unavailable>");throw new Error("UI batch creation did not reach review queue. Browser errors: "+browserErrors.join(" | ")+"; visible page text: "+visible.slice(-12000)+"; original: "+error.message);}
 assert.equal(await page.getByTestId("batch-review-item").count(),1,"The routed page did not create and display the student review from the UI");
 const createdBatch=await ok(admin.from("schoolpro_class_result_batches").select("id,status,expected_student_count,created_by").eq("school_id",ids.school).eq("class_id",ids.class).eq("term","First Term").eq("session","2026/2027").single(),"Inspect UI-created class batch");
 batchId=createdBatch.id;
 assert.equal(createdBatch.status,"prepared");
 assert.equal(createdBatch.expected_student_count,1);
 assert.equal(createdBatch.created_by,userId);
 const createdReviews=await ok(admin.from("schoolpro_class_result_batch_reviews").select("student_id,review_status,student_storage_path").eq("batch_id",batchId),"Inspect UI-created review queue");
 assert.equal(createdReviews.length,1);
 assert.equal(createdReviews[0].student_id,ids.student);
 assert.equal(createdReviews[0].review_status,"pending");
 batchPaths.push(ids.school+"/"+ids.class+"/"+batchId+"/workbook.xlsx",...createdReviews.map(row=>row.student_storage_path));
 const storedRegister=await ok(admin.storage.from(bucket).download(ids.school+"/"+ids.class+"/"+batchId+"/workbook.xlsx"),"Download UI-created consolidated workbook");
 assert(storedRegister.size>100);
 const storedStudent=await ok(admin.storage.from(bucket).download(createdReviews[0].student_storage_path),"Download UI-created student workbook");
 assert(storedStudent.size>100);
 await page.getByRole("button",{name:"Approve and finalize Amina Fixture"}).click();
 try{await page.getByText("Student output finalized and the batch review was recorded.",{exact:false}).waitFor({timeout:30000});}
 catch(error){
  const visible=await page.locator("body").innerText().catch(()=>"");
  const reviews=await admin.from("schoolpro_class_result_batch_reviews").select("review_status,reviewed_by,generated_result_output_id").eq("batch_id",batchId);
  const outputs=await admin.from("schoolpro_generated_result_outputs").select("id,storage_path,student_id").eq("school_id",ids.school);
  throw new Error("UI batch approval did not complete. Visible page text: "+visible.slice(-10000)+"; browser errors: "+browserErrors.join(" | ")+"; review rows: "+JSON.stringify(reviews.data)+"; official outputs: "+JSON.stringify(outputs.data)+"; original: "+error.message);
 }
 const approved=await ok(admin.from("schoolpro_class_result_batch_reviews").select("review_status,reviewed_by,generated_result_output_id").eq("batch_id",batchId).single(),"Inspect UI-approved review");
 assert.equal(approved.review_status,"approved");assert.equal(approved.reviewed_by,userId);assert(approved.generated_result_output_id,"UI approval did not link an official output");
 const official=await ok(admin.from("schoolpro_generated_result_outputs").select("id,storage_path,student_id,term,session").eq("id",approved.generated_result_output_id).single(),"Inspect official output");
 assert.equal(official.student_id,ids.student);assert.equal(official.term,"First Term");assert.equal(official.session,"2026/2027");officialPaths.push(official.storage_path);
 const officialFile=await ok(browserAuth.storage.from("schoolpro-result-outputs").download(official.storage_path),"Retrieve official output through authenticated Storage");assert(officialFile.size>100);
 const finalBatch=await ok(admin.from("schoolpro_class_result_batches").select("status").eq("id",batchId).single(),"Reload UI-approved batch");
 assert.equal(finalBatch.status,"completed");
 console.log("PASS: UI-driven class batch creation, private workbook persistence, routed UI approval, official output linkage, and authenticated private-output retrieval.");
}finally{
 await browser?.close();server?.kill();
 if(userId){try{await admin.storage.from("school-result-templates").remove([ids.school+"/templates/batch.xlsx"]);}catch{}try{if(batchPaths.length)await admin.storage.from(bucket).remove(batchPaths);if(officialPaths.length)await admin.storage.from("schoolpro-result-outputs").remove(officialPaths);}catch{}try{await admin.from("schoolpro_schools").delete().eq("id",ids.school);}catch{}try{await admin.auth.admin.deleteUser(userId);}catch{}}
}
