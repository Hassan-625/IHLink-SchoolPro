import {Link,useLocation} from 'react-router-dom';
import {ShieldX} from 'lucide-react';
import {Button} from '@/components/ui/Button';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useSchoolProPermissions} from '@/hooks/useSchoolProPermissions';
import {useAuth} from '@/context/AuthContext';
import {schoolDashboard} from '@/lib/schoolAccess';
import {permissionForSchoolPath,permissionPlanFeature} from '@/lib/schoolPermissions';

export function SchoolProAccessDenied(){
 const ctx=useSchoolProContext();
 const access=useSchoolProPermissions();
 const {user,profile}=useAuth();
 const location=useLocation();

 const origin=(location.state as {from?:string}|null)?.from||'';
 const permission=origin?permissionForSchoolPath(origin):null;

 const portalOnly=Boolean(
  origin&&/^\/schoolpro\/(student-|parent-dashboard(?:\/|$)|cbt\/take(?:\/|$))/.test(origin)
 );

 const portal=portalOnly||Boolean(
  origin&&/^\/schoolpro\/(report-card|transcript|receipts|invoices|payments|notifications)(\/|$)/.test(origin)
 );

 const planFeature=permission?permissionPlanFeature(permission):null;
 const roleAllowed=permission?access.hasRolePermission(permission,portal):null;
 const planAllowed=permission?access.isPlanAllowed(permission):null;

 const checking=ctx.loading||access.loading||Boolean(planFeature&&access.planLoading);
 const checkError=ctx.error||access.error||(planFeature?access.planError:null);

 const roleDenied=roleAllowed===false;
 const planDenied=planAllowed===false;

 const title=checking
  ?'Checking access'
  :checkError
   ?'Access check could not be completed'
   :planDenied
    ?'Subscription plan required'
    :roleDenied
     ?'School role permission required'
     :'Permission required';

 const description=checking
  ?'Your school role and subscription access are being checked.'
  :checkError
   ?'SchoolPro could not verify the required access. Please reload or contact your school administrator.'
   :planDenied
    ?'This feature is not included in the active school subscription. Contact your school administrator about the required plan.'
    :roleDenied
     ?'Your current school role does not have permission to access this page. Contact your school administrator if you need access.'
     :'SchoolPro could not authorize this page for the current signed-in account. Sign in through the correct school portal or contact your school administrator.';

 const destination=ctx.schoolId
  ?schoolDashboard(ctx.role)
  :user
   ?'/schoolpro/register?requests=1'
   :'/schoolpro/login';

 return <main className="grid min-h-screen place-items-center bg-slate-50 p-6">
  <div className="max-w-lg rounded-3xl border bg-white p-9 text-center shadow-sm">
   <ShieldX className="mx-auto h-10 w-10 text-rose-600"/>
   <h1 className="mt-4 text-2xl font-extrabold">
    {user&&!ctx.schoolId?'School registration status':title}
   </h1>

   <p className="mt-2 text-sm text-muted">
    {user&&!ctx.schoolId
     ?'Your account is signed in, but it is not linked to an active school workspace yet. If you have submitted a school registration request, you can follow its review status here.'
     :description}
   </p>

   {!ctx.loading&&<div className="mt-4 rounded-xl bg-slate-100 p-3 text-left text-xs text-slate-700" role="status">
    <p>Access diagnostics: {user?'Signed in':'Not signed in'} · School {ctx.schoolId?'linked':'not resolved'} · School role: {ctx.role}</p>
    {profile?.role==='super_admin'&&<p>Super Admin access bypass: active</p>}
    {origin&&<p>Requested page: {origin}</p>}
    {permission&&<p>Required permission: {permission}</p>}
    {permission&&<p>Role permission: {checking?'Checking…':roleAllowed?'Granted':'Denied'}</p>}
    {planFeature&&<p>Plan feature ({planFeature}): {checking?'Checking…':planAllowed?'Included':'Not included'}</p>}
    {ctx.error&&<p>Context: {ctx.error}</p>}
    {access.error&&<p>Permission check: {access.error}</p>}
    {access.planError&&<p>Plan check: {access.planError}</p>}
   </div>}

   <Link to={destination}>
    <Button className="mt-5">
     {user&&!ctx.schoolId?'View my school requests':'Return to SchoolPro'}
    </Button>
   </Link>

   <p className="mt-3 text-xs text-muted">
    Student Login is only for students using school-issued admission details.
   </p>
   <Link className="mt-2 inline-block text-sm underline" to="/schoolpro/student-login">
    Student Login
   </Link>
  </div>
 </main>;
}
