/**
 * Translate same-worksheet A1 references when a repeated workbook row block
 * is copied. Relative row references move by rowDelta; absolute row references
 * remain fixed. Quoted string literals are never rewritten.
 *
 * This intentionally supports the same-sheet formula subset used by the
 * SchoolPro verified calculation engine. Cross-sheet, external and structured
 * references must be rejected by the caller before translation.
 */
export function translateFormulaRows(formula, rowDelta) {
  if (typeof formula !== "string" || !formula.trim()) {
    throw new Error("A non-empty formula is required for row translation.");
  }
  if (!Number.isInteger(rowDelta)) {
    throw new Error("Formula row translation requires an integer row offset.");
  }
  if (/!|\[[^\]]+\]|#REF!|_xlfn\.|_xlws\./i.test(formula)) {
    throw new Error("Cross-sheet, external, broken or unsupported formula references cannot be translated.");
  }

  const parts = formula.split(/("(?:[^"]|"")*")/g);
  return parts.map((part, index) => {
    if (index % 2 === 1) return part;
    return part.replace(/(?<![A-Z0-9_.])\$?([A-Z]{1,3})(\$?)([1-9][0-9]*)(?![A-Z0-9_.])/gi,
      (reference, column, absoluteRow, rowText) => {
        const row = Number(rowText);
        const translated = absoluteRow ? row : row + rowDelta;
        if (!Number.isSafeInteger(translated) || translated < 1 || translated > 1048576) {
          throw new Error("Formula row translation would create an invalid Excel row reference.");
        }
        const columnPrefix = reference.startsWith("$") ? "$" : "";
        return columnPrefix + column + absoluteRow + translated;
      });
  }).join("");
}
