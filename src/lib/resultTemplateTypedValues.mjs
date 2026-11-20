export function typedCustomValue(raw, valueType = 'text', label = 'Custom field') {
  if (raw === null || raw === undefined || String(raw).trim() === '') return '';
  switch (valueType || 'text') {
    case 'number': {
      const value = typeof raw === 'number' ? raw : Number(String(raw).trim());
      if (!Number.isFinite(value)) throw new Error(label + ' must resolve to a finite number.');
      return value;
    }
    case 'date': {
      const value = raw instanceof Date ? raw : new Date(String(raw));
      if (Number.isNaN(value.getTime())) throw new Error(label + ' must resolve to a valid date.');
      return value;
    }
    case 'boolean': {
      if (typeof raw === 'boolean') return raw;
      const value = String(raw).trim().toLowerCase();
      if (['true', 'yes', '1'].includes(value)) return true;
      if (['false', 'no', '0'].includes(value)) return false;
      throw new Error(label + ' must resolve to true/false, yes/no or 1/0.');
    }
    case 'text':
    default:
      return String(raw);
  }
}
