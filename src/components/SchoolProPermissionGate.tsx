import {useSchoolClassScope} from '@/hooks/useSchoolClassScope';
import {useLocation,Navigate} from 'react-router-dom';
import type {ReactNode} from 'react';
import {useSchoolProPermissions} from '@/hooks/useSchoolProPermissions';
import {useAuth} from '@/context/AuthContext';
import {permissionPlanFeature} from '@/lib/schoolPermissions';
import {SchoolProEntitlementGate} from '@/components/SchoolProEntitlementGate';

export function SchoolProPermissionGate({
 permission,
 portal=false,
 portalOnly=false,
 children
}:{
 permission:string;
 portal?:boolean;
 portalOnly?:boolean;
 children:ReactNode
}){
 const {profile}=useAuth();
 const {can,canPortal,hasRolePermission,isPlanAllowed,loading,planLoading,error,role}=useSchoolProPermissions();
 const scope=useSchoolClassScope();
 const path=useLocation().pathname;

 if(profile?.role==='super_admin')return <>{children}</>;

 const requiresPlanCheck=Boolean(permissionPlanFeature(permission));

 if(loading||(requiresPlanCheck&&planLoading)||scope.loading)
  return <div className="p-8 text-sm text-muted">Checking school permission…</div>;

 if(error)
  return <div role="alert" className="p-8 text-rose-700">School permissions could not be verified. Please reload.</div>;

 const planFeature=permissionPlanFeature(permission);
 const rolePermission=portal?hasRolePermission(permission,true):hasRolePermission(permission);
 if(rolePermission&&planFeature&&!isPlanAllowed(permission))
  return <SchoolProEntitlementGate feature={planFeature}>{children}</SchoolProEntitlementGate>;

 if(
  ['teacher','class_teacher'].includes(role.toLowerCase())&&
  ['/schoolpro/former-students','/schoolpro/broadsheet','/schoolpro/result-templates'].includes(path)&&
  !scope.coordinatorClassIds.length
 )
  return <Navigate to="/schoolpro/access-denied" replace state={{from:path}}/>;

 return ((portal&&canPortal(permission))||(!portalOnly&&can(permission)))
  ?<>{children}</>
  :<Navigate to="/schoolpro/access-denied" replace state={{from:path}}/>;
}
