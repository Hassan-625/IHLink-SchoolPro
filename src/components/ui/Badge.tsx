import type { ReactNode } from 'react';
import { statusBadgeClass, statusLabel } from '@/lib/designTokens';

interface BadgeProps {
  children?: ReactNode;
  variant?: 'default' | 'status' | 'dot';
  status?: string;
  className?: string;
  dotColor?: string;
}

export function Badge({ children, variant = 'default', status, className = '', dotColor }: BadgeProps) {
  if (variant === 'status' && status) {
    return (
      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full border ${statusBadgeClass(status)} ${className}`}>
        <span className={`w-1.5 h-1.5 rounded-full ${dotColor || 'bg-current'}`} />
        {statusLabel(status)}
      </span>
    );
  }
  if (variant === 'dot') {
    return (
      <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold rounded-full border border-border bg-gray-50 text-ink ${className}`}>
        <span className={`w-1.5 h-1.5 rounded-full ${dotColor || 'bg-gray-400'}`} />
        {children}
      </span>
    );
  }
  return (
    <span className={`inline-flex items-center px-2.5 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-700 ${className}`}>
      {children}
    </span>
  );
}
