export type SchoolProGradeBand = {
  label: string;
  min_score: number | string;
  max_score: number | string;
  is_active?: boolean;
  remark?: string | null;
  overall_remark?: string | null;
};

export function findSchoolProGradeBand(score: number, scale: readonly SchoolProGradeBand[] = []) {
  if (!Number.isFinite(score)) return undefined;
  return scale.find((band) => band.is_active !== false
    && score >= Number(band.min_score)
    && score <= Number(band.max_score));
}

export function schoolProGradeLabel(score: number, scale: readonly SchoolProGradeBand[] = []) {
  const activeBands = scale.filter((band) => band.is_active !== false);
  const match = findSchoolProGradeBand(score, activeBands);
  if (match) return match.label;
  if (activeBands.length) return 'Ungraded';
  return score >= 80 ? 'A' : score >= 70 ? 'B' : score >= 60 ? 'C' : score >= 50 ? 'D' : score >= 40 ? 'E' : 'F';
}
