import { customerMessage } from '@/lib/customerMessage';
import { useEffect, useRef, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';

const turnstileSiteKey = String(import.meta.env.VITE_TURNSTILE_SITE_KEY || '');
const turnstileAction = 'schoolpro_public_admission';

export function SchoolProPublicAdmission() {
  const [params] = useSearchParams();
  const school = params.get('school');
  const [form, setForm] = useState<any>({
    first_name: '', last_name: '', gender: '', date_of_birth: '',
    guardian_name: '', guardian_contact: '', guardian_email: '',
    class_applied: '', previous_school: '',
  });
  const [message, setMessage] = useState('');
  const [turnstileToken, setTurnstileToken] = useState('');
  const [widgetReady, setWidgetReady] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const widgetContainer = useRef<HTMLDivElement | null>(null);
  const widgetId = useRef<string | null>(null);

  useEffect(() => {
    if (!turnstileSiteKey || !widgetContainer.current) return;
    let cancelled = false;
    const mount = () => {
      const api = (window as any).turnstile;
      if (cancelled || !api || !widgetContainer.current || widgetId.current !== null) return;
      widgetId.current = String(api.render(widgetContainer.current, {
        sitekey: turnstileSiteKey,
        action: turnstileAction,
        callback: (token: string) => setTurnstileToken(token),
        'expired-callback': () => setTurnstileToken(''),
        'error-callback': () => {
          setTurnstileToken('');
          setMessage('Secure verification could not be completed. Please try again.');
        },
        theme: 'auto',
      }));
      setWidgetReady(true);
    };

    if ((window as any).turnstile) {
      mount();
    } else {
      let script = document.querySelector<HTMLScriptElement>('script[data-schoolpro-turnstile]');
      if (!script) {
        script = document.createElement('script');
        script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';
        script.async = true;
        script.defer = true;
        script.dataset.schoolproTurnstile = 'true';
        document.head.appendChild(script);
      }
      script.addEventListener('load', mount);
      script.addEventListener('error', () => setMessage('Secure verification could not load. Please refresh and try again.'), { once: true });
      if ((window as any).turnstile) mount();
    }

    return () => {
      cancelled = true;
      const api = (window as any).turnstile;
      if (widgetId.current !== null && api) api.remove(widgetId.current);
      widgetId.current = null;
    };
  }, []);

  async function submit() {
    if (!supabase || !school) {
      setMessage('A valid school admission link is required.');
      return;
    }
    if (!turnstileSiteKey || !widgetReady) {
      setMessage('Secure admission verification is not configured. Please contact the school.');
      return;
    }
    if (!turnstileToken) {
      setMessage('Complete the secure verification before submitting.');
      return;
    }

    setSubmitting(true);
    setMessage('');
    try {
      const { data, error } = await supabase.functions.invoke('schoolpro-public-admission', {
        body: {
          school,
          first_name: form.first_name,
          last_name: form.last_name,
          gender: form.gender,
          date_of_birth: form.date_of_birth || null,
          guardian_name: form.guardian_name,
          guardian_contact: form.guardian_contact,
          guardian_email: form.guardian_email,
          class_applied: form.class_applied,
          previous_school: form.previous_school || null,
          turnstileToken,
        },
      });
      if (error) throw new Error(data?.error || 'The application could not be submitted. Please try again.');
      setMessage(customerMessage(data?.error || 'Application submitted successfully. Reference: ' + data?.application_number));
    } catch (error) {
      const text = error instanceof Error ? error.message : 'The application could not be submitted. Please try again.';
      setMessage(customerMessage(text));
    } finally {
      setSubmitting(false);
      setTurnstileToken('');
      const api = (window as any).turnstile;
      if (widgetId.current !== null && api) api.reset(widgetId.current);
    }
  }

  return (
    <main className="min-h-screen bg-background p-4 md:p-10">
      <div className="mx-auto max-w-3xl">
        <h1 className="text-3xl font-black">Online Admission Application</h1>
        <p className="mt-2 text-muted">Complete the form carefully. The school will review your application and contact the guardian using the supplied details.</p>
        <Card className="mt-6">
          <div className="grid gap-3 md:grid-cols-2">
            {[
              ['first_name', 'First name'], ['last_name', 'Surname'], ['gender', 'Gender'],
              ['date_of_birth', 'Date of birth'], ['guardian_name', 'Parent/Guardian name'],
              ['guardian_contact', 'Guardian phone'], ['guardian_email', 'Guardian email'],
              ['class_applied', 'Class applying for'], ['previous_school', 'Previous school'],
            ].map(([key, label]) => (
              <input
                key={key}
                type={key === 'date_of_birth' ? 'date' : 'text'}
                value={form[key]}
                onChange={(event) => setForm({ ...form, [key]: event.target.value })}
                placeholder={label}
                aria-label={label}
                className="rounded-xl border p-3"
                maxLength={key === 'first_name' || key === 'last_name' ? 80 : key === 'guardian_name' ? 120 : key === 'class_applied' ? 80 : key === 'previous_school' ? 160 : key === 'guardian_contact' ? 32 : key === 'guardian_email' ? 254 : undefined}
              />
            ))}
            {turnstileSiteKey ? (
              <div className="md:col-span-2">
                <div ref={widgetContainer} aria-label="Secure admission verification" />
                <p className="mt-1 text-xs text-muted">Secure verification helps protect the school from automated submissions.</p>
              </div>
            ) : (
              <p className="md:col-span-2 text-sm text-muted">Secure admission verification is not configured yet. Online applications are temporarily unavailable.</p>
            )}
            <Button onClick={() => void submit()} disabled={submitting || !turnstileToken || !widgetReady}>
              {submitting ? 'Submitting…' : 'Submit Application'}
            </Button>
          </div>
          {message && <p role="status" className="mt-4 text-sm font-semibold">{message}</p>}
        </Card>
      </div>
    </main>
  );
}
