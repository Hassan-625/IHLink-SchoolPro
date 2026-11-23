import ExcelJS from "exceljs";
import { expandWorksheetRowsForRoster } from "./excelWorksheetRowExpansion.mjs";
import { calculateWorkbookFormulas } from "./excelFormulaCalculation.mjs";

const MAX_STUDENTS = 500;

function requiredText(value, label) {
  const text = String(value ?? "").trim();
  if (!text) throw new Error(label + " is required.");
  return text;
}

function componentContract(scheme, subjectId) {
  const components = scheme?.components;
  if (!Array.isArray(components) || components.length < 1) {
    throw new Error("Every published subject result must have a configured assessment scheme.");
  }
  const seen = new Set();
  return components.map((component, index) => {
    const key = requiredText(component?.key, "Assessment component key");
    if (seen.has(key)) throw new Error("An assessment scheme contains duplicate component keys.");
    seen.add(key);
    const label = requiredText(component?.label, "Assessment component label");
    const maxScore = Number(component?.maxScore);
    if (!Number.isFinite(maxScore) || maxScore < 0) {
      throw new Error("An assessment component has an invalid maximum score.");
    }
    return { key, label, maxScore, order: index, subjectId };
  });
}

/**
 * Builds a class-wide assessment workbook. It deliberately remains separate
 * from the branded individual report-card artifacts and official output rows.
 */
export async function buildSchoolProConsolidatedClassResultWorkbook(options = {}) {
  const roster = options.roster;
  const subjects = options.subjects;
  const resultRows = options.results;
  const schemes = options.assessmentSchemes;
  if (!Array.isArray(roster) || roster.length < 1 || roster.length > MAX_STUDENTS) {
    throw new Error("The consolidated workbook requires between 1 and 500 students.");
  }
  if (!Array.isArray(subjects) || subjects.length < 1) {
    throw new Error("The selected class has no allocated canonical subjects.");
  }
  if (!Array.isArray(resultRows)) throw new Error("Published class result rows are required.");
  if (!Array.isArray(schemes) || schemes.length < 1) {
    throw new Error("Assessment scheme definitions are required to show component scores.");
  }

  const studentIds = roster.map((student) => requiredText(student?.id, "Student ID"));
  if (new Set(studentIds).size !== studentIds.length) throw new Error("The class roster contains duplicate student IDs.");
  const subjectIds = subjects.map((subject) => requiredText(subject?.subject_id ?? subject?.id, "Canonical subject ID"));
  if (new Set(subjectIds).size !== subjectIds.length) throw new Error("The class subject list contains duplicate canonical subject IDs.");

  const studentsById = new Map(roster.map((student) => [String(student.id), student]));
  const subjectsById = new Map(subjects.map((subject, index) => [subjectIds[index], subject]));
  const schemesById = new Map(schemes.map((scheme) => [String(scheme.id), scheme]));
  if (schemesById.size !== schemes.length) throw new Error("Assessment scheme definitions contain duplicate IDs.");

  const schemeBySubject = new Map();
  const componentColumns = new Map();
  const scores = new Map();
  for (const row of resultRows) {
    const studentId = String(row?.student_id ?? "");
    const subjectId = String(row?.subject_id ?? "");
    if (!studentsById.has(studentId) || !subjectsById.has(subjectId)) {
      throw new Error("A result row falls outside the selected class roster or canonical subject allocation.");
    }
    if (String(row?.status ?? "").toLowerCase() !== "published") {
      throw new Error("Every student subject result must be published before the consolidated class workbook can be created.");
    }
    const score = Number(row.total_score);
    if (row.total_score === null || row.total_score === undefined || !Number.isFinite(score) || score < 0) {
      throw new Error("A published subject result contains a missing or invalid total score.");
    }
    const schemeId = requiredText(row.assessment_scheme_id, "Assessment scheme ID");
    const scheme = schemesById.get(schemeId);
    if (!scheme) throw new Error("A published result references a missing assessment scheme.");
    const components = componentContract(scheme, subjectId);
    const previousScheme = schemeBySubject.get(subjectId);
    if (previousScheme && previousScheme.id !== schemeId) {
      throw new Error("Students in the same subject use different assessment schemes; a consistent component layout cannot be generated.");
    }
    schemeBySubject.set(subjectId, scheme);

    const supplied = row.assessment_scores;
    if (!supplied || typeof supplied !== "object" || Array.isArray(supplied)) {
      throw new Error("A published result is missing its assessment component scores.");
    }
    const keys = Object.keys(supplied);
    if (keys.length !== components.length || components.some((component) => !Object.prototype.hasOwnProperty.call(supplied, component.key))) {
      throw new Error("A published result does not contain exactly the configured assessment components.");
    }
    let calculatedSubjectTotal = 0;
    const componentScores = {};
    for (const component of components) {
      const value = supplied[component.key];
      if (typeof value !== "number" || !Number.isFinite(value) || value < 0 || value > component.maxScore) {
        throw new Error("A published result contains a missing or out-of-range assessment component score.");
      }
      componentScores[component.key] = value;
      calculatedSubjectTotal += value;
      if (!componentColumns.has(subjectId)) componentColumns.set(subjectId, components);
    }
    if (Math.abs(calculatedSubjectTotal - score) > 0.000001) {
      throw new Error("A published subject total does not equal the sum of its assessment components.");
    }
    const key = studentId + ":" + subjectId;
    if (scores.has(key)) throw new Error("A student has duplicate result rows for the same canonical subject.");
    scores.set(key, { total: score, components: componentScores });
  }

  for (const studentId of studentIds) {
    for (const subjectId of subjectIds) {
      if (!scores.has(studentId + ":" + subjectId)) {
        throw new Error("The consolidated class workbook is incomplete: at least one student is missing a published subject result.");
      }
    }
  }
  if (schemeBySubject.size !== subjectIds.length) {
    throw new Error("At least one allocated subject has no published assessment scheme definition.");
  }

  const workbook = new ExcelJS.Workbook();
  workbook.creator = "IHLink SchoolPro";
  workbook.subject = "Consolidated class assessment results";
  workbook.title = [
    options.schoolName || "School",
    options.className || "Class",
    options.term || "Term",
    options.session || "Session",
  ].join(" · ");
  workbook.properties = {
    ...workbook.properties,
    created: new Date("2000-01-01T00:00:00.000Z"),
    modified: new Date("2000-01-01T00:00:00.000Z"),
  };

  const sheet = workbook.addWorksheet("Class Results", {
    views: [{ state: "frozen", ySplit: 4, xSplit: 3 }],
    properties: { defaultRowHeight: 20 },
  });

  const columns = [];
  let nextColumn = 4;
  const subjectGroups = subjects.map((subject, index) => {
    const subjectId = subjectIds[index];
    const components = componentColumns.get(subjectId);
    const group = { subjectId, label: [subject.name, subject.code].filter(Boolean).join(" · "), components: [], totalColumn: null };
    for (const component of components) {
      group.components.push({ ...component, column: nextColumn++ });
    }
    group.totalColumn = nextColumn++;
    columns.push(...group.components, { subjectId, label: "Subject total", kind: "subject-total", column: group.totalColumn });
    return group;
  });
  const grandTotalColumn = nextColumn++;
  const averageColumn = nextColumn++;
  const positionColumn = nextColumn++;
  const lastColumn = positionColumn;

  for (const rowNumber of [1, 2, 3]) sheet.mergeCells(rowNumber, 1, rowNumber, lastColumn);
  sheet.getCell(1, 1).value = requiredText(options.schoolName, "School name");
  sheet.getCell(1, 1).font = { bold: true, size: 16 };
  sheet.getCell(2, 1).value = [
    requiredText(options.className, "Class name"),
    requiredText(options.term, "Term"),
    requiredText(options.session, "Academic session"),
  ].join(" · ");
  sheet.getCell(2, 1).font = { bold: true, size: 12 };
  sheet.getCell(3, 1).value = "Published assessment components, subject totals and class positions — one row per student";
  sheet.getCell(3, 1).font = { italic: true, color: { argb: "FF475569" } };

  const headers = ["Order", "Student", "Admission number"];
  const headerNotes = new Map();
  for (const group of subjectGroups) {
    for (const component of group.components) {
      headers.push(group.label + " · " + component.label);
      headerNotes.set(headers.length, "Canonical subject ID: " + group.subjectId + "; assessment component key: " + component.key + "; maximum: " + component.maxScore);
    }
    headers.push(group.label + " · Total");
    headerNotes.set(headers.length, "Canonical subject ID: " + group.subjectId + "; sum of configured assessment components");
  }
  headers.push("Grand total", "Average", "Class position");
  headers.forEach((header, index) => {
    const cell = sheet.getCell(4, index + 1);
    cell.value = header;
    if (headerNotes.has(index + 1)) cell.note = headerNotes.get(index + 1);
    cell.font = { bold: true, color: { argb: "FFFFFFFF" } };
    cell.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF1E3A8A" } };
    cell.alignment = { vertical: "middle", wrapText: true };
    cell.border = { bottom: { style: "thin" } };
  });
  sheet.getColumn(1).width = 9;
  sheet.getColumn(2).width = 30;
  sheet.getColumn(3).width = 20;
  for (let column = 4; column <= lastColumn; column += 1) sheet.getColumn(column).width = 16;
  sheet.getColumn(grandTotalColumn).width = 14;
  sheet.getColumn(averageColumn).width = 14;
  sheet.getColumn(positionColumn).width = 16;
  sheet.getRow(4).height = 54;

  const firstDataRow = 5;
  const first = sheet.getRow(firstDataRow);
  first.getCell(1).value = 1;
  first.getCell(2).value = "";
  first.getCell(3).value = "";
  for (const group of subjectGroups) {
    for (const component of group.components) first.getCell(component.column).value = 0;
    const firstLetter = sheet.getColumn(group.components[0].column).letter;
    const lastLetter = sheet.getColumn(group.components[group.components.length - 1].column).letter;
    first.getCell(group.totalColumn).value = { formula: "SUM(" + firstLetter + firstDataRow + ":" + lastLetter + firstDataRow + ")" };
  }
  const subjectTotalRefs = subjectGroups.map((group) => sheet.getColumn(group.totalColumn).letter + firstDataRow);
  first.getCell(grandTotalColumn).value = { formula: "SUM(" + subjectTotalRefs.join(",") + ")" };
  first.getCell(averageColumn).value = { formula: "AVERAGE(" + subjectTotalRefs.join(",") + ")" };
  first.eachCell({ includeEmpty: true }, (cell) => {
    cell.border = { bottom: { style: "hair" } };
    cell.alignment = { vertical: "middle" };
  });
  expandWorksheetRowsForRoster(sheet, { startRow: firstDataRow, endRow: firstDataRow, repeatCount: roster.length });

  const totals = [];
  roster.forEach((student, index) => {
    const rowNumber = firstDataRow + index;
    const row = sheet.getRow(rowNumber);
    row.getCell(1).value = index + 1;
    row.getCell(2).value = [student.first_name, student.middle_name, student.last_name].filter(Boolean).join(" ");
    row.getCell(3).value = String(student.admission_number ?? "");
    for (const group of subjectGroups) {
      const result = scores.get(String(student.id) + ":" + group.subjectId);
      for (const component of group.components) row.getCell(component.column).value = result.components[component.key];
      row.getCell(group.totalColumn).numFmt = "0.00";
    }
    row.getCell(grandTotalColumn).numFmt = "0.00";
    row.getCell(averageColumn).numFmt = "0.00";
    totals.push({ rowNumber, total: subjectGroups.reduce((sum, group) => sum + scores.get(String(student.id) + ":" + group.subjectId).total, 0) });
  });

  const orderedTotals = [...totals].sort((a, b) => b.total - a.total);
  const ranks = new Map();
  orderedTotals.forEach((item, index) => {
    if (index === 0 || Math.abs(item.total - orderedTotals[index - 1].total) > 1e-9) ranks.set(item.rowNumber, index + 1);
    else ranks.set(item.rowNumber, ranks.get(orderedTotals[index - 1].rowNumber));
  });
  for (const item of totals) sheet.getCell(item.rowNumber, positionColumn).value = ranks.get(item.rowNumber);

  sheet.autoFilter = { from: { row: 4, column: 1 }, to: { row: 4 + roster.length, column: lastColumn } };
  const formulaCalculation = calculateWorkbookFormulas(workbook);
  const buffer = await workbook.xlsx.writeBuffer();
  return {
    buffer,
    formulaCalculation,
    studentCount: roster.length,
    subjectCount: subjects.length,
    subjectIds,
    worksheetName: sheet.name,
    assessmentComponentCount: columns.filter((column) => column.kind !== "subject-total").length,
    rankingMethod: "competition-rank-by-grand-total",
  };
}
