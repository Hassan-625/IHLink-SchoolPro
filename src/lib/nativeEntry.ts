export function signedOutNativeAccess(path: string): 'welcome' | 'public' | 'signin' {
  if (path === '/' || path === '/schoolpro') return 'welcome';
  if (/^\/(?:signin|register|reset-password|verify-email|auth\/(?:handoff|update-password))\/?$/.test(path)) return 'public';
  if (/^\/schoolpro\/(?:login|teacher-login|parent-login|student-login|register|get-in-touch|result-checker|verify-document)\/?$/.test(path)) return 'public';
  if (/^\/school(?:\/[^/]+)?\/?$/.test(path) || /^\/schoolpro\/(?:apply|admission\/(?:offer|cbt)\/[^/]+)\/?$/.test(path)) return 'public';
  return 'signin';
}
