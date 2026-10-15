import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';

const source=readFileSync('src/hooks/useSchoolProContext.ts','utf8');

// A selected school ID is a workspace request, not proof of authorization.
for (const [fragment,reason] of [
  ["profile?.role==='super_admin'&&selected",'Super Admin selection must be explicit'],
  ["profile?.role==='super_admin'&&!selected",'Super Admin without a workspace must stay unassigned'],
  ["db.from('schoolpro_schools').select('id,name').eq('owner_id',uid)",'school ownership must be tied to the signed-in user'],
  ["if(selected)oq=oq.eq('id',selected)",'owner lookup must be constrained to the selected school'],
  ["getSchoolMembership(db,uid,selected)",'membership lookup must verify the selected school'],
  ["if(selected)sq=sq.eq('school_id',selected)",'generic student lookup must be school-scoped'],
  ["if(selected)gq=gq.eq('school_id',selected)",'generic guardian lookup must be school-scoped'],
  ["if(studentPortal)",'student portal must resolve through authenticated student identity'],
  ["if(parentPortal)",'parent portal must resolve through guardian identity'],
  [".eq('status','active')",'guardian access must require an active link'],
]) assert.ok(source.includes(fragment),reason);

assert.match(source,/const valid=requested[\s\S]*?\.test\(requested\)\?requested:null/,'URL school_id must be UUID-validated');
console.log('PASS: school-context source-contract checks cover explicit Super Admin selection and user-bound workspace resolution.');
