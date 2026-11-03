import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const migration = readFileSync('supabase/migrations/20261103110000_schoolpro_production_graduation_certificates.sql', 'utf8');
const studio = readFileSync('src/pages/schoolpro/SchoolProDocumentStudio.tsx', 'utf8');
const testingWorker = readFileSync('supabase/functions/schoolpro-testing-certificate-worker/index.ts', 'utf8');
const integration = readFileSync('scripts/test-schoolpro-production-graduation-certificates.integration.sql', 'utf8');

assert.match(migration, /trg_schoolpro_graduation_certificate_issue/);
assert.match(migration, /v_student\.status <> 'graduated'/);
assert.match(migration, /p\.decision = 'graduated'/);
assert.match(migration, /p\.status = 'applied'/);
assert.match(migration, /document_type = 'certificate'/);
assert.match(migration, /is_active = true/);
assert.match(migration, /issued_by=auth\.uid\(\)/);
assert.match(migration, /schoolpro_document_issue_events/);
assert.match(migration, /revoke all on function public\.finalize_schoolpro_document_issue/);
const executableMigration = migration.replace(/^\s*--.*$/gm, '');
assert.doesNotMatch(executableMigration, /schoolpro_finalize_testing_certificate|IH-TST-|synthetic/);

assert.match(studio, /class_name,status/);
assert.match(studio, /s\.status==='graduated'/);
assert.match(studio, /s\?\.status!=='graduated'/);
assert.match(studio, /progression_session:t\?\.document_type==='certificate'\?issue\.session/);
assert.match(studio, /Choose a certificate template and a class containing graduated students/);

assert.match(integration, /position\('Only graduated students'/);
assert.match(integration, /position\('An applied graduation decision'/);
assert.match(integration, /position\('Not authorized to issue graduation certificates'/);
assert.match(integration, /schoolpro_document_issue_events/);
assert.match(integration, /Generic document issuance regressed/);

// The existing synthetic-only worker must remain isolated and unchanged in purpose.
assert.match(testingWorker, /IH-TST-/);
assert.match(testingWorker, /payload\?\.synthetic!==true/);
console.log('PASS: production certificate issuance is restricted to graduated students with an applied graduation decision, an active same-school certificate template, authorized staff, and audited finalization. Testing-only worker remains isolated.');
