import type {ReactNode} from 'react';
import {Navigate,useLocation} from 'react-router-dom';
import {useSchoolProHouseMasterAccess} from '@/hooks/useSchoolProHouseMasterAccess';

export function SchoolProHouseMasterGate({children}:{children:ReactNode}){
 const access=useSchoolProHouseMasterAccess();
 const location=useLocation();
 if(access.loading)return <div role="status" className="p-8 text-sm text-muted">Checking House Master appointment…</div>;
 if(access.error)return <div role="alert" className="p-8 text-sm text-rose-700">House Master access could not be verified. Please reload.</div>;
 return access.allowed?<>{children}</>:<Navigate to="/schoolpro/access-denied" replace state={{from:location.pathname}}/>;
}
