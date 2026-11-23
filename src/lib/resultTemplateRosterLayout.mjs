/**
 * Builds deterministic repeated subject-row blocks for a class workbook.
 *
 * The saved subject mapping remains keyed by canonical subject ID. Each roster
 * member receives the same subject layout shifted by a fixed row stride.
 * This helper deliberately does not mutate an ExcelJS worksheet; callers must
 * expand/copy the configured worksheet rows before writing these addresses.
 */
export function buildRosterSubjectRowPlan(roster, subjects, subjectRowMappings, options = {}) {
  if (!Array.isArray(roster) || roster.length === 0) {
    throw new Error("The class roster is empty.");
  }
  if (!Array.isArray(subjects) || subjects.length === 0) {
    throw new Error("The class has no allocated catalogue subjects.");
  }
  if (!subjectRowMappings || typeof subjectRowMappings !== "object" || Array.isArray(subjectRowMappings)) {
    throw new Error("Saved subject-row mappings are invalid.");
  }

  const studentIds = roster.map((student) => String(student?.id ?? "").trim());
  if (studentIds.some((id) => !id) || new Set(studentIds).size !== studentIds.length) {
    throw new Error("Every roster student must have a unique stable ID.");
  }

  const subjectIds = subjects.map((subject) => String(subject?.subject_id ?? subject?.id ?? "").trim());
  if (subjectIds.some((id) => !id) || new Set(subjectIds).size !== subjectIds.length) {
    throw new Error("Every allocated subject must have a unique canonical subject ID.");
  }

  const rows = subjectIds.map((id) => {
    const raw = subjectRowMappings[id];
    const row = Number(raw);
    if (!Number.isInteger(row) || row < 1 || String(raw).trim() !== String(row)) {
      throw new Error("Every allocated class subject must have exactly one valid saved workbook row mapping.");
    }
    return { subjectId: id, row };
  });
  const uniqueRows = new Set(rows.map(({ row }) => row));
  if (uniqueRows.size !== rows.length) {
    throw new Error("Two subjects cannot be mapped to the same workbook row.");
  }

  const firstSubjectRow = Math.min(...rows.map(({ row }) => row));
  const lastSubjectRow = Math.max(...rows.map(({ row }) => row));
  const subjectBlockHeight = lastSubjectRow - firstSubjectRow + 1;
  const rowStride = Number(options.rowStride ?? subjectBlockHeight);
  if (!Number.isInteger(rowStride) || rowStride < subjectBlockHeight) {
    throw new Error("The repeated student row stride must fit the complete subject block.");
  }
  const maxRows = Number(options.maxRows ?? 100000);
  const finalRow = firstSubjectRow + (roster.length - 1) * rowStride + subjectBlockHeight - 1;
  if (!Number.isInteger(maxRows) || maxRows < 1 || finalRow > maxRows) {
    throw new Error("The expanded class workbook exceeds the supported worksheet row limit.");
  }

  const students = roster.map((student, index) => {
    const offset = index * rowStride;
    const subjectRows = Object.fromEntries(rows.map(({ subjectId, row }) => [subjectId, row + offset]));
    return {
      studentId: studentIds[index],
      index,
      rowOffset: offset,
      subjectRows,
      firstSubjectRow: firstSubjectRow + offset,
      lastSubjectRow: lastSubjectRow + offset,
    };
  });

  return {
    firstSubjectRow,
    lastSubjectRow,
    subjectBlockHeight,
    rowStride,
    finalRow,
    students,
  };
}
