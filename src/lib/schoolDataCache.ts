/**
 * In-memory, school-scoped request/data cache.
 * Deduplicates concurrent reads and reuses successful results during navigation.
 * Never use this cache as an authorization boundary; Supabase RLS remains authoritative.
 */
type Entry = { promise: Promise<unknown>; expiresAt: number };
const entries = new Map<string, Entry>();
const DEFAULT_TTL_MS = 120_000;

export function getSchoolData<T>(
  key: string,
  loader: () => Promise<T>,
  ttlMs = DEFAULT_TTL_MS,
): Promise<T> {
  const existing = entries.get(key);
  if (existing && existing.expiresAt > Date.now()) return existing.promise as Promise<T>;
  if (existing) entries.delete(key);

  const promise = Promise.resolve().then(loader).then((value) => {
    if (value && typeof value === "object" && "error" in value && (value as { error?: unknown }).error) {
      entries.delete(key);
    }
    return value;
  }).catch((error) => {
    entries.delete(key);
    throw error;
  });
  entries.set(key, { promise, expiresAt: Date.now() + ttlMs });
  return promise;
}

export function invalidateSchoolData(prefix?: string) {
  if (!prefix) {
    entries.clear();
    return;
  }
  for (const key of entries.keys()) {
    if (key.startsWith(prefix)) entries.delete(key);
  }
}

if (typeof window !== "undefined") {
  window.addEventListener("ihlink:account-change", () => invalidateSchoolData());
  window.addEventListener("ihlink:school-refresh", () => invalidateSchoolData());
}
