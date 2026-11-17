import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const read = path => readFileSync(new URL(path, import.meta.url), 'utf8');
const migration = read('../supabase/migrations/20261117180000_schoolpro_atomic_member_profile_corrections.sql');
const edge = read('../supabase/functions/schoolpro-profile-correction/index.ts');
const staff = read('../src/pages/schoolpro/SchoolProStaff.tsx');
const parents = read('../src/pages/schoolpro/SchoolProParents.tsx');

assert.match(migration, /create or replace function public\.schoolpro_correct_member_profile_atomic/);
assert.match(migration, /school_owner = p_actor_id/);
assert.match(migration, /actor_role in \('proprietor', 'administrator'\)/);
assert.match(migration, /r\.responsibility = 'school_admin'/);
assert.match(migration, /actor_global_role = 'super_admin'/);
assert.match(migration, /for key share/i);
assert.match(migration, /from public\.schoolpro_members m[\s\S]*?for key share/i);
assert.match(migration, /from public\.schoolpro_guardian_links g[\s\S]*?for key share/i);
assert.match(migration, /for update/i);
assert.match(migration, /update public\.profiles[\s\S]*?insert into public\.schoolpro_profile_change_audit/);
assert.match(migration, /revoke all on function public\.schoolpro_correct_member_profile_atomic[\s\S]*?from public, anon, authenticated/i);
assert.match(migration, /grant execute on function public\.schoolpro_correct_member_profile_atomic[\s\S]*?to service_role/i);
assert.match(migration, /before_values jsonb not null[\s\S]*?after_values jsonb not null/i);
assert.doesNotMatch(migration, /on delete cascade/i, 'profile audit must survive school or account deletion');

assert.match(edge, /caller\.auth\.getUser\(token\)/);
assert.match(edge, /admin\.rpc\('schoolpro_correct_member_profile_atomic'/);
assert.match(edge, /p_actor_id: actor\.id/);
assert.match(edge, /firstName/);
assert.match(edge, /middleName/);
assert.match(edge, /lastName/);
assert.match(edge, /phone/);
assert.doesNotMatch(edge, /body\.email|p_email|updateUserById|auth\.admin\.updateUser/i, 'email and Auth identity must not be changed');
assert.doesNotMatch(edge, /profiles'\)\.update/i, 'all profile writes must pass through the atomic database RPC');

assert.match(staff, /profile:profiles!schoolpro_members_user_id_fkey\([^)]*phone/);
assert.match(staff, /schoolpro-profile-correction/);
assert.match(staff, /Edit profile/);
assert.match(staff, /visible in every school linked to that same account/);
assert.match(parents, /profile:profiles!schoolpro_guardian_links_guardian_user_id_fkey\([^)]*middle_name[^)]*phone/);
assert.match(parents, /schoolpro-profile-correction/);
assert.match(parents, /Edit profile/);
assert.match(parents, /visible in every school linked to that account/);

console.log('PASS: staff/guardian profile correction is school-authorized, identity-aware, email-isolated, membership-locked and atomically audited.');
