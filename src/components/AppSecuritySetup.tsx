import {setupReminderDeferred,deferSetupReminder} from '@/lib/securitySetupReminder';
import {useEffect,useState} from 'react';
import {useAuth} from '@/context/AuthContext';
import {androidVault,NativeVault,securitySupported,type VaultStatus} from '@/lib/nativeVault';
import {NativeAppSecurity} from './NativeAppSecurity';
import {Modal} from './ui/Modal';
import {Button} from './ui/Button';
export function AppSecuritySetup(){
 const {user}=useAuth();const reminderKey='ihlink.schoolpro.setup-reminder.'+(user?.id||'signed-out');function dismissReminder(){deferSetupReminder(reminderKey);setDismissed(true)}
 const [status,setStatus]=useState<VaultStatus|null>(null),[dismissed,setDismissed]=useState(false);
 useEffect(()=>{setStatus(null);setDismissed(setupReminderDeferred(reminderKey));if(!user||!securitySupported)return;let active=true;
  const refresh=()=>{void NativeVault.status().then(value=>{if(active)setStatus(value)}).catch(()=>{});};
  refresh();window.addEventListener('ihlink:security-changed',refresh);return()=>{active=false;window.removeEventListener('ihlink:security-changed',refresh)};
 },[user?.id]);
 const missing=status&&(!status.enabled||(status.biometricAvailable&&!status.biometricEnabled&&localStorage.getItem('ihlink.schoolpro.fingerprint-choice')!=='skipped'));
 return <Modal open={Boolean(user&&missing&&!dismissed)} title="Secure your SchoolPro account" onClose={dismissReminder} footer={<Button variant="secondary" onClick={dismissReminder}>Set up later</Button>}>
  <p className="mb-4 text-sm text-muted">Set a six-digit passcode for this device. {androidVault?'Fingerprint or device unlock is optional.':''} You can change these choices in Account.</p>
  <NativeAppSecurity setupOnly/>
 </Modal>;
}
