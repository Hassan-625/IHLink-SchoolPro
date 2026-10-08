export function schoolRole(role:string){return role.trim().toLowerCase().replaceAll(' ','_');}
export function canManageSchoolBilling(role:string){return ['proprietor','administrator','bursar'].includes(schoolRole(role));}
export function schoolDashboard(role:string){
 switch(schoolRole(role)){
  case 'student':return '/schoolpro/student-dashboard';
  case 'parent':return '/schoolpro/parent-dashboard';
  case 'teacher':return '/schoolpro/teacher-dashboard';
  case 'proprietor':return '/schoolpro/proprietor-dashboard';
  case 'administrator':case 'bursar':case 'accountant':case 'super_administrator':return '/schoolpro/admin-dashboard';
  default:return '/schoolpro';
 }
}
