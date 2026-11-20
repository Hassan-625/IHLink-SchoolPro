import { translateFormulaRows } from "./excelFormulaRowTranslation.mjs";

const MAX_EXCEL_ROWS = 1048576;

function cloneValue(value) {
  if (value instanceof Date) return new Date(value.getTime());
  if (value && typeof value === "object") return structuredClone(value);
  return value;
}

function splitFormula(formula, transform) {
  if (typeof formula !== "string" || !formula.trim()) throw new Error("A non-empty formula is required.");
  if (/!|\\[[^\\]]+\\]|#REF!|_xlfn\\.|_xlws\\./i.test(formula)) {
    throw new Error("Cross-sheet, external, broken, structured or unsupported formulas cannot be expanded safely.");
  }
  return formula.split(/("(?:[^"]|"")*")/g).map((part, index) => index % 2 ? part : transform(part)).join("");
}

function shiftReferencesAtOrBelow(formula, threshold, delta) {
  return splitFormula(formula, part => part.replace(/(?<![A-Z0-9_.])\\$?([A-Z]{1,3})(\\$?)([1-9][0-9]*)(?![A-Z0-9_.])/gi,
    (reference, column, absoluteRow, rowText) => {
      const row = Number(rowText);
      if (absoluteRow || row < threshold) return reference;
      const next = row + delta;
      if (!Number.isSafeInteger(next) || next < 1 || next > MAX_EXCEL_ROWS) {
        throw new Error("Expanding the workbook would create an invalid formula row reference.");
      }
      return (reference.startsWith("$") ? "$" : "") + column + absoluteRow + next;
    }));
}

function rangeParts(reference) {
  const match = /^([A-Z]+)([1-9][0-9]*)(?::([A-Z]+)([1-9][0-9]*))?$/i.exec(reference);
  if (!match) throw new Error("A workbook merge could not be interpreted safely.");
  const columnNumber = letters => [...letters.toUpperCase()].reduce((n, c) => n * 26 + c.charCodeAt(0) - 64, 0);
  return { startRow: Number(match[2]), endRow: Number(match[4] || match[2]), startCol: columnNumber(match[1]), endCol: columnNumber(match[3] || match[1]) };
}

function snapshotRow(row) {
  const cells = [];
  for (let column = 1; column <= row.cellCount; column++) {
    const cell = row.getCell(column);
    cells.push({ column, value: cloneValue(cell.value), style: cloneValue(cell.style), numFmt: cell.numFmt,
      note: cloneValue(cell.note), dataValidation: cloneValue(cell.dataValidation), protection: cloneValue(cell.protection) });
  }
  return { number: row.number, height: row.height, hidden: row.hidden, outlineLevel: row.outlineLevel,
    collapsed: row.collapsed, style: cloneValue(row.style), cells };
}

function restoreRow(worksheet, rowNumber, snapshot, rowDelta) {
  const row = worksheet.getRow(rowNumber);
  row.height = snapshot.height;
  row.hidden = snapshot.hidden;
  row.outlineLevel = snapshot.outlineLevel;
  row.collapsed = snapshot.collapsed;
  row.style = cloneValue(snapshot.style || {});
  for (const item of snapshot.cells) {
    const cell = row.getCell(item.column);
    let value = cloneValue(item.value);
    if (value && typeof value === "object" && value.formula) {
      value = { ...value, formula: translateFormulaRows(value.formula, rowDelta) };
    } else if (value && typeof value === "object" && (value.sharedFormula || value.shareType === "array")) {
      throw new Error("Shared and array formulas cannot be copied into repeated student rows.");
    }
    cell.value = value;
    cell.style = cloneValue(item.style || {});
    if (item.numFmt !== undefined) cell.numFmt = item.numFmt;
    if (item.note !== undefined) cell.note = cloneValue(item.note);
    if (item.dataValidation !== undefined) cell.dataValidation = cloneValue(item.dataValidation);
    if (item.protection !== undefined) cell.protection = cloneValue(item.protection);
  }
}

/**
 * Expands a configured worksheet row block into one repeated block per roster
 * member. The original block is the first member; additional blocks are inserted
 * immediately after it. All existing rows below the insertion point are shifted.
 *
 * This is intentionally fail-closed: unsupported formulas, shared/array formulas,
 * merged ranges crossing the insertion boundary, and unsafe row limits abort.
 */
export function expandWorksheetRowsForRoster(worksheet, options = {}) {
  const startRow = Number(options.startRow);
  const endRow = Number(options.endRow);
  const repeatCount = Number(options.repeatCount);
  if (!worksheet || !Number.isInteger(startRow) || !Number.isInteger(endRow) ||
      startRow < 1 || endRow < startRow || !Number.isInteger(repeatCount) || repeatCount < 1) {
    throw new Error("A worksheet, valid source row block and positive roster size are required.");
  }
  const blockHeight = endRow - startRow + 1;
  const rowStride = Number(options.rowStride ?? blockHeight);
  if (!Number.isInteger(rowStride) || rowStride < blockHeight) {
    throw new Error("The repeated row stride must fit the complete source block.");
  }
  const insertedRows = (repeatCount - 1) * rowStride;
  const insertionRow = endRow + 1;
  if (endRow > worksheet.rowCount || insertionRow + insertedRows - 1 > MAX_EXCEL_ROWS) {
    throw new Error("The expanded class workbook exceeds Excel's worksheet row limit.");
  }
  if (!insertedRows) return { startRow, endRow, rowStride, insertedRows: 0, blocks: [{ startRow, endRow }] };

  const sourceRows = [];
  for (let row = startRow; row <= endRow; row++) sourceRows.push(snapshotRow(worksheet.getRow(row)));

  const mergeRefs = Object.keys(worksheet._merges || {});
  const sourceMerges = [];
  const preservedMerges = [];
  for (const reference of mergeRefs) {
    const bounds = rangeParts(reference);
    const intersectsSource = bounds.startRow <= endRow && bounds.endRow >= startRow;
    if (intersectsSource && !(bounds.startRow >= startRow && bounds.endRow <= endRow)) {
      throw new Error("A merged range crosses the repeated student row-block boundary.");
    }
    if (bounds.startRow < insertionRow && bounds.endRow >= insertionRow) {
      throw new Error("A merged range crosses the row insertion boundary and cannot be shifted safely.");
    }
    if (intersectsSource) sourceMerges.push(reference);
    else preservedMerges.push({ reference, bounds });
  }

  const formulas = [];
  worksheet.eachRow({ includeEmpty: true }, row => row.eachCell({ includeEmpty: true }, cell => {
    const value = cell.value;
    if (value && typeof value === "object" && (value.sharedFormula || value.shareType === "array")) {
      throw new Error("Shared and array formulas must be converted to ordinary formulas before roster expansion.");
    }
    if (value && typeof value === "object" && value.formula) formulas.push({ row: cell.row, column: cell.col, formula: value.formula, value: cloneValue(value) });
  }));

  // Validate every formula before mutating the worksheet.
  for (const item of formulas) splitFormula(item.formula, part => part);
  for (const reference of mergeRefs) worksheet.unMergeCells(reference);
  worksheet.spliceRows(insertionRow, 0, ...Array.from({ length: insertedRows }, () => []));

  // Reapply original formulas with references to shifted rows adjusted.
  for (const item of formulas) {
    const targetRow = item.row >= insertionRow ? item.row + insertedRows : item.row;
    const cell = worksheet.getCell(targetRow, item.column);
    cell.value = { ...item.value, formula: shiftReferencesAtOrBelow(item.formula, insertionRow, insertedRows) };
  }

  // Restore original merges at their post-insertion addresses.
  for (const item of preservedMerges) {
    const shift = item.bounds.startRow >= insertionRow ? insertedRows : 0;
    const reference = shift ? item.reference.replace(/([A-Z]+)([1-9][0-9]*)/gi, (m, col, row) => col + (Number(row) + shift)) : item.reference;
    worksheet.mergeCells(reference);
  }
  for (const reference of sourceMerges) worksheet.mergeCells(reference);

  const blocks = [];
  for (let index = 0; index < repeatCount; index++) {
    const blockStart = startRow + index * rowStride;
    if (index > 0) {
      for (let offset = 0; offset < blockHeight; offset++) {
        restoreRow(worksheet, blockStart + offset, sourceRows[offset], index * rowStride);
      }
      for (const reference of sourceMerges) {
        const shifted = reference.replace(/([A-Z]+)([1-9][0-9]*)/gi, (m, col, row) => col + (Number(row) + index * rowStride));
        worksheet.mergeCells(shifted);
      }
    }
    blocks.push({ startRow: blockStart, endRow: blockStart + blockHeight - 1 });
  }
  return { startRow, endRow, rowStride, insertedRows, blocks };
}
