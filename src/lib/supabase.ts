import {securitySupported,nativeAuthStorage} from '@/lib/nativeVault';
import {isNativeApp,nativeOAuthEnabled} from '@/lib/nativeAuth';
import { createClient } from "@supabase/supabase-js";

// These are public browser credentials (not the service-role secret). Environment
// variables can override them for staging or a future Supabase project.
const supabaseUrl = (import.meta.env.VITE_SUPABASE_URL ||
  "https://lnqsroyiybutkfngbyge.supabase.co") as string;
const supabasePublishableKey = (import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  "sb_publishable_VtL5RtPncmUXxxjrM_tFQw_T4cPPYDq") as string;

export const isSupabaseConfigured = Boolean(supabaseUrl && supabasePublishableKey);

export const supabase = isSupabaseConfigured
  ? createClient(supabaseUrl!, supabasePublishableKey!, {
      auth: {
        persistSession: true,
        flowType: isNativeApp()&&nativeOAuthEnabled?'pkce':'implicit',
        autoRefreshToken: !securitySupported,
        ...(securitySupported?{storage:nativeAuthStorage}:{}),
        detectSessionInUrl: !isNativeApp(),
      },
    })
  : null;

export async function googleSignInAvailable(signal?:AbortSignal):Promise<boolean>{
 if(!isSupabaseConfigured)return false;
 try{const response=await fetch(`${supabaseUrl}/auth/v1/settings`,{headers:{apikey:supabasePublishableKey},signal});if(!response.ok)return false;const settings=await response.json();return settings.external?.google===true;}catch{return false;}
}
