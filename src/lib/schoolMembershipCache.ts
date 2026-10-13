import type { SupabaseClient } from "@supabase/supabase-js";

type SchoolMembership = {
  id: string;
  school_id: string;
  role: string;
  schoolpro_schools?: { name?: string } | null;
} | null;

const memberships = new Map<string, Promise<SchoolMembership>>();

export function getSchoolMembership(
  client: SupabaseClient,
  userId: string,
  schoolId?: string | null,
): Promise<SchoolMembership> {
  const key = `${userId}:${schoolId || "*"}`;
  const existing = memberships.get(key);
  if (existing) return existing;

  let query = client
    .from("schoolpro_members")
    .select("id,school_id,role,schoolpro_schools!schoolpro_members_school_id_fkey(name)")
    .eq("user_id", userId)
    .limit(1);
  if (schoolId) query = query.eq("school_id", schoolId);

  const request = query.maybeSingle().then(({ data, error }) => {
    if (error) {
      memberships.delete(key);
      throw error;
    }
    return (data as SchoolMembership) || null;
  }).catch((error) => {
    memberships.delete(key);
    throw error;
  });
  memberships.set(key, request);
  return request;
}

export function clearSchoolMembershipCache() {
  memberships.clear();
}

if (typeof window !== "undefined") {
  window.addEventListener("ihlink:account-change", clearSchoolMembershipCache);
  window.addEventListener("ihlink:school-refresh", clearSchoolMembershipCache);
}
