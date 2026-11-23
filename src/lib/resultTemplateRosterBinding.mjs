import { buildRosterSubjectRowPlan } from "./resultTemplateRosterLayout.mjs";
import { expandWorksheetRowsForRoster } from "./excelWorksheetRowExpansion.mjs";
import { typedCustomValue } from "./resultTemplateTypedValues.mjs";

function formulaCell(cell) {
  const value = cell?.value;
  return Boolean(value && typeof value === "object" && (value.formula || value.sharedFormula || value.shareType === "array"));
}

function writeInputCell(worksheet, address, value, label) {
  if (!address) return;
  const cell = worksheet.getCell(address).master;
  if (formulaCell(cell)) throw new Error(label + " targets formula cell " + cell.address + "; formulas are preserved and cannot be overwritten.");
  cell.value = value ?? "";
}

function finiteScore(value, label, maximum) {
  if (value === null || value === undefined || (typeof value === "string" && !value.trim())) {
    throw new Error(label + " is missing.");
  }
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0 || (Number.isFinite(maximum) && number > maximum)) {
    throw new Error(label + " is outside its valid score range.");
  }
  return number;
}

/**
 * Expand one configured subject-row block and bind the selected class roster.
 * All subject lookups use canonical subject IDs; display names are presentation only.
 */
export function populateRosterSubjectRows({
  worksheet, roster, subjects, subjectRowMappings, results,
  columns = {}, componentColumns = {}, assessmentComponentsBySubject = {},
  rowStride, studentBlock, studentFieldCells = {}, studentContext = {}, customFields = [], customFieldValuesByStudent = {},
}) {
  if (!worksheet) throw new Error("A loaded custom result worksheet is required.");
  if (!Array.isArray(results)) throw new Error("Class result rows are invalid.");
  const plan = buildRosterSubjectRowPlan(roster, subjects, subjectRowMappings, { rowStride, studentBlock });
  const rosterIds = new Set(plan.students.map(student => student.studentId));
  const subjectIds = new Set(subjects.map(subject => String(subject.subject_id ?? subject.id)));
  const resultMap = new Map();

  for (const result of results) {
    const studentId = String(result?.student_id ?? "").trim();
    const subjectId = String(result?.subject_id ?? "").trim();
    if (!rosterIds.has(studentId)) throw new Error("A result row belongs to a student outside the selected class roster.");
    if (!subjectIds.has(subjectId)) throw new Error("A result row references a subject not allocated to this class.");
    const key = studentId + "|" + subjectId;
    if (resultMap.has(key)) throw new Error("Duplicate result rows exist for one student and canonical subject.");
    resultMap.set(key, result);
  }

  const expectedCount = roster.length * subjects.length;
  if (resultMap.size !== expectedCount) {
    throw new Error("Every selected student must have exactly one result row for every allocated class subject before class workbook generation.");
  }

  expandWorksheetRowsForRoster(worksheet, {
    startRow: plan.blockStartRow,
    endRow: plan.blockEndRow,
    repeatCount: roster.length,
    rowStride: plan.rowStride,
  });

  const studentFieldValues = (student) => ({
    student_name: [student.first_name, student.middle_name, student.last_name].filter(Boolean).join(" "),
    student_first_name: student.first_name ?? "",
    student_middle_name: student.middle_name ?? "",
    student_last_name: student.last_name ?? "",
    admission_number: student.admission_number ?? "",
    gender: student.gender ?? "",
    date_of_birth: student.date_of_birth ?? "",
    school_name: studentContext.schoolName ?? student.school_name ?? "",
    class_name: student.class_name ?? "",
    term: studentContext.term ?? student.term ?? "",
    session: studentContext.session ?? student.session ?? "",
  });
  for (const studentPlan of plan.students) {
    const student = roster[studentPlan.index];
    const values = studentFieldValues(student, studentContext);
    for (const [field, addressValue] of Object.entries(studentFieldCells || {})) {
      if (!addressValue) continue;
      const match = /^([A-Z]+)(\d+)$/.exec(String(addressValue).toUpperCase().trim().split(":")[0]);
      if (!match) throw new Error("Student field " + field + " must map to one worksheet cell inside the repeated block.");
      const baseRow = Number(match[2]);
      if (baseRow < plan.blockStartRow || baseRow > plan.blockEndRow) {
        throw new Error("Student field " + field + " must be mapped inside the configured repeated student block.");
      }
      const shiftedAddress = match[1] + (baseRow + studentPlan.rowOffset);
      writeInputCell(worksheet, shiftedAddress, values[field] ?? "", "Student " + field);
    }
    for (const field of (customFields || []).filter(item => item && item.enabled !== false && item.cell)) {
      const match = /^([A-Z]+)(\d+)$/.exec(String(field.cell).toUpperCase().trim().split(":")[0]);
      if (!match) throw new Error("Custom field " + (field.label || field.id) + " must map to one worksheet cell inside the repeated block.");
      const baseRow = Number(match[2]);
      if (baseRow < plan.blockStartRow || baseRow > plan.blockEndRow) throw new Error("Custom field " + (field.label || field.id) + " must be mapped inside the configured repeated student block.");
      const sourceValues = customFieldValuesByStudent[studentPlan.studentId] || {};
      const raw = field.source === "literal" ? field.value : sourceValues[field.id];
      if (field.source !== "literal" && !Object.prototype.hasOwnProperty.call(sourceValues, field.id)) throw new Error("Custom field " + (field.label || field.id) + " has no verified class-workbook value for source " + field.source + ".");
      const shiftedAddress = match[1] + (baseRow + studentPlan.rowOffset);
      writeInputCell(worksheet, shiftedAddress, typedCustomValue(raw, field.valueType, field.label || field.id), "Custom field " + (field.label || field.id));
    }
  }

  for (const studentPlan of plan.students) {
    for (const subject of subjects) {
      const subjectId = String(subject.subject_id ?? subject.id);
      const result = resultMap.get(studentPlan.studentId + "|" + subjectId);
      const row = studentPlan.subjectRows[subjectId];
      const label = String(subject.name || "Subject");
      if (columns.subject) writeInputCell(worksheet, columns.subject + row, label, label + " subject name");
      if (columns.subject_code) writeInputCell(worksheet, columns.subject_code + row, subject.code || "", label + " subject code");

      const components = assessmentComponentsBySubject[subjectId] || [];
      if (components.length && !result.assessment_scores) throw new Error(label + " assessment scores are missing.");
      for (const component of components) {
        const column = componentColumns[component.key];
        if (!column) throw new Error("The custom workbook has no mapped column for assessment component " + component.key + ".");
        const score = finiteScore(result.assessment_scores?.[component.key], label + " " + component.label, Number(component.maxScore));
        writeInputCell(worksheet, column + row, score, label + " " + component.label);
      }

      if (columns.total) {
        const total = finiteScore(result.total_score, label + " total score");
        writeInputCell(worksheet, columns.total + row, total, label + " total score");
      }
      if (columns.grade) writeInputCell(worksheet, columns.grade + row, result.grade_label ?? result.grade ?? "", label + " grade");
      if (columns.status) writeInputCell(worksheet, columns.status + row, result.status ?? "", label + " result status");
      if (columns.subject_average) writeInputCell(worksheet, columns.subject_average + row, result.subject_average ?? "", label + " subject average");
      if (columns.subject_position) writeInputCell(worksheet, columns.subject_position + row, result.subject_position ?? "", label + " subject position");
      if (columns.subject_remark) writeInputCell(worksheet, columns.subject_remark + row, result.subject_remark ?? "", label + " subject remark");
    }
  }

  return {
    ...plan,
    boundResultCount: resultMap.size,
    subjectRows: plan.students.map(student => ({ studentId: student.studentId, ...student.subjectRows })),
  };
}
