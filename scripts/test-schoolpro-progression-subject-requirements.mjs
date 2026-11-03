import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migration=readFileSync('supabase/migrations/20261103100000_schoolpro_progression_subject_requirements.sql','utf8');
const prior=readFileSync('supabase/migrations/20261103090000_schoolpro_progression_repeat_threshold.sql','utf8');
const ui=readFileSync('src/components/SchoolBulkAcademicActions.tsx','utf8');

assert.match(migration,/create table if not exists public\.schoolpro_progression_subject_requirements/i);
assert.match(migration,/unique \(school_id, subject_id\)/i);
assert.match(migration,/minimum_score >= 0 and minimum_score <= 100/i);
assert.match(migration,/enable row level security/i);
assert.match(migration,/force row level security/i);
assert.match(migration,/schoolpro_validate_progression_subject_requirement/i);
assert.match(migration,/v_average < 45/i,'The default annual repeat threshold remains strictly below 45%.');
assert.match(migration,/schoolpro_progression_subject_requirements rule/i,'Only enabled school-configured subject rules should be evaluated.');
assert.match(migration,/upper\(trim\(sub\.class_name\)\) = upper\(trim\(h\.name\)\)/i,'Subject requirements must be scoped to the historical class.');
assert.match(migration,/v_subject_terms <> 3/i,'A configured subject without all three published terms must be skipped for review.');
assert.match(migration,/v_subject_average < req\.minimum_score/i,'Annual subject average must be compared with its configured minimum.');
assert.match(migration,/Failed subject requirements:/i,'Failed subject requirements must be recorded in the reviewed decision reason.');
assert.match(migration,/create_schoolpro_progression/i,'Decisions must use the existing reviewed progression creator.');
assert.match(migration,/apply_schoolpro_promotion/i,'The existing reviewed-then-apply workflow must remain.');
assert.match(migration,/private\.schoolpro_module_allowed\(p_school,'promotions'\)/i,'The progression module permission must remain enforced.');
assert.match(migration,/All three terms must be published/i,'The annual publication gate must remain.');

assert.match(prior,/v_average\s*<\s*45/i,'The preceding 45% migration remains the historical source.');
console.log('PASS: subject requirements are school-scoped, class-scoped, bounded, term-complete, audited, and integrated with reviewed progression.');
