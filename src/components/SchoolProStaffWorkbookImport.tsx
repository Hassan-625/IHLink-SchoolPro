import ExcelJS from "exceljs";
import { useState, type ChangeEvent } from "react";
import { Button } from "@/components/ui/Button";
import { supabase } from "@/lib/supabase";

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
    case "principal": return "principal";
    case "vice principal": return "vice_principal";
    default: return "";
  }
};

export function SchoolProStaffWorkbookImport({ schoolName, schoolId }: { schoolName: string; schoolId: string }) {
  const [file, setFile] = useState<File | null>(null);
  const [rows, setRows] = useState<ImportRow[]>([]);
  const [issues, setIssues] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);
  const [workbookName, setWorkbookName] = useState("");
  const [provisioning, setProvisioning] = useState(false);
  const [progress, setProgress] = useState({ done: 0, total: 0 });
  const [provisionResults, setProvisionResults] = useState<{ email: string; status: "created" | "invited" | "already_member" | "failed"; message?: string }[]>([]);
  const [appointmentResults, setAppointmentResults] = useState<{ email: string; assignment: string; status: "assigned" | "failed"; message?: string }[]>([]);
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
        const sourceTitle = key(r.position || "Board Member");
        const validBoardTitles = new Map([
          ["chairperson", "Chairperson"],
          ["director", "Director"],
          ["co owner", "Co-owner"],
          ["owner", "Owner"],
          ["board secretary", "Board Secretary"],
          ["board member", "Board Member"],
          ["executive director", "Executive Director"],
          ["deputy director", "Deputy Director"],
        ]);
        // The HA workbook uses numbered placeholders rather than governance
        // titles. Assign five distinct, least-privilege designations in sheet
        // order; explicit titles in a future workbook always take precedence.
        const numberedBoardTitle = sourceTitle.match(/^board member\s+(\d+)$/);
        const defaultBoardTitles = ["Owner", "Co-owner", "Director", "Executive Director", "Board Secretary"];
        const boardTitle = numberedBoardTitle
          ? defaultBoardTitles[Number(numberedBoardTitle[1]) - 1]
          : validBoardTitles.get(sourceTitle);
        if (!boardTitle) { errors.push("HA Board row " + n + ": unsupported Board designation '" + (r.position || "") + "'."); return null; }
        return { source: "Board", email: r.email.toLowerCase(), firstName: r["first name"], middleName: r["middle name"] || "", surname: r["last name"], phone: r.phone || "", role: "board_member", position: boardTitle, section: null, assignedClass: null };
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
  async function provisionAccounts() {
    if (!supabase || !schoolId || !rows.length || provisioning) return;
    if (key(schoolName) !== "ha academy") { setIssues(["Select the HA ACADEMY workspace before provisioning this HA-only workbook."]); return; }
    const confirmed = window.confirm(`Create or link the ${rows.length} validated HA Academy staff, administrator and Board accounts? New accounts receive the surname-based temporary first-login credential and must change it immediately. Existing students and the current Exam Officer account are not reimported.`);
    if (!confirmed) return;
    setProvisioning(true);
    setProvisionResults([]);
    setProgress({ done: 0, total: rows.length });
    const results: { email: string; status: "created" | "invited" | "already_member" | "failed"; message?: string }[] = [];
    try {
      for (const row of rows) {
        try {
          const { data: existingProfile, error: profileError } = await supabase.from("profiles").select("id").ilike("email", row.email).maybeSingle();
          if (profileError) throw profileError;
          if (existingProfile?.id) {
            const { data: existingMember, error: memberError } = await supabase.from("schoolpro_members").select("id").eq("school_id", schoolId).eq("user_id", existingProfile.id).maybeSingle();
            if (memberError) throw memberError;
            if (existingMember?.id) {
              results.push({ email: row.email, status: "already_member" });
              setProvisionResults([...results]);
              setProgress({ done: results.length, total: rows.length });
              continue;
            }
          }
          const { data, error } = await supabase.functions.invoke("invite-school-staff", {
            body: { schoolId, email: row.email, role: row.role, firstName: row.firstName, middleName: row.middleName, surname: row.surname, phone: row.phone || null }
          });
          if (error) throw error;
          if (data?.error) throw new Error(String(data.error));
          results.push({ email: row.email, status: data?.created ? "created" : "invited", message: data?.created ? undefined : "Existing account requires invitation acceptance." });
        } catch (error) {
          results.push({ email: row.email, status: "failed", message: error instanceof Error ? error.message : "Provisioning failed." });
        }
        setProvisionResults([...results]);
        setProgress({ done: results.length, total: rows.length });
      }
      // Apply workbook responsibilities only after account processing. Resolve
      // members by exact email within this school; never guess a class or user.
      const emails = rows.map(row => row.email);
      const { data: profiles, error: profilesError } = await supabase.from("profiles").select("id,email").in("email", emails);
      if (profilesError) throw profilesError;
      const userIds = (profiles || []).map(profile => profile.id);
      const { data: members, error: membersError } = await supabase.from("schoolpro_members").select("id,user_id,role").eq("school_id", schoolId).in("user_id", userIds);
      if (membersError) throw membersError;
      const profileByEmail = new Map((profiles || []).map(profile => [key(profile.email || ""), profile.id]));
      const memberByUser = new Map((members || []).map(member => [member.user_id, member]));
      const { data: classes, error: classesError } = await supabase.from("schoolpro_classes").select("id,name,arm").eq("school_id", schoolId).is("archived_at", null);
      if (classesError) throw classesError;
      const classKey = (name: string, arm?: string | null) => key([name, arm].filter(Boolean).join(" "));
      const appointmentOutcomes: { email: string; assignment: string; status: "assigned" | "failed"; message?: string }[] = [];
      for (const row of rows) {
        const userId = profileByEmail.get(key(row.email));
        const member = userId ? memberByUser.get(userId) : null;
        if (!member) {
          if (row.role === "board_member" || row.role === "head_teacher" || row.role === "class_teacher") {
            appointmentOutcomes.push({ email: row.email, assignment: row.position, status: "failed", message: "Account is not yet a member of this school; resolve provisioning first." });
          }
          continue;
        }
        if (row.role === "class_teacher" && row.assignedClass && key(row.assignedClass) !== "to be allocated") {
          const matches = (classes || []).filter(item => classKey(item.name, item.arm) === key(row.assignedClass!) || key(item.name) === key(row.assignedClass!));
          if (matches.length !== 1) {
            appointmentOutcomes.push({ email: row.email, assignment: "Form Master · " + row.assignedClass, status: "failed", message: matches.length ? "Class name is ambiguous; no assignment was made." : "No exact active class match; no assignment was made." });
          } else {
            const { error } = await supabase.rpc("schoolpro_set_form_master", { p_class: matches[0].id, p_member: member.id });
            appointmentOutcomes.push({ email: row.email, assignment: "Form Master · " + row.assignedClass, status: error ? "failed" : "assigned", message: error?.message });
          }
        }
        if (row.role === "head_teacher" && row.section) {
          const sectionKey = key(row.section).replace(/ section$/, "");
          const section = ({ nursery: "nursery", primary: "primary", "junior secondary": "junior_secondary", "senior secondary": "senior_secondary", other: "other" } as Record<string, string>)[sectionKey];
          if (!section) {
            appointmentOutcomes.push({ email: row.email, assignment: "Section Head · " + row.section, status: "failed", message: "Workbook section does not match a supported school section." });
          } else {
            const { error } = await supabase.rpc("schoolpro_set_section_leader", { p_school: schoolId, p_member: member.id, p_section: section, p_assigned: true });
            appointmentOutcomes.push({ email: row.email, assignment: "Section Head · " + row.section, status: error ? "failed" : "assigned", message: error?.message });
          }
        }
        if (row.role === "board_member" && row.position) {
          const { error } = await supabase.rpc("schoolpro_set_board_role", { p_school: schoolId, p_member: member.id, p_title: row.position });
          appointmentOutcomes.push({ email: row.email, assignment: "Board · " + row.position, status: error ? "failed" : "assigned", message: error?.message });
        }
      }
      setAppointmentResults(appointmentOutcomes);
    } catch (error) {
      setIssues([error instanceof Error ? error.message : "Account provisioning or workbook appointments could not be completed."]);
    } finally {
      setProvisioning(false);
    }
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
        <table className="w-full text-left text-xs"><thead className="sticky top-0 bg-slate-50"><tr>{["Name","Email","Access role","Workbook responsibility"].map(x=><th key={x} className="p-2">{x}</th>)}</tr></thead><tbody>{rows.map((r,i)=><tr key={r.email} className="border-t"><td className="p-2">{r.firstName} {r.middleName} {r.surname}</td><td className="p-2">{r.email}</td><td className="p-2">{r.role === "administrator" ? "School Administrator" : r.role === "principal" ? "Principal" : r.role.replaceAll("_"," ")}</td><td className="p-2">{r.position}{r.assignedClass ? " · " + r.assignedClass : ""}{r.section && r.role === "head_teacher" ? " · " + r.section : ""}</td></tr>)}</tbody></table>
      </div>
      <p className="text-sm text-muted">Validated {rows.length} records. The Proprietor / School Owner workbook row is mapped to School Administrator, with no ownership transfer. The five Board records use the separate least-privilege Board Member role. Subject Teachers remain unallocated.</p>
      <div className="flex flex-wrap items-center gap-3">
        <Button disabled={provisioning || !schoolId || rows.length !== 59} onClick={() => void provisionAccounts()}>{provisioning ? `Provisioning ${progress.done}/${progress.total}…` : "Create / link 59 staff accounts"}</Button>
        <p className="text-xs text-muted">New accounts use the approved surname-first-login challenge; passwords are never displayed here.</p>
      </div>
      {!!provisionResults.length && <div className="rounded-lg border p-3 text-sm" role="status">
        <p className="font-semibold">Provisioning progress: {progress.done}/{progress.total}</p>
        <p className="mt-1">Created: {provisionResults.filter(x=>x.status==="created").length} · Invitation required: {provisionResults.filter(x=>x.status==="invited").length} · Already members: {provisionResults.filter(x=>x.status==="already_member").length} · Failed: {provisionResults.filter(x=>x.status==="failed").length}</p>
        {provisionResults.some(x=>x.status==="failed") && <ul className="mt-2 list-disc pl-5">{provisionResults.filter(x=>x.status==="failed").map(x=><li key={x.email}>{x.email}: {x.message}</li>)}</ul>}
      </div>}
      {!!appointmentResults.length && <div className="rounded-lg border p-3 text-sm" role="status">
        <p className="font-semibold">Workbook appointments: {appointmentResults.filter(x=>x.status==="assigned").length} assigned · {appointmentResults.filter(x=>x.status==="failed").length} need attention</p>
        <ul className="mt-2 space-y-1">{appointmentResults.map((item,i)=><li key={item.email+"-"+item.assignment+"-"+i} className="flex flex-wrap gap-2"><span className={item.status==="assigned"?"text-emerald-700":"text-rose-700"}>{item.status==="assigned"?"Assigned":"Not assigned"}</span><span>{item.assignment} — {item.email}</span>{item.message&&<span className="text-muted">({item.message})</span>}</li>)}</ul>
      </div>}
      <p className="text-sm font-medium text-amber-800">Email delivery is not part of this workflow. Unmatched classes or unsupported sections are reported and never guessed. Board appointments use the existing least-privilege governance RPC.</p>
    </div>}
  </section>;
}
