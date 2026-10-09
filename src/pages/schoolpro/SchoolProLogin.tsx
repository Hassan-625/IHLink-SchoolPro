import {useAuth} from '@/context/AuthContext';
import {schoolSignInDestination} from '@/lib/schoolSignIn';
import { Link, useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { PageShell } from '@/components/PageShell';
import { supabase,googleSignInAvailable } from '@/lib/supabase';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Input } from '@/components/ui/Input';
import {isNativeApp,nativeOAuthEnabled} from '@/lib/nativeAuth';
import { Logo } from '@/components/Logo';
import { Lock, Mail, ArrowRight, GraduationCap, Users, BookOpen, Award } from 'lucide-react';

interface SchoolProLoginProps {
  role: 'school' | 'parent' | 'student' | 'teacher';
}

const roleConfig = {
  school: { title: 'School Login', desc: 'Access your school management dashboard', icon: Award, color: 'purple', dashboard: '/schoolpro/proprietor-dashboard' },
  parent: { title: 'Parent Login', desc: 'View your child\'s results and submit fee receipts', icon: Users, color: 'indigo', dashboard: '/schoolpro/parent-dashboard' },
  student: { title: 'Student Login', desc: 'Check your results and assignments', icon: GraduationCap, color: 'purple', dashboard: '/schoolpro/student-dashboard' },
  teacher: { title: 'Teacher Login', desc: 'Enter scores and manage your classes', icon: BookOpen, color: 'indigo', dashboard: '/schoolpro/teacher-dashboard' },
};

export function SchoolProLogin({ role }: SchoolProLoginProps) {
  const config = roleConfig[role]; const native=isNativeApp();
  const {user,profile,loading:authLoading,signInWithGoogle}=useAuth();
  const [googleAvailable,setGoogleAvailable]=useState(false);
  const navigate = useNavigate();
  const [joiningCode,setJoiningCode]=useState(''); const [schoolCode,setSchoolCode]=useState(''); const [challenge,setChallenge]=useState(''); const [confirm,setConfirm]=useState(''); const [email,setEmail]=useState(''); const [password,setPassword]=useState(''); const [error,setError]=useState(''); const [loading,setLoading]=useState(false); const [remember,setRemember]=useState(()=>localStorage.getItem('ih_remember_device')==='1');
  useEffect(()=>{setChallenge('');setEmail('');setPassword('');setConfirm('');setSchoolCode('');setError('');},[role]);
  useEffect(()=>{const controller=new AbortController();let active=true;setGoogleAvailable(false);if(role!=='student'&&(!native||nativeOAuthEnabled))void googleSignInAvailable(controller.signal).then(enabled=>{if(active)setGoogleAvailable(enabled)});return()=>{active=false;controller.abort()}},[role,native]);
  useEffect(()=>{if(!user||authLoading)return;const returned=new URLSearchParams(window.location.search).get('oauth')==='1'||sessionStorage.getItem('ih_school_google_pending')==='1';if(!returned)return;let active=true;setLoading(true);void schoolSignInDestination(user.id,profile?.role==='super_admin').then(destination=>{if(!active)return;sessionStorage.removeItem('ih_school_google_pending');sessionStorage.removeItem('ih_auth_next');if(destination)navigate(destination,{replace:true});else setError('This Google account is not linked to a school workspace. Use the email invited by your school, or register your school as its proprietor.');}).catch(()=>{if(active)setError('Your school access could not be checked. Please try again.')}).finally(()=>{if(active)setLoading(false)});return()=>{active=false}},[user?.id,authLoading,profile?.role,navigate]);
  async function googleSignIn(){setLoading(true);setError('');sessionStorage.setItem('ih_school_google_pending','1');sessionStorage.setItem('ih_auth_next','/schoolpro/login?oauth=1');try{const message=await signInWithGoogle();if(message){sessionStorage.removeItem('ih_school_google_pending');sessionStorage.removeItem('ih_auth_next');setError(message);}}catch{sessionStorage.removeItem('ih_school_google_pending');sessionStorage.removeItem('ih_auth_next');setError('Google sign-in could not start. Please try again.');}finally{setLoading(false)}}
  const signIn=async()=>{
    sessionStorage.removeItem('ih_school_google_pending');sessionStorage.removeItem('ih_auth_next');
    if(!supabase){setError('Sign in is temporarily unavailable. Please try again.');return;}
    if(challenge&&(password.length<10||password!==confirm)){setError('Use at least 10 characters and confirm the same password.');return;}
    setLoading(true);setError('');let destination=config.dashboard;
    try{
      if(role==='student'){
        const {data,error}=await supabase.functions.invoke('schoolpro-student-login',{body:{schoolCode,admissionNumber:email,password,...(challenge?{challenge}:{})}});
        if(error||data?.error){setError(data?.error||'Sign in could not be completed. Check your details or contact your school.');return;}
        if(data?.requiresPasswordChange){setChallenge(data.challenge);setPassword('');return;}
        if(!data?.session){setError('Sign in could not be completed. Please try again.');return;}
        const {error:sessionError}=await supabase.auth.setSession(data.session);if(sessionError){setError('Sign in could not be completed. Please try again.');return;}
      }else{
        const {data,error}=await supabase.functions.invoke('schoolpro-account-login',{body:{email:email.trim(),password,...(challenge?{challenge}:{})}});
        if(error||data?.error){let feedback=data?.error;if(!feedback&&error?.context instanceof Response){const result=await error.context.clone().json().catch(()=>null);feedback=result?.error;}setError(feedback||'Your email or password was not recognised. Please try again.');return;}
        if(data?.requiresPasswordChange){setChallenge(data.challenge);setPassword('');setConfirm('');return;}
        if(!data?.session){setError('Sign in could not be completed. Please try again.');return;}
        const {data:sessionData,error:sessionError}=await supabase.auth.setSession(data.session);if(sessionError||!sessionData.user){setError('Sign in could not be completed. Please try again.');return;}
        if(joiningCode.trim()){const result=await supabase.functions.invoke('invite-school-staff',{body:{action:'accept',code:joiningCode.trim()}});if(result.error||result.data?.error){setError(result.data?.error||'This joining code could not be accepted. Check with your school.');return;}}
        destination=await schoolSignInDestination(sessionData.user.id,profile?.id===sessionData.user.id&&profile.role==='super_admin')||'/schoolpro';
      }
      if(remember)localStorage.setItem('ih_remember_device','1');else localStorage.removeItem('ih_remember_device');navigate(destination);
    }catch{setError('Sign in could not be completed. Please try again.');}finally{setLoading(false);}
  };

  return (
    <PageShell product="schoolpro" showAnnouncement={false} showHeader={false} showFooter={false}>
      <div className={native?"app-page":"min-h-screen grid grid-cols-12"}>
        {/* Left panel */}
        {!native&&<div className="col-span-12 lg:col-span-5 bg-gradient-to-br from-purple-700 via-indigo-600 to-purple-500 text-white p-10 flex flex-col justify-center">
          <Logo product="schoolpro" size="lg" variant="full" />
          <div className="mt-12">
            <config.icon className="w-12 h-12 mb-4 text-purple-200" />
            <h2 className="text-3xl font-extrabold mb-3">{config.title}</h2>
            <p className="text-purple-100 max-w-sm">{config.desc}</p>
          </div>
          <div className="mt-12 space-y-3">
            {['Secure access with encryption', 'Real-time results and updates', 'Mobile-friendly interface'].map((f, i) => (
              <div key={i} className="flex items-center gap-2 text-sm text-purple-100"><div className="w-1.5 h-1.5 rounded-full bg-purple-300" /> {f}</div>
            ))}
          </div>
        </div>}

        {/* Right panel */}
        <div className={native?"app-card":"col-span-12 lg:col-span-7 flex items-center justify-center p-10 bg-white"}>
          <div className="w-full max-w-sm">
            <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">{config.title}</Badge>
            <h1 className="text-2xl font-extrabold text-ink mb-2">{challenge?'Choose your password':'Welcome Back'}</h1>
            <p className="text-sm text-muted mb-6">{challenge?'Set your own password before opening your school records.':role==='student'?'Use your school code and admission number. Your surname is the first-time password.':`Sign in with your email. New staff and parents use their surname first, then choose a new password.`}</p>

            {googleAvailable&&!challenge&&<div className="mb-5"><Button fullWidth variant="secondary" disabled={loading} onClick={()=>void googleSignIn()}>Continue with Google</Button><p className="mt-2 text-xs text-muted">Use the Google account with the email registered or invited by your school.</p><p className="mt-4 text-center text-xs text-muted">or sign in with email</p></div>}
            <div className="space-y-4">
              {role==='student'&&<Input label="School code" value={schoolCode} disabled={Boolean(challenge)} onChange={e=>setSchoolCode(e.target.value)} placeholder="Code supplied by your school"/>}<Input label={role==='student'?'Admission number':'Email'} disabled={Boolean(challenge)} value={email} onChange={(e)=>setEmail(e.target.value)} type={role==='student'?'text':'email'} placeholder={role==='student'?'School admission number':'you@example.com'} leftIcon={<Mail className="w-4 h-4" />} themeClass="focus:ring-purple-500/20 focus:border-purple-500" />
              <div>
                <label className="block text-sm font-semibold text-ink mb-1.5">{challenge?'New password':'Password'}</label>
                <div className="relative">
                  <Input aria-label={challenge?'New password':'Password'} value={password} onChange={e=>setPassword(e.target.value)} type="password" autoComplete={challenge?'new-password':'current-password'} leftIcon={<Lock size={16}/>} />

                </div>
              </div>
              {role!=='student'&&!challenge&&<Input label="School joining code (existing accounts only)" value={joiningCode} onChange={e=>setJoiningCode(e.target.value)} placeholder="Leave blank unless your school supplied a code"/>}{challenge&&<><Input label="Confirm new password" type="password" value={confirm} onChange={e=>setConfirm(e.target.value)}/><button type="button" className="min-h-11 text-sm underline" onClick={()=>{setChallenge('');setPassword('');setConfirm('');setError('');}}>Restart activation</button></>}<div className="flex items-center justify-between">
                <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={remember} onChange={e=>setRemember(e.target.checked)} className="w-4 h-4 rounded border-border text-purple-500" /> <span className="text-ink">Remember me</span></label>
                {role!=='student'&&<Link to="/reset-password" className="text-sm font-semibold text-purple-600 hover:underline">Forgot password?</Link>}{role==='student'&&<span className="text-xs text-muted">Need a reset? Contact your school.</span>}
              </div>
              {error&&<p className="text-sm text-red-600">{error}</p>}<Button fullWidth size="lg" disabled={loading||!email||!password||(role==='student'&&!schoolCode)} themeClass="bg-purple-600 hover:bg-purple-700" rightIcon={<ArrowRight className="w-4 h-4" />} onClick={signIn}>{loading?'Please wait…':challenge?'Activate account':'Sign In'}</Button>
            </div>

            <div className="mt-6 text-center text-sm text-muted">
              {role==='school'?<>Proprietor or director? <Link to="/schoolpro/register" className="font-semibold text-purple-600 hover:underline">Register your school</Link></>:<p>{role==='student'?'Your school creates your student record.':'Ask your school proprietor or director for an email invitation.'}</p>}
            </div>

            <div className="mt-8 pt-6 border-t border-border flex items-center justify-center gap-4 text-xs text-muted">
              <Link to="/schoolpro" className="hover:text-ink">SchoolPro Home</Link>
              <Link to="/schoolpro/support" className="hover:text-ink">Support</Link>
              <Link to="/" className="hover:text-ink">IHLink Co. Ltd.</Link>
            </div>
          </div>
        </div>
      </div>
    </PageShell>
  );
}
