import {androidVault,NativeVault,vaultReady} from '@/lib/nativeVault';
import {customerAuthError} from '@/lib/customerAuthError';
import {isNativeApp,nativeAuthRedirect,openNativeOAuth,publicAppOrigin,nativeOAuthEnabled} from '@/lib/nativeAuth';
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import type { Session, User } from "@supabase/supabase-js";
import { isSupabaseConfigured, supabase } from "@/lib/supabase";

export type UserRole =
  "super_admin" | "platform_admin" | "support" | "finance" | "customer";

export interface UserProfile {
  id: string;
  email: string;
  first_name: string | null;
  middle_name?: string | null;
  last_name: string | null;
  phone?: string | null;
  sex?: "male" | "female" | "prefer_not_to_say" | null;
  newsletter_opt_in?: boolean;
  role: UserRole;
  status: "active" | "suspended" | "invited";
  created_at?: string;
}
export type ProductKey = "corporate" | "datasub" | "schoolpro" | "consult" | "host" | "engineering" | "business_centre" | "print" | "fabrication" | "compute" | "academy" | "digital_business";
export interface AdminProductAccess { product: ProductKey; can_view: boolean; can_edit: boolean; can_approve: boolean; can_delete: boolean; can_manage: boolean; can_use_website_builder: boolean; can_use_command_center: boolean; }
export interface CustomerServiceAccess { product: ProductKey; status: "active" | "pending" | "suspended"; plan_name: string | null; }

interface SignUpInput {
  email: string;
  password: string;
  firstName: string;
  middleName: string;
  lastName: string;
  phone: string;
  sex: string;
  newsletterOptIn: boolean;
  service: string;
}

interface AuthValue {
  user: User | null;
  session: Session | null;
  profile: UserProfile | null;
  adminAccess: AdminProductAccess[];
  serviceAccess: CustomerServiceAccess[];
  loading: boolean;
  configured: boolean;
  signIn: (email: string, password: string) => Promise<string | null>;
  signUp: (input: SignUpInput) => Promise<{ error: string | null; needsVerification: boolean; existingAccount: boolean }>;
  signInWithGoogle: () => Promise<string | null>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<string | null>;
}

const AuthContext = createContext<AuthValue | undefined>(undefined);
const REMEMBER_KEY = "ih_remember_device";

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [adminAccess, setAdminAccess] = useState<AdminProductAccess[]>([]);
  const [serviceAccess, setServiceAccess] = useState<CustomerServiceAccess[]>([]);
  const [loading, setLoading] = useState(isSupabaseConfigured);

  useEffect(() => {
    if (!supabase) return;
    const client = supabase;
    let active = true;

    const loadProfile = async (current: Session | null) => {
      setSession(current);
      if (!current?.user) {
        setProfile(null);
        setAdminAccess([]);
        setServiceAccess([]);
        setLoading(false);
        return;
      }
      const [{ data }, { data: accessRows }, { data: serviceRows }] = await Promise.all([
        client.from("profiles").select("*").eq("id", current.user.id).maybeSingle(),
        client.from("admin_product_access").select("product,can_view,can_edit,can_approve,can_delete,can_manage,can_use_website_builder,can_use_command_center").eq("user_id", current.user.id),
        client.from("customer_service_access").select("product,status,plan_name").eq("user_id", current.user.id),
      ]);
      if (active) {
        setProfile((data as UserProfile | null) || null);
        setAdminAccess((accessRows || []) as AdminProductAccess[]);
        setServiceAccess((serviceRows || []) as CustomerServiceAccess[]);
        setLoading(false);
      }
    };

    client.auth.getSession().then(({ data }) => void loadProfile(data.session));
    const { data: listener } = client.auth.onAuthStateChange(
      (_event, nextSession) => {
        // Keep the auth callback synchronous. Supabase documents that awaiting
        // other client calls from this callback can deadlock subsequent calls.
        setSession(nextSession);
        if (!nextSession?.user) {
          setProfile(null);
          setAdminAccess([]);
          setServiceAccess([]);
          setLoading(false);
          return;
        }
        setLoading(true);
        window.setTimeout(() => {
          if (active) void loadProfile(nextSession);
        }, 0);
      },
    );
    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (!supabase || !session?.user || !profile) return;
    const client = supabase;
    const timeoutMs = profile.role === "super_admin" || profile.role === "platform_admin" || profile.role === "support" || profile.role === "finance"
      ? 15 * 60 * 1000
      : 30 * 60 * 1000;
    const expire=()=>{if(androidVault&&profile.role==='customer')void NativeVault.status().then(status=>{if(status.enabled)window.dispatchEvent(new Event('ihlink:lock-app'));else void client.auth.signOut({scope:'local'});});else void client.auth.signOut({scope:'local'});};
    const activityKey='ihlink.native.activity.'+session.user.id;
    const isAdministrator=profile.role!=='customer';
    const remembered=Number(sessionStorage.getItem(activityKey)||0);
    const delay=androidVault&&isAdministrator&&remembered?Math.max(0,timeoutMs-(Date.now()-remembered)):timeoutMs;
    if(androidVault&&!remembered)sessionStorage.setItem(activityKey,String(Date.now()));
    let timer = window.setTimeout(expire,delay);
    const reset = () => {
      window.clearTimeout(timer);
      if(androidVault)sessionStorage.setItem(activityKey,String(Date.now()));
      timer = window.setTimeout(expire,timeoutMs);
    };
    const events = ["pointerdown", "keydown", "scroll", "touchstart"];
    events.forEach((event) => window.addEventListener(event, reset, { passive: true }));
    return () => {
      window.clearTimeout(timer);
      events.forEach((event) => window.removeEventListener(event, reset));
    };
  }, [profile, session?.user]);

  const value = useMemo<AuthValue>(
    () => ({
      user: session?.user ?? null,
      session,
      profile,
      adminAccess,
      serviceAccess,
      loading,
      configured: isSupabaseConfigured,
      async signIn(email, password) {
        if (!supabase)
          return "Sign-in is temporarily unavailable. Please try again shortly.";
        const { error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        return error ? customerAuthError(error) : null;
      },
      async signUp({ email, password, firstName, middleName, lastName, phone, sex, newsletterOptIn, service }) {
        if (![firstName, middleName, lastName].every(name => name.trim())) return { error: "Enter your first name, middle name and surname.", needsVerification: false, existingAccount: false };
        if (!supabase)
          return { error: "Sign-in is temporarily unavailable. Please try again shortly.", needsVerification: false, existingAccount: false };
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: {
            emailRedirectTo: isNativeApp()&&nativeOAuthEnabled?nativeAuthRedirect:`${isNativeApp()?publicAppOrigin:window.location.origin}/verify-email?verified=1`,
            data: {
              first_name: firstName,
              middle_name: middleName,
              last_name: lastName,
              phone,
              sex,
              newsletter_opt_in: newsletterOptIn,
              requested_service: service,
            },
          },
        });
        if (error) return { error: customerAuthError(error), needsVerification: false, existingAccount: false };
        const identities = data.user?.identities;
        const existingAccount = Array.isArray(identities) && identities.length === 0;
        return { error: null, needsVerification: !data.session && !existingAccount, existingAccount };
      },
      async signInWithGoogle() {
        if (!supabase)
          return "Google sign-in is unavailable. Use your email and password.";
        const callback = new URL("/schoolpro/login", window.location.origin);
        // Return to the school login; its verified membership check chooses the dashboard.
        if(isNativeApp()&&!nativeOAuthEnabled)return 'Google sign-in is not enabled for this app build. Use email and password.';
        const { data, error } = await supabase.auth.signInWithOAuth({
          provider: "google",
          options: { redirectTo: isNativeApp()?nativeAuthRedirect:callback.toString(), skipBrowserRedirect:isNativeApp() },
        });
        if(!error&&isNativeApp()&&data.url){try{await openNativeOAuth(data.url);}catch{return 'Could not open secure Google sign-in. Use email and password.';}}
        return error ? customerAuthError(error) : null;
      },
      async signOut() {
        if (supabase) {
          await supabase.auth.signOut({ scope: "local" });
          if(androidVault){await NativeVault.reset();vaultReady();}
          setSession(null);
          setProfile(null);
          setAdminAccess([]);
          setServiceAccess([]);
          sessionStorage.removeItem("ih_auth_next");
          localStorage.removeItem(REMEMBER_KEY);
        }
      },
      async resetPassword(email) {
        if (!supabase)
          return "Password recovery is temporarily unavailable. Please try again shortly.";
        const { error } = await supabase.auth.resetPasswordForEmail(email, {
          redirectTo: isNativeApp()&&nativeOAuthEnabled?nativeAuthRedirect+'?flow=recovery':`${isNativeApp()?publicAppOrigin:window.location.origin}/auth/update-password`,
        });
        return error ? customerAuthError(error) : null;
      },
    }),
    [adminAccess, serviceAccess, loading, profile, session],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error("useAuth must be used inside AuthProvider");
  return value;
}
