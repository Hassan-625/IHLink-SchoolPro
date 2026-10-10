export function setupReminderDeferred(key:string){try{return Number(sessionStorage.getItem(key)||0)>Date.now()}catch{return false}}
export function deferSetupReminder(key:string){try{sessionStorage.setItem(key,String(Date.now()+24*60*60*1000))}catch{}}
