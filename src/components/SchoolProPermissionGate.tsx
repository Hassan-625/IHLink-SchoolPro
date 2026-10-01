import type {ReactNode} from 'react';
import {Navigate} from 'react-router-dom';
import {useSchoolProPermissions} from '@/hooks/useSchoolProPermissions';
import {useAuth} from '@/context/AuthContext';
export function SchoolProPermissionGate({permission,portal=false,portalOnly=false,children}:{permission:string;portal?:boolean;portalOnly?:boolean;children:ReactNode}){
 const {profile}=useAuth();
 const {can,canPortal,loading,error}=useSchoolProPermissions();
 if(profile?.role==='super_admin')return <>{children}</>;
 if(loading)return <div className="p-8 text-sm text-muted">Checking school permission…</div>;
 if(error)return <div role="alert" className="p-8 text-rose-700">School permissions could not be verified. Please reload.</div>;
 return ((portal&&canPortal(permission))||(!portalOnly&&can(permission)))?<>{children}</>:<Navigate to="/schoolpro/access-denied" replace/>;
}
