import type { ReactNode } from 'react';

interface BarChartProps {
  data: { label: string; value: number; color?: string }[];
  height?: number;
  formatValue?: (v: number) => string;
  themeColor?: string;
}

export function BarChart({ data, height = 200, formatValue, themeColor = '#1565D8' }: BarChartProps) {
  const maxVal = Math.max(...data.map(d => d.value), 1);
  return (
    <div className="w-full">
      <div className="flex items-end justify-between gap-2" style={{ height }}>
        {data.map((d, i) => (
          <div key={i} className="flex-1 flex flex-col items-center gap-2 group">
            <div className="relative w-full flex items-end justify-center" style={{ height: height - 30 }}>
              <div
                className="w-full max-w-[40px] rounded-t-lg transition-all duration-500 hover:opacity-80 cursor-pointer relative"
                style={{
                  height: `${(d.value / maxVal) * 100}%`,
                  backgroundColor: d.color || themeColor,
                  minHeight: '4px',
                }}
              >
                <div className="absolute -top-7 left-1/2 -translate-x-1/2 px-2 py-0.5 text-2xs font-bold text-white bg-navy-900 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                  {formatValue ? formatValue(d.value) : d.value}
                </div>
              </div>
            </div>
            <span className="text-2xs font-medium text-muted truncate w-full text-center">{d.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

interface LineChartProps {
  data: { label: string; value: number }[];
  height?: number;
  color?: string;
  formatValue?: (v: number) => string;
}

export function LineChart({ data, height = 200, color = '#1565D8', formatValue }: LineChartProps) {
  const maxVal = Math.max(...data.map(d => d.value), 1);
  const minVal = Math.min(...data.map(d => d.value), 0);
  const range = maxVal - minVal || 1;
  const width = 100;
  const stepX = width / (data.length - 1 || 1);

  const points = data.map((d, i) => ({
    x: i * stepX,
    y: height - 30 - ((d.value - minVal) / range) * (height - 50),
  ...d,
  }));

  const pathD = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ');
  const areaD = `${pathD} L ${points[points.length - 1].x} ${height - 30} L 0 ${height - 30} Z`;

  return (
    <div className="w-full">
      <svg viewBox={`0 0 ${width} ${height}`} className="w-full" style={{ height }} preserveAspectRatio="none">
        <defs>
          <linearGradient id={`grad-${color.replace('#', '')}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.25" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>
        {[0.25, 0.5, 0.75].map(r => (
          <line key={r} x1="0" y1={height * r} x2={width} y2={height * r} stroke="#E2E8F0" strokeWidth="0.2" strokeDasharray="0.5" />
        ))}
        <path d={areaD} fill={`url(#grad-${color.replace('#', '')})`} />
        <path d={pathD} fill="none" stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
        {points.map((p, i) => (
          <g key={i}>
            <circle cx={p.x} cy={p.y} r="1.2" fill={color} />
            <circle cx={p.x} cy={p.y} r="3" fill={color} fillOpacity="0" className="hover:fill-opacity-20" />
          </g>
        ))}
      </svg>
      <div className="flex items-center justify-between mt-2">
        {data.map((d, i) => (
          <span key={i} className="text-2xs font-medium text-muted">{d.label}</span>
        ))}
      </div>
    </div>
  );
}

interface DonutChartProps {
  data: { label: string; value: number; color: string }[];
  size?: number;
  thickness?: number;
  centerLabel?: string;
  centerValue?: string;
}

export function DonutChart({ data, size = 180, thickness = 24, centerLabel, centerValue }: DonutChartProps) {
  const total = data.reduce((sum, d) => sum + d.value, 0);
  const radius = (size - thickness) / 2;
  const circumference = 2 * Math.PI * radius;
  let offset = 0;

  return (
    <div className="flex items-center gap-6">
      <div className="relative" style={{ width: size, height: size }}>
        <svg width={size} height={size} className="-rotate-90">
          {data.map((d, i) => {
            const pct = (d.value / total) * circumference;
            const circle = (
              <circle
                key={i}
                cx={size / 2}
                cy={size / 2}
                r={radius}
                fill="none"
                stroke={d.color}
                strokeWidth={thickness}
                strokeDasharray={`${pct} ${circumference}`}
                strokeDashoffset={-offset}
                strokeLinecap="round"
              />
            );
            offset += pct;
            return circle;
          })}
        </svg>
        {(centerLabel || centerValue) && (
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            {centerValue && <span className="text-xl font-bold text-ink">{centerValue}</span>}
            {centerLabel && <span className="text-xs text-muted">{centerLabel}</span>}
          </div>
        )}
      </div>
      <div className="space-y-2">
        {data.map((d, i) => (
          <div key={i} className="flex items-center gap-2.5">
            <span className="w-3 h-3 rounded-full" style={{ backgroundColor: d.color }} />
            <span className="text-sm font-medium text-ink">{d.label}</span>
            <span className="text-sm font-bold text-muted ml-auto">
              {Math.round((d.value / total) * 100)}%
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

interface AnimatedCounterProps {
  value: number;
  prefix?: string;
  suffix?: string;
  duration?: number;
  className?: string;
  format?: (v: number) => string;
}

export function AnimatedCounter({ value, prefix = '', suffix = '', className = '', format }: AnimatedCounterProps) {
  const display = format ? format(value) : value.toLocaleString('en-US');
  return (
    <span className={`tabular-nums ${className}`}>
      {prefix}{display}{suffix}
    </span>
  );
}

interface StatCardProps {
  label: string;
  value: ReactNode;
  icon?: ReactNode;
  trend?: { value: string; positive: boolean };
  color?: string;
  iconBg?: string;
  iconColor?: string;
}

export function StatCard({ label, value, icon, trend, iconBg = 'bg-royal-50', iconColor = 'text-royal-600' }: StatCardProps) {
  return (
    <div className="bg-white rounded-xl border border-border shadow-card p-5">
      <div className="flex items-start justify-between mb-3">
        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${iconBg} ${iconColor}`}>
          {icon}
        </div>
        {trend && (
          <span className={`text-xs font-bold px-2 py-1 rounded-full ${trend.positive ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>
            {trend.positive ? '↑' : '↓'} {trend.value}
          </span>
        )}
      </div>
      <p className="text-2xl font-bold text-ink">{value}</p>
      <p className="text-sm text-muted mt-1">{label}</p>
    </div>
  );
}
