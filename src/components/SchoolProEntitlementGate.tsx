import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import { useSchoolProEntitlements } from "@/hooks/useSchoolProEntitlements";
import { useAuth } from "@/context/AuthContext";

type EntitlementKey = "website" | "cbt" | "advanced_reports" | "custom_branding";

const labels: Record<EntitlementKey, string> = {
  website: "School website",
  cbt: "CBT & online tests",
  advanced_reports: "Advanced reports",
  custom_branding: "Custom branding",
};

export function SchoolProEntitlementGate({ feature, children }: { feature: EntitlementKey; children: ReactNode }) {
  const { profile } = useAuth();
  const { entitlements, loading } = useSchoolProEntitlements();

  if (profile?.role === "super_admin") return <>{children}</>;

  if (loading) return <div className="min-h-[50vh] grid place-items-center text-sm text-muted">Checking SchoolPro subscription…</div>;
  if (entitlements?.active && entitlements?.[feature]) return <>{children}</>;

  return (
    <div className="min-h-[60vh] grid place-items-center bg-slate-50 px-6">
      <div className="w-full max-w-lg rounded-2xl border bg-white p-8 text-center shadow-sm">
        <h1 className="text-2xl font-bold text-slate-900">{labels[feature]} is not enabled</h1>
        <p className="mt-3 text-sm leading-6 text-slate-600">
          This feature is not included in the school's current SchoolPro subscription. Your existing school data is unchanged.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          <Link to="/schoolpro/pricing" className="rounded-lg bg-slate-900 px-4 py-2 text-sm font-semibold text-white">View plans</Link>
          <Link to="/schoolpro/admin-dashboard" className="rounded-lg border px-4 py-2 text-sm font-semibold text-slate-700">Back to dashboard</Link>
        </div>
      </div>
    </div>
  );
}
