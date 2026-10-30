/** Build the supported academic-session list using the platform's YYYY/YYYY storage format. */
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
