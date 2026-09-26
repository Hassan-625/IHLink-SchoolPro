import { createContext, useCallback, useContext, useState, type ReactNode } from 'react';
import { CheckCircle2, XCircle, Info, AlertTriangle, X } from 'lucide-react';

type ToastType = 'success' | 'error' | 'info' | 'warning';

interface ToastItem {
  id: string;
  type: ToastType;
  title: string;
  message?: string;
}

interface ToastContextValue {
  showToast: (type: ToastType, title: string, message?: string) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used within ToastProvider');
  return ctx;
}

const toastConfig: Record<ToastType, { icon: typeof CheckCircle2; bg: string; iconColor: string; border: string }> = {
  success: { icon: CheckCircle2, bg: 'bg-white', iconColor: 'text-emerald-500', border: 'border-l-emerald-500' },
  error: { icon: XCircle, bg: 'bg-white', iconColor: 'text-rose-500', border: 'border-l-rose-500' },
  info: { icon: Info, bg: 'bg-white', iconColor: 'text-royal-500', border: 'border-l-royal-500' },
  warning: { icon: AlertTriangle, bg: 'bg-white', iconColor: 'text-amber-500', border: 'border-l-amber-500' },
};

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([]);

  const showToast = useCallback((type: ToastType, title: string, message?: string) => {
    const id = Math.random().toString(36).slice(2);
    setToasts(prev => [...prev, { id, type, title, message }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 4000);
  }, []);

  const dismiss = (id: string) => setToasts(prev => prev.filter(t => t.id !== id));

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}
      <div className="fixed bottom-6 right-6 z-[100] flex flex-col gap-2 w-96 max-w-[calc(100vw-2rem)]">
        {toasts.map(toast => {
          const cfg = toastConfig[toast.type];
          const Icon = cfg.icon;
          return (
            <div
              key={toast.id}
              className={`flex items-start gap-3 p-4 rounded-xl shadow-float border border-l-4 ${cfg.bg} ${cfg.border} animate-slide-in-right`}
            >
              <Icon className={`w-5 h-5 shrink-0 mt-0.5 ${cfg.iconColor}`} />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-bold text-ink">{toast.title}</p>
                {toast.message && <p className="text-xs text-muted mt-0.5">{toast.message}</p>}
              </div>
              <button onClick={() => dismiss(toast.id)} className="text-muted hover:text-ink shrink-0">
                <X className="w-4 h-4" />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}
