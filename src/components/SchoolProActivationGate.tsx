import type {ReactNode} from 'react';
import {Link} from 'react-router-dom';
import {useSchoolProEntitlements} from '@/hooks/useSchoolProEntitlements';
export function SchoolProActivationGate({children}:{children:ReactNode}){
 const {entitlements,loading,error}=useSchoolProEntitlements();
 if(loading)return <p role="status" className="p-8">Checking school activation…</p>;
 if(error)return <p role="alert" className="p-8 text-rose-700">School activation could not be verified. Please reload.</p>;
 if(entitlements?.active)return <>{children}</>;
 return <main className="mx-auto max-w-xl p-8"><h1 className="text-2xl font-bold">School activation required</h1><p className="mt-4">Your school record is saved. Operational modules become available after verified subscription payment or an authorized Control Center activation.</p><Link className="mt-5 inline-block rounded-lg bg-slate-900 px-4 py-3 text-white" to="/schoolpro/subscription">Review subscription and payment</Link></main>;
}
