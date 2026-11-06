
import {Link,useLocation} from 'react-router-dom';
import {ShieldX} from 'lucide-react';
import {Button} from '@/components/ui/Button';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useSchoolProPermissions} from '@/hooks/useSchoolProPermissions';
import {useAuth} from '@/context/AuthContext';
import {schoolDashboard} from '@/lib/schoolAccess';
import {permissionForSchoolPath} from '@/lib/schoolPermissions';

export function SchoolProAccessDenied(){
 const ctx=useSchoolProContext();
 const {user,profile}=useAuth();
 const access=useSchoolProPermissions();
 const location=useLocation();

 const origin=(location.state as {from?:string}|null)?.from;
 const destination=ctx.schoolId
  ?schoolDashboard(ctx.role)
  :user?'/schoolpro/register?requests=1':'/schoolpro/login';

 const permission=origin?permissionForSchoolPath(origin):null;
 const portalOnly=Boolean(origin&&/\/schoolpro\/(student-|parent-dashboard|cbt\/take)/.test(origin));
 const portal=portalOnly||Boolean(origin&&/\/schoolpro\/(report-card|transcript|receipts|invoices|payments|notifications)(\/|$)/.test(origin));

 const roleAllowed=permission?access.hasRolePermission(permission,portal):null;
 const planFeature=permission?permissionForSchoolPath(origin||''):null;
 const planAllowed=permission?access.isPlanAllowed(permission):null;

 const checking=access.loading||
  Boolean(planFeature&&access.planLoading);

 const diagnosis=checking
  ?'Checking the required school access…'
  :access.error
   ?'School role permissions could not be verified. Please reload or contact your school administrator.'
   :permission&&roleAllowed===false
    ?'Your current school role does not have the permission required for this module. Contact your school administrator.'
    :permission&&access.planError
     ?'The school subscription could not be verified. Please try again.'
     :permission&&planAllowed===false
      ?'Your school role has the required permission, but this feature is not enabled on the current subscription plan.'
      :'SchoolPro could not authorize this page for the current signed-in account. Contact your school administrator.';

 const planStatus=permission&&!planFeature
  ?'No separate plan feature gate'
  :planAllowed===true
   ?'Enabled'
   :planAllowed===false
    ?'Not enabled'
    :'Not verified';

 return <main className="grid min-h-screen place-items-center bg-slate-50 p-6">
  <div className="max-w-lg rounded-3xl border bg-white p-9 text-center shadow-sm">
   <ShieldX className="mx-auto h-10 w-10 text-rose-600"/>
   <h1 className="mt-4 text-2xl font-extrabold">
    {user&&!ctx.schoolId?'School registration status':'Permission required'}
   </h1>
   <p className="mt-2 text-sm text-muted">
    {user&&!ctx.schoolId
     ?'Your account is signed in, but it is not linked to an active school workspace yet. If you have submitted a school registration request, you can follow its review status here.'
     :diagnosis}
   </p>

   {!ctx.loading&&<div className="mt-4 rounded-xl bg-slate-100 p-3 text-left text-xs text-slate-700" role="status">
    <p>Access diagnostics: {user?'Signed in':'Not signed in'} · School {ctx.schoolId?'linked':'not resolved'} · School role: {ctx.role}</p>
    {origin&&<p>Requested page: {origin}</p>}
    {permission&&<p>Required permission: {permission}</p>}
    {permission&&!checking&&<p>Role permission: {roleAllowed?'Granted':'Not granted'}</p>}
    {permission&&!checking&&<p>Plan feature: {planStatus}</p>}
    {profile?.role==='super_admin'&&<p>Super Admin access bypass: active</p>}
    {ctx.error&&<p>Context: {ctx.error}</p>}
   </div>}

   <Link to={destination}>
    <Button className="mt-5">
     {user&&!ctx.schoolId?'View my school requests':'Return to SchoolPro dashboard'}
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
