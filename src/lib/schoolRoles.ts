export const schoolRoleOptions=[
['proprietor','Proprietor / School Owner'],['administrator','School Administrator'],['vice_principal','Vice Principal'],['head_teacher','Head Teacher'],['bursar','Bursar'],['accountant','Accountant'],['registrar','Registrar'],['admissions_officer','Admissions Officer'],['exam_officer','Examination Officer'],['teacher','Subject Teacher'],['class_teacher','Class Teacher'],['librarian','Librarian'],['counsellor','Guidance Counsellor'],['nurse','School Nurse / Clinic Officer'],['hostel_manager','Hostel Manager'],['transport_manager','Transport Manager'],['inventory_officer','Inventory / Store Officer'],['hr_officer','HR Officer'],['receptionist','Receptionist'],['it_admin','IT Administrator']
] as const;
export const schoolRoleDescriptions:Record<string,string>={proprietor:'Full school-level ownership and oversight.',administrator:'Delegated school administration.',vice_principal:'Academic/administrative leadership.',head_teacher:'Primary/nursery academic leadership.',bursar:'Fees, collections and financial operations.',accountant:'Accounting and financial records.',registrar:'Student records and registration.',admissions_officer:'Applications, screening and admissions.',exam_officer:'Exams, CBT and result coordination.',teacher:'Assigned subjects, results and assignments.',class_teacher:'Class-level attendance, reports and pastoral records.',librarian:'Library catalogue, loans and returns.',counsellor:'Student guidance records.',nurse:'Clinic and authorized health records.',hostel_manager:'Hostel rooms and allocations.',transport_manager:'Routes and student transport.',inventory_officer:'Assets, stores and inventory.',hr_officer:'Staff records and HR workflows.',receptionist:'Front-desk and permitted enquiries.',it_admin:'School technical administration.'};
/** Canonical display labels. Authorization must continue to use the stored role codes. */
export function schoolRoleLabel(role:string|null|undefined):string {
 const code=(role||'').trim().toLowerCase().replaceAll(' ','_');
 const known=schoolRoleOptions.find(([value])=>value===code);
 if(known)return known[1];
 if(code==='super_administrator'||code==='super_admin')return 'Super Administrator';
 return code?code.split('_').map(part=>part.charAt(0).toUpperCase()+part.slice(1)).join(' '):'Not assigned';
}
export function schoolTeachingResponsibility(isCoordinator:boolean,isSubjectTeacher:boolean):string {
 if(isCoordinator&&isSubjectTeacher)return 'Form Master / Class Coordinator & Subject Teacher';
 if(isCoordinator)return 'Form Master / Class Coordinator';
 if(isSubjectTeacher)return 'Subject Teacher';
 return 'No teaching allocation';
}
