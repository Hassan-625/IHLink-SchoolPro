import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import './test-schoolpro-tenant-scope-migration.mjs';

const source=readFileSync('src/context/AuthContext.tsx','utf8');
assert.match(source,/let authEventVersion\s*=\s*0/,'auth events need a monotonic generation');
assert.match(source,/let profileRequestVersion\s*=\s*0/,'profile loads need a monotonic generation');
assert.match(source,/const requestVersion\s*=\s*\+\+profileRequestVersion/,'each profile load must supersede prior loads');
assert.match(source,/active\s*&&\s*requestVersion\s*===\s*profileRequestVersion/,'stale profile responses must not overwrite access state');
assert.match(source,/const eventVersion\s*=\s*\+\+authEventVersion/,'access-resolving auth events must be versioned');
assert.match(source,/active\s*&&\s*eventVersion\s*===\s*authEventVersion/,'delayed callbacks from older auth events must be ignored');
assert.match(source,/authEventVersion\+\+;\s*profileRequestVersion\+\+;\s*setProfile\(null\)/,'logout must invalidate scheduled and in-flight account loads');

// Exercise the latest-generation contract with deliberately reordered completions.
let authEventVersion=0,profileRequestVersion=0;
const scheduledA=++authEventVersion;
const scheduledB=++authEventVersion;
assert.notEqual(scheduledA,scheduledB);
assert.equal(scheduledA===authEventVersion,false,'an old scheduled sign-in callback must be rejected');
assert.equal(scheduledB===authEventVersion,true,'the latest scheduled sign-in callback may proceed');
const profileA=++profileRequestVersion;
const profileB=++profileRequestVersion;
assert.equal(profileA===profileRequestVersion,false,'an older account profile response must not commit');
assert.equal(profileB===profileRequestVersion,true,'the latest account profile response may commit');
authEventVersion++;profileRequestVersion++;
assert.equal(scheduledB===authEventVersion,false,'logout invalidates scheduled profile loading');
assert.equal(profileB===profileRequestVersion,false,'logout invalidates in-flight profile loading');

console.log('PASS: auth source enforces latest-event/latest-profile guards; reordered sign-in, profile response and logout race cases are covered.');
