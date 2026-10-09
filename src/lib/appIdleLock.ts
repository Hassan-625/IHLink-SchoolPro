export const APP_IDLE_LOCK_MS=2*60*1000;
type IdleEnvironment={
 activity:EventTarget;
 visibility:EventTarget&{readonly visibilityState:string};
 now:()=>number;
 setTimer:(callback:()=>void,delay:number)=>number;
 clearTimer:(timer:number)=>void;
};
export function startAppIdleLock(onLock:()=>void,timeoutMs=APP_IDLE_LOCK_MS,env:IdleEnvironment={
 activity:window,visibility:document,now:()=>performance.now(),
 setTimer:(callback,delay)=>window.setTimeout(callback,delay),clearTimer:timer=>window.clearTimeout(timer)
}){
 let deadline=env.now()+timeoutMs,timer:number|undefined,stopped=false;
 const events=['pointerdown','pointermove','keydown','scroll'];
 function dispose(){if(stopped)return;stopped=true;if(timer!==undefined)env.clearTimer(timer);for(const event of events)env.activity.removeEventListener(event,activity,true);env.visibility.removeEventListener('visibilitychange',visibility);}
 function lock(){if(stopped)return;dispose();onLock();}
 function arm(){if(timer!==undefined)env.clearTimer(timer);timer=env.setTimer(check,Math.max(1,deadline-env.now()));}
 function check(){if(stopped)return;if(env.now()>=deadline)lock();else arm();}
 function activity(){if(stopped)return;if(env.now()>=deadline){lock();return;}deadline=env.now()+timeoutMs;}
 function visibility(){if(env.visibility.visibilityState==='hidden')lock();else check();}
 for(const event of events)env.activity.addEventListener(event,activity,{capture:true,passive:true});
 env.visibility.addEventListener('visibilitychange',visibility);
 if(env.visibility.visibilityState==='hidden')lock();else arm();
 return dispose;
}
