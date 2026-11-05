import type {ReactNode} from 'react';
import {useLocation,Link} from 'react-router-dom';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {canManageSchoolBilling} from '@/lib/schoolAccess';
import {useSchoolProEntitlements} from '@/hooks/useSchoolProEntitlements';
import {useAuth} from '@/context/AuthContext';

// A pending school may prepare its core workspace while IHLink reviews payment.
// Paid-plan features remain independently protected by SchoolProEntitlementGate.
const PRE_ACTIVATION_WORKSPACE_PATHS = new Set([
 '/schoolpro/proprietor-dashboard',
 '/schoolpro/admin-dashboard',
 '/schoolpro/teacher-dashboard',
 '/schoolpro/students',
 '/schoolpro/staff',
 '/schoolpro/classes',
 '/schoolpro/subjects',
 '/schoolpro/attendance',
 '/schoolpro/calendar',
 '/schoolpro/games',
 '/schoolpro/operations',
 '/schoolpro/roles-permissions',
 '/schoolpro/user-permissions',
 '/schoolpro/admissions',
 '/schoolpro/parents',
 '/schoolpro/discipline',
 '/schoolpro/house',
 '/schoolpro/houses',
 '/schoolpro/subscription',
 '/schoolpro/profile',
]);

export function SchoolProActivationGate({children}:{children:ReactNode}){
 const ctx=useSchoolProContext();
 const {profile}=useAuth();
 const {pathname}=useLocation();
 const {entitlements,loading,error}=useSchoolProEntitlements();

 // Platform administrators inspect registered workspaces without purchasing
 // a school subscription. School-level permissions and RLS still apply.
 if(profile?.role==='super_admin')return <>{children}</>;

 if(loading)return <p role="status" className="p-8">Checking school activation…</p>;
 if(error)return <p role="alert" className="p-8 text-rose-700">School activation could not be verified. Please reload.</p>;
 if(entitlements?.active)return <>{children}</>;

 // Registration and core setup remain usable while payment is pending.
 // Premium capabilities are still denied by their individual entitlement gates.
 if(PRE_ACTIVATION_WORKSPACE_PATHS.has(pathname))return <>{children}</>;

 return <main className="mx-auto max-w-xl p-8"><h1 className="text-2xl font-bold">School activation required</h1><p className="mt-4">{canManageSchoolBilling(ctx.role)?'Your school record is saved. Complete subscription review to activate the remaining school modules.':'Your school is awaiting activation. Please contact your school administrator.'}</p>{canManageSchoolBilling(ctx.role)&&<Link className="mt-5 inline-block rounded-lg bg-slate-900 px-4 py-3 text-white" to="/schoolpro/subscription">Review subscription and payment</Link>}</main>;
}
