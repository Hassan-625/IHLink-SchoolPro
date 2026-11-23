export interface SchoolProConsolidatedRosterStudent {
  id: string;
  first_name?: string | null;
  middle_name?: string | null;
  last_name?: string | null;
  admission_number?: string | null;
}

export interface SchoolProConsolidatedSubject {
  subject_id: string;
  id?: string;
  name?: string;
  code?: string;
}

export interface SchoolProConsolidatedResult {
  student_id: string;
  subject_id: string;
  total_score: number;
  status: string;
  assessment_scheme_id: string;
  assessment_scores: Record<string, number>;
}

export interface SchoolProAssessmentScheme {
  id: string;
  components: Array<{ key: string; label: string; maxScore: number }>;
}

export interface SchoolProConsolidatedWorkbookOptions {
  roster: SchoolProConsolidatedRosterStudent[];
  subjects: SchoolProConsolidatedSubject[];
  results: SchoolProConsolidatedResult[];
  assessmentSchemes: SchoolProAssessmentScheme[];
  schoolName: string;
  className: string;
  term: string;
  session: string;
}

export interface SchoolProConsolidatedWorkbookResult {
  buffer: any;
  formulaCalculation: {
    formulaCount: number;
    evaluationCount: number;
    sheets: Array<{ name: string; formulaCount: number }>;
    engine: string;
    engineVersion: string;
    calculationMode: string;
  };
  studentCount: number;
  subjectCount: number;
  subjectIds: string[];
  worksheetName: string;
  assessmentComponentCount: number;
  rankingMethod: "competition-rank-by-grand-total";
}

export function buildSchoolProConsolidatedClassResultWorkbook(
  options: SchoolProConsolidatedWorkbookOptions
): Promise<SchoolProConsolidatedWorkbookResult>;
