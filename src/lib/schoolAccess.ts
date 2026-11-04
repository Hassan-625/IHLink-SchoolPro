const schoolOperationalRoles=['administrator','bursar','accountant','vice_principal','head_teacher','exam_officer','registrar','admissions_officer','librarian','nurse','hostel_manager','transport_manager','inventory_officer','hr_officer','it_admin','counsellor','receptionist','discipline_master','game_master'];
export function schoolRole(role:string){return role.trim().toLowerCase().replaceAll(' ','_');}
export function canManageSchoolBilling(role:string){return ['proprietor','administrator','bursar'].includes(schoolRole(role));}
export function schoolDashboard(role:string){
 switch(schoolRole(role)){
  case 'student':return '/schoolpro/student-dashboard';
  case 'parent':return '/schoolpro/parent-dashboard';
  case 'class_teacher':case 'teacher':return '/schoolpro/teacher-dashboard';
  case 'proprietor':return '/schoolpro/proprietor-dashboard';
  case 'game_master':return '/schoolpro/games';
  case 'discipline_master':case 'counsellor':return '/schoolpro/discipline';
  case 'bursar':case 'accountant':return '/schoolpro/fees';
  case 'exam_officer':return '/schoolpro/results';
  case 'registrar':return '/schoolpro/students';
  case 'admissions_officer':case 'receptionist':return '/schoolpro/admissions';
  case 'librarian':return '/schoolpro/library';
  case 'transport_manager':return '/schoolpro/transport';
  case 'hostel_manager':return '/schoolpro/hostel';
  case 'inventory_officer':return '/schoolpro/inventory';
  case 'nurse':return '/schoolpro/medical';
  case 'hr_officer':return '/schoolpro/staff';
  case 'it_admin':return '/schoolpro/roles-permissions';
  case 'administrator':case 'super_administrator':return '/schoolpro/admin-dashboard';
  default:return schoolOperationalRoles.includes(schoolRole(role))?'/schoolpro/admin-dashboard':'/schoolpro';
 }
}
export function schoolDashboardAllowed(path:string,role:string,globalRole?:string){
 const normalized=schoolRole(role);
 if(globalRole==='super_admin'||normalized==='super_administrator')return true;
 const management=['proprietor','administrator','bursar','accountant'];
 switch(path){
  case '/schoolpro/proprietor-dashboard':return normalized==='proprietor';
  case '/schoolpro/admin-dashboard':return management.includes(normalized)||schoolOperationalRoles.includes(normalized);
  case '/schoolpro/teacher-dashboard':return ['teacher','class_teacher'].includes(normalized)||management.includes(normalized);
  case '/schoolpro/student-dashboard':return normalized==='student';
  case '/schoolpro/parent-dashboard':return normalized==='parent';
  default:return true;
 }
}
