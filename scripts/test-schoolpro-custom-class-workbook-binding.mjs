import assert from "node:assert/strict";
import ExcelJS from "exceljs";
import { populateRosterSubjectRows } from "../src/lib/resultTemplateRosterBinding.mjs";
import { repeatedBlockImageAnchor, storedWorkbookImageFormat } from "../src/lib/resultTemplateMediaLayout.mjs";

const workbook = new ExcelJS.Workbook();
const sheet = workbook.addWorksheet("Class");
sheet.getCell("A2").value = "Student";
sheet.getCell("B2").value = "Subject";
sheet.getCell("C2").value = "CA";
sheet.getCell("D2").value = "Exam";
sheet.getCell("E2").value = "Total";
sheet.getCell("B3").value = "Mathematics";
sheet.getCell("C3").value = 0;
sheet.getCell("D3").value = 0;
sheet.getCell("E3").value = { formula: "SUM(C3:D3)" };
sheet.getCell("B4").value = "English";
sheet.getCell("C4").value = 0;
sheet.getCell("D4").value = 0;
sheet.getCell("E4").value = { formula: "SUM(C4:D4)" };
sheet.getCell("A3").value = "Student A";
sheet.getCell("A3").style = { font: { bold: true } };
sheet.getRow(3).height = 24;

const roster = [{id:"student-a",first_name:"Amina",middle_name:"M",last_name:"Ali",admission_number:"A001"},{id:"student-b",first_name:"Bala",last_name:"Bello",admission_number:"B002"}];
const subjects = [
  {subject_id:"math-id",name:"Mathematics",code:"MTH"},
  {subject_id:"english-id",name:"English",code:"ENG"},
];
const results = [];
for (const student of roster) {
  results.push(
    {student_id:student.id,subject_id:"math-id",total_score:75,assessment_scores:{ca:25,exam:50},grade_label:"A",status:"published"},
    {student_id:student.id,subject_id:"english-id",total_score:68,assessment_scores:{ca:28,exam:40},grade_label:"B",status:"published"},
  );
}
const plan = populateRosterSubjectRows({
  worksheet:sheet,roster,subjects,subjectRowMappings:{"math-id":3,"english-id":4},results,
  columns:{subject:"B",subject_code:"F",grade:"G",status:"H"},
  componentColumns:{ca:"C",exam:"D"},
  studentBlock:{startRow:3,endRow:4,rowStride:2},
  studentFieldCells:{student_name:"A3",admission_number:"I3",school_name:"J3",term:"K3",session:"L3"},
  studentContext:{schoolName:"IH Academy",term:"First Term",session:"2026/2027"},
  customFields:[
    {id:"house",label:"House",cell:"M3",source:"house",valueType:"text"},
    {id:"fee",label:"Fee",cell:"N3",source:"fee",valueType:"number"},
    {id:"literal",label:"School motto",cell:"O3",source:"literal",value:"Nigeria Greater Tomorrow",valueType:"text"},
  ],
  customFieldValuesByStudent:{
    "student-a":{house:"Blue",fee:"1250"},
    "student-b":{house:"Green",fee:"1500"},
  },
  assessmentComponentsBySubject:{
    "math-id":[{key:"ca",label:"CA",maxScore:30},{key:"exam",label:"Exam",maxScore:70}],
    "english-id":[{key:"ca",label:"CA",maxScore:30},{key:"exam",label:"Exam",maxScore:70}],
  },
});
assert.equal(plan.boundResultCount,4);
assert.equal(sheet.getCell("A3").value,"Amina M Ali");
assert.equal(sheet.getCell("I3").value,"A001");
assert.equal(sheet.getCell("J3").value,"IH Academy");
assert.equal(sheet.getCell("K3").value,"First Term");
assert.equal(sheet.getCell("L3").value,"2026/2027");
assert.equal(sheet.getCell("M3").value,"Blue");
assert.equal(sheet.getCell("N3").value,1250);
assert.equal(sheet.getCell("O3").value,"Nigeria Greater Tomorrow");
assert.equal(sheet.getCell("M5").value,"Green");
assert.equal(sheet.getCell("N5").value,1500);
assert.equal(sheet.getCell("O5").value,"Nigeria Greater Tomorrow");
assert.equal(sheet.getCell("A5").value,"Bala Bello");
assert.equal(sheet.getCell("I5").value,"B002");
assert.deepEqual(plan.students.map(s=>s.subjectRows),[
  {"math-id":3,"english-id":4},{"math-id":5,"english-id":6},
]);
assert.equal(sheet.getCell("C5").value,25);
assert.equal(sheet.getCell("D5").value,50);
assert.equal(sheet.getCell("B6").value,"English");
assert.equal(sheet.getCell("F6").value,"ENG");
assert.equal(sheet.getCell("E5").value.formula,"SUM(C5:D5)");
assert.equal(sheet.getCell("E6").value.formula,"SUM(C6:D6)");
assert.equal(sheet.getRow(5).height,24);
assert.equal(sheet.getCell("A5").style.font.bold,true);

const incomplete = new ExcelJS.Workbook().addWorksheet("Incomplete");
incomplete.getCell("A1").value = "Math";
assert.throws(()=>populateRosterSubjectRows({
  worksheet:incomplete,roster,subjects,subjectRowMappings:{"math-id":1,"english-id":2},studentBlock:{startRow:1,endRow:2},results:results.slice(0,3),
}),/exactly one result row/);
assert.equal(incomplete.rowCount,1,"incomplete result sets must fail before worksheet mutation");

const duplicate = [...results,{...results[0]}];
assert.throws(()=>populateRosterSubjectRows({
  worksheet:new ExcelJS.Workbook().addWorksheet("Duplicate"),roster,subjects,
  subjectRowMappings:{"math-id":1,"english-id":2},studentBlock:{startRow:1,endRow:2},results:duplicate,
}),/Duplicate result rows/);

const formulaTarget = new ExcelJS.Workbook().addWorksheet("Formula");
formulaTarget.getCell("A1").value = {formula:"1+1"};
assert.throws(()=>populateRosterSubjectRows({
  worksheet:formulaTarget,roster:[{id:"student-a"}],subjects:[subjects[0]],
  subjectRowMappings:{"math-id":1},studentBlock:{startRow:1,endRow:1},
  results:[{student_id:"student-a",subject_id:"math-id",total_score:1,assessment_scores:{ca:0,exam:1}}],
  columns:{subject:"A"},assessmentComponentsBySubject:{"math-id":[]},
}),/targets formula cell/);
assert.throws(()=>populateRosterSubjectRows({
  worksheet:formulaTarget,roster:[{id:"student-a"}],subjects:[subjects[0]],
  subjectRowMappings:{"math-id":1},studentBlock:{startRow:1,endRow:1},
  results:[{student_id:"student-a",subject_id:"math-id",total_score:1,assessment_scores:{ca:0,exam:1}}],
  studentFieldCells:{student_name:"A1"},assessmentComponentsBySubject:{"math-id":[]},
}),/targets formula cell/);
const customInvalid = new ExcelJS.Workbook().addWorksheet("Custom invalid");
customInvalid.getRow(1);
assert.throws(()=>populateRosterSubjectRows({
  worksheet:customInvalid,roster:[{id:"student-a"}],subjects:[subjects[0]],
  subjectRowMappings:{"math-id":1},studentBlock:{startRow:1,endRow:1},
  results:[{student_id:"student-a",subject_id:"math-id",total_score:1}],
  customFields:[{id:"x",label:"Custom",cell:"A1",source:"value",valueType:"number"}],
  customFieldValuesByStudent:{"student-a":{x:"not-a-number"}},
}),/finite number/);
const customFormula= new ExcelJS.Workbook().addWorksheet("Custom formula protected");
customFormula.getCell("A1").value={formula:"1+1"};
assert.throws(()=>populateRosterSubjectRows({
  worksheet:customFormula,roster:[{id:"student-a"}],subjects:[subjects[0]],
  subjectRowMappings:{"math-id":1},studentBlock:{startRow:1,endRow:1},
  results:[{student_id:"student-a",subject_id:"math-id",total_score:1}],
  customFields:[{id:"x",label:"Custom",cell:"A1",source:"value"}],
  customFieldValuesByStudent:{"student-a":{x:"unsafe"}},
}),/targets formula cell/);
const customOutside = new ExcelJS.Workbook().addWorksheet("Custom outside block");
customOutside.getRow(1);
assert.throws(()=>populateRosterSubjectRows({
  worksheet:customOutside,roster:[{id:"student-a"}],subjects:[subjects[0]],
  subjectRowMappings:{"math-id":1},studentBlock:{startRow:1,endRow:1},
  results:[{student_id:"student-a",subject_id:"math-id",total_score:1}],
  customFields:[{id:"x",label:"Custom",cell:"A2",source:"value"}],
  customFieldValuesByStudent:{"student-a":{x:"ok"}},
}),/inside the configured repeated student block/);

assert.deepEqual(repeatedBlockImageAnchor("J2",{studentIndex:0,rowStride:10}),{col:9,row:1});
assert.deepEqual(repeatedBlockImageAnchor("J2",{studentIndex:1,rowStride:10}),{col:9,row:11});
assert.deepEqual(repeatedBlockImageAnchor("J2:L5",{studentIndex:2,rowStride:10}),{col:9,row:21});
assert.deepEqual(repeatedBlockImageAnchor("A1",{blockEndRow:10,insertedRows:20}),{col:0,row:0});
assert.deepEqual(repeatedBlockImageAnchor("J40",{blockEndRow:10,insertedRows:20}),{col:9,row:59});
assert.deepEqual(repeatedBlockImageAnchor("B10",{blockEndRow:10,insertedRows:20}),{col:1,row:9});
assert.equal(storedWorkbookImageFormat("school/student-photos/a.png"),"png");
assert.equal(storedWorkbookImageFormat("school/student-photos/b.jpeg"),"jpeg");
assert.equal(storedWorkbookImageFormat("school/student-photos/c.webp"),"webp");
assert.throws(()=>repeatedBlockImageAnchor("not-a-cell",{studentIndex:0,rowStride:10}),/valid Excel cell/);
assert.throws(()=>storedWorkbookImageFormat("school/student-photos/a.svg"),/PNG, JPEG or WebP/);


const noExplicitBlock = new ExcelJS.Workbook().addWorksheet("No block");
assert.throws(()=>populateRosterSubjectRows({
  worksheet:noExplicitBlock,roster:[{id:"student-a"}],subjects:[subjects[0]],
  subjectRowMappings:{"math-id":1},
  results:[{student_id:"student-a",subject_id:"math-id",total_score:1}],
}),/explicit saved student-block/);
assert.equal(noExplicitBlock.rowCount,0,"missing block configuration must fail before worksheet mutation");



console.log("SchoolPro custom class workbook binding regression passed.");
