import assert from "node:assert/strict";
import { calculateWorkbookFormulas } from "../src/lib/excelFormulaCalculation.mjs";

function makeWorkbook(rows) {
  const cells = new Map();
  const columnName = (number) => {
    let value = number;
    let label = "";
    while (value > 0) {
      const remainder = (value - 1) % 26;
      label = String.fromCharCode(65 + remainder) + label;
      value = Math.floor((value - 1) / 26);
    }
    return label;
  };
  const getCell = (rowOrAddress, column) => {
    const address = typeof rowOrAddress === "string"
      ? rowOrAddress.replace(/\\$/g, "").toUpperCase()
      : columnName(column) + rowOrAddress;
    if (!cells.has(address)) {
      const cell = {
        address,
        value: null,
        get formula() {
          return this.value && typeof this.value === "object" ? this.value.formula || null : null;
        },
        get result() {
          return this.value && typeof this.value === "object" ? this.value.result : undefined;
        },
      };
      cells.set(address, cell);
    }
    return cells.get(address);
  };
  rows.forEach((row, rowIndex) => row.forEach((value, columnIndex) => {
    if (value !== undefined) getCell(rowIndex + 1, columnIndex + 1).value = value;
  }));
  const maxRow = rows.length;
  const maxColumn = Math.max(...rows.map(row => row.length));
  const sheet = {
    name: "Result",
    getCell,
    eachRow(callback) {
      for (let rowIndex = 1; rowIndex <= maxRow; rowIndex += 1) {
        callback({
          eachCell(cellCallback) {
            for (let columnIndex = 1; columnIndex <= maxColumn; columnIndex += 1) {
              const cell = getCell(rowIndex, columnIndex);
              if (cell.value !== null && cell.value !== undefined) cellCallback(cell);
            }
          },
        });
      }
    },
  };
  return { worksheets: [sheet], calcProperties: {}, sheet };
}

const workbook = makeWorkbook([
  [10, 20, { formula: "SUM(A1:B1)", result: 0 }],
  [{ formula: "C1*2", result: 0 }, { formula: "IF(A2>=60,\\"PASS\\",\\"FAIL\\")", result: "stale" }],
  [{ formula: "AVERAGE(A1:B1)", result: 0 }],
]);
const summary = calculateWorkbookFormulas(workbook);
assert.equal(summary.formulaCount, 3);
assert.equal(workbook.sheet.getCell("C1").result, 30);
assert.equal(workbook.sheet.getCell("A2").result, 60);
assert.equal(workbook.sheet.getCell("B2").result, "PASS");
assert.equal(workbook.sheet.getCell("A3").result, 15);
assert.equal(workbook.calcProperties.calcMode, "auto");
assert.equal(workbook.calcProperties.fullCalcOnLoad, true);

const circular = makeWorkbook([
  [{ formula: "B1+1", result: 0 }, { formula: "A1+1", result: 0 }],
]);
assert.throws(() => calculateWorkbookFormulas(circular), /Circular formula reference/);

const broken = makeWorkbook([
  [{ formula: "1/0", result: 0 }],
]);
assert.throws(() => calculateWorkbookFormulas(broken), /Formula calculation/);

console.log("PASS: formula dependency order, ranges, SUM, AVERAGE, IF, cached-result replacement, circular-reference rejection and calculation metadata.");
