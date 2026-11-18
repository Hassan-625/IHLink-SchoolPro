export type FormulaCalculationSummary = {
  formulaCount: number;
  evaluationCount: number;
  sheets: Array<{ name: string; formulaCount: number }>;
  engine: "hot-formula-parser";
  engineVersion: "4.0.0";
  calculationMode: "same-sheet-dependency-graph";
};
export declare function calculateWorkbookFormulas(workbook: any): FormulaCalculationSummary;
