import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const edge = readFileSync("supabase/functions/invite-school-staff/index.ts", "utf8");
const bulkStart = edge.indexOf("if(body.action==='bulk-provision-guardians')");
const bulkEnd = edge.indexOf("if(!schoolId||!", bulkStart);
assert.notEqual(bulkStart, -1, "The administrator bulk guardian action must exist.");
assert.ok(bulkEnd > bulkStart, "The bulk guardian action must close before the single-account path.");
const bulk = edge.slice(bulkStart, bulkEnd);
assert.match(bulk, /schoolpro_students/);
assert.match(bulk, /eq\('school_id',schoolId\)/, "Bulk provisioning must read only the active workspace's students.");
assert.match(bulk, /new Map<string,\{email:string;name:string;phone:string;studentIds:string\[\]\}\>\(\)/, "Repeated guardian emails must be grouped into one account.");
assert.match(bulk, /group\.studentIds\.push\(student\.id\)/, "All children for a shared guardian must be collected.");
assert.match(bulk, /schoolpro_guardian_links/, "Existing guardian links must be detected before creating new ones.");
assert.match(bulk, /schoolpro_access_invitations/, "Existing IHLink accounts must receive school-scoped pending invitations.");
assert.match(bulk, /schoolpro_set_initial_credential/, "New guardian accounts must use the established first-login credential setup RPC.");
assert.match(bulk, /p_surname:surname/, "The imported guardian surname must be the initial password.");
assert.match(bulk, /ban_duration:'876000h'/, "New guardian accounts must remain blocked until first-login password change.");
assert.match(bulk, /schoolpro_accept_access_invitation/, "New accounts must be linked through the existing invitation acceptance RPC.");
assert.match(bulk, /invitation-already-pending/, "Repeated bulk runs must not create duplicate pending invitations.");
assert.match(bulk, /createdUserId\)await admin\.auth\.admin\.deleteUser/, "A failed new-account setup must roll back the newly created Auth user.");

const parentStart = edge.indexOf("if(role==='parent'){", edge.indexOf("if(existing?.id===school.owner_id"));
assert.notEqual(parentStart, -1, "The manual parent invitation path must remain available.");
const parentEnd = edge.indexOf("\n  }", parentStart);
assert.notEqual(parentEnd, -1, "The manual parent invitation branch must close.");
const parentPath = edge.slice(parentStart, parentEnd);
assert.match(parentPath, /student_ids:studentIds/, "Manual invitations must be bound to the exact selected students.");
assert.match(parentPath, /relationship/, "The guardian relationship must be preserved.");
assert.match(parentPath, /guardianInvitation:true/, "The response must identify the manual guardian acceptance flow.");
assert.doesNotMatch(parentPath, /email_confirm|createUser|schoolpro_accept_access_invitation/, "Manual invitations must not create accounts or activate guardian links on the guardian's behalf.");

const login = readFileSync("supabase/functions/schoolpro-account-login/index.ts", "utf8");
assert.match(login, /schoolpro_initial_challenge/, "Guardians must use the existing first-login surname challenge.");
assert.match(login, /schoolpro_consume_account_challenge/, "Guardians must set a new password before a session is issued.");
assert.match(login, /ban_duration:'none'/, "The new account is unblocked only after password replacement.");

const form = readFileSync("src/components/SchoolAccountForm.tsx", "utf8");
assert.match(form, /guardianInvitation/, "The manual form must distinguish guardian invitations from staff account provisioning.");
assert.match(form, /create or sign in to an IHLink account using this exact email/i, "The guardian must authenticate with the invited email.");

const bulkUi = readFileSync("src/components/schoolpro/BulkGuardianAccountProvisioner.tsx", "utf8");
assert.match(bulkUi, /Create & Link Parent\/Guardian Accounts/);
assert.match(bulkUi, /surname as the first-login password/i);
assert.match(bulkUi, /Existing IHLink accounts keep their current passwords/i);

const parents = readFileSync("src/pages/schoolpro/SchoolProParents.tsx", "utf8");
assert.match(parents, /BulkGuardianAccountProvisioner/, "The bulk action must appear on Parents & Guardians.");
assert.match(parents, /Contact details imported with student records\. These are contact records, not IHLink parent login accounts\./, "Imported contacts must remain distinct from authenticated guardian accounts.");

const migration = readFileSync("supabase/migrations/20261112153000_schoolpro_guardian_invitation_verified_email.sql", "utf8");
assert.match(migration, /email_confirmed_at is not null/, "School-code acceptance must reject unverified Auth identities.");
assert.match(migration, /lower\(trim\(u\.email\)\)=account_email/, "Verified Auth email must match the invited profile email.");

console.log("PASS: bulk guardian grouping, surname first-login, invitation-gated existing accounts, idempotency and tenant scoping.");
