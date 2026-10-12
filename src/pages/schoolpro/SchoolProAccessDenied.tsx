import {Link,useLocation} from 'react-router-dom';
import {ShieldX} from 'lucide-react';
import {Button} from '@/components/ui/Button';
import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useAuth} from '@/context/AuthContext';
import {schoolDashboard} from '@/lib/schoolAccess';

export function SchoolProAccessDenied(){
 const ctx=useSchoolProContext();
 const {user}=useAuth();
 const location=useLocation();
 const origin=(location.state as {from?:string}|null)?.from;
 const destination=ctx.schoolId?schoolDashboard(ctx.role):'/schoolpro/student-login';
 return <main className="grid min-h-screen place-items-center bg-slate-50 p-6">
  <div className="max-w-lg rounded-3xl border bg-white p-9 text-center shadow-sm">
   <ShieldX className="mx-auto h-10 w-10 text-rose-600"/>
   <h1 className="mt-4 text-2xl font-extrabold">Permission required</h1>
   <p className="mt-2 text-sm text-muted">SchoolPro could not authorize this page for the current signed-in account. Your school can review your access.</p>
   {!ctx.loading&&<div className="mt-4 rounded-xl bg-slate-100 p-3 text-left text-xs text-slate-700" role="status">
    <p>Access diagnostics: {user?'Signed in':'Not signed in'} · School {ctx.schoolId?'linked':'not resolved'} · School role: {ctx.role}</p>
    {ctx.error&&<p>Context: {ctx.error}</p>}
    {origin&&<p>Requested page: {origin}</p>}
   </div>}
   <Link to={destination}><Button className="mt-5">Return to my dashboard</Button></Link>
   <p className="mt-3 text-xs text-muted">If you expected student access, sign out of any other IHLink account and sign in again through Student Login.</p>
   <Link className="mt-2 inline-block text-sm underline" to="/schoolpro/student-login">Student Login</Link>
  </div>
 </main>;
}