import {useSchoolProContext} from '@/hooks/useSchoolProContext';
import {useSchoolProPermissions} from '@/hooks/useSchoolProPermissions';
import {Logo} from '@/components/Logo';
import {type ReactNode,useEffect} from 'react';
import {Link,NavLink,useLocation,useNavigate} from 'react-router-dom';
import {Home,Wallet,Grid2X2,History,User,ArrowLeft,LifeBuoy,Bell} from 'lucide-react';
import {isNativeApp} from '@/lib/nativeAuth';
import {useAuth} from '@/context/AuthContext';
export function NativeAppShell({children}:{children:ReactNode}){
 const location=useLocation();const navigate=useNavigate();const {user}=useAuth();const school=useSchoolProContext();const permissions=useSchoolProPermissions();
 useEffect(()=>{if(isNativeApp())window.scrollTo(0,0)},[location.pathname]);
 if(!isNativeApp())return <>{children}</>;
 const home='/schoolpro'; const atHome=location.pathname===home||location.pathname==='/';
 const role=school.role.toLowerCase();const results=role==='student'?'/schoolpro/student-results':role==='parent'?'/schoolpro/parent-dashboard':permissions.can('results')?'/schoolpro/results':'/schoolpro/result-checker';
 const tabs=[{label:'Home',to:home,icon:Home},{label:'Results',to:results,icon:Grid2X2},{label:'Account',to:'/schoolpro/profile',icon:User}];
 return <div className="native-shell"><header className="native-header"><div className="flex min-w-0 items-center gap-2">{!atHome&&<button type="button" aria-label="Go back" onClick={()=>window.history.length>1?navigate(-1):navigate(home)}><ArrowLeft size={20}/></button>}<Link to={home} className="gap-2 text-sm font-extrabold"><Logo product="schoolpro" variant="icon" size="sm" disableLink/>IHLink SchoolPro</Link></div><div className="flex items-center">{user&&<Link aria-label="Notifications" to="/schoolpro/notifications"><Bell size={20}/></Link>}<Link aria-label="Help" to="/schoolpro/get-in-touch"><LifeBuoy size={20}/></Link></div></header>{children}<nav aria-label="App navigation" className="native-nav" style={{gridTemplateColumns:`repeat(${tabs.length}, minmax(0, 1fr))`}}>{tabs.map(({label,to,icon:Icon})=><NavLink key={to} to={to} end className={({isActive})=>isActive||(label==='Home'&&atHome)?'app-tab-active':''}><Icon size={21}/><span>{label}</span></NavLink>)}</nav></div>;
}
