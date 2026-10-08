import type {ReactNode} from 'react';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {canManageSchoolBilling} from '@/lib/schoolAccess';
import {Link} from 'react-router-dom';
import {useSchoolProEntitlements} from '@/hooks/useSchoolProEntitlements';
export function SchoolProActivationGate({children}:{children:ReactNode}){
 const ctx=useSchoolProContext();
 const {entitlements,loading,error}=useSchoolProEntitlements();
 if(loading)return <p role="status" className="p-8">Checking school activation…</p>;
 if(error)return <p role="alert" className="p-8 text-rose-700">School activation could not be verified. Please reload.</p>;
 if(entitlements?.active)return <>{children}</>;
 return <main className="mx-auto max-w-xl p-8"><h1 className="text-2xl font-bold">School activation required</h1><p className="mt-4">{canManageSchoolBilling(ctx.role)?'Your school record is saved. Review the subscription to activate school access.':'Your school is not ready to use yet. Please contact your school administrator.'}</p>{canManageSchoolBilling(ctx.role)&&<Link className="mt-5 inline-block rounded-lg bg-slate-900 px-4 py-3 text-white" to="/schoolpro/subscription">Review subscription and payment</Link>}</main>;
}
