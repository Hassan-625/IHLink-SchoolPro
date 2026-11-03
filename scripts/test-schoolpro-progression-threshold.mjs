import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const migration=readFileSync('supabase/migrations/20261103090000_schoolpro_progression_repeat_threshold.sql','utf8');
const bulk=readFileSync('supabase/migrations/20261012070029_schoolpro_bulk_year_end_academic_actions.sql','utf8');
const ui=readFileSync('src/components/SchoolBulkAcademicActions.tsx','utf8');
assert.match(migration,/v_average\s*<\s*45/,'The default repeat threshold must be strictly below 45%.');
assert.doesNotMatch(migration,/v_average\s*<\s*30/,'The old 30% threshold must not remain in the replacement function.');
assert.match(migration,/All three terms must be published/,'Progression must still require all three published terms.');
assert.match(migration,/create_schoolpro_progression/,'The migration must continue to create reviewed progression decisions.');
assert.match(migration,/apply_schoolpro_promotion/,'The migration must preserve the reviewed-then-apply workflow.');
assert.match(migration,/private\.schoolpro_module_allowed\(p_school,'promotions'\)/,'Progression module permission must remain enforced.');
assert.match(bulk,/v_average<30/,'The original migration is preserved as historical migration source; the new migration supersedes it.');
assert.match(ui,/annual average below 45% repeat/i,'The UI must explain the agreed 45% default threshold.');
console.log('PASS: default progression repeat threshold is below 45%; existing published-term and reviewed-apply guards remain.');
