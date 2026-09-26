import { useState, type ReactNode } from 'react';

interface TabsProps {
  tabs: { label: string; value: string; icon?: ReactNode; count?: number }[];
  defaultTab?: string;
  onChange?: (value: string) => void;
  themeClass?: string;
  children?: (activeTab: string) => ReactNode;
  content?: Record<string, ReactNode>;
}

export function Tabs({ tabs, defaultTab, onChange, themeClass, children, content }: TabsProps) {
  const [active, setActive] = useState(defaultTab || tabs[0]?.value || '');

  const handleChange = (value: string) => {
    setActive(value);
    onChange?.(value);
  };

  return (
    <div className="w-full">
      <div className="flex items-center gap-1 border-b border-border overflow-x-auto">
        {tabs.map(tab => (
          <button
            key={tab.value}
            onClick={() => handleChange(tab.value)}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-semibold whitespace-nowrap border-b-2 transition-all -mb-px ${
              active === tab.value
                ? (themeClass || 'border-royal-500 text-royal-600')
                : 'border-transparent text-muted hover:text-ink'
            }`}
          >
            {tab.icon}
            {tab.label}
            {tab.count !== undefined && (
              <span className={`px-1.5 py-0.5 text-2xs font-bold rounded-full ${active === tab.value ? 'bg-royal-50 text-royal-600' : 'bg-gray-100 text-gray-500'}`}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>
      <div className="pt-4">
        {content ? content[active] : children?.(active)}
      </div>
    </div>
  );
}
