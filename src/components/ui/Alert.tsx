import type { ReactNode } from 'react';
import { CheckCircle2, XCircle, Info, AlertTriangle, type LucideIcon } from 'lucide-react';

type AlertVariant = 'success' | 'error' | 'info' | 'warning';

interface AlertProps {
  variant: AlertVariant;
  title: string;
  children?: ReactNode;
  action?: ReactNode;
}

const config: Record<AlertVariant, { icon: LucideIcon; bg: string; border: string; iconColor: string; titleColor: string }> = {
  success: { icon: CheckCircle2, bg: 'bg-emerald-50', border: 'border-emerald-200', iconColor: 'text-emerald-500', titleColor: 'text-emerald-800' },
  error: { icon: XCircle, bg: 'bg-rose-50', border: 'border-rose-200', iconColor: 'text-rose-500', titleColor: 'text-rose-800' },
  info: { icon: Info, bg: 'bg-blue-50', border: 'border-blue-200', iconColor: 'text-blue-500', titleColor: 'text-blue-800' },
  warning: { icon: AlertTriangle, bg: 'bg-amber-50', border: 'border-amber-200', iconColor: 'text-amber-500', titleColor: 'text-amber-800' },
};

export function Alert({ variant, title, children, action }: AlertProps) {
  const cfg = config[variant];
  const Icon = cfg.icon;
  return (
    <div className={`flex items-start gap-3 p-4 rounded-xl border ${cfg.bg} ${cfg.border}`}>
      <Icon className={`w-5 h-5 shrink-0 mt-0.5 ${cfg.iconColor}`} />
      <div className="flex-1">
        <p className={`text-sm font-bold ${cfg.titleColor}`}>{title}</p>
        {children && <div className="text-sm text-ink/70 mt-1">{children}</div>}
      </div>
      {action && <div className="shrink-0">{action}</div>}
    </div>
  );
}

interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
}

export function EmptyState({ icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
      {icon && (
        <div className="w-16 h-16 rounded-2xl bg-gray-50 flex items-center justify-center text-gray-300 mb-4">
          {icon}
        </div>
      )}
      <h3 className="text-base font-bold text-ink">{title}</h3>
      {description && <p className="text-sm text-muted mt-1 max-w-sm">{description}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className = '' }: SkeletonProps) {
  return <div className={`skeleton rounded-lg ${className}`} />;
}

interface SpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export function Spinner({ size = 'md', className = '' }: SpinnerProps) {
  const sizes = { sm: 'w-4 h-4', md: 'w-6 h-6', lg: 'w-8 h-8' };
  return (
    <div className={`${sizes[size]} border-2 border-gray-200 border-t-royal-500 rounded-full animate-spin ${className}`} />
  );
}

interface LoadingStateProps {
  message?: string;
}

export function LoadingState({ message = 'Loading...' }: LoadingStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 gap-3">
      <Spinner size="lg" />
      <p className="text-sm text-muted">{message}</p>
    </div>
  );
}

interface ErrorStateProps {
  title?: string;
  message?: string;
  onRetry?: () => void;
}

export function ErrorState({ title = 'Something went wrong', message, onRetry }: ErrorStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
      <div className="w-16 h-16 rounded-2xl bg-rose-50 flex items-center justify-center text-rose-300 mb-4">
        <XCircle className="w-8 h-8" />
      </div>
      <h3 className="text-base font-bold text-ink">{title}</h3>
      {message && <p className="text-sm text-muted mt-1 max-w-sm">{message}</p>}
      {onRetry && (
        <button onClick={onRetry} className="mt-4 px-4 py-2 text-sm font-semibold text-royal-600 border border-royal-300 rounded-lg hover:bg-royal-50">
          Try again
        </button>
      )}
    </div>
  );
}

interface SuccessStateProps {
  title: string;
  message?: string;
  action?: ReactNode;
}

export function SuccessState({ title, message, action }: SuccessStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
      <div className="w-20 h-20 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-500 mb-4 relative">
        <div className="absolute inset-0 rounded-full bg-emerald-200 animate-pulse-ring" />
        <CheckCircle2 className="w-10 h-10 relative" />
      </div>
      <h3 className="text-lg font-bold text-ink">{title}</h3>
      {message && <p className="text-sm text-muted mt-1 max-w-sm">{message}</p>}
      {action && <div className="mt-6">{action}</div>}
    </div>
  );
}
