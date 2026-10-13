import {securitySupported,nativeAuthStorage} from '@/lib/nativeVault';
import {isNativeApp,nativeOAuthEnabled} from '@/lib/nativeAuth';
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/database.types";

// The URL and publishable-key fallbacks below keep the browser client configured by default.
// These are public browser credentials (not the service-role secret). Environment
// variables can override them for staging or a future Supabase project.
const supabaseUrl = (import.meta.env.VITE_SUPABASE_URL ||
  "https://lnqsroyiybutkfngbyge.supabase.co") as string;
const supabasePublishableKey = (import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  "sb_publishable_VtL5RtPncmUXxxjrM_tFQw_T4cPPYDq") as string;

export const isSupabaseConfigured = Boolean(supabaseUrl && supabasePublishableKey);

export const supabase = (isSupabaseConfigured
  ? createClient<Database>(supabaseUrl!, supabasePublishableKey!, {
      auth: {
        persistSession: true,
        flowType: isNativeApp()&&nativeOAuthEnabled?'pkce':'implicit',
        autoRefreshToken: !securitySupported,
        ...(securitySupported?{storage:nativeAuthStorage}:{}),
        detectSessionInUrl: !isNativeApp(),
      },
    })
  : null) as ReturnType<typeof createClient<Database>>;


