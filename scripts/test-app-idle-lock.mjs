import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import ts from 'typescript';
const source=readFileSync(new URL('../src/lib/appIdleLock.ts',import.meta.url),'utf8');
const js=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;
const {startAppIdleLock,APP_IDLE_LOCK_MS}=await import('data:text/javascript;base64,'+Buffer.from(js).toString('base64'));
assert.equal(APP_IDLE_LOCK_MS,120000);
function fixture(){let now=0,next=0,locked=0;const timers=new Map();const activity=new EventTarget(),visibility=new EventTarget();visibility.visibilityState='visible';
 const stop=startAppIdleLock(()=>locked++,100,{activity,visibility,now:()=>now,setTimer:(fn,delay)=>{const id=++next;timers.set(id,{fn,at:now+delay});return id;},clearTimer:id=>timers.delete(id)});
 return {activity,visibility,stop,get locked(){return locked},get timers(){return timers.size},advance(value,run=true){now=value;if(run)for(const [id,t] of [...timers])if(t.at<=now){timers.delete(id);t.fn();}}};
}
let f=fixture();f.advance(99);assert.equal(f.locked,0);f.advance(100);assert.equal(f.locked,1);f.advance(200);assert.equal(f.locked,1);
f=fixture();f.advance(80);f.activity.dispatchEvent(new Event('keydown'));f.advance(100);assert.equal(f.locked,0);f.advance(179);assert.equal(f.locked,0);f.advance(180);assert.equal(f.locked,1);
f=fixture();f.advance(150,false);f.activity.dispatchEvent(new Event('pointerdown'));assert.equal(f.locked,1,'A delayed timer must not let the first touch extend an expired session');
f=fixture();f.visibility.visibilityState='hidden';f.visibility.dispatchEvent(new Event('visibilitychange'));assert.equal(f.locked,1,'Backgrounding locks immediately');
f=fixture();f.advance(150,false);f.visibility.dispatchEvent(new Event('visibilitychange'));assert.equal(f.locked,1,'Returning after a throttled timer locks before interaction');
f=fixture();f.stop();f.activity.dispatchEvent(new Event('scroll'));f.visibility.visibilityState='hidden';f.visibility.dispatchEvent(new Event('visibilitychange'));f.advance(1000);assert.equal(f.locked,0);assert.equal(f.timers,0,'Unmount removes listeners and timers');
console.log('PASS: two-minute default, active-use extension, delayed timers, backgrounding, resumed expiry and cleanup');
