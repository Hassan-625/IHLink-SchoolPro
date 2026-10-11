import {createClient} from 'npm:@supabase/supabase-js@2.57.4';
import {PDFDocument,StandardFonts,rgb} from 'npm:pdf-lib@1.17.1';
import {orientDocument,drawDesignImage} from '../schoolpro-render-document/design.ts';
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Content-Type':'application/json'};
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
 const respond=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:cors});
 if(req.method!=='POST')return respond({error:'Method not allowed'},405);
 try{
 const authorization=req.headers.get('Authorization');if(!authorization)return respond({error:'Sign in to open a transcript'},401);
 const reader=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_ANON_KEY')!,{global:{headers:{Authorization:authorization}}});
 const {data:{user}}=await reader.auth.getUser();if(!user)return respond({error:'Sign in to open a transcript'},401);
 const {student_id,issue_id}=await req.json();
 const access=await reader.rpc('schoolpro_student_transcripts',{p_student:student_id});
 const record=(Array.isArray(access.data)?access.data:[]).find((r:any)=>r.id===issue_id&&r.allowed&&!r.revoked);
 if(access.error||!record?.snapshot)return respond({error:'This transcript is unavailable. Contact your school.'},403);
 const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
 const {data:issued,error:ie}=await admin.from('schoolpro_transcript_issues').select('school_id,student_id').eq('id',issue_id).eq('student_id',student_id).single();if(ie||!issued)return respond({error:'Transcript unavailable'},404);
 const saved=record.snapshot.design_snapshot;
 const selected=await admin.from('schoolpro_document_templates').select('*').eq('school_id',issued.school_id).eq('document_type','transcript').eq('is_active',true).eq('is_default',true).limit(1).maybeSingle();
 if(selected.error)throw selected.error;const template=saved||selected.data;
 let pdf=await PDFDocument.create();
 if(template?.storage_path){
 if(!String(template.storage_path).startsWith(issued.school_id+'/'))throw new Error('Invalid source');
 const source=await admin.storage.from('schoolpro-document-templates').download(template.storage_path);if(source.error||!source.data)throw new Error('Template unavailable');
 if(template.source_format==='pdf')pdf=await PDFDocument.load(await source.data.arrayBuffer());else if(template.source_format==='image'){const bytes=await source.data.arrayBuffer();const image=template.mime_type==='image/png'?await pdf.embedPng(bytes):await pdf.embedJpg(bytes);pdf.addPage([image.width,image.height]).drawImage(image,{x:0,y:0,width:image.width,height:image.height});}else throw new Error('Use a PDF or image template');
 pdf=await orientDocument(pdf,template.settings||{});
 }else pdf.addPage([595.28,841.89]);
 const snapshot=record.snapshot,fields=template?.field_mappings||[],frame=fields.find((f:any)=>f.key==='transcript_records');
 const first=Math.max(0,Number(frame?.page||1)-1),sourcePage=pdf.getPages()[first];if(!sourcePage)throw new Error('Invalid table page');
 const original=await pdf.save(),background=await PDFDocument.load(original);
 pdf=await PDFDocument.load(original);const base=pdf.getPages()[first];
 const normal=await pdf.embedFont(StandardFonts.Helvetica),bold=await pdf.embedFont(StandardFonts.HelveticaBold);
 const safe=(v:unknown)=>String(v??'').replace(/[^\x20-\x7E]/g,' ').replace(/\s+/g,' ').trim();
 const values:any={...snapshot,student_name:snapshot.student_name,serial_number:record.serial_number,issue_date:new Date(record.issued_at).toISOString().slice(0,10),...(template?.settings||{})};
 const x=Math.max(20,Number(frame?.x||40)),top=Math.max(150,Number(frame?.y||210)),width=Math.min(base.getWidth()-x-20,Math.max(200,Number(frame?.width||base.getWidth()-80))),bottom=Math.max(40,base.getHeight()-top-Math.max(80,Number(frame?.height||base.getHeight()-top-60)));
 const rowHeight=20,capacity=Math.max(1,Math.floor((base.getHeight()-top-bottom-26)/rowHeight));
 const records=snapshot.records||[];if(!records.length)throw new Error('No academic records');
 const parts=Math.ceil(records.length/capacity);
 for(let part=0;part<parts;part++){
 let page=part===0?base:(await pdf.copyPages(background,[first]))[0];if(part>0)pdf.addPage(page);
 if(!template){page.drawText(safe(snapshot.school_name),{x:40,y:page.getHeight()-55,size:18,font:bold});page.drawText('ACADEMIC TRANSCRIPT',{x:40,y:page.getHeight()-85,size:14,font:bold});page.drawText(safe(snapshot.student_name)+' | '+safe(snapshot.admission_number),{x:40,y:page.getHeight()-115,size:11,font:normal});page.drawText(safe(record.serial_number),{x:40,y:page.getHeight()-140,size:8,font:normal});}
 for(const field of fields){if(field.key==='transcript_records'||Number(field.page||1)-1!==first)continue;
 const imageKey=({school_logo:'logo_storage_path',principal_signature:'signature_1_storage_path',signature_2:'signature_2_storage_path'} as Record<string,string>)[field.key];
 if(imageKey){const path=template.settings?.[imageKey];if(!path)continue;if(!String(path).startsWith(issued.school_id+'/'))throw new Error('Invalid image');const image=await admin.storage.from('schoolpro-document-templates').download(path);if(image.error||!image.data)throw new Error('Image unavailable');await drawDesignImage(pdf,page,field,await image.data.arrayBuffer());continue;}
 const text=safe(field.key==='custom_text'?field.value:values[field.key]);if(!text)continue;const font=field.bold?bold:normal,size=Math.max(6,Math.min(36,Number(field.fontSize||11)));let px=Number(field.x||40);const measured=font.widthOfTextAtSize(text,size);if(field.align==='center')px-=measured/2;else if(field.align==='right')px-=measured;page.drawText(text,{x:px,y:page.getHeight()-Number(field.y||60)-size,size,font});
 }
 let y=page.getHeight()-top;const columns=[0,.16,.31,.52,.88];const labels=['Session','Term','Class','Subject','Score'];
 page.drawRectangle({x,y:y-18,width,height:22,color:rgb(.94,.94,.98)});labels.forEach((label,i)=>page.drawText(label,{x:x+width*columns[i]+3,y:y-12,size:9,font:bold}));y-=26;
 for(const row of records.slice(part*capacity,(part+1)*capacity)){
 const data=[row.session,row.term,safe(row.class_name)+' '+safe(row.arm),row.subject,Number(row.score).toFixed(1)];
 data.forEach((value,i)=>{let text=safe(value);const available=width*((columns[i+1]??1)-columns[i])-7;while(text.length&&normal.widthOfTextAtSize(text,8)>available)text=text.slice(0,-1);page.drawText(text,{x:x+width*columns[i]+3,y:y-10,size:8,font:normal});});page.drawLine({start:{x,y:y-15},end:{x:x+width,y:y-15},thickness:.3,color:rgb(.8,.8,.8)});y-=rowHeight;
 }
 page.drawText('Page '+(part+1)+' of '+parts+' | Issued '+values.issue_date,{x:40,y:20,size:8,font:normal});
 }
 const bytes=await pdf.save();let binary='';for(let i=0;i<bytes.length;i+=8192)binary+=String.fromCharCode(...bytes.subarray(i,i+8192));
 return respond({ok:true,base64:btoa(binary),template_name:template?.name||'Standard academic transcript',pages:pdf.getPageCount()});
 }catch{return respond({error:'The transcript could not be prepared. Check the school template and try again.'},400);}
});
