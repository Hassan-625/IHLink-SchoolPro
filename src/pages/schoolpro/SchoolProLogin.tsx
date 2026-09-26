import { Link, useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { PageShell } from '@/components/PageShell';
import { supabase } from '@/lib/supabase';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Input } from '@/components/ui/Input';
import { Logo } from '@/components/Logo';
import { Lock, Mail, ArrowRight, GraduationCap, Users, BookOpen, Award } from 'lucide-react';

interface SchoolProLoginProps {
  role: 'school' | 'parent' | 'student' | 'teacher';
}

const roleConfig = {
  school: { title: 'School Login', desc: 'Access your school management dashboard', icon: Award, color: 'purple', dashboard: '/schoolpro/proprietor-dashboard' },
  parent: { title: 'Parent Login', desc: 'View your child\'s results and pay fees', icon: Users, color: 'indigo', dashboard: '/schoolpro/parent-dashboard' },
  student: { title: 'Student Login', desc: 'Check your results and assignments', icon: GraduationCap, color: 'purple', dashboard: '/schoolpro/student-dashboard' },
  teacher: { title: 'Teacher Login', desc: 'Enter scores and manage your classes', icon: BookOpen, color: 'indigo', dashboard: '/schoolpro/teacher-dashboard' },
};

export function SchoolProLogin({ role }: SchoolProLoginProps) {
  const config = roleConfig[role];
  const navigate = useNavigate();
  const [email,setEmail]=useState(''); const [password,setPassword]=useState(''); const [error,setError]=useState(''); const [loading,setLoading]=useState(false);
  const signIn=async()=>{ if(!supabase){setError('Authentication is not configured.');return;} setLoading(true);setError('');const {error:e}=await supabase.auth.signInWithPassword({email,password});setLoading(false);if(e){setError(e.message);return;}navigate(config.dashboard); };

  return (
    <PageShell product="schoolpro" showAnnouncement={false} showHeader={false} showFooter={false}>
      <div className="min-h-screen grid grid-cols-12">
        {/* Left panel */}
        <div className="col-span-12 lg:col-span-5 bg-gradient-to-br from-purple-700 via-indigo-600 to-purple-500 text-white p-10 flex flex-col justify-center">
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
        </div>

        {/* Right panel */}
        <div className="col-span-12 lg:col-span-7 flex items-center justify-center p-10 bg-white">
          <div className="w-full max-w-sm">
            <Badge className="mb-3 bg-purple-50 text-purple-700 border-purple-200">{config.title}</Badge>
            <h1 className="text-2xl font-extrabold text-ink mb-2">Welcome Back</h1>
            <p className="text-sm text-muted mb-6">Sign in to your {role} account.</p>

            <div className="space-y-4">
              <Input label="Email" value={email} onChange={(e)=>setEmail(e.target.value)} type="email" placeholder="you@example.com" leftIcon={<Mail className="w-4 h-4" />} themeClass="focus:ring-purple-500/20 focus:border-purple-500" />
              <div>
                <label className="block text-sm font-semibold text-ink mb-1.5">Password</label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted" />
                  <input value={password} onChange={(e)=>setPassword(e.target.value)} type="password" placeholder="••••••••" className="w-full pl-10 pr-10 py-2.5 text-sm rounded-lg border border-border focus:outline-none focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500" />

                </div>
              </div>
              <div className="flex items-center justify-between">
                <label className="flex items-center gap-2 text-sm"><input type="checkbox" className="w-4 h-4 rounded border-border text-purple-500" /> <span className="text-ink">Remember me</span></label>
                <Link to="/reset-password" className="text-sm font-semibold text-purple-600 hover:underline">Forgot password?</Link>
              </div>
              {error&&<p className="text-sm text-red-600">{error}</p>}<Button fullWidth size="lg" disabled={loading||!email||!password} themeClass="bg-purple-600 hover:bg-purple-700" rightIcon={<ArrowRight className="w-4 h-4" />} onClick={signIn}>{loading?'Signing in…':'Sign In'}</Button>
            </div>

            <div className="mt-6 text-center text-sm text-muted">
              Don't have an account? <Link to="/schoolpro/register" className="font-semibold text-purple-600 hover:underline">Register your school</Link>
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
