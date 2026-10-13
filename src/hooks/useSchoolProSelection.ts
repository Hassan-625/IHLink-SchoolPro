import { useCallback, useEffect, useState } from "react";

export function useSchoolProSelection<T>(name: string, userId: string | undefined, schoolId: string | null | undefined, initialValue: T): [T, (next: T | ((current: T) => T)) => void] {
  const key = `ihlink-schoolpro-selection:${userId || "anonymous"}:${schoolId || "unresolved"}:${name}`;
  const read = useCallback((storageKey: string): T => {
    try { const saved = typeof window !== "undefined" ? window.localStorage.getItem(storageKey) : null; return saved === null ? initialValue : JSON.parse(saved) as T; }
    catch { return initialValue; }
  }, [initialValue]);
  const [state, setState] = useState<{ key: string; value: T }>(() => ({ key, value: read(key) }));
  useEffect(() => { setState({ key, value: read(key) }); }, [key, read]);
  const value = state.key === key ? state.value : read(key);
  const setValue = useCallback((next: T | ((current: T) => T)) => {
    setState(current => {
      const previous = current.key === key ? current.value : read(key);
      const value = typeof next === "function" ? (next as (current: T) => T)(previous) : next;
      try { if (typeof window !== "undefined") window.localStorage.setItem(key, JSON.stringify(value)); } catch { /* Keep in-memory selection if storage is unavailable. */ }
      return { key, value };
    });
  }, [key, read]);
  return [value, setValue];
}
