const modules:Record<string,string>={
  'admin-dashboard':'dashboard','proprietor-dashboard':'dashboard','teacher-dashboard':'dashboard',
  'student-dashboard':'dashboard','parent-dashboard':'dashboard','students':'students',
  'results':'results','result-templates':'results','report-card':'results','broadsheet':'reports',
  'class-results-print':'reports','reports':'reports','fees':'finance','payments':'finance',
  'receipts':'finance','invoices':'finance','invoice-design':'finance','subscription':'finance',
  'classes':'classes','subjects':'subjects','attendance':'attendance','timetable':'timetable',
  'assignments':'assignments','admissions':'admissions','question-bank':'cbt','cbt':'cbt',
  'library':'library','staff':'staff','parents':'parents','transport':'transport','hostel':'hostel',
  'inventory':'inventory','discipline':'discipline','medical':'medical','documents':'documents',
  'announcements':'announcements','roles-permissions':'roles','user-permissions':'roles',
  'settings':'branding','notifications':'notifications','payroll':'payroll','calendar':'calendar',
  'lesson-notes':'lesson-notes','leave':'leave','promotions':'promotions','operations':'operations',
};
export function permissionForSchoolPath(href:string){
 const page=href.split(/[?#]/)[0].replace(/^\/schoolpro\//,'').split('/')[0];
 if(page.startsWith('student-')&&page!=='student-dashboard')return modules[page.slice(8)]||null;
 return modules[page]||null;
}
export const studentReadPermissions=['dashboard','results','finance','attendance','timetable','assignments','announcements','library','cbt','notifications'];
export const parentReadPermissions=['dashboard','results','finance','attendance','announcements','notifications'];
