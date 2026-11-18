import { Parser, SUPPORTED_FORMULAS } from "hot-formula-parser";

const MAX_FORMULA_CELLS = 10000;
const MAX_FORMULA_EVALUATIONS = 50000;
const MAX_RANGE_CELLS = 25000;
const EXCEL_ERROR = /^#(?:REF!|NAME\?|VALUE!|DIV\/0!|N\/A|NUM!|NULL!|CIRCULAR!)/i;
const SUPPORTED_FUNCTIONS = new Set(SUPPORTED_FORMULAS.map((name) => String(name).toUpperCase()));
const UNSUPPORTED_FUNCTIONS = new Set([
  "DATE", "DATEVALUE", "TIME", "TIMEVALUE", "NOW", "TODAY", "RAND", "RANDBETWEEN",
  "YEAR", "MONTH", "DAY", "HOUR", "MINUTE", "SECOND", "EDATE", "EOMONTH",
  "NETWORKDAYS", "NETWORKDAYS.INTL", "WORKDAY", "WORKDAY.INTL", "WEEKDAY", "WEEKNUM",
  "DAYS", "DATEDIF", "OFFSET", "INDIRECT",
]);

export function unsupportedWorkbookFormula(formula) {
  if (/#REF!|_xlfn\.|_xlws\.|\[[^\]]+\.(?:xlsx|xlsm|xlsb|xls)\]/i.test(formula)) {
    return "broken, external-workbook or unsupported Excel function reference";
  }
  if (formula.includes("!")) return "cross-worksheet formula references are not supported";
  if (/\[[^\]]+\]/.test(formula)) return "structured table references are not supported";
  const functions = [...formula.matchAll(/([A-Z][A-Z0-9_.]*)\s*\(/gi)].map((match) => match[1].toUpperCase());
  const unsupported = [...new Set(functions.filter((name) => UNSUPPORTED_FUNCTIONS.has(name) || !SUPPORTED_FUNCTIONS.has(name)))];
  return unsupported.length ? "formula function(s) not supported for verified calculation: " + unsupported.join(", ") : null;
}

function cellScalar(cell) {
  const value = cell?.value;
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return Date.UTC(value.getUTCFullYear(), value.getUTCMonth(), value.getUTCDate(), value.getUTCHours(), value.getUTCMinutes(), value.getUTCSeconds(), value.getUTCMilliseconds()) / 86400000 + 25569;
  if (typeof value === "object") {
    if (Array.isArray(value.richText)) return value.richText.map((part) => part.text || "").join("");
    if (typeof value.text === "string") return value.text;
    if (value.error) return value.error;
    if (Object.prototype.hasOwnProperty.call(value, "result")) return value.result;
    if (Object.prototype.hasOwnProperty.call(value, "formula")) return null;
  }
  return value;
}

/**
 * Recalculate every formula in every worksheet using a deterministic,
 * same-sheet Excel-compatible formula parser. Unsupported functions,
 * cross-sheet/external references, circular references and formula errors
 * fail the workbook closed rather than preserving stale cached values.
 */
export function calculateWorkbookFormulas(workbook) {
  if (!workbook || !Array.isArray(workbook.worksheets)) {
    throw new Error("The uploaded workbook could not be recalculated.");
  }

  let formulaCount = 0;
  let evaluationCount = 0;
  const calculatedSheets = [];

  for (const sheet of workbook.worksheets) {
    const formulas = [];
    sheet.eachRow((row) => row.eachCell((cell) => {
      if (cell.formula) {
        if (cell.value?.shareType === "array") {
          throw new Error("Array formulas are not supported for verified calculation (" + sheet.name + "!" + cell.address + "). Replace the array formula with ordinary cell formulas.");
        }
        formulas.push(cell);
      } else if (cell.value?.sharedFormula) {
        throw new Error("Shared-formula cells are not supported for verified calculation (" + sheet.name + "!" + cell.address + "). Save the workbook with individual formulas in each cell.");
      }
    }));

    formulaCount += formulas.length;
    if (formulaCount > MAX_FORMULA_CELLS) {
      throw new Error("This workbook contains too many formulas to calculate safely (maximum 10,000). Split the workbook or simplify its formula layout.");
    }

    const cache = new Map();
    const evaluating = new Set();

    const readCell = (cell) => {
      if (!cell?.formula) return cellScalar(cell);
      return evaluateCell(cell);
    };

    const evaluateCell = (cell) => {
      const address = cell.address;
      if (cache.has(address)) return cache.get(address);
      if (evaluating.has(address)) {
        throw new Error("Circular formula reference detected at " + sheet.name + "!" + address + ".");
      }
      evaluationCount += 1;
      if (evaluationCount > MAX_FORMULA_EVALUATIONS) {
        throw new Error("The workbook exceeded the safe formula evaluation limit.");
      }

      const formula = String(cell.formula || "").replace(/^=/, "");
      if (!formula.trim()) throw new Error("A formula cell is empty at " + sheet.name + "!" + address + ".");
      if (formula.length > 8192) throw new Error("The formula at " + sheet.name + "!" + address + " exceeds Excel's supported formula length.");
      const unsupportedReason = unsupportedWorkbookFormula(formula);
      if (unsupportedReason) throw new Error("Unsupported formula at " + sheet.name + "!" + address + ": " + unsupportedReason + ".");
      if (formula.includes("!") || /\[[^\]]+\]/.test(formula)) {
        throw new Error("Cross-sheet and external-workbook formula references are not supported yet (" + sheet.name + "!" + address + "). Keep formula dependencies on the same worksheet.");
      }

      evaluating.add(address);
      let callbackError = null;
      const parser = new Parser();

      parser.on("callCellValue", (coordinate, done) => {
        try {
          const label = String(coordinate?.label || "").replace(/\$/g, "");
          if (!/^[A-Z]{1,3}[1-9][0-9]*$/i.test(label)) {
            throw new Error("Unsupported cell reference in " + sheet.name + "!" + address + ".");
          }
          done(readCell(sheet.getCell(label)));
        } catch (error) {
          callbackError = error;
          done("#VALUE!");
        }
      });

      parser.on("callRangeValue", (start, end, done) => {
        try {
          const startRow = Number(start?.row?.index);
          const endRow = Number(end?.row?.index);
          const startColumn = Number(start?.column?.index);
          const endColumn = Number(end?.column?.index);
          const height = endRow - startRow + 1;
          const width = endColumn - startColumn + 1;
          if (![startRow, endRow, startColumn, endColumn].every(Number.isInteger)
            || startRow < 0 || startColumn < 0 || height < 1 || width < 1
            || height * width > MAX_RANGE_CELLS) {
            throw new Error("An invalid or oversized cell range was used by " + sheet.name + "!" + address + ".");
          }
          const values = [];
          for (let row = startRow; row <= endRow; row += 1) {
            const valuesRow = [];
            for (let column = startColumn; column <= endColumn; column += 1) {
              valuesRow.push(readCell(sheet.getCell(row + 1, column + 1)));
            }
            values.push(valuesRow);
          }
          done(values);
        } catch (error) {
          callbackError = error;
          done("#VALUE!");
        }
      });

      try {
        const parsed = parser.parse(formula);
        if (callbackError) throw callbackError;
        if (parsed?.error) {
          throw new Error("Formula calculation failed at " + sheet.name + "!" + address + " (" + parsed.error + "). Check the formula and its referenced cells.");
        }
        const result = parsed?.result;
        if (typeof result === "string" && EXCEL_ERROR.test(result)) {
          throw new Error("Formula calculation returned " + result + " at " + sheet.name + "!" + address + ".");
        }
        if (result === undefined) {
          throw new Error("Formula calculation returned no value at " + sheet.name + "!" + address + ".");
        }
        // Reassign the formula with its newly calculated result. ExcelJS keeps
        // the formula and stores this result as the workbook's cached value.
        cell.value = { formula, result };
        cache.set(address, result);
        return result;
      } finally {
        evaluating.delete(address);
      }
    };

    for (const cell of formulas) evaluateCell(cell);
    if (formulas.length) calculatedSheets.push({ name: sheet.name, formulaCount: formulas.length });
  }

  if (workbook.calcProperties) {
    Object.assign(workbook.calcProperties, {
      calcMode: "auto",
      fullCalcOnLoad: true,
      forceFullCalc: true,
    });
  }

  return {
    formulaCount,
    evaluationCount,
    sheets: calculatedSheets,
    engine: "hot-formula-parser",
    engineVersion: "4.0.0",
    calculationMode: "same-sheet-dependency-graph",
  };
}
