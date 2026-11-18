declare module "hot-formula-parser" {
  export class Parser {
    on(event: "callCellValue", listener: (coordinate: any, done: (value: any) => void) => void): this;
    on(event: "callRangeValue", listener: (start: any, end: any, done: (value: any) => void) => void): this;
    parse(expression: string): { result: any; error: string | null };
  }
  export const SUPPORTED_FORMULAS: string[];
}
