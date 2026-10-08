export function schoolRole(role:string){return role.trim().toLowerCase().replaceAll(' ','_');}
export function canManageSchoolBilling(role:string){return ['proprietor','administrator','bursar'].includes(schoolRole(role));}
export function schoolDashboard(role:string){
 switch(schoolRole(role)){
  case 'student':return '/schoolpro/student-dashboard';
  case 'parent':return '/schoolpro/parent-dashboard';
  case 'class_teacher':case 'teacher':return '/schoolpro/teacher-dashboard';
  case 'proprietor':return '/schoolpro/proprietor-dashboard';
  case 'administrator':case 'bursar':case 'accountant':case 'super_administrator':return '/schoolpro/admin-dashboard';
  default:return '/schoolpro';
 }
}
export function schoolDashboardAllowed(path:string,role:string,globalRole?:string){
 const normalized=schoolRole(role);
 if(globalRole==='super_admin'||normalized==='super_administrator')return true;
 const management=['proprietor','administrator','bursar','accountant'];
 switch(path){
  case '/schoolpro/proprietor-dashboard':return normalized==='proprietor';
  case '/schoolpro/admin-dashboard':return management.includes(normalized);
  case '/schoolpro/teacher-dashboard':return ['teacher','class_teacher'].includes(normalized)||management.includes(normalized);
  case '/schoolpro/student-dashboard':return normalized==='student';
  case '/schoolpro/parent-dashboard':return normalized==='parent';
  default:return true;
 }
}
