import ExcelJS from "exceljs";
import { populateRosterSubjectRows } from "./resultTemplateRosterBinding.mjs";
import { calculateWorkbookFormulas } from "./excelFormulaCalculation.mjs";

const STUDENT_FIELDS = new Set([
  "school_name", "student_name", "student_first_name", "student_middle_name",
  "student_last_name", "admission_number", "class_name", "term", "session",
  "gender", "date_of_birth",
]);

function requiredText(value, label) {
  const text = String(value ?? "").trim();
  if (!text) throw new Error(label + " is required for the custom class workbook.");
  return text;
}

/**
 * Populate the school-assigned workbook as one repeated-block class workbook.
 * This is deliberately fail-closed: the saved template must explicitly define
 * its repeated student block, subject-ID row map and writable assessment columns.
 */
export async function buildSchoolProCustomClassResultWorkbook(options) {
  const {
    templateBuffer, templateConfig, roster, subjects, subjectRowMappings,
    results, assessmentSchemes, schoolName, className, term, session,
  } = options || {};
  if (!templateBuffer) throw new Error("The saved custom workbook file is unavailable.");
  const config = templateConfig || {};
  const block = config.student_block || {};
  const startRow = Number(block.startRow);
  const endRow = Number(block.endRow);
  const rowStride = block.rowStride == null || block.rowStride === "" ? undefined : Number(block.rowStride);
  if (!Number.isInteger(startRow) || startRow < 1 || !Number.isInteger(endRow) || endRow < startRow ||
      (rowStride !== undefined && (!Number.isInteger(rowStride) || rowStride < endRow - startRow + 1))) {
    throw new Error("Configure a valid repeated student block in the saved workbook before generating the class workbook.");
  }
  if (!Array.isArray(roster) || !roster.length || !Array.isArray(subjects) || !subjects.length) {
    throw new Error("A verified class roster and allocated canonical subjects are required.");
  }
  const subjectIds = new Set(subjects.map(subject => String(subject.subject_id ?? subject.id)));
  if (Object.keys(subjectRowMappings || {}).length !== subjectIds.size ||
      [...subjectIds].some(id => !Number.isInteger(Number(subjectRowMappings[id])))) {
    throw new Error("The saved class workbook must map every allocated subject by its canonical subject ID.");
  }
  if (!Array.isArray(results) || results.some(row => String(row.status).toLowerCase() !== "published")) {
    throw new Error("Every class subject result must be published before the custom class workbook can be generated.");
  }

  const schemesById = new Map((assessmentSchemes || []).map(scheme => [String(scheme.id), scheme]));
  const assessmentComponentsBySubject = {};
  const componentColumns = {};
  for (const subject of subjects) {
    const id = String(subject.subject_id ?? subject.id);
    const rows = results.filter(row => String(row.subject_id) === id);
    const schemeIds = [...new Set(rows.map(row => String(row.assessment_scheme_id ?? "")))];
    if (schemeIds.length !== 1 || !schemeIds[0]) {
      throw new Error("Each allocated subject must have one consistent published assessment scheme across the class.");
    }
    const scheme = schemesById.get(schemeIds[0]);
    if (!scheme || !Array.isArray(scheme.components) || !scheme.components.length) {
      throw new Error("A published subject references a missing assessment scheme definition.");
    }
    assessmentComponentsBySubject[id] = scheme.components.map(component => {
      const key = requiredText(component?.key, "Assessment component key");
      const maxScore = Number(component?.maxScore);
      if (!Number.isFinite(maxScore) || maxScore <= 0) {
        throw new Error("An assessment component has an invalid maximum score.");
      }
      return { key, label: String(component.label || component.name || key), maxScore };
    });
    for (const component of scheme.components) {
      const column = config.component_columns?.[component.key];
      if (typeof column !== "string" || !/^[A-Z]{1,3}$/.test(column.toUpperCase())) {
        throw new Error("Map assessment component " + component.key + " to a workbook column before generating the class workbook.");
      }
      const previous = componentColumns[component.key];
      if (previous && previous.toUpperCase() !== column.toUpperCase()) {
        throw new Error("The same assessment component key maps to conflicting workbook columns.");
      }
      componentColumns[component.key] = column.toUpperCase();
    }
  }

  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(templateBuffer);
  const sheetName = requiredText(config.sheet_name, "Worksheet name");
  const worksheet = workbook.getWorksheet(sheetName) || workbook.worksheets[0];
  if (!worksheet) throw new Error("The saved custom workbook does not contain a worksheet.");

  const supportedFieldCells = {};
  for (const [field, address] of Object.entries(config.field_cells || {})) {
    if (!address) continue;
    if (!STUDENT_FIELDS.has(field)) throw new Error("Student field " + field + " is not yet supported by the class-wide custom workbook data contract; remove or remap it before generating this batch.");
    supportedFieldCells[field] = String(address).split(":")[0];
  }
  const customFields = (config.custom_fields || []).filter(field => field && field.enabled !== false && field.cell);
  const customFieldValuesByStudent = {};
  for (const student of roster) {
    const studentId = String(student.id);
    const values = {
      school_name: schoolName,
      student_name: [student.first_name, student.middle_name, student.last_name].filter(Boolean).join(" "),
      student_first_name: student.first_name ?? "",
      student_middle_name: student.middle_name ?? "",
      student_last_name: student.last_name ?? "",
      admission_number: student.admission_number ?? "",
      class_name: student.class_name ?? className,
      term, session, gender: student.gender ?? "", date_of_birth: student.date_of_birth ?? "",
    };
    customFieldValuesByStudent[studentId] = {};
    for (const field of customFields) {
      if (field.source === "literal") continue;
      if (!STUDENT_FIELDS.has(String(field.source))) {
        throw new Error("Custom field " + (field.label || field.id) + " uses source " + field.source + ", which is not yet available in the class-wide workbook data contract.");
      }
      customFieldValuesByStudent[studentId][field.id] = values[field.source];
    }
  }

  const plan = populateRosterSubjectRows({
    worksheet, roster, subjects, subjectRowMappings, results,
    columns: config.columns || {},
    componentColumns,
    assessmentComponentsBySubject,
    studentBlock: { startRow, endRow, ...(rowStride ? { rowStride } : {}) },
    studentFieldCells: supportedFieldCells,
    studentContext: { schoolName, term, session },
    customFields,
    customFieldValuesByStudent,
  });
  const formulaCalculation = calculateWorkbookFormulas(workbook);
  Object.assign(workbook.calcProperties, { fullCalcOnLoad: true, forceFullCalc: true, calcMode: "auto" });
  const buffer = await workbook.xlsx.writeBuffer();
  return {
    buffer, formulaCalculation, studentCount: roster.length, subjectCount: subjects.length,
    boundResultCount: plan.boundResultCount, subjectIds: [...subjectIds], worksheetName: worksheet.name,
    repeatedStudentBlock: { startRow, endRow, rowStride: plan.rowStride },
  };
}
