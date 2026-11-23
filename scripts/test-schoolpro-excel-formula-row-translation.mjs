import assert from "node:assert/strict";
import { translateFormulaRows } from "../src/lib/excelFormulaRowTranslation.mjs";

assert.equal(translateFormulaRows("SUM(B13:B24)", 12), "SUM(B25:B36)");
assert.equal(translateFormulaRows("=IF(B13>0,$C$4+D13,$E13)", 12), "=IF(B25>0,$C$4+D25,$E25)");
assert.equal(translateFormulaRows('IF(A13="A13",B13,0)', 5), 'IF(A18="A13",B18,0)');
assert.equal(translateFormulaRows("$A13+A$13+$A$13", 3), "$A16+A$13+$A$13");
assert.equal(translateFormulaRows("SUM(A1:A3)", 0), "SUM(A1:A3)");
assert.throws(() => translateFormulaRows("SUM(Sheet2!A1:A3)", 1), /Cross-sheet/);
assert.throws(() => translateFormulaRows("SUM([Other.xlsx]Sheet1!A1)", 1), /Cross-sheet/);
assert.throws(() => translateFormulaRows("A1", -1), /invalid Excel row/);
assert.throws(() => translateFormulaRows("A1", 1.5), /integer row offset/);
console.log("Excel formula row translation tests passed.");
