export type CustomWorkbookValueType = 'text' | 'number' | 'date' | 'boolean';
export declare function typedCustomValue(raw: unknown, valueType?: CustomWorkbookValueType, label?: string): string | number | Date | boolean;
