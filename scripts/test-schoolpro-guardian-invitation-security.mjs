import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const edge = readFileSync("supabase/functions/invite-school-staff/index.ts", "utf8");
const parentStart = edge.indexOf("if(role==='parent'){", edge.indexOf("if(existing?.id===school.owner_id"));
assert.notEqual(parentStart, -1, "Guardian invitation must have a dedicated parent path.");
const parentEnd = edge.indexOf("\n  }", parentStart);
assert.notEqual(parentEnd, -1, "Guardian invitation branch must close.");
const parentPath = edge.slice(parentStart, parentEnd);
const accountCreation = edge.indexOf("admin.auth.admin.createUser");
assert.ok(accountCreation > parentEnd, "Guardian invitations must not provision Auth accounts before guardian acceptance.");
assert.match(parentPath, /student_ids:studentIds/, "The invitation must be bound to the exact selected students.");
assert.match(parentPath, /relationship/, "The guardian relationship must be preserved.");
assert.match(parentPath, /expires_at:new Date\(Date.now\(\)\+7\*86400000\)/, "Guardian invitations must expire after seven days.");
assert.match(parentPath, /guardianInvitation:true/, "The response must identify the guardian acceptance flow.");
assert.doesNotMatch(parentPath, /email_confirm|createUser|schoolpro_accept_access_invitation/, "School staff must not verify an email or activate a guardian link on the guardian's behalf.");

const form = readFileSync("src/components/SchoolAccountForm.tsx", "utf8");
assert.match(form, /guardianInvitation/, "The form must distinguish guardian invitations from staff account provisioning.");
assert.match(form, /create or sign in to an IHLink account using this exact email/i, "The guardian must authenticate with the invited email.");
assert.match(form, /access activates only after the guardian accepts/i, "The UI must explain that no student access exists before acceptance.");
assert.match(form, /!parent\?\(\['firstName','middleName','surname'\]as const\):\[\]/, "Guardian identity details must be supplied by the guardian during account creation, not invented by school staff.");

const parents = readFileSync("src/pages/schoolpro/SchoolProParents.tsx", "utf8");
assert.match(parents, /Contact details imported with student records\. These are contact records, not IHLink parent login accounts\./, "Imported contacts must remain distinct from authenticated guardian accounts.");

console.log("PASS: guardian-owned account creation, exact student-bound invitation, expiry and acceptance-only activation.");
