import assert from "node:assert/strict";
import ExcelJS from "exceljs";
import { buildSchoolProConsolidatedClassResultWorkbook } from "../src/lib/schoolproClassResultWorkbook.mjs";

const roster = [
  { id: "student-a", first_name: "Amina", middle_name: "Z", last_name: "Bello", admission_number: "ADM-001" },
  { id: "student-b", first_name: "Musa", middle_name: null, last_name: "Garba", admission_number: "ADM-002" },
  { id: "student-c", first_name: "Zainab", middle_name: "M", last_name: "Yusuf", admission_number: "ADM-003" },
];
const subjects = [
  { subject_id: "subject-math", name: "Mathematics", code: "MTH" },
  { subject_id: "subject-eng", name: "English", code: "ENG" },
];
const assessmentSchemes = [{
  id: "scheme-primary",
  components: [
    { key: "ca", label: "Continuous assessment", maxScore: 40 },
    { key: "exam", label: "Examination", maxScore: 60 },
  ],
}];
const row = (student_id, subject_id, ca, exam) => ({
  student_id, subject_id, total_score: ca + exam, status: "published",
  assessment_scheme_id: "scheme-primary", assessment_scores: { ca, exam },
});
const results = [
  row("student-a", "subject-math", 30, 50),
  row("student-a", "subject-eng", 25, 45),
  row("student-b", "subject-math", 20, 40),
  row("student-b", "subject-eng", 20, 30),
  row("student-c", "subject-math", 35, 45),
  row("student-c", "subject-eng", 25, 45),
];
const options = {
  roster, subjects, results, assessmentSchemes, schoolName: "IH Academy",
  className: "Pre-Nursery A", term: "First Term", session: "2026/2027",
};

const built = await buildSchoolProConsolidatedClassResultWorkbook(options);
assert.equal(built.studentCount, 3);
assert.equal(built.subjectCount, 2);
assert.equal(built.assessmentComponentCount, 4);
assert.equal(built.formulaCalculation.formulaCount, 12);
assert.equal(built.formulaCalculation.engine, "hot-formula-parser");
assert.equal(built.rankingMethod, "competition-rank-by-grand-total");

const reopened = new ExcelJS.Workbook();
await reopened.xlsx.load(built.buffer);
const sheet = reopened.getWorksheet("Class Results");
assert.ok(sheet);
assert.equal(sheet.getCell("B5").value, "Amina Z Bello");
assert.equal(sheet.getCell("C6").value, "ADM-002");
assert.equal(sheet.getCell("D5").value, 30);
assert.equal(sheet.getCell("E5").value, 50);
assert.equal(sheet.getCell("F5").value.result, 80);
assert.equal(sheet.getCell("G5").value, 25);
assert.equal(sheet.getCell("H5").value, 45);
assert.equal(sheet.getCell("I5").value.result, 70);
assert.equal(sheet.getCell("J5").value.result, 150);
assert.equal(sheet.getCell("K5").value.result, 75);
assert.equal(sheet.getCell("L5").value, 1);
assert.equal(sheet.getCell("J6").value.result, 110);
assert.equal(sheet.getCell("L6").value, 3);
assert.equal(sheet.getCell("J7").value.result, 150);
assert.equal(sheet.getCell("L7").value, 1);
assert.equal(sheet.getCell("J5").value.formula, "SUM(F5,I5)");
assert.equal(sheet.getCell("K7").value.formula, "AVERAGE(F7,I7)");
assert.equal(sheet.getCell("B4").value, "Student");
assert.equal(sheet.getCell("D4").value, "Mathematics · MTH · Continuous assessment");
assert.match(sheet.getCell("D4").note, /subject-math/);

await assert.rejects(() => buildSchoolProConsolidatedClassResultWorkbook({
  ...options, results: results.slice(0, 5),
}), /missing a published subject result/);
await assert.rejects(() => buildSchoolProConsolidatedClassResultWorkbook({
  ...options, results: results.map((item, index) => index === 0 ? { ...item, status: "draft" } : item),
}), /must be published/);
await assert.rejects(() => buildSchoolProConsolidatedClassResultWorkbook({
  ...options, results: [...results, results[0]],
}), /duplicate result rows/);
await assert.rejects(() => buildSchoolProConsolidatedClassResultWorkbook({
  ...options, results: results.map((item, index) => index === 0
    ? { ...item, assessment_scores: { ca: 30 }, total_score: 30 } : item),
}), /exactly the configured assessment components/);
await assert.rejects(() => buildSchoolProConsolidatedClassResultWorkbook({
  ...options, results: results.map((item, index) => index === 0
    ? { ...item, assessment_scores: { ca: 41, exam: 50 }, total_score: 91 } : item),
}), /out-of-range assessment component/);
await assert.rejects(() => buildSchoolProConsolidatedClassResultWorkbook({
  ...options, results: results.map((item, index) => index === 1
    ? { ...item, assessment_scheme_id: "different-scheme" } : item),
  assessmentSchemes: [...assessmentSchemes, {
    id: "different-scheme", components: [
      { key: "ca", label: "Continuous assessment", maxScore: 41 },
      { key: "exam", label: "Examination", maxScore: 59 },
    ],
  }],
}), /different assessment schemes/);

console.log("SchoolPro consolidated assessment-component and class-ranking regression passed.");
