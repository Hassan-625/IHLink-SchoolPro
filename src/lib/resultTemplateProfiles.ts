export type ReportSection='nursery'|'primary';
export const resultTemplateProfile=(section:ReportSection)=>{
 const end=section==='nursery'?24:27,summary=end+3,remark=end+20;
 return {name:section==='nursery'?'Nursery report':'Primary report',sheet_name:'Sheet1',start_row:13,
 field_cells:{school_name:'',student_name:'C8:J8',admission_number:'C9:E9',class_name:'J9:L9',term:'E7',session:'J7:K7',term_ending:'C10:D10',next_term_begins:'L10:M10',class_population:`C${summary}`,class_position:`C${summary+1}`},
 columns:{subject:'B',total:'G',grade:'K',status:'',first_term:'H',second_term:'I',subject_average:'J',subject_position:'L',subject_class_average:'M',subject_remark:'N'},
 component_columns:{__layout:{section,last_subject_row:end,preserve_subject_labels:true,grade_thresholds:[75,65,55,45,40]}},
 custom_fields:[],logo_cell:'',photo_cell:'M2:N6',principal_signature_cell:`M${remark+1}:N${remark+1}`,teacher_signature_cell:`M${remark}:N${remark}`,qr_cell:''};
};
export const subjectKey=(name:string)=>name.toUpperCase().replace(/[^A-Z0-9]/g,'');
export function resolveSubjectRows(labels:Array<{row:number;label:string}>,subjects:string[]){
 const rows=new Map<string,number>();for(const entry of labels){const key=subjectKey(entry.label);if(key&&rows.has(key))throw new Error('This template repeats a subject. Give each subject a distinct name.');if(key)rows.set(key,entry.row);}
 return subjects.map(name=>{const row=rows.get(subjectKey(name));if(row===undefined)throw new Error(`No matching row was found for ${name}. Check the subject names before generating.`);return row;});
}
export function combineAssessment(scores:Record<string,number>,keys:string[]){
 if(!keys.length||keys.some(key=>typeof scores[key]!=='number'||!Number.isFinite(scores[key])))return null;
 return keys.reduce((sum,key)=>sum+scores[key],0);
}
export function subjectClassSummary(rows:Array<{student_id:string;subject_id:string;term:string;total_score:number|string}>,subjectId:string,studentId:string,terms:string[],population:number){
 const marks=new Map<string,Map<string,number>>();
 for(const row of rows){if(row.subject_id!==subjectId||!terms.includes(row.term))continue;const value=Number(row.total_score);if(!Number.isFinite(value))return null;const student=marks.get(row.student_id)||new Map<string,number>();if(student.has(row.term))return null;student.set(row.term,value);marks.set(row.student_id,student);}
 if(population<1||marks.size!==population||[...marks.values()].some(scores=>scores.size!==terms.length))return null;
 const averages=new Map([...marks].map(([id,scores])=>[id,[...scores.values()].reduce((a,b)=>a+b,0)/terms.length]));const score=averages.get(studentId);if(score===undefined)return null;
 return {position:1+[...averages.values()].filter(value=>value>score).length,classAverage:[...averages.values()].reduce((a,b)=>a+b,0)/averages.size};
}
