import {SchoolProLiveDashboard} from "./SchoolProLiveDashboard";
import {useAuth} from '@/context/AuthContext';

export function SchoolProAdminDashboard(){
 const {profile}=useAuth();
 return <SchoolProLiveDashboard roleLabel={profile?.role==='super_admin'?"IHLink Super Administrator":"School Administrator"}/>;
}
