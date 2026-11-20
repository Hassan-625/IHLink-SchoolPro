import assert from "node:assert/strict";
import ExcelJS from "exceljs";
import { expandWorksheetRowsForRoster } from "../src/lib/excelWorksheetRowExpansion.mjs";

const workbook = new ExcelJS.Workbook();
const sheet = workbook.addWorksheet("Class");
sheet.getCell("A2").value = "Roster";
sheet.getCell("B2").value = { formula: "SUM(B5:B6)" };
sheet.getCell("A3").value = "Student";
sheet.getCell("B3").value = 12;
sheet.getCell("C3").value = { formula: "B3*2" };
sheet.getCell("A4").value = "Mathematics";
sheet.getCell("B4").value = 18;
sheet.getCell("C4").value = { formula: "SUM(B3:B4)" };
sheet.getCell("A3").style = { font: { bold: true }, fill: { type: "pattern", pattern: "solid", fgColor: { argb: "FFFF00" } } };
sheet.getRow(3).height = 27;
sheet.mergeCells("A3:A4");
sheet.getCell("D7").value = { formula: "SUM(B6:B7)" };

const plan = expandWorksheetRowsForRoster(sheet, { startRow: 3, endRow: 4, repeatCount: 2 });
assert.deepEqual(plan.blocks, [{ startRow: 3, endRow: 4 }, { startRow: 5, endRow: 6 }]);
assert.equal(plan.insertedRows, 2);
assert.equal(sheet.getCell("C5").value.formula, "B5*2");
assert.equal(sheet.getCell("C6").value.formula, "SUM(B5:B6)");
assert.equal(sheet.getCell("B2").value.formula, "SUM(B7:B8)");
assert.equal(sheet.getCell("D9").value.formula, "SUM(B8:B9)");
assert.equal(sheet.getCell("A5").value, "Student");
assert.equal(sheet.getCell("B5").value, 12);
assert.equal(sheet.getRow(5).height, 27);
assert.equal(sheet.getCell("A5").isMerged, true);
assert.equal(sheet.getCell("A3").isMerged, true);
assert.equal(sheet.getCell("A5").style.font.bold, true);

const blocked = workbook.addWorksheet("Blocked");
blocked.getCell("A2").value = "x";
blocked.getCell("B2").value = { formula: "Sheet2!A1" };
assert.throws(() => expandWorksheetRowsForRoster(blocked, { startRow: 1, endRow: 2, repeatCount: 2 }), /unsupported formulas/);
assert.equal(blocked.rowCount, 2, "failed validation must not mutate the worksheet");

const merged = workbook.addWorksheet("Merged");
merged.getCell("A1").value = "x";
merged.mergeCells("A1:A3");
assert.throws(() => expandWorksheetRowsForRoster(merged, { startRow: 2, endRow: 2, repeatCount: 2 }), /merged range crosses/);
assert.equal(merged.rowCount, 3, "cross-boundary merge rejection must not mutate the worksheet");

console.log("SchoolPro ExcelJS roster row-expansion regression passed.");
