import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const migration = await readFile("supabase/migrations/20261123090000_schoolpro_form_master_subject_selection.sql","utf8");
const component = await readFile("src/components/schoolpro/SchoolProFormMasterSubjects.tsx","utf8");
const page = await readFile("src/pages/schoolpro/SchoolProSubjects.tsx","utf8");

for (const fragment of [
  "security definer",
  "private.is_active_account()",
  "private.schoolpro_operationally_active(p_school)",
  "private.schoolpro_module_allowed(p_school, 'results')",
  "m.user_id = auth.uid()",
  "c.form_teacher_id = v_member_id",
  "c.archived_at is null",
  "s.is_catalogue_entry = true",
  "on conflict (class_id, subject_id, session) do nothing",
  "grant execute on function public.schoolpro_form_master_select_class_subject"
]) {
  assert.ok(migration.toLowerCase().includes(fragment.toLowerCase()), "Missing SQL security contract: " + fragment);
}

assert.ok(component.includes("schoolpro_form_master_select_class_subject"));
assert.ok(component.includes("item.form_teacher_id===member.id"));
assert.ok(component.includes("subjects.filter(item=>item.is_catalogue_entry)"));
assert.ok(!component.includes('.from("schoolpro_subjects").insert'));
assert.ok(page.includes("!canManage&&<SchoolProFormMasterSubjects"));
console.log("SchoolPro Form Master subject-selection contract passed.");
