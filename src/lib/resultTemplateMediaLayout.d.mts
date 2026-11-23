export function repeatedBlockImageAnchor(address: string, options?: {
  studentIndex?: number;
  rowStride?: number;
  blockEndRow?: number;
  insertedRows?: number;
}): { col: number; row: number };
export function storedWorkbookImageFormat(path: string): "png" | "jpeg" | "webp";
