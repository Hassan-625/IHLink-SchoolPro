/**
 * Resolve ExcelJS image anchors for shared and per-student media in a
 * repeated-row class workbook. Returned row/column values are zero-based.
 */
export function repeatedBlockImageAnchor(address, options = {}) {
  const firstCell = String(address ?? "").trim().toUpperCase().split(":")[0];
  const match = /^([A-Z]{1,3})([1-9][0-9]*)$/.exec(firstCell);
  if (!match) throw new Error("A workbook image anchor must be a valid Excel cell or merged range.");
  let column = 0;
  for (const character of match[1]) column = column * 26 + character.charCodeAt(0) - 64;
  const baseRow = Number(match[2]) - 1;
  const studentIndex = options.studentIndex;
  let row = baseRow;
  if (studentIndex !== undefined && studentIndex !== null) {
    const index = Number(studentIndex);
    const stride = Number(options.rowStride);
    if (!Number.isInteger(index) || index < 0 || !Number.isInteger(stride) || stride < 1) {
      throw new Error("A student photo requires a non-negative roster index and valid repeated row stride.");
    }
    row += index * stride;
  } else {
    const blockEndRow = Number(options.blockEndRow);
    const insertedRows = Number(options.insertedRows ?? 0);
    if (!Number.isInteger(blockEndRow) || blockEndRow < 1 || !Number.isInteger(insertedRows) || insertedRows < 0) {
      throw new Error("A shared image requires a valid repeated-block end row and inserted-row count.");
    }
    if (baseRow + 1 > blockEndRow) row += insertedRows;
  }
  return { col: column - 1, row };
}

export function storedWorkbookImageFormat(path) {
  const value = String(path ?? "").toLowerCase();
  if (value.endsWith(".png")) return "png";
  if (value.endsWith(".jpg") || value.endsWith(".jpeg")) return "jpeg";
  if (value.endsWith(".webp")) return "webp";
  throw new Error("The configured workbook image must be a PNG, JPEG or WebP image.");
}
