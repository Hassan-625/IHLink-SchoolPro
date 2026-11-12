import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const games = readFileSync('src/pages/schoolpro/SchoolProGames.tsx', 'utf8');
const houseMaster = readFileSync('src/pages/schoolpro/SchoolProHouseDashboard.tsx', 'utf8');
const routes = readFileSync('src/App.tsx', 'utf8');

assert.match(games, /schoolpro_student_house_history/);
assert.match(games, /\.is\('effective_to',\s*null\)/);
assert.match(games, /class_name/);
assert.match(games, /houseRosterGroups/);
assert.match(games, /School-wide house roster/);
assert.match(games, /Unassigned/);
assert.match(games, /student\.middle_name/);
assert.match(games, /student\.classLabel/);
assert.match(games, /\.eq\('status',\s*'active'\)/);
assert.match(games, /permission="games"/);
assert.match(houseMaster, /schoolpro_house_master_roster/);
assert.match(houseMaster, /My House & Students/);
assert.match(routes, /path="\/schoolpro\/house-dashboard".*SchoolProHouseDashboard/);
console.log('School-wide house roster and House Master separation contracts passed.');
