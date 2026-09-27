import { lazy, Suspense, type ReactNode } from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import { ProtectedRoute } from "@/components/ProtectedRoute";
import { SchoolProEntitlementGate } from "@/components/SchoolProEntitlementGate";
import { SchoolProHome } from "@/pages/schoolpro/SchoolProHome";
import { SchoolProFeatures } from "@/pages/schoolpro/SchoolProFeatures";
import { SchoolProResultManagement } from "@/pages/schoolpro/SchoolProResultManagement";
import { SchoolProPricing } from "@/pages/schoolpro/SchoolProPricing";
import { SchoolProBookDemo } from "@/pages/schoolpro/SchoolProBookDemo";
import { SchoolProRegister } from "@/pages/schoolpro/SchoolProRegister";
import { SchoolProFaq } from "@/pages/schoolpro/SchoolProFaq";
import { SchoolProSupport } from "@/pages/schoolpro/SchoolProSupport";
import { SchoolProLogin } from "@/pages/schoolpro/SchoolProLogin";
import { SchoolProResultChecker } from "@/pages/schoolpro/SchoolProResultChecker";
import { SchoolProProprietorDashboard } from "@/pages/schoolpro/SchoolProProprietorDashboard";
import { SchoolProAdminDashboard } from "@/pages/schoolpro/SchoolProAdminDashboard";
import { SchoolProStudents } from "@/pages/schoolpro/SchoolProStudents";
import { SchoolProResults } from "@/pages/schoolpro/SchoolProResults";
import { SchoolProFees } from "@/pages/schoolpro/SchoolProFees";
import { SchoolProReportCard } from "@/pages/schoolpro/SchoolProReportCard";
import { SchoolProStaff } from "@/pages/schoolpro/SchoolProStaff";
import { SchoolProClasses } from "@/pages/schoolpro/SchoolProClasses";
import { SchoolProSubjects } from "@/pages/schoolpro/SchoolProSubjects";
import { SchoolProAttendance } from "@/pages/schoolpro/SchoolProAttendance";
import { SchoolProTeacherDashboard } from "@/pages/schoolpro/SchoolProTeacherDashboard";
import { SchoolProParentDashboard } from "@/pages/schoolpro/SchoolProParentDashboard";
import { SchoolProParents } from "@/pages/schoolpro/SchoolProParents";
import { SchoolProReceipt } from "@/pages/schoolpro/SchoolProReceipt";
import { SchoolProStudentDashboard } from "@/pages/schoolpro/SchoolProStudentDashboard";
import { SchoolProModulePage } from "@/pages/schoolpro/SchoolProModulePage";
import { SchoolProQuestionBank } from "@/pages/schoolpro/SchoolProQuestionBank";
import { SchoolProBrandingSettings } from "@/pages/schoolpro/SchoolProBrandingSettings";
import { SchoolProAdmissions } from "@/pages/schoolpro/SchoolProAdmissions";
import { SchoolProRoles } from "@/pages/schoolpro/SchoolProRoles";
import { SchoolProPublicAdmission } from "@/pages/schoolpro/SchoolProPublicAdmission";
import { SchoolProCBTRunner } from "@/pages/schoolpro/SchoolProCBTRunner";
import { SchoolProCBTManager } from "@/pages/schoolpro/SchoolProCBTManager";
import { SchoolProStudentCBT } from "@/pages/schoolpro/SchoolProStudentCBT";
import { SchoolProStudentPortalView } from "@/pages/schoolpro/SchoolProStudentPortalView";
import { SchoolProCustomRequest } from "@/pages/schoolpro/SchoolProCustomRequest";
import { SchoolProSchoolSite } from "@/pages/schoolpro/SchoolProSchoolSite";
import { SchoolProAdmissionOffer } from "@/pages/schoolpro/SchoolProAdmissionOffer";
import { SchoolProCandidateCBT } from "@/pages/schoolpro/SchoolProCandidateCBT";
import { SchoolProAdmissionsWorkspace } from "@/pages/schoolpro/SchoolProAdmissionsWorkspace";
import { SchoolProOperations } from "@/pages/schoolpro/SchoolProOperations";
import { SchoolProOperationalModule } from "@/pages/schoolpro/SchoolProOperationalModule";
import { SchoolProBroadsheet } from "@/pages/schoolpro/SchoolProBroadsheet";
import { SchoolProDocumentStudio } from "@/pages/schoolpro/SchoolProDocumentStudio";
import { SchoolProDocumentVerification } from "@/pages/schoolpro/SchoolProDocumentVerification";
import { SchoolProInvoiceStudio } from "@/pages/schoolpro/SchoolProInvoiceStudio";
import { SchoolProNotifications } from "@/pages/schoolpro/SchoolProNotifications";
import { SchoolProProfile } from "@/pages/schoolpro/SchoolProProfile";
import { SchoolProAccessDenied } from "@/pages/schoolpro/SchoolProAccessDenied";
import { SchoolProPermissions } from "@/pages/schoolpro/SchoolProPermissions";
import { SchoolProInvoice } from "@/pages/schoolpro/SchoolProInvoice";
import { SchoolProPermissionGate } from "@/components/SchoolProPermissionGate";
import { ResetPasswordPage } from "@/pages/auth/ResetPasswordPage";
import { UpdatePasswordPage } from "@/pages/auth/UpdatePasswordPage";
import { VerifyEmailPage } from "@/pages/auth/VerifyEmailPage";

const SchoolProResultTemplates=lazy(()=>import("@/pages/schoolpro/SchoolProResultTemplates").then(m=>({default:m.SchoolProResultTemplates})));
const Guard=({children,permission}:{children:ReactNode;permission?:string})=><ProtectedRoute product="schoolpro" requireServiceAccess>{permission?<SchoolProPermissionGate permission={permission}>{children}</SchoolProPermissionGate>:children}</ProtectedRoute>;
const studentViews=["results","fees","attendance","timetable","assignments","announcements"] as const;

export default function App(){
 return <Routes>
  <Route path="/" element={<Navigate to="/schoolpro" replace/>}/>
  <Route path="/schoolpro" element={<SchoolProHome/>}/>
  <Route path="/schoolpro/features" element={<SchoolProFeatures/>}/>
  <Route path="/schoolpro/result-management" element={<SchoolProResultManagement/>}/>
  <Route path="/schoolpro/pricing" element={<SchoolProPricing/>}/>
  <Route path="/schoolpro/book-demo" element={<SchoolProBookDemo/>}/>
  <Route path="/schoolpro/register" element={<SchoolProRegister/>}/>
  <Route path="/schoolpro/faq" element={<SchoolProFaq/>}/>
  <Route path="/schoolpro/support" element={<SchoolProSupport/>}/>
  <Route path="/schoolpro/contact" element={<SchoolProSupport/>}/>
  <Route path="/schoolpro/login" element={<SchoolProLogin role="school"/>}/>
  <Route path="/schoolpro/parent-login" element={<SchoolProLogin role="parent"/>}/>
  <Route path="/schoolpro/student-login" element={<SchoolProLogin role="student"/>}/>
  <Route path="/schoolpro/teacher-login" element={<SchoolProLogin role="teacher"/>}/>
  <Route path="/schoolpro/result-checker" element={<SchoolProResultChecker/>}/>
  <Route path="/schoolpro/apply" element={<SchoolProPublicAdmission/>}/>
  <Route path="/schoolpro/verify-document" element={<SchoolProDocumentVerification/>}/>
  <Route path="/school/:slug" element={<SchoolProSchoolSite/>}/>
  <Route path="/schoolpro/admission/offer/:token" element={<SchoolProAdmissionOffer/>}/>
  <Route path="/schoolpro/admission/cbt/:token" element={<SchoolProCandidateCBT/>}/>
  <Route path="/schoolpro/custom" element={<SchoolProCustomRequest/>}/>

  <Route path="/schoolpro/proprietor-dashboard" element={<Guard><SchoolProProprietorDashboard/></Guard>}/>
  <Route path="/schoolpro/admin-dashboard" element={<Guard><SchoolProAdminDashboard/></Guard>}/>
  <Route path="/schoolpro/students" element={<Guard permission="students"><SchoolProStudents/></Guard>}/>
  <Route path="/schoolpro/results" element={<Guard permission="results"><SchoolProResults/></Guard>}/>
  <Route path="/schoolpro/result-templates" element={<Guard><Suspense fallback={<div className="p-6 text-sm">Loading result templates…</div>}><SchoolProResultTemplates/></Suspense></Guard>}/>
  <Route path="/schoolpro/fees" element={<Guard permission="finance"><SchoolProFees/></Guard>}/>
  <Route path="/schoolpro/invoice-design" element={<Guard permission="finance"><SchoolProInvoiceStudio/></Guard>}/>
  <Route path="/schoolpro/notifications" element={<Guard permission="notifications"><SchoolProNotifications/></Guard>}/>
  <Route path="/schoolpro/profile" element={<Guard><SchoolProProfile/></Guard>}/>
  <Route path="/schoolpro/access-denied" element={<SchoolProAccessDenied/>}/>
  <Route path="/schoolpro/receipts/:receiptId" element={<Guard permission="finance"><SchoolProReceipt/></Guard>}/>
  <Route path="/schoolpro/invoices/:invoiceId" element={<Guard permission="finance"><SchoolProInvoice/></Guard>}/>
  <Route path="/schoolpro/staff" element={<Guard permission="staff"><SchoolProStaff/></Guard>}/>
  <Route path="/schoolpro/classes" element={<Guard permission="classes"><SchoolProClasses/></Guard>}/>
  <Route path="/schoolpro/subjects" element={<Guard permission="subjects"><SchoolProSubjects/></Guard>}/>
  <Route path="/schoolpro/attendance" element={<Guard permission="attendance"><SchoolProAttendance/></Guard>}/>
  <Route path="/schoolpro/parents" element={<Guard permission="parents"><SchoolProParents/></Guard>}/>
  <Route path="/schoolpro/report-card" element={<Guard><SchoolProReportCard/></Guard>}/>
  <Route path="/schoolpro/teacher-dashboard" element={<Guard><SchoolProTeacherDashboard/></Guard>}/>
  <Route path="/schoolpro/parent-dashboard" element={<Guard><SchoolProParentDashboard/></Guard>}/>
  <Route path="/schoolpro/student-dashboard" element={<Guard><SchoolProStudentDashboard/></Guard>}/>
  <Route path="/schoolpro/admissions" element={<Guard permission="admissions"><SchoolProAdmissions/></Guard>}/>
  <Route path="/schoolpro/admissions/workspace" element={<Guard permission="admissions"><SchoolProAdmissionsWorkspace/></Guard>}/>
  <Route path="/schoolpro/operations" element={<Guard permission="operations"><SchoolProOperations/></Guard>}/>
  <Route path="/schoolpro/roles-permissions" element={<Guard permission="roles"><SchoolProRoles/></Guard>}/>
  <Route path="/schoolpro/user-permissions" element={<Guard permission="roles"><SchoolProPermissions/></Guard>}/>
  <Route path="/schoolpro/documents" element={<Guard permission="documents"><SchoolProDocumentStudio/></Guard>}/>
  <Route path="/schoolpro/broadsheet" element={<Guard permission="reports"><SchoolProEntitlementGate feature="advanced_reports"><SchoolProBroadsheet/></SchoolProEntitlementGate></Guard>}/>
  <Route path="/schoolpro/settings" element={<Guard permission="branding"><SchoolProEntitlementGate feature="custom_branding"><SchoolProBrandingSettings/></SchoolProEntitlementGate></Guard>}/>
  <Route path="/schoolpro/student-cbt" element={<Guard><SchoolProEntitlementGate feature="cbt"><SchoolProStudentCBT/></SchoolProEntitlementGate></Guard>}/>
  <Route path="/schoolpro/question-bank" element={<Guard permission="cbt"><SchoolProEntitlementGate feature="cbt"><SchoolProQuestionBank/></SchoolProEntitlementGate></Guard>}/>
  <Route path="/schoolpro/cbt" element={<Guard permission="cbt"><SchoolProEntitlementGate feature="cbt"><SchoolProCBTManager/></SchoolProEntitlementGate></Guard>}/>
  <Route path="/schoolpro/cbt/take/:testId" element={<Guard><SchoolProEntitlementGate feature="cbt"><SchoolProCBTRunner/></SchoolProEntitlementGate></Guard>}/>
  <Route path="/schoolpro/reports" element={<Guard><SchoolProEntitlementGate feature="advanced_reports"><SchoolProModulePage module="reports"/></SchoolProEntitlementGate></Guard>}/>

  {["timetable","assignments","announcements"].map(module=><Route key={module} path={"/schoolpro/"+module} element={<Guard><SchoolProModulePage module={module as "timetable"|"assignments"|"announcements"}/></Guard>}/>)}
  {["library","transport","hostel","inventory","payroll","discipline","calendar","lesson-notes","leave","promotions","medical"].map(kind=><Route key={kind} path={"/schoolpro/"+kind} element={<Guard><SchoolProOperationalModule kind={kind as any}/></Guard>}/>)}
  {studentViews.map(kind=><Route key={kind} path={"/schoolpro/student-"+kind} element={<Guard><SchoolProStudentPortalView kind={kind}/></Guard>}/>)}

  <Route path="/signin" element={<Navigate to="/schoolpro/login" replace/>}/>
  <Route path="/reset-password" element={<ResetPasswordPage/>}/>
  <Route path="/auth/update-password" element={<UpdatePasswordPage/>}/>
  <Route path="/verify-email" element={<VerifyEmailPage/>}/>
  <Route path="/register" element={<Navigate to="/schoolpro/register" replace/>}/>
  <Route path="/admin/access-denied" element={<Navigate to="/schoolpro" replace/>}/>
  <Route path="*" element={<Navigate to="/schoolpro" replace/>}/>
 </Routes>;
}
