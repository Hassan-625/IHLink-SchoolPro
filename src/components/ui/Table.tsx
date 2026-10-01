import { isValidElement, useMemo, useState, type ReactNode } from 'react';
import { Search } from 'lucide-react';

interface TableProps {
  headers: { label: string; align?: 'left' | 'center' | 'right'; width?: string }[];
  rows: ReactNode[][];
  className?: string;
  searchable?: boolean;
  searchPlaceholder?: string;
  searchValues?: string[];
}

function searchableText(value: ReactNode): string {
  if (typeof value === 'string' || typeof value === 'number') return String(value);
  if (Array.isArray(value)) return value.map(searchableText).join(' ');
  if (isValidElement(value)) {
    const props = value.props as { children?: ReactNode; title?: string; 'aria-label'?: string; alt?: string };
    return [props.title, props['aria-label'], props.alt, searchableText(props.children)].filter(Boolean).join(' ');
  }
  return '';
}

export function Table({ headers, rows, className = '', searchable = true, searchPlaceholder = 'Search table…', searchValues }: TableProps) {
  const [query,setQuery]=useState('');
  const visibleRows=useMemo(()=>{
    const needle=query.trim().toLocaleLowerCase();
    if(!searchable||!needle)return rows;
    return rows.filter((row,index)=>`${searchValues?.[index]||''} ${row.map(searchableText).join(' ')}`.toLocaleLowerCase().includes(needle));
  },[rows,query,searchable,searchValues]);
  return (
    <div className={`w-full overflow-hidden rounded-2xl border border-border bg-white shadow-sm ${className}`}>
      {searchable&&<div className="relative m-4 max-w-md"><Search className="absolute left-3 top-3 h-4 w-4 text-muted"/><input type="search" aria-label={searchPlaceholder} value={query} onChange={e=>setQuery(e.target.value)} placeholder={searchPlaceholder} className="w-full rounded-xl border border-border bg-white py-2.5 pl-10 pr-3 text-sm shadow-sm outline-none transition focus:border-royal-500 focus:ring-4 focus:ring-royal-500/10"/></div>}
      <div className="max-h-[70vh] overflow-auto">
      <table className="w-full">
        <thead className="sticky top-0 z-10 bg-white">
          <tr className="border-b border-border">
            {headers.map((h, i) => (
              <th
                key={i}
                className={`px-4 py-3 text-xs font-bold text-muted uppercase tracking-wide whitespace-nowrap ${
                  h.align === 'right' ? 'text-right' : h.align === 'center' ? 'text-center' : 'text-left'
                }`}
                style={h.width ? { width: h.width } : undefined}
              >
                {h.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {visibleRows.map((row, ri) => (
            <tr key={ri} className="border-b border-border last:border-0 hover:bg-gray-50/50 transition-colors">
              {row.map((cell, ci) => (
                <td
                  key={ci}
                  className={`px-4 py-3 text-sm text-ink ${
                    headers[ci]?.align === 'right' ? 'text-right' : headers[ci]?.align === 'center' ? 'text-center' : 'text-left'
                  }`}
                >
                  {cell}
                </td>
              ))}
            </tr>
          ))}
          {!visibleRows.length && <tr><td colSpan={headers.length} className="px-4 py-12 text-center text-sm font-medium text-muted">{query.trim() ? 'No matching records.' : 'No records yet.'}</td></tr>}
        </tbody>
      </table>
      </div>
    </div>
  );
}

interface PaginationProps {
  current: number;
  total: number;
  onChange?: (page: number) => void;
}

export function Pagination({ current, total, onChange }: PaginationProps) {
  const pages = Math.min(total, 7);
  const start = Math.max(1, current - 3);
  const end = Math.min(total, start + pages - 1);
  const pageNumbers = [];
  for (let i = start; i <= end; i++) pageNumbers.push(i);

  return (
    <div className="flex items-center justify-between gap-4 mt-4">
      <p className="text-xs text-muted">
        Page {current} of {total}
      </p>
      <div className="flex items-center gap-1">
        <button
          onClick={() => onChange?.(Math.max(1, current - 1))}
          disabled={current === 1}
          className="px-3 py-1.5 text-xs font-semibold border border-border rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          Previous
        </button>
        {pageNumbers.map(p => (
          <button
            key={p}
            onClick={() => onChange?.(p)}
            className={`w-8 h-8 text-xs font-semibold rounded-lg transition-colors ${
              p === current ? 'bg-royal-500 text-white' : 'border border-border hover:bg-gray-50'
            }`}
          >
            {p}
          </button>
        ))}
        <button
          onClick={() => onChange?.(Math.min(total, current + 1))}
          disabled={current === total}
          className="px-3 py-1.5 text-xs font-semibold border border-border rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
        >
          Next
        </button>
      </div>
    </div>
  );
}

interface BreadcrumbsProps {
  items: { label: string; href?: string }[];
  themeClass?: string;
}

export function Breadcrumbs({ items, themeClass }: BreadcrumbsProps) {
  return (
    <nav className="flex items-center gap-2 text-sm">
      {items.map((item, i) => (
        <span key={i} className="flex items-center gap-2">
          {i > 0 && <span className="text-gray-300">/</span>}
          {item.href ? (
            <a href={item.href} className={`font-medium hover:underline ${themeClass || 'text-royal-600'}`}>
              {item.label}
            </a>
          ) : (
            <span className="font-medium text-muted">{item.label}</span>
          )}
        </span>
      ))}
    </nav>
  );
}
