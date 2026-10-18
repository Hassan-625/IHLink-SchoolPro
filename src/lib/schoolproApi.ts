import { supabase } from "@/lib/supabase";

const apiBaseUrl = (import.meta.env.VITE_SCHOOLPRO_API_URL || "").replace(/\/+$/, "");

export type SchoolContext = {
  id: string;
  name: string;
  code: string;
  status: string;
  role: string;
};

export type SchoolProApiErrorCode =
  | "api_not_configured"
  | "not_authenticated"
  | "request_failed";

export class SchoolProApiError extends Error {
  constructor(
    message: string,
    readonly code: SchoolProApiErrorCode,
    readonly status?: number,
  ) {
    super(message);
    this.name = "SchoolProApiError";
  }
}

async function apiGet<T>(path: string): Promise<T> {
  if (!apiBaseUrl) {
    throw new SchoolProApiError(
      "The SchoolPro API is not configured for this environment.",
      "api_not_configured",
    );
  }
  const { data, error } = await supabase.auth.getSession();
  if (error || !data.session?.access_token) {
    throw new SchoolProApiError("Sign in is required.", "not_authenticated", 401);
  }
  const response = await fetch(`${apiBaseUrl}${path}`, {
    method: "GET",
    headers: {
      authorization: `Bearer ${data.session.access_token}`,
      accept: "application/json",
    },
    cache: "no-store",
  });
  if (response.status === 401) {
    throw new SchoolProApiError("Your session is invalid or has expired.", "not_authenticated", 401);
  }
  if (!response.ok) {
    throw new SchoolProApiError("The SchoolPro service could not complete the request.", "request_failed", response.status);
  }
  return response.json() as Promise<T>;
}

/** Staged read-only API; existing production Supabase workflows are not redirected by this helper. */
export function getSchoolProContext() {
  return apiGet<{ user: { id: string; email: string | null }; platformAdmin: boolean; schools: SchoolContext[] }>(
    "/v1/me",
  );
}

export function getSchoolProSchool(schoolId: string) {
  if (!/^[0-9a-f-]{36}$/i.test(schoolId)) {
    throw new SchoolProApiError("Invalid school identifier.", "request_failed", 400);
  }
  return apiGet<{ school: SchoolContext }>(`/v1/schools/${encodeURIComponent(schoolId)}`);
}
