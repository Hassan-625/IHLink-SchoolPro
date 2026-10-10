const managers:Record<string,readonly string[]>={
 library:['librarian'],transport:['transport_manager'],hostel:['hostel_manager'],inventory:['inventory_officer'],
 promotions:['registrar','head_teacher','vice_principal'],calendar:['registrar','head_teacher','vice_principal'],
 payroll:['accountant','bursar'],medical:['nurse','counsellor','head_teacher'],leave:['hr_officer'],
};
export function canManageSchoolOperation(kind:string,role:string){
 const value=role.trim().toLowerCase().replaceAll(' ','_');
 if(['proprietor','administrator','super_admin','super_administrator'].includes(value))return true;
 return (managers[kind]||[]).includes(value);
}
