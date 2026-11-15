import ExcelJS from "exceljs";
import { useState, type ChangeEvent } from "react";
import { Button } from "@/components/ui/Button";

type ImportRow = {
  source: string;
  email: string;
  firstName: string;
  middleName: string;
  surname: string;
  phone: string;
  role: string;
  position: string;
  section: string | null;
  assignedClass: string | null;
};
const clean = (value: unknown) => {
  if (value == null) return "";
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  if (typeof value === "object" && value && "text" in value) return String((value as { text?: unknown }).text ?? "").trim();
  if (typeof value === "object" && value && "result" in value) return String((value as { result?: unknown }).result ?? "").trim();
  return String(value).trim();
};
const key = (value: string) => value.trim().toLowerCase().replace(/[ _-]+/g, " ").replace(/\s+/g, " ");
const staffRole = (role: string) => {
  switch (key(role)) {
    case "section head": return "head_teacher";
    case "class teacher / form master":
    case "class teacher":
    case "form master": return "class_teacher";
    case "subject teacher": return "teacher";
    case "exam officer": return "exam_officer";
    case "discipline master": return "discipline_master";
    case "game master": return "game_master";
    case "librarian": return "librarian";
    case "school counsellor":
    case "school counselor":
    case "counsellor": return "counsellor";
    case "bursar": return "bursar";
    default: return "";
  }
};
const adminRole = (role: string) => {
  switch (key(role)) {
    case "proprietor / school owner":
    case "school administrator": return "administrator";
    case "principal": return "administrator";
    case "vice principal": return "vice_principal";
    default: return "";
  }
};

export function SchoolProStaffWorkbookImport({ schoolName }: { schoolName: string }) {
  const [file, setFile] = useState<File | null>(null);
  const [rows, setRows] = useState<ImportRow[]>([]);
  const [issues, setIssues] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);
  const [workbookName, setWorkbookName] = useState("");
  async function preview() {
    if (!file || busy) return;
    if (key(schoolName) !== "ha academy") { setIssues(["Select the HA ACADEMY workspace before validating this HA-only workbook."]); return; }
    setBusy(true); setRows([]); setIssues([]); setWorkbookName(file.name);
    try {
      const workbook = new ExcelJS.Workbook();
      await workbook.xlsx.load(await file.arrayBuffer() as unknown as Parameters<typeof workbook.xlsx.load>[0]);
      const requiredSheets = ["HA Staff", "HA Admins", "HA Board"];
      const missing = requiredSheets.filter(name => !workbook.getWorksheet(name));
      if (missing.length) throw new Error("The workbook is missing these HA Academy tabs: " + missing.join(", "));
      const parsed: ImportRow[] = [];
      const errors: string[] = [];
      const readSheet = (sheetName: string, map: (record: Record<string, string>, rowNumber: number) => ImportRow | null) => {
        const sheet = workbook.getWorksheet(sheetName)!;
        const headers: string[] = [];
        sheet.getRow(1).eachCell((cell, col) => { headers[col] = key(clean(cell.value)); });
        sheet.eachRow((row, rowNumber) => {
          if (rowNumber === 1) return;
          const record: Record<string, string> = {};
          row.eachCell((cell, col) => { const header = headers[col]; if (header) record[header] = clean(cell.value); });
          if (!Object.values(record).some(Boolean)) return;
          const result = map(record, rowNumber);
          if (result) parsed.push(result);
        });
      };
      readSheet("HA Staff", (r, n) => {
        const role = staffRole(r.role || "");
        if (!role) { errors.push("HA Staff row " + n + ": unsupported role '" + (r.role || "") + "'."); return null; }
        return { source: "Staff", email: (r.email || "").toLowerCase(), firstName: r["first name"] || "", middleName: r["middle name"] || "", surname: r["last name"] || r.surname || "", phone: r.phone || "", role, position: r.role || "", section: r.section || null, assignedClass: r["assigned class / scope"] || null };
      });
      readSheet("HA Admins", (r, n) => {
        const role = adminRole(r.role || "");
        if (!role) { errors.push("HA Admins row " + n + ": unsupported role '" + (r.role || "") + "'."); return null; }
        const proprietorLabel = key(r.role) === "proprietor / school owner";
        return { source: "Admins", email: (r.email || "").toLowerCase(), firstName: r["first name"] || "", middleName: r["middle name"] || "", surname: r["last name"] || "", phone: r.phone || "", role, position: proprietorLabel || key(r.role) === "school administrator" ? "School Administrator" : r.role, section: null, assignedClass: null };
      });
      readSheet("HA Board", (r, n) => {
        if (!r.email || !r["first name"] || !r["last name"]) { errors.push("HA Board row " + n + ": email, first name and surname are required."); return null; }
        return { source: "Board", email: r.email.toLowerCase(), firstName: r["first name"], middleName: r["middle name"] || "", surname: r["last name"], phone: r.phone || "", role: "board_member", position: r.position || "Board Member", section: null, assignedClass: null };
      });
      const seen = new Set<string>();
      for (const row of parsed) {
        if (!/^\S+@\S+\.\S+$/.test(row.email)) errors.push(row.source + ": invalid email for " + [row.firstName, row.surname].join(" ") + ".");
        if (!row.firstName || !row.middleName || !row.surname) errors.push(row.source + ": full first, middle and surname are required for " + row.email + ".");
        if (seen.has(row.email)) errors.push("Duplicate email in workbook: " + row.email + ".");
        seen.add(row.email);
      }
      if (parsed.length !== 59) errors.push("Expected 59 HA Academy accounts (50 staff, 4 administrators, 5 Board Members); found " + parsed.length + ".");
      const formMasters = parsed.filter(r => r.role === "class_teacher" && r.assignedClass && key(r.assignedClass) !== "to be allocated");
      const sectionHeads = parsed.filter(r => r.role === "head_teacher" && r.section);
      if (formMasters.length !== 30) errors.push("Expected 30 explicit Form Master class assignments; found " + formMasters.length + ".");
      if (sectionHeads.length !== 4) errors.push("Expected four section-head assignments; found " + sectionHeads.length + ".");
      setIssues(errors);
      if (!errors.length) setRows(parsed);
    } catch (error) {
      setIssues([error instanceof Error ? error.message : "The workbook could not be read."]);
    } finally { setBusy(false); }
  }
  function onFile(event: ChangeEvent<HTMLInputElement>) {
    const selected = event.target.files?.[0] || null;
    setFile(selected); setRows([]); setIssues([]);
  }
  const counts = {
    staff: rows.filter(r => r.source === "Staff").length,
    administrators: rows.filter(r => r.source === "Admins").length,
    board: rows.filter(r => r.source === "Board").length,
    formMasters: rows.filter(r => r.role === "class_teacher").length,
    sectionHeads: rows.filter(r => r.role === "head_teacher").length,
  };
  return <section className="rounded-xl border border-border p-4">
    <h3 className="font-bold">Import HA Academy staff, administrators & Board</h3>
    <p className="mt-1 text-sm text-muted">Select the corrected three-school workbook while the HA ACADEMY workspace is active. This preview reads only HA Staff, HA Admins and HA Board; it does not import students or create accounts.</p>
    <div className="mt-3 flex flex-wrap items-center gap-3">
      <input type="file" accept=".xlsx,.xlsm" onChange={onFile} disabled={busy} className="min-w-0 max-w-full text-sm"/>
      <Button variant="secondary" disabled={!file || busy} onClick={() => void preview()}>{busy ? "Reading workbook…" : "Validate account workbook"}</Button>
    </div>
    {workbookName && <p className="mt-2 text-xs text-muted">Workbook: {workbookName}</p>}
    {!!issues.length && <div role="alert" className="mt-3 rounded-lg border border-rose-200 bg-rose-50 p-3 text-sm text-rose-800"><p className="font-semibold">Workbook validation needs attention</p><ul className="mt-2 list-disc pl-5">{issues.map((issue, i) => <li key={i}>{issue}</li>)}</ul></div>}
    {!!rows.length && <div className="mt-3 space-y-3">
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-5">
        {[["Staff",counts.staff],["Administrators",counts.administrators],["Board",counts.board],["Form Masters",counts.formMasters],["Section Heads",counts.sectionHeads]].map(([label,value]) => <div key={label} className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-muted">{label}</p><p className="text-xl font-bold tabular-nums">{value}</p></div>)}
      </div>
      <div className="max-h-72 overflow-auto rounded-lg border">
        <table className="w-full text-left text-xs"><thead className="sticky top-0 bg-slate-50"><tr>{["Name","Email","Access role","Workbook responsibility"].map(x=><th key={x} className="p-2">{x}</th>)}</tr></thead><tbody>{rows.map((r,i)=><tr key={r.email} className="border-t"><td className="p-2">{r.firstName} {r.middleName} {r.surname}</td><td className="p-2">{r.email}</td><td className="p-2">{r.role === "administrator" ? "School Administrator" : r.role.replaceAll("_"," ")}</td><td className="p-2">{r.position}{r.assignedClass ? " · " + r.assignedClass : ""}{r.section && r.role === "head_teacher" ? " · " + r.section : ""}</td></tr>)}</tbody></table>
      </div>
      <p className="text-sm text-muted">Validated {rows.length} records. The Proprietor / School Owner workbook row is mapped to School Administrator, with no ownership transfer. The five Board records use the separate least-privilege Board Member role. Subject Teachers remain unallocated.</p>
      <p className="text-sm font-medium text-amber-800">Account creation and email sending are intentionally not triggered by this preview. The invitation delivery and post-acceptance appointment flow must be completed and verified before sending this batch.</p>
    </div>}
  </section>;
}
