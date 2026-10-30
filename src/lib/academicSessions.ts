/** Canonical academic-session options in the platform's YYYY/YYYY format. */
export function academicSessionOptions(currentYear = new Date().getFullYear()): string[] {
  const firstYear = 2001;
  return Array.from(
    { length: Math.max(0, currentYear - firstYear + 1) },
    (_, index) => {
      const start = firstYear + index;
      return `${start}/${start + 1}`;
    },
  );
}

export type AcademicSessionStatus = 'upcoming' | 'active' | 'completed' | 'archived';

/** Derive date-sensitive status at read time; archived is an explicit retained state. */
export function academicSessionStatus(
  startDate: string,
  endDate: string,
  today: string,
  archived = false,
): AcademicSessionStatus {
  if (archived) return 'archived';
  if (today < startDate) return 'upcoming';
  if (today > endDate) return 'completed';
  return 'active';
}
